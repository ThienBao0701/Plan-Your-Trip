package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PartnerFinanceDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerFinanceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/partner/finance")
@Tag(name = "Partner - Finance", description = "Read-only finance and settlement analytics for approved partners, scoped to hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerFinanceController {

    private final PartnerFinanceService service;

    public PartnerFinanceController(PartnerFinanceService service) { this.service = service; }

    @GetMapping("/overview")
    @Operation(summary = "Finance overview: gross/net revenue, commission, tax estimate, settlement status")
    public PartnerFinanceOverviewResponse overview(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getOverview(uid, hotelId, from, to);
    }

    @GetMapping("/revenue")
    @Operation(summary = "Revenue by day/month/hotel/room, average and highest booking value")
    public PartnerRevenueResponse revenue(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getRevenue(uid, hotelId, from, to);
    }

    @GetMapping("/settlements")
    @Operation(summary = "Settlement status: current, last, pending, paid and full history")
    public PartnerSettlementResponse settlements(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getSettlement(uid, hotelId, from, to);
    }

    @GetMapping("/payouts")
    @Operation(summary = "Upcoming and completed payouts with an estimated next payout date")
    public PartnerPayoutResponse payouts(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getPayout(uid, hotelId, from, to);
    }

    @GetMapping("/commissions")
    @Operation(summary = "Gross / commission / net breakdown at the configured platform commission rate")
    public PartnerCommissionResponse commissions(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getCommission(uid, hotelId, from, to);
    }

    @GetMapping("/invoices")
    @Operation(summary = "Invoice counts by status and total invoiced amount")
    public PartnerInvoiceFinanceResponse invoices(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getInvoiceFinance(uid, hotelId, from, to);
    }

    @GetMapping("/refunds")
    @Operation(summary = "Refund count, amount and refund rate")
    public PartnerRefundResponse refunds(
            @AuthUser Long uid,
            @RequestParam(required = false) Long hotelId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return service.getRefund(uid, hotelId, from, to);
    }
}
