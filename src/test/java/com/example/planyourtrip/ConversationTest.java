package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * ConversationTest — Phase 6.6.
 * Every scenario provisions its own throwaway partner, hotel, hotel-detail, room,
 * guest and booking (never touching shared seed data or other test files' fixtures)
 * so tests stay isolated from each other and from other test classes sharing the
 * same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class ConversationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private LocalDate today;

    @BeforeEach
    void setup() {
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
        today              = LocalDate.now();
    }

    private record PartnerCtx(String token, Long profileId) {}
    private record ConvCtx(PartnerCtx partner, String guestToken, Long bookingId, Long conversationId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE / OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void user_createsConversationForOwnBooking() throws Exception {
        ConvCtx c = setupConversation("CreateConv");

        mvc.perform(get("/api/me/conversations/" + c.conversationId())
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.bookingId").value(c.bookingId()))
            .andExpect(jsonPath("$.status").value("OPEN"));
    }

    @Test
    void user_cannotCreateConversationForOtherUsersBooking() throws Exception {
        ConvCtx c = setupConversation("OtherUserBooking");
        String strangerGuestToken = registerGuest();

        mvc.perform(post("/api/me/conversations")
                .header("Authorization", "Bearer " + strangerGuestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + c.bookingId() + "}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void partner_listsConversationsForOwnedHotel() throws Exception {
        ConvCtx c = setupConversation("PartnerList");

        String body = mvc.perform(get("/api/partner/conversations")
                .header("Authorization", "Bearer " + c.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsId(mapper.readTree(body), c.conversationId()));
    }

    @Test
    void partner_cannotAccessAnotherPartnerConversation() throws Exception {
        ConvCtx c = setupConversation("PartnerOwnershipEnforced");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/conversations/" + c.conversationId())
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // MESSAGES
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void user_sendsMessage() throws Exception {
        ConvCtx c = setupConversation("UserSendsMessage");

        String body = mvc.perform(post("/api/me/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Hello, is early check-in possible?\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("USER", res.get("senderRole").asText());
        assertEquals("Hello, is early check-in possible?", res.get("body").asText());
    }

    @Test
    void partner_sendsMessage() throws Exception {
        ConvCtx c = setupConversation("PartnerSendsMessage");

        String body = mvc.perform(post("/api/partner/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Sure, early check-in is available.\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("PARTNER", mapper.readTree(body).get("senderRole").asText());
    }

    @Test
    void admin_sendsMessage() throws Exception {
        ConvCtx c = setupConversation("AdminSendsMessage");

        String body = mvc.perform(post("/api/admin/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"This is support checking in.\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("ADMIN", mapper.readTree(body).get("senderRole").asText());
    }

    @Test
    void messageBody_required() throws Exception {
        ConvCtx c = setupConversation("BodyRequired");

        mvc.perform(post("/api/me/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"\"}"))
            .andExpect(status().isBadRequest());
    }

    @Test
    void lastMessageAt_updates() throws Exception {
        ConvCtx c = setupConversation("LastMessageUpdates");

        String before = mvc.perform(get("/api/me/conversations/" + c.conversationId())
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(before).get("lastMessageAt").isNull());

        mvc.perform(post("/api/me/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"First message\"}"))
            .andExpect(status().isCreated());

        String after = mvc.perform(get("/api/me/conversations/" + c.conversationId())
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertFalse(mapper.readTree(after).get("lastMessageAt").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CLOSE / REOPEN
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void closeConversation() throws Exception {
        ConvCtx c = setupConversation("Close");

        String body = mvc.perform(patch("/api/me/conversations/" + c.conversationId() + "/close")
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("CLOSED", mapper.readTree(body).get("status").asText());
    }

    @Test
    void sendingMessage_reopensClosedConversation() throws Exception {
        ConvCtx c = setupConversation("Reopen");

        mvc.perform(patch("/api/me/conversations/" + c.conversationId() + "/close")
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk());

        mvc.perform(post("/api/partner/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Reopening with a reply\"}"))
            .andExpect(status().isCreated());

        String body = mvc.perform(get("/api/me/conversations/" + c.conversationId())
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("OPEN", mapper.readTree(body).get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // READ STATUS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void markRead_user() throws Exception {
        ConvCtx c = setupConversation("MarkReadUser");

        mvc.perform(post("/api/partner/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Message from host\"}"))
            .andExpect(status().isCreated());

        String body = mvc.perform(patch("/api/me/conversations/" + c.conversationId() + "/read")
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode messages = mapper.readTree(body).get("messages");
        for (JsonNode m : messages) assertTrue(m.get("readByUser").asBoolean());
    }

    @Test
    void markRead_partner() throws Exception {
        ConvCtx c = setupConversation("MarkReadPartner");

        mvc.perform(post("/api/me/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Message from guest\"}"))
            .andExpect(status().isCreated());

        String body = mvc.perform(patch("/api/partner/conversations/" + c.conversationId() + "/read")
                .header("Authorization", "Bearer " + c.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode messages = mapper.readTree(body).get("messages");
        for (JsonNode m : messages) assertTrue(m.get("readByPartner").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN ARCHIVE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_archive() throws Exception {
        ConvCtx c = setupConversation("AdminArchive");

        String body = mvc.perform(patch("/api/admin/conversations/" + c.conversationId() + "/archive")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals("ARCHIVED", mapper.readTree(body).get("status").asText());

        mvc.perform(post("/api/me/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Still there?\"}"))
            .andExpect(status().isUnprocessableEntity());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_partnerOnUserMessage() throws Exception {
        ConvCtx c = setupConversation("NotifyPartner");

        mvc.perform(post("/api/me/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.guestToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Hi there\"}"))
            .andExpect(status().isCreated());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + c.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "New message from guest"));
    }

    @Test
    void notification_userOnPartnerMessage() throws Exception {
        ConvCtx c = setupConversation("NotifyUser");

        mvc.perform(post("/api/partner/conversations/" + c.conversationId() + "/messages")
                .header("Authorization", "Bearer " + c.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"body\":\"Hi guest\"}"))
            .andExpect(status().isCreated());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + c.guestToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "New message from host"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/me/conversations"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private ConvCtx setupConversation(String prefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(prefix));
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        bulkCreateInventory(roomId, today.minusDays(2), 40);

        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, roomId, today.plusDays(5), today.plusDays(7));

        String body = mvc.perform(post("/api/me/conversations")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"bookingId\":" + bookingId + ",\"subject\":\"Question about my stay\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long conversationId = mapper.readTree(body).get("id").asLong();

        return new ConvCtx(partner, guestToken, bookingId, conversationId);
    }

    private Long createAndConfirmBooking(String guestToken, Long roomId, LocalDate ci, LocalDate co) throws Exception {
        String bookingBody = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + guestToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(String.format(
                    "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,\"numberOfRooms\":1}",
                    roomId, ci, co)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long bookingId = mapper.readTree(bookingBody).get("id").asLong();

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

    private String registerAndLogin(String fullName, String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + fullName + "\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerGuest() throws Exception {
        return registerAndLogin("Guest Tester", "conv-guest-" + counter.getAndIncrement() + "@test.com");
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-conv-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);

        String profileReq = """
                {"businessName":"Test Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(counter.get());
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        return new PartnerCtx(token, profileId);
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
                "{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10," +
                "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0," +
                "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}", d));
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

    private boolean containsId(JsonNode arr, Long id) {
        for (JsonNode n : arr) if (n.get("id").asLong() == id) return true;
        return false;
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
