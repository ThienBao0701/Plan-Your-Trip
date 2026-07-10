package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TripPlanReminder;
import com.example.planyourtrip.model.TripPlanReminderStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface TripPlanReminderRepository extends JpaRepository<TripPlanReminder, Long> {

    List<TripPlanReminder> findByTripPlanIdOrderByReminderAtAsc(Long tripPlanId);

    void deleteByTripPlanId(Long tripPlanId);

    // ── Phase 7.11 — Reminder Delivery Foundation ──────────────────────────────

    /** System-wide due reminders: pending, past their reminderAt, not yet delivered. */
    List<TripPlanReminder> findByStatusAndReminderAtLessThanEqualAndDeliveredAtIsNullOrderByReminderAtAsc(
        TripPlanReminderStatus status, Instant now);

    /** Same as above, scoped to a single user (for the "my due reminders" endpoint). */
    List<TripPlanReminder> findByUserIdAndStatusAndReminderAtLessThanEqualAndDeliveredAtIsNullOrderByReminderAtAsc(
        Long userId, TripPlanReminderStatus status, Instant now);

    // ── Phase 7.13 — Wallet Expiry Alerts & Smart Organizer (idempotency) ─────

    /** Idempotency lookup — see {@code TripPlanReminder#sourceKey}. */
    Optional<TripPlanReminder> findBySourceKey(String sourceKey);

    boolean existsBySourceKey(String sourceKey);
}
