package com.example.planyourtrip;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.security.rbac.AdminEndpointRule;
import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.security.rbac.EndpointAuthorizationInterceptor;
import com.example.planyourtrip.security.rbac.EndpointAuthorizationRegistry;
import com.example.planyourtrip.security.rbac.EndpointKind;
import com.example.planyourtrip.security.rbac.PartnerEndpointRule;
import com.example.planyourtrip.security.rbac.PartnerEndpointRule.AggregateScope;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.example.planyourtrip.service.AdminAccessService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerMapping;
import org.springframework.web.servlet.mvc.method.RequestMappingInfo;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R1 — the endpoint authorization registry covers every partner and admin handler (RBAC V1.1 §24 B11, I17):
 * 99 partner (90 + 4 in RBAC R3a + 1 in R3b + 4 in R4) and 181 admin handlers, no handler missing, no rule without a handler, and a missing mapping
 * is refused rather than allowed.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RbacEndpointRegistryTest {

    @Autowired @Qualifier("requestMappingHandlerMapping") RequestMappingHandlerMapping handlerMapping;
    @Autowired EndpointAuthorizationRegistry registry;

    @Test
    void everyPartnerAndAdminHandlerIsRegisteredAndNothingElse() {
        Set<String> partnerHandlers = new TreeSet<>();
        Set<String> adminHandlers = new TreeSet<>();
        for (Map.Entry<RequestMappingInfo, HandlerMethod> e : handlerMapping.getHandlerMethods().entrySet()) {
            String controller = e.getValue().getBeanType().getSimpleName();
            Set<RequestMethod> methods = e.getKey().getMethodsCondition().getMethods();
            for (String pattern : e.getKey().getPatternValues()) {
                boolean partnerPath = EndpointAuthorizationRegistry.isPartnerPath(pattern);
                boolean adminPath = EndpointAuthorizationRegistry.isAdminPath(pattern);
                if (controller.startsWith("Partner")) assertTrue(partnerPath, controller + " serves " + pattern);
                if (controller.startsWith("Admin")) assertTrue(adminPath, controller + " serves " + pattern);
                if (!partnerPath && !adminPath) continue;
                assertFalse(methods.isEmpty(), pattern + " accepts every HTTP method and cannot be mapped");
                for (RequestMethod method : methods) {
                    (partnerPath ? partnerHandlers : adminHandlers).add(EndpointAuthorizationRegistry.key(method, pattern));
                }
            }
        }

        Set<String> partnerRules = registry.partnerRules().stream().map(PartnerEndpointRule::key)
            .collect(Collectors.toCollection(TreeSet::new));
        Set<String> adminRules = registry.adminRules().stream().map(AdminEndpointRule::key)
            .collect(Collectors.toCollection(TreeSet::new));

        assertEquals(Set.of(), difference(partnerHandlers, partnerRules), "partner handlers without a rule");
        assertEquals(Set.of(), difference(partnerRules, partnerHandlers), "partner rules without a handler");
        assertEquals(Set.of(), difference(adminHandlers, adminRules), "admin handlers without a rule");
        assertEquals(Set.of(), difference(adminRules, adminHandlers), "admin rules without a handler");
        // RBAC R3a adds PUT /team/{id}/grants, POST /team/{id}/suspend, /reactivate and POST /team/leave;
        // RBAC R3b adds GET /api/partner/me/access; RBAC R4 adds GET/POST /team/invitations, POST
        // /team/invitations/{id}/resend and DELETE /team/invitations/{id}
        assertEquals(99, partnerHandlers.size());
        // RBAC R6 adds the 3 admin access endpoints (§25.4) and the 5 dual-control endpoints (§22.6)
        assertEquals(189, adminHandlers.size());
    }

    @Test
    void everyActivePermissionProtectsSomethingAndNoReservedOneDoes() {
        Set<PartnerPermission> partnerUsed = registry.partnerRules().stream()
            .flatMap(r -> Stream.concat(r.permissions().stream(), r.fieldPermissions().stream()))
            .collect(Collectors.toCollection(() -> EnumSet.noneOf(PartnerPermission.class)));
        Set<AdminPermission> adminUsed = registry.adminRules().stream()
            .flatMap(r -> r.permissions().stream())
            .collect(Collectors.toCollection(() -> EnumSet.noneOf(AdminPermission.class)));

        for (PartnerPermission p : PartnerPermission.values()) {
            assertEquals(!p.reserved(), partnerUsed.contains(p), p.id() + " " + p.key());
        }
        for (AdminPermission p : AdminPermission.values()) {
            assertEquals(!p.reserved(), adminUsed.contains(p), p.id() + " " + p.key());
        }
    }

    @Test
    void rulesFollowTheDesignShape() {
        for (PartnerEndpointRule rule : registry.partnerRules()) {
            if (rule.kind() == EndpointKind.RESOURCE) assertNotNull(rule.resourceType(), rule.key());
            if (rule.aggregate() == AggregateScope.COMPANY_ONLY) assertEquals(EndpointKind.COMPANY, rule.kind(), rule.key());
            if (rule.aggregate() == AggregateScope.FILTERABLE_BY_PROPERTY)
                assertNotEquals(EndpointKind.RESOURCE, rule.kind(), rule.key());
            if (rule.kind() == EndpointKind.COMPANY && rule.permissions().get(0) != PartnerPermission.WORKSPACE_ACCESS)
                assertNotEquals(ScopeType.UNIT,
                    rule.permissions().get(0).floor(), rule.key());
        }
        assertEquals(5, registry.partnerRules().stream().filter(r -> r.kind() == EndpointKind.SELF).count());
        // spot checks against RBAC V1.1 §25.1 and §9.2
        assertEquals(List.of(PartnerPermission.PROPERTY_CREATE),
            registry.partnerRule(RequestMethod.POST, "/api/partner/hotels").orElseThrow().permissions());
        assertEquals(ResourceType.MEMBERSHIP,
            registry.partnerRule(RequestMethod.PATCH, "/api/partner/team/{id}").orElseThrow().resourceType());
        assertTrue(registry.partnerRule(RequestMethod.PUT, "/api/partner/payout-account").orElseThrow().stepUp());
        assertEquals(List.of(AdminPermission.PLACE_OWNER_ASSIGN),
            registry.adminRule(RequestMethod.POST, "/api/admin/hotels/{hotelId}/assign-owner").orElseThrow().permissions());
        assertEquals(List.of(AdminPermission.PLACE_MODERATE, AdminPermission.PLACE_PUBLISH),
            registry.adminRule(RequestMethod.PATCH, "/api/admin/places/{id}/status").orElseThrow().permissions());
        assertEquals(List.of(AdminPermission.ANALYTICS_VIEW),
            registry.adminRule(RequestMethod.GET, "/api/admin/reviews/analytics/overview").orElseThrow().permissions());
        assertEquals(List.of(AdminPermission.CUSTOMER_ENTITLEMENT_ADJUST),
            registry.adminRule(RequestMethod.POST, "/api/admin/users/{userId}/coupons/{couponId}/revoke").orElseThrow().permissions());
    }

    @Test
    void anUnregisteredHandlerIsRefused() throws Exception {
        EndpointAuthorizationInterceptor guard = new EndpointAuthorizationInterceptor(
            // an unregistered handler is refused before the admin access, step-up or read-audit collaborators run
            new EndpointAuthorizationRegistry(List.of(), List.of()), new AdminAccessService(null), null, null);
        HandlerMethod handler = new HandlerMethod(this, getClass().getDeclaredMethod("anUnregisteredHandlerIsRefused"));

        for (String pattern : List.of("/api/partner/hotels", "/api/admin/partners")) {
            MockHttpServletRequest request = new MockHttpServletRequest("GET", pattern);
            request.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, pattern);
            ApiException refused = assertThrows(ApiException.class,
                () -> guard.preHandle(request, new MockHttpServletResponse(), handler), pattern);
            assertEquals(HttpStatus.FORBIDDEN, refused.status());
            assertEquals("PERMISSION_DENIED", refused.code());
        }

        // outside the partner and admin trees the guard has nothing to say
        MockHttpServletRequest userRequest = new MockHttpServletRequest("GET", "/api/me");
        userRequest.setAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE, "/api/me");
        assertTrue(guard.preHandle(userRequest, new MockHttpServletResponse(), handler));
    }

    @Test
    void aMalformedRuleStopsTheRegistryFromLoading() {
        PartnerEndpointRule untypedResource = new PartnerEndpointRule(RequestMethod.GET, "/api/partner/x/{id}",
            EndpointKind.RESOURCE, null, List.of(PartnerPermission.PROPERTY_VIEW), null, Set.of(), AggregateScope.NONE, false);
        PartnerEndpointRule reserved = new PartnerEndpointRule(RequestMethod.POST, "/api/partner/x",
            EndpointKind.COMPANY, null, List.of(PartnerPermission.PROPERTY_PUBLISH), null, Set.of(), AggregateScope.NONE, false);
        PartnerEndpointRule outsideTree = new PartnerEndpointRule(RequestMethod.GET, "/api/places",
            EndpointKind.COLLECTION, ResourceType.PROPERTY, List.of(PartnerPermission.PROPERTY_VIEW), null, Set.of(),
            AggregateScope.NONE, false);
        PartnerEndpointRule ambiguous = new PartnerEndpointRule(RequestMethod.GET, "/api/partner/y",
            EndpointKind.COMPANY, null, List.of(PartnerPermission.SETTINGS_EDIT, PartnerPermission.TEAM_VIEW), null,
            Set.of(), AggregateScope.NONE, false);

        for (PartnerEndpointRule bad : List.of(untypedResource, reserved, outsideTree, ambiguous)) {
            assertThrows(IllegalStateException.class,
                () -> new EndpointAuthorizationRegistry(List.of(bad), List.of()), bad.key());
        }
        PartnerEndpointRule ok = new PartnerEndpointRule(RequestMethod.GET, "/api/partner/z",
            EndpointKind.COMPANY, null, List.of(PartnerPermission.WORKSPACE_ACCESS), null, Set.of(), AggregateScope.NONE, false);
        assertThrows(IllegalStateException.class,
            () -> new EndpointAuthorizationRegistry(List.of(ok, ok), List.of()), "duplicate");
        assertThrows(IllegalStateException.class, () -> new EndpointAuthorizationRegistry(List.of(), List.of(
            new AdminEndpointRule(RequestMethod.GET, "/api/admin/x", List.of(AdminPermission.CUSTOMER_ACCOUNT_MANAGE), null, false, false))));
    }

    private static Set<String> difference(Set<String> a, Set<String> b) {
        Set<String> d = new TreeSet<>(a);
        d.removeAll(b);
        return d;
    }
}
