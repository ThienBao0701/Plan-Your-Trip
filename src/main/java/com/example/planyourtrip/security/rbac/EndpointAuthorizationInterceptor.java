package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.service.AdminAccessService;
import com.example.planyourtrip.service.PartnerAccessService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.HandlerMapping;

/**
 * Fail-closed guard for the endpoint registry (RBAC V1.1 §24 B11, I17).
 *
 * <p>Runs after the security filter chain, for controller handlers only:
 * <ul>
 *   <li>a handler under {@code /api/partner} or {@code /api/admin} that is not in the registry is refused
 *       with 403 — a new endpoint cannot ship unprotected;</li>
 *   <li>an admin handler additionally requires its admin permission. In R1 every {@code ADMIN} holds every
 *       admin permission, so this changes nothing for today's administrators.</li>
 * </ul>
 * Partner permission decisions stay in the services, which resolve the workspace and the resource from
 * stored data ({@code PartnerAccessService}). The matched rule is exposed as a request attribute.
 */
@Component
public class EndpointAuthorizationInterceptor implements HandlerInterceptor {

    /** Request attribute holding the matched {@link PartnerEndpointRule} or {@link AdminEndpointRule}. */
    public static final String RULE_ATTRIBUTE = EndpointAuthorizationInterceptor.class.getName() + ".rule";

    private static final Logger log = LoggerFactory.getLogger(EndpointAuthorizationInterceptor.class);

    private final EndpointAuthorizationRegistry registry;
    private final AdminAccessService adminAccess;

    public EndpointAuthorizationInterceptor(EndpointAuthorizationRegistry registry, AdminAccessService adminAccess) {
        this.registry = registry;
        this.adminAccess = adminAccess;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        if (!(handler instanceof HandlerMethod)) return true;
        Object matched = request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
        if (!(matched instanceof String pattern)) return true;

        boolean partner = EndpointAuthorizationRegistry.isPartnerPath(pattern);
        boolean admin = EndpointAuthorizationRegistry.isAdminPath(pattern);
        if (!partner && !admin) return true;

        RequestMethod method = methodOf(request);
        if (partner) {
            PartnerEndpointRule rule = method == null ? null
                : registry.partnerRule(method, pattern).orElse(null);
            if (rule == null) throw unregistered(request, pattern);
            request.setAttribute(RULE_ATTRIBUTE, rule);
            return true;
        }

        AdminEndpointRule rule = method == null ? null : registry.adminRule(method, pattern).orElse(null);
        if (rule == null) throw unregistered(request, pattern);
        if (!adminAccess.holdsAny(SecurityContextHolder.getContext().getAuthentication(), rule.permissions())) {
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
        }
        request.setAttribute(RULE_ATTRIBUTE, rule);
        return true;
    }

    /** HEAD is served by GET handlers, so it is authorized as GET; an unknown method matches nothing. */
    private static RequestMethod methodOf(HttpServletRequest request) {
        String raw = request.getMethod();
        if ("HEAD".equals(raw)) return RequestMethod.GET;
        try {
            return RequestMethod.valueOf(raw);
        } catch (IllegalArgumentException | NullPointerException unknown) {
            return null;
        }
    }

    private static ApiException unregistered(HttpServletRequest request, String pattern) {
        log.error("Refused {} {}: the handler is not in the endpoint authorization registry",
            request.getMethod(), pattern);
        return new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
    }
}
