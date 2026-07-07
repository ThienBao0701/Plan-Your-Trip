package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.PartnerProfileService;
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
 * PartnerExtranetTest — Phase 6.10.
 * Every scenario provisions its own throwaway partner, hotel, hotel-detail, room,
 * guest and booking (never touching shared seed data or other test files' fixtures)
 * so tests stay isolated from each other and from other test classes sharing the
 * same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerExtranetTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PartnerProfileRepository partnerProfileRepo;
    @Autowired UserRepository userRepo;
    @Autowired PartnerProfileService partnerProfileService;

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
    private record Scenario(PartnerCtx partner, String guestToken, Long hotelId, Long hotelDetailId,
                             Long roomId, Long bookingId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // HOME / MENU / ACCOUNT SUMMARY / ACTIVITY LOGS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void home_returnsSummary() throws Exception {
        Scenario s = setupBookingScenario("Home", 3, 5);

        String body = mvc.perform(get("/api/partner/extranet/home")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("profile"));
        assertEquals("APPROVED", res.get("verificationStatus").asText());
        assertTrue(res.get("ownedHotelCount").asLong() >= 1);
        assertTrue(res.get("activeRoomCount").asLong() >= 1);
        assertNotNull(res.get("financeSummary"));
        assertTrue(res.get("quickActions").isArray());
    }

    @Test
    void menu_returnsSections() throws Exception {
        Scenario s = setupBookingScenario("Menu", 3, 5);

        String body = mvc.perform(get("/api/partner/extranet/menu")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode sections = mapper.readTree(body).get("sections");
        assertEquals(13, sections.size());
        boolean hasSettings = false, hasMessages = false;
        for (JsonNode sec : sections) {
            if ("settings".equals(sec.get("key").asText())) hasSettings = true;
            if ("messages".equals(sec.get("key").asText())) hasMessages = true;
        }
        assertTrue(hasSettings);
        assertTrue(hasMessages);
    }

    @Test
    void accountSummary_works() throws Exception {
        Scenario s = setupBookingScenario("AccountSummary", 3, 5);

        String body = mvc.perform(get("/api/partner/extranet/account-summary")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertNotNull(res.get("profile"));
        assertNotNull(res.get("settings"));
        assertTrue(res.get("teamMemberCount").asInt() >= 0);
    }

    @Test
    void activityLogs_list() throws Exception {
        Scenario s = setupBookingScenario("ActivityList", 3, 5);
        updateBasicInfo(s);

        String body = mvc.perform(get("/api/partner/extranet/activity-logs")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ACTIVITY LOGGING HOOKS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void propertyUpdate_createsActivityLog() throws Exception {
        Scenario s = setupBookingScenario("PropertyLog", 3, 5);
        updateBasicInfo(s);

        assertTrue(containsAction(myActivityLogs(s.partner().token()), "PROPERTY_UPDATED"));
    }

    @Test
    void ratePlanUpdate_createsActivityLog() throws Exception {
        Scenario s = setupBookingScenario("RatePlanLog", 3, 5);
        Long ratePlanId = createRatePlan(s, "Standard", today.plusDays(10), today.plusDays(20));

        mvc.perform(put("/api/partner/rate-plans/" + ratePlanId)
                .header("Authorization", "Bearer " + s.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Updated Rate", today.plusDays(10), today.plusDays(20))))
            .andExpect(status().isOk());

        assertTrue(containsAction(myActivityLogs(s.partner().token()), "RATE_PLAN_UPDATED"));
    }

    @Test
    void promotionUpdate_createsActivityLog() throws Exception {
        Scenario s = setupBookingScenario("PromoLog", 3, 5);
        Long promoId = createHotelPromotion(s);

        mvc.perform(put("/api/partner/promotions/" + promoId)
                .header("Authorization", "Bearer " + s.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Updated Promo", "PROMO-" + uniqSuffix(), s.hotelDetailId())))
            .andExpect(status().isOk());

        assertTrue(containsAction(myActivityLogs(s.partner().token()), "PROMOTION_UPDATED"));
    }

    @Test
    void bookingStatusChange_createsActivityLog() throws Exception {
        Scenario s = setupBookingScenario("BookingStatusLog", 0, 2);

        mvc.perform(patch("/api/partner/bookings/" + s.bookingId() + "/check-in")
                .header("Authorization", "Bearer " + s.partner().token()))
            .andExpect(status().isOk());

        assertTrue(containsAction(myActivityLogs(s.partner().token()), "BOOKING_STATUS_CHANGED"));
    }

    @Test
    void payoutUpdate_createsActivityLog() throws Exception {
        Scenario s = setupBookingScenario("PayoutLog", 3, 5);
        putPayoutAccount(s.partner().token(), "1234567890123456");

        assertTrue(containsAction(myActivityLogs(s.partner().token()), "PAYOUT_ACCOUNT_UPDATED"));
    }

    @Test
    void teamMemberAdd_createsActivityLog() throws Exception {
        Scenario s = setupBookingScenario("TeamLog", 3, 5);
        String email = registerPlainUser("teammatelog");
        addTeamMember(s.partner().token(), email, "MANAGER");

        assertTrue(containsAction(myActivityLogs(s.partner().token()), "TEAM_MEMBER_ADDED"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN VISIBILITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_partnerDetail_works() throws Exception {
        Scenario s = setupBookingScenario("AdminDetail", 3, 5);

        String body = mvc.perform(get("/api/admin/partners/" + s.partner().profileId() + "/detail")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("APPROVED", res.get("verificationStatus").asText());
        assertTrue(res.get("ownedHotelCount").asLong() >= 1);
    }

    @Test
    void admin_canViewPartnerTeam() throws Exception {
        Scenario s = setupBookingScenario("AdminTeam", 3, 5);

        String body = mvc.perform(get("/api/admin/partners/" + s.partner().profileId() + "/team")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        boolean hasOwner = false;
        for (JsonNode n : arr) if ("OWNER".equals(n.get("role").asText())) hasOwner = true;
        assertTrue(hasOwner, "Approved partner must have an auto-created OWNER team member");
    }

    @Test
    void admin_canViewPartnerSettings() throws Exception {
        Scenario s = setupBookingScenario("AdminSettings", 3, 5);

        mvc.perform(get("/api/admin/partners/" + s.partner().profileId() + "/settings")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.defaultLanguage").exists());
    }

    @Test
    void admin_canViewPartnerActivityLogs() throws Exception {
        Scenario s = setupBookingScenario("AdminActivityLogs", 3, 5);
        updateBasicInfo(s);

        String body = mvc.perform(get("/api/admin/partners/" + s.partner().profileId() + "/activity-logs")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).size() >= 1);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTO OWNER TEAM MEMBER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void approve_createsOwnerTeamMember() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        String body = mvc.perform(get("/api/admin/partners/" + partner.profileId() + "/team")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        long ownerCount = 0;
        for (JsonNode n : arr) if ("OWNER".equals(n.get("role").asText())) ownerCount++;
        assertEquals(1, ownerCount);
    }

    @Test
    void approve_doesNotDuplicateOwnerTeamMember() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        // Reset to SUBMITTED directly to exercise a second adminApprove() call.
        PartnerProfile profile = partnerProfileRepo.findById(partner.profileId()).orElseThrow();
        profile.setVerificationStatus(PartnerVerificationStatus.SUBMITTED);
        partnerProfileRepo.save(profile);

        Long adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
        partnerProfileService.adminApprove(adminUserId, partner.profileId());

        String body = mvc.perform(get("/api/admin/partners/" + partner.profileId() + "/team")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        long ownerCount = 0;
        for (JsonNode n : arr) if ("OWNER".equals(n.get("role").asText())) ownerCount++;
        assertEquals(1, ownerCount, "Approving twice must not duplicate the OWNER team member");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/partner/extranet/home"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void nonApprovedPartner_rejected() throws Exception {
        String draftToken = createDraftPartnerToken();

        mvc.perform(get("/api/partner/extranet/home")
                .header("Authorization", "Bearer " + draftToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void ownershipEnforced_activityLogsAreScoped() throws Exception {
        Scenario a = setupBookingScenario("OwnA", 3, 5);
        Scenario b = setupBookingScenario("OwnB", 3, 5);
        updateBasicInfo(a);

        JsonNode logsForB = myActivityLogs(b.partner().token());
        assertEquals(0, logsForB.size(), "Partner B must not see partner A's activity log entries");

        mvc.perform(get("/api/admin/partners/999999/detail")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private Scenario setupBookingScenario(String prefix, int checkInOffset, int checkOutOffset) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(prefix));
        Long hotelDetailId = createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        bulkCreateInventory(roomId, today.minusDays(30), 60);

        String guestToken = registerGuest();
        Long bookingId = createAndConfirmBooking(guestToken, roomId,
            today.plusDays(checkInOffset), today.plusDays(checkOutOffset));

        return new Scenario(partner, guestToken, hotelId, hotelDetailId, roomId, bookingId);
    }

    private void updateBasicInfo(Scenario s) throws Exception {
        mvc.perform(put("/api/partner/hotels/" + s.hotelId())
                .header("Authorization", "Bearer " + s.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"name":"Updated Hotel Name","shortDescription":"New desc","description":"Longer desc",
                         "slug":"updated-slug-%s"}
                        """.formatted(uniqSuffix())))
            .andExpect(status().isOk());
    }

    private JsonNode myActivityLogs(String token) throws Exception {
        String body = mvc.perform(get("/api/partner/extranet/activity-logs")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private boolean containsAction(JsonNode arr, String action) {
        for (JsonNode n : arr) if (action.equals(n.get("action").asText())) return true;
        return false;
    }

    private Long createRatePlan(Scenario s, String rateName, LocalDate start, LocalDate end) throws Exception {
        String body = mvc.perform(post("/api/partner/rooms/" + s.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + s.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload(rateName, start, end)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String ratePlanPayload(String rateName, LocalDate start, LocalDate end) {
        return """
                {"rateName":"%s","rateType":"STANDARD","pricePerNight":400000,"startDate":"%s","endDate":"%s","active":true}
                """.formatted(rateName, start, end);
    }

    private Long createHotelPromotion(Scenario s) throws Exception {
        String body = mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + s.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Hotel Promo", "PROMO-" + uniqSuffix(), s.hotelDetailId())))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private String promotionPayload(String name, String code, Long hotelDetailId) {
        return """
                {"name":"%s","code":"%s","promotionType":"GENERAL","discountType":"PERCENTAGE","discountValue":10,
                 "minimumStay":1,"stackable":false,"priority":1,"startDate":"%s","endDate":"%s","active":true,
                 "targetType":"HOTEL","targetId":%d}
                """.formatted(name, code, today.minusDays(5), today.plusDays(30), hotelDetailId);
    }

    private String putPayoutAccount(String token, String accountNumber) throws Exception {
        return mvc.perform(put("/api/partner/payout-account")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"accountHolderName":"Test Holder","bankName":"Test Bank",
                         "bankAccountNumber":"%s","payoutMethod":"BANK_TRANSFER"}
                        """.formatted(accountNumber)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
    }

    private String addTeamMember(String ownerToken, String email, String role) throws Exception {
        return mvc.perform(post("/api/partner/team")
                .header("Authorization", "Bearer " + ownerToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"role\":\"" + role + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
    }

    private String registerPlainUser(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated());
        return email;
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
        return registerAndLogin("Guest Tester", "extranet-guest-" + counter.getAndIncrement() + "@test.com");
    }

    private String createDraftPartnerToken() throws Exception {
        String email = "partner-extranet-draft-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin("Partner Tester", email);
        String profileReq = """
                {"businessName":"Draft Hotel Co","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """;
        mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk());
        return token;
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-extranet-" + counter.getAndIncrement() + "@test.com";
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

    private Long createHotelDetail(Long placeId) throws Exception {
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
        String resp = mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
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
}
