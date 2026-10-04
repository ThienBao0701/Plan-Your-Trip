package com.example.planyourtrip;

import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.PartnerTeamMember;
import com.example.planyourtrip.model.PromotionTargetType;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.example.planyourtrip.security.rbac.PartnerAccessContext;
import com.example.planyourtrip.security.rbac.PartnerPermission;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import com.example.planyourtrip.security.rbac.ScopeType;
import com.example.planyourtrip.service.PartnerAccessService;
import com.example.planyourtrip.service.PartnerResourceTargetResolver;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * R1 — the RBAC kernel behind the real HTTP stack: the three system roles keep their boundaries, the
 * registrant keeps every power over their own company, team members gain nothing, the approval gate now
 * carries {@code PARTNER_NOT_APPROVED}, and resource scope always comes from stored data.
 *
 * <p>Every scenario provisions its own partners through the public API (as {@code PartnerPropertyCrudTest}
 * does) and the class is not {@code @Transactional}, so each request commits as in production.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RbacKernelHttpTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired UserRepository userRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired PartnerTeamMemberRepository teamMemberRepo;
    @Autowired JwtService jwt;
    @Autowired PartnerAccessService partnerAccess;
    @Autowired PartnerResourceTargetResolver targets;

    private static final AtomicInteger counter = new AtomicInteger(1);
    private static final String SETTINGS_BODY = """
        {"defaultLanguage":"en","timezone":"Asia/Ho_Chi_Minh",
         "notificationEmailEnabled":true,"notificationSmsEnabled":false,"notificationInAppEnabled":true,
         "bookingNotificationEnabled":true,"paymentNotificationEnabled":true,
         "reviewNotificationEnabled":true,"promotionNotificationEnabled":true}
        """;
    private static final String PAYOUT_BODY = """
        {"accountHolderName":"Rbac Holder","bankName":"Rbac Bank","bankAccountNumber":"1234567890",
         "payoutMethod":"BANK_TRANSFER"}
        """;

    private String adminToken;

    private record Partner(String token, Long profileId, Long userId, String email) {}

    // ═══════════════════════════════════════════════════════════════════════
    // System role boundaries (unchanged)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void userCannotReachPartnerOrAdminTrees() throws Exception {
        String user = registerAndLogin(uniqueEmail("traveller"));
        expect(get("/api/partner/hotels"), user, HttpStatus.FORBIDDEN);
        expect(get("/api/partner/bookings"), user, HttpStatus.FORBIDDEN);
        expect(get("/api/admin/partners"), user, HttpStatus.FORBIDDEN);
    }

    @Test
    void partnerCannotReachTheAdminTree() throws Exception {
        Partner partner = approvedPartner();
        expect(get("/api/admin/partners"), partner.token(), HttpStatus.FORBIDDEN);
        expect(get("/api/admin/activity-logs"), partner.token(), HttpStatus.FORBIDDEN);
    }

    @Test
    void adminBehaviourIsUnchanged() throws Exception {
        expect(get("/api/admin/partners"), adminToken(), HttpStatus.OK);
        expect(get("/api/admin/places"), adminToken(), HttpStatus.OK);
        expect(get("/api/admin/activity-logs"), adminToken(), HttpStatus.OK);
        // an administrator still has no partner workspace of their own
        mvc.perform(auth(get("/api/partner/hotels"), adminToken()))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.message").value("Partner profile not found"));
    }

    @Test
    void missingOrInvalidCredentialsAreUnauthorized() throws Exception {
        mvc.perform(get("/api/partner/hotels")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/admin/partners")).andExpect(status().isUnauthorized());
        expect(get("/api/partner/hotels"), "not-a-jwt", HttpStatus.UNAUTHORIZED);
        expect(get("/api/admin/partners"), "a.b.c", HttpStatus.UNAUTHORIZED);
    }

    @Test
    void anUnknownStoredRoleFailsClosed() throws Exception {
        for (String role : new String[] {"SUPER_PARTNER", "SUPER_ADMIN", "partner", "OWNER"}) {
            User u = new User();
            u.setFullName("Unknown Role");
            u.setEmail(uniqueEmail("role"));
            u.setPasswordHash("x");
            u.setRole(role);
            u = userRepo.saveAndFlush(u);
            String token = jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion());
            expect(get("/api/partner/hotels"), token, HttpStatus.UNAUTHORIZED);
            expect(get("/api/admin/partners"), token, HttpStatus.UNAUTHORIZED);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Registrant and approval gate (behaviour preserved)
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void registrantKeepsEveryPowerOverTheirCompany() throws Exception {
        Partner partner = approvedPartner();
        Long propertyId = createProperty(partner);
        expect(get("/api/partner/hotels"), partner.token(), HttpStatus.OK);
        expect(get("/api/partner/hotels/" + propertyId), partner.token(), HttpStatus.OK);
        expect(get("/api/partner/extranet/home"), partner.token(), HttpStatus.OK);
        expect(get("/api/partner/settings"), partner.token(), HttpStatus.OK);
        expect(json(put("/api/partner/settings"), SETTINGS_BODY), partner.token(), HttpStatus.OK);
        expect(json(put("/api/partner/payout-account"), PAYOUT_BODY), partner.token(), HttpStatus.OK);
        expect(get("/api/partner/team"), partner.token(), HttpStatus.OK);
        expect(get("/api/partner/finance/overview"), partner.token(), HttpStatus.OK);
    }

    @Test
    void aCompanyThatIsNotApprovedIsRefusedWithAStableCode() throws Exception {
        Partner partner = approvedPartner();
        mvc.perform(auth(post("/api/admin/partners/" + partner.profileId() + "/suspend"), adminToken())
                .contentType(MediaType.APPLICATION_JSON).content("{\"reason\":\"rbac test\"}"))
            .andExpect(status().isOk());

        for (String path : new String[] {"/api/partner/hotels", "/api/partner/settings", "/api/partner/team"}) {
            mvc.perform(auth(get(path), partner.token()))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("PARTNER_NOT_APPROVED"))
                .andExpect(jsonPath("$.message").value("Partner profile is not approved"));
        }
    }

    @Test
    void aPartnerAccountWithoutAWorkspaceIsNotFound() throws Exception {
        User u = new User();
        u.setFullName("No Workspace");
        u.setEmail(uniqueEmail("noworkspace"));
        u.setPasswordHash("x");
        u.setRole("PARTNER");
        u = userRepo.saveAndFlush(u);
        String token = jwt.createToken(u.getId(), u.getEmail(), u.getTokenVersion());
        for (String path : new String[] {"/api/partner/hotels", "/api/partner/settings"}) {
            mvc.perform(auth(get(path), token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Partner profile not found"));
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Team members gain nothing in R1
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void frontDeskMemberKeepsOnlyTodaysSettingsReads() throws Exception {
        Partner owner = approvedPartner();
        Long propertyId = createProperty(owner);
        String member = member(owner, "FRONT_DESK");

        for (String path : new String[] {"/api/partner/hotels", "/api/partner/hotels/" + propertyId,
                "/api/partner/bookings", "/api/partner/extranet/home", "/api/partner/finance/overview"}) {
            mvc.perform(auth(get(path), member))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Partner profile not found"));
        }
        expect(get("/api/partner/settings"), member, HttpStatus.OK);
        expect(get("/api/partner/team"), member, HttpStatus.OK);
        mvc.perform(auth(json(put("/api/partner/settings"), SETTINGS_BODY), member))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.code").value("PERMISSION_DENIED"))
            .andExpect(jsonPath("$.message").value("Your role does not allow you to manage business/notification settings"));
        mvc.perform(auth(json(put("/api/partner/payout-account"), PAYOUT_BODY), member))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.message").value("Your role does not allow you to manage payout metadata"));
        mvc.perform(auth(json(post("/api/partner/team"),
                "{\"email\":\"" + registerPlainUser() + "\",\"role\":\"VIEWER\"}"), member))
            .andExpect(status().isForbidden())
            .andExpect(jsonPath("$.message").value("Only the partner owner can manage team members"));
    }

    @Test
    void managerAndFinanceKeepExactlyTheirLegacyWrites() throws Exception {
        Partner owner = approvedPartner();
        String manager = member(owner, "MANAGER");
        String finance = member(owner, "FINANCE");

        expect(json(put("/api/partner/settings"), SETTINGS_BODY), manager, HttpStatus.OK);
        expect(json(put("/api/partner/payout-account"), PAYOUT_BODY), manager, HttpStatus.FORBIDDEN);
        expect(json(put("/api/partner/payout-account"), PAYOUT_BODY), finance, HttpStatus.OK);
        expect(json(put("/api/partner/settings"), SETTINGS_BODY), finance, HttpStatus.FORBIDDEN);
        expect(get("/api/partner/hotels"), manager, HttpStatus.NOT_FOUND);
        expect(get("/api/partner/finance/settlements"), finance, HttpStatus.NOT_FOUND);
    }

    @Test
    void aNonRegistrantOwnerManagesTheTeamButStillHasNoOperationalAccess() throws Exception {
        Partner owner = approvedPartner();
        String coOwner = member(owner, "OWNER");

        mvc.perform(auth(json(post("/api/partner/team"),
                "{\"email\":\"" + registerPlainUser() + "\",\"role\":\"VIEWER\"}"), coOwner))
            .andExpect(status().isCreated());
        expect(get("/api/partner/hotels"), coOwner, HttpStatus.NOT_FOUND);
        expect(get("/api/partner/extranet/home"), coOwner, HttpStatus.NOT_FOUND);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Scope always comes from stored data
    // ═══════════════════════════════════════════════════════════════════════

    @Test
    void anotherCompanysResourceIsNotFoundOverHttp() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long foreign = createProperty(b);
        mvc.perform(auth(get("/api/partner/hotels/" + foreign), a.token()))
            .andExpect(status().isNotFound());
        // a filter naming another company's property is answered like a missing id
        expect(get("/api/partner/finance/overview").param("hotelId", foreign.toString()), a.token(), HttpStatus.NOT_FOUND);
    }

    @Test
    void resourceTargetsAreResolvedFromStoredOwnership() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long property = createProperty(a);
        Long foreign = createProperty(b);
        Long room = createRoom(property);
        Long hotelDetailId = hotelDetailRepo.findByPlaceId(property).orElseThrow().getId();

        assertEquals(Optional.of(ScopePath.property(a.profileId(), property)), targets.resolve(ResourceType.PROPERTY, property));
        assertEquals(Optional.of(ScopePath.unit(a.profileId(), property, room)), targets.resolve(ResourceType.ROOM, room));
        assertEquals(Optional.of(ScopePath.unit(a.profileId(), property, room)), targets.resolve(ResourceType.CALENDAR, room));
        assertEquals(Optional.of(ScopePath.property(b.profileId(), foreign)), targets.resolve(ResourceType.PROPERTY, foreign));
        assertTrue(targets.resolve(ResourceType.PROPERTY, Long.MAX_VALUE).isEmpty());
        assertTrue(targets.resolve(ResourceType.ROOM, null).isEmpty());
        assertTrue(targets.resolve(null, property).isEmpty());

        // a HOTEL promotion target is a hotel_details id resolved through its place, never a place id
        assertEquals(Optional.of(ScopePath.property(a.profileId(), property)),
            targets.resolvePromotionTarget(PromotionTargetType.HOTEL, hotelDetailId));
        assertEquals(Optional.of(ScopePath.unit(a.profileId(), property, room)),
            targets.resolvePromotionTarget(PromotionTargetType.ROOM, room));
        assertTrue(targets.resolvePromotionTarget(PromotionTargetType.ALL, hotelDetailId).isEmpty());

        // stored grant scopes resolve only inside the company that holds them
        assertEquals(Optional.of(ScopePath.company(a.profileId())),
            targets.resolveGrantScope(a.profileId(), new ScopeRef(ScopeType.COMPANY, a.profileId())));
        assertEquals(Optional.of(ScopePath.unit(a.profileId(), property, room)),
            targets.resolveGrantScope(a.profileId(), new ScopeRef(ScopeType.UNIT, room)));
        assertTrue(targets.resolveGrantScope(a.profileId(), new ScopeRef(ScopeType.PROPERTY, foreign)).isEmpty());
        assertTrue(targets.resolveGrantScope(a.profileId(), new ScopeRef(ScopeType.COMPANY, b.profileId())).isEmpty());
    }

    @Test
    void theKernelDecidesOnTheResolvedTargetNotOnTheCallersClaim() throws Exception {
        Partner a = approvedPartner();
        Partner b = approvedPartner();
        Long property = createProperty(a);
        Long foreign = createProperty(b);
        PartnerAccessContext ctx = partnerAccess.requireRegistrantWorkspace(a.userId());

        assertEquals(ScopePath.property(a.profileId(), property),
            partnerAccess.requireResource(ctx, PartnerPermission.PROPERTY_CONTENT_EDIT, ResourceType.PROPERTY, property,
                "Hotel not found: " + property));
        ApiException refused = assertThrows(ApiException.class, () -> partnerAccess.requireResource(ctx,
            PartnerPermission.PROPERTY_VIEW, ResourceType.PROPERTY, foreign, "Hotel not found: " + foreign));
        assertEquals(HttpStatus.NOT_FOUND, refused.status());
        assertEquals("Hotel not found: " + foreign, refused.getMessage());

        assertTrue(partnerAccess.requireCollection(ctx, PartnerPermission.BOOKING_VIEW).companyWide());
        partnerAccess.requireCompanyPermission(ctx, PartnerPermission.PAYOUT_ACCOUNT_MANAGE, null);

        String memberEmail = registerPlainUser();
        addMember(a, memberEmail, "VIEWER");
        Long memberId = userRepo.findByEmail(memberEmail).orElseThrow().getId();
        PartnerTeamMember row = teamMemberRepo.findByPartnerProfileIdOrderByCreatedAtAsc(a.profileId()).stream()
            .filter(m -> m.getUser().getId().equals(memberId)).findFirst().orElseThrow();
        assertEquals(Optional.of(ScopePath.company(a.profileId())), targets.resolve(ResourceType.MEMBERSHIP, row.getId()));

        PartnerAccessContext viewer = partnerAccess.requireTeamWorkspace(memberId);
        assertFalse(viewer.registrant());
        ApiException denied = assertThrows(ApiException.class,
            () -> partnerAccess.requireCompanyPermission(viewer, PartnerPermission.SETTINGS_EDIT, "denied"));
        assertEquals(HttpStatus.FORBIDDEN, denied.status());
        assertEquals("PERMISSION_DENIED", denied.code());
        // the operational resolution still refuses a member outright
        ApiException notFound = assertThrows(ApiException.class, () -> partnerAccess.requireRegistrantWorkspace(memberId));
        assertEquals(HttpStatus.NOT_FOUND, notFound.status());
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Helpers
    // ═══════════════════════════════════════════════════════════════════════

    private void expect(MockHttpServletRequestBuilder request, String token, HttpStatus expected) throws Exception {
        mvc.perform(auth(request, token)).andExpect(status().is(expected.value()));
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder request, String token) {
        return request.header("Authorization", "Bearer " + token);
    }

    private static MockHttpServletRequestBuilder json(MockHttpServletRequestBuilder request, String body) {
        return request.contentType(MediaType.APPLICATION_JSON).content(body);
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(json(post("/api/auth/login"),
                "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private static String uniqueEmail(String prefix) {
        return "rbac-" + prefix + "-" + counter.getAndIncrement() + "-"
            + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(json(post("/api/auth/register"),
                "{\"fullName\":\"Rbac Tester\",\"email\":\"" + email + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerPlainUser() throws Exception {
        String email = uniqueEmail("member");
        registerAndLogin(email);
        return email;
    }

    private Partner approvedPartner() throws Exception {
        String email = uniqueEmail("partner");
        String token = registerAndLogin(email);
        String profile = """
            {"businessName":"Rbac Co %s","businessType":"HOTEL","representativeName":"Rbac Tester",
             "phone":"0901234567","email":"contact@example.com","address":"1 Le Loi, Da Nang"}
            """.formatted(UUID.randomUUID().toString().substring(0, 8));
        Long profileId = mapper.readTree(mvc.perform(auth(json(post("/api/partner/profile"), profile), token))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).get("id").asLong();
        mvc.perform(auth(post("/api/partner/profile/submit"), token)).andExpect(status().isOk());
        mvc.perform(auth(post("/api/admin/partners/" + profileId + "/approve"), adminToken()))
            .andExpect(status().isOk());
        return new Partner(token, profileId, userRepo.findByEmail(email).orElseThrow().getId(), email);
    }

    private void addMember(Partner owner, String email, String role) throws Exception {
        mvc.perform(auth(json(post("/api/partner/team"),
                "{\"email\":\"" + email + "\",\"role\":\"" + role + "\"}"), owner.token()))
            .andExpect(status().isCreated());
    }

    private String member(Partner owner, String role) throws Exception {
        String email = registerPlainUser();
        addMember(owner, email, role);
        return login(email, "password123");
    }

    private Long createProperty(Partner partner) throws Exception {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", "Rbac Stay " + UUID.randomUUID().toString().substring(0, 8));
        body.put("categoryId", categoryRepo.findBySlug("accommodation").orElseThrow().getId());
        body.put("subcategoryId", categoryRepo.findBySlug("hotel").orElseThrow().getId());
        body.put("administrativeUnitId", locationRepo.findByCode("VT").orElseThrow().getId());
        body.put("address", "15 Thuy Van, Vung Tau");
        body.put("starRating", 3);
        body.put("checkIn", "14:00:00");
        body.put("checkOut", "12:00:00");
        String response = mvc.perform(auth(json(post("/api/partner/hotels"), mapper.writeValueAsString(body)),
                partner.token()))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        return mapper.readTree(response).get("id").asLong();
    }

    private Long createRoom(Long placeId) throws Exception {
        String body = """
            {"placeId":%d,"roomName":"Rbac Room","roomCode":"RB-%s","roomType":"STANDARD","bedType":"DOUBLE",
             "bedCount":1,"maxAdults":2,"maxChildren":0,"maxGuests":2,"priceFrom":100.00,"originalPrice":120.00,
             "quantity":5,"availableQuantity":5}
            """.formatted(placeId, UUID.randomUUID().toString().substring(0, 6));
        JsonNode room = mapper.readTree(mvc.perform(auth(json(post("/api/admin/rooms"), body), adminToken()))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());
        return room.get("id").asLong();
    }
}
