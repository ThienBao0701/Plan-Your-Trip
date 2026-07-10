package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TravelWalletOrganizerDto.WalletExpiryReminderResultResponse;
import com.example.planyourtrip.model.TravelWalletItem;
import com.example.planyourtrip.model.TripPlanReminder;
import com.example.planyourtrip.model.TripPlanReminderType;
import com.example.planyourtrip.repository.TravelWalletItemRepository;
import com.example.planyourtrip.repository.TripPlanReminderRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Phase 7.13 — Wallet Expiry Alerts &amp; Smart Organizer.
 * Generates {@link TripPlanReminder} rows for {@link TravelWalletItem}s
 * approaching their {@code validUntil} date. Deliberately NOT a second
 * reminder engine: every row this creates is a plain {@code TripPlanReminder},
 * later delivered by the existing {@code TripReminderDeliveryService} (Phase
 * 7.11) exactly like a user-created one — this class only ever inserts rows,
 * it never sends anything itself. No scheduler is wired up here; every entry
 * point is a manual/on-demand trigger (see {@code TravelWalletController} and
 * {@code AdminWalletExpiryController}).
 */
@Service
public class WalletExpiryReminderService {

    /** 30/7/1 days before {@code validUntil} — see phase spec's exact reminder titles below. */
    private static final int[] WINDOWS_DAYS = {30, 7, 1};
    private static final LocalTime REMINDER_TIME_OF_DAY = LocalTime.of(9, 0);

    private final TravelWalletItemRepository walletRepo;
    private final TripPlanReminderRepository reminderRepo;
    private final TravelWalletService walletService;

    public WalletExpiryReminderService(TravelWalletItemRepository walletRepo,
                                        TripPlanReminderRepository reminderRepo,
                                        TravelWalletService walletService) {
        this.walletRepo = walletRepo;
        this.reminderRepo = reminderRepo;
        this.walletService = walletService;
    }

    // ── Entry points ──────────────────────────────────────────────────────

    @Transactional
    public WalletExpiryReminderResultResponse generateExpiryRemindersForUser(Long userId) {
        List<TravelWalletItem> items = walletRepo.findByUserIdAndValidUntilIsNotNullAndExpiryReminderEnabledTrue(userId);
        GenTotals totals = generateForAll(items);
        return new WalletExpiryReminderResultResponse(1, totals.itemsProcessed, totals.created, totals.skipped);
    }

    @Transactional
    public WalletExpiryReminderResultResponse generateExpiryRemindersForAllUsers() {
        List<TravelWalletItem> items = walletRepo.findByValidUntilIsNotNullAndExpiryReminderEnabledTrue();
        Set<Long> userIds = items.stream().map(i -> i.getUser().getId()).collect(Collectors.toSet());
        GenTotals totals = generateForAll(items);
        return new WalletExpiryReminderResultResponse(userIds.size(), totals.itemsProcessed, totals.created, totals.skipped);
    }

    /** Ownership-enforced single-item generation — another user's wallet item id yields a 404 (via {@code TravelWalletService#ownedItemOrThrow}). */
    @Transactional
    public WalletExpiryReminderResultResponse generateForWalletItem(Long userId, Long walletItemId) {
        TravelWalletItem item = walletService.ownedItemOrThrow(userId, walletItemId);
        GenTotals totals = generateForAll(List.of(item));
        return new WalletExpiryReminderResultResponse(1, totals.itemsProcessed, totals.created, totals.skipped);
    }

    /** Items expiring within the next 30 days (and not already expired), excluding archived — for callers that only need the raw entity list. */
    @Transactional(readOnly = true)
    public List<TravelWalletItem> getExpiringSoonForUser(Long userId) {
        LocalDate today = LocalDate.now();
        return walletRepo.findByUserIdAndValidUntilBetween(userId, today, today.plusDays(30)).stream()
            .filter(i -> !i.isArchived())
            .toList();
    }

    // ── Generation engine ─────────────────────────────────────────────────

    private record GenTotals(int itemsProcessed, int created, int skipped) {}

    private GenTotals generateForAll(List<TravelWalletItem> items) {
        int created = 0, skipped = 0;
        for (TravelWalletItem item : items) {
            int[] r = generateForItem(item);
            created += r[0];
            skipped += r[1];
        }
        return new GenTotals(items.size(), created, skipped);
    }

    /**
     * Attempts all three reminder windows for one item. Returns {@code [created, skipped]}.
     * Skips (without creating) when: {@code validUntil} is null, {@code expiryReminderEnabled}
     * is false, the computed {@code reminderAt} for that window is already in the past, or a
     * reminder with the same deterministic {@code sourceKey} already exists (idempotency —
     * see {@code TripPlanReminder#sourceKey}).
     */
    private int[] generateForItem(TravelWalletItem item) {
        if (item.getValidUntil() == null || !item.isExpiryReminderEnabled()) {
            return new int[]{0, 0};
        }

        Instant now = Instant.now();
        int created = 0, skipped = 0;

        for (int windowDays : WINDOWS_DAYS) {
            Instant reminderAt = item.getValidUntil().minusDays(windowDays)
                .atTime(REMINDER_TIME_OF_DAY)
                .atZone(ZoneId.systemDefault())
                .toInstant();

            if (reminderAt.isBefore(now)) {
                skipped++;
                continue;
            }

            String sourceKey = sourceKey(item.getId(), windowDays);
            if (reminderRepo.findBySourceKey(sourceKey).isPresent()) {
                skipped++;
                continue;
            }

            TripPlanReminder reminder = new TripPlanReminder();
            reminder.setTripPlan(item.getTripPlan()); // nullable — see TripPlanReminder#tripPlan javadoc (Phase 7.13)
            reminder.setUser(item.getUser());
            reminder.setReminderType(TripPlanReminderType.DOCUMENT);
            reminder.setTitle(titleFor(windowDays));
            reminder.setMessage(buildMessage(item));
            reminder.setReminderAt(reminderAt);
            reminder.setSourceType("WALLET_EXPIRY");
            reminder.setSourceId(item.getId());
            reminder.setSourceKey(sourceKey);

            try {
                reminderRepo.save(reminder);
                created++;
            } catch (DataIntegrityViolationException e) {
                // Concurrent generation race on the unique sourceKey constraint — treat as an idempotent skip.
                skipped++;
            }
        }

        return new int[]{created, skipped};
    }

    private String sourceKey(Long walletItemId, int windowDays) {
        return "WALLET_EXPIRY:" + walletItemId + ":" + windowDays;
    }

    private String titleFor(int windowDays) {
        return switch (windowDays) {
            case 30 -> "Travel document expires in 30 days";
            case 7 -> "Travel document expires in 7 days";
            case 1 -> "Travel document expires tomorrow";
            default -> throw new IllegalStateException("Unsupported reminder window: " + windowDays);
        };
    }

    /**
     * Includes {@code displayTitle} and {@code walletItemType} only — deliberately never
     * {@code referenceNumberMasked} (or any reference value, masked or raw), per the phase's
     * "no reference data anywhere in reminder messages" constraint.
     */
    private String buildMessage(TravelWalletItem item) {
        return "Your " + item.getWalletItemType().name() + " \"" + item.getDisplayTitle()
            + "\" is expiring soon. Check your Travel Wallet for details.";
    }
}
