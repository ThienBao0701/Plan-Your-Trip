package com.example.planyourtrip;

import com.example.planyourtrip.model.AdminProfileAssignment;
import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.model.BusinessType;
import com.example.planyourtrip.model.Category;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerVerificationStatus;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.UnitType;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdminProfileAssignmentRepository;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.rbac.AdminProfile;
import com.example.planyourtrip.service.AdminActivityLogService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/**
 * RBAC R6 — A16 dual control under real SQL Server 2022 locking (RBAC V1.1 §22.6).
 *
 * <p><b>Disabled by default</b>: runs only with {@code DB05_SQLSERVER_VERIFY=true} under the {@code prod} profile
 * against a disposable SQL Server database, exactly like {@link SqlServerProdChainVerificationTest} (same
 * environment variables). It never runs against H2.
 *
 * <p>The races are made deterministic, without sleeps: the first request is paused inside its own transaction at its
 * final audit write — after every lock of the operation is taken and the change is made, before the commit. The
 * competing request is then started, and the test waits until SQL Server itself reports that request's session as
 * blocked by another session ({@code sys.dm_exec_requests.blocking_session_id}). Only then is the first request
 * released. So each scenario proves a real lock wait in SQL Server, then checks the committed outcome with SQL.
 * Each scenario builds its own companies, place and platform owners.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("prod")
@EnabledIfEnvironmentVariable(named = "DB05_SQLSERVER_VERIFY", matches = "(?i)true")
class SqlServerDualControlConcurrencyTest {

    private static final String PASSWORD = "R6-sqlserver-concurrency-Pw1";
    private static final String REQUESTS = "/api/admin/dual-control/requests";
    private static final Duration WAIT = Duration.ofSeconds(60);

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired JdbcTemplate jdbc;
    @Autowired PasswordEncoder encoder;
    @Autowired UserRepository users;
    @Autowired AdminProfileAssignmentRepository assignments;
    @Autowired PartnerProfileRepository partnerProfiles;
    @Autowired PlaceRepository places;
    @Autowired CategoryRepository categories;
    @Autowired AdministrativeUnitRepository units;
    /** Spied so a test can hold a transaction open at a known point, or make it fail there. */
    @MockitoSpyBean AdminActivityLogService audit;

    private final ExecutorService pool = Executors.newFixedThreadPool(4);

    record Admin(String token, Long id) {}

    @AfterEach
    void cleanUp() {
        Mockito.reset(audit);
        pool.shutdownNow();
    }

    // ── 1 · Two approvals of one request ────────────────────────────────────

    @Test
    void twoSimultaneousApprovalsExecuteTheMoveExactlyOnce() throws Exception {
        Fixture f = fixture();
        long id = submit(f.requester(), f.place(), f.b());
        Admin first = owner(), second = owner();

        Gate gate = holdAt("DUAL_CONTROL_APPROVE");
        Future<Integer> a = pool.submit(() -> status(post(REQUESTS + "/" + id + "/approve"), first.token()));
        gate.awaitHeld();
        Future<Integer> b = pool.submit(() -> status(post(REQUESTS + "/" + id + "/approve"), second.token()));
        long blocked = awaitBlockedSession();
        gate.release();

        assertEquals(200, a.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals(409, b.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertTrue(blocked > 0, "the second approval waited on SQL Server's lock");
        assertEquals("APPROVED", statusOf(id));
        assertEquals(first.id(), jdbc.queryForObject(
            "SELECT approved_by FROM admin_dual_control_requests WHERE id = ?", Long.class, id));
        assertEquals(f.b(), ownerOf(f.place()));
        assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()));
        assertEquals(1, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));
        assertEquals(1, notificationsAbout(f.place()), "one 'Hotel assigned' notification");
    }

    @Test
    void freeRunningApprovalRacesNeverExecuteTwiceOrDeadlock() throws Exception {
        for (int round = 0; round < 5; round++) {
            Fixture f = fixture();
            long id = submit(f.requester(), f.place(), f.b());
            Admin first = owner(), second = owner();
            List<Integer> results = race(
                () -> status(post(REQUESTS + "/" + id + "/approve"), first.token()),
                () -> status(post(REQUESTS + "/" + id + "/approve"), second.token()));
            assertEquals(List.of(200, 409), results.stream().sorted().toList(), "round " + round + ": " + results);
            assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()), "round " + round);
            assertEquals(f.b(), ownerOf(f.place()));
        }
    }

    // ── 2 · Approval racing cancellation ────────────────────────────────────

    @Test
    void anApprovalHoldingTheLockWinsOverTheRequestersCancellation() throws Exception {
        Fixture f = fixture();
        long id = submit(f.requester(), f.place(), f.b());
        Admin approver = owner();

        Gate gate = holdAt("DUAL_CONTROL_APPROVE");
        Future<Integer> approve = pool.submit(() -> status(post(REQUESTS + "/" + id + "/approve"), approver.token()));
        gate.awaitHeld();
        Future<Integer> cancel = pool.submit(() -> status(post(REQUESTS + "/" + id + "/cancel"), f.requester().token()));
        awaitBlockedSession();
        gate.release();

        assertEquals(200, approve.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals(409, cancel.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals("APPROVED", statusOf(id));
        assertEquals(f.b(), ownerOf(f.place()));
        assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()));
        assertEquals(0, audits("DUAL_CONTROL_CANCEL", "DUAL_CONTROL_REQUEST", id));
    }

    @Test
    void aCancellationHoldingTheLockWinsOverTheApproval() throws Exception {
        Fixture f = fixture();
        long id = submit(f.requester(), f.place(), f.b());
        Admin approver = owner();

        Gate gate = holdAt("DUAL_CONTROL_CANCEL");
        Future<Integer> cancel = pool.submit(() -> status(post(REQUESTS + "/" + id + "/cancel"), f.requester().token()));
        gate.awaitHeld();
        Future<Integer> approve = pool.submit(() -> status(post(REQUESTS + "/" + id + "/approve"), approver.token()));
        awaitBlockedSession();
        gate.release();

        assertEquals(200, cancel.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals(409, approve.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals("CANCELLED", statusOf(id));
        assertEquals(f.a(), ownerOf(f.place()), "nothing moved");
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()));
        assertEquals(0, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));
        assertEquals(1, audits("DUAL_CONTROL_CANCEL", "DUAL_CONTROL_REQUEST", id));
    }

    @Test
    void freeRunningApprovalVersusCancellationEndsInOneTerminalState() throws Exception {
        for (int round = 0; round < 5; round++) {
            Fixture f = fixture();
            long id = submit(f.requester(), f.place(), f.b());
            Admin approver = owner();
            List<Integer> results = race(
                () -> status(post(REQUESTS + "/" + id + "/approve"), approver.token()),
                () -> status(post(REQUESTS + "/" + id + "/cancel"), f.requester().token()));
            assertEquals(List.of(200, 409), results.stream().sorted().toList(), "round " + round + ": " + results);
            String status = statusOf(id);
            assertTrue(status.equals("APPROVED") || status.equals("CANCELLED"), status);
            assertEquals(status.equals("APPROVED") ? 1 : 0, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()));
            assertEquals(status.equals("APPROVED") ? f.b() : f.a(), ownerOf(f.place()));
        }
    }

    // ── 3 · Duplicate submissions ───────────────────────────────────────────

    @Test
    void concurrentSubmissionsLeaveExactlyOneOpenRequest() throws Exception {
        Fixture f = fixture();
        Admin other = owner();
        String body = "{\"partnerProfileId\":" + f.b() + "}";

        Gate gate = holdAt("DUAL_CONTROL_REQUEST");
        Future<Integer> first = pool.submit(() -> status(json(post(assign(f.place())), body), f.requester().token()));
        gate.awaitHeld();
        Future<Integer> second = pool.submit(() -> status(json(post(assign(f.place())), body), other.token()));
        awaitBlockedSession();
        gate.release();

        assertEquals(202, first.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals(409, second.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM admin_dual_control_requests WHERE target_id = ? "
            + "AND status = 'PENDING' AND live_key = 0", Integer.class, f.place()));
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM admin_dual_control_requests WHERE target_id = ?",
            Integer.class, f.place()));

        // and without any pause, racing submissions still leave one open request
        Fixture g = fixture();
        List<Integer> results = race(
            () -> status(json(post(assign(g.place())), "{\"partnerProfileId\":" + g.b() + "}"), g.requester().token()),
            () -> status(json(post(assign(g.place())), "{\"partnerProfileId\":" + g.b() + "}"), other.token()));
        assertEquals(List.of(202, 409), results.stream().sorted().toList(), results.toString());
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM admin_dual_control_requests WHERE target_id = ?",
            Integer.class, g.place()));
    }

    // ── 4 · A failed approval commits nothing ───────────────────────────────

    @Test
    void aFailedApprovalLeavesNoMoveAndNoSuccessAudit() throws Exception {
        Fixture f = fixture();
        long id = submit(f.requester(), f.place(), f.b());
        Admin approver = owner();
        long version = jdbc.queryForObject("SELECT version FROM admin_dual_control_requests WHERE id = ?",
            Long.class, id);

        // fail at the last write of the approval: after the move, HOTEL_ASSIGN_OWNER and the notification
        Mockito.doThrow(new IllegalStateException("audit store unavailable")).when(audit)
            .record(any(), eq("DUAL_CONTROL_APPROVE"), any(), any(), any(), any(), any());
        assertEquals(500, status(post(REQUESTS + "/" + id + "/approve"), approver.token()));
        Mockito.reset(audit);

        assertEquals("PENDING", statusOf(id));
        assertEquals(version, jdbc.queryForObject("SELECT version FROM admin_dual_control_requests WHERE id = ?",
            Long.class, id), "the request row was not changed");
        assertEquals(f.a(), ownerOf(f.place()), "the move rolled back");
        assertEquals(0, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()));
        assertEquals(0, audits("DUAL_CONTROL_APPROVE", "DUAL_CONTROL_REQUEST", id));
        assertEquals(0, notificationsAbout(f.place()), "the notification rolled back");

        // still pending: the retry executes once
        assertEquals(200, status(post(REQUESTS + "/" + id + "/approve"), approver.token()));
        assertEquals(f.b(), ownerOf(f.place()));
        assertEquals(1, audits("HOTEL_ASSIGN_OWNER", "PLACE", f.place()));
    }

    // ── Deterministic overlap ───────────────────────────────────────────────

    /** Pauses the first {@code record(action, …)} call — inside the caller's open transaction — until released. */
    private Gate holdAt(String action) {
        Gate gate = new Gate();
        Mockito.doAnswer(invocation -> {
            if (gate.claimed.compareAndSet(false, true)) {
                gate.held.countDown();
                if (!gate.released.await(WAIT.toSeconds(), TimeUnit.SECONDS)) {
                    throw new IllegalStateException("gate never released");
                }
            }
            return invocation.callRealMethod();
        }).when(audit).record(any(), eq(action), any(), any(), any(), any(), any());
        return gate;
    }

    static final class Gate {
        final AtomicBoolean claimed = new AtomicBoolean();
        final CountDownLatch held = new CountDownLatch(1);
        final CountDownLatch released = new CountDownLatch(1);

        void awaitHeld() throws InterruptedException {
            assertTrue(held.await(WAIT.toSeconds(), TimeUnit.SECONDS), "the first request never reached the gate");
        }

        void release() {
            released.countDown();
        }
    }

    /**
     * Waits until SQL Server reports a request in this database blocked by another session, and returns the blocked
     * session id. Polls the DMV; the condition, not a fixed delay, ends the wait.
     */
    private long awaitBlockedSession() throws InterruptedException {
        long deadline = System.nanoTime() + WAIT.toNanos();
        while (System.nanoTime() < deadline) {
            List<Long> blocked = jdbc.queryForList("SELECT session_id FROM sys.dm_exec_requests "
                + "WHERE blocking_session_id <> 0 AND database_id = DB_ID()", Long.class);
            if (!blocked.isEmpty()) return blocked.get(0);
            Thread.onSpinWait();
            TimeUnit.MILLISECONDS.sleep(20);
        }
        fail("no session was blocked: the competing request did not wait on a lock");
        return -1;
    }

    /** Starts every call at once behind a latch; no pause point. */
    @SafeVarargs
    private List<Integer> race(Callable<Integer>... calls) throws Exception {
        CountDownLatch start = new CountDownLatch(1);
        List<Future<Integer>> futures = new ArrayList<>();
        for (Callable<Integer> call : calls) {
            futures.add(pool.submit(() -> {
                start.await();
                return call.call();
            }));
        }
        start.countDown();
        List<Integer> results = new ArrayList<>();
        for (Future<Integer> future : futures) results.add(future.get(WAIT.toSeconds(), TimeUnit.SECONDS));
        return results;
    }

    // ── Fixtures (repositories: the prod profile seeds no catalogue) ────────

    record Fixture(Admin requester, Long a, Long b, Long place) {}

    private Fixture fixture() throws Exception {
        Long a = company(), b = company();
        return new Fixture(owner(), a, b, place(a));
    }

    /** A fresh enabled PLATFORM_OWNER, signed in now (a step-up fresh session). */
    private Admin owner() throws Exception {
        User u = user("ADMIN");
        assignments.save(AdminProfileAssignment.systemGrant(u, AdminProfile.PLATFORM_OWNER, Instant.now()));
        MvcResult login = mvc.perform(json(post("/api/auth/login"),
            "{\"email\":\"" + u.getEmail() + "\",\"password\":\"" + PASSWORD + "\"}")).andReturn();
        assertEquals(200, login.getResponse().getStatus(), login.getResponse().getContentAsString());
        return new Admin(mapper.readTree(login.getResponse().getContentAsString()).get("token").asText(), u.getId());
    }

    private User user(String role) {
        User u = new User();
        u.setFullName("R6 SQL Server " + role);
        u.setEmail("r6-sql-" + UUID.randomUUID().toString().substring(0, 12) + "@test.invalid");
        u.setPasswordHash(encoder.encode(PASSWORD));
        u.setRole(role);
        u.setEmailVerifiedAt(Instant.now());
        return users.save(u);
    }

    private Long company() {
        PartnerProfile p = new PartnerProfile();
        p.setUser(user("PARTNER"));
        p.setBusinessName("R6Sql-" + UUID.randomUUID().toString().substring(0, 8));
        p.setBusinessType(BusinessType.HOTEL);
        p.setRepresentativeName("R6 SQL Owner");
        p.setPhone("0901234567");
        p.setEmail("contact@test.invalid");
        p.setAddress("1 Test Street");
        p.setVerificationStatus(PartnerVerificationStatus.APPROVED);
        p.setApprovedAt(Instant.now());
        return partnerProfiles.save(p).getId();
    }

    private Long place(Long ownerId) {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        Category category = new Category();
        category.setName("R6 SQL Category " + suffix);
        category.setSlug("r6-sql-category-" + suffix);
        category = categories.save(category);
        AdministrativeUnit unit = new AdministrativeUnit();
        unit.setName("R6 SQL Unit " + suffix);
        unit.setSlug("r6-sql-unit-" + suffix);
        unit.setCode("R6" + suffix);
        unit.setType(UnitType.CITY);
        unit = units.save(unit);
        Place p = new Place();
        p.setName("R6 SQL Stay " + suffix);
        p.setNameNormalized("r6 sql stay " + suffix);
        p.setSlug("r6-sql-stay-" + suffix);
        p.setCategory(category);
        p.setAdministrativeUnit(unit);
        p.setAddress("1 Test Street");
        p.setStatus(PlaceStatus.DRAFT);
        p.setOwner(partnerProfiles.getReferenceById(ownerId));
        // a traveller account: an ADMIN without a profile would break the AP-4 "every ADMIN is a platform owner" check
        p.setCreatedBy(user("USER"));
        return places.save(p).getId();
    }

    // ── HTTP and SQL helpers ────────────────────────────────────────────────

    private long submit(Admin requester, Long place, Long partnerProfileId) throws Exception {
        MvcResult r = mvc.perform(json(post(assign(place)), "{\"partnerProfileId\":" + partnerProfileId + "}")
            .header("Authorization", "Bearer " + requester.token())).andReturn();
        assertEquals(202, r.getResponse().getStatus(), r.getResponse().getContentAsString());
        return mapper.readTree(r.getResponse().getContentAsString()).get("id").asLong();
    }

    private int status(MockHttpServletRequestBuilder request, String token) throws Exception {
        return mvc.perform(request.header("Authorization", "Bearer " + token)).andReturn().getResponse().getStatus();
    }

    private static String assign(Long place) {
        return "/api/admin/hotels/" + place + "/assign-owner";
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private String statusOf(long id) {
        return jdbc.queryForObject("SELECT status FROM admin_dual_control_requests WHERE id = ?", String.class, id);
    }

    private Long ownerOf(Long place) {
        return jdbc.queryForObject("SELECT owner_partner_profile_id FROM places WHERE id = ?", Long.class, place);
    }

    private int audits(String action, String targetType, Long targetId) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM admin_activity_logs WHERE action = ? AND target_type = ? "
            + "AND target_id = ?", Integer.class, action, targetType, targetId);
    }

    private int notificationsAbout(Long place) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM notifications WHERE related_entity_id = ? "
            + "AND title = 'Hotel assigned to your account'", Integer.class, place);
    }
}
