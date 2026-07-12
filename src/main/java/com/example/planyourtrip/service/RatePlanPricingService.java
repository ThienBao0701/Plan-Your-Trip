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
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.29 — the CENTRALIZED rate-plan pricing evaluator.
 *
 * <p>It resolves, per stay/occupancy: base nightly rate → derived-plan adjustment →
 * occupancy override → child / extra-bed supplements → final nightly rate → stay subtotal,
 * and maps cancellation terms. It intentionally does NOT re-implement promotion / coupon /
 * loyalty / credit / gift-card discounting — those remain exclusively in
 * {@link PricingEngineService} and {@code BookingService}. Its output composes as the
 * rate-plan stages that come BEFORE that untouched customer-discount chain.
 *
 * <p>Occupancy fallback: when {@code occupancyPricingEnabled} is set but no occupancy row
 * matches the requested (adults, children), pricing FALLS BACK to the plan's base nightly
 * rate (occupancyAdjustment = 0).
 */
@Service
@Transactional(readOnly = true)
public class RatePlanPricingService {

    private final RatePlanRepository ratePlanRepo;
    private final RatePlanOccupancyPriceRepository occupancyRepo;
    private final HotelRoomRepository roomRepo;
    private final RatePlanEligibilityService eligibilityService;

    public RatePlanPricingService(RatePlanRepository ratePlanRepo,
                                  RatePlanOccupancyPriceRepository occupancyRepo,
                                  HotelRoomRepository roomRepo,
                                  RatePlanEligibilityService eligibilityService) {
        this.ratePlanRepo       = ratePlanRepo;
        this.occupancyRepo      = occupancyRepo;
        this.roomRepo           = roomRepo;
        this.eligibilityService = eligibilityService;
    }

    // ── Public preview APIs ───────────────────────────────────────────────────

    /** List every plan for a room as a pricing/eligibility breakdown for the given stay. */
    public List<RatePlanPricingBreakdownResponse> previewRoom(Long roomId, LocalDate checkIn, LocalDate checkOut,
                                                              int adults, int children, int extraBeds) {
        roomOrThrow(roomId);
        return ratePlanRepo.findByHotelRoomIdOrderByStartDateAsc(roomId).stream()
            .map(p -> buildBreakdown(p, checkIn, checkOut, adults, children, extraBeds, true))
            .toList();
    }

    public RatePlanPricingBreakdownResponse preview(Long roomId, Long ratePlanId, LocalDate checkIn,
                                                    LocalDate checkOut, int adults, int children, int extraBeds) {
        RatePlan plan = planForRoomOrThrow(roomId, ratePlanId);
        return buildBreakdown(plan, checkIn, checkOut, adults, children, extraBeds, true);
    }

    /** Partner/admin preview by plan id (room derived from the plan). */
    public RatePlanPricingBreakdownResponse previewByPlan(Long ratePlanId, LocalDate checkIn, LocalDate checkOut,
                                                          int adults, int children, int extraBeds) {
        RatePlan plan = planOrThrow(ratePlanId);
        return buildBreakdown(plan, checkIn, checkOut, adults, children, extraBeds, true);
    }

    public RatePlanEligibilityResponse validate(Long ratePlanId, RatePlanEligibilityRequest req) {
        RatePlan plan = planOrThrow(ratePlanId);
        int adults   = req.adults()   != null ? req.adults()   : 1;
        int children = req.children() != null ? req.children() : 0;
        int extraBeds= req.extraBeds()!= null ? req.extraBeds(): 0;
        RatePlanEligibilityService.Result r =
            eligibilityService.evaluate(plan, req.checkIn(), req.checkOut(), adults, children, extraBeds, true);
        return new RatePlanEligibilityResponse(plan.getId(), plan.getCode(), plan.getRateName(),
            r.eligible(), r.reason());
    }

    public RatePlanCancellationPreviewResponse cancellationPreview(Long roomId, Long ratePlanId, LocalDate checkIn,
                                                                   LocalDate checkOut, int adults, int children, int extraBeds) {
        RatePlan plan = planForRoomOrThrow(roomId, ratePlanId);
        RatePlanPricingBreakdownResponse b = buildBreakdown(plan, checkIn, checkOut, adults, children, extraBeds, false);
        Instant deadline = b.cancellationDeadline();
        boolean pastDeadline = deadline != null && Instant.now().isAfter(deadline);
        BigDecimal subtotal = b.staySubtotal();
        BigDecimal penalty = penaltyFor(plan, subtotal, pastDeadline);
        BigDecimal refund = subtotal.subtract(penalty).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
        return new RatePlanCancellationPreviewResponse(
            plan.getId(), plan.getCancellationPolicyType(), plan.isRefundable(),
            deadline, pastDeadline, subtotal, penalty, refund, policySummary(plan));
    }

    // ── Best-plan selection (booking snapshot when ratePlanId omitted) ────────

    /**
     * Best eligible plan for a stay/occupancy: highest {@code priority}, then lowest final
     * nightly rate. Used to snapshot a rate plan onto a booking created without an explicit
     * ratePlanId. Never throws — returns empty when no plan is eligible.
     */
    public Optional<RatePlan> selectBestEligible(HotelRoom room, LocalDate checkIn, LocalDate checkOut,
                                                 int adults, int children, int extraBeds, boolean checkInventory) {
        return ratePlanRepo.findByHotelRoomIdOrderByStartDateAsc(room.getId()).stream()
            .filter(p -> eligibilityService.evaluate(p, checkIn, checkOut, adults, children, extraBeds, checkInventory).eligible())
            .min(Comparator.comparingInt(RatePlan::getPriority).reversed()
                .thenComparing(p -> finalNightlyRate(p, adults, children, extraBeds)));
    }

    // ── Booking snapshot resolution ───────────────────────────────────────────

    /** Immutable snapshot of the rate-plan terms captured onto a booking at creation. */
    public record BookingRateResolution(
        RatePlan plan,
        BigDecimal finalNightlyRate,
        BigDecimal staySubtotal,
        BigDecimal ratePlanAdjustment,
        Instant cancellationDeadlineAt
    ) {}

    /**
     * Resolve the rate plan to snapshot onto a booking.
     * <ul>
     *   <li>{@code ratePlanId} provided → it MUST exist for the room and be eligible, else 422.</li>
     *   <li>{@code ratePlanId} omitted → the best eligible plan is selected (or none).</li>
     * </ul>
     * Inventory eligibility is NOT re-checked here ({@code checkInventory=false}) — the booking
     * transaction already confirmed availability under the Phase 7.28 lock.
     */
    public Optional<BookingRateResolution> resolveForBooking(HotelRoom room, Long ratePlanId, LocalDate checkIn,
                                                             LocalDate checkOut, int adults, int children, int extraBeds) {
        RatePlan plan;
        if (ratePlanId != null) {
            plan = ratePlanRepo.findById(ratePlanId)
                .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Selected rate plan not found: " + ratePlanId));
            if (!plan.getHotelRoom().getId().equals(room.getId()))
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Selected rate plan does not belong to this room");
            RatePlanEligibilityService.Result r =
                eligibilityService.evaluate(plan, checkIn, checkOut, adults, children, extraBeds, false);
            if (!r.eligible())
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                    "Selected rate plan is not eligible: " + r.reason());
        } else {
            Optional<RatePlan> best = selectBestEligible(room, checkIn, checkOut, adults, children, extraBeds, false);
            if (best.isEmpty()) return Optional.empty();
            plan = best.get();
        }
        long nights = ChronoUnit.DAYS.between(checkIn, checkOut);
        BigDecimal nightly = finalNightlyRate(plan, adults, children, extraBeds);
        BigDecimal subtotal = nightly.multiply(BigDecimal.valueOf(nights)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal adjustment = derivedAdjustment(plan);
        return Optional.of(new BookingRateResolution(plan, nightly, subtotal, adjustment,
            cancellationDeadlineAt(plan, checkIn)));
    }

    // ── Core breakdown computation ────────────────────────────────────────────

    private RatePlanPricingBreakdownResponse buildBreakdown(RatePlan plan, LocalDate checkIn, LocalDate checkOut,
                                                            int adults, int children, int extraBeds, boolean checkInventory) {
        RatePlanEligibilityService.Result elig =
            eligibilityService.evaluate(plan, checkIn, checkOut, adults, children, extraBeds, checkInventory);

        int nights = (checkIn != null && checkOut != null && checkOut.isAfter(checkIn))
            ? (int) ChronoUnit.DAYS.between(checkIn, checkOut) : 0;

        BigDecimal baseNightly = resolveParentNightly(plan);          // parent-resolved nightly (== pricePerNight for BASE)
        BigDecimal preOccupancy = resolveNightlyBeforeOccupancy(plan); // after derived adjustment
        BigDecimal derivedAdj = preOccupancy.subtract(baseNightly).setScale(2, RoundingMode.HALF_UP);

        Optional<RatePlanOccupancyPrice> occ = matchingOccupancy(plan, adults, children);
        BigDecimal effectiveNightly;
        BigDecimal occupancyAdj;
        if (plan.isOccupancyPricingEnabled() && occ.isPresent()) {
            effectiveNightly = occ.get().getPricePerNight();
            occupancyAdj = effectiveNightly.subtract(preOccupancy).setScale(2, RoundingMode.HALF_UP);
        } else {
            effectiveNightly = preOccupancy;                          // fallback to base
            occupancyAdj = BigDecimal.ZERO.setScale(2);
        }

        BigDecimal childSupp = childSupplementPerNight(plan, occ.orElse(null), children);
        BigDecimal extraBedSupp = extraBedSupplementPerNight(plan, occ.orElse(null), extraBeds);

        BigDecimal finalNightly = effectiveNightly.add(childSupp).add(extraBedSupp).max(BigDecimal.ZERO)
            .setScale(2, RoundingMode.HALF_UP);
        BigDecimal subtotal = finalNightly.multiply(BigDecimal.valueOf(nights)).setScale(2, RoundingMode.HALF_UP);

        return new RatePlanPricingBreakdownResponse(
            plan.getId(), plan.getCode(), plan.getRateName(),
            plan.getHotelRoom().getId(), plan.getHotelRoom().getRoomName(),
            plan.getSourceType(),
            plan.getParentRatePlan() != null ? plan.getParentRatePlan().getId() : null,
            elig.eligible(), elig.reason(), nights,
            baseNightly.setScale(2, RoundingMode.HALF_UP),
            derivedAdj, occupancyAdj,
            childSupp.setScale(2, RoundingMode.HALF_UP),
            extraBedSupp.setScale(2, RoundingMode.HALF_UP),
            finalNightly, subtotal,
            plan.getMealPlanType(), plan.getCancellationPolicyType(), plan.isRefundable(),
            cancellationDeadlineAt(plan, checkIn), policySummary(plan));
    }

    // ── Nightly-rate helpers ──────────────────────────────────────────────────

    /** Final nightly rate incl. derived adjustment, occupancy override and supplements. */
    BigDecimal finalNightlyRate(RatePlan plan, int adults, int children, int extraBeds) {
        BigDecimal preOccupancy = resolveNightlyBeforeOccupancy(plan);
        Optional<RatePlanOccupancyPrice> occ = matchingOccupancy(plan, adults, children);
        BigDecimal effective = (plan.isOccupancyPricingEnabled() && occ.isPresent())
            ? occ.get().getPricePerNight() : preOccupancy;
        BigDecimal childSupp = childSupplementPerNight(plan, occ.orElse(null), children);
        BigDecimal extraBedSupp = extraBedSupplementPerNight(plan, occ.orElse(null), extraBeds);
        return effective.add(childSupp).add(extraBedSupp).max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
    }

    /** Nightly rate after the derived adjustment but BEFORE occupancy/supplements. */
    private BigDecimal resolveNightlyBeforeOccupancy(RatePlan plan) {
        if (plan.getSourceType() != RateSourceType.DERIVED || plan.getParentRatePlan() == null
                || plan.getAdjustmentType() == null || plan.getAdjustmentValue() == null)
            return plan.getPricePerNight();
        BigDecimal parentNightly = resolveNightlyBeforeOccupancy(plan.getParentRatePlan());
        return RatePlanService.computeDerived(parentNightly, plan.getAdjustmentType(), plan.getAdjustmentValue());
    }

    /** The parent's resolved nightly (used as the baseNightlyRate reference for display). */
    private BigDecimal resolveParentNightly(RatePlan plan) {
        if (plan.getSourceType() == RateSourceType.DERIVED && plan.getParentRatePlan() != null)
            return resolveNightlyBeforeOccupancy(plan.getParentRatePlan());
        return plan.getPricePerNight();
    }

    private BigDecimal derivedAdjustment(RatePlan plan) {
        return resolveNightlyBeforeOccupancy(plan).subtract(resolveParentNightly(plan))
            .setScale(2, RoundingMode.HALF_UP);
    }

    private Optional<RatePlanOccupancyPrice> matchingOccupancy(RatePlan plan, int adults, int children) {
        if (!plan.isOccupancyPricingEnabled()) return Optional.empty();
        return occupancyRepo.findByRatePlanIdAndAdultsAndChildren(plan.getId(), adults, children);
    }

    private BigDecimal childSupplementPerNight(RatePlan plan, RatePlanOccupancyPrice occ, int children) {
        if (!plan.isChildPricingEnabled() || children <= 0) return BigDecimal.ZERO.setScale(2);
        BigDecimal perChild = (occ != null && occ.getChildSupplement() != null)
            ? occ.getChildSupplement() : BigDecimal.ZERO;
        return perChild.multiply(BigDecimal.valueOf(children)).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal extraBedSupplementPerNight(RatePlan plan, RatePlanOccupancyPrice occ, int extraBeds) {
        if (extraBeds <= 0) return BigDecimal.ZERO.setScale(2);
        BigDecimal perBed = (occ != null && occ.getExtraBedSupplement() != null)
            ? occ.getExtraBedSupplement()
            : (plan.getExtraBedPrice() != null ? plan.getExtraBedPrice() : BigDecimal.ZERO);
        return perBed.multiply(BigDecimal.valueOf(extraBeds)).setScale(2, RoundingMode.HALF_UP);
    }

    // ── Cancellation helpers ──────────────────────────────────────────────────

    Instant cancellationDeadlineAt(RatePlan plan, LocalDate checkIn) {
        if (checkIn == null) return null;
        if (plan.getCancellationPolicyType() == CancellationPolicyType.NON_REFUNDABLE) return null;
        if (plan.getCancellationDeadlineHours() == null) return null;
        return checkIn.atStartOfDay(ZoneOffset.UTC).toInstant()
            .minus(plan.getCancellationDeadlineHours(), ChronoUnit.HOURS);
    }

    private BigDecimal penaltyFor(RatePlan plan, BigDecimal subtotal, boolean pastDeadline) {
        BigDecimal full = subtotal.setScale(2, RoundingMode.HALF_UP);
        return switch (plan.getCancellationPolicyType()) {
            case NON_REFUNDABLE -> full;                                     // 100%
            case FREE_CANCELLATION -> pastDeadline ? full : BigDecimal.ZERO.setScale(2);
            case PARTIALLY_REFUNDABLE -> {
                BigDecimal pct = plan.getCancellationPenaltyPercent() != null
                    ? plan.getCancellationPenaltyPercent() : BigDecimal.ZERO;
                yield subtotal.multiply(pct).divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            }
            case CUSTOM -> BigDecimal.ZERO.setScale(2);                      // metadata only in this phase
        };
    }

    private String policySummary(RatePlan plan) {
        return switch (plan.getCancellationPolicyType()) {
            case FREE_CANCELLATION -> plan.getCancellationDeadlineHours() != null
                ? "Free cancellation up to " + plan.getCancellationDeadlineHours() + " hours before check-in"
                : "Free cancellation";
            case PARTIALLY_REFUNDABLE -> "Partially refundable — "
                + (plan.getCancellationPenaltyPercent() != null ? plan.getCancellationPenaltyPercent() : BigDecimal.ZERO)
                + "% penalty";
            case NON_REFUNDABLE -> "Non-refundable";
            case CUSTOM -> "Custom cancellation policy";
        };
    }

    // ── Lookups ───────────────────────────────────────────────────────────────

    private HotelRoom roomOrThrow(Long roomId) {
        return roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }

    private RatePlan planOrThrow(Long id) {
        return ratePlanRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found: " + id));
    }

    private RatePlan planForRoomOrThrow(Long roomId, Long ratePlanId) {
        RatePlan plan = planOrThrow(ratePlanId);
        if (!plan.getHotelRoom().getId().equals(roomId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Rate plan not found for room: " + ratePlanId);
        return plan;
    }
}
