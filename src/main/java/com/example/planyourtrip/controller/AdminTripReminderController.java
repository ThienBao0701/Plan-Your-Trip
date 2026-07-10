package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripReminderDeliveryDto.TripReminderDeliveryResultResponse;
import com.example.planyourtrip.service.TripReminderDeliveryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Phase 7.11 — Reminder Delivery Foundation (admin manual trigger).
 * No real scheduler is wired up in this phase; delivery is triggered manually
 * here. Access is restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code "/api/admin/**"} -> hasRole("ADMIN") rule, matching every other
 * admin controller in this codebase (no per-controller @PreAuthorize needed).
 */
@RestController
@RequestMapping("/api/admin/trip-reminders")
@Tag(name = "Admin - Trip Reminder Delivery")
public class AdminTripReminderController {

    private final TripReminderDeliveryService deliveryService;

    public AdminTripReminderController(TripReminderDeliveryService deliveryService) {
        this.deliveryService = deliveryService;
    }

    @PostMapping("/deliver-due")
    @Operation(summary = "Trigger delivery of all due reminders, system-wide")
    public TripReminderDeliveryResultResponse deliverDue() {
        return deliveryService.deliverDueReminders();
    }

    @PostMapping("/{id}/deliver")
    @Operation(summary = "Trigger delivery of a single reminder by id")
    public TripReminderDeliveryResultResponse deliverOne(@PathVariable Long id) {
        return deliveryService.deliverReminder(id);
    }
}
