package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.AdminAnalyticsDto.AdminAnalyticsOverviewResponse;
import com.example.planyourtrip.dto.PartnerAnalyticsDto.MetricBreakdown;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
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
                                 HotelDetailRepository hotelDetails) {
        this.bookingRepo = bookingRepo;
        this.userRepo = userRepo;
        this.partnerProfiles = partnerProfiles;
        this.rooms = rooms;
        this.hotelDetails = hotelDetails;
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
