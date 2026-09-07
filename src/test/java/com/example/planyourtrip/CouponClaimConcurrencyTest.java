package com.example.planyourtrip;

import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D4 — the coupon claim path must honour its own issuance limits under concurrency.
 *
 * <p>{@code CouponDefinition} carries two limits an operator sets when they configure a campaign:
 * {@code totalUsageLimit} (how many claims exist in total) and {@code usageLimitPerUser}. Both were
 * enforced by reading the count, comparing it, and then incrementing — with no lock on the
 * definition row and no {@code @Version} on the entity. Two claims arriving together both read the
 * pre-increment value, both pass the check, and both write: the campaign issues more discount than
 * the operator authorised, and the overshoot is silent.
 *
 * <p>These two tests are the proof. They follow the concurrency pattern already used by
 * {@code LoyaltyRedemptionTest} and {@code RoomInventorySafetyTest}: a fixed pool, a latch so both
 * requests start together, status codes returned rather than asserted inside the worker, and an
 * assertion on the final persisted state. There is no sleeping and no retrying — the latch makes
 * the race deterministic enough to observe, and the invariant asserted afterwards is exact.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CouponClaimConcurrencyTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    /**
     * Two different customers race for the only claim a campaign authorises. Exactly one may win.
     */
    @Test
    void concurrentClaimsCannotExceedTotalUsageLimit() throws Exception {
        String code = uniqueCode("TOTAL");
        Long defId = createCoupon(couponPayload(code, 1, 5)).get("id").asLong();

        String tokenA = registerAndLogin("cpn-total-a");
        String tokenB = registerAndLogin("cpn-total-b");

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        Callable<Integer> claimA = () -> { start.await(); return claimStatus(tokenA, code); };
        Callable<Integer> claimB = () -> { start.await(); return claimStatus(tokenB, code); };
        Future<Integer> fa = pool.submit(claimA);
        Future<Integer> fb = pool.submit(claimB);
        start.countDown();
        int statusA = fa.get(30, TimeUnit.SECONDS);
        int statusB = fb.get(30, TimeUnit.SECONDS);
        pool.shutdown();

        int created = (statusA == 201 ? 1 : 0) + (statusB == 201 ? 1 : 0);
        assertEquals(1, created,
            "exactly one of two concurrent claims may succeed against totalUsageLimit=1, got "
                + statusA + " and " + statusB);

        JsonNode def = definition(defId);
        assertEquals(1, def.get("currentUsageCount").asInt(),
            "the campaign must not issue more claims than it authorised");
    }

    /**
     * One customer sends the same claim twice at once. The per-user limit must still hold.
     */
    @Test
    void concurrentClaimsBySameUserCannotExceedPerUserLimit() throws Exception {
        String code = uniqueCode("PERUSER");
        Long defId = createCoupon(couponPayload(code, 50, 1)).get("id").asLong();

        String token = registerAndLogin("cpn-peruser");

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        Callable<Integer> first = () -> { start.await(); return claimStatus(token, code); };
        Callable<Integer> second = () -> { start.await(); return claimStatus(token, code); };
        Future<Integer> f1 = pool.submit(first);
        Future<Integer> f2 = pool.submit(second);
        start.countDown();
        int s1 = f1.get(30, TimeUnit.SECONDS);
        int s2 = f2.get(30, TimeUnit.SECONDS);
        pool.shutdown();

        int created = (s1 == 201 ? 1 : 0) + (s2 == 201 ? 1 : 0);
        assertEquals(1, created,
            "exactly one of two concurrent claims by the same user may succeed against "
                + "usageLimitPerUser=1, got " + s1 + " and " + s2);

        long held = 0;
        for (JsonNode c : mine(token)) {
            if (defId.equals(c.get("coupon").get("id").asLong())) held++;
        }
        assertEquals(1, held, "the customer must end up holding exactly one copy of the coupon");
        assertEquals(1, definition(defId).get("currentUsageCount").asInt(),
            "the definition's live-claim count must match the coupons actually issued");
    }


    /**
     * One claimed coupon, two bookings started at the same moment. A coupon is single-use: the
     * discount may be granted once. {@code validateForCheckout} picks the AVAILABLE claim and
     * {@code markUsedForBooking} consumes it, so without a lock on that row both bookings see the
     * same AVAILABLE coupon, both pass, and the customer spends one coupon twice.
     *
     * <p>The two bookings deliberately use different date ranges, so room inventory can never be
     * the thing that rejects one of them — the only contended resource is the coupon.
     */
    @Test
    void oneCouponCannotBeSpentOnTwoConcurrentBookings() throws Exception {
        String code = uniqueCode("DBLSPEND");
        createCoupon(couponPayload(code, null, 1));

        String token = registerAndLogin("cpn-dblspend");
        assertEquals(201, claimStatus(token, code), "precondition: the claim must succeed");

        Long roomId = seededRoomId();
        // Both ranges sit inside the seeded 90-day inventory horizon and do not overlap each
        // other, so inventory can never be what rejects a booking here.
        LocalDate ciA = TODAY.plusDays(60), coA = ciA.plusDays(2);
        LocalDate ciB = TODAY.plusDays(75), coB = ciB.plusDays(2);

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        Callable<Integer> bookA = () -> { start.await(); return bookStatus(token, roomId, ciA, coA, code); };
        Callable<Integer> bookB = () -> { start.await(); return bookStatus(token, roomId, ciB, coB, code); };
        Future<Integer> fa = pool.submit(bookA);
        Future<Integer> fb = pool.submit(bookB);
        start.countDown();
        int statusA = fa.get(60, TimeUnit.SECONDS);
        int statusB = fb.get(60, TimeUnit.SECONDS);
        pool.shutdown();

        int created = (statusA == 201 ? 1 : 0) + (statusB == 201 ? 1 : 0);
        assertEquals(1, created,
            "a single-use coupon may be spent on exactly one of two concurrent bookings, got "
                + statusA + " and " + statusB);
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private String adminTokenCache;

    private String adminToken() throws Exception {
        if (adminTokenCache == null) {
            String body = mvc.perform(post("/api/auth/login")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
            adminTokenCache = mapper.readTree(body).get("token").asText();
        }
        return adminTokenCache;
    }

    private String registerAndLogin(String prefix) throws Exception {
        String email = prefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Coupon Racer\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private static String uniqueCode(String prefix) {
        return ("CPN-D4-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private static String couponPayload(String code, Integer totalUsageLimit, int perUser) {
        return """
            {"code":"%s","name":"D4 Race %s","description":"concurrency probe",
             "discountType":"PERCENTAGE","discountValue":10,"maxDiscountAmount":null,
             "minimumSpend":null,"validFrom":"%s","validUntil":"%s","active":true,
             "totalUsageLimit":%s,"usageLimitPerUser":%d}
            """.formatted(code, code, TODAY.minusDays(1), TODAY.plusDays(30),
                          totalUsageLimit == null ? "null" : totalUsageLimit.toString(), perUser);
    }

    private JsonNode createCoupon(String payload) throws Exception {
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    /** Raw status — the worker must not assert, so a losing claim is data, not a thrown error. */
    private int claimStatus(String token, String code) throws Exception {
        return mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andReturn().getResponse().getStatus();
    }

    private Long seededRoomId() {
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        return hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    /** Raw status — a losing booking is data, not a thrown assertion, inside the worker. */
    private int bookStatus(String token, Long roomId, LocalDate ci, LocalDate co, String code)
            throws Exception {
        String payload = ("{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\","
            + "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null,"
            + "\"couponCode\":\"%s\",\"creditAmount\":null}").formatted(roomId, ci, co, code);
        return mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andReturn().getResponse().getStatus();
    }

    private JsonNode definition(Long id) throws Exception {
        return mapper.readTree(mvc.perform(get("/api/admin/coupon-definitions/" + id)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
    }

    private JsonNode mine(String token) throws Exception {
        return mapper.readTree(mvc.perform(get("/api/me/coupons")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
    }
}
