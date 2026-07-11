package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PersonalizationDto.PersonalizationRuleRequest;
import com.example.planyourtrip.dto.PersonalizationDto.PersonalizationRuleResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PersonalizationRule;
import com.example.planyourtrip.model.PersonalizationRuleType;
import com.example.planyourtrip.repository.CouponDefinitionRepository;
import com.example.planyourtrip.repository.CustomerRecommendationRepository;
import com.example.planyourtrip.repository.PersonalizationRuleRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.PromotionRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Admin CRUD + activate/deactivate over {@link PersonalizationRule}. Follows the
 * established {@code ReferralCampaignService} conventions: 409 on duplicate
 * ruleCode (case-insensitive), 404 on unknown id, 400 on invalid business
 * values; optimistic {@code @Version} conflicts surface as 409 via the global
 * handler.
 *
 * <p>Rule-type compatibility (validation): explicit target ids
 * (place/hotel/promotion/coupon) are only accepted for a {@code MANUAL} rule, and
 * a {@code MANUAL} rule requires exactly one of them. All other rule types derive
 * their candidates from customer signals, so they must not carry a hard target id.
 */
@Service
@Transactional(readOnly = true)
public class PersonalizationRuleService {

    private final PersonalizationRuleRepository ruleRepo;
    private final CustomerRecommendationRepository recRepo;
    private final PlaceRepository placeRepo;
    private final PromotionRepository promotionRepo;
    private final CouponDefinitionRepository couponRepo;
    private final ObjectMapper objectMapper;

    public PersonalizationRuleService(PersonalizationRuleRepository ruleRepo,
                                       CustomerRecommendationRepository recRepo,
                                       PlaceRepository placeRepo,
                                       PromotionRepository promotionRepo,
                                       CouponDefinitionRepository couponRepo,
                                       ObjectMapper objectMapper) {
        this.ruleRepo = ruleRepo;
        this.recRepo = recRepo;
        this.placeRepo = placeRepo;
        this.promotionRepo = promotionRepo;
        this.couponRepo = couponRepo;
        this.objectMapper = objectMapper;
    }

    public List<PersonalizationRuleResponse> getAll() {
        return ruleRepo.findAllByOrderByPriorityDescIdAsc().stream().map(this::toResponse).toList();
    }

    public PersonalizationRuleResponse getById(Long id) {
        return toResponse(ruleOrThrow(id));
    }

    @Transactional
    public PersonalizationRuleResponse create(PersonalizationRuleRequest req) {
        String code = normalizeCode(req.ruleCode());
        if (ruleRepo.existsByRuleCodeIgnoreCase(code))
            throw new ApiException(HttpStatus.CONFLICT, "Personalization rule already exists: " + code);
        PersonalizationRule r = new PersonalizationRule();
        r.setRuleCode(code);
        fill(r, req);
        return toResponse(ruleRepo.save(r));
    }

    @Transactional
    public PersonalizationRuleResponse update(Long id, PersonalizationRuleRequest req) {
        PersonalizationRule r = ruleOrThrow(id);
        String code = normalizeCode(req.ruleCode());
        ruleRepo.findByRuleCodeIgnoreCase(code)
            .filter(other -> !other.getId().equals(id))
            .ifPresent(other -> { throw new ApiException(HttpStatus.CONFLICT,
                "Another personalization rule already uses code: " + code); });
        r.setRuleCode(code);
        fill(r, req);
        return toResponse(ruleRepo.save(r));
    }

    @Transactional
    public PersonalizationRuleResponse activate(Long id) {
        PersonalizationRule r = ruleOrThrow(id);
        r.setActive(true);
        return toResponse(ruleRepo.save(r));
    }

    @Transactional
    public PersonalizationRuleResponse deactivate(Long id) {
        PersonalizationRule r = ruleOrThrow(id);
        r.setActive(false);
        return toResponse(ruleRepo.save(r));
    }

    @Transactional
    public void delete(Long id) {
        PersonalizationRule r = ruleOrThrow(id);
        // Detach snapshots first so history is preserved and no FK violation occurs.
        recRepo.clearSourceRule(id);
        ruleRepo.delete(r);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    PersonalizationRule ruleOrThrow(Long id) {
        return ruleRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Personalization rule not found: " + id));
    }

    private String normalizeCode(String raw) {
        return raw == null ? "" : raw.trim();
    }

    private void fill(PersonalizationRule r, PersonalizationRuleRequest req) {
        r.setName(req.name() == null ? null : req.name().trim());
        r.setDescription(req.description());
        r.setRuleType(req.ruleType());

        int priority = req.priority() == null ? 0 : req.priority();
        if (priority < 0) throw new ApiException(HttpStatus.BAD_REQUEST, "priority must not be negative");
        r.setPriority(priority);

        r.setActive(req.active() == null || req.active());

        if (req.validFrom() != null && req.validUntil() != null && !req.validUntil().isAfter(req.validFrom()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "validUntil must be after validFrom");
        r.setValidFrom(req.validFrom());
        r.setValidUntil(req.validUntil());

        r.setMinimumMembershipTier(req.minimumMembershipTier());
        r.setTargetPlaceType(req.targetPlaceType());

        validateAndSetTargets(r, req);

        r.setConfigurationJson(validateJson(req.configurationJson()));
    }

    /**
     * Enforces rule-type compatibility for hard targets and resolves each
     * supplied id. Only MANUAL rules may carry an explicit target id (exactly
     * one); every other type is signal-driven.
     */
    private void validateAndSetTargets(PersonalizationRule r, PersonalizationRuleRequest req) {
        int targetCount = count(req.targetPlaceId(), req.targetHotelId(),
            req.targetPromotionId(), req.targetCouponDefinitionId());

        if (req.ruleType() == PersonalizationRuleType.MANUAL) {
            if (targetCount != 1)
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "A MANUAL rule must specify exactly one target (place, hotel, promotion or coupon)");
        } else if (targetCount > 0) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Target ids are only allowed for a MANUAL rule; " + req.ruleType()
                    + " rules derive candidates from customer signals");
        }

        if (req.targetPlaceId() != null && !placeRepo.existsById(req.targetPlaceId()))
            throw new ApiException(HttpStatus.NOT_FOUND, "Target place not found: " + req.targetPlaceId());
        if (req.targetHotelId() != null && !placeRepo.existsById(req.targetHotelId()))
            throw new ApiException(HttpStatus.NOT_FOUND, "Target hotel not found: " + req.targetHotelId());
        if (req.targetPromotionId() != null && !promotionRepo.existsById(req.targetPromotionId()))
            throw new ApiException(HttpStatus.NOT_FOUND, "Target promotion not found: " + req.targetPromotionId());
        if (req.targetCouponDefinitionId() != null && !couponRepo.existsById(req.targetCouponDefinitionId()))
            throw new ApiException(HttpStatus.NOT_FOUND,
                "Target coupon definition not found: " + req.targetCouponDefinitionId());

        r.setTargetPlaceId(req.targetPlaceId());
        r.setTargetHotelId(req.targetHotelId());
        r.setTargetPromotionId(req.targetPromotionId());
        r.setTargetCouponDefinitionId(req.targetCouponDefinitionId());
    }

    private int count(Object... values) {
        int n = 0;
        for (Object v : values) if (v != null) n++;
        return n;
    }

    private String validateJson(String json) {
        if (json == null || json.isBlank()) return null;
        try {
            objectMapper.readTree(json);
            return json;
        } catch (Exception e) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "configurationJson must be valid JSON");
        }
    }

    PersonalizationRuleResponse toResponse(PersonalizationRule r) {
        return new PersonalizationRuleResponse(
            r.getId(), r.getRuleCode(), r.getName(), r.getDescription(), r.getRuleType(),
            r.getPriority(), r.isActive(), r.getValidFrom(), r.getValidUntil(),
            r.getMinimumMembershipTier(), r.getTargetPlaceType(), r.getTargetPlaceId(),
            r.getTargetHotelId(), r.getTargetPromotionId(), r.getTargetCouponDefinitionId(),
            r.getConfigurationJson(), r.getCreatedAt(), r.getUpdatedAt(), r.getVersion());
    }
}
