package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.BookingDto.BookingResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PartnerBookingDto.*;
import com.example.planyourtrip.dto.PartnerCheckInDto.CheckInRequest;
import com.example.planyourtrip.dto.PartnerCheckInDto.CheckInResponse;
import com.example.planyourtrip.dto.PartnerCheckOutDto.CheckOutRequest;
import com.example.planyourtrip.dto.PartnerCheckOutDto.CheckOutResponse;
import com.example.planyourtrip.dto.PartnerVoucherDto.VoucherVerificationResponse;
import com.example.planyourtrip.dto.PartnerVoucherDto.VoucherVerifyRequest;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerBookingService;
import com.example.planyourtrip.service.PartnerCheckInService;
import com.example.planyourtrip.service.PartnerCheckOutService;
import com.example.planyourtrip.service.PartnerVoucherVerificationService;
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
    private final PartnerVoucherVerificationService voucherVerificationService;
    private final PartnerCheckInService checkInService;
    private final PartnerCheckOutService checkOutService;

    public PartnerBookingController(PartnerBookingService service,
                                    PartnerVoucherVerificationService voucherVerificationService,
                                    PartnerCheckInService checkInService,
                                    PartnerCheckOutService checkOutService) {
        this.service = service;
        this.voucherVerificationService = voucherVerificationService;
        this.checkInService = checkInService;
        this.checkOutService = checkOutService;
    }

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

    // ── Phase 7.39 — Partner Voucher Verification (read-only; NO check-in) ──────

    @PostMapping("/api/partner/bookings/voucher/verify")
    @Operation(summary = "Verify a signed customer voucher QR payload for one of my hotels",
        description = "Verifies the Phase 7.38 HMAC-signed voucher payload, resolves the booking, "
            + "confirms it belongs to one of the caller's OWN hotels and reports check-in eligibility. "
            + "Strictly READ-ONLY — performs no check-in and mutates nothing (check-in is deferred to "
            + "Phase 7.40). Invalid signature / unknown booking / another partner's booking all return "
            + "a uniform 404; a valid, owned but ineligible booking returns 200 with eligible=false.")
    public VoucherVerificationResponse verifyVoucher(@AuthUser Long uid,
                                                     @RequestBody VoucherVerifyRequest req) {
        return voucherVerificationService.verify(uid, req);
    }

    // ── Phase 7.40 — Partner Guest Check-in (first staff-performed booking MUTATION) ──

    @PostMapping("/api/partner/bookings/check-in")
    @Operation(summary = "Check in a guest via signed voucher payload or booking code",
        description = "The MUTATION counterpart to the Phase 7.39 read-only verify endpoint. Reuses the "
            + "same signature-verify + booking-resolution + ownership check, then transitions the booking "
            + "to CHECKED_IN (via BookingStatusEngineService), notifies the customer and writes one "
            + "immutable audit row. Exactly one of voucherPayload / bookingCode is required (400 "
            + "otherwise). Ineligible status / outside the check-in window → 422; invalid signature / "
            + "unknown / another partner's booking → uniform 404. IDEMPOTENT: repeating a check-in on an "
            + "already-CHECKED_IN booking returns a deterministic 200 with the unchanged check-in time and "
            + "no duplicate notification/audit/timeline event.")
    public CheckInResponse checkInGuest(@AuthUser Long uid, @RequestBody CheckInRequest req) {
        return checkInService.checkIn(uid, req);
    }

    // ── Phase 7.41 — Partner Guest Check-out (near-mirror of the 7.40 check-in mutation) ──

    @PostMapping("/api/partner/bookings/check-out")
    @Operation(summary = "Check out a guest via signed voucher payload or booking code",
        description = "The departure counterpart to the Phase 7.40 check-in endpoint. Reuses the same "
            + "signature-verify + booking-resolution + ownership check, then transitions the booking from "
            + "CHECKED_IN to CHECKED_OUT (via BookingStatusEngineService), which notifies the customer; "
            + "writes one immutable audit row carrying the method (QR_SCAN for a scanned payload, MANUAL "
            + "for a typed code). Exactly one of voucherPayload / bookingCode is required (400 otherwise). "
            + "A booking that is not CHECKED_IN, or outside the check-out window → 422; invalid signature / "
            + "unknown / another partner's booking → uniform 404. IDEMPOTENT: repeating a check-out on an "
            + "already-CHECKED_OUT booking returns a deterministic 200 with the unchanged check-out time "
            + "and no duplicate notification/audit/timeline event.")
    public CheckOutResponse checkOutGuest(@AuthUser Long uid, @RequestBody CheckOutRequest req) {
        return checkOutService.checkOut(uid, req);
    }
}
