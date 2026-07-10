package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TravelWalletDto.TravelWalletItemResponse;
import com.example.planyourtrip.dto.TravelWalletOrganizerDto.*;
import com.example.planyourtrip.model.TravelWalletItem;
import com.example.planyourtrip.model.TravelWalletItemStatus;
import com.example.planyourtrip.repository.TravelWalletItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Phase 7.13 — Wallet Expiry Alerts &amp; Smart Organizer.
 * Read-only aggregation over {@link TravelWalletItem} — no new organizer
 * tables, every grouping is computed at query time from a single per-user
 * fetch. Deliberately kept separate from {@link TravelWalletService} (which
 * owns CRUD/ownership) but reuses its effective-status computation and
 * response mapping verbatim (both widened to package-private on that class
 * for exactly this purpose) rather than re-implementing them here.
 */
@Service
public class TravelWalletOrganizerService {

    private final TravelWalletItemRepository walletRepo;
    private final TravelWalletService walletService;

    public TravelWalletOrganizerService(TravelWalletItemRepository walletRepo, TravelWalletService walletService) {
        this.walletRepo = walletRepo;
        this.walletService = walletService;
    }

    @Transactional(readOnly = true)
    public TravelWalletSummaryMetrics summary(Long userId) {
        List<TravelWalletItem> items = walletRepo.findByUserIdOrderByCreatedAtDesc(userId);
        List<TravelWalletItem> nonArchived = items.stream().filter(i -> !i.isArchived()).toList();

        long active = nonArchived.stream().filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.ACTIVE).count();
        long upcoming = nonArchived.stream().filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.UPCOMING).count();
        long expired = nonArchived.stream().filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.EXPIRED).count();
        long expiringSoon = nonArchived.stream().filter(walletService::isExpiringSoon).count();
        long archived = items.stream().filter(TravelWalletItem::isArchived).count();
        long favorite = items.stream().filter(TravelWalletItem::isFavorite).count();
        long unlinked = items.stream().filter(walletService::isUnlinked).count();

        Map<String, Long> countsByType = items.stream()
            .collect(Collectors.groupingBy(i -> i.getWalletItemType().name(), Collectors.counting()));
        Map<String, Long> countsByTrip = items.stream()
            .filter(i -> i.getTripPlan() != null)
            .collect(Collectors.groupingBy(i -> i.getTripPlan().getId().toString(), Collectors.counting()));

        return new TravelWalletSummaryMetrics(items.size(), active, upcoming, expiringSoon, expired,
            archived, favorite, unlinked, countsByType, countsByTrip);
    }

    @Transactional(readOnly = true)
    public TravelWalletOrganizerResponse organized(Long userId) {
        List<TravelWalletItem> items = walletRepo.findByUserIdOrderByCreatedAtDesc(userId);
        List<TravelWalletItem> nonArchived = items.stream().filter(i -> !i.isArchived()).toList();

        List<TravelWalletItemResponse> favorites = map(nonArchived.stream().filter(TravelWalletItem::isFavorite));
        List<TravelWalletItemResponse> expiringSoon = map(nonArchived.stream().filter(walletService::isExpiringSoon));
        List<TravelWalletItemResponse> upcoming = map(nonArchived.stream()
            .filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.UPCOMING));
        List<TravelWalletItemResponse> active = map(nonArchived.stream()
            .filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.ACTIVE));
        List<TravelWalletItemResponse> expired = map(nonArchived.stream()
            .filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.EXPIRED));
        List<TravelWalletItemResponse> archived = map(items.stream().filter(TravelWalletItem::isArchived));

        Map<String, List<TravelWalletItemResponse>> byType = items.stream()
            .collect(Collectors.groupingBy(i -> i.getWalletItemType().name(),
                Collectors.mapping(walletService::toResponse, Collectors.toList())));
        Map<String, List<TravelWalletItemResponse>> byTrip = items.stream()
            .filter(i -> i.getTripPlan() != null)
            .collect(Collectors.groupingBy(i -> i.getTripPlan().getId().toString(),
                Collectors.mapping(walletService::toResponse, Collectors.toList())));

        return new TravelWalletOrganizerResponse(favorites, expiringSoon, upcoming, active, expired, archived, byType, byTrip);
    }

    @Transactional(readOnly = true)
    public TravelWalletGroupResponse expiringSoon(Long userId, boolean includeArchived) {
        return toGroup("expiringSoon", scoped(userId, includeArchived).stream().filter(walletService::isExpiringSoon));
    }

    @Transactional(readOnly = true)
    public TravelWalletGroupResponse expired(Long userId, boolean includeArchived) {
        return toGroup("expired", scoped(userId, includeArchived).stream()
            .filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.EXPIRED));
    }

    @Transactional(readOnly = true)
    public TravelWalletGroupResponse upcoming(Long userId, boolean includeArchived) {
        return toGroup("upcoming", scoped(userId, includeArchived).stream()
            .filter(i -> walletService.effectiveStatus(i) == TravelWalletItemStatus.UPCOMING));
    }

    @Transactional(readOnly = true)
    public TravelWalletGroupResponse unlinked(Long userId, boolean includeArchived) {
        return toGroup("unlinked", scoped(userId, includeArchived).stream().filter(walletService::isUnlinked));
    }

    // ── helpers ───────────────────────────────────────────────────────────

    private List<TravelWalletItem> scoped(Long userId, boolean includeArchived) {
        List<TravelWalletItem> items = walletRepo.findByUserIdOrderByCreatedAtDesc(userId);
        return includeArchived ? items : items.stream().filter(i -> !i.isArchived()).toList();
    }

    private List<TravelWalletItemResponse> map(java.util.stream.Stream<TravelWalletItem> items) {
        return items.map(walletService::toResponse).toList();
    }

    private TravelWalletGroupResponse toGroup(String name, java.util.stream.Stream<TravelWalletItem> items) {
        List<TravelWalletItemResponse> mapped = map(items);
        return new TravelWalletGroupResponse(name, mapped.size(), mapped);
    }
}
