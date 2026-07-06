package com.example.planyourtrip.controller;

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
    public List<PaymentResponse> getAll() {
        return service.adminListPayments();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get payment by ID")
    public PaymentResponse getById(@PathVariable Long id) {
        return service.adminGetPayment(id);
    }

    @PostMapping("/{id}/refund")
    @Operation(summary = "Refund a PAID payment")
    public PaymentResponse refund(@PathVariable Long id,
                                   @RequestBody(required = false) RefundRequest req) {
        return service.refund(id, req);
    }
}
