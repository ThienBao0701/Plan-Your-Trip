package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.BookingDto.*;
import com.example.planyourtrip.dto.BookingModificationPreviewDto.BookingModificationPreviewRequest;
import com.example.planyourtrip.dto.BookingModificationPreviewDto.BookingModificationPreviewResponse;
import com.example.planyourtrip.dto.BookingVoucherDto.BookingVoucherResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.BookingModificationPreviewService;
import com.example.planyourtrip.service.BookingService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Booking")
public class BookingController {

    private final BookingService service;
    private final BookingModificationPreviewService modificationPreviewService;

    public BookingController(BookingService service,
                            BookingModificationPreviewService modificationPreviewService) {
        this.service = service;
        this.modificationPreviewService = modificationPreviewService;
    }

    @PostMapping("/api/bookings")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a new booking")
    public BookingResponse create(@AuthUser Long uid,
                                   @RequestBody @Valid BookingRequest req) {
        return service.create(uid, req);
    }

    @GetMapping("/api/bookings/{id}")
    @Operation(summary = "Get booking by ID (owner or admin only)")
    public BookingResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getById(uid, id);
    }

    @GetMapping("/api/bookings/{id}/timeline")
    @Operation(summary = "Get booking timeline (owner or admin)")
    public BookingTimelineResponse getTimeline(@AuthUser Long uid, @PathVariable Long id) {
        return service.getTimeline(uid, id);
    }

    @GetMapping("/api/me/bookings")
    @Operation(summary = "List current user's bookings")
    public List<BookingSummaryResponse> getMyBookings(@AuthUser Long uid) {
        return service.getMyBookings(uid);
    }

    @GetMapping("/api/me/bookings/upcoming")
    @Operation(summary = "Upcoming bookings (PENDING / CONFIRMED / CHECK_IN_READY)")
    public List<UpcomingBookingResponse> getUpcoming(@AuthUser Long uid) {
        return service.getUpcomingBookings(uid);
    }

    @GetMapping("/api/me/bookings/history")
    @Operation(summary = "Booking history (completed / cancelled / archived)")
    public List<BookingHistoryResponse> getHistory(@AuthUser Long uid) {
        return service.getBookingHistory(uid);
    }

    @GetMapping("/api/me/bookings/active")
    @Operation(summary = "Active bookings (currently checked in)")
    public List<BookingSummaryResponse> getActive(@AuthUser Long uid) {
        return service.getActiveBookings(uid);
    }

    // Phase 7.38 — Customer Booking Digital Voucher (read-only). Owner-scoped and, unlike
    // getById/cancel/modify (403 for another user's booking, ADMIN allowed), this surface returns
    // 404 for ANY booking that is not the caller's own — a deliberate "don't leak existence" privacy
    // choice for the customer voucher (mirroring the coupon / gift-card / wallet read surfaces). See
    // BookingService.getVoucher.
    @GetMapping("/api/me/bookings/{bookingId}/voucher")
    @Operation(summary = "Get the read-only digital check-in voucher for one of the caller's bookings",
        description = "Returns a safe, customer-facing voucher/confirmation DERIVED from the persisted "
            + "booking, latest payment and modification snapshots — no price recomputation, no mutation. "
            + "voucherStatus reflects check-in validity (VALID / NOT_READY / INVALID / CANCELLED / "
            + "REFUNDED / HISTORICAL); terminal states return 200 so the app can render them. qrPayload "
            + "is compact non-sensitive text (booking code only). 404 for a booking the caller does not own.")
    public BookingVoucherResponse getVoucher(@AuthUser Long uid, @PathVariable Long bookingId) {
        return service.getVoucher(uid, bookingId);
    }

    @PatchMapping("/api/bookings/{id}/cancel")
    @Operation(summary = "Cancel a booking (owner only)")
    public BookingResponse cancel(@AuthUser Long uid,
                                   @PathVariable Long id,
                                   @RequestBody(required = false) CancelRequest req) {
        return service.cancel(uid, id, req != null ? req.cancelReason() : null);
    }

    @PatchMapping("/api/bookings/{id}/modify")
    @Operation(summary = "Modify a PENDING booking's dates / occupancy / rate plan (owner only)")
    public BookingResponse modify(@AuthUser Long uid,
                                   @PathVariable Long id,
                                   @RequestBody @Valid BookingModificationRequest req) {
        return service.modify(uid, id, req);
    }

    @PostMapping("/api/me/bookings/{bookingId}/modify/preview")
    @Operation(summary = "Preview modifying a PENDING booking (read-only; owner only)",
        description = "Computes what PATCH /api/bookings/{id}/modify WOULD do for the same inputs — new "
            + "price, old→new totals and difference (additional payment / refundable amount), overlap-adjusted "
            + "inventory availability and advisories — without changing anything. Optional coupon/loyalty/"
            + "travel-credit/gift-card inputs layer a hypothetical checkout benefit preview on top.")
    public BookingModificationPreviewResponse previewModify(@AuthUser Long uid,
                                                            @PathVariable Long bookingId,
                                                            @RequestBody @Valid BookingModificationPreviewRequest req) {
        return modificationPreviewService.preview(uid, bookingId, req);
    }
}
