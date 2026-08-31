package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PaymentDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class PaymentService {

    private final PaymentRepository paymentRepo;
    private final BookingRepository bookingRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;
    private final LoyaltyRedemptionService loyaltyRedemptionService;
    private final GiftCardService giftCardService;
    private final InventoryReservationService inventoryReservationService;
    /** D1a — refunds move money and must leave an administrative trail. */
    private final AdminActivityLogService adminAudit;

    public PaymentService(PaymentRepository paymentRepo,
                          BookingRepository bookingRepo,
                          UserRepository userRepo,
                          NotificationService notificationService,
                          LoyaltyRedemptionService loyaltyRedemptionService,
                          GiftCardService giftCardService,
                          InventoryReservationService inventoryReservationService,
                           AdminActivityLogService adminAudit) {
        this.paymentRepo = paymentRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo    = userRepo;
        this.notificationService = notificationService;
        this.loyaltyRedemptionService = loyaltyRedemptionService;
        this.giftCardService = giftCardService;
        this.inventoryReservationService = inventoryReservationService;
        this.adminAudit = adminAudit;
    }

    @Transactional
    public PaymentResponse createPayment(Long userId, PaymentRequest req) {
        Booking booking = bookingRepo.findById(req.bookingId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Booking not found: " + req.bookingId()));

        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN,
                "Access denied: booking belongs to another user");

        BookingStatus status = booking.getStatus();
        if (status == BookingStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot create payment for a cancelled booking");
        if (status == BookingStatus.CHECKED_OUT)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Cannot create payment for a checked-out booking");

        if (paymentRepo.existsByBookingIdAndStatus(req.bookingId(), PaymentStatus.PAID))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "A successful payment already exists for this booking");

        Payment payment = new Payment();
        payment.setBooking(booking);
        payment.setAmount(booking.getFinalPrice());
        payment.setCurrency(booking.getCurrency());
        payment.setPaymentMethod(req.paymentMethod());
        payment.setStatus(PaymentStatus.PENDING);
        payment.setProvider(providerFor(req.paymentMethod()));

        payment = paymentRepo.save(payment);
        payment.setPaymentCode(generateCode(payment.getId()));
        payment = paymentRepo.save(payment);

        return toResponse(payment);
    }

    @Transactional(readOnly = true)
    public PaymentResponse getPayment(Long userId, Long paymentId) {
        Payment payment = paymentRepo.findById(paymentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Payment not found: " + paymentId));
        checkOwnerOrAdmin(userId, payment);
        return toResponse(payment);
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> getPaymentsByBooking(Long userId, Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
        return paymentRepo.findByBookingIdOrderByCreatedAtDesc(bookingId)
            .stream().map(this::toResponse).toList();
    }

    @Transactional
    public PaymentResponse mockSuccess(Long userId, Long paymentId, PaymentResultRequest req) {
        Payment payment = paymentRepo.findById(paymentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Payment not found: " + paymentId));
        checkOwnerOrAdmin(userId, payment);

        if (payment.getStatus() != PaymentStatus.PENDING)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only PENDING payments can be confirmed. Current status: " + payment.getStatus());

        payment.setStatus(PaymentStatus.PAID);
        payment.setPaidAt(Instant.now());
        if (req != null && req.providerTransactionId() != null)
            payment.setProviderTransactionId(req.providerTransactionId());

        Booking booking = payment.getBooking();
        booking.setStatus(BookingStatus.CONFIRMED);
        if (booking.getConfirmedAt() == null)
            booking.setConfirmedAt(Instant.now());
        bookingRepo.save(booking);

        Payment saved = paymentRepo.save(payment);

        // Phase 7.20 — confirm any RESERVED loyalty redemption now the booking is
        // paid/confirmed (RESERVED → APPLIED). Idempotent; no-op when none exists.
        loyaltyRedemptionService.applyForBooking(booking.getId());

        // Phase 7.28 — payment succeeded: consume the room hold (HELD → CONSUMED). Pure
        // status flip — the decrement made at booking creation is now permanent and is NOT
        // re-applied. Idempotent; no-op when there is no hold or it is already terminal.
        inventoryReservationService.consumeForBooking(booking.getId());

        // Phase 7.25 — gift card: payment success KEEPS the redemption. No callback
        // is needed because a gift card is an immediate debit at booking creation
        // (there is no reserve/apply split like loyalty) — the REDEMPTION already
        // stands and is only ever reversed by release (failure) / refund (cancel).

        notificationService.create(booking.getUser().getId(), NotificationType.PAYMENT, Priority.HIGH,
            "Payment successful",
            "Your payment for booking " + booking.getBookingCode() + " was successful.",
            RelatedEntityType.PAYMENT, saved.getId());
        notificationService.create(booking.getUser().getId(), NotificationType.BOOKING, Priority.NORMAL,
            "Booking confirmed",
            "Your booking " + booking.getBookingCode() + " has been confirmed.",
            RelatedEntityType.BOOKING, booking.getId());

        return toResponse(saved);
    }

    @Transactional
    public PaymentResponse mockFail(Long userId, Long paymentId, PaymentResultRequest req) {
        Payment payment = paymentRepo.findById(paymentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Payment not found: " + paymentId));
        checkOwnerOrAdmin(userId, payment);

        if (payment.getStatus() != PaymentStatus.PENDING)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only PENDING payments can be failed. Current status: " + payment.getStatus());

        payment.setStatus(PaymentStatus.FAILED);
        payment.setFailedAt(Instant.now());
        if (req != null && req.failureReason() != null)
            payment.setFailureReason(req.failureReason());

        // Booking remains PENDING
        Payment saved = paymentRepo.save(payment);

        // Phase 7.20 — payment failed before the redemption was applied: release
        // the RESERVED reservation so the held points return to the customer.
        // Idempotent; no-op when there is no active reservation.
        loyaltyRedemptionService.onPaymentFailed(payment.getBooking().getId());

        // Phase 7.25 — payment failed: release any gift card redeemed at checkout
        // (restore balance + REFUND ledger row, un-apply the discount on the
        // booking). Idempotent; no-op when nothing was redeemed.
        giftCardService.releaseForBooking(payment.getBooking().getId());

        // Phase 7.28 — payment failed: release the room hold (HELD → RELEASED) and restore
        // inventory via the EXISTING restoreInventory method. This single hook also covers
        // session-cancel/session-expiry, because Phase 7.27's PaymentSettlementBridge routes
        // those through this same mockFail. Booking status is deliberately UNCHANGED (stays
        // PENDING) — after this phase a PENDING booking can legitimately hold NO inventory
        // (its hold was released on payment failure/expiry). Idempotent; no double-restore.
        inventoryReservationService.releaseForBooking(payment.getBooking().getId());

        notificationService.create(payment.getBooking().getUser().getId(), NotificationType.PAYMENT, Priority.HIGH,
            "Payment failed",
            "Your payment for booking " + payment.getBooking().getBookingCode() + " failed.",
            RelatedEntityType.PAYMENT, saved.getId());

        return toResponse(saved);
    }

    @Transactional
    public PaymentResponse refund(Long adminUserId, Long paymentId, RefundRequest req) {
        Payment payment = paymentRepo.findById(paymentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Payment not found: " + paymentId));

        if (payment.getStatus() != PaymentStatus.PAID)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only PAID payments can be refunded. Current status: " + payment.getStatus());

        payment.setStatus(PaymentStatus.REFUNDED);
        payment.setRefundedAt(Instant.now());
        if (req != null && req.reason() != null)
            payment.setFailureReason(req.reason());

        Payment saved = paymentRepo.save(payment);

        // D1a — money movement: record amount, currency, target and the supplied reason only.
        // Never the provider transaction id, checkout URL, card data or any provider credential.
        String reason = (req != null && req.reason() != null && !req.reason().isBlank())
            ? " Reason: " + req.reason() : "";
        adminAudit.record(adminUserId, "PAYMENT_REFUND", "PAYMENT", saved.getId(),
            "Refunded " + saved.getAmount() + " " + saved.getCurrency()
                + " on booking " + (saved.getBooking() != null ? saved.getBooking().getId() : null)
                + "." + reason,
            PaymentStatus.PAID.name(), PaymentStatus.REFUNDED.name());

        return toResponse(saved);
    }

    /** Entity properties an administrator may sort the payment grid by (D1a-12 allowlist). */
    private static final java.util.Set<String> PAYMENT_SORT_FIELDS = java.util.Set.of(
        "createdAt", "amount", "status", "paidAt", "refundedAt");

    /** D1a — database-side paginated payment grid, replacing the unbounded list (D0-2). */
    @Transactional(readOnly = true)
    public com.example.planyourtrip.dto.PageResponse<PaymentResponse> adminListPaymentsPaged(
            PaymentStatus status, Long bookingId, Integer page, Integer size, String sort) {
        org.springframework.data.domain.Pageable pageable =
            AdminPaging.of(page, size, sort, PAYMENT_SORT_FIELDS, "createdAt");
        org.springframework.data.jpa.domain.Specification<Payment> spec =
            (root, q, cb) -> {
                var predicates = new java.util.ArrayList<jakarta.persistence.criteria.Predicate>();
                if (status != null) predicates.add(cb.equal(root.get("status"), status));
                if (bookingId != null) predicates.add(cb.equal(root.get("booking").get("id"), bookingId));
                return predicates.isEmpty() ? cb.conjunction()
                    : cb.and(predicates.toArray(new jakarta.persistence.criteria.Predicate[0]));
            };
        return com.example.planyourtrip.dto.PageResponse.of(
            paymentRepo.findAll(spec, pageable).map(this::toResponse));
    }

    @Transactional(readOnly = true)
    public PaymentResponse adminGetPayment(Long paymentId) {
        return toResponse(paymentRepo.findById(paymentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Payment not found: " + paymentId)));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private void checkOwnerOrAdmin(Long userId, Payment payment) {
        Long ownerId = payment.getBooking().getUser().getId();
        if (ownerId.equals(userId)) return;
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
    }

    private PaymentProvider providerFor(PaymentMethod method) {
        return switch (method) {
            case VNPAY -> PaymentProvider.VNPAY;
            case MOMO  -> PaymentProvider.MOMO;
            case STRIPE -> PaymentProvider.STRIPE;
            case PAYOS -> PaymentProvider.PAYOS;
            case CASH, CARD, BANK_TRANSFER -> PaymentProvider.MANUAL;
            default -> PaymentProvider.MOCK;
        };
    }

    private String generateCode(Long id) {
        return "PAY-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", id);
    }

    PaymentResponse toResponse(Payment p) {
        return new PaymentResponse(
            p.getId(),
            p.getPaymentCode(),
            p.getBooking().getId(),
            p.getBooking().getBookingCode(),
            p.getAmount(),
            p.getCurrency(),
            p.getPaymentMethod().name(),
            p.getStatus().name(),
            p.getProvider().name(),
            p.getProviderTransactionId(),
            p.getCheckoutUrl(),
            p.getFailureReason(),
            p.getPaidAt(),
            p.getFailedAt(),
            p.getRefundedAt(),
            p.getCreatedAt(),
            p.getUpdatedAt()
        );
    }
}
