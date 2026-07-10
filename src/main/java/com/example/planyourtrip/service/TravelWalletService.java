package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.TravelWalletDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.InvoiceRepository;
import com.example.planyourtrip.repository.TravelWalletItemRepository;
import com.example.planyourtrip.repository.TripPlanCollaboratorRepository;
import com.example.planyourtrip.repository.TripPlanDocumentRepository;
import com.example.planyourtrip.repository.TripPlanRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;

/**
 * Phase 7.12 — Travel Wallet Foundation. Aggregates existing
 * {@link TripPlanDocument}, {@link Booking} and {@link Invoice} rows into a
 * single per-user organizer, without duplicating any of their file/business
 * data. Response mapping for those three linked entities is reused verbatim
 * from {@link TripPlanDocumentService#toResponse}, {@link BookingService#toSummary}
 * and {@link InvoiceService#toSummary} rather than re-implemented here.
 *
 * <p>Mirrors {@code TripPlannerService}'s three-tier permission model (owner /
 * active EDITOR / active VIEWER) via its own small, independently-duplicated
 * ownership checks — matching the established per-service convention (see
 * {@code TripPlanReminderService}, {@code TripPlanDocumentService}). Wallet
 * items themselves are strictly owner-only for every mutating operation;
 * {@code tripPlan} is only used to confirm the caller may reference that trip
 * when linking one on create.
 */
@Service
public class TravelWalletService {

    private final TravelWalletItemRepository walletRepo;
    private final UserRepository userRepo;
    private final TripPlanRepository tripRepo;
    private final TripPlanCollaboratorRepository collaboratorRepo;
    private final TripPlanDocumentRepository documentRepo;
    private final BookingRepository bookingRepo;
    private final InvoiceRepository invoiceRepo;
    private final TripPlanDocumentService tripPlanDocumentService;
    private final BookingService bookingService;
    private final InvoiceService invoiceService;

    public TravelWalletService(TravelWalletItemRepository walletRepo,
                                UserRepository userRepo,
                                TripPlanRepository tripRepo,
                                TripPlanCollaboratorRepository collaboratorRepo,
                                TripPlanDocumentRepository documentRepo,
                                BookingRepository bookingRepo,
                                InvoiceRepository invoiceRepo,
                                TripPlanDocumentService tripPlanDocumentService,
                                BookingService bookingService,
                                InvoiceService invoiceService) {
        this.walletRepo = walletRepo;
        this.userRepo = userRepo;
        this.tripRepo = tripRepo;
        this.collaboratorRepo = collaboratorRepo;
        this.documentRepo = documentRepo;
        this.bookingRepo = bookingRepo;
        this.invoiceRepo = invoiceRepo;
        this.tripPlanDocumentService = tripPlanDocumentService;
        this.bookingService = bookingService;
        this.invoiceService = invoiceService;
    }

    // ── Read ──────────────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<TravelWalletSummaryResponse> list(Long userId) {
        return walletRepo.findByUserIdOrderByCreatedAtDesc(userId).stream()
            .sorted(sortComparator())
            .map(this::toSummary)
            .toList();
    }

    @Transactional(readOnly = true)
    public TravelWalletItemResponse getMine(Long userId, Long id) {
        return toResponse(ownedItemOrThrow(userId, id));
    }

    /** Admin visibility only — strictly read-only, matches {@code CustomerProfileService#adminGetProfile}. */
    @Transactional(readOnly = true)
    public List<TravelWalletSummaryResponse> adminList(Long targetUserId) {
        userRepo.findById(targetUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + targetUserId));
        return walletRepo.findByUserIdOrderByCreatedAtDesc(targetUserId).stream()
            .sorted(sortComparator())
            .map(this::toSummary)
            .toList();
    }

    // ── Create / update / delete ─────────────────────────────────────────────

    @Transactional
    public TravelWalletItemResponse create(Long userId, TravelWalletItemRequest req) {
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TripPlan tripPlan = req.tripPlanId() != null ? viewableTripOrThrow(userId, req.tripPlanId()) : null;
        TripPlanDocument document = req.tripPlanDocumentId() != null
            ? viewableDocumentOrThrow(userId, req.tripPlanDocumentId()) : null;
        Booking booking = req.bookingId() != null ? ownedBookingOrThrow(userId, req.bookingId()) : null;
        Invoice invoice = req.invoiceId() != null ? ownedInvoiceOrThrow(userId, req.invoiceId()) : null;

        if (document == null && booking == null && invoice == null && isBlank(req.displayTitle()))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "At least one of tripPlanDocumentId, bookingId, invoiceId or displayTitle must be provided");

        rejectExplicitExpired(req.status());

        TravelWalletItem item = new TravelWalletItem();
        item.setUser(user);
        item.setTripPlan(tripPlan);
        item.setTripPlanDocument(document);
        item.setBooking(booking);
        item.setInvoice(invoice);
        item.setWalletItemType(req.walletItemType());
        item.setDisplayTitle(resolveDisplayTitle(req.displayTitle(), document, booking, invoice, null));
        item.setIssuer(req.issuer());
        item.setReferenceNumberMasked(maskReference(req.referenceNumber()));
        item.setValidFrom(req.validFrom());
        item.setValidUntil(req.validUntil());
        item.setStatus(req.status() != null ? req.status() : TravelWalletItemStatus.ACTIVE);
        item.setFavorite(false);
        item.setArchived(false);

        return toResponse(walletRepo.save(item));
    }

    /**
     * Metadata-only update — mirrors {@code TripPlanDocumentService#update}: link
     * fields (tripPlan/document/booking/invoice) set at creation are immutable
     * afterwards, only display metadata and validity/status can change.
     */
    @Transactional
    public TravelWalletItemResponse update(Long userId, Long id, TravelWalletItemRequest req) {
        TravelWalletItem item = ownedItemOrThrow(userId, id);
        rejectExplicitExpired(req.status());

        item.setWalletItemType(req.walletItemType());
        item.setDisplayTitle(resolveDisplayTitle(req.displayTitle(), item.getTripPlanDocument(),
            item.getBooking(), item.getInvoice(), item.getDisplayTitle()));
        item.setIssuer(req.issuer());
        item.setReferenceNumberMasked(maskReference(req.referenceNumber()));
        item.setValidFrom(req.validFrom());
        item.setValidUntil(req.validUntil());
        if (req.status() != null) item.setStatus(req.status());

        return toResponse(walletRepo.save(item));
    }

    /** Hard delete of the wallet item row only — never cascades to the referenced Document/Booking/Invoice/MediaAsset. */
    @Transactional
    public void delete(Long userId, Long id) {
        walletRepo.delete(ownedItemOrThrow(userId, id));
    }

    // ── Favorite / archive toggles ───────────────────────────────────────────

    @Transactional
    public TravelWalletItemResponse favorite(Long userId, Long id) {
        TravelWalletItem item = ownedItemOrThrow(userId, id);
        item.setFavorite(true);
        return toResponse(walletRepo.save(item));
    }

    @Transactional
    public TravelWalletItemResponse unfavorite(Long userId, Long id) {
        TravelWalletItem item = ownedItemOrThrow(userId, id);
        item.setFavorite(false);
        return toResponse(walletRepo.save(item));
    }

    /** Soft delete — sets {@code archived = true}, the row is kept. */
    @Transactional
    public TravelWalletItemResponse archive(Long userId, Long id) {
        TravelWalletItem item = ownedItemOrThrow(userId, id);
        item.setArchived(true);
        return toResponse(walletRepo.save(item));
    }

    @Transactional
    public TravelWalletItemResponse restore(Long userId, Long id) {
        TravelWalletItem item = ownedItemOrThrow(userId, id);
        item.setArchived(false);
        return toResponse(walletRepo.save(item));
    }

    // ── Automatic import (explicit-trigger only, idempotent) ────────────────

    @Transactional
    public TravelWalletImportResponse importTripDocument(Long userId, Long documentId) {
        var existing = walletRepo.findByUserIdAndTripPlanDocumentId(userId, documentId);
        if (existing.isPresent()) return new TravelWalletImportResponse(toResponse(existing.get()), false);

        TripPlanDocument document = viewableDocumentOrThrow(userId, documentId);
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TravelWalletItem item = new TravelWalletItem();
        item.setUser(user);
        item.setTripPlan(document.getTripPlan());
        item.setTripPlanDocument(document);
        item.setWalletItemType(mapDocumentType(document.getDocumentType()));
        item.setDisplayTitle(!isBlank(document.getTitle()) ? document.getTitle() : humanize(document.getDocumentType().name()));
        item.setStatus(TravelWalletItemStatus.ACTIVE);
        item.setFavorite(false);
        item.setArchived(false);

        return new TravelWalletImportResponse(toResponse(walletRepo.save(item)), true);
    }

    @Transactional
    public TravelWalletImportResponse importBooking(Long userId, Long bookingId) {
        var existing = walletRepo.findByUserIdAndBookingId(userId, bookingId);
        if (existing.isPresent()) return new TravelWalletImportResponse(toResponse(existing.get()), false);

        Booking booking = ownedBookingOrThrow(userId, bookingId);
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TravelWalletItem item = new TravelWalletItem();
        item.setUser(user);
        item.setBooking(booking);
        // Booking has no explicit "booking type" discriminator field in this codebase
        // (every Booking row is a hotel-room reservation), so there is nothing to
        // branch on — default to BOOKING_CONFIRMATION per the spec's fallback rule.
        item.setWalletItemType(TravelWalletItemType.BOOKING_CONFIRMATION);
        item.setDisplayTitle("Booking " + booking.getBookingCode());
        item.setIssuer(booking.getHotel() != null ? booking.getHotel().getName() : null);
        item.setReferenceNumberMasked(maskReference(booking.getBookingCode()));
        item.setValidFrom(booking.getCheckInDate());
        item.setValidUntil(booking.getCheckOutDate());
        item.setStatus(TravelWalletItemStatus.ACTIVE);
        item.setFavorite(false);
        item.setArchived(false);

        return new TravelWalletImportResponse(toResponse(walletRepo.save(item)), true);
    }

    @Transactional
    public TravelWalletImportResponse importInvoice(Long userId, Long invoiceId) {
        var existing = walletRepo.findByUserIdAndInvoiceId(userId, invoiceId);
        if (existing.isPresent()) return new TravelWalletImportResponse(toResponse(existing.get()), false);

        Invoice invoice = ownedInvoiceOrThrow(userId, invoiceId);
        User user = userRepo.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));

        TravelWalletItem item = new TravelWalletItem();
        item.setUser(user);
        item.setInvoice(invoice);
        item.setWalletItemType(TravelWalletItemType.INVOICE);
        item.setDisplayTitle("Invoice " + invoice.getInvoiceNumber());
        item.setIssuer(invoice.getHotel() != null ? invoice.getHotel().getName() : null);
        item.setReferenceNumberMasked(maskReference(invoice.getInvoiceNumber()));
        item.setStatus(TravelWalletItemStatus.ACTIVE);
        item.setFavorite(false);
        item.setArchived(false);

        return new TravelWalletImportResponse(toResponse(walletRepo.save(item)), true);
    }

    // ── Permission helpers (duplicated by convention — see class javadoc) ───

    private boolean isOwner(TripPlan trip, Long userId) {
        return trip.getUser().getId().equals(userId);
    }

    private boolean canView(TripPlan trip, Long userId) {
        if (isOwner(trip, userId)) return true;
        return collaboratorRepo.findByTripPlanIdAndUserId(trip.getId(), userId)
            .map(TripPlanCollaborator::isActive).orElse(false);
    }

    private TripPlan viewableTripOrThrow(Long userId, Long tripId) {
        TripPlan trip = tripRepo.findById(tripId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId));
        if (!canView(trip, userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Trip not found: " + tripId);
        return trip;
    }

    private TripPlanDocument viewableDocumentOrThrow(Long userId, Long documentId) {
        TripPlanDocument document = documentRepo.findById(documentId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Document not found: " + documentId));
        if (!canView(document.getTripPlan(), userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Document not found: " + documentId);
        return document;
    }

    /** 404 (not 403) on another user's booking, matching the "avoid leaking existence" convention used in 7.10/7.11. */
    private Booking ownedBookingOrThrow(Long userId, Long bookingId) {
        Booking booking = bookingRepo.findById(bookingId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId));
        if (!booking.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Booking not found: " + bookingId);
        return booking;
    }

    /** 404 (not 403) on another user's invoice, matching the "avoid leaking existence" convention used in 7.10/7.11. */
    private Invoice ownedInvoiceOrThrow(Long userId, Long invoiceId) {
        Invoice invoice = invoiceRepo.findById(invoiceId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Invoice not found: " + invoiceId));
        if (!invoice.getUser().getId().equals(userId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Invoice not found: " + invoiceId);
        return invoice;
    }

    private TravelWalletItem ownedItemOrThrow(Long userId, Long id) {
        return walletRepo.findByIdAndUserId(id, userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Wallet item not found: " + id));
    }

    // ── Validation / mutation helpers ────────────────────────────────────────

    private void rejectExplicitExpired(TravelWalletItemStatus status) {
        if (status == TravelWalletItemStatus.EXPIRED)
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "status EXPIRED is computed automatically from validUntil and cannot be set directly");
    }

    private String resolveDisplayTitle(String requested, TripPlanDocument document, Booking booking,
                                        Invoice invoice, String fallbackExisting) {
        if (!isBlank(requested)) return requested.trim();
        if (document != null) return !isBlank(document.getTitle()) ? document.getTitle() : humanize(document.getDocumentType().name());
        if (booking != null) return "Booking " + booking.getBookingCode();
        if (invoice != null) return "Invoice " + invoice.getInvoiceNumber();
        if (!isBlank(fallbackExisting)) return fallbackExisting;
        throw new ApiException(HttpStatus.BAD_REQUEST, "displayTitle is required when no document/booking/invoice is linked");
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }

    private String humanize(String enumName) {
        String[] parts = enumName.split("_");
        StringBuilder sb = new StringBuilder();
        for (String p : parts) {
            if (sb.length() > 0) sb.append(' ');
            sb.append(p.substring(0, 1)).append(p.substring(1).toLowerCase(Locale.ROOT));
        }
        return sb.toString();
    }

    /**
     * Masking scheme (reused from {@code CustomerProfileService#maskPassport}'s
     * established "store only last4" convention, Phase 6.x/7.x): the last 4
     * characters remain visible, everything before them is replaced with
     * {@code *}. Values of 4 characters or fewer are masked entirely. The raw
     * value passed in is never persisted — only the masked result is stored on
     * {@code referenceNumberMasked}, so this method must be called on every
     * write path (create/update/import) before setting that field.
     */
    private String maskReference(String raw) {
        if (isBlank(raw)) return null;
        String trimmed = raw.trim();
        if (trimmed.length() <= 4) return "*".repeat(trimmed.length());
        String last4 = trimmed.substring(trimmed.length() - 4);
        return "*".repeat(trimmed.length() - 4) + last4;
    }

    private TravelWalletItemType mapDocumentType(TripPlanDocumentType t) {
        return switch (t) {
            case FLIGHT_TICKET -> TravelWalletItemType.FLIGHT_TICKET;
            case HOTEL_BOOKING -> TravelWalletItemType.HOTEL_VOUCHER;
            case TRAIN_TICKET -> TravelWalletItemType.TRAIN_TICKET;
            case BUS_TICKET -> TravelWalletItemType.BUS_TICKET;
            case PASSPORT -> TravelWalletItemType.PASSPORT;
            case VISA -> TravelWalletItemType.VISA;
            case INSURANCE -> TravelWalletItemType.INSURANCE;
            case TOUR -> TravelWalletItemType.TOUR_VOUCHER;
            case RECEIPT -> TravelWalletItemType.RECEIPT;
            case PDF, IMAGE, OTHER -> TravelWalletItemType.OTHER;
        };
    }

    // ── Effective status computation (read-time only, never persisted) ──────

    private TravelWalletItemStatus effectiveStatus(TravelWalletItem item) {
        if (item.isArchived()) return TravelWalletItemStatus.ARCHIVED;
        if (item.getStatus() == TravelWalletItemStatus.CANCELLED) return TravelWalletItemStatus.CANCELLED;
        LocalDate today = LocalDate.now();
        if (item.getValidUntil() != null && item.getValidUntil().isBefore(today)) return TravelWalletItemStatus.EXPIRED;
        if (item.getValidFrom() != null && item.getValidFrom().isAfter(today)) return TravelWalletItemStatus.UPCOMING;
        return item.getStatus();
    }

    private boolean isExpired(TravelWalletItem item) {
        return item.getValidUntil() != null && item.getValidUntil().isBefore(LocalDate.now());
    }

    private int statusPriority(TravelWalletItemStatus effective) {
        return switch (effective) {
            case ACTIVE, UPCOMING -> 0;
            case EXPIRED -> 1;
            case CANCELLED -> 2;
            case ARCHIVED -> 3;
        };
    }

    /** archived ASC, favorite DESC, effective-upcoming/active first, validFrom ASC (nulls last), createdAt DESC. */
    private Comparator<TravelWalletItem> sortComparator() {
        return Comparator
            .comparing(TravelWalletItem::isArchived)
            .thenComparing(i -> !i.isFavorite())
            .thenComparing(i -> statusPriority(effectiveStatus(i)))
            .thenComparing(i -> i.getValidFrom() == null ? LocalDate.MAX : i.getValidFrom())
            .thenComparing(Comparator.comparing(TravelWalletItem::getCreatedAt).reversed());
    }

    // ── Response mapping ─────────────────────────────────────────────────────

    private TravelWalletItemResponse toResponse(TravelWalletItem i) {
        TravelWalletTripSummary tripSummary = i.getTripPlan() != null
            ? new TravelWalletTripSummary(i.getTripPlan().getId(), i.getTripPlan().getTitle(),
                i.getTripPlan().getDestination(), i.getTripPlan().getStartDate(), i.getTripPlan().getEndDate())
            : null;

        return new TravelWalletItemResponse(
            i.getId(), i.getUser().getId(), tripSummary,
            i.getTripPlanDocument() != null ? tripPlanDocumentService.toResponse(i.getTripPlanDocument()) : null,
            i.getBooking() != null ? bookingService.toSummary(i.getBooking()) : null,
            i.getInvoice() != null ? invoiceService.toSummary(i.getInvoice()) : null,
            i.getWalletItemType().name(), i.getDisplayTitle(), i.getIssuer(), i.getReferenceNumberMasked(),
            i.getValidFrom(), i.getValidUntil(), i.getStatus().name(), effectiveStatus(i).name(), isExpired(i),
            i.isFavorite(), i.isArchived(), i.getCreatedAt(), i.getUpdatedAt()
        );
    }

    private TravelWalletSummaryResponse toSummary(TravelWalletItem i) {
        return new TravelWalletSummaryResponse(
            i.getId(),
            i.getTripPlan() != null ? i.getTripPlan().getId() : null,
            i.getTripPlan() != null ? i.getTripPlan().getTitle() : null,
            i.getWalletItemType().name(), i.getDisplayTitle(), i.getIssuer(), i.getReferenceNumberMasked(),
            i.getValidFrom(), i.getValidUntil(), i.getStatus().name(), effectiveStatus(i).name(), isExpired(i),
            i.isFavorite(), i.isArchived(), i.getCreatedAt(), i.getUpdatedAt()
        );
    }
}
