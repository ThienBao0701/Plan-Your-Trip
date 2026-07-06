package com.example.planyourtrip.repository;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

import java.time.LocalDate;
import java.util.Collection;
import java.util.List;

public interface BookingRepository extends JpaRepository<Booking, Long>,
        JpaSpecificationExecutor<Booking> {

    List<Booking> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Booking> findAllByOrderByCreatedAtDesc();

    List<Booking> findByUserIdAndCheckInDateGreaterThanEqualAndStatusInOrderByCheckInDateAsc(
            Long userId, LocalDate from, Collection<BookingStatus> statuses);

    List<Booking> findByUserIdAndStatusInOrderByCheckInDateDesc(
            Long userId, Collection<BookingStatus> statuses);

    List<Booking> findByUserIdAndStatusInOrderByCreatedAtDesc(
            Long userId, Collection<BookingStatus> statuses);
}
