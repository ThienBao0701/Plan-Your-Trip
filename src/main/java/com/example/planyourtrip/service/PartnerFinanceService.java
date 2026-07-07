package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.MetricBreakdown;
import com.example.planyourtrip.dto.PartnerAnalyticsDto.PartnerAnalyticsOverviewResponse;
import com.example.planyourtrip.dto.PartnerAnalyticsDto.RevenueAnalyticsResponse;
import com.example.planyourtrip.dto.PartnerAnalyticsDto.TimeSeriesPoint;
import com.example.planyourtrip.dto.PartnerFinanceDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Read-only finance and settlement analytics for approved partners, scoped to hotels
 * they own. Nothing here executes a payout or touches a bank/PSP — it only aggregates
 * data already produced by the existing Booking/Payment/Invoice write flows.
 *
 * <p>Two constants below are explicit business assumptions, since no real commission
 * or tax engine exists yet:
 * <ul>
 *   <li>{@link #COMMISSION_RATE} — flat 15% platform commission on gross revenue.</li>
 *   <li>{@link #ESTIMATED_TAX_RATE} — indicative 10% VAT-style estimate on net revenue,
 *       purely informational (not a real tax computation).</li>
 * </ul>
 * Likewise, "settlement"/"payout" periods are synthesized as calendar months from paid
 * booking revenue (past months = PAID, current month = PENDING) since there is no real
 * settlement ledger or payout scheduler in the system yet.
 */
@Service
@Transactional(readOnly = true)
public class PartnerFinanceService {

    /** Flat platform commission applied to gross revenue. Single source of truth for this rate. */
    private static final double COMMISSION_RATE = 0.15;

    /** Indicative tax estimate applied to net (post-commission) revenue. Not real tax logic. */
    private static final double ESTIMATED_TAX_RATE = 0.10;

    private static final Set<BookingStatus> REVENUE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY, BookingStatus.CHECKED_IN,
                   BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED, BookingStatus.ARCHIVED);

    private final PartnerProfileRepository partnerProfiles;
    private final PlaceRepository places;
    private final BookingRepository bookingRepo;
    private final PaymentRepository paymentRepo;
    private final InvoiceRepository invoiceRepo;
    private final PartnerAnalyticsService analyticsService;

    public PartnerFinanceService(PartnerProfileRepository partnerProfiles,
                                  PlaceRepository places,
                                  BookingRepository bookingRepo,
                                  PaymentRepository paymentRepo,
                                  InvoiceRepository invoiceRepo,
                                  PartnerAnalyticsService analyticsService) {
        this.partnerProfiles = partnerProfiles;
        this.places = places;
        this.bookingRepo = bookingRepo;
        this.paymentRepo = paymentRepo;
        this.invoiceRepo = invoiceRepo;
        this.analyticsService = analyticsService;
    }

    // ── Overview ─────────────────────────────────────────────────────────────

    public PartnerFinanceOverviewResponse getOverview(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);

        // Reuse Phase 6.7's already-computed gross revenue / completed-booking count
        // rather than re-deriving them from raw bookings.
        PartnerAnalyticsOverviewResponse analyticsOverview = analyticsService.getOverview(userId, hotelId, range[0], range[1]);
        BigDecimal grossRevenue = analyticsOverview.totalRevenue();
        long completedBookings = analyticsOverview.completedBookings();

        BigDecimal commissionAmount = commissionOf(grossRevenue);
        BigDecimal netRevenue = grossRevenue.subtract(commissionAmount).setScale(2, RoundingMode.HALF_UP);
        BigDecimal estimatedTax = netRevenue.multiply(BigDecimal.valueOf(ESTIMATED_TAX_RATE))
            .setScale(2, RoundingMode.HALF_UP);

        List<Long> bookingIds = bookingsInRange(hotelIds, range[0], range[1]).stream().map(Booking::getId).toList();
        long paidBookings = bookingIds.isEmpty() ? 0 : paymentRepo.findByBookingIdInAndStatus(bookingIds, PaymentStatus.PAID)
            .stream().map(p -> p.getBooking().getId()).distinct().count();
        BigDecimal refundedAmount = bookingIds.isEmpty() ? BigDecimal.ZERO
            : paymentRepo.findByBookingIdInAndStatus(bookingIds, PaymentStatus.REFUNDED)
                .stream().map(Payment::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        // No real settlement ledger exists yet, so the entire net revenue for the
        // queried window is treated as still pending settlement.
        BigDecimal pendingSettlement = netRevenue;

        return new PartnerFinanceOverviewResponse(
            grossRevenue.setScale(2, RoundingMode.HALF_UP), netRevenue, commissionAmount, estimatedTax,
            completedBookings, paidBookings, refundedAmount.setScale(2, RoundingMode.HALF_UP),
            pendingSettlement, nextPayoutDate()
        );
    }

    // ── Revenue ──────────────────────────────────────────────────────────────

    public PartnerRevenueResponse getRevenue(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);

        // Reuse Phase 6.7's day/room/hotel revenue breakdowns instead of re-grouping bookings here.
        RevenueAnalyticsResponse analyticsRevenue = analyticsService.getRevenue(userId, hotelId, range[0], range[1]);
        List<TimeSeriesPoint> revenueByDay = analyticsRevenue.revenueByDay();
        List<MetricBreakdown> revenueByHotel = analyticsRevenue.revenueByHotel();
        List<MetricBreakdown> revenueByRoom = analyticsRevenue.revenueByRoom();

        List<Booking> revenueBookings = bookingsInRange(hotelIds, range[0], range[1]).stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus())).toList();

        List<FinanceMetric> revenueByMonth = revenueByMonth(revenueBookings);

        BigDecimal totalRevenue = sumRevenue(revenueBookings);
        BigDecimal avgBookingValue = revenueBookings.isEmpty() ? BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP)
            : totalRevenue.divide(BigDecimal.valueOf(revenueBookings.size()), 2, RoundingMode.HALF_UP);
        BigDecimal highestBooking = revenueBookings.stream().map(Booking::getFinalPrice)
            .max(Comparator.naturalOrder()).orElse(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);

        return new PartnerRevenueResponse(revenueByDay, revenueByMonth, revenueByHotel, revenueByRoom,
            avgBookingValue, highestBooking);
    }

    // ── Commission ───────────────────────────────────────────────────────────

    public PartnerCommissionResponse getCommission(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);

        BigDecimal gross = analyticsService.getOverview(userId, hotelId, range[0], range[1]).totalRevenue();
        BigDecimal commission = commissionOf(gross);
        BigDecimal net = gross.subtract(commission).setScale(2, RoundingMode.HALF_UP);

        return new PartnerCommissionResponse(gross.setScale(2, RoundingMode.HALF_UP), commission, net, COMMISSION_RATE);
    }

    // ── Settlement ───────────────────────────────────────────────────────────

    public PartnerSettlementResponse getSettlement(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Booking> revenueBookings = bookingsInRange(hotelIds, range[0], range[1]).stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus())).toList();

        List<SettlementHistoryItem> history = monthlySettlements(revenueBookings);
        String currentPeriod = YearMonth.now().toString();

        BigDecimal current = history.stream()
            .filter(h -> h.period().equals(currentPeriod))
            .map(SettlementHistoryItem::netAmount).findFirst().orElse(zero());

        List<SettlementHistoryItem> past = history.stream()
            .filter(h -> !h.period().equals(currentPeriod))
            .sorted(Comparator.comparing(SettlementHistoryItem::period).reversed())
            .toList();

        BigDecimal last = past.isEmpty() ? zero() : past.get(0).netAmount();
        BigDecimal paid = past.stream().map(SettlementHistoryItem::netAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add).setScale(2, RoundingMode.HALF_UP);

        return new PartnerSettlementResponse(current, last, current, paid, history, current);
    }

    // ── Payout ───────────────────────────────────────────────────────────────

    public PartnerPayoutResponse getPayout(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Booking> revenueBookings = bookingsInRange(hotelIds, range[0], range[1]).stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus())).toList();

        List<SettlementHistoryItem> history = monthlySettlements(revenueBookings);
        List<SettlementHistoryItem> completed = history.stream().filter(h -> "PAID".equals(h.status())).toList();
        List<SettlementHistoryItem> upcoming = history.stream().filter(h -> "PENDING".equals(h.status())).toList();

        return new PartnerPayoutResponse(upcoming, completed, nextPayoutDate());
    }

    // ── Invoice finance ──────────────────────────────────────────────────────

    public PartnerInvoiceFinanceResponse getInvoiceFinance(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Long> bookingIds = bookingsInRange(hotelIds, range[0], range[1]).stream().map(Booking::getId).toList();

        List<Invoice> invoices = bookingIds.isEmpty() ? List.of() : invoiceRepo.findByBookingIdIn(bookingIds);

        long issued = invoices.stream().filter(i -> i.getStatus() == InvoiceStatus.ISSUED).count();
        long paid = invoices.stream().filter(i -> i.getStatus() == InvoiceStatus.PAID).count();
        long cancelled = invoices.stream().filter(i -> i.getStatus() == InvoiceStatus.CANCELLED).count();
        long refunded = invoices.stream().filter(i -> i.getStatus() == InvoiceStatus.REFUNDED).count();
        BigDecimal total = invoices.stream().map(Invoice::getTotalAmount).reduce(BigDecimal.ZERO, BigDecimal::add);

        return new PartnerInvoiceFinanceResponse(issued, paid, cancelled, refunded, total.setScale(2, RoundingMode.HALF_UP));
    }

    // ── Refund ───────────────────────────────────────────────────────────────

    public PartnerRefundResponse getRefund(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Long> bookingIds = bookingsInRange(hotelIds, range[0], range[1]).stream().map(Booking::getId).toList();

        List<Payment> refundedPayments = bookingIds.isEmpty() ? List.of()
            : paymentRepo.findByBookingIdInAndStatus(bookingIds, PaymentStatus.REFUNDED);
        List<Payment> paidPayments = bookingIds.isEmpty() ? List.of()
            : paymentRepo.findByBookingIdInAndStatus(bookingIds, PaymentStatus.PAID);

        long refundCount = refundedPayments.size();
        BigDecimal refundAmount = refundedPayments.stream().map(Payment::getAmount)
            .reduce(BigDecimal.ZERO, BigDecimal::add).setScale(2, RoundingMode.HALF_UP);

        long relevantPayments = refundCount + paidPayments.size();
        double refundPercentage = relevantPayments > 0 ? refundCount * 100.0 / relevantPayments : 0.0;

        return new PartnerRefundResponse(refundCount, refundAmount, round2(refundPercentage));
    }

    // ── Ownership / scope helpers ────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private List<Long> resolveHotelScope(Long ownerId, Long hotelId) {
        List<Long> owned = places.findAllByOwnerId(ownerId).stream().map(Place::getId).toList();
        if (hotelId == null) return owned;
        if (!owned.contains(hotelId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId);
        return List.of(hotelId);
    }

    private LocalDate[] resolveRange(LocalDate from, LocalDate to) {
        LocalDate today = LocalDate.now();
        LocalDate resolvedTo = to != null ? to : today;
        LocalDate resolvedFrom = from != null ? from : resolvedTo.minusDays(29);
        if (resolvedFrom.isAfter(resolvedTo))
            throw new ApiException(HttpStatus.BAD_REQUEST, "from must not be after to");
        return new LocalDate[]{resolvedFrom, resolvedTo};
    }

    private List<Booking> bookingsInRange(List<Long> hotelIds, LocalDate from, LocalDate to) {
        Specification<Booking> spec = Specification
            .where(BookingSpecification.withHotelIdIn(hotelIds))
            .and(BookingSpecification.withCheckInDateRange(from, to));
        return bookingRepo.findAll(spec);
    }

    // ── Calculation helpers ──────────────────────────────────────────────────

    private BigDecimal commissionOf(BigDecimal gross) {
        return gross.multiply(BigDecimal.valueOf(COMMISSION_RATE)).setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal sumRevenue(List<Booking> revenueBookings) {
        return revenueBookings.stream().map(Booking::getFinalPrice).reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    /**
     * No real payout schedule exists yet — this assumes a simple, documented monthly
     * cadence: payouts run on the 1st of next month, covering the prior period's revenue.
     */
    private LocalDate nextPayoutDate() {
        return LocalDate.now().withDayOfMonth(1).plusMonths(1);
    }

    private List<FinanceMetric> revenueByMonth(List<Booking> revenueBookings) {
        Map<YearMonth, BigDecimal> byMonth = revenueBookings.stream()
            .collect(Collectors.groupingBy(b -> YearMonth.from(b.getCheckInDate()),
                Collectors.reducing(BigDecimal.ZERO, Booking::getFinalPrice, BigDecimal::add)));
        return byMonth.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .map(e -> new FinanceMetric(e.getKey().toString(), e.getValue().setScale(2, RoundingMode.HALF_UP)))
            .toList();
    }

    /**
     * Buckets bookings into calendar months and synthesizes a settlement/payout period
     * per month: months before the current one are marked PAID (settled), the current
     * month is marked PENDING (still accruing).
     */
    private List<SettlementHistoryItem> monthlySettlements(List<Booking> revenueBookings) {
        Map<YearMonth, BigDecimal> grossByMonth = revenueBookings.stream()
            .collect(Collectors.groupingBy(b -> YearMonth.from(b.getCheckInDate()),
                Collectors.reducing(BigDecimal.ZERO, Booking::getFinalPrice, BigDecimal::add)));
        YearMonth currentMonth = YearMonth.now();
        return grossByMonth.entrySet().stream()
            .sorted(Map.Entry.comparingByKey())
            .map(e -> {
                BigDecimal gross = e.getValue().setScale(2, RoundingMode.HALF_UP);
                BigDecimal commission = commissionOf(gross);
                BigDecimal net = gross.subtract(commission).setScale(2, RoundingMode.HALF_UP);
                String status = e.getKey().isBefore(currentMonth) ? "PAID" : "PENDING";
                return new SettlementHistoryItem(e.getKey().toString(), gross, commission, net, status);
            })
            .toList();
    }

    private BigDecimal zero() {
        return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
