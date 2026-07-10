package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripReminderDeliveryDto.DueReminderResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripReminderDeliveryService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Phase 7.11 — Reminder Delivery Foundation (user-facing side).
 * Kept as its own controller (rather than added to Phase 7.10's
 * TripReminderController) to avoid touching an already-shipped file.
 */
@RestController
@RequestMapping("/api/me/trips/reminders")
@Tag(name = "Customer - Trip Reminder Delivery", description = "Due reminders scoped to the current user")
@SecurityRequirement(name = "bearerAuth")
public class TripReminderDeliveryController {

    private final TripReminderDeliveryService deliveryService;

    public TripReminderDeliveryController(TripReminderDeliveryService deliveryService) {
        this.deliveryService = deliveryService;
    }

    @GetMapping("/due")
    @Operation(summary = "List the current user's own due reminders",
        description = "PENDING reminders whose reminderAt has passed and that have not yet been delivered.")
    public List<DueReminderResponse> due(@AuthUser Long uid) {
        return deliveryService.getDueReminders(uid);
    }
}
