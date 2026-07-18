package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.BookingDto.BookingResponse;
import com.example.planyourtrip.dto.BookingDto.BookingTimelineResponse;
import com.example.planyourtrip.dto.BookingVoucherDto.VoucherStatus;
import com.example.planyourtrip.dto.InvoiceDto.InvoiceSummaryResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PartnerBookingDto.*;
import com.example.planyourtrip.dto.PartnerGuestStayDto.*;
import com.example.planyourtrip.dto.PaymentDto.PaymentResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Objects;
import java.util.Set;

@Service
public class PartnerBookingService {

    private final PartnerProfileRepository partnerProfiles;
    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final BookingRepository bookingRepo;
    private final PaymentRepository paymentRepo;
    private final InvoiceRepository invoiceRepo;
    private final UserRepository userRepo;
    private final BookingModificationRepository bookingModificationRepo;
    private final BookingCheckInAuditRepository checkInAuditRepo;
    private final BookingCheckOutAuditRepository checkOutAuditRepo;
    private final BookingService bookingService;
    private final PaymentService paymentService;
    private final InvoiceService invoiceService;
    private final BookingStatusEngineService statusEngine;
    private final NotificationService notificationService;
    private final PartnerActivityLogService activityLogService;

    private static final Set<BookingStatus> UPCOMING_STATUSES =
        EnumSet.of(BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY);

    private static final Set<BookingStatus> REVENUE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY, BookingStatus.CHECKED_IN,
                   BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED, BookingStatus.ARCHIVED);

    public PartnerBookingService(PartnerProfileRepository partnerProfiles,
                                  PlaceRepository places,
                                  HotelDetailRepository hotelDetails,
                                  HotelRoomRepository rooms,
                                  BookingRepository bookingRepo,
                                  PaymentRepository paymentRepo,
                                  InvoiceRepository invoiceRepo,
                                  UserRepository userRepo,
                                  BookingModificationRepository bookingModificationRepo,
                                  BookingCheckInAuditRepository checkInAuditRepo,
                                  BookingCheckOutAuditRepository checkOutAuditRepo,
                                  BookingService bookingService,
                                  PaymentService paymentService,
                                  InvoiceService invoiceService,
                                  BookingStatusEngineService statusEngine,
                                  NotificationService notificationService,
                                  PartnerActivityLogService activityLogService) {
        this.partnerProfiles = partnerProfiles;
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.bookingRepo = bookingRepo;
        this.paymentRepo = paymentRepo;
        this.invoiceRepo = invoiceRepo;
        this.userRepo = userRepo;
        this.bookingModificationRepo = bookingModificationRepo;
        this.checkInAuditRepo = checkInAuditRepo;
        this.checkOutAuditRepo = checkOutAuditRepo;
        this.bookingService = bookingService;
        this.paymentService = paymentService;
        this.invoiceService = invoiceService;
        this.statusEngine = statusEngine;
        this.notificationService = notificationService;
        this.activityLogService = activityLogService;
    }

    // ── List / search ────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PageResponse<PartnerBookingSummaryResponse> getMyBookings(
            Long userId, String status, LocalDate date, LocalDate checkInFrom, LocalDate checkInTo,
            String guest, String bookingCode, Long roomId,
            Boolean arrivalToday, Boolean departureToday, Boolean upcoming,
            Boolean inHouse, Boolean cancelled, Boolean completed,
            int page, int size) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = ownedHotelIds(profile.getId());
        LocalDate today = LocalDate.now();

        Specification<Booking> spec = Specification
            .where(BookingSpecification.withHotelIdIn(hotelIds))
            .and(BookingSpecification.withStatus(status))
            .and(BookingSpecification.withGuest(guest))
            .and(BookingSpecification.withBookingCode(bookingCode))
            .and(BookingSpecification.withRoomId(roomId))
            .and(BookingSpecification.withCheckInDateRange(checkInFrom, checkInTo))
            .and(BookingSpecification.withCheckInDate(date));

        if (Boolean.TRUE.equals(arrivalToday))
            spec = spec.and(BookingSpecification.withCheckInDate(today));
        if (Boolean.TRUE.equals(departureToday))
            spec = spec.and(BookingSpecification.withCheckOutDate(today));
        if (Boolean.TRUE.equals(upcoming))
            spec = spec.and(BookingSpecification.withCheckInDateRange(today, null))
                       .and(BookingSpecification.withStatusIn(UPCOMING_STATUSES));
        if (Boolean.TRUE.equals(inHouse))
            spec = spec.and(BookingSpecification.withStatusIn(EnumSet.of(BookingStatus.CHECKED_IN)));
        if (Boolean.TRUE.equals(cancelled))
            spec = spec.and(BookingSpecification.withStatusIn(EnumSet.of(BookingStatus.CANCELLED)));
        if (Boolean.TRUE.equals(completed))
            spec = spec.and(BookingSpecification.withStatusIn(EnumSet.of(BookingStatus.COMPLETED)));

        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return PageResponse.of(bookingRepo.findAll(spec, pageable).map(this::toPartnerSummary));
    }

    // ── Detail ───────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PartnerBookingDetailResponse getBookingDetail(Long userId, Long bookingId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Booking booking = ownedBookingOrThrow(bookingId, profile.getId());

        BookingResponse bookingResponse = bookingService.toResponse(booking);
        List<PaymentResponse> payments = paymentRepo.findByBookingIdOrderByCreatedAtDesc(bookingId)
            .stream().map(paymentService::toResponse).toList();
        InvoiceSummaryResponse invoice = invoiceRepo.findByBookingId(bookingId)
            .map(invoiceService::toSummary).orElse(null);
        BookingTimelineResponse timeline = bookingService.adminGetTimeline(bookingId);

        return new PartnerBookingDetailResponse(bookingResponse, payments, invoice, timeline);
    }

    // ── Phase 7.42 — Consolidated READ-ONLY guest stay detail ──────────────────

    /**
     * Phase 7.42 — one consolidated, ownership-scoped, strictly READ-ONLY guest-stay projection for a
     * single booking. Reuses the SAME ownership resolution ({@link #myApprovedProfileOrThrow} +
     * {@link #ownedBookingOrThrow}, which already returns a uniform 404 for both an unknown booking and
     * a booking outside the caller's properties — so another partner's booking never leaks), the SAME
     * lifecycle timeline ({@link BookingService#adminGetTimeline}) and the SAME voucher-status derivation
     * ({@link BookingService#partnerVoucherStatus}) as the existing endpoints. Performs NO mutation: it
     * only reads the booking, its timeline, its immutable modification history and its at-most-one
     * check-in / check-out audit rows. Bounded, deterministic (ascending) per-booking queries — no N+1.
     */
    @Transactional(readOnly = true)
    public PartnerGuestStayResponse getGuestStay(Long userId, Long bookingId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Booking booking = ownedBookingOrThrow(bookingId, profile.getId());

        BookingTimelineResponse timeline = bookingService.adminGetTimeline(bookingId);
        VoucherStatus vs = bookingService.partnerVoucherStatus(booking);

        List<StayModification> modifications = bookingModificationRepo
            .findByBookingIdOrderByCreatedAtAscIdAsc(bookingId)
            .stream().map(this::toStayModification).toList();

        StayCheckAudit checkInAudit = checkInAuditRepo.findByBookingId(bookingId).stream()
            .findFirst().map(this::toCheckInAudit).orElse(null);
        StayCheckAudit checkOutAudit = checkOutAuditRepo.findByBookingId(bookingId).stream()
            .findFirst().map(this::toCheckOutAudit).orElse(null);

        LocalDate today = LocalDate.now();
        long totalNights = Math.max(0,
            ChronoUnit.DAYS.between(booking.getCheckInDate(), booking.getCheckOutDate()));
        long currentNight = currentNightNumber(booking, today, totalNights);
        long remainingNights = Math.max(0, totalNights - currentNight);

        StaySchedule schedule = new StaySchedule(
            booking.getCheckInDate(), booking.getCheckOutDate(), totalNights,
            booking.getActualCheckInAt(), booking.getActualCheckOutAt(),
            deriveStayState(booking, today), currentNight, remainingNights);

        return new PartnerGuestStayResponse(
            booking.getId(), booking.getBookingCode(), booking.getStatus().name(),
            booking.getCreatedAt(), booking.getUpdatedAt(),
            booking.getUser().getFullName(),
            new OccupancyInfo(booking.getAdults(), booking.getChildren()),
            booking.getHotel().getId(), booking.getHotel().getName(),
            booking.getRoom().getId(), booking.getRoom().getRoomName(), booking.getRoom().getRoomCode(),
            schedule,
            new VoucherSummary(vs == VoucherStatus.VALID, vs.name()),
            timeline,
            modifications,
            checkInAudit, checkOutAudit,
            deriveWarnings(booking, today));
    }

    /**
     * Derive the response-level {@code currentStayState} from persisted status + dates + today
     * (using {@code LocalDate.now()}, the convention the rest of the booking/check-in code uses — no
     * property timezone exists). Table (real {@link BookingStatus} values):
     * <pre>
     *   CANCELLED / REFUNDED                                → CANCELLED
     *   NO_SHOW                                             → NO_SHOW
     *   CHECKED_OUT                                         → CHECKED_OUT
     *   COMPLETED / ARCHIVED                                → COMPLETED
     *   CHECKED_IN                                          → IN_HOUSE
     *   CONFIRMED / CHECK_IN_READY, today &lt; checkIn      → UPCOMING
     *   CONFIRMED / CHECK_IN_READY, checkIn &le; today &le; checkOut → READY_FOR_CHECK_IN
     *   CONFIRMED / CHECK_IN_READY, today &gt; checkOut     → EXPIRED (window passed, never checked in)
     *   PENDING, today &gt; checkOut                        → EXPIRED
     *   PENDING, otherwise                                 → UPCOMING (not confirmed ⇒ not check-in ready)
     * </pre>
     */
    private String deriveStayState(Booking b, LocalDate today) {
        switch (b.getStatus()) {
            case CANCELLED:
            case REFUNDED:
                return "CANCELLED";
            case NO_SHOW:
                return "NO_SHOW";
            case CHECKED_OUT:
                return "CHECKED_OUT";
            case COMPLETED:
            case ARCHIVED:
                return "COMPLETED";
            case CHECKED_IN:
                return "IN_HOUSE";
            case CONFIRMED:
            case CHECK_IN_READY:
                if (today.isBefore(b.getCheckInDate())) return "UPCOMING";
                if (!today.isAfter(b.getCheckOutDate())) return "READY_FOR_CHECK_IN";
                return "EXPIRED";
            case PENDING:
            default:
                return today.isAfter(b.getCheckOutDate()) ? "EXPIRED" : "UPCOMING";
        }
    }

    /**
     * Deterministic, never-negative current night number.
     * <ul>
     *   <li>CHECKED_OUT / COMPLETED / ARCHIVED → {@code totalNights} (stay fully elapsed).</li>
     *   <li>CHECKED_IN (in-house) → nights elapsed since check-in, {@code arrival day = night 1}
     *       ({@code DAYS.between(checkIn, today) + 1}), clamped to {@code [1, totalNights]} (an early
     *       check-in before {@code checkInDate} clamps up to 1; a same-day arrival is night 1).</li>
     *   <li>every other state (future / not-yet-checked-in / cancelled / refunded / no-show) → 0.</li>
     * </ul>
     * When {@code totalNights == 0} (degenerate same-day check-in/out) the result is 0.
     */
    private long currentNightNumber(Booking b, LocalDate today, long totalNights) {
        switch (b.getStatus()) {
            case CHECKED_OUT:
            case COMPLETED:
            case ARCHIVED:
                return totalNights;
            case CHECKED_IN:
                if (totalNights == 0) return 0;
                long elapsed = ChronoUnit.DAYS.between(b.getCheckInDate(), today) + 1;
                return Math.max(1, Math.min(elapsed, totalNights));
            default:
                return 0;
        }
    }

    /**
     * Derive operational warning tokens from status + dates + today (documented conditions):
     * <ul>
     *   <li>{@code CANCELLED_STAY} — CANCELLED / REFUNDED / NO_SHOW.</li>
     *   <li>{@code COMPLETED_STAY} — CHECKED_OUT / COMPLETED / ARCHIVED.</li>
     *   <li>{@code CURRENTLY_STAYING} — CHECKED_IN; plus {@code CHECK_OUT_OVERDUE} when
     *       {@code today > checkOutDate}.</li>
     *   <li>Pre-arrival active states (PENDING / CONFIRMED / CHECK_IN_READY):
     *       {@code FUTURE_BOOKING} when {@code today < checkInDate}, or {@code CHECK_IN_OVERDUE} when
     *       {@code today > checkInDate} (arrival day itself is neither).</li>
     * </ul>
     */
    private List<String> deriveWarnings(Booking b, LocalDate today) {
        List<String> warnings = new ArrayList<>();
        switch (b.getStatus()) {
            case CANCELLED:
            case REFUNDED:
            case NO_SHOW:
                warnings.add("CANCELLED_STAY");
                return warnings;
            case CHECKED_OUT:
            case COMPLETED:
            case ARCHIVED:
                warnings.add("COMPLETED_STAY");
                return warnings;
            case CHECKED_IN:
                warnings.add("CURRENTLY_STAYING");
                if (today.isAfter(b.getCheckOutDate())) warnings.add("CHECK_OUT_OVERDUE");
                return warnings;
            default: // PENDING / CONFIRMED / CHECK_IN_READY
                if (today.isBefore(b.getCheckInDate())) warnings.add("FUTURE_BOOKING");
                else if (today.isAfter(b.getCheckInDate())) warnings.add("CHECK_IN_OVERDUE");
                return warnings;
        }
    }

    private StayModification toStayModification(BookingModification m) {
        return new StayModification(
            m.getOldCheckInDate(), m.getNewCheckInDate(),
            m.getOldCheckOutDate(), m.getNewCheckOutDate(),
            m.getOldAdults(), m.getNewAdults(),
            m.getOldChildren(), m.getNewChildren(),
            m.getOldRatePlanId(), m.getNewRatePlanId(),
            m.getOldRatePlanName(), m.getNewRatePlanName(),
            m.getOldTotalPrice(), m.getNewTotalPrice(),
            m.getCreatedAt());
    }

    private StayCheckAudit toCheckInAudit(BookingCheckInAudit a) {
        return new StayCheckAudit(a.getPartnerProfileId(), a.getPartnerUserId(),
            a.getOperation(), null, a.getCreatedAt());
    }

    private StayCheckAudit toCheckOutAudit(BookingCheckOutAudit a) {
        return new StayCheckAudit(a.getPartnerProfileId(), a.getPartnerUserId(),
            a.getOperation(), a.getMethod().name(), a.getCreatedAt());
    }

    // ── Status transitions ──────────────────────────────────────────────────

    @Transactional
    public BookingResponse checkIn(Long userId, Long bookingId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Booking booking = ownedBookingOrThrow(bookingId, profile.getId());
        statusEngine.transition(booking, BookingStatus.CHECKED_IN);
        Booking saved = bookingRepo.save(booking);
        logStatusChange(profile.getId(), userId, saved);
        return bookingService.toResponse(saved);
    }

    @Transactional
    public BookingResponse checkOut(Long userId, Long bookingId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Booking booking = ownedBookingOrThrow(bookingId, profile.getId());
        statusEngine.transition(booking, BookingStatus.CHECKED_OUT);
        Booking saved = bookingRepo.save(booking);
        logStatusChange(profile.getId(), userId, saved);
        return bookingService.toResponse(saved);
    }

    @Transactional
    public BookingResponse markNoShow(Long userId, Long bookingId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Booking booking = ownedBookingOrThrow(bookingId, profile.getId());
        statusEngine.transition(booking, BookingStatus.NO_SHOW);
        Booking saved = bookingRepo.save(booking);
        notifyAdminsNoShow(saved);
        logStatusChange(profile.getId(), userId, saved);
        return bookingService.toResponse(saved);
    }

    @Transactional
    public BookingResponse complete(Long userId, Long bookingId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Booking booking = ownedBookingOrThrow(bookingId, profile.getId());
        statusEngine.transition(booking, BookingStatus.COMPLETED);
        Booking saved = bookingRepo.save(booking);
        logStatusChange(profile.getId(), userId, saved);
        return bookingService.toResponse(saved);
    }

    private void logStatusChange(Long partnerProfileId, Long userId, Booking booking) {
        activityLogService.log(partnerProfileId, userId, "BOOKING_STATUS_CHANGED", "BOOKING", booking.getId(),
            "Booking " + booking.getBookingCode() + " status changed to " + booking.getStatus());
    }

    // ── Dashboard ────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PartnerDashboardResponse getDashboard(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = ownedHotelIds(profile.getId());
        if (hotelIds.isEmpty()) {
            return new PartnerDashboardResponse(0, 0, 0, 0, 0, 0, 0.0,
                BigDecimal.ZERO.setScale(2), BigDecimal.ZERO.setScale(2), 0.0);
        }

        LocalDate today = LocalDate.now();
        List<Booking> all = bookingRepo.findAll(
            Specification.where(BookingSpecification.withHotelIdIn(hotelIds)));

        long arrivalsToday = all.stream()
            .filter(b -> b.getCheckInDate().equals(today) && b.getStatus() != BookingStatus.CANCELLED)
            .count();
        long departuresToday = all.stream()
            .filter(b -> b.getCheckOutDate().equals(today) && b.getStatus() != BookingStatus.CANCELLED)
            .count();
        long currentGuests = all.stream().filter(b -> b.getStatus() == BookingStatus.CHECKED_IN).count();
        long upcomingCount = all.stream()
            .filter(b -> !b.getCheckInDate().isBefore(today) && UPCOMING_STATUSES.contains(b.getStatus()))
            .count();
        long cancelledCount = all.stream().filter(b -> b.getStatus() == BookingStatus.CANCELLED).count();
        long completedCount = all.stream().filter(b -> b.getStatus() == BookingStatus.COMPLETED).count();

        BigDecimal revenueToday = all.stream()
            .filter(b -> b.getCheckInDate().equals(today) && REVENUE_STATUSES.contains(b.getStatus()))
            .map(Booking::getFinalPrice)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        YearMonth thisMonth = YearMonth.now();
        BigDecimal revenueMonth = all.stream()
            .filter(b -> YearMonth.from(b.getCheckInDate()).equals(thisMonth) && REVENUE_STATUSES.contains(b.getStatus()))
            .map(Booking::getFinalPrice)
            .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<Booking> stayedBookings = all.stream()
            .filter(b -> b.getStatus() == BookingStatus.CHECKED_OUT || b.getStatus() == BookingStatus.COMPLETED)
            .toList();
        double averageStay = stayedBookings.isEmpty() ? 0.0 : stayedBookings.stream()
            .mapToLong(b -> ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate()))
            .average().orElse(0.0);

        int capacity = totalRoomCapacity(hotelIds);
        int occupiedRooms = all.stream()
            .filter(b -> b.getStatus() == BookingStatus.CHECKED_IN)
            .mapToInt(Booking::getNumberOfRooms).sum();
        double occupancyRate = capacity > 0 ? (occupiedRooms * 100.0 / capacity) : 0.0;

        return new PartnerDashboardResponse(
            arrivalsToday, departuresToday, currentGuests, upcomingCount, cancelledCount, completedCount,
            round2(occupancyRate),
            revenueToday.setScale(2, RoundingMode.HALF_UP),
            revenueMonth.setScale(2, RoundingMode.HALF_UP),
            round2(averageStay)
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private List<Long> ownedHotelIds(Long ownerId) {
        return places.findAllByOwnerId(ownerId).stream().map(Place::getId).toList();
    }

    private Booking ownedBookingOrThrow(Long bookingId, Long ownerId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        PartnerProfile owner = booking.getHotel().getOwner();
        if (owner == null || !owner.getId().equals(ownerId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId);
        return booking;
    }

    private int totalRoomCapacity(List<Long> hotelIds) {
        return hotelIds.stream()
            .map(hotelId -> hotelDetails.findByPlaceId(hotelId).orElse(null))
            .filter(Objects::nonNull)
            .flatMap(hd -> rooms.findAllByHotelDetailId(hd.getId()).stream())
            .mapToInt(r -> r.getQuantity() != null ? r.getQuantity() : 0)
            .sum();
    }

    private void notifyAdminsNoShow(Booking booking) {
        userRepo.findAll().stream()
            .filter(u -> "ADMIN".equals(u.getRole()))
            .forEach(admin -> notificationService.create(admin.getId(), NotificationType.ADMIN, Priority.HIGH,
                "Booking marked as no-show",
                "Booking " + booking.getBookingCode() + " at " + booking.getHotel().getName()
                    + " was marked as a no-show.",
                RelatedEntityType.BOOKING, booking.getId()));
    }

    private PartnerBookingSummaryResponse toPartnerSummary(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new PartnerBookingSummaryResponse(
            b.getId(), b.getBookingCode(),
            b.getRoom().getId(), b.getRoom().getRoomName(), b.getRoom().getRoomCode(),
            b.getUser().getFullName(), b.getUser().getEmail(),
            b.getCheckInDate(), b.getCheckOutDate(), nights,
            b.getStatus().name(), b.getFinalPrice(), b.getCurrency(),
            b.getCreatedAt()
        );
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
