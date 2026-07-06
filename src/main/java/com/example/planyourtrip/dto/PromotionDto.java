package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.DiscountType;
import com.example.planyourtrip.model.PromotionTargetType;
import com.example.planyourtrip.model.PromotionType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class PromotionDto {

    public record PromotionRequest(
        @NotBlank String name,
        String code,
        String description,
        @NotNull PromotionType promotionType,
        @NotNull DiscountType discountType,
        @NotNull @DecimalMin("0.0") BigDecimal discountValue,
        @DecimalMin("0.0") BigDecimal maxDiscountAmount,
        @Min(1) Integer minimumStay,
        @DecimalMin("0.0") BigDecimal minimumSpend,
        boolean stackable,
        int priority,
        @NotNull LocalDate startDate,
        @NotNull LocalDate endDate,
        Boolean active,
        PromotionTargetType targetType,
        Long targetId
    ) {}

    public record PromotionResponse(
        Long id,
        String name,
        String code,
        String description,
        boolean active,
        LocalDate startDate,
        LocalDate endDate,
        PromotionType promotionType,
        DiscountType discountType,
        BigDecimal discountValue,
        BigDecimal maxDiscountAmount,
        Integer minimumStay,
        BigDecimal minimumSpend,
        boolean stackable,
        int priority,
        PromotionTargetType targetType,
        Long targetId,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record PromotionSummaryResponse(
        Long promotionId,
        String name,
        String code,
        DiscountType discountType,
        BigDecimal discountValue,
        BigDecimal discountApplied
    ) {}

    public record PricingBreakdownResponse(
        Long roomId,
        String roomName,
        String roomCode,
        LocalDate checkIn,
        LocalDate checkOut,
        int nights,
        BigDecimal basePrice,
        BigDecimal ratePlanPrice,
        String ratePlanName,
        BigDecimal promotionDiscount,
        BigDecimal finalPrice,
        String currency,
        List<PromotionSummaryResponse> appliedPromotions
    ) {}
}
