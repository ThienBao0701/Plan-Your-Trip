package com.example.planyourtrip.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

/**
 * Phase 7.38 — Customer Booking Digital Voucher (read-only foundation).
 *
 * <p>A safe, customer-facing check-in voucher / confirmation representation for the mobile User App,
 * DERIVED entirely from already-persisted Booking / Payment / BookingModification snapshots. There is
 * NO new entity: the voucher is a pure projection of the live booking row, so it always reflects the
 * current persisted values (including any Phase 7.34 modification). No price is recomputed — every
 * monetary field is a persisted Booking value copied verbatim; {@code numberOfNights} is the only
 * arithmetic ({@code ChronoUnit.DAYS.between}), which is not a price calculation.
 *
 * <p>Stable identifiers:
 * <ul>
 *   <li>{@code bookingReference} / {@code confirmationCode} = the immutable {@code Booking.bookingCode}.</li>
 *   <li>{@code voucherCode} = {@code "VCH-" + bookingCode} — a deterministic transform of the immutable
 *       code, so repeated reads return the SAME value and it survives a pending-booking modification
 *       unchanged (bookingCode itself never changes).</li>
 *   <li>{@code qrPayload} = a versioned, HMAC-signed payload {@code PYT-V1.<bookingCode>.<base64urlSig>}
 *       (see {@code security.VoucherSignatureService}), where the signature is
 *       {@code HMAC-SHA256(voucherSigningSecret, "PYT-V1|" + bookingCode)} Base64URL-encoded without
 *       padding. Because only the immutable {@code bookingCode} is signed, the payload is stable across
 *       repeated reads and Phase 7.34 modifications. A valid signature proves only that the platform
 *       generated the payload — it is NOT authentication and does not resolve booking data. It carries
 *       ONLY the version tag, the safe booking code and the signature: never a JWT/access/refresh
 *       token, payment-provider secret or transaction id, gift-card code, coupon secret, partner note
 *       or other PII.</li>
 * </ul>
 */
public class BookingVoucherDto {

    /**
     * The derived check-in validity of the voucher, computed from the persisted booking + latest
     * payment status (never recomputed pricing). See {@code BookingService.voucherStatusOf}. Surfaced
     * as a String in the response (mirroring how {@code bookingStatus}/{@code paymentStatus} are
     * exposed) so terminal states render as data rather than throwing.
     */
    public enum VoucherStatus {
        /** CONFIRMED / CHECK_IN_READY with a PAID payment — a genuine check-in voucher. */
        VALID,
        /** PENDING, or payment not yet PAID — the voucher exists but is not yet check-in valid. */
        NOT_READY,
        /** Latest payment FAILED — the voucher cannot be used until payment succeeds. */
        INVALID,
        /** Booking CANCELLED — historical/invalid; rendered so the app can show a cancelled state. */
        CANCELLED,
        /** Booking REFUNDED — historical/invalid. */
        REFUNDED,
        /** Stay already happened/closed (CHECKED_IN / CHECKED_OUT / COMPLETED / ARCHIVED / NO_SHOW). */
        HISTORICAL
    }

    public record BookingVoucherResponse(
        Long bookingId,
        // Stable identifiers derived from the immutable bookingCode.
        String bookingReference,
        String confirmationCode,
        String voucherCode,
        String voucherStatus,
        String qrPayload,
        // Persisted status snapshots.
        String bookingStatus,
        String paymentStatus,
        // Guest + stay location (persisted snapshots / linked entities).
        String guestName,
        String hotelName,
        String hotelAddress,
        String roomName,
        String roomCode,
        // Stay details.
        LocalDate checkIn,
        LocalDate checkOut,
        int numberOfNights,
        int adults,
        int children,
        int numberOfRooms,
        // Rate-plan snapshot (all nullable — null when no plan was resolved for the booking).
        String selectedRatePlanCode,
        String selectedRatePlanName,
        String mealPlanType,
        String cancellationPolicyType,
        Instant cancellationDeadlineAt,
        Boolean refundable,
        // Persisted pricing snapshot (verbatim; nothing recomputed).
        BigDecimal subtotal,
        BigDecimal discountAmount,
        BigDecimal couponDiscountAmount,
        BigDecimal creditAmountUsed,
        BigDecimal loyaltyDiscountAmount,
        BigDecimal giftCardAmountUsed,
        BigDecimal finalPrice,
        String currency,
        // Latest Phase 7.36 modification timestamp (nullable — null when never modified).
        Instant latestModificationAt,
        // Customer-safe advisory strings (empty when the voucher is VALID).
        List<String> warnings
    ) {}
}
