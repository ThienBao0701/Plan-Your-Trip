package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
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
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.29 — Advanced Rate Plans & Pricing Rules.
 *
 * <p>Provisions isolated partner/hotel/rooms per scenario (never mutating the shared
 * seeded Grand Palace Hotel except for the read-only backward-compat + seed checks), and
 * exercises: advanced plan CRUD & validation, eligibility rules, derived plans, occupancy /
 * child / extra-bed pricing, cancellation preview, booking snapshot, ownership/security,
 * seed data and backward-compatibility of the untouched pricing/availability engines.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdvancedRatePlanTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository roomRepo;

    private String adminToken;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private Long stdTwinRoomId;
    private static final AtomicInteger counter = new AtomicInteger(1);

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = roomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode())).findFirst().orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1–3. CRUD + code uniqueness
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario01_createAdvancedRatePlan() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("Advanced Flex", "ADV-1");
        p.put("mealPlanType", "BREAKFAST");
        p.put("cancellationPolicyType", "FREE_CANCELLATION");
        p.put("cancellationDeadlineHours", 48);
        p.put("priority", 7);
        p.put("minStayNights", 2);
        p.put("occupancyPricingEnabled", true);

        mvc.perform(adminPost("/api/admin/rooms/" + roomId + "/rate-plans", p))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.code").value("ADV-1"))
            .andExpect(jsonPath("$.rateName").value("Advanced Flex"))
            .andExpect(jsonPath("$.mealPlanType").value("BREAKFAST"))
            .andExpect(jsonPath("$.cancellationPolicyType").value("FREE_CANCELLATION"))
            .andExpect(jsonPath("$.sourceType").value("BASE"))
            .andExpect(jsonPath("$.priority").value(7))
            .andExpect(jsonPath("$.minStayNights").value(2))
            .andExpect(jsonPath("$.occupancyPricingEnabled").value(true));
    }

    @Test
    void scenario02_duplicateCodeRejectedPerRoom() throws Exception {
        Long roomId = provisionRoom();
        mvc.perform(adminPost("/api/admin/rooms/" + roomId + "/rate-plans", basePlan("First", "DUP")))
            .andExpect(status().isCreated());
        mvc.perform(adminPost("/api/admin/rooms/" + roomId + "/rate-plans", basePlan("Second", "DUP")))
            .andExpect(status().isConflict());
    }

    @Test
    void scenario03_sameCodeAllowedOnAnotherRoom() throws Exception {
        Long room1 = provisionRoom();
        Long room2 = provisionRoom();
        mvc.perform(adminPost("/api/admin/rooms/" + room1 + "/rate-plans", basePlan("A", "SHARED")))
            .andExpect(status().isCreated());
        mvc.perform(adminPost("/api/admin/rooms/" + room2 + "/rate-plans", basePlan("B", "SHARED")))
            .andExpect(status().isCreated());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 4–9. Stay / advance / closed eligibility
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario04_minimumStayEnforced() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("MinStay", "MINSTAY");
        p.put("minStayNights", 3);
        Long planId = createPlanReturnId(roomId, p);
        JsonNode b = previewJson(roomId, planId, today(2), today(3), 2, 0, 0); // 1 night
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").asText().toLowerCase().contains("minimum stay"));
    }

    @Test
    void scenario05_maximumStayEnforced() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("MaxStay", "MAXSTAY");
        p.put("maxStayNights", 2);
        Long planId = createPlanReturnId(roomId, p);
        JsonNode b = previewJson(roomId, planId, today(2), today(6), 2, 0, 0); // 4 nights
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").asText().toLowerCase().contains("maximum stay"));
    }

    @Test
    void scenario06_advanceBookingMinimumEnforced() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("AdvMin", "ADVMIN");
        p.put("minAdvanceBookingDays", 30);
        Long planId = createPlanReturnId(roomId, p);
        JsonNode b = previewJson(roomId, planId, today(2), today(4), 2, 0, 0);
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").toString().contains("advance"));
    }

    @Test
    void scenario07_advanceBookingMaximumEnforced() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("AdvMax", "ADVMAX");
        p.put("maxAdvanceBookingDays", 5);
        Long planId = createPlanReturnId(roomId, p);
        JsonNode b = previewJson(roomId, planId, today(20), today(22), 2, 0, 0);
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").toString().contains("advance"));
    }

    @Test
    void scenario08_closedToArrivalEnforced() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("CTA", "CTA");
        p.put("closedToArrival", true);
        Long planId = createPlanReturnId(roomId, p);
        JsonNode b = previewJson(roomId, planId, today(2), today(4), 2, 0, 0);
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").asText().toLowerCase().contains("arrival"));
    }

    @Test
    void scenario09_closedToDepartureEnforced() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("CTD", "CTD");
        p.put("closedToDeparture", true);
        Long planId = createPlanReturnId(roomId, p);
        JsonNode b = previewJson(roomId, planId, today(2), today(4), 2, 0, 0);
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").asText().toLowerCase().contains("departure"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10–13. Occupancy / child / extra-bed
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario10_occupancySpecificPriceSelected() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("Occ", "OCC");
        p.put("pricePerNight", 1000000);
        p.put("occupancyPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1300000, null, null);

        JsonNode b = previewJson(roomId, planId, today(2), today(3), 2, 1, 0);
        assertEquals(1300000.0, b.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(300000.0, b.get("occupancyAdjustment").asDouble(), 0.01);
    }

    @Test
    void scenario11_occupancyFallbackToBasePrice() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("OccFallback", "OCCFB");
        p.put("pricePerNight", 1000000);
        p.put("occupancyPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1300000, null, null);

        // Request 3 adults / 0 children — no matching occupancy row → fall back to base.
        JsonNode b = previewJson(roomId, planId, today(2), today(3), 3, 0, 0);
        assertEquals(1000000.0, b.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(0.0, b.get("occupancyAdjustment").asDouble(), 0.01);
    }

    @Test
    void scenario12_childSupplementCalculated() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("Child", "CHILD");
        p.put("pricePerNight", 1000000);
        p.put("occupancyPricingEnabled", true);
        p.put("childPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1000000, 150000L, null);

        JsonNode b = previewJson(roomId, planId, today(2), today(3), 2, 1, 0);
        assertEquals(150000.0, b.get("childSupplement").asDouble(), 0.01);
        assertEquals(1150000.0, b.get("finalNightlyRate").asDouble(), 0.01);
    }

    @Test
    void scenario13_extraBedSupplementCalculated() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("ExtraBed", "XBED");
        p.put("pricePerNight", 1000000);
        p.put("extraBedPrice", 200000);
        Long planId = createPlanReturnId(roomId, p);

        JsonNode b = previewJson(roomId, planId, today(2), today(3), 2, 0, 1);
        assertEquals(200000.0, b.get("extraBedSupplement").asDouble(), 0.01);
        assertEquals(1200000.0, b.get("finalNightlyRate").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 14–19. Derived plans
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario14_derivedFixedAdjustment() throws Exception {
        Long roomId = provisionRoom();
        Long parentId = createPlanReturnId(roomId, parentPlan("Flexible", "FLEX-A", 1000000));
        Long derivedId = createPlanReturnId(roomId, derivedPlan("Breakfast", "BRK-A", parentId, "FIXED_AMOUNT", 150000));
        JsonNode b = previewJson(roomId, derivedId, today(2), today(3), 2, 0, 0);
        assertEquals(1150000.0, b.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(150000.0, b.get("derivedAdjustment").asDouble(), 0.01);
    }

    @Test
    void scenario15_derivedPercentageAdjustment() throws Exception {
        Long roomId = provisionRoom();
        Long parentId = createPlanReturnId(roomId, parentPlan("Flexible", "FLEX-B", 1000000));
        Long derivedId = createPlanReturnId(roomId, derivedPlan("NonRef", "NREF-B", parentId, "PERCENTAGE", -10));
        JsonNode b = previewJson(roomId, derivedId, today(2), today(3), 2, 0, 0);
        assertEquals(900000.0, b.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(-100000.0, b.get("derivedAdjustment").asDouble(), 0.01);
    }

    @Test
    void scenario16_derivedFinalPriceNeverNegative() throws Exception {
        Long roomId = provisionRoom();
        Long parentId = createPlanReturnId(roomId, parentPlan("Flexible", "FLEX-C", 1000000));
        // FIXED -2,000,000 → derived would be negative → rejected at creation.
        mvc.perform(adminPost("/api/admin/rooms/" + roomId + "/rate-plans",
                derivedPlan("Bad", "BAD-C", parentId, "FIXED_AMOUNT", -2000000)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void scenario17_parentMustBelongToSameRoom() throws Exception {
        Long room1 = provisionRoom();
        Long room2 = provisionRoom();
        Long parentId = createPlanReturnId(room1, parentPlan("Flexible", "FLEX-D", 1000000));
        mvc.perform(adminPost("/api/admin/rooms/" + room2 + "/rate-plans",
                derivedPlan("Cross", "CROSS-D", parentId, "FIXED_AMOUNT", 100000)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void scenario18_circularDependencyRejected() throws Exception {
        Long roomId = provisionRoom();
        Long aId = createPlanReturnId(roomId, parentPlan("A", "A-CYC", 1000000));
        Long bId = createPlanReturnId(roomId, derivedPlan("B", "B-CYC", aId, "FIXED_AMOUNT", 100000));
        // Update A to be derived from B → cycle A→B→A.
        Map<String, Object> updateA = derivedPlan("A", "A-CYC", bId, "FIXED_AMOUNT", 100000);
        mvc.perform(put("/api/admin/rate-plans/" + aId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(updateA)))
            .andExpect(status().isBadRequest());
    }

    @Test
    void scenario19_inactiveParentMakesChildIneligible() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> parent = parentPlan("Flexible", "FLEX-E", 1000000);
        parent.put("active", false);
        Long parentId = createPlanReturnId(roomId, parent);
        Long derivedId = createPlanReturnId(roomId, derivedPlan("Child", "CHILD-E", parentId, "FIXED_AMOUNT", 100000));
        JsonNode b = previewJson(roomId, derivedId, today(2), today(3), 2, 0, 0);
        assertFalse(b.get("eligible").asBoolean());
        assertTrue(b.get("reason").asText().toLowerCase().contains("parent"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 20–22. Cancellation preview
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario20_cancellationPreviewFreeCancellation() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("Free", "FREE");
        p.put("pricePerNight", 1000000);
        p.put("cancellationPolicyType", "FREE_CANCELLATION");
        p.put("cancellationDeadlineHours", 48);
        Long planId = createPlanReturnId(roomId, p);

        JsonNode b = cancellationPreview(roomId, planId, today(10), today(12), 2, 0, 0); // 2 nights, deadline in future
        assertFalse(b.get("pastDeadline").asBoolean());
        assertEquals(0.0, b.get("penaltyAmount").asDouble(), 0.01);
        assertEquals(2000000.0, b.get("refundAmount").asDouble(), 0.01);
    }

    @Test
    void scenario21_partialPenaltyCalculated() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("Partial", "PART");
        p.put("pricePerNight", 1000000);
        p.put("cancellationPolicyType", "PARTIALLY_REFUNDABLE");
        p.put("cancellationPenaltyPercent", 30);
        p.put("refundable", true);
        Long planId = createPlanReturnId(roomId, p);

        JsonNode b = cancellationPreview(roomId, planId, today(10), today(12), 2, 0, 0); // subtotal 2,000,000
        assertEquals(600000.0, b.get("penaltyAmount").asDouble(), 0.01);
        assertEquals(1400000.0, b.get("refundAmount").asDouble(), 0.01);
    }

    @Test
    void scenario22_nonRefundablePenaltyIs100Percent() throws Exception {
        Long roomId = provisionRoom();
        Map<String, Object> p = basePlan("NonRef", "NREF");
        p.put("pricePerNight", 1000000);
        p.put("cancellationPolicyType", "NON_REFUNDABLE");
        p.put("refundable", false);
        Long planId = createPlanReturnId(roomId, p);

        JsonNode b = cancellationPreview(roomId, planId, today(10), today(12), 2, 0, 0);
        assertEquals(2000000.0, b.get("penaltyAmount").asDouble(), 0.01);
        assertEquals(0.0, b.get("refundAmount").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 23–27. Booking integration
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario23_bestEligiblePlanSelected() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> low = basePlan("Low Priority", "LOWP");
        low.put("priority", 5);
        createPlanReturnId(roomId, low);
        Map<String, Object> high = basePlan("High Priority", "HIGHP");
        high.put("priority", 20);
        Long highId = createPlanReturnId(roomId, high);

        String customer = registerAndLogin("bestplan-" + uniq() + "@test.com");
        JsonNode booking = book(customer, roomId, today(3), today(5), 2, 0, null, 0);
        assertEquals(highId.longValue(), booking.get("selectedRatePlanId").asLong());
        assertEquals("High Priority", booking.get("selectedRatePlanName").asText());
    }

    @Test
    void scenario24_explicitRatePlanBookingWorks() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, basePlan("Explicit", "EXPL"));
        String customer = registerAndLogin("explicit-" + uniq() + "@test.com");
        JsonNode booking = book(customer, roomId, today(3), today(5), 2, 0, planId, 0);
        assertEquals(planId.longValue(), booking.get("selectedRatePlanId").asLong());
        assertEquals("Explicit", booking.get("selectedRatePlanName").asText());
    }

    @Test
    void scenario25_invalidExplicitRatePlanRejected() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = basePlan("LongStay", "LONGSTAY");
        p.put("minStayNights", 5);
        Long planId = createPlanReturnId(roomId, p);
        String customer = registerAndLogin("invalid-" + uniq() + "@test.com");
        // 2-night stay violates min-stay 5 → 422.
        mvc.perform(bookRequest(customer, roomId, today(3), today(5), 2, 0, planId, 0))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("not eligible")));
    }

    @Test
    void scenario26_bookingStoresRatePlanSnapshot() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = basePlan("Snapshot", "SNAP");
        p.put("pricePerNight", 1000000);
        p.put("mealPlanType", "BREAKFAST");
        p.put("cancellationPolicyType", "FREE_CANCELLATION");
        p.put("cancellationDeadlineHours", 24);
        Long planId = createPlanReturnId(roomId, p);
        String customer = registerAndLogin("snap-" + uniq() + "@test.com");
        JsonNode booking = book(customer, roomId, today(3), today(5), 2, 0, planId, 0);
        assertEquals("BREAKFAST", booking.get("mealPlanType").asText());
        assertEquals("FREE_CANCELLATION", booking.get("cancellationPolicyType").asText());
        assertFalse(booking.get("nightlyRateSnapshot").isNull());
        assertEquals(1000000.0, booking.get("nightlyRateSnapshot").asDouble(), 0.01);
    }

    @Test
    void scenario27_laterRatePlanEditDoesNotChangeSnapshot() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = basePlan("Original Name", "SNAPEDIT");
        p.put("pricePerNight", 1000000);
        Long planId = createPlanReturnId(roomId, p);
        String customer = registerAndLogin("snapedit-" + uniq() + "@test.com");
        JsonNode booking = book(customer, roomId, today(3), today(5), 2, 0, planId, 0);
        Long bookingId = booking.get("id").asLong();

        // Edit the plan after booking.
        Map<String, Object> edit = basePlan("Renamed", "SNAPEDIT");
        edit.put("pricePerNight", 2000000);
        mvc.perform(put("/api/admin/rate-plans/" + planId)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(edit)))
            .andExpect(status().isOk());

        JsonNode after = mapper.readTree(mvc.perform(get("/api/bookings/" + bookingId)
                .header("Authorization", "Bearer " + customer))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("Original Name", after.get("selectedRatePlanName").asText());
        assertEquals(1000000.0, after.get("nightlyRateSnapshot").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 28–29. Ownership + public preview
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario28_partnerOwnershipEnforced() throws Exception {
        // Partner A owns a hotel/room and creates a plan; Partner B cannot touch it.
        String[] a = createApprovedPartner();
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        assignOwner(hotelId, Long.parseLong(a[1]));

        String created = mvc.perform(post("/api/partner/rooms/" + roomId + "/rate-plans")
                .header("Authorization", "Bearer " + a[0])
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(basePlan("Owned", "OWNED"))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long planId = mapper.readTree(created).get("id").asLong();

        String[] b = createApprovedPartner();
        mvc.perform(put("/api/partner/rate-plans/" + planId)
                .header("Authorization", "Bearer " + b[0])
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(basePlan("Hijack", "OWNED"))))
            .andExpect(status().isNotFound());
    }

    @Test
    void scenario29_publicPreviewWorks() throws Exception {
        Long roomId = provisionRoom();
        Long planId = createPlanReturnId(roomId, basePlan("Public", "PUB"));
        // No auth header.
        mvc.perform(get("/api/rooms/" + roomId + "/rate-plans/" + planId + "/preview"
                + "?checkIn=" + today(2) + "&checkOut=" + today(4) + "&adults=2"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.ratePlanId").value(planId));
        mvc.perform(get("/api/rooms/" + roomId + "/rate-plans"))
            .andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 30–34. Backward-compat + seed
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario30_existingAvailabilitySearchBackwardCompatible() throws Exception {
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        String body = mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + today(1) + "&checkOut=" + today(4) + "&adults=2&children=0"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode rooms = mapper.readTree(body).get("availableRooms");
        boolean summerDeal = false;
        for (JsonNode r : rooms) {
            if (r.get("appliedRatePlan") != null && !r.get("appliedRatePlan").isNull()
                    && "Summer Deal".equals(r.get("appliedRatePlan").asText())) summerDeal = true;
        }
        assertTrue(summerDeal, "STD-TWIN must still surface 'Summer Deal' as the cheapest plan");
    }

    @Test
    void scenario31_existingPricingPromotionOrderUnchanged() throws Exception {
        // The untouched PricingEngineService: STD-TWIN base 900k, Summer Deal 800k → ratePlanPrice 2,400,000.
        String body = mvc.perform(get("/api/rooms/" + stdTwinRoomId + "/pricing"
                + "?checkIn=" + today(1) + "&checkOut=" + today(4)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode r = mapper.readTree(body);
        assertEquals("Summer Deal", r.get("ratePlanName").asText());
        assertEquals(2400000.0, r.get("ratePlanPrice").asDouble(), 0.01);
        assertEquals(2700000.0, r.get("basePrice").asDouble(), 0.01);
        assertTrue(r.get("promotionDiscount").asDouble() > 0);
    }

    @Test
    void scenario32_inventoryConcurrencyRemainsGreen() throws Exception {
        // Rate-plan resolution now runs inside create(); the Phase 7.28 lock+reject must still hold.
        Long roomId = provisionBookableRoomWith(today(40), 3, 1); // exactly 1 available on the night
        String c1 = registerAndLogin("conc1-" + uniq() + "@test.com");
        String c2 = registerAndLogin("conc2-" + uniq() + "@test.com");
        mvc.perform(bookRequest(c1, roomId, today(40), today(41), 1, 0, null, 0))
            .andExpect(status().isCreated());
        mvc.perform(bookRequest(c2, roomId, today(40), today(41), 1, 0, null, 0))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void scenario33_seededAdvancedPlansExist() throws Exception {
        String body = mvc.perform(get("/api/rooms/" + stdTwinRoomId + "/rate-plans"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);
        assertTrue(hasCode(arr, "FLEX-RO"), "seeded Flexible plan must exist");
        assertTrue(hasCode(arr, "NONREF-10"), "seeded Non-refundable plan must exist");
        assertTrue(hasCode(arr, "BRKFST"), "seeded Breakfast plan must exist");
    }

    @Test
    void scenario34_restartSafeSeed() throws Exception {
        String body = mvc.perform(get("/api/admin/rate-plans?roomId=" + stdTwinRoomId)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode arr = mapper.readTree(body);
        int flexCount = 0;
        for (JsonNode n : arr)
            if (n.get("code") != null && "FLEX-RO".equals(n.get("code").asText())) flexCount++;
        assertEquals(1, flexCount, "seed must be restart-safe — no duplicate FLEX-RO");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 35–36. Security
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario35_unauthenticatedProtectedEndpointsRejected() throws Exception {
        mvc.perform(get("/api/admin/rate-plans"))
            .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/partner/rate-plans/1/duplicate"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void scenario36_nonAdminAdminEndpointsRejected() throws Exception {
        String customer = registerAndLogin("nonadmin-" + uniq() + "@test.com");
        mvc.perform(get("/api/admin/rate-plans")
                .header("Authorization", "Bearer " + customer))
            .andExpect(status().isForbidden());
    }

    // scenario37 (all previous tests still pass) is verified by the full suite.

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    private Map<String, Object> basePlan(String name, String code) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("rateName", name);
        m.put("rateType", "STANDARD");
        m.put("pricePerNight", 1000000);
        m.put("startDate", LocalDate.now().toString());
        m.put("endDate", LocalDate.now().plusDays(365).toString());
        m.put("active", true);
        if (code != null) m.put("code", code);
        return m;
    }

    private Map<String, Object> parentPlan(String name, String code, long price) {
        Map<String, Object> m = basePlan(name, code);
        m.put("pricePerNight", price);
        m.put("sourceType", "BASE");
        return m;
    }

    private Map<String, Object> derivedPlan(String name, String code, Long parentId, String adjType, long adjValue) {
        Map<String, Object> m = basePlan(name, code);
        m.put("sourceType", "DERIVED");
        m.put("parentRatePlanId", parentId);
        m.put("adjustmentType", adjType);
        m.put("adjustmentValue", adjValue);
        return m;
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder adminPost(String url, Object body) throws Exception {
        return post(url)
            .header("Authorization", "Bearer " + adminToken)
            .contentType(MediaType.APPLICATION_JSON)
            .content(mapper.writeValueAsString(body));
    }

    private Long createPlanReturnId(Long roomId, Object body) throws Exception {
        String resp = mvc.perform(adminPost("/api/admin/rooms/" + roomId + "/rate-plans", body))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void addOccupancy(Long planId, int adults, int children, long price, Long childSupp, Long extraBedSupp) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("adults", adults);
        m.put("children", children);
        m.put("pricePerNight", price);
        if (childSupp != null) m.put("childSupplement", childSupp);
        if (extraBedSupp != null) m.put("extraBedSupplement", extraBedSupp);
        mvc.perform(adminPost("/api/admin/rate-plans/" + planId + "/occupancy-prices", m))
            .andExpect(status().isCreated());
    }

    private JsonNode previewJson(Long roomId, Long planId, LocalDate ci, LocalDate co, int adults, int children, int extraBeds) throws Exception {
        String body = mvc.perform(get("/api/rooms/" + roomId + "/rate-plans/" + planId + "/preview"
                + "?checkIn=" + ci + "&checkOut=" + co
                + "&adults=" + adults + "&children=" + children + "&extraBeds=" + extraBeds))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode cancellationPreview(Long roomId, Long planId, LocalDate ci, LocalDate co, int adults, int children, int extraBeds) throws Exception {
        String body = mvc.perform(get("/api/rooms/" + roomId + "/rate-plans/" + planId + "/cancellation-preview"
                + "?checkIn=" + ci + "&checkOut=" + co
                + "&adults=" + adults + "&children=" + children + "&extraBeds=" + extraBeds))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private boolean hasCode(JsonNode arr, String code) {
        for (JsonNode n : arr) {
            JsonNode c = n.get("code");
            if (c != null && !c.isNull() && code.equals(c.asText())) return true;
        }
        return false;
    }

    // ── Provisioning ──────────────────────────────────────────────────────────

    /** A published admin-owned room (no inventory) — enough for CRUD / preview. */
    private Long provisionRoom() throws Exception {
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        return createRoom(hotelId, "RM-" + uniq());
    }

    /** A bookable room: published hotel + inventory seeded around the near-future test windows. */
    private Long provisionBookableRoom() throws Exception {
        return provisionBookableRoomWith(null, 10, 10);
    }

    private Long provisionBookableRoomWith(LocalDate onlyDate, int total, int available) throws Exception {
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        if (onlyDate != null) {
            seedNight(roomId, onlyDate, total, available);
        } else {
            // Cover the common booking windows today+1 .. today+50.
            StringBuilder items = new StringBuilder();
            for (int i = 1; i <= 50; i++) {
                if (items.length() > 0) items.append(",");
                items.append(String.format(
                    "{\"inventoryDate\":\"%s\",\"totalInventory\":%d,\"availableInventory\":%d,"
                    + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
                    + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
                    today(i), total, available));
            }
            mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                    .header("Authorization", "Bearer " + adminToken)
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{\"items\":[" + items + "]}"))
                .andExpect(status().isOk());
        }
        return roomId;
    }

    private void seedNight(Long roomId, LocalDate date, int total, int available) throws Exception {
        String item = String.format(
            "{\"inventoryDate\":\"%s\",\"totalInventory\":%d,\"availableInventory\":%d,"
            + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
            + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
            date, total, available);
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + item + "]}"))
            .andExpect(status().isOk());
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder bookRequest(
            String token, Long roomId, LocalDate ci, LocalDate co, int adults, int children, Long ratePlanId, int extraBeds) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("roomId", roomId);
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", adults);
        m.put("children", children);
        m.put("numberOfRooms", 1);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
        if (extraBeds > 0) m.put("extraBeds", extraBeds);
        try {
            return post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m));
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    private JsonNode book(String token, Long roomId, LocalDate ci, LocalDate co, int adults, int children, Long ratePlanId, int extraBeds) throws Exception {
        String body = mvc.perform(bookRequest(token, roomId, ci, co, adults, children, ratePlanId, extraBeds))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniq() { return UUID.randomUUID().toString().substring(0, 8); }

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
                .content("{\"fullName\":\"RP Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    /** @return [token, profileId] of an approved partner. */
    private String[] createApprovedPartner() throws Exception {
        String email = "adv-rp-partner-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"businessName":"RP Hotel Co","businessType":"HOTEL","representativeName":"RP Tester",
                     "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi, Da Nang"}
                    """))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();
        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        return new String[]{token, String.valueOf(profileId)};
    }

    private Long createHotelPlace(String name) throws Exception {
        String req = """
            {"name":"%s","categoryId":%d,"subcategoryId":%d,"administrativeUnitId":%d,
             "address":"123 Test Street","priceLevel":2,"featured":false,"verified":false,"status":"DRAFT"}
            """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);
        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(resp).get("id").asLong();
        patchStatus(id, "APPROVED");
        patchStatus(id, "PUBLISHED");
        return id;
    }

    private void patchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private Long createHotelDetail(Long placeId) throws Exception {
        String req = """
            {"placeId":%d,"starRating":4,"checkInTime":"14:00:00","checkOutTime":"12:00:00",
             "totalRooms":10,"availableRooms":10,"freeCancellation":false,"prepaymentRequired":false,
             "breakfastIncluded":false,"airportShuttle":false}
            """.formatted(placeId);
        String resp = mvc.perform(post("/api/admin/hotels")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String req = """
            {"placeId":%d,"roomName":"Deluxe Room","roomCode":"%s","roomType":"DELUXE","bedType":"QUEEN",
             "bedCount":1,"maxAdults":3,"maxChildren":2,"maxGuests":4,"roomSizeSqm":25.0,"floorNumber":2,
             "smokingAllowed":false,"breakfastIncluded":true,"freeCancellation":true,"instantConfirmation":true,
             "priceFrom":900000,"originalPrice":1000000,"quantity":10,"availableQuantity":10,"active":true}
            """.formatted(placeId, roomCode);
        String resp = mvc.perform(post("/api/admin/rooms")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void assignOwner(Long hotelId, Long partnerProfileId) throws Exception {
        mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + partnerProfileId + "}"))
            .andExpect(status().isOk());
    }
}
