package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerExtranetDto.*;
import com.example.planyourtrip.dto.PartnerFinanceDto.PartnerFinanceOverviewResponse;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerPayoutAccountResponse;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerSettingsResponse;
import com.example.planyourtrip.dto.PartnerSettingsDto.PartnerTeamMemberResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerPayoutAccountRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import org.springframework.http.HttpStatus;
import com.example.planyourtrip.dto.RedactedField;
import com.example.planyourtrip.security.rbac.AuthorizationDecision;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.ScopeSet;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

import static com.example.planyourtrip.security.rbac.PartnerPermission.*;

/**
 * Aggregates the Partner Portal's "home", "menu" and "account summary" views purely
 * by composing already-existing partner services (Booking, Analytics, Finance,
 * Settings, Notification) — nothing here re-derives a metric another service already
 * computes, and nothing here mutates state.
 *
 * <p>RBAC R3b — access is the shared workspace of every partner endpoint (registrant or ACTIVE member); each
 * composed block is computed only with its own permission, over that permission's scope set.
 */
@Service
public class PartnerExtranetService {

    private final PartnerProfileRepository partnerProfileRepo;
    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final PartnerTeamMemberRepository teamMemberRepo;
    private final PartnerPayoutAccountRepository payoutAccountRepo;
    private final PartnerBookingService bookingService;
    private final PartnerAnalyticsService analyticsService;
    private final PartnerFinanceService financeService;
    private final PartnerSettingsService settingsService;
    private final PartnerActivityLogService activityLogService;
    private final NotificationService notificationService;
    private final PartnerAccessService partnerAccess;

    public PartnerExtranetService(PartnerProfileRepository partnerProfileRepo,
                                   PlaceRepository places,
                                   HotelDetailRepository hotelDetails,
                                   HotelRoomRepository rooms,
                                   PartnerTeamMemberRepository teamMemberRepo,
                                   PartnerPayoutAccountRepository payoutAccountRepo,
                                   PartnerBookingService bookingService,
                                   PartnerAnalyticsService analyticsService,
                                   PartnerFinanceService financeService,
                                   PartnerSettingsService settingsService,
                                   PartnerActivityLogService activityLogService,
                                   NotificationService notificationService,
                                   PartnerAccessService partnerAccess) {
        this.partnerProfileRepo = partnerProfileRepo;
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.teamMemberRepo = teamMemberRepo;
        this.payoutAccountRepo = payoutAccountRepo;
        this.bookingService = bookingService;
        this.analyticsService = analyticsService;
        this.financeService = financeService;
        this.settingsService = settingsService;
        this.activityLogService = activityLogService;
        this.notificationService = notificationService;
        this.partnerAccess = partnerAccess;
    }

    // ── Partner: home / menu / account summary / activity ──────────────────────

    /**
     * RBAC R3b — workspace entry (P01, any grant). Every block is computed only when the caller holds its own
     * permission, over that permission's scope set (§25.1 Extranet, FILTERABLE BY PROPERTY): hotels P14, rooms P21,
     * arrivals/departures P34, messages/reviews/promotions badges P48, finance summary P49, profile detail P02.
     * A withheld block is 0 or null and listed in {@code redacted}.
     */
    @Transactional(readOnly = true)
    public PartnerExtranetHomeResponse getHome(Long userId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, WORKSPACE_ACCESS, null);
        PartnerProfile profile = access.profile();
        List<RedactedField> redacted = new ArrayList<>();

        long ownedHotelCount = 0;
        if (partnerAccess.holdsAnywhere(access, PROPERTY_VIEW)) {
            ownedHotelCount = partnerAccess.propertyIds(access, partnerAccess.requireCollection(access, PROPERTY_VIEW)).size();
        } else {
            redacted.add(RedactedField.omitted("ownedHotelCount"));
        }
        long activeRoomCount = countActiveRooms(access);

        long arrivals = 0, departures = 0;
        if (partnerAccess.holdsAnywhere(access, BOOKING_VIEW)) {
            var dashboard = bookingService.getDashboard(userId);
            arrivals = dashboard.todaysArrivals();
            departures = dashboard.todaysDepartures();
        } else {
            redacted.add(RedactedField.omitted("todaysArrivals"));
            redacted.add(RedactedField.omitted("todaysDepartures"));
        }
        long unreadMessages = 0, pendingReviews = 0, activePromotions = 0;
        if (partnerAccess.holdsAnywhere(access, ANALYTICS_VIEW)) {
            unreadMessages = analyticsService.getMessageAnalytics(userId, null, null, null).unreadPartnerMessages();
            pendingReviews = analyticsService.getReviewAnalytics(userId, null, null, null).pendingReviews();
            activePromotions = analyticsService.getPromotionAnalytics(userId, null, null, null).activePromotions();
        } else {
            for (String field : List.of("unreadMessages", "pendingReviews", "activePromotions"))
                redacted.add(RedactedField.omitted(field));
        }
        long unreadNotifications = notificationService.countUnread(userId);
        PartnerFinanceOverviewResponse finance = null;
        if (partnerAccess.holdsAnywhere(access, FINANCE_REVENUE_VIEW)) {
            finance = financeService.getOverview(userId, null, null, null);
        } else {
            redacted.add(RedactedField.omitted("financeSummary"));
        }

        List<QuickAction> quickActions = buildQuickActions(access, unreadMessages, pendingReviews, arrivals);

        return new PartnerExtranetHomeResponse(
            toProfileSummary(access, profile, redacted, "profile."), profile.getVerificationStatus().name(),
            ownedHotelCount, activeRoomCount,
            arrivals, departures,
            unreadMessages, unreadNotifications, pendingReviews, activePromotions,
            finance, quickActions, List.copyOf(redacted)
        );
    }

    /**
     * RBAC R3b — §23 F4: a destination is listed when the caller holds its permission at any scope; badges are
     * computed only when their own permission allows.
     */
    @Transactional(readOnly = true)
    public PartnerMenuResponse getMenu(Long userId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, WORKSPACE_ACCESS, null);
        boolean analytics = partnerAccess.holdsAnywhere(access, ANALYTICS_VIEW);

        Long unreadMessages = analytics
            ? analyticsService.getMessageAnalytics(userId, null, null, null).unreadPartnerMessages() : null;
        long unreadNotifications = notificationService.countUnread(userId);
        Long pendingReviews = analytics
            ? analyticsService.getReviewAnalytics(userId, null, null, null).pendingReviews() : null;
        Long activePromotions = analytics
            ? analyticsService.getPromotionAnalytics(userId, null, null, null).activePromotions() : null;

        List<MenuItem> sections = new ArrayList<>();
        sections.add(new MenuItem("dashboard", "Dashboard", "/partner/dashboard", true, null));
        // hotels: P14, or parent context (§11.7) for a member holding only room types
        if (partnerAccess.holdsAnywhere(access, PROPERTY_VIEW) || partnerAccess.holdsAnywhere(access, ROOM_VIEW))
            sections.add(new MenuItem("hotels", "Hotels", "/partner/hotels", true, null));
        if (partnerAccess.holdsAnywhere(access, ROOM_VIEW))
            sections.add(new MenuItem("rooms", "Rooms", "/partner/rooms", true, null));
        if (partnerAccess.holdsAnywhere(access, INVENTORY_VIEW))
            sections.add(new MenuItem("calendar", "Calendar", "/partner/calendar", true, null));
        if (partnerAccess.holdsAnywhere(access, RATE_VIEW))
            sections.add(new MenuItem("pricing", "Pricing", "/partner/pricing", true, null));
        if (partnerAccess.holdsAnywhere(access, PROMOTION_VIEW))
            sections.add(new MenuItem("promotions", "Promotions", "/partner/promotions", true, activePromotions));
        if (partnerAccess.holdsAnywhere(access, BOOKING_VIEW))
            sections.add(new MenuItem("bookings", "Bookings", "/partner/bookings", true, null));
        if (partnerAccess.holdsAnywhere(access, CONVERSATION_VIEW))
            sections.add(new MenuItem("messages", "Messages", "/partner/messages", true, unreadMessages));
        if (analytics || partnerAccess.holdsAnywhere(access, FINANCE_REVENUE_VIEW))
            sections.add(new MenuItem("analytics", "Analytics", "/partner/analytics", true, null));
        if (partnerAccess.holdsAnywhere(access, FINANCE_REVENUE_VIEW)
                || partnerAccess.holdsAnywhere(access, FINANCE_STATEMENT_VIEW)
                || partnerAccess.holdsAnywhere(access, FINANCE_PAYOUT_VIEW))
            sections.add(new MenuItem("finance", "Finance", "/partner/finance", true, null));
        if (partnerAccess.holdsAnywhere(access, REVIEW_VIEW))
            sections.add(new MenuItem("reviews", "Reviews", "/partner/reviews", true, pendingReviews));
        sections.add(new MenuItem("notifications", "Notifications", "/partner/notifications", true, unreadNotifications));
        sections.add(new MenuItem("settings", "Settings", "/partner/settings", true, null));
        return new PartnerMenuResponse(List.copyOf(sections));
    }

    /**
     * RBAC R3b — workspace entry (P01) with company-level blocks (§25.1 COMPANY ONLY): workspace settings (P01),
     * profile detail (P02), payout account (P52), team size (P07).
     */
    @Transactional(readOnly = true)
    public PartnerAccountSummaryResponse getAccountSummary(Long userId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        partnerAccess.requireCompanyPermission(access, WORKSPACE_ACCESS, null);
        List<RedactedField> redacted = new ArrayList<>();

        PartnerSettingsResponse settings = settingsService.getSettings(userId);
        PartnerPayoutAccountResponse payout = null;
        if (PartnerAuthorization.company(access, PAYOUT_ACCOUNT_VIEW) == AuthorizationDecision.ALLOW) {
            payout = settingsService.getPayoutAccountOrNull(userId);
        } else {
            redacted.add(RedactedField.omitted("payoutAccount"));
        }
        int teamSize = 0;
        if (partnerAccess.holdsAnywhere(access, TEAM_VIEW)) {
            teamSize = settingsService.getTeamMembers(userId).size();
        } else {
            redacted.add(RedactedField.omitted("teamMemberCount"));
        }
        return new PartnerAccountSummaryResponse(toProfileSummary(access, access.profile(), redacted, "profile."),
            settings, payout, teamSize, List.copyOf(redacted));
    }

    /** RBAC R3b — COMPANY P05 (AU-4): owners and company-level managers read the workspace trail. */
    @Transactional(readOnly = true)
    public List<PartnerActivityLogResponse> getActivityLogs(Long userId) {
        return activityLogService.listMine(userId);
    }

    // ── Admin: partner detail / team / settings / activity ─────────────────────

    @Transactional(readOnly = true)
    public AdminPartnerDetailResponse adminGetDetail(Long partnerProfileId) {
        PartnerProfile profile = partnerProfileRepo.findById(partnerProfileId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found: " + partnerProfileId));

        long ownedHotelCount = places.findAllByOwnerId(profile.getId()).size();
        long teamMemberCount = teamMemberRepo.findByPartnerProfileIdOrderByCreatedAtAsc(profile.getId()).size();
        String payoutStatus = payoutAccountRepo.findByPartnerProfileId(profile.getId())
            .map(a -> a.getStatus().name()).orElse("NOT_CONFIGURED");

        return new AdminPartnerDetailResponse(
            profile.getId(), profile.getBusinessName(), profile.getVerificationStatus().name(),
            ownedHotelCount, teamMemberCount, payoutStatus, profile.getCreatedAt()
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /** Active room types over room view's scope set (P21, floor U): whole properties, plus single granted units. */
    private long countActiveRooms(PartnerAccessContext access) {
        if (!partnerAccess.holdsAnywhere(access, ROOM_VIEW)) return 0;
        ScopeSet scope = partnerAccess.requireCollection(access, ROOM_VIEW);
        List<Long> hotelIds = partnerAccess.propertyIds(access, scope);
        long whole = hotelIds.stream()
            .map(id -> hotelDetails.findByPlaceId(id).orElse(null))
            .filter(Objects::nonNull)
            .flatMap(hd -> rooms.findAllByHotelDetailIdAndActiveTrue(hd.getId()).stream())
            .count();
        long units = scope.units().stream()
            .filter(unit -> !hotelIds.contains(unit.propertyId()))
            .filter(unit -> rooms.findById(unit.unitId()).map(r -> r.isActive()).orElse(false))
            .count();
        return whole + units;
    }

    private List<QuickAction> buildQuickActions(PartnerAccessContext access, long unreadMessages, long pendingReviews,
                                                long todaysArrivals) {
        List<QuickAction> actions = new ArrayList<>();
        if (todaysArrivals > 0) actions.add(new QuickAction("Review today's arrivals", "/partner/bookings?arrivalToday=true"));
        if (unreadMessages > 0 && partnerAccess.holdsAnywhere(access, CONVERSATION_RESPOND))
            actions.add(new QuickAction("Reply to guest messages", "/partner/messages"));
        if (pendingReviews > 0 && partnerAccess.holdsAnywhere(access, REVIEW_REPLY))
            actions.add(new QuickAction("Respond to pending reviews", "/partner/reviews"));
        if (partnerAccess.holdsAnywhere(access, PROPERTY_VIEW)) actions.add(new QuickAction("Manage hotels", "/partner/hotels"));
        if (partnerAccess.holdsAnywhere(access, INVENTORY_VIEW)) actions.add(new QuickAction("View calendar", "/partner/calendar"));
        return actions;
    }

    /** §11.7 parent context for everyone (id, business name); the representative and contact need P02 (§21.1). */
    private PartnerProfileSummary toProfileSummary(PartnerAccessContext access, PartnerProfile p,
                                                   List<RedactedField> redacted, String prefix) {
        if (PartnerAuthorization.company(access, BUSINESS_PROFILE_VIEW) == AuthorizationDecision.ALLOW) {
            return new PartnerProfileSummary(p.getId(), p.getBusinessName(), p.getRepresentativeName(), p.getEmail());
        }
        redacted.add(RedactedField.omitted(prefix + "representativeName"));
        redacted.add(RedactedField.omitted(prefix + "email"));
        return new PartnerProfileSummary(p.getId(), p.getBusinessName(), null, null);
    }

    /** Admin views see the whole profile summary. */
    private PartnerProfileSummary toProfileSummary(PartnerProfile p) {
        return new PartnerProfileSummary(p.getId(), p.getBusinessName(), p.getRepresentativeName(), p.getEmail());
    }
}
