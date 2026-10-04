package com.example.planyourtrip.security.rbac;

import org.springframework.web.bind.annotation.RequestMethod;

import java.util.List;

/**
 * How one admin handler is authorized — one backing endpoint of RBAC V1.1 §9.2.
 *
 * @param permissions the admin permission; two only for a value-dependent endpoint
 * @param condition   null for a single permission; otherwise which value selects which permission
 * @param stepUp      whether the action needs a fresh token (§18 O-7)
 * @param readAudit   whether a read must be audited (§22.5)
 */
public record AdminEndpointRule(RequestMethod method, String pattern, List<AdminPermission> permissions,
                                String condition, boolean stepUp, boolean readAudit) {

    public AdminEndpointRule {
        permissions = List.copyOf(permissions);
    }

    public String key() {
        return EndpointAuthorizationRegistry.key(method, pattern);
    }

    public boolean conditional() {
        return condition != null;
    }
}
