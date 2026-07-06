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

    public PaymentService(PaymentRepository paymentRepo,
                          BookingRepository bookingRepo,
                          UserRepository userRepo,
                          NotificationService notificationService) {
        this.paymentRepo = paymentRepo;
        this.bookingRepo = bookingRepo;
        this.userRepo    = userRepo;
        this.notificationService = notificationService;
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

        notificationService.create(payment.getBooking().getUser().getId(), NotificationType.PAYMENT, Priority.HIGH,
            "Payment failed",
            "Your payment for booking " + payment.getBooking().getBookingCode() + " failed.",
            RelatedEntityType.PAYMENT, saved.getId());

        return toResponse(saved);
    }

    @Transactional
    public PaymentResponse refund(Long paymentId, RefundRequest req) {
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

        return toResponse(paymentRepo.save(payment));
    }

    @Transactional(readOnly = true)
    public List<PaymentResponse> adminListPayments() {
        return paymentRepo.findAllByOrderByCreatedAtDesc()
            .stream().map(this::toResponse).toList();
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
            case CASH, CARD, BANK_TRANSFER -> PaymentProvider.MANUAL;
            default -> PaymentProvider.MOCK;
        };
    }

    private String generateCode(Long id) {
        return "PAY-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", id);
    }

    private PaymentResponse toResponse(Payment p) {
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
