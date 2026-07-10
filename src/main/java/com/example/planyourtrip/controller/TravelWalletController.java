package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TravelWalletDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TravelWalletService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.12 — Travel Wallet Foundation. Owner-only CRUD over
 * {@code TravelWalletItem}, plus explicit-trigger idempotent import from an
 * existing {@code TripPlanDocument}/{@code Booking}/{@code Invoice}. No file
 * upload here — every item either references one of those existing records
 * or stands alone as metadata.
 */
@RestController
@RequestMapping("/api/me/travel-wallet")
@Tag(name = "Customer - Travel Wallet", description = "Unified organizer for a user's travel documents/references across trips")
@SecurityRequirement(name = "bearerAuth")
public class TravelWalletController {

    private final TravelWalletService service;

    public TravelWalletController(TravelWalletService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my wallet items (archived last, favorites first, then upcoming/active, then by validFrom/createdAt)")
    public List<TravelWalletSummaryResponse> list(@AuthUser Long uid) {
        return service.list(uid);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my own wallet items")
    public TravelWalletItemResponse get(@AuthUser Long uid, @PathVariable Long id) {
        return service.getMine(uid, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a wallet item",
        description = "At least one of tripPlanDocumentId, bookingId, invoiceId or displayTitle must be provided.")
    public TravelWalletItemResponse create(@AuthUser Long uid, @Valid @RequestBody TravelWalletItemRequest req) {
        return service.create(uid, req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a wallet item's metadata (link fields are immutable after creation)")
    public TravelWalletItemResponse update(@AuthUser Long uid, @PathVariable Long id,
                                            @Valid @RequestBody TravelWalletItemRequest req) {
        return service.update(uid, id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Hard-delete a wallet item (never deletes the underlying document/booking/invoice)")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.delete(uid, id);
    }

    @PatchMapping("/{id}/favorite")
    @Operation(summary = "Mark a wallet item as favorite")
    public TravelWalletItemResponse favorite(@AuthUser Long uid, @PathVariable Long id) {
        return service.favorite(uid, id);
    }

    @PatchMapping("/{id}/unfavorite")
    @Operation(summary = "Unmark a wallet item as favorite")
    public TravelWalletItemResponse unfavorite(@AuthUser Long uid, @PathVariable Long id) {
        return service.unfavorite(uid, id);
    }

    @PatchMapping("/{id}/archive")
    @Operation(summary = "Archive a wallet item (soft delete)")
    public TravelWalletItemResponse archive(@AuthUser Long uid, @PathVariable Long id) {
        return service.archive(uid, id);
    }

    @PatchMapping("/{id}/restore")
    @Operation(summary = "Restore an archived wallet item")
    public TravelWalletItemResponse restore(@AuthUser Long uid, @PathVariable Long id) {
        return service.restore(uid, id);
    }

    @PostMapping("/import/trip-document/{documentId}")
    @Operation(summary = "Import a TripPlanDocument into the wallet (idempotent per user+document)")
    public TravelWalletImportResponse importTripDocument(@AuthUser Long uid, @PathVariable Long documentId) {
        return service.importTripDocument(uid, documentId);
    }

    @PostMapping("/import/booking/{bookingId}")
    @Operation(summary = "Import one of my own bookings into the wallet (idempotent per user+booking)")
    public TravelWalletImportResponse importBooking(@AuthUser Long uid, @PathVariable Long bookingId) {
        return service.importBooking(uid, bookingId);
    }

    @PostMapping("/import/invoice/{invoiceId}")
    @Operation(summary = "Import one of my own invoices into the wallet (idempotent per user+invoice)")
    public TravelWalletImportResponse importInvoice(@AuthUser Long uid, @PathVariable Long invoiceId) {
        return service.importInvoice(uid, invoiceId);
    }
}
