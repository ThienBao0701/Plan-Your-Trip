package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.BookingDto.BookingSummaryResponse;
import com.example.planyourtrip.dto.InvoiceDto.InvoiceSummaryResponse;
import com.example.planyourtrip.dto.TripPlanDocumentDto.TripPlanDocumentResponse;
import com.example.planyourtrip.model.TravelWalletItemStatus;
import com.example.planyourtrip.model.TravelWalletItemType;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.time.LocalDate;

public class TravelWalletDto {

    /**
     * Link fields ({@code tripPlanId}/{@code tripPlanDocumentId}/{@code bookingId}/
     * {@code invoiceId}) are only honoured on create; {@code update} ignores them and
     * only mutates metadata — mirroring {@code TripPlanDocumentDto}'s "registration
     * fields are ignored on update" convention. On create, at least one of
     * {tripPlanDocumentId, bookingId, invoiceId, displayTitle} must be meaningfully
     * present. {@code referenceNumber} is masked server-side before storage — the raw
     * value submitted here is never persisted or echoed back (see
     * {@code TravelWalletService#maskReference}). {@code status} may not be set to
     * {@code EXPIRED} directly — that value is always computed from
     * {@code validUntil} on read.
     */
    public record TravelWalletItemRequest(
        Long tripPlanId,
        Long tripPlanDocumentId,
        Long bookingId,
        Long invoiceId,
        @NotNull TravelWalletItemType walletItemType,
        String displayTitle,
        String issuer,
        String referenceNumber,
        LocalDate validFrom,
        LocalDate validUntil,
        TravelWalletItemStatus status,
        /** Phase 7.13. Null on create defaults to {@code true}; null on update leaves the existing value unchanged. */
        Boolean expiryReminderEnabled
    ) {}

    public record TravelWalletTripSummary(
        Long id,
        String title,
        String destination,
        LocalDate startDate,
        LocalDate endDate
    ) {}

    /**
     * {@code status} is the stored/base status; {@code effectiveStatus} is the
     * computed one (accounts for archived/cancelled/expiry) and is what clients
     * should generally display. {@code document}/{@code booking}/{@code invoice}
     * reuse the existing response mappers from their own services verbatim.
     */
    public record TravelWalletItemResponse(
        Long id,
        Long userId,
        TravelWalletTripSummary tripPlan,
        TripPlanDocumentResponse document,
        BookingSummaryResponse booking,
        InvoiceSummaryResponse invoice,
        String walletItemType,
        String displayTitle,
        String issuer,
        String referenceNumberMasked,
        LocalDate validFrom,
        LocalDate validUntil,
        String status,
        String effectiveStatus,
        boolean expired,
        boolean favorite,
        boolean archived,
        /** Phase 7.13 — whether {@code WalletExpiryReminderService} will generate expiry reminders for this item. */
        boolean expiryReminderEnabled,
        /** Phase 7.13 — computed from {@code walletItemType} via {@code WalletOrganizerCategory#forItemType}, never persisted. */
        String organizerCategory,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /** Lightweight list-view projection (mirrors BookingSummaryResponse/InvoiceSummaryResponse). */
    public record TravelWalletSummaryResponse(
        Long id,
        Long tripPlanId,
        String tripPlanTitle,
        String walletItemType,
        String displayTitle,
        String issuer,
        String referenceNumberMasked,
        LocalDate validFrom,
        LocalDate validUntil,
        String status,
        String effectiveStatus,
        boolean expired,
        boolean favorite,
        boolean archived,
        boolean expiryReminderEnabled,
        String organizerCategory,
        Instant createdAt,
        Instant updatedAt
    ) {}

    /** {@code created} is false when an idempotent import returned a pre-existing item instead of inserting a new row. */
    public record TravelWalletImportResponse(
        TravelWalletItemResponse item,
        boolean created
    ) {}
}
