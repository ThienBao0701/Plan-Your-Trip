package com.example.planyourtrip.security.rbac;

import java.util.Arrays;
import java.util.Collection;
import java.util.EnumSet;
import java.util.Optional;
import java.util.Set;

import static com.example.planyourtrip.security.rbac.AdminPermission.*;

/**
 * RBAC R6 — the 11 admin profiles of RBAC V1.1 §7 and their permission bundles, transcribed from the
 * role → permission matrix of §10.2 (the source of truth). An administrator may hold several profiles; the
 * effective permissions are the union (§7). Admin permissions are platform-wide: a profile has no scope.
 *
 * <p>Reserved permissions (A07, A11, A12) stay in the bundles exactly as the matrix lists them; they grant
 * nothing until their endpoints exist, because no registered handler maps to them.
 */
public enum AdminProfile {

    /** Ultimate platform authority: every admin permission (§10.2 column PO, 46). */
    PLATFORM_OWNER(EnumSet.allOf(AdminPermission.class)),

    /** Partner onboarding and supply operations (§10.2 column PT, 9). */
    PARTNER_OPERATIONS(EnumSet.of(CONSOLE_ACCESS, PARTNER_VIEW, PARTNER_VERIFY, PARTNER_SUSPEND,
        PARTNER_OWNERSHIP_INTERVENE, PLACE_VIEW, INVENTORY_EDIT, RATE_EDIT, BOOKING_VIEW)),

    /** Listing quality and taxonomy (§10.2 column CC, 10). */
    CONTENT_CATALOGUE(EnumSet.of(CONSOLE_ACCESS, PLACE_VIEW, PLACE_EDIT, PLACE_MODERATE, PLACE_PUBLISH,
        ROOM_EDIT, MEDIA_MANAGE, CATEGORY_MANAGE, AMENITY_MANAGE, PERSONALIZATION_MANAGE)),

    /** Customer and booking support (§10.2 column BS, 11). */
    BOOKING_SUPPORT(EnumSet.of(CONSOLE_ACCESS, CUSTOMER_VIEW, CUSTOMER_WALLET_VIEW, PLACE_VIEW, BOOKING_VIEW,
        BOOKING_OPERATE, BOOKING_OVERRIDE, CONVERSATION_VIEW, CONVERSATION_INTERVENE, PAYMENT_VIEW, INVOICE_VIEW)),

    /** Money movement and stored value (§10.2 column FO, 14). */
    FINANCE_OPERATIONS(EnumSet.of(CONSOLE_ACCESS, ANALYTICS_VIEW, CUSTOMER_VIEW, PARTNER_VIEW,
        PARTNER_PAYOUT_MANAGE, BOOKING_VIEW, BOOKING_COMPENSATE, PAYMENT_VIEW, PAYMENT_INTERVENE, INVOICE_VIEW,
        INVOICE_MANAGE, GIFT_CARD_VALUE_MANAGE, CUSTOMER_ENTITLEMENT_ADJUST, TRAVEL_CREDIT_ADJUST)),

    /** Discount and loyalty programme design (§10.2 column GM, 8; §31 Q11). */
    GROWTH_MARKETING(EnumSet.of(CONSOLE_ACCESS, ANALYTICS_VIEW, PLACE_VIEW, PROMOTION_MANAGE, COUPON_MANAGE,
        GIFT_CARD_CATALOG_MANAGE, CUSTOMER_PROGRAM_MANAGE, PERSONALIZATION_MANAGE)),

    /** Abuse, fraud and policy enforcement (§10.2 column TS, 14). */
    TRUST_SAFETY(EnumSet.of(CONSOLE_ACCESS, AUDIT_LOG_VIEW, CUSTOMER_VIEW, CUSTOMER_WALLET_VIEW,
        CUSTOMER_ACCOUNT_MANAGE, PARTNER_VIEW, PARTNER_SUSPEND, PLACE_VIEW, PLACE_MODERATE, BOOKING_VIEW,
        CONVERSATION_VIEW, CONVERSATION_INTERVENE, REVIEW_VIEW, REVIEW_MODERATE)),

    /** The review queue (§10.2 column RM, 4). */
    REVIEW_MODERATION(EnumSet.of(CONSOLE_ACCESS, PLACE_VIEW, REVIEW_VIEW, REVIEW_MODERATE)),

    /** Aggregate reporting only — no row-level data, no PII, no write (§10.2 column AN, 2; §31 Q14). */
    ANALYTICS(EnumSet.of(CONSOLE_ACCESS, ANALYTICS_VIEW)),

    /** The administrative-unit hierarchy (§10.2 column LC, 3). */
    LOCATION_CATALOGUE(EnumSet.of(CONSOLE_ACCESS, PLACE_VIEW, LOCATION_MANAGE)),

    /** Incident diagnosis and scheduled-job recovery; guest identity masked (§10.2 column TE, 6). */
    TECH_SUPPORT(EnumSet.of(CONSOLE_ACCESS, AUDIT_LOG_VIEW, PLACE_VIEW, BOOKING_VIEW, PAYMENT_VIEW,
        SYSTEM_JOB_RUN));

    /** The SQL Server / H2 CHECK on {@code admin_profile_assignments.profile}: exactly these 11 values. */
    public static final String CHECK = "profile in ('PLATFORM_OWNER','PARTNER_OPERATIONS','CONTENT_CATALOGUE',"
        + "'BOOKING_SUPPORT','FINANCE_OPERATIONS','GROWTH_MARKETING','TRUST_SAFETY','REVIEW_MODERATION',"
        + "'ANALYTICS','LOCATION_CATALOGUE','TECH_SUPPORT')";

    private final Set<AdminPermission> permissions;

    AdminProfile(Set<AdminPermission> permissions) {
        this.permissions = Set.copyOf(permissions);
    }

    public Set<AdminPermission> permissions() {
        return permissions;
    }

    /** The union of the bundles of {@code profiles}; empty for none (deny by default). */
    public static Set<AdminPermission> permissionsOf(Collection<AdminProfile> profiles) {
        EnumSet<AdminPermission> union = EnumSet.noneOf(AdminPermission.class);
        if (profiles != null) profiles.forEach(p -> union.addAll(p.permissions));
        return Set.copyOf(union);
    }

    /** The profile named exactly {@code name}, or empty — an unknown value grants nothing. */
    public static Optional<AdminProfile> fromName(String name) {
        if (name == null) return Optional.empty();
        return Arrays.stream(values()).filter(p -> p.name().equals(name)).findFirst();
    }
}
