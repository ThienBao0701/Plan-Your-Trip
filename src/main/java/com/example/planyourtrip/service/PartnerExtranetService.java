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
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * Aggregates the Partner Portal's "home", "menu" and "account summary" views purely
 * by composing already-existing partner services (Booking, Analytics, Finance,
 * Settings, Notification) — nothing here re-derives a metric another service already
 * computes, and nothing here mutates state.
 *
 * <p>Access is resolved the same owner-only way as every partner service prior to
 * Phase 6.9 ({@code PartnerProfileRepository.findByUserId}), not the newer team-aware
 * resolution introduced for settings/payout/team management. This is a deliberate
 * choice: every reused service below (Booking/Analytics/Finance) is itself
 * owner-only, so resolving Extranet access any other way would only produce
 * inconsistent 404s when those calls are made on the caller's behalf. Broadening the
 * whole partner surface to be team-aware is out of scope for this phase.
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
                                   NotificationService notificationService) {
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
    }

    // ── Partner: home / menu / account summary / activity ──────────────────────

    @Transactional(readOnly = true)
    public PartnerExtranetHomeResponse getHome(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = places.findAllByOwnerId(profile.getId()).stream().map(Place::getId).toList();

        long ownedHotelCount = hotelIds.size();
        long activeRoomCount = countActiveRooms(hotelIds);

        var dashboard = bookingService.getDashboard(userId);
        long unreadNotifications = notificationService.countUnread(userId);
        long unreadMessages = analyticsService.getMessageAnalytics(userId, null, null, null).unreadPartnerMessages();
        long pendingReviews = analyticsService.getReviewAnalytics(userId, null, null, null).pendingReviews();
        long activePromotions = analyticsService.getPromotionAnalytics(userId, null, null, null).activePromotions();
        PartnerFinanceOverviewResponse finance = financeService.getOverview(userId, null, null, null);

        List<QuickAction> quickActions = buildQuickActions(unreadMessages, pendingReviews, dashboard.todaysArrivals());

        return new PartnerExtranetHomeResponse(
            toProfileSummary(profile), profile.getVerificationStatus().name(),
            ownedHotelCount, activeRoomCount,
            dashboard.todaysArrivals(), dashboard.todaysDepartures(),
            unreadMessages, unreadNotifications, pendingReviews, activePromotions,
            finance, quickActions
        );
    }

    @Transactional(readOnly = true)
    public PartnerMenuResponse getMenu(Long userId) {
        myApprovedProfileOrThrow(userId);

        long unreadMessages = analyticsService.getMessageAnalytics(userId, null, null, null).unreadPartnerMessages();
        long unreadNotifications = notificationService.countUnread(userId);
        long pendingReviews = analyticsService.getReviewAnalytics(userId, null, null, null).pendingReviews();
        long activePromotions = analyticsService.getPromotionAnalytics(userId, null, null, null).activePromotions();

        List<MenuItem> sections = List.of(
            new MenuItem("dashboard", "Dashboard", "/partner/dashboard", true, null),
            new MenuItem("hotels", "Hotels", "/partner/hotels", true, null),
            new MenuItem("rooms", "Rooms", "/partner/rooms", true, null),
            new MenuItem("calendar", "Calendar", "/partner/calendar", true, null),
            new MenuItem("pricing", "Pricing", "/partner/pricing", true, null),
            new MenuItem("promotions", "Promotions", "/partner/promotions", true, activePromotions),
            new MenuItem("bookings", "Bookings", "/partner/bookings", true, null),
            new MenuItem("messages", "Messages", "/partner/messages", true, unreadMessages),
            new MenuItem("analytics", "Analytics", "/partner/analytics", true, null),
            new MenuItem("finance", "Finance", "/partner/finance", true, null),
            new MenuItem("reviews", "Reviews", "/partner/reviews", true, pendingReviews),
            new MenuItem("notifications", "Notifications", "/partner/notifications", true, unreadNotifications),
            new MenuItem("settings", "Settings", "/partner/settings", true, null)
        );
        return new PartnerMenuResponse(sections);
    }

    @Transactional(readOnly = true)
    public PartnerAccountSummaryResponse getAccountSummary(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);

        PartnerSettingsResponse settings = settingsService.getSettings(userId);
        PartnerPayoutAccountResponse payout = settingsService.getPayoutAccountOrNull(userId);
        List<PartnerTeamMemberResponse> team = settingsService.getTeamMembers(userId);

        return new PartnerAccountSummaryResponse(toProfileSummary(profile), settings, payout, team.size());
    }

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

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfileRepo.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private long countActiveRooms(List<Long> hotelIds) {
        return hotelIds.stream()
            .map(id -> hotelDetails.findByPlaceId(id).orElse(null))
            .filter(Objects::nonNull)
            .flatMap(hd -> rooms.findAllByHotelDetailIdAndActiveTrue(hd.getId()).stream())
            .count();
    }

    private List<QuickAction> buildQuickActions(long unreadMessages, long pendingReviews, long todaysArrivals) {
        List<QuickAction> actions = new ArrayList<>();
        if (todaysArrivals > 0) actions.add(new QuickAction("Review today's arrivals", "/partner/bookings?arrivalToday=true"));
        if (unreadMessages > 0) actions.add(new QuickAction("Reply to guest messages", "/partner/messages"));
        if (pendingReviews > 0) actions.add(new QuickAction("Respond to pending reviews", "/partner/reviews"));
        actions.add(new QuickAction("Manage hotels", "/partner/hotels"));
        actions.add(new QuickAction("View calendar", "/partner/calendar"));
        return actions;
    }

    private PartnerProfileSummary toProfileSummary(PartnerProfile p) {
        return new PartnerProfileSummary(p.getId(), p.getBusinessName(), p.getRepresentativeName(), p.getEmail());
    }
}
