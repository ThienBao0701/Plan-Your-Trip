package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.LoyaltyDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.LoyaltyAccountRepository;
import com.example.planyourtrip.repository.LoyaltyPointsTransactionRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.18 — Loyalty Points Foundation.
 * Structural template is {@code TravelCreditService}: one ledger account per
 * user, created lazily on first access; every balance change inserts exactly
 * one immutable {@link LoyaltyPointsTransaction} carrying
 * balanceBefore/balanceAfter; idempotency via a pre-checked
 * {@code idempotencyKey} backstopped by a DB unique constraint; concurrency via
 * a pessimistic write lock on the account row
 * ({@link LoyaltyAccountRepository#findByUserIdForUpdate}, SELECT ... FOR
 * UPDATE) inside the {@code @Transactional} boundary — chosen over optimistic
 * {@code @Version} + retry, matching the proven Phase 7.14 strategy.
 *
 * <p>Points are integer counts, not money — {@code long}, never
 * {@code BigDecimal}. This phase does NOT implement redemption: points can
 * only ever be earned or granted, never spent or converted to cash, so
 * {@link LoyaltyAccount#currentBalance} and {@link LoyaltyAccount#lifetimePointsEarned}
 * move in lockstep here (every award increases both by the same amount) — see
 * {@link LoyaltyAccount} class javadoc for why the two fields are still kept
 * structurally independent.
 *
 * <p><b>Phase 7.19 update — points multiplier &amp; membership evaluation
 * hook.</b> {@link #awardBookingPoints} was written as a thin wrapper over the
 * internal {@link #credit} primitive specifically so this phase could
 * wrap/extend it with a tier multiplier without touching the ledger machinery
 * itself: {@code basePoints = floor(finalPrice/10,000)}, then
 * {@code awardedPoints = max(floor(basePoints × multiplier), 1)}, where the
 * multiplier comes from {@code CustomerMembershipService#resolveMultiplierForUser}
 * (1.00 when the user has no {@code CustomerMembership} row — existing users
 * are unaffected). {@link #awardReviewBonus} and {@link #adminGrant} remain
 * deliberately UNmultiplied, per Phase 7.19 spec. {@link #credit} — the single
 * insertion point for every increase — is also the single authoritative hook
 * that triggers {@code CustomerMembershipService#evaluateAutomaticUpgrade}
 * after a successful (non-idempotent-replay) award, atomically in the same
 * transaction, for all three transaction types (EARN_BOOKING, EARN_REVIEW,
 * GRANT) — "loyalty points awarded" in the 7.19 spec is the general rule that
 * booking completion and admin grant are both instances of.
 */
@Service
public class LoyaltyService {

    private final LoyaltyAccountRepository accountRepo;
    private final LoyaltyPointsTransactionRepository transactionRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;
    private final CustomerMembershipService customerMembershipService;

    /** Booking-completion earn rate: 1 point per 10,000 (of currency unit), floored, minimum 1. */
    private static final BigDecimal POINTS_PER_UNIT = BigDecimal.valueOf(10_000);

    public LoyaltyService(LoyaltyAccountRepository accountRepo,
                           LoyaltyPointsTransactionRepository transactionRepo,
                           UserRepository userRepo,
                           NotificationService notificationService,
                           CustomerMembershipService customerMembershipService) {
        this.accountRepo = accountRepo;
        this.transactionRepo = transactionRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
        this.customerMembershipService = customerMembershipService;
    }

    // ── Customer read paths ──────────────────────────────────────────────────

    /** Not readOnly — first access lazily creates the account. */
    @Transactional
    public LoyaltyAccountResponse getOrCreateMyAccount(Long userId) {
        return toAccountResponse(getOrCreateAccount(userId));
    }

    /** Strictly read-only — never creates the account. Used by e.g. the MEMBER coupon segment check. */
    @Transactional(readOnly = true)
    public Optional<LoyaltyAccountResponse> getAccount(Long userId) {
        return accountRepo.findByUserId(userId).map(this::toAccountResponse);
    }

    /**
     * Filtered/paginated transaction history, mirroring
     * {@code TravelCreditService#myTransactions}. Every filter is optional;
     * {@code from}/{@code to} are inclusive calendar dates in the system zone.
     */
    @Transactional
    public PageResponse<LoyaltyTransactionResponse> myTransactions(Long userId, Integer page, Integer size,
                                                                     LoyaltyTransactionType type,
                                                                     LocalDate from, LocalDate to) {
        LoyaltyAccount account = getOrCreateAccount(userId);

        List<LoyaltyPointsTransaction> all = transactionRepo
            .findByAccountIdOrderByCreatedAtDescIdDesc(account.getId()).stream()
            .filter(t -> type == null || t.getTransactionType() == type)
            .filter(t -> from == null || !txDate(t).isBefore(from))
            .filter(t -> to == null || !txDate(t).isAfter(to))
            .toList();

        int p = page != null ? Math.max(page, 0) : 0;
        int sz = size != null && size > 0 ? size : 20;
        int fromIdx = Math.min(p * sz, all.size());
        int toIdx = Math.min(fromIdx + sz, all.size());
        List<LoyaltyTransactionResponse> content =
            all.subList(fromIdx, toIdx).stream().map(this::toTransactionResponse).toList();

        return new PageResponse<>(content, p, sz, all.size(), (int) Math.ceil((double) all.size() / sz));
    }

    // ── Admin support view (strictly read-only — never creates the account) ─

    @Transactional(readOnly = true)
    public LoyaltyAdminViewResponse adminView(Long targetUserId) {
        userOrThrow(targetUserId);
        return accountRepo.findByUserId(targetUserId)
            .map(account -> new LoyaltyAdminViewResponse(
                targetUserId,
                toAccountResponse(account),
                transactionRepo.findByAccountIdOrderByCreatedAtDescIdDesc(account.getId()).stream()
                    .limit(20).map(this::toTransactionResponse).toList()))
            .orElseGet(() -> new LoyaltyAdminViewResponse(targetUserId, null, List.of()));
    }

    // ── Admin mutation (customers can NEVER grant their own points) ─────────

    @Transactional
    public LoyaltyTransactionResponse adminGrant(Long targetUserId, LoyaltyGrantRequest req) {
        String idempotencyKey = normalizeKey(req.idempotencyKey());
        return credit(targetUserId, LoyaltyTransactionType.GRANT, req.points(), req.description(),
            req.referenceType() != null ? req.referenceType() : LoyaltyReferenceType.ADMIN,
            req.referenceId(), idempotencyKey);
    }

    // ── Booking-completion earn (called by BookingService) ───────────────────

    /**
     * Awards PLAIN, unmultiplied points for a completed booking:
     * {@code basePoints = floor(finalPrice / 10,000)}, minimum 1 point for any
     * positive {@code finalPrice} (a qualifying booking always earns at least
     * 1 point). Idempotent via the deterministic key
     * {@code booking-<id>-loyalty-earn}, so a repeated completion trigger (e.g.
     * both {@code BookingService#adminUpdateStatus} and
     * {@code BookingService#adminComplete} reaching COMPLETED) never
     * double-awards. Returns empty when {@code finalPrice} is null or not
     * positive (nothing to award — no ledger row is written).
     */
    @Transactional
    public Optional<LoyaltyTransactionResponse> awardBookingPoints(Long userId, Long bookingId, BigDecimal finalPrice) {
        if (finalPrice == null || finalPrice.signum() <= 0) return Optional.empty();

        long basePoints = finalPrice.divide(POINTS_PER_UNIT, 0, RoundingMode.FLOOR).longValue();
        // Phase 7.19 — tier multiplier (1.00 when the user has no CustomerMembership row).
        BigDecimal multiplier = customerMembershipService.resolveMultiplierForUser(userId);
        long multiplied = BigDecimal.valueOf(basePoints).multiply(multiplier)
            .setScale(0, RoundingMode.FLOOR).longValue();
        long points = Math.max(multiplied, 1L);
        String idempotencyKey = "booking-" + bookingId + "-loyalty-earn";

        return Optional.of(credit(userId, LoyaltyTransactionType.EARN_BOOKING, points,
            "Points earned for completed booking #" + bookingId,
            LoyaltyReferenceType.BOOKING, bookingId, idempotencyKey));
    }

    // ── Review bonus (internal / admin-callable capability — no automatic trigger) ──

    /**
     * Awards review-bonus points via a distinct {@code EARN_REVIEW} path,
     * deliberately separate from {@link #awardBookingPoints}'s
     * {@code EARN_BOOKING} path so a future tier multiplier can apply
     * differently to the two (per Phase 7.19: "review bonus points are not
     * multiplied"). NOT wired to any automatic trigger — no review-submission
     * hook calls this; it is exposed purely as an internal/admin-callable
     * service capability for now. {@code reviewReferenceId} is optional; when
     * supplied it both anchors {@code referenceType=REVIEW} and produces a
     * deterministic idempotency key ({@code review-<id>-loyalty-bonus}) so the
     * same review can never be bonused twice.
     */
    @Transactional
    public LoyaltyTransactionResponse awardReviewBonus(Long userId, Long reviewReferenceId, long points,
                                                         String description) {
        String idempotencyKey = reviewReferenceId != null ? "review-" + reviewReferenceId + "-loyalty-bonus" : null;
        String desc = (description != null && !description.isBlank()) ? description : "Review bonus points";
        return credit(userId, LoyaltyTransactionType.EARN_REVIEW, points, desc,
            LoyaltyReferenceType.REVIEW, reviewReferenceId, idempotencyKey);
    }

    // ── Core ledger primitive ────────────────────────────────────────────────

    /**
     * The single insertion point for every increase in this phase
     * (EARN_BOOKING / EARN_REVIEW / GRANT). Idempotency pre-check, pessimistic
     * account lock, immutable ledger insert, then both
     * {@code currentBalance} and {@code lifetimePointsEarned} are increased by
     * the same amount — {@code lifetimePointsEarned} is NEVER decremented here
     * or anywhere else, preserving its monotonic guarantee (see
     * {@link LoyaltyAccount} class javadoc).
     */
    private LoyaltyTransactionResponse credit(Long userId, LoyaltyTransactionType type, long points,
                                               String description, LoyaltyReferenceType referenceType,
                                               Long referenceId, String idempotencyKey) {
        User user = userOrThrow(userId);
        if (points <= 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "points must be greater than zero");

        // Idempotency pre-check: replaying a key returns the original ledger row untouched.
        if (idempotencyKey != null) {
            var existing = transactionRepo.findByIdempotencyKey(idempotencyKey);
            if (existing.isPresent()) return toTransactionResponse(existing.get());
        }

        // Pessimistic write lock on the account row — see class javadoc.
        LoyaltyAccount account = accountRepo.findByUserIdForUpdate(userId)
            .orElseGet(() -> accountRepo.save(newAccount(user)));

        long before = account.getCurrentBalance();
        long after = before + points;

        LoyaltyPointsTransaction tx = new LoyaltyPointsTransaction();
        tx.setAccount(account);
        tx.setTransactionType(type);
        tx.setPoints(points);
        tx.setBalanceBefore(before);
        tx.setBalanceAfter(after);
        tx.setDescription(description);
        tx.setReferenceType(referenceType);
        tx.setReferenceId(referenceId);
        tx.setIdempotencyKey(idempotencyKey);
        LoyaltyPointsTransaction saved = transactionRepo.save(tx);

        account.setCurrentBalance(after);
        account.setLifetimePointsEarned(account.getLifetimePointsEarned() + points); // monotonic — never decremented
        accountRepo.save(account);

        notify(userId, type, points, saved.getId());

        // Phase 7.19 — single authoritative membership evaluation hook, same transaction.
        // No-op (and never creates a membership) when the user has never enrolled.
        customerMembershipService.evaluateAutomaticUpgrade(userId);

        return toTransactionResponse(saved);
    }

    private void notify(Long userId, LoyaltyTransactionType type, long points, Long txId) {
        // Deliberately only points — description/internal notes never leak into the user-facing message.
        String title = type == LoyaltyTransactionType.GRANT ? "Loyalty points added" : "Loyalty points earned";
        String verb = type == LoyaltyTransactionType.GRANT ? "added to" : "credited to";
        notificationService.create(userId, NotificationType.PROMOTION, Priority.NORMAL, title,
            points + " loyalty points have been " + verb + " your account.",
            RelatedEntityType.SYSTEM, txId);
    }

    // ── Account helpers ──────────────────────────────────────────────────────

    private LoyaltyAccount getOrCreateAccount(Long userId) {
        return accountRepo.findByUserId(userId)
            .orElseGet(() -> accountRepo.save(newAccount(userOrThrow(userId))));
    }

    private LoyaltyAccount newAccount(User user) {
        LoyaltyAccount account = new LoyaltyAccount();
        account.setUser(user);
        account.setCurrentBalance(0L);
        account.setLifetimePointsEarned(0L);
        return account;
    }

    private String normalizeKey(String key) {
        return key != null && !key.isBlank() ? key.trim() : null;
    }

    private User userOrThrow(Long userId) {
        return userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));
    }

    private LocalDate txDate(LoyaltyPointsTransaction t) {
        return t.getCreatedAt().atZone(ZoneId.systemDefault()).toLocalDate();
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private LoyaltyAccountResponse toAccountResponse(LoyaltyAccount a) {
        return new LoyaltyAccountResponse(
            a.getId(), a.getUser().getId(), a.getCurrentBalance(), a.getLifetimePointsEarned(),
            a.getCreatedAt(), a.getUpdatedAt()
        );
    }

    private LoyaltyTransactionResponse toTransactionResponse(LoyaltyPointsTransaction t) {
        return new LoyaltyTransactionResponse(
            t.getId(), t.getAccount().getId(), t.getTransactionType(),
            t.getPoints(), t.getBalanceBefore(), t.getBalanceAfter(),
            t.getDescription(), t.getReferenceType(), t.getReferenceId(),
            t.getIdempotencyKey(), t.getCreatedAt()
        );
    }
}
