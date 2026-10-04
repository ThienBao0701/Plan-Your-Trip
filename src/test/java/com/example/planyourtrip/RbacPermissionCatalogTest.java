package com.example.planyourtrip;

import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.Permission;
import com.example.planyourtrip.security.rbac.ScopeType;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.IntStream;
import java.util.stream.Stream;

import static org.junit.jupiter.api.Assertions.*;

/**
 * R1 — the permission catalogue in code is exactly the frozen RBAC V1.1 catalogue (§9): 54 partner and
 * 46 admin permissions, 100 in total, with the reserved entries and scope floors the document freezes.
 * A drift between code and design fails here before it can reach an endpoint.
 */
class RbacPermissionCatalogTest {

    @Test
    void theCatalogueHasExactlyOneHundredPermissions() {
        assertEquals(54, PartnerPermission.values().length);
        assertEquals(46, AdminPermission.values().length);
        assertEquals(100, allPermissions().count());
    }

    @Test
    void identifiersAreContiguousUniqueAndNeverReused() {
        Set<String> partnerIds = ids(PartnerPermission.values());
        Set<String> adminIds = ids(AdminPermission.values());
        assertEquals(IntStream.rangeClosed(1, 54).mapToObj(i -> String.format("P%02d", i)).collect(Collectors.toSet()),
            partnerIds);
        assertEquals(IntStream.rangeClosed(1, 46).mapToObj(i -> String.format("A%02d", i)).collect(Collectors.toSet()),
            adminIds);
    }

    @Test
    void keysAreUniqueAndCarryTheirNamespace() {
        assertEquals(100, allPermissions().map(Permission::key).distinct().count());
        for (PartnerPermission p : PartnerPermission.values()) {
            assertTrue(p.key().startsWith("partner."), p.key());
            assertEquals(Permission.Namespace.PARTNER, p.namespace());
        }
        for (AdminPermission p : AdminPermission.values()) {
            assertTrue(p.key().startsWith("admin."), p.key());
            assertEquals(Permission.Namespace.ADMIN, p.namespace());
        }
    }

    @Test
    void reservedPermissionsAreExactlyTheFrozenTwelve() {
        assertEquals(Set.of("P06", "P13", "P19", "P20", "P22", "P41", "P46", "P47"),
            ids(Arrays.stream(PartnerPermission.values()).filter(Permission::reserved).toArray(Permission[]::new)));
        assertEquals(Set.of("A02", "A07", "A11", "A12"),
            ids(Arrays.stream(AdminPermission.values()).filter(Permission::reserved).toArray(Permission[]::new)));
    }

    @Test
    void scopeFloorsMatchTheDesign() {
        assertEquals(Set.of("P02", "P03", "P04", "P05", "P06", "P12", "P13", "P15", "P50", "P51", "P52", "P53"),
            idsWithFloor(ScopeType.COMPANY));
        assertEquals(Set.of("P01", "P21", "P46", "P47"), idsWithFloor(ScopeType.UNIT));
        assertEquals(54 - 12 - 4, idsWithFloor(ScopeType.PROPERTY).size());
    }

    @Test
    void floorsAdmitOnlyEqualOrWiderGrants() {
        assertTrue(ScopeType.COMPANY.admits(ScopeType.COMPANY));
        assertFalse(ScopeType.COMPANY.admits(ScopeType.PROPERTY));
        assertFalse(ScopeType.COMPANY.admits(ScopeType.UNIT));
        assertTrue(ScopeType.PROPERTY.admits(ScopeType.COMPANY));
        assertTrue(ScopeType.PROPERTY.admits(ScopeType.PROPERTY));
        assertFalse(ScopeType.PROPERTY.admits(ScopeType.UNIT));
        assertTrue(ScopeType.UNIT.admits(ScopeType.UNIT));
        assertFalse(ScopeType.UNIT.admits(null));
    }

    @Test
    void unknownKeysFailClosed() {
        assertTrue(Permission.fromKey("partner.nonexistent.view").isEmpty());
        assertTrue(Permission.fromKey("PARTNER.PROPERTY.VIEW").isEmpty());
        assertTrue(Permission.fromKey(" partner.property.view").isEmpty());
        assertTrue(Permission.fromKey("").isEmpty());
        assertTrue(Permission.fromKey(null).isEmpty());
        assertTrue(PartnerPermission.fromKey(null).isEmpty());
        assertTrue(AdminPermission.fromKey(null).isEmpty());
    }

    @Test
    void namespacesNeverResolveIntoEachOther() {
        assertTrue(PartnerPermission.fromKey("admin.place.view").isEmpty());
        assertTrue(AdminPermission.fromKey("partner.property.view").isEmpty());
        assertEquals(PartnerPermission.PROPERTY_VIEW, Permission.fromKey("partner.property.view").orElseThrow());
        assertEquals(AdminPermission.PLACE_VIEW, Permission.fromKey("admin.place.view").orElseThrow());
    }

    @Test
    void revisionOneOneAdditionsCarryTheirFrozenIdentifiers() {
        assertEquals("P54", PartnerPermission.BOOKING_GUEST_IDENTITY_VIEW.id());
        assertEquals("partner.booking.guest_identity.view", PartnerPermission.BOOKING_GUEST_IDENTITY_VIEW.key());
        assertEquals("A46", AdminPermission.PLACE_PUBLISH.id());
        assertEquals("admin.place.publish", AdminPermission.PLACE_PUBLISH.key());
    }

    private static Stream<Permission> allPermissions() {
        return Stream.concat(Arrays.stream(PartnerPermission.values()), Arrays.stream(AdminPermission.values()));
    }

    private static Set<String> ids(Permission[] permissions) {
        Set<String> ids = Arrays.stream(permissions).map(Permission::id).collect(Collectors.toSet());
        assertEquals(permissions.length, ids.size(), "duplicate identifier");
        return ids;
    }

    private static Set<String> idsWithFloor(ScopeType floor) {
        return Arrays.stream(PartnerPermission.values()).filter(p -> p.floor() == floor)
            .map(PartnerPermission::id).collect(Collectors.toSet());
    }
}
