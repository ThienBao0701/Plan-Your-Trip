package com.example.planyourtrip.security.rbac;

/**
 * The outcome of one evaluation (RBAC V1.1 §26): allowed, refused about something the caller may know
 * exists (403), or refused as if the target did not exist (404).
 */
public enum AuthorizationDecision {
    ALLOW,
    FORBIDDEN,
    NOT_FOUND
}
