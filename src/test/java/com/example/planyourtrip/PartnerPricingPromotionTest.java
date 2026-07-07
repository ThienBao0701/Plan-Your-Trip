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

import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerPricingPromotionTest — Phase 6.4.
 * Every scenario provisions its own throwaway partner, hotel, hotel-detail and room
 * (never touching the shared seeded Grand Palace Hotel) so tests stay isolated from
 * each other and from other test classes sharing the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerPricingPromotionTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;

    @BeforeEach
    void setup() {
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    private record PartnerCtx(String token, Long profileId) {}
    private record OwnedHotelRoom(PartnerCtx partner, Long hotelId, Long hotelDetailId, Long roomId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // RATE PLANS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_listsOwnRoomRatePlans() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ListRatePlans");
        createRatePlan(r, "Standard", "2030-06-01", "2030-06-10");

        String body = mvc.perform(get("/api/partner/rooms/" + r.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
    }

    @Test
    void partner_createsRatePlanForOwnRoom() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CreateRatePlan");

        String body = mvc.perform(post("/api/partner/rooms/" + r.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Peak Season", "STANDARD", 500000, "2030-07-01", "2030-07-10")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Peak Season", mapper.readTree(body).get("rateName").asText());
        assertEquals(r.roomId(), mapper.readTree(body).get("roomId").asLong());
    }

    @Test
    void partner_cannotCreateRatePlanForAnotherPartnersRoom() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CreateRatePlanOther");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(post("/api/partner/rooms/" + r.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + stranger.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Hijacked", "STANDARD", 500000, "2030-07-01", "2030-07-10")))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_updatesOwnRatePlan() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UpdateRatePlan");
        Long ratePlanId = createRatePlan(r, "Standard", "2030-06-01", "2030-06-10");

        String body = mvc.perform(put("/api/partner/rate-plans/" + ratePlanId)
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Updated Rate", "PROMOTIONAL", 450000, "2030-06-01", "2030-06-15")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Updated Rate", mapper.readTree(body).get("rateName").asText());
        assertEquals(450000, mapper.readTree(body).get("pricePerNight").asDouble());
    }

    @Test
    void partner_cannotUpdateAnotherPartnersRatePlan() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UpdateRatePlanOther");
        Long ratePlanId = createRatePlan(r, "Standard", "2030-06-01", "2030-06-10");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(put("/api/partner/rate-plans/" + ratePlanId)
                .header("Authorization", "Bearer " + stranger.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload("Hijacked Rate", "STANDARD", 100, "2030-06-01", "2030-06-10")))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_deletesOwnRatePlan() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("DeleteRatePlan");
        Long ratePlanId = createRatePlan(r, "ToDelete", "2030-06-01", "2030-06-10");

        mvc.perform(delete("/api/partner/rate-plans/" + ratePlanId)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/partner/rooms/" + r.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[?(@.id == " + ratePlanId + ")]").doesNotExist());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PRICING PREVIEW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_pricingPreviewWorks() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("PricingPreview");

        String body = mvc.perform(get("/api/partner/rooms/" + r.roomId() + "/pricing-preview")
                .param("checkIn", "2030-12-01")
                .param("checkOut", "2030-12-03")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(r.roomId(), res.get("roomId").asLong());
        assertEquals(2, res.get("nights").asInt());
        assertNotNull(res.get("finalPrice"));
    }

    @Test
    void partner_cannotPreviewAnotherPartnersRoomPricing() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("PricingPreviewOther");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/rooms/" + r.roomId() + "/pricing-preview")
                .param("checkIn", "2030-12-01")
                .param("checkOut", "2030-12-03")
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PROMOTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_listsOwnPromotions() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("ListPromotions");
        createHotelPromotion(r, "PROMO-" + uniqSuffix());

        String body = mvc.perform(get("/api/partner/promotions")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        assertTrue(arr.size() >= 1);
    }

    @Test
    void partner_createsHotelPromotionForOwnHotel() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CreateHotelPromo");

        String body = mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Hotel Deal", "PROMO-" + uniqSuffix(), "HOTEL",
                    r.hotelDetailId(), "2030-06-01", "2030-06-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("HOTEL", mapper.readTree(body).get("targetType").asText());
        assertEquals(r.hotelDetailId(), mapper.readTree(body).get("targetId").asLong());
    }

    @Test
    void partner_createsRoomPromotionForOwnRoom() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CreateRoomPromo");

        String body = mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Room Deal", "PROMO-" + uniqSuffix(), "ROOM",
                    r.roomId(), "2030-06-01", "2030-06-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        assertEquals("ROOM", mapper.readTree(body).get("targetType").asText());
        assertEquals(r.roomId(), mapper.readTree(body).get("targetId").asLong());
    }

    @Test
    void partner_cannotCreateGlobalAllPromotion() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("CreateAllPromo");

        mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Global Deal", "PROMO-" + uniqSuffix(), "ALL",
                    null, "2030-06-01", "2030-06-30")))
            .andExpect(status().isForbidden());
    }

    @Test
    void partner_cannotTargetAnotherPartnersHotel() throws Exception {
        OwnedHotelRoom mine = setupOwnedHotelRoom("TargetOtherHotelMine");
        OwnedHotelRoom other = setupOwnedHotelRoom("TargetOtherHotelTheirs");

        mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + mine.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Sneaky Deal", "PROMO-" + uniqSuffix(), "HOTEL",
                    other.hotelDetailId(), "2030-06-01", "2030-06-30")))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_cannotTargetAnotherPartnersRoom() throws Exception {
        OwnedHotelRoom mine = setupOwnedHotelRoom("TargetOtherRoomMine");
        OwnedHotelRoom other = setupOwnedHotelRoom("TargetOtherRoomTheirs");

        mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + mine.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Sneaky Room Deal", "PROMO-" + uniqSuffix(), "ROOM",
                    other.roomId(), "2030-06-01", "2030-06-30")))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_updatesOwnPromotion() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UpdatePromo");
        Long promoId = createHotelPromotion(r, "PROMO-" + uniqSuffix());

        String body = mvc.perform(put("/api/partner/promotions/" + promoId)
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Updated Deal", "PROMO-" + uniqSuffix(), "HOTEL",
                    r.hotelDetailId(), "2030-06-01", "2030-06-30")))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertEquals("Updated Deal", mapper.readTree(body).get("name").asText());
    }

    @Test
    void partner_cannotUpdateAnotherPartnersPromotion() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("UpdatePromoOther");
        Long promoId = createHotelPromotion(r, "PROMO-" + uniqSuffix());
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(put("/api/partner/promotions/" + promoId)
                .header("Authorization", "Bearer " + stranger.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Hijacked Deal", "PROMO-" + uniqSuffix(), "HOTEL",
                    r.hotelDetailId(), "2030-06-01", "2030-06-30")))
            .andExpect(status().isNotFound());
    }

    @Test
    void partner_deletesOwnPromotion() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("DeletePromo");
        Long promoId = createHotelPromotion(r, "PROMO-" + uniqSuffix());

        mvc.perform(delete("/api/partner/promotions/" + promoId)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/partner/promotions/" + promoId)
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH / APPROVAL
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonApprovedPartner_rejected() throws Exception {
        String draftToken = createDraftPartnerToken();

        mvc.perform(get("/api/partner/promotions")
                .header("Authorization", "Bearer " + draftToken))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticated_rejected() throws Exception {
        mvc.perform(get("/api/partner/promotions"))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void notification_createdForRatePlanUpdate() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("RatePlanNotify");
        createRatePlan(r, "Notify Rate", "2030-06-01", "2030-06-10");

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsTitle(mapper.readTree(body), "Rate plan updated"));
    }

    @Test
    void notification_createdForPromotionUpdate() throws Exception {
        OwnedHotelRoom r = setupOwnedHotelRoom("PromoNotify");
        createHotelPromotion(r, "PROMO-" + uniqSuffix());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + r.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(containsTitle(mapper.readTree(body), "Promotion updated"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private OwnedHotelRoom setupOwnedHotelRoom(String namePrefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(namePrefix));
        Long hotelDetailId = createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniqSuffix());
        assignOwner(hotelId, partner.profileId());
        return new OwnedHotelRoom(partner, hotelId, hotelDetailId, roomId);
    }

    private Long createRatePlan(OwnedHotelRoom r, String rateName, String start, String end) throws Exception {
        String body = mvc.perform(post("/api/partner/rooms/" + r.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlanPayload(rateName, "STANDARD", 400000, start, end)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private Long createHotelPromotion(OwnedHotelRoom r, String code) throws Exception {
        String body = mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + r.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(promotionPayload("Hotel Promo", code, "HOTEL", r.hotelDetailId(),
                    "2030-06-01", "2030-06-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
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

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Partner Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String createDraftPartnerToken() throws Exception {
        String email = "partner-pricing-draft-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);
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
        String email = "partner-pricing-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);

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

    private String ratePlanPayload(String rateName, String rateType, double price, String start, String end) {
        return """
                {"rateName":"%s","rateType":"%s","pricePerNight":%s,"startDate":"%s","endDate":"%s","active":true}
                """.formatted(rateName, rateType, price, start, end);
    }

    private String promotionPayload(String name, String code, String targetType, Long targetId,
                                     String start, String end) {
        String targetIdJson = targetId != null ? String.valueOf(targetId) : "null";
        return """
                {"name":"%s","code":"%s","promotionType":"GENERAL","discountType":"PERCENTAGE","discountValue":10,
                 "minimumStay":1,"stackable":false,"priority":1,"startDate":"%s","endDate":"%s","active":true,
                 "targetType":"%s","targetId":%s}
                """.formatted(name, code, start, end, targetType, targetIdJson);
    }

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String uniqSuffix() {
        return UUID.randomUUID().toString().substring(0, 8);
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
