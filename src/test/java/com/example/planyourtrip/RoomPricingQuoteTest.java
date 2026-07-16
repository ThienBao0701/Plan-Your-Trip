package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.CustomerCouponRepository;
import com.example.planyourtrip.repository.GiftCardTransactionRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.InventoryReservationRepository;
import com.example.planyourtrip.repository.LoyaltyPointsTransactionRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import com.example.planyourtrip.repository.TravelCreditTransactionRepository;
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
 * Phase 7.32 — Public pricing quote (POST /api/rooms/{roomId}/pricing/quote).
 *
 * <p>Proves the canonical quote returns the SAME priority-based rate plan and pre-customer-benefit
 * price as booking checkout, availability search and the partner preview; enforces validation and
 * public visibility; and — critically — proves the quote is a pure read: no inventory decrement,
 * no InventoryReservation, and no coupon / loyalty / travel-credit / gift-card consumption.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RoomPricingQuoteTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository roomRepo;
    @Autowired RoomInventoryRepository inventoryRepo;
    @Autowired InventoryReservationRepository reservationRepo;
    @Autowired CustomerCouponRepository customerCouponRepo;
    @Autowired LoyaltyPointsTransactionRepository loyaltyTxnRepo;
    @Autowired TravelCreditTransactionRepository creditTxnRepo;
    @Autowired GiftCardTransactionRepository giftTxnRepo;

    private String adminToken;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;
    private static final AtomicInteger counter = new AtomicInteger(1);

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1–4. Consistency with checkout / search / partner preview
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario01_quoteReturnsPriorityBasedSelectedPlan() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> low = basePlan("Cheap Rate", "Q-CHEAP");
        low.put("pricePerNight", 700000);
        low.put("priority", 5);
        createPlanReturnId(roomId, low);
        Map<String, Object> high = basePlan("Premium Rate", "Q-PREM");
        high.put("pricePerNight", 1000000);
        high.put("priority", 20);
        Long premiumId = createPlanReturnId(roomId, high);

        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, null);
        // Priority-based pick (Premium, priority 20) — NOT the cheaper plan.
        assertEquals(premiumId.longValue(), q.get("selectedRatePlanId").asLong());
        assertEquals("Premium Rate", q.get("selectedRatePlanName").asText());
        assertEquals(1000000.0, q.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(2000000.0, q.get("staySubtotal").asDouble(), 0.01);
    }

    @Test
    void scenario02_quotePriceMatchesBookingPreCustomerBenefitPrice() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Match", "Q-MATCH", 1000000));

        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, null);
        String customer = registerAndLogin("q-match-" + uniq() + "@test.com");
        JsonNode booking = book(customer, roomId, today(3), today(5), 2, 0, planId, 0);

        // The quote's stay subtotal and headline equal what checkout charges before customer benefits.
        assertEquals(booking.get("ratePlanPrice").asDouble(), q.get("staySubtotal").asDouble(), 0.01);
        assertEquals(booking.get("finalPrice").asDouble(), q.get("finalQuotedPrice").asDouble(), 0.01);
        assertEquals(planId.longValue(), q.get("selectedRatePlanId").asLong());
    }

    @Test
    void scenario03_quoteMatchesAvailabilitySearchSelectedPlan() throws Exception {
        Long placeId = createHotelPlace(uniq());
        createHotelDetail(placeId);
        String roomCode = "RM-" + uniq();
        Long roomId = createRoom(placeId, roomCode);
        seedNight(roomId, today(3), 5, 5);
        seedNight(roomId, today(4), 5, 5);

        Map<String, Object> cheap = priced("Cheap", "Q-S-CHEAP", 700000);
        cheap.put("priority", 5);
        createPlanReturnId(roomId, cheap);
        Map<String, Object> prem = priced("Premium", "Q-S-PREM", 1000000);
        prem.put("priority", 20);
        createPlanReturnId(roomId, prem);

        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, null);
        JsonNode searchRoom = availabilityRoom(placeId, roomCode, today(3), today(5), 2, 0);
        assertNotNull(searchRoom);
        assertEquals(searchRoom.get("appliedRatePlan").asText(), q.get("selectedRatePlanName").asText());
        assertEquals(searchRoom.get("pricePerNight").asDouble(), q.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(searchRoom.get("totalPrice").asDouble(), q.get("staySubtotal").asDouble(), 0.01);
    }

    @Test
    void scenario04_quoteMatchesPartnerPreviewSelectedPlan() throws Exception {
        // Partner-owned room; partner preview and the public quote must select the same plan/price.
        String[] partner = createApprovedPartner();
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        assignOwner(hotelId, Long.parseLong(partner[1]));
        seedNight(roomId, today(3), 5, 5);
        seedNight(roomId, today(4), 5, 5);
        Map<String, Object> prem = priced("Premium", "Q-PP-PREM", 1000000);
        prem.put("priority", 20);
        createPlanReturnId(roomId, prem);
        Map<String, Object> cheap = priced("Cheap", "Q-PP-CHEAP", 700000);
        cheap.put("priority", 5);
        createPlanReturnId(roomId, cheap);

        String previewBody = mvc.perform(get("/api/partner/rooms/" + roomId + "/pricing-preview"
                + "?checkIn=" + today(3) + "&checkOut=" + today(5))
                .header("Authorization", "Bearer " + partner[0]))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode preview = mapper.readTree(previewBody);

        JsonNode q = quote(roomId, today(3), today(5), 1, 0, 0, null);
        assertEquals(preview.get("ratePlanName").asText(), q.get("selectedRatePlanName").asText());
        assertEquals(preview.get("ratePlanPrice").asDouble(), q.get("staySubtotal").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 5–7. Explicit rate plan handling
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario05_explicitEligibleRatePlanWorks() throws Exception {
        Long roomId = provisionBookableRoom();
        createPlanReturnId(roomId, priced("Auto", "Q-AUTO", 1000000)); // decoy best-priority
        Long explicitId = createPlanReturnId(roomId, priced("Explicit", "Q-EXPL", 800000));

        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, explicitId);
        assertEquals(explicitId.longValue(), q.get("selectedRatePlanId").asLong());
        assertEquals("Explicit", q.get("selectedRatePlanName").asText());
        assertEquals(800000.0, q.get("finalNightlyRate").asDouble(), 0.01);
    }

    @Test
    void scenario06_explicitRatePlanFromAnotherRoomRejected() throws Exception {
        Long roomA = provisionBookableRoom();
        Long roomB = provisionBookableRoom();
        Long planA = createPlanReturnId(roomA, priced("A", "Q-XROOM", 1000000));
        mvc.perform(quoteRequest(roomB, today(3), today(5), 2, 0, 0, planA))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("does not belong")));
    }

    @Test
    void scenario07_inactivePlanRejected() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("Inactive", "Q-INACT", 1000000);
        p.put("active", false);
        Long planId = createPlanReturnId(roomId, p);
        mvc.perform(quoteRequest(roomId, today(3), today(5), 2, 0, 0, planId))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("not eligible")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 8–10. Stay restrictions
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario08_minimumStayEnforced() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("MinStay", "Q-MIN", 1000000);
        p.put("minStayNights", 5);
        Long planId = createPlanReturnId(roomId, p);
        mvc.perform(quoteRequest(roomId, today(3), today(5), 2, 0, 0, planId)) // 2 nights < 5
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Minimum stay")));
    }

    @Test
    void scenario09_maximumStayEnforced() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("MaxStay", "Q-MAX", 1000000);
        p.put("maxStayNights", 1);
        Long planId = createPlanReturnId(roomId, p);
        mvc.perform(quoteRequest(roomId, today(3), today(5), 2, 0, 0, planId)) // 2 nights > 1
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("Maximum stay")));
    }

    @Test
    void scenario10_advanceBookingRestrictionEnforced() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("AdvMin", "Q-ADV", 1000000);
        p.put("minAdvanceBookingDays", 30);
        Long planId = createPlanReturnId(roomId, p);
        mvc.perform(quoteRequest(roomId, today(3), today(5), 2, 0, 0, planId))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("advance")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11–14. Supplements & adjustments in the quote
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario11_occupancyPriceIncluded() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("Occ", "Q-OCC", 1000000);
        p.put("occupancyPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1300000, null, null);

        JsonNode q = quote(roomId, today(3), today(4), 2, 1, 0, planId);
        assertEquals(1300000.0, q.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(300000.0, q.get("occupancyAdjustment").asDouble(), 0.01);
    }

    @Test
    void scenario12_childSupplementIncluded() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("Child", "Q-CHILD", 1000000);
        p.put("occupancyPricingEnabled", true);
        p.put("childPricingEnabled", true);
        Long planId = createPlanReturnId(roomId, p);
        addOccupancy(planId, 2, 1, 1000000, 150000L, null);

        JsonNode q = quote(roomId, today(3), today(4), 2, 1, 0, planId);
        assertEquals(150000.0, q.get("childSupplement").asDouble(), 0.01);
        assertEquals(1150000.0, q.get("finalNightlyRate").asDouble(), 0.01);
    }

    @Test
    void scenario13_extraBedSupplementIncluded() throws Exception {
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("XBed", "Q-XBED", 1000000);
        p.put("extraBedPrice", 200000);
        Long planId = createPlanReturnId(roomId, p);

        JsonNode q = quote(roomId, today(3), today(4), 2, 0, 1, planId);
        assertEquals(200000.0, q.get("extraBedSupplement").asDouble(), 0.01);
        assertEquals(1200000.0, q.get("finalNightlyRate").asDouble(), 0.01);
    }

    @Test
    void scenario14_derivedPercentageAdjustmentIncluded() throws Exception {
        Long roomId = provisionBookableRoom();
        Long parentId = createPlanReturnId(roomId, priced("Flexible", "Q-FLEX", 1000000));
        Long derivedId = createPlanReturnId(roomId,
            derivedPlan("NonRef", "Q-DERIV", parentId, "PERCENTAGE", -10));
        JsonNode q = quote(roomId, today(3), today(4), 2, 0, 0, derivedId);
        assertEquals(900000.0, q.get("finalNightlyRate").asDouble(), 0.01);
        assertEquals(-100000.0, q.get("derivedAdjustment").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 15. Promotion applied once
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario15_promotionDiscountAppliedOnce() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Promo", "Q-PROMO", 1000000));
        // 10% ROOM promotion with priority above every seeded ALL promotion so it deterministically
        // dominates (non-stackable) — proving a single promotion is applied ONCE, not doubled.
        createRoomPromotion(roomId, "PERCENTAGE", 10, 100);

        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, planId); // subtotal 2,000,000
        assertEquals(2000000.0, q.get("staySubtotal").asDouble(), 0.01);
        assertEquals(200000.0, q.get("promotionDiscount").asDouble(), 0.01);            // once (10% only)
        assertEquals(1800000.0, q.get("totalBeforeCustomerBenefits").asDouble(), 0.01);
        assertEquals(1800000.0, q.get("finalQuotedPrice").asDouble(), 0.01);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 16–21. NO STATE MUTATION — the heart of this phase
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario16_quoteDoesNotClaimCoupon() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoClaim", "Q-NC", 1000000));
        long before = customerCouponRepo.count();
        quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertEquals(before, customerCouponRepo.count(), "quote must not create/claim any CustomerCoupon");
    }

    @Test
    void scenario17_quoteDoesNotRedeemLoyalty() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoLoyalty", "Q-NL", 1000000));
        long before = loyaltyTxnRepo.count();
        quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertEquals(before, loyaltyTxnRepo.count(), "quote must not write any loyalty points transaction");
    }

    @Test
    void scenario18_quoteDoesNotConsumeTravelCredit() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoCredit", "Q-NCR", 1000000));
        long before = creditTxnRepo.count();
        quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertEquals(before, creditTxnRepo.count(), "quote must not write any travel credit transaction");
    }

    @Test
    void scenario19_quoteDoesNotConsumeGiftCard() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoGift", "Q-NG", 1000000));
        long before = giftTxnRepo.count();
        quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertEquals(before, giftTxnRepo.count(), "quote must not write any gift card transaction");
    }

    @Test
    void scenario20_quoteDoesNotDecrementInventory() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoDecrement", "Q-ND", 1000000));
        int before = availableOn(roomId, today(3));
        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertTrue(q.get("inventoryAvailable").asBoolean());
        assertEquals(before, availableOn(roomId, today(3)),
            "quote must not decrement available inventory");
        // A subsequent booking still consumes the full, untouched inventory.
        String customer = registerAndLogin("q-nd-" + uniq() + "@test.com");
        book(customer, roomId, today(3), today(5), 2, 0, planId, 0);
        assertEquals(before - 1, availableOn(roomId, today(3)), "only the booking decrements inventory");
    }

    @Test
    void scenario21_quoteDoesNotCreateInventoryReservation() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("NoReservation", "Q-NR", 1000000));
        long before = reservationRepo.count();
        quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertEquals(before, reservationRepo.count(), "quote must not create an InventoryReservation");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 22–29. Availability, backward-compat, visibility, validation, security
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void scenario22_unavailableRoomHandledClearly() throws Exception {
        Long placeId = createHotelPlace(uniq());
        createHotelDetail(placeId);
        Long roomId = createRoom(placeId, "RM-" + uniq());
        seedNight(roomId, today(3), 1, 0); // sold out
        seedNight(roomId, today(4), 1, 0);
        Long planId = createPlanReturnId(roomId, priced("SoldOut", "Q-SO", 1000000));

        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, planId);
        assertFalse(q.get("inventoryAvailable").asBoolean(), "sold-out stay must report inventoryAvailable=false");
        assertEquals(0, q.get("availableRooms").asInt());
        assertTrue(q.get("warnings").toString().toLowerCase().contains("no inventory"),
            "a clear warning must explain unavailability");
        // Pricing is still returned (informational) and is honest about the selected plan.
        assertEquals(planId.longValue(), q.get("selectedRatePlanId").asLong());
    }

    @Test
    void scenario23_legacyPricingEndpointRemainsBackwardCompatible() throws Exception {
        Long stdTwinRoomId = seededStdTwinRoomId();
        String body = mvc.perform(get("/api/rooms/" + stdTwinRoomId + "/pricing"
                + "?checkIn=" + today(1) + "&checkOut=" + today(4)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode r = mapper.readTree(body);
        // Legacy contract + legacy cheapest-plan selection unchanged.
        assertEquals("Summer Deal", r.get("ratePlanName").asText());
        assertEquals(2400000.0, r.get("ratePlanPrice").asDouble(), 0.01);
        assertEquals(2700000.0, r.get("basePrice").asDouble(), 0.01);
        assertTrue(r.has("appliedPromotions"));
    }

    @Test
    void scenario24_unpublishedRoomNotPubliclyQuoted() throws Exception {
        // Hotel place left in DRAFT (not published) → must not be quotable.
        Long placeId = createDraftHotelPlace(uniq());
        createHotelDetail(placeId);
        Long roomId = createRoom(placeId, "RM-" + uniq());
        seedNight(roomId, today(3), 5, 5);
        seedNight(roomId, today(4), 5, 5);
        Long planId = createPlanReturnId(roomId, priced("Hidden", "Q-HID", 1000000));
        mvc.perform(quoteRequest(roomId, today(3), today(5), 2, 0, 0, planId))
            .andExpect(status().isNotFound());
    }

    @Test
    void scenario25_invalidDatesRejected() throws Exception {
        Long roomId = provisionBookableRoom();
        createPlanReturnId(roomId, priced("Dates", "Q-DATE", 1000000));
        // checkOut before checkIn
        mvc.perform(quoteRequest(roomId, today(5), today(3), 2, 0, 0, null))
            .andExpect(status().isBadRequest());
        // checkIn in the past
        mvc.perform(quoteRequest(roomId, today(-2), today(2), 2, 0, 0, null))
            .andExpect(status().isBadRequest());
    }

    @Test
    void scenario26_guestCapacityEnforced() throws Exception {
        // Room maxAdults=3; explicit plan with 5 adults → eligibility rejects (422).
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Cap", "Q-CAP", 1000000));
        mvc.perform(quoteRequest(roomId, today(3), today(5), 5, 0, 0, planId))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.message").value(org.hamcrest.Matchers.containsString("capacity")));
    }

    @Test
    void scenario27_responseExposesClearNightlyAndStayTotals() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Totals", "Q-TOT", 1000000));
        JsonNode q = quote(roomId, today(3), today(6), 2, 0, 0, planId); // 3 nights
        assertEquals(3, q.get("nights").asInt());
        assertEquals(1000000.0, q.get("finalNightlyRate").asDouble(), 0.01);          // per-night
        assertEquals(3000000.0, q.get("staySubtotal").asDouble(), 0.01);              // total stay (rate-plan)
        assertEquals("VND", q.get("currency").asText());
        // Headline is the pre-customer-benefit total = staySubtotal minus any promotion discount.
        double subtotal = q.get("staySubtotal").asDouble();
        double promo = q.get("promotionDiscount").asDouble();
        assertEquals(subtotal - promo, q.get("finalQuotedPrice").asDouble(), 0.01);   // headline
        assertEquals(q.get("totalBeforeCustomerBenefits").asDouble(), q.get("finalQuotedPrice").asDouble(), 0.01);
        assertFalse(q.get("quoteGeneratedAt").isNull());
        assertFalse(q.get("quoteExpiresAt").isNull());
    }

    @Test
    void scenario28_quoteWarningExplainsNoInventoryHold() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Warn", "Q-WARN", 1000000));
        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, planId);
        String warnings = q.get("warnings").toString().toLowerCase();
        assertTrue(warnings.contains("hold") && warnings.contains("change"),
            "quote must warn it holds no inventory and price/availability may change");
    }

    @Test
    void scenario29_unauthenticatedAccessIsPublic() throws Exception {
        Long roomId = provisionBookableRoom();
        Long planId = createPlanReturnId(roomId, priced("Public", "Q-PUB", 1000000));
        // No Authorization header — the quote endpoint is public like legacy pricing.
        mvc.perform(post("/api/rooms/" + roomId + "/pricing/quote")
                .contentType(MediaType.APPLICATION_JSON)
                .content(quoteBody(today(3), today(5), 2, 0, 0, planId)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.selectedRatePlanId").value(planId));
    }

    @Test
    void scenario30_noEligiblePlanReturnsClearIneligibleQuote() throws Exception {
        // Auto-select with every plan failing min-stay → 200 with a clear ineligible response.
        Long roomId = provisionBookableRoom();
        Map<String, Object> p = priced("LongOnly", "Q-LONG", 1000000);
        p.put("minStayNights", 10);
        createPlanReturnId(roomId, p);
        JsonNode q = quote(roomId, today(3), today(5), 2, 0, 0, null); // 2 nights
        assertTrue(q.get("selectedRatePlanId").isNull(), "no plan selected");
        assertTrue(q.get("finalQuotedPrice").isNull(), "no price when no plan is eligible");
        assertFalse(q.get("eligibilityReason").isNull(), "eligibilityReason must explain why");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private LocalDate today(int plus) { return LocalDate.now().plusDays(plus); }

    private int availableOn(Long roomId, LocalDate date) {
        return inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date)
            .orElseThrow().getAvailableInventory();
    }

    private Long seededStdTwinRoomId() {
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        return roomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode())).findFirst().orElseThrow().getId();
    }

    private JsonNode availabilityRoom(Long placeId, String roomCode, LocalDate ci, LocalDate co, int adults, int children) throws Exception {
        String body = mvc.perform(get("/api/places/" + placeId + "/availability"
                + "?checkIn=" + ci + "&checkOut=" + co + "&adults=" + adults + "&children=" + children))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        for (JsonNode r : mapper.readTree(body).get("availableRooms")) {
            if (roomCode.equals(r.get("roomCode").asText())) return r;
        }
        return null;
    }

    // ── Quote request builders ──────────────────────────────────────────────────

    private String quoteBody(LocalDate ci, LocalDate co, int adults, int children, int extraBeds, Long ratePlanId) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("checkIn", ci.toString());
        m.put("checkOut", co.toString());
        m.put("adults", adults);
        m.put("children", children);
        m.put("extraBeds", extraBeds);
        if (ratePlanId != null) m.put("ratePlanId", ratePlanId);
        return mapper.writeValueAsString(m);
    }

    private org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder quoteRequest(
            Long roomId, LocalDate ci, LocalDate co, int adults, int children, int extraBeds, Long ratePlanId) {
        try {
            return post("/api/rooms/" + roomId + "/pricing/quote")
                .contentType(MediaType.APPLICATION_JSON)
                .content(quoteBody(ci, co, adults, children, extraBeds, ratePlanId));
        } catch (Exception e) { throw new RuntimeException(e); }
    }

    private JsonNode quote(Long roomId, LocalDate ci, LocalDate co, int adults, int children, int extraBeds, Long ratePlanId) throws Exception {
        String body = mvc.perform(quoteRequest(roomId, ci, co, adults, children, extraBeds, ratePlanId))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    // ── Plan builders ───────────────────────────────────────────────────────────

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

    private Map<String, Object> priced(String name, String code, long price) {
        Map<String, Object> m = basePlan(name, code);
        m.put("pricePerNight", price);
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

    private Long createPlanReturnId(Long roomId, Object body) throws Exception {
        String resp = mvc.perform(post("/api/admin/rooms/" + roomId + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
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
        mvc.perform(post("/api/admin/rate-plans/" + planId + "/occupancy-prices")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated());
    }

    private void createRoomPromotion(Long roomId, String discountType, long value, int priority) throws Exception {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("name", "Quote Promo " + uniq());
        m.put("promotionType", "ROOM");
        m.put("discountType", discountType);
        m.put("discountValue", value);
        m.put("stackable", false);
        m.put("priority", priority);
        m.put("startDate", LocalDate.now().toString());
        m.put("endDate", LocalDate.now().plusDays(365).toString());
        m.put("active", true);
        m.put("targetType", "ROOM");
        m.put("targetId", roomId);
        mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(m)))
            .andExpect(status().isCreated());
    }

    // ── Provisioning ────────────────────────────────────────────────────────────

    private Long provisionBookableRoom() throws Exception {
        Long hotelId = createHotelPlace(uniq());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "RM-" + uniq());
        StringBuilder items = new StringBuilder();
        for (int i = 1; i <= 20; i++) {
            if (items.length() > 0) items.append(",");
            items.append(String.format(
                "{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10,"
                + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,"
                + "\"stopSell\":false,\"closedArrival\":false,\"closedDeparture\":false}",
                today(i)));
        }
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory/bulk")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + items + "]}"))
            .andExpect(status().isOk());
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
                .content("{\"fullName\":\"Quote Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String[] createApprovedPartner() throws Exception {
        String email = "quote-partner-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"businessName":"Quote Hotel Co","businessType":"HOTEL","representativeName":"Quote Tester",
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
        Long id = createDraftHotelPlace(name);
        patchStatus(id, "APPROVED");
        patchStatus(id, "PUBLISHED");
        return id;
    }

    private Long createDraftHotelPlace(String name) throws Exception {
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
        return mapper.readTree(resp).get("id").asLong();
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
