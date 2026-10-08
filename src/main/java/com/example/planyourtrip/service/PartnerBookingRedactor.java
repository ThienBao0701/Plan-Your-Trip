package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.BookingDto.BookingResponse;
import com.example.planyourtrip.dto.PartnerBookingDto.PartnerBookingView;
import com.example.planyourtrip.dto.PartnerBookingDto.PartnerPaymentView;
import com.example.planyourtrip.dto.PaymentDto.PaymentResponse;
import com.example.planyourtrip.dto.RedactedField;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ScopePath;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

/**
 * RBAC R3b — field-level data minimisation for partner booking responses (RBAC V1.1 §21, SD-1…SD-3, NR-1, NR-2).
 *
 * <p>Each field permission is evaluated against the booking's own property, as stored ({@code booking.hotel}):
 * <ul>
 *   <li>guest name — masked "T. T. B." without {@code booking.guest_identity.view} (P54);</li>
 *   <li>guest email — omitted without {@code booking.guest_contact.view} (P35);</li>
 *   <li>{@code specialRequest}, {@code partnerNote}, {@code cancelReason} — omitted without
 *       {@code booking.stay.view} (P40);</li>
 *   <li>price breakdown, payments and invoice — omitted without {@code booking.payment.view} (P36).</li>
 * </ul>
 * Omitted means null in the response and listed in {@code redacted}. The never-to-partner fields — traveller
 * {@code userId}, {@code loyaltyPointsRedeemed}, payment {@code checkoutUrl}, raw {@code failureReason} — are not
 * part of the partner projections at all and are not listed (SD-3).
 */
@Component
public class PartnerBookingRedactor {

    private final PartnerAccessService access;
    private final BookingService bookingService;

    public PartnerBookingRedactor(PartnerAccessService access, BookingService bookingService) {
        this.access = access;
        this.bookingService = bookingService;
    }

    /** Where a booking lives for field checks: the PROPERTY of {@code booking.hotel} in the caller's company. */
    public ScopePath targetOf(PartnerAccessContext ctx, Booking booking) {
        return ScopePath.property(ctx.companyId(), booking.getHotel().getId());
    }

    public boolean may(PartnerAccessContext ctx, PartnerPermission permission, Booking booking) {
        return access.holds(ctx, permission, targetOf(ctx, booking));
    }

    /** The guest's name as the caller may see it, recording a masking under {@code path}. */
    public String guestName(PartnerAccessContext ctx, Booking booking, String name, List<RedactedField> redacted,
                            String path) {
        if (may(ctx, PartnerPermission.BOOKING_GUEST_IDENTITY_VIEW, booking)) return name;
        redacted.add(RedactedField.masked(path));
        return RedactedField.maskName(name);
    }

    /** The guest's email as the caller may see it (null without P35), recording an omission under {@code path}. */
    public String guestEmail(PartnerAccessContext ctx, Booking booking, String email, List<RedactedField> redacted,
                             String path) {
        if (may(ctx, PartnerPermission.BOOKING_GUEST_CONTACT_VIEW, booking)) return email;
        redacted.add(RedactedField.omitted(path));
        return null;
    }

    /** The partner projection of one booking. */
    public PartnerBookingView view(PartnerAccessContext ctx, Booking booking) {
        BookingResponse r = bookingService.toResponse(booking);
        List<RedactedField> redacted = new ArrayList<>();
        String name = guestName(ctx, booking, r.userFullName(), redacted, "userFullName");
        String email = guestEmail(ctx, booking, r.userEmail(), redacted, "userEmail");
        boolean freeText = may(ctx, PartnerPermission.BOOKING_STAY_VIEW, booking);
        if (!freeText) {
            for (String field : List.of("specialRequest", "partnerNote", "cancelReason"))
                redacted.add(RedactedField.omitted(field));
        }
        boolean payment = may(ctx, PartnerPermission.BOOKING_PAYMENT_VIEW, booking);
        if (!payment) {
            for (String field : List.of("basePrice", "ratePlanPrice", "discountAmount", "couponCode",
                    "couponDiscountAmount", "creditAmountUsed", "loyaltyDiscountAmount", "giftCardAmountUsed",
                    "giftCardReference", "nightlyRateSnapshot", "ratePlanAdjustmentSnapshot"))
                redacted.add(RedactedField.omitted(field));
        }
        return new PartnerBookingView(
            r.id(), r.bookingCode(), name, email,
            r.hotelId(), r.hotelName(), r.roomId(), r.roomName(), r.roomCode(),
            r.checkIn(), r.checkOut(), r.nights(), r.adults(), r.children(), r.numberOfRooms(),
            r.status(), r.currency(),
            payment ? r.basePrice() : null, payment ? r.ratePlanPrice() : null,
            payment ? r.discountAmount() : null, r.finalPrice(),
            freeText ? r.specialRequest() : null, freeText ? r.partnerNote() : null,
            r.createdAt(), r.updatedAt(), r.confirmedAt(), r.cancelledAt(), r.actualCheckInAt(),
            r.actualCheckOutAt(), r.completedAt(), r.archivedAt(), r.lastStatusChangedAt(),
            freeText ? r.cancelReason() : null,
            payment ? r.couponCode() : null, payment ? r.couponDiscountAmount() : null,
            payment ? r.creditAmountUsed() : null, payment ? r.loyaltyDiscountAmount() : null,
            payment ? r.giftCardAmountUsed() : null, payment ? r.giftCardReference() : null,
            r.selectedRatePlanId(), r.selectedRatePlanCode(), r.selectedRatePlanName(), r.mealPlanType(),
            r.cancellationPolicyType(), r.cancellationDeadlineAt(), r.refundable(),
            payment ? r.nightlyRateSnapshot() : null, payment ? r.ratePlanAdjustmentSnapshot() : null,
            List.copyOf(redacted));
    }

    /** A payment record without the never-to-partner payment link and provider error (NR-1). */
    public static PartnerPaymentView payment(PaymentResponse p) {
        return new PartnerPaymentView(p.id(), p.paymentCode(), p.bookingId(), p.bookingCode(), p.amount(),
            p.currency(), p.paymentMethod(), p.status(), p.provider(), p.providerTransactionId(), p.paidAt(),
            p.failedAt(), p.refundedAt(), p.createdAt(), p.updatedAt());
    }
}
