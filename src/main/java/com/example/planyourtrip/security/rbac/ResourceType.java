package com.example.planyourtrip.security.rbac;

/**
 * Partner resource types and their designated view permission, {@code view(type)} of RBAC V1.1 §4.5.
 *
 * <p>The view permission decides 403 versus 404: a caller who may view a resource of this type at a scope
 * covering the target learns a refusal (403); anyone else learns nothing (404), even if an unrelated view
 * permission covers the same property.
 */
public enum ResourceType {
    PROPERTY(PartnerPermission.PROPERTY_VIEW),
    ROOM(PartnerPermission.ROOM_VIEW),
    CALENDAR(PartnerPermission.INVENTORY_VIEW),
    RATE_PLAN(PartnerPermission.RATE_VIEW),
    OCCUPANCY_PRICE(PartnerPermission.RATE_VIEW),
    PROMOTION(PartnerPermission.PROMOTION_VIEW),
    BOOKING(PartnerPermission.BOOKING_VIEW),
    CONVERSATION(PartnerPermission.CONVERSATION_VIEW),
    REVIEW(PartnerPermission.REVIEW_VIEW),
    MEMBERSHIP(PartnerPermission.TEAM_VIEW),
    /** RBAC R4 — a team invitation; seen, like a membership, through team view covering all of its grants. */
    INVITATION(PartnerPermission.TEAM_VIEW);

    private final PartnerPermission viewPermission;

    ResourceType(PartnerPermission viewPermission) {
        this.viewPermission = viewPermission;
    }

    public PartnerPermission viewPermission() {
        return viewPermission;
    }
}
