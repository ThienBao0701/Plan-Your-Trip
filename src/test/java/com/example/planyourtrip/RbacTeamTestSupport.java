package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.PartnerInvitationRepository;
import com.example.planyourtrip.repository.PartnerMemberGrantRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.example.planyourtrip.service.mail.AccountEmail;
import com.example.planyourtrip.service.mail.EmailSender;
import com.example.planyourtrip.support.TeamMemberSeeder;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.mockito.Mockito;
import org.mockito.invocation.Invocation;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Shared fixture of the RBAC R4 suites ({@link RbacTeamInvitationTest}, {@link RbacTeamAdministrationTest}).
 *
 * <p>The application's {@link EmailSender} (the development sender outside {@code prod}) is wrapped in a Mockito spy:
 * the invitation link — the only place an invitation token ever exists — is read from the {@code send} call, and a
 * test can make the sender unavailable or failing. Every request runs through the real HTTP stack and commits, so the
 * company row lock and the database constraints are real. Both subclasses declare the same bean override, so they
 * share one application context.
 */
@SpringBootTest
@AutoConfigureMockMvc
abstract class RbacTeamTestSupport {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired JdbcTemplate jdbc;
    @Autowired JwtService jwt;
    @Autowired UserRepository userRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired PartnerTeamMemberRepository teamMemberRepo;
    @Autowired PartnerMemberGrantRepository grantRepo;
    @Autowired PartnerInvitationRepository invitationRepo;
    @Autowired TeamMemberSeeder seeder;
    @MockitoSpyBean EmailSender emailSender;
    /** Spied so a test can make the strict audit write fail and prove the mutation rolls back with it (AU-1). */
    @MockitoSpyBean com.example.planyourtrip.service.PartnerActivityLogService activityLog;
    @Autowired com.example.planyourtrip.service.PartnerTeamService teamService;
    @Autowired com.example.planyourtrip.service.PartnerInvitationService invitationService;

    static final String PASSWORD = "password123";
    static final String SETTINGS_ALL_OFF = """
        {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh",
         "notificationEmailEnabled":false,"notificationSmsEnabled":false,"notificationInAppEnabled":false,
         "bookingNotificationEnabled":false,"paymentNotificationEnabled":false,
         "reviewNotificationEnabled":false,"promotionNotificationEnabled":false}
        """;
    private static final AtomicInteger counter = new AtomicInteger(1);
    private static String adminToken;

    record Company(String token, Long id, Long userId, String email, Long ownerRowId) {}
    record Member(String token, Long userId, String email, Long rowId) {}

    // ── Companies, accounts, members ─────────────────────────────────────────

    Company approvedCompany() throws Exception {
        String email = registerUser();
        String token = login(email);
        Long id = body(json(post("/api/partner/profile"), """
            {"businessName":"R4 Co %s","businessType":"HOTEL","representativeName":"R4 Owner",
             "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi, Da Nang"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8))), token, 200).get("id").asLong();
        send(post("/api/partner/profile/submit"), token).andExpect(status().isOk());
        send(post("/api/admin/partners/" + id + "/approve"), adminToken()).andExpect(status().isOk());
        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        Long ownerRow = teamMemberRepo.findByPartnerProfileIdAndUserId(id, userId).orElseThrow().getId();
        return new Company(login(email), id, userId, email, ownerRow);
    }

    String registerUser() throws Exception {
        String email = uniqueEmail("user");
        mvc.perform(json(post("/api/auth/register"),
                "{\"fullName\":\"Tran Thien Tester\",\"email\":\"" + email + "\",\"password\":\"" + PASSWORD + "\"}"))
            .andExpect(status().isCreated());
        return email;
    }

    /** An existing PARTNER account without a company, as a self-registered Partner would be. */
    String partnerAccount() throws Exception {
        String email = registerUser();
        User u = userRepo.findByEmail(email).orElseThrow();
        u.setRole("PARTNER");
        userRepo.save(u);
        return email;
    }

    /** A member with {@code role} at company scope (seeded exactly as an accepted invitation creates it). */
    Member member(Company c, String role) throws Exception {
        return member(c, role, ScopeType.COMPANY, c.id());
    }

    Member member(Company c, String role, ScopeType scopeType, Long scopeId) throws Exception {
        String email = partnerAccount();
        Long rowId = seeder.seed(c.id(), email,
            List.of(Map.entry(PartnerTeamRole.valueOf(role), new ScopeRef(scopeType, scopeId))), true);
        return new Member(login(email), userRepo.findByEmail(email).orElseThrow().getId(), email, rowId);
    }

    Long createProperty(Company c) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "R4 Stay " + UUID.randomUUID().toString().substring(0, 8));
        body.put("categoryId", categoryRepo.findBySlug("accommodation").orElseThrow().getId());
        body.put("subcategoryId", categoryRepo.findBySlug("hotel").orElseThrow().getId());
        body.put("administrativeUnitId", locationRepo.findByCode("VT").orElseThrow().getId());
        body.put("address", "15 Thuy Van, Vung Tau");
        body.put("starRating", 3);
        body.put("checkIn", "14:00:00");
        body.put("checkOut", "12:00:00");
        return body(json(post("/api/partner/hotels"), mapper.writeValueAsString(body)), c.token(), 201).get("id").asLong();
    }

    Long createRoom(Long placeId) throws Exception {
        return body(json(post("/api/admin/rooms"), """
            {"placeId":%d,"roomName":"R4 Room","roomCode":"R4-%s","roomType":"DELUXE","bedType":"QUEEN","bedCount":1,
             "maxAdults":2,"maxChildren":1,"maxGuests":3,"roomSizeSqm":25.0,"floorNumber":2,"smokingAllowed":false,
             "breakfastIncluded":true,"freeCancellation":true,"instantConfirmation":true,"priceFrom":500000,
             "originalPrice":600000,"quantity":10,"availableQuantity":10,"active":true}
            """.formatted(placeId, UUID.randomUUID().toString().substring(0, 6))), adminToken(), 201).get("id").asLong();
    }

    // ── Invitations ──────────────────────────────────────────────────────────

    static String invitationBody(String email, String role, String scope) {
        return "{\"email\":\"" + email + "\",\"grants\":[{\"role\":\"" + role + "\",\"scope\":\"" + scope + "\"}]}";
    }

    ResultActions invite(String token, String email, String role, String scope) throws Exception {
        return send(json(post("/api/partner/team/invitations"), invitationBody(email, role, scope)), token);
    }

    /** The token of the latest invitation link sent to {@code email} — read from the email, as the invitee would. */
    String lastToken(String email) {
        String link = null;
        for (Invocation call : Mockito.mockingDetails(emailSender).getInvocations()) {
            if (!call.getMethod().getName().equals("send")) continue;
            AccountEmail sent = call.getArgument(0);
            if (sent.kind() == AccountEmail.Kind.PARTNER_INVITATION && sent.to().equals(email.toLowerCase())) {
                link = sent.actionUrl();
            }
        }
        assertNotNull(link, "no invitation email to " + email);
        return link.substring(link.indexOf("#token=") + "#token=".length());
    }

    ResultActions accept(String token, String invitationToken) throws Exception {
        return send(json(post("/api/me/partner-invitations/accept"), "{\"token\":\"" + invitationToken + "\"}"), token);
    }

    /** The company's invitation to {@code email}, as the team list shows it. */
    JsonNode invitationOf(Company c, String email) throws Exception {
        JsonNode list = body(get("/api/partner/team/invitations"), c.token(), 200);
        for (JsonNode i : list) if (i.get("email").asText().equals(email.toLowerCase())) return i;
        throw new AssertionError("no invitation to " + email + " in " + list);
    }

    /** Moves the last send of the invitation back, so the 60 s cooldown has passed. */
    void cooldownPassed(Long invitationId) {
        jdbc.update("update partner_invitations set last_sent_at = ?, created_at = ? where id = ?",
            java.sql.Timestamp.from(Instant.now().minusSeconds(120)),
            java.sql.Timestamp.from(Instant.now().minusSeconds(120)), invitationId);
    }

    // ── HTTP and data helpers ────────────────────────────────────────────────

    ResultActions send(MockHttpServletRequestBuilder request, String token) throws Exception {
        return mvc.perform(request.header("Authorization", "Bearer " + token));
    }

    static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    JsonNode body(MockHttpServletRequestBuilder request, String token, int expected) throws Exception {
        String content = send(request, token).andExpect(status().is(expected)).andReturn().getResponse().getContentAsString();
        return content.isEmpty() ? null : mapper.readTree(content);
    }

    static String grantsBody(long version, String role, String scope) {
        return "{\"grants\":[{\"role\":\"" + role + "\",\"scope\":\"" + scope + "\"}],\"version\":" + version + "}";
    }

    long version(Long rowId) {
        return teamMemberRepo.findById(rowId).orElseThrow().getVersion();
    }

    List<String> grants(Long rowId) {
        return grantRepo.findByTeamMemberIdOrderByIdAsc(rowId).stream()
            .map(g -> g.getRole().name() + "@" + g.getScopeType().name() + ":" + g.getScopeId()).sorted().toList();
    }

    List<String> actions(Long companyId) {
        return jdbc.queryForList("select action from partner_activity_logs where partner_profile_id = ? order by id",
            String.class, companyId);
    }

    List<Map<String, Object>> auditRows(Long companyId, String action) {
        return jdbc.queryForList("select action, actor_user_id, actor_email, entity_type, entity_id, before_state, "
            + "after_state, reason, description from partner_activity_logs where partner_profile_id = ? and action = ? "
            + "order by id", companyId, action);
    }

    List<String> titles(String token) throws Exception {
        List<String> titles = new ArrayList<>();
        body(get("/api/me/notifications"), token, 200).forEach(n -> titles.add(n.get("title").asText()));
        return titles;
    }

    List<Long> teamIds(Company c) throws Exception {
        List<Long> ids = new ArrayList<>();
        body(get("/api/partner/team"), c.token(), 200).forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }

    String staleToken(Long userId) {
        User u = userRepo.findById(userId).orElseThrow();
        return jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion(),
            Instant.now().minus(StepUpPolicy.FRESHNESS).minusSeconds(60));
    }

    String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    String login(String email) throws Exception {
        return login(email, PASSWORD);
    }

    String login(String email, String password) throws Exception {
        return mapper.readTree(mvc.perform(json(post("/api/auth/login"),
                "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("token").asText();
    }

    static String uniqueEmail(String prefix) {
        return "r4-" + prefix + "-" + counter.getAndIncrement() + "-"
            + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    @SafeVarargs
    static List<Integer> concurrently(Callable<Integer>... calls) throws Exception {
        ExecutorService pool = Executors.newFixedThreadPool(calls.length);
        CountDownLatch start = new CountDownLatch(1);
        try {
            List<Future<Integer>> futures = new ArrayList<>();
            for (Callable<Integer> call : calls) {
                futures.add(pool.submit(() -> { start.await(); return call.call(); }));
            }
            start.countDown();
            List<Integer> results = new ArrayList<>();
            for (Future<Integer> f : futures) results.add(f.get(60, TimeUnit.SECONDS));
            return results;
        } finally {
            pool.shutdownNow();
        }
    }
}
