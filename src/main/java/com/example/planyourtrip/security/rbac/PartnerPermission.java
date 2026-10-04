package com.example.planyourtrip.security.rbac;

import java.util.Arrays;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;
import java.util.stream.Collectors;

import static com.example.planyourtrip.security.rbac.ScopeType.COMPANY;
import static com.example.planyourtrip.security.rbac.ScopeType.PROPERTY;
import static com.example.planyourtrip.security.rbac.ScopeType.UNIT;

/**
 * The 54 partner permissions of RBAC V1.1 §9.1, verbatim: identifier, key, scope floor and status.
 *
 * <p>The floor is the narrowest grant type that may satisfy the permission ({@link ScopeType#admits}).
 * {@code P54} was added in revision 1.1 and sits next to its domain; identifiers are not an ordering.
 */
public enum PartnerPermission implements Permission {

    WORKSPACE_ACCESS("P01", "partner.workspace.access", UNIT, false),
    BUSINESS_PROFILE_VIEW("P02", "partner.business_profile.view", COMPANY, false),
    BUSINESS_PROFILE_EDIT("P03", "partner.business_profile.edit", COMPANY, false),
    SETTINGS_EDIT("P04", "partner.settings.edit", COMPANY, false),
    ACTIVITY_LOG_VIEW("P05", "partner.activity_log.view", COMPANY, false),
    SECURITY_SETTINGS_MANAGE("P06", "partner.security_settings.manage", COMPANY, true),
    TEAM_VIEW("P07", "partner.team.view", PROPERTY, false),
    TEAM_INVITE("P08", "partner.team.invite", PROPERTY, false),
    TEAM_ROLE_ASSIGN("P09", "partner.team.role.assign", PROPERTY, false),
    TEAM_SUSPEND("P10", "partner.team.suspend", PROPERTY, false),
    TEAM_REMOVE("P11", "partner.team.remove", PROPERTY, false),
    TEAM_OWNER_MANAGE("P12", "partner.team.owner.manage", COMPANY, false),
    OWNERSHIP_TRANSFER("P13", "partner.ownership.transfer", COMPANY, true),
    PROPERTY_VIEW("P14", "partner.property.view", PROPERTY, false),
    PROPERTY_CREATE("P15", "partner.property.create", COMPANY, false),
    PROPERTY_CONTENT_EDIT("P16", "partner.property.content.edit", PROPERTY, false),
    PROPERTY_POLICY_EDIT("P17", "partner.property.policy.edit", PROPERTY, false),
    PROPERTY_STATUS_TOGGLE("P18", "partner.property.status.toggle", PROPERTY, false),
    PROPERTY_MEDIA_MANAGE("P19", "partner.property.media.manage", PROPERTY, true),
    PROPERTY_PUBLISH("P20", "partner.property.publish", PROPERTY, true),
    ROOM_VIEW("P21", "partner.room.view", UNIT, false),
    ROOM_CREATE("P22", "partner.room.create", PROPERTY, true),
    ROOM_CONTENT_EDIT("P23", "partner.room.content.edit", PROPERTY, false),
    ROOM_COMMERCIAL_EDIT("P24", "partner.room.commercial.edit", PROPERTY, false),
    ROOM_STATUS_TOGGLE("P25", "partner.room.status.toggle", PROPERTY, false),
    INVENTORY_VIEW("P26", "partner.inventory.view", PROPERTY, false),
    INVENTORY_ALLOTMENT_EDIT("P27", "partner.inventory.allotment.edit", PROPERTY, false),
    INVENTORY_RESTRICTION_EDIT("P28", "partner.inventory.restriction.edit", PROPERTY, false),
    RATE_VIEW("P29", "partner.rate.view", PROPERTY, false),
    RATE_EDIT("P30", "partner.rate.edit", PROPERTY, false),
    RATE_ACTIVATE("P31", "partner.rate.activate", PROPERTY, false),
    PROMOTION_VIEW("P32", "partner.promotion.view", PROPERTY, false),
    PROMOTION_MANAGE("P33", "partner.promotion.manage", PROPERTY, false),
    BOOKING_VIEW("P34", "partner.booking.view", PROPERTY, false),
    BOOKING_GUEST_CONTACT_VIEW("P35", "partner.booking.guest_contact.view", PROPERTY, false),
    BOOKING_GUEST_IDENTITY_VIEW("P54", "partner.booking.guest_identity.view", PROPERTY, false),
    BOOKING_PAYMENT_VIEW("P36", "partner.booking.payment.view", PROPERTY, false),
    BOOKING_ARRIVAL_OPERATE("P37", "partner.booking.arrival.operate", PROPERTY, false),
    BOOKING_DEPARTURE_OPERATE("P38", "partner.booking.departure.operate", PROPERTY, false),
    BOOKING_NO_SHOW_MARK("P39", "partner.booking.no_show.mark", PROPERTY, false),
    BOOKING_STAY_VIEW("P40", "partner.booking.stay.view", PROPERTY, false),
    BOOKING_MODIFY("P41", "partner.booking.modify", PROPERTY, true),
    CONVERSATION_VIEW("P42", "partner.conversation.view", PROPERTY, false),
    CONVERSATION_RESPOND("P43", "partner.conversation.respond", PROPERTY, false),
    REVIEW_VIEW("P44", "partner.review.view", PROPERTY, false),
    REVIEW_REPLY("P45", "partner.review.reply", PROPERTY, false),
    HOUSEKEEPING_VIEW("P46", "partner.housekeeping.view", UNIT, true),
    HOUSEKEEPING_UPDATE("P47", "partner.housekeeping.update", UNIT, true),
    ANALYTICS_VIEW("P48", "partner.analytics.view", PROPERTY, false),
    FINANCE_REVENUE_VIEW("P49", "partner.finance.revenue.view", PROPERTY, false),
    FINANCE_STATEMENT_VIEW("P50", "partner.finance.statement.view", COMPANY, false),
    FINANCE_PAYOUT_VIEW("P51", "partner.finance.payout.view", COMPANY, false),
    PAYOUT_ACCOUNT_VIEW("P52", "partner.payout_account.view", COMPANY, false),
    PAYOUT_ACCOUNT_MANAGE("P53", "partner.payout_account.manage", COMPANY, false);

    private static final Map<String, PartnerPermission> BY_KEY = Arrays.stream(values())
        .collect(Collectors.toUnmodifiableMap(PartnerPermission::key, Function.identity()));

    private final String id;
    private final String key;
    private final ScopeType floor;
    private final boolean reserved;

    PartnerPermission(String id, String key, ScopeType floor, boolean reserved) {
        this.id = id;
        this.key = key;
        this.floor = floor;
        this.reserved = reserved;
    }

    @Override public String id() { return id; }
    @Override public String key() { return key; }
    @Override public Namespace namespace() { return Namespace.PARTNER; }
    @Override public boolean reserved() { return reserved; }

    /** The narrowest grant type that may satisfy this permission (§4.5 {@code floor(p)}). */
    public ScopeType floor() { return floor; }

    /** The partner permission named exactly by {@code key}, or empty — never an admin permission. */
    public static Optional<PartnerPermission> fromKey(String key) {
        return key == null ? Optional.empty() : Optional.ofNullable(BY_KEY.get(key));
    }
}
