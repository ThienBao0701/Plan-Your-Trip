package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

@Service
public class BookingService {

    private final BookingRepository bookingRepo;
    private final HotelRoomRepository roomRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final UserRepository userRepo;
    private final PricingEngineService pricingEngine;
    private final BookingStatusEngineService statusEngine;
    private final PaymentRepository paymentRepo;
    private final NotificationService notificationService;

    private static final Set<BookingStatus> UPCOMING_STATUSES =
        EnumSet.of(BookingStatus.PENDING, BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY);

    private static final Set<BookingStatus> ACTIVE_STATUSES =
        EnumSet.of(BookingStatus.CHECKED_IN);

    private static final Set<BookingStatus> HISTORY_STATUSES =
        EnumSet.of(BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED,
                   BookingStatus.CANCELLED, BookingStatus.REFUNDED,
                   BookingStatus.ARCHIVED, BookingStatus.NO_SHOW);

    public BookingService(BookingRepository bookingRepo,
                          HotelRoomRepository roomRepo,
                          RoomInventoryRepository inventoryRepo,
                          UserRepository userRepo,
                          PricingEngineService pricingEngine,
                          BookingStatusEngineService statusEngine,
                          PaymentRepository paymentRepo,
                          NotificationService notificationService) {
        this.bookingRepo   = bookingRepo;
        this.roomRepo      = roomRepo;
        this.inventoryRepo = inventoryRepo;
        this.userRepo      = userRepo;
        this.pricingEngine = pricingEngine;
        this.statusEngine  = statusEngine;
        this.paymentRepo   = paymentRepo;
        this.notificationService = notificationService;
    }

    // ── Create ────────────────────────────────────────────────────────────────

    @Transactional
    public BookingResponse create(Long userId, BookingRequest req) {
        LocalDate today = LocalDate.now();
        if (req.checkIn().isBefore(today))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn cannot be in the past");
        if (!req.checkOut().isAfter(req.checkIn()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut must be after checkIn");

        HotelRoom room = roomRepo.findById(req.roomId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + req.roomId()));
        if (!room.isActive())
            throw new ApiException(HttpStatus.BAD_REQUEST, "Room is not available for booking");

        Place hotel = room.getHotelDetail().getPlace();
        if (hotel.getStatus() != PlaceStatus.PUBLISHED)
            throw new ApiException(HttpStatus.BAD_REQUEST, "Hotel is not published");

        int numRooms = req.numberOfRooms() != null ? req.numberOfRooms() : 1;
        int children = req.children() != null ? req.children() : 0;

        int maxAdultsTotal = room.getMaxAdults() != null ? room.getMaxAdults() * numRooms : numRooms;
        int maxGuestsTotal = room.getMaxGuests() != null ? room.getMaxGuests() * numRooms : numRooms;
        if (req.adults() > maxAdultsTotal)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Adults exceed maximum capacity of " + maxAdultsTotal);
        if ((req.adults() + children) > maxGuestsTotal)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Total guests exceed maximum capacity of " + maxGuestsTotal);

        long nights = ChronoUnit.DAYS.between(req.checkIn(), req.checkOut());
        long availNights = inventoryRepo.countNightsWithSufficientInventory(
            req.roomId(), req.checkIn(), req.checkOut(), numRooms);
        if (availNights < nights)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Insufficient inventory for the selected dates");

        var pricing = pricingEngine.calculate(req.roomId(), req.checkIn(), req.checkOut());

        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        Booking booking = new Booking();
        booking.setUser(user);
        booking.setHotel(hotel);
        booking.setRoom(room);
        booking.setCheckInDate(req.checkIn());
        booking.setCheckOutDate(req.checkOut());
        booking.setAdults(req.adults());
        booking.setChildren(children);
        booking.setNumberOfRooms(numRooms);
        booking.setStatus(BookingStatus.PENDING);
        booking.setCurrency("VND");
        booking.setBasePrice(pricing.basePrice());
        booking.setRatePlanPrice(pricing.ratePlanPrice());
        booking.setDiscountAmount(pricing.promotionDiscount());
        booking.setFinalPrice(pricing.finalPrice());
        booking.setSpecialRequest(req.specialRequest());

        booking = bookingRepo.save(booking);
        booking.setBookingCode(generateCode(booking.getId()));
        booking = bookingRepo.save(booking);

        inventoryRepo.decrementInventory(req.roomId(), req.checkIn(), req.checkOut(), numRooms);

        return toResponse(booking);
    }

    // ── Read ──────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public BookingResponse getById(Long userId, Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!booking.getUser().getId().equals(userId) && !"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return toResponse(booking);
    }

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> getMyBookings(Long userId) {
        return bookingRepo.findByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<UpcomingBookingResponse> getUpcomingBookings(Long userId) {
        return bookingRepo.findByUserIdAndCheckInDateGreaterThanEqualAndStatusInOrderByCheckInDateAsc(
                userId, LocalDate.now(), UPCOMING_STATUSES)
            .stream().map(this::toUpcoming).toList();
    }

    @Transactional(readOnly = true)
    public List<BookingHistoryResponse> getBookingHistory(Long userId) {
        return bookingRepo.findByUserIdAndStatusInOrderByCheckInDateDesc(userId, HISTORY_STATUSES)
            .stream().map(this::toHistory).toList();
    }

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> getActiveBookings(Long userId) {
        return bookingRepo.findByUserIdAndStatusInOrderByCreatedAtDesc(userId, ACTIVE_STATUSES)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public BookingTimelineResponse getTimeline(Long userId, Long bookingId) {
        Booking b = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!b.getUser().getId().equals(userId) && !"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return buildTimeline(b);
    }

    // ── Cancel ────────────────────────────────────────────────────────────────

    @Transactional
    public BookingResponse cancel(Long userId, Long bookingId, String cancelReason) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");

        BookingStatus current = booking.getStatus();
        if (current == BookingStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Booking is already cancelled");

        Set<BookingStatus> nonCancellable = EnumSet.of(
            BookingStatus.CHECKED_IN, BookingStatus.CHECKED_OUT,
            BookingStatus.CHECK_IN_READY, BookingStatus.COMPLETED,
            BookingStatus.ARCHIVED, BookingStatus.REFUNDED, BookingStatus.NO_SHOW);
        if (nonCancellable.contains(current))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot cancel booking with status: " + current);

        booking.setStatus(BookingStatus.CANCELLED);
        booking.setCancelledAt(Instant.now());
        booking.setLastStatusChangedAt(Instant.now());
        if (cancelReason != null) booking.setCancelReason(cancelReason);

        inventoryRepo.restoreInventory(booking.getRoom().getId(),
            booking.getCheckInDate(), booking.getCheckOutDate(), booking.getNumberOfRooms());

        Booking saved = bookingRepo.save(booking);

        notificationService.create(userId, NotificationType.BOOKING, Priority.NORMAL,
            "Booking cancelled",
            "Your booking " + saved.getBookingCode() + " has been cancelled.",
            RelatedEntityType.BOOKING, saved.getId());

        return toResponse(saved);
    }

    // ── Admin: list / get ─────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> adminGetAll() {
        return bookingRepo.findAllByOrderByCreatedAtDesc()
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public BookingResponse adminGetById(Long bookingId) {
        return toResponse(bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId)));
    }

    @Transactional(readOnly = true)
    public List<BookingSummaryResponse> adminSearch(String status, String hotel,
                                                     LocalDate date, String guest,
                                                     String bookingCode) {
        Specification<Booking> spec = Specification
            .where(BookingSpecification.withStatus(status))
            .and(BookingSpecification.withHotel(hotel))
            .and(BookingSpecification.withCheckInDate(date))
            .and(BookingSpecification.withGuest(guest))
            .and(BookingSpecification.withBookingCode(bookingCode));
        return bookingRepo.findAll(spec).stream()
            .sorted(Comparator.comparing(Booking::getCreatedAt).reversed())
            .map(this::toSummary).toList();
    }

    // ── Admin: force-set status (backward compat — no engine validation) ──────

    @Transactional
    public BookingResponse adminUpdateStatus(Long bookingId, BookingStatus newStatus) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));

        BookingStatus old = booking.getStatus();
        Instant now = Instant.now();
        booking.setStatus(newStatus);
        booking.setLastStatusChangedAt(now);

        if (newStatus == BookingStatus.CONFIRMED && old != BookingStatus.CONFIRMED)
            booking.setConfirmedAt(now);
        if (newStatus == BookingStatus.CHECKED_IN && booking.getActualCheckInAt() == null)
            booking.setActualCheckInAt(now);
        if (newStatus == BookingStatus.CHECKED_OUT && booking.getActualCheckOutAt() == null)
            booking.setActualCheckOutAt(now);
        if (newStatus == BookingStatus.COMPLETED && booking.getCompletedAt() == null)
            booking.setCompletedAt(now);
        if (newStatus == BookingStatus.ARCHIVED && booking.getArchivedAt() == null)
            booking.setArchivedAt(now);
        if (newStatus == BookingStatus.CANCELLED && old != BookingStatus.CANCELLED) {
            booking.setCancelledAt(now);
            inventoryRepo.restoreInventory(booking.getRoom().getId(),
                booking.getCheckInDate(), booking.getCheckOutDate(), booking.getNumberOfRooms());
        }

        return toResponse(bookingRepo.save(booking));
    }

    // ── Admin: engine-validated transitions ───────────────────────────────────

    @Transactional
    public BookingResponse adminCheckIn(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.CHECKED_IN);
        return toResponse(bookingRepo.save(booking));
    }

    @Transactional
    public BookingResponse adminCheckOut(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.CHECKED_OUT);
        return toResponse(bookingRepo.save(booking));
    }

    @Transactional
    public BookingResponse adminComplete(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.COMPLETED);
        return toResponse(bookingRepo.save(booking));
    }

    @Transactional
    public BookingResponse adminArchive(Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        statusEngine.transition(booking, BookingStatus.ARCHIVED);
        return toResponse(bookingRepo.save(booking));
    }

    // ── Admin: timeline ───────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public BookingTimelineResponse adminGetTimeline(Long bookingId) {
        Booking b = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        return buildTimeline(b);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private BookingTimelineResponse buildTimeline(Booking b) {
        List<TimelineEvent> events = new ArrayList<>();
        events.add(new TimelineEvent("CREATED", b.getCreatedAt(), "Booking created"));

        paymentRepo.findByBookingIdOrderByCreatedAtDesc(b.getId()).stream()
            .filter(p -> p.getStatus() == PaymentStatus.PAID && p.getPaidAt() != null)
            .min(Comparator.comparing(Payment::getPaidAt))
            .ifPresent(p -> events.add(new TimelineEvent("PAID", p.getPaidAt(), "Payment completed")));

        if (b.getConfirmedAt() != null)
            events.add(new TimelineEvent("CONFIRMED", b.getConfirmedAt(), "Booking confirmed"));
        if (b.getActualCheckInAt() != null)
            events.add(new TimelineEvent("CHECKED_IN", b.getActualCheckInAt(), "Guest checked in"));
        if (b.getActualCheckOutAt() != null)
            events.add(new TimelineEvent("CHECKED_OUT", b.getActualCheckOutAt(), "Guest checked out"));
        if (b.getCompletedAt() != null)
            events.add(new TimelineEvent("COMPLETED", b.getCompletedAt(), "Reservation completed"));
        if (b.getCancelledAt() != null)
            events.add(new TimelineEvent("CANCELLED", b.getCancelledAt(), "Booking cancelled"));
        if (b.getArchivedAt() != null)
            events.add(new TimelineEvent("ARCHIVED", b.getArchivedAt(), "Reservation archived"));

        events.sort(Comparator.comparing(TimelineEvent::occurredAt));
        return new BookingTimelineResponse(b.getId(), b.getBookingCode(), events);
    }

    private String generateCode(Long id) {
        return "PYT-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", id);
    }

    BookingResponse toResponse(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new BookingResponse(
            b.getId(),
            b.getBookingCode(),
            b.getUser().getId(), b.getUser().getFullName(), b.getUser().getEmail(),
            b.getHotel().getId(), b.getHotel().getName(),
            b.getRoom().getId(), b.getRoom().getRoomName(), b.getRoom().getRoomCode(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights, b.getAdults(), b.getChildren(), b.getNumberOfRooms(),
            b.getStatus().name(),
            b.getCurrency(),
            b.getBasePrice(), b.getRatePlanPrice(),
            b.getDiscountAmount(), b.getFinalPrice(),
            b.getSpecialRequest(), b.getPartnerNote(),
            b.getCreatedAt(), b.getUpdatedAt(),
            b.getConfirmedAt(), b.getCancelledAt(),
            b.getActualCheckInAt(), b.getActualCheckOutAt(),
            b.getCompletedAt(), b.getArchivedAt(),
            b.getLastStatusChangedAt(), b.getCancelReason()
        );
    }

    BookingSummaryResponse toSummary(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new BookingSummaryResponse(
            b.getId(),
            b.getBookingCode(),
            b.getHotel().getId(), b.getHotel().getName(),
            b.getRoom().getId(), b.getRoom().getRoomName(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights,
            b.getStatus().name(),
            b.getFinalPrice(), b.getCurrency(),
            b.getCreatedAt()
        );
    }

    private UpcomingBookingResponse toUpcoming(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new UpcomingBookingResponse(
            b.getId(), b.getBookingCode(),
            b.getHotel().getName(), b.getRoom().getRoomName(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights, b.getStatus().name(),
            b.getFinalPrice(), b.getCurrency()
        );
    }

    private BookingHistoryResponse toHistory(Booking b) {
        int nights = (int) ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate());
        return new BookingHistoryResponse(
            b.getId(), b.getBookingCode(),
            b.getHotel().getName(), b.getRoom().getRoomName(),
            b.getCheckInDate(), b.getCheckOutDate(),
            nights, b.getStatus().name(),
            b.getFinalPrice(), b.getCurrency(),
            b.getCreatedAt(), b.getConfirmedAt()
        );
    }
}
