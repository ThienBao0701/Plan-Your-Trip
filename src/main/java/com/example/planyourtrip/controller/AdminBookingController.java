package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PageResponse;

import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.service.AdminAccessService;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.service.BookingService;
import com.example.planyourtrip.service.PartnerAccessService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/admin/bookings")
@Tag(name = "Admin - Booking")
public class AdminBookingController {

    private final BookingService service;
    private final AdminAccessService adminAccess;

    public AdminBookingController(BookingService service, AdminAccessService adminAccess) {
        this.service = service;
        this.adminAccess = adminAccess;
    }

    /**
     * RBAC R6 — guest identity and contact are returned unmasked only to a caller holding A05
     * {@code admin.customer.view}; any other administrator (notably TECH_SUPPORT and PARTNER_OPERATIONS) gets the
     * name masked and the email omitted, listed in {@code redacted} (§21.4, AP-6).
     */
    private BookingResponse forCaller(Authentication authentication, BookingResponse booking) {
        return adminAccess.holds(authentication, AdminPermission.CUSTOMER_VIEW)
            ? booking : booking.withGuestIdentityMasked();
    }

    /**
     * RBAC R6 — {@code guest} matches a substring of the guest's name or email, so its result set and
     * {@code totalElements} answer "does this booking's guest contain X?" and, repeated, rebuild the identity
     * the responses mask. Guest identity and contact need A05 (§21.4, I12), so a non-blank {@code guest} filter
     * needs it too. The refusal is decided before any query, never from the data, and does not echo the value.
     */
    @GetMapping
    @Operation(summary = "List / search bookings (admin)")
    public PageResponse<BookingSummaryResponse> getAll(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String hotel,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String guest,
            @RequestParam(required = false) String bookingCode,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sort,
            Authentication authentication) {
        if (guest != null && !guest.isBlank()
                && !adminAccess.holds(authentication, AdminPermission.CUSTOMER_VIEW)) {
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
        }
        return service.adminSearchPaged(status, hotel, date, guest, bookingCode, page, size, sort);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get booking by ID")
    public BookingResponse getById(@PathVariable Long id, Authentication authentication) {
        return forCaller(authentication, service.adminGetById(id));
    }

    @GetMapping("/{id}/timeline")
    @Operation(summary = "Get booking timeline")
    public BookingTimelineResponse getTimeline(@PathVariable Long id) {
        return service.adminGetTimeline(id);
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Force-set booking status (admin override)")
    public BookingResponse updateStatus(@AuthUser Long uid, @PathVariable Long id,
                                         @RequestBody @Valid BookingStatusRequest req,
                                         Authentication authentication) {
        return forCaller(authentication, service.adminUpdateStatus(uid, id, req.status()));
    }

    @PatchMapping("/{id}/check-in")
    @Operation(summary = "Check in guest (requires CONFIRMED or CHECK_IN_READY)")
    public BookingResponse checkIn(@AuthUser Long uid, @PathVariable Long id, Authentication authentication) {
        return forCaller(authentication, service.adminCheckIn(uid, id));
    }

    @PatchMapping("/{id}/check-out")
    @Operation(summary = "Check out guest (requires CHECKED_IN)")
    public BookingResponse checkOut(@AuthUser Long uid, @PathVariable Long id, Authentication authentication) {
        return forCaller(authentication, service.adminCheckOut(uid, id));
    }

    @PatchMapping("/{id}/complete")
    @Operation(summary = "Complete reservation (requires CHECKED_OUT)")
    public BookingResponse complete(@AuthUser Long uid, @PathVariable Long id, Authentication authentication) {
        return forCaller(authentication, service.adminComplete(uid, id));
    }

    @PatchMapping("/{id}/archive")
    @Operation(summary = "Archive reservation (requires COMPLETED)")
    public BookingResponse archive(@AuthUser Long uid, @PathVariable Long id, Authentication authentication) {
        return forCaller(authentication, service.adminArchive(uid, id));
    }

    @PostMapping("/{id}/refund-to-credits")
    @Operation(summary = "Refund a CANCELLED booking's PAID payment as promotional travel credits "
        + "(booking and payment become REFUNDED; idempotent REFUND_CREDIT ledger row)")
    public BookingResponse refundToCredits(@AuthUser Long uid, @PathVariable Long id, Authentication authentication) {
        return forCaller(authentication, service.adminRefundToCredits(uid, id));
    }
}
