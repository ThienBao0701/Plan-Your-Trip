package com.example.planyourtrip.model;

/**
 * State of a partner team membership (RBAC V1.1 §12.3, §17).
 *
 * <ul>
 *   <li>{@code ACTIVE} — the membership counts; the legacy {@code active} flag is true.</li>
 *   <li>{@code SUSPENDED} — kept with its grants but grants no access; reversible.</li>
 *   <li>{@code REVOKED} — ended; never reactivated (the person is re-invited instead).</li>
 * </ul>
 */
public enum PartnerMembershipStatus {
    ACTIVE,
    SUSPENDED,
    REVOKED
}
