package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminActivityLog;
import com.example.planyourtrip.repository.AdminActivityLogRepository;
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

import java.time.LocalDate;
import java.util.List;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * D4 — the administrative audit trail for the one Admin mutation in the coupon domain.
 *
 * <p>{@code POST /api/admin/users/{userId}/coupons/{couponId}/revoke} takes spendable value away
 * from a named customer, and {@code CustomerCouponService#adminRevoke} has recorded a
 * {@code CUSTOMER_COUPON_REVOKE} row since D1c — but nothing asserted it. The behaviour was covered
 * by {@code CouponCreditLifecycleTest}; the audit row, the actor, the before/after pair and the
 * deliberate omission of the coupon code from the trail were not.
 *
 * <p>The code omission is the part worth pinning. A coupon code is redeemable text: if it were
 * written into the description, the audit trail — readable by every admin — would become somewhere
 * to harvest working discount codes from. The service says so in a comment; this test makes it a
 * fact that fails loudly if someone changes it.
 */
@SpringBootTest
@AutoConfigureMockMvc
class CouponAdminMutationAuditTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired AdminActivityLogRepository auditRepo;
    @Autowired UserRepository userRepo;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final LocalDate TODAY = LocalDate.now();

    private String adminToken;
    private Long adminUserId;

    @BeforeEach
    void setup() throws Exception {
        adminToken = login("admin@planyourtrip.com", "admin123456");
        adminUserId = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow().getId();
    }

    @Test
    void revokingACouponWritesExactlyOneAuditRowWithTheRightActorAndStates() throws Exception {
        Claimed c = claimedCoupon("revoke-ok");

        long before = auditRepo.count();
        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/" + c.couponId + "/revoke")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("REVOKED"));

        assertEquals(before + 1, auditRepo.count(), "the trail must grow by exactly one row");

        AdminActivityLog log = one("CUSTOMER_COUPON_REVOKE", c.couponId);
        assertEquals("CUSTOMER_COUPON", log.getTargetType());
        assertEquals(c.couponId, log.getTargetId(), "the target is the customer-coupon row id");
        assertEquals(adminUserId, log.getActorUserId(), "the actor comes from the session, not the body");
        assertEquals("AVAILABLE", log.getBeforeState());
        assertEquals("REVOKED", log.getAfterState());
        assertTrue(log.getDescription().contains("user " + c.userId), log.getDescription());
    }

    /**
     * The coupon code must never reach the trail — it is redeemable text, not an identifier.
     */
    @Test
    void theRevokeAuditRowNeverCarriesTheCouponCode() throws Exception {
        Claimed c = claimedCoupon("revoke-code");

        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/" + c.couponId + "/revoke")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());

        AdminActivityLog log = one("CUSTOMER_COUPON_REVOKE", c.couponId);
        String all = log.getDescription() + "|" + log.getBeforeState() + "|" + log.getAfterState();
        assertFalse(all.contains(c.code),
            "a redeemable coupon code must not be harvestable from the audit trail: " + all);
    }

    @Test
    void revokingAnAlreadyRevokedCouponConflictsAndWritesNoSecondRow() throws Exception {
        Claimed c = claimedCoupon("revoke-twice");

        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/" + c.couponId + "/revoke")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isOk());
        long afterFirst = auditRepo.count();

        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/" + c.couponId + "/revoke")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isConflict());

        assertEquals(afterFirst, auditRepo.count(), "a refused repeat must not be recorded");
        assertEquals(1, rowsFor("CUSTOMER_COUPON_REVOKE", c.couponId).size(),
            "exactly one revoke row for this coupon, ever");
    }

    @Test
    void revokingAnUnknownCouponIsNotFoundAndWritesNothing() throws Exception {
        Claimed c = claimedCoupon("revoke-404");
        long before = auditRepo.count();

        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/99999999/revoke")
                .header("Authorization", "Bearer " + adminToken))
            .andExpect(status().isNotFound());

        assertEquals(before, auditRepo.count());
    }

    @Test
    void nonAdminCallersCannotRevokeAndWriteNothing() throws Exception {
        Claimed c = claimedCoupon("revoke-authz");
        long before = auditRepo.count();

        // The owner themselves is still not an admin.
        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/" + c.couponId + "/revoke")
                .header("Authorization", "Bearer " + c.token))
            .andExpect(status().isForbidden());

        mvc.perform(post("/api/admin/users/" + c.userId + "/coupons/" + c.couponId + "/revoke"))
            .andExpect(status().isUnauthorized());

        assertEquals(before, auditRepo.count(), "a refused caller must add no administrative row");
        assertTrue(rowsFor("CUSTOMER_COUPON_REVOKE", c.couponId).isEmpty());
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private record Claimed(String token, Long userId, Long couponId, String code) {}

    /** A throwaway customer holding one freshly claimed coupon of a uniquely-coded definition. */
    private Claimed claimedCoupon(String prefix) throws Exception {
        String code = ("CPN-D4A-" + prefix + "-" + counter.getAndIncrement()).toUpperCase();
        mvc.perform(post("/api/admin/coupon-definitions")
                .header("Authorization", "Bearer " + adminToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"code":"%s","name":"D4 Audit %s","description":"revoke audit probe",
                     "discountType":"PERCENTAGE","discountValue":10,"maxDiscountAmount":null,
                     "minimumSpend":null,"validFrom":"%s","validUntil":"%s","active":true,
                     "totalUsageLimit":null,"usageLimitPerUser":1}
                    """.formatted(code, code, TODAY.minusDays(1), TODAY.plusDays(30))))
            .andExpect(status().isCreated());

        String email = prefix + "-" + counter.getAndIncrement() + "@test.com";
        JsonNode registered = mapper.readTree(mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Coupon Holder\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());
        String token = registered.get("token").asText();
        Long userId = registered.get("user").get("id").asLong();

        JsonNode claimed = mapper.readTree(mvc.perform(post("/api/me/coupons/claim")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"code\":\"" + code + "\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());

        return new Claimed(token, userId, claimed.get("id").asLong(), code);
    }

    private List<AdminActivityLog> rowsFor(String action, Long targetId) {
        return auditRepo.search(null, action, null, targetId, null, null, PageRequest.of(0, 10))
            .getContent();
    }

    private AdminActivityLog one(String action, Long targetId) {
        List<AdminActivityLog> rows = rowsFor(action, targetId);
        assertEquals(1, rows.size(),
            "exactly one " + action + " row expected for target " + targetId + ", got " + rows.size());
        return rows.get(0);
    }

    private String login(String email, String password) throws Exception {
        return mapper.readTree(mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString()).get("token").asText();
    }
}
