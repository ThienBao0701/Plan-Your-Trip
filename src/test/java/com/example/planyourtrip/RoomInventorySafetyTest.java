package com.example.planyourtrip;

import com.example.planyourtrip.dto.RoomInventoryDto.RoomInventoryRequest;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import com.example.planyourtrip.service.RoomInventoryService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * H-FIX 1 — room-inventory write safety.
 *
 * <p>Covers the three defects H proved live against the running backend:
 * <ol>
 *   <li>the numeric write path took no lock while the booking path held a pessimistic one, so a
 *       partner save could silently erase a booking's decrement;</li>
 *   <li>{@code soldInventory} — authoritative booking state — was freely partner-writable;</li>
 *   <li>the counters were only bounded individually, so {@code total=20} with all four counters at
 *       {@code 20} (sum 80) was accepted.</li>
 * </ol>
 *
 * <p>Dates are far past the 90-day seed window so nothing here can disturb seeded inventory.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RoomInventorySafetyTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired RoomInventoryService inventoryService;
    @Autowired TransactionTemplate txTemplate;

    private String adminToken;
    private String partnerToken;
    private Long roomId;

    /** Well clear of the seeded window (today + 90 days) and of the other suites' far dates. */
    private static final LocalDate SAFE_DATE = LocalDate.of(2031, 3, 10);

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        partnerToken = login("partner@planyourtrip.com", "partner123456");

        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        roomId = hotelRoomRepo.findAllByHotelDetailId(detailId).get(0).getId();

        // Deterministic starting point: total 20 = available 18 + sold 0 + blocked 1 + maintenance 1.
        inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, SAFE_DATE)
            .ifPresent(inventoryRepo::delete);
        inventoryService.create(roomId, req(SAFE_DATE, 20, 18, 1, 0, 1));
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private static RoomInventoryRequest req(LocalDate date, int total, int available,
                                            int blocked, int sold, int maintenance) {
        return new RoomInventoryRequest(date, total, available, blocked, sold, maintenance,
            false, false, false);
    }

    // ─── H-FIX 1C: the sum invariant ──────────────────────────────────────────

    @Test
    void overAllocation_isRejected() {
        // The exact payload H proved was accepted live: every counter at total, sum 80 of total 20.
        ApiException ex = assertThrows(ApiException.class, () -> inventoryService.update(
            roomId, SAFE_DATE, req(SAFE_DATE, 20, 20, 20, 20, 20)));
        assertEquals(HttpStatus.BAD_REQUEST, ex.status());
        assertTrue(ex.getMessage().contains("must not exceed totalInventory"),
            "Expected the over-allocation rule to be named in the message, got: " + ex.getMessage());
    }

    @Test
    void overAllocationByOne_isRejected() {
        // 11 + 5 + 3 + 2 = 21 against a total of 20 — one unit of oversell.
        ApiException ex = assertThrows(ApiException.class, () -> inventoryService.update(
            roomId, SAFE_DATE, req(SAFE_DATE, 20, 11, 3, 5, 2), RoomInventoryService.Authority.ADMIN));
        assertEquals(HttpStatus.BAD_REQUEST, ex.status());
        assertTrue(ex.getMessage().contains("must not exceed totalInventory"));
    }

    /**
     * Under-allocation stays legal: provisioning writes nights such as {@code total=3, available=1}
     * with the remaining units unaccounted. That is the existing domain behaviour, so {@code <=} is
     * the correct bound — see {@code RoomInventoryService.validateCounts}.
     */
    @Test
    void underAllocation_isAccepted() {
        var res = inventoryService.update(roomId, SAFE_DATE, req(SAFE_DATE, 20, 1, 0, 0, 0));
        assertEquals(20, res.totalInventory());
        assertEquals(1, res.availableInventory());
    }

    @Test
    void exactAllocation_isAccepted() {
        var res = inventoryService.update(roomId, SAFE_DATE, req(SAFE_DATE, 30, 25, 2, 1, 2));
        assertEquals(30, res.totalInventory());
        assertEquals(25, res.availableInventory());
        assertEquals(1, res.soldInventory());
        assertEquals(30, res.availableInventory() + res.soldInventory()
            + res.blockedInventory() + res.maintenanceInventory());
    }

    @Test
    void individualBounds_stillRejectFieldGreaterThanTotal() {
        ApiException ex = assertThrows(ApiException.class, () -> inventoryService.update(
            roomId, SAFE_DATE, req(SAFE_DATE, 10, 15, 0, 0, 0)));
        assertEquals(HttpStatus.BAD_REQUEST, ex.status());
        assertTrue(ex.getMessage().contains("availableInventory exceeds totalInventory"));
    }

    @Test
    void negativeCounts_areRejectedByBeanValidation() throws Exception {
        // @Min(0) on the request record — surfaces as 400 through the controller layer.
        mvc.perform(put("/api/admin/rooms/" + roomId + "/inventory/" + SAFE_DATE)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"inventoryDate":"%s","totalInventory":20,"availableInventory":-5,
                     "blockedInventory":1,"soldInventory":0,"maintenanceInventory":1,
                     "stopSell":false,"closedArrival":false,"closedDeparture":false}
                    """.formatted(SAFE_DATE)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    // ─── H-FIX 1B: soldInventory authority ────────────────────────────────────

    @Test
    void partnerWrite_cannotChangeSoldInventory() {
        setSold(3);   // as if a booking had taken 3 units

        ApiException ex = assertThrows(ApiException.class, () -> inventoryService.update(
            roomId, SAFE_DATE, req(SAFE_DATE, 20, 16, 1, 0, 1),   // claims sold = 0
            RoomInventoryService.Authority.PARTNER));

        assertEquals(HttpStatus.CONFLICT, ex.status());
        assertTrue(ex.getMessage().contains("derived from bookings"));
        assertEquals(3, current().getSoldInventory(), "sold must be untouched by the rejected write");
    }

    @Test
    void partnerWrite_succeedsWhenEchoingCurrentSold() {
        setSold(3);
        var res = inventoryService.update(roomId, SAFE_DATE, req(SAFE_DATE, 20, 15, 1, 3, 1),
            RoomInventoryService.Authority.PARTNER);
        assertEquals(3, res.soldInventory());
        assertEquals(15, res.availableInventory());
    }

    @Test
    void adminWrite_mayStillCorrectSoldInventory() {
        setSold(3);
        var res = inventoryService.update(roomId, SAFE_DATE, req(SAFE_DATE, 20, 18, 1, 0, 1),
            RoomInventoryService.Authority.ADMIN);
        assertEquals(0, res.soldInventory(), "admin remains able to correct sold");
    }

    @Test
    void partnerBulkUpsert_cannotChangeSoldInventory() {
        setSold(2);
        var body = new com.example.planyourtrip.dto.RoomInventoryDto.BulkInventoryRequest(
            List.of(req(SAFE_DATE, 20, 17, 1, 0, 1)));
        ApiException ex = assertThrows(ApiException.class, () -> inventoryService.bulkUpsert(
            roomId, body, RoomInventoryService.Authority.PARTNER));
        assertEquals(HttpStatus.CONFLICT, ex.status());
        assertEquals(2, current().getSoldInventory());
    }

    @Test
    void partnerBulkUpsert_mayCreateNewRowWithZeroSold() {
        LocalDate fresh = SAFE_DATE.plusDays(5);
        inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, fresh).ifPresent(inventoryRepo::delete);
        var body = new com.example.planyourtrip.dto.RoomInventoryDto.BulkInventoryRequest(
            List.of(req(fresh, 12, 10, 1, 0, 1)));
        var res = inventoryService.bulkUpsert(roomId, body, RoomInventoryService.Authority.PARTNER);
        assertEquals(1, res.size());
        assertEquals(0, res.get(0).soldInventory());
        inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, fresh).ifPresent(inventoryRepo::delete);
    }

    // ─── H-FIX 1A: concurrency ────────────────────────────────────────────────

    /**
     * The lost update H proved. Two transactions touch the same night: one simulates the booking path
     * (lock, then the same bulk decrement {@code BookingService} issues), the other is a partner save
     * built from a snapshot read <em>before</em> the booking ran.
     *
     * <p>The partner write now takes the same row lock, so it cannot interleave; and because it
     * carries a stale {@code soldInventory} it is rejected outright rather than committing a total
     * that erases the sale. Either way the booking's decrement must survive.
     */
    @Test
    void concurrentBookingDecrementAndPartnerWrite_doesNotLoseTheBooking() throws Exception {
        RoomInventory before = current();
        assertEquals(0, before.getSoldInventory());

        CountDownLatch bookingCommitted = new CountDownLatch(1);
        AtomicReference<Throwable> partnerFailure = new AtomicReference<>();

        Thread booking = new Thread(() -> txTemplate.executeWithoutResult(s -> {
            inventoryRepo.lockForUpdate(roomId, SAFE_DATE, SAFE_DATE.plusDays(1));
            inventoryRepo.decrementInventory(roomId, SAFE_DATE, SAFE_DATE.plusDays(1), 2);
        }));
        booking.start();
        booking.join(10_000);
        bookingCommitted.countDown();

        // Partner submits the snapshot it read before the booking landed.
        Thread partner = new Thread(() -> {
            try {
                bookingCommitted.await(10, TimeUnit.SECONDS);
                txTemplate.executeWithoutResult(s -> inventoryService.update(
                    roomId, SAFE_DATE,
                    req(SAFE_DATE, 20, before.getAvailableInventory(), 1,
                        before.getSoldInventory(), 1),
                    RoomInventoryService.Authority.PARTNER));
            } catch (Throwable t) {
                partnerFailure.set(t);
            }
        });
        partner.start();
        partner.join(10_000);

        RoomInventory after = current();
        assertEquals(2, after.getSoldInventory(),
            "the booking's decrement must survive the concurrent partner write");
        assertEquals(16, after.getAvailableInventory());
        assertTrue(after.getAvailableInventory() + after.getSoldInventory()
                + after.getBlockedInventory() + after.getMaintenanceInventory()
                <= after.getTotalInventory(),
            "the room must not be over-allocated after concurrent writes");
        assertNotNull(partnerFailure.get(), "the stale partner write must be rejected, not silently applied");
    }

    /** Two partner saves of the same night serialize on the row lock and both leave a valid row. */
    @Test
    void concurrentPartnerWrites_bothLeaveAConsistentRow() throws Exception {
        Thread a = new Thread(() -> txTemplate.executeWithoutResult(s -> inventoryService.update(
            roomId, SAFE_DATE, req(SAFE_DATE, 20, 17, 2, 0, 1),
            RoomInventoryService.Authority.PARTNER)));
        Thread b = new Thread(() -> txTemplate.executeWithoutResult(s -> inventoryService.update(
            roomId, SAFE_DATE, req(SAFE_DATE, 20, 16, 2, 0, 2),
            RoomInventoryService.Authority.PARTNER)));
        a.start(); b.start();
        a.join(10_000); b.join(10_000);

        RoomInventory after = current();
        assertTrue(after.getAvailableInventory() + after.getSoldInventory()
                + after.getBlockedInventory() + after.getMaintenanceInventory()
                <= after.getTotalInventory(),
            "whichever write won, the row must not over-allocate total");
        assertEquals(0, after.getSoldInventory(), "neither partner write may invent sold units");
    }

    // ─── helpers ──────────────────────────────────────────────────────────────

    private RoomInventory current() {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, SAFE_DATE).orElseThrow();
    }

    /** Moves units available→sold exactly as the booking path does, keeping the partition valid. */
    private void setSold(int sold) {
        txTemplate.executeWithoutResult(s ->
            inventoryRepo.decrementInventory(roomId, SAFE_DATE, SAFE_DATE.plusDays(1), sold));
    }
}
