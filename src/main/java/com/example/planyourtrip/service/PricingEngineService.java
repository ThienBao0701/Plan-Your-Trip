package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

@Service
@Transactional(readOnly = true)
public class PricingEngineService {

    private final HotelRoomRepository roomRepo;
    private final RatePlanRepository ratePlanRepo;
    private final PromotionRepository promotionRepo;

    public PricingEngineService(HotelRoomRepository roomRepo,
                                 RatePlanRepository ratePlanRepo,
                                 PromotionRepository promotionRepo) {
        this.roomRepo      = roomRepo;
        this.ratePlanRepo  = ratePlanRepo;
        this.promotionRepo = promotionRepo;
    }

    /**
     * Standalone pricing: selects the cheapest active rate plan itself (Step 2 min-price pick).
     * Used by the public {@code GET /api/rooms/{roomId}/pricing} endpoint,
     * {@code PartnerPricingService} and {@code CustomerCouponService}. Behaviour unchanged.
     */
    public PricingBreakdownResponse calculate(Long roomId,
                                               LocalDate checkIn,
                                               LocalDate checkOut) {
        return calculate(roomId, checkIn, checkOut, false, null, null);
    }

    /**
     * Phase 7.30 — checkout pricing driven by an EXTERNALLY resolved rate plan.
     *
     * <p>Called from {@code BookingService.create()} with the full resolved per-stay subtotal
     * produced by {@link RatePlanPricingService} (base nightly + derived adjustment + occupancy /
     * child / extra-bed supplements, already multiplied by nights). This SKIPS the internal
     * Step-2 min-price selection and uses the supplied value as the rate-plan price, then flows
     * through the SAME promotion-discount logic (Steps 3–4) as the 3-arg overload — so the amount
     * charged is consistent with the rate-plan snapshotted onto the booking.
     *
     * @param resolvedRatePlanSubtotal the resolved stay subtotal, or {@code null} to fall back to
     *                                 the base room price (matches the "no eligible plan" case).
     * @param resolvedRatePlanName     display name of the resolved plan, or {@code null}.
     */
    public PricingBreakdownResponse calculate(Long roomId,
                                               LocalDate checkIn,
                                               LocalDate checkOut,
                                               BigDecimal resolvedRatePlanSubtotal,
                                               String resolvedRatePlanName) {
        return calculate(roomId, checkIn, checkOut, true, resolvedRatePlanSubtotal, resolvedRatePlanName);
    }

    private PricingBreakdownResponse calculate(Long roomId,
                                               LocalDate checkIn,
                                               LocalDate checkOut,
                                               boolean useResolvedRatePlan,
                                               BigDecimal resolvedRatePlanSubtotal,
                                               String resolvedRatePlanName) {
        if (!checkOut.isAfter(checkIn)) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut must be after checkIn");
        }
        if (checkIn.isBefore(LocalDate.now())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn cannot be in the past");
        }

        HotelRoom room = roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));

        long nights    = ChronoUnit.DAYS.between(checkIn, checkOut);
        LocalDate lastNight = checkOut.minusDays(1);

        // ── Step 1: Base price ────────────────────────────────────────────────
        BigDecimal priceFrom = room.getPriceFrom() != null
            ? room.getPriceFrom() : BigDecimal.ZERO;
        BigDecimal basePrice = priceFrom.multiply(BigDecimal.valueOf(nights));

        // ── Step 2: Rate plan price ───────────────────────────────────────────
        BigDecimal ratePlanPrice;
        String ratePlanName;
        if (useResolvedRatePlan) {
            // Phase 7.30 — trust the externally resolved plan/subtotal; no internal selection.
            ratePlanPrice = resolvedRatePlanSubtotal;
            ratePlanName  = resolvedRatePlanName;
        } else {
            List<RatePlan> plans = ratePlanRepo.findActiveForStay(roomId, checkIn, lastNight);
            Optional<RatePlan> bestPlan = plans.stream()
                .min(Comparator.comparing(RatePlan::getPricePerNight));

            BigDecimal ratePlanNightly = bestPlan.map(RatePlan::getPricePerNight).orElse(null);
            ratePlanPrice = ratePlanNightly != null
                ? ratePlanNightly.multiply(BigDecimal.valueOf(nights)) : null;
            ratePlanName = bestPlan.map(RatePlan::getRateName).orElse(null);
        }

        BigDecimal workingPrice = ratePlanPrice != null ? ratePlanPrice : basePrice;

        // ── Step 3: Promotions ────────────────────────────────────────────────
        List<Promotion> candidates = promotionRepo.findActiveForDateRange(checkIn, lastNight);
        List<Promotion> applicable = candidates.stream()
            .filter(p -> isApplicable(p, room, nights, workingPrice))
            .sorted(Comparator.comparingInt(Promotion::getPriority).reversed())
            .toList();

        BigDecimal totalDiscount = BigDecimal.ZERO;
        List<PromotionSummaryResponse> appliedList = new ArrayList<>();

        for (Promotion promo : applicable) {
            BigDecimal disc = computeDiscount(promo, workingPrice);
            totalDiscount = totalDiscount.add(disc);
            appliedList.add(new PromotionSummaryResponse(
                promo.getId(),
                promo.getName(),
                promo.getCode(),
                promo.getDiscountType(),
                promo.getDiscountValue(),
                disc
            ));
            if (!promo.isStackable()) break;
        }

        // ── Step 4: Final price ───────────────────────────────────────────────
        BigDecimal finalPrice = workingPrice.subtract(totalDiscount)
            .max(BigDecimal.ZERO)
            .setScale(2, RoundingMode.HALF_UP);

        return new PricingBreakdownResponse(
            roomId,
            room.getRoomName(),
            room.getRoomCode(),
            checkIn,
            checkOut,
            (int) nights,
            basePrice.setScale(2, RoundingMode.HALF_UP),
            ratePlanPrice != null ? ratePlanPrice.setScale(2, RoundingMode.HALF_UP) : null,
            ratePlanName,
            totalDiscount.setScale(2, RoundingMode.HALF_UP),
            finalPrice,
            "VND",
            appliedList
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private boolean isApplicable(Promotion p, HotelRoom room, long nights, BigDecimal workingPrice) {
        switch (p.getTargetType()) {
            case HOTEL -> {
                Long hotelDetailId = room.getHotelDetail() != null
                    ? room.getHotelDetail().getId() : null;
                if (!p.getTargetId().equals(hotelDetailId)) return false;
            }
            case ROOM -> {
                if (!p.getTargetId().equals(room.getId())) return false;
            }
            default -> { /* ALL — no target filter */ }
        }
        if (p.getMinimumStay() != null && nights < p.getMinimumStay()) return false;
        if (p.getMinimumSpend() != null && workingPrice.compareTo(p.getMinimumSpend()) < 0) return false;
        return true;
    }

    private BigDecimal computeDiscount(Promotion p, BigDecimal price) {
        if (p.getDiscountType() == DiscountType.PERCENTAGE) {
            BigDecimal disc = price.multiply(p.getDiscountValue())
                .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);
            if (p.getMaxDiscountAmount() != null) {
                disc = disc.min(p.getMaxDiscountAmount());
            }
            return disc;
        } else {
            // FIXED_AMOUNT — never exceed remaining price
            return p.getDiscountValue().min(price);
        }
    }
}
