package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TripReminderDeliveryDto.DueReminderResponse;
import com.example.planyourtrip.dto.TripReminderDeliveryDto.TripReminderDeliveryResultResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RelatedEntityType;
import com.example.planyourtrip.model.TripPlanReminder;
import com.example.planyourtrip.model.TripPlanReminderStatus;
import com.example.planyourtrip.repository.TripPlanReminderRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

/**
 * Phase 7.11 — Reminder Delivery Foundation.
 * Delivers due {@link TripPlanReminder}s into the existing in-app Notification
 * system. Deliberately out of scope: email, Firebase/push, WebSocket delivery,
 * and a real background scheduler — this is the delivery engine plus a manual
 * admin/test trigger only (see AdminTripReminderController).
 */
@Service
public class TripReminderDeliveryService {

    private final TripPlanReminderRepository reminderRepo;
    private final NotificationService notificationService;

    public TripReminderDeliveryService(TripPlanReminderRepository reminderRepo,
                                        NotificationService notificationService) {
        this.reminderRepo = reminderRepo;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<DueReminderResponse> getDueReminders(Long userId) {
        return reminderRepo.findByUserIdAndStatusAndReminderAtLessThanEqualAndDeliveredAtIsNullOrderByReminderAtAsc(
                userId, TripPlanReminderStatus.PENDING, Instant.now())
            .stream().map(this::toDueResponse).toList();
    }

    @Transactional
    public TripReminderDeliveryResultResponse deliverDueReminders() {
        List<TripPlanReminder> due = reminderRepo
            .findByStatusAndReminderAtLessThanEqualAndDeliveredAtIsNullOrderByReminderAtAsc(
                TripPlanReminderStatus.PENDING, Instant.now());

        int delivered = 0, failed = 0, skipped = 0;
        for (TripPlanReminder r : due) {
            switch (deliverOne(r)) {
                case DELIVERED -> delivered++;
                case FAILED -> failed++;
                case SKIPPED -> skipped++;
            }
        }
        return new TripReminderDeliveryResultResponse(due.size(), delivered, failed, skipped);
    }

    @Transactional
    public TripReminderDeliveryResultResponse deliverReminder(Long reminderId) {
        TripPlanReminder r = reminderRepo.findById(reminderId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Reminder not found: " + reminderId));

        DeliveryOutcome outcome = deliverOne(r);
        return new TripReminderDeliveryResultResponse(
            1,
            outcome == DeliveryOutcome.DELIVERED ? 1 : 0,
            outcome == DeliveryOutcome.FAILED ? 1 : 0,
            outcome == DeliveryOutcome.SKIPPED ? 1 : 0
        );
    }

    // ── Delivery engine ──────────────────────────────────────────────────────

    private enum DeliveryOutcome { DELIVERED, FAILED, SKIPPED }

    /**
     * Delivers a single reminder. Idempotent: a reminder whose deliveredAt is
     * already set is skipped without incrementing attempts or creating a
     * duplicate notification. On success, deliveredAt is stamped and
     * lastDeliveryError cleared. On failure, the exception message is
     * recorded. deliveryAttempts is incremented on every real attempt
     * (success or failure), but never on a skip. Reminder.status is left
     * untouched either way — delivery is independent of completion/cancellation.
     */
    private DeliveryOutcome deliverOne(TripPlanReminder r) {
        if (r.getDeliveredAt() != null) {
            return DeliveryOutcome.SKIPPED;
        }

        r.setDeliveryAttempts(r.getDeliveryAttempts() + 1);
        try {
            String message = r.getMessage() != null && !r.getMessage().isBlank() ? r.getMessage() : r.getTitle();
            // Phase 7.13: a wallet-expiry reminder for a wallet item with no linked trip has a
            // null tripPlan (see TripPlanReminder#tripPlan) — fall back to no related entity
            // rather than NPE-ing on getTripPlan().getId().
            notificationService.create(
                r.getUser().getId(),
                NotificationType.TRIP,
                Priority.NORMAL,
                r.getTitle(),
                message,
                r.getTripPlan() != null ? RelatedEntityType.TRIP : null,
                r.getTripPlan() != null ? r.getTripPlan().getId() : null
            );
            r.setDeliveredAt(Instant.now());
            r.setLastDeliveryError(null);
            reminderRepo.save(r);
            return DeliveryOutcome.DELIVERED;
        } catch (Exception e) {
            r.setLastDeliveryError(e.getMessage());
            reminderRepo.save(r);
            return DeliveryOutcome.FAILED;
        }
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private DueReminderResponse toDueResponse(TripPlanReminder r) {
        return new DueReminderResponse(
            r.getId(), r.getTripPlan() != null ? r.getTripPlan().getId() : null, r.getUser().getId(),
            r.getReminderType().name(), r.getTitle(), r.getMessage(), r.getReminderAt(),
            r.getStatus().name(), r.getDeliveryAttempts(), r.getLastDeliveryError()
        );
    }
}
