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
import com.example.planyourtrip.dto.PartnerBookingDto.PartnerBookingView;
import com.example.planyourtrip.dto.PartnerBookingDto.PartnerPaymentView;
import com.example.planyourtrip.dto.RedactedField;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
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

import static com.example.planyourtrip.security.rbac.PartnerPermission.*;

@Service
public class PartnerBookingService {

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
    private final PartnerAccessService partnerAccess;
    private final PartnerBookingRedactor redactor;

    private static final Set<BookingStatus> UPCOMING_STATUSES =
        EnumSet.of(BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY);

    private static final Set<BookingStatus> REVENUE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY, BookingStatus.CHECKED_IN,
                   BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED, BookingStatus.ARCHIVED);

    public PartnerBookingService(PlaceRepository places,
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
                                  PartnerActivityLogService activityLogService,
                                  PartnerAccessService partnerAccess,
                                  PartnerBookingRedactor redactor) {
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
        this.partnerAccess = partnerAccess;
        this.redactor = redactor;
    }

    // ── List / search ────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PageResponse<PartnerBookingSummaryResponse> getMyBookings(
            Long userId, String status, LocalDate date, LocalDate checkInFrom, LocalDate checkInTo,
            String guest, String bookingCode, Long roomId,
            Boolean arrivalToday, Boolean departureToday, Boolean upcoming,
            Boolean inHouse, Boolean cancelled, Boolean completed,
            int page, int size) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        // §4.5 COLLECTION (booking): bookings of the properties the caller may view, filtered in the query (B5)
        List<Long> hotelIds = partnerAccess.propertyIds(access, partnerAccess.requireCollection(access, BOOKING_VIEW));
        LocalDate today = LocalDate.now();

        Specification<Booking> spec = Specification
            .where(BookingSpecification.withHotelIdIn(hotelIds))
            .and(BookingSpecification.withStatus(status))
            .and(guestFilter(access, hotelIds, guest))
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
        return PageResponse.of(bookingRepo.findAll(spec, pageable).map(b -> toPartnerSummary(access, b)));
    }

    /**
     * RBAC (§21, I12) — {@code guest} is a substring match on the guest's name and email, so its rows and
     * {@code totalElements} would answer "does this guest's name or email contain X?". It therefore matches the
     * name only where the caller holds P54 and the email only where they hold P35, within the P34 properties.
     * Held nowhere (REVENUE, VIEWER): 403 {@code PERMISSION_DENIED}, decided before any query, the same for every
     * value and never echoing it. FINANCE (P54 without P35) searches names only.
     */
    private Specification<Booking> guestFilter(PartnerAccessContext access, List<Long> hotelIds, String guest) {
        if (guest == null || guest.isBlank()) return Specification.where(null);
        List<Long> names = partnerAccess.propertyIdsHolding(access, BOOKING_GUEST_IDENTITY_VIEW).stream()
            .filter(hotelIds::contains).toList();
        List<Long> emails = partnerAccess.propertyIdsHolding(access, BOOKING_GUEST_CONTACT_VIEW).stream()
            .filter(hotelIds::contains).toList();
        if (names.isEmpty() && emails.isEmpty()) {
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
        }
        return BookingSpecification.withGuestVisibleIn(guest, names, emails);
    }

    // ── Detail ───────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PartnerBookingDetailResponse getBookingDetail(Long userId, Long bookingId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        Booking booking = authorizedBooking(access, BOOKING_VIEW, bookingId);

        PartnerBookingView view = redactor.view(access, booking);
        List<RedactedField> redacted = new ArrayList<>();
        view.redacted().forEach(r -> redacted.add(new RedactedField("booking." + r.field(), r.mode())));
        List<PartnerPaymentView> payments = null;
        InvoiceSummaryResponse invoice = null;
        if (redactor.may(access, BOOKING_PAYMENT_VIEW, booking)) {
            payments = paymentRepo.findByBookingIdOrderByCreatedAtDesc(bookingId).stream()
                .map(paymentService::toResponse).map(PartnerBookingRedactor::payment).toList();
            invoice = invoiceRepo.findByBookingId(bookingId).map(invoiceService::toSummary).orElse(null);
        } else {
            redacted.add(RedactedField.omitted("payments"));
            redacted.add(RedactedField.omitted("invoice"));
        }
        BookingTimelineResponse timeline = bookingService.adminGetTimeline(bookingId);

        return new PartnerBookingDetailResponse(view, payments, invoice, timeline, List.copyOf(redacted));
    }

    // ── Phase 7.42 — Consolidated READ-ONLY guest stay detail ──────────────────

    /**
     * Phase 7.42 — one consolidated, ownership-scoped, strictly READ-ONLY guest-stay projection for a
     * single booking. RBAC R3b: authorized as a RESOURCE (booking) needing booking.stay.view ({@link #authorizedBooking} +
     * {@link #ownedBookingOrThrow}, which already returns a uniform 404 for both an unknown booking and
     * a booking outside the caller's properties — so another partner's booking never leaks), the SAME
     * lifecycle timeline ({@link BookingService#adminGetTimeline}) and the SAME voucher-status derivation
     * ({@link BookingService#partnerVoucherStatus}) as the existing endpoints. Performs NO mutation: it
     * only reads the booking, its timeline, its immutable modification history and its at-most-one
     * check-in / check-out audit rows. Bounded, deterministic (ascending) per-booking queries — no N+1.
     */
    @Transactional(readOnly = true)
    public PartnerGuestStayResponse getGuestStay(Long userId, Long bookingId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        // §25.1 Stay: RESOURCE (booking) needing booking.stay.view (P40); view(type) stays booking.view
        Booking booking = authorizedBooking(access, BOOKING_STAY_VIEW, bookingId);
        List<RedactedField> redacted = new ArrayList<>();

        BookingTimelineResponse timeline = bookingService.adminGetTimeline(bookingId);
        VoucherStatus vs = bookingService.partnerVoucherStatus(booking);

        List<StayModification> modifications = bookingModificationRepo
            .findByBookingIdOrderByCreatedAtAscIdAsc(bookingId)
            .stream().map(this::toStayModification).toList();

        StayCheckAudit checkInAudit = checkInAuditRepo.findByBookingId(bookingId).stream()
            .findFirst().map(a -> toCheckInAudit(access, a)).orElse(null);
        StayCheckAudit checkOutAudit = checkOutAuditRepo.findByBookingId(bookingId).stream()
            .findFirst().map(a -> toCheckOutAudit(access, a)).orElse(null);

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
            redactor.guestName(access, booking, booking.getUser().getFullName(), redacted, "guestName"),
            new OccupancyInfo(booking.getAdults(), booking.getChildren()),
            booking.getHotel().getId(), booking.getHotel().getName(),
            booking.getRoom().getId(), booking.getRoom().getRoomName(), booking.getRoom().getRoomCode(),
            schedule,
            new VoucherSummary(vs == VoucherStatus.VALID, vs.name()),
            timeline,
            modifications,
            checkInAudit, checkOutAudit,
            deriveWarnings(booking, today),
            List.copyOf(redacted));
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

    /**
     * §16 PA-4 step 4 — a check audit written by another company (the property moved since) shows the operation
     * and time, never that company's identity or staff.
     */
    private StayCheckAudit toCheckInAudit(PartnerAccessContext access, BookingCheckInAudit a) {
        boolean own = access.companyId().equals(a.getPartnerProfileId());
        return new StayCheckAudit(own ? a.getPartnerProfileId() : null, own ? a.getPartnerUserId() : null,
            a.getOperation(), null, a.getCreatedAt());
    }

    private StayCheckAudit toCheckOutAudit(PartnerAccessContext access, BookingCheckOutAudit a) {
        boolean own = access.companyId().equals(a.getPartnerProfileId());
        return new StayCheckAudit(own ? a.getPartnerProfileId() : null, own ? a.getPartnerUserId() : null,
            a.getOperation(), a.getMethod().name(), a.getCreatedAt());
    }

    // ── Status transitions ──────────────────────────────────────────────────

    @Transactional
    public PartnerBookingView checkIn(Long userId, Long bookingId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        Booking booking = authorizedBooking(access, BOOKING_ARRIVAL_OPERATE, bookingId);
        statusEngine.transition(booking, BookingStatus.CHECKED_IN);
        Booking saved = bookingRepo.save(booking);
        logStatusChange(access.companyId(), userId, saved);
        return redactor.view(access, saved);
    }

    @Transactional
    public PartnerBookingView checkOut(Long userId, Long bookingId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        Booking booking = authorizedBooking(access, BOOKING_DEPARTURE_OPERATE, bookingId);
        statusEngine.transition(booking, BookingStatus.CHECKED_OUT);
        Booking saved = bookingRepo.save(booking);
        logStatusChange(access.companyId(), userId, saved);
        return redactor.view(access, saved);
    }

    @Transactional
    public PartnerBookingView markNoShow(Long userId, Long bookingId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        Booking booking = authorizedBooking(access, BOOKING_NO_SHOW_MARK, bookingId);
        statusEngine.transition(booking, BookingStatus.NO_SHOW);
        Booking saved = bookingRepo.save(booking);
        notifyAdminsNoShow(saved);
        logStatusChange(access.companyId(), userId, saved);
        return redactor.view(access, saved);
    }

    @Transactional
    public PartnerBookingView complete(Long userId, Long bookingId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        Booking booking = authorizedBooking(access, BOOKING_DEPARTURE_OPERATE, bookingId);
        statusEngine.transition(booking, BookingStatus.COMPLETED);
        Booking saved = bookingRepo.save(booking);
        logStatusChange(access.companyId(), userId, saved);
        return redactor.view(access, saved);
    }

    private void logStatusChange(Long partnerProfileId, Long userId, Booking booking) {
        activityLogService.log(partnerProfileId, userId, "BOOKING_STATUS_CHANGED", "BOOKING", booking.getId(),
            "Booking " + booking.getBookingCode() + " status changed to " + booking.getStatus());
    }

    // ── Dashboard ────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public PartnerDashboardResponse getDashboard(Long userId) {
        PartnerAccessContext access = partnerAccess.requireWorkspace(userId);
        // §25.1 dashboard: COLLECTION (booking) over S, revenue fields need finance.revenue.view (P49) over all of it
        List<Long> hotelIds = partnerAccess.propertyIds(access, partnerAccess.requireCollection(access, BOOKING_VIEW));
        boolean revenue = partnerAccess.holdsOver(access, FINANCE_REVENUE_VIEW, hotelIds);
        List<RedactedField> redacted = revenue ? List.of()
            : List.of(RedactedField.omitted("revenueToday"), RedactedField.omitted("revenueMonth"));
        if (hotelIds.isEmpty()) {
            return new PartnerDashboardResponse(0, 0, 0, 0, 0, 0, 0.0,
                revenue ? BigDecimal.ZERO.setScale(2) : null, revenue ? BigDecimal.ZERO.setScale(2) : null, 0.0,
                redacted);
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
            revenue ? revenueToday.setScale(2, RoundingMode.HALF_UP) : null,
            revenue ? revenueMonth.setScale(2, RoundingMode.HALF_UP) : null,
            round2(averageStay),
            redacted
        );
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    /**
     * RBAC R3b — §4.5 RESOURCE (booking): the booking lives at {@code booking.hotel}'s property; the caller needs
     * {@code permission} there (404 without booking view there, 403 with view but not this action).
     */
    private Booking authorizedBooking(PartnerAccessContext access, PartnerPermission permission, Long bookingId) {
        partnerAccess.requireResource(access, permission, ResourceType.BOOKING, bookingId, "Booking not found: " + bookingId);
        return bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
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

    private PartnerBookingSummaryResponse toPartnerSummary(PartnerAccessContext access, Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        List<RedactedField> redacted = new ArrayList<>();
        String guestName = redactor.guestName(access, b, b.getUser().getFullName(), redacted, "guestName");
        String guestEmail = redactor.guestEmail(access, b, b.getUser().getEmail(), redacted, "guestEmail");
        return new PartnerBookingSummaryResponse(
            b.getId(), b.getBookingCode(),
            b.getRoom().getId(), b.getRoom().getRoomName(), b.getRoom().getRoomCode(),
            guestName, guestEmail,
            b.getCheckInDate(), b.getCheckOutDate(), nights,
            b.getStatus().name(), b.getFinalPrice(), b.getCurrency(),
            b.getCreatedAt(), List.copyOf(redacted)
        );
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
