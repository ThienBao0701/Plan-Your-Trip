package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class BookingService {

    private final BookingRepository bookingRepo;
    private final HotelRoomRepository roomRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final UserRepository userRepo;
    private final PricingEngineService pricingEngine;

    public BookingService(BookingRepository bookingRepo,
                          HotelRoomRepository roomRepo,
                          RoomInventoryRepository inventoryRepo,
                          UserRepository userRepo,
                          PricingEngineService pricingEngine) {
        this.bookingRepo   = bookingRepo;
        this.roomRepo      = roomRepo;
        this.inventoryRepo = inventoryRepo;
        this.userRepo      = userRepo;
        this.pricingEngine = pricingEngine;
    }

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

        int maxAdultsTotal  = room.getMaxAdults()  != null ? room.getMaxAdults()  * numRooms : numRooms;
        int maxGuestsTotal  = room.getMaxGuests()  != null ? room.getMaxGuests()  * numRooms : numRooms;
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

    @Transactional
    public BookingResponse cancel(Long userId, Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");

        BookingStatus current = booking.getStatus();
        if (current == BookingStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Booking is already cancelled");
        if (current == BookingStatus.CHECKED_IN)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Cannot cancel a checked-in booking");
        if (current == BookingStatus.CHECKED_OUT || current == BookingStatus.NO_SHOW)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot cancel booking with status: " + current);

        booking.setStatus(BookingStatus.CANCELLED);
        booking.setCancelledAt(Instant.now());

        inventoryRepo.restoreInventory(booking.getRoom().getId(),
            booking.getCheckInDate(), booking.getCheckOutDate(), booking.getNumberOfRooms());

        return toResponse(bookingRepo.save(booking));
    }

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

    @Transactional
    public BookingResponse adminUpdateStatus(Long bookingId, BookingStatus newStatus) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));

        BookingStatus old = booking.getStatus();
        booking.setStatus(newStatus);

        if (newStatus == BookingStatus.CONFIRMED && old != BookingStatus.CONFIRMED)
            booking.setConfirmedAt(Instant.now());
        if (newStatus == BookingStatus.CANCELLED && old != BookingStatus.CANCELLED) {
            booking.setCancelledAt(Instant.now());
            inventoryRepo.restoreInventory(booking.getRoom().getId(),
                booking.getCheckInDate(), booking.getCheckOutDate(), booking.getNumberOfRooms());
        }

        return toResponse(bookingRepo.save(booking));
    }

    private String generateCode(Long id) {
        return "PYT-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", id);
    }

    private BookingResponse toResponse(Booking b) {
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
            b.getConfirmedAt(), b.getCancelledAt()
        );
    }

    private BookingSummaryResponse toSummary(Booking b) {
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
}
