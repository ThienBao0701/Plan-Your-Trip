package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PartnerFinanceDto.PartnerFinanceOverviewResponse;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerPayoutAccountResponse;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerSettingsResponse;

import java.time.Instant;
import java.util.List;

public class PartnerExtranetDto {

    public record PartnerProfileSummary(
        Long id,
        String businessName,
        String representativeName,
        String email
    ) {}

    public record QuickAction(String label, String route) {}

    public record MenuItem(String key, String label, String route, boolean enabled, Long badgeCount) {}

    public record PartnerExtranetHomeResponse(
        PartnerProfileSummary profile,
        String verificationStatus,
        long ownedHotelCount,
        long activeRoomCount,
        long todaysArrivals,
        long todaysDepartures,
        long unreadMessages,
        long unreadNotifications,
        long pendingReviews,
        long activePromotions,
        PartnerFinanceOverviewResponse financeSummary,
        List<QuickAction> quickActions,
        // RBAC R3b — each block needs its own permission over the caller's scope; withheld blocks are 0/null here
        List<RedactedField> redacted
    ) {}

    public record PartnerMenuResponse(List<MenuItem> sections) {}

    public record PartnerAccountSummaryResponse(
        PartnerProfileSummary profile,
        PartnerSettingsResponse settings,
        PartnerPayoutAccountResponse payoutAccount,
        int teamMemberCount,
        // RBAC R3b — profile detail needs P02, the payout block P52, the team count P07
        List<RedactedField> redacted
    ) {}

    public record PartnerActivityLogResponse(
        Long id,
        Long partnerProfileId,
        Long actorUserId,
        String actorName,
        String action,
        String entityType,
        Long entityId,
        String description,
        Instant createdAt
    ) {}

    public record AdminPartnerDetailResponse(
        Long partnerProfileId,
        String businessName,
        String verificationStatus,
        long ownedHotelCount,
        long teamMemberCount,
        String payoutAccountStatus,
        Instant createdAt
    ) {}
}
