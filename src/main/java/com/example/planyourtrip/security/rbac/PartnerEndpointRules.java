package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.security.rbac.PartnerEndpointRule.AggregateScope;
import org.springframework.web.bind.annotation.RequestMethod;

import java.util.List;
import java.util.Set;

import static com.example.planyourtrip.security.rbac.PartnerEndpointRule.AggregateScope.COMPANY_ONLY;
import static com.example.planyourtrip.security.rbac.PartnerEndpointRule.AggregateScope.FILTERABLE_BY_PROPERTY;
import static com.example.planyourtrip.security.rbac.PartnerPermission.*;
import static org.springframework.web.bind.annotation.RequestMethod.DELETE;
import static org.springframework.web.bind.annotation.RequestMethod.GET;
import static org.springframework.web.bind.annotation.RequestMethod.PATCH;
import static org.springframework.web.bind.annotation.RequestMethod.POST;
import static org.springframework.web.bind.annotation.RequestMethod.PUT;

/**
 * The 90 partner handlers and their authorization, transcribed from RBAC V1.1 §25.1 (the source of truth).
 *
 * <p>This is the target mapping the matrix enforcement phase (R3b) applies. In R1 every handler must be
 * listed here — an unlisted handler is refused at runtime ({@link EndpointAuthorizationInterceptor}) and
 * fails the registry test — while operational endpoints keep resolving the registrant's company only.
 */
final class PartnerEndpointRules {

    private PartnerEndpointRules() {}

    private static final String FIELD_DIFF_CALENDAR =
        "P27 when an inventory count changes, P28 when a restriction flag changes (§24 B9)";
    private static final String FIELD_DIFF_ROOM =
        "P23 when a content field changes, P24 when a commercial field changes (§24 B9)";
    private static final String AFTER_APPROVAL =
        "registrant before approval; the listed permission once the company is approved";

    static final List<PartnerEndpointRule> RULES = List.of(
        // ── Analytics ───────────────────────────────────────────────────────
        aggregate(GET, "/api/partner/analytics/overview", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY).withFields(FINANCE_REVENUE_VIEW),
        aggregate(GET, "/api/partner/analytics/revenue", FINANCE_REVENUE_VIEW, FILTERABLE_BY_PROPERTY),
        aggregate(GET, "/api/partner/analytics/occupancy", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY),
        aggregate(GET, "/api/partner/analytics/bookings", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY),
        // R3b: room revenue ranking is a revenue figure (P49); review previews are individual reviews (P44, §21)
        aggregate(GET, "/api/partner/analytics/rooms", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY).withFields(FINANCE_REVENUE_VIEW),
        aggregate(GET, "/api/partner/analytics/reviews", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY).withFields(REVIEW_VIEW),
        aggregate(GET, "/api/partner/analytics/messages", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY),
        aggregate(GET, "/api/partner/analytics/promotions", ANALYTICS_VIEW, FILTERABLE_BY_PROPERTY).withFields(FINANCE_REVENUE_VIEW),

        // ── Bookings ────────────────────────────────────────────────────────
        collection(GET, "/api/partner/bookings", ResourceType.BOOKING, BOOKING_VIEW)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW, BOOKING_GUEST_CONTACT_VIEW, BOOKING_STAY_VIEW),
        resource(GET, "/api/partner/bookings/{id}", ResourceType.BOOKING, BOOKING_VIEW)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW, BOOKING_GUEST_CONTACT_VIEW, BOOKING_STAY_VIEW, BOOKING_PAYMENT_VIEW),
        resource(PATCH, "/api/partner/bookings/{id}/check-in", ResourceType.BOOKING, BOOKING_ARRIVAL_OPERATE),
        resource(PATCH, "/api/partner/bookings/{id}/check-out", ResourceType.BOOKING, BOOKING_DEPARTURE_OPERATE),
        resource(PATCH, "/api/partner/bookings/{id}/complete", ResourceType.BOOKING, BOOKING_DEPARTURE_OPERATE),
        resource(PATCH, "/api/partner/bookings/{id}/no-show", ResourceType.BOOKING, BOOKING_NO_SHOW_MARK),
        collection(GET, "/api/partner/dashboard", ResourceType.BOOKING, BOOKING_VIEW)
            .withFields(FINANCE_REVENUE_VIEW).withAggregate(FILTERABLE_BY_PROPERTY),
        resource(POST, "/api/partner/bookings/voucher/verify", ResourceType.BOOKING, BOOKING_ARRIVAL_OPERATE)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW),
        resource(POST, "/api/partner/bookings/check-in", ResourceType.BOOKING, BOOKING_ARRIVAL_OPERATE)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW),
        resource(POST, "/api/partner/bookings/check-out", ResourceType.BOOKING, BOOKING_DEPARTURE_OPERATE)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW),

        // ── Calendar ────────────────────────────────────────────────────────
        resource(GET, "/api/partner/calendar/rooms/{roomId}", ResourceType.CALENDAR, INVENTORY_VIEW),
        resource(PUT, "/api/partner/calendar/rooms/{roomId}/{date}", ResourceType.CALENDAR, INVENTORY_ALLOTMENT_EDIT)
            .when(FIELD_DIFF_CALENDAR, INVENTORY_RESTRICTION_EDIT),
        resource(POST, "/api/partner/calendar/rooms/{roomId}/bulk", ResourceType.CALENDAR, INVENTORY_ALLOTMENT_EDIT)
            .when(FIELD_DIFF_CALENDAR, INVENTORY_RESTRICTION_EDIT),
        resource(PATCH, "/api/partner/calendar/rooms/{roomId}/{date}/stop-sell", ResourceType.CALENDAR, INVENTORY_RESTRICTION_EDIT),
        resource(PATCH, "/api/partner/calendar/rooms/{roomId}/{date}/closed-arrival", ResourceType.CALENDAR, INVENTORY_RESTRICTION_EDIT),
        resource(PATCH, "/api/partner/calendar/rooms/{roomId}/{date}/closed-departure", ResourceType.CALENDAR, INVENTORY_RESTRICTION_EDIT),
        resource(PUT, "/api/partner/calendar/rooms/{roomId}/price", ResourceType.RATE_PLAN, RATE_EDIT),
        resource(GET, "/api/partner/calendar/rooms/{roomId}/price", ResourceType.RATE_PLAN, RATE_VIEW),

        // ── Conversations ───────────────────────────────────────────────────
        collection(GET, "/api/partner/conversations", ResourceType.CONVERSATION, CONVERSATION_VIEW)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW),
        resource(GET, "/api/partner/conversations/{id}", ResourceType.CONVERSATION, CONVERSATION_VIEW)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW),
        resource(POST, "/api/partner/conversations/{id}/messages", ResourceType.CONVERSATION, CONVERSATION_RESPOND),
        resource(PATCH, "/api/partner/conversations/{id}/read", ResourceType.CONVERSATION, CONVERSATION_RESPOND),
        resource(PATCH, "/api/partner/conversations/{id}/close", ResourceType.CONVERSATION, CONVERSATION_RESPOND),

        // ── Extranet ────────────────────────────────────────────────────────
        // R3b: "each block needs its permission" (§25.1) — the gates PartnerExtranetService applies
        company(GET, "/api/partner/extranet/home", WORKSPACE_ACCESS)
            .withFields(FINANCE_REVENUE_VIEW, PROPERTY_VIEW, ROOM_VIEW, BOOKING_VIEW, ANALYTICS_VIEW, BUSINESS_PROFILE_VIEW)
            .withAggregate(FILTERABLE_BY_PROPERTY),
        company(GET, "/api/partner/extranet/menu", WORKSPACE_ACCESS),
        company(GET, "/api/partner/extranet/account-summary", WORKSPACE_ACCESS)
            .withFields(PAYOUT_ACCOUNT_VIEW, TEAM_VIEW, BUSINESS_PROFILE_VIEW).withAggregate(COMPANY_ONLY),
        company(GET, "/api/partner/extranet/activity-logs", ACTIVITY_LOG_VIEW).withAggregate(COMPANY_ONLY),

        // ── Finance ─────────────────────────────────────────────────────────
        aggregate(GET, "/api/partner/finance/overview", FINANCE_REVENUE_VIEW, FILTERABLE_BY_PROPERTY),
        aggregate(GET, "/api/partner/finance/revenue", FINANCE_REVENUE_VIEW, FILTERABLE_BY_PROPERTY),
        company(GET, "/api/partner/finance/settlements", FINANCE_STATEMENT_VIEW).withAggregate(COMPANY_ONLY),
        company(GET, "/api/partner/finance/commissions", FINANCE_STATEMENT_VIEW).withAggregate(COMPANY_ONLY),
        company(GET, "/api/partner/finance/invoices", FINANCE_STATEMENT_VIEW).withAggregate(COMPANY_ONLY),
        company(GET, "/api/partner/finance/refunds", FINANCE_STATEMENT_VIEW).withAggregate(COMPANY_ONLY),
        company(GET, "/api/partner/finance/payouts", FINANCE_PAYOUT_VIEW).withAggregate(COMPANY_ONLY),

        // ── Properties ──────────────────────────────────────────────────────
        collection(GET, "/api/partner/hotels", ResourceType.PROPERTY, PROPERTY_VIEW),
        company(POST, "/api/partner/hotels", PROPERTY_CREATE),
        resource(GET, "/api/partner/hotels/{id}", ResourceType.PROPERTY, PROPERTY_VIEW),
        resource(PUT, "/api/partner/hotels/{id}", ResourceType.PROPERTY, PROPERTY_CONTENT_EDIT),
        resource(PUT, "/api/partner/hotels/{id}/contact", ResourceType.PROPERTY, PROPERTY_CONTENT_EDIT),
        resource(PUT, "/api/partner/hotels/{id}/location", ResourceType.PROPERTY, PROPERTY_CONTENT_EDIT),
        resource(PUT, "/api/partner/hotels/{id}/amenities", ResourceType.PROPERTY, PROPERTY_CONTENT_EDIT),
        resource(PUT, "/api/partner/hotels/{id}/policies", ResourceType.PROPERTY, PROPERTY_POLICY_EDIT),
        resource(PATCH, "/api/partner/hotels/{id}/activate", ResourceType.PROPERTY, PROPERTY_STATUS_TOGGLE),
        resource(PATCH, "/api/partner/hotels/{id}/deactivate", ResourceType.PROPERTY, PROPERTY_STATUS_TOGGLE),

        // ── Place review analytics (one property, not a company report) ─────
        resource(GET, "/api/partner/places/{placeId}/reviews/analytics", ResourceType.REVIEW, REVIEW_VIEW),

        // ── Pricing ─────────────────────────────────────────────────────────
        resource(GET, "/api/partner/rooms/{roomId}/rate-plans", ResourceType.RATE_PLAN, RATE_VIEW),
        resource(GET, "/api/partner/rooms/{roomId}/pricing-preview", ResourceType.RATE_PLAN, RATE_VIEW),
        resource(GET, "/api/partner/rate-plans/{id}/occupancy-prices", ResourceType.RATE_PLAN, RATE_VIEW),
        resource(GET, "/api/partner/rate-plans/{id}/preview", ResourceType.RATE_PLAN, RATE_VIEW),
        resource(POST, "/api/partner/rate-plans/{id}/validate", ResourceType.RATE_PLAN, RATE_VIEW),
        resource(POST, "/api/partner/rooms/{roomId}/rate-plans", ResourceType.RATE_PLAN, RATE_EDIT),
        resource(PUT, "/api/partner/rate-plans/{id}", ResourceType.RATE_PLAN, RATE_EDIT),
        resource(DELETE, "/api/partner/rate-plans/{id}", ResourceType.RATE_PLAN, RATE_EDIT),
        resource(POST, "/api/partner/rate-plans/{id}/duplicate", ResourceType.RATE_PLAN, RATE_EDIT),
        resource(POST, "/api/partner/rate-plans/{id}/occupancy-prices", ResourceType.RATE_PLAN, RATE_EDIT),
        resource(PUT, "/api/partner/rate-plan-occupancy-prices/{id}", ResourceType.OCCUPANCY_PRICE, RATE_EDIT),
        resource(DELETE, "/api/partner/rate-plan-occupancy-prices/{id}", ResourceType.OCCUPANCY_PRICE, RATE_EDIT),
        resource(POST, "/api/partner/rate-plans/{id}/activate", ResourceType.RATE_PLAN, RATE_ACTIVATE),
        resource(POST, "/api/partner/rate-plans/{id}/deactivate", ResourceType.RATE_PLAN, RATE_ACTIVATE),

        // ── Onboarding and self (outside the workspace evaluator) ───────────
        new PartnerEndpointRule(GET, "/api/partner/me/access", EndpointKind.SELF, null, List.of(WORKSPACE_ACCESS),
            "SELF (§25.2): not gated by P01, approval or membership status; permissions listed only when they apply",
            Set.of(), AggregateScope.NONE, false),
        self(POST, "/api/partner/profile", BUSINESS_PROFILE_EDIT),
        self(POST, "/api/partner/profile/submit", BUSINESS_PROFILE_EDIT),
        self(GET, "/api/partner/profile", BUSINESS_PROFILE_VIEW),

        // ── Promotions ──────────────────────────────────────────────────────
        collection(GET, "/api/partner/promotions", ResourceType.PROMOTION, PROMOTION_VIEW),
        resource(GET, "/api/partner/promotions/{id}", ResourceType.PROMOTION, PROMOTION_VIEW),
        resource(POST, "/api/partner/promotions", ResourceType.PROMOTION, PROMOTION_MANAGE),
        resource(PUT, "/api/partner/promotions/{id}", ResourceType.PROMOTION, PROMOTION_MANAGE),
        resource(DELETE, "/api/partner/promotions/{id}", ResourceType.PROMOTION, PROMOTION_MANAGE),

        // ── Reviews ─────────────────────────────────────────────────────────
        resource(PUT, "/api/partner/reviews/{reviewId}/reply", ResourceType.REVIEW, REVIEW_REPLY),

        // ── Rooms ───────────────────────────────────────────────────────────
        collection(GET, "/api/partner/rooms", ResourceType.ROOM, ROOM_VIEW),
        resource(GET, "/api/partner/rooms/{roomId}", ResourceType.ROOM, ROOM_VIEW),
        resource(PUT, "/api/partner/rooms/{roomId}", ResourceType.ROOM, ROOM_CONTENT_EDIT)
            .when(FIELD_DIFF_ROOM, ROOM_COMMERCIAL_EDIT),
        resource(PATCH, "/api/partner/rooms/{roomId}/activate", ResourceType.ROOM, ROOM_STATUS_TOGGLE),
        resource(PATCH, "/api/partner/rooms/{roomId}/deactivate", ResourceType.ROOM, ROOM_STATUS_TOGGLE),

        // ── Settings, payout account, team ──────────────────────────────────
        company(GET, "/api/partner/settings", WORKSPACE_ACCESS),
        company(PUT, "/api/partner/settings", SETTINGS_EDIT),
        company(GET, "/api/partner/payout-account", PAYOUT_ACCOUNT_VIEW),
        company(PUT, "/api/partner/payout-account", PAYOUT_ACCOUNT_MANAGE).withStepUp(),
        collection(GET, "/api/partner/team", ResourceType.MEMBERSHIP, TEAM_VIEW),
        company(POST, "/api/partner/team", TEAM_INVITE)
            .when("P12 and step-up when the role is OWNER", TEAM_OWNER_MANAGE),
        resource(PATCH, "/api/partner/team/{id}", ResourceType.MEMBERSHIP, TEAM_ROLE_ASSIGN)
            .when("P09 for a role change, P10 for an active change, P12 and step-up when OWNER is involved",
                TEAM_SUSPEND, TEAM_OWNER_MANAGE),
        resource(DELETE, "/api/partner/team/{id}", ResourceType.MEMBERSHIP, TEAM_REMOVE)
            .when("P12 and step-up when the member holds OWNER", TEAM_OWNER_MANAGE),
        // RBAC R3a (§25.3): grants, suspend/reactivate, leave
        resource(PUT, "/api/partner/team/{id}/grants", ResourceType.MEMBERSHIP, TEAM_ROLE_ASSIGN)
            .when("P12 and step-up when an OWNER grant is added, confirmed or removed", TEAM_OWNER_MANAGE),
        resource(POST, "/api/partner/team/{id}/suspend", ResourceType.MEMBERSHIP, TEAM_SUSPEND)
            .when("P12 and step-up when the member holds OWNER", TEAM_OWNER_MANAGE),
        resource(POST, "/api/partner/team/{id}/reactivate", ResourceType.MEMBERSHIP, TEAM_SUSPEND)
            .when("P12 and step-up when the member holds OWNER", TEAM_OWNER_MANAGE),
        new PartnerEndpointRule(POST, "/api/partner/team/leave", EndpointKind.SELF, null, List.of(WORKSPACE_ACCESS),
            "SELF on the caller's own membership in any state but REVOKED; P01 is not required, so a suspended "
                + "member can leave; refused for the primary owner and the last owner", Set.of(),
            AggregateScope.NONE, false),

        // ── Stays ───────────────────────────────────────────────────────────
        resource(GET, "/api/partner/stays/{bookingId}", ResourceType.BOOKING, BOOKING_STAY_VIEW)
            .withFields(BOOKING_GUEST_IDENTITY_VIEW)
    );

    private static PartnerEndpointRule resource(RequestMethod method, String pattern, ResourceType type,
                                                PartnerPermission permission) {
        return rule(method, pattern, EndpointKind.RESOURCE, type, permission, AggregateScope.NONE);
    }

    private static PartnerEndpointRule collection(RequestMethod method, String pattern, ResourceType type,
                                                  PartnerPermission permission) {
        return rule(method, pattern, EndpointKind.COLLECTION, type, permission, AggregateScope.NONE);
    }

    private static PartnerEndpointRule aggregate(RequestMethod method, String pattern, PartnerPermission permission,
                                                 AggregateScope scope) {
        return rule(method, pattern, EndpointKind.COLLECTION, null, permission, scope);
    }

    private static PartnerEndpointRule company(RequestMethod method, String pattern, PartnerPermission permission) {
        return rule(method, pattern, EndpointKind.COMPANY, null, permission, AggregateScope.NONE);
    }

    private static PartnerEndpointRule self(RequestMethod method, String pattern, PartnerPermission afterApproval) {
        return new PartnerEndpointRule(method, pattern, EndpointKind.SELF, null, List.of(afterApproval),
            AFTER_APPROVAL, Set.of(), AggregateScope.NONE, false);
    }

    private static PartnerEndpointRule rule(RequestMethod method, String pattern, EndpointKind kind,
                                            ResourceType type, PartnerPermission permission, AggregateScope scope) {
        return new PartnerEndpointRule(method, pattern, kind, type, List.of(permission), null, Set.of(), scope, false);
    }
}
