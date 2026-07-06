package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PaymentDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PaymentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Payment")
public class PaymentController {

    private final PaymentService service;

    public PaymentController(PaymentService service) { this.service = service; }

    @PostMapping("/api/payments")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a payment for a booking")
    public PaymentResponse create(@AuthUser Long uid,
                                   @RequestBody @Valid PaymentRequest req) {
        return service.createPayment(uid, req);
    }

    @GetMapping("/api/payments/{id}")
    @Operation(summary = "Get payment by ID (owner or admin)")
    public PaymentResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getPayment(uid, id);
    }

    @GetMapping("/api/bookings/{bookingId}/payments")
    @Operation(summary = "List payments for a booking (owner only)")
    public List<PaymentResponse> getByBooking(@AuthUser Long uid,
                                               @PathVariable Long bookingId) {
        return service.getPaymentsByBooking(uid, bookingId);
    }

    @PostMapping("/api/payments/{id}/mock-success")
    @Operation(summary = "Simulate successful payment (owner or admin)")
    public PaymentResponse mockSuccess(@AuthUser Long uid,
                                        @PathVariable Long id,
                                        @RequestBody(required = false) PaymentResultRequest req) {
        return service.mockSuccess(uid, id, req);
    }

    @PostMapping("/api/payments/{id}/mock-fail")
    @Operation(summary = "Simulate failed payment (owner or admin)")
    public PaymentResponse mockFail(@AuthUser Long uid,
                                     @PathVariable Long id,
                                     @RequestBody(required = false) PaymentResultRequest req) {
        return service.mockFail(uid, id, req);
    }
}
