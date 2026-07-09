package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripPlanBudgetDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Trip budget and expense tracking. Mirrors {@code TripPlannerService}'s
 * three-tier permission model (owner / active EDITOR collaborator / active VIEWER
 * collaborator) via its own small, independently-duplicated ownership checks —
 * matching the established per-service convention rather than a shared utility —
 * except that budget mutation is strictly owner-only (expenses allow EDITOR too).
 */
@Service
public class TripPlanBudgetService {

    private final TripPlanRepository tripRepo;
    private final TripPlanDayRepository dayRepo;
    private final TripPlanItemRepository itemRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanBudgetRepository budgetRepo;
    private final TripPlanExpenseRepository expenseRepo;
    private final UserRepository userRepo;

    public TripPlanBudgetService(TripPlanRepository tripRepo,
                                  TripPlanDayRepository dayRepo,
                                  TripPlanItemRepository itemRepo,
                                  TripPlanCollaboratorRepository collaboratorRepo,
                                  TripPlanBudgetRepository budgetRepo,
                                  TripPlanExpenseRepository expenseRepo,
                                  UserRepository userRepo) {
        this.tripRepo = tripRepo;
        this.dayRepo = dayRepo;
        this.itemRepo = itemRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.budgetRepo = budgetRepo;
        this.expenseRepo = expenseRepo;
        this.userRepo = userRepo;
    }

    // ── Budget (owner-only mutation) ─────────────────────────────────────────

    @Transactional(readOnly = true)
    public TripPlanBudgetResponse getBudget(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        TripPlanBudget budget = budgetRepo.findByTripPlanId(trip.getId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Budget not set for this trip"));
        return toBudgetResponse(budget);
    }

    @Transactional
    public TripPlanBudgetResponse upsertBudget(Long userId, Long tripId, TripPlanBudgetRequest req) {
        TripPlan trip = myTripOrThrow(userId, tripId);
        validateAmount(req.totalBudget());
        validateCurrency(req.currency());

        TripPlanBudget budget = budgetRepo.findByTripPlanId(trip.getId()).orElseGet(() -> {
            TripPlanBudget b = new TripPlanBudget();
            b.setTripPlan(trip);
            return b;
        });
        budget.setTotalBudget(req.totalBudget());
        budget.setCurrency(req.currency());
        budget.setNotes(req.notes());
        return toBudgetResponse(budgetRepo.save(budget));
    }

    @Transactional
    public void deleteBudget(Long userId, Long tripId) {
        TripPlan trip = myTripOrThrow(userId, tripId);
        budgetRepo.deleteByTripPlanId(trip.getId());
    }

    // ── Expenses (owner or EDITOR mutation) ──────────────────────────────────

    @Transactional
    public TripPlanExpenseResponse addExpense(Long userId, Long tripId, TripPlanExpenseRequest req) {
        TripPlan trip = editableTripOrThrow(userId, tripId);
        validateAmount(req.amount());
        validateCurrency(req.currency());
        TripPlanDay day = resolveSameTripDayOrNull(trip.getId(), req.tripDayId());
        TripPlanItem item = resolveSameTripItemOrNull(trip.getId(), req.tripItemId());
        User payer = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TripPlanExpense expense = new TripPlanExpense();
        expense.setTripPlan(trip);
        expense.setTripDay(day);
        expense.setTripItem(item);
        expense.setPaidByUser(payer);
        applyExpenseRequest(expense, req);
        return toExpenseResponse(expenseRepo.save(expense));
    }

    @Transactional
    public TripPlanExpenseResponse updateExpense(Long userId, Long expenseId, TripPlanExpenseRequest req) {
        TripPlanExpense expense = editableExpenseOrThrow(userId, expenseId);
        validateAmount(req.amount());
        validateCurrency(req.currency());
        Long tripId = expense.getTripPlan().getId();
        expense.setTripDay(resolveSameTripDayOrNull(tripId, req.tripDayId()));
        expense.setTripItem(resolveSameTripItemOrNull(tripId, req.tripItemId()));
        applyExpenseRequest(expense, req);
        return toExpenseResponse(expenseRepo.save(expense));
    }

    @Transactional
    public void deleteExpense(Long userId, Long expenseId) {
        TripPlanExpense expense = editableExpenseOrThrow(userId, expenseId);
        expenseRepo.delete(expense);
    }

    @Transactional(readOnly = true)
    public List<TripPlanExpenseResponse> listExpenses(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        return expenseRepo.findByTripPlanIdOrderByExpenseDateDescCreatedAtDesc(trip.getId())
            .stream().map(this::toExpenseResponse).toList();
    }

    @Transactional(readOnly = true)
    public TripPlanExpenseResponse getExpense(Long userId, Long expenseId) {
        return toExpenseResponse(viewableExpenseOrThrow(userId, expenseId));
    }

    // ── Summary ───────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public TripPlanBudgetSummaryResponse getBudgetSummary(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        BigDecimal totalBudget = budgetRepo.findByTripPlanId(trip.getId())
            .map(TripPlanBudget::getTotalBudget).orElse(BigDecimal.ZERO);
        List<TripPlanExpense> expenses = expenseRepo.findByTripPlanIdOrderByExpenseDateDescCreatedAtDesc(trip.getId());

        BigDecimal totalSpent = expenses.stream()
            .map(TripPlanExpense::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal remaining = totalBudget.subtract(totalSpent);
        boolean overBudget = totalSpent.compareTo(totalBudget) > 0;

        Map<TripPlanExpenseCategory, BigDecimal> byCategory = expenses.stream()
            .collect(Collectors.groupingBy(TripPlanExpense::getCategory,
                Collectors.reducing(BigDecimal.ZERO, TripPlanExpense::getAmount, BigDecimal::add)));
        List<ExpenseCategoryBreakdown> breakdown = byCategory.entrySet().stream()
            .map(e -> new ExpenseCategoryBreakdown(e.getKey().name(), e.getValue()))
            .sorted(Comparator.comparing(ExpenseCategoryBreakdown::category))
            .toList();

        return new TripPlanBudgetSummaryResponse(trip.getId(), totalBudget, totalSpent, remaining, overBudget, breakdown);
    }

    // ── Permission helpers (duplicated from TripPlannerService by convention) ──

    private TripPlan myTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        if (!isOwner(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Only the trip owner can perform this action");
        return trip;
    }

    private TripPlan viewableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
        return trip;
    }

    private TripPlan editableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = viewableTripOrThrow(userId, tripId);
        if (!canEdit(trip, userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage expenses for this trip");
        return trip;
    }

    private TripPlanExpense viewableExpenseOrThrow(Long userId, Long expenseId) {
        TripPlanExpense expense = expenseRepo.findById(expenseId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Expense not found: " + expenseId));
        if (!canView(expense.getTripPlan(), userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Expense not found: " + expenseId);
        return expense;
    }

    private TripPlanExpense editableExpenseOrThrow(Long userId, Long expenseId) {
        TripPlanExpense expense = viewableExpenseOrThrow(userId, expenseId);
        if (!canEdit(expense.getTripPlan(), userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "You do not have permission to manage expenses for this trip");
        return expense;
    }

    private boolean isOwner(TripPlan trip, Long userId) {
        return trip.getUser().getId().equals(userId);
    }

    private boolean canView(TripPlan trip, Long userId) {
        if (isOwner(trip, userId)) return true;
        return collaboratorRepo.findByTripPlanIdAndUserId(trip.getId(), userId)
            .map(TripPlanCollaborator::isActive).orElse(false);
    }

    private boolean canEdit(TripPlan trip, Long userId) {
        if (isOwner(trip, userId)) return true;
        return collaboratorRepo.findByTripPlanIdAndUserId(trip.getId(), userId)
            .filter(TripPlanCollaborator::isActive)
            .map(c -> c.getRole() == TripCollaboratorRole.EDITOR)
            .orElse(false);
    }

    // ── Validation / mutation helpers ───────────────────────────────────────

    private void validateAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) < 0)
            throw new ApiException(HttpStatus.BAD_REQUEST, "Amount must be >= 0");
    }

    private void validateCurrency(String currency) {
        if (currency == null || currency.isBlank())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Currency is required");
    }

    private TripPlanDay resolveSameTripDayOrNull(Long tripId, Long dayId) {
        if (dayId == null) return null;
        TripPlanDay day = dayRepo.findById(dayId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip day not found: " + dayId));
        if (!day.getTripPlan().getId().equals(tripId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Trip day does not belong to this trip");
        return day;
    }

    private TripPlanItem resolveSameTripItemOrNull(Long tripId, Long itemId) {
        if (itemId == null) return null;
        TripPlanItem item = itemRepo.findById(itemId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip item not found: " + itemId));
        if (!item.getTripPlanDay().getTripPlan().getId().equals(tripId))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Trip item does not belong to this trip");
        return item;
    }

    private void applyExpenseRequest(TripPlanExpense expense, TripPlanExpenseRequest req) {
        expense.setCategory(req.category());
        expense.setAmount(req.amount());
        expense.setCurrency(req.currency());
        expense.setTitle(req.title());
        expense.setNotes(req.notes());
        expense.setExpenseDate(req.expenseDate());
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TripPlanBudgetResponse toBudgetResponse(TripPlanBudget b) {
        return new TripPlanBudgetResponse(
            b.getId(), b.getTripPlan().getId(), b.getTotalBudget(), b.getCurrency(), b.getNotes(),
            b.getCreatedAt(), b.getUpdatedAt()
        );
    }

    private TripPlanExpenseResponse toExpenseResponse(TripPlanExpense e) {
        return new TripPlanExpenseResponse(
            e.getId(), e.getTripPlan().getId(),
            e.getTripDay() != null ? e.getTripDay().getId() : null,
            e.getTripItem() != null ? e.getTripItem().getId() : null,
            e.getPaidByUser().getId(), e.getPaidByUser().getFullName(),
            e.getCategory().name(), e.getAmount(), e.getCurrency(), e.getTitle(), e.getNotes(),
            e.getExpenseDate(), e.getCreatedAt(), e.getUpdatedAt()
        );
    }
}
