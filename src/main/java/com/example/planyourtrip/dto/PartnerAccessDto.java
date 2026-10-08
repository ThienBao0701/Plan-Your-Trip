package com.example.planyourtrip.dto;

import java.time.Instant;
import java.util.List;
import java.util.Map;

/**
 * RBAC R3b — the effective access document, {@code GET /api/partner/me/access} (RBAC V1.1 §25.2).
 *
 * <p>What the client uses to shape its menu and actions (§23 F2–F6). It never grants anything: the server decides
 * every request from stored data whatever this document says.
 */
public class PartnerAccessDto {

    public record AccessDocument(
        Workspace workspace,
        Membership membership,
        List<Grant> grants,
        Permissions permissions,
        Context context,
        StepUp stepUp
    ) {}

    public record Workspace(Long companyId, String businessName, String verificationStatus) {}

    /** The caller's membership row; for the primary owner, their own OWNER row. */
    public record Membership(Long id, String status, boolean primaryOwner, boolean pendingOwnerConfirmation) {}

    public record Grant(String role, String scopeType, Long scopeId) {}

    /**
     * Effective permission keys by scope, after scope floors (§4.5): a floor-C permission never appears under a
     * property, a floor-P permission never under a unit. Reserved permissions are never listed. Empty unless the
     * membership is ACTIVE (or the caller is the primary owner) and the company is APPROVED.
     */
    public record Permissions(List<String> company, Map<String, List<String>> properties,
                              Map<String, List<String>> units) {}

    /** §11.7 parent context: identity of the properties and room types the caller works in, nothing more. */
    public record Context(List<PropertyContext> properties, List<UnitContext> units) {}

    public record PropertyContext(Long id, String name, String locationLabel, boolean active, String placeStatus) {}

    public record UnitContext(Long id, String roomName, String roomCode, Long propertyId) {}

    /** Until when the current session counts as fresh for step-up actions (§18 O-7), or null. */
    public record StepUp(Instant freshUntil) {}
}
