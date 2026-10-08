package com.example.planyourtrip;

import com.example.planyourtrip.model.PartnerMembershipStatus;
import com.example.planyourtrip.model.PartnerTeamRole;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.ConversationRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PartnerActivityLogRepository;
import com.example.planyourtrip.repository.PartnerMemberGrantRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.example.planyourtrip.security.StepUpPolicy;
import com.example.planyourtrip.security.rbac.EndpointAuthorizationRegistry;
import com.example.planyourtrip.security.rbac.EndpointKind;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerEndpointRule;
import com.example.planyourtrip.security.rbac.PartnerAuthorization;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.PartnerRoleBundles;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.service.PartnerAccessService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.repository.CrudRepository;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.time.Instant;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R3b — partner permission enforcement (RBAC V1.1 §4.5, §10.1, §11, §21, §24, §25).
 *
 * <p>One company A with properties P1 (room types R1a, R1b) and P2 (R2a), and a company B with property Q (Rq).
 * Confirmed bookings b1 (R1a), b2 (R2a), bq (Rq); a guest conversation on b1. Members of A each hold one role at
 * one scope, granted through the R3a team endpoint. Every request goes through the real HTTP stack and commits.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RbacPartnerEnforcementTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired JdbcTemplate jdbc;
    @Autowired JwtService jwt;
    @Autowired UserRepository userRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired PartnerTeamMemberRepository teamMemberRepo;
    @Autowired PartnerMemberGrantRepository grantRepo;
    @Autowired ConversationRepository conversationRepo;
    @Autowired PartnerAccessService partnerAccess;
    @Autowired EndpointAuthorizationRegistry registry;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final String PASSWORD = "password123";
    private static final LocalDate TODAY = LocalDate.now();
    /** Keys no partner response may ever carry (§21.3 NR-1…NR-5). */
    private static final Set<String> NEVER = Set.of("checkoutUrl", "failureReason", "loyaltyPointsRedeemed",
        "qrPayload", "signature", "fullCode", "callbackToken", "userId", "senderUserId");

    private static Fixture fx;
    private static String adminToken;

    record Company(String ownerToken, Long companyId, Long ownerUserId, String ownerEmail) {}
    record Member(String token, Long userId, String email, Long rowId) {}
    record Fixture(Company a, Company b, Long p1, Long p2, Long q, Long r1a, Long r1b, Long r2a, Long rq,
                   Long b1, Long b2, Long bq, Long conv1, String guestToken, String guestName,
                   Map<String, Member> members) {
        Member m(String key) { return members.get(key); }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Role bundles at their scopes (§10.1, §12.1)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void theOwnerOperatesTheWholeCompany() throws Exception {
        Fixture f = fixture();
        assertEquals(Set.of(f.p1(), f.p2()), ids(get("/api/partner/hotels"), f.a().ownerToken()));
        assertTrue(bookingIds(f.a().ownerToken()).containsAll(List.of(f.b1(), f.b2())));
        ok(get("/api/partner/finance/settlements"), f.a().ownerToken());
        ok(get("/api/partner/payout-account"), f.a().ownerToken(), 404); // not configured yet, but authorized
        ok(get("/api/partner/extranet/activity-logs"), f.a().ownerToken());
    }

    @Test
    void aCompanyManagerOperatesEverythingButPayoutAndTeamMutations() throws Exception {
        Fixture f = fixture();
        String t = f.m("managerCompany").token();
        assertEquals(Set.of(f.p1(), f.p2()), ids(get("/api/partner/hotels"), t));
        ok(get("/api/partner/finance/settlements"), t);
        ok(get("/api/partner/extranet/activity-logs"), t);           // AU-4: MANAGER@COMPANY reads the trail
        ok(get("/api/partner/team"), t);
        denied(get("/api/partner/payout-account"), t);                 // P52 is OWNER/FINANCE only
        denied(json(post("/api/partner/team"), "{\"email\":\"x@test.com\",\"role\":\"VIEWER\"}"), t); // R4
        denied(post("/api/partner/team/" + f.m("viewerCompany").rowId() + "/suspend"), t);
    }

    @Test
    void aPropertyManagerStaysInsideTheirProperty() throws Exception {
        Fixture f = fixture();
        String t = f.m("managerP1").token();
        assertEquals(Set.of(f.p1()), ids(get("/api/partner/hotels"), t));
        ok(get("/api/partner/hotels/" + f.p1()), t);
        notFound(get("/api/partner/hotels/" + f.p2()), t);
        ok(patch("/api/partner/hotels/" + f.p1() + "/activate"), t);
        notFound(patch("/api/partner/hotels/" + f.p2() + "/activate"), t);
        assertEquals(Set.of(f.b1()), Set.copyOf(bookingIds(t)));
        notFound(get("/api/partner/bookings/" + f.b2()), t);
        // a property grant never acts at company scope (floor C): statements, settings, new property
        denied(get("/api/partner/finance/settlements"), t);
        denied(json(put("/api/partner/settings"), settingsBody()), t);
        denied(json(post("/api/partner/hotels"), hotelCreateBody()), t);
        denied(get("/api/partner/extranet/activity-logs"), t);
    }

    @Test
    void revenueManagesRatesAndCommercialFieldsButNotGuestsOrContent() throws Exception {
        Fixture f = fixture();
        String t = f.m("revenueCompany").token();
        ok(get("/api/partner/rooms/" + f.r1a() + "/rate-plans"), t);
        ok(get("/api/partner/finance/overview"), t);
        denied(get("/api/partner/finance/settlements"), t);
        denied(patch("/api/partner/bookings/" + f.b1() + "/check-in"), t);   // views the booking, may not operate it
        JsonNode list = body(get("/api/partner/bookings"), t).get("content");
        JsonNode row = find(list, f.b1());
        assertEquals(mask(f.guestName()), row.get("guestName").asText());
        assertTrue(row.get("guestEmail").isNull());
        assertTrue(redacted(row).containsAll(List.of("guestName:MASKED", "guestEmail:OMITTED")));
    }

    @Test
    void reservationsWorksTheBookingsOfItsPropertyOnly() throws Exception {
        Fixture f = fixture();
        String t = f.m("reservationsP1").token();
        JsonNode row = find(body(get("/api/partner/bookings"), t).get("content"), f.b1());
        assertEquals(f.guestName(), row.get("guestName").asText());   // P54
        assertFalse(row.get("guestEmail").isNull());                    // P35
        assertEquals(Set.of(f.b1()), Set.copyOf(bookingIds(t)));
        notFound(get("/api/partner/bookings/" + f.b2()), t);
        assertEquals(Set.of(f.conv1()), ids(get("/api/partner/conversations"), t));
        ok(get("/api/partner/rooms/" + f.r1a() + "/rate-plans"), t);
        denied(json(post("/api/partner/rooms/" + f.r1a() + "/rate-plans"), ratePlanBody()), t);   // no rate edit
    }

    @Test
    void frontDeskVerifiesAndChecksInAtItsPropertyOnly() throws Exception {
        Fixture f = fixture();
        String t = f.m("frontDeskP1").token();
        JsonNode verified = body(json(post("/api/partner/bookings/voucher/verify"),
            "{\"voucherPayload\":\"" + voucherPayload(f.b1()) + "\"}"), t);
        assertEquals(f.guestName(), verified.get("guestName").asText());
        notFound(json(post("/api/partner/bookings/voucher/verify"),
            "{\"voucherPayload\":\"" + voucherPayload(f.b2()) + "\"}"), t);
        notFound(patch("/api/partner/bookings/" + f.b2() + "/check-in"), t);
        denied(json(put("/api/partner/hotels/" + f.p1() + "/policies"), "{\"checkIn\":\"14:00:00\",\"checkOut\":\"12:00:00\"}"), t);
        denied(get("/api/partner/finance/revenue"), t);
        denied(json(post("/api/partner/hotels"), hotelCreateBody()), t);
    }

    @Test
    void financeSeesMoneyAtCompanyScopeButNoGuestContactOrFreeText() throws Exception {
        Fixture f = fixture();
        String t = f.m("financeCompany").token();
        JsonNode detail = body(get("/api/partner/bookings/" + f.b1()), t);
        assertTrue(detail.get("payments").isArray());                         // P36
        assertEquals(f.guestName(), detail.get("booking").get("userFullName").asText());   // P54
        assertTrue(detail.get("booking").get("userEmail").isNull());          // no P35
        assertTrue(detail.get("booking").get("specialRequest").isNull());     // no P40
        assertTrue(redacted(detail).containsAll(List.of("booking.userEmail:OMITTED", "booking.specialRequest:OMITTED",
            "booking.partnerNote:OMITTED", "booking.cancelReason:OMITTED")));
        ok(get("/api/partner/finance/payouts"), t);
        ok(get("/api/partner/payout-account"), t, 404);
        notFound(get("/api/partner/rooms/" + f.r1a() + "/rate-plans"), t);  // no rate view anywhere
        denied(get("/api/partner/team"), t);
        // FINANCE is company-only (Q10): it cannot be granted at a property
        Member viewer = newMember(f.a(), "VIEWER");
        send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"),
                grants(viewer.rowId(), "FINANCE", "PROPERTY:" + f.p1())), f.a().ownerToken())
            .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
    }

    @Test
    void contentEditsContentNeverCommercialFields() throws Exception {
        Fixture f = fixture();
        String t = f.m("contentP1").token();
        JsonNode room = body(get("/api/partner/rooms/" + f.r1a()), t);
        ok(json(put("/api/partner/rooms/" + f.r1a()), roomBody(room, "Renamed by content", null)), t);
        denied(json(put("/api/partner/rooms/" + f.r1a()), roomBody(room, "Renamed by content", "999999")), t);
        ok(get("/api/partner/places/" + f.p1() + "/reviews/analytics"), t);
        notFound(get("/api/partner/places/" + f.p2() + "/reviews/analytics"), t);
        denied(get("/api/partner/bookings"), t);                     // no booking view anywhere: the list is 403…
        notFound(get("/api/partner/bookings/" + f.b1()), t);       // …and a booking's existence is not revealed
    }

    @Test
    void housekeepingAtAPropertyAndAtARoomType() throws Exception {
        Fixture f = fixture();
        String p = f.m("housekeepingP1").token();
        ok(get("/api/partner/settings"), p);
        assertEquals(Set.of(f.p1()), ids(get("/api/partner/hotels"), p));
        denied(get("/api/partner/bookings"), p);
        notFound(get("/api/partner/bookings/" + f.b1()), p);
        notFound(get("/api/partner/hotels/" + f.p2()), p);

        String u = f.m("housekeepingUnit").token();
        ok(get("/api/partner/rooms/" + f.r1a()), u);
        notFound(get("/api/partner/rooms/" + f.r1b()), u);          // a unit grant never reaches its siblings
        notFound(get("/api/partner/hotels/" + f.p1()), u);          // …nor its property (P14 floor P)
        denied(get("/api/partner/hotels"), u);
        assertEquals(Set.of(f.r1a()), ids(get("/api/partner/rooms").param("hotelId", f.p1().toString()), u));
        JsonNode menu = body(get("/api/partner/extranet/menu"), u).get("sections");
        Set<String> keys = new TreeSet<>();
        menu.forEach(item -> keys.add(item.get("key").asText()));
        assertTrue(keys.containsAll(List.of("hotels", "rooms", "settings")), keys.toString());
        assertFalse(keys.contains("bookings") || keys.contains("finance") || keys.contains("calendar"), keys.toString());
    }

    @Test
    void aViewerReadsAndWritesNothing() throws Exception {
        Fixture f = fixture();
        String t = f.m("viewerCompany").token();
        ok(get("/api/partner/hotels"), t);
        ok(get("/api/partner/calendar/rooms/" + f.r1a()), t);
        JsonNode overview = body(get("/api/partner/analytics/overview"), t);
        assertTrue(overview.get("totalRevenue").isNull());
        assertTrue(redacted(overview).contains("totalRevenue:OMITTED"));
        JsonNode dashboard = body(get("/api/partner/dashboard"), t);
        assertTrue(dashboard.get("revenueToday").isNull());
        denied(patch("/api/partner/hotels/" + f.p1() + "/deactivate"), t);
        denied(json(post("/api/partner/rooms/" + f.r1a() + "/rate-plans"), ratePlanBody()), t);
        denied(patch("/api/partner/bookings/" + f.b1() + "/check-in"), t);
        denied(json(put("/api/partner/settings"), settingsBody()), t);
        denied(get("/api/partner/team"), t);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Scope boundaries (§11, §12.2)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anotherCompanysResourcesAreNotFound() throws Exception {
        Fixture f = fixture();
        for (String token : List.of(f.a().ownerToken(), f.m("managerCompany").token())) {
            notFound(get("/api/partner/hotels/" + f.q()), token);
            notFound(get("/api/partner/rooms/" + f.rq()), token);
            notFound(get("/api/partner/bookings/" + f.bq()), token);
            notFound(get("/api/partner/calendar/rooms/" + f.rq()), token);
            notFound(get("/api/partner/finance/overview").param("hotelId", f.q().toString()), token);
        }
        Long qDetail = hotelDetailRepo.findByPlaceId(f.q()).orElseThrow().getId();
        notFound(json(post("/api/partner/promotions"), promotionBody("HOTEL", qDetail)), f.a().ownerToken());
    }

    @Test
    void aClientSuppliedScopeNeverWidensTheServerScope() throws Exception {
        Fixture f = fixture();
        String t = f.m("managerP1").token();
        notFound(get("/api/partner/finance/overview").param("hotelId", f.p2().toString()), t);
        notFound(get("/api/partner/analytics/bookings").param("hotelId", f.p2().toString()), t);
        notFound(get("/api/partner/rooms").param("hotelId", f.p2().toString()), t);
        Long p2Detail = hotelDetailRepo.findByPlaceId(f.p2()).orElseThrow().getId();
        notFound(json(post("/api/partner/promotions"), promotionBody("HOTEL", p2Detail)), t);
        notFound(json(post("/api/partner/promotions"), promotionBody("ROOM", f.r2a())), t);
        // a body naming another company or owner is ignored: scope always comes from the stored target
        assertEquals(Set.of(f.b1()), Set.copyOf(bookingIds(t)));
    }

    @Test
    void aggregatesAreComputedOverTheCallersScopeOnly() throws Exception {
        Fixture f = fixture();
        JsonNode all = body(window(get("/api/partner/finance/overview")), f.a().ownerToken());
        JsonNode onlyP1 = body(window(get("/api/partner/finance/overview")), f.m("managerP1").token());
        JsonNode p1ByOwner = body(window(get("/api/partner/finance/overview")).param("hotelId", f.p1().toString()), f.a().ownerToken());
        assertEquals(p1ByOwner.get("grossRevenue").decimalValue(), onlyP1.get("grossRevenue").decimalValue());
        assertTrue(all.get("grossRevenue").decimalValue().compareTo(onlyP1.get("grossRevenue").decimalValue()) > 0,
            "company-wide revenue includes P2's booking, the property manager's does not");
        // front desk holds booking view but no revenue view: dashboard counts, never money
        JsonNode dashboard = body(get("/api/partner/dashboard"), f.m("frontDeskP1").token());
        assertTrue(dashboard.get("revenueMonth").isNull());
        assertTrue(redacted(dashboard).contains("revenueMonth:OMITTED"));
    }

    @Test
    void reviewAnalyticsNeverHandsIndividualReviewsToARoleWithoutReviewView() throws Exception {
        Fixture f = fixture();
        JsonNode finance = body(get("/api/partner/analytics/reviews"), f.m("financeCompany").token());
        assertTrue(finance.get("latestReviews").isNull());
        assertTrue(redacted(finance).contains("latestReviews:OMITTED"));
        JsonNode viewer = body(get("/api/partner/analytics/reviews"), f.m("viewerCompany").token());
        assertTrue(viewer.get("latestReviews").isArray());
    }

    @Test
    void mixedPayloadsAreAuthorizedByTheFieldsTheyChange() throws Exception {
        Fixture f = fixture();
        String revenue = f.m("revenueCompany").token();
        JsonNode room = body(get("/api/partner/rooms/" + f.r1b()), f.a().ownerToken());
        ok(json(put("/api/partner/rooms/" + f.r1b()), roomBody(room, null, "777777")), revenue);       // P24 only
        denied(json(put("/api/partner/rooms/" + f.r1b()), roomBody(room, "Revenue renamed", null)), revenue); // P23
        assertEquals(0, body(get("/api/partner/rooms/" + f.r1b()), revenue).get("priceFrom").decimalValue()
            .compareTo(new java.math.BigDecimal("777777")));

        // calendar: RESERVATIONS holds restriction flags (P28) but not counts (P27)
        String reservations = f.m("reservationsP1").token();
        LocalDate day = TODAY.plusDays(30);
        JsonNode cal = body(get("/api/partner/calendar/rooms/" + f.r1a()).param("from", day.toString())
            .param("to", day.toString()), f.a().ownerToken());
        JsonNode d = cal.get("inventory").get(0);
        ok(json(put("/api/partner/calendar/rooms/" + f.r1a() + "/" + day), dayBody(d, day, false, true)), reservations);
        denied(json(put("/api/partner/calendar/rooms/" + f.r1a() + "/" + day), dayBody(d, day, true, true)), reservations);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Field-level data minimisation (§21)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void neverToPartnerFieldsAppearInNoPartnerResponse() throws Exception {
        Fixture f = fixture();
        String owner = f.a().ownerToken();
        List<JsonNode> responses = new ArrayList<>();
        responses.add(body(get("/api/partner/bookings"), owner));
        responses.add(body(get("/api/partner/bookings/" + f.b1()), owner));
        responses.add(body(get("/api/partner/stays/" + f.b1()), owner));
        responses.add(body(get("/api/partner/conversations/" + f.conv1()), owner));
        responses.add(body(get("/api/partner/conversations"), owner));
        responses.add(body(json(post("/api/partner/bookings/voucher/verify"),
            "{\"voucherPayload\":\"" + voucherPayload(f.b1()) + "\"}"), owner));
        responses.add(body(get("/api/partner/extranet/home"), owner));
        responses.add(body(get("/api/partner/dashboard"), owner));
        responses.add(body(get("/api/partner/me/access"), owner));
        for (JsonNode response : responses) {
            Set<String> keys = new TreeSet<>();
            collectKeys(response, keys);
            for (String forbidden : NEVER) assertFalse(keys.contains(forbidden), forbidden + " leaked in " + response);
        }
    }

    @Test
    void guestFreeTextAndPaymentDetailFollowTheirPermissions() throws Exception {
        Fixture f = fixture();
        JsonNode owner = body(get("/api/partner/bookings/" + f.b1()), f.a().ownerToken());
        assertEquals("Late arrival, quiet room", owner.get("booking").get("specialRequest").asText());
        assertTrue(owner.get("redacted").isEmpty());
        assertTrue(owner.get("payments").isArray());

        JsonNode reservations = body(get("/api/partner/bookings/" + f.b1()), f.m("reservationsP1").token());
        assertEquals("Late arrival, quiet room", reservations.get("booking").get("specialRequest").asText());  // P40
        assertTrue(reservations.get("payments").isNull());                                                       // no P36
        assertTrue(reservations.get("booking").get("basePrice").isNull());
        assertTrue(redacted(reservations).containsAll(List.of("payments:OMITTED", "invoice:OMITTED",
            "booking.basePrice:OMITTED")));
        assertFalse(reservations.get("booking").get("finalPrice").isNull(), "the per-booking total is P34 (FI-1)");

        JsonNode viewer = body(get("/api/partner/bookings/" + f.b1()), f.m("viewerCompany").token());
        assertEquals(mask(f.guestName()), viewer.get("booking").get("userFullName").asText());
        assertTrue(viewer.get("booking").get("specialRequest").isNull());
        assertTrue(viewer.get("booking").get("cancelReason").isNull());
        assertTrue(viewer.get("booking").get("partnerNote").isNull());

        JsonNode conversation = body(get("/api/partner/conversations/" + f.conv1()), f.m("viewerCompany").token(), 404);
        assertNotNull(conversation);  // VIEWER holds no conversation view: the thread does not exist for them
        JsonNode thread = body(get("/api/partner/conversations/" + f.conv1()), f.m("reservationsP1").token());
        assertEquals(f.guestName(), thread.get("userName").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Membership states, R3a protections, errors
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void suspendedAndRevokedMembersAreRefusedOnTheNextRequest() throws Exception {
        Fixture f = fixture();
        Member m = newMember(f.a(), "MANAGER");
        ok(get("/api/partner/hotels"), m.token());
        send(post("/api/partner/team/" + m.rowId() + "/suspend"), f.a().ownerToken()).andExpect(status().isOk());
        notFound(get("/api/partner/hotels"), m.token());
        JsonNode doc = body(get("/api/partner/me/access"), m.token());
        assertEquals("SUSPENDED", doc.get("membership").get("status").asText());
        assertTrue(doc.get("permissions").get("company").isEmpty());
        send(post("/api/partner/team/" + m.rowId() + "/reactivate"), f.a().ownerToken()).andExpect(status().isOk());
        ok(get("/api/partner/hotels"), m.token());
        send(delete("/api/partner/team/" + m.rowId()), f.a().ownerToken()).andExpect(status().isNoContent());
        notFound(get("/api/partner/hotels"), m.token());
        notFound(get("/api/partner/me/access"), m.token());
    }

    @Test
    void ownerProtectionStepUpAndTheAppendOnlyTrailStillHold() throws Exception {
        Fixture f = fixture();
        // a company manager cannot touch the primary owner (no team mutations before R4; O-1 regardless)
        Long ownerRow = teamMemberRepo.findByPartnerProfileIdAndUserId(f.a().companyId(), f.a().ownerUserId())
            .orElseThrow().getId();
        denied(post("/api/partner/team/" + ownerRow + "/suspend"), f.m("managerCompany").token());
        // step-up still guards the payout account, for the owner and for finance
        for (Long userId : List.of(f.a().ownerUserId(), f.m("financeCompany").userId())) {
            send(json(put("/api/partner/payout-account"),
                    "{\"accountHolderName\":\"H\",\"bankName\":\"B\",\"bankAccountNumber\":\"1234567890\",\"payoutMethod\":\"BANK_TRANSFER\"}"),
                    staleToken(userId))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value(StepUpPolicy.STEP_UP_REQUIRED));
        }
        assertFalse(CrudRepository.class.isAssignableFrom(PartnerActivityLogRepository.class));
    }

    @Test
    void errorSemanticsAre401_403_404() throws Exception {
        Fixture f = fixture();
        mvc.perform(get("/api/partner/me/access")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/partner/hotels").header("Authorization", "Bearer not-a-token")).andExpect(status().isUnauthorized());
        send(get("/api/partner/hotels"), f.guestToken()).andExpect(status().isForbidden());        // USER on /api/partner
        send(get("/api/partner/me/access"), adminToken()).andExpect(status().isNotFound());      // admins have no workspace
        denied(patch("/api/partner/hotels/" + f.p1() + "/activate"), f.m("viewerCompany").token());  // views it: 403
        denied(patch("/api/partner/hotels/" + f.p1() + "/activate"), f.m("financeCompany").token());       // views it: 403
        notFound(patch("/api/partner/hotels/" + f.p1() + "/activate"), f.m("housekeepingUnit").token());  // cannot see it: 404
        notFound(get("/api/partner/hotels/" + Long.MAX_VALUE), f.a().ownerToken());
    }

    @Test
    void unknownPermissionsAndMalformedScopesFailClosed() throws Exception {
        Fixture f = fixture();
        PartnerAccessContext ctx = partnerAccess.requireWorkspace(f.m("managerCompany").userId());
        ScopePath p1 = ScopePath.property(f.a().companyId(), f.p1());
        assertFalse(PartnerAuthorization.isGranted(ctx, "partner.does.not.exist", p1));
        assertFalse(PartnerAuthorization.isGranted(ctx, "admin.partner.view", p1));
        assertFalse(PartnerAuthorization.isGranted(ctx, "partner.property.view", null));
        assertTrue(PartnerPermission.fromKey("PARTNER.PROPERTY.VIEW").isEmpty());
        Member viewer = newMember(f.a(), "VIEWER");
        for (String scope : List.of("PROPERTY:abc", "property:" + f.p1(), "ALL:1", "PROPERTY:" + f.q())) {
            send(json(put("/api/partner/team/" + viewer.rowId() + "/grants"), grants(viewer.rowId(), "MANAGER", scope)),
                    f.a().ownerToken())
                .andExpect(status().isUnprocessableEntity()).andExpect(jsonPath("$.code").value("SCOPE_INVALID"));
        }
    }

    @Test
    void theAccessDocumentListsEffectivePermissionsAfterFloors() throws Exception {
        Fixture f = fixture();
        JsonNode doc = mvc.perform(get("/api/partner/me/access")
                .header("Authorization", "Bearer " + f.m("managerP1").token()))
            .andExpect(status().isOk())
            .andExpect(header().string("Cache-Control", org.hamcrest.Matchers.containsString("no-store")))
            .andReturn().getResponse().getContentAsString().transform(this::tree);
        assertTrue(doc.get("permissions").get("company").isEmpty());
        JsonNode atP1 = doc.get("permissions").get("properties").get(f.p1().toString());
        Set<String> keys = new TreeSet<>();
        atP1.forEach(k -> keys.add(k.asText()));
        assertTrue(keys.containsAll(List.of("partner.property.view", "partner.booking.view", "partner.rate.edit")));
        assertFalse(keys.contains("partner.finance.statement.view"), "floor C never appears under a property");
        assertFalse(keys.contains("partner.property.create"));
        assertFalse(keys.contains("partner.team.invite"), "MANAGER team mutations wait for R4");
        assertFalse(keys.contains("partner.housekeeping.view"), "reserved permissions are never listed");
        assertEquals(1, doc.get("context").get("properties").size());
        assertEquals(f.p1().longValue(), doc.get("context").get("properties").get(0).get("id").asLong());

        JsonNode unit = body(get("/api/partner/me/access"), f.m("housekeepingUnit").token());
        assertTrue(unit.get("permissions").get("units").has(f.r1a().toString()));
        assertTrue(unit.get("permissions").get("properties").isEmpty(), "floor P never appears under a unit");
        assertEquals(f.r1a().longValue(), unit.get("context").get("units").get(0).get("id").asLong());
        assertEquals(f.p1().longValue(), unit.get("context").get("properties").get(0).get("id").asLong());
    }

    @Test
    void theV11BundlesMatchTheMatrix() {
        Map<PartnerTeamRole, Integer> totals = Map.of(PartnerTeamRole.OWNER, 54, PartnerTeamRole.MANAGER, 47,
            PartnerTeamRole.REVENUE, 17, PartnerTeamRole.RESERVATIONS, 16, PartnerTeamRole.FRONT_DESK, 16,
            PartnerTeamRole.FINANCE, 13, PartnerTeamRole.CONTENT, 8, PartnerTeamRole.HOUSEKEEPING, 5,
            PartnerTeamRole.VIEWER, 9);
        totals.forEach((role, n) -> assertEquals(n, PartnerRoleBundles.of(role).size(), role.name()));
        assertEquals(43, PartnerRoleBundles.effective(PartnerTeamRole.MANAGER).size());
        for (PartnerTeamRole role : PartnerTeamRole.values()) {
            if (role == PartnerTeamRole.OWNER) continue;
            for (PartnerPermission p : List.of(PartnerPermission.BUSINESS_PROFILE_EDIT, PartnerPermission.SECURITY_SETTINGS_MANAGE,
                    PartnerPermission.TEAM_OWNER_MANAGE, PartnerPermission.OWNERSHIP_TRANSFER)) {
                assertFalse(PartnerRoleBundles.of(role).contains(p), "I10: " + p.key() + " is owner-only, not " + role);
            }
        }
    }

    @Test
    void noRoleCanRaiseItsOwnOrAnotherMembersPrivileges() throws Exception {
        Fixture f = fixture();
        Member self = f.m("managerCompany");
        // MANAGER holds no grant-assignment before R4 and never P12: not for itself, not for anyone
        denied(json(put("/api/partner/team/" + self.rowId() + "/grants"), grants(self.rowId(), "OWNER", "COMPANY:" + f.a().companyId())), self.token());
        denied(json(put("/api/partner/team/" + f.m("viewerCompany").rowId() + "/grants"),
            grants(f.m("viewerCompany").rowId(), "MANAGER", "COMPANY:" + f.a().companyId())), self.token());
        denied(json(post("/api/partner/team"), "{\"email\":\"" + uniqueEmail("x") + "\",\"role\":\"OWNER\"}"), self.token());
        // a property-scoped member gains nothing company-wide by naming another property or the company in a query
        notFound(get("/api/partner/finance/overview").param("hotelId", f.q().toString()), f.m("managerP1").token());
        // partner and admin authority never cross (§3)
        send(get("/api/admin/partners"), self.token()).andExpect(status().isForbidden());
        send(get("/api/admin/partners"), f.a().ownerToken()).andExpect(status().isForbidden());
        send(get("/api/partner/hotels"), adminToken()).andExpect(status().isNotFound())     // no workspace
            .andExpect(jsonPath("$.message").value("Partner profile not found"));
        PartnerAccessContext ctx = partnerAccess.requireWorkspace(self.userId());
        assertTrue(PartnerAuthorization.effectivePermissions(ctx).company().stream()
            .noneMatch(p -> p == PartnerPermission.TEAM_OWNER_MANAGE || p == PartnerPermission.OWNERSHIP_TRANSFER
                || p == PartnerPermission.TEAM_ROLE_ASSIGN));
    }

    @Test
    void roomRevenueRankingNeedsRevenueView() throws Exception {
        Fixture f = fixture();
        JsonNode viewer = body(get("/api/partner/analytics/rooms"), f.m("viewerCompany").token());
        assertTrue(viewer.get("topRoomsByRevenue").isNull());
        assertTrue(redacted(viewer).contains("topRoomsByRevenue:OMITTED"));
        JsonNode revenue = body(get("/api/partner/analytics/rooms"), f.m("revenueCompany").token());
        assertTrue(revenue.get("topRoomsByRevenue").isArray());
    }

    /** The registry is the single source of truth: its field gates and aggregate kinds match what services enforce. */
    @Test
    void theRegistryDeclaresEveryGateTheServicesEnforce() {
        assertEquals(Set.of(PartnerPermission.FINANCE_REVENUE_VIEW), rule(GET_, "/api/partner/analytics/rooms").fieldPermissions());
        assertEquals(Set.of(PartnerPermission.REVIEW_VIEW), rule(GET_, "/api/partner/analytics/reviews").fieldPermissions());
        assertTrue(rule(GET_, "/api/partner/extranet/home").fieldPermissions().containsAll(Set.of(
            PartnerPermission.FINANCE_REVENUE_VIEW, PartnerPermission.PROPERTY_VIEW, PartnerPermission.ROOM_VIEW,
            PartnerPermission.BOOKING_VIEW, PartnerPermission.ANALYTICS_VIEW, PartnerPermission.BUSINESS_PROFILE_VIEW)));
        // SD-4: every endpoint returning guest or money data declares its field gates
        for (String path : List.of("/api/partner/bookings", "/api/partner/bookings/{id}", "/api/partner/stays/{bookingId}",
                "/api/partner/conversations", "/api/partner/conversations/{id}", "/api/partner/dashboard",
                "/api/partner/extranet/home", "/api/partner/extranet/account-summary", "/api/partner/analytics/overview")) {
            assertFalse(rule(GET_, path).fieldPermissions().isEmpty(), path);
        }
        // finance statements and payouts are COMPANY ONLY; revenue reports are FILTERABLE BY PROPERTY
        for (String path : List.of("/api/partner/finance/settlements", "/api/partner/finance/commissions",
                "/api/partner/finance/invoices", "/api/partner/finance/refunds", "/api/partner/finance/payouts")) {
            PartnerEndpointRule r = rule(GET_, path);
            assertEquals(EndpointKind.COMPANY, r.kind(), path);
            assertEquals(PartnerEndpointRule.AggregateScope.COMPANY_ONLY, r.aggregate(), path);
        }
        for (PartnerEndpointRule r : registry.partnerRules()) {
            assertFalse(r.permissions().isEmpty(), r.key());
            assertTrue(r.permissions().stream().noneMatch(PartnerPermission::reserved), r.key() + " uses a reserved permission");
            if (r.kind() == EndpointKind.RESOURCE
                    || (r.kind() == EndpointKind.COLLECTION && r.aggregate() == PartnerEndpointRule.AggregateScope.NONE)) {
                assertNotNull(r.resourceType(), r.key());
            }
        }
    }

    private static final org.springframework.web.bind.annotation.RequestMethod GET_ =
        org.springframework.web.bind.annotation.RequestMethod.GET;

    private PartnerEndpointRule rule(org.springframework.web.bind.annotation.RequestMethod method, String pattern) {
        return registry.partnerRule(method, pattern).orElseThrow(() -> new AssertionError("no rule for " + pattern));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PA-4: a property moving between companies (§16)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void aMovedPropertyLeavesNothingOfThePreviousCompanyBehind() throws Exception {
        Company a = approvedCompany();
        Company b = approvedCompany();
        Long property = createPublishedHotel(a);
        Long room = createRoom(property);
        bulkInventory(room);
        String guest = registerAndLogin(uniqueEmail("guest"));
        Long booking = confirmedBooking(guest, room, null);
        Long conversation = openConversation(guest, booking);
        Member scoped = newMember(a, "VIEWER");
        send(json(put("/api/partner/team/" + scoped.rowId() + "/grants"),
                grants(scoped.rowId(), "FRONT_DESK", "PROPERTY:" + property)), a.ownerToken()).andExpect(status().isOk());
        ok(get("/api/partner/bookings/" + booking), scoped.token());
        ok(get("/api/partner/conversations/" + conversation), scoped.token());

        send(json(post("/api/admin/hotels/" + property + "/assign-owner"), "{\"partnerProfileId\":" + b.companyId() + "}"),
            adminToken()).andExpect(status().isOk());

        // the previous company loses the property, its bookings and its conversations on the next request
        notFound(get("/api/partner/bookings/" + booking), scoped.token());
        notFound(get("/api/partner/conversations/" + conversation), a.ownerToken());
        notFound(get("/api/partner/hotels/" + property), a.ownerToken());
        assertTrue(grantRepo.findByTeamMemberIdOrderByIdAsc(scoped.rowId()).isEmpty(), "the property grant is revoked");
        List<Map<String, Object>> audit = jdbc.queryForList(
            "select action, before_state, reason from partner_activity_logs where partner_profile_id = ? and entity_id = ?",
            a.companyId(), scoped.rowId());
        assertTrue(audit.stream().anyMatch(r -> "TEAM_MEMBER_SCOPE_REVOKED".equals(r.get("action"))
            && ("FRONT_DESK@PROPERTY:" + property).equals(r.get("before_state"))), audit.toString());
        assertTrue(titles(a.ownerToken()).contains("Team member access removed"));
        // the new company sees the conversation; the denormalized column follows
        ok(get("/api/partner/conversations/" + conversation), b.ownerToken());
        assertEquals(b.companyId(), conversationRepo.findById(conversation).orElseThrow().getPartnerProfile().getId());
        assertEquals(PartnerMembershipStatus.ACTIVE, teamMemberRepo.findById(scoped.rowId()).orElseThrow().getStatus());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Fixture
    // ═══════════════════════════════════════════════════════════════════════

    private synchronized Fixture fixture() throws Exception {
        if (fx != null) return fx;
        Company a = approvedCompany();
        Company b = approvedCompany();
        Long p1 = createPublishedHotel(a);
        Long p2 = createPublishedHotel(a);
        Long q = createPublishedHotel(b);
        Long r1a = createRoom(p1), r1b = createRoom(p1), r2a = createRoom(p2), rq = createRoom(q);
        for (Long room : List.of(r1a, r1b, r2a, rq)) bulkInventory(room);
        String guestEmail = uniqueEmail("guest");
        String guestToken = registerAndLogin(guestEmail);
        String guestName = userRepo.findByEmail(guestEmail).orElseThrow().getFullName();
        Long b1 = confirmedBooking(guestToken, r1a, "Late arrival, quiet room");
        Long b2 = confirmedBooking(guestToken, r2a, null);
        Long bq = confirmedBooking(guestToken, rq, null);
        Long conv1 = openConversation(guestToken, b1);

        Map<String, Member> members = new java.util.LinkedHashMap<>();
        members.put("managerCompany", scopedMember(a, "MANAGER", "COMPANY:" + a.companyId()));
        members.put("managerP1", scopedMember(a, "MANAGER", "PROPERTY:" + p1));
        members.put("revenueCompany", scopedMember(a, "REVENUE", "COMPANY:" + a.companyId()));
        members.put("reservationsP1", scopedMember(a, "RESERVATIONS", "PROPERTY:" + p1));
        members.put("frontDeskP1", scopedMember(a, "FRONT_DESK", "PROPERTY:" + p1));
        members.put("financeCompany", scopedMember(a, "FINANCE", "COMPANY:" + a.companyId()));
        members.put("contentP1", scopedMember(a, "CONTENT", "PROPERTY:" + p1));
        members.put("housekeepingP1", scopedMember(a, "HOUSEKEEPING", "PROPERTY:" + p1));
        members.put("housekeepingUnit", scopedMember(a, "HOUSEKEEPING", "UNIT:" + r1a));
        members.put("viewerCompany", scopedMember(a, "VIEWER", "COMPANY:" + a.companyId()));
        fx = new Fixture(a, b, p1, p2, q, r1a, r1b, r2a, rq, b1, b2, bq, conv1, guestToken, guestName, members);
        return fx;
    }

    private Member scopedMember(Company company, String role, String scope) throws Exception {
        Member m = newMember(company, "VIEWER");
        if (!(role.equals("VIEWER") && scope.startsWith("COMPANY"))) {
            send(json(put("/api/partner/team/" + m.rowId() + "/grants"), grants(m.rowId(), role, scope)), company.ownerToken())
                .andExpect(status().isOk());
        }
        return new Member(login(m.email()), m.userId(), m.email(), m.rowId());
    }

    private Member newMember(Company company, String role) throws Exception {
        String email = uniqueEmail("member");
        registerAndLogin(email);
        User u = userRepo.findByEmail(email).orElseThrow();
        u.setRole("PARTNER");
        userRepo.save(u);
        Long rowId = body(json(post("/api/partner/team"), "{\"email\":\"" + email + "\",\"role\":\"" + role + "\"}"),
            company.ownerToken(), 201).get("id").asLong();
        return new Member(login(email), u.getId(), email, rowId);
    }

    private String grants(Long rowId, String role, String scope) {
        long version = teamMemberRepo.findById(rowId).orElseThrow().getVersion();
        return "{\"grants\":[{\"role\":\"" + role + "\",\"scope\":\"" + scope + "\"}],\"version\":" + version + "}";
    }

    private Company approvedCompany() throws Exception {
        String email = uniqueEmail("owner");
        String token = registerAndLogin(email);
        Long id = body(json(post("/api/partner/profile"), """
            {"businessName":"R3b Co %s","businessType":"HOTEL","representativeName":"R3b Owner",
             "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi, Da Nang"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8))), token).get("id").asLong();
        send(post("/api/partner/profile/submit"), token).andExpect(status().isOk());
        send(post("/api/admin/partners/" + id + "/approve"), adminToken()).andExpect(status().isOk());
        return new Company(login(email), id, userRepo.findByEmail(email).orElseThrow().getId(), email);
    }

    private Long createPublishedHotel(Company owner) throws Exception {
        Long id = body(json(post("/api/admin/places"), """
            {"name":"R3b Hotel %s","categoryId":%d,"subcategoryId":%d,"administrativeUnitId":%d,
             "address":"1 Test Street","priceLevel":2,"featured":false,"verified":false,"status":"DRAFT"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8),
                categoryRepo.findBySlug("accommodation").orElseThrow().getId(),
                categoryRepo.findBySlug("hotel").orElseThrow().getId(),
                locationRepo.findByCode("VT").orElseThrow().getId())), adminToken(), 201).get("id").asLong();
        for (String s : List.of("APPROVED", "PUBLISHED")) {
            send(json(patch("/api/admin/places/" + id + "/status"), "{\"status\":\"" + s + "\"}"), adminToken())
                .andExpect(status().isOk());
        }
        send(json(post("/api/admin/hotels"), """
            {"placeId":%d,"starRating":4,"checkInTime":"14:00:00","checkOutTime":"12:00:00","totalRooms":10,
             "availableRooms":10,"freeCancellation":false,"prepaymentRequired":false,"breakfastIncluded":false,
             "airportShuttle":false}""".formatted(id)), adminToken()).andExpect(status().isCreated());
        send(json(post("/api/admin/hotels/" + id + "/assign-owner"), "{\"partnerProfileId\":" + owner.companyId() + "}"),
            adminToken()).andExpect(status().isOk());
        return id;
    }

    private Long createRoom(Long placeId) throws Exception {
        return body(json(post("/api/admin/rooms"), """
            {"placeId":%d,"roomName":"R3b Room","roomCode":"R3B-%s","roomType":"DELUXE","bedType":"QUEEN","bedCount":1,
             "maxAdults":2,"maxChildren":1,"maxGuests":3,"roomSizeSqm":25.0,"floorNumber":2,"smokingAllowed":false,
             "breakfastIncluded":true,"freeCancellation":true,"instantConfirmation":true,"priceFrom":500000,
             "originalPrice":600000,"quantity":10,"availableQuantity":10,"active":true}
            """.formatted(placeId, UUID.randomUUID().toString().substring(0, 6))), adminToken(), 201).get("id").asLong();
    }

    private void bulkInventory(Long roomId) throws Exception {
        StringBuilder items = new StringBuilder();
        for (int i = 0; i < 40; i++) {
            if (i > 0) items.append(",");
            items.append(String.format("{\"inventoryDate\":\"%s\",\"totalInventory\":10,\"availableInventory\":10,"
                + "\"blockedInventory\":0,\"soldInventory\":0,\"maintenanceInventory\":0,\"stopSell\":false,"
                + "\"closedArrival\":false,\"closedDeparture\":false}", TODAY.minusDays(2).plusDays(i)));
        }
        send(json(post("/api/admin/rooms/" + roomId + "/inventory/bulk"), "{\"items\":[" + items + "]}"), adminToken())
            .andExpect(status().isOk());
    }

    private Long confirmedBooking(String guestToken, Long roomId, String specialRequest) throws Exception {
        String request = String.format("{\"roomId\":%d,\"checkIn\":\"%s\",\"checkOut\":\"%s\",\"adults\":2,\"children\":0,"
            + "\"numberOfRooms\":1%s}", roomId, TODAY.plusDays(3), TODAY.plusDays(5),
            specialRequest == null ? "" : ",\"specialRequest\":\"" + specialRequest + "\"");
        Long bookingId = body(json(post("/api/bookings"), request), guestToken, 201).get("id").asLong();
        Long paymentId = body(json(post("/api/payments"), "{\"bookingId\":" + bookingId + ",\"paymentMethod\":\"CASH\"}"),
            guestToken, 201).get("id").asLong();
        send(json(post("/api/payments/" + paymentId + "/mock-success"), "{}"), guestToken).andExpect(status().isOk());
        return bookingId;
    }

    private Long openConversation(String guestToken, Long bookingId) throws Exception {
        Long id = body(json(post("/api/me/conversations"), "{\"bookingId\":" + bookingId + ",\"subject\":\"Arrival\"}"),
            guestToken, 201).get("id").asLong();
        send(json(post("/api/me/conversations/" + id + "/messages"), "{\"body\":\"We arrive late\"}"), guestToken)
            .andExpect(status().is2xxSuccessful());
        return id;
    }

    private String voucherPayload(Long bookingId) throws Exception {
        return body(get("/api/me/bookings/" + bookingId + "/voucher"), fixture().guestToken()).get("qrPayload").asText();
    }

    // ── HTTP helpers ─────────────────────────────────────────────────────────

    private ResultActions send(MockHttpServletRequestBuilder request, String token) throws Exception {
        return mvc.perform(request.header("Authorization", "Bearer " + token));
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private JsonNode tree(String body) {
        try { return mapper.readTree(body); } catch (Exception e) { throw new IllegalStateException(e); }
    }

    private JsonNode body(MockHttpServletRequestBuilder request, String token) throws Exception {
        return body(request, token, 200);
    }

    private JsonNode body(MockHttpServletRequestBuilder request, String token, int expected) throws Exception {
        return tree(send(request, token).andExpect(status().is(expected)).andReturn().getResponse().getContentAsString());
    }

    private void ok(MockHttpServletRequestBuilder request, String token) throws Exception {
        send(request, token).andExpect(status().isOk());
    }

    private void ok(MockHttpServletRequestBuilder request, String token, int expected) throws Exception {
        send(request, token).andExpect(status().is(expected));
    }

    private void denied(MockHttpServletRequestBuilder request, String token) throws Exception {
        send(request, token).andExpect(status().isForbidden());
    }

    private void notFound(MockHttpServletRequestBuilder request, String token) throws Exception {
        send(request, token).andExpect(status().isNotFound());
    }

    private void notFound(MockHttpServletRequestBuilder request, String token, int expected) throws Exception {
        send(request, token).andExpect(status().is(expected));
    }

    private Set<Long> ids(MockHttpServletRequestBuilder request, String token) throws Exception {
        JsonNode list = body(request, token);
        Set<Long> ids = new TreeSet<>();
        list.forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }

    private List<Long> bookingIds(String token) throws Exception {
        List<Long> ids = new ArrayList<>();
        body(get("/api/partner/bookings").param("size", "100"), token).get("content").forEach(n -> ids.add(n.get("id").asLong()));
        return ids;
    }

    private static JsonNode find(JsonNode list, Long id) {
        for (JsonNode n : list) if (n.get("id").asLong() == id) return n;
        throw new AssertionError("id " + id + " not in " + list);
    }

    private static List<String> redacted(JsonNode node) {
        List<String> out = new ArrayList<>();
        node.get("redacted").forEach(r -> out.add(r.get("field").asText() + ":" + r.get("mode").asText()));
        return out;
    }

    private static void collectKeys(JsonNode node, Set<String> keys) {
        if (node.isObject()) {
            Iterator<String> names = node.fieldNames();
            while (names.hasNext()) {
                String name = names.next();
                keys.add(name);
                collectKeys(node.get(name), keys);
            }
        } else if (node.isArray()) {
            node.forEach(child -> collectKeys(child, keys));
        }
    }

    private static String mask(String name) {
        return com.example.planyourtrip.dto.RedactedField.maskName(name);
    }

    private List<String> titles(String token) throws Exception {
        List<String> titles = new ArrayList<>();
        body(get("/api/me/notifications"), token).forEach(n -> titles.add(n.get("title").asText()));
        return titles;
    }

    private static MockHttpServletRequestBuilder window(MockHttpServletRequestBuilder request) {
        return request.param("from", TODAY.minusDays(1).toString()).param("to", TODAY.plusDays(10).toString());
    }

    private static String ratePlanBody() {
        return """
            {"rateName":"R3b rate","rateType":"STANDARD","pricePerNight":450000,"startDate":"%s","endDate":"%s"}
            """.formatted(TODAY.plusDays(20), TODAY.plusDays(25));
    }

    private String hotelCreateBody() {
        return """
            {"name":"R3b denied","categoryId":%d,"administrativeUnitId":%d,"address":"2 Test Street","starRating":3,
             "checkIn":"14:00:00","checkOut":"12:00:00"}
            """.formatted(categoryRepo.findBySlug("hotel").orElseThrow().getId(),
                locationRepo.findByCode("VT").orElseThrow().getId());
    }

    private static String settingsBody() {
        return """
            {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh","notificationEmailEnabled":true,
             "notificationSmsEnabled":false,"notificationInAppEnabled":true,"bookingNotificationEnabled":true,
             "paymentNotificationEnabled":true,"reviewNotificationEnabled":true,"promotionNotificationEnabled":true}
            """;
    }

    private static String promotionBody(String targetType, Long targetId) {
        return """
            {"name":"R3b promo","promotionType":"GENERAL","discountType":"PERCENTAGE","discountValue":10,
             "startDate":"%s","endDate":"%s","targetType":"%s","targetId":%d,"active":true,"priority":1,"stackable":false}
            """.formatted(TODAY, TODAY.plusDays(10), targetType, targetId);
    }

    /** The stored room as a full PUT body, with an optional new name (content) and/or new priceFrom (commercial). */
    private String roomBody(JsonNode room, String newName, String newPriceFrom) throws Exception {
        com.fasterxml.jackson.databind.node.ObjectNode body = mapper.createObjectNode();
        for (String f : List.of("roomName", "roomCode", "roomType", "description", "bedType", "bedCount", "maxAdults",
                "maxChildren", "maxGuests", "roomSizeSqm", "floorNumber", "smokingAllowed", "breakfastIncluded",
                "freeCancellation", "instantConfirmation", "priceFrom", "originalPrice", "quantity", "availableQuantity")) {
            if (room.has(f)) body.set(f, room.get(f));
        }
        com.fasterxml.jackson.databind.node.ArrayNode amenities = body.putArray("amenitySlugs");
        if (room.has("amenities")) room.get("amenities").forEach(a -> amenities.add(a.get("slug").asText()));
        if (newName != null) body.put("roomName", newName);
        if (newPriceFrom != null) body.put("priceFrom", new java.math.BigDecimal(newPriceFrom));
        return mapper.writeValueAsString(body);
    }

    /** A calendar day as a PUT body; optionally a changed count and/or a changed restriction flag. */
    private String dayBody(JsonNode day, LocalDate date, boolean changeCount, boolean changeFlag) {
        int total = day.get("totalInventory").asInt();
        return String.format("{\"inventoryDate\":\"%s\",\"totalInventory\":%d,\"availableInventory\":%d,"
                + "\"blockedInventory\":%d,\"soldInventory\":%d,\"maintenanceInventory\":%d,\"stopSell\":%s,"
                + "\"closedArrival\":%s,\"closedDeparture\":%s}", date,
            total, changeCount ? Math.max(0, day.get("availableInventory").asInt() - 1) : day.get("availableInventory").asInt(),
            day.get("blockedInventory").asInt(), day.get("soldInventory").asInt(), day.get("maintenanceInventory").asInt(),
            day.get("stopSell").asBoolean(), changeFlag != day.get("closedArrival").asBoolean(),
            day.get("closedDeparture").asBoolean());
    }

    private String staleToken(Long userId) {
        User u = userRepo.findById(userId).orElseThrow();
        return jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion(),
            Instant.now().minus(StepUpPolicy.FRESHNESS).minusSeconds(60));
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email) throws Exception {
        return login(email, PASSWORD);
    }

    private String login(String email, String password) throws Exception {
        return tree(mvc.perform(json(post("/api/auth/login"),
                "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("token").asText();
    }

    private String registerAndLogin(String email) throws Exception {
        return tree(mvc.perform(json(post("/api/auth/register"),
                "{\"fullName\":\"Tran Thien Guest\",\"email\":\"" + email + "\",\"password\":\"" + PASSWORD + "\"}"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString()).get("token").asText();
    }

    private static String uniqueEmail(String prefix) {
        return "r3b-" + prefix + "-" + counter.getAndIncrement() + "-"
            + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }
}
