package com.example.planyourtrip.dto;

import java.time.Instant;

/**
 * Phase 7.11 — Reminder Delivery Foundation.
 * DTOs for surfacing due reminders and delivery-trigger results. Delivery
 * itself only fans into the existing in-app Notification system (no
 * email/push/WebSocket/scheduler — see TripReminderDeliveryService).
 */
public class TripReminderDeliveryDto {

    /**
     * A reminder that is currently due (PENDING, reminderAt <= now, not yet
     * delivered). Extends {@code TripPlanTimelineDto.TripPlanReminderResponse}
     * with delivery-tracking fields since due reminders may carry prior failed
     * attempts worth surfacing to the caller.
     */
    public record DueReminderResponse(
        Long id,
        Long tripPlanId,
        Long userId,
        String reminderType,
        String title,
        String message,
        Instant reminderAt,
        String status,
        int deliveryAttempts,
        String lastDeliveryError
    ) {}

    /** Outcome of an admin delivery trigger — bulk or single. */
    public record TripReminderDeliveryResultResponse(
        int totalAttempted,
        int delivered,
        int failed,
        int skipped
    ) {}
}
