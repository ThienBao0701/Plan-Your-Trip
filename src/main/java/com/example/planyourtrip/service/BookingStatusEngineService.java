package com.example.planyourtrip.service;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RelatedEntityType;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import static com.example.planyourtrip.model.BookingStatus.*;

@Service
public class BookingStatusEngineService {

    private final NotificationService notificationService;

    public BookingStatusEngineService(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    private static final Map<BookingStatus, Set<BookingStatus>> ALLOWED = new HashMap<>();

    static {
        ALLOWED.put(PENDING,        EnumSet.of(CONFIRMED, CHECK_IN_READY, CANCELLED));
        ALLOWED.put(CONFIRMED,      EnumSet.of(CHECK_IN_READY, CHECKED_IN, CANCELLED, NO_SHOW));
        ALLOWED.put(CHECK_IN_READY, EnumSet.of(CHECKED_IN, CANCELLED, NO_SHOW));
        ALLOWED.put(CHECKED_IN,     EnumSet.of(CHECKED_OUT));
        ALLOWED.put(CHECKED_OUT,    EnumSet.of(COMPLETED));
        ALLOWED.put(COMPLETED,      EnumSet.of(ARCHIVED));
        ALLOWED.put(CANCELLED,      EnumSet.of(REFUNDED));
        ALLOWED.put(REFUNDED,       EnumSet.of(ARCHIVED));
        ALLOWED.put(NO_SHOW,        EnumSet.of(CANCELLED));
        ALLOWED.put(ARCHIVED,       EnumSet.noneOf(BookingStatus.class));
    }

    public Booking transition(Booking booking, BookingStatus target) {
        BookingStatus current = booking.getStatus();
        Set<BookingStatus> allowed = ALLOWED.getOrDefault(current, EnumSet.noneOf(BookingStatus.class));
        if (!allowed.contains(target)) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Illegal status transition: " + current + " → " + target);
        }
        applyTransition(booking, target, Instant.now());
        return booking;
    }

    private void applyTransition(Booking booking, BookingStatus target, Instant now) {
        booking.setStatus(target);
        booking.setLastStatusChangedAt(now);
        switch (target) {
            case CONFIRMED    -> { if (booking.getConfirmedAt() == null) booking.setConfirmedAt(now); }
            case CHECKED_IN   -> booking.setActualCheckInAt(now);
            case CHECKED_OUT  -> booking.setActualCheckOutAt(now);
            case COMPLETED    -> booking.setCompletedAt(now);
            case ARCHIVED     -> booking.setArchivedAt(now);
            case CANCELLED    -> { if (booking.getCancelledAt() == null) booking.setCancelledAt(now); }
            default           -> {}
        }
        notifyIfApplicable(booking, target);
    }

    private void notifyIfApplicable(Booking booking, BookingStatus target) {
        switch (target) {
            case CHECKED_IN -> notificationService.create(booking.getUser().getId(),
                NotificationType.BOOKING, Priority.NORMAL, "Booking checked in",
                "You have checked in for booking " + booking.getBookingCode() + ".",
                RelatedEntityType.BOOKING, booking.getId());
            case CHECKED_OUT -> notificationService.create(booking.getUser().getId(),
                NotificationType.BOOKING, Priority.NORMAL, "Booking checked out",
                "You have checked out for booking " + booking.getBookingCode() + ".",
                RelatedEntityType.BOOKING, booking.getId());
            default -> {}
        }
    }
}
