package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.security.rbac.EffectivePermissions;
import com.example.planyourtrip.security.rbac.LegacyPartnerBundles;
import com.example.planyourtrip.security.rbac.ParentContext;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerGrant;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeSet;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.junit.jupiter.api.Test;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;

import static com.example.planyourtrip.security.rbac.AuthorizationDecision.ALLOW;
import static com.example.planyourtrip.security.rbac.AuthorizationDecision.FORBIDDEN;
import static com.example.planyourtrip.security.rbac.AuthorizationDecision.NOT_FOUND;
import static com.example.planyourtrip.security.rbac.PartnerPermission.*;
import static org.junit.jupiter.api.Assertions.*;

/**
 * R1 — the §4.5 evaluator as pure functions, with grants at every scope type. The worked examples follow
 * RBAC V1.1 §12.1: company 456 owns properties 123 and 124; property 123 has room types 9001 and 9002;
 * company 789 owns property 555.
 *
 * <p>Grants are built from explicit bundles: R1 resolves only company-level legacy grants at runtime, so
 * property and unit grants are exercised here, where the kernel's scope semantics are decided.
 */
class RbacScopeEvaluatorTest {

    private static final long COMPANY = 456, OTHER_COMPANY = 789;
    private static final long P123 = 123, P124 = 124, P555 = 555;
    private static final long U9001 = 9001, U9002 = 9002;

    private static final ScopePath COMPANY_456 = ScopePath.company(COMPANY);
    private static final ScopePath PROPERTY_123 = ScopePath.property(COMPANY, P123);
    private static final ScopePath PROPERTY_124 = ScopePath.property(COMPANY, P124);
    private static final ScopePath UNIT_9001 = ScopePath.unit(COMPANY, P123, U9001);
    private static final ScopePath UNIT_9002 = ScopePath.unit(COMPANY, P123, U9002);
    private static final ScopePath FOREIGN_555 = ScopePath.property(OTHER_COMPANY, P555);

    // ── Cross-company and cross-property ─────────────────────────────────────

    @Test
    void foreignCompanyResourceIsNotFoundEvenForTheRegistrant() {
        PartnerAccessContext registrant = ctx(new PartnerGrant(LegacyPartnerBundles.registrant(), COMPANY_456));
        for (PartnerPermission p : PartnerPermission.values()) {
            assertEquals(NOT_FOUND, PartnerAuthorization.resource(registrant, p, ResourceType.PROPERTY, FOREIGN_555), p.id());
        }
        assertFalse(PartnerAuthorization.collection(registrant, PROPERTY_VIEW).permits(FOREIGN_555));
    }

    @Test
    void foreignPropertyOfTheSameCompanyIsNotFound() {
        PartnerAccessContext frontDesk = ctx(new PartnerGrant(
            EnumSet.of(WORKSPACE_ACCESS, PROPERTY_VIEW, BOOKING_VIEW, BOOKING_ARRIVAL_OPERATE), PROPERTY_123));
        assertEquals(ALLOW, PartnerAuthorization.resource(frontDesk, BOOKING_ARRIVAL_OPERATE, ResourceType.BOOKING, PROPERTY_123));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(frontDesk, BOOKING_ARRIVAL_OPERATE, ResourceType.BOOKING, PROPERTY_124));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(frontDesk, PROPERTY_VIEW, ResourceType.PROPERTY, PROPERTY_124));
    }

    @Test
    void grantsOfAnotherCompanyInsideTheContextNeverCount() {
        PartnerAccessContext tampered = ctx(new PartnerGrant(LegacyPartnerBundles.registrant(), ScopePath.company(OTHER_COMPANY)));
        assertTrue(PartnerAuthorization.effectiveScopes(tampered, PROPERTY_VIEW).isEmpty());
        assertEquals(FORBIDDEN, PartnerAuthorization.company(tampered, WORKSPACE_ACCESS));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(tampered, PROPERTY_VIEW, ResourceType.PROPERTY, FOREIGN_555));
    }

    // ── No escalation through narrower grants ───────────────────────────────

    @Test
    void propertyGrantNeverBecomesCompanyAccess() {
        PartnerAccessContext propertyManager = ctx(new PartnerGrant(
            EnumSet.of(WORKSPACE_ACCESS, SETTINGS_EDIT, FINANCE_STATEMENT_VIEW, PROPERTY_CREATE, PROPERTY_VIEW), PROPERTY_123));

        // floor-COMPANY permissions in the bundle are not effective at property scope
        assertTrue(PartnerAuthorization.effectiveScopes(propertyManager, FINANCE_STATEMENT_VIEW).isEmpty());
        assertEquals(FORBIDDEN, PartnerAuthorization.company(propertyManager, FINANCE_STATEMENT_VIEW));
        assertEquals(FORBIDDEN, PartnerAuthorization.company(propertyManager, SETTINGS_EDIT));
        assertEquals(FORBIDDEN, PartnerAuthorization.company(propertyManager, PROPERTY_CREATE));
        // a floor-PROPERTY permission held at property scope does not satisfy a company-level check either
        assertEquals(FORBIDDEN, PartnerAuthorization.company(propertyManager, PROPERTY_VIEW));
        assertFalse(PROPERTY_123.covers(COMPANY_456));
        assertFalse(PartnerAuthorization.collection(propertyManager, PROPERTY_VIEW).companyWide());
        // workspace entry is the one company-level permission any grant satisfies
        assertEquals(ALLOW, PartnerAuthorization.company(propertyManager, WORKSPACE_ACCESS));
    }

    @Test
    void unitGrantGetsWorkspaceEntryAndParentContextOnly() {
        PartnerAccessContext housekeeper = ctx(new PartnerGrant(
            EnumSet.of(WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW), UNIT_9001));

        assertEquals(ALLOW, PartnerAuthorization.company(housekeeper, WORKSPACE_ACCESS));
        assertEquals(ALLOW, PartnerAuthorization.resource(housekeeper, ROOM_VIEW, ResourceType.ROOM, UNIT_9001));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(housekeeper, ROOM_VIEW, ResourceType.ROOM, UNIT_9002));
        // property view has floor PROPERTY: a unit grant never reads the property record itself
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(housekeeper, PROPERTY_VIEW, ResourceType.PROPERTY, PROPERTY_123));
        assertFalse(UNIT_9001.covers(PROPERTY_123));

        ParentContext context = PartnerAuthorization.parentContext(housekeeper);
        assertFalse(context.companyWide());
        assertEquals(Set.of(P123), context.propertyIds());
        assertEquals(Set.of(U9001), context.unitIds());

        EffectivePermissions effective = PartnerAuthorization.effectivePermissions(housekeeper);
        assertTrue(effective.company().isEmpty());
        assertTrue(effective.properties().isEmpty());
        assertEquals(Set.of(WORKSPACE_ACCESS, ROOM_VIEW), effective.units().get(U9001));
    }

    @Test
    void effectivePermissionsApplyScopeFloors() {
        PartnerAccessContext propertyManager = ctx(new PartnerGrant(
            EnumSet.of(WORKSPACE_ACCESS, PROPERTY_VIEW, FINANCE_STATEMENT_VIEW, PAYOUT_ACCOUNT_VIEW), PROPERTY_123));
        EffectivePermissions effective = PartnerAuthorization.effectivePermissions(propertyManager);
        assertEquals(Set.of(WORKSPACE_ACCESS, PROPERTY_VIEW), effective.properties().get(P123));
        assertTrue(effective.company().isEmpty());

        PartnerAccessContext registrant = ctx(new PartnerGrant(LegacyPartnerBundles.registrant(), COMPANY_456));
        assertEquals(EnumSet.allOf(PartnerPermission.class),
            EnumSet.copyOf(PartnerAuthorization.effectivePermissions(registrant).company()));
    }

    // ── Endpoint kinds ───────────────────────────────────────────────────────

    @Test
    void collectionFiltersToThePermittedScope() {
        ScopeSet companyWide = PartnerAuthorization.collection(
            ctx(new PartnerGrant(EnumSet.of(BOOKING_VIEW), COMPANY_456)), BOOKING_VIEW);
        assertTrue(companyWide.companyWide());
        assertTrue(companyWide.permits(PROPERTY_123) && companyWide.permits(PROPERTY_124));
        assertFalse(companyWide.permits(FOREIGN_555));

        ScopeSet onlyProperty = PartnerAuthorization.collection(
            ctx(new PartnerGrant(EnumSet.of(BOOKING_VIEW), PROPERTY_123)), BOOKING_VIEW);
        assertFalse(onlyProperty.companyWide());
        assertEquals(Set.of(P123), onlyProperty.propertyIds());
        assertTrue(onlyProperty.permits(PROPERTY_123));
        assertTrue(onlyProperty.permits(UNIT_9001));
        assertFalse(onlyProperty.permits(PROPERTY_124));
        assertFalse(onlyProperty.permits(COMPANY_456));

        ScopeSet onlyUnit = PartnerAuthorization.collection(
            ctx(new PartnerGrant(EnumSet.of(ROOM_VIEW), UNIT_9001)), ROOM_VIEW);
        assertTrue(onlyUnit.permits(UNIT_9001));
        assertFalse(onlyUnit.permits(UNIT_9002));
        assertFalse(onlyUnit.permits(PROPERTY_123));

        // a unit grant cannot list a floor-PROPERTY collection at all
        assertTrue(PartnerAuthorization.collection(ctx(new PartnerGrant(EnumSet.of(BOOKING_VIEW), UNIT_9001)), BOOKING_VIEW).isEmpty());
        // not held anywhere: the endpoint answers 403, not an empty list
        assertTrue(PartnerAuthorization.collection(ctx(new PartnerGrant(EnumSet.of(WORKSPACE_ACCESS), COMPANY_456)), BOOKING_VIEW).isEmpty());
    }

    @Test
    void resourceDecisionFollowsTheTargetNotTheCaller() {
        PartnerAccessContext revenue = ctx(
            new PartnerGrant(EnumSet.of(RATE_VIEW, RATE_EDIT), PROPERTY_123),
            new PartnerGrant(EnumSet.of(RATE_VIEW), PROPERTY_124));
        assertEquals(ALLOW, PartnerAuthorization.resource(revenue, RATE_EDIT, ResourceType.RATE_PLAN, UNIT_9001));
        assertEquals(FORBIDDEN, PartnerAuthorization.resource(revenue, RATE_EDIT, ResourceType.RATE_PLAN,
            ScopePath.unit(COMPANY, P124, 9100L)));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(revenue, RATE_EDIT, ResourceType.RATE_PLAN, null));
    }

    @Test
    void companyEndpointNeedsACompanyLevelGrant() {
        assertEquals(ALLOW, PartnerAuthorization.company(ctx(new PartnerGrant(EnumSet.of(SETTINGS_EDIT), COMPANY_456)), SETTINGS_EDIT));
        assertEquals(FORBIDDEN, PartnerAuthorization.company(ctx(new PartnerGrant(EnumSet.of(SETTINGS_EDIT), PROPERTY_123)), SETTINGS_EDIT));
        assertEquals(FORBIDDEN, PartnerAuthorization.company(ctx(new PartnerGrant(EnumSet.of(TEAM_VIEW), COMPANY_456)), SETTINGS_EDIT));
        assertEquals(FORBIDDEN, PartnerAuthorization.company(null, WORKSPACE_ACCESS));
    }

    // ── 403 versus 404 is decided by the resource type ───────────────────────

    @Test
    void forbiddenOnlyWhenTheCallerMayViewThatResourceType() {
        PartnerAccessContext frontDesk = ctx(new PartnerGrant(
            EnumSet.of(WORKSPACE_ACCESS, PROPERTY_VIEW, BOOKING_VIEW, BOOKING_ARRIVAL_OPERATE), PROPERTY_123));
        // may view the property: refusing the policy edit reveals nothing new
        assertEquals(FORBIDDEN, PartnerAuthorization.resource(frontDesk, PROPERTY_POLICY_EDIT, ResourceType.PROPERTY, PROPERTY_123));

        PartnerAccessContext housekeeping = ctx(new PartnerGrant(
            EnumSet.of(WORKSPACE_ACCESS, PROPERTY_VIEW, ROOM_VIEW), PROPERTY_123));
        // property view covers the booking's property, but booking view is what matters: 404, not 403
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(housekeeping, BOOKING_VIEW, ResourceType.BOOKING, PROPERTY_123));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(housekeeping, BOOKING_ARRIVAL_OPERATE, ResourceType.BOOKING, PROPERTY_123));
        assertEquals(NOT_FOUND, PartnerAuthorization.resource(housekeeping, PROPERTY_VIEW, ResourceType.PROPERTY, PROPERTY_124));
    }

    // ── Fail closed ──────────────────────────────────────────────────────────

    @Test
    void permissionKeysAreCheckedByNamespaceAndUnknownKeysFailClosed() {
        PartnerAccessContext registrant = ctx(new PartnerGrant(LegacyPartnerBundles.registrant(), COMPANY_456));
        assertTrue(PartnerAuthorization.isGranted(registrant, "partner.property.view", PROPERTY_123));
        assertFalse(PartnerAuthorization.isGranted(registrant, "admin.place.view", PROPERTY_123));
        assertFalse(PartnerAuthorization.isGranted(registrant, "admin.console.access", COMPANY_456));
        assertFalse(PartnerAuthorization.isGranted(registrant, "partner.property.delete", PROPERTY_123));
        assertFalse(PartnerAuthorization.isGranted(registrant, null, PROPERTY_123));
        assertFalse(PartnerAuthorization.isGranted(registrant, "partner.property.view", null));
        assertFalse(PartnerAuthorization.isGranted(registrant, "partner.property.view", FOREIGN_555));
    }

    @Test
    void unknownRoleHoldsNothing() {
        assertTrue(LegacyPartnerBundles.member(null).isEmpty());
        PartnerAccessContext unknown = ctx(new PartnerGrant(LegacyPartnerBundles.member(null), COMPANY_456));
        assertEquals(FORBIDDEN, PartnerAuthorization.company(unknown, WORKSPACE_ACCESS));
        assertTrue(PartnerAuthorization.collection(unknown, PROPERTY_VIEW).isEmpty());
        assertFalse(PartnerAuthorization.parentContext(unknown).companyWide());
    }

    @Test
    void malformedScopesFailClosed() {
        for (String raw : new String[] {null, "", "PROPERTY", "PROPERTY:", "PROPERTY:abc", "PROPERTY:-1", "PROPERTY:0",
                "PROPERTY:007", "property:123", " PROPERTY:123", "PROPERTY:123 ", "ROOM:1", "COMPANY:1:2",
                "PROPERTY:99999999999999999999"}) {
            assertTrue(ScopeRef.parse(raw).isEmpty(), "accepted " + raw);
        }
        assertEquals(new ScopeRef(ScopeType.PROPERTY, 123), ScopeRef.parse("PROPERTY:123").orElseThrow());
        assertEquals(new ScopeRef(ScopeType.UNIT, 9001), ScopeRef.parse("UNIT:9001").orElseThrow());

        assertThrows(IllegalArgumentException.class, () -> new ScopePath(null, null, null));
        assertThrows(IllegalArgumentException.class, () -> new ScopePath(0L, null, null));
        assertThrows(IllegalArgumentException.class, () -> new ScopePath(COMPANY, -1L, null));
        assertThrows(IllegalArgumentException.class, () -> new ScopePath(COMPANY, null, U9001));
        assertThrows(IllegalArgumentException.class, () -> ScopePath.property(COMPANY, null));
        assertThrows(IllegalArgumentException.class, () -> new PartnerGrant(Set.of(PROPERTY_VIEW), null));
    }

    // ── R1 legacy bundles reproduce today's rules ───────────────────────────

    @Test
    void legacyBundlesGiveTeamMembersNoNewPowers() {
        assertEquals(EnumSet.allOf(PartnerPermission.class), EnumSet.copyOf(LegacyPartnerBundles.registrant()));

        Set<PartnerPermission> reads = Set.of(WORKSPACE_ACCESS, TEAM_VIEW, PAYOUT_ACCOUNT_VIEW);
        assertEquals(reads, LegacyPartnerBundles.member(PartnerTeamRole.VIEWER));
        assertEquals(reads, LegacyPartnerBundles.member(PartnerTeamRole.FRONT_DESK));
        assertEquals(union(reads, SETTINGS_EDIT), LegacyPartnerBundles.member(PartnerTeamRole.MANAGER));
        assertEquals(union(reads, PAYOUT_ACCOUNT_MANAGE), LegacyPartnerBundles.member(PartnerTeamRole.FINANCE));
        assertEquals(union(reads, SETTINGS_EDIT, PAYOUT_ACCOUNT_MANAGE, TEAM_INVITE, TEAM_ROLE_ASSIGN, TEAM_SUSPEND,
            TEAM_REMOVE, TEAM_OWNER_MANAGE), LegacyPartnerBundles.member(PartnerTeamRole.OWNER));

        Set<PartnerPermission> settingsService = Set.of(WORKSPACE_ACCESS, SETTINGS_EDIT, PAYOUT_ACCOUNT_VIEW,
            PAYOUT_ACCOUNT_MANAGE, TEAM_VIEW, TEAM_INVITE, TEAM_ROLE_ASSIGN, TEAM_SUSPEND, TEAM_REMOVE, TEAM_OWNER_MANAGE);
        for (PartnerTeamRole role : PartnerTeamRole.values()) {
            assertTrue(settingsService.containsAll(LegacyPartnerBundles.member(role)),
                role + " must not hold an operational permission in R1");
        }
    }

    private static PartnerAccessContext ctx(PartnerGrant... grants) {
        PartnerProfile company = new PartnerProfile();
        company.setId(COMPANY);
        return new PartnerAccessContext(company, 1L, false, List.of(grants));
    }

    private static Set<PartnerPermission> union(Set<PartnerPermission> base, PartnerPermission... more) {
        EnumSet<PartnerPermission> all = EnumSet.copyOf(base);
        all.addAll(List.of(more));
        return all;
    }
}
