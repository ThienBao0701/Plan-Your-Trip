package com.example.planyourtrip.security;

import java.time.Instant;

/**
 * RBAC R3a — what the request's bearer token says about its session, kept as the authentication's details:
 * when the token was issued ({@code exp - app.jwt.expiration-ms}, §18 O-7). Used only to decide whether the
 * session is fresh enough for a step-up action; it never carries a permission.
 */
public record TokenSession(Instant issuedAt) {}
