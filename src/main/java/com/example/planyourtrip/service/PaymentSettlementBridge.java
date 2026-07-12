package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PaymentDto.PaymentRequest;
import com.example.planyourtrip.dto.PaymentDto.PaymentResponse;
import com.example.planyourtrip.dto.PaymentDto.PaymentResultRequest;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.PaymentRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

/**
 * Phase 7.27 — the ONE-WAY bridge from a terminal {@link PaymentSession} into the EXISTING
 * {@link Payment} settlement flow. This is the single place a gateway-layer session touches
 * the real settlement engine, and it does so ONLY by calling {@code PaymentService}'s
 * existing public methods — it NEVER re-implements a status transition, a hook call, or a
 * notification.
 *
 * <p><b>Direction of dependency.</b> The gateway layer ({@code PaymentGatewayService} →
 * this bridge → {@code PaymentService}) depends on {@code PaymentService}; {@code
 * PaymentService} stays completely unaware that {@code PaymentSession} exists, preserving
 * its provider-/session-agnostic guarantees from Phase 7.26.
 *
 * <p><b>Reused settlement methods.</b>
 * <ul>
 *   <li>Success → {@link PaymentService#createPayment} (creates the real PENDING row via
 *       the existing entry point and its own duplicate-PAID guard) then
 *       {@link PaymentService#mockSuccess} — which fires the established success hook chain
 *       unchanged: {@code loyaltyRedemptionService.applyForBooking(...)}, booking → CONFIRMED,
 *       and the "Payment successful"/"Booking confirmed" notifications.</li>
 *   <li>Failure → {@link PaymentService#createPayment} then {@link PaymentService#mockFail} —
 *       which fires the established failure hook chain unchanged:
 *       {@code loyaltyRedemptionService.onPaymentFailed(...)},
 *       {@code giftCardService.releaseForBooking(...)}, and the "Payment failed"
 *       notification.</li>
 * </ul>
 *
 * <p><b>Idempotency.</b> This bridge adds NO second idempotency mechanism. It is invoked at
 * most once per session-terminal transition because {@code PaymentGatewayService} already
 * guards each transition with the immutable {@code PaymentSessionEvent} ledger + status
 * checks (a duplicate/late callback on an already-terminal session is a no-op BEFORE the
 * bridge is reached). The lightweight PAID/booking-state pre-checks below make a re-entry
 * (e.g. a session settled after the booking was already paid by the legacy flow) a safe
 * no-op WITHOUT throwing — throwing inside the shared transaction would poison it
 * (rollback-only), so the expected-terminal cases are pre-checked, not caught-after-throw.
 */
@Component
public class PaymentSettlementBridge {

    private final PaymentService paymentService;
    private final PaymentRepository paymentRepo;

    public PaymentSettlementBridge(PaymentService paymentService, PaymentRepository paymentRepo) {
        this.paymentService = paymentService;
        this.paymentRepo = paymentRepo;
    }

    /**
     * Bridge a session that reached CAPTURED into a real PAID {@link Payment}. Runs in the
     * caller's transaction; a genuine settlement failure propagates and rolls the whole
     * session transition back (atomicity).
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void settleSuccess(PaymentSession session) {
        Booking booking = session.getBooking();
        Long bookingId = booking.getId();
        if (session.getPayment() != null) return;                       // already bridged
        if (paymentRepo.existsByBookingIdAndStatus(bookingId, PaymentStatus.PAID)) return; // already paid

        Long ownerId = booking.getUser().getId();
        PaymentResponse created = paymentService.createPayment(
            ownerId, new PaymentRequest(bookingId, methodFor(session.getProvider())));
        paymentService.mockSuccess(ownerId, created.id(),
            new PaymentResultRequest(session.getProviderReference(), true, null));
        session.setPayment(paymentRepo.getReferenceById(created.id()));
    }

    /**
     * Bridge a session that reached a non-success terminal state (FAILED / CANCELLED /
     * EXPIRED) into a real FAILED {@link Payment}, firing the existing release hooks. A
     * no-op when the booking is already paid or is no longer eligible for a payment row
     * (its own cancellation lifecycle has already released any holds).
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public void settleFailure(PaymentSession session, String reason) {
        Booking booking = session.getBooking();
        Long bookingId = booking.getId();
        if (session.getPayment() != null) return;                       // already bridged
        if (paymentRepo.existsByBookingIdAndStatus(bookingId, PaymentStatus.PAID)) return; // succeeded elsewhere
        BookingStatus bs = booking.getStatus();
        if (bs == BookingStatus.CANCELLED || bs == BookingStatus.CHECKED_OUT) return; // holds handled by booking lifecycle

        Long ownerId = booking.getUser().getId();
        PaymentResponse created = paymentService.createPayment(
            ownerId, new PaymentRequest(bookingId, methodFor(session.getProvider())));
        paymentService.mockFail(ownerId, created.id(),
            new PaymentResultRequest(session.getProviderReference(), false, reason));
        session.setPayment(paymentRepo.getReferenceById(created.id()));
    }

    /**
     * Map the session's provider onto the {@link PaymentMethod} the existing
     * {@code PaymentService.createPayment} understands (which in turn derives the recorded
     * {@code Payment.provider}). Providers without a dedicated method fall back to MOCK.
     */
    private PaymentMethod methodFor(PaymentProvider provider) {
        return switch (provider) {
            case VNPAY  -> PaymentMethod.VNPAY;
            case MOMO   -> PaymentMethod.MOMO;
            case STRIPE -> PaymentMethod.STRIPE;
            case PAYOS  -> PaymentMethod.PAYOS;
            default     -> PaymentMethod.MOCK;
        };
    }
}
