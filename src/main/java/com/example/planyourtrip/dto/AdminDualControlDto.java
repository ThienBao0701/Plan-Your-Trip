package com.example.planyourtrip.dto;

import com.example.planyourtrip.dto.PartnerHotelDto.PartnerHotelResponse;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.Instant;

/** RBAC R6 — dual-control requests for A16 (RBAC V1.1 §22.6). */
public class AdminDualControlDto {

    /**
     * One request as an eligible administrator reviews it. {@code status} is what the request is now: a pending
     * request past its 24 hours reads {@code EXPIRED} even before a decision attempt persists that. {@code mine} marks
     * the caller's own request, which they may cancel but never approve or reject.
     */
    public record DualControlRequestResponse(
        Long id,
        String permission,
        String targetType,
        Long targetId,
        OwnerAssignmentProposal proposal,
        String status,
        Long requestedBy,
        String requestedByName,
        Instant requestedAt,
        Instant expiresAt,
        String reason,
        Long decidedBy,
        Instant decidedAt,
        String decisionReason,
        boolean mine
    ) {}

    /**
     * The immutable A16 proposal, read from the stored payload: move {@code placeId} from
     * {@code expectedOwnerProfileId} (null: no owner) to {@code proposedOwnerProfileId}. Names are read live for the
     * reviewer's convenience; the ids are what executes.
     */
    public record OwnerAssignmentProposal(
        Long placeId,
        String placeName,
        Long expectedOwnerProfileId,
        String expectedOwnerName,
        Long proposedOwnerProfileId,
        String proposedOwnerName
    ) {}

    /** {@code POST …/{id}/approve}: the closed request and the property as the executed move left it. */
    public record DualControlApprovalResponse(
        DualControlRequestResponse request,
        PartnerHotelResponse result
    ) {}

    /** {@code POST …/{id}/reject}: the reason is required, credential-free, at most 500 characters. */
    public record DualControlRejectRequest(
        @NotBlank @Size(max = 500) String reason
    ) {}
}
