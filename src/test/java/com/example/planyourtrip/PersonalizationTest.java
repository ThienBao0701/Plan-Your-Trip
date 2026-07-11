package com.example.planyourtrip;

import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.model.Category;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultMatcher;

import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PersonalizationTest — Phase 7.23 (Personalized Offers &amp; Rule-Based
 * Recommendations). Covers admin rule CRUD/validation, signal-driven generation
 * (wishlist / recently-viewed / booking history / travel style / membership
 * tier), eligibility filtering (inactive promotion, unpublished place), score
 * ordering, duplicate-prevention, engagement tracking (dismiss/click/convert),
 * ownership isolation, the type-specific and summary endpoints, admin
 * support/generation, security, seeded rules, and confirmation that generation
 * never claims coupons or mutates booking/pricing state. Each scenario uses fresh
 * throwaway users and its own data so state never leaks; broad admin rules are
 * cleaned up after use.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PersonalizationTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository unitRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private String adminTokenCache;
    private Long stdTwinRoomId;

    // ═══════════════════════════════════════════════════════════════════════
    // 1: ADMIN CREATES RULE
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void adminCreatesPersonalizationRule() throws Exception {
        Map<String, Object> body = rule(ruleCode("WISH"), "WISHLIST_AFFINITY");
        body.put("priority", 55);
        JsonNode created = createRule(body);
        assertNotNull(created.get("id"));
        assertTrue(created.get("active").asBoolean());
        assertEquals("WISHLIST_AFFINITY", created.get("ruleType").asText());
        assertEquals(55, created.get("priority").asInt());
        deleteRule(created.get("id").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 2: DUPLICATE RULE CODE REJECTED (case-insensitive)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void duplicateRuleCodeRejectedCaseInsensitively() throws Exception {
        String code = ruleCode("DUP");
        JsonNode created = createRule(rule(code, "TRENDING"));
        mvc.perform(post("/api/admin/personalization-rules")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(rule(code.toLowerCase(), "TRENDING"))))
            .andExpect(status().isConflict());
        deleteRule(created.get("id").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 3: INVALID DATE RANGE REJECTED
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void invalidRuleDateRangeRejected() throws Exception {
        Map<String, Object> body = rule(ruleCode("DATE"), "TRENDING");
        body.put("validFrom", "2030-01-01T00:00:00Z");
        body.put("validUntil", "2029-01-01T00:00:00Z");
        mvc.perform(post("/api/admin/personalization-rules")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isBadRequest());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 4: INACTIVE RULE IGNORED
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void inactiveRuleIsIgnoredDuringGeneration() throws Exception {
        Long placeId = createPlace(cafeCategoryId(), unitId("DL"), "inactive-rule");
        Map<String, Object> body = rule(ruleCode("MAN"), "MANUAL");
        body.put("targetPlaceId", placeId);
        JsonNode ruleNode = createRule(body);
        Long ruleId = ruleNode.get("id").asLong();

        JsonNode user = registerUser("rec-inactive");
        String token = token(user);

        // Active manual rule → the target place is recommended.
        assertTrue(hasTarget(generate(token), "PLACE", placeId), "active manual rule should recommend its target");

        // Deactivate → regenerate → target gone.
        mvc.perform(patch("/api/admin/personalization-rules/" + ruleId + "/deactivate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.active").value(false));
        assertFalse(hasTarget(generate(token), "PLACE", placeId), "inactive rule must be ignored");

        deleteRule(ruleId);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 5: USER GENERATES RECOMMENDATIONS
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void userGeneratesRecommendations() throws Exception {
        Long unit = unitId("DL");
        Long anchor = createPlace(cafeCategoryId(), unit, "gen-anchor");
        createPlace(cafeCategoryId(), unit, "gen-similar");

        JsonNode user = registerUser("rec-gen");
        String token = token(user);
        addWishlist(token, anchor);

        JsonNode gen = generate(token);
        assertTrue(gen.get("generatedCount").asInt() > 0);
        assertTrue(gen.get("totalActive").asInt() > 0);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 6: WISHLIST AFFINITY GENERATES MATCHING RECOMMENDATION
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void wishlistAffinityGeneratesMatchingRecommendation() throws Exception {
        Long unit = unitId("DL");
        Long anchor = createPlace(cafeCategoryId(), unit, "wish-anchor");
        Long similar = createPlace(cafeCategoryId(), unit, "wish-similar");

        JsonNode user = registerUser("rec-wish");
        String token = token(user);
        addWishlist(token, anchor);

        JsonNode gen = generate(token);
        JsonNode rec = findTarget(gen, "PLACE", similar);
        assertNotNull(rec, "a similar place should be recommended from wishlist affinity");
        assertEquals("SAVED_SIMILAR_PLACE", rec.get("reasonCode").asText());
        // Anchor (the saved place itself) is not re-recommended as a similar place.
        assertNull(findTarget(gen, "PLACE", anchor));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 7: RECENTLY VIEWED GENERATES MATCHING RECOMMENDATION
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void recentlyViewedGeneratesMatchingRecommendation() throws Exception {
        Long unit = unitId("HL");
        Long anchor = createPlace(cafeCategoryId(), unit, "recent-anchor");
        Long similar = createPlace(cafeCategoryId(), unit, "recent-similar");

        JsonNode user = registerUser("rec-recent");
        String token = token(user);
        recordView(token, anchor);

        JsonNode gen = generate(token);
        JsonNode rec = findTarget(gen, "PLACE", similar);
        assertNotNull(rec, "a similar place should be recommended from recently-viewed affinity");
        assertEquals("VIEWED_SIMILAR_PLACE", rec.get("reasonCode").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 8: BOOKING HISTORY INFLUENCES SCORING
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void bookingHistoryInfluencesScoring() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DNC"), "book-anchor");
        Long candidateVt = createPlace(cafeCategoryId(), unitId("VT"), "book-vt");   // in booked destination
        Long candidateDl = createPlace(cafeCategoryId(), unitId("DL"), "book-dl");   // elsewhere

        JsonNode user = registerUser("rec-booking");
        String token = token(user);
        addWishlist(token, anchor); // wishlist a cafe → both candidates qualify (same category)

        // Complete a booking at Grand Palace (Vũng Tàu / VT) — establishes a booked destination signal.
        JsonNode booking = createBooking(token, TODAY.plusDays(40), TODAY.plusDays(42));
        completeBooking(booking.get("id").asLong());

        JsonNode gen = generate(token);
        JsonNode vt = findTarget(gen, "PLACE", candidateVt);
        JsonNode dl = findTarget(gen, "PLACE", candidateDl);
        assertNotNull(vt);
        assertNotNull(dl);
        assertTrue(vt.get("score").asInt() > dl.get("score").asInt(),
            "a candidate in the previously-booked destination must score higher");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 9: TRAVEL STYLE INFLUENCES SCORING
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void travelStyleInfluencesScoring() throws Exception {
        Long unit = unitId("DL");
        Long matching = createPlace(cafeCategoryId(), unit, "style-match");
        setMetadataStyle(matching, "SOLO");
        Long nonMatching = createPlace(cafeCategoryId(), unit, "style-nomatch");
        setMetadataStyle(nonMatching, "LUXURY");

        JsonNode ruleNode = createRule(rule(ruleCode("STYLE"), "TRAVEL_STYLE"));
        Long ruleId = ruleNode.get("id").asLong();

        JsonNode user = registerUser("rec-style");
        String token = token(user);
        setTravelStyle(token, "SOLO");

        JsonNode gen = generate(token);
        JsonNode match = findTarget(gen, "PLACE", matching);
        assertNotNull(match, "place matching the customer's travel style should be recommended");
        assertEquals("MATCHED_TRAVEL_STYLE", match.get("reasonCode").asText());
        assertTrue(match.get("score").asInt() >= 20);
        // Non-matching style place is not generated by the travel-style rule (no other signal).
        assertNull(findTarget(gen, "PLACE", nonMatching));

        deleteRule(ruleId);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 10: MEMBERSHIP-TIER RULE ELIGIBILITY
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void membershipTierRuleEligibilityWorks() throws Exception {
        Long couponId = createTierCoupon(couponCode("TIER"), "SILVER");

        // User with NO membership → tier-exclusive coupon not recommended.
        JsonNode noTier = registerUser("rec-notier");
        String noTierToken = token(noTier);
        assertFalse(hasTarget(generate(noTierToken), "COUPON", couponId),
            "a user below the required tier must not receive a tier-exclusive coupon");

        // User assigned GOLD (>= SILVER) → recommended via the seeded MEMBERSHIP_TIER rule.
        JsonNode goldUser = registerUser("rec-gold");
        String goldToken = token(goldUser);
        assignTier(userId(goldUser), "GOLD");
        assertTrue(hasTarget(generate(goldToken), "COUPON", couponId),
            "a member at/above the required tier must receive the tier-exclusive coupon");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 11: INACTIVE PROMOTION NOT RECOMMENDED
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void inactivePromotionIsNotRecommended() throws Exception {
        Long inactivePromo = createPromotion(promoCode("INACT"), false);

        JsonNode user = registerUser("rec-inactivepromo");
        String token = token(user);
        // Make the user a returning customer so the re-engagement rule runs.
        JsonNode booking = createBooking(token, TODAY.plusDays(43), TODAY.plusDays(45));
        completeBooking(booking.get("id").asLong());

        JsonNode gen = generate(token);
        assertFalse(hasTarget(gen, "PROMOTION", inactivePromo),
            "an inactive promotion must never be recommended");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 12: UNPUBLISHED PLACE NOT RECOMMENDED
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void unpublishedPlaceIsNotRecommended() throws Exception {
        Long draftPlace = createDraftPlace(cafeCategoryId(), unitId("DL"), "draft-place");
        Map<String, Object> body = rule(ruleCode("MANDRAFT"), "MANUAL");
        body.put("targetPlaceId", draftPlace);
        JsonNode ruleNode = createRule(body);
        Long ruleId = ruleNode.get("id").asLong();

        JsonNode user = registerUser("rec-draft");
        JsonNode gen = generate(token(user));
        assertFalse(hasTarget(gen, "PLACE", draftPlace),
            "an unpublished (DRAFT) place must be filtered out by eligibility");

        deleteRule(ruleId);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 13: SCORES SORTED DESCENDING
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void recommendationScoresSortedDescending() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "sort-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "sort-high"); // shares dest + category → higher
        createPlace(cafeCategoryId(), unitId("HL"), "sort-low");  // shares category only → lower

        JsonNode user = registerUser("rec-sort");
        String token = token(user);
        addWishlist(token, anchor);
        generate(token);

        JsonNode page = getJson(token, "/api/me/recommendations?size=100");
        JsonNode content = page.get("content");
        assertTrue(content.size() >= 2);
        int prev = Integer.MAX_VALUE;
        for (JsonNode r : content) {
            int score = r.get("score").asInt();
            assertTrue(score <= prev, "recommendations must be sorted by score descending");
            prev = score;
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 14: DUPLICATE ACTIVE RECOMMENDATION PREVENTED
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void duplicateActiveRecommendationPrevented() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "dup-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "dup-similar");

        JsonNode user = registerUser("rec-dup");
        String token = token(user);
        addWishlist(token, anchor);
        generate(token);
        generate(token); // regenerate

        JsonNode page = getJson(token, "/api/me/recommendations?size=100");
        java.util.Set<String> keys = new java.util.HashSet<>();
        for (JsonNode r : page.get("content")) {
            String key = r.get("type").asText() + ":" + targetId(r);
            assertTrue(keys.add(key), "no duplicate active recommendation for the same user+type+target");
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 15: REGENERATION PRESERVES CLICKED HISTORY
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void regenerationPreservesClickedRecommendationHistory() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "clickhist-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "clickhist-similar");

        JsonNode user = registerUser("rec-clickhist");
        String token = token(user);
        addWishlist(token, anchor);
        JsonNode gen = generate(token);
        Long recId = gen.get("recommendations").get(0).get("id").asLong();

        patchOk(token, "/api/me/recommendations/" + recId + "/click");
        generate(token); // regenerate — must NOT delete the engaged snapshot

        JsonNode still = getJson(token, "/api/me/recommendations/" + recId);
        assertEquals(recId, still.get("id").asLong());
        assertNotNull(still.get("clickedAt"));
        assertFalse(still.get("clickedAt").isNull(), "clicked recommendation must survive regeneration");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 16: DISMISS HIDES FROM DEFAULT LIST
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void dismissHidesRecommendationFromDefaultList() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "dismiss-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "dismiss-similar");

        JsonNode user = registerUser("rec-dismiss");
        String token = token(user);
        addWishlist(token, anchor);
        JsonNode gen = generate(token);
        Long recId = gen.get("recommendations").get(0).get("id").asLong();

        patchOk(token, "/api/me/recommendations/" + recId + "/dismiss");

        assertFalse(pageContains(getJson(token, "/api/me/recommendations?size=100"), recId),
            "dismissed recommendation must be hidden from the default list");
        assertTrue(pageContains(getJson(token, "/api/me/recommendations?size=100&includeDismissed=true"), recId),
            "dismissed recommendation must still be visible when includeDismissed=true");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 17-18: CLICK / CONVERT IDEMPOTENT
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void clickIsIdempotent() throws Exception {
        Long recId = firstRecId("rec-click");
        String token = clickTokenCache;
        patchOk(token, "/api/me/recommendations/" + recId + "/click");
        // Compare persisted (DB-truncated) values so this asserts idempotency, not clock precision.
        String firstAt = getJson(token, "/api/me/recommendations/" + recId).get("clickedAt").asText();
        patchOk(token, "/api/me/recommendations/" + recId + "/click");
        String secondAt = getJson(token, "/api/me/recommendations/" + recId).get("clickedAt").asText();
        assertEquals(firstAt, secondAt, "click timestamp must not change on repeat");
    }

    @Test
    void conversionIsIdempotent() throws Exception {
        Long recId = firstRecId("rec-convert");
        String token = clickTokenCache;
        patchOk(token, "/api/me/recommendations/" + recId + "/convert");
        String firstAt = getJson(token, "/api/me/recommendations/" + recId).get("convertedAt").asText();
        patchOk(token, "/api/me/recommendations/" + recId + "/convert");
        String secondAt = getJson(token, "/api/me/recommendations/" + recId).get("convertedAt").asText();
        assertEquals(firstAt, secondAt, "convert timestamp must not change on repeat");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 19-20: OWNERSHIP ISOLATION
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void userSeesOnlyOwnRecommendations() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "own-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "own-similar");

        JsonNode userA = registerUser("rec-owner-a");
        String tokenA = token(userA);
        addWishlist(tokenA, anchor);
        JsonNode gen = generate(tokenA);
        Long recId = gen.get("recommendations").get(0).get("id").asLong();

        JsonNode userB = registerUser("rec-owner-b");
        String tokenB = token(userB);
        assertEquals(0, getJson(tokenB, "/api/me/recommendations?size=100").get("content").size(),
            "a fresh user sees none of another user's recommendations");
    }

    @Test
    void anotherUsersRecommendationReturns404() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "x-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "x-similar");

        JsonNode userA = registerUser("rec-x-a");
        String tokenA = token(userA);
        addWishlist(tokenA, anchor);
        Long recId = generate(tokenA).get("recommendations").get(0).get("id").asLong();

        JsonNode userB = registerUser("rec-x-b");
        mvc.perform(get("/api/me/recommendations/" + recId)
                .header("Authorization", "Bearer " + token(userB)))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 21: PLACE ENDPOINT
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void placeEndpointReturnsPlaceRecommendations() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "pe-anchor");
        Long similar = createPlace(cafeCategoryId(), unitId("DL"), "pe-similar");

        JsonNode user = registerUser("rec-placeep");
        String token = token(user);
        addWishlist(token, anchor);
        generate(token);

        JsonNode places = getJson(token, "/api/me/recommendations/places");
        assertTrue(places.size() > 0);
        for (JsonNode r : places) {
            String type = r.get("type").asText();
            assertTrue(type.equals("PLACE") || type.equals("TRIP_IDEA"));
        }
        assertTrue(listContains(places, "PLACE", similar));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 22: HOTEL ENDPOINT
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void hotelEndpointReturnsHotelRecommendations() throws Exception {
        Long grandPalaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Map<String, Object> body = rule(ruleCode("MANHOTEL"), "MANUAL");
        body.put("targetHotelId", grandPalaceId);
        JsonNode ruleNode = createRule(body);
        Long ruleId = ruleNode.get("id").asLong();

        JsonNode user = registerUser("rec-hotelep");
        String token = token(user);
        generate(token);

        JsonNode hotels = getJson(token, "/api/me/recommendations/hotels");
        assertTrue(listContains(hotels, "HOTEL", grandPalaceId),
            "hotel endpoint must return the manually-targeted hotel recommendation");

        deleteRule(ruleId);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 23: OFFERS ENDPOINT
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void offersEndpointReturnsPromotionAndCouponRecommendations() throws Exception {
        // Target a specific promotion AND coupon via MANUAL rules so the offers are
        // deterministic and independent of how many other offers exist globally.
        Long activePromo = createPromotion(promoCode("OFFER"), true);
        Long coupon = createTierCoupon(couponCode("OFFERCPN"), "BRONZE");

        Map<String, Object> promoRule = rule(ruleCode("MANOFFERP"), "MANUAL");
        promoRule.put("targetPromotionId", activePromo);
        Long promoRuleId = createRule(promoRule).get("id").asLong();
        Map<String, Object> couponRule = rule(ruleCode("MANOFFERC"), "MANUAL");
        couponRule.put("targetCouponDefinitionId", coupon);
        Long couponRuleId = createRule(couponRule).get("id").asLong();

        JsonNode user = registerUser("rec-offers");
        String token = token(user);
        assignTier(userId(user), "GOLD"); // eligible for the BRONZE-gated coupon
        generate(token);

        JsonNode offers = getJson(token, "/api/me/recommendations/offers");
        assertTrue(offers.size() > 0, "offers endpoint should return promotion/coupon recommendations");
        for (JsonNode r : offers) {
            String type = r.get("type").asText();
            assertTrue(type.equals("PROMOTION") || type.equals("COUPON"));
        }
        assertTrue(listContains(offers, "PROMOTION", activePromo), "targeted promotion should appear in offers");
        assertTrue(listContains(offers, "COUPON", coupon), "targeted coupon should appear in offers");

        deleteRule(promoRuleId);
        deleteRule(couponRuleId);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 24: SUMMARY METRICS
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void summaryMetricsAreCorrect() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "sum-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "sum-similar");

        JsonNode user = registerUser("rec-summary");
        String token = token(user);
        addWishlist(token, anchor);
        JsonNode gen = generate(token);
        int generated = gen.get("generatedCount").asInt();

        JsonNode summary = getJson(token, "/api/me/recommendations/summary");
        assertEquals(generated, summary.get("totalActive").asLong());
        assertTrue(summary.get("placeRecommendations").asLong() >= 1);
        assertEquals(0, summary.get("dismissedCount").asLong());
        assertNotNull(summary.get("lastGeneratedAt"));

        // Dismiss one → dismissedCount rises, totalActive falls.
        Long recId = gen.get("recommendations").get(0).get("id").asLong();
        patchOk(token, "/api/me/recommendations/" + recId + "/dismiss");
        JsonNode after = getJson(token, "/api/me/recommendations/summary");
        assertEquals(1, after.get("dismissedCount").asLong());
        assertEquals(generated - 1, after.get("totalActive").asLong());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 25-26: ADMIN SUPPORT VIEW + GENERATION
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void adminCanInspectAndGenerateCustomerRecommendations() throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), "admin-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), "admin-similar");

        JsonNode user = registerUser("rec-adminview");
        String token = token(user);
        Long uid = userId(user);
        addWishlist(token, anchor);

        // Admin generates for the customer (reuses the same engine).
        String genBody = mvc.perform(post("/api/admin/users/" + uid + "/recommendations/generate")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(genBody).get("generatedCount").asInt() > 0);

        // Admin inspects the customer's recommendations (read-only view).
        JsonNode view = getJsonAdmin("/api/admin/users/" + uid + "/recommendations?size=100");
        assertTrue(view.get("content").size() > 0);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 27-28: SECURITY
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void nonAdminCannotManageRulesOrAdminViews() throws Exception {
        JsonNode user = registerUser("rec-nonadmin");
        String token = token(user);
        Long uid = userId(user);

        mvc.perform(get("/api/admin/personalization-rules")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
        mvc.perform(post("/api/admin/personalization-rules")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(rule(ruleCode("NOPE"), "TRENDING"))))
            .andExpect(status().isForbidden());
        mvc.perform(get("/api/admin/users/" + uid + "/recommendations")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedRecommendationEndpointsRejected() throws Exception {
        mvc.perform(get("/api/me/recommendations")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/recommendations/summary")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/me/recommendations/generate")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/me/recommendations/places")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 29: SEEDED RULES EXIST
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void seededRulesExist() throws Exception {
        JsonNode rules = getJsonAdmin("/api/admin/personalization-rules");
        java.util.Set<String> codes = new java.util.HashSet<>();
        for (JsonNode r : rules) codes.add(r.get("ruleCode").asText());
        assertTrue(codes.contains("WISHLIST_AFFINITY_DEFAULT"));
        assertTrue(codes.contains("RECENTLY_VIEWED_DEFAULT"));
        assertTrue(codes.contains("MEMBERSHIP_TIER_DEFAULT"));
        assertTrue(codes.contains("REENGAGEMENT_DEFAULT"));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // 30: GENERATION DOES NOT CLAIM COUPONS OR MUTATE BOOKING/PRICING
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void generationDoesNotClaimCouponsOrChangeBookingState() throws Exception {
        JsonNode user = registerUser("rec-nomutate");
        String token = token(user);
        JsonNode booking = createBooking(token, TODAY.plusDays(49), TODAY.plusDays(51));
        String finalPriceBefore = booking.get("finalPrice").asText();
        completeBooking(booking.get("id").asLong());

        JsonNode gen = generate(token);
        // Coupons may be recommended, but never auto-claimed.
        boolean recommendedACoupon = false;
        for (JsonNode r : gen.get("recommendations")) {
            if (r.get("type").asText().equals("COUPON")) { recommendedACoupon = true; break; }
        }
        JsonNode myCoupons = getJson(token, "/api/me/coupons");
        assertEquals(0, myCoupons.size(),
            "generation must never auto-claim coupons (even when one is recommended: " + recommendedACoupon + ")");

        // Booking final price is unchanged by recommendation generation.
        JsonNode bookingAfter = getJson(token, "/api/bookings/" + booking.get("id").asLong());
        assertEquals(finalPriceBefore, bookingAfter.get("finalPrice").asText(),
            "recommendation generation must not change booking pricing");
    }

    // ═══════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════

    private String clickTokenCache;

    /** Generates a wishlist-affinity recommendation set and returns the first rec id (caches its token). */
    private Long firstRecId(String prefix) throws Exception {
        Long anchor = createPlace(cafeCategoryId(), unitId("DL"), prefix + "-anchor");
        createPlace(cafeCategoryId(), unitId("DL"), prefix + "-similar");
        JsonNode user = registerUser(prefix);
        clickTokenCache = token(user);
        addWishlist(clickTokenCache, anchor);
        return generate(clickTokenCache).get("recommendations").get(0).get("id").asLong();
    }

    private Map<String, Object> rule(String code, String type) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("ruleCode", code);
        m.put("name", "Rule " + code);
        m.put("ruleType", type);
        m.put("active", true);
        return m;
    }

    private JsonNode createRule(Map<String, Object> body) throws Exception {
        String resp = mvc.perform(post("/api/admin/personalization-rules")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private void deleteRule(Long id) throws Exception {
        mvc.perform(delete("/api/admin/personalization-rules/" + id)
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isNoContent());
    }

    private JsonNode generate(String token) throws Exception {
        String resp = mvc.perform(post("/api/me/recommendations/generate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private JsonNode patchOk(String token, String url) throws Exception {
        String resp = mvc.perform(patch(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp);
    }

    private boolean hasTarget(JsonNode gen, String type, Long targetId) {
        return findTarget(gen, type, targetId) != null;
    }

    private JsonNode findTarget(JsonNode gen, String type, Long targetId) {
        for (JsonNode r : gen.get("recommendations")) {
            if (r.get("type").asText().equals(type) && targetId.equals(targetId(r))) return r;
        }
        return null;
    }

    private boolean listContains(JsonNode list, String type, Long targetId) {
        for (JsonNode r : list) {
            if (r.get("type").asText().equals(type) && targetId.equals(targetId(r))) return true;
        }
        return false;
    }

    private boolean pageContains(JsonNode page, Long recId) {
        for (JsonNode r : page.get("content")) if (r.get("id").asLong() == recId) return true;
        return false;
    }

    /** Resolves the underlying target entity id from a recommendation response. */
    private Long targetId(JsonNode r) {
        String type = r.get("type").asText();
        JsonNode node = switch (type) {
            case "PLACE", "TRIP_IDEA" -> r.get("place");
            case "HOTEL" -> r.get("hotel");
            case "ROOM" -> r.get("room");
            case "PROMOTION" -> r.get("promotion");
            case "COUPON" -> r.get("coupon");
            default -> null;
        };
        if (node == null || node.isNull()) return null;
        JsonNode idNode = node.has("id") ? node.get("id")
            : node.has("promotionId") ? node.get("promotionId") : null;
        return idNode == null ? null : idNode.asLong();
    }

    private Long createPlace(Long catId, Long unitId, String prefix) throws Exception {
        return createPlaceWithStatus(catId, unitId, prefix, "PUBLISHED");
    }

    private Long createDraftPlace(Long catId, Long unitId, String prefix) throws Exception {
        return createPlaceWithStatus(catId, unitId, prefix, "DRAFT");
    }

    private Long createPlaceWithStatus(Long catId, Long unitId, String prefix, String status) throws Exception {
        String name = prefix + "-" + counter.getAndIncrement();
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", name);
        body.put("categoryId", catId);
        body.put("administrativeUnitId", unitId);
        body.put("address", "1 Test Street");
        body.put("priceLevel", 1);
        body.put("featured", false);
        body.put("verified", false);
        body.put("status", status);
        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void setMetadataStyle(Long placeId, String style) throws Exception {
        mvc.perform(put("/api/admin/places/" + placeId + "/metadata")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"travelStyles\":[\"" + style + "\"]}"))
            .andExpect(status().isOk());
    }

    private Long createTierCoupon(String code, String minimumTier) throws Exception {
        String payload = String.format("""
                {"code":"%s","name":"Tier coupon %s","discountType":"PERCENTAGE","discountValue":10,
                 "validFrom":"%s","validUntil":"%s","active":true,"usageLimitPerUser":5,"minimumTier":"%s"}
                """, code, code, TODAY.minusDays(1), TODAY.plusDays(200), minimumTier);
        String resp = mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private Long createPromotion(String code, boolean active) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "Promo " + code);
        body.put("code", code);
        body.put("promotionType", "GENERAL");
        body.put("discountType", "PERCENTAGE");
        body.put("discountValue", 10);
        body.put("startDate", TODAY.minusDays(1).toString());
        body.put("endDate", TODAY.plusDays(60).toString());
        body.put("active", active);
        String resp = mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(mapper.writeValueAsString(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(resp).get("id").asLong();
    }

    private void assignTier(Long userId, String tier) throws Exception {
        mvc.perform(post("/api/admin/users/" + userId + "/membership/assign")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"tier\":\"" + tier + "\",\"reason\":\"test assignment\"}"))
            .andExpect(status().isOk());
    }

    private void addWishlist(String token, Long placeId) throws Exception {
        mvc.perform(post("/api/me/wishlist/items")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"placeId\":" + placeId + "}"))
            .andExpect(status().isCreated());
    }

    private void recordView(String token, Long placeId) throws Exception {
        mvc.perform(post("/api/me/recently-viewed/" + placeId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().is2xxSuccessful());
    }

    private void setTravelStyle(String token, String style) throws Exception {
        mvc.perform(put("/api/me/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"travelStyle\":\"" + style + "\"}"))
            .andExpect(status().isOk());
    }

    private JsonNode createBooking(String token, LocalDate ci, LocalDate co) throws Exception {
        Long roomId = resolveStdTwinRoomId();
        String payload = String.format(
            "{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":1,\"children\":0,\"numberOfRooms\":1}",
            roomId, ci, co);
        String body = mvc.perform(post("/api/bookings")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(payload))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private synchronized Long resolveStdTwinRoomId() {
        if (stdTwinRoomId != null) return stdTwinRoomId;
        Long placeId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(placeId).orElseThrow().getId();
        stdTwinRoomId = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .filter(r -> "STD-TWIN".equals(r.getRoomCode()))
            .findFirst().orElseThrow().getId();
        return stdTwinRoomId;
    }

    private void completeBooking(Long bookingId) throws Exception {
        mvc.perform(patch("/api/admin/bookings/" + bookingId + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"COMPLETED\"}"))
            .andExpect(status().isOk());
    }

    private Long cafeCategoryIdCache;

    private synchronized Long cafeCategoryId() {
        if (cafeCategoryIdCache == null)
            cafeCategoryIdCache = categoryRepo.findBySlug("cafe").orElseThrow().getId();
        return cafeCategoryIdCache;
    }

    private Long unitId(String code) {
        return unitRepo.findByCode(code).map(AdministrativeUnit::getId).orElseThrow();
    }

    private String adminToken() throws Exception {
        if (adminTokenCache == null) adminTokenCache = login("admin@planyourtrip.com", "admin123456");
        return adminTokenCache;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
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

    private String token(JsonNode user) { return user.get("token").asText(); }

    private Long userId(JsonNode user) { return user.get("user").get("id").asLong(); }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode getJsonAdmin(String url) throws Exception {
        return getJson(adminToken(), url);
    }

    private String ruleCode(String p) { return (p + "-" + counter.getAndIncrement()).toUpperCase(); }
    private String couponCode(String p) { return (p + counter.getAndIncrement()).toUpperCase(); }
    private String promoCode(String p) { return (p + counter.getAndIncrement()).toUpperCase(); }
}
