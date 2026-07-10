package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TravelWalletDto.*;
import com.example.planyourtrip.dto.TravelWalletOrganizerDto.*;
import com.example.planyourtrip.model.TravelWalletItemStatus;
import com.example.planyourtrip.model.TravelWalletItemType;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TravelWalletOrganizerService;
import com.example.planyourtrip.service.TravelWalletService;
import com.example.planyourtrip.service.WalletExpiryReminderService;
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
 *
 * <p>Phase 7.13 — Wallet Expiry Alerts &amp; Smart Organizer adds the
 * read-only summary/organizer/group endpoints (delegated to
 * {@link TravelWalletOrganizerService}), the optional filter/sort/page params
 * on the base list endpoint, and the manual expiry-reminder generation
 * triggers (delegated to {@link WalletExpiryReminderService} — reminder
 * *delivery* remains out of scope here, see {@code TripReminderDeliveryService}).
 */
@RestController
@RequestMapping("/api/me/travel-wallet")
@Tag(name = "Customer - Travel Wallet", description = "Unified organizer for a user's travel documents/references across trips")
@SecurityRequirement(name = "bearerAuth")
public class TravelWalletController {

    private final TravelWalletService service;
    private final TravelWalletOrganizerService organizerService;
    private final WalletExpiryReminderService expiryReminderService;

    public TravelWalletController(TravelWalletService service,
                                   TravelWalletOrganizerService organizerService,
                                   WalletExpiryReminderService expiryReminderService) {
        this.service = service;
        this.organizerService = organizerService;
        this.expiryReminderService = expiryReminderService;
    }

    @GetMapping
    @Operation(summary = "List my wallet items, optionally filtered/sorted/paginated",
        description = "No params behaves exactly like the pre-7.13 endpoint (all items, default sort). "
            + "status filters on the computed effective status, not the raw persisted one.")
    public List<TravelWalletSummaryResponse> list(@AuthUser Long uid,
                                                    @RequestParam(required = false) TravelWalletItemType type,
                                                    @RequestParam(required = false) TravelWalletItemStatus status,
                                                    @RequestParam(required = false) Long tripId,
                                                    @RequestParam(required = false) Boolean favorite,
                                                    @RequestParam(required = false) Boolean archived,
                                                    @RequestParam(required = false) Integer expiringWithinDays,
                                                    @RequestParam(required = false) Integer page,
                                                    @RequestParam(required = false) Integer size,
                                                    @RequestParam(required = false) String sort) {
        return service.list(uid, type, status, tripId, favorite, archived, expiringWithinDays, page, size, sort);
    }

    // ── Phase 7.13 — Smart Organizer (read-only) ─────────────────────────────

    @GetMapping("/summary")
    @Operation(summary = "Dashboard-style counts across my wallet (active/upcoming/expiring/expired/archived/favorite/unlinked, by type, by trip)")
    public TravelWalletSummaryMetrics summary(@AuthUser Long uid) {
        return organizerService.summary(uid);
    }

    @GetMapping("/organized")
    @Operation(summary = "My wallet grouped by favorites/expiringSoon/upcoming/active/expired/archived/byType/byTrip")
    public TravelWalletOrganizerResponse organized(@AuthUser Long uid) {
        return organizerService.organized(uid);
    }

    @GetMapping("/expiring-soon")
    @Operation(summary = "Items with validUntil within the next 30 days (inclusive) and not already expired")
    public TravelWalletGroupResponse expiringSoon(@AuthUser Long uid,
                                                    @RequestParam(required = false, defaultValue = "false") boolean archived) {
        return organizerService.expiringSoon(uid, archived);
    }

    @GetMapping("/expired")
    @Operation(summary = "Items whose validUntil has already passed")
    public TravelWalletGroupResponse expired(@AuthUser Long uid,
                                               @RequestParam(required = false, defaultValue = "false") boolean archived) {
        return organizerService.expired(uid, archived);
    }

    @GetMapping("/upcoming")
    @Operation(summary = "Items whose validFrom is in the future")
    public TravelWalletGroupResponse upcoming(@AuthUser Long uid,
                                                @RequestParam(required = false, defaultValue = "false") boolean archived) {
        return organizerService.upcoming(uid, archived);
    }

    @GetMapping("/unlinked")
    @Operation(summary = "Metadata-only items — no tripPlanDocument/booking/invoice and no tripPlan")
    public TravelWalletGroupResponse unlinked(@AuthUser Long uid,
                                                @RequestParam(required = false, defaultValue = "false") boolean archived) {
        return organizerService.unlinked(uid, archived);
    }

    // ── Phase 7.13 — Expiry reminder generation (creation only, no delivery) ─

    @PostMapping("/generate-expiry-reminders")
    @Operation(summary = "Generate 30/7/1-day-before expiry reminders for all of my eligible wallet items (idempotent)")
    public WalletExpiryReminderResultResponse generateExpiryReminders(@AuthUser Long uid) {
        return expiryReminderService.generateExpiryRemindersForUser(uid);
    }

    @PostMapping("/{id}/generate-expiry-reminders")
    @Operation(summary = "Generate 30/7/1-day-before expiry reminders for one of my own wallet items (idempotent)")
    public WalletExpiryReminderResultResponse generateExpiryRemindersForItem(@AuthUser Long uid, @PathVariable Long id) {
        return expiryReminderService.generateForWalletItem(uid, id);
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
