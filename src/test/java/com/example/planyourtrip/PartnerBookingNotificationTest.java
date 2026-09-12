package com.example.planyourtrip;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Notification;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.RelatedEntityType;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.NotificationRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.service.NotificationService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doThrow;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D9 — partner booking notifications.
 *
 * <p>Scope, exactly as approved: the hotel's owning partner is notified on booking
 * <b>CREATE</b>, <b>MODIFY</b> and <b>CANCEL</b> — the three events Q156 names — and on nothing
 * else. Confirm, refund, complete, check-in, check-out, no-show and archive are deliberately
 * untouched.
 *
 * <p>Guarantees pinned here:
 * <ul>
 *   <li>exactly one partner notification per event, addressed to the profile-owning user;</li>
 *   <li>silence when there is nobody to tell — unassigned hotel, or a non-APPROVED owner;</li>
 *   <li>no cross-partner leakage;</li>
 *   <li>the customer's own notifications are unchanged;</li>
 *   <li>no duplication via {@code BookingStatusEngineService}, which owns a disjoint set of
 *       transitions;</li>
 *   <li><b>the booking still succeeds when the partner notification cannot be written</b> — the
 *       whole point of the {@code REQUIRES_NEW} + catch isolation.</li>
 * </ul>
 *
 * <p>Fixtures follow {@code PartnerBookingTest}: every scenario provisions its own throwaway
 * partner, hotel, room, inventory and guest, so nothing here depends on seeded data or on another
 * test class sharing the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerBookingNotificationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired NotificationRepository notificationRepo;
    @Autowired PartnerProfileRepository partnerProfileRepo;

    /** Spied so a notification write can be made to fail deterministically. */
    @MockitoSpyBean NotificationService notificationService;

    private static final AtomicInteger counter = new AtomicInteger(1);

    private String adminToken;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private LocalDate today;

    @BeforeEach
    void setup() {
        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId = locationRepo.findByCode("VT").orElseThrow().getId();
        today = LocalDate.now();
    }

    private record PartnerCtx(String token, Long profileId) {}
    private record OwnedHotelRoom(PartnerCtx partner, Long hotelId, Long roomId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE / MODIFY / CANCEL — the three approved events
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void create_notifiesTheOwningPartnerExactlyOnce() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Create");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();

        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        List<Notification> partnerRows = bookingNotificationsFor(ownerUserId, bookingId);
        assertEquals(1, partnerRows.size(), "exactly one partner notification for CREATE");

        Notification n = partnerRows.get(0);
        assertEquals(NotificationType.BOOKING, n.getNotificationType());
        assertEquals(RelatedEntityType.BOOKING, n.getRelatedEntityType());
        assertEquals(bookingId, n.getRelatedEntityId());
        assertEquals("New booking", n.getTitle());
        assertNotNull(n.getCreatedAt(), "createdAt is server-generated");
        assertFalse(n.isRead());
    }

    @Test
    void modify_notifiesTheOwningPartnerExactlyOnce() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Modify");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        modifyBooking(guest, bookingId, today.plusDays(14), today.plusDays(16));

        List<Notification> rows = bookingNotificationsFor(ownerUserId, bookingId);
        assertEquals(2, rows.size(), "CREATE + MODIFY, one each");
        assertEquals(1, rows.stream().filter(n -> "Booking modified".equals(n.getTitle())).count());
    }

    @Test
    void cancel_notifiesTheOwningPartnerExactlyOnce() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Cancel");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        cancelBooking(guest, bookingId);

        List<Notification> rows = bookingNotificationsFor(ownerUserId, bookingId);
        assertEquals(2, rows.size(), "CREATE + CANCEL, one each");
        assertEquals(1, rows.stream().filter(n -> "Booking cancelled".equals(n.getTitle())).count());
    }

    @Test
    void everyPartnerNotificationCarriesTheBookingTypeAndTarget() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Payload");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));
        modifyBooking(guest, bookingId, today.plusDays(14), today.plusDays(16));
        cancelBooking(guest, bookingId);

        List<Notification> rows = bookingNotificationsFor(ownerUserId, bookingId);
        assertEquals(3, rows.size());
        for (Notification n : rows) {
            assertEquals(NotificationType.BOOKING, n.getNotificationType(),
                "D9 uses BOOKING; no new type is invented");
            assertEquals(RelatedEntityType.BOOKING, n.getRelatedEntityType());
            assertEquals(bookingId, n.getRelatedEntityId());
            assertNotNull(n.getCreatedAt());
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP AND APPROVAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unassignedHotel_producesNoPartnerNotification() throws Exception {
        // A hotel with no owner assigned at all.
        Long hotelId = createHotelPlace(uniq("NoOwner"));
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        bulkCreateInventory(roomId, today.minusDays(2), 40);

        String guest = registerGuest();
        Long bookingId = createBooking(guest, roomId, today.plusDays(10), today.plusDays(12));

        // The booking exists and no BOOKING notification was written for it by anyone.
        // Scoped by type as well as target: `relatedEntityId` is only unique within a type,
        // so other domains can legitimately hold the same numeric id.
        assertNotNull(bookingId);
        List<Notification> bookingRows = notificationRepo.findAll().stream()
            .filter(n -> n.getNotificationType() == NotificationType.BOOKING)
            .filter(n -> bookingId.equals(n.getRelatedEntityId()))
            .toList();
        assertTrue(bookingRows.isEmpty(),
            "an unassigned hotel has nobody to notify, and CREATE notifies no customer either");
    }

    /**
     * A non-approved partner cannot become an owner in the first place:
     * {@code PartnerPropertyService.assignOwner} refuses anything but APPROVED with a 422. So
     * "DRAFT owner receives a booking notification" is unreachable by construction, and this
     * pins the guarantee that makes it so. The one reachable non-APPROVED state — suspension
     * after assignment — has its own test below.
     */
    @Test
    void aNonApprovedPartnerCannotOwnAHotelAtAll() throws Exception {
        PartnerCtx draft = createDraftPartner();
        Long hotelId = createHotelPlace(uniq("DraftOwner"));
        createHotelDetail(hotelId);

        mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + draft.profileId() + "}"))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void suspendedOwner_producesNoPartnerNotification() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Suspended");
        Long ownerUserId = ownerUserId(r);

        mvc.perform(post("/api/admin/partners/" + r.partner().profileId() + "/suspend")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"reason\":\"D9 test\"}"))
            .andExpect(status().isOk());

        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        assertTrue(bookingNotificationsFor(ownerUserId, bookingId).isEmpty(),
            "a SUSPENDED partner must not receive booking notifications");
    }

    @Test
    void anotherPartnerNeverReceivesSomeoneElsesBooking() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("Isolation");
        PartnerCtx stranger = createAndApprovePartner();
        Long strangerUserId = partnerProfileRepo.findById(stranger.profileId()).orElseThrow()
            .getUser().getId();

        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        assertEquals(1, bookingNotificationsFor(ownerUserId(r), bookingId).size());
        assertTrue(bookingNotificationsFor(strangerUserId, bookingId).isEmpty(),
            "no cross-partner leakage");
    }

    @Test
    void onlyTheProfileOwnerIsNotified_neverTeamMembers() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("TeamMember");
        Long ownerUserId = ownerUserId(r);

        // Invite a second account onto the partner team.
        String memberEmail = "d9-member-" + counter.getAndIncrement() + "@test.com";
        registerAndLogin(memberEmail, "Team Member");
        mvc.perform(post("/api/partner/team")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + memberEmail + "\",\"role\":\"MANAGER\"}"))
            .andExpect(status().isCreated());

        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        List<Notification> forBooking = notificationRepo.findAll().stream()
            .filter(n -> bookingId.equals(n.getRelatedEntityId()))
            .filter(n -> n.getNotificationType() == NotificationType.BOOKING)
            .toList();
        assertEquals(1, forBooking.size(), "one partner notification, not one per team member");
        assertEquals(ownerUserId, forBooking.get(0).getRecipientUser().getId());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CUSTOMER BEHAVIOUR AND DUPLICATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void customerNotificationsAreUnchanged() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CustomerIntact");
        String guest = registerGuest();
        Long guestUserId = meId(guest);
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        // CREATE still notifies no customer — Q151 is a separate follow-up, not D9.
        assertTrue(bookingNotificationsFor(guestUserId, bookingId).isEmpty(),
            "D9 must not add the customer CREATE notification");

        cancelBooking(guest, bookingId);
        List<Notification> guestRows = bookingNotificationsFor(guestUserId, bookingId);
        assertEquals(1, guestRows.size(), "the pre-existing customer cancel notification survives");
        assertEquals("Booking cancelled", guestRows.get(0).getTitle());
    }

    @Test
    void statusEngineTransitionsAddNoPartnerNotification() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("EngineDisjoint");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();
        Long bookingId = createAndConfirmBooking(guest, r.roomId(), today, today.plusDays(2));

        int afterConfirm = bookingNotificationsFor(ownerUserId, bookingId).size();

        // Drive the engine: CHECKED_IN → CHECKED_OUT → COMPLETED.
        partnerPatch(r, bookingId, "check-in");
        partnerPatch(r, bookingId, "check-out");
        partnerPatch(r, bookingId, "complete");

        assertEquals(afterConfirm, bookingNotificationsFor(ownerUserId, bookingId).size(),
            "the status engine owns a disjoint set of events and adds no partner notification");
    }

    @Test
    void repeatedCancelDoesNotDuplicate() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("RepeatCancel");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        cancelBooking(guest, bookingId);
        int after = bookingNotificationsFor(ownerUserId, bookingId).size();

        // A second cancel is refused by the state machine; nothing may be written.
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + guest)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cancelReason\":\"again\"}"))
            .andExpect(status().is4xxClientError());

        assertEquals(after, bookingNotificationsFor(ownerUserId, bookingId).size(),
            "a refused repeat writes nothing");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FAILURE ISOLATION — the booking must survive a failed notification
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void create_succeedsWhenThePartnerNotificationCannotBeWritten() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CreateFails");
        Long ownerUserId = ownerUserId(r);
        String guest = registerGuest();
        failPartnerNotifications();

        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));

        assertNotNull(bookingId, "the booking must be created regardless");
        mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + guest))
            .andExpect(status().isOk());
        assertTrue(bookingNotificationsFor(ownerUserId, bookingId).isEmpty(),
            "the notification genuinely did not land");
    }

    @Test
    void modify_succeedsWhenThePartnerNotificationCannotBeWritten() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ModifyFails");
        Long guestUserId;
        String guest = registerGuest();
        guestUserId = meId(guest);
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));
        failPartnerNotifications();

        modifyBooking(guest, bookingId, today.plusDays(14), today.plusDays(16));

        String body = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + guest))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(today.plusDays(14).toString(),
            mapper.readTree(body).get("checkIn").asText(),
            "the modification committed");
        // The customer's own notification joined the booking transaction and survived.
        assertEquals(1, bookingNotificationsFor(guestUserId, bookingId).stream()
            .filter(n -> "Booking modified".equals(n.getTitle())).count());
    }

    @Test
    void cancel_succeedsWhenThePartnerNotificationCannotBeWritten() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CancelFails");
        String guest = registerGuest();
        Long guestUserId = meId(guest);
        Long bookingId = createBooking(guest, r.roomId(), today.plusDays(10), today.plusDays(12));
        failPartnerNotifications();

        cancelBooking(guest, bookingId);

        String body = mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + guest))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("CANCELLED", mapper.readTree(body).get("status").asText());
        assertEquals(1, bookingNotificationsFor(guestUserId, bookingId).stream()
            .filter(n -> "Booking cancelled".equals(n.getTitle())).count(),
            "the customer notification is unaffected by the partner one failing");
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /** Makes every isolated (partner) notification write fail, leaving customer ones real. */
    private void failPartnerNotifications() {
        doThrow(new ApiException(HttpStatus.NOT_FOUND, "simulated notification failure"))
            .when(notificationService).createInNewTransaction(
                anyLong(), any(NotificationType.class), any(), anyString(), anyString(),
                any(), anyLong());
    }

    private Long ownerUserId(OwnedHotelRoom r) {
        return partnerProfileRepo.findById(r.partner().profileId()).orElseThrow()
            .getUser().getId();
    }

    private List<Notification> bookingNotificationsFor(Long userId, Long bookingId) {
        return notificationRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId).stream()
            .filter(n -> bookingId.equals(n.getRelatedEntityId()))
            .filter(n -> n.getNotificationType() == NotificationType.BOOKING)
            .toList();
    }

    private Long meId(String token) throws Exception {
        String body = mvc.perform(get("/api/me")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createBooking(String guestToken, Long roomId, LocalDate ci, LocalDate co)
            throws Exception {
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\","
                        + "\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private void modifyBooking(String guestToken, Long bookingId, LocalDate ci, LocalDate co)
            throws Exception {
        mvc.perform(patch("/api/bookings/" + bookingId + "/modify")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format("{\"checkIn\":\"%s\",\"checkOut\":\"%s\"}", ci, co)))
            .andExpect(status().isOk());
    }

    private void cancelBooking(String guestToken, Long bookingId) throws Exception {
        mvc.perform(patch("/api/bookings/" + bookingId + "/cancel")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"cancelReason\":\"D9 test\"}"))
            .andExpect(status().isOk());
    }

    private void partnerPatch(OwnedHotelRoom r, Long bookingId, String action) throws Exception {
        mvc.perform(patch("/api/partner/bookings/" + bookingId + "/" + action)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk());
    }

    private Long createAndConfirmBooking(String guestToken, Long roomId, LocalDate ci, LocalDate co)
            throws Exception {
        Long bookingId = createBooking(guestToken, roomId, ci, co);
        String paymentBody = mvc.perform(post("/api/payments")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"CASH\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long paymentId = mapper.readTree(paymentBody).get("id").asLong();
        mvc.perform(post("/api/payments/" + paymentId + "/mock-success")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isOk());
        return bookingId;
    }

    private OwnedHotelRoom setupOwnedHotelRoom(String namePrefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(namePrefix));
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        bulkCreateInventory(roomId, today.minusDays(2), 40);
        return new OwnedHotelRoom(partner, hotelId, roomId);
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerAndLogin(String email, String fullName) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + fullName + "\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerGuest() throws Exception {
        return registerAndLogin("d9-guest-" + counter.getAndIncrement() + "@test.com", "Guest Tester");
    }

    private PartnerCtx createDraftPartner() throws Exception {
        String email = "d9-partner-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email, "Partner Tester");
        String profileReq = """
                {"businessName":"D9 Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(counter.get());
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return new PartnerCtx(token, mapper.readTree(profileBody).get("id").asLong());
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        PartnerCtx draft = createDraftPartner();
        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + draft.token()))
            .andExpect(status().isOk());
        mvc.perform(post("/api/admin/partners/" + draft.profileId() + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());
        return draft;
    }

    private Long createHotelPlace(String name) throws Exception {
        String req = """
                {
                  "name": "%s",
                  "categoryId": %d,
                  "subcategoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "123 Test Street, Test City",
                  "priceLevel": 2,
                  "featured": false,
                  "verified": false,
                  "status": "DRAFT"
                }
                """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);
        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(resp).get("id").asLong();
        adminPatchStatus(id, "APPROVED");
        adminPatchStatus(id, "PUBLISHED");
        return id;
    }

    private void adminPatchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private void createHotelDetail(Long placeId) throws Exception {
        String req = """
                {
                  "placeId": %d,
                  "starRating": 4,
                  "checkInTime": "14:00:00",
                  "checkOutTime": "12:00:00",
                  "totalRooms": 10,
                  "availableRooms": 10,
                  "freeCancellation": false,
                  "prepaymentRequired": false,
                  "breakfastIncluded": false,
                  "airportShuttle": false
                }
                """.formatted(placeId);
        mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated());
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String req = """
                {
                  "placeId": %d,
                  "roomName": "Deluxe Room",
                  "roomCode": "%s",
                  "roomType": "DELUXE",
                  "bedType": "QUEEN",
                  "bedCount": 1,
                  "maxAdults": 2,
                  "maxChildren": 1,
                  "maxGuests": 3,
                  "roomSizeSqm": 25.0,
                  "floorNumber": 2,
                  "smokingAllowed": false,
                  "breakfastIncluded": true,
                  "freeCancellation": true,
                  "instantConfirmation": true,
                  "priceFrom": 500000,
                  "originalPrice": 600000,
                  "quantity": 10,
                  "availableQuantity": 10,
                  "active": true
                }
                """.formatted(placeId, roomCode);
        String resp = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void assignOwner(Long hotelId, Long partnerProfileId) throws Exception {
        mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + partnerProfileId + "}"))
            .andExpect(status().isOk());
    }

    private void bulkCreateInventory(Long roomId, LocalDate start, int days) throws Exception {
        StringBuilder items = new StringBuilder();
        for (int i = 0; i < days; i++) {
            if (i > 0) items.append(",");
            LocalDate d = start.plusDays(i);
            items.append(String.format(
                "{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10,"
                    + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
                    + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}", d));
        }
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + items + "]}"))
            .andExpect(status().isOk());
    }

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String uniqSuffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }
}
