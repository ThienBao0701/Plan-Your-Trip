package com.example.planyourtrip;

import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
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

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class PricingEngineTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository roomRepo;

    private String adminToken;
    private Long firstRoomId;  // STD-TWIN, priceFrom=900,000
    private Long hotelDetailId;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"admin@planyourtrip.com\",\"password\":\"admin123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        adminToken = mapper.readTree(body).get("token").asText();

        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        hotelDetailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        firstRoomId   = roomRepo.findAllByHotelDetailId(hotelDetailId).get(0).getId();
    }

    // ═════════════════════════════════════════════════════════════════════════
    // PROMOTION CRUD
    // ═════════════════════════════════════════════════════════════════════════

    @Test
    void promotion_create_returns201() throws Exception {
        String body = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("Test Promo", "TESTCODE1", "GENERAL", "PERCENTAGE",
                    "10", null, null, null, false, 5, "2035-01-01", "2035-12-31")))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").isNumber())
            .andExpect(jsonPath("$.name").value("Test Promo"))
            .andExpect(jsonPath("$.code").value("TESTCODE1"))
            .andExpect(jsonPath("$.discountType").value("PERCENTAGE"))
            .andExpect(jsonPath("$.discountValue").value(10))
            .andExpect(jsonPath("$.active").value(true))
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("id").asLong() > 0);
    }

    @Test
    void promotion_list_includesSeedData() throws Exception {
        String body = mvc.perform(get("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode list = mapper.readTree(body);
        assertTrue(list.isArray());
        assertTrue(list.size() >= 5, "Should include at least 5 seeded promotions");

        // Verify "Summer Sale" is in the list
        boolean hasSummerSale = false;
        for (JsonNode p : list) {
            if ("Summer Sale".equals(p.get("name").asText())) { hasSummerSale = true; break; }
        }
        assertTrue(hasSummerSale, "Summer Sale seeded promotion must be present");
    }

    @Test
    void promotion_getById_returns200() throws Exception {
        String created = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("GetById Test", null, "HOTEL", "FIXED_AMOUNT",
                    "50000", null, null, null, false, 1, "2035-02-01", "2035-02-28")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long id = mapper.readTree(created).get("id").asLong();

        mvc.perform(get("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id))
            .andExpect(jsonPath("$.name").value("GetById Test"))
            .andExpect(jsonPath("$.discountType").value("FIXED_AMOUNT"));
    }

    @Test
    void promotion_update_returns200() throws Exception {
        String created = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("Original", null, "GENERAL", "PERCENTAGE",
                    "5", null, null, null, false, 1, "2035-03-01", "2035-03-31")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long id = mapper.readTree(created).get("id").asLong();

        mvc.perform(put("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("Updated Name", null, "MEMBER", "PERCENTAGE",
                    "12", null, null, null, true, 8, "2035-03-01", "2035-03-31")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.name").value("Updated Name"))
            .andExpect(jsonPath("$.promotionType").value("MEMBER"))
            .andExpect(jsonPath("$.discountValue").value(12))
            .andExpect(jsonPath("$.stackable").value(true))
            .andExpect(jsonPath("$.priority").value(8));
    }

    @Test
    void promotion_delete_returns204() throws Exception {
        String created = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("To Delete", null, "GENERAL", "PERCENTAGE",
                    "5", null, null, null, false, 1, "2035-04-01", "2035-04-30")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();

        Long id = mapper.readTree(created).get("id").asLong();

        mvc.perform(delete("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());

        mvc.perform(get("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());
    }

    @Test
    void promotion_invalidDates_returns400() throws Exception {
        mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("Bad Dates", null, "GENERAL", "PERCENTAGE",
                    "10", null, null, null, false, 1, "2035-12-31", "2035-01-01")))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void promotion_requiresAdminAuth() throws Exception {
        mvc.perform(post("/api/admin/promotions")
                .contentType(MediaType.APPLICATION_JSON)
                .content(promoPayload("Unauth", null, "GENERAL", "PERCENTAGE",
                    "10", null, null, null, false, 1, "2035-01-01", "2035-12-31")))
            .andExpect(status().isUnauthorized());
    }

    // ═════════════════════════════════════════════════════════════════════════
    // PRICING BREAKDOWN — Structure & Near-future dates (seeded data)
    // ═════════════════════════════════════════════════════════════════════════

    @Test
    void pricing_breakdown_returnsCorrectStructure() throws Exception {
        // STD-TWIN: priceFrom=900000, rate plan "Summer Deal" 800000 (covers next 30 days)
        // Weekend Special (priority=20, 15%) is highest-priority non-stackable → applied
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(4); // 3 nights

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.roomId").value(firstRoomId))
            .andExpect(jsonPath("$.nights").value(3))
            .andExpect(jsonPath("$.currency").value("VND"))
            .andExpect(jsonPath("$.basePrice").isNumber())
            .andExpect(jsonPath("$.finalPrice").isNumber())
            .andExpect(jsonPath("$.promotionDiscount").isNumber())
            .andExpect(jsonPath("$.appliedPromotions").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        double basePrice  = result.get("basePrice").asDouble();
        double finalPrice = result.get("finalPrice").asDouble();

        assertEquals(2700000.0, basePrice, 0.01, "basePrice = priceFrom * nights");
        assertTrue(finalPrice >= 0, "finalPrice must be non-negative");
        assertTrue(finalPrice <= basePrice, "finalPrice must not exceed basePrice");
    }

    @Test
    void pricing_ratePlanApplied_ratePlanPriceLessThanBase() throws Exception {
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(4);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        // Rate plan "Summer Deal" at 800000 < priceFrom 900000
        assertFalse(result.get("ratePlanPrice").isNull(), "ratePlanPrice must be present");
        double ratePlanPrice = result.get("ratePlanPrice").asDouble();
        double basePrice     = result.get("basePrice").asDouble();
        assertEquals(2400000.0, ratePlanPrice, 0.01);
        assertTrue(ratePlanPrice < basePrice, "ratePlanPrice < basePrice");
        assertEquals("Summer Deal", result.get("ratePlanName").asText());
    }

    @Test
    void pricing_seededPromotionApplied_discountsWorkingPrice() throws Exception {
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(4);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        JsonNode promos = result.get("appliedPromotions");
        assertTrue(promos.isArray());
        assertTrue(promos.size() >= 1, "At least one seeded promotion must apply");

        double discount = result.get("promotionDiscount").asDouble();
        assertTrue(discount > 0, "A seeded promotion must yield a positive discount");
    }

    @Test
    void pricing_publicEndpoint_noAuthRequired() throws Exception {
        LocalDate checkIn  = LocalDate.now().plusDays(1);
        LocalDate checkOut = LocalDate.now().plusDays(3);

        mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=" + checkIn + "&checkOut=" + checkOut))
            .andExpect(status().isOk()); // no auth header
    }

    @Test
    void pricing_pastCheckIn_returns400() throws Exception {
        String yesterday = LocalDate.now().minusDays(1).toString();
        String tomorrow  = LocalDate.now().plusDays(1).toString();

        mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=" + yesterday + "&checkOut=" + tomorrow))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void pricing_sameCheckInAndCheckOut_returns400() throws Exception {
        String date = LocalDate.now().plusDays(2).toString();

        mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=" + date + "&checkOut=" + date))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400));
    }

    @Test
    void pricing_nonExistentRoom_returns404() throws Exception {
        mvc.perform(get("/api/rooms/99999/pricing"
                + "?checkIn=" + LocalDate.now().plusDays(1)
                + "&checkOut=" + LocalDate.now().plusDays(3)))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404));
    }

    // ═════════════════════════════════════════════════════════════════════════
    // PRICING ENGINE BEHAVIOUR — Isolated far-future date ranges (2030)
    // No seeded promotions or rate plans apply in 2030.
    // workingPrice = basePrice = 900000 * nights for STD-TWIN.
    // ═════════════════════════════════════════════════════════════════════════

    @Test
    void pricing_expiredPromotion_ignored() throws Exception {
        // Expired: endDate 2030-03-10, stay starts 2030-03-15 → expired for this stay
        createPromo("Expired Deal", null, "GENERAL", "PERCENTAGE", "50",
            null, null, null, false, 100, "2030-01-01", "2030-03-10", null);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-03-15&checkOut=2030-03-18"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(0, result.get("appliedPromotions").size(),
            "Expired promotion must not be applied");
        assertEquals(0.0, result.get("promotionDiscount").asDouble(), 0.01);
    }

    @Test
    void pricing_inactivePromotion_ignored() throws Exception {
        // Inactive promotion in valid date range
        createPromo("Inactive Deal", null, "GENERAL", "PERCENTAGE", "50",
            null, null, null, false, 100, "2030-04-01", "2030-04-30", false);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-04-10&checkOut=2030-04-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(0, result.get("appliedPromotions").size(),
            "Inactive promotion must not be applied");
    }

    @Test
    void pricing_percentageDiscount_calculatedCorrectly() throws Exception {
        // workingPrice = 900000 * 3 = 2,700,000; 10% = 270,000; final = 2,430,000
        createPromo("Pct Test", null, "GENERAL", "PERCENTAGE", "10",
            null, null, null, false, 100, "2030-12-01", "2030-12-31", null);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-12-10&checkOut=2030-12-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(2700000.0, result.get("basePrice").asDouble(), 0.01);
        assertNull(result.get("ratePlanPrice").isNull() ? null : "notNull");
        assertEquals(270000.0, result.get("promotionDiscount").asDouble(), 0.01);
        assertEquals(2430000.0, result.get("finalPrice").asDouble(), 0.01);
        assertEquals(1, result.get("appliedPromotions").size());
        assertEquals("Pct Test", result.get("appliedPromotions").get(0).get("name").asText());
    }

    @Test
    void pricing_fixedAmountDiscount_calculatedCorrectly() throws Exception {
        // workingPrice = 2,700,000; fixed 100,000; final = 2,600,000
        createPromo("Fixed Test", null, "GENERAL", "FIXED_AMOUNT", "100000",
            null, null, null, false, 100, "2030-11-01", "2030-11-30", null);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-11-10&checkOut=2030-11-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(100000.0, result.get("promotionDiscount").asDouble(), 0.01);
        assertEquals(2600000.0, result.get("finalPrice").asDouble(), 0.01);
    }

    @Test
    void pricing_maxDiscountCap_applied() throws Exception {
        // 50% of 2,700,000 = 1,350,000 but capped at 50,000
        createPromo("Capped Pct", null, "GENERAL", "PERCENTAGE", "50",
            "50000", null, null, false, 100, "2030-10-01", "2030-10-31", null);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-10-10&checkOut=2030-10-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(50000.0, result.get("promotionDiscount").asDouble(), 0.01,
            "Discount must be capped at maxDiscountAmount");
        assertEquals(2650000.0, result.get("finalPrice").asDouble(), 0.01);
    }

    @Test
    void pricing_finalPrice_neverNegative() throws Exception {
        // FIXED_AMOUNT larger than total price → finalPrice = 0
        createPromo("Huge Discount", null, "GENERAL", "FIXED_AMOUNT", "999999999",
            null, null, null, false, 100, "2030-09-01", "2030-09-30", null);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-09-10&checkOut=2030-09-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(0.0, result.get("finalPrice").asDouble(), 0.01,
            "finalPrice must never go negative");
    }

    @Test
    void pricing_stackable_bothPromotionsApplied() throws Exception {
        // Two stackable promos → both discounts summed
        // 10% + 5% of 2,700,000 = 270,000 + 135,000 = 405,000; final = 2,295,000
        createPromoForRoom("Stack A", "GENERAL", "PERCENTAGE", "10",
            null, true, 100, "2030-06-01", "2030-06-30", firstRoomId);
        createPromoForRoom("Stack B", "GENERAL", "PERCENTAGE", "5",
            null, true, 90, "2030-06-01", "2030-06-30", firstRoomId);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-06-15&checkOut=2030-06-18"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(2, result.get("appliedPromotions").size(),
            "Both stackable promotions must be applied");

        // Determine actual working price (rate plan may override base price)
        double base = result.get("basePrice").asDouble();
        JsonNode rppNode = result.get("ratePlanPrice");
        double working = (rppNode == null || rppNode.isNull()) ? base : rppNode.asDouble();

        // Stack A = 10%, Stack B = 5% → total 15% of working price
        double expectedDiscount = working * 0.15;
        assertEquals(expectedDiscount, result.get("promotionDiscount").asDouble(), 1.0,
            "Stackable discounts must be summed (10% + 5%)");
        assertEquals(working - expectedDiscount, result.get("finalPrice").asDouble(), 1.0);
    }

    @Test
    void pricing_nonStackable_stopsAfterFirst() throws Exception {
        // Only the higher-priority non-stackable is applied; chain stops
        // Promo A (priority=100, 10%) applied → 270,000; Promo B (priority=90, 5%) skipped
        createPromoForRoom("NonStack A", "GENERAL", "PERCENTAGE", "10",
            null, false, 100, "2030-07-01", "2030-07-31", firstRoomId);
        createPromoForRoom("NonStack B", "GENERAL", "PERCENTAGE", "5",
            null, false, 90, "2030-07-01", "2030-07-31", firstRoomId);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-07-10&checkOut=2030-07-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(1, result.get("appliedPromotions").size(),
            "Non-stackable must stop after first match");
        assertEquals("NonStack A",
            result.get("appliedPromotions").get(0).get("name").asText());
        assertEquals(270000.0, result.get("promotionDiscount").asDouble(), 0.01);
        assertEquals(2430000.0, result.get("finalPrice").asDouble(), 0.01);
    }

    @Test
    void pricing_priority_higherAppliedFirst() throws Exception {
        // Promo Y (priority=100, 20%) vs Promo X (priority=50, 5%); non-stackable
        // Promo Y wins, 20% of 2,700,000 = 540,000
        createPromoForRoom("Priority Low",  "GENERAL", "PERCENTAGE", "5",
            null, false, 50, "2030-08-01", "2030-08-31", firstRoomId);
        createPromoForRoom("Priority High", "GENERAL", "PERCENTAGE", "20",
            null, false, 100, "2030-08-01", "2030-08-31", firstRoomId);

        String body = mvc.perform(get("/api/rooms/" + firstRoomId + "/pricing"
                + "?checkIn=2030-08-10&checkOut=2030-08-13"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode result = mapper.readTree(body);
        assertEquals(1, result.get("appliedPromotions").size(),
            "Non-stackable stops after highest-priority");
        assertEquals("Priority High",
            result.get("appliedPromotions").get(0).get("name").asText());
        assertEquals(540000.0, result.get("promotionDiscount").asDouble(), 0.01);
        assertEquals(2160000.0, result.get("finalPrice").asDouble(), 0.01);
    }

    // ═════════════════════════════════════════════════════════════════════════
    // Helpers
    // ═════════════════════════════════════════════════════════════════════════

    private String promoPayload(String name, String code, String type, String discountType,
                                 String discountValue, String maxDiscount, String minStay,
                                 String minSpend, boolean stackable, int priority,
                                 String startDate, String endDate) {
        String codeJson      = code != null ? "\"" + code + "\"" : "null";
        String maxDiscJson   = maxDiscount != null ? maxDiscount : "null";
        String minStayJson   = minStay != null ? minStay : "null";
        String minSpendJson  = minSpend != null ? minSpend : "null";
        return """
            {
              "name": "%s",
              "code": %s,
              "promotionType": "%s",
              "discountType": "%s",
              "discountValue": %s,
              "maxDiscountAmount": %s,
              "minimumStay": %s,
              "minimumSpend": %s,
              "stackable": %b,
              "priority": %d,
              "startDate": "%s",
              "endDate": "%s",
              "targetType": "ALL"
            }
            """.formatted(name, codeJson, type, discountType, discountValue,
                          maxDiscJson, minStayJson, minSpendJson, stackable, priority,
                          startDate, endDate);
    }

    private void createPromo(String name, String code, String type, String discountType,
                              String discountValue, String maxDiscount, String minStay,
                              String minSpend, boolean stackable, int priority,
                              String startDate, String endDate, Boolean active) throws Exception {
        String payload = promoPayload(name, code, type, discountType, discountValue,
            maxDiscount, minStay, minSpend, stackable, priority, startDate, endDate);
        // Inject active flag if specified
        if (active != null && !active) {
            payload = payload.replace("\"targetType\": \"ALL\"",
                "\"targetType\": \"ALL\", \"active\": false");
        }
        mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }

    private void createPromoForRoom(String name, String type, String discountType,
                                     String discountValue, String maxDiscount,
                                     boolean stackable, int priority,
                                     String startDate, String endDate, Long roomId) throws Exception {
        String payload = """
            {
              "name": "%s",
              "promotionType": "%s",
              "discountType": "%s",
              "discountValue": %s,
              "maxDiscountAmount": %s,
              "stackable": %b,
              "priority": %d,
              "startDate": "%s",
              "endDate": "%s",
              "targetType": "ROOM",
              "targetId": %d
            }
            """.formatted(name, type, discountType, discountValue,
                          maxDiscount != null ? maxDiscount : "null",
                          stackable, priority, startDate, endDate, roomId);
        mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated());
    }
}
