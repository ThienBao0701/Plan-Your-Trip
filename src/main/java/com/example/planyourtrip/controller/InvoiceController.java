package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.InvoiceDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.InvoiceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Invoice")
public class InvoiceController {

    private final InvoiceService service;

    public InvoiceController(InvoiceService service) { this.service = service; }

    @PostMapping("/api/invoices")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create an invoice for a paid booking/payment (owner only)")
    public InvoiceResponse create(@AuthUser Long uid, @RequestBody @Valid InvoiceRequest req) {
        return service.createInvoice(uid, req);
    }

    @GetMapping("/api/invoices/{id}")
    @Operation(summary = "Get invoice by ID (owner or admin)")
    public InvoiceResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getInvoice(uid, id);
    }

    @GetMapping("/api/bookings/{bookingId}/invoice")
    @Operation(summary = "Get invoice for a booking (owner or admin)")
    public InvoiceResponse getByBooking(@AuthUser Long uid, @PathVariable Long bookingId) {
        return service.getInvoiceByBooking(uid, bookingId);
    }

    @GetMapping("/api/me/invoices")
    @Operation(summary = "List current user's invoices")
    public List<InvoiceSummaryResponse> getMine(@AuthUser Long uid) {
        return service.listMine(uid);
    }
}
