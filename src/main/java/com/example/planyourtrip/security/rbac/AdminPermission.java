package com.example.planyourtrip.security.rbac;

import java.util.Arrays;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * The 46 admin permissions of RBAC V1.1 §9.2, verbatim. Admin permissions have no scope: they are
 * platform-wide. {@code A46} was added in revision 1.1 (split from A15) and sits next to its domain.
 */
public enum AdminPermission implements Permission {

    CONSOLE_ACCESS("A01", "admin.console.access", false),
    /** RBAC R6: active — backs {@code GET/PUT /api/admin/access/admins…} (§25.4). */
    ACCESS_MANAGE("A02", "admin.access.manage", false),
    AUDIT_LOG_VIEW("A03", "admin.audit_log.view", false),
    ANALYTICS_VIEW("A04", "admin.analytics.view", false),
    CUSTOMER_VIEW("A05", "admin.customer.view", false),
    CUSTOMER_WALLET_VIEW("A06", "admin.customer.wallet.view", false),
    CUSTOMER_ACCOUNT_MANAGE("A07", "admin.customer.account.manage", true),
    PARTNER_VIEW("A08", "admin.partner.view", false),
    PARTNER_VERIFY("A09", "admin.partner.verify", false),
    PARTNER_SUSPEND("A10", "admin.partner.suspend", false),
    PARTNER_OWNERSHIP_INTERVENE("A11", "admin.partner.ownership.intervene", true),
    PARTNER_PAYOUT_MANAGE("A12", "admin.partner_payout.manage", true),
    PLACE_VIEW("A13", "admin.place.view", false),
    PLACE_EDIT("A14", "admin.place.edit", false),
    PLACE_MODERATE("A15", "admin.place.moderate", false),
    PLACE_PUBLISH("A46", "admin.place.publish", false),
    PLACE_OWNER_ASSIGN("A16", "admin.place.owner.assign", false),
    ROOM_EDIT("A17", "admin.room.edit", false),
    INVENTORY_EDIT("A18", "admin.inventory.edit", false),
    RATE_EDIT("A19", "admin.rate.edit", false),
    MEDIA_MANAGE("A20", "admin.media.manage", false),
    CATEGORY_MANAGE("A21", "admin.category.manage", false),
    AMENITY_MANAGE("A22", "admin.amenity.manage", false),
    LOCATION_MANAGE("A23", "admin.location.manage", false),
    BOOKING_VIEW("A24", "admin.booking.view", false),
    BOOKING_OPERATE("A25", "admin.booking.operate", false),
    BOOKING_OVERRIDE("A26", "admin.booking.override", false),
    BOOKING_COMPENSATE("A27", "admin.booking.compensate", false),
    CONVERSATION_VIEW("A28", "admin.conversation.view", false),
    CONVERSATION_INTERVENE("A29", "admin.conversation.intervene", false),
    PAYMENT_VIEW("A30", "admin.payment.view", false),
    PAYMENT_INTERVENE("A31", "admin.payment.intervene", false),
    INVOICE_VIEW("A32", "admin.invoice.view", false),
    INVOICE_MANAGE("A33", "admin.invoice.manage", false),
    REVIEW_VIEW("A34", "admin.review.view", false),
    REVIEW_MODERATE("A35", "admin.review.moderate", false),
    PROMOTION_MANAGE("A36", "admin.promotion.manage", false),
    COUPON_MANAGE("A37", "admin.coupon.manage", false),
    GIFT_CARD_CATALOG_MANAGE("A38", "admin.gift_card.catalog.manage", false),
    GIFT_CARD_VALUE_MANAGE("A39", "admin.gift_card.value.manage", false),
    CUSTOMER_PROGRAM_MANAGE("A40", "admin.customer_program.manage", false),
    CUSTOMER_ENTITLEMENT_ADJUST("A41", "admin.customer.entitlement.adjust", false),
    TRAVEL_CREDIT_ADJUST("A42", "admin.travel_credit.adjust", false),
    PERSONALIZATION_MANAGE("A43", "admin.personalization.manage", false),
    NOTIFICATION_BROADCAST("A44", "admin.notification.broadcast", false),
    SYSTEM_JOB_RUN("A45", "admin.system_job.run", false);

    private static final Map<String, AdminPermission> BY_KEY = Arrays.stream(values())
        .collect(Collectors.toUnmodifiableMap(AdminPermission::key, Function.identity()));

    private final String id;
    private final String key;
    private final boolean reserved;

    AdminPermission(String id, String key, boolean reserved) {
        this.id = id;
        this.key = key;
        this.reserved = reserved;
    }

    @Override public String id() { return id; }
    @Override public String key() { return key; }
    @Override public Namespace namespace() { return Namespace.ADMIN; }
    @Override public boolean reserved() { return reserved; }

    /** The admin permission named exactly by {@code key}, or empty — never a partner permission. */
    public static Optional<AdminPermission> fromKey(String key) {
        return key == null ? Optional.empty() : Optional.ofNullable(BY_KEY.get(key));
    }
}
