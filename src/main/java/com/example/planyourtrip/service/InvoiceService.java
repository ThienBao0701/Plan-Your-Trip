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
    private final AdminActivityLogService adminAudit;

    public InvoiceService(InvoiceRepository invoiceRepo,
                           BookingRepository bookingRepo,
                           PaymentRepository paymentRepo,
                           UserRepository userRepo,
                           NotificationService notificationService,
                           AdminActivityLogService adminAudit) {
        this.invoiceRepo = invoiceRepo;
        this.bookingRepo = bookingRepo;
        this.paymentRepo = paymentRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
        this.adminAudit = adminAudit;
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
        // Phase 7.16 — snapshot the coupon/credit lines from the booking (same
        // snapshot-at-issue convention as subtotal/discountAmount above); null
        // when the booking used no coupon / credits.
        invoice.setCouponCode(booking.getCouponCode());
        invoice.setCouponDiscountAmount(booking.getCouponDiscountAmount());
        invoice.setCreditAmountUsed(booking.getCreditAmountUsed());
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

    /** Entity properties an administrator may sort the invoice grid by (D1a-12 allowlist). */
    private static final java.util.Set<String> INVOICE_SORT_FIELDS = java.util.Set.of(
        "createdAt", "status", "issuedAt", "totalAmount");

    /** D1a — database-side paginated invoice grid, replacing the unbounded list (D0-2). */
    @Transactional(readOnly = true)
    public com.example.planyourtrip.dto.PageResponse<InvoiceResponse> adminListPaged(
            InvoiceStatus status, Integer page, Integer size, String sort) {
        org.springframework.data.domain.Pageable pageable =
            AdminPaging.of(page, size, sort, INVOICE_SORT_FIELDS, "createdAt");
        org.springframework.data.jpa.domain.Specification<Invoice> spec =
            (root, q, cb) -> status == null ? cb.conjunction() : cb.equal(root.get("status"), status);
        return com.example.planyourtrip.dto.PageResponse.of(
            invoiceRepo.findAll(spec, pageable).map(this::toResponse));
    }

    @Transactional
    public InvoiceResponse adminUpdateStatus(Long adminUserId, Long invoiceId, InvoiceStatus newStatus) {
        Invoice invoice = invoiceOrThrow(invoiceId);
        InvoiceStatus before = invoice.getStatus();
        Instant now = Instant.now();
        invoice.setStatus(newStatus);
        if (newStatus == InvoiceStatus.PAID && invoice.getPaidAt() == null)
            invoice.setPaidAt(now);
        if (newStatus == InvoiceStatus.CANCELLED && invoice.getCancelledAt() == null)
            invoice.setCancelledAt(now);
        Invoice saved = invoiceRepo.save(invoice);
        // D1c - an invoice is the customer's financial record of a stay. Forcing it to PAID
        // without a payment, or away from PAID, is an accounting act and is recorded as one.
        // Only the status pair and the invoice id are stored - never billing address, tax code
        // or contact details, all of which live on the same row.
        adminAudit.record(adminUserId, "INVOICE_STATUS_OVERRIDE", "INVOICE", saved.getId(),
            "Admin set invoice " + saved.getId() + " status",
            before == null ? null : before.name(),
            saved.getStatus() == null ? null : saved.getStatus().name());
        return toResponse(saved);
    }

    @Transactional
    public InvoiceResponse cancelInvoice(Long adminUserId, Long invoiceId) {
        Invoice invoice = invoiceOrThrow(invoiceId);
        if (invoice.getStatus() == InvoiceStatus.CANCELLED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Invoice is already cancelled");
        InvoiceStatus before = invoice.getStatus();
        invoice.setStatus(InvoiceStatus.CANCELLED);
        invoice.setCancelledAt(Instant.now());
        Invoice saved = invoiceRepo.save(invoice);
        adminAudit.record(adminUserId, "INVOICE_CANCEL", "INVOICE", saved.getId(),
            "Admin cancelled invoice " + saved.getId(),
            before == null ? null : before.name(), saved.getStatus().name());
        return toResponse(saved);
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

    InvoiceResponse toResponse(Invoice i) {
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
            i.getSubtotal(), i.getDiscountAmount(),
            i.getCouponCode(), i.getCouponDiscountAmount(), i.getCreditAmountUsed(),
            i.getTaxAmount(), i.getTotalAmount(),
            i.getIssuedAt(), i.getPaidAt(), i.getCancelledAt(),
            i.getBillingName(), i.getBillingEmail(), i.getBillingPhone(), i.getBillingAddress(),
            i.getTaxCode(), i.getNotes(),
            i.getCreatedAt(), i.getUpdatedAt()
        );
    }

    InvoiceSummaryResponse toSummary(Invoice i) {
        return new InvoiceSummaryResponse(
            i.getId(), i.getInvoiceNumber(),
            i.getBooking().getId(), i.getBooking().getBookingCode(),
            i.getStatus().name(),
            i.getTotalAmount(), i.getCurrency(),
            i.getIssuedAt()
        );
    }
}
