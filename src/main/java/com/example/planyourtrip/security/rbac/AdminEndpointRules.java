package com.example.planyourtrip.security.rbac;

import org.springframework.web.bind.annotation.RequestMethod;

import java.util.List;

import static com.example.planyourtrip.security.rbac.AdminPermission.*;
import static org.springframework.web.bind.annotation.RequestMethod.DELETE;
import static org.springframework.web.bind.annotation.RequestMethod.GET;
import static org.springframework.web.bind.annotation.RequestMethod.PATCH;
import static org.springframework.web.bind.annotation.RequestMethod.POST;
import static org.springframework.web.bind.annotation.RequestMethod.PUT;

/**
 * The 189 admin handlers (181 + 3 access endpoints + 5 dual-control endpoints in RBAC R6) and their admin permission, transcribed from the "Backing endpoints" column of
 * RBAC V1.1 §9.2 (the source of truth), grouped by controller.
 *
 * <p>RBAC R6: an administrator holds the union of their admin profiles' bundles ({@code AdminAccessService}); the
 * M-5 backfill made every existing {@code ADMIN} a {@code PLATFORM_OWNER}, so enforcing this map changed nothing
 * for them until profiles are narrowed. Any admin handler that is not listed is refused.
 */
final class AdminEndpointRules {

    private AdminEndpointRules() {}

    private static final String PUBLISH_OR_MODERATE =
        "A46 when the requested status is PUBLISHED, A15 for every other status";

    static final List<AdminEndpointRule> RULES = List.of(
        // RBAC R6 — admin access (§25.4): the caller's own access document, and access management (AP-1)
        rule(GET, "/api/admin/me/access", CONSOLE_ACCESS),
        rule(GET, "/api/admin/access/admins", ACCESS_MANAGE),
        new AdminEndpointRule(PUT, "/api/admin/access/admins/{userId}/profiles", List.of(ACCESS_MANAGE),
            null, true, false),
        // RBAC R6 — dual control for A16 (§22.6): the queue and its decisions; approving needs a fresh session
        rule(GET, "/api/admin/dual-control/requests", PLACE_OWNER_ASSIGN),
        rule(GET, "/api/admin/dual-control/requests/{id}", PLACE_OWNER_ASSIGN),
        new AdminEndpointRule(POST, "/api/admin/dual-control/requests/{id}/approve", List.of(PLACE_OWNER_ASSIGN),
            null, true, false),
        rule(POST, "/api/admin/dual-control/requests/{id}/reject", PLACE_OWNER_ASSIGN),
        rule(POST, "/api/admin/dual-control/requests/{id}/cancel", PLACE_OWNER_ASSIGN),
        // Activity log
        rule(GET, "/api/admin/activity-logs", AUDIT_LOG_VIEW),
        // Amenities
        rule(GET, "/api/admin/amenities", CONSOLE_ACCESS),
        rule(POST, "/api/admin/amenities", AMENITY_MANAGE),
        rule(PUT, "/api/admin/amenities/{id}", AMENITY_MANAGE),
        rule(PATCH, "/api/admin/amenities/{id}/status", AMENITY_MANAGE),
        // Analytics
        rule(GET, "/api/admin/analytics/overview", ANALYTICS_VIEW),
        // Bookings
        rule(GET, "/api/admin/bookings", BOOKING_VIEW),
        rule(GET, "/api/admin/bookings/{id}", BOOKING_VIEW),
        rule(GET, "/api/admin/bookings/{id}/timeline", BOOKING_VIEW),
        rule(PATCH, "/api/admin/bookings/{id}/status", BOOKING_OVERRIDE),
        rule(PATCH, "/api/admin/bookings/{id}/check-in", BOOKING_OPERATE),
        rule(PATCH, "/api/admin/bookings/{id}/check-out", BOOKING_OPERATE),
        rule(PATCH, "/api/admin/bookings/{id}/complete", BOOKING_OPERATE),
        rule(PATCH, "/api/admin/bookings/{id}/archive", BOOKING_OVERRIDE),
        rule(POST, "/api/admin/bookings/{id}/refund-to-credits", BOOKING_COMPENSATE),
        // Categories
        rule(GET, "/api/admin/categories", CONSOLE_ACCESS),
        rule(POST, "/api/admin/categories", CATEGORY_MANAGE),
        rule(PUT, "/api/admin/categories/{id}", CATEGORY_MANAGE),
        rule(PATCH, "/api/admin/categories/{id}/status", CATEGORY_MANAGE),
        // Conversations
        readAudited(GET, "/api/admin/conversations", CONVERSATION_VIEW),
        readAudited(GET, "/api/admin/conversations/{id}", CONVERSATION_VIEW),
        rule(POST, "/api/admin/conversations/{id}/messages", CONVERSATION_INTERVENE),
        rule(PATCH, "/api/admin/conversations/{id}/archive", CONVERSATION_INTERVENE),
        // Coupon definitions
        rule(GET, "/api/admin/coupon-definitions", COUPON_MANAGE),
        rule(POST, "/api/admin/coupon-definitions", COUPON_MANAGE),
        rule(GET, "/api/admin/coupon-definitions/{id}", COUPON_MANAGE),
        rule(PUT, "/api/admin/coupon-definitions/{id}", COUPON_MANAGE),
        rule(PATCH, "/api/admin/coupon-definitions/{id}/activate", COUPON_MANAGE),
        rule(PATCH, "/api/admin/coupon-definitions/{id}/deactivate", COUPON_MANAGE),
        rule(GET, "/api/admin/coupon-definitions/{id}/eligibility-preview", COUPON_MANAGE),
        // Travel credit expiration
        rule(POST, "/api/admin/travel-credits/process-expirations", SYSTEM_JOB_RUN),
        // Customer coupons
        rule(GET, "/api/admin/users/{userId}/coupons", CUSTOMER_VIEW),
        rule(POST, "/api/admin/users/{userId}/coupons/{couponId}/revoke", CUSTOMER_ENTITLEMENT_ADJUST),
        // Customer profile
        rule(GET, "/api/admin/users/{id}/profile", CUSTOMER_VIEW),
        // Gift cards
        rule(GET, "/api/admin/gift-cards", GIFT_CARD_VALUE_MANAGE),
        rule(GET, "/api/admin/gift-cards/{id}", GIFT_CARD_VALUE_MANAGE),
        rule(POST, "/api/admin/gift-cards/issue", GIFT_CARD_VALUE_MANAGE),
        rule(POST, "/api/admin/gift-cards/{id}/activate", GIFT_CARD_VALUE_MANAGE),
        rule(POST, "/api/admin/gift-cards/{id}/cancel", GIFT_CARD_VALUE_MANAGE),
        rule(POST, "/api/admin/gift-cards/{id}/adjust", GIFT_CARD_VALUE_MANAGE),
        rule(GET, "/api/admin/gift-cards/{id}/transactions", GIFT_CARD_VALUE_MANAGE),
        rule(POST, "/api/admin/gift-cards/process-expirations", SYSTEM_JOB_RUN),
        // Gift-card products
        rule(GET, "/api/admin/gift-card-products", GIFT_CARD_CATALOG_MANAGE),
        rule(GET, "/api/admin/gift-card-products/{id}", GIFT_CARD_CATALOG_MANAGE),
        rule(POST, "/api/admin/gift-card-products", GIFT_CARD_CATALOG_MANAGE),
        rule(PUT, "/api/admin/gift-card-products/{id}", GIFT_CARD_CATALOG_MANAGE),
        rule(PATCH, "/api/admin/gift-card-products/{id}/activate", GIFT_CARD_CATALOG_MANAGE),
        rule(PATCH, "/api/admin/gift-card-products/{id}/deactivate", GIFT_CARD_CATALOG_MANAGE),
        rule(DELETE, "/api/admin/gift-card-products/{id}", GIFT_CARD_CATALOG_MANAGE),
        // Hotels
        rule(GET, "/api/admin/hotels/{placeId}", PLACE_VIEW),
        rule(POST, "/api/admin/hotels", PLACE_EDIT),
        rule(PUT, "/api/admin/hotels/{placeId}", PLACE_EDIT),
        rule(GET, "/api/admin/hotels/{placeId}/experience", PLACE_VIEW),
        rule(PUT, "/api/admin/hotels/{placeId}/experience", PLACE_EDIT),
        new AdminEndpointRule(POST, "/api/admin/hotels/{hotelId}/assign-owner", List.of(PLACE_OWNER_ASSIGN),
            null, true, false),
        // Inventory
        rule(GET, "/api/admin/rooms/{roomId}/inventory", PLACE_VIEW),
        rule(POST, "/api/admin/rooms/{roomId}/inventory", INVENTORY_EDIT),
        rule(PUT, "/api/admin/rooms/{roomId}/inventory/{date}", INVENTORY_EDIT),
        rule(POST, "/api/admin/rooms/{roomId}/inventory/bulk", INVENTORY_EDIT),
        // Inventory reservations
        rule(GET, "/api/admin/inventory-reservations", BOOKING_VIEW),
        rule(GET, "/api/admin/inventory-reservations/booking/{bookingId}", BOOKING_VIEW),
        rule(POST, "/api/admin/inventory-reservations/process-expirations", SYSTEM_JOB_RUN),
        // Invoices
        rule(GET, "/api/admin/invoices", INVOICE_VIEW),
        rule(GET, "/api/admin/invoices/{id}", INVOICE_VIEW),
        rule(PATCH, "/api/admin/invoices/{id}/status", INVOICE_MANAGE),
        rule(PATCH, "/api/admin/invoices/{id}/cancel", INVOICE_MANAGE),
        // Locations
        rule(GET, "/api/admin/locations", CONSOLE_ACCESS),
        rule(POST, "/api/admin/locations", LOCATION_MANAGE),
        rule(PUT, "/api/admin/locations/{id}", LOCATION_MANAGE),
        rule(PATCH, "/api/admin/locations/{id}/status", LOCATION_MANAGE),
        // Loyalty
        rule(GET, "/api/admin/users/{userId}/loyalty", CUSTOMER_VIEW),
        rule(POST, "/api/admin/users/{userId}/loyalty/grant", CUSTOMER_ENTITLEMENT_ADJUST),
        // Loyalty redemption policies and redemptions
        rule(GET, "/api/admin/loyalty/redemption-policies", CUSTOMER_PROGRAM_MANAGE),
        rule(GET, "/api/admin/loyalty/redemption-policies/{id}", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/loyalty/redemption-policies", CUSTOMER_PROGRAM_MANAGE),
        rule(PUT, "/api/admin/loyalty/redemption-policies/{id}", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/loyalty/redemption-policies/{id}/activate", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/loyalty/redemption-policies/{id}/deactivate", CUSTOMER_PROGRAM_MANAGE),
        rule(GET, "/api/admin/loyalty/redemptions", CUSTOMER_VIEW),
        rule(GET, "/api/admin/loyalty/redemptions/{redemptionReference}", CUSTOMER_VIEW),
        rule(POST, "/api/admin/loyalty/redemptions/{redemptionReference}/release", CUSTOMER_ENTITLEMENT_ADJUST),
        rule(POST, "/api/admin/loyalty/redemptions/{redemptionReference}/refund", CUSTOMER_ENTITLEMENT_ADJUST),
        rule(POST, "/api/admin/loyalty/redemptions/expire-stale", SYSTEM_JOB_RUN),
        // Media
        rule(GET, "/api/admin/places/{placeId}/media", PLACE_VIEW),
        rule(POST, "/api/admin/media", MEDIA_MANAGE),
        rule(PUT, "/api/admin/media/{id}", MEDIA_MANAGE),
        rule(PATCH, "/api/admin/media/{id}/deactivate", MEDIA_MANAGE),
        rule(PATCH, "/api/admin/media/cover", MEDIA_MANAGE),
        rule(PATCH, "/api/admin/media/reorder", MEDIA_MANAGE),
        // Membership tiers, benefits and assignments
        rule(GET, "/api/admin/membership/tiers", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/membership/tiers", CUSTOMER_PROGRAM_MANAGE),
        rule(GET, "/api/admin/membership/tiers/{tier}", CUSTOMER_PROGRAM_MANAGE),
        rule(PUT, "/api/admin/membership/tiers/{tier}", CUSTOMER_PROGRAM_MANAGE),
        rule(PATCH, "/api/admin/membership/tiers/{tier}/activate", CUSTOMER_PROGRAM_MANAGE),
        rule(PATCH, "/api/admin/membership/tiers/{tier}/deactivate", CUSTOMER_PROGRAM_MANAGE),
        rule(GET, "/api/admin/membership/benefits", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/membership/benefits", CUSTOMER_PROGRAM_MANAGE),
        rule(PUT, "/api/admin/membership/benefits/{id}", CUSTOMER_PROGRAM_MANAGE),
        rule(DELETE, "/api/admin/membership/benefits/{id}", CUSTOMER_PROGRAM_MANAGE),
        rule(GET, "/api/admin/users/{userId}/membership", CUSTOMER_VIEW),
        rule(POST, "/api/admin/users/{userId}/membership/assign", CUSTOMER_ENTITLEMENT_ADJUST),
        rule(POST, "/api/admin/users/{userId}/membership/reevaluate", CUSTOMER_ENTITLEMENT_ADJUST),
        rule(POST, "/api/admin/users/{userId}/membership/clear-manual-assignment", CUSTOMER_ENTITLEMENT_ADJUST),
        // Notifications
        rule(POST, "/api/admin/notifications/broadcast", NOTIFICATION_BROADCAST),
        rule(GET, "/api/admin/notifications", NOTIFICATION_BROADCAST),
        // Partners
        rule(GET, "/api/admin/partners", PARTNER_VIEW),
        rule(GET, "/api/admin/partners/{id}", PARTNER_VIEW),
        rule(POST, "/api/admin/partners/{id}/approve", PARTNER_VERIFY),
        rule(POST, "/api/admin/partners/{id}/reject", PARTNER_VERIFY),
        rule(POST, "/api/admin/partners/{id}/suspend", PARTNER_SUSPEND),
        rule(GET, "/api/admin/partners/{id}/detail", PARTNER_VIEW),
        rule(GET, "/api/admin/partners/{id}/team", PARTNER_VIEW),
        rule(GET, "/api/admin/partners/{id}/settings", PARTNER_VIEW),
        rule(GET, "/api/admin/partners/{id}/activity-logs", PARTNER_VIEW),
        // Payments
        rule(GET, "/api/admin/payments", PAYMENT_VIEW),
        rule(GET, "/api/admin/payments/{id}", PAYMENT_VIEW),
        rule(POST, "/api/admin/payments/{id}/refund", PAYMENT_INTERVENE),
        // Payment sessions
        rule(GET, "/api/admin/payment-sessions", PAYMENT_VIEW),
        rule(GET, "/api/admin/payment-sessions/{sessionId}", PAYMENT_VIEW),
        rule(GET, "/api/admin/payment-sessions/{sessionId}/events", PAYMENT_VIEW),
        rule(POST, "/api/admin/payment-sessions/{sessionId}/expire", PAYMENT_INTERVENE),
        rule(POST, "/api/admin/payment-sessions/process-expirations", SYSTEM_JOB_RUN),
        // Personalization rules
        rule(GET, "/api/admin/personalization-rules", PERSONALIZATION_MANAGE),
        rule(GET, "/api/admin/personalization-rules/{id}", PERSONALIZATION_MANAGE),
        rule(POST, "/api/admin/personalization-rules", PERSONALIZATION_MANAGE),
        rule(PUT, "/api/admin/personalization-rules/{id}", PERSONALIZATION_MANAGE),
        rule(PATCH, "/api/admin/personalization-rules/{id}/activate", PERSONALIZATION_MANAGE),
        rule(PATCH, "/api/admin/personalization-rules/{id}/deactivate", PERSONALIZATION_MANAGE),
        rule(DELETE, "/api/admin/personalization-rules/{id}", PERSONALIZATION_MANAGE),
        // Places
        rule(GET, "/api/admin/places", PLACE_VIEW),
        rule(GET, "/api/admin/places/{id}", PLACE_VIEW),
        rule(POST, "/api/admin/places", PLACE_EDIT),
        rule(PUT, "/api/admin/places/{id}", PLACE_EDIT),
        new AdminEndpointRule(PATCH, "/api/admin/places/{id}/status", List.of(PLACE_MODERATE, PLACE_PUBLISH),
            PUBLISH_OR_MODERATE, false, false),
        rule(PATCH, "/api/admin/places/{id}/featured", PLACE_PUBLISH),
        rule(PATCH, "/api/admin/places/{id}/verified", PLACE_MODERATE),
        rule(PUT, "/api/admin/places/{id}/metadata", PLACE_EDIT),
        // Promotions
        rule(GET, "/api/admin/promotions", PROMOTION_MANAGE),
        rule(POST, "/api/admin/promotions", PROMOTION_MANAGE),
        rule(GET, "/api/admin/promotions/{id}", PROMOTION_MANAGE),
        rule(PUT, "/api/admin/promotions/{id}", PROMOTION_MANAGE),
        rule(DELETE, "/api/admin/promotions/{id}", PROMOTION_MANAGE),
        // Rate plans and occupancy prices
        rule(GET, "/api/admin/rate-plans", PLACE_VIEW),
        rule(GET, "/api/admin/rooms/{roomId}/rate-plans", PLACE_VIEW),
        rule(POST, "/api/admin/rooms/{roomId}/rate-plans", RATE_EDIT),
        rule(GET, "/api/admin/rate-plans/{id}", PLACE_VIEW),
        rule(PUT, "/api/admin/rate-plans/{id}", RATE_EDIT),
        rule(DELETE, "/api/admin/rate-plans/{id}", RATE_EDIT),
        rule(POST, "/api/admin/rate-plans/{id}/activate", RATE_EDIT),
        rule(POST, "/api/admin/rate-plans/{id}/deactivate", RATE_EDIT),
        rule(POST, "/api/admin/rate-plans/{id}/duplicate", RATE_EDIT),
        rule(GET, "/api/admin/rate-plans/{id}/occupancy-prices", PLACE_VIEW),
        rule(POST, "/api/admin/rate-plans/{id}/occupancy-prices", RATE_EDIT),
        rule(PUT, "/api/admin/rate-plan-occupancy-prices/{id}", RATE_EDIT),
        rule(DELETE, "/api/admin/rate-plan-occupancy-prices/{id}", RATE_EDIT),
        rule(GET, "/api/admin/rate-plans/{id}/preview", PLACE_VIEW),
        rule(POST, "/api/admin/rate-plans/{id}/validate", RATE_EDIT),
        // Referral campaigns
        rule(GET, "/api/admin/referral/campaigns", CUSTOMER_PROGRAM_MANAGE),
        rule(GET, "/api/admin/referral/campaigns/{id}", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/referral/campaigns", CUSTOMER_PROGRAM_MANAGE),
        rule(PUT, "/api/admin/referral/campaigns/{id}", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/referral/campaigns/{id}/activate", CUSTOMER_PROGRAM_MANAGE),
        rule(POST, "/api/admin/referral/campaigns/{id}/deactivate", CUSTOMER_PROGRAM_MANAGE),
        // Reviews
        rule(GET, "/api/admin/reviews", REVIEW_VIEW),
        rule(GET, "/api/admin/reviews/{id}", REVIEW_VIEW),
        rule(PATCH, "/api/admin/reviews/{id}/moderate", REVIEW_MODERATE),
        rule(GET, "/api/admin/reviews/analytics/overview", ANALYTICS_VIEW),
        // Rooms
        rule(GET, "/api/admin/hotels/{placeId}/rooms", PLACE_VIEW),
        rule(POST, "/api/admin/rooms", ROOM_EDIT),
        rule(GET, "/api/admin/rooms/{id}", PLACE_VIEW),
        rule(PUT, "/api/admin/rooms/{id}", ROOM_EDIT),
        rule(PATCH, "/api/admin/rooms/{id}/deactivate", ROOM_EDIT),
        // Travel credits
        rule(GET, "/api/admin/users/{userId}/travel-credits", CUSTOMER_VIEW),
        rule(POST, "/api/admin/users/{userId}/travel-credits/grant", TRAVEL_CREDIT_ADJUST),
        rule(POST, "/api/admin/users/{userId}/travel-credits/deduct", TRAVEL_CREDIT_ADJUST),
        // Travel wallet
        readAudited(GET, "/api/admin/users/{userId}/travel-wallet", CUSTOMER_WALLET_VIEW),
        // Trip reminders
        rule(POST, "/api/admin/trip-reminders/deliver-due", SYSTEM_JOB_RUN),
        rule(POST, "/api/admin/trip-reminders/{id}/deliver", SYSTEM_JOB_RUN),
        // Recommendations
        rule(GET, "/api/admin/users/{userId}/recommendations", CUSTOMER_VIEW),
        rule(POST, "/api/admin/users/{userId}/recommendations/generate", PERSONALIZATION_MANAGE),
        // Wallet expiry reminders
        rule(POST, "/api/admin/travel-wallet/generate-expiry-reminders", SYSTEM_JOB_RUN)
    );

    private static AdminEndpointRule rule(RequestMethod method, String pattern, AdminPermission permission) {
        return new AdminEndpointRule(method, pattern, List.of(permission), null, false, false);
    }

    private static AdminEndpointRule readAudited(RequestMethod method, String pattern, AdminPermission permission) {
        return new AdminEndpointRule(method, pattern, List.of(permission), null, false, true);
    }
}
