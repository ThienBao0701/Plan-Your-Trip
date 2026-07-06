package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.InvoiceDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class InvoiceService {

    private final InvoiceRepository invoiceRepo;
    private final BookingRepository bookingRepo;
    private final PaymentRepository paymentRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;

    public InvoiceService(InvoiceRepository invoiceRepo,
                           BookingRepository bookingRepo,
                           PaymentRepository paymentRepo,
                           UserRepository userRepo,
                           NotificationService notificationService) {
        this.invoiceRepo = invoiceRepo;
        this.bookingRepo = bookingRepo;
        this.paymentRepo = paymentRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
    }

    @Transactional
    public InvoiceResponse createInvoice(Long userId, InvoiceRequest req) {
        Booking booking = bookingRepo.findById(req.bookingId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + req.bookingId()));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied: booking belongs to another user");

        Payment payment = paymentRepo.findById(req.paymentId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Payment not found: " + req.paymentId()));
        if (!payment.getBooking().getId().equals(booking.getId()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "Payment does not belong to this booking");
        if (payment.getStatus() != PaymentStatus.PAID)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only a PAID payment can generate an invoice");

        if (invoiceRepo.existsByBookingId(booking.getId()))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "An invoice already exists for this booking");

        User user = booking.getUser();

        Invoice invoice = new Invoice();
        invoice.setBooking(booking);
        invoice.setPayment(payment);
        invoice.setUser(user);
        invoice.setHotel(booking.getHotel());
        invoice.setStatus(InvoiceStatus.ISSUED);
        invoice.setCurrency(booking.getCurrency());
        invoice.setSubtotal(booking.getBasePrice());
        invoice.setDiscountAmount(booking.getDiscountAmount());
        invoice.setTaxAmount(BigDecimal.ZERO.setScale(2));
        invoice.setTotalAmount(payment.getAmount());
        invoice.setIssuedAt(Instant.now());
        invoice.setPaidAt(payment.getPaidAt());
        invoice.setBillingName(req.billingName() != null ? req.billingName() : user.getFullName());
        invoice.setBillingEmail(req.billingEmail() != null ? req.billingEmail() : user.getEmail());
        invoice.setBillingPhone(req.billingPhone());
        invoice.setBillingAddress(req.billingAddress());
        invoice.setTaxCode(req.taxCode());
        invoice.setNotes(req.notes());

        invoice = invoiceRepo.save(invoice);
        invoice.setInvoiceNumber(generateNumber(invoice.getId()));
        invoice = invoiceRepo.save(invoice);

        notificationService.create(user.getId(), NotificationType.BOOKING, Priority.NORMAL,
            "Invoice issued",
            "Your invoice " + invoice.getInvoiceNumber() + " for booking " + booking.getBookingCode()
                + " has been issued.",
            RelatedEntityType.BOOKING, booking.getId());

        return toResponse(invoice);
    }

    @Transactional(readOnly = true)
    public InvoiceResponse getInvoice(Long userId, Long invoiceId) {
        Invoice invoice = invoiceRepo.findById(invoiceId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Invoice not found: " + invoiceId));
        checkOwnerOrAdmin(userId, invoice.getUser().getId());
        return toResponse(invoice);
    }

    @Transactional(readOnly = true)
    public InvoiceResponse getInvoiceByBooking(Long userId, Long bookingId) {
        Invoice invoice = invoiceRepo.findByBookingId(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "No invoice found for booking: " + bookingId));
        checkOwnerOrAdmin(userId, invoice.getUser().getId());
        return toResponse(invoice);
    }

    @Transactional(readOnly = true)
    public List<InvoiceSummaryResponse> listMine(Long userId) {
        return invoiceRepo.findByUserIdOrderByCreatedAtDesc(userId)
            .stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public List<InvoiceResponse> adminList() {
        return invoiceRepo.findAllByOrderByCreatedAtDesc()
            .stream().map(this::toResponse).toList();
    }

    @Transactional
    public InvoiceResponse adminUpdateStatus(Long invoiceId, InvoiceStatus newStatus) {
        Invoice invoice = invoiceOrThrow(invoiceId);
        Instant now = Instant.now();
        invoice.setStatus(newStatus);
        if (newStatus == InvoiceStatus.PAID && invoice.getPaidAt() == null)
            invoice.setPaidAt(now);
        if (newStatus == InvoiceStatus.CANCELLED && invoice.getCancelledAt() == null)
            invoice.setCancelledAt(now);
        return toResponse(invoiceRepo.save(invoice));
    }

    @Transactional
    public InvoiceResponse cancelInvoice(Long invoiceId) {
        Invoice invoice = invoiceOrThrow(invoiceId);
        if (invoice.getStatus() == InvoiceStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Invoice is already cancelled");
        invoice.setStatus(InvoiceStatus.CANCELLED);
        invoice.setCancelledAt(Instant.now());
        return toResponse(invoiceRepo.save(invoice));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private Invoice invoiceOrThrow(Long invoiceId) {
        return invoiceRepo.findById(invoiceId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Invoice not found: " + invoiceId));
    }

    private void checkOwnerOrAdmin(Long userId, Long ownerId) {
        if (ownerId.equals(userId)) return;
        User requestingUser = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
        if (!"ADMIN".equals(requestingUser.getRole()))
            throw new ApiException(HttpStatus.FORBIDDEN, "Access denied");
    }

    private String generateNumber(Long id) {
        return "INV-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE)
            + "-" + String.format("%06d", id);
    }

    private InvoiceResponse toResponse(Invoice i) {
        return new InvoiceResponse(
            i.getId(),
            i.getInvoiceNumber(),
            i.getBooking().getId(), i.getBooking().getBookingCode(),
            i.getPayment() != null ? i.getPayment().getId() : null,
            i.getPayment() != null ? i.getPayment().getPaymentCode() : null,
            i.getUser().getId(),
            i.getHotel().getId(), i.getHotel().getName(),
            i.getStatus().name(),
            i.getCurrency(),
            i.getSubtotal(), i.getDiscountAmount(), i.getTaxAmount(), i.getTotalAmount(),
            i.getIssuedAt(), i.getPaidAt(), i.getCancelledAt(),
            i.getBillingName(), i.getBillingEmail(), i.getBillingPhone(), i.getBillingAddress(),
            i.getTaxCode(), i.getNotes(),
            i.getCreatedAt(), i.getUpdatedAt()
        );
    }

    private InvoiceSummaryResponse toSummary(Invoice i) {
        return new InvoiceSummaryResponse(
            i.getId(), i.getInvoiceNumber(),
            i.getBooking().getId(), i.getBooking().getBookingCode(),
            i.getStatus().name(),
            i.getTotalAmount(), i.getCurrency(),
            i.getIssuedAt()
        );
    }
}
