package com.example.planyourtrip.security.rbac;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMethod;

import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.function.Function;

/**
 * The endpoint authorization registry of RBAC V1.1 §24 B11: every partner and admin handler, keyed by
 * HTTP method and the handler's path pattern, with the authorization it requires.
 *
 * <p>The registry is validated when it is built, so a malformed rule — a duplicate, a reserved permission
 * on an endpoint, a {@code RESOURCE} without a resource type, a partner pattern outside {@code /api/partner}
 * — stops the application from starting instead of silently weakening a check.
 */
@Component
public class EndpointAuthorizationRegistry {

    public static final String PARTNER_PREFIX = "/api/partner";
    public static final String ADMIN_PREFIX = "/api/admin";

    private final Map<String, PartnerEndpointRule> partnerRules;
    private final Map<String, AdminEndpointRule> adminRules;

    @Autowired
    public EndpointAuthorizationRegistry() {
        this(PartnerEndpointRules.RULES, AdminEndpointRules.RULES);
    }

    /** For tests that need a registry with a different rule set. */
    public EndpointAuthorizationRegistry(List<PartnerEndpointRule> partner, List<AdminEndpointRule> admin) {
        this.partnerRules = index(partner, PartnerEndpointRule::key);
        this.adminRules = index(admin, AdminEndpointRule::key);
        partner.forEach(EndpointAuthorizationRegistry::validate);
        admin.forEach(EndpointAuthorizationRegistry::validate);
    }

    /** {@code "GET /api/partner/hotels/{id}"} — the lookup key of a handler. */
    public static String key(RequestMethod method, String pattern) {
        return method.name() + " " + pattern;
    }

    public Optional<PartnerEndpointRule> partnerRule(RequestMethod method, String pattern) {
        return Optional.ofNullable(partnerRules.get(key(method, pattern)));
    }

    public Optional<AdminEndpointRule> adminRule(RequestMethod method, String pattern) {
        return Optional.ofNullable(adminRules.get(key(method, pattern)));
    }

    public Collection<PartnerEndpointRule> partnerRules() {
        return partnerRules.values();
    }

    public Collection<AdminEndpointRule> adminRules() {
        return adminRules.values();
    }

    public static boolean isPartnerPath(String pattern) {
        return pattern != null && (pattern.equals(PARTNER_PREFIX) || pattern.startsWith(PARTNER_PREFIX + "/"));
    }

    public static boolean isAdminPath(String pattern) {
        return pattern != null && (pattern.equals(ADMIN_PREFIX) || pattern.startsWith(ADMIN_PREFIX + "/"));
    }

    // ── Validation ───────────────────────────────────────────────────────────

    private static <R> Map<String, R> index(List<R> rules, Function<R, String> key) {
        Map<String, R> byKey = new LinkedHashMap<>();
        for (R rule : rules) {
            if (byKey.put(key.apply(rule), rule) != null) {
                throw new IllegalStateException("Duplicate endpoint authorization rule: " + key.apply(rule));
            }
        }
        return Map.copyOf(byKey);
    }

    private static void validate(PartnerEndpointRule rule) {
        String where = rule.key();
        require(rule.method() != null && isPartnerPath(rule.pattern()), where, "must be a partner path");
        require(rule.kind() != null && rule.aggregate() != null, where, "needs a kind and an aggregate marking");
        require(!rule.permissions().isEmpty(), where, "needs a permission");
        require(rule.conditional() || rule.permissions().size() == 1, where,
            "lists several permissions without saying when each applies");
        rule.permissions().forEach(p -> require(!p.reserved(), where, "maps reserved permission " + p.id()));
        rule.fieldPermissions().forEach(p -> require(!p.reserved(), where, "gates a field with reserved " + p.id()));
        switch (rule.kind()) {
            case RESOURCE -> require(rule.resourceType() != null, where, "is a RESOURCE without a resource type");
            case COLLECTION -> require(rule.resourceType() != null
                    || rule.aggregate() != PartnerEndpointRule.AggregateScope.NONE,
                where, "is a COLLECTION that is neither typed nor an aggregate");
            case COMPANY, SELF -> require(rule.resourceType() == null, where, "has a resource type it cannot use");
        }
        require(rule.kind() != EndpointKind.SELF || rule.conditional(), where,
            "is SELF without saying when its permission applies");
    }

    private static void validate(AdminEndpointRule rule) {
        String where = rule.key();
        require(rule.method() != null && isAdminPath(rule.pattern()), where, "must be an admin path");
        require(!rule.permissions().isEmpty(), where, "needs a permission");
        require(rule.conditional() || rule.permissions().size() == 1, where,
            "lists several permissions without saying when each applies");
        rule.permissions().forEach(p -> require(!p.reserved(), where, "maps reserved permission " + p.id()));
    }

    private static void require(boolean condition, String rule, String problem) {
        if (!condition) throw new IllegalStateException("Endpoint authorization rule " + rule + " " + problem);
    }
}
