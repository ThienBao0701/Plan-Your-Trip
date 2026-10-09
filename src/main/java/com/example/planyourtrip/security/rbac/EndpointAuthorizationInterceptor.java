package com.example.planyourtrip.security.rbac;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.UserPrincipal;
import com.example.planyourtrip.service.AdminAccessService;
import com.example.planyourtrip.service.AdminReadAuditService;
import com.example.planyourtrip.service.PartnerAccessService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;
import org.springframework.web.servlet.HandlerMapping;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Fail-closed guard for the endpoint registry (RBAC V1.1 §24 B11, I17).
 *
 * <p>Runs after the security filter chain, for controller handlers only:
 * <ul>
 *   <li>a handler under {@code /api/partner} or {@code /api/admin} that is not in the registry is refused
 *       with 403 — a new endpoint cannot ship unprotected;</li>
 *   <li>an admin handler additionally requires its admin permission — RBAC R6: the union of the caller's admin
 *       profiles ({@link AdminAccessService}) — then, for the rules that say so, a fresh session (step-up,
 *       403 {@code STEP_UP_REQUIRED}) and a read-access audit row written before the read runs (§22.5, fail
 *       closed).</li>
 * </ul>
 * A refused admin request is logged at WARN with the user id, the permission keys and the route — never the
 * target's data — at most once a minute per user and route, so probing is visible without flooding the log
 * (§22.4). Denials are not audit events.
 * Partner permission decisions stay in the services, which resolve the workspace and the resource from
 * stored data ({@code PartnerAccessService}). The matched rule is exposed as a request attribute.
 */
@Component
public class EndpointAuthorizationInterceptor implements HandlerInterceptor {

    /** Request attribute holding the matched {@link PartnerEndpointRule} or {@link AdminEndpointRule}. */
    public static final String RULE_ATTRIBUTE = EndpointAuthorizationInterceptor.class.getName() + ".rule";

    private static final Logger log = LoggerFactory.getLogger(EndpointAuthorizationInterceptor.class);

    /** One WARN per user and route per minute (§22.4); the map is bounded and simply cleared when full. */
    private static final long DENIAL_LOG_INTERVAL_MS = 60_000;
    private static final int DENIAL_LOG_MAX_KEYS = 10_000;
    private final Map<String, Long> lastDenialLog = new ConcurrentHashMap<>();

    private final EndpointAuthorizationRegistry registry;
    private final AdminAccessService adminAccess;
    private final StepUpPolicy stepUp;
    private final AdminReadAuditService readAudit;

    public EndpointAuthorizationInterceptor(EndpointAuthorizationRegistry registry, AdminAccessService adminAccess,
                                            StepUpPolicy stepUp, AdminReadAuditService readAudit) {
        this.registry = registry;
        this.adminAccess = adminAccess;
        this.stepUp = stepUp;
        this.readAudit = readAudit;
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
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (!adminAccess.holdsAny(authentication, rule.permissions())) {
            logDenial(authentication, rule);
            throw new ApiException(HttpStatus.FORBIDDEN, PartnerAccessService.PERMISSION_DENIED, "Access denied");
        }
        if (rule.stepUp()) stepUp.requireFresh();
        request.setAttribute(RULE_ATTRIBUTE, rule);
        if (rule.readAudit()) {
            readAudit.recordRead(rule, userIdOf(authentication), pathVariables(request), request.getParameterMap());
        }
        return true;
    }

    private void logDenial(Authentication authentication, AdminEndpointRule rule) {
        Long userId = userIdOf(authentication);
        String key = userId + " " + rule.key();
        long now = System.currentTimeMillis();
        Long last = lastDenialLog.get(key);
        if (last != null && now - last < DENIAL_LOG_INTERVAL_MS) return;
        if (lastDenialLog.size() >= DENIAL_LOG_MAX_KEYS) lastDenialLog.clear();
        lastDenialLog.put(key, now);
        log.warn("Admin permission denied: user {} lacks {} for {}", userId,
            rule.permissions().stream().map(AdminPermission::key).toList(), rule.key());
    }

    private static Long userIdOf(Authentication authentication) {
        return authentication != null && authentication.getPrincipal() instanceof UserPrincipal principal
            ? principal.id() : null;
    }

    @SuppressWarnings("unchecked")
    private static Map<String, String> pathVariables(HttpServletRequest request) {
        Object variables = request.getAttribute(HandlerMapping.URI_TEMPLATE_VARIABLES_ATTRIBUTE);
        return variables instanceof Map<?, ?> map ? (Map<String, String>) map : Map.of();
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
