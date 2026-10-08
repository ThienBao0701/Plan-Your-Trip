package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.model.PartnerTeamRole;

import java.util.Arrays;
import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

import static com.example.planyourtrip.security.rbac.PartnerPermission.*;

/**
 * RBAC R3b — the default permission bundle of every partner role, exactly the matrix of RBAC V1.1 §10.1.
 *
 * <p>{@link #of} is the matrix as designed (OWNER 54, MANAGER 47, REVENUE 17, RESERVATIONS 16, FRONT_DESK 16,
 * FINANCE 13, CONTENT 8, HOUSEKEEPING 5, VIEWER 9). {@link #effective} is what a grant carries today: MANAGER's
 * team mutations (P08–P11, footnote ¹) take effect only in R4, so until then they are withheld and team mutations
 * stay owner-only. Reserved permissions are part of the bundles but no endpoint uses them (§9.1).
 *
 * <p>A bundle says what a role may do; where it may do it is the grant's scope, cut by each permission's floor
 * ({@link PartnerAuthorization#effectiveScopes}).
 */
public final class PartnerRoleBundles {

    /** MANAGER's team mutations, deferred to R4 (§10.1 footnote ¹, §31 Q3). */
    public static final Set<PartnerPermission> DEFERRED_TO_R4 =
        Set.copyOf(EnumSet.of(TEAM_INVITE, TEAM_ROLE_ASSIGN, TEAM_SUSPEND, TEAM_REMOVE));

    private static final Map<PartnerTeamRole, Set<PartnerPermission>> MATRIX = new EnumMap<>(PartnerTeamRole.class);

    static {
        MATRIX.put(PartnerTeamRole.OWNER, Set.copyOf(EnumSet.allOf(PartnerPermission.class)));
        MATRIX.put(PartnerTeamRole.MANAGER, set(
            WORKSPACE_ACCESS, BUSINESS_PROFILE_VIEW, SETTINGS_EDIT, ACTIVITY_LOG_VIEW,
            TEAM_VIEW, TEAM_INVITE, TEAM_ROLE_ASSIGN, TEAM_SUSPEND, TEAM_REMOVE,
            PROPERTY_VIEW, PROPERTY_CREATE, PROPERTY_CONTENT_EDIT, PROPERTY_POLICY_EDIT, PROPERTY_STATUS_TOGGLE,
            PROPERTY_MEDIA_MANAGE, PROPERTY_PUBLISH,
            ROOM_VIEW, ROOM_CREATE, ROOM_CONTENT_EDIT, ROOM_COMMERCIAL_EDIT, ROOM_STATUS_TOGGLE,
            INVENTORY_VIEW, INVENTORY_ALLOTMENT_EDIT, INVENTORY_RESTRICTION_EDIT,
            RATE_VIEW, RATE_EDIT, RATE_ACTIVATE, PROMOTION_VIEW, PROMOTION_MANAGE,
            BOOKING_VIEW, BOOKING_GUEST_CONTACT_VIEW, BOOKING_GUEST_IDENTITY_VIEW, BOOKING_PAYMENT_VIEW,
            BOOKING_ARRIVAL_OPERATE, BOOKING_DEPARTURE_OPERATE, BOOKING_NO_SHOW_MARK, BOOKING_STAY_VIEW, BOOKING_MODIFY,
            CONVERSATION_VIEW, CONVERSATION_RESPOND, REVIEW_VIEW, REVIEW_REPLY,
            HOUSEKEEPING_VIEW, HOUSEKEEPING_UPDATE,
            ANALYTICS_VIEW, FINANCE_REVENUE_VIEW, FINANCE_STATEMENT_VIEW));
        MATRIX.put(PartnerTeamRole.REVENUE, set(
            WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW, ROOM_COMMERCIAL_EDIT, ROOM_STATUS_TOGGLE,
            INVENTORY_VIEW, INVENTORY_ALLOTMENT_EDIT, INVENTORY_RESTRICTION_EDIT,
            RATE_VIEW, RATE_EDIT, RATE_ACTIVATE, PROMOTION_VIEW, PROMOTION_MANAGE,
            BOOKING_VIEW, REVIEW_VIEW, ANALYTICS_VIEW, FINANCE_REVENUE_VIEW));
        MATRIX.put(PartnerTeamRole.RESERVATIONS, set(
            WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW, INVENTORY_VIEW, INVENTORY_RESTRICTION_EDIT,
            RATE_VIEW, PROMOTION_VIEW,
            BOOKING_VIEW, BOOKING_GUEST_CONTACT_VIEW, BOOKING_GUEST_IDENTITY_VIEW, BOOKING_NO_SHOW_MARK,
            BOOKING_STAY_VIEW, BOOKING_MODIFY, CONVERSATION_VIEW, CONVERSATION_RESPOND, REVIEW_VIEW));
        MATRIX.put(PartnerTeamRole.FRONT_DESK, set(
            WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW, INVENTORY_VIEW, RATE_VIEW,
            BOOKING_VIEW, BOOKING_GUEST_CONTACT_VIEW, BOOKING_GUEST_IDENTITY_VIEW,
            BOOKING_ARRIVAL_OPERATE, BOOKING_DEPARTURE_OPERATE, BOOKING_NO_SHOW_MARK, BOOKING_STAY_VIEW,
            CONVERSATION_VIEW, CONVERSATION_RESPOND, HOUSEKEEPING_VIEW, HOUSEKEEPING_UPDATE));
        MATRIX.put(PartnerTeamRole.FINANCE, set(
            WORKSPACE_ACCESS, BUSINESS_PROFILE_VIEW, PROPERTY_VIEW, ROOM_VIEW,
            BOOKING_VIEW, BOOKING_GUEST_IDENTITY_VIEW, BOOKING_PAYMENT_VIEW,
            ANALYTICS_VIEW, FINANCE_REVENUE_VIEW, FINANCE_STATEMENT_VIEW, FINANCE_PAYOUT_VIEW,
            PAYOUT_ACCOUNT_VIEW, PAYOUT_ACCOUNT_MANAGE));
        MATRIX.put(PartnerTeamRole.CONTENT, set(
            WORKSPACE_ACCESS, PROPERTY_VIEW, PROPERTY_CONTENT_EDIT, PROPERTY_MEDIA_MANAGE,
            ROOM_VIEW, ROOM_CONTENT_EDIT, REVIEW_VIEW, REVIEW_REPLY));
        MATRIX.put(PartnerTeamRole.HOUSEKEEPING, set(
            WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW, HOUSEKEEPING_VIEW, HOUSEKEEPING_UPDATE));
        MATRIX.put(PartnerTeamRole.VIEWER, set(
            WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW, INVENTORY_VIEW, RATE_VIEW, PROMOTION_VIEW,
            BOOKING_VIEW, REVIEW_VIEW, ANALYTICS_VIEW));
    }

    private PartnerRoleBundles() {}

    /** The §10.1 bundle of {@code role}; empty for none. */
    public static Set<PartnerPermission> of(PartnerTeamRole role) {
        return role == null ? Set.of() : MATRIX.getOrDefault(role, Set.of());
    }

    /**
     * What a grant of {@code role} carries in this release: the §10.1 bundle without MANAGER's R4 team
     * mutations. OWNER keeps every permission (team mutations are owner-only, O-2).
     */
    public static Set<PartnerPermission> effective(PartnerTeamRole role) {
        if (role != PartnerTeamRole.MANAGER) return of(role);
        EnumSet<PartnerPermission> bundle = EnumSet.copyOf(of(role));
        bundle.removeAll(DEFERRED_TO_R4);
        return Set.copyOf(bundle);
    }

    private static Set<PartnerPermission> set(PartnerPermission... permissions) {
        return Set.copyOf(EnumSet.copyOf(Arrays.asList(permissions)));
    }
}
