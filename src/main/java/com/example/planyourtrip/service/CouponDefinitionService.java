package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CouponDto.CouponDefinitionRequest;
import com.example.planyourtrip.dto.CouponDto.CouponDefinitionResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.CouponDefinition;
import com.example.planyourtrip.repository.CouponDefinitionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

/**
 * Phase 7.14 — Customer Coupons &amp; Travel Credits Foundation.
 * Admin CRUD over {@link CouponDefinition}. Mirrors {@code PromotionService}'s
 * conventions: 409 on duplicate code, 400 on invalid dates, 404 on unknown id.
 * Codes are normalized to trimmed upper-case on every write so uniqueness and
 * claim lookup are case-insensitive.
 *
 * <p>Note one deliberate deviation from {@code PromotionService#validateDates}
 * (which requires end strictly after start): the 7.14 spec allows a single-day
 * coupon, so {@code validFrom == validUntil} is accepted here.
 */
@Service
@Transactional(readOnly = true)
public class CouponDefinitionService {

    private final CouponDefinitionRepository couponRepo;

    public CouponDefinitionService(CouponDefinitionRepository couponRepo) {
        this.couponRepo = couponRepo;
    }

    public List<CouponDefinitionResponse> getAll() {
        return couponRepo.findAll().stream().map(this::toResponse).toList();
    }

    public CouponDefinitionResponse getById(Long id) {
        return toResponse(definitionOrThrow(id));
    }

    @Transactional
    public CouponDefinitionResponse create(CouponDefinitionRequest req) {
        String code = normalizeCode(req.code());
        validate(req);
        if (couponRepo.existsByCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Coupon code already exists: " + code);

        CouponDefinition def = new CouponDefinition();
        fill(def, req, code);
        if (req.active() == null) def.setActive(true);
        return toResponse(couponRepo.save(def));
    }

    @Transactional
    public CouponDefinitionResponse update(Long id, CouponDefinitionRequest req) {
        CouponDefinition def = definitionOrThrow(id);
        String code = normalizeCode(req.code());
        validate(req);
        if (!code.equalsIgnoreCase(def.getCode()) && couponRepo.existsByCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Coupon code already exists: " + code);

        fill(def, req, code);
        return toResponse(couponRepo.save(def));
    }

    @Transactional
    public CouponDefinitionResponse activate(Long id) {
        CouponDefinition def = definitionOrThrow(id);
        def.setActive(true);
        return toResponse(couponRepo.save(def));
    }

    @Transactional
    public CouponDefinitionResponse deactivate(Long id) {
        CouponDefinition def = definitionOrThrow(id);
        def.setActive(false);
        return toResponse(couponRepo.save(def));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** Package-private — reused as-is by {@code CustomerCouponService} so claim lookup normalizes identically. */
    static String normalizeCode(String raw) {
        return raw == null ? null : raw.trim().toUpperCase(Locale.ROOT);
    }

    CouponDefinition definitionOrThrow(Long id) {
        return couponRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Coupon definition not found: " + id));
    }

    private void validate(CouponDefinitionRequest req) {
        // Bean validation on the DTO already covers: code/name required,
        // discountValue > 0, maxDiscountAmount/minimumSpend >= 0 when present,
        // totalUsageLimit/usageLimitPerUser >= 1 when present, dates required.
        if (req.validUntil().isBefore(req.validFrom()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "validFrom must be on or before validUntil");
    }

    private void fill(CouponDefinition def, CouponDefinitionRequest req, String normalizedCode) {
        def.setCode(normalizedCode);
        def.setName(req.name());
        def.setDescription(req.description());
        def.setDiscountType(req.discountType());
        def.setDiscountValue(req.discountValue());
        def.setMaxDiscountAmount(req.maxDiscountAmount());
        def.setMinimumSpend(req.minimumSpend());
        def.setValidFrom(req.validFrom());
        def.setValidUntil(req.validUntil());
        def.setTotalUsageLimit(req.totalUsageLimit());
        def.setUsageLimitPerUser(req.usageLimitPerUser() != null ? req.usageLimitPerUser() : 1);
        if (req.active() != null) def.setActive(req.active());
        // currentUsageCount is never client-settable.
    }

    /** Package-private — reused as-is by {@code CustomerCouponService} so both map the exact same shape. */
    CouponDefinitionResponse toResponse(CouponDefinition d) {
        return new CouponDefinitionResponse(
            d.getId(), d.getCode(), d.getName(), d.getDescription(),
            d.getDiscountType(), d.getDiscountValue(), d.getMaxDiscountAmount(), d.getMinimumSpend(),
            d.getValidFrom(), d.getValidUntil(), d.isActive(),
            d.getTotalUsageLimit(), d.getUsageLimitPerUser(), d.getCurrentUsageCount(),
            d.getCreatedAt(), d.getUpdatedAt()
        );
    }
}
