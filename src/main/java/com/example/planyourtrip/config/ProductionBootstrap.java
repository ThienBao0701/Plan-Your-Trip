package com.example.planyourtrip.config;

import com.example.planyourtrip.model.LoyaltyRedemptionPolicy;
import com.example.planyourtrip.model.ReferralCampaign;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.LoyaltyRedemptionPolicyRepository;
import com.example.planyourtrip.repository.ReferralCampaignRepository;
import com.example.planyourtrip.repository.UserRepository;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;

/**
 * DB-04 — production seed / bootstrap. Runs ONLY under the {@code prod} profile (the dev/test
 * {@link DataInitializer} is {@code @Profile("!prod")} and never runs in prod), so a fresh
 * production database gets the minimum data the backend demonstrably requires.
 *
 * <p>Strictly limited to <b>system reference data</b> plus an <b>optional, environment-gated
 * admin</b> — no demo/customer business data is ever created here:
 * <ul>
 *   <li>the single active default <b>referral campaign</b> — without it
 *       {@code ReferralService#use} → {@code ReferralCampaignService#resolveApplicable} throws 409;</li>
 *   <li>the single active default <b>loyalty redemption policy</b> — without it
 *       {@code LoyaltyRedemptionService} → {@code LoyaltyRedemptionPolicyService#resolveApplicable}
 *       throws 409;</li>
 *   <li>an initial <b>admin user</b>, created only when both credential env vars are supplied.</li>
 * </ul>
 *
 * <p>Every operation is idempotent (create-if-absent by a stable business key / email) and never
 * overwrites, duplicates or deletes an existing row — safe to run on every restart. Values for the two
 * defaults deliberately mirror {@link DataInitializer}'s seeders; the two runners never co-execute
 * (opposite profiles), so there is no runtime drift.
 */
@Component
@Profile("prod")
public class ProductionBootstrap implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(ProductionBootstrap.class);

    private static final String DEFAULT_REFERRAL_CODE = "DEFAULT_REFERRAL";
    private static final String DEFAULT_REDEMPTION_POLICY_CODE = "DEFAULT_LOYALTY_REDEMPTION";

    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final ReferralCampaignRepository referralCampaigns;
    private final LoyaltyRedemptionPolicyRepository redemptionPolicies;

    private final String adminEmail;
    private final String adminPassword;
    private final String adminFullName;

    public ProductionBootstrap(UserRepository users,
                               PasswordEncoder encoder,
                               ReferralCampaignRepository referralCampaigns,
                               LoyaltyRedemptionPolicyRepository redemptionPolicies,
                               @Value("${app.bootstrap.admin.email:}") String adminEmail,
                               @Value("${app.bootstrap.admin.password:}") String adminPassword,
                               @Value("${app.bootstrap.admin.full-name:Administrator}") String adminFullName) {
        this.users = users;
        this.encoder = encoder;
        this.referralCampaigns = referralCampaigns;
        this.redemptionPolicies = redemptionPolicies;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
        this.adminFullName = adminFullName;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        ensureDefaultReferralCampaign();
        ensureDefaultRedemptionPolicy();
        ensureBootstrapAdmin(adminEmail, adminPassword, adminFullName);
    }

    /**
     * Creates the single active default referral campaign if none exists with
     * {@value #DEFAULT_REFERRAL_CODE}. Idempotent; never overwrites an admin-customized row.
     */
    public void ensureDefaultReferralCampaign() {
        if (referralCampaigns.findByCodeIgnoreCase(DEFAULT_REFERRAL_CODE).isPresent()) {
            log.info("DB-04: default referral campaign already present — preserved.");
            return;
        }
        ReferralCampaign c = new ReferralCampaign();
        c.setCode(DEFAULT_REFERRAL_CODE);
        c.setName("Default referral programme");
        c.setMinimumQualifyingBookingAmount(null);
        c.setInviterRewardPoints(200L);
        c.setInviteeRewardPoints(100L);
        c.setActive(true);
        c.setEffectiveFrom(Instant.now());
        c.setEffectiveUntil(null);
        referralCampaigns.save(c);
        log.info("DB-04: created default referral campaign '{}'.", DEFAULT_REFERRAL_CODE);
    }

    /**
     * Creates the single active default loyalty redemption policy if none exists with
     * {@value #DEFAULT_REDEMPTION_POLICY_CODE}. Idempotent; never overwrites an admin-customized row.
     */
    public void ensureDefaultRedemptionPolicy() {
        if (redemptionPolicies.findByPolicyCodeIgnoreCase(DEFAULT_REDEMPTION_POLICY_CODE).isPresent()) {
            log.info("DB-04: default loyalty redemption policy already present — preserved.");
            return;
        }
        LoyaltyRedemptionPolicy p = new LoyaltyRedemptionPolicy();
        p.setPolicyCode(DEFAULT_REDEMPTION_POLICY_CODE);
        p.setDisplayName("Default loyalty redemption");
        p.setPointsPerUnit(100L);
        p.setValuePerUnit(new BigDecimal("1000.00"));
        p.setMinimumRedemptionPoints(1000L);
        p.setRedemptionIncrementPoints(100L);
        p.setMaximumDiscountPercentage(20);
        p.setMinimumFinalPayableAmount(new BigDecimal("1000.00"));
        p.setActive(true);
        p.setEffectiveFrom(Instant.now());
        p.setEffectiveUntil(null);
        redemptionPolicies.save(p);
        log.info("DB-04: created default loyalty redemption policy '{}'.", DEFAULT_REDEMPTION_POLICY_CODE);
    }

    /**
     * Creates an initial admin ONLY when both {@code email} and {@code password} are supplied (via
     * {@code ADMIN_BOOTSTRAP_EMAIL} / {@code ADMIN_BOOTSTRAP_PASSWORD}). Skips silently when
     * credentials are absent (no default password) and when the email already exists (never
     * overwrites an existing user or its password). The password is hashed with the application's
     * {@link PasswordEncoder} and is NEVER logged.
     */
    public void ensureBootstrapAdmin(String email, String password, String fullName) {
        String trimmedEmail = email == null ? "" : email.trim();
        if (trimmedEmail.isEmpty() || password == null || password.isEmpty()) {
            log.info("DB-04: admin bootstrap skipped — no admin credentials configured.");
            return;
        }
        if (users.existsByEmail(trimmedEmail)) {
            log.info("DB-04: admin bootstrap skipped — a user already exists for the configured email.");
            return;
        }
        User u = new User();
        u.setFullName(fullName == null || fullName.isBlank() ? "Administrator" : fullName.trim());
        u.setEmail(trimmedEmail);
        u.setPasswordHash(encoder.encode(password));
        u.setRole("ADMIN");
        u.setEnabled(true);
        users.save(u);
        log.info("DB-04: created bootstrap admin user for the configured email (role ADMIN).");
    }
}
