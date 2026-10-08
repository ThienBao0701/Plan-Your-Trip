package com.example.planyourtrip.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;
import java.util.List;

public class ConversationDto {

    public record ConversationRequest(
        @NotNull Long bookingId,
        String subject
    ) {}

    public record MessageRequest(
        @NotBlank String body
    ) {}

    public record MessageResponse(
        Long id,
        Long conversationId,
        Long senderUserId,
        String senderName,
        String senderRole,
        String body,
        boolean readByUser,
        boolean readByPartner,
        Instant createdAt
    ) {}

    public record ConversationResponse(
        Long id,
        Long bookingId,
        String bookingCode,
        Long userId,
        String userName,
        Long partnerProfileId,
        String partnerBusinessName,
        String status,
        String subject,
        Instant lastMessageAt,
        Instant createdAt,
        Instant updatedAt,
        List<MessageResponse> messages
    ) {}

    public record ConversationSummaryResponse(
        Long id,
        Long bookingId,
        String bookingCode,
        String subject,
        String status,
        Instant lastMessageAt,
        String lastMessagePreview,
        long unreadCount,
        Instant createdAt
    ) {}

    /**
     * RBAC R3b — a message as a partner sees it: no sender account id (§21.3 NR-2); a guest's name is masked without
     * {@code booking.guest_identity.view} (P54).
     */
    public record PartnerMessageView(
        Long id,
        Long conversationId,
        String senderName,
        String senderRole,
        String body,
        boolean readByUser,
        boolean readByPartner,
        Instant createdAt
    ) {}

    /**
     * RBAC R3b — a conversation as a partner sees it: no traveller {@code userId} (NR-2); {@code userName} and guest
     * sender names masked without P54 at the booking's property; {@code redacted} lists what was masked.
     */
    public record PartnerConversationView(
        Long id,
        Long bookingId,
        String bookingCode,
        String userName,
        Long partnerProfileId,
        String partnerBusinessName,
        String status,
        String subject,
        Instant lastMessageAt,
        Instant createdAt,
        Instant updatedAt,
        List<PartnerMessageView> messages,
        List<com.example.planyourtrip.dto.RedactedField> redacted
    ) {}
}
