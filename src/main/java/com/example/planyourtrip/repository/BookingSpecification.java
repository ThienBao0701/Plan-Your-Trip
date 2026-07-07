package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import org.springframework.data.jpa.domain.Specification;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

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

    public static Specification<Booking> withHotelIdIn(List<Long> hotelIds) {
        if (hotelIds == null || hotelIds.isEmpty()) return (root, query, cb) -> cb.disjunction();
        return (root, query, cb) -> root.get("hotel").get("id").in(hotelIds);
    }

    public static Specification<Booking> withRoomId(Long roomId) {
        if (roomId == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("room").get("id"), roomId);
    }

    public static Specification<Booking> withCheckOutDate(LocalDate date) {
        if (date == null) return Specification.where(null);
        return (root, query, cb) -> cb.equal(root.get("checkOutDate"), date);
    }

    public static Specification<Booking> withCheckInDateRange(LocalDate from, LocalDate to) {
        if (from == null && to == null) return Specification.where(null);
        return (root, query, cb) -> {
            if (from != null && to != null) return cb.between(root.get("checkInDate"), from, to);
            if (from != null) return cb.greaterThanOrEqualTo(root.get("checkInDate"), from);
            return cb.lessThanOrEqualTo(root.get("checkInDate"), to);
        };
    }

    public static Specification<Booking> withStatusIn(Collection<BookingStatus> statuses) {
        if (statuses == null || statuses.isEmpty()) return Specification.where(null);
        return (root, query, cb) -> root.get("status").in(statuses);
    }
}
