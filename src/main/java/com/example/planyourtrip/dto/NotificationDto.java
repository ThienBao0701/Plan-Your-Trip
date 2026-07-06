package com.example.planyourtrip.dto;

import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RelatedEntityType;
import jakarta.validation.constraints.NotBlank;

import java.time.Instant;

public class NotificationDto {

    public record NotificationResponse(
        Long id,
        String title,
        String message,
        NotificationType notificationType,
        Priority priority,
        RelatedEntityType relatedEntityType,
        Long relatedEntityId,
        boolean read,
        Instant readAt,
        Instant createdAt
    ) {}

    public record NotificationSummaryResponse(
        Long id,
        String title,
        String message,
        NotificationType notificationType,
        Priority priority,
        boolean read,
        Instant createdAt
    ) {}

    public record BroadcastRequest(
        @NotBlank String title,
        @NotBlank String message,
        NotificationType notificationType,
        Priority priority,
        RelatedEntityType relatedEntityType,
        Long relatedEntityId
    ) {}
}
