package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.MembershipDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.MembershipBenefitDefinition;
import com.example.planyourtrip.model.MembershipTier;
import com.example.planyourtrip.model.MembershipTierDefinition;
import com.example.planyourtrip.repository.MembershipBenefitDefinitionRepository;
import com.example.planyourtrip.repository.MembershipTierDefinitionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * Admin CRUD over {@link MembershipTierDefinition} (qualification thresholds
 * + points multiplier — configurable DB rows, never hardcoded in service
 * logic) and {@link MembershipBenefitDefinition} (display-only benefit
 * metadata). Mirrors {@code CouponDefinitionService}'s conventions: 409 on
 * duplicate, 404 on unknown, 400 on invalid business state.
 *
 * <p>"One active definition per tier" is enforced structurally rather than by
 * a runtime uniqueness check on {@code active=true}: there is only ever ONE
 * {@link MembershipTierDefinition} row per {@link MembershipTier} at all
 * (unique DB constraint on {@code tier}) — {@code active} simply gates
 * whether that single row currently participates in qualification
 * ({@link #activeTiersOrderedBySortOrder}) and multiplier resolution
 * ({@link #resolveMultiplier}, which falls back to 1.00 when the tier's row
 * is inactive or missing entirely).
 */
@Service
@Transactional(readOnly = true)
public class MembershipTierService {

    private final MembershipTierDefinitionRepository tierDefRepo;
    private final MembershipBenefitDefinitionRepository benefitRepo;

    public MembershipTierService(MembershipTierDefinitionRepository tierDefRepo,
                                  MembershipBenefitDefinitionRepository benefitRepo) {
        this.tierDefRepo = tierDefRepo;
        this.benefitRepo = benefitRepo;
    }

    // ── Tier definitions ─────────────────────────────────────────────────────

    public List<MembershipTierDefinitionResponse> getAllTierDefinitions() {
        return tierDefRepo.findAllByOrderBySortOrderAsc().stream().map(this::toResponse).toList();
    }

    public MembershipTierDefinitionResponse getTierDefinition(MembershipTier tier) {
        return toResponse(definitionOrThrow(tier));
    }

    @Transactional
    public MembershipTierDefinitionResponse createTierDefinition(MembershipTierDefinitionRequest req) {
        if (tierDefRepo.findByTier(req.tier()).isPresent())
            throw new ApiException(HttpStatus.CONFLICT, "Tier definition already exists: " + req.tier());

        MembershipTierDefinition def = new MembershipTierDefinition();
        def.setTier(req.tier());
        fill(def, req);
        if (req.active() == null) def.setActive(true);
        return toResponse(tierDefRepo.save(def));
    }

    @Transactional
    public MembershipTierDefinitionResponse updateTierDefinition(MembershipTier tier, MembershipTierDefinitionRequest req) {
        MembershipTierDefinition def = definitionOrThrow(tier);
        fill(def, req);
        if (req.active() != null) def.setActive(req.active());
        return toResponse(tierDefRepo.save(def));
    }

    @Transactional
    public MembershipTierDefinitionResponse activateTierDefinition(MembershipTier tier) {
        MembershipTierDefinition def = definitionOrThrow(tier);
        def.setActive(true);
        return toResponse(tierDefRepo.save(def));
    }

    @Transactional
    public MembershipTierDefinitionResponse deactivateTierDefinition(MembershipTier tier) {
        MembershipTierDefinition def = definitionOrThrow(tier);
        def.setActive(false);
        return toResponse(tierDefRepo.save(def));
    }

    /** Only active rows participate in qualification — see {@code CustomerMembershipService#computeQualifiedTier}. */
    List<MembershipTierDefinition> activeTiersOrderedBySortOrder() {
        return tierDefRepo.findByActiveTrueOrderBySortOrderAsc();
    }

    Optional<MembershipTierDefinition> findActiveDefinition(MembershipTier tier) {
        return tierDefRepo.findByTierAndActiveTrue(tier);
    }

    /** Used by {@code CustomerMembershipService#adminAssign} — an admin may only assign a currently active tier. */
    MembershipTierDefinition activeDefinitionOrThrow(MembershipTier tier) {
        return tierDefRepo.findByTierAndActiveTrue(tier)
            .orElseThrow(() -> new ApiException(HttpStatus.BAD_REQUEST, "Tier is not active/configured: " + tier));
    }

    /** Falls back to 1.00 (no boost) when the tier's definition is missing or inactive. */
    public BigDecimal resolveMultiplier(MembershipTier tier) {
        return tierDefRepo.findByTierAndActiveTrue(tier)
            .map(MembershipTierDefinition::getPointsMultiplier)
            .orElse(BigDecimal.ONE);
    }

    String displayName(MembershipTier tier) {
        return tierDefRepo.findByTierAndActiveTrue(tier)
            .map(MembershipTierDefinition::getDisplayName)
            .orElse(tier.name());
    }

    private MembershipTierDefinition definitionOrThrow(MembershipTier tier) {
        return tierDefRepo.findByTier(tier)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Tier definition not found: " + tier));
    }

    private void fill(MembershipTierDefinition def, MembershipTierDefinitionRequest req) {
        def.setDisplayName(req.displayName());
        def.setDescription(req.description());
        def.setMinimumLifetimePoints(req.minimumLifetimePoints());
        def.setMinimumCompletedBookings(req.minimumCompletedBookings());
        def.setPointsMultiplier(req.pointsMultiplier());
        def.setSortOrder(req.sortOrder());
    }

    private MembershipTierDefinitionResponse toResponse(MembershipTierDefinition d) {
        return new MembershipTierDefinitionResponse(
            d.getId(), d.getTier(), d.getDisplayName(), d.getDescription(),
            d.getMinimumLifetimePoints(), d.getMinimumCompletedBookings(), d.getPointsMultiplier(),
            d.isActive(), d.getSortOrder(), d.getCreatedAt(), d.getUpdatedAt()
        );
    }

    // ── Benefit definitions (metadata only) ──────────────────────────────────

    public List<MembershipBenefitResponse> getAllBenefits() {
        return benefitRepo.findAllByOrderByTierAscSortOrderAsc().stream().map(this::toBenefitResponse).toList();
    }

    /** Used by {@code CustomerMembershipService#getMyBenefits} for the effective tier. */
    List<MembershipBenefitResponse> activeBenefitsForTier(MembershipTier tier) {
        return benefitRepo.findByTierAndActiveTrueOrderBySortOrderAsc(tier).stream()
            .map(this::toBenefitResponse).toList();
    }

    @Transactional
    public MembershipBenefitResponse createBenefit(MembershipBenefitRequest req) {
        MembershipBenefitDefinition b = new MembershipBenefitDefinition();
        fill(b, req);
        if (req.active() == null) b.setActive(true);
        return toBenefitResponse(benefitRepo.save(b));
    }

    @Transactional
    public MembershipBenefitResponse updateBenefit(Long id, MembershipBenefitRequest req) {
        MembershipBenefitDefinition b = benefitOrThrow(id);
        fill(b, req);
        if (req.active() != null) b.setActive(req.active());
        return toBenefitResponse(benefitRepo.save(b));
    }

    @Transactional
    public void deleteBenefit(Long id) {
        MembershipBenefitDefinition b = benefitOrThrow(id);
        benefitRepo.delete(b);
    }

    private MembershipBenefitDefinition benefitOrThrow(Long id) {
        return benefitRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Benefit definition not found: " + id));
    }

    private void fill(MembershipBenefitDefinition b, MembershipBenefitRequest req) {
        b.setTier(req.tier());
        b.setBenefitType(req.benefitType());
        b.setName(req.name());
        b.setDescription(req.description());
        b.setNumericValue(req.numericValue());
        b.setTextValue(req.textValue());
        if (req.sortOrder() != null) b.setSortOrder(req.sortOrder());
    }

    private MembershipBenefitResponse toBenefitResponse(MembershipBenefitDefinition b) {
        return new MembershipBenefitResponse(
            b.getId(), b.getTier(), b.getBenefitType(), b.getName(), b.getDescription(),
            b.getNumericValue(), b.getTextValue(), b.isActive(), b.getSortOrder(),
            b.getCreatedAt(), b.getUpdatedAt()
        );
    }
}
