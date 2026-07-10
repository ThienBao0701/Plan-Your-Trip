package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.TravelWalletDto.TravelWalletItemResponse;

import java.util.List;
import java.util.Map;

/**
 * Phase 7.13 — Wallet Expiry Alerts &amp; Smart Organizer.
 * All groups below are computed at query time from {@code TravelWalletItem}
 * (plus its already-linked records) — there are no new organizer tables, and
 * every item embedded here is the same {@code TravelWalletItemResponse}
 * mapping used by the plain CRUD endpoints (no separate remap).
 */
public class TravelWalletOrganizerDto {

    /**
     * {@code favorites}/{@code expiringSoon}/{@code upcoming}/{@code active}/{@code expired}
     * all exclude archived items by default (archived items only ever appear in
     * {@code archived} here). {@code byType} is keyed by {@code walletItemType}
     * name; {@code byTrip} is keyed by {@code tripPlan} id (as a string) and only
     * contains items that have a linked trip. Both {@code byType} and
     * {@code byTrip} intentionally include archived items too, since they act as
     * a full index rather than an "active items" view.
     */
    public record TravelWalletOrganizerResponse(
        List<TravelWalletItemResponse> favorites,
        List<TravelWalletItemResponse> expiringSoon,
        List<TravelWalletItemResponse> upcoming,
        List<TravelWalletItemResponse> active,
        List<TravelWalletItemResponse> expired,
        List<TravelWalletItemResponse> archived,
        Map<String, List<TravelWalletItemResponse>> byType,
        Map<String, List<TravelWalletItemResponse>> byTrip
    ) {}

    /**
     * Dashboard-style counts. {@code activeItems}/{@code upcomingItems}/
     * {@code expiringSoonItems}/{@code expiredItems} exclude archived items;
     * {@code totalItems}/{@code favoriteItems}/{@code countsByType} do not.
     * {@code unlinkedItems} counts items with no {@code tripPlanDocument},
     * {@code booking}, {@code invoice} AND no {@code tripPlan} (metadata-only).
     */
    public record TravelWalletSummaryMetrics(
        long totalItems,
        long activeItems,
        long upcomingItems,
        long expiringSoonItems,
        long expiredItems,
        long archivedItems,
        long favoriteItems,
        long unlinkedItems,
        Map<String, Long> countsByType,
        Map<String, Long> countsByTrip
    ) {}

    /** Generic named-group wrapper used by the dedicated /expiring-soon, /expired, /upcoming, /unlinked endpoints. */
    public record TravelWalletGroupResponse(
        String group,
        long count,
        List<TravelWalletItemResponse> items
    ) {}

    /**
     * Outcome of an expiry-reminder generation trigger — mirrors the shape of
     * {@code TripReminderDeliveryDto.TripReminderDeliveryResultResponse} from
     * Phase 7.11. {@code remindersSkipped} covers both "already exists"
     * (idempotency) and "computed reminderAt already in the past" skips —
     * generation never fails outright (no OCR/network calls involved), so
     * there is no separate failed count.
     */
    public record WalletExpiryReminderResultResponse(
        int usersProcessed,
        int itemsProcessed,
        int remindersCreated,
        int remindersSkipped
    ) {}
}
