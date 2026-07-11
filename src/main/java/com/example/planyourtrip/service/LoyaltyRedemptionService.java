package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.LoyaltyRedemptionDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.LoyaltyAccountRepository;
import com.example.planyourtrip.repository.LoyaltyPointsRedemptionRepository;
import com.example.planyourtrip.repository.LoyaltyPointsTransactionRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Reservation-based redemption of loyalty points for a booking discount, built
 * ENTIRELY on Phase 7.18's existing ledger primitives — the same
 * {@link LoyaltyAccount#getCurrentBalance() currentBalance} counter and the same
 * immutable {@link LoyaltyPointsTransaction} ledger table — never a parallel
 * balance system. Redemption only ever touches {@code currentBalance};
 * {@code lifetimePointsEarned} (the monotonic tier-qualification counter) is
 * NEVER changed here, so membership qualification is unaffected by redemption or
 * refund.
 *
 * <p><b>Lifecycle</b> (see {@link LoyaltyRedemptionStatus}):
 * RESERVE debits points (REDEMPTION_DEBIT) and reduces the booking's
 * {@code finalPrice}; APPLY confirms the reservation when the booking is
 * confirmed/paid; RELEASE/EXPIRE/CANCEL give unapplied points back
 * (REDEMPTION_RELEASE); REFUND gives applied points back when the booking is
 * later cancelled/refunded (REDEMPTION_REFUND). Points are restored AT MOST
 * ONCE per redemption, guarded by a single deterministic ledger idempotency key.
 *
 * <p><b>Concurrency &amp; transactions.</b> Every balance mutation acquires the
 * SAME pessimistic write lock on the account row used by
 * {@code LoyaltyService#credit} ({@link LoyaltyAccountRepository#findByUserIdForUpdate},
 * SELECT ... FOR UPDATE), re-reads the balance inside the transaction, and
 * performs the account update + ledger insert + redemption row change in one
 * atomic {@code @Transactional} unit. The {@link LoyaltyPointsRedemption} row
 * additionally carries optimistic {@code @Version} so concurrent
 * release/refund/expire callbacks cannot both win. Lock order is always
 * account-row-first to avoid deadlocks.
 *
 * <p><b>Discount ordering.</b> The 20% cap is computed against the eligible
 * amount = the booking amount remaining after promotion + coupon discounts but
 * BEFORE travel-credit and loyalty deductions (for a booking:
 * {@code finalPrice + creditAmountUsed}). The loyalty discount then further
 * reduces the payable amount, which may never fall below the policy's minimum
 * final payable.
 *
 * <p><b>Phase 7.21 (additive) — tier-aware discount multiplier.</b> The single
 * shared money-conversion primitive {@link #pointsToMoney} now takes the
 * redeeming customer's {@code redemptionDiscountMultiplier} (resolved via
 * {@code CustomerMembershipService#resolveRedemptionMultiplierForUser} — 1.00
 * baseline when the user has no membership, so every pre-7.21 caller/test is
 * completely unaffected): {@code finalDiscount = baseDiscount(points) ×
 * multiplier}, both stages rounded DOWN to scale 2 (matching this class's
 * existing money-rounding convention). Applied identically at
 * {@link #preview} and {@link #reserve} — the only two places a discount is
 * computed fresh from a points count — so both surfaces always agree.
 * Deliberately NOT folded into the 20%-cap / minimum-payable-floor point math
 * ({@link #maxPointsByMoney}): the number of points a customer may spend
 * stays governed by the policy's base (unmultiplied) rate, and the tier
 * multiplier is a pure bonus layered on top of the resulting money value —
 * the same "bonus stacks on top of the base calculation" pattern already
 * used by {@code MembershipTierDefinition#pointsMultiplier} for booking-award
 * points.
 */
@Service
public class LoyaltyRedemptionService {

    /** How long a RESERVED redemption is held before it becomes eligible for expiry cleanup. */
    private static final Duration RESERVATION_TTL = Duration.ofMinutes(60);

    private final LoyaltyAccountRepository accountRepo;
    private final LoyaltyPointsTransactionRepository transactionRepo;
    private final LoyaltyPointsRedemptionRepository redemptionRepo;
    private final LoyaltyRedemptionPolicyService policyService;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;
    private final CustomerMembershipService customerMembershipService;

    public LoyaltyRedemptionService(LoyaltyAccountRepository accountRepo,
                                    LoyaltyPointsTransactionRepository transactionRepo,
                                    LoyaltyPointsRedemptionRepository redemptionRepo,
                                    LoyaltyRedemptionPolicyService policyService,
                                    BookingRepository bookingRepo,
                                    UserRepository userRepo,
                                    NotificationService notificationService,
                                    CustomerMembershipService customerMembershipService) {
        this.accountRepo = accountRepo;
        this.transactionRepo = transactionRepo;
        this.redemptionRepo = redemptionRepo;
        this.policyService = policyService;
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
        this.customerMembershipService = customerMembershipService;
    }

    public record ReserveOutcome(RedemptionResponse response, boolean created) {}

    // ── Preview (no mutation) ────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public RedemptionPreviewResponse preview(Long userId, RedemptionPreviewRequest req) {
        if ((req.bookingId() == null) == (req.eligibleAmount() == null))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Provide exactly one of bookingId or eligibleAmount");

        LoyaltyRedemptionPolicy policy = policyService.resolveApplicable(Instant.now());

        BigDecimal eligibleBase;
        BigDecimal payableBefore;
        if (req.bookingId() != null) {
            Booking booking = bookingRepo.findById(req.bookingId())
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + req.bookingId()));
            if (!booking.getUser().getId().equals(userId))
                throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
            payableBefore = booking.getFinalPrice();
            eligibleBase = eligibleBaseFor(booking);
        } else {
            eligibleBase = req.eligibleAmount().setScale(2, RoundingMode.HALF_UP);
            payableBefore = eligibleBase;
        }

        long balance = accountRepo.findByUserId(userId).map(LoyaltyAccount::getCurrentBalance).orElse(0L);
        BigDecimal multiplier = customerMembershipService.resolveRedemptionMultiplierForUser(userId);
        Calc calc = compute(policy, eligibleBase, payableBefore, req.requestedPoints(), balance, multiplier);

        return new RedemptionPreviewResponse(
            req.requestedPoints(), calc.acceptedPoints(), calc.discount(),
            calc.maxPoints(), balance, calc.remainingBalance(),
            eligibleBase.setScale(2, RoundingMode.HALF_UP), calc.finalPayable(),
            calc.redeemable(), calc.messages(),
            LoyaltyRedemptionPolicyService.toSummary(policy));
    }

    // ── Reserve ──────────────────────────────────────────────────────────────

    @Transactional
    public ReserveOutcome reserve(Long userId, RedemptionReserveRequest req) {
        String key = req.idempotencyKey().trim();

        // Idempotent replay: same key + same payload returns the original; a
        // different payload under the same key is a conflict.
        Optional<LoyaltyPointsRedemption> replay = redemptionRepo.findByIdempotencyKey(key);
        if (replay.isPresent()) {
            LoyaltyPointsRedemption r = replay.get();
            if (!r.getBooking().getId().equals(req.bookingId()) || r.getPointsRedeemed() != req.requestedPoints())
                throw new ApiException(HttpStatus.CONFLICT,
                    "Idempotency key already used with a different payload");
            return new ReserveOutcome(toResponse(r), false);
        }

        Booking booking = bookingRepo.findById(req.bookingId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + req.bookingId()));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied: booking belongs to another user");
        if (booking.getStatus() != BookingStatus.PENDING)
            throw new ApiException(HttpStatus.CONFLICT,
                "Loyalty points can only be redeemed on a PENDING booking. Current status: " + booking.getStatus());

        if (!redemptionRepo.findByBookingIdAndStatusIn(booking.getId(), LoyaltyRedemptionStatus.NON_TERMINAL).isEmpty())
            throw new ApiException(HttpStatus.CONFLICT,
                "An active loyalty redemption already exists for this booking");

        LoyaltyRedemptionPolicy policy = policyService.resolveApplicable(Instant.now());

        // Pessimistic write lock on the account row + re-read balance inside the tx.
        LoyaltyAccount account = accountRepo.findByUserIdForUpdate(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Loyalty account not found"));
        if (account.getStatus() != LoyaltyAccountStatus.ACTIVE)
            throw new ApiException(HttpStatus.CONFLICT,
                "Loyalty account is not active (status " + account.getStatus() + ") and cannot redeem points");

        long points = req.requestedPoints();
        BigDecimal eligibleBase = eligibleBaseFor(booking);
        BigDecimal payableBefore = booking.getFinalPrice();
        validateStrict(policy, eligibleBase, payableBefore, points, account.getCurrentBalance());
        BigDecimal multiplier = customerMembershipService.resolveRedemptionMultiplierForUser(userId);
        BigDecimal discount = pointsToMoney(policy, points, multiplier);

        // Persist the redemption first so its id/reference anchor the ledger row.
        LoyaltyPointsRedemption redemption = new LoyaltyPointsRedemption();
        redemption.setCustomer(booking.getUser());
        redemption.setBooking(booking);
        redemption.setLoyaltyAccount(account);
        redemption.setPolicy(policy);
        redemption.setPointsRedeemed(points);
        redemption.setDiscountAmount(discount);
        redemption.setEligibleAmount(eligibleBase.setScale(2, RoundingMode.HALF_UP));
        redemption.setPointsPerUnitSnapshot(policy.getPointsPerUnit());
        redemption.setValuePerUnitSnapshot(policy.getValuePerUnit());
        redemption.setStatus(LoyaltyRedemptionStatus.RESERVED);
        redemption.setReservedAt(Instant.now());
        redemption.setExpiresAt(Instant.now().plus(RESERVATION_TTL));
        redemption.setReason("Reserved against booking #" + booking.getId());
        redemption.setIdempotencyKey(key);
        // redemption_reference is nullable=false AND updatable=false, so it must be
        // set before the (single) insert — a save-then-update two-step can never
        // work here (the second save's column change would be silently dropped).
        redemption.setRedemptionReference(generateReference());
        redemption = redemptionRepo.save(redemption);

        // Atomic debit + immutable ledger row (lifetimePointsEarned untouched).
        writeLedger(account, LoyaltyTransactionType.REDEMPTION_DEBIT, points, true,
            redemption.getId(),
            "Redeemed " + points + " points against booking #" + booking.getId()
                + " (" + redemption.getRedemptionReference() + ")",
            "redemption-" + redemption.getRedemptionReference() + "-debit");

        // Reflect the discount in the booking pricing breakdown so a subsequent
        // payment is charged the reduced amount.
        applyDiscountToBooking(booking, discount, points);
        bookingRepo.save(booking);

        notificationService.create(userId, NotificationType.PROMOTION, Priority.NORMAL,
            "Loyalty points reserved",
            points + " loyalty points reserved for a " + discount.toPlainString()
                + " " + booking.getCurrency() + " discount on booking " + booking.getBookingCode() + ".",
            RelatedEntityType.BOOKING, booking.getId());

        return new ReserveOutcome(toResponse(redemption), true);
    }

    // ── Apply (booking confirmed / payment succeeded) ─────────────────────────

    /** Idempotent: RESERVED → APPLIED. No-op if there is no reservation or it is already applied/terminal. */
    @Transactional
    public Optional<RedemptionResponse> applyForBooking(Long bookingId) {
        Optional<LoyaltyPointsRedemption> active = nonTerminalFor(bookingId);
        if (active.isEmpty()) return Optional.empty();
        LoyaltyPointsRedemption r = active.get();
        if (r.getStatus() == LoyaltyRedemptionStatus.APPLIED) return Optional.of(toResponse(r)); // idempotent
        if (r.getStatus() != LoyaltyRedemptionStatus.RESERVED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Cannot apply a redemption in status " + r.getStatus());
        r.setStatus(LoyaltyRedemptionStatus.APPLIED);
        r.setAppliedAt(Instant.now());
        // Discount already persisted on the booking at reserve time — no second debit, no pricing change.
        return Optional.of(toResponse(redemptionRepo.save(r)));
    }

    // ── Release (explicit, customer/admin) ────────────────────────────────────

    @Transactional
    public RedemptionResponse releaseByReference(Long userId, String reference, boolean adminOverride) {
        LoyaltyPointsRedemption r = referenceOrThrow(reference);
        if (!adminOverride && !r.getCustomer().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        if (r.getStatus() == LoyaltyRedemptionStatus.RELEASED
            || r.getStatus() == LoyaltyRedemptionStatus.CANCELLED
            || r.getStatus() == LoyaltyRedemptionStatus.EXPIRED)
            return toResponse(r); // idempotent — already released/terminal, no double restore
        if (r.getStatus() != LoyaltyRedemptionStatus.RESERVED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Only a RESERVED redemption can be released. Current status: " + r.getStatus());
        return toResponse(restore(r, LoyaltyRedemptionStatus.RELEASED, LoyaltyTransactionType.REDEMPTION_RELEASE,
            "released"));
    }

    // ── Booking-cancellation hook (called by BookingService) ──────────────────

    /**
     * Restores points when a booking with an active redemption is cancelled:
     * RESERVED → RELEASED, APPLIED → REFUNDED. No-op when there is no active
     * redemption (already terminal), so a non-refundable / already-processed
     * cancellation never restores points a second time. Idempotent and safe to
     * call from both the customer and admin cancel paths.
     */
    @Transactional
    public void onBookingCancelled(Long bookingId) {
        Optional<LoyaltyPointsRedemption> active = nonTerminalFor(bookingId);
        if (active.isEmpty()) return;
        LoyaltyPointsRedemption r = active.get();
        if (r.getStatus() == LoyaltyRedemptionStatus.RESERVED)
            restore(r, LoyaltyRedemptionStatus.RELEASED, LoyaltyTransactionType.REDEMPTION_RELEASE, "released");
        else if (r.getStatus() == LoyaltyRedemptionStatus.APPLIED)
            restore(r, LoyaltyRedemptionStatus.REFUNDED, LoyaltyTransactionType.REDEMPTION_REFUND, "refunded");
    }

    /**
     * Payment-failure hook: releases a still-RESERVED redemption so held points
     * return to the customer. No-op if the reservation was already applied or is
     * terminal. Idempotent.
     */
    @Transactional
    public void onPaymentFailed(Long bookingId) {
        Optional<LoyaltyPointsRedemption> active = nonTerminalFor(bookingId);
        if (active.isEmpty()) return;
        LoyaltyPointsRedemption r = active.get();
        if (r.getStatus() == LoyaltyRedemptionStatus.RESERVED)
            restore(r, LoyaltyRedemptionStatus.RELEASED, LoyaltyTransactionType.REDEMPTION_RELEASE, "released");
    }

    /** Explicit admin refund of an APPLIED redemption (APPLIED → REFUNDED). */
    @Transactional
    public RedemptionResponse refundByReference(String reference) {
        LoyaltyPointsRedemption r = referenceOrThrow(reference);
        if (r.getStatus() == LoyaltyRedemptionStatus.REFUNDED) return toResponse(r); // idempotent
        if (r.getStatus() != LoyaltyRedemptionStatus.APPLIED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Only an APPLIED redemption can be refunded. Current status: " + r.getStatus());
        return toResponse(restore(r, LoyaltyRedemptionStatus.REFUNDED, LoyaltyTransactionType.REDEMPTION_REFUND,
            "refunded"));
    }

    // ── Expire stale reservations (admin-triggered; no scheduler) ─────────────

    @Transactional
    public ExpireStaleRunResponse expireStale() {
        Instant now = Instant.now();
        List<LoyaltyPointsRedemption> stale =
            redemptionRepo.findByStatusAndExpiresAtLessThanEqual(LoyaltyRedemptionStatus.RESERVED, now);

        List<RedemptionResponse> expired = new ArrayList<>();
        long restored = 0L;
        for (LoyaltyPointsRedemption r : stale) {
            // Re-check status under the account lock inside restore(); only truly-RESERVED rows are touched.
            if (r.getStatus() != LoyaltyRedemptionStatus.RESERVED) continue;
            restore(r, LoyaltyRedemptionStatus.EXPIRED, LoyaltyTransactionType.REDEMPTION_RELEASE, "expired");
            restored += r.getPointsRedeemed();
            expired.add(toResponse(r));
        }
        return new ExpireStaleRunResponse(expired.size(), restored, expired);
    }

    // ── Reads ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public RedemptionResponse getByReferenceForCustomer(Long userId, String reference) {
        LoyaltyPointsRedemption r = referenceOrThrow(reference);
        if (!r.getCustomer().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return toResponse(r);
    }

    @Transactional(readOnly = true)
    public RedemptionResponse getForBooking(Long userId, Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return redemptionRepo.findByBookingIdOrderByCreatedAtDescIdDesc(bookingId).stream()
            .findFirst().map(this::toResponse)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "No loyalty redemption exists for booking " + bookingId));
    }

    @Transactional(readOnly = true)
    public RedemptionResponse adminGetByReference(String reference) {
        return toResponse(referenceOrThrow(reference));
    }

    // ── Core restore primitive ────────────────────────────────────────────────

    /**
     * Moves a redemption to a restoring terminal status and gives its points
     * back exactly once. The single deterministic ledger key
     * {@code redemption-<ref>-restore} guarantees the points can never be
     * restored twice, no matter how many release/expire/refund callbacks fire.
     */
    private LoyaltyPointsRedemption restore(LoyaltyPointsRedemption r,
                                            LoyaltyRedemptionStatus target,
                                            LoyaltyTransactionType ledgerType,
                                            String verb) {
        if (!r.getStatus().canTransitionTo(target))
            throw new ApiException(HttpStatus.CONFLICT,
                "Invalid redemption transition " + r.getStatus() + " → " + target);

        Long userId = r.getCustomer().getId();
        LoyaltyAccount account = accountRepo.findByUserIdForUpdate(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Loyalty account not found"));

        writeLedger(account, ledgerType, r.getPointsRedeemed(), false, r.getId(),
            "Restored " + r.getPointsRedeemed() + " points (" + verb + ") for booking #"
                + r.getBooking().getId() + " (" + r.getRedemptionReference() + ")",
            "redemption-" + r.getRedemptionReference() + "-restore");

        Instant now = Instant.now();
        r.setStatus(target);
        switch (target) {
            case RELEASED -> r.setReleasedAt(now);
            case REFUNDED -> r.setRefundedAt(now);
            case CANCELLED -> r.setCancelledAt(now);
            case EXPIRED -> r.setReleasedAt(now);
            default -> {}
        }
        r.setReason("Redemption " + verb + " for booking #" + r.getBooking().getId());
        LoyaltyPointsRedemption saved = redemptionRepo.save(r);

        // Give the discount back on the booking pricing breakdown consistently.
        Booking booking = saved.getBooking();
        removeDiscountFromBooking(booking, saved.getDiscountAmount(), saved.getPointsRedeemed());
        bookingRepo.save(booking);

        return saved;
    }

    /**
     * The single ledger-insert point for redemption balance changes. Reuses the
     * existing {@link LoyaltyPointsTransaction} table (no parallel ledger),
     * carries balanceBefore/balanceAfter, and NEVER touches
     * {@code lifetimePointsEarned}. Idempotent by {@code key} (pre-check + DB
     * unique backstop) so a repeated callback creates no second row and restores
     * no points twice.
     */
    private void writeLedger(LoyaltyAccount account, LoyaltyTransactionType type, long points,
                             boolean decrease, Long redemptionId, String description, String key) {
        if (key != null && transactionRepo.findByIdempotencyKey(key).isPresent()) return; // already recorded

        long before = account.getCurrentBalance();
        long after = decrease ? before - points : before + points;
        if (after < 0)
            throw new ApiException(HttpStatus.CONFLICT,
                "Insufficient loyalty point balance: balance " + before + ", requested " + points);

        LoyaltyPointsTransaction tx = new LoyaltyPointsTransaction();
        tx.setAccount(account);
        tx.setTransactionType(type);
        tx.setPoints(points);
        tx.setBalanceBefore(before);
        tx.setBalanceAfter(after);
        tx.setDescription(description);
        tx.setReferenceType(LoyaltyReferenceType.REDEMPTION);
        tx.setReferenceId(redemptionId);
        tx.setIdempotencyKey(key);
        transactionRepo.save(tx);

        account.setCurrentBalance(after); // lifetimePointsEarned deliberately untouched
        accountRepo.save(account);
    }

    // ── Calculation (pure, integer/BigDecimal only) ───────────────────────────

    private record Calc(long acceptedPoints, BigDecimal discount, long maxPoints,
                        BigDecimal finalPayable, long remainingBalance, boolean redeemable,
                        List<String> messages) {}

    private Calc compute(LoyaltyRedemptionPolicy policy, BigDecimal eligibleBase, BigDecimal payableBefore,
                         long requested, long balance, BigDecimal multiplier) {
        long inc = policy.getRedemptionIncrementPoints();
        long min = policy.getMinimumRedemptionPoints();

        long maxByMoney = maxPointsByMoney(policy, eligibleBase, payableBefore);
        long maxByBalance = floorToIncrement(balance, inc);
        long maxPoints = Math.min(maxByMoney, maxByBalance);

        long reqFloored = floorToIncrement(Math.max(requested, 0), inc);
        long candidate = Math.min(reqFloored, maxPoints);
        long accepted = candidate >= min ? candidate : 0L;

        BigDecimal discount = pointsToMoney(policy, accepted, multiplier);
        BigDecimal finalPayable = payableBefore.subtract(discount).max(BigDecimal.ZERO)
            .setScale(2, RoundingMode.HALF_UP);

        List<String> messages = new ArrayList<>();
        if (requested <= 0) messages.add("requestedPoints must be greater than zero");
        if (requested > 0 && requested % inc != 0)
            messages.add("requestedPoints must be a multiple of " + inc);
        if (requested > 0 && requested < min)
            messages.add("Minimum redemption is " + min + " points");
        if (requested > balance)
            messages.add("Insufficient balance: available " + balance + " points");
        else if (requested > maxByMoney)
            messages.add("Requested points exceed the maximum "
                + policy.getMaximumDiscountPercentage() + "% discount / minimum payable limit ("
                + maxByMoney + " points)");

        return new Calc(accepted, discount, maxPoints, finalPayable,
            balance - accepted, accepted > 0, messages);
    }

    private void validateStrict(LoyaltyRedemptionPolicy policy, BigDecimal eligibleBase, BigDecimal payableBefore,
                                long points, long balance) {
        long inc = policy.getRedemptionIncrementPoints();
        if (points % inc != 0)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "requestedPoints must be a multiple of " + inc);
        if (points < policy.getMinimumRedemptionPoints())
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Minimum redemption is " + policy.getMinimumRedemptionPoints() + " points");
        if (points > balance)
            throw new ApiException(HttpStatus.CONFLICT,
                "Insufficient loyalty point balance: available " + balance + ", requested " + points);
        long maxByMoney = maxPointsByMoney(policy, eligibleBase, payableBefore);
        if (points > maxByMoney)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Requested points exceed the maximum " + policy.getMaximumDiscountPercentage()
                    + "% discount / minimum payable limit (" + maxByMoney + " points)");
    }

    /** Largest point count (floored to increment) whose discount respects both the % cap and the min-payable floor. */
    private long maxPointsByMoney(LoyaltyRedemptionPolicy policy, BigDecimal eligibleBase, BigDecimal payableBefore) {
        BigDecimal maxByPct = eligibleBase
            .multiply(BigDecimal.valueOf(policy.getMaximumDiscountPercentage()))
            .divide(BigDecimal.valueOf(100), 2, RoundingMode.DOWN);
        BigDecimal maxByPayable = payableBefore.subtract(policy.getMinimumFinalPayableAmount()).max(BigDecimal.ZERO);
        BigDecimal maxDiscount = maxByPct.min(maxByPayable);
        long points = moneyToPoints(policy, maxDiscount);
        return floorToIncrement(points, policy.getRedemptionIncrementPoints());
    }

    /**
     * Phase 7.21 (additive) — {@code multiplier} is the redeeming customer's
     * tier {@code redemptionDiscountMultiplier} (1.00 baseline when the user
     * has no membership — see class javadoc). {@code baseDiscount} is rounded
     * DOWN to scale 2 first (the pre-7.21 formula, unchanged), then the
     * multiplier is applied and the result is rounded DOWN to scale 2 again —
     * same conservative rounding convention used throughout this class.
     */
    private BigDecimal pointsToMoney(LoyaltyRedemptionPolicy policy, long points, BigDecimal multiplier) {
        BigDecimal baseDiscount = policy.getValuePerUnit()
            .multiply(BigDecimal.valueOf(points))
            .divide(BigDecimal.valueOf(policy.getPointsPerUnit()), 2, RoundingMode.DOWN);
        return baseDiscount.multiply(multiplier).setScale(2, RoundingMode.DOWN);
    }

    private long moneyToPoints(LoyaltyRedemptionPolicy policy, BigDecimal money) {
        if (money.signum() <= 0) return 0L;
        return money.multiply(BigDecimal.valueOf(policy.getPointsPerUnit()))
            .divide(policy.getValuePerUnit(), 0, RoundingMode.DOWN)
            .longValueExact();
    }

    private static long floorToIncrement(long points, long inc) {
        if (points <= 0) return 0L;
        return (points / inc) * inc;
    }

    // ── Booking pricing integration ───────────────────────────────────────────

    /** Eligible base = amount after promotion + coupon, adding back travel credit (before loyalty + credit deduction). */
    private BigDecimal eligibleBaseFor(Booking booking) {
        BigDecimal credit = booking.getCreditAmountUsed() != null ? booking.getCreditAmountUsed() : BigDecimal.ZERO;
        BigDecimal loyaltyAlready = booking.getLoyaltyDiscountAmount() != null
            ? booking.getLoyaltyDiscountAmount() : BigDecimal.ZERO;
        // finalPrice already has credit + any current loyalty subtracted; add them back to reconstruct the pre-deduction base.
        return booking.getFinalPrice().add(credit).add(loyaltyAlready).setScale(2, RoundingMode.HALF_UP);
    }

    private void applyDiscountToBooking(Booking booking, BigDecimal discount, long points) {
        booking.setLoyaltyDiscountAmount(discount);
        booking.setLoyaltyPointsRedeemed(points);
        booking.setFinalPrice(booking.getFinalPrice().subtract(discount)
            .max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP));
    }

    private void removeDiscountFromBooking(Booking booking, BigDecimal discount, long points) {
        // Only reverse if this booking still reflects this redemption's discount (guards double-restore of pricing).
        if (booking.getLoyaltyPointsRedeemed() != null && booking.getLoyaltyPointsRedeemed() == points
            && booking.getLoyaltyDiscountAmount() != null) {
            booking.setFinalPrice(booking.getFinalPrice().add(discount).setScale(2, RoundingMode.HALF_UP));
            booking.setLoyaltyDiscountAmount(null);
            booking.setLoyaltyPointsRedeemed(null);
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Optional<LoyaltyPointsRedemption> nonTerminalFor(Long bookingId) {
        return redemptionRepo.findByBookingIdAndStatusIn(bookingId, LoyaltyRedemptionStatus.NON_TERMINAL)
            .stream().findFirst();
    }

    private LoyaltyPointsRedemption referenceOrThrow(String reference) {
        return redemptionRepo.findByRedemptionReference(reference)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Redemption not found: " + reference));
    }

    /**
     * Must not depend on the row's DB-generated id — {@code redemptionReference}
     * is {@code nullable=false} and has to be set before the (single) insert.
     * UUID-derived suffix backed by the DB unique constraint.
     */
    private String generateReference() {
        return "LRD-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + java.util.UUID.randomUUID().toString().replace("-", "").substring(0, 10).toUpperCase();
    }

    RedemptionResponse toResponse(LoyaltyPointsRedemption r) {
        return new RedemptionResponse(
            r.getId(), r.getRedemptionReference(), r.getCustomer().getId(), r.getBooking().getId(),
            r.getLoyaltyAccount().getId(), r.getPolicy().getPolicyCode(),
            r.getPointsRedeemed(), r.getDiscountAmount(), r.getEligibleAmount(), r.getStatus(),
            r.getReservedAt(), r.getAppliedAt(), r.getReleasedAt(), r.getRefundedAt(), r.getCancelledAt(),
            r.getExpiresAt(), r.getReason(), r.getIdempotencyKey(), r.getCreatedAt(), r.getUpdatedAt()
        );
    }

    // ── Admin listing (Specification-backed, paginated) ───────────────────────

    @Transactional(readOnly = true)
    public com.example.planyourtrip.dto.PageResponse<RedemptionResponse> adminList(
            Long customerId, Long bookingId, LoyaltyRedemptionStatus status, String reference,
            Instant createdFrom, Instant createdTo, Integer page, Integer size) {
        org.springframework.data.jpa.domain.Specification<LoyaltyPointsRedemption> spec =
            org.springframework.data.jpa.domain.Specification
                .where(com.example.planyourtrip.repository.LoyaltyRedemptionSpecification.withCustomerId(customerId))
                .and(com.example.planyourtrip.repository.LoyaltyRedemptionSpecification.withBookingId(bookingId))
                .and(com.example.planyourtrip.repository.LoyaltyRedemptionSpecification.withStatus(status))
                .and(com.example.planyourtrip.repository.LoyaltyRedemptionSpecification.withReference(reference))
                .and(com.example.planyourtrip.repository.LoyaltyRedemptionSpecification.createdFrom(createdFrom))
                .and(com.example.planyourtrip.repository.LoyaltyRedemptionSpecification.createdTo(createdTo));

        int p = page != null ? Math.max(page, 0) : 0;
        int sz = size != null && size > 0 ? size : 20;
        org.springframework.data.domain.Pageable pageable = org.springframework.data.domain.PageRequest.of(
            p, sz, org.springframework.data.domain.Sort.by("createdAt").descending().and(
                org.springframework.data.domain.Sort.by("id").descending()));

        org.springframework.data.domain.Page<RedemptionResponse> result =
            redemptionRepo.findAll(spec, pageable).map(this::toResponse);
        return com.example.planyourtrip.dto.PageResponse.of(result);
    }
}
