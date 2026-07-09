package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanBudgetDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripPlanBudgetService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Budget & Expenses", description = "Budget and expense tracking for a trip")
@SecurityRequirement(name = "bearerAuth")
public class TripBudgetController {

    private final TripPlanBudgetService service;

    public TripBudgetController(TripPlanBudgetService service) { this.service = service; }

    // ── Budget ────────────────────────────────────────────────────────────────

    @GetMapping("/{tripId}/budget")
    @Operation(summary = "Get a trip's budget")
    public TripPlanBudgetResponse getBudget(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.getBudget(uid, tripId);
    }

    @PutMapping("/{tripId}/budget")
    @Operation(summary = "Create or update a trip's budget (owner only)")
    public TripPlanBudgetResponse upsertBudget(@AuthUser Long uid, @PathVariable Long tripId,
                                                @Valid @RequestBody TripPlanBudgetRequest req) {
        return service.upsertBudget(uid, tripId, req);
    }

    @DeleteMapping("/{tripId}/budget")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a trip's budget (owner only)")
    public void deleteBudget(@AuthUser Long uid, @PathVariable Long tripId) {
        service.deleteBudget(uid, tripId);
    }

    // ── Expenses ──────────────────────────────────────────────────────────────

    @GetMapping("/{tripId}/expenses")
    @Operation(summary = "List a trip's expenses, newest expense date first")
    public List<TripPlanExpenseResponse> listExpenses(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.listExpenses(uid, tripId);
    }

    @PostMapping("/{tripId}/expenses")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Add an expense to a trip (owner or EDITOR collaborator)")
    public TripPlanExpenseResponse addExpense(@AuthUser Long uid, @PathVariable Long tripId,
                                               @Valid @RequestBody TripPlanExpenseRequest req) {
        return service.addExpense(uid, tripId, req);
    }

    @GetMapping("/expenses/{expenseId}")
    @Operation(summary = "Get a single expense")
    public TripPlanExpenseResponse getExpense(@AuthUser Long uid, @PathVariable Long expenseId) {
        return service.getExpense(uid, expenseId);
    }

    @PutMapping("/expenses/{expenseId}")
    @Operation(summary = "Update an expense (owner or EDITOR collaborator)")
    public TripPlanExpenseResponse updateExpense(@AuthUser Long uid, @PathVariable Long expenseId,
                                                  @Valid @RequestBody TripPlanExpenseRequest req) {
        return service.updateExpense(uid, expenseId, req);
    }

    @DeleteMapping("/expenses/{expenseId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete an expense (owner or EDITOR collaborator)")
    public void deleteExpense(@AuthUser Long uid, @PathVariable Long expenseId) {
        service.deleteExpense(uid, expenseId);
    }

    // ── Summary ───────────────────────────────────────────────────────────────

    @GetMapping("/{tripId}/budget-summary")
    @Operation(summary = "Get budget vs. actual spend summary with a per-category breakdown")
    public TripPlanBudgetSummaryResponse getBudgetSummary(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.getBudgetSummary(uid, tripId);
    }
}
