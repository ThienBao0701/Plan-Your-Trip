package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;

public final class BookingSpecification {

    private BookingSpecification() {}

    public static Specification<Booking> withStatus(String status) {
        if (status == null || status.isBlank()) return Specification.where(null);
        try {
            BookingStatus s = BookingStatus.valueOf(status.toUpperCase());
            return (root, query, cb) -> cb.equal(root.get("status"), s);
        } catch (IllegalArgumentException e) {
            return Specification.where(null);
        }
    }

    public static Specification<Booking> withHotel(String hotel) {
        if (hotel == null || hotel.isBlank()) return Specification.where(null);
        String like = "%" + hotel.toLowerCase() + "%";
        return (root, query, cb) ->
            cb.like(cb.lower(root.get("hotel").get("name")), like);
    }

    public static Specification<Booking> withCheckInDate(LocalDate date) {
        if (date == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("checkInDate"), date);
    }

    public static Specification<Booking> withGuest(String guest) {
        if (guest == null || guest.isBlank()) return Specification.where(null);
        String like = "%" + guest.toLowerCase() + "%";
        return (root, query, cb) -> cb.or(
            cb.like(cb.lower(root.get("user").get("fullName")), like),
            cb.like(cb.lower(root.get("user").get("email")), like)
        );
    }

    public static Specification<Booking> withBookingCode(String code) {
        if (code == null || code.isBlank()) return Specification.where(null);
        return (root, query, cb) ->
            cb.equal(cb.upper(root.get("bookingCode")), code.toUpperCase());
    }
}
