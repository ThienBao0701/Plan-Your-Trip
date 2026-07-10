package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.TravelWalletItem;
import com.example.planyourtrip.model.TravelWalletItemType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface TravelWalletItemRepository extends JpaRepository<TravelWalletItem, Long> {

    List<TravelWalletItem> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<TravelWalletItem> findByIdAndUserId(Long id, Long userId);

    Optional<TravelWalletItem> findByUserIdAndTripPlanDocumentId(Long userId, Long tripPlanDocumentId);

    Optional<TravelWalletItem> findByUserIdAndBookingId(Long userId, Long bookingId);

    Optional<TravelWalletItem> findByUserIdAndInvoiceId(Long userId, Long invoiceId);

    // ── Phase 7.13 — Wallet Expiry Alerts & Smart Organizer ──────────────────

    /** Bounded window lookup for the "expiring soon" group/endpoint (one query, no N+1). */
    List<TravelWalletItem> findByUserIdAndValidUntilBetween(Long userId, LocalDate from, LocalDate to);

    List<TravelWalletItem> findByUserIdAndArchived(Long userId, boolean archived);

    List<TravelWalletItem> findByUserIdAndWalletItemType(Long userId, TravelWalletItemType type);

    List<TravelWalletItem> findByUserIdAndTripPlanId(Long userId, Long tripPlanId);

    /** Per-user candidate set for expiry-reminder generation — one bounded query, grouping done in-memory. */
    List<TravelWalletItem> findByUserIdAndValidUntilIsNotNullAndExpiryReminderEnabledTrue(Long userId);

    /** System-wide candidate set for the admin "generate for all users" trigger — one bounded query, grouped by user in-memory. */
    List<TravelWalletItem> findByValidUntilIsNotNullAndExpiryReminderEnabledTrue();
}
