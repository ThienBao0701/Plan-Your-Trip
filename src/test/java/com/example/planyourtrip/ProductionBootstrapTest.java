package com.example.planyourtrip;

import com.example.planyourtrip.config.ProductionBootstrap;
import com.example.planyourtrip.dto.AuthDtos.AuthResponse;
import com.example.planyourtrip.dto.AuthDtos.LoginRequest;
import com.example.planyourtrip.model.LoyaltyRedemptionPolicy;
import com.example.planyourtrip.model.ReferralCampaign;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.repository.LoyaltyPointsRedemptionRepository;
import com.example.planyourtrip.repository.LoyaltyRedemptionPolicyRepository;
import com.example.planyourtrip.repository.ReferralCampaignRepository;
import com.example.planyourtrip.repository.ReferralRewardRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.service.AuthService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.DefaultApplicationArguments;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.jupiter.api.Assertions.*;

/**
 * DB-04 — verifies {@link ProductionBootstrap}'s idempotent bootstrap logic against H2. The bean is
 * {@code @Profile("prod")} so it is NOT auto-registered here; it is constructed manually with the
 * autowired repositories + {@link PasswordEncoder}, exactly as Spring would in prod. {@code @Transactional}
 * rolls every test back so the DataInitializer-seeded dev/test data is left untouched.
 */
@SpringBootTest
@Transactional
class ProductionBootstrapTest {

    private static final String REFERRAL_CODE = "DEFAULT_REFERRAL";
    private static final String POLICY_CODE = "DEFAULT_LOYALTY_REDEMPTION";

    @Autowired UserRepository users;
    @Autowired PasswordEncoder encoder;
    @Autowired ReferralCampaignRepository referralCampaigns;
    @Autowired LoyaltyRedemptionPolicyRepository redemptionPolicies;
    @Autowired AdminProfileAssignmentRepository adminProfiles;
    @Autowired ReferralRewardRepository referralRewards;
    @Autowired LoyaltyPointsRedemptionRepository loyaltyRedemptions;
    @Autowired AuthService authService;

    private ProductionBootstrap bootstrap(String email, String password, String fullName) {
        return new ProductionBootstrap(users, encoder, referralCampaigns, redemptionPolicies, adminProfiles,
                email, password, fullName);
    }

    private long countByReferralCode(String code) {
        return referralCampaigns.findAll().stream().filter(c -> code.equals(c.getCode())).count();
    }

    private long countByPolicyCode(String code) {
        return redemptionPolicies.findAll().stream().filter(p -> code.equals(p.getPolicyCode())).count();
    }

    @Test
    void createsRequiredReferenceDataWhenAbsent() {
        // Remove FK dependents then the seeded defaults (rolled back after the test).
        referralRewards.deleteAll();
        referralCampaigns.findByCodeIgnoreCase(REFERRAL_CODE).ifPresent(referralCampaigns::delete);
        loyaltyRedemptions.deleteAll();
        redemptionPolicies.findByPolicyCodeIgnoreCase(POLICY_CODE).ifPresent(redemptionPolicies::delete);
        assertTrue(referralCampaigns.findByCodeIgnoreCase(REFERRAL_CODE).isEmpty());
        assertTrue(redemptionPolicies.findByPolicyCodeIgnoreCase(POLICY_CODE).isEmpty());

        ProductionBootstrap b = bootstrap("", "", "Administrator");
        b.ensureDefaultReferralCampaign();
        b.ensureDefaultRedemptionPolicy();

        ReferralCampaign c = referralCampaigns.findByCodeIgnoreCase(REFERRAL_CODE).orElseThrow();
        assertTrue(c.isActive());
        assertEquals(200L, c.getInviterRewardPoints());
        assertEquals(100L, c.getInviteeRewardPoints());
        assertNotNull(c.getEffectiveFrom());

        LoyaltyRedemptionPolicy p = redemptionPolicies.findByPolicyCodeIgnoreCase(POLICY_CODE).orElseThrow();
        assertTrue(p.isActive());
        assertEquals(100L, p.getPointsPerUnit());
        assertEquals(1000L, p.getMinimumRedemptionPoints());
        assertEquals(20, p.getMaximumDiscountPercentage());
        assertEquals(0, new java.math.BigDecimal("1000.00").compareTo(p.getValuePerUnit()));
    }

    @Test
    void rerunCreatesNoDuplicates() {
        // Rows already exist (DataInitializer). Re-running must not duplicate them.
        ProductionBootstrap b = bootstrap("", "", "Administrator");
        b.ensureDefaultReferralCampaign();
        b.ensureDefaultReferralCampaign();
        b.ensureDefaultRedemptionPolicy();
        b.ensureDefaultRedemptionPolicy();
        assertEquals(1, countByReferralCode(REFERRAL_CODE));
        assertEquals(1, countByPolicyCode(POLICY_CODE));
    }

    @Test
    void preservesCustomizedReferralCampaign() {
        ReferralCampaign existing = referralCampaigns.findByCodeIgnoreCase(REFERRAL_CODE).orElseThrow();
        existing.setInviterRewardPoints(999L);
        referralCampaigns.save(existing);

        bootstrap("", "", "Administrator").ensureDefaultReferralCampaign();

        ReferralCampaign after = referralCampaigns.findByCodeIgnoreCase(REFERRAL_CODE).orElseThrow();
        assertEquals(999L, after.getInviterRewardPoints(), "existing campaign must not be overwritten");
        assertEquals(1, countByReferralCode(REFERRAL_CODE));
    }

    @Test
    void createsAdminWhenConfigured() {
        String email = "db04-admin-" + System.nanoTime() + "@example.com";
        String password = "Sup3r-Secret-Bootstrap-Pw";

        bootstrap(email, password, "Ops Admin").ensureBootstrapAdmin(email, password, "Ops Admin");

        User u = users.findByEmail(email).orElseThrow();
        assertEquals("ADMIN", u.getRole());
        assertTrue(u.isEnabled());
        assertNotEquals(password, u.getPasswordHash(), "password must be hashed, not stored in plaintext");
        assertTrue(encoder.matches(password, u.getPasswordHash()));
        // RBAC R6 (AP-2, AP-4): the bootstrap administrator is the platform owner, a system grant.
        assertEquals(java.util.List.of(com.example.planyourtrip.security.rbac.AdminProfile.PLATFORM_OWNER),
            adminProfiles.findActiveProfiles(u.getId()));
    }

    @Test
    void adminIsIdempotentAndNeverOverwrites() {
        String email = "db04-admin-" + System.nanoTime() + "@example.com";
        String password = "Original-Pw-123456";
        ProductionBootstrap b = bootstrap(email, password, "Ops Admin");
        b.ensureBootstrapAdmin(email, password, "Ops Admin");
        String hashAfterCreate = users.findByEmail(email).orElseThrow().getPasswordHash();

        // Re-run with a DIFFERENT password/name for the same email — must not overwrite.
        b.ensureBootstrapAdmin(email, "A-Completely-Different-Pw", "Someone Else");

        assertEquals(1, users.findAll().stream().filter(u -> email.equals(u.getEmail())).count());
        User after = users.findByEmail(email).orElseThrow();
        assertEquals(hashAfterCreate, after.getPasswordHash(), "existing password must be preserved");
        assertEquals("ADMIN", after.getRole());
    }

    /**
     * Phase A (S7) — ADMIN_BOOTSTRAP_EMAIL is normalized the way sign-in normalizes it. Before, a
     * mixed-case or padded value was stored as typed while sign-in lowercased its lookup, so the
     * bootstrap admin could never sign in.
     */
    @Test
    void adminEmailIsNormalizedAndTheAdminCanActuallySignIn() {
        String local = "Ops.Admin-" + System.nanoTime();
        String configured = "  " + local + "@Example.COM ";
        String password = "Bootstrap-Sign-In-Pw";

        bootstrap(configured, password, "Ops Admin").ensureBootstrapAdmin(configured, password, "Ops Admin");

        String canonical = (local + "@example.com").toLowerCase();
        User u = users.findByEmail(canonical).orElseThrow();
        assertEquals("ADMIN", u.getRole());
        assertNotNull(u.getEmailVerifiedAt(), "the operator-supplied address is treated as verified");
        assertFalse(u.isEmailVerificationRequired());

        AuthResponse session = authService.login(new LoginRequest(local.toUpperCase() + "@example.com", password));
        assertEquals("ADMIN", session.user().role());
        assertFalse(session.token().isBlank());
    }

    @Test
    void anExistingAccountDifferingOnlyInCaseIsNeitherDuplicatedNorOverwritten() {
        String stored = "Case-Existing-" + System.nanoTime() + "@Example.com";
        User existing = new User();
        existing.setFullName("Existing");
        existing.setEmail(stored);
        existing.setPasswordHash(encoder.encode("Existing-Pw-123"));
        existing.setRole("ADMIN");
        users.saveAndFlush(existing);
        String hash = existing.getPasswordHash();

        bootstrap(stored.toLowerCase(), "Different-Pw-456", "Other").ensureBootstrapAdmin(
            "  " + stored.toUpperCase() + " ", "Different-Pw-456", "Other");

        assertEquals(1, users.findAll().stream().filter(u -> stored.equalsIgnoreCase(u.getEmail())).count());
        assertEquals(hash, users.findByEmail(stored).orElseThrow().getPasswordHash());
    }

    @Test
    void aPasswordBcryptCannotHashStopsStartUpWithoutRevealingIt() {
        String email = "db04-long-" + System.nanoTime() + "@example.com";
        String password = "p".repeat(73);
        IllegalStateException e = assertThrows(IllegalStateException.class,
            () -> bootstrap(email, password, "Ops").ensureBootstrapAdmin(email, password, "Ops"));
        assertFalse(e.getMessage().contains(password));
        assertTrue(users.findByEmail(email).isEmpty());
    }

    @Test
    void adminSkippedWhenCredentialsMissing() {
        long before = users.count();
        ProductionBootstrap b = bootstrap("", "", "Administrator");
        assertDoesNotThrow(() -> {
            b.ensureBootstrapAdmin("", "", "Administrator");            // both blank
            b.ensureBootstrapAdmin("   ", "   ", "Administrator");      // whitespace only
            b.ensureBootstrapAdmin("someone@example.com", "", "X");     // blank password
            b.ensureBootstrapAdmin("", "only-a-password", "X");         // blank email
        });
        assertEquals(before, users.count(), "no user must be created without full credentials");
    }

    @Test
    void runExecutesAllStepsIdempotently() {
        ProductionBootstrap b = bootstrap("", "", "Administrator"); // no admin creds → admin step skipped
        assertDoesNotThrow(() -> {
            b.run(new DefaultApplicationArguments());
            b.run(new DefaultApplicationArguments());
        });
        assertEquals(1, countByReferralCode(REFERRAL_CODE));
        assertEquals(1, countByPolicyCode(POLICY_CODE));
    }
}
