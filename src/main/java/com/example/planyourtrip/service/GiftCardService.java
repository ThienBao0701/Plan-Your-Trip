package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.GiftCardDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.GiftCardRepository;
import com.example.planyourtrip.repository.GiftCardSpecification;
import com.example.planyourtrip.repository.GiftCardTransactionRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.security.SecureRandom;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Phase 7.24 — Gift Cards Foundation.
 * PREPAID PROMOTIONAL VALUE ONLY — not a bank account, no withdrawal, no
 * transfer between users, no cash conversion, no external payment gateway.
 * Built on the exact same proven ledger idiom already used by
 * {@code TravelCreditService} (Phase 7.14) and
 * {@code LoyaltyRedemptionService} (Phase 7.20): a pessimistic write lock on
 * the mutable row ({@link GiftCardRepository#findByIdForUpdate}, SELECT ...
 * FOR UPDATE) around every balance change, one immutable
 * {@link GiftCardTransaction} per change, and idempotency via a pre-checked +
 * DB-unique {@code idempotencyKey}. This is a NEW, independent ledger — it
 * never touches {@code TravelCreditAccount}/{@code LoyaltyAccount}.
 *
 * <p><b>Code masking.</b> {@link GiftCard#getGiftCardCode()} is the redeemable
 * secret; {@link GiftCard#getCodeLast4()} is safe for support display. Every
 * response returned by this service is masked by default
 * ({@code maskedCode} populated, {@code fullCode} null); the full code is
 * echoed back ONLY on the response returned directly from a successful
 * {@link #issueForCustomer}/{@link #issueForAdmin} call to the authorized
 * purchaser/admin — see {@link #toResponse(GiftCard, boolean)}. The full code
 * is never written to a log message or exception message anywhere in this
 * class.
 *
 * <p><b>Effective status.</b> {@link #effectiveStatus} computes EXPIRED on
 * read (expiresAt passed + balance &gt; 0) without persisting anything — the
 * same read-time pattern as {@code CustomerCouponService#effectiveStatus} /
 * {@code TravelWalletService#effectiveStatus}. The manual
 * {@link #processExpirations()} sweep is what actually persists the
 * EXPIRED status + zeroes the balance; until it runs, a card that is
 * effectively expired still shows its STORED (non-EXPIRED) status to
 * anything that reads {@code status} directly (e.g. admin list filtering,
 * cancellation eligibility) — deliberately, per the phase spec's "do not
 * silently expire cards only in memory if a manual processor has already
 * persisted expiration" instruction: reads always compute-and-show the
 * effective status, but never persist it themselves.
 */
@Service
public class GiftCardService {

    /** Excludes ambiguous characters (0/O, 1/I/L) — see class/phase javadoc. */
    private static final String CODE_ALPHABET = "23456789ABCDEFGHJKMNPQRSTUVWXYZ";
    private static final SecureRandom RANDOM = new SecureRandom();
    private static final int MAX_CODE_ATTEMPTS = 25;
    private static final List<GiftCardStatus> EXPIRABLE_STATUSES =
        List.of(GiftCardStatus.ISSUED, GiftCardStatus.ACTIVE, GiftCardStatus.PARTIALLY_REDEEMED);

    private final GiftCardRepository giftCardRepo;
    private final GiftCardTransactionRepository transactionRepo;
    private final GiftCardProductService productService;
    private final UserRepository userRepo;
    private final NotificationService notificationService;
    private final BookingRepository bookingRepo;

    public GiftCardService(GiftCardRepository giftCardRepo,
                            GiftCardTransactionRepository transactionRepo,
                            GiftCardProductService productService,
                            UserRepository userRepo,
                            NotificationService notificationService,
                            BookingRepository bookingRepo) {
        this.giftCardRepo = giftCardRepo;
        this.transactionRepo = transactionRepo;
        this.productService = productService;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
        this.bookingRepo = bookingRepo;
    }

    // ═════════════════════════════════════════════════════════════════════
    // ISSUANCE
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Customer self-service issuance — {@code POST /api/me/gift-cards/issue}.
     * NO REAL PAYMENT IS COLLECTED: this is a clearly named mock/internal
     * issuance path. Production issuance must later be gated on a successful
     * payment (a future phase) before calling the shared {@link #issueInternal}
     * primitive with a real payment reference.
     */
    @Transactional
    public GiftCardResponse issueForCustomer(Long purchaserUserId, GiftCardIssueRequest req) {
        User purchaser = userOrThrow(purchaserUserId);
        return issueInternal(purchaser, req.productCode(), req.amount(),
            req.recipientUserId(), req.recipientEmail(), req.personalMessage(),
            req.idempotencyKey(), GiftCardReferenceType.SYSTEM,
            "Self-service mock issuance (no real payment collected in this phase)");
    }

    /**
     * Admin issuance — {@code POST /api/admin/gift-cards/issue}.
     * {@code purchaserUserId} is optional — {@code null} means a house/admin
     * grant with no purchaser (e.g. a promotional campaign card).
     */
    @Transactional
    public GiftCardResponse issueForAdmin(AdminGiftCardIssueRequest req) {
        User purchaser = req.purchaserUserId() != null ? userOrThrow(req.purchaserUserId()) : null;
        return issueInternal(purchaser, req.productCode(), req.amount(),
            req.recipientUserId(), req.recipientEmail(), req.personalMessage(),
            req.idempotencyKey(), GiftCardReferenceType.ADMIN, "Admin issuance");
    }

    private GiftCardResponse issueInternal(User purchaser, String productCode, BigDecimal amount,
                                            Long recipientUserId, String recipientEmailRaw,
                                            String personalMessage, String idempotencyKeyRaw,
                                            GiftCardReferenceType referenceType, String ledgerNote) {
        // Idempotency pre-check: the ISSUE ledger row carries the key (GiftCard
        // itself has no idempotencyKey column — see class javadoc / phase spec
        // field list). Replaying the same key returns the original card untouched.
        String idempotencyKey = blankToNull(idempotencyKeyRaw);
        if (idempotencyKey != null) {
            Optional<GiftCardTransaction> existing = transactionRepo.findByIdempotencyKey(idempotencyKey);
            if (existing.isPresent()) return toResponse(existing.get().getGiftCard(), true);
        }

        if (recipientUserId != null && recipientEmailRaw != null && !recipientEmailRaw.isBlank())
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Provide at most one of recipientUserId or recipientEmail");

        GiftCardProduct product = productService.productByCodeOrThrow(productCode);
        assertProductIssuable(product);

        BigDecimal normalizedAmount = amount.setScale(2, RoundingMode.HALF_UP);
        validateAmountAgainstProduct(product, normalizedAmount);

        User recipientUser = recipientUserId != null ? userOrThrow(recipientUserId) : null;
        String recipientEmail = normalizeEmail(recipientEmailRaw);

        GiftCard card = new GiftCard();
        card.setGiftCardCode(generateUniqueCode());
        card.setCodeLast4(lastFour(card.getGiftCardCode()));
        card.setProduct(product);
        card.setPurchaserUser(purchaser);
        card.setRecipientUser(recipientUser);
        card.setRecipientEmail(recipientEmail);
        card.setOriginalAmount(normalizedAmount);
        card.setCurrentBalance(normalizedAmount);
        card.setCurrency(product.getCurrency());
        card.setStatus(GiftCardStatus.ISSUED);
        card.setPersonalMessage(personalMessage);
        card.setIssuedAt(Instant.now());
        GiftCard saved = giftCardRepo.save(card);

        insertLedger(saved, GiftCardTransactionType.ISSUE, normalizedAmount,
            BigDecimal.ZERO.setScale(2, RoundingMode.UNNECESSARY), normalizedAmount,
            "Issued gift card (" + ledgerNote + ")", referenceType, null, idempotencyKey);

        if (recipientUser != null && (purchaser == null || !recipientUser.getId().equals(purchaser.getId()))) {
            notificationService.create(recipientUser.getId(), NotificationType.PROMOTION, Priority.NORMAL,
                "You received a gift card",
                "You received a " + normalizedAmount.toPlainString() + " " + card.getCurrency()
                    + " gift card. Activate it to start using it.",
                RelatedEntityType.SYSTEM, saved.getId());
        }

        return toResponse(saved, true);
    }

    // ═════════════════════════════════════════════════════════════════════
    // ACTIVATION / CLAIMING
    // ═════════════════════════════════════════════════════════════════════

    /** Direct activation by id for the registered recipient (or the purchaser, when no recipient was set). */
    @Transactional
    public GiftCardResponse activate(Long userId, Long giftCardId) {
        GiftCard card = ownedCardOrThrow(userId, giftCardId);
        return toResponse(activateInternal(userId, card), false);
    }

    /**
     * Claim an email-issued gift card after authentication —
     * {@code POST /api/me/gift-cards/claim}. Binds {@code recipientUser} to the
     * caller the first time (only when the caller's own email matches the
     * card's {@code recipientEmail}, case-insensitively), then runs the same
     * activation core. Idempotent: claiming twice as the same (now-bound)
     * recipient just returns the current state.
     */
    @Transactional
    public GiftCardResponse claim(Long userId, String rawCode) {
        String code = normalizeCode(rawCode);
        GiftCard card = giftCardRepo.findByGiftCardCode(code)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found"));

        User caller = userOrThrow(userId);
        boolean alreadyAuthorized = isPurchaserOrRecipient(userId, card);
        boolean emailMatch = card.getRecipientUser() == null && card.getRecipientEmail() != null
            && card.getRecipientEmail().equalsIgnoreCase(normalizeEmail(caller.getEmail()));

        if (!alreadyAuthorized && !emailMatch)
            throw new ApiException(HttpStatus.NOT_FOUND, "Gift card not found");

        if (emailMatch && card.getRecipientUser() == null) {
            card.setRecipientUser(caller);
            card = giftCardRepo.save(card);
        }

        return toResponse(activateInternal(userId, card), false);
    }

    /** Admin activation for support/testing — bypasses the purchaser/recipient ownership gate. */
    @Transactional
    public GiftCardResponse adminActivate(Long giftCardId) {
        GiftCard card = giftCardOrThrow(giftCardId);
        Long actingUserId = card.getRecipientUser() != null ? card.getRecipientUser().getId()
            : card.getPurchaserUser() != null ? card.getPurchaserUser().getId() : null;
        return toResponse(activateInternal(actingUserId, card), false);
    }

    /**
     * Shared activation core. Only an ISSUED card can activate; ACTIVE (same
     * authorized user replaying) is idempotent and returns the current state
     * unchanged; any other stored status (CANCELLED/EXPIRED/PARTIALLY_REDEEMED/
     * FULLY_REDEEMED) is rejected with 409. Expiry is derived from whichever of
     * the product's {@code validUntil} / {@code activatedAt + validDaysAfterActivation}
     * applies, using the EARLIER date when both are present.
     */
    private GiftCard activateInternal(Long userId, GiftCard viewedCard) {
        GiftCard card = giftCardRepo.findByIdForUpdate(viewedCard.getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found"));

        if (card.getStatus() == GiftCardStatus.ACTIVE) return card; // idempotent replay
        if (card.getStatus() != GiftCardStatus.ISSUED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Only an ISSUED gift card can be activated (current status: " + card.getStatus() + ")");

        Instant now = Instant.now();
        card.setActivatedAt(now);
        card.setExpiresAt(computeExpiresAt(card.getProduct(), now));
        card.setStatus(GiftCardStatus.ACTIVE);
        GiftCard saved = giftCardRepo.save(card);

        // Zero-amount marker row — records the activation event without touching the balance.
        String key = "giftcard-" + saved.getId() + "-activate";
        if (transactionRepo.findByIdempotencyKey(key).isEmpty()) {
            insertLedger(saved, GiftCardTransactionType.ACTIVATE,
                BigDecimal.ZERO.setScale(2, RoundingMode.UNNECESSARY),
                saved.getCurrentBalance(), saved.getCurrentBalance(),
                "Gift card activated", GiftCardReferenceType.SYSTEM, null, key);
        }

        if (userId != null) {
            notificationService.create(userId, NotificationType.PROMOTION, Priority.NORMAL,
                "Gift card activated",
                "Your " + saved.getCurrentBalance().toPlainString() + " " + saved.getCurrency()
                    + " gift card is now active and ready to use.",
                RelatedEntityType.SYSTEM, saved.getId());
        }

        return saved;
    }

    private Instant computeExpiresAt(GiftCardProduct product, Instant activatedAt) {
        Instant fromProductWindow = product.getValidUntil() != null ? endOfDay(product.getValidUntil()) : null;
        Instant fromActivation = product.getValidDaysAfterActivation() != null
            ? activatedAt.plus(product.getValidDaysAfterActivation(), java.time.temporal.ChronoUnit.DAYS)
            : null;
        if (fromProductWindow == null) return fromActivation;
        if (fromActivation == null) return fromProductWindow;
        return fromProductWindow.isBefore(fromActivation) ? fromProductWindow : fromActivation;
    }

    private Instant endOfDay(LocalDate date) {
        return date.plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();
    }

    // ═════════════════════════════════════════════════════════════════════
    // PREVIEW (strictly read-only)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Redemption preview — {@code POST /api/me/gift-cards/preview}. Deliberately
     * NOT ownership-scoped (documented judgment call): a gift card is redeemable
     * by whoever holds the code, exactly like a coupon code — the phase spec
     * lists no purchaser/recipient restriction for preview, only for the
     * list/get-by-id/get-by-code/transactions endpoints. Never mutates a
     * balance. An unknown code returns a structured ineligible response (never
     * a 404) — mirrors {@code CouponPreviewResponse}'s soft-fail convention for
     * a checkout-time preview.
     */
    @Transactional(readOnly = true)
    public GiftCardPreviewResponse preview(GiftCardPreviewRequest req) {
        Optional<GiftCard> found = giftCardRepo.findByGiftCardCode(normalizeCode(req.giftCardCode()));
        BigDecimal orderAmount = req.orderAmount().setScale(2, RoundingMode.HALF_UP);
        if (found.isEmpty())
            return new GiftCardPreviewResponse(false, "Gift card not found",
                BigDecimal.ZERO, BigDecimal.ZERO, orderAmount, null, null);

        GiftCard card = found.get();
        GiftCardStatus effective = effectiveStatus(card);

        if (!card.getCurrency().equalsIgnoreCase(req.currency().trim()))
            return new GiftCardPreviewResponse(false, "Currency mismatch: gift card currency is " + card.getCurrency(),
                card.getCurrentBalance(), BigDecimal.ZERO, orderAmount, effective, card.getExpiresAt());

        if (effective != GiftCardStatus.ACTIVE && effective != GiftCardStatus.PARTIALLY_REDEEMED)
            return new GiftCardPreviewResponse(false, "Gift card is not redeemable (status: " + effective + ")",
                card.getCurrentBalance(), BigDecimal.ZERO, orderAmount, effective, card.getExpiresAt());

        if (card.getCurrentBalance().signum() <= 0)
            return new GiftCardPreviewResponse(false, "Gift card has no remaining balance",
                card.getCurrentBalance(), BigDecimal.ZERO, orderAmount, effective, card.getExpiresAt());

        BigDecimal redeemable = card.getCurrentBalance().min(orderAmount);
        BigDecimal finalPayable = orderAmount.subtract(redeemable).max(BigDecimal.ZERO);
        return new GiftCardPreviewResponse(true, null,
            card.getCurrentBalance(), redeemable, finalPayable, effective, card.getExpiresAt());
    }

    // ═════════════════════════════════════════════════════════════════════
    // CHECKOUT INTEGRATION (Phase 7.25)
    // ═════════════════════════════════════════════════════════════════════
    //
    // Checkout pricing order (documented — enforced by BookingService.create's
    // pipeline, which reduces booking.finalPrice step by step):
    //     Base → Promotion → Coupon → Loyalty → Travel Credits → GIFT CARD → Payable
    // Gift cards always apply AFTER travel credits: redemption is computed against
    // the booking's CURRENT finalPrice at this point in the pipeline.
    //
    // Unlike loyalty's reserve/apply split, a gift card is an IMMEDIATE DEBIT at
    // booking creation (like travel credits): one REDEMPTION ledger row now. The
    // three-way payment split is then:
    //     payment SUCCESS  → keep the redemption (no callback — the debit stands)
    //     payment FAILURE  → releaseForBooking (restore balance, REFUND row)
    //     booking CANCELLED → refundForBooking (restore balance, REFUND row)
    // Both release and refund route through the SAME single restore primitive with
    // ONE deterministic idempotency key ({@code booking-<id>-giftcard-refund}), so a
    // booking that fails payment and is later cancelled is restored AT MOST ONCE —
    // additionally guarded by clearing the booking's own gift-card fields on restore
    // (mirrors LoyaltyRedemptionService.removeDiscountFromBooking / the 7.15 credit
    // guard). Every balance change reuses the same centralized {@link #insertLedger}
    // primitive + {@link GiftCardRepository#findByIdForUpdate} pessimistic lock +
    // {@link #deriveStatusAfterBalanceChange} used by every other operation — never a
    // second debit/credit code path.

    /**
     * Booking-scoped redemption preview (read-only) —
     * {@code POST /api/me/gift-cards/preview-booking}. Ownership-scoped: an unknown
     * or unrelated card returns a structured ineligible response (never a 404),
     * mirroring the general {@link #preview}'s soft-fail convention (documented
     * judgment call — avoids leaking card existence on a read-only endpoint). The
     * booking must belong to the caller (403 otherwise).
     */
    @Transactional(readOnly = true)
    public GiftCardBookingPreviewResponse previewForBooking(Long userId, GiftCardBookingPreviewRequest req) {
        Booking booking = bookingRepo.findById(req.bookingId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + req.bookingId()));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");

        BigDecimal payable = booking.getFinalPrice();
        Optional<GiftCard> found = giftCardRepo.findByGiftCardCode(normalizeCode(req.giftCardCode()));
        if (found.isEmpty() || !isPurchaserOrRecipient(userId, found.get()))
            return new GiftCardBookingPreviewResponse(false, "Gift card not found",
                BigDecimal.ZERO, BigDecimal.ZERO, payable, null, null);

        GiftCard card = found.get();
        GiftCardStatus effective = effectiveStatus(card);

        if (!card.getCurrency().equalsIgnoreCase(booking.getCurrency()))
            return new GiftCardBookingPreviewResponse(false,
                "Currency mismatch: gift card currency is " + card.getCurrency(),
                card.getCurrentBalance(), card.getCurrentBalance(), payable, effective, card.getExpiresAt());
        if (effective != GiftCardStatus.ACTIVE && effective != GiftCardStatus.PARTIALLY_REDEEMED)
            return new GiftCardBookingPreviewResponse(false,
                "Gift card is not redeemable (status: " + effective + ")",
                card.getCurrentBalance(), card.getCurrentBalance(), payable, effective, card.getExpiresAt());
        if (card.getCurrentBalance().signum() <= 0)
            return new GiftCardBookingPreviewResponse(false, "Gift card has no remaining balance",
                card.getCurrentBalance(), card.getCurrentBalance(), payable, effective, card.getExpiresAt());

        BigDecimal applied = card.getCurrentBalance().min(payable).max(BigDecimal.ZERO);
        BigDecimal remainingPayable = payable.subtract(applied).max(BigDecimal.ZERO);
        BigDecimal remainingBalance = card.getCurrentBalance().subtract(applied);
        return new GiftCardBookingPreviewResponse(true, null,
            applied, remainingBalance, remainingPayable, effective, card.getExpiresAt());
    }

    /**
     * Immediate gift-card debit at booking creation — called by
     * {@code BookingService.create} AFTER travel-credit application. Redeems
     * {@code min(currentBalance, booking.finalPrice)} (never negative, never more
     * than the remaining payable), writes ONE REDEMPTION ledger row
     * (referenceType=BOOKING, referenceId=bookingId, key
     * {@code booking-<id>-giftcard-redemption}), reduces {@code booking.finalPrice}
     * and records the masked reference on the booking. Runs inside the caller's
     * booking-creation transaction under the card's pessimistic lock, so a failed
     * booking rolls the debit back.
     *
     * <p>Security: only the card's purchaser/recipient may redeem it — any other
     * card is a 404 (never 403), matching the "avoid leaking existence" convention.
     * Currency must match the booking (400), the card must be redeemable
     * (ACTIVE/PARTIALLY_REDEEMED — else 409), balance &gt; 0. When the remaining
     * payable is already 0 the gift card contributes nothing and no ledger row is
     * written (no-op).
     */
    @Transactional
    public void redeemForBooking(Long userId, String rawCode, Booking booking) {
        String code = normalizeCode(rawCode);
        GiftCard viewed = giftCardRepo.findByGiftCardCode(code)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found"));
        if (!isPurchaserOrRecipient(userId, viewed))
            throw new ApiException(HttpStatus.NOT_FOUND, "Gift card not found");

        String key = "booking-" + booking.getId() + "-giftcard-redemption";
        if (transactionRepo.findByIdempotencyKey(key).isPresent()) return; // already redeemed (defensive replay)

        GiftCard card = giftCardRepo.findByIdForUpdate(viewed.getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found"));

        GiftCardStatus effective = effectiveStatus(card);
        if (!card.getCurrency().equalsIgnoreCase(booking.getCurrency()))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Currency mismatch: gift card currency is " + card.getCurrency());
        if (effective != GiftCardStatus.ACTIVE && effective != GiftCardStatus.PARTIALLY_REDEEMED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Gift card is not redeemable (status: " + effective + ")");
        if (card.getCurrentBalance().signum() <= 0)
            throw new ApiException(HttpStatus.CONFLICT, "Gift card has no remaining balance");

        BigDecimal remainingPayable = booking.getFinalPrice();
        BigDecimal redeem = card.getCurrentBalance().min(remainingPayable)
            .max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
        if (redeem.signum() <= 0) return; // nothing left to pay — gift card contributes nothing

        BigDecimal before = card.getCurrentBalance();
        BigDecimal after = before.subtract(redeem);
        card.setCurrentBalance(after);
        card.setStatus(deriveStatusAfterBalanceChange(card, after));
        if (card.getStatus() == GiftCardStatus.FULLY_REDEEMED && card.getFullyRedeemedAt() == null)
            card.setFullyRedeemedAt(Instant.now());
        giftCardRepo.save(card);

        insertLedger(card, GiftCardTransactionType.REDEMPTION, redeem, before, after,
            "Redeemed against booking #" + booking.getId(),
            GiftCardReferenceType.BOOKING, booking.getId(), key);

        booking.setGiftCardAmountUsed(redeem);
        booking.setGiftCardReference(maskCode(card.getCodeLast4()));
        booking.setFinalPrice(booking.getFinalPrice().subtract(redeem)
            .max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP));
        bookingRepo.save(booking);

        Long notifyUserId = booking.getUser().getId();
        notificationService.create(notifyUserId, NotificationType.PROMOTION, Priority.NORMAL,
            "Gift card used",
            redeem.toPlainString() + " " + card.getCurrency() + " from your gift card "
                + maskCode(card.getCodeLast4()) + " was applied to booking " + booking.getBookingCode() + ".",
            RelatedEntityType.BOOKING, booking.getId());
    }

    /**
     * Payment-failure release — {@code PaymentService.mockFail} hook. Restores the
     * redeemed balance and un-applies the discount from the booking. Idempotent
     * no-op when there is nothing (still) redeemed for the booking.
     */
    @Transactional
    public void releaseForBooking(Long bookingId) {
        restoreForBooking(bookingId, "payment failed");
    }

    /**
     * Booking-cancellation refund — {@code BookingService} cancel hook. Same restore
     * primitive as {@link #releaseForBooking} (same REFUND ledger type + same single
     * deterministic idempotency key), so a booking that failed payment and is later
     * cancelled is never restored twice. Idempotent no-op when nothing is redeemed.
     */
    @Transactional
    public void refundForBooking(Long bookingId) {
        restoreForBooking(bookingId, "booking cancelled");
    }

    /**
     * Single restore primitive shared by release (payment failure) and refund
     * (cancellation). Guard #1: the booking's own {@code giftCardAmountUsed} — once
     * a restore clears it, every later trigger is a no-op (mirrors the 7.15 credit /
     * loyalty guard). Guard #2: the deterministic REFUND ledger key
     * {@code booking-<id>-giftcard-refund} (pre-check + DB unique backstop). The
     * gift card is located via the REDEMPTION ledger row's BOOKING/referenceId
     * anchor, so no full code is ever stored on the booking.
     */
    private void restoreForBooking(Long bookingId, String trigger) {
        Booking booking = bookingRepo.findById(bookingId).orElse(null);
        if (booking == null) return;
        if (booking.getGiftCardAmountUsed() == null || booking.getGiftCardAmountUsed().signum() <= 0)
            return; // nothing redeemed, or already restored

        String refundKey = "booking-" + bookingId + "-giftcard-refund";
        if (transactionRepo.findByIdempotencyKey(refundKey).isPresent()) return; // already restored

        Optional<GiftCardTransaction> redemption = transactionRepo
            .findFirstByReferenceTypeAndReferenceIdAndTransactionType(
                GiftCardReferenceType.BOOKING, bookingId, GiftCardTransactionType.REDEMPTION);
        if (redemption.isEmpty()) return; // no debit on record — nothing to give back

        BigDecimal amount = booking.getGiftCardAmountUsed();
        GiftCard card = giftCardRepo.findByIdForUpdate(redemption.get().getGiftCard().getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found"));

        BigDecimal before = card.getCurrentBalance();
        BigDecimal after = before.add(amount);
        card.setCurrentBalance(after);
        card.setStatus(deriveStatusAfterBalanceChange(card, after));
        if (after.signum() > 0) card.setFullyRedeemedAt(null); // reopened — no longer fully redeemed
        giftCardRepo.save(card);

        insertLedger(card, GiftCardTransactionType.REFUND, amount, before, after,
            "Gift card refunded (" + trigger + ") for booking #" + bookingId,
            GiftCardReferenceType.BOOKING, bookingId, refundKey);

        // Un-apply the discount on the booking and clear the gift-card fields
        // (mirrors LoyaltyRedemptionService.removeDiscountFromBooking) so the payable
        // is correct on a retry and any subsequent restore is a no-op.
        booking.setFinalPrice(booking.getFinalPrice().add(amount).setScale(2, RoundingMode.HALF_UP));
        booking.setGiftCardAmountUsed(null);
        booking.setGiftCardReference(null);
        bookingRepo.save(booking);

        notificationService.create(booking.getUser().getId(), NotificationType.PROMOTION, Priority.NORMAL,
            "Gift card refunded",
            amount.toPlainString() + " " + card.getCurrency() + " was refunded to your gift card "
                + maskCode(card.getCodeLast4()) + " for booking " + booking.getBookingCode() + ".",
            RelatedEntityType.BOOKING, booking.getId());
    }

    // ═════════════════════════════════════════════════════════════════════
    // ADMIN ADJUSTMENT
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Admin manual credit/debit — {@code POST /api/admin/gift-cards/{id}/adjust}.
     * CANCELLED/EXPIRED/FULLY_REDEEMED cards cannot be adjusted — no support
     * exception is implemented in this phase (documented judgment call; the
     * spec allows one to be "explicitly documented", so this phase deliberately
     * chooses not to add one). The internal {@code description} is an admin
     * note persisted only on the ledger row — never surfaced in a notification.
     */
    @Transactional
    public GiftCardTransactionResponse adminAdjust(Long giftCardId, GiftCardAdjustmentRequest req) {
        String idempotencyKey = blankToNull(req.idempotencyKey());
        if (idempotencyKey != null) {
            Optional<GiftCardTransaction> existing = transactionRepo.findByIdempotencyKey(idempotencyKey);
            if (existing.isPresent()) return toTransactionResponse(existing.get());
        }

        GiftCard card = giftCardRepo.findByIdForUpdate(giftCardId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found: " + giftCardId));

        if (card.getStatus() == GiftCardStatus.CANCELLED || card.getStatus() == GiftCardStatus.EXPIRED
                || card.getStatus() == GiftCardStatus.FULLY_REDEEMED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Cannot adjust a gift card in status " + card.getStatus());

        BigDecimal amount = req.amount().setScale(2, RoundingMode.HALF_UP);
        BigDecimal before = card.getCurrentBalance();
        BigDecimal after;
        if (req.direction() == GiftCardAdjustmentDirection.CREDIT) {
            after = before.add(amount);
        } else {
            if (before.compareTo(amount) < 0)
                throw new ApiException(HttpStatus.CONFLICT,
                    "Insufficient gift card balance: balance " + before.toPlainString()
                        + ", requested deduction " + amount.toPlainString());
            after = before.subtract(amount);
        }

        card.setCurrentBalance(after);
        card.setStatus(deriveStatusAfterBalanceChange(card, after));
        if (card.getStatus() == GiftCardStatus.FULLY_REDEEMED && card.getFullyRedeemedAt() == null)
            card.setFullyRedeemedAt(Instant.now());
        giftCardRepo.save(card);

        GiftCardTransaction tx = insertLedger(card, GiftCardTransactionType.ADJUSTMENT, amount, before, after,
            req.description(), req.referenceType(), req.referenceId(), idempotencyKey);

        return toTransactionResponse(tx);
    }

    private GiftCardStatus deriveStatusAfterBalanceChange(GiftCard card, BigDecimal newBalance) {
        if (newBalance.signum() == 0) return GiftCardStatus.FULLY_REDEEMED;
        if (card.getStatus() == GiftCardStatus.ISSUED) return GiftCardStatus.ISSUED;
        return newBalance.compareTo(card.getOriginalAmount()) < 0
            ? GiftCardStatus.PARTIALLY_REDEEMED : GiftCardStatus.ACTIVE;
    }

    // ═════════════════════════════════════════════════════════════════════
    // CANCELLATION
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Admin cancellation — {@code POST /api/admin/gift-cards/{id}/cancel}. Only
     * ISSUED/ACTIVE/PARTIALLY_REDEEMED (by STORED status) may cancel;
     * FULLY_REDEEMED can never cancel. Already-CANCELLED is idempotent (returns
     * the existing state, no second ledger row / notification). No cash refund
     * is created — the balance is simply zeroed on the ledger.
     */
    @Transactional
    public GiftCardResponse adminCancel(Long giftCardId) {
        GiftCard card = giftCardRepo.findByIdForUpdate(giftCardId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found: " + giftCardId));

        if (card.getStatus() == GiftCardStatus.CANCELLED) return toResponse(card, false); // idempotent
        if (card.getStatus() == GiftCardStatus.FULLY_REDEEMED)
            throw new ApiException(HttpStatus.CONFLICT, "A fully redeemed gift card cannot be cancelled");
        if (card.getStatus() != GiftCardStatus.ISSUED && card.getStatus() != GiftCardStatus.ACTIVE
                && card.getStatus() != GiftCardStatus.PARTIALLY_REDEEMED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Cannot cancel a gift card in status " + card.getStatus());

        BigDecimal before = card.getCurrentBalance();
        card.setCurrentBalance(BigDecimal.ZERO.setScale(2, RoundingMode.UNNECESSARY));
        card.setStatus(GiftCardStatus.CANCELLED);
        card.setCancelledAt(Instant.now());
        GiftCard saved = giftCardRepo.save(card);

        insertLedger(saved, GiftCardTransactionType.CANCELLATION, before, before, BigDecimal.ZERO,
            "Gift card cancelled by admin", GiftCardReferenceType.ADMIN, null,
            "giftcard-" + saved.getId() + "-cancellation");

        Long notifyUserId = saved.getRecipientUser() != null ? saved.getRecipientUser().getId()
            : saved.getPurchaserUser() != null ? saved.getPurchaserUser().getId() : null;
        if (notifyUserId != null) {
            notificationService.create(notifyUserId, NotificationType.PROMOTION, Priority.NORMAL,
                "Gift card cancelled",
                "Your gift card has been cancelled by support and can no longer be used.",
                RelatedEntityType.SYSTEM, saved.getId());
        }

        return toResponse(saved, false);
    }

    // ═════════════════════════════════════════════════════════════════════
    // EXPIRATION PROCESSOR (admin-triggered; no scheduler)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * {@code POST /api/admin/gift-cards/process-expirations}. Locks each
     * affected card, appends one EXPIRATION ledger row for the remaining
     * balance, zeroes the balance and sets status EXPIRED. Idempotent: a card
     * already at zero balance / already EXPIRED never matches the candidate
     * query again, backstopped by a per-card idempotency key.
     */
    @Transactional
    public GiftCardExpirationResultResponse processExpirations() {
        Instant now = Instant.now();
        List<GiftCard> candidates = giftCardRepo.findExpirationCandidates(now, EXPIRABLE_STATUSES);

        List<GiftCardTransactionResponse> expirations = new ArrayList<>();
        BigDecimal totalExpired = BigDecimal.ZERO.setScale(2, RoundingMode.UNNECESSARY);

        for (GiftCard candidate : candidates) {
            GiftCard card = giftCardRepo.findByIdForUpdate(candidate.getId()).orElseThrow();
            // Re-check under the lock — defensive against any change since the candidate scan.
            if (card.getCurrentBalance().signum() <= 0) continue;
            if (card.getExpiresAt() == null || !card.getExpiresAt().isBefore(now)) continue;
            if (card.getStatus() == GiftCardStatus.CANCELLED || card.getStatus() == GiftCardStatus.EXPIRED
                    || card.getStatus() == GiftCardStatus.FULLY_REDEEMED) continue;

            String key = "giftcard-" + card.getId() + "-expiration";
            if (transactionRepo.findByIdempotencyKey(key).isPresent()) continue;

            BigDecimal before = card.getCurrentBalance();
            card.setCurrentBalance(BigDecimal.ZERO.setScale(2, RoundingMode.UNNECESSARY));
            card.setStatus(GiftCardStatus.EXPIRED);
            GiftCard saved = giftCardRepo.save(card);

            GiftCardTransaction tx = insertLedger(saved, GiftCardTransactionType.EXPIRATION, before, before,
                BigDecimal.ZERO, "Gift card expired (expiresAt " + saved.getExpiresAt() + ")",
                GiftCardReferenceType.SYSTEM, null, key);

            expirations.add(toTransactionResponse(tx));
            totalExpired = totalExpired.add(before);
        }

        return new GiftCardExpirationResultResponse(expirations.size(),
            totalExpired.setScale(2, RoundingMode.HALF_UP), expirations);
    }

    // ═════════════════════════════════════════════════════════════════════
    // CUSTOMER READS
    // ═════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public PageResponse<GiftCardSummaryResponse> listMine(Long userId, GiftCardStatus statusFilter,
                                                           Boolean includeExpired, Integer page, Integer size) {
        Map<Long, GiftCard> byId = new LinkedHashMap<>();
        giftCardRepo.findByPurchaserUserIdOrderByCreatedAtDesc(userId).forEach(c -> byId.put(c.getId(), c));
        giftCardRepo.findByRecipientUserIdOrderByCreatedAtDesc(userId).forEach(c -> byId.put(c.getId(), c));

        boolean includeExp = includeExpired != null && includeExpired;
        List<GiftCardSummaryResponse> all = byId.values().stream()
            .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt()))
            .map(c -> Map.entry(c, effectiveStatus(c)))
            .filter(e -> includeExp || e.getValue() != GiftCardStatus.EXPIRED)
            .filter(e -> statusFilter == null || e.getValue() == statusFilter)
            .map(e -> toSummary(e.getKey(), e.getValue()))
            .toList();

        return paginate(all, page, size);
    }

    @Transactional(readOnly = true)
    public GiftCardResponse getMine(Long userId, Long id) {
        return toResponse(ownedCardOrThrow(userId, id), false);
    }

    @Transactional(readOnly = true)
    public GiftCardResponse getMineByCode(Long userId, String rawCode) {
        GiftCard card = giftCardRepo.findByGiftCardCode(normalizeCode(rawCode))
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found"));
        if (!isPurchaserOrRecipient(userId, card))
            throw new ApiException(HttpStatus.NOT_FOUND, "Gift card not found");
        return toResponse(card, false);
    }

    @Transactional(readOnly = true)
    public PageResponse<GiftCardTransactionResponse> myTransactions(Long userId, Long id, Integer page, Integer size) {
        GiftCard card = ownedCardOrThrow(userId, id);
        List<GiftCardTransactionResponse> all = transactionRepo
            .findByGiftCardIdOrderByCreatedAtDescIdDesc(card.getId()).stream()
            .map(this::toTransactionResponse).toList();
        return paginate(all, page, size);
    }

    // ═════════════════════════════════════════════════════════════════════
    // ADMIN READS
    // ═════════════════════════════════════════════════════════════════════

    /**
     * Filters by the STORED status column (documented judgment call — the
     * effectiveStatus computed field is still returned per-row for admin
     * visibility, but a DB-level Specification filter can't cheaply express
     * the read-time expiry computation).
     */
    @Transactional(readOnly = true)
    public PageResponse<GiftCardResponse> adminList(String code, Long purchaserUserId, Long recipientUserId,
                                                      GiftCardStatus status, Long productId,
                                                      Instant issuedFrom, Instant issuedTo,
                                                      Instant expiresFrom, Instant expiresTo,
                                                      Integer page, Integer size) {
        Specification<GiftCard> spec = Specification
            .where(GiftCardSpecification.withCode(code))
            .and(GiftCardSpecification.withPurchaserUserId(purchaserUserId))
            .and(GiftCardSpecification.withRecipientUserId(recipientUserId))
            .and(GiftCardSpecification.withStatus(status))
            .and(GiftCardSpecification.withProductId(productId))
            .and(GiftCardSpecification.issuedFrom(issuedFrom))
            .and(GiftCardSpecification.issuedTo(issuedTo))
            .and(GiftCardSpecification.expiresFrom(expiresFrom))
            .and(GiftCardSpecification.expiresTo(expiresTo));

        int p = page != null ? Math.max(page, 0) : 0;
        int sz = size != null && size > 0 ? size : 20;
        Pageable pageable = PageRequest.of(p, sz,
            Sort.by("createdAt").descending().and(Sort.by("id").descending()));

        return PageResponse.of(giftCardRepo.findAll(spec, pageable).map(c -> toResponse(c, false)));
    }

    @Transactional(readOnly = true)
    public GiftCardResponse adminGet(Long id) {
        return toResponse(giftCardOrThrow(id), false);
    }

    @Transactional(readOnly = true)
    public PageResponse<GiftCardTransactionResponse> adminTransactions(Long id, Integer page, Integer size) {
        GiftCard card = giftCardOrThrow(id);
        List<GiftCardTransactionResponse> all = transactionRepo
            .findByGiftCardIdOrderByCreatedAtDescIdDesc(card.getId()).stream()
            .map(this::toTransactionResponse).toList();
        return paginate(all, page, size);
    }

    // ═════════════════════════════════════════════════════════════════════
    // EFFECTIVE STATUS (read-time only, never persisted here)
    // ═════════════════════════════════════════════════════════════════════

    /**
     * CANCELLED/FULLY_REDEEMED/EXPIRED are terminal and always win. Otherwise a
     * card whose {@code expiresAt} has passed while a balance remains is
     * reported EXPIRED on read — computed only, matching the phase spec's
     * "Computed effective expiry on reads" section exactly.
     */
    GiftCardStatus effectiveStatus(GiftCard card) {
        if (card.getStatus() == GiftCardStatus.CANCELLED || card.getStatus() == GiftCardStatus.FULLY_REDEEMED
                || card.getStatus() == GiftCardStatus.EXPIRED)
            return card.getStatus();
        if (card.getExpiresAt() != null && card.getExpiresAt().isBefore(Instant.now())
                && card.getCurrentBalance().signum() > 0)
            return GiftCardStatus.EXPIRED;
        return card.getStatus();
    }

    // ═════════════════════════════════════════════════════════════════════
    // CODE GENERATION (see phase spec "GIFT CARD CODE" section)
    // ═════════════════════════════════════════════════════════════════════

    private String generateUniqueCode() {
        for (int attempt = 0; attempt < MAX_CODE_ATTEMPTS; attempt++) {
            String candidate = "PYT-GC-" + randomSegment() + "-" + randomSegment() + "-" + randomSegment();
            if (giftCardRepo.findByGiftCardCode(candidate).isEmpty()) return candidate;
        }
        // Never happens in practice (32^4 per segment keyspace) — no code is logged either way.
        throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "Failed to generate a unique gift card code");
    }

    private String randomSegment() {
        StringBuilder sb = new StringBuilder(4);
        for (int i = 0; i < 4; i++) sb.append(CODE_ALPHABET.charAt(RANDOM.nextInt(CODE_ALPHABET.length())));
        return sb.toString();
    }

    private String lastFour(String code) {
        return code.substring(code.length() - 4);
    }

    private String maskCode(String codeLast4) {
        return "PYT-GC-****-****-" + codeLast4;
    }

    static String normalizeCode(String raw) {
        return raw == null ? null : raw.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeEmail(String raw) {
        return raw == null || raw.isBlank() ? null : raw.trim().toLowerCase(Locale.ROOT);
    }

    // ═════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═════════════════════════════════════════════════════════════════════

    private void assertProductIssuable(GiftCardProduct product) {
        if (!product.isActive())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Gift card product is not active: " + product.getProductCode());
        LocalDate today = LocalDate.now();
        if (product.getValidFrom() != null && today.isBefore(product.getValidFrom()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Gift card product is not yet available: " + product.getProductCode());
        if (product.getValidUntil() != null && today.isAfter(product.getValidUntil()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Gift card product is no longer available: " + product.getProductCode());
    }

    private void validateAmountAgainstProduct(GiftCardProduct product, BigDecimal amount) {
        if (!product.isCustomAmountAllowed()) {
            if (product.getFixedAmount() != null && amount.compareTo(product.getFixedAmount()) != 0)
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Amount must equal the fixed amount (" + product.getFixedAmount().toPlainString()
                        + ") for this product");
            return;
        }
        if (product.getMinimumAmount() != null && amount.compareTo(product.getMinimumAmount()) < 0)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Amount is below the minimum allowed (" + product.getMinimumAmount().toPlainString() + ") for this product");
        if (product.getMaximumAmount() != null && amount.compareTo(product.getMaximumAmount()) > 0)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Amount exceeds the maximum allowed (" + product.getMaximumAmount().toPlainString() + ") for this product");
    }

    private GiftCardTransaction insertLedger(GiftCard card, GiftCardTransactionType type, BigDecimal amount,
                                              BigDecimal before, BigDecimal after, String description,
                                              GiftCardReferenceType referenceType, Long referenceId,
                                              String idempotencyKey) {
        GiftCardTransaction tx = new GiftCardTransaction();
        tx.setGiftCard(card);
        tx.setTransactionType(type);
        tx.setAmount(amount);
        tx.setBalanceBefore(before);
        tx.setBalanceAfter(after);
        tx.setDescription(description);
        tx.setReferenceType(referenceType);
        tx.setReferenceId(referenceId);
        tx.setIdempotencyKey(idempotencyKey);
        return transactionRepo.save(tx);
    }

    private boolean isPurchaserOrRecipient(Long userId, GiftCard card) {
        if (userId == null) return false;
        if (card.getPurchaserUser() != null && card.getPurchaserUser().getId().equals(userId)) return true;
        return card.getRecipientUser() != null && card.getRecipientUser().getId().equals(userId);
    }

    private GiftCard ownedCardOrThrow(Long userId, Long id) {
        GiftCard card = giftCardOrThrow(id);
        if (!isPurchaserOrRecipient(userId, card))
            throw new ApiException(HttpStatus.NOT_FOUND, "Gift card not found: " + id);
        return card;
    }

    private GiftCard giftCardOrThrow(Long id) {
        return giftCardRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Gift card not found: " + id));
    }

    private User userOrThrow(Long userId) {
        return userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));
    }

    private String blankToNull(String s) {
        return s != null && !s.isBlank() ? s.trim() : null;
    }

    private <T> PageResponse<T> paginate(List<T> all, Integer page, Integer size) {
        int p = page != null ? Math.max(page, 0) : 0;
        int sz = size != null && size > 0 ? size : 20;
        int fromIdx = Math.min(p * sz, all.size());
        int toIdx = Math.min(fromIdx + sz, all.size());
        return new PageResponse<>(all.subList(fromIdx, toIdx), p, sz, all.size(),
            (int) Math.ceil((double) all.size() / sz));
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private GiftCardResponse toResponse(GiftCard c, boolean includeFullCode) {
        return new GiftCardResponse(
            c.getId(), maskCode(c.getCodeLast4()), includeFullCode ? c.getGiftCardCode() : null,
            toProductSummary(c.getProduct()),
            c.getPurchaserUser() != null ? toPartySummary(c.getPurchaserUser()) : null,
            c.getRecipientUser() != null ? toPartySummary(c.getRecipientUser()) : null,
            c.getRecipientEmail(),
            c.getOriginalAmount(), c.getCurrentBalance(), c.getCurrency(),
            c.getStatus(), effectiveStatus(c), c.getPersonalMessage(),
            c.getIssuedAt(), c.getActivatedAt(), c.getExpiresAt(), c.getCancelledAt(), c.getFullyRedeemedAt(),
            c.getCreatedAt(), c.getUpdatedAt(), c.getVersion()
        );
    }

    private GiftCardSummaryResponse toSummary(GiftCard c, GiftCardStatus effective) {
        return new GiftCardSummaryResponse(
            c.getId(), maskCode(c.getCodeLast4()), c.getProduct().getName(),
            c.getOriginalAmount(), c.getCurrentBalance(), c.getCurrency(),
            c.getStatus(), effective, c.getIssuedAt(), c.getExpiresAt()
        );
    }

    private GiftCardProductSummary toProductSummary(GiftCardProduct p) {
        return new GiftCardProductSummary(p.getId(), p.getProductCode(), p.getName(), p.getCurrency());
    }

    private GiftCardPartySummary toPartySummary(User u) {
        return new GiftCardPartySummary(u.getId(), u.getFullName());
    }

    private GiftCardTransactionResponse toTransactionResponse(GiftCardTransaction t) {
        return new GiftCardTransactionResponse(
            t.getId(), t.getGiftCard().getId(), t.getTransactionType(),
            t.getAmount(), t.getBalanceBefore(), t.getBalanceAfter(),
            t.getDescription(), t.getReferenceType(), t.getReferenceId(),
            t.getIdempotencyKey(), t.getCreatedAt()
        );
    }
}
