package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.InvoiceDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.InvoiceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/invoices")
@Tag(name = "Admin - Invoice")
public class AdminInvoiceController {

    private final InvoiceService service;

    public AdminInvoiceController(InvoiceService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all invoices")
    public List<InvoiceResponse> getAll() {
        return service.adminList();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get invoice by ID")
    public InvoiceResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getInvoice(uid, id);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Force-set invoice status (admin override)")
    public InvoiceResponse updateStatus(@PathVariable Long id, @RequestBody @Valid InvoiceStatusRequest req) {
        return service.adminUpdateStatus(id, req.status());
    }

    @PatchMapping("/{id}/cancel")
    @Operation(summary = "Cancel an invoice (does not cancel the booking)")
    public InvoiceResponse cancel(@PathVariable Long id) {
        return service.cancelInvoice(id);
    }
}
