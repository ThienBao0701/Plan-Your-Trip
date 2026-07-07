package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.BookingDto.BookingResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PartnerBookingDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerBookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@Tag(name = "Partner - Bookings", description = "Approved partners manage bookings for hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerBookingController {

    private final PartnerBookingService service;

    public PartnerBookingController(PartnerBookingService service) { this.service = service; }

    @GetMapping("/api/partner/bookings")
    @Operation(summary = "List/search my bookings (paginated)")
    public PageResponse<PartnerBookingSummaryResponse> getMyBookings(
            @AuthUser Long uid,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkInFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate checkInTo,
            @RequestParam(required = false) String guest,
            @RequestParam(required = false) String bookingCode,
            @RequestParam(required = false) Long roomId,
            @RequestParam(required = false) Boolean arrivalToday,
            @RequestParam(required = false) Boolean departureToday,
            @RequestParam(required = false) Boolean upcoming,
            @RequestParam(required = false) Boolean inHouse,
            @RequestParam(required = false) Boolean cancelled,
            @RequestParam(required = false) Boolean completed,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.getMyBookings(uid, status, date, checkInFrom, checkInTo, guest, bookingCode, roomId,
            arrivalToday, departureToday, upcoming, inHouse, cancelled, completed, page, size);
    }

    @GetMapping("/api/partner/bookings/{id}")
    @Operation(summary = "Get booking detail: booking, guest, room, hotel, payment summary, invoice summary, timeline")
    public PartnerBookingDetailResponse getBookingDetail(@AuthUser Long uid, @PathVariable Long id) {
        return service.getBookingDetail(uid, id);
    }

    @PatchMapping("/api/partner/bookings/{id}/check-in")
    @Operation(summary = "Check in guest (reuses BookingStatusEngineService)")
    public BookingResponse checkIn(@AuthUser Long uid, @PathVariable Long id) {
        return service.checkIn(uid, id);
    }

    @PatchMapping("/api/partner/bookings/{id}/check-out")
    @Operation(summary = "Check out guest (reuses BookingStatusEngineService)")
    public BookingResponse checkOut(@AuthUser Long uid, @PathVariable Long id) {
        return service.checkOut(uid, id);
    }

    @PatchMapping("/api/partner/bookings/{id}/no-show")
    @Operation(summary = "Mark booking as no-show (reuses BookingStatusEngineService)")
    public BookingResponse noShow(@AuthUser Long uid, @PathVariable Long id) {
        return service.markNoShow(uid, id);
    }

    @PatchMapping("/api/partner/bookings/{id}/complete")
    @Operation(summary = "Complete reservation (reuses BookingStatusEngineService)")
    public BookingResponse complete(@AuthUser Long uid, @PathVariable Long id) {
        return service.complete(uid, id);
    }

    @GetMapping("/api/partner/dashboard")
    @Operation(summary = "Partner dashboard summary across all owned hotels")
    public PartnerDashboardResponse getDashboard(@AuthUser Long uid) {
        return service.getDashboard(uid);
    }
}
