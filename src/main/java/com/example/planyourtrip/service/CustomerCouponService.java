package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CouponDto.CouponPreviewRequest;
import com.example.planyourtrip.dto.CouponDto.CouponPreviewResponse;
import com.example.planyourtrip.dto.CouponDto.CustomerCouponResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.CouponDefinitionRepository;
import com.example.planyourtrip.repository.CustomerCouponRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

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
 * Nothing in this phase applies a coupon to a Booking.
 */
@Service
public class CustomerCouponService {

    private final CustomerCouponRepository customerCouponRepo;
    private final CouponDefinitionRepository couponDefinitionRepo;
    private final UserRepository userRepo;
    private final CouponDefinitionService couponDefinitionService;
    private final NotificationService notificationService;

    public CustomerCouponService(CustomerCouponRepository customerCouponRepo,
                                  CouponDefinitionRepository couponDefinitionRepo,
                                  UserRepository userRepo,
                                  CouponDefinitionService couponDefinitionService,
                                  NotificationService notificationService) {
        this.customerCouponRepo = customerCouponRepo;
        this.couponDefinitionRepo = couponDefinitionRepo;
        this.userRepo = userRepo;
        this.couponDefinitionService = couponDefinitionService;
        this.notificationService = notificationService;
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

    // ── Preview (strictly read-only — never marks the coupon used) ──────────

    @Transactional(readOnly = true)
    public CouponPreviewResponse preview(Long userId, Long couponId, CouponPreviewRequest req) {
        CustomerCoupon coupon = ownedCouponOrThrow(userId, couponId);
        CouponDefinition def = coupon.getCouponDefinition();
        BigDecimal orderAmount = req.orderAmount();

        CustomerCouponStatus effective = effectiveStatus(coupon);
        if (effective != CustomerCouponStatus.AVAILABLE)
            return ineligible(orderAmount, "Coupon is not available (status: " + effective + ")");
        if (!def.isActive())
            return ineligible(orderAmount, "Coupon is no longer active");
        if (LocalDate.now().isBefore(def.getValidFrom()))
            return ineligible(orderAmount, "Coupon is not valid yet");
        if (def.getMinimumSpend() != null && orderAmount.compareTo(def.getMinimumSpend()) < 0)
            return ineligible(orderAmount,
                "Minimum spend of " + def.getMinimumSpend().toPlainString() + " not met");

        BigDecimal discount = computeDiscount(def, orderAmount);
        return new CouponPreviewResponse(orderAmount, discount, orderAmount.subtract(discount), true, null);
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
