package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.AdminPermission;
import com.example.planyourtrip.security.rbac.AdminProfile;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Instant;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static com.example.planyourtrip.security.rbac.AdminPermission.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * RBAC R6 — admin profiles (RBAC V1.1 §7, §10.2, §21.4, §22.5, §25.4, §28 M-5): the 11 bundles, deny by default,
 * per-handler enforcement for every profile, the A15/A46 value-dependent mapping, guest masking without A05,
 * read-access audit, access management (AP-1…AP-3) with step-up and the last-platform-owner rule.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RbacAdminProfilesTest {

    private static final String PASSWORD = "R6-admin-profiles-Pw1";
    private static final AtomicInteger counter = new AtomicInteger();

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository users;
    @Autowired PasswordEncoder encoder;
    @Autowired AdminProfileAssignmentRepository assignments;
    @Autowired JdbcTemplate jdbc;
    @Autowired BookingRepository bookings;
    @Autowired PlaceRepository places;
    @Autowired JwtService jwt;

    // ── Bundles (§10.2) ─────────────────────────────────────────────────────

    @Test
    void theElevenBundlesMatchTheMatrixTotals() {
        Map<AdminProfile, Integer> totals = Map.ofEntries(
            Map.entry(AdminProfile.PLATFORM_OWNER, 46), Map.entry(AdminProfile.PARTNER_OPERATIONS, 9),
            Map.entry(AdminProfile.CONTENT_CATALOGUE, 10), Map.entry(AdminProfile.BOOKING_SUPPORT, 11),
            Map.entry(AdminProfile.FINANCE_OPERATIONS, 14), Map.entry(AdminProfile.GROWTH_MARKETING, 8),
            Map.entry(AdminProfile.TRUST_SAFETY, 14), Map.entry(AdminProfile.REVIEW_MODERATION, 4),
            Map.entry(AdminProfile.ANALYTICS, 2), Map.entry(AdminProfile.LOCATION_CATALOGUE, 3),
            Map.entry(AdminProfile.TECH_SUPPORT, 6));
        assertEquals(11, AdminProfile.values().length);
        for (AdminProfile profile : AdminProfile.values()) {
            assertEquals(totals.get(profile), profile.permissions().size(), profile.name());
            assertTrue(profile.permissions().contains(CONSOLE_ACCESS), profile + " holds A01");
        }
        assertEquals(EnumSet.allOf(AdminPermission.class), Set.copyOf(AdminProfile.PLATFORM_OWNER.permissions()));
        // §7 "sole holder": access management, moving properties, broadcast
        for (AdminPermission sole : List.of(ACCESS_MANAGE, PLACE_OWNER_ASSIGN, NOTIFICATION_BROADCAST)) {
            List<AdminProfile> holders = EnumSet.allOf(AdminProfile.class).stream()
                .filter(p -> p.permissions().contains(sole)).toList();
            assertEquals(List.of(AdminProfile.PLATFORM_OWNER), holders, sole.key());
        }
        // §31 Q11: discount design and money movement never sit in one profile
        assertFalse(AdminProfile.GROWTH_MARKETING.permissions().contains(GIFT_CARD_VALUE_MANAGE));
        assertFalse(AdminProfile.FINANCE_OPERATIONS.permissions().contains(PROMOTION_MANAGE));
        // §31 Q14: ANALYTICS reads aggregates only
        assertEquals(Set.of(CONSOLE_ACCESS, ANALYTICS_VIEW), AdminProfile.ANALYTICS.permissions());
        assertEquals(Set.of(), AdminProfile.permissionsOf(List.of()), "no profile, no permission");
    }

    // ── Deny by default, backfill, access document ──────────────────────────

    @Test
    void theSeededAdministratorIsAPlatformOwnerAndSeesTheActivePermissions() throws Exception {
        JsonNode doc = json(send(get("/api/admin/me/access"), login("admin@planyourtrip.com", "admin123456"), 200));
        assertEquals(List.of("PLATFORM_OWNER"), strings(doc.get("profiles")));
        List<String> permissions = strings(doc.get("permissions"));
        assertEquals(43, permissions.size(), "46 minus the reserved A07, A11, A12");
        assertTrue(permissions.contains("admin.access.manage"));
        assertFalse(permissions.contains("admin.customer.account.manage"), "reserved keys are not listed");
        assertNotNull(doc.get("stepUp").get("freshUntil").asText(null));
    }

    @Test
    void anAdministratorWithoutProfilesHoldsNothing() throws Exception {
        String token = adminWith();
        send(get("/api/admin/me/access"), token, 403);
        send(get("/api/admin/places"), token, 403);
        send(get("/api/admin/analytics/overview"), token, 403);
        send(get("/api/admin/access/admins"), token, 403);
    }

    @Test
    void nonAdministratorsNeverReachTheAdminApi() throws Exception {
        String traveller = login("demo@planyourtrip.com", "demo123456");
        send(get("/api/admin/me/access"), traveller, 403);
        mvc.perform(get("/api/admin/me/access")).andExpect(r -> assertEquals(401, r.getResponse().getStatus()));
    }

    // ── Per-profile enforcement (table-driven, direct API requests) ─────────

    @Test
    void everyProfileReachesExactlyItsEndpointFamilies() throws Exception {
        record Probe(String path, AdminPermission permission) {}
        List<Probe> probes = List.of(
            new Probe("/api/admin/activity-logs", AUDIT_LOG_VIEW),
            new Probe("/api/admin/analytics/overview", ANALYTICS_VIEW),
            new Probe("/api/admin/partners", PARTNER_VIEW),
            new Probe("/api/admin/places", PLACE_VIEW),
            new Probe("/api/admin/bookings", BOOKING_VIEW),
            new Probe("/api/admin/conversations", CONVERSATION_VIEW),
            new Probe("/api/admin/payments", PAYMENT_VIEW),
            new Probe("/api/admin/invoices", INVOICE_VIEW),
            new Probe("/api/admin/reviews", REVIEW_VIEW),
            new Probe("/api/admin/promotions", PROMOTION_MANAGE),
            new Probe("/api/admin/coupon-definitions", COUPON_MANAGE),
            new Probe("/api/admin/gift-card-products", GIFT_CARD_CATALOG_MANAGE),
            new Probe("/api/admin/gift-cards", GIFT_CARD_VALUE_MANAGE),
            new Probe("/api/admin/personalization-rules", PERSONALIZATION_MANAGE),
            new Probe("/api/admin/notifications", NOTIFICATION_BROADCAST),
            new Probe("/api/admin/access/admins", ACCESS_MANAGE));
        for (AdminProfile profile : AdminProfile.values()) {
            String token = adminWith(profile);
            for (Probe probe : probes) {
                int status = status(get(probe.path()), token);
                if (profile.permissions().contains(probe.permission())) {
                    assertNotEquals(403, status, profile + " must reach " + probe.path());
                } else {
                    assertEquals(403, status, profile + " must not reach " + probe.path());
                }
            }
        }
    }

    @Test
    void profilesCombineAsAUnion() throws Exception {
        String token = adminWith(AdminProfile.ANALYTICS, AdminProfile.REVIEW_MODERATION);
        send(get("/api/admin/analytics/overview"), token, 200);
        send(get("/api/admin/reviews"), token, 200);
        send(get("/api/admin/bookings"), token, 403);
    }

    // ── A15 / A46 value-dependent mapping (§9.2, §25.5) ─────────────────────

    @Test
    void publishingNeedsA46WhileOtherStatusesNeedA15() throws Exception {
        Place place = places.findAll().stream().filter(p -> p.getStatus() == PlaceStatus.PUBLISHED)
            .findFirst().orElseThrow();
        String trustSafety = adminWith(AdminProfile.TRUST_SAFETY);   // A15, not A46
        String content = adminWith(AdminProfile.CONTENT_CATALOGUE);  // A15 and A46
        String path = "/api/admin/places/" + place.getId() + "/status";
        try {
            send(json(patch(path), "{\"status\":\"HIDDEN\"}"), trustSafety, 200);
            MvcResult refused = mvc.perform(auth(json(patch(path), "{\"status\":\"PUBLISHED\"}"), trustSafety))
                .andReturn();
            assertEquals(403, refused.getResponse().getStatus());
            assertEquals("PERMISSION_DENIED", json(refused).get("code").asText());
            assertEquals(PlaceStatus.HIDDEN, places.findById(place.getId()).orElseThrow().getStatus());
            send(json(patch(path), "{\"status\":\"PUBLISHED\"}"), content, 200);
        } finally {
            Place restored = places.findById(place.getId()).orElseThrow();
            if (restored.getStatus() != PlaceStatus.PUBLISHED) {
                send(json(patch(path), "{\"status\":\"PUBLISHED\"}"), content, 200);
            }
        }
    }

    // ── Guest masking without A05 (§21.4, AP-6) ─────────────────────────────

    @Test
    void guestIdentityIsMaskedForAdministratorsWithoutCustomerView() throws Exception {
        Booking booking = bookings.findAll().stream().findFirst().orElseThrow();
        User guest = users.findById(booking.getUser().getId()).orElseThrow();
        String path = "/api/admin/bookings/" + booking.getId();

        JsonNode masked = json(send(get(path), adminWith(AdminProfile.TECH_SUPPORT), 200));
        assertTrue(masked.get("userEmail").isNull(), "contact omitted");
        String fullName = guest.getFullName();
        assertNotEquals(fullName, masked.get("userFullName").asText());
        assertTrue(masked.get("userFullName").asText().matches("([A-Z]\\.)( [A-Z]\\.)*"), "name masked");
        assertEquals(Set.of("userFullName:MASKED", "userEmail:OMITTED"), redacted(masked));

        JsonNode partnerOps = json(send(get(path), adminWith(AdminProfile.PARTNER_OPERATIONS), 200));
        assertTrue(partnerOps.get("userEmail").isNull());

        JsonNode support = json(send(get(path), adminWith(AdminProfile.BOOKING_SUPPORT), 200));
        assertEquals(fullName, support.get("userFullName").asText());
        assertEquals(guest.getEmail(), support.get("userEmail").asText());
        assertTrue(support.get("redacted").isNull(), "nothing withheld from A05 holders");
    }

    @Test
    void theGuestFilterIsNoIdentityOracleWithoutCustomerView() throws Exception {
        Booking booking = bookings.findAll().stream().findFirst().orElseThrow();
        User guest = users.findById(booking.getUser().getId()).orElseThrow();
        String matching = guest.getEmail().substring(0, 3);           // a prefix of the real guest's email
        String missing = "zz-no-guest-" + UUID.randomUUID();           // matches nobody
        int everything = json(send(get("/api/admin/bookings?size=100"), adminWith(AdminProfile.BOOKING_SUPPORT), 200))
            .get("totalElements").asInt();

        for (AdminProfile masked : List.of(AdminProfile.TECH_SUPPORT, AdminProfile.PARTNER_OPERATIONS)) {
            String token = adminWith(masked);
            assertTrue(masked.permissions().contains(BOOKING_VIEW) && !masked.permissions().contains(CUSTOMER_VIEW));

            // matching and non-matching probes get the same refusal: no count, no rows, no echo
            MvcResult hit = send(get("/api/admin/bookings").param("guest", matching), token, 403);
            MvcResult miss = send(get("/api/admin/bookings").param("guest", missing), token, 403);
            MvcResult narrowed = send(get("/api/admin/bookings").param("guest", matching)
                .param("bookingCode", booking.getBookingCode()), token, 403);
            for (MvcResult refused : List.of(hit, miss, narrowed)) {
                JsonNode body = json(refused);
                assertEquals("PERMISSION_DENIED", body.get("code").asText(), masked.name());
                assertEquals("Access denied", body.get("message").asText());
                assertEquals("/api/admin/bookings", body.get("path").asText());
                assertNull(body.get("totalElements"));
                String raw = refused.getResponse().getContentAsString();
                assertFalse(raw.contains(matching) || raw.contains(missing), "the probe is not echoed");
            }
            assertEquals(json(hit).get("message"), json(miss).get("message"));

            // the list itself stays available, and carries no identity to begin with
            MvcResult list = send(get("/api/admin/bookings?size=100"), token, 200);
            assertEquals(everything, json(list).get("totalElements").asInt(), masked.name());
            String rows = list.getResponse().getContentAsString();
            assertFalse(rows.contains(guest.getEmail()), "no guest email in list rows");
            assertFalse(rows.contains(guest.getFullName()), "no guest name in list rows");
            assertFalse(json(list).get("content").get(0).has("userEmail"));
            // a blank filter is no filter, exactly as for every other caller
            assertEquals(everything, json(send(get("/api/admin/bookings?size=100").param("guest", "  "), token, 200))
                .get("totalElements").asInt());
        }

        // A05 holders keep the search (narrowed by code: the seeded guest has many bookings in a full run)
        String support = adminWith(AdminProfile.BOOKING_SUPPORT);
        JsonNode found = json(send(get("/api/admin/bookings?size=100").param("guest", guest.getEmail())
            .param("bookingCode", booking.getBookingCode()), support, 200));
        assertTrue(found.get("totalElements").asInt() >= 1);
        boolean listed = false;
        for (JsonNode row : found.get("content")) listed |= row.get("id").asLong() == booking.getId();
        assertTrue(listed, "the guest's booking is found by an A05 holder");
        assertEquals(0, json(send(get("/api/admin/bookings").param("guest", missing), support, 200))
            .get("totalElements").asInt());
    }

    // ── Read-access audit (§22.5) ───────────────────────────────────────────

    @Test
    void sensitiveReadsAreAuditedWithIdentifiersOnly() throws Exception {
        User customer = users.findByEmail("demo@planyourtrip.com").orElseThrow();
        String support = adminWith(AdminProfile.BOOKING_SUPPORT);
        Long actor = idOf(support);

        send(get("/api/admin/users/" + customer.getId() + "/travel-wallet"), support, 200);
        Audit wallet = latest(actor, "TRAVEL_WALLET_VIEW");
        assertEquals("USER", wallet.targetType());
        assertEquals(customer.getId(), wallet.targetId());

        send(get("/api/admin/conversations?status=OPEN&userId=" + customer.getId() + "&q=ignored"), support, 200);
        Audit list = latest(actor, "CONVERSATION_VIEW");
        assertEquals("CONVERSATION", list.targetType());
        assertNull(list.targetId(), "one row per list request, not one per conversation");
        assertEquals("Listed conversations (status=OPEN, userId=" + customer.getId() + ")", list.description());

        // the row is written before the read runs, so even a miss is on record
        status(get("/api/admin/conversations/987654321"), support);
        Audit detail = latest(actor, "CONVERSATION_VIEW");
        assertEquals(987654321L, detail.targetId());

        // a refused read writes no read-audit row (signing in writes ADMIN_LOGIN_SUCCESS, which is not counted)
        String analytics = adminWith(AdminProfile.ANALYTICS);
        send(get("/api/admin/users/" + customer.getId() + "/travel-wallet"), analytics, 403);
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM admin_activity_logs WHERE actor_user_id = ? "
            + "AND action = 'TRAVEL_WALLET_VIEW'", Integer.class, idOf(analytics)));
    }

    // ── Access management (§25.4, AP-1…AP-3) ────────────────────────────────

    @Test
    void aPlatformOwnerGrantsAndRevokesProfilesWhichApplyOnTheNextRequest() throws Exception {
        String owner = adminWith(AdminProfile.PLATFORM_OWNER);
        Long ownerId = idOf(owner);
        String target = adminWith();
        Long targetId = idOf(target);
        send(get("/api/admin/reviews"), target, 403);

        JsonNode granted = json(send(json(put("/api/admin/access/admins/" + targetId + "/profiles"),
            "{\"profiles\":[\"REVIEW_MODERATION\"],\"reason\":\"Queue cover\"}"), owner, 200));
        assertEquals(List.of("REVIEW_MODERATION"), strings(granted.get("profiles")));
        send(get("/api/admin/reviews"), target, 200);
        Audit grant = latest(ownerId, "ADMIN_PROFILE_GRANT");
        assertEquals(targetId, grant.targetId());
        assertEquals("REVIEW_MODERATION", grant.afterState());
        assertEquals("Granted admin profile REVIEW_MODERATION: Queue cover", grant.description());

        JsonNode listed = json(send(get("/api/admin/access/admins"), owner, 200));
        JsonNode row = find(listed, targetId);
        assertEquals(List.of("REVIEW_MODERATION"), strings(row.get("profiles")));
        assertTrue(find(listed, ownerId).get("self").asBoolean());

        send(json(put("/api/admin/access/admins/" + targetId + "/profiles"), "{\"profiles\":[]}"), owner, 200);
        send(get("/api/admin/reviews"), target, 403);
        assertEquals("REVIEW_MODERATION", latest(ownerId, "ADMIN_PROFILE_REVOKE").beforeState());
        assertTrue(assignments.findActiveProfiles(targetId).isEmpty());
        assertEquals(1, assignments.findAll().stream()
            .filter(a -> a.getUser().getId().equals(targetId) && !a.isActive()).count(), "kept as history");
    }

    @Test
    void onlyPlatformOwnersManageAccess() throws Exception {
        Long targetId = idOf(adminWith());
        for (AdminProfile profile : EnumSet.complementOf(EnumSet.of(AdminProfile.PLATFORM_OWNER))) {
            String token = adminWith(profile);
            send(json(put("/api/admin/access/admins/" + targetId + "/profiles"),
                "{\"profiles\":[\"PLATFORM_OWNER\"]}"), token, 403);
        }
        assertTrue(assignments.findActiveProfiles(targetId).isEmpty(), "no escalation");
    }

    @Test
    void nobodyChangesTheirOwnProfiles() throws Exception {
        String owner = adminWith(AdminProfile.PLATFORM_OWNER);
        MvcResult self = mvc.perform(auth(json(put("/api/admin/access/admins/" + idOf(owner) + "/profiles"),
            "{\"profiles\":[\"PLATFORM_OWNER\",\"ANALYTICS\"]}"), owner)).andReturn();
        assertEquals(403, self.getResponse().getStatus());
        assertEquals("SELF_MODIFICATION_FORBIDDEN", json(self).get("code").asText());
    }

    @Test
    void profilesAreForAdministratorsOnlyAndMustBeKnown() throws Exception {
        String owner = adminWith(AdminProfile.PLATFORM_OWNER);
        User traveller = users.findByEmail("demo@planyourtrip.com").orElseThrow();
        send(json(put("/api/admin/access/admins/" + traveller.getId() + "/profiles"),
            "{\"profiles\":[\"ANALYTICS\"]}"), owner, 404);
        assertTrue(assignments.findActiveProfiles(traveller.getId()).isEmpty());

        Long targetId = idOf(adminWith());
        for (String body : List.of("{\"profiles\":[\"SUPER_ADMIN\"]}", "{\"profiles\":[\"ANALYTICS\",\"ANALYTICS\"]}",
                "{\"profiles\":[\"analytics\"]}", "{}")) {
            send(json(put("/api/admin/access/admins/" + targetId + "/profiles"), body), owner, 400);
        }
        send(json(put("/api/admin/access/admins/" + targetId + "/profiles"),
            "{\"profiles\":[\"ANALYTICS\"],\"reason\":\"password=hunter2\"}"), owner, 400);
        assertTrue(assignments.findActiveProfiles(targetId).isEmpty());
    }

    @Test
    void changingProfilesNeedsAFreshSession() throws Exception {
        String owner = adminWith(AdminProfile.PLATFORM_OWNER);
        Long targetId = idOf(adminWith());
        User ownerUser = users.findById(idOf(owner)).orElseThrow();
        String stale = jwt.createToken(ownerUser.getId(), ownerUser.getEmail(), ownerUser.getTokenVersion(),
            Instant.now().minus(StepUpPolicy.FRESHNESS).minusSeconds(60));
        MvcResult refused = mvc.perform(auth(json(put("/api/admin/access/admins/" + targetId + "/profiles"),
            "{\"profiles\":[\"ANALYTICS\"]}"), stale)).andReturn();
        assertEquals(403, refused.getResponse().getStatus());
        assertEquals("STEP_UP_REQUIRED", json(refused).get("code").asText());
        assertTrue(assignments.findActiveProfiles(targetId).isEmpty());
        // reading needs no freshness
        send(get("/api/admin/access/admins"), stale, 200);
    }

    @Test
    void movingAPropertyBetweenCompaniesIsPlatformOwnerOnlyAndNeedsAFreshSession() throws Exception {
        // A16 (AP-5 interim): PLATFORM_OWNER only and step-up until dual control exists. The partner profile id
        // does not exist, so a request that passes both gates changes nothing.
        Place place = places.findAll().stream().findFirst().orElseThrow();
        String path = "/api/admin/hotels/" + place.getId() + "/assign-owner";
        String body = "{\"partnerProfileId\":987654321}";

        MvcResult denied = mvc.perform(auth(json(post(path), body), adminWith(AdminProfile.PARTNER_OPERATIONS)))
            .andReturn();
        assertEquals(403, denied.getResponse().getStatus());
        assertEquals("PERMISSION_DENIED", json(denied).get("code").asText());

        String owner = adminWith(AdminProfile.PLATFORM_OWNER);
        User ownerUser = users.findById(idOf(owner)).orElseThrow();
        String stale = jwt.createToken(ownerUser.getId(), ownerUser.getEmail(), ownerUser.getTokenVersion(),
            Instant.now().minus(StepUpPolicy.FRESHNESS).minusSeconds(60));
        MvcResult notFresh = mvc.perform(auth(json(post(path), body), stale)).andReturn();
        assertEquals(403, notFresh.getResponse().getStatus());
        assertEquals("STEP_UP_REQUIRED", json(notFresh).get("code").asText());

        int fresh = status(json(post(path), body), owner);
        assertNotEquals(403, fresh, "a fresh platform owner passes both gates and reaches the handler");
    }

    @Test
    void twoOwnersRevokingEachOtherAtOnceLeaveOneOwner() throws Exception {
        String a = adminWith(AdminProfile.PLATFORM_OWNER);
        String b = adminWith(AdminProfile.PLATFORM_OWNER);
        Long aId = idOf(a);
        Long bId = idOf(b);
        List<Integer> results = RbacTeamTestSupport.concurrently(
            () -> status(json(put("/api/admin/access/admins/" + bId + "/profiles"), "{\"profiles\":[]}"), a),
            () -> status(json(put("/api/admin/access/admins/" + aId + "/profiles"), "{\"profiles\":[]}"), b));
        assertEquals(1, results.stream().filter(s -> s == 200).count(), "exactly one revocation wins: " + results);
        assertEquals(1, results.stream().filter(s -> s == 403).count(), "the loser is no longer an owner: " + results);
        boolean aOwner = assignments.findActiveProfiles(aId).contains(AdminProfile.PLATFORM_OWNER);
        boolean bOwner = assignments.findActiveProfiles(bId).contains(AdminProfile.PLATFORM_OWNER);
        assertTrue(aOwner ^ bOwner, "exactly one of them keeps PLATFORM_OWNER");
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    /** A fresh ADMIN account holding exactly {@code profiles} (a test fixture, granted directly), logged in. */
    private String adminWith(AdminProfile... profiles) throws Exception {
        User u = new User();
        u.setFullName("R6 Admin " + counter.incrementAndGet());
        u.setEmail("r6-admin-" + counter.get() + "-" + UUID.randomUUID().toString().substring(0, 8) + "@test.com");
        u.setPasswordHash(encoder.encode(PASSWORD));
        u.setRole("ADMIN");
        u.setEmailVerifiedAt(Instant.now());
        users.save(u);
        for (AdminProfile profile : profiles) {
            assignments.save(AdminProfileAssignment.systemGrant(u, profile, Instant.now()));
        }
        return login(u.getEmail(), PASSWORD);
    }

    private String login(String email, String password) throws Exception {
        MvcResult r = mvc.perform(json(post("/api/auth/login"),
            "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}")).andReturn();
        assertEquals(200, r.getResponse().getStatus(), r.getResponse().getContentAsString());
        return json(r).get("token").asText();
    }

    private Long idOf(String token) {
        return jwt.parse(token).orElseThrow().userId();
    }

    private MvcResult send(MockHttpServletRequestBuilder request, String token, int expected) throws Exception {
        MvcResult r = mvc.perform(auth(request, token)).andReturn();
        assertEquals(expected, r.getResponse().getStatus(), r.getRequest().getMethod() + " "
            + r.getRequest().getRequestURI() + " -> " + r.getResponse().getContentAsString());
        return r;
    }

    private int status(MockHttpServletRequestBuilder request, String token) throws Exception {
        return mvc.perform(auth(request, token)).andReturn().getResponse().getStatus();
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request, String token) {
        return request.header("Authorization", "Bearer " + token);
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private JsonNode json(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString());
    }

    private static List<String> strings(JsonNode array) {
        List<String> out = new ArrayList<>();
        array.forEach(n -> out.add(n.asText()));
        return out;
    }

    private static Set<String> redacted(JsonNode booking) {
        Set<String> out = new java.util.HashSet<>();
        booking.get("redacted").forEach(r -> out.add(r.get("field").asText() + ":" + r.get("mode").asText()));
        return out;
    }

    private static JsonNode find(JsonNode admins, Long userId) {
        for (JsonNode n : admins) if (n.get("userId").asLong() == userId) return n;
        throw new AssertionError("administrator " + userId + " not listed");
    }

    /** One admin audit row, read straight from the append-only table (its repository has no list read). */
    private record Audit(String targetType, Long targetId, String description, String beforeState,
                         String afterState) {}

    private Audit latest(Long actorUserId, String action) {
        List<Audit> rows = jdbc.query("SELECT target_type, target_id, description, before_state, after_state "
                + "FROM admin_activity_logs WHERE actor_user_id = ? AND action = ? ORDER BY id DESC",
            (rs, i) -> new Audit(rs.getString(1), rs.getObject(2) == null ? null : rs.getLong(2), rs.getString(3),
                rs.getString(4), rs.getString(5)),
            actorUserId, action);
        assertFalse(rows.isEmpty(), "no " + action + " row for " + actorUserId);
        return rows.get(0);
    }
}
