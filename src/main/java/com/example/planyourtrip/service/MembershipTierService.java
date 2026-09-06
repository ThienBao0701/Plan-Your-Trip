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
    private final AdminActivityLogService adminAudit;

    public MembershipTierService(MembershipTierDefinitionRepository tierDefRepo,
                                  MembershipBenefitDefinitionRepository benefitRepo,
                                  AdminActivityLogService adminAudit) {
        this.tierDefRepo = tierDefRepo;
        this.benefitRepo = benefitRepo;
        this.adminAudit = adminAudit;
    }

    // ── Tier definitions ─────────────────────────────────────────────────────

    public List<MembershipTierDefinitionResponse> getAllTierDefinitions() {
        return tierDefRepo.findAllByOrderBySortOrderAsc().stream().map(this::toResponse).toList();
    }

    public MembershipTierDefinitionResponse getTierDefinition(MembershipTier tier) {
        return toResponse(definitionOrThrow(tier));
    }

    // -- D3H . audited administrative writes -----------------------------------
    //
    // Every write on this service is reached only from AdminMembershipController;
    // CustomerMembershipService consumes the read helpers (activeTiersOrderedBySortOrder,
    // resolveMultiplier, displayName, activeDefinitionOrThrow) and never a write. The audit is
    // therefore inline, with the actor first, matching deleteBenefit below.
    //
    // A tier definition sets the earning multiplier and the thresholds that qualify a customer for
    // it, so an edit silently re-prices loyalty for everyone in that tier; the before/after pair
    // records every qualification and multiplier scalar. The targetId is the definition row's own
    // id, not the tier enum in the path - the trail addresses rows, and the tier travels in the
    // state string where it belongs. Operator free text (displayName, description, benefit name,
    // textValue) is excluded (D1c-NEW-1).

    @Transactional
    public MembershipTierDefinitionResponse createTierDefinition(Long adminUserId,
                                                                  MembershipTierDefinitionRequest req) {
        if (tierDefRepo.findByTier(req.tier()).isPresent())
            throw new ApiException(HttpStatus.CONFLICT, "Tier definition already exists: " + req.tier());

        MembershipTierDefinition def = new MembershipTierDefinition();
        def.setTier(req.tier());
        fill(def, req);
        if (req.active() == null) def.setActive(true);
        MembershipTierDefinitionResponse saved = toResponse(tierDefRepo.save(def));
        adminAudit.record(adminUserId, "MEMBERSHIP_TIER_CREATE", "MEMBERSHIP_TIER", saved.id(),
            "Admin created membership tier definition " + saved.id(), null, summarise(saved));
        return saved;
    }

    @Transactional
    public MembershipTierDefinitionResponse updateTierDefinition(Long adminUserId, MembershipTier tier,
                                                                  MembershipTierDefinitionRequest req) {
        MembershipTierDefinition def = definitionOrThrow(tier);
        // Snapshot to an immutable record before fill() mutates the managed entity.
        String before = summarise(toResponse(def));
        fill(def, req);
        if (req.active() != null) def.setActive(req.active());
        MembershipTierDefinitionResponse saved = toResponse(tierDefRepo.save(def));
        adminAudit.record(adminUserId, "MEMBERSHIP_TIER_UPDATE", "MEMBERSHIP_TIER", saved.id(),
            "Admin updated membership tier definition " + saved.id(), before, summarise(saved));
        return saved;
    }

    @Transactional
    public MembershipTierDefinitionResponse activateTierDefinition(Long adminUserId, MembershipTier tier) {
        MembershipTierDefinition def = definitionOrThrow(tier);
        String before = summarise(toResponse(def));
        def.setActive(true);
        MembershipTierDefinitionResponse saved = toResponse(tierDefRepo.save(def));
        adminAudit.record(adminUserId, "MEMBERSHIP_TIER_ACTIVATE", "MEMBERSHIP_TIER", saved.id(),
            "Admin activated membership tier definition " + saved.id(), before, summarise(saved));
        return saved;
    }

    @Transactional
    public MembershipTierDefinitionResponse deactivateTierDefinition(Long adminUserId, MembershipTier tier) {
        MembershipTierDefinition def = definitionOrThrow(tier);
        String before = summarise(toResponse(def));
        def.setActive(false);
        MembershipTierDefinitionResponse saved = toResponse(tierDefRepo.save(def));
        adminAudit.record(adminUserId, "MEMBERSHIP_TIER_DEACTIVATE", "MEMBERSHIP_TIER", saved.id(),
            "Admin deactivated membership tier definition " + saved.id(), before, summarise(saved));
        return saved;
    }

    private static String summarise(MembershipTierDefinitionResponse d) {
        return "tier:" + d.tier()
            + " active:" + d.active()
            + " minLifetimePoints:" + num(d.minimumLifetimePoints())
            + " minCompletedBookings:" + num(d.minimumCompletedBookings())
            + " pointsMultiplier:" + num(d.pointsMultiplier())
            + " redemptionMultiplier:" + num(d.redemptionDiscountMultiplier())
            + " sortOrder:" + num(d.sortOrder());
    }

    private static String summarise(MembershipBenefitResponse b) {
        return "tier:" + b.tier()
            + " type:" + b.benefitType()
            + " active:" + b.active()
            + " numericValue:" + num(b.numericValue())
            + " sortOrder:" + num(b.sortOrder());
    }

    private static String num(Object value) {
        return AdminActivityLogService.safeNumber(value);
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

    /**
     * Phase 7.21 (additive) — used by {@code CustomerMembershipService#resolveRedemptionMultiplierForUser}
     * (in turn consumed by {@code LoyaltyRedemptionService}). Falls back to
     * 1.00 (no boost) when the tier's definition is missing or inactive,
     * exactly mirroring {@link #resolveMultiplier}.
     */
    public BigDecimal resolveRedemptionMultiplier(MembershipTier tier) {
        return tierDefRepo.findByTierAndActiveTrue(tier)
            .map(MembershipTierDefinition::getRedemptionDiscountMultiplier)
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
        // Phase 7.21 — null on create leaves the entity's own 1.00 default; null on update leaves it unchanged.
        if (req.redemptionDiscountMultiplier() != null) def.setRedemptionDiscountMultiplier(req.redemptionDiscountMultiplier());
    }

    private MembershipTierDefinitionResponse toResponse(MembershipTierDefinition d) {
        return new MembershipTierDefinitionResponse(
            d.getId(), d.getTier(), d.getDisplayName(), d.getDescription(),
            d.getMinimumLifetimePoints(), d.getMinimumCompletedBookings(), d.getPointsMultiplier(),
            d.isActive(), d.getSortOrder(), d.getRedemptionDiscountMultiplier(), d.getCreatedAt(), d.getUpdatedAt()
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
    public MembershipBenefitResponse createBenefit(Long adminUserId, MembershipBenefitRequest req) {
        MembershipBenefitDefinition b = new MembershipBenefitDefinition();
        fill(b, req);
        if (req.active() == null) b.setActive(true);
        MembershipBenefitResponse saved = toBenefitResponse(benefitRepo.save(b));
        adminAudit.record(adminUserId, "MEMBERSHIP_BENEFIT_CREATE", "MEMBERSHIP_BENEFIT", saved.id(),
            "Admin created membership benefit definition " + saved.id(), null, summarise(saved));
        return saved;
    }

    @Transactional
    public MembershipBenefitResponse updateBenefit(Long adminUserId, Long id, MembershipBenefitRequest req) {
        MembershipBenefitDefinition b = benefitOrThrow(id);
        String before = summarise(toBenefitResponse(b));
        fill(b, req);
        if (req.active() != null) b.setActive(req.active());
        MembershipBenefitResponse saved = toBenefitResponse(benefitRepo.save(b));
        adminAudit.record(adminUserId, "MEMBERSHIP_BENEFIT_UPDATE", "MEMBERSHIP_BENEFIT", id,
            "Admin updated membership benefit definition " + id, before, summarise(saved));
        return saved;
    }

    @Transactional
    public void deleteBenefit(Long adminUserId, Long id) {
        MembershipBenefitDefinition b = benefitOrThrow(id);
        String tier = b.getTier() == null ? null : b.getTier().name();
        benefitRepo.delete(b);
        adminAudit.record(adminUserId, "MEMBERSHIP_BENEFIT_DELETE", "MEMBERSHIP_BENEFIT", id,
            "Admin deleted membership benefit definition " + id, tier, null);
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
