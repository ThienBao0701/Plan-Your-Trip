package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.TripPlanExpenseCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public class TripPlanBudgetDto {

    public record TripPlanBudgetRequest(
        @NotNull BigDecimal totalBudget,
        @NotBlank String currency,
        String notes
    ) {}

    public record TripPlanBudgetResponse(
        Long id,
        Long tripPlanId,
        BigDecimal totalBudget,
        String currency,
        String notes,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record TripPlanExpenseRequest(
        Long tripDayId,
        Long tripItemId,
        @NotNull TripPlanExpenseCategory category,
        @NotNull BigDecimal amount,
        @NotBlank String currency,
        @NotBlank String title,
        String notes,
        @NotNull LocalDate expenseDate
    ) {}

    public record TripPlanExpenseResponse(
        Long id,
        Long tripPlanId,
        Long tripDayId,
        Long tripItemId,
        Long paidByUserId,
        String paidByUserName,
        String category,
        BigDecimal amount,
        String currency,
        String title,
        String notes,
        LocalDate expenseDate,
        Instant createdAt,
        Instant updatedAt
    ) {}

    public record ExpenseCategoryBreakdown(
        String category,
        BigDecimal totalAmount
    ) {}

    public record TripPlanBudgetSummaryResponse(
        Long tripPlanId,
        BigDecimal totalBudget,
        BigDecimal totalSpent,
        BigDecimal remainingBudget,
        boolean overBudget,
        List<ExpenseCategoryBreakdown> categoryBreakdown
    ) {}
}
