package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RatePlanDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RatePlanOccupancyPriceRepository;
import com.example.planyourtrip.repository.RatePlanRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Rate-plan CRUD + occupancy-price management. Phase 7.29 extends this ADDITIVELY —
 * all pre-existing methods keep their contracts; new fields are validated only when
 * supplied. Pricing/eligibility resolution lives in {@link RatePlanPricingService} and
 * {@link RatePlanEligibilityService} to avoid duplicating {@link PricingEngineService}.
 */
@Service
@Transactional(readOnly = true)
public class RatePlanService {

    private final RatePlanRepository ratePlanRepo;
    private final HotelRoomRepository roomRepo;
    private final RatePlanOccupancyPriceRepository occupancyRepo;

    public RatePlanService(RatePlanRepository ratePlanRepo, HotelRoomRepository roomRepo,
                           RatePlanOccupancyPriceRepository occupancyRepo) {
        this.ratePlanRepo  = ratePlanRepo;
        this.roomRepo      = roomRepo;
        this.occupancyRepo = occupancyRepo;
    }

    // ── Read ────────────────────────────────────────────────────────────────

    public List<RatePlanResponse> getByRoom(Long roomId) {
        roomOrThrow(roomId);
        return ratePlanRepo.findByHotelRoomIdOrderByStartDateAsc(roomId)
            .stream().map(this::toResponse).toList();
    }

    public RatePlanResponse getById(Long id) {
        return toResponse(planOrThrow(id));
    }

    public List<RatePlanResponse> getAll() {
        return ratePlanRepo.findAllByOrderByIdDesc().stream().map(this::toResponse).toList();
    }

    /** Admin global filter — all criteria optional and AND-combined. */
    public List<RatePlanResponse> filter(Long hotelId, Long roomId, Boolean active,
                                         RatePlanType type, MealPlanType mealPlan,
                                         Boolean refundable, LocalDate from, LocalDate to) {
        return ratePlanRepo.findAllByOrderByIdDesc().stream()
            .filter(rp -> roomId == null || rp.getHotelRoom().getId().equals(roomId))
            .filter(rp -> hotelId == null || matchesHotel(rp, hotelId))
            .filter(rp -> active == null || rp.isActive() == active)
            .filter(rp -> type == null || rp.getRateType() == type)
            .filter(rp -> mealPlan == null || rp.getMealPlanType() == mealPlan)
            .filter(rp -> refundable == null || rp.isRefundable() == refundable)
            .filter(rp -> from == null || !rp.getEndDate().isBefore(from))
            .filter(rp -> to == null || !rp.getStartDate().isAfter(to))
            .map(this::toResponse).toList();
    }

    private boolean matchesHotel(RatePlan rp, Long hotelId) {
        HotelDetail hd = rp.getHotelRoom().getHotelDetail();
        return hd != null && hd.getId().equals(hotelId);
    }

    // ── Create / Update / Delete ────────────────────────────────────────────

    @Transactional
    public RatePlanResponse create(Long roomId, RatePlanRequest req) {
        HotelRoom room = roomOrThrow(roomId);
        RatePlan plan = new RatePlan();
        plan.setHotelRoom(room);
        applyAndValidate(plan, roomId, req, null);
        return toResponse(ratePlanRepo.save(plan));
    }

    @Transactional
    public RatePlanResponse update(Long id, RatePlanRequest req) {
        RatePlan plan = planOrThrow(id);
        applyAndValidate(plan, plan.getHotelRoom().getId(), req, id);
        return toResponse(ratePlanRepo.save(plan));
    }

    @Transactional
    public void delete(Long id) {
        RatePlan plan = planOrThrow(id);
        List<RatePlan> children = ratePlanRepo.findByParentRatePlanId(id);
        if (!children.isEmpty())
            throw new ApiException(HttpStatus.CONFLICT,
                "Cannot delete a rate plan that is the parent of derived plans");
        occupancyRepo.deleteByRatePlanId(id);
        ratePlanRepo.deleteById(id);
    }

    @Transactional
    public RatePlanResponse setActive(Long id, boolean active) {
        RatePlan plan = planOrThrow(id);
        plan.setActive(active);
        return toResponse(ratePlanRepo.save(plan));
    }

    /** Deep-copy a rate plan (base fields + config) into the same room under a new code/name. */
    @Transactional
    public RatePlanResponse duplicate(Long id, RatePlanDuplicateRequest req) {
        RatePlan src = planOrThrow(id);
        RatePlan copy = new RatePlan();
        copy.setHotelRoom(src.getHotelRoom());
        copy.setRateName(req != null && req.rateName() != null && !req.rateName().isBlank()
            ? req.rateName() : src.getRateName() + " (copy)");
        copy.setRateType(src.getRateType());
        copy.setPricePerNight(src.getPricePerNight());
        copy.setStartDate(src.getStartDate());
        copy.setEndDate(src.getEndDate());
        copy.setActive(src.isActive());
        copy.setDescription(src.getDescription());
        copy.setMealPlanType(src.getMealPlanType());
        copy.setCancellationPolicyType(src.getCancellationPolicyType());
        copy.setCancellationDeadlineHours(src.getCancellationDeadlineHours());
        copy.setCancellationPenaltyPercent(src.getCancellationPenaltyPercent());
        copy.setRefundable(src.isRefundable());
        // A duplicate is a standalone BASE plan (does not inherit the derived link).
        copy.setSourceType(RateSourceType.BASE);
        copy.setPriority(src.getPriority());
        copy.setMinStayNights(src.getMinStayNights());
        copy.setMaxStayNights(src.getMaxStayNights());
        copy.setMinAdvanceBookingDays(src.getMinAdvanceBookingDays());
        copy.setMaxAdvanceBookingDays(src.getMaxAdvanceBookingDays());
        copy.setClosedToArrival(src.isClosedToArrival());
        copy.setClosedToDeparture(src.isClosedToDeparture());
        copy.setOccupancyPricingEnabled(src.isOccupancyPricingEnabled());
        copy.setChildPricingEnabled(src.isChildPricingEnabled());
        copy.setExtraBedPrice(src.getExtraBedPrice());

        String newCode = req != null && req.code() != null && !req.code().isBlank()
            ? req.code().trim()
            : (src.getCode() != null ? src.getCode() + "-COPY" : null);
        if (newCode != null) {
            requireUniqueCode(src.getHotelRoom().getId(), newCode, null);
            copy.setCode(newCode);
        }
        RatePlan saved = ratePlanRepo.save(copy);

        // Copy occupancy prices too.
        for (RatePlanOccupancyPrice op : occupancyRepo.findByRatePlanIdOrderByAdultsAscChildrenAsc(id)) {
            RatePlanOccupancyPrice c = new RatePlanOccupancyPrice();
            c.setRatePlan(saved);
            c.setAdults(op.getAdults());
            c.setChildren(op.getChildren());
            c.setPricePerNight(op.getPricePerNight());
            c.setChildSupplement(op.getChildSupplement());
            c.setExtraBedSupplement(op.getExtraBedSupplement());
            occupancyRepo.save(c);
        }
        return toResponse(saved);
    }

    // ── Occupancy prices ──────────────────────────────────────────────────────

    public List<RatePlanOccupancyPriceResponse> getOccupancyPrices(Long ratePlanId) {
        planOrThrow(ratePlanId);
        return occupancyRepo.findByRatePlanIdOrderByAdultsAscChildrenAsc(ratePlanId)
            .stream().map(this::toOccupancyResponse).toList();
    }

    @Transactional
    public RatePlanOccupancyPriceResponse addOccupancyPrice(Long ratePlanId, RatePlanOccupancyPriceRequest req) {
        RatePlan plan = planOrThrow(ratePlanId);
        validateOccupancy(req);
        if (occupancyRepo.existsByRatePlanIdAndAdultsAndChildren(ratePlanId, req.adults(), req.children()))
            throw new ApiException(HttpStatus.CONFLICT,
                "An occupancy price already exists for " + req.adults() + " adults + " + req.children() + " children");
        RatePlanOccupancyPrice op = new RatePlanOccupancyPrice();
        op.setRatePlan(plan);
        fillOccupancy(op, req);
        return toOccupancyResponse(occupancyRepo.save(op));
    }

    @Transactional
    public RatePlanOccupancyPriceResponse updateOccupancyPrice(Long occupancyPriceId, RatePlanOccupancyPriceRequest req) {
        RatePlanOccupancyPrice op = occupancyRepo.findById(occupancyPriceId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Occupancy price not found: " + occupancyPriceId));
        validateOccupancy(req);
        // Enforce uniqueness if the occupancy key changed.
        if ((op.getAdults() != req.adults() || op.getChildren() != req.children())
                && occupancyRepo.existsByRatePlanIdAndAdultsAndChildren(
                    op.getRatePlan().getId(), req.adults(), req.children()))
            throw new ApiException(HttpStatus.CONFLICT,
                "An occupancy price already exists for " + req.adults() + " adults + " + req.children() + " children");
        fillOccupancy(op, req);
        return toOccupancyResponse(occupancyRepo.save(op));
    }

    @Transactional
    public void deleteOccupancyPrice(Long occupancyPriceId) {
        if (!occupancyRepo.existsById(occupancyPriceId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Occupancy price not found: " + occupancyPriceId);
        occupancyRepo.deleteById(occupancyPriceId);
    }

    public RatePlanOccupancyPrice occupancyPriceOrThrow(Long occupancyPriceId) {
        return occupancyRepo.findById(occupancyPriceId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Occupancy price not found: " + occupancyPriceId));
    }

    // ── Validation & mapping ──────────────────────────────────────────────────

    private void applyAndValidate(RatePlan plan, Long roomId, RatePlanRequest req, Long selfId) {
        validateDates(req.startDate(), req.endDate());

        plan.setRateName(req.rateName());
        plan.setRateType(req.rateType());
        plan.setPricePerNight(req.pricePerNight());
        plan.setStartDate(req.startDate());
        plan.setEndDate(req.endDate());
        if (req.active() != null) plan.setActive(req.active());

        // code — unique per room, case-insensitive (only when supplied).
        if (req.code() != null && !req.code().isBlank()) {
            String code = req.code().trim();
            requireUniqueCode(roomId, code, selfId);
            plan.setCode(code);
        } else {
            plan.setCode(null);
        }

        plan.setDescription(req.description());
        if (req.mealPlanType() != null) plan.setMealPlanType(req.mealPlanType());
        if (req.cancellationPolicyType() != null) plan.setCancellationPolicyType(req.cancellationPolicyType());

        if (req.cancellationDeadlineHours() != null) {
            if (req.cancellationDeadlineHours() < 0)
                throw badRequest("cancellationDeadlineHours must be >= 0");
            plan.setCancellationDeadlineHours(req.cancellationDeadlineHours());
        } else {
            plan.setCancellationDeadlineHours(null);
        }

        if (req.cancellationPenaltyPercent() != null) {
            BigDecimal p = req.cancellationPenaltyPercent();
            if (p.signum() < 0 || p.compareTo(BigDecimal.valueOf(100)) > 0)
                throw badRequest("cancellationPenaltyPercent must be between 0 and 100");
            plan.setCancellationPenaltyPercent(p);
        } else {
            plan.setCancellationPenaltyPercent(null);
        }

        // refundable — derive a sensible default from policy when not explicitly given.
        if (req.refundable() != null) {
            plan.setRefundable(req.refundable());
        } else {
            plan.setRefundable(plan.getCancellationPolicyType() != CancellationPolicyType.NON_REFUNDABLE);
        }

        if (req.priority() != null) {
            if (req.priority() < 0) throw badRequest("priority must be >= 0");
            plan.setPriority(req.priority());
        }

        validateStay(req);
        plan.setMinStayNights(req.minStayNights());
        plan.setMaxStayNights(req.maxStayNights());

        validateAdvance(req);
        plan.setMinAdvanceBookingDays(req.minAdvanceBookingDays());
        plan.setMaxAdvanceBookingDays(req.maxAdvanceBookingDays());

        if (req.closedToArrival() != null) plan.setClosedToArrival(req.closedToArrival());
        if (req.closedToDeparture() != null) plan.setClosedToDeparture(req.closedToDeparture());
        if (req.occupancyPricingEnabled() != null) plan.setOccupancyPricingEnabled(req.occupancyPricingEnabled());
        if (req.childPricingEnabled() != null) plan.setChildPricingEnabled(req.childPricingEnabled());

        if (req.extraBedPrice() != null) {
            if (req.extraBedPrice().signum() < 0) throw badRequest("extraBedPrice must be >= 0");
            plan.setExtraBedPrice(req.extraBedPrice());
        } else {
            plan.setExtraBedPrice(null);
        }

        // ── Derived-plan relationship ────────────────────────────────────────
        RateSourceType source = req.sourceType() != null ? req.sourceType() : RateSourceType.BASE;
        plan.setSourceType(source);
        if (source == RateSourceType.DERIVED) {
            if (req.parentRatePlanId() == null)
                throw badRequest("A DERIVED rate plan requires parentRatePlanId");
            if (selfId != null && req.parentRatePlanId().equals(selfId))
                throw badRequest("A rate plan cannot be its own parent");
            RatePlan parent = ratePlanRepo.findById(req.parentRatePlanId())
                .orElseThrow(() -> badRequest("Parent rate plan not found: " + req.parentRatePlanId()));
            if (!parent.getHotelRoom().getId().equals(roomId))
                throw badRequest("Parent rate plan must belong to the same room");
            if (req.adjustmentType() == null || req.adjustmentValue() == null)
                throw badRequest("A DERIVED rate plan requires adjustmentType and adjustmentValue");
            // No circular relation: walking the parent chain must never reach this plan.
            assertNoCycle(parent, selfId);
            // Final computed price must be >= 0.
            BigDecimal derived = computeDerived(parent.getPricePerNight(), req.adjustmentType(), req.adjustmentValue());
            if (derived.signum() < 0)
                throw badRequest("Derived final price cannot be negative");
            plan.setParentRatePlan(parent);
            plan.setAdjustmentType(req.adjustmentType());
            plan.setAdjustmentValue(req.adjustmentValue());
        } else {
            plan.setParentRatePlan(null);
            plan.setAdjustmentType(null);
            plan.setAdjustmentValue(null);
        }
    }

    private void assertNoCycle(RatePlan parent, Long selfId) {
        Set<Long> seen = new HashSet<>();
        RatePlan cur = parent;
        while (cur != null) {
            if (selfId != null && selfId.equals(cur.getId()))
                throw badRequest("Circular derived-plan relationship detected");
            if (!seen.add(cur.getId()))
                throw badRequest("Circular derived-plan relationship detected");
            cur = cur.getParentRatePlan();
        }
    }

    static BigDecimal computeDerived(BigDecimal parentPrice, RateAdjustmentType type, BigDecimal value) {
        BigDecimal result;
        if (type == RateAdjustmentType.PERCENTAGE) {
            BigDecimal factor = BigDecimal.ONE.add(value.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP));
            result = parentPrice.multiply(factor);
        } else {
            result = parentPrice.add(value);
        }
        return result.setScale(2, RoundingMode.HALF_UP);
    }

    private void requireUniqueCode(Long roomId, String code, Long selfId) {
        ratePlanRepo.findByHotelRoomIdAndCodeIgnoreCase(roomId, code).ifPresent(existing -> {
            if (selfId == null || !existing.getId().equals(selfId))
                throw new ApiException(HttpStatus.CONFLICT,
                    "Rate plan code already exists for this room: " + code);
        });
    }

    private void validateDates(LocalDate start, LocalDate end) {
        if (!end.isAfter(start)) throw badRequest("endDate must be after startDate");
    }

    private void validateStay(RatePlanRequest req) {
        if (req.minStayNights() != null && req.minStayNights() < 1)
            throw badRequest("minStayNights must be >= 1");
        if (req.maxStayNights() != null && req.maxStayNights() < 1)
            throw badRequest("maxStayNights must be >= 1");
        if (req.minStayNights() != null && req.maxStayNights() != null
                && req.maxStayNights() < req.minStayNights())
            throw badRequest("maxStayNights must be >= minStayNights");
    }

    private void validateAdvance(RatePlanRequest req) {
        if (req.minAdvanceBookingDays() != null && req.minAdvanceBookingDays() < 0)
            throw badRequest("minAdvanceBookingDays must be >= 0");
        if (req.maxAdvanceBookingDays() != null && req.maxAdvanceBookingDays() < 0)
            throw badRequest("maxAdvanceBookingDays must be >= 0");
        if (req.minAdvanceBookingDays() != null && req.maxAdvanceBookingDays() != null
                && req.maxAdvanceBookingDays() < req.minAdvanceBookingDays())
            throw badRequest("maxAdvanceBookingDays must be >= minAdvanceBookingDays");
    }

    private void validateOccupancy(RatePlanOccupancyPriceRequest req) {
        if (req.adults() == null || req.adults() < 1) throw badRequest("adults must be >= 1");
        if (req.children() == null || req.children() < 0) throw badRequest("children must be >= 0");
        if (req.pricePerNight() == null || req.pricePerNight().signum() < 0)
            throw badRequest("pricePerNight must be >= 0");
        if (req.childSupplement() != null && req.childSupplement().signum() < 0)
            throw badRequest("childSupplement must be >= 0");
        if (req.extraBedSupplement() != null && req.extraBedSupplement().signum() < 0)
            throw badRequest("extraBedSupplement must be >= 0");
    }

    private void fillOccupancy(RatePlanOccupancyPrice op, RatePlanOccupancyPriceRequest req) {
        op.setAdults(req.adults());
        op.setChildren(req.children());
        op.setPricePerNight(req.pricePerNight());
        op.setChildSupplement(req.childSupplement());
        op.setExtraBedSupplement(req.extraBedSupplement());
    }

    RatePlanResponse toResponse(RatePlan p) {
        return new RatePlanResponse(
            p.getId(),
            p.getHotelRoom().getId(),
            p.getRateName(),
            p.getRateType(),
            p.getPricePerNight(),
            p.getStartDate(),
            p.getEndDate(),
            p.isActive(),
            p.getCreatedAt(),
            p.getUpdatedAt(),
            p.getCode(),
            p.getDescription(),
            p.getMealPlanType(),
            p.getCancellationPolicyType(),
            p.getCancellationDeadlineHours(),
            p.getCancellationPenaltyPercent(),
            p.isRefundable(),
            p.getSourceType(),
            p.getParentRatePlan() != null ? p.getParentRatePlan().getId() : null,
            p.getAdjustmentType(),
            p.getAdjustmentValue(),
            p.getPriority(),
            p.getMinStayNights(),
            p.getMaxStayNights(),
            p.getMinAdvanceBookingDays(),
            p.getMaxAdvanceBookingDays(),
            p.isClosedToArrival(),
            p.isClosedToDeparture(),
            p.isOccupancyPricingEnabled(),
            p.isChildPricingEnabled(),
            p.getExtraBedPrice()
        );
    }

    RatePlanOccupancyPriceResponse toOccupancyResponse(RatePlanOccupancyPrice op) {
        return new RatePlanOccupancyPriceResponse(
            op.getId(),
            op.getRatePlan().getId(),
            op.getAdults(),
            op.getChildren(),
            op.getPricePerNight(),
            op.getChildSupplement(),
            op.getExtraBedSupplement(),
            op.getCreatedAt(),
            op.getUpdatedAt()
        );
    }

    private HotelRoom roomOrThrow(Long roomId) {
        return roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }

    RatePlan planOrThrow(Long id) {
        return ratePlanRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found: " + id));
    }

    private static ApiException badRequest(String msg) {
        return new ApiException(HttpStatus.BAD_REQUEST, msg);
    }
}
