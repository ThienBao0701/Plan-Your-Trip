package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.BookingDto.BookingSummaryResponse;
import com.example.planyourtrip.dto.BookingModificationPreviewDto.BookingModificationPreviewRequest;
import com.example.planyourtrip.dto.BookingModificationPreviewDto.BookingModificationPreviewResponse;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteRequest;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.BookingStatus;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.InventoryReservation;
import com.example.planyourtrip.model.InventoryReservationStatus;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.InventoryReservationRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.35 — the READ-ONLY PREVIEW of the Phase 7.34 booking modification
 * ({@code BookingService.modify} / {@code PATCH /api/bookings/{id}/modify}).
 *
 * <p>Given the SAME modification inputs, this computes and returns what modify() WOULD produce — the
 * new price, old→new totals and their difference (additional payment / refundable amount), the
 * inventory availability and advisories — WITHOUT mutating anything. It is the exact analogue of how
 * Phase 7.32 / 7.33 build read-only pricing quotes that reuse the checkout pricing pipeline without
 * booking anything.
 *
 * <p><b>Nothing is duplicated.</b> The proposed pricing (rate-plan resolution → promotion →
 * pre-benefit total → the four customer-benefit previews) is delegated in full to
 * {@link CustomerPricingQuoteService#quote}, which already takes room + dates + occupancy +
 * benefit-inputs and returns the layered breakdown — and which itself reuses the SAME
 * {@code RatePlanPricingService.resolveForBooking} + {@code PricingEngineService.calculate} (5-arg)
 * that {@code BookingService.modify} calls. So the previewed pre-benefit total equals exactly what
 * modify() would write to {@code finalPrice}.
 *
 * <p><b>Strictly read-only.</b> This never updates/creates a booking, never touches a payment or
 * payment session, never locks / decrements / restores inventory (it uses only the pure
 * {@link RoomInventoryRepository#findBetweenDates} read — NEVER {@code lockForUpdate}), never creates
 * or mutates an inventory reservation, never consumes a coupon / loyalty / travel credit / gift card,
 * and never writes a notification or ledger entry. {@code @Transactional(readOnly = true)}.
 *
 * <p><b>Validation mirrors modify() precisely</b> so a successful preview predicts a successful
 * modify: owner-only (403), PENDING-only (422), no-applied-benefit (422), and the same hard 400s for
 * past check-in / non-positive stay / adults &lt; 1 / capacity exceeded. Soft conditions
 * (unavailable inventory, an ineligible previewed benefit, an inactive hold) are surfaced in
 * {@code eligibilityFailures} rather than thrown, since a preview is informational.
 *
 * <p><b>Documented deviations from modify().</b>
 * <ul>
 *   <li><b>No-eligible-plan fallback.</b> When no rate plan is eligible for the new params,
 *       {@code modify()} falls back to base-room pricing; this preview instead returns null price
 *       fields with an eligibility failure — the established Phase 7.32/7.33 read-only-quote
 *       behaviour (the delegated {@code RoomPricingQuoteService} does not apply the base-room
 *       fallback). Bookings always carry an eligible plan in practice, so this is an edge case.</li>
 *   <li><b>Room visibility.</b> The delegated quote requires the room to be ACTIVE and its hotel
 *       PUBLISHED (else 404); {@code modify()} does not re-check this. A PENDING booking is on a
 *       still-sellable room in practice, so this only diverges for a since-unpublished room.</li>
 * </ul>
 */
@Service
@Transactional(readOnly = true)
public class BookingModificationPreviewService {

    private static final String READ_ONLY_DISCLAIMER =
        "This is a read-only preview; it holds no inventory and creates no payment. "
        + "Apply it via PATCH /api/bookings/{id}/modify to actually change the booking.";
    private static final String BENEFIT_PREVIEW_NOTE =
        "Coupon / loyalty / travel-credit / gift-card amounts are an ESTIMATE for a later checkout; "
        + "the modification itself applies no benefit — its total is the promotion-discounted price.";

    private final BookingRepository bookingRepo;
    private final CustomerPricingQuoteService customerPricingQuoteService;
    private final RoomInventoryRepository inventoryRepo;
    private final InventoryReservationRepository reservationRepo;

    public BookingModificationPreviewService(BookingRepository bookingRepo,
                                             CustomerPricingQuoteService customerPricingQuoteService,
                                             RoomInventoryRepository inventoryRepo,
                                             InventoryReservationRepository reservationRepo) {
        this.bookingRepo = bookingRepo;
        this.customerPricingQuoteService = customerPricingQuoteService;
        this.inventoryRepo = inventoryRepo;
        this.reservationRepo = reservationRepo;
    }

    public BookingModificationPreviewResponse preview(Long userId, Long bookingId,
                                                      BookingModificationPreviewRequest req) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));

        // Ownership convention MATCHES modify()/cancel(): another user's booking → 403.
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");

        // PENDING-only boundary (mirrors modify()). The spec lists CANCELLED/COMPLETED/EXPIRED/
        // REFUNDED explicitly; we reject ANY non-PENDING status (which subsumes those plus
        // CONFIRMED/CHECKED_IN/… ) with the same 422 convention modify() uses, because a preview
        // that priced a modification for a booking that could not actually be modified would mislead.
        if (booking.getStatus() != BookingStatus.PENDING)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot preview modification for booking with status: " + booking.getStatus());

        // No-applied-benefit rule (mirrors modify()): a booking that already has a checkout benefit
        // attached cannot be modified, so previewing its modification would be misleading → 422.
        if (hasAppliedCheckoutBenefit(booking))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Remove the applied coupon / travel credit / loyalty / gift card before modifying this booking");

        HotelRoom room = booking.getRoom();
        Long roomId = room.getId();
        LocalDate oldCheckIn = booking.getCheckInDate();
        LocalDate oldCheckOut = booking.getCheckOutDate();
        int numRooms = booking.getNumberOfRooms(); // room count is not modifiable in this phase

        // Merge request with current values (omitted → keep current) — IDENTICAL to modify().
        LocalDate newCheckIn  = req.checkIn()  != null ? req.checkIn()  : oldCheckIn;
        LocalDate newCheckOut = req.checkOut() != null ? req.checkOut() : oldCheckOut;
        int newAdults   = req.adults()   != null ? req.adults()   : booking.getAdults();
        int newChildren = req.children() != null ? req.children() : booking.getChildren();
        int newExtraBeds = req.extraBeds() != null ? req.extraBeds() : 0; // pricing-only
        Long effectiveRatePlanId = req.ratePlanId() != null ? req.ratePlanId() : booking.getSelectedRatePlanId();

        // Hard validation — the SAME rules (and 400s) as modify(), so preview success ⟺ modify success.
        LocalDate today = LocalDate.now();
        if (newCheckIn.isBefore(today))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn cannot be in the past");
        if (!newCheckOut.isAfter(newCheckIn))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut must be after checkIn");
        if (newAdults < 1)
            throw new ApiException(HttpStatus.BAD_REQUEST, "adults must be at least 1");
        int maxAdultsTotal = room.getMaxAdults() != null ? room.getMaxAdults() * numRooms : numRooms;
        int maxGuestsTotal = room.getMaxGuests() != null ? room.getMaxGuests() * numRooms : numRooms;
        if (newAdults > maxAdultsTotal)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Adults exceed maximum capacity of " + maxAdultsTotal);
        if ((newAdults + newChildren) > maxGuestsTotal)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Total guests exceed maximum capacity of " + maxGuestsTotal);

        // ── Delegate all pricing to the Phase 7.33 read-only quote (reuses 7.32 base + benefits) ──
        CustomerPricingQuoteResponse proposedPricing = customerPricingQuoteService.quote(userId, roomId,
            new CustomerPricingQuoteRequest(newCheckIn, newCheckOut, newAdults, newChildren, newExtraBeds,
                effectiveRatePlanId, req.couponId(), req.requestedPoints(),
                req.travelCreditAmountRequested(), req.giftCardCode()));

        // ── Overlap-adjusted availability (read-only net effect of modify()'s restore-then-check) ──
        List<String> warnings = new ArrayList<>();
        List<String> failures = new ArrayList<>();
        if (proposedPricing.eligibilityFailures() != null) failures.addAll(proposedPricing.eligibilityFailures());
        warnings.add(READ_ONLY_DISCLAIMER);
        warnings.add(BENEFIT_PREVIEW_NOTE);

        InventoryAvailability inv = computeOverlapAdjustedAvailability(
            bookingId, roomId, oldCheckIn, oldCheckOut, newCheckIn, newCheckOut, numRooms, failures);
        if (!inv.available)
            failures.add("Insufficient inventory for the selected dates");

        // ── Old → New → Difference (no payment created) ───────────────────────
        String currency = proposedPricing.currency() != null ? proposedPricing.currency() : booking.getCurrency();
        BigDecimal oldTotal = scale(booking.getFinalPrice());
        BigDecimal estimatedTotal = proposedPricing.totalBeforeCustomerBenefits() != null
            ? scale(proposedPricing.totalBeforeCustomerBenefits())
            : null; // no eligible rate plan for the new params
        BigDecimal priceDifference = null, additionalPayment = null, refundableAmount = null;
        if (estimatedTotal != null) {
            priceDifference = estimatedTotal.subtract(oldTotal).setScale(2, RoundingMode.HALF_UP);
            additionalPayment = priceDifference.max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
            refundableAmount = priceDifference.negate().max(BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP);
        }

        BigDecimal subtotal = proposedPricing.baseQuote() != null
            ? proposedPricing.baseQuote().staySubtotal() : null;

        // ── Existing vs proposed booking summaries (proposed is projection-only, not persisted) ──
        int oldNights = (int) ChronoUnit.DAYS.between(oldCheckIn, oldCheckOut);
        int newNights = (int) ChronoUnit.DAYS.between(newCheckIn, newCheckOut);
        BookingSummaryResponse existing = new BookingSummaryResponse(
            booking.getId(), booking.getBookingCode(),
            booking.getHotel().getId(), booking.getHotel().getName(),
            room.getId(), room.getRoomName(),
            oldCheckIn, oldCheckOut, oldNights,
            booking.getStatus().name(), oldTotal, booking.getCurrency(), booking.getCreatedAt());
        BookingSummaryResponse proposed = new BookingSummaryResponse(
            booking.getId(), booking.getBookingCode(),
            booking.getHotel().getId(), booking.getHotel().getName(),
            room.getId(), room.getRoomName(),
            newCheckIn, newCheckOut, newNights,
            booking.getStatus().name(), estimatedTotal, currency, booking.getCreatedAt());

        // New rate plan (from the resolved base quote — null when none is eligible).
        Long newRatePlanId = proposedPricing.baseQuote() != null
            ? proposedPricing.baseQuote().selectedRatePlanId() : null;
        String newRatePlanName = proposedPricing.baseQuote() != null
            ? proposedPricing.baseQuote().selectedRatePlanName() : null;

        return new BookingModificationPreviewResponse(
            booking.getId(), booking.getBookingCode(), booking.getStatus().name(),
            existing, proposed,
            // Room change not supported → old == new by construction.
            room.getId(), room.getRoomName(), room.getId(), room.getRoomName(),
            oldCheckIn, oldCheckOut, newCheckIn, newCheckOut,
            booking.getAdults(), booking.getChildren(), newAdults, newChildren,
            booking.getSelectedRatePlanId(), booking.getSelectedRatePlanName(),
            newRatePlanId, newRatePlanName,
            inv.available, inv.availableRooms,
            proposedPricing, subtotal,
            oldTotal, estimatedTotal, priceDifference, additionalPayment, refundableAmount,
            currency, warnings, failures);
    }

    /**
     * Read-only availability for the NEW dates, treating this booking's OWN current hold as if it
     * were released — i.e. for any night in the new range that is ALSO in the old range, add this
     * booking's {@code numberOfRooms} back to the available count before comparing. This is the pure
     * read/computation equivalent of modify()'s "restoreInventory(old) then check(new)", so a stay
     * that merely shifts by a night (overlapping the rest) shows AVAILABLE even when the room would
     * otherwise look full ONLY because of this booking's own hold. NEVER locks and NEVER mutates.
     *
     * <p>The add-back is applied ONLY when this booking currently HOLDS its inventory (its
     * reservation is HELD). A PENDING booking whose hold was released/expired holds nothing, so no
     * add-back is made and an eligibility failure is surfaced — mirroring modify()'s
     * {@code assertHeldForModification} precondition (as an informational failure, not a throw).
     */
    private InventoryAvailability computeOverlapAdjustedAvailability(
            Long bookingId, Long roomId, LocalDate oldCheckIn, LocalDate oldCheckOut,
            LocalDate newCheckIn, LocalDate newCheckOut, int numRooms, List<String> failures) {

        boolean holdActive = reservationRepo.findByBookingId(bookingId)
            .map(r -> r.getStatus() == InventoryReservationStatus.HELD)
            .orElse(false);
        if (!holdActive)
            failures.add("This booking's inventory hold is no longer active; it can no longer be modified");

        long nights = ChronoUnit.DAYS.between(newCheckIn, newCheckOut);
        List<RoomInventory> rows = inventoryRepo.findBetweenDates(roomId, newCheckIn, newCheckOut.minusDays(1));

        // A missing inventory row for any night means that night is not sellable.
        if (rows.size() < nights)
            return new InventoryAvailability(false, 0);

        boolean available = true;
        int minAvailable = Integer.MAX_VALUE;
        for (RoomInventory r : rows) {
            int effective = r.getAvailableInventory();
            LocalDate d = r.getInventoryDate();
            boolean sharedWithOld = holdActive && !d.isBefore(oldCheckIn) && d.isBefore(oldCheckOut);
            if (sharedWithOld) effective += numRooms; // give back this booking's own hold for the check
            if (r.isStopSell() || effective < numRooms) available = false;
            minAvailable = Math.min(minAvailable, effective);
        }
        int availableRooms = available ? Math.max(0, minAvailable) : 0;
        return new InventoryAvailability(available, availableRooms);
    }

    /**
     * Mirrors {@code BookingService.hasAppliedCheckoutBenefit}: true when any checkout benefit
     * (coupon / travel credit / loyalty / gift card) is attached to the booking.
     */
    private boolean hasAppliedCheckoutBenefit(Booking b) {
        return (b.getCouponCode() != null && !b.getCouponCode().isBlank())
            || (b.getCreditAmountUsed() != null && b.getCreditAmountUsed().signum() > 0)
            || (b.getLoyaltyDiscountAmount() != null && b.getLoyaltyDiscountAmount().signum() > 0)
            || (b.getGiftCardAmountUsed() != null && b.getGiftCardAmountUsed().signum() > 0);
    }

    private static BigDecimal scale(BigDecimal v) {
        return v == null ? null : v.setScale(2, RoundingMode.HALF_UP);
    }

    private record InventoryAvailability(boolean available, int availableRooms) {}
}
