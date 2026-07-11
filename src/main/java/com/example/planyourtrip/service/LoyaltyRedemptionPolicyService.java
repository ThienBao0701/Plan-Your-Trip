package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.LoyaltyRedemptionDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.LoyaltyRedemptionPolicy;
import com.example.planyourtrip.repository.LoyaltyRedemptionPolicyRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

/**
 * Phase 7.20 — Loyalty Points Redemption.
 * Admin CRUD over {@link LoyaltyRedemptionPolicy}, plus the authoritative
 * "policy applicable now" selector reused by {@code LoyaltyRedemptionService}.
 * Follows {@code MembershipTierService}'s conventions: 409 on duplicate code,
 * 404 on unknown id, 400 on invalid business values. Optimistic
 * {@code @Version} conflicts on concurrent edits surface as 409 via the global
 * handler.
 */
@Service
@Transactional(readOnly = true)
public class LoyaltyRedemptionPolicyService {

    private final LoyaltyRedemptionPolicyRepository policyRepo;

    public LoyaltyRedemptionPolicyService(LoyaltyRedemptionPolicyRepository policyRepo) {
        this.policyRepo = policyRepo;
    }

    public List<RedemptionPolicyResponse> getAll() {
        return policyRepo.findAllByOrderByEffectiveFromDescIdDesc().stream().map(this::toResponse).toList();
    }

    public RedemptionPolicyResponse getById(Long id) {
        return toResponse(policyOrThrow(id));
    }

    @Transactional
    public RedemptionPolicyResponse create(RedemptionPolicyRequest req) {
        String code = req.policyCode().trim();
        if (policyRepo.findByPolicyCodeIgnoreCase(code).isPresent())
            throw new ApiException(HttpStatus.CONFLICT, "Redemption policy already exists: " + code);

        LoyaltyRedemptionPolicy p = new LoyaltyRedemptionPolicy();
        p.setPolicyCode(code);
        fill(p, req);
        return toResponse(policyRepo.save(p));
    }

    @Transactional
    public RedemptionPolicyResponse update(Long id, RedemptionPolicyRequest req) {
        LoyaltyRedemptionPolicy p = policyOrThrow(id);
        String code = req.policyCode().trim();
        policyRepo.findByPolicyCodeIgnoreCase(code)
            .filter(other -> !other.getId().equals(id))
            .ifPresent(other -> { throw new ApiException(HttpStatus.CONFLICT,
                "Another redemption policy already uses code: " + code); });
        p.setPolicyCode(code);
        fill(p, req);
        return toResponse(policyRepo.save(p));
    }

    @Transactional
    public RedemptionPolicyResponse activate(Long id) {
        LoyaltyRedemptionPolicy p = policyOrThrow(id);
        p.setActive(true);
        return toResponse(policyRepo.save(p));
    }

    @Transactional
    public RedemptionPolicyResponse deactivate(Long id) {
        LoyaltyRedemptionPolicy p = policyOrThrow(id);
        p.setActive(false);
        return toResponse(policyRepo.save(p));
    }

    /** The one policy in force at {@code at} (newest applicable window), or 404-style error if none. */
    public LoyaltyRedemptionPolicy resolveApplicable(Instant at) {
        return policyRepo.findApplicable(at).stream().findFirst()
            .orElseThrow(() -> new ApiException(HttpStatus.CONFLICT,
                "No active loyalty redemption policy is currently in effect"));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private LoyaltyRedemptionPolicy policyOrThrow(Long id) {
        return policyRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Redemption policy not found: " + id));
    }

    private void fill(LoyaltyRedemptionPolicy p, RedemptionPolicyRequest req) {
        // Defensive re-validation beyond the DTO bean-validation (positivity / percentage / date range).
        if (req.pointsPerUnit() <= 0 || req.minimumRedemptionPoints() <= 0 || req.redemptionIncrementPoints() <= 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "points values must be positive");
        if (req.valuePerUnit().signum() <= 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "valuePerUnit must be greater than zero");
        if (req.minimumFinalPayableAmount().signum() < 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "minimumFinalPayableAmount must not be negative");
        if (req.maximumDiscountPercentage() < 0 || req.maximumDiscountPercentage() > 100)
            throw new ApiException(HttpStatus.BAD_REQUEST, "maximumDiscountPercentage must be between 0 and 100");
        if (req.minimumRedemptionPoints() % req.redemptionIncrementPoints() != 0)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "minimumRedemptionPoints must be a multiple of redemptionIncrementPoints");

        Instant from = req.effectiveFrom() != null ? req.effectiveFrom() : Instant.now();
        Instant until = req.effectiveUntil();
        if (until != null && !until.isAfter(from))
            throw new ApiException(HttpStatus.BAD_REQUEST, "effectiveUntil must be after effectiveFrom");

        p.setDisplayName(req.displayName());
        p.setPointsPerUnit(req.pointsPerUnit());
        p.setValuePerUnit(req.valuePerUnit().setScale(2, java.math.RoundingMode.HALF_UP));
        p.setMinimumRedemptionPoints(req.minimumRedemptionPoints());
        p.setRedemptionIncrementPoints(req.redemptionIncrementPoints());
        p.setMaximumDiscountPercentage(req.maximumDiscountPercentage());
        p.setMinimumFinalPayableAmount(req.minimumFinalPayableAmount().setScale(2, java.math.RoundingMode.HALF_UP));
        p.setActive(req.active() == null || req.active());
        p.setEffectiveFrom(from);
        p.setEffectiveUntil(until);
    }

    RedemptionPolicyResponse toResponse(LoyaltyRedemptionPolicy p) {
        return new RedemptionPolicyResponse(
            p.getId(), p.getPolicyCode(), p.getDisplayName(),
            p.getPointsPerUnit(), p.getValuePerUnit(),
            p.getMinimumRedemptionPoints(), p.getRedemptionIncrementPoints(),
            p.getMaximumDiscountPercentage(), p.getMinimumFinalPayableAmount(),
            p.isActive(), p.getEffectiveFrom(), p.getEffectiveUntil(),
            p.getCreatedAt(), p.getUpdatedAt(), p.getVersion()
        );
    }

    static RedemptionPolicySummary toSummary(LoyaltyRedemptionPolicy p) {
        return new RedemptionPolicySummary(
            p.getPolicyCode(), p.getPointsPerUnit(), p.getValuePerUnit(),
            p.getMinimumRedemptionPoints(), p.getRedemptionIncrementPoints(),
            p.getMaximumDiscountPercentage(), p.getMinimumFinalPayableAmount()
        );
    }
}
