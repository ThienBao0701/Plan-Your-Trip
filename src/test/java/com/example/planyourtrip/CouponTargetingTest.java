package com.example.planyourtrip;

import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.example.planyourtrip.util.SlugUtils;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * CouponTargetingTest — Phase 7.17 (Coupon Targeting &amp; Advanced Eligibility).
 * Covers target-type resolution (ALL/HOTEL/ROOM/PLACE_TYPE), minimum-stay and
 * booking-date-window eligibility, customer-segment eligibility (NEW_USER,
 * RETURNING_USER, MEMBER-unsupported, MANUAL-no-op), firstBookingOnly,
 * promotion/credit stacking flags enforced at checkout, atomicity (a rejected
 * checkout burns neither coupon nor credits), the new customer
 * {@code /eligibility} endpoint and admin {@code /eligibility-preview} tool,
 * backward compatibility of the existing preview/plain-booking flows, and the
 * updated seed data (WELCOME10 explicit fields, GRANDPALACE15). Every scenario
 * registers its own throwaway user(s)/coupon code(s)/booking dates so state
 * never leaks across tests — mirrors CheckoutCouponCreditTest's conventions.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CouponTargetingTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;
    @Autowired RoomInventoryRepository roomInventoryRepo;
    @Autowired UserRepository userRepo;
    @Autowired CustomerCouponRepository customerCouponRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private Long grandPalacePlaceId;
    private Long stdTwinRoomId;
    private Long dlxKingRoomId;
    private Long secondHotelPlaceId;
    private Long secondHotelRoomId;
    private Long wrongTypePlaceId;

    @BeforeEach
    void setup() {
        grandPalacePlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(grandPalacePlaceId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode())).findFirst().orElseThrow().getId();
        dlxKingRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "DLX-KING".equals(r.getRoomCode())).findFirst().orElseThrow().getId();

        ensureSecondHotel();
        ensureWrongTypePlace();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 1-5: ADMIN TARGET CONFIGURATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void adminCreatesAllTargetCoupon() throws Exception {
        String code = uniqueCode("all");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "ALL");

        JsonNode res = postCouponDef(payload, status().isCreated());
        assertEquals("ALL", res.get("targetType").asText());
        assertTrue(res.get("targetId").isNull());
    }

    @Test
    void adminCreatesHotelTargetCoupon() throws Exception {
        String code = uniqueCode("hoteldef");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "HOTEL");
        payload.put("targetId", grandPalacePlaceId);

        JsonNode res = postCouponDef(payload, status().isCreated());
        assertEquals("HOTEL", res.get("targetType").asText());
        assertEquals(grandPalacePlaceId, res.get("targetId").asLong());
    }

    @Test
    void adminCreatesRoomTargetCoupon() throws Exception {
        String code = uniqueCode("roomdef");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "ROOM");
        payload.put("targetId", stdTwinRoomId);

        JsonNode res = postCouponDef(payload, status().isCreated());
        assertEquals("ROOM", res.get("targetType").asText());
        assertEquals(stdTwinRoomId, res.get("targetId").asLong());
    }

    @Test
    void invalidTargetConfigurationRejected() throws Exception {
        String code = uniqueCode("notarget");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "HOTEL"); // targetId deliberately omitted -> null
        postCouponDef(payload, status().isBadRequest());
    }

    @Test
    void missingTargetHotelRejected404() throws Exception {
        String code = uniqueCode("badtarget");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "HOTEL");
        payload.put("targetId", 999_999_999L);
        postCouponDef(payload, status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 6-9: TARGET RESOLUTION (HOTEL / ROOM)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void hotelTargetCouponEligibleForMatchingHotel() throws Exception {
        String code = uniqueCode("hotelok");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "HOTEL");
        payload.put("targetId", grandPalacePlaceId);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-hotel-ok");
        Long couponId = claim(token, code).get("id").asLong();

        LocalDate ci = TODAY.plusDays(12), co = ci.plusDays(1);
        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(grandPalacePlaceId, stdTwinRoomId, ci, co, "1000000", null), status().isOk());

        assertTrue(res.get("eligible").asBoolean());
        assertEquals("HOTEL", res.get("matchedTargetType").asText());
        assertDecimal("100000", res.get("previewDiscount"));
    }

    @Test
    void hotelTargetCouponRejectedForAnotherHotel() throws Exception {
        String code = uniqueCode("hotelbad");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "HOTEL");
        payload.put("targetId", grandPalacePlaceId);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-hotel-bad");
        Long couponId = claim(token, code).get("id").asLong();

        LocalDate ci = TODAY.plusDays(13), co = ci.plusDays(1);
        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(secondHotelPlaceId, secondHotelRoomId, ci, co, "1000000", null), status().isOk());

        assertFalse(res.get("eligible").asBoolean());
        assertTrue(res.get("reason").asText().toLowerCase().contains("hotel"));
        assertDecimal("0", res.get("previewDiscount"));
    }

    @Test
    void roomTargetCouponEligibleForMatchingRoom() throws Exception {
        String code = uniqueCode("roomok");
        ObjectNode payload = baseCouponPayload(code, "FIXED_AMOUNT", "50000");
        payload.put("targetType", "ROOM");
        payload.put("targetId", stdTwinRoomId);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-room-ok");
        Long couponId = claim(token, code).get("id").asLong();

        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(grandPalacePlaceId, stdTwinRoomId, null, null, "1000000", null), status().isOk());

        assertTrue(res.get("eligible").asBoolean());
        assertEquals("ROOM", res.get("matchedTargetType").asText());
        assertDecimal("50000", res.get("previewDiscount"));
    }

    @Test
    void roomTargetCouponRejectedForAnotherRoom() throws Exception {
        String code = uniqueCode("roombad");
        ObjectNode payload = baseCouponPayload(code, "FIXED_AMOUNT", "50000");
        payload.put("targetType", "ROOM");
        payload.put("targetId", stdTwinRoomId);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-room-bad");
        Long couponId = claim(token, code).get("id").asLong();

        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(grandPalacePlaceId, dlxKingRoomId, null, null, "1000000", null), status().isOk());

        assertFalse(res.get("eligible").asBoolean());
        assertTrue(res.get("reason").asText().toLowerCase().contains("room"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 10: PLACE_TYPE TARGETING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void placeTypeCouponEligibilityWorks() throws Exception {
        String code = uniqueCode("placetype");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "PLACE_TYPE");
        payload.put("placeType", "ACCOMMODATION");
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-placetype");
        Long couponId = claim(token, code).get("id").asLong();

        LocalDate ci = TODAY.plusDays(14), co = ci.plusDays(1);
        JsonNode matched = checkEligibility(token, couponId,
            eligibilityPayload(grandPalacePlaceId, null, ci, co, "1000000", null), status().isOk());
        assertTrue(matched.get("eligible").asBoolean());
        assertEquals("PLACE_TYPE", matched.get("matchedTargetType").asText());

        JsonNode mismatched = checkEligibility(token, couponId,
            eligibilityPayload(wrongTypePlaceId, null, ci, co, "1000000", null), status().isOk());
        assertFalse(mismatched.get("eligible").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 11-12: MINIMUM STAY / BOOKING DATE WINDOW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void minimumStayEligibilityEnforced() throws Exception {
        String code = uniqueCode("minstay");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("minimumStayNights", 3);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-minstay");
        Long couponId = claim(token, code).get("id").asLong();

        LocalDate ci = TODAY.plusDays(16);
        JsonNode tooShort = checkEligibility(token, couponId,
            eligibilityPayload(null, null, ci, ci.plusDays(1), "1000000", null), status().isOk());
        assertFalse(tooShort.get("eligible").asBoolean());
        assertFalse(tooShort.get("minimumStaySatisfied").asBoolean());

        JsonNode longEnough = checkEligibility(token, couponId,
            eligibilityPayload(null, null, ci, ci.plusDays(3), "1000000", null), status().isOk());
        assertTrue(longEnough.get("eligible").asBoolean());
        assertTrue(longEnough.get("minimumStaySatisfied").asBoolean());
    }

    @Test
    void bookingDateWindowEligibilityEnforced() throws Exception {
        String code = uniqueCode("datewindow");
        LocalDate windowFrom = TODAY.plusDays(20), windowTo = TODAY.plusDays(25);
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("bookingDateFrom", windowFrom.toString());
        payload.put("bookingDateTo", windowTo.toString());
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-datewindow");
        Long couponId = claim(token, code).get("id").asLong();

        JsonNode inside = checkEligibility(token, couponId,
            eligibilityPayload(null, null, windowFrom.plusDays(1), windowFrom.plusDays(2), "1000000", null),
            status().isOk());
        assertTrue(inside.get("eligible").asBoolean());
        assertTrue(inside.get("dateWindowSatisfied").asBoolean());

        JsonNode outside = checkEligibility(token, couponId,
            eligibilityPayload(null, null, windowTo.plusDays(5), windowTo.plusDays(6), "1000000", null),
            status().isOk());
        assertFalse(outside.get("eligible").asBoolean());
        assertFalse(outside.get("dateWindowSatisfied").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 13-16: CUSTOMER SEGMENTS / FIRST-BOOKING-ONLY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void newUserSegmentEligibleForFreshUser() throws Exception {
        String code = uniqueCode("newuserok");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("customerSegment", "NEW_USER");
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-newuser-fresh");
        Long couponId = claim(token, code).get("id").asLong();

        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(null, null, null, null, "1000000", null), status().isOk());
        assertTrue(res.get("eligible").asBoolean());
        assertTrue(res.get("customerSegmentSatisfied").asBoolean());
    }

    @Test
    void newUserSegmentRejectedAfterPriorBooking() throws Exception {
        String code = uniqueCode("newuserold");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("customerSegment", "NEW_USER");
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-newuser-old");
        // Claimed while still a fresh user — claim-time NEW_USER check passes.
        Long couponId = claim(token, code).get("id").asLong();

        LocalDate ci = TODAY.plusDays(18), co = ci.plusDays(1);
        book(token, bookingPayload(stdTwinRoomId, ci, co, null, null), status().isCreated());

        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(null, null, null, null, "1000000", null), status().isOk());
        assertFalse(res.get("eligible").asBoolean());
        assertFalse(res.get("customerSegmentSatisfied").asBoolean());
    }

    @Test
    void returningUserSegmentEligibleAfterConfirmedBooking() throws Exception {
        String token = registerAndLogin("targeting-returning");
        LocalDate ci = TODAY.plusDays(19), co = ci.plusDays(1);
        Long bookingId = book(token, bookingPayload(stdTwinRoomId, ci, co, null, null), status().isCreated())
            .get("id").asLong();

        String code = uniqueCode("returning");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("customerSegment", "RETURNING_USER");
        postCouponDef(payload, status().isCreated());

        // A brand-new user with no confirmed booking cannot even claim it —
        // RETURNING_USER is enforced at claim time too.
        String freshToken = registerAndLogin("targeting-returning-fresh");
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + freshToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isBadRequest());

        // Still just PENDING — the owning user cannot claim it yet either.
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isBadRequest());

        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"CONFIRMED\"}"))
            .andExpect(status().isOk());

        Long couponId = claim(token, code).get("id").asLong();
        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(null, null, null, null, "1000000", null), status().isOk());
        assertTrue(res.get("eligible").asBoolean());
        assertTrue(res.get("customerSegmentSatisfied").asBoolean());
    }

    @Test
    void firstBookingOnlyEnforced() throws Exception {
        String code = uniqueCode("firstonly");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("firstBookingOnly", true);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-firstonly");
        Long couponId = claim(token, code).get("id").asLong(); // fresh user — claim succeeds

        LocalDate ci = TODAY.plusDays(22), co = ci.plusDays(1);
        book(token, bookingPayload(stdTwinRoomId, ci, co, null, null), status().isCreated());

        JsonNode res = checkEligibility(token, couponId,
            eligibilityPayload(null, null, null, null, "1000000", null), status().isOk());
        assertFalse(res.get("eligible").asBoolean());
        assertTrue(res.get("reason").asText().toLowerCase().contains("first"));

        // A second firstBookingOnly coupon can no longer even be CLAIMED by this
        // user — same rule, enforced at claim time too.
        String code2 = uniqueCode("firstonly2");
        ObjectNode payload2 = baseCouponPayload(code2, "PERCENTAGE", "10");
        payload2.put("firstBookingOnly", true);
        postCouponDef(payload2, status().isCreated());
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code2 + "\"}"))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 17-20: STACKING / ATOMICITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nonCombinablePromotionStackingRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(24), co = ci.plusDays(1);
        String code = uniqueCode("nopromo");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("combinableWithPromotions", false);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-nopromo");
        Long couponId = claim(token, code).get("id").asLong();

        // A seeded ALL-target promotion (e.g. "Weekend Special") always applies
        // within its active window, so this room+date combination already has a
        // promotion discount baked into pricing — confirmed via the standalone
        // eligibility tool before proving the checkout rejection.
        JsonNode elig = checkEligibility(token, couponId,
            eligibilityPayload(null, stdTwinRoomId, ci, co, "1000000", null), status().isOk());
        assertFalse(elig.get("promotionStackingAllowed").asBoolean());
        assertFalse(elig.get("eligible").asBoolean());

        book(token, bookingPayload(stdTwinRoomId, ci, co, code, null), status().isBadRequest());

        // Rejection must not burn the coupon.
        assertEquals("AVAILABLE", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());
    }

    @Test
    void nonCombinableCreditStackingRejected() throws Exception {
        LocalDate ci = TODAY.plusDays(26), co = ci.plusDays(1);
        String code = uniqueCode("nocredit");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("combinableWithTravelCredits", false);
        postCouponDef(payload, status().isCreated());

        JsonNode user = registerUser("targeting-nocredit");
        String token = user.get("token").asText();
        Long couponId = claim(token, code).get("id").asLong();
        grantCredits(user.get("user").get("id").asLong(), "500000");

        book(token, bookingPayload(stdTwinRoomId, ci, co, code, "100000"), status().isBadRequest());
        assertEquals("AVAILABLE", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());
    }

    @Test
    void combinableCouponAndCreditsSucceed() throws Exception {
        LocalDate ci = TODAY.plusDays(28), co = ci.plusDays(1);
        String code = uniqueCode("combo");
        // combinableWithPromotions / combinableWithTravelCredits omitted -> default true.
        postCouponDef(baseCouponPayload(code, "FIXED_AMOUNT", "50000"), status().isCreated());

        JsonNode user = registerUser("targeting-combo");
        String token = user.get("token").asText();
        Long couponId = claim(token, code).get("id").asLong();
        grantCredits(user.get("user").get("id").asLong(), "500000");

        JsonNode res = book(token, bookingPayload(stdTwinRoomId, ci, co, code, "100000"), status().isCreated());
        assertEquals(code, res.get("couponCode").asText());
        assertDecimal("50000", res.get("couponDiscountAmount"));
        assertDecimal("100000", res.get("creditAmountUsed"));

        assertEquals("USED", getJson(token, "/api/me/coupons/" + couponId).get("status").asText());
    }

    @Test
    void failedEligibilityDoesNotConsumeCoupon() throws Exception {
        LocalDate ci = TODAY.plusDays(30), co = ci.plusDays(1); // 1 night only
        String code = uniqueCode("nomin");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("minimumStayNights", 3);
        postCouponDef(payload, status().isCreated());

        String token = registerAndLogin("targeting-atomic");
        Long couponId = claim(token, code).get("id").asLong();

        book(token, bookingPayload(stdTwinRoomId, ci, co, code, null), status().isBadRequest());

        JsonNode coupon = getJson(token, "/api/me/coupons/" + couponId);
        assertEquals("AVAILABLE", coupon.get("status").asText());
        assertTrue(coupon.get("usedAt").isNull());
        assertTrue(coupon.get("bookingId").isNull());

        // currentUsageCount reflects only the one claim, not a phantom redemption.
        JsonNode def = getCouponDefinitionByCode(code);
        assertEquals(1, def.get("currentUsageCount").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 21-22: BACKWARD COMPATIBILITY / REGRESSION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void existingPreviewRemainsBackwardCompatible() throws Exception {
        String code = uniqueCode("previewcompat");
        postCouponDef(baseCouponPayload(code, "PERCENTAGE", "10"), status().isCreated());
        String token = registerAndLogin("targeting-previewcompat");
        Long couponId = claim(token, code).get("id").asLong();

        // Old-style call: only orderAmount, no hotelId/roomId/checkIn/checkOut/travelCreditAmount.
        JsonNode res = preview(token, couponId, "1000000");

        assertTrue(res.get("eligible").asBoolean());
        assertDecimal("100000", res.get("discountAmount"));
        assertDecimal("900000", res.get("finalAmount"));
    }

    @Test
    void existingBookingWithoutCouponUnchanged() throws Exception {
        LocalDate ci = TODAY.plusDays(32), co = ci.plusDays(2);
        String token = registerAndLogin("targeting-legacy");
        String legacyPayload = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null}",
            stdTwinRoomId, ci, co);

        JsonNode res = book(token, legacyPayload, status().isCreated());
        assertEquals("PENDING", res.get("status").asText());
        assertTrue(res.get("couponCode").isNull());
        assertTrue(res.get("couponDiscountAmount").isNull());
        assertTrue(res.get("creditAmountUsed").isNull());
        assertTrue(res.get("basePrice").asDouble() > 0);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 23-24: SEED DATA
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void seededWelcome10RemainsValidAndClaimable() throws Exception {
        JsonNode welcome = getCouponDefinitionByCode("WELCOME10");
        assertNotNull(welcome, "WELCOME10 must be seeded");
        assertTrue(welcome.get("active").asBoolean());
        assertEquals("ALL", welcome.get("targetType").asText());
        assertEquals("ALL_USERS", welcome.get("customerSegment").asText());
        assertTrue(welcome.get("combinableWithPromotions").asBoolean());
        assertTrue(welcome.get("combinableWithTravelCredits").asBoolean());

        String token = registerAndLogin("targeting-welcome");
        Long id = claim(token, "welcome10").get("id").asLong();
        JsonNode res = preview(token, id, "1000000");
        assertTrue(res.get("eligible").asBoolean());
        assertDecimal("100000", res.get("discountAmount"));
    }

    @Test
    void seededGrandPalace15ExistsAndCorrect() throws Exception {
        JsonNode def = getCouponDefinitionByCode("GRANDPALACE15");
        assertNotNull(def, "GRANDPALACE15 must be seeded");
        assertTrue(def.get("active").asBoolean());
        assertEquals("HOTEL", def.get("targetType").asText());
        assertEquals(grandPalacePlaceId, def.get("targetId").asLong());
        assertEquals(2, def.get("minimumStayNights").asInt());
        assertDecimal("15", def.get("discountValue"));

        String token = registerAndLogin("targeting-grandpalace15");
        Long couponId = claim(token, "grandpalace15").get("id").asLong();

        LocalDate ci = TODAY.plusDays(34);
        JsonNode longEnough = checkEligibility(token, couponId,
            eligibilityPayload(grandPalacePlaceId, stdTwinRoomId, ci, ci.plusDays(2), "1000000", null),
            status().isOk());
        assertTrue(longEnough.get("eligible").asBoolean());

        JsonNode tooShort = checkEligibility(token, couponId,
            eligibilityPayload(grandPalacePlaceId, stdTwinRoomId, ci, ci.plusDays(1), "1000000", null),
            status().isOk());
        assertFalse(tooShort.get("eligible").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // 25-26: SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anotherUsersCouponEligibilityReturns404() throws Exception {
        String code = uniqueCode("owner404");
        postCouponDef(baseCouponPayload(code, "PERCENTAGE", "10"), status().isCreated());
        String owner = registerAndLogin("targeting-owner404");
        String stranger = registerAndLogin("targeting-stranger404");
        Long couponId = claim(owner, code).get("id").asLong();

        mvc.perform(post("/api/me/coupons/" + couponId + "/eligibility")
                .header("Authorization", "Bearer " + stranger)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(eligibilityPayload(null, null, null, null, "1000000", null))))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticatedEligibilityEndpointRejected() throws Exception {
        mvc.perform(post("/api/me/coupons/1/eligibility")
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(eligibilityPayload(null, null, null, null, "1000000", null))))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BONUS: documented MEMBER/MANUAL decisions + admin eligibility-preview tool
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void memberSegmentAlwaysIneligibleManualSegmentIsNoOp() throws Exception {
        String memberCode = uniqueCode("member");
        ObjectNode memberPayload = baseCouponPayload(memberCode, "PERCENTAGE", "10");
        memberPayload.put("customerSegment", "MEMBER");
        postCouponDef(memberPayload, status().isCreated());

        String token = registerAndLogin("targeting-member");
        // MEMBER is unsupported (no reliable signal in CustomerProfile) — always
        // ineligible, enforced at claim time too.
        mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + memberCode + "\"}"))
            .andExpect(status().isBadRequest());

        String manualCode = uniqueCode("manual");
        ObjectNode manualPayload = baseCouponPayload(manualCode, "PERCENTAGE", "10");
        manualPayload.put("customerSegment", "MANUAL");
        postCouponDef(manualPayload, status().isCreated());
        Long manualCouponId = claim(token, manualCode).get("id").asLong(); // succeeds — MANUAL is a no-op

        JsonNode res = checkEligibility(token, manualCouponId,
            eligibilityPayload(null, null, null, null, "1000000", null), status().isOk());
        assertTrue(res.get("eligible").asBoolean());
        assertTrue(res.get("customerSegmentSatisfied").asBoolean());
    }

    @Test
    void adminEligibilityPreviewEndpointWorks() throws Exception {
        String code = uniqueCode("adminpreview");
        ObjectNode payload = baseCouponPayload(code, "PERCENTAGE", "10");
        payload.put("targetType", "HOTEL");
        payload.put("targetId", grandPalacePlaceId);
        Long defId = postCouponDef(payload, status().isCreated()).get("id").asLong();

        JsonNode matched = getJsonAdmin("/api/admin/coupon-definitions/" + defId
            + "/eligibility-preview?hotelId=" + grandPalacePlaceId + "&orderAmount=1000000");
        assertTrue(matched.get("eligible").asBoolean());
        assertEquals("HOTEL", matched.get("matchedTargetType").asText());

        JsonNode mismatched = getJsonAdmin("/api/admin/coupon-definitions/" + defId
            + "/eligibility-preview?hotelId=" + secondHotelPlaceId + "&orderAmount=1000000");
        assertFalse(mismatched.get("eligible").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

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

    private String registerAndLogin(String namePrefix) throws Exception {
        return registerUser(namePrefix).get("token").asText();
    }

    private JsonNode registerUser(String namePrefix) throws Exception {
        String email = namePrefix + "-" + counter.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + namePrefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String uniqueCode(String prefix) {
        return ("TGT-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
    }

    private ObjectNode baseCouponPayload(String code, String discountType, String discountValue) {
        ObjectNode node = mapper.createObjectNode();
        node.put("code", code);
        node.put("name", "Targeting " + code);
        node.put("description", "Phase 7.17 test coupon");
        node.put("discountType", discountType);
        node.put("discountValue", new BigDecimal(discountValue));
        node.put("validFrom", TODAY.minusDays(1).toString());
        node.put("validUntil", TODAY.plusDays(150).toString());
        node.put("active", true);
        node.put("usageLimitPerUser", 3);
        return node;
    }

    private JsonNode postCouponDef(ObjectNode payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(payload)))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode getCouponDefinitionByCode(String code) throws Exception {
        JsonNode all = mapper.readTree(mvc.perform(get("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        for (JsonNode d : all) {
            if (code.equalsIgnoreCase(d.get("code").asText())) return d;
        }
        return null;
    }

    private ObjectNode eligibilityPayload(Long hotelId, Long roomId, LocalDate checkIn, LocalDate checkOut,
                                           String orderAmount, String travelCreditAmount) {
        ObjectNode node = mapper.createObjectNode();
        if (hotelId != null) node.put("hotelId", hotelId);
        if (roomId != null) node.put("roomId", roomId);
        if (checkIn != null) node.put("checkIn", checkIn.toString());
        if (checkOut != null) node.put("checkOut", checkOut.toString());
        node.put("orderAmount", new BigDecimal(orderAmount));
        if (travelCreditAmount != null) node.put("travelCreditAmount", new BigDecimal(travelCreditAmount));
        return node;
    }

    private JsonNode checkEligibility(String token, Long couponId, ObjectNode payload,
                                       ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/" + couponId + "/eligibility")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(payload)))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private JsonNode claim(String token, String code) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode preview(String token, Long couponId, String orderAmount) throws Exception {
        String body = mvc.perform(post("/api/me/coupons/" + couponId + "/preview")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"orderAmount\":" + orderAmount + "}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String bookingPayload(Long roomId, LocalDate ci, LocalDate co,
                                   String couponCode, String creditAmount) {
        return String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\"," +
            "\"adults\":2,\"children\":0,\"numberOfRooms\":1,\"specialRequest\":null," +
            "\"couponCode\":%s,\"creditAmount\":%s}",
            roomId, ci, co,
            couponCode == null ? "null" : "\"" + couponCode + "\"",
            creditAmount == null ? "null" : creditAmount);
    }

    private JsonNode book(String token, String payload, ResultMatcher expected) throws Exception {
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(expected)
            .andReturn().getResponse().getContentAsString();
        return body.isBlank() ? null : mapper.readTree(body);
    }

    private void grantCredits(Long userId, String amount) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/travel-credits/grant")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"amount\":" + amount + ",\"currency\":\"VND\"," +
                         "\"description\":\"Phase 7.17 test grant\"}"))
            .andExpect(status().isCreated());
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getJsonAdmin(String url) throws Exception {
        String body = mvc.perform(get(url)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void assertDecimal(String expected, JsonNode actual) {
        assertNotNull(actual);
        assertEquals(0, new BigDecimal(expected).compareTo(new BigDecimal(actual.asText())),
            "expected " + expected + " but was " + actual.asText());
    }

    // ── Fixture setup: a second bookable hotel + a non-accommodation place ────
    // (built directly via repositories, mirroring DataInitializer's own
    // place()/roomFor() patterns, since only one seeded hotel — Grand Palace —
    // has bookable rooms.)

    private void ensureSecondHotel() {
        String slug = "coupon-targeting-second-hotel";
        var existing = placeRepo.findBySlug(slug);
        if (existing.isPresent()) {
            secondHotelPlaceId = existing.get().getId();
            Long detailId = hotelDetailRepo.findByPlaceId(secondHotelPlaceId).orElseThrow().getId();
            secondHotelRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).get(0).getId();
            return;
        }

        User admin = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow();
        Category cat = categoryRepo.findBySlug("accommodation").orElseThrow();
        AdministrativeUnit loc = locationRepo.findByCode("VT").orElseThrow();

        Place p = new Place();
        p.setName("Coupon Targeting Second Hotel");
        p.setNameNormalized(SlugUtils.normalize("Coupon Targeting Second Hotel"));
        p.setSlug(slug);
        p.setCategory(cat);
        p.setAdministrativeUnit(loc);
        p.setAddress("1 Test Street, Vung Tau");
        p.setStatus(PlaceStatus.PUBLISHED);
        p.setCreatedBy(admin);
        p = placeRepo.save(p);
        secondHotelPlaceId = p.getId();

        HotelDetail d = new HotelDetail();
        d.setPlace(p);
        d.setStarRating(3);
        d.setCheckInTime(LocalTime.of(14, 0));
        d.setCheckOutTime(LocalTime.of(12, 0));
        d = hotelDetailRepo.save(d);

        HotelRoom r = new HotelRoom();
        r.setHotelDetail(d);
        r.setRoomName("Second Hotel Standard Room");
        r.setRoomCode("SEC-STD");
        r.setRoomType(RoomType.STANDARD);
        r.setMaxAdults(2);
        r.setMaxChildren(1);
        r.setMaxGuests(3);
        r.setPriceFrom(new BigDecimal("800000.00"));
        r.setQuantity(10);
        r.setAvailableQuantity(10);
        r.setActive(true);
        r = hotelRoomRepo.save(r);
        secondHotelRoomId = r.getId();

        for (int i = 0; i < 160; i++) {
            RoomInventory inv = new RoomInventory();
            inv.setHotelRoom(r);
            inv.setInventoryDate(TODAY.plusDays(i));
            inv.setTotalInventory(20);
            inv.setAvailableInventory(18);
            inv.setBlockedInventory(1);
            inv.setSoldInventory(0);
            inv.setMaintenanceInventory(1);
            roomInventoryRepo.save(inv);
        }
    }

    private void ensureWrongTypePlace() {
        String slug = "coupon-targeting-wrong-type-place";
        var existing = placeRepo.findBySlug(slug);
        if (existing.isPresent()) {
            wrongTypePlaceId = existing.get().getId();
            return;
        }

        User admin = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow();
        Category cat = categoryRepo.findBySlug("cafe").orElseThrow();
        AdministrativeUnit loc = locationRepo.findByCode("VT").orElseThrow();

        Place p = new Place();
        p.setName("Coupon Targeting Wrong Type Place");
        p.setNameNormalized(SlugUtils.normalize("Coupon Targeting Wrong Type Place"));
        p.setSlug(slug);
        p.setCategory(cat);
        p.setAdministrativeUnit(loc);
        p.setAddress("2 Test Street, Vung Tau");
        p.setStatus(PlaceStatus.PUBLISHED);
        p.setCreatedBy(admin);
        p = placeRepo.save(p);
        wrongTypePlaceId = p.getId();
    }
}
