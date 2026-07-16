package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CouponDto.CouponPreviewRequest;
import com.example.planyourtrip.dto.CouponDto.CouponPreviewResponse;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteRequest;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteResponse;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.TravelCreditPreview;
import com.example.planyourtrip.dto.GiftCardDto.GiftCardPreviewRequest;
import com.example.planyourtrip.dto.GiftCardDto.GiftCardPreviewResponse;
import com.example.planyourtrip.dto.LoyaltyRedemptionDto.RedemptionPreviewRequest;
import com.example.planyourtrip.dto.LoyaltyRedemptionDto.RedemptionPreviewResponse;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteRequest;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

/**
 * Phase 7.33 — orchestrates the AUTHENTICATED customer pricing quote: a pure
 * READ-ONLY preview of the full price a specific customer would pay, including
 * their coupon / loyalty / travel-credit / gift-card benefits, WITHOUT creating a
 * booking, holding inventory, or consuming/reserving any benefit.
 *
 * <p>It composes existing read-only building blocks and adds NO pricing or
 * discount math of its own (one documented exception below):
 * <ul>
 *   <li>rate plan → promotion → {@code totalBeforeCustomerBenefits} →
 *       {@link RoomPricingQuoteService#quote} (the Phase 7.32 base quote, reused
 *       verbatim as the base this layers benefits onto);</li>
 *   <li>coupon discount → {@link CustomerCouponService#preview} (ownership-scoped;
 *       a coupon id that is not the caller's 404s);</li>
 *   <li>loyalty discount → {@link LoyaltyRedemptionService#preview} (ad-hoc
 *       {@code eligibleAmount}, no booking — side-effect-free);</li>
 *   <li>gift-card redemption → {@link GiftCardService#preview} (the Phase 7.24
 *       general, pre-booking preview by code + amount + currency);</li>
 *   <li>travel-credit redemption → the ONLY stage computed here, because no
 *       travel-credit preview exists to reuse: it reads the balance via the
 *       strictly read-only {@link TravelCreditService#previewAvailableBalance}
 *       (which never creates an account) and applies the trivial
 *       {@code min(requested, balance, remainingPayable)} — nothing is duplicated
 *       (there is nothing to duplicate).</li>
 * </ul>
 *
 * <p>The stacking order — coupon → loyalty → travel credit → gift card, applied
 * to the promotion-discounted total — is exactly the order
 * {@code BookingService.create} uses for real checkout (documented at
 * {@code BookingService.java:144} and enforced by the pipeline at
 * {@code BookingService.java:160-178}, {@code :180-191} credit,
 * {@code :255-263} gift card), so the estimate matches the eventual checkout by
 * construction.
 */
@Service
@Transactional(readOnly = true)
public class CustomerPricingQuoteService {

    private static final String ESTIMATE_DISCLAIMER =
        "Customer benefit amounts (coupon, loyalty, travel credit, gift card) are an ESTIMATE only; "
        + "they hold no balance and are finalised at checkout.";

    private final RoomPricingQuoteService roomPricingQuoteService;
    private final CustomerCouponService customerCouponService;
    private final LoyaltyRedemptionService loyaltyRedemptionService;
    private final TravelCreditService travelCreditService;
    private final GiftCardService giftCardService;

    public CustomerPricingQuoteService(RoomPricingQuoteService roomPricingQuoteService,
                                       CustomerCouponService customerCouponService,
                                       LoyaltyRedemptionService loyaltyRedemptionService,
                                       TravelCreditService travelCreditService,
                                       GiftCardService giftCardService) {
        this.roomPricingQuoteService = roomPricingQuoteService;
        this.customerCouponService = customerCouponService;
        this.loyaltyRedemptionService = loyaltyRedemptionService;
        this.travelCreditService = travelCreditService;
        this.giftCardService = giftCardService;
    }

    public CustomerPricingQuoteResponse quote(Long userId, Long roomId, CustomerPricingQuoteRequest req) {
        // ── 1. Base quote (rate plan → promotion → pre-benefit total) ─────────
        // Reuses the EXACT Phase 7.32 public quote logic; never reimplemented.
        RoomPricingQuoteResponse base = roomPricingQuoteService.quote(roomId, new RoomPricingQuoteRequest(
            req.checkIn(), req.checkOut(), req.adults(), req.children(), req.extraBeds(), req.ratePlanId()));

        List<String> warnings = new ArrayList<>();
        if (base.warnings() != null) warnings.addAll(base.warnings());
        warnings.add(ESTIMATE_DISCLAIMER);
        List<String> failures = new ArrayList<>();

        // No eligible rate plan → no price to layer benefits onto: return the base
        // quote as-is with empty benefit stages (still HTTP 200).
        if (base.totalBeforeCustomerBenefits() == null) {
            if (base.eligibilityReason() != null) failures.add(base.eligibilityReason());
            return new CustomerPricingQuoteResponse(base, null, null, null, null,
                null, null, null, null, null, null, null, null, null,
                base.currency(), warnings, failures);
        }

        String currency = base.currency();
        boolean promotionApplied = base.promotionDiscount() != null && base.promotionDiscount().signum() > 0;
        BigDecimal afterPromotion = scale(base.totalBeforeCustomerBenefits());

        // ── 2. Coupon preview (against the promotion-discounted total) ─────────
        CouponPreviewResponse couponPreview = null;
        BigDecimal couponDiscount = BigDecimal.ZERO;
        BigDecimal afterCoupon = afterPromotion;
        if (req.couponId() != null && afterPromotion.signum() > 0) {
            // Ownership is enforced by preview itself — a coupon id that is not the
            // caller's throws 404 here (existence never leaks), which propagates.
            couponPreview = customerCouponService.preview(userId, req.couponId(), new CouponPreviewRequest(
                afterPromotion, base.placeId(), roomId, req.checkIn(), req.checkOut(),
                req.travelCreditAmountRequested(), promotionApplied));
            if (couponPreview.eligible()) {
                couponDiscount = scale(nz(couponPreview.discountAmount()));
                afterCoupon = subFloor(afterPromotion, couponDiscount);
            } else {
                failures.add("Coupon not applied: " + couponPreview.reason());
            }
        }

        // ── 3. Loyalty preview (against the after-coupon amount) ───────────────
        RedemptionPreviewResponse loyaltyPreview = null;
        BigDecimal loyaltyDiscount = BigDecimal.ZERO;
        BigDecimal afterLoyalty = afterCoupon;
        if (req.requestedPoints() != null && req.requestedPoints() > 0 && afterCoupon.signum() > 0) {
            // Ad-hoc eligibleAmount (no booking exists yet) — strictly read-only,
            // writes no ledger row.
            loyaltyPreview = loyaltyRedemptionService.preview(userId,
                new RedemptionPreviewRequest(null, afterCoupon, req.requestedPoints()));
            loyaltyDiscount = scale(nz(loyaltyPreview.discountAmount()));
            afterLoyalty = subFloor(afterCoupon, loyaltyDiscount);
            if (!loyaltyPreview.redeemable()) {
                String detail = loyaltyPreview.messages() != null && !loyaltyPreview.messages().isEmpty()
                    ? String.join("; ", loyaltyPreview.messages())
                    : "requested points cannot be redeemed";
                failures.add("Loyalty points not applied: " + detail);
            }
        }

        // ── 4. Travel-credit preview (the only stage computed here) ────────────
        TravelCreditPreview travelCreditPreview = null;
        BigDecimal travelCreditApplied = BigDecimal.ZERO;
        BigDecimal afterTravelCredit = afterLoyalty;
        if (req.travelCreditAmountRequested() != null && req.travelCreditAmountRequested().signum() > 0
                && afterLoyalty.signum() > 0) {
            BigDecimal requested = scale(req.travelCreditAmountRequested());
            BigDecimal balance = scale(travelCreditService.previewAvailableBalance(userId)); // read-only, no account creation
            travelCreditApplied = requested.min(balance).min(afterLoyalty).max(BigDecimal.ZERO)
                .setScale(2, RoundingMode.HALF_UP);
            afterTravelCredit = subFloor(afterLoyalty, travelCreditApplied);
            boolean eligible = travelCreditApplied.signum() > 0;
            String reason = null;
            if (requested.compareTo(balance) > 0)
                reason = "Requested travel credit " + requested.toPlainString()
                    + " exceeds available balance " + balance.toPlainString()
                    + "; applied " + travelCreditApplied.toPlainString();
            else if (!eligible)
                reason = "No travel credit could be applied";
            if (reason != null) failures.add("Travel credit: " + reason);
            travelCreditPreview = new TravelCreditPreview(
                eligible, reason, balance, travelCreditApplied, afterTravelCredit, currency);
        }

        // ── 5. Gift-card preview (against the remaining payable) ───────────────
        GiftCardPreviewResponse giftCardPreview = null;
        BigDecimal giftCardApplied = BigDecimal.ZERO;
        BigDecimal estimatedPayable = afterTravelCredit;
        if (req.giftCardCode() != null && !req.giftCardCode().isBlank() && afterTravelCredit.signum() > 0) {
            giftCardPreview = giftCardService.preview(new GiftCardPreviewRequest(
                req.giftCardCode(), afterTravelCredit, currency));
            if (giftCardPreview.eligible()) {
                giftCardApplied = scale(nz(giftCardPreview.redeemableAmount()));
                estimatedPayable = subFloor(afterTravelCredit, giftCardApplied);
            } else {
                failures.add("Gift card not applied: " + giftCardPreview.reason());
            }
        }

        return new CustomerPricingQuoteResponse(
            base, couponPreview, loyaltyPreview, travelCreditPreview, giftCardPreview,
            afterPromotion, couponDiscount, afterCoupon, loyaltyDiscount, afterLoyalty,
            travelCreditApplied, afterTravelCredit, giftCardApplied, estimatedPayable,
            currency, warnings, failures);
    }

    private static BigDecimal scale(BigDecimal v) {
        return v.setScale(2, RoundingMode.HALF_UP);
    }

    /** a − b, floored at zero, scale 2. */
    private static BigDecimal subFloor(BigDecimal a, BigDecimal b) {
        return a.subtract(b).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal nz(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }
}
