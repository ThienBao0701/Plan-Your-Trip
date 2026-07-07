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
}
