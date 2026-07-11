package com.example.planyourtrip.model;

/**
 * Phase 7.19 — Membership Tier &amp; Loyalty Qualification.
 * What produced a {@link MembershipTierHistory} row:
 * <ul>
 *   <li>{@code INITIAL_ENROLLMENT} — first membership creation
 *       ({@code CustomerMembershipService#enroll}).</li>
 *   <li>{@code AUTOMATIC_UPGRADE} — the synchronous, idempotent post-award
 *       evaluation hook found a higher qualified tier
 *       ({@code CustomerMembershipService#evaluateAutomaticUpgrade}), or an
 *       admin-triggered reevaluation that happens to raise the tier.</li>
 *   <li>{@code AUTOMATIC_DOWNGRADE} — only ever produced by an EXPLICIT admin
 *       reevaluation ({@code CustomerMembershipService#adminReevaluate}); never
 *       produced by the automatic post-award hook, which is strictly
 *       upgrade-only (grace-period rule — see class javadoc on
 *       {@code CustomerMembershipService}).</li>
 *   <li>{@code MANUAL_UPGRADE}/{@code MANUAL_DOWNGRADE} — admin manual
 *       assignment ({@code CustomerMembershipService#adminAssign}), direction
 *       derived by comparing the new tier's ordinal to the previous one's.</li>
 *   <li>{@code EXPIRATION} — an explicit admin reevaluation that detects the
 *       membership's {@code validUntil} has already passed; this is the ONLY
 *       path that fires the "Membership expired" notification (there is no
 *       background scheduler in this phase — expiry is otherwise computed
 *       on-read only, never destructively applied to the stored row).</li>
 *   <li>{@code REACTIVATION} — reserved for a future phase that reintroduces a
 *       lapsed/inactive membership; not produced by anything in this phase.</li>
 * </ul>
 */
public enum MembershipTierChangeType {
    INITIAL_ENROLLMENT, AUTOMATIC_UPGRADE, AUTOMATIC_DOWNGRADE,
    MANUAL_UPGRADE, MANUAL_DOWNGRADE, EXPIRATION, REACTIVATION
}
