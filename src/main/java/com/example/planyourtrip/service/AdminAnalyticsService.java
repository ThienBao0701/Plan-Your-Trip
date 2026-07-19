package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AdminAnalyticsDto.AdminAnalyticsOverviewResponse;
import com.example.planyourtrip.dto.AdminAnalyticsDto.AdminReviewAnalyticsOverviewResponse;
import com.example.planyourtrip.dto.PartnerAnalyticsDto.MetricBreakdown;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.ReviewStatus;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.ReviewRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Read-only platform-wide analytics for the platform ADMIN.
 *
 * <p>Unlike {@link PartnerAnalyticsService} — which scopes every metric to a specific
 * owner's hotels — this service computes UN-scoped aggregates across ALL rows directly
 * from the existing repositories (a distinct, simpler rollup, not a duplicate of the
 * partner engine). Nothing here mutates state; the revenue definition below is kept
 * byte-for-byte consistent with the partner engine so admin and partner numbers reconcile.
 */
@Service
@Transactional(readOnly = true)
public class AdminAnalyticsService {

    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final PartnerProfileRepository partnerProfiles;
    private final HotelRoomRepository rooms;
    private final HotelDetailRepository hotelDetails;
    private final ReviewRepository reviewRepo;

    /**
     * Revenue-recognised booking statuses — IDENTICAL to
     * {@code PartnerAnalyticsService.REVENUE_STATUSES} so a partner's revenue for their
     * hotels always sums into this platform total.
     */
    private static final Set<BookingStatus> REVENUE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY, BookingStatus.CHECKED_IN,
                   BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED, BookingStatus.ARCHIVED);

    public AdminAnalyticsService(BookingRepository bookingRepo,
                                 UserRepository userRepo,
                                 PartnerProfileRepository partnerProfiles,
                                 HotelRoomRepository rooms,
                                 HotelDetailRepository hotelDetails,
                                 ReviewRepository reviewRepo) {
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.partnerProfiles = partnerProfiles;
        this.rooms = rooms;
        this.hotelDetails = hotelDetails;
        this.reviewRepo = reviewRepo;
    }

    public AdminAnalyticsOverviewResponse getOverview(LocalDate from, LocalDate to) {
        LocalDate[] range = resolveRange(from, to);

        long totalBookings = bookingRepo.count();
        List<MetricBreakdown> bookingsByStatus = bookingsByStatus();
        BigDecimal grossRevenue = scale2(bookingRepo.sumFinalPriceByStatusIn(REVENUE_STATUSES));

        long activeHotels = hotelDetails.countByPlaceStatus(PlaceStatus.PUBLISHED);
        long activeRooms = rooms.countByActiveTrue();
        long totalUsers = userRepo.count();
        long totalPartners = partnerProfiles.count();

        long bookingsInRange = bookingRepo.countByCheckInDateBetween(range[0], range[1]);
        BigDecimal revenueInRange = scale2(
            bookingRepo.sumFinalPriceByStatusInAndCheckInDateBetween(REVENUE_STATUSES, range[0], range[1]));

        return new AdminAnalyticsOverviewResponse(
            range[0], range[1], totalBookings, bookingsByStatus, grossRevenue,
            activeHotels, activeRooms, totalUsers, totalPartners, bookingsInRange, revenueInRange);
    }

    /**
     * Every {@link BookingStatus} bucket in natural enum order, 0-filled for statuses with
     * no bookings so the admin dashboard always sees a stable, complete breakdown.
     */
    private List<MetricBreakdown> bookingsByStatus() {
        Map<BookingStatus, Long> counts = new HashMap<>();
        for (Object[] row : bookingRepo.countGroupedByStatus()) {
            counts.put((BookingStatus) row[0], (Long) row[1]);
        }
        List<MetricBreakdown> breakdown = new ArrayList<>();
        for (BookingStatus status : BookingStatus.values()) {
            long c = counts.getOrDefault(status, 0L);
            breakdown.add(new MetricBreakdown(status.name(), BigDecimal.valueOf(c), c));
        }
        return breakdown;
    }

    /**
     * Phase 7.46 — platform-wide READ-ONLY review analytics overview. Un-scoped aggregates computed
     * straight from additive {@link ReviewRepository} aggregate queries (COUNT/AVG/GROUP BY) so no
     * review rows are loaded platform-wide. Population of each metric is documented on
     * {@code AdminReviewAnalyticsOverviewResponse}. Nothing here mutates state.
     */
    public AdminReviewAnalyticsOverviewResponse getReviewAnalyticsOverview(LocalDate from, LocalDate to) {
        LocalDate[] range = resolveRange(from, to);
        Instant start = range[0].atStartOfDay(ZoneId.systemDefault()).toInstant();
        Instant end = range[1].plusDays(1).atStartOfDay(ZoneId.systemDefault()).toInstant();

        long totalReviews = reviewRepo.count();
        List<MetricBreakdown> statusBreakdown = reviewStatusBreakdown();
        Map<Integer, Long> ratingDistribution = ratingDistribution();

        Object[] avgRow = reviewRepo.averageRatingsByStatus(ReviewStatus.APPROVED).get(0);
        double avgOverall    = nz(avgRow[0]);
        double avgClean      = nz(avgRow[1]);
        double avgService    = nz(avgRow[2]);
        double avgLocation   = nz(avgRow[3]);
        double avgValue      = nz(avgRow[4]);
        double avgFacilities = nz(avgRow[5]);

        long withReply = reviewRepo.countByPartnerRepliedAtIsNotNull();
        double partnerReplyRate = totalReviews == 0 ? 0.0 : round2(withReply * 100.0 / totalReviews);

        long reviewedPlaces = reviewRepo.countDistinctPlaces();
        Instant latestReviewAt = reviewRepo.maxCreatedAt();

        long reviewsInRange = reviewRepo.countCreatedInRange(start, end);
        double avgRatingInRange = round2(nz(
            reviewRepo.averageOverallByStatusCreatedInRange(ReviewStatus.APPROVED, start, end)));

        return new AdminReviewAnalyticsOverviewResponse(
            range[0], range[1], totalReviews, statusBreakdown, ratingDistribution,
            round2(avgOverall), round2(avgClean), round2(avgService), round2(avgLocation),
            round2(avgValue), round2(avgFacilities), partnerReplyRate, reviewedPlaces,
            latestReviewAt, reviewsInRange, avgRatingInRange);
    }

    /** Every {@link ReviewStatus} bucket in natural enum order, 0-filled for statuses with no reviews. */
    private List<MetricBreakdown> reviewStatusBreakdown() {
        Map<ReviewStatus, Long> counts = new HashMap<>();
        for (Object[] row : reviewRepo.countGroupedByStatus()) {
            counts.put((ReviewStatus) row[0], (Long) row[1]);
        }
        List<MetricBreakdown> breakdown = new ArrayList<>();
        for (ReviewStatus status : ReviewStatus.values()) {
            long c = counts.getOrDefault(status, 0L);
            breakdown.add(new MetricBreakdown(status.name(), BigDecimal.valueOf(c), c));
        }
        return breakdown;
    }

    /** Overall-rating distribution 1..5 over APPROVED reviews, 0-filled for stars with none. */
    private Map<Integer, Long> ratingDistribution() {
        Map<Integer, Long> counts = new HashMap<>();
        for (Object[] row : reviewRepo.countRatingGroupedByStatus(ReviewStatus.APPROVED)) {
            counts.put(((Number) row[0]).intValue(), (Long) row[1]);
        }
        Map<Integer, Long> dist = new LinkedHashMap<>();
        for (int star = 1; star <= 5; star++) dist.put(star, counts.getOrDefault(star, 0L));
        return dist;
    }

    /** Null-safe unwrap of a JPQL AVG (null ⇒ 0.0), so an empty population never NPEs or divides by zero. */
    private double nz(Object avg) {
        return avg == null ? 0.0 : ((Number) avg).doubleValue();
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }

    /** Mirrors {@code PartnerAnalyticsService.resolveRange}: defaults to the last 30 days, rejects from &gt; to. */
    private LocalDate[] resolveRange(LocalDate from, LocalDate to) {
        LocalDate today = LocalDate.now();
        LocalDate resolvedTo = to != null ? to : today;
        LocalDate resolvedFrom = from != null ? from : resolvedTo.minusDays(29);
        if (resolvedFrom.isAfter(resolvedTo))
            throw new ApiException(HttpStatus.BAD_REQUEST, "from must not be after to");
        return new LocalDate[]{resolvedFrom, resolvedTo};
    }

    private BigDecimal scale2(BigDecimal value) {
        return (value != null ? value : BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
    }
}
