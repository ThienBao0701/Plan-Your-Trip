package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CouponDto.CouponEligibilityRequest;
import com.example.planyourtrip.dto.CouponDto.CouponEligibilityResponse;
import com.example.planyourtrip.dto.CouponDto.CouponPreviewRequest;
import com.example.planyourtrip.dto.CouponDto.CouponPreviewResponse;
import com.example.planyourtrip.dto.CouponDto.CustomerCouponResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.CouponDefinitionRepository;
import com.example.planyourtrip.repository.CustomerCouponRepository;
import com.example.planyourtrip.repository.CustomerMembershipRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.EnumSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Customer-side coupon operations: claim by code (case-insensitive), list/get
 * own coupons (404 — never 403 — on another user's coupon, per the established
 * "avoid leaking existence" convention), effective-status computation and a
 * strictly read-only discount preview.
 *
 * <p>HTTP status choices for claim failures, following existing conventions
 * ({@code PromotionService} uses 409 for conflicts, {@code TravelWalletService}
 * uses 400 for invalid state): unknown code → 404; inactive / expired /
 * not-yet-valid definition → 400; per-user or total usage limit exhausted → 409.
 *
 * <p>The discount formula deliberately mirrors the private
 * {@code PricingEngineService#computeDiscount(Promotion, BigDecimal)} (which is
 * not cleanly reusable here — it is Promotion-typed and modifying
 * PricingEngineService beyond visibility is out of scope): PERCENTAGE →
 * amount × value / 100 at scale 2 HALF_UP, FIXED_AMOUNT → value; capped at
 * maxDiscountAmount when configured and never exceeding the order amount.
 *
 * <p><b>Phase 7.17 — Coupon Targeting &amp; Advanced Eligibility.</b> Every new
 * eligibility rule (target type, minimum stay, booking-date window, customer
 * segment, first-booking-only, promotion/credit stacking) is evaluated by ONE
 * centralized evaluator — {@link #evaluateDefinitionRules} (definition-level
 * rules) composed with {@link #evaluateEligibility} (adds the claim's own
 * AVAILABLE/USED/EXPIRED/REVOKED state check) — so {@link #claim},
 * {@link #preview}, {@link #checkEligibility} (new customer endpoint),
 * {@link CouponDefinitionService}'s admin eligibility-preview support and
 * {@link #validateForCheckout} (7.15's checkout entry point) all route through
 * the exact same logic; nothing is duplicated.
 *
 * <p>Documented judgment call on missing context: a targeting/stay/date/
 * stacking check that has nothing to evaluate against (e.g. no {@code hotelId}
 * supplied to {@link #preview}, or a coupon claimed with no booking context yet
 * at {@link #claim} time) is treated as <em>satisfied</em> rather than failed —
 * this is what keeps the pre-7.17 preview contract exactly backward compatible
 * for callers that only ever send {@code orderAmount}, and what makes
 * {@link #claim} — which has no hotel/room/dates to check against — able to
 * still enforce the two rules that never need booking context: customer
 * segment and first-booking-only (both derived purely from the user's own
 * past bookings). Full targeting/stay/date/stacking enforcement always applies
 * at {@link #preview}, {@link #checkEligibility} (when the caller supplies the
 * context) and always at {@link #validateForCheckout} (which is always called
 * with full real checkout context by {@code BookingService}).
 */
@Service
public class CustomerCouponService {

    private final CustomerCouponRepository customerCouponRepo;
    private final CouponDefinitionRepository couponDefinitionRepo;
    private final UserRepository userRepo;
    private final BookingRepository bookingRepo;
    private final PlaceRepository placeRepo;
    private final CouponDefinitionService couponDefinitionService;
    private final PricingEngineService pricingEngineService;
    private final NotificationService notificationService;
    private final CustomerMembershipRepository customerMembershipRepo;

    /** RETURNING_USER / customer-level threshold constants — see {@link #evaluateSegment}. */
    private static final Set<BookingStatus> NOT_QUALIFYING_STATUSES =
        EnumSet.of(BookingStatus.CANCELLED, BookingStatus.REFUNDED);
    private static final Set<BookingStatus> RETURNING_USER_STATUSES = EnumSet.of(
        BookingStatus.CONFIRMED, BookingStatus.CHECKED_IN, BookingStatus.CHECKED_OUT,
        BookingStatus.COMPLETED, BookingStatus.ARCHIVED);
    /** HIGH_VALUE segment threshold — documented judgment call: 5 fully COMPLETED bookings. */
    static final int HIGH_VALUE_COMPLETED_BOOKING_THRESHOLD = 5;

    public CustomerCouponService(CustomerCouponRepository customerCouponRepo,
                                  CouponDefinitionRepository couponDefinitionRepo,
                                  UserRepository userRepo,
                                  BookingRepository bookingRepo,
                                  PlaceRepository placeRepo,
                                  CouponDefinitionService couponDefinitionService,
                                  PricingEngineService pricingEngineService,
                                  NotificationService notificationService,
                                  CustomerMembershipRepository customerMembershipRepo) {
        this.customerCouponRepo = customerCouponRepo;
        this.couponDefinitionRepo = couponDefinitionRepo;
        this.userRepo = userRepo;
        this.bookingRepo = bookingRepo;
        this.placeRepo = placeRepo;
        this.couponDefinitionService = couponDefinitionService;
        this.pricingEngineService = pricingEngineService;
        this.notificationService = notificationService;
        this.customerMembershipRepo = customerMembershipRepo;
    }

    // ── Claim ────────────────────────────────────────────────────────────────

    @Transactional
    public CustomerCouponResponse claim(Long userId, String rawCode) {
        String code = CouponDefinitionService.normalizeCode(rawCode);
        CouponDefinition def = couponDefinitionRepo.findByCodeIgnoreCase(code)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Coupon code not found: " + code));

        LocalDate today = LocalDate.now();
        if (!def.isActive())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Coupon is not active: " + code);
        if (today.isBefore(def.getValidFrom()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Coupon is not valid yet: " + code);
        if (today.isAfter(def.getValidUntil()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Coupon has expired: " + code);

        long claimedByUser = customerCouponRepo.countByUserIdAndCouponDefinitionId(userId, def.getId());
        if (claimedByUser >= def.getUsageLimitPerUser())
            throw new ApiException(HttpStatus.CONFLICT,
                "Per-user claim limit reached for coupon: " + code);
        if (def.getTotalUsageLimit() != null && def.getCurrentUsageCount() >= def.getTotalUsageLimit())
            throw new ApiException(HttpStatus.CONFLICT,
                "Coupon has reached its total usage limit: " + code);

        // Phase 7.17 — the two eligibility rules that never need booking context
        // (customer segment, first-booking-only) are enforced right at claim
        // time, via the same helper the full evaluator uses.
        CustomerLevelEligibility customerLevel = evaluateCustomerLevel(def, userId);
        if (!customerLevel.segmentSatisfied())
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Coupon is not available for your customer segment (" + def.getCustomerSegment() + "): " + code);
        if (!customerLevel.firstBookingSatisfied())
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Coupon is limited to first-time bookings: " + code);

        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        CustomerCoupon coupon = new CustomerCoupon();
        coupon.setUser(user);
        coupon.setCouponDefinition(def);
        coupon.setStatus(CustomerCouponStatus.AVAILABLE);
        coupon.setClaimedAt(Instant.now());
        CustomerCoupon saved = customerCouponRepo.save(coupon);

        def.setCurrentUsageCount(def.getCurrentUsageCount() + 1);
        couponDefinitionRepo.save(def);

        notificationService.create(userId, NotificationType.PROMOTION, Priority.NORMAL,
            "Coupon added",
            "Coupon " + def.getCode() + " (" + def.getName() + ") has been added to your account.",
            RelatedEntityType.PROMOTION, def.getId());

        return toResponse(saved);
    }

    // ── Read ─────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<CustomerCouponResponse> listMine(Long userId) {
        return customerCouponRepo.findByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public CustomerCouponResponse getMine(Long userId, Long id) {
        return toResponse(ownedCouponOrThrow(userId, id));
    }

    /** Admin visibility only — strictly read-only, mirrors {@code TravelWalletService#adminList}. */
    @Transactional(readOnly = true)
    public List<CustomerCouponResponse> adminListForUser(Long targetUserId) {
        userRepo.findById(targetUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + targetUserId));
        return customerCouponRepo.findByUserIdOrderByCreatedAtDesc(targetUserId)
            .stream().map(this::toResponse).toList();
    }

    // ── Phase 7.16 — admin revocation ────────────────────────────────────────

    /**
     * Phase 7.16 — admin revokes a claimed coupon. REVOKED is terminal (it
     * always wins in {@link #effectiveStatus}), so a revoked claim is rejected
     * at checkout (409) and reported ineligible by the preview from the moment
     * this commits.
     *
     * <p>Documented judgment calls:
     * <ul>
     *   <li>only a stored-AVAILABLE claim can be revoked — a USED coupon is
     *       history attached to a booking (409), an already-REVOKED one is a
     *       repeat (409). A stored-AVAILABLE claim whose effective expiry has
     *       passed may still be revoked (harmless bookkeeping);</li>
     *   <li>{@code CouponDefinition#currentUsageCount} counts LIVE claims
     *       against {@code totalUsageLimit}, so revocation decrements it
     *       (floored at 0) and frees the slot for other customers. The per-user
     *       claim count deliberately still includes the revoked row — revocation
     *       is punitive/corrective, and the target user must not be able to
     *       simply re-claim the code;</li>
     *   <li>lookup is ownership-scoped under the path's userId: a coupon id
     *       that exists but belongs to a different user is a 404, never a 403,
     *       per the established convention.</li>
     * </ul>
     */
    @Transactional
    public CustomerCouponResponse adminRevoke(Long targetUserId, Long couponId) {
        userRepo.findById(targetUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + targetUserId));
        CustomerCoupon coupon = customerCouponRepo.findByIdAndUserId(couponId, targetUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Coupon not found: " + couponId));

        if (coupon.getStatus() == CustomerCouponStatus.USED)
            throw new ApiException(HttpStatus.CONFLICT,
                "Cannot revoke a coupon that has already been used");
        if (coupon.getStatus() == CustomerCouponStatus.REVOKED)
            throw new ApiException(HttpStatus.CONFLICT, "Coupon is already revoked");

        coupon.setStatus(CustomerCouponStatus.REVOKED);
        CustomerCoupon saved = customerCouponRepo.save(coupon);

        CouponDefinition def = coupon.getCouponDefinition();
        if (def.getCurrentUsageCount() > 0) {
            def.setCurrentUsageCount(def.getCurrentUsageCount() - 1);
            couponDefinitionRepo.save(def);
        }

        notificationService.create(targetUserId, NotificationType.PROMOTION, Priority.NORMAL,
            "Coupon revoked",
            "Coupon " + def.getCode() + " (" + def.getName()
                + ") has been revoked and can no longer be used.",
            RelatedEntityType.PROMOTION, def.getId());

        return toResponse(saved);
    }

    // ── Preview (strictly read-only — never marks the coupon used) ──────────

    @Transactional(readOnly = true)
    public CouponPreviewResponse preview(Long userId, Long couponId, CouponPreviewRequest req) {
        CustomerCoupon coupon = ownedCouponOrThrow(userId, couponId);
        BigDecimal orderAmount = req.orderAmount();

        boolean promotionApplied = req.promotionDiscountApplied() != null
            ? req.promotionDiscountApplied()
            : resolvePromotionApplied(req.roomId(), req.checkIn(), req.checkOut());
        EligibilityContext ctx = new EligibilityContext(req.hotelId(), req.roomId(),
            req.checkIn(), req.checkOut(), orderAmount, req.travelCreditAmount(), promotionApplied);

        EligibilityResult result = evaluateEligibility(userId, coupon, ctx);
        if (!result.eligible())
            return ineligible(orderAmount, result.reason());

        return new CouponPreviewResponse(orderAmount, result.previewDiscount(),
            orderAmount.subtract(result.previewDiscount()), true, null);
    }

    // ── Phase 7.17 — full eligibility breakdown (strictly read-only) ────────

    /** Customer-facing — {@code POST /api/me/coupons/{id}/eligibility}, ownership-scoped like every other {@code /me} coupon endpoint. */
    @Transactional(readOnly = true)
    public CouponEligibilityResponse checkEligibility(Long userId, Long couponId, CouponEligibilityRequest req) {
        CustomerCoupon coupon = ownedCouponOrThrow(userId, couponId);
        boolean promotionApplied = resolvePromotionApplied(req.roomId(), req.checkIn(), req.checkOut());
        EligibilityContext ctx = new EligibilityContext(req.hotelId(), req.roomId(),
            req.checkIn(), req.checkOut(), req.orderAmount(), req.travelCreditAmount(), promotionApplied);

        EligibilityResult result = evaluateEligibility(userId, coupon, ctx);
        return toEligibilityResponse(result);
    }

    /**
     * Admin support/testing tool — {@code GET /api/admin/coupon-definitions/{id}/eligibility-preview}.
     * Operates directly on the {@link CouponDefinition} rather than a specific
     * claim (an admin may want to test eligibility before anyone has claimed
     * the coupon), so it skips the claim-state gate (AVAILABLE/USED/EXPIRED/
     * REVOKED — there is no specific claim) but runs the exact same
     * definition-level rules via {@link #evaluateDefinitionRules}.
     * {@code targetUserId} is optional: when absent, customer-segment and
     * first-booking-only checks are skipped (treated as satisfied) since there
     * is no specific user to evaluate them against.
     */
    @Transactional(readOnly = true)
    public CouponEligibilityResponse adminEligibilityPreview(Long definitionId, Long targetUserId,
                                                               Long hotelId, Long roomId,
                                                               LocalDate checkIn, LocalDate checkOut,
                                                               BigDecimal orderAmount,
                                                               BigDecimal travelCreditAmount) {
        CouponDefinition def = couponDefinitionService.definitionOrThrow(definitionId);
        boolean promotionApplied = resolvePromotionApplied(roomId, checkIn, checkOut);
        EligibilityContext ctx = new EligibilityContext(hotelId, roomId, checkIn, checkOut,
            orderAmount, travelCreditAmount, promotionApplied);

        EligibilityResult result = evaluateDefinitionRules(def, targetUserId, ctx);
        return toEligibilityResponse(result);
    }

    private CouponEligibilityResponse toEligibilityResponse(EligibilityResult r) {
        return new CouponEligibilityResponse(r.eligible(), r.reason(), r.matchedTargetType(),
            r.minimumStaySatisfied(), r.dateWindowSatisfied(), r.customerSegmentSatisfied(),
            r.promotionStackingAllowed(), r.creditStackingAllowed(), r.previewDiscount());
    }

    // ── Phase 7.15 — checkout integration (called by BookingService) ─────────

    /** A validated coupon + its computed discount, ready to be consumed by a booking. */
    public record CheckoutCouponResult(CustomerCoupon coupon, BigDecimal discountAmount) {}

    /**
     * Phase 7.17 — the full checkout-time targeting/eligibility context:
     * {@code hotelId}/{@code roomId} identify what's being booked,
     * {@code checkIn}/{@code checkOut} drive minimum-stay and booking-date-window
     * eligibility, {@code orderAmount} is the promotion-discounted total the
     * coupon discount is computed against, {@code travelCreditAmount} is the
     * raw requested credit amount (for the credit-stacking check — may exceed
     * what {@code TravelCreditService} would actually allow; that's validated
     * separately) and {@code promotionDiscountApplied} is whether the pricing
     * engine already applied a promotion discount to this order (for the
     * promotion-stacking check).
     */
    public record EligibilityContext(Long hotelId, Long roomId, LocalDate checkIn, LocalDate checkOut,
                                      BigDecimal orderAmount, BigDecimal travelCreditAmount,
                                      boolean promotionDiscountApplied) {}

    /**
     * Phase 7.17 — the structured result of {@link #evaluateEligibility} /
     * {@link #evaluateDefinitionRules}: an overall verdict plus one flag per
     * rule category, mirroring {@code CouponEligibilityResponse} exactly (the
     * DTO is built from this 1:1). {@code matchedTargetType} always reports the
     * coupon definition's configured {@link CouponTargetType} (informational),
     * regardless of whether it matched. When an earlier gate short-circuits
     * evaluation (claim not AVAILABLE / definition inactive / not yet valid /
     * target mismatch), the individual rule flags default to {@code true} —
     * "not the thing that failed" — since they were never actually evaluated.
     */
    public record EligibilityResult(boolean eligible, String reason, CouponTargetType matchedTargetType,
                                     boolean minimumStaySatisfied, boolean dateWindowSatisfied,
                                     boolean customerSegmentSatisfied, boolean promotionStackingAllowed,
                                     boolean creditStackingAllowed, BigDecimal previewDiscount) {}

    /**
     * Phase 7.15 — validates a claimed coupon for checkout and computes its
     * discount against {@code ctx.orderAmount()} (the booking total AFTER any
     * promotion discount) using the exact same centralized eligibility
     * evaluator as {@link #preview}/{@link #checkEligibility}. Read-only: never
     * marks the coupon used — that happens in {@link #markUsedForBooking} after
     * the booking row exists, all inside the booking-creation transaction.
     *
     * <p>Status choices (documented judgment calls, consistent with 7.14/7.17):
     * no claim of this code owned by the caller → 404 (covers unknown codes and
     * other users' claims without leaking existence); claimed but no AVAILABLE
     * instance (USED / EXPIRED / REVOKED) → 409 state conflict; any
     * definition-level rule failure (inactive / not yet valid / minimumSpend /
     * target mismatch / minimum stay / booking-date window / customer segment /
     * first-booking-only / promotion or credit stacking conflict) → 400.
     */
    @Transactional
    public CheckoutCouponResult validateForCheckout(Long userId, String rawCode, EligibilityContext ctx) {
        String code = CouponDefinitionService.normalizeCode(rawCode);
        List<CustomerCoupon> claims =
            customerCouponRepo.findByUserIdAndCouponDefinitionCodeOrderByClaimedAtAsc(userId, code);
        if (claims.isEmpty())
            throw new ApiException(HttpStatus.NOT_FOUND, "Coupon not found: " + code);

        CustomerCoupon coupon = claims.stream()
            .filter(c -> effectiveStatus(c) == CustomerCouponStatus.AVAILABLE)
            .findFirst()
            .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT,
                "Coupon is not available (already used, expired or revoked): " + code));

        EligibilityResult result = evaluateDefinitionRules(coupon.getCouponDefinition(), userId, ctx);
        if (!result.eligible())
            throw new ApiException(HttpStatus.BAD_REQUEST, result.reason() + ": " + code);

        return new CheckoutCouponResult(coupon, result.previewDiscount());
    }

    /**
     * Phase 7.15 — atomically consumes a validated coupon: USED + usedAt +
     * booking link, in the same transaction as the booking insert, so a failed
     * booking never burns the coupon.
     */
    @Transactional
    public void markUsedForBooking(CustomerCoupon coupon, Booking booking) {
        coupon.setStatus(CustomerCouponStatus.USED);
        coupon.setUsedAt(Instant.now());
        coupon.setBooking(booking);
        customerCouponRepo.save(coupon);
    }

    /**
     * Phase 7.15 — cancellation hook. Releases the booking's coupon back to
     * AVAILABLE (clearing usedAt + booking) IF it is still redeemable — i.e. its
     * effective expiry has not passed and the definition is still active;
     * otherwise it stays USED (documented judgment call: a coupon that could no
     * longer be used anyway is not resurrected). Safe to call for bookings that
     * never used a coupon (no-op), and naturally idempotent — once released the
     * coupon no longer references the booking.
     */
    @Transactional
    public void releaseForCancelledBooking(Long bookingId) {
        customerCouponRepo.findByBookingId(bookingId).ifPresent(coupon -> {
            if (coupon.getStatus() != CustomerCouponStatus.USED) return;
            LocalDate expiry = effectiveExpiry(coupon);
            boolean stillRedeemable = coupon.getCouponDefinition().isActive()
                && (expiry == null || !expiry.isBefore(LocalDate.now()));
            if (!stillRedeemable) return;
            coupon.setStatus(CustomerCouponStatus.AVAILABLE);
            coupon.setUsedAt(null);
            coupon.setBooking(null);
            customerCouponRepo.save(coupon);
        });
    }

    // ── Phase 7.17 — centralized eligibility evaluator ───────────────────────

    /**
     * Adds the claim's own state check (AVAILABLE/USED/EXPIRED/REVOKED) on top
     * of {@link #evaluateDefinitionRules} — used whenever a specific claimed
     * {@link CustomerCoupon} is in hand ({@link #preview}, {@link #checkEligibility},
     * {@link #validateForCheckout}).
     */
    private EligibilityResult evaluateEligibility(Long userId, CustomerCoupon coupon, EligibilityContext ctx) {
        CouponDefinition def = coupon.getCouponDefinition();
        CustomerCouponStatus effective = effectiveStatus(coupon);
        if (effective != CustomerCouponStatus.AVAILABLE)
            return ineligibleResult(def.getTargetType(), "Coupon is not available (status: " + effective + ")");
        return evaluateDefinitionRules(def, userId, ctx);
    }

    /**
     * The single source of truth for every Phase 7.17 rule: active/validFrom,
     * target-type resolution, minimum-stay, booking-date window, customer
     * segment, first-booking-only, promotion/credit stacking and minimum
     * spend. {@code userId} may be {@code null} (admin eligibility-preview with
     * no target user) — customer-segment/first-booking-only checks are then
     * skipped (treated as satisfied). Reused directly by
     * {@link CouponDefinitionService} callers via
     * {@link #adminEligibilityPreview} and by every claim-scoped entry point
     * via {@link #evaluateEligibility}.
     */
    private EligibilityResult evaluateDefinitionRules(CouponDefinition def, Long userId, EligibilityContext ctx) {
        CouponTargetType matchedType = def.getTargetType();

        if (!def.isActive())
            return ineligibleResult(matchedType, "Coupon is no longer active");
        if (LocalDate.now().isBefore(def.getValidFrom()))
            return ineligibleResult(matchedType, "Coupon is not valid yet");

        boolean targetOk = targetMatches(def, ctx);
        if (!targetOk)
            return ineligibleResult(matchedType,
                "Coupon does not apply to the selected " + matchedType.name().toLowerCase(Locale.ROOT));

        boolean minStayOk = minimumStaySatisfied(def, ctx);
        boolean dateWindowOk = dateWindowSatisfied(def, ctx);
        CustomerLevelEligibility customerLevel = evaluateCustomerLevel(def, userId);
        boolean promoStackOk = def.isCombinableWithPromotions() || !ctx.promotionDiscountApplied();
        boolean creditStackOk = def.isCombinableWithTravelCredits()
            || ctx.travelCreditAmount() == null || ctx.travelCreditAmount().signum() <= 0;
        boolean minSpendOk = def.getMinimumSpend() == null || ctx.orderAmount() == null
            || ctx.orderAmount().compareTo(def.getMinimumSpend()) >= 0;

        String reason = null;
        if (!minStayOk)
            reason = "Minimum stay of " + def.getMinimumStayNights() + " night(s) not met";
        else if (!dateWindowOk)
            reason = "Booking dates fall outside the coupon's valid booking window";
        else if (!customerLevel.segmentSatisfied())
            reason = "Coupon is not available for your customer segment (" + def.getCustomerSegment() + ")";
        else if (!customerLevel.firstBookingSatisfied())
            reason = "Coupon is limited to your first booking";
        else if (!promoStackOk)
            reason = "Coupon cannot be combined with an already-applied promotion discount";
        else if (!creditStackOk)
            reason = "Coupon cannot be combined with travel credits";
        else if (!minSpendOk)
            reason = "Minimum spend of " + def.getMinimumSpend().toPlainString() + " not met";

        boolean eligible = reason == null;
        BigDecimal discount = eligible && ctx.orderAmount() != null
            ? computeDiscount(def, ctx.orderAmount()) : BigDecimal.ZERO;

        return new EligibilityResult(eligible, reason, matchedType, minStayOk, dateWindowOk,
            customerLevel.segmentSatisfied(), promoStackOk, creditStackOk, discount);
    }

    private EligibilityResult ineligibleResult(CouponTargetType matchedType, String reason) {
        return new EligibilityResult(false, reason, matchedType, true, true, true, true, true, BigDecimal.ZERO);
    }

    /**
     * Target resolution — deliberately not shared code with
     * {@code PricingEngineService#isApplicable} (Promotion-typed, HOTEL there
     * resolves against a {@code HotelDetail} id; see class javadoc for why
     * CouponDefinition's HOTEL resolves against a {@code Place} id instead).
     * A missing context value (no {@code hotelId}/{@code roomId} supplied) is
     * treated as "cannot evaluate, not violated" — see class javadoc.
     */
    private boolean targetMatches(CouponDefinition def, EligibilityContext ctx) {
        return switch (def.getTargetType()) {
            case ALL -> true;
            case HOTEL -> ctx.hotelId() == null || def.getTargetId().equals(ctx.hotelId());
            case ROOM -> ctx.roomId() == null || def.getTargetId().equals(ctx.roomId());
            case PLACE_TYPE -> {
                if (ctx.hotelId() == null) yield true;
                Place place = placeRepo.findById(ctx.hotelId()).orElse(null);
                String actualType = (place != null && place.getCategory() != null)
                    ? place.getCategory().getType() : null;
                yield actualType != null && actualType.equalsIgnoreCase(def.getPlaceType());
            }
        };
    }

    /**
     * Coverage semantics: {@code nights >= minimumStayNights}, nights computed
     * from {@code ctx.checkIn()}/{@code ctx.checkOut()}. Skipped (satisfied)
     * when either the coupon has no minimum stay configured or the context
     * carries no dates to check against.
     */
    private boolean minimumStaySatisfied(CouponDefinition def, EligibilityContext ctx) {
        if (def.getMinimumStayNights() == null) return true;
        if (ctx.checkIn() == null || ctx.checkOut() == null) return true;
        long nights = ChronoUnit.DAYS.between(ctx.checkIn(), ctx.checkOut());
        return nights >= def.getMinimumStayNights();
    }

    /**
     * Coverage semantics (documented judgment call — one clear rule applied
     * consistently everywhere): the BOOKING's check-in date must fall within
     * {@code [bookingDateFrom, bookingDateTo]}, each bound checked
     * independently when present. Checkout date is deliberately not part of
     * the window — a stay that starts inside the promotional window qualifies
     * even if it runs past the end date, mirroring how {@code Promotion}'s own
     * {@code startDate}/{@code endDate} are checked against the stay in
     * {@code PromotionRepository#findActiveForDateRange} (campaign window
     * gates the stay by its start). Skipped (satisfied) when the coupon has no
     * window configured or the context carries no check-in date.
     */
    private boolean dateWindowSatisfied(CouponDefinition def, EligibilityContext ctx) {
        if (def.getBookingDateFrom() == null && def.getBookingDateTo() == null) return true;
        if (ctx.checkIn() == null) return true;
        if (def.getBookingDateFrom() != null && ctx.checkIn().isBefore(def.getBookingDateFrom())) return false;
        if (def.getBookingDateTo() != null && ctx.checkIn().isAfter(def.getBookingDateTo())) return false;
        return true;
    }

    /** Result of the two eligibility rules that never need booking context — see class javadoc. */
    private record CustomerLevelEligibility(boolean segmentSatisfied, boolean firstBookingSatisfied) {}

    private CustomerLevelEligibility evaluateCustomerLevel(CouponDefinition def, Long userId) {
        if (userId == null) return new CustomerLevelEligibility(true, true);
        boolean segmentOk = evaluateSegment(def.getCustomerSegment(), userId);
        boolean firstOk = !def.isFirstBookingOnly() || !hasQualifyingBooking(userId);
        return new CustomerLevelEligibility(segmentOk, firstOk);
    }

    /**
     * Customer segments — evaluated against the requesting user's OWN booking
     * history only (no raw SQL — reuses the derived-query patterns already on
     * {@link BookingRepository}):
     * <ul>
     *   <li>{@code ALL_USERS} — always true;</li>
     *   <li>{@code NEW_USER} — true when the user has no prior "qualifying"
     *       booking (see {@link #NOT_QUALIFYING_STATUSES}: CANCELLED and
     *       REFUNDED both excluded — a refunded booking means the money came
     *       back and the stay was effectively voided, so it does not count as
     *       "having booked before" any more than an outright cancellation
     *       does);</li>
     *   <li>{@code RETURNING_USER} — true when the user has at least one
     *       booking that reached CONFIRMED or later
     *       (see {@link #RETURNING_USER_STATUSES}: CONFIRMED, CHECKED_IN,
     *       CHECKED_OUT, COMPLETED, ARCHIVED — i.e. a real, honored booking,
     *       not merely a still-pending one);</li>
     *   <li>{@code MEMBER} — Phase 7.19 "Membership Tier &amp; Loyalty
     *       Qualification" refinement: true when the user has an ACTIVE,
     *       NON-EXPIRED {@code CustomerMembership} row (BRONZE and above all
     *       count — the tier value itself doesn't gate MEMBER, only having a
     *       currently-valid membership does). Superseded from the Phase 7.18
     *       version, which only required bare {@code LoyaltyAccount}
     *       existence — a {@code LoyaltyAccount} with no {@code CustomerMembership}
     *       enrollment no longer satisfies MEMBER. This check is strictly
     *       read-only — it never creates (or enrolls) a membership during
     *       eligibility evaluation, mirroring the "do not create membership
     *       during eligibility" convention already established for the other
     *       checks in this method;</li>
     *   <li>{@code HIGH_VALUE} — true when the user has at least
     *       {@link #HIGH_VALUE_COMPLETED_BOOKING_THRESHOLD} (5) COMPLETED
     *       bookings;</li>
     *   <li>{@code MANUAL} — always true. Every caller of this evaluator
     *       already operates on a claim the user owns (or, for the admin
     *       preview tool, no specific user at all) — "you already hold a
     *       claim" is enforced elsewhere (ownership-scoped lookup), so this
     *       segment is effectively a no-op beyond that existing gate.</li>
     * </ul>
     */
    private boolean evaluateSegment(CustomerSegment segment, Long userId) {
        return switch (segment) {
            case ALL_USERS, MANUAL -> true;
            case NEW_USER -> !hasQualifyingBooking(userId);
            case RETURNING_USER -> bookingRepo.existsByUserIdAndStatusIn(userId, RETURNING_USER_STATUSES);
            case MEMBER -> customerMembershipRepo.findByUserIdAndActiveTrue(userId)
                .map(m -> m.getValidUntil() == null || !Instant.now().isAfter(m.getValidUntil()))
                .orElse(false);
            case HIGH_VALUE -> bookingRepo.countByUserIdAndStatus(userId, BookingStatus.COMPLETED)
                >= HIGH_VALUE_COMPLETED_BOOKING_THRESHOLD;
        };
    }

    /** "Qualifying" = any booking not CANCELLED and not REFUNDED — shared definition for NEW_USER and firstBookingOnly. */
    private boolean hasQualifyingBooking(Long userId) {
        return bookingRepo.existsByUserIdAndStatusNotIn(userId, NOT_QUALIFYING_STATUSES);
    }

    /**
     * Best-effort promotion-applied detection for the two standalone
     * eligibility endpoints (customer {@link #checkEligibility} and
     * {@link #adminEligibilityPreview}) — a support/testing tool, not the real
     * checkout path, so it never fails the request: any pricing-engine
     * validation error (invalid dates, room not found, etc.) is swallowed and
     * treated as "no promotion detected". At real checkout,
     * {@code BookingService} passes the actual computed flag directly instead
     * of going through this method.
     */
    private boolean resolvePromotionApplied(Long roomId, LocalDate checkIn, LocalDate checkOut) {
        if (roomId == null || checkIn == null || checkOut == null) return false;
        if (!checkOut.isAfter(checkIn) || checkIn.isBefore(LocalDate.now())) return false;
        try {
            var pricing = pricingEngineService.calculate(roomId, checkIn, checkOut);
            return pricing.promotionDiscount() != null && pricing.promotionDiscount().signum() > 0;
        } catch (ApiException e) {
            return false;
        }
    }

    /**
     * Mirrors {@code PricingEngineService#computeDiscount} — see class javadoc
     * for why the formula is duplicated rather than reused.
     */
    private BigDecimal computeDiscount(CouponDefinition def, BigDecimal orderAmount) {
        BigDecimal discount;
        if (def.getDiscountType() == DiscountType.PERCENTAGE) {
            discount = orderAmount.multiply(def.getDiscountValue())
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
        } else {
            discount = def.getDiscountValue();
        }
        if (def.getMaxDiscountAmount() != null) discount = discount.min(def.getMaxDiscountAmount());
        return discount.min(orderAmount); // discount never exceeds the order amount
    }

    private CouponPreviewResponse ineligible(BigDecimal orderAmount, String reason) {
        return new CouponPreviewResponse(orderAmount, BigDecimal.ZERO, orderAmount, false, reason);
    }

    // ── Effective status (read-time only, never persisted) ──────────────────

    /**
     * USED/REVOKED are terminal and always win; otherwise the coupon is EXPIRED
     * when the effective expiry (earlier of definition.validUntil and the
     * claim's own expiresAt) has passed — computed on read, no destructive
     * update, same pattern as {@code TravelWalletService#effectiveStatus}.
     */
    CustomerCouponStatus effectiveStatus(CustomerCoupon coupon) {
        if (coupon.getStatus() == CustomerCouponStatus.USED
                || coupon.getStatus() == CustomerCouponStatus.REVOKED)
            return coupon.getStatus();
        LocalDate expiry = effectiveExpiry(coupon);
        if (expiry != null && expiry.isBefore(LocalDate.now())) return CustomerCouponStatus.EXPIRED;
        return coupon.getStatus();
    }

    LocalDate effectiveExpiry(CustomerCoupon coupon) {
        LocalDate defUntil = coupon.getCouponDefinition().getValidUntil();
        LocalDate own = coupon.getExpiresAt();
        if (own == null) return defUntil;
        if (defUntil == null) return own;
        return own.isBefore(defUntil) ? own : defUntil;
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private CustomerCoupon ownedCouponOrThrow(Long userId, Long id) {
        return customerCouponRepo.findByIdAndUserId(id, userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Coupon not found: " + id));
    }

    private CustomerCouponResponse toResponse(CustomerCoupon c) {
        return new CustomerCouponResponse(
            c.getId(), c.getUser().getId(),
            couponDefinitionService.toResponse(c.getCouponDefinition()),
            c.getStatus().name(), effectiveStatus(c).name(),
            c.getClaimedAt(), c.getUsedAt(), c.getExpiresAt(), effectiveExpiry(c),
            c.getBooking() != null ? c.getBooking().getId() : null,
            c.getCreatedAt(), c.getUpdatedAt()
        );
    }
}
