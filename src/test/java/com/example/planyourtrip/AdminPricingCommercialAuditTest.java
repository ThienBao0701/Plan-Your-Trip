package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D3H — the administrative audit trail for pricing, inventory and commercial configuration.
 *
 * <p>The production-readiness checkpoint counted 34 admin mutations across eight services that
 * committed with nothing recording who performed them: rate plans and occupancy prices, room
 * inventory, gift-card products, coupon definitions, promotions, the loyalty redemption policy,
 * referral campaigns and membership tiers. Between them they set what the platform charges, how
 * much of it can be discounted away, how many rooms may be sold and how much value is minted per
 * booking — the changes an investigation into a revenue anomaly would need to reconstruct first.
 *
 * <p>These tests pin the properties D3F and D3G pinned for catalog and hotel data, and add the one
 * this phase turns on specifically: six of these services are also partner write paths, so the
 * suite proves a partner changing the <em>same</em> business object through their own endpoint
 * produces no administrative row at all.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AdminPricingCommercialAuditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);

    private String adminToken;
    private String userToken;
    private Long adminUserId;
    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        userToken = login("demo@planyourtrip.com", "demo123456");
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
        accCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // RATE PLANS — 7 mutations
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void ratePlanLifecycleIsFullyAudited() throws Exception {
        Long roomId = ownRoom();

        Long planId = idOf(adminPost("/api/admin/rooms/" + roomId + "/rate-plans",
            ratePlan("450000"), 201));
        AdminActivityLog created = one("RATE_PLAN_CREATE", planId);
        assertEquals("RATE_PLAN", created.getTargetType());
        assertEquals(planId, created.getTargetId());
        assertEquals(adminUserId, created.getActorUserId());
        assertNull(created.getBeforeState());
        assertTrue(created.getAfterState().contains("price:450000"), created.getAfterState());
        assertTrue(created.getDescription().contains("room " + roomId), created.getDescription());

        adminPut("/api/admin/rate-plans/" + planId, ratePlan("990000"), 200);
        AdminActivityLog updated = one("RATE_PLAN_UPDATE", planId);
        assertTrue(updated.getBeforeState().contains("price:450000"), updated.getBeforeState());
        assertTrue(updated.getAfterState().contains("price:990000"), updated.getAfterState());

        adminPost("/api/admin/rate-plans/" + planId + "/deactivate", null, 200);
        AdminActivityLog off = one("RATE_PLAN_DEACTIVATE", planId);
        assertTrue(off.getBeforeState().startsWith("active:true"), off.getBeforeState());
        assertTrue(off.getAfterState().startsWith("active:false"), off.getAfterState());

        adminPost("/api/admin/rate-plans/" + planId + "/activate", null, 200);
        AdminActivityLog on = one("RATE_PLAN_ACTIVATE", planId);
        assertTrue(on.getBeforeState().startsWith("active:false"), on.getBeforeState());
        assertTrue(on.getAfterState().startsWith("active:true"), on.getAfterState());

        Long copyId = idOf(adminPost("/api/admin/rate-plans/" + planId + "/duplicate", null, 201));
        AdminActivityLog dup = one("RATE_PLAN_DUPLICATE", copyId);
        assertEquals(copyId, dup.getTargetId(),
            "the target must be the row the duplicate created, not the row it was copied from");
        assertTrue(dup.getDescription().contains("duplicated rate plan " + planId),
            "the source plan belongs in the description: " + dup.getDescription());
    }

    @Test
    void occupancyPriceCreateAndUpdateAreAudited() throws Exception {
        Long planId = ownRatePlan();

        Long priceId = idOf(adminPost("/api/admin/rate-plans/" + planId + "/occupancy-prices", """
            {"adults":2,"children":1,"pricePerNight":600000,"childSupplement":50000,
             "extraBedSupplement":80000}
            """, 201));
        AdminActivityLog created = one("RATE_PLAN_OCCUPANCY_PRICE_CREATE", priceId);
        assertEquals("RATE_PLAN_OCCUPANCY_PRICE", created.getTargetType());
        assertEquals(priceId, created.getTargetId(),
            "the target must be the occupancy price, not its parent rate plan");
        assertTrue(created.getAfterState().contains("adults:2"), created.getAfterState());

        adminPut("/api/admin/rate-plan-occupancy-prices/" + priceId, """
            {"adults":2,"children":1,"pricePerNight":750000,"childSupplement":50000,
             "extraBedSupplement":80000}
            """, 200);
        AdminActivityLog updated = one("RATE_PLAN_OCCUPANCY_PRICE_UPDATE", priceId);
        assertTrue(updated.getBeforeState().contains("price:600000"), updated.getBeforeState());
        assertTrue(updated.getAfterState().contains("price:750000"), updated.getAfterState());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // ROOM INVENTORY — 3 mutations
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void inventoryCreateUpdateAndBulkUpsertAreAudited() throws Exception {
        Long roomId = ownRoom();
        String date = "2031-03-11";

        Long invId = idOf(adminPost("/api/admin/rooms/" + roomId + "/inventory",
            inventory(date, 20, 18, 1, 0, 1), 201));
        AdminActivityLog created = one("ROOM_INVENTORY_CREATE", invId);
        assertEquals("ROOM_INVENTORY", created.getTargetType());
        assertEquals(invId, created.getTargetId());
        assertEquals(adminUserId, created.getActorUserId());
        assertTrue(created.getAfterState().contains("available:18"), created.getAfterState());

        adminPut("/api/admin/rooms/" + roomId + "/inventory/" + date,
            inventory(date, 20, 12, 3, 0, 1), 200);
        AdminActivityLog updated = one("ROOM_INVENTORY_UPDATE", invId);
        assertTrue(updated.getBeforeState().contains("available:18"), updated.getBeforeState());
        assertTrue(updated.getAfterState().contains("available:12"), updated.getAfterState());
        assertTrue(updated.getAfterState().contains("blocked:3"), updated.getAfterState());

        adminPost("/api/admin/rooms/" + roomId + "/inventory/bulk",
            "{\"items\":[" + inventory("2031-04-01", 20, 20, 0, 0, 0) + ","
                + inventory("2031-04-02", 20, 19, 1, 0, 0) + "]}", 200);
        AdminActivityLog bulk = one("ROOM_INVENTORY_BULK_UPSERT", roomId);
        assertEquals("HOTEL_ROOM", bulk.getTargetType(),
            "a fan-out over N nights has no single mutated child, so the room is the honest target");
        assertEquals(roomId, bulk.getTargetId());
        assertTrue(bulk.getDescription().contains("2 inventory day(s)"), bulk.getDescription());
        assertTrue(bulk.getAfterState().contains("2031-04-01..2031-04-02"), bulk.getAfterState());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // GIFT CARD PRODUCTS / COUPONS / PROMOTIONS — 10 mutations
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void giftCardProductLifecycleIsFullyAudited() throws Exception {
        Long id = idOf(adminPost("/api/admin/gift-card-products",
            giftCard("GC-" + suffix(), "500000"), 201));
        AdminActivityLog created = one("GIFT_CARD_PRODUCT_CREATE", id);
        assertEquals("GIFT_CARD_PRODUCT", created.getTargetType());
        assertEquals(adminUserId, created.getActorUserId());
        assertTrue(created.getAfterState().contains("fixed:500000"), created.getAfterState());

        adminPut("/api/admin/gift-card-products/" + id, giftCard("GC-" + suffix(), "700000"), 200);
        AdminActivityLog updated = one("GIFT_CARD_PRODUCT_UPDATE", id);
        assertTrue(updated.getBeforeState().contains("fixed:500000"), updated.getBeforeState());
        assertTrue(updated.getAfterState().contains("fixed:700000"), updated.getAfterState());

        adminPatch("/api/admin/gift-card-products/" + id + "/deactivate", 200);
        assertEquals("active:false", head(one("GIFT_CARD_PRODUCT_DEACTIVATE", id).getAfterState()));

        adminPatch("/api/admin/gift-card-products/" + id + "/activate", 200);
        assertEquals("active:true", head(one("GIFT_CARD_PRODUCT_ACTIVATE", id).getAfterState()));

        adminPatch("/api/admin/gift-card-products/" + id + "/deactivate", 200);
    }

    @Test
    void couponDefinitionLifecycleIsFullyAudited() throws Exception {
        Long id = idOf(adminPost("/api/admin/coupon-definitions", coupon("CP-" + suffix(), "15"), 201));
        AdminActivityLog created = one("COUPON_DEFINITION_CREATE", id);
        assertEquals("COUPON_DEFINITION", created.getTargetType());
        assertEquals(adminUserId, created.getActorUserId());
        assertTrue(created.getAfterState().contains("value:15"), created.getAfterState());

        adminPut("/api/admin/coupon-definitions/" + id, coupon("CP-" + suffix(), "40"), 200);
        AdminActivityLog updated = one("COUPON_DEFINITION_UPDATE", id);
        assertTrue(updated.getBeforeState().contains("value:15"), updated.getBeforeState());
        assertTrue(updated.getAfterState().contains("value:40"), updated.getAfterState());

        adminPatch("/api/admin/coupon-definitions/" + id + "/deactivate", 200);
        assertEquals("active:false", head(one("COUPON_DEFINITION_DEACTIVATE", id).getAfterState()));

        adminPatch("/api/admin/coupon-definitions/" + id + "/activate", 200);
        assertEquals("active:true", head(one("COUPON_DEFINITION_ACTIVATE", id).getAfterState()));

        // Leave no globally claimable probe coupon behind.
        adminPatch("/api/admin/coupon-definitions/" + id + "/deactivate", 200);
    }

    /**
     * An admin promotion is global ({@code targetType: ALL}) and {@code PricingEngineService}
     * evaluates every one of them, so a probe promotion left behind changes what later pricing
     * tests compute. The finally block removes it.
     */
    @Test
    void promotionCreateAndUpdateAreAudited() throws Exception {
        Long id = idOf(adminPost("/api/admin/promotions", promotion("PR-" + suffix(), "10"), 201));
        try {
            AdminActivityLog created = one("PROMOTION_CREATE", id);
            assertEquals("PROMOTION", created.getTargetType());
            assertEquals(adminUserId, created.getActorUserId());
            assertTrue(created.getAfterState().contains("value:10"), created.getAfterState());

            adminPut("/api/admin/promotions/" + id, promotion("PR-" + suffix(), "25"), 200);
            AdminActivityLog updated = one("PROMOTION_UPDATE", id);
            assertTrue(updated.getBeforeState().contains("value:10"), updated.getBeforeState());
            assertTrue(updated.getAfterState().contains("value:25"), updated.getAfterState());
        } finally {
            deletePromotion(id);
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // REWARD ECONOMICS — 8 mutations
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * The redemption policy is global singleton-ish state: {@code resolveApplicable} picks the
     * newest active policy in force, so a probe policy left active silently re-prices every
     * later loyalty redemption in the suite. The finally block puts the platform back on the
     * seeded policy.
     */
    @Test
    void redemptionPolicyLifecycleIsFullyAudited() throws Exception {
        Long id = idOf(adminPost("/api/admin/loyalty/redemption-policies",
            redemptionPolicy("RP-" + suffix(), 100, "1.00"), 201));
        try {
            AdminActivityLog created = one("LOYALTY_REDEMPTION_POLICY_CREATE", id);
            assertEquals("LOYALTY_REDEMPTION_POLICY", created.getTargetType());
            assertEquals(adminUserId, created.getActorUserId());
            assertTrue(created.getAfterState().contains("pointsPerUnit:100"), created.getAfterState());

            adminPut("/api/admin/loyalty/redemption-policies/" + id,
                redemptionPolicy("RP-" + suffix(), 50, "2.50"), 200);
            AdminActivityLog updated = one("LOYALTY_REDEMPTION_POLICY_UPDATE", id);
            assertTrue(updated.getBeforeState().contains("pointsPerUnit:100"), updated.getBeforeState());
            assertTrue(updated.getAfterState().contains("pointsPerUnit:50"), updated.getAfterState());
            assertTrue(updated.getAfterState().contains("valuePerUnit:2.50"),
                "the money-per-point rate is the whole point of this row: " + updated.getAfterState());

            adminPost("/api/admin/loyalty/redemption-policies/" + id + "/deactivate", null, 200);
            assertEquals("active:false",
                head(one("LOYALTY_REDEMPTION_POLICY_DEACTIVATE", id).getAfterState()));

            adminPost("/api/admin/loyalty/redemption-policies/" + id + "/activate", null, 200);
            assertEquals("active:true",
                head(one("LOYALTY_REDEMPTION_POLICY_ACTIVATE", id).getAfterState()));
        } finally {
            adminPost("/api/admin/loyalty/redemption-policies/" + id + "/deactivate", null, 200);
        }
    }

    /**
     * {@code ReferralService} resolves the newest active campaign in force, so a probe campaign
     * left active would rewrite every later referral reward in the suite. The finally block puts
     * the platform back on the seeded campaign.
     */
    @Test
    void referralCampaignLifecycleIsFullyAudited() throws Exception {
        Long id = idOf(adminPost("/api/admin/referral/campaigns",
            referralCampaign("RC-" + suffix(), 500, 200), 201));
        try {
            AdminActivityLog created = one("REFERRAL_CAMPAIGN_CREATE", id);
            assertEquals("REFERRAL_CAMPAIGN", created.getTargetType());
            assertEquals(adminUserId, created.getActorUserId());
            assertTrue(created.getAfterState().contains("inviterPoints:500"), created.getAfterState());
            assertTrue(created.getAfterState().contains("inviteePoints:200"), created.getAfterState());

            adminPut("/api/admin/referral/campaigns/" + id,
                referralCampaign("RC-" + suffix(), 9000, 200), 200);
            AdminActivityLog updated = one("REFERRAL_CAMPAIGN_UPDATE", id);
            assertTrue(updated.getBeforeState().contains("inviterPoints:500"), updated.getBeforeState());
            assertTrue(updated.getAfterState().contains("inviterPoints:9000"),
                "an 18x jump in minted points must be reconstructable: " + updated.getAfterState());

            adminPost("/api/admin/referral/campaigns/" + id + "/deactivate", null, 200);
            assertEquals("active:false", head(one("REFERRAL_CAMPAIGN_DEACTIVATE", id).getAfterState()));

            adminPost("/api/admin/referral/campaigns/" + id + "/activate", null, 200);
            assertEquals("active:true", head(one("REFERRAL_CAMPAIGN_ACTIVATE", id).getAfterState()));
        } finally {
            adminPost("/api/admin/referral/campaigns/" + id + "/deactivate", null, 200);
        }
    }

    @Test
    void membershipBenefitCreateAndUpdateAreAudited() throws Exception {
        Long id = idOf(adminPost("/api/admin/membership/benefits", """
            {"tier":"GOLD","benefitType":"LATE_CHECKOUT","name":"D3H Late checkout",
             "description":"probe","numericValue":14,"active":true,"sortOrder":99}
            """, 201));
        AdminActivityLog created = one("MEMBERSHIP_BENEFIT_CREATE", id);
        assertEquals("MEMBERSHIP_BENEFIT", created.getTargetType());
        assertEquals(adminUserId, created.getActorUserId());
        assertTrue(created.getAfterState().contains("tier:GOLD"), created.getAfterState());
        assertTrue(created.getAfterState().contains("numericValue:14"), created.getAfterState());

        adminPut("/api/admin/membership/benefits/" + id, """
            {"tier":"GOLD","benefitType":"LATE_CHECKOUT","name":"D3H Late checkout",
             "description":"probe","numericValue":16,"active":true,"sortOrder":99}
            """, 200);
        AdminActivityLog updated = one("MEMBERSHIP_BENEFIT_UPDATE", id);
        assertTrue(updated.getBeforeState().contains("numericValue:14"), updated.getBeforeState());
        assertTrue(updated.getAfterState().contains("numericValue:16"), updated.getAfterState());

        // Clean up the probe benefit so the seeded GOLD benefit list is left as it was found.
        mvc.perform(delete("/api/admin/membership/benefits/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());
    }

    /**
     * Every tier definition row is seeded and there is no delete endpoint for one, so this test
     * borrows DIAMOND and puts it back exactly as it found it — {@code MembershipTierTest} and
     * {@code MembershipRedemptionIntegrationTest} both assert its seeded thresholds and multipliers.
     * The restore is itself an audited update, so the assertions read the newest row rather than
     * demanding there be only one.
     */
    @Test
    void membershipTierUpdateActivateAndDeactivateAreAudited() throws Exception {
        JsonNode original = mapper.readTree(adminGet("/api/admin/membership/tiers/DIAMOND"));
        Long defId = original.get("id").asLong();
        try {
            adminPut("/api/admin/membership/tiers/DIAMOND", tierBody(original, 77), 200);
            AdminActivityLog updated = latest("MEMBERSHIP_TIER_UPDATE", defId);
            assertEquals("MEMBERSHIP_TIER", updated.getTargetType());
            assertEquals(defId, updated.getTargetId(),
                "the target is the definition row's id, not the tier enum from the path");
            assertEquals(adminUserId, updated.getActorUserId());
            assertTrue(updated.getAfterState().contains("sortOrder:77"), updated.getAfterState());
            assertTrue(updated.getAfterState().contains("tier:DIAMOND"), updated.getAfterState());

            adminPatch("/api/admin/membership/tiers/DIAMOND/deactivate", 200);
            AdminActivityLog off = latest("MEMBERSHIP_TIER_DEACTIVATE", defId);
            assertTrue(off.getAfterState().contains("active:false"), off.getAfterState());

            adminPatch("/api/admin/membership/tiers/DIAMOND/activate", 200);
            AdminActivityLog on = latest("MEMBERSHIP_TIER_ACTIVATE", defId);
            assertTrue(on.getAfterState().contains("active:true"), on.getAfterState());
        } finally {
            adminPut("/api/admin/membership/tiers/DIAMOND",
                tierBody(original, original.get("sortOrder").asInt()), 200);
        }

        JsonNode restored = mapper.readTree(adminGet("/api/admin/membership/tiers/DIAMOND"));
        assertEquals(original.get("minimumLifetimePoints").asLong(),
            restored.get("minimumLifetimePoints").asLong());
        assertEquals(original.get("minimumCompletedBookings").asInt(),
            restored.get("minimumCompletedBookings").asInt());
        assertEquals(0, new BigDecimal(original.get("pointsMultiplier").asText())
            .compareTo(new BigDecimal(restored.get("pointsMultiplier").asText())));
        assertEquals(0, new BigDecimal(original.get("redemptionDiscountMultiplier").asText())
            .compareTo(new BigDecimal(restored.get("redemptionDiscountMultiplier").asText())));
        assertEquals(original.get("sortOrder").asInt(), restored.get("sortOrder").asInt());
        assertTrue(restored.get("active").asBoolean(), "DIAMOND must be left active for other tests");
    }

    /**
     * Every {@code MembershipTier} constant already has a seeded definition and there is no delete
     * endpoint for one, so {@code POST /api/admin/membership/tiers} can only ever conflict on a
     * seeded database. It still must not leave a row behind when it does.
     */
    @Test
    void tierCreateOnAnAlreadyDefinedTierConflictsAndRecordsNothing() throws Exception {
        long before = count("MEMBERSHIP_TIER_CREATE");
        mvc.perform(post("/api/admin/membership/tiers")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"tier":"GOLD","displayName":"Dup","description":"d","minimumLifetimePoints":1,
                     "minimumCompletedBookings":1,"pointsMultiplier":1.00,"active":true,"sortOrder":1}
                    """))
            .andExpect(status().isConflict());
        assertEquals(before, count("MEMBERSHIP_TIER_CREATE"));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NO ROW FOR A MUTATION THAT DID NOT HAPPEN
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void refusedMutationsRecordNothing() throws Exception {
        long ratePlanUpdates = count("RATE_PLAN_UPDATE");
        long couponCreates = count("COUPON_DEFINITION_CREATE");
        long inventoryCreates = count("ROOM_INVENTORY_CREATE");

        // 404 — no such rate plan.
        mvc.perform(put("/api/admin/rate-plans/99999999")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(ratePlan("100000")))
            .andExpect(status().isNotFound());

        // 409 — duplicate coupon code.
        String code = "CP-" + suffix();
        Long survivor = idOf(adminPost("/api/admin/coupon-definitions", coupon(code, "10"), 201));
        adminPatch("/api/admin/coupon-definitions/" + survivor + "/deactivate", 200);
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(coupon(code, "10")))
            .andExpect(status().isConflict());

        // 400 — endDate is not after startDate.
        mvc.perform(post("/api/admin/rooms/" + ownRoom() + "/rate-plans")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(ratePlan("100000").replace("2031-01-31", "2030-12-01")))
            .andExpect(status().isBadRequest());

        // 409 — inventory already exists for that date.
        Long roomId = ownRoom();
        adminPost("/api/admin/rooms/" + roomId + "/inventory",
            inventory("2031-06-06", 5, 5, 0, 0, 0), 201);
        mvc.perform(post("/api/admin/rooms/" + roomId + "/inventory")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventory("2031-06-06", 5, 5, 0, 0, 0)))
            .andExpect(status().isConflict());

        assertEquals(ratePlanUpdates, count("RATE_PLAN_UPDATE"));
        assertEquals(couponCreates + 1, count("COUPON_DEFINITION_CREATE"),
            "only the one coupon that was actually created may be recorded");
        assertEquals(inventoryCreates + 1, count("ROOM_INVENTORY_CREATE"));
    }

    @Test
    void unauthenticatedAndNonAdminCallersRecordNothing() throws Exception {
        long before = count("PROMOTION_CREATE");

        mvc.perform(post("/api/admin/promotions")
                .contentType(MediaType.APPLICATION_JSON).content(promotion("PR-" + suffix(), "10")))
            .andExpect(status().isUnauthorized());

        mvc.perform(post("/api/admin/promotions")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON).content(promotion("PR-" + suffix(), "10")))
            .andExpect(status().isForbidden());

        mvc.perform(post("/api/admin/loyalty/redemption-policies")
                .header("Authorization", "Bearer " + userToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(redemptionPolicy("RP-" + suffix(), 10, "1.00")))
            .andExpect(status().isForbidden());

        assertEquals(before, count("PROMOTION_CREATE"));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CROSS-ROLE CONTAMINATION — the reason ten of these audits are wrappers
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerPricingAndCalendarWritesProduceNoAdminRows() throws Exception {
        OwnedRoom owned = partnerOwnedRoom();
        long before = totalRows();

        String created = mvc.perform(post("/api/partner/rooms/" + owned.roomId() + "/rate-plans")
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON).content(ratePlan("300000")))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long partnerPlanId = mapper.readTree(created).get("id").asLong();

        mvc.perform(put("/api/partner/rate-plans/" + partnerPlanId)
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON).content(ratePlan("310000")))
            .andExpect(status().isOk());

        mvc.perform(post("/api/partner/rate-plans/" + partnerPlanId + "/deactivate")
                .header("Authorization", "Bearer " + owned.token()))
            .andExpect(status().isOk());

        mvc.perform(post("/api/partner/rate-plans/" + partnerPlanId + "/activate")
                .header("Authorization", "Bearer " + owned.token()))
            .andExpect(status().isOk());

        mvc.perform(post("/api/partner/rate-plans/" + partnerPlanId + "/duplicate")
                .header("Authorization", "Bearer " + owned.token()))
            .andExpect(status().isCreated());

        mvc.perform(post("/api/partner/rate-plans/" + partnerPlanId + "/occupancy-prices")
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"adults\":2,\"children\":0,\"pricePerNight\":320000}"))
            .andExpect(status().isCreated());

        mvc.perform(post("/api/partner/calendar/rooms/" + owned.roomId() + "/bulk")
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"items\":[" + inventory("2031-09-09", 10, 10, 0, 0, 0) + "]}"))
            .andExpect(status().isOk());

        mvc.perform(put("/api/partner/calendar/rooms/" + owned.roomId() + "/2031-09-09")
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(inventory("2031-09-09", 10, 8, 2, 0, 0)))
            .andExpect(status().isOk());

        assertEquals(before, totalRows(),
            "a partner changing their own rate plans and calendar must add no administrative row");
    }

    @Test
    void partnerPromotionWritesProduceNoAdminRows() throws Exception {
        OwnedRoom owned = partnerOwnedRoom();
        long before = totalRows();

        // A partner may only promote their own hotel — PartnerPromotionService refuses a global
        // ALL promotion outright, so the probe has to be a HOTEL-targeted one they actually own.
        String created = mvc.perform(post("/api/partner/promotions")
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPromotion("PP-" + suffix(), "5", owned.roomId())))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long promoId = mapper.readTree(created).get("id").asLong();

        mvc.perform(put("/api/partner/promotions/" + promoId)
                .header("Authorization", "Bearer " + owned.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(roomPromotion("PP-" + suffix(), "7", owned.roomId())))
            .andExpect(status().isOk());

        assertEquals(before, totalRows(),
            "a partner changing their own promotion must add no administrative row");
    }

    // ══════════════════════════════════════════════════════════════════════════
    // WHAT THE TRAIL MAY AND MAY NOT CARRY
    // ══════════════════════════════════════════════════════════════════════════

    @Test
    void stateStringsCarryNoOperatorFreeText() throws Exception {
        String code = "SECRET-PASSWORD-CODE-" + suffix();
        String body = coupon(code, "10").replace("\"name\":\"D3H Coupon\"",
                                                  "\"name\":\"api_key bearer token\"");
        Long id = idOf(adminPost("/api/admin/coupon-definitions", body, 201));

        AdminActivityLog log = one("COUPON_DEFINITION_CREATE", id);
        String all = log.getDescription() + "|" + log.getBeforeState() + "|" + log.getAfterState();
        assertFalse(all.contains(code), "the operator-supplied code must not reach the trail: " + all);
        assertFalse(all.toLowerCase().contains("password"), all);
        assertFalse(all.toLowerCase().contains("api_key"), all);
        assertFalse(all.toLowerCase().contains("bearer"), all);

        adminPatch("/api/admin/coupon-definitions/" + id + "/deactivate", 200);
    }

    /**
     * The money columns are {@code precision = 15}, so a thirteen-digit price is legal. Written
     * verbatim it would match the audit guard's card-number rule, and because the audit write
     * shares the mutation's transaction the guard would roll back a valid pricing change. The guard
     * is not weakened; the state string simply never carries a digit run that long.
     */
    @Test
    void anAbsurdlyLargePriceDoesNotRollBackTheMutation() throws Exception {
        Long roomId = ownRoom();
        Long planId = idOf(adminPost("/api/admin/rooms/" + roomId + "/rate-plans",
            ratePlan("9999999999999"), 201));

        AdminActivityLog log = one("RATE_PLAN_CREATE", planId);
        assertTrue(log.getAfterState().contains("price:(out-of-range)"), log.getAfterState());

        JsonNode plan = mapper.readTree(adminGet("/api/admin/rate-plans/" + planId));
        assertEquals(0, new BigDecimal("9999999999999")
            .compareTo(new BigDecimal(plan.get("pricePerNight").asText())),
            "the mutation itself must have committed");
    }

    @Test
    void everyNewActionRecordsTheSessionAdminAsActor() throws Exception {
        // Drive one of each so this sweep has rows to inspect regardless of execution order.
        ratePlanLifecycleIsFullyAudited();
        occupancyPriceCreateAndUpdateAreAudited();
        inventoryCreateUpdateAndBulkUpsertAreAudited();
        giftCardProductLifecycleIsFullyAudited();
        couponDefinitionLifecycleIsFullyAudited();
        promotionCreateAndUpdateAreAudited();
        redemptionPolicyLifecycleIsFullyAudited();
        referralCampaignLifecycleIsFullyAudited();
        membershipBenefitCreateAndUpdateAreAudited();
        membershipTierUpdateActivateAndDeactivateAreAudited();

        List<String> actions = List.of(
            "RATE_PLAN_CREATE", "RATE_PLAN_UPDATE", "RATE_PLAN_ACTIVATE", "RATE_PLAN_DEACTIVATE",
            "RATE_PLAN_DUPLICATE", "RATE_PLAN_OCCUPANCY_PRICE_CREATE",
            "RATE_PLAN_OCCUPANCY_PRICE_UPDATE", "ROOM_INVENTORY_CREATE", "ROOM_INVENTORY_UPDATE",
            "ROOM_INVENTORY_BULK_UPSERT", "GIFT_CARD_PRODUCT_CREATE", "GIFT_CARD_PRODUCT_UPDATE",
            "GIFT_CARD_PRODUCT_ACTIVATE", "GIFT_CARD_PRODUCT_DEACTIVATE",
            "COUPON_DEFINITION_CREATE", "COUPON_DEFINITION_UPDATE", "COUPON_DEFINITION_ACTIVATE",
            "COUPON_DEFINITION_DEACTIVATE", "PROMOTION_CREATE", "PROMOTION_UPDATE",
            "LOYALTY_REDEMPTION_POLICY_CREATE", "LOYALTY_REDEMPTION_POLICY_UPDATE",
            "LOYALTY_REDEMPTION_POLICY_ACTIVATE", "LOYALTY_REDEMPTION_POLICY_DEACTIVATE",
            "REFERRAL_CAMPAIGN_CREATE", "REFERRAL_CAMPAIGN_UPDATE", "REFERRAL_CAMPAIGN_ACTIVATE",
            "REFERRAL_CAMPAIGN_DEACTIVATE", "MEMBERSHIP_TIER_UPDATE", "MEMBERSHIP_TIER_ACTIVATE",
            "MEMBERSHIP_TIER_DEACTIVATE", "MEMBERSHIP_BENEFIT_CREATE", "MEMBERSHIP_BENEFIT_UPDATE");
        assertEquals(33, actions.size(),
            "D3H adds 34 actions for 34 mutations; 33 are listed here because MEMBERSHIP_TIER_CREATE "
                + "cannot succeed on a seeded database — every MembershipTier constant already has a "
                + "definition and there is no delete endpoint for one. Its refusal path is covered by "
                + "tierCreateOnAnAlreadyDefinedTierConflictsAndRecordsNothing.");

        for (String action : actions) {
            List<AdminActivityLog> rows = auditRepo
                .search(null, action, null, null, null, null, PageRequest.of(0, 20)).getContent();
            assertFalse(rows.isEmpty(), action + " produced no audit row");
            for (AdminActivityLog row : rows) {
                assertEquals(adminUserId, row.getActorUserId(), action + " recorded the wrong actor");
                assertNotNull(row.getTargetType(), action + " recorded no target type");
                assertNotNull(row.getTargetId(), action + " recorded no target id");
                assertTrue(row.getBeforeState() == null || row.getBeforeState().length() <= 500);
                assertTrue(row.getAfterState() == null || row.getAfterState().length() <= 500);
                assertTrue(row.getDescription().length() <= 4000);
            }
        }
    }

    /**
     * The audit read API is unchanged by this phase and must keep working for the five target types
     * it did not previously see. Strictly read-only: every call here is a GET.
     */
    @Test
    void auditReadApiServesTheNewActionsAndTargetTypesUnchanged() throws Exception {
        ratePlanLifecycleIsFullyAudited();
        occupancyPriceCreateAndUpdateAreAudited();
        inventoryCreateUpdateAndBulkUpsertAreAudited();
        couponDefinitionLifecycleIsFullyAudited();
        redemptionPolicyLifecycleIsFullyAudited();
        referralCampaignLifecycleIsFullyAudited();

        JsonNode page = mapper.readTree(adminGet("/api/admin/activity-logs?size=1"));
        for (String key : List.of("content", "page", "size", "totalElements", "totalPages")) {
            assertTrue(page.has(key), "the PageResponse envelope lost " + key);
        }

        for (String targetType : List.of("RATE_PLAN", "RATE_PLAN_OCCUPANCY_PRICE", "ROOM_INVENTORY",
                                          "COUPON_DEFINITION", "LOYALTY_REDEMPTION_POLICY",
                                          "REFERRAL_CAMPAIGN")) {
            JsonNode byType = mapper.readTree(
                adminGet("/api/admin/activity-logs?targetType=" + targetType + "&size=5"));
            assertTrue(byType.get("totalElements").asLong() > 0,
                "the audit API returns nothing for targetType=" + targetType);
            for (JsonNode row : byType.get("content")) {
                assertEquals(targetType, row.get("targetType").asText());
            }
        }

        JsonNode combined = mapper.readTree(adminGet(
            "/api/admin/activity-logs?action=RATE_PLAN_CREATE&targetType=RATE_PLAN&size=5"));
        assertTrue(combined.get("totalElements").asLong() > 0);
        for (JsonNode row : combined.get("content")) {
            assertEquals("RATE_PLAN_CREATE", row.get("action").asText());
        }

        // Paging stays clamped rather than becoming a 500 — unchanged behaviour.
        mvc.perform(get("/api/admin/activity-logs?page=-5&size=0")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        // And the trail is still admin-only.
        mvc.perform(get("/api/admin/activity-logs"))
            .andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/activity-logs")
                .header("Authorization", "Bearer " + userToken))
            .andExpect(status().isForbidden());
    }

    // ══════════════════════════════════════════════════════════════════════════
    // helpers
    // ══════════════════════════════════════════════════════════════════════════

    private record OwnedRoom(String token, Long hotelId, Long roomId) {}

    private long count(String action) {
        return auditRepo.search(null, action, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    private long totalRows() {
        return auditRepo.search(null, null, null, null, null, null, PageRequest.of(0, 1))
            .getTotalElements();
    }

    /** Exactly one row — valid whenever the target was created inside this test. */
    private AdminActivityLog one(String action, Long targetId) {
        List<AdminActivityLog> rows = auditRepo
            .search(null, action, null, targetId, null, null, PageRequest.of(0, 10)).getContent();
        assertEquals(1, rows.size(),
            "exactly one " + action + " row expected for target " + targetId + ", got " + rows.size());
        return rows.get(0);
    }

    /** Newest row — for targets that pre-exist and may accumulate rows across runs. */
    private AdminActivityLog latest(String action, Long targetId) {
        List<AdminActivityLog> rows = auditRepo
            .search(null, action, null, targetId, null, null, PageRequest.of(0, 50)).getContent();
        assertFalse(rows.isEmpty(), "no " + action + " row for target " + targetId);
        return rows.get(0);
    }

    /** "active:true price:..." -> "active:true" */
    private static String head(String state) {
        int i = state.indexOf(' ');
        return i < 0 ? state : state.substring(0, i);
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private static String suffix() {
        return UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private Long idOf(String body) throws Exception {
        return mapper.readTree(body).get("id").asLong();
    }

    private String adminGet(String path) throws Exception {
        return mvc.perform(get(path).header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
    }

    private String adminPost(String path, String body, int expected) throws Exception {
        var req = post(path).header("Authorization", "Bearer " + adminToken);
        if (body != null) req = req.contentType(MediaType.APPLICATION_JSON).content(body);
        return mvc.perform(req).andExpect(status().is(expected))
            .andReturn().getResponse().getContentAsString();
    }

    private void adminPut(String path, String body, int expected) throws Exception {
        mvc.perform(put(path)
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON).content(body))
            .andExpect(status().is(expected));
    }

    private void deletePromotion(Long id) throws Exception {
        mvc.perform(delete("/api/admin/promotions/" + id)
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNoContent());
    }

    private void adminPatch(String path, int expected) throws Exception {
        mvc.perform(patch(path).header("Authorization", "Bearer " + adminToken))
            .andExpect(status().is(expected));
    }

    // ── payloads ──────────────────────────────────────────────────────────────

    private static String ratePlan(String price) {
        return """
            {"rateName":"D3H Rate","rateType":"STANDARD","pricePerNight":%s,
             "startDate":"2031-01-01","endDate":"2031-01-31","active":true,
             "mealPlanType":"ROOM_ONLY","cancellationPolicyType":"FREE_CANCELLATION",
             "refundable":true,"sourceType":"BASE","priority":0}
            """.formatted(price);
    }

    private static String inventory(String date, int total, int available, int blocked,
                                     int sold, int maintenance) {
        return """
            {"inventoryDate":"%s","totalInventory":%d,"availableInventory":%d,
             "blockedInventory":%d,"soldInventory":%d,"maintenanceInventory":%d,
             "stopSell":false,"closedArrival":false,"closedDeparture":false}
            """.formatted(date, total, available, blocked, sold, maintenance);
    }

    private static String giftCard(String code, String amount) {
        return """
            {"productCode":"%s","name":"D3H Gift Card","description":"probe","currency":"VND",
             "fixedAmount":%s,"minimumAmount":100000,"maximumAmount":5000000,
             "customAmountAllowed":false,"validDaysAfterActivation":365,"active":true,
             "validFrom":"2030-01-01","validUntil":"2032-12-31"}
            """.formatted(code, amount);
    }

    private static String coupon(String code, String value) {
        return """
            {"code":"%s","name":"D3H Coupon","description":"probe","discountType":"PERCENTAGE",
             "discountValue":%s,"maxDiscountAmount":200000,"minimumSpend":500000,
             "validFrom":"2030-01-01","validUntil":"2032-12-31","active":true,
             "totalUsageLimit":100,"usageLimitPerUser":1,"targetType":"ALL",
             "customerSegment":"ALL_USERS","firstBookingOnly":false,
             "combinableWithPromotions":true,"combinableWithTravelCredits":true}
            """.formatted(code, value);
    }

    private static String promotion(String code, String value) {
        return """
            {"name":"D3H Promotion","code":"%s","description":"probe","promotionType":"GENERAL",
             "discountType":"PERCENTAGE","discountValue":%s,"maxDiscountAmount":300000,
             "minimumStay":1,"minimumSpend":400000,"stackable":false,"priority":1,
             "startDate":"2030-01-01","endDate":"2032-12-31","active":true,"targetType":"ALL"}
            """.formatted(code, value);
    }

    /**
     * A partner promotion must target something they own: PartnerPromotionService refuses a global
     * ALL promotion outright, and its HOTEL branch resolves targetId against a HotelDetail id
     * rather than a Place id. ROOM targeting is the unambiguous choice here.
     */
    private static String roomPromotion(String code, String value, Long roomId) {
        return """
            {"name":"D3H Partner Promotion","code":"%s","description":"probe",
             "promotionType":"ROOM","discountType":"PERCENTAGE","discountValue":%s,
             "maxDiscountAmount":300000,"minimumStay":1,"minimumSpend":400000,
             "stackable":false,"priority":1,"startDate":"2030-01-01","endDate":"2032-12-31",
             "active":true,"targetType":"ROOM","targetId":%d}
            """.formatted(code, value, roomId);
    }

    private static String redemptionPolicy(String code, int pointsPerUnit, String valuePerUnit) {
        return """
            {"policyCode":"%s","displayName":"D3H Policy","pointsPerUnit":%d,
             "valuePerUnit":%s,"minimumRedemptionPoints":1000,"redemptionIncrementPoints":100,
             "maximumDiscountPercentage":50,"minimumFinalPayableAmount":10000,"active":true}
            """.formatted(code, pointsPerUnit, valuePerUnit);
    }

    private static String referralCampaign(String code, long inviterPoints, long inviteePoints) {
        return """
            {"code":"%s","name":"D3H Campaign","minimumQualifyingBookingAmount":500000,
             "inviterRewardPoints":%d,"inviteeRewardPoints":%d,"active":true}
            """.formatted(code, inviterPoints, inviteePoints);
    }

    private static String tierBody(JsonNode original, int sortOrder) {
        return """
            {"tier":"%s","displayName":"%s","description":"%s","minimumLifetimePoints":%d,
             "minimumCompletedBookings":%d,"pointsMultiplier":%s,"active":true,"sortOrder":%d,
             "redemptionDiscountMultiplier":%s}
            """.formatted(original.get("tier").asText(),
                          original.get("displayName").asText(),
                          original.get("description").asText().replace("\"", "'"),
                          original.get("minimumLifetimePoints").asLong(),
                          original.get("minimumCompletedBookings").asInt(),
                          original.get("pointsMultiplier").asText(),
                          sortOrder,
                          original.get("redemptionDiscountMultiplier").asText());
    }

    // ── fixtures ──────────────────────────────────────────────────────────────

    /** A hotel and room created for this test's exclusive use, so no seeded row is ever mutated. */
    private Long ownRoom() throws Exception {
        Long hotelId = createHotelPlace("D3H-" + suffix());
        createHotelDetail(hotelId);
        return createRoom(hotelId, "D3H-" + suffix());
    }

    private Long ownRatePlan() throws Exception {
        return idOf(adminPost("/api/admin/rooms/" + ownRoom() + "/rate-plans",
            ratePlan("500000"), 201));
    }

    private OwnedRoom partnerOwnedRoom() throws Exception {
        String email = "partner-d3h-" + counter.getAndIncrement() + "-" + suffix() + "@test.com";
        String token = registerAndLogin(email);

        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"businessName":"D3H Hotel Co %s","businessType":"HOTEL",
                     "representativeName":"D3H Tester","phone":"0901234567",
                     "email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                    """.formatted(suffix())))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        Long hotelId = createHotelPlace("D3H-P-" + suffix());
        createHotelDetail(hotelId);
        Long roomId = createRoom(hotelId, "D3HP-" + suffix());
        mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + profileId + "}"))
            .andExpect(status().isOk());

        return new OwnedRoom(token, hotelId, roomId);
    }

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"D3H Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long createHotelPlace(String name) throws Exception {
        String resp = adminPost("/api/admin/places", """
            {"name":"%s","categoryId":%d,"subcategoryId":%d,"administrativeUnitId":%d,
             "address":"123 Test Street","priceLevel":2,"featured":false,"verified":false,
             "status":"DRAFT"}
            """.formatted(name, accCategoryId, hotelSubcategoryId, locationId), 201);
        Long id = mapper.readTree(resp).get("id").asLong();
        patchStatus(id, "APPROVED");
        patchStatus(id, "PUBLISHED");
        return id;
    }

    private void patchStatus(Long placeId, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + placeId + "/status")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private void createHotelDetail(Long placeId) throws Exception {
        adminPost("/api/admin/hotels", """
            {"placeId":%d,"starRating":4,"checkInTime":"14:00:00","checkOutTime":"12:00:00",
             "totalRooms":10,"availableRooms":10,"freeCancellation":false,
             "prepaymentRequired":false,"breakfastIncluded":false,"airportShuttle":false}
            """.formatted(placeId), 201);
    }

    private Long createRoom(Long placeId, String roomCode) throws Exception {
        String resp = adminPost("/api/admin/rooms", """
            {"placeId":%d,"roomName":"D3H Room","roomCode":"%s","roomType":"DELUXE",
             "bedType":"QUEEN","bedCount":1,"maxAdults":2,"maxChildren":1,"maxGuests":3,
             "roomSizeSqm":25.0,"floorNumber":2,"smokingAllowed":false,"breakfastIncluded":true,
             "freeCancellation":true,"instantConfirmation":true,"priceFrom":500000,
             "originalPrice":600000,"quantity":10,"availableQuantity":10,"active":true}
            """.formatted(placeId, roomCode), 201);
        return mapper.readTree(resp).get("id").asLong();
    }
}
