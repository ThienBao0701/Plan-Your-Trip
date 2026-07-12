package com.example.planyourtrip;

import com.example.planyourtrip.model.CallbackOutcome;
import com.example.planyourtrip.model.InventoryReservation;
import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Instant;
import java.time.LocalDate;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * InventoryReservationTest — Phase 7.28 (Inventory Lock &amp; Room Hold).
 *
 * <p>Exercises the {@code InventoryReservation} tracking/expiry layer end-to-end: the HELD
 * hold created at booking time (over the EXISTING decrement), consumption on payment success,
 * release on payment failure / cancelled session / booking cancellation, timeout expiry, and
 * the admin/customer inspection endpoints. Also proves overselling is impossible under
 * concurrent booking attempts and that every release path is idempotent (no double-restore).
 *
 * <p>Isolation: uses SUITE-KNG at grand-palace on a FAR-FUTURE date band (day 500+) that the
 * seed (days 0–89) and every other test class leave untouched; each test seeds its own
 * inventory rows there via the admin bulk-upsert endpoint, so availability values are exact.
 */
@SpringBootTest
@AutoConfigureMockMvc
class InventoryReservationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired InventoryReservationRepository reservationRepo;

    private static final LocalDate TODAY = LocalDate.now();
    private static final AtomicInteger DAY = new AtomicInteger(500);

    private String adminToken;
    private String userToken;
    private Long roomId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        userToken  = login("demo@planyourtrip.com",  "demo123456");

        Long placeId  = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        roomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "SUITE-KNG".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HOLD
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingCreatesHeldReservationAndDecrementsInventory() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 3, 3);

        Long bookingId = createBooking(userToken, ci, 1);

        InventoryReservation r = reservationRepo.findByBookingId(bookingId).orElseThrow();
        assertEquals("HELD", r.getStatus().name());
        assertNotNull(r.getExpiresAt(), "hold must carry an expiry");
        assertEquals(2, avail(ci), "one room held → availability decremented by 1");
    }

    @Test
    void onlyOneReservationPerBooking() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 2, 2);
        Long bookingId = createBooking(userToken, ci, 1);
        // The unique constraint + pre-check guarantee exactly one reservation row.
        assertTrue(reservationRepo.existsByBookingId(bookingId));
        assertEquals(1, reservationRepo.findAll().stream()
            .filter(x -> x.getBooking().getId().equals(bookingId)).count());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYMENT SUCCESS → CONSUME
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void paymentSuccessConsumesHoldWithoutRestoringInventory() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 2, 2);
        Long bookingId = createBooking(userToken, ci, 1);
        assertEquals(1, avail(ci));

        payAndSucceed(userToken, bookingId);

        assertEquals("CONSUMED", resStatus(bookingId));
        assertEquals(1, avail(ci), "consumed hold keeps the decrement permanent — no restore");
        assertEquals("CONFIRMED", bookingStatus(bookingId));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PAYMENT FAILURE → RELEASE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void paymentFailureReleasesHoldAndRestoresInventory() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);
        Long bookingId = createBooking(userToken, ci, 1);
        assertEquals(0, avail(ci), "room exhausted while held");

        Long paymentId = createPaymentPending(userToken, bookingId);
        failPayment(userToken, paymentId);

        assertEquals("RELEASED", resStatus(bookingId));
        assertEquals(1, avail(ci), "failed payment restores the held inventory");
        // Documented Phase 7.28 behavior: the booking legitimately stays PENDING with its
        // hold already released.
        assertEquals("PENDING", bookingStatus(bookingId));
    }

    @Test
    void duplicateReleaseIsIdempotentAndDoesNotDoubleRestore() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);
        Long bookingId = createBooking(userToken, ci, 1);

        Long p1 = createPaymentPending(userToken, bookingId);
        failPayment(userToken, p1);
        assertEquals(1, avail(ci));
        assertEquals("RELEASED", resStatus(bookingId));

        // A second failed payment fires releaseForBooking again — must be a no-op.
        Long p2 = createPaymentPending(userToken, bookingId);
        failPayment(userToken, p2);

        assertEquals("RELEASED", resStatus(bookingId));
        assertEquals(1, avail(ci), "second release must NOT restore inventory again");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CANCELLED SESSION → RELEASE   +   DUPLICATE WEBHOOK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void cancelledPaymentSessionReleasesHold() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);
        Long bookingId = createBooking(userToken, ci, 1);
        assertEquals(0, avail(ci));

        JsonNode session = createSession(userToken, bookingId);
        String sessionId = session.get("sessionId").asText();
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/cancel")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk());

        assertEquals("RELEASED", resStatus(bookingId), "cancelled session releases the hold via mockFail bridge");
        assertEquals(1, avail(ci));
    }

    @Test
    void duplicateFailedWebhookDoesNotDoubleRelease() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);
        Long bookingId = createBooking(userToken, ci, 1);

        JsonNode session = createSession(userToken, bookingId);
        callback(session, CallbackOutcome.FAILED);
        assertEquals("RELEASED", resStatus(bookingId));
        assertEquals(1, avail(ci));

        // Duplicate provider callback on the now-terminal session is a no-op end to end.
        callback(session, CallbackOutcome.FAILED);
        assertEquals("RELEASED", resStatus(bookingId));
        assertEquals(1, avail(ci), "duplicate webhook must not restore inventory twice");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // TIMEOUT → EXPIRE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void overdueHoldIsExpiredBySweepAndRestoresInventory() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);
        Long bookingId = createBooking(userToken, ci, 1);
        assertEquals(0, avail(ci));

        // Force the hold overdue, then run the admin sweep.
        InventoryReservation r = reservationRepo.findByBookingId(bookingId).orElseThrow();
        r.setExpiresAt(Instant.now().minusSeconds(120));
        reservationRepo.saveAndFlush(r);

        String body = mvc.perform(post("/api/admin/inventory-reservations/process-expirations")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(body).get("expiredCount").asInt() >= 1);

        assertEquals("EXPIRED", resStatus(bookingId));
        assertEquals(1, avail(ci), "expired hold restores inventory");
    }

    @Test
    void freshHoldIsNotExpiredBySweep() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);
        Long bookingId = createBooking(userToken, ci, 1);

        mvc.perform(post("/api/admin/inventory-reservations/process-expirations")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        assertEquals("HELD", resStatus(bookingId), "a hold within its window must survive the sweep");
        assertEquals(0, avail(ci));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BOOKING CANCELLATION → RELEASE (no double-restore vs the direct restoreInventory)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingCancellationReleasesHoldExactlyOnce() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 2, 2);
        Long bookingId = createBooking(userToken, ci, 1);
        assertEquals(1, avail(ci));

        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cancelReason\":\"changed plans\"}"))
            .andExpect(status().isOk());

        assertEquals("RELEASED", resStatus(bookingId));
        assertEquals(2, avail(ci), "cancellation restores exactly once (2), never doubled to 3");
    }

    @Test
    void confirmedBookingCancellationRestoresOnceAfterConsume() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 2, 2);
        Long bookingId = createBooking(userToken, ci, 1);
        payAndSucceed(userToken, bookingId);
        assertEquals("CONSUMED", resStatus(bookingId));
        assertEquals(1, avail(ci));

        // Admin force-cancel a CONFIRMED booking → existing restoreInventory + reservation flip.
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CANCELLED\"}"))
            .andExpect(status().isOk());

        // A CONSUMED hold is terminal: booking cancellation is a safe no-op on the reservation
        // (stays CONSUMED), so the hold is never double-restored. The inventory itself is
        // returned exactly once by the pre-existing direct restoreInventory call in the
        // cancellation flow.
        assertEquals("CONSUMED", resStatus(bookingId));
        assertEquals(2, avail(ci), "confirmed-then-cancelled restores inventory exactly once");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INVENTORY EXHAUSTION + ROLLBACK
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void inventoryExhaustionRejectsSecondBooking() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1);

        Long first = createBooking(userToken, ci, 1);
        assertEquals("HELD", resStatus(first));
        assertEquals(0, avail(ci));

        // Second booking for the exhausted night is rejected (422) and creates no hold.
        assertEquals(422, createBookingRaw(userToken, ci, 1, null));
        assertEquals(0, avail(ci), "availability never goes negative");
    }

    @Test
    void failedBookingRollsBackDecrementAndHoldTogether() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 3, 3);

        // A bogus gift-card code makes create() throw AFTER the decrement + hold (gift card is
        // the last checkout step) → the whole transaction rolls back atomically.
        assertEquals(404, createBookingRaw(userToken, ci, 1, "NO-SUCH-GIFTCARD-XYZ"));

        assertEquals(3, avail(ci), "rolled-back booking leaves inventory untouched");
        assertEquals(0, reservationRepo.findAll().stream()
            .filter(x -> x.getCheckInDate().equals(ci)).count(),
            "rolled-back booking leaves no orphan reservation");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONCURRENCY — the overselling proof
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void simultaneousReservationsCannotOversell() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 1, 1); // exactly ONE room for this night

        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        Callable<Integer> a = () -> { start.await(); return createBookingRaw(userToken, ci, 1, null); };
        Callable<Integer> b = () -> { start.await(); return createBookingRaw(userToken, ci, 1, null); };
        Future<Integer> fa = pool.submit(a);
        Future<Integer> fb = pool.submit(b);
        start.countDown();
        int sa = fa.get(30, TimeUnit.SECONDS);
        int sb = fb.get(30, TimeUnit.SECONDS);
        pool.shutdown();

        int created  = (sa == 201 ? 1 : 0) + (sb == 201 ? 1 : 0);
        int rejected = (sa == 422 ? 1 : 0) + (sb == 422 ? 1 : 0);
        assertEquals(1, created,  "exactly one of two concurrent bookings may hold the last room");
        assertEquals(1, rejected, "the other must be rejected for insufficient inventory");
        assertEquals(0, avail(ci), "availability lands at exactly zero, never negative (no oversell)");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ENDPOINTS — customer status + admin inspection
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerCanReadOwnReservationStatusOthersForbidden() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 2, 2);
        Long bookingId = createBooking(userToken, ci, 1);

        String body = mvc.perform(get("/api/bookings/" + bookingId + "/inventory-reservation")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("HELD", mapper.readTree(body).get("status").asText());
        assertEquals(bookingId.longValue(), mapper.readTree(body).get("bookingId").asLong());

        // A different customer cannot see this booking's hold.
        String otherToken = registerUser("res-other").get("token").asText();
        mvc.perform(get("/api/bookings/" + bookingId + "/inventory-reservation")
                .header("Authorization", "Bearer " + otherToken))
            .andExpect(status().isForbidden());

        // Admin can.
        mvc.perform(get("/api/bookings/" + bookingId + "/inventory-reservation")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
    }

    @Test
    void adminCanListAndInspectReservationsUserForbidden() throws Exception {
        LocalDate ci = nextWindow();
        seedNight(ci, 2, 2);
        Long bookingId = createBooking(userToken, ci, 1);

        mvc.perform(get("/api/admin/inventory-reservations?status=HELD&page=0&size=5")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray());

        String byBooking = mvc.perform(get("/api/admin/inventory-reservations/booking/" + bookingId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("HELD", mapper.readTree(byBooking).get("status").asText());

        mvc.perform(get("/api/admin/inventory-reservations")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    /** Reserves a unique far-future 1-night check-in date, 5-day spaced from any other test. */
    private LocalDate nextWindow() {
        return TODAY.plusDays(DAY.getAndAdd(5));
    }

    private void seedNight(LocalDate checkIn, int total, int available) throws Exception {
        String item = String.format(
            "{\"inventoryDate\":\"%s\",\"totalInventory\":%d,\"availableInventory\":%d,"
            + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
            + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
            checkIn, total, available);
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + item + "]}"))
            .andExpect(status().isOk());
    }

    private int avail(LocalDate date) {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date).orElseThrow()
            .getAvailableInventory();
    }

    private String resStatus(Long bookingId) {
        return reservationRepo.findByBookingId(bookingId).orElseThrow().getStatus().name();
    }

    private String bookingStatus(Long bookingId) throws Exception {
        String body = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + userToken))
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("status").asText();
    }

    private Long createBooking(String token, LocalDate ci, int nights) throws Exception {
        LocalDate co = ci.plusDays(nights);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    /** Booking attempt returning the raw HTTP status (for exhaustion / concurrency / rollback). */
    private int createBookingRaw(String token, LocalDate ci, int nights, String giftCardCode) throws Exception {
        LocalDate co = ci.plusDays(nights);
        String gc = giftCardCode == null ? "" : ",\"giftCardCode\":\"" + giftCardCode + "\"";
        return mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1%s}",
                    roomId, ci, co, gc)))
            .andReturn().getResponse().getStatus();
    }

    private Long createPaymentPending(String token, Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private void failPayment(String token, Long paymentId) throws Exception {
        mvc.perform(post("/api/payments/" + paymentId + "/mock-fail")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private void payAndSucceed(String token, Long bookingId) throws Exception {
        Long paymentId = createPaymentPending(token, bookingId);
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private JsonNode createSession(String token, Long bookingId) throws Exception {
        String body = mvc.perform(post("/api/payment-sessions")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"provider\":\"MOCK\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void callback(JsonNode session, CallbackOutcome outcome) throws Exception {
        String sessionId = session.get("sessionId").asText();
        String cbToken = session.get("callbackToken").asText();
        mvc.perform(post("/api/payment-sessions/" + sessionId + "/callback")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"callbackToken\":\"" + cbToken + "\",\"outcome\":\"" + outcome.name() + "\"}"))
            .andExpect(status().isOk());
    }

    private JsonNode registerUser(String namePrefix) throws Exception {
        String email = namePrefix + "-" + DAY.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }
}
