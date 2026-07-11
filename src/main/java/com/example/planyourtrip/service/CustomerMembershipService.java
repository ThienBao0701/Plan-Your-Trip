package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.MembershipDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CustomerMembershipRepository;
import com.example.planyourtrip.repository.LoyaltyAccountRepository;
import com.example.planyourtrip.repository.MembershipTierHistoryRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Customer membership lifecycle built on top of Phase 7.18's loyalty ledger:
 * enrollment, qualification, automatic upgrade evaluation, manual admin
 * assignment/reevaluation, tier history and the read-only MEMBER
 * coupon-eligibility signal.
 *
 * <p><b>Qualification</b> ({@link #computeQualifiedTier}) uses
 * {@code LoyaltyAccount#lifetimePointsEarned} (the monotonic counter — see its
 * class javadoc) plus the user's COMPLETED booking count. BOTH configured
 * thresholds on a tier's ACTIVE {@link MembershipTierDefinition} must be
 * satisfied; the highest such tier wins; BRONZE is the unconditional fallback
 * when nothing else qualifies (even if BRONZE's own definition row is inactive
 * or missing — the enum constant itself is the floor).
 *
 * <p><b>Upgrade vs downgrade — the grace-period rule.</b>
 * {@link #evaluateAutomaticUpgrade} is the single, idempotent, synchronous
 * hook invoked by {@code LoyaltyService#credit} (inside the SAME transaction
 * as the point award, for every EARN_BOOKING/EARN_REVIEW/GRANT) — it is
 * STRICTLY upgrade-only: it moves {@code currentTier} up when a higher tier
 * newly qualifies, resets the 12-month validity window, and records ONE
 * {@code AUTOMATIC_UPGRADE} history row; it NEVER lowers the stored tier, and
 * repeated calls with no qualification change are a complete no-op (no
 * duplicate history). A tier can therefore outlive the metrics that earned it
 * for up to 12 months (or indefinitely, until an explicit action) — ordinary
 * point deduction alone (a future redemption phase) must never cause an
 * immediate downgrade. Downgrade only ever happens via
 * {@link #adminReevaluate} (an explicit admin action, which can move the tier
 * in either direction, including detecting and processing an EXPIRED
 * validity window — the only path that fires the "Membership expired"
 * notification, since this phase has no background expiry scheduler).
 *
 * <p><b>Expiry is a read-time projection, not a stored-state mutation.</b>
 * {@link #effectiveTier} returns BRONZE once {@code validUntil} has passed,
 * without touching the stored {@code currentTier} — every customer-facing
 * response exposes both {@code currentTier} (stored) and
 * {@code effectiveTier} (expiry-aware) so a client can distinguish "what tier
 * is on file" from "what tier actually applies right now".
 *
 * <p><b>Concurrency: optimistic ({@code @Version}), not pessimistic.</b>
 * Deliberate deviation from {@code LoyaltyService}/{@code TravelCreditService}
 * (which both use {@code SELECT ... FOR UPDATE}): a single user's membership
 * row is mutated far less often and by far fewer concurrent paths than a
 * ledger account (which serializes every earn/grant), and most membership
 * traffic is READS (progress/benefits/history). A lost-update race here is
 * rare and, when it happens, simply losing the retry via a 409 (mapped in
 * {@code GlobalExceptionHandler} from {@code ObjectOptimisticLockingFailureException})
 * is an acceptable, simple outcome — the caller can safely retry the same
 * mutation. No automatic retry loop is implemented in this phase.
 */
@Service
public class CustomerMembershipService {

    private final CustomerMembershipRepository membershipRepo;
    private final MembershipTierHistoryRepository historyRepo;
    private final MembershipTierService tierService;
    private final LoyaltyAccountRepository loyaltyAccountRepo;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;

    /** Recommended default validity window — resets on enrollment/automatic upgrade/reevaluation. */
    private static final long DEFAULT_VALIDITY_MONTHS = 12;

    public CustomerMembershipService(CustomerMembershipRepository membershipRepo,
                                      MembershipTierHistoryRepository historyRepo,
                                      MembershipTierService tierService,
                                      LoyaltyAccountRepository loyaltyAccountRepo,
                                      BookingRepository bookingRepo,
                                      UserRepository userRepo,
                                      NotificationService notificationService) {
        this.membershipRepo = membershipRepo;
        this.historyRepo = historyRepo;
        this.tierService = tierService;
        this.loyaltyAccountRepo = loyaltyAccountRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
    }

    // ── Customer: enrollment ─────────────────────────────────────────────────

    /** Idempotent — replaying an enroll call for an already-enrolled user returns the existing membership untouched. */
    @Transactional
    public CustomerMembershipResponse enroll(Long userId) {
        Optional<CustomerMembership> existing = membershipRepo.findByUserId(userId);
        if (existing.isPresent()) return toResponse(existing.get());

        LoyaltyAccount account = loyaltyAccountRepo.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST,
                "An active loyalty account is required to enroll in membership"));
        User user = userOrThrow(userId);

        long completedBookings = bookingRepo.countByUserIdAndStatus(userId, BookingStatus.COMPLETED);
        MembershipTier tier = computeQualifiedTier(account.getLifetimePointsEarned(), completedBookings);
        Instant now = Instant.now();

        CustomerMembership m = new CustomerMembership();
        m.setUser(user);
        m.setLoyaltyAccount(account);
        m.setCurrentTier(tier);
        m.setQualifiedAt(now);
        m.setValidFrom(now);
        m.setValidUntil(plusMonths(now, DEFAULT_VALIDITY_MONTHS));
        m.setManuallyAssigned(false);
        m.setActive(true);
        CustomerMembership saved = membershipRepo.save(m);

        recordHistory(saved, null, tier, MembershipTierChangeType.INITIAL_ENROLLMENT,
            "Initial enrollment", now, saved.getValidUntil(), MembershipReferenceType.LOYALTY_ACCOUNT, account.getId());
        notify(userId, "Membership activated",
            "You have been enrolled in the " + tierService.displayName(tier) + " membership tier.");

        return toResponse(saved);
    }

    // ── Customer: reads (never create a membership as a side effect) ────────

    @Transactional(readOnly = true)
    public CustomerMembershipResponse getMyMembership(Long userId) {
        return toResponse(membershipOrThrow(userId));
    }

    /**
     * Works whether or not the user has enrolled — when there is no membership
     * row, {@code currentTier} reports BRONZE (the unenrolled default) while
     * {@code effectiveTier} still reports the LIVE calculated qualified tier,
     * so a prospective member can preview what enrolling would grant them
     * right now. Never creates a membership.
     */
    @Transactional(readOnly = true)
    public MembershipProgressResponse getProgress(Long userId) {
        long lifetimePoints = loyaltyAccountRepo.findByUserId(userId)
            .map(LoyaltyAccount::getLifetimePointsEarned).orElse(0L);
        long completedBookings = bookingRepo.countByUserIdAndStatus(userId, BookingStatus.COMPLETED);

        Optional<CustomerMembership> membership = membershipRepo.findByUserIdAndActiveTrue(userId);
        MembershipTier currentTier = membership.map(CustomerMembership::getCurrentTier).orElse(MembershipTier.BRONZE);
        MembershipTier effectiveTier = membership
            .map(this::effectiveTier)
            .orElseGet(() -> computeQualifiedTier(lifetimePoints, completedBookings));
        boolean expired = membership.map(this::isExpired).orElse(false);
        Instant validUntil = membership.map(CustomerMembership::getValidUntil).orElse(null);
        boolean manuallyAssigned = membership.map(CustomerMembership::isManuallyAssigned).orElse(false);

        return buildProgress(currentTier, effectiveTier, lifetimePoints, completedBookings,
            validUntil, expired, manuallyAssigned);
    }

    private MembershipProgressResponse buildProgress(MembershipTier currentTier, MembershipTier effectiveTier,
                                                       long lifetimePoints, long completedBookings,
                                                       Instant validUntil, boolean expired, boolean manuallyAssigned) {
        List<MembershipTierDefinition> active = tierService.activeTiersOrderedBySortOrder();

        MembershipTierDefinition currentDef = active.stream()
            .filter(d -> d.getTier() == effectiveTier).findFirst().orElse(null);
        long currentMinPoints = currentDef != null ? currentDef.getMinimumLifetimePoints() : 0L;

        MembershipTierDefinition nextDef = active.stream()
            .filter(d -> d.getTier().ordinal() > effectiveTier.ordinal())
            .min((a, b) -> Integer.compare(a.getTier().ordinal(), b.getTier().ordinal()))
            .orElse(null);

        MembershipTier nextTier = nextDef != null ? nextDef.getTier() : null;
        Long pointsRequired = nextDef != null ? Math.max(nextDef.getMinimumLifetimePoints() - lifetimePoints, 0) : 0L;
        Long bookingsRequired = nextDef != null
            ? Math.max((long) nextDef.getMinimumCompletedBookings() - completedBookings, 0) : 0L;

        double progressPercentage;
        if (nextDef == null) {
            progressPercentage = 100.0;
        } else {
            long span = nextDef.getMinimumLifetimePoints() - currentMinPoints;
            if (span <= 0) {
                progressPercentage = 100.0;
            } else {
                double raw = ((lifetimePoints - currentMinPoints) * 100.0) / span;
                progressPercentage = Math.min(100.0, Math.max(0.0, raw));
            }
        }

        return new MembershipProgressResponse(currentTier, effectiveTier, lifetimePoints, completedBookings,
            nextTier, pointsRequired, bookingsRequired, progressPercentage, validUntil, expired, manuallyAssigned);
    }

    /** Defaults to BRONZE's active benefits when the user has never enrolled. */
    @Transactional(readOnly = true)
    public List<MembershipBenefitResponse> getMyBenefits(Long userId) {
        MembershipTier effectiveTier = membershipRepo.findByUserIdAndActiveTrue(userId)
            .map(this::effectiveTier)
            .orElse(MembershipTier.BRONZE);
        return tierService.activeBenefitsForTier(effectiveTier);
    }

    /** Empty list (not an error) when the user has never enrolled. */
    @Transactional(readOnly = true)
    public List<MembershipTierHistoryResponse> getMyHistory(Long userId) {
        return membershipRepo.findByUserId(userId)
            .map(m -> historyRepo.findByMembershipIdOrderByEffectiveAtDescIdDesc(m.getId()).stream()
                .map(this::toHistoryResponse).toList())
            .orElse(List.of());
    }

    // ── Integration hook — called by LoyaltyService#credit, same transaction ──

    /**
     * The ONE authoritative post-award evaluation hook (see class javadoc for
     * the upgrade-only / no-duplicate-history contract). No-op — and does NOT
     * create a membership — when the user has never enrolled, per the
     * "eligibility checks must not implicitly create a membership" rule
     * (existing users without membership simply keep multiplier 1.00 and never
     * get auto-enrolled by earning points).
     */
    @Transactional
    public MembershipEvaluationResultResponse evaluateAutomaticUpgrade(Long userId) {
        Optional<CustomerMembership> opt = membershipRepo.findByUserIdAndActiveTrue(userId);
        Instant now = Instant.now();
        if (opt.isEmpty())
            return new MembershipEvaluationResultResponse(userId, null, null, false, "Not enrolled", now);

        CustomerMembership m = opt.get();
        long lifetimePoints = loyaltyAccountRepo.findByUserId(userId).map(LoyaltyAccount::getLifetimePointsEarned).orElse(0L);
        long completedBookings = bookingRepo.countByUserIdAndStatus(userId, BookingStatus.COMPLETED);
        MembershipTier qualified = computeQualifiedTier(lifetimePoints, completedBookings);
        MembershipTier previous = m.getCurrentTier();

        if (qualified.ordinal() <= previous.ordinal())
            return new MembershipEvaluationResultResponse(userId, previous, previous, false, "No tier change", now);

        m.setCurrentTier(qualified);
        m.setQualifiedAt(now);
        m.setValidFrom(now);
        m.setValidUntil(plusMonths(now, DEFAULT_VALIDITY_MONTHS));
        membershipRepo.save(m);

        recordHistory(m, previous, qualified, MembershipTierChangeType.AUTOMATIC_UPGRADE,
            "Automatic upgrade: qualification thresholds met", now, m.getValidUntil(),
            MembershipReferenceType.LOYALTY_ACCOUNT, m.getLoyaltyAccount() != null ? m.getLoyaltyAccount().getId() : null);
        notify(userId, "Membership upgraded",
            "Congratulations! Your membership has been upgraded to " + tierService.displayName(qualified) + ".");

        return new MembershipEvaluationResultResponse(userId, previous, qualified, true, "Automatic upgrade", now);
    }

    /** Used by {@code LoyaltyService#awardBookingPoints} — 1.00 when the user has no membership row. */
    @Transactional(readOnly = true)
    public java.math.BigDecimal resolveMultiplierForUser(Long userId) {
        return membershipRepo.findByUserIdAndActiveTrue(userId)
            .map(m -> tierService.resolveMultiplier(effectiveTier(m)))
            .orElse(java.math.BigDecimal.ONE);
    }

    /** Read-only MEMBER coupon-eligibility signal — see {@code CustomerCouponService#evaluateSegment}. Never creates a membership. */
    @Transactional(readOnly = true)
    public boolean isActiveNonExpiredMember(Long userId) {
        return membershipRepo.findByUserIdAndActiveTrue(userId)
            .map(m -> !isExpired(m))
            .orElse(false);
    }

    /**
     * Phase 7.21 (additive) — read-only effective-tier lookup for other
     * services to reuse rather than recompute (e.g. {@code CustomerCouponService}'s
     * {@code minimumTier} coupon gate). Empty when the user has never enrolled
     * or their membership row is inactive — callers must treat that as "below
     * BRONZE", not as BRONZE itself (see {@link #getMyBenefits}, which
     * deliberately defaults to BRONZE for display purposes; that default is
     * NOT appropriate for a tier-gated eligibility check). Never creates a
     * membership.
     */
    @Transactional(readOnly = true)
    public Optional<MembershipTier> effectiveTierForUser(Long userId) {
        return membershipRepo.findByUserIdAndActiveTrue(userId).map(this::effectiveTier);
    }

    /**
     * Phase 7.21 (additive) — used by {@code LoyaltyRedemptionService} to boost
     * a redemption's discount amount. 1.00 (baseline, unchanged behavior) when
     * the user has no membership row, exactly mirroring
     * {@link #resolveMultiplierForUser}'s fallback for the (separate)
     * booking-award points multiplier.
     */
    @Transactional(readOnly = true)
    public java.math.BigDecimal resolveRedemptionMultiplierForUser(Long userId) {
        return membershipRepo.findByUserIdAndActiveTrue(userId)
            .map(m -> tierService.resolveRedemptionMultiplier(effectiveTier(m)))
            .orElse(java.math.BigDecimal.ONE);
    }

    // ── Admin ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public CustomerMembershipResponse adminView(Long userId) {
        userOrThrow(userId);
        return toResponse(membershipOrThrow(userId));
    }

    /**
     * Admin can assign ANY currently-active tier, regardless of the user's
     * actual qualification metrics, and regardless of whether the user has
     * enrolled or even has a {@code LoyaltyAccount} yet (an admin override, not
     * a self-service action). Always creates one {@code MANUAL_UPGRADE}/
     * {@code MANUAL_DOWNGRADE} history row (direction derived by comparing tier
     * ordinals; a first-ever assignment is recorded as {@code MANUAL_UPGRADE}
     * with a null previous tier).
     *
     * <p>{@code idempotencyKey} is accepted for API symmetry with
     * {@code LoyaltyGrantRequest} but — unlike the loyalty ledger, which has a
     * unique DB column backing true replay-safety — {@code CustomerMembership}/
     * {@code MembershipTierHistory} carry no such column (not part of the 7.19
     * entity spec), so repeated calls with the same key are not deduplicated
     * at the storage layer; they are naturally idempotent in EFFECT though
     * (the resulting membership state is identical), just not in history-row
     * count. Documented deviation, not a silent gap.
     */
    @Transactional
    public CustomerMembershipResponse adminAssign(Long userId, MembershipManualAssignmentRequest req) {
        User user = userOrThrow(userId);
        tierService.activeDefinitionOrThrow(req.tier());
        Instant now = Instant.now();
        if (req.validUntil() != null && !req.validUntil().isAfter(now))
            throw new ApiException(HttpStatus.BAD_REQUEST, "validUntil must be in the future");

        Optional<CustomerMembership> existing = membershipRepo.findByUserId(userId);
        CustomerMembership m = existing.orElseGet(() -> {
            CustomerMembership fresh = new CustomerMembership();
            fresh.setUser(user);
            fresh.setLoyaltyAccount(loyaltyAccountRepo.findByUserId(userId).orElse(null));
            fresh.setActive(true);
            return fresh;
        });
        MembershipTier previous = existing.map(CustomerMembership::getCurrentTier).orElse(null);

        m.setCurrentTier(req.tier());
        m.setQualifiedAt(now);
        m.setValidFrom(now);
        m.setValidUntil(req.validUntil() != null ? req.validUntil() : plusMonths(now, DEFAULT_VALIDITY_MONTHS));
        m.setManuallyAssigned(true);
        m.setActive(true);
        CustomerMembership saved = membershipRepo.save(m);

        MembershipTierChangeType changeType = (previous != null && req.tier().ordinal() < previous.ordinal())
            ? MembershipTierChangeType.MANUAL_DOWNGRADE : MembershipTierChangeType.MANUAL_UPGRADE;
        recordHistory(saved, previous, req.tier(), changeType, req.reason(), now, saved.getValidUntil(),
            MembershipReferenceType.ADMIN, null);
        notify(userId, "Membership tier updated",
            "Your membership tier has been updated to " + tierService.displayName(req.tier()) + ".");

        return toResponse(saved);
    }

    /**
     * The explicit admin recalculation path — the ONLY way (besides manual
     * assignment) the stored tier can move DOWN, per the grace-period rule.
     * Also the ONLY path that detects and processes an expired validity window
     * (records an {@code EXPIRATION} history row and fires the "Membership
     * expired" notification) — there is no background scheduler in this phase.
     */
    @Transactional
    public MembershipEvaluationResultResponse adminReevaluate(Long userId) {
        return recalculate(membershipOrThrow(userId), "Admin-triggered reevaluation");
    }

    /** Clears the manual-assignment flag and immediately recalculates from current qualification metrics. */
    @Transactional
    public MembershipEvaluationResultResponse clearManualAssignment(Long userId) {
        CustomerMembership m = membershipOrThrow(userId);
        m.setManuallyAssigned(false);
        return recalculate(m, "Manual assignment cleared; tier restored to calculated eligibility");
    }

    private MembershipEvaluationResultResponse recalculate(CustomerMembership m, String trigger) {
        Instant now = Instant.now();
        boolean wasExpired = m.getValidUntil() != null && now.isAfter(m.getValidUntil());
        long lifetimePoints = loyaltyAccountRepo.findByUserId(m.getUser().getId())
            .map(LoyaltyAccount::getLifetimePointsEarned).orElse(0L);
        long completedBookings = bookingRepo.countByUserIdAndStatus(m.getUser().getId(), BookingStatus.COMPLETED);
        MembershipTier qualified = computeQualifiedTier(lifetimePoints, completedBookings);
        MembershipTier previous = m.getCurrentTier();
        Long userId = m.getUser().getId();

        if (qualified == previous && !wasExpired) {
            m.setManuallyAssigned(false);
            membershipRepo.save(m);
            return new MembershipEvaluationResultResponse(userId, previous, previous, false, "No tier change", now);
        }

        MembershipTierChangeType changeType;
        String reason;
        if (wasExpired) {
            changeType = MembershipTierChangeType.EXPIRATION;
            reason = trigger + ": validity period had expired; tier recalculated from current qualification metrics";
        } else if (qualified.ordinal() > previous.ordinal()) {
            changeType = MembershipTierChangeType.AUTOMATIC_UPGRADE;
            reason = trigger + ": qualification thresholds now met for a higher tier";
        } else {
            changeType = MembershipTierChangeType.AUTOMATIC_DOWNGRADE;
            reason = trigger + ": no longer meets requirements for " + previous;
        }

        m.setCurrentTier(qualified);
        m.setQualifiedAt(now);
        m.setValidFrom(now);
        m.setValidUntil(plusMonths(now, DEFAULT_VALIDITY_MONTHS));
        m.setManuallyAssigned(false);
        membershipRepo.save(m);

        recordHistory(m, previous, qualified, changeType, reason, now, m.getValidUntil(),
            MembershipReferenceType.ADMIN, null);

        if (wasExpired) {
            notify(userId, "Membership expired",
                "Your membership validity period ended and your tier has been recalculated.");
        } else if (changeType == MembershipTierChangeType.AUTOMATIC_UPGRADE) {
            notify(userId, "Membership upgraded",
                "Your membership has been upgraded to " + tierService.displayName(qualified) + ".");
        }

        return new MembershipEvaluationResultResponse(userId, previous, qualified, true, reason, now);
    }

    // ── Qualification core ────────────────────────────────────────────────────

    /**
     * BOTH thresholds on a tier's ACTIVE definition must be satisfied; the
     * highest such tier (by enum ordinal) wins; BRONZE is the unconditional
     * fallback. Only active {@link MembershipTierDefinition} rows participate.
     */
    MembershipTier computeQualifiedTier(long lifetimePoints, long completedBookings) {
        MembershipTier best = MembershipTier.BRONZE;
        int bestRank = -1;
        for (MembershipTierDefinition d : tierService.activeTiersOrderedBySortOrder()) {
            boolean qualifies = lifetimePoints >= d.getMinimumLifetimePoints()
                && completedBookings >= d.getMinimumCompletedBookings();
            if (qualifies && d.getTier().ordinal() > bestRank) {
                bestRank = d.getTier().ordinal();
                best = d.getTier();
            }
        }
        return best;
    }

    /** Expiry is a projection, never a stored mutation — see class javadoc. */
    MembershipTier effectiveTier(CustomerMembership m) {
        return isExpired(m) ? MembershipTier.BRONZE : m.getCurrentTier();
    }

    boolean isExpired(CustomerMembership m) {
        return m.getValidUntil() != null && Instant.now().isAfter(m.getValidUntil());
    }

    private Instant plusMonths(Instant base, long months) {
        return base.atZone(ZoneId.systemDefault()).plusMonths(months).toInstant();
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private CustomerMembership membershipOrThrow(Long userId) {
        return membershipRepo.findByUserIdAndActiveTrue(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "No membership found for user: " + userId));
    }

    private User userOrThrow(Long userId) {
        return userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));
    }

    private void recordHistory(CustomerMembership m, MembershipTier previous, MembershipTier newTier,
                                MembershipTierChangeType type, String reason, Instant effectiveAt, Instant expiresAt,
                                MembershipReferenceType refType, Long refId) {
        MembershipTierHistory h = new MembershipTierHistory();
        h.setMembership(m);
        h.setPreviousTier(previous);
        h.setNewTier(newTier);
        h.setChangeType(type);
        h.setReason(reason);
        h.setEffectiveAt(effectiveAt);
        h.setExpiresAt(expiresAt);
        h.setReferenceType(refType);
        h.setReferenceId(refId);
        historyRepo.save(h);
    }

    private void notify(Long userId, String title, String message) {
        // Deliberately generic — internal qualification math / admin reasons never leak into the message.
        notificationService.create(userId, NotificationType.PROMOTION, Priority.NORMAL, title, message,
            RelatedEntityType.SYSTEM, null);
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private CustomerMembershipResponse toResponse(CustomerMembership m) {
        return new CustomerMembershipResponse(
            m.getId(), m.getUser().getId(), m.getCurrentTier(), effectiveTier(m),
            m.getQualifiedAt(), m.getValidFrom(), m.getValidUntil(),
            m.isManuallyAssigned(), m.isActive(), isExpired(m), m.getCreatedAt(), m.getUpdatedAt()
        );
    }

    private MembershipTierHistoryResponse toHistoryResponse(MembershipTierHistory h) {
        return new MembershipTierHistoryResponse(
            h.getId(), h.getMembership().getId(), h.getPreviousTier(), h.getNewTier(),
            h.getChangeType(), h.getReason(), h.getEffectiveAt(), h.getExpiresAt(),
            h.getReferenceType(), h.getReferenceId(), h.getCreatedAt()
        );
    }
}
