package com.example.planyourtrip.controller;

import com.example.planyourtrip.model.PaymentStatus;

import com.example.planyourtrip.dto.PageResponse;

import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.dto.PaymentDto.*;
import com.example.planyourtrip.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/payments")
@Tag(name = "Admin - Payment")
public class AdminPaymentController {

    private final PaymentService service;

    public AdminPaymentController(PaymentService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all payments")
    public PageResponse<PaymentResponse> getAll(
            @RequestParam(required = false) PaymentStatus status,
            @RequestParam(required = false) Long bookingId,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sort) {
        return service.adminListPaymentsPaged(status, bookingId, page, size, sort);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get payment by ID")
    public PaymentResponse getById(@PathVariable Long id) {
        return service.adminGetPayment(id);
    }

    @PostMapping("/{id}/refund")
    @Operation(summary = "Refund a PAID payment")
    public PaymentResponse refund(@AuthUser Long uid, @PathVariable Long id,
                                   @RequestBody(required = false) RefundRequest req) {
        return service.refund(uid, id, req);
    }
}
