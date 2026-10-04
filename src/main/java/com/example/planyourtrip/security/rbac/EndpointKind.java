package com.example.planyourtrip.security.rbac;

/**
 * How a partner endpoint is authorized (RBAC V1.1 §4.5).
 *
 * <ul>
 *   <li>{@code RESOURCE} — one identified target; scope comes from the stored resource.</li>
 *   <li>{@code COLLECTION} — a list or aggregate, computed only over the caller's scope set.</li>
 *   <li>{@code COMPANY} — a company-level object; needs a company grant (workspace entry excepted).</li>
 *   <li>{@code SELF} — outside the workspace evaluator; authorized on the caller's own identity.</li>
 * </ul>
 */
public enum EndpointKind {
    RESOURCE,
    COLLECTION,
    COMPANY,
    SELF
}
