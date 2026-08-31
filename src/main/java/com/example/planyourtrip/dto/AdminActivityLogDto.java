package com.example.planyourtrip.dto;

import java.time.Instant;

/** D1a — read shapes for the administrative audit trail. */
public class AdminActivityLogDto {

    /**
     * One audit entry.
     *
     * <p>{@code actorEmail} is the snapshot taken when the action happened, not a live lookup, so a
     * later email change does not rewrite history. {@code beforeState}/{@code afterState} are short
     * safe scalars (a status, an amount + currency) and never serialised entities.
     */
    public record AdminActivityLogResponse(
        Long id,
        Long actorUserId,
        String actorEmail,
        String action,
        String targetType,
        Long targetId,
        String description,
        String beforeState,
        String afterState,
        Instant createdAt
    ) {}
}
