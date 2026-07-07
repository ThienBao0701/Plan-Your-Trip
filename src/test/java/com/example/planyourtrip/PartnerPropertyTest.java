package com.example.planyourtrip;

import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * PartnerPropertyTest — Phase 6.2.
 * Every scenario provisions its own throwaway partner profile and hotel place
 * (never mutating the shared seeded Grand Palace Hotel) so tests stay isolated
 * from each other and from other test classes sharing the same H2 instance.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerPropertyTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;

    private String adminToken;
    private static final AtomicInteger counter = new AtomicInteger(1);

    private Long accCategoryId;
    private Long hotelSubcategoryId;
    private Long locationId;

    @BeforeEach
    void setup() {
        accCategoryId      = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        locationId         = locationRepo.findByCode("VT").orElseThrow().getId();
    }

    private record PartnerCtx(String token, Long profileId) {}
    private record OwnedHotel(PartnerCtx partner, Long hotelId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // LIST / VIEW
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_listsOwnHotels() throws Exception {
        OwnedHotel h = setupOwnedHotel("ListMine");

        String body = mvc.perform(get("/api/partner/hotels")
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode arr = mapper.readTree(body);
        assertTrue(arr.isArray());
        boolean found = false;
        for (JsonNode n : arr) if (n.get("id").asLong() == h.hotelId()) found = true;
        assertTrue(found, "Owned hotel must appear in getMyHotels()");
    }

    @Test
    void partner_cannotViewAnotherHotel() throws Exception {
        OwnedHotel h = setupOwnedHotel("ViewOther");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(get("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + stranger.token()))
            .andExpect(status().isNotFound());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // UPDATES
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_updatesHotel() throws Exception {
        OwnedHotel h = setupOwnedHotel("BasicUpdate");
        String newSlug = "partner-updated-" + UUID.randomUUID().toString().substring(0, 8);

        String body = mvc.perform(put("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(basicInfoJson("Updated Hotel Name", newSlug)))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("Updated Hotel Name", res.get("name").asText());
        assertEquals(newSlug, res.get("slug").asText());
        assertEquals("New short description", res.get("shortDescription").asText());
    }

    @Test
    void partner_updatesContact() throws Exception {
        OwnedHotel h = setupOwnedHotel("ContactUpdate");

        String req = """
                {"phone":"0909999999","email":"contact@hotel.com","website":"https://hotel.com",
                 "facebook":"https://fb.com/hotel","instagram":"https://instagram.com/hotel"}
                """;

        String body = mvc.perform(put("/api/partner/hotels/" + h.hotelId() + "/contact")
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("0909999999", res.get("phone").asText());
        assertEquals("contact@hotel.com", res.get("email").asText());
        assertEquals("https://hotel.com", res.get("website").asText());
        assertEquals("https://fb.com/hotel", res.get("facebook").asText());
        assertEquals("https://instagram.com/hotel", res.get("instagram").asText());
    }

    @Test
    void partner_updatesPolicies() throws Exception {
        OwnedHotel h = setupOwnedHotel("PolicyUpdate");

        String req = """
                {"checkIn":"15:00:00","checkOut":"11:00:00","childrenPolicy":"Children welcome",
                 "petPolicy":"No pets allowed","smokingPolicy":"Non-smoking property"}
                """;

        String body = mvc.perform(put("/api/partner/hotels/" + h.hotelId() + "/policies")
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals("15:00:00", res.get("checkIn").asText());
        assertEquals("11:00:00", res.get("checkOut").asText());
        assertEquals("Children welcome", res.get("childrenPolicy").asText());
        assertEquals("No pets allowed", res.get("petPolicy").asText());
        assertEquals("Non-smoking property", res.get("smokingPolicy").asText());
    }

    @Test
    void partner_updatesLocation() throws Exception {
        OwnedHotel h = setupOwnedHotel("LocationUpdate");

        String req = """
                {"latitude":10.5,"longitude":107.1,"address":"999 New Address, Vung Tau"}
                """;

        String body = mvc.perform(put("/api/partner/hotels/" + h.hotelId() + "/location")
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode res = mapper.readTree(body);
        assertEquals(10.5, res.get("latitude").asDouble());
        assertEquals(107.1, res.get("longitude").asDouble());
        assertEquals("999 New Address, Vung Tau", res.get("address").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ACTIVATE / DEACTIVATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_activatesHotel() throws Exception {
        OwnedHotel h = setupOwnedHotel("Activate");

        mvc.perform(patch("/api/partner/hotels/" + h.hotelId() + "/deactivate")
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk());

        String body = mvc.perform(patch("/api/partner/hotels/" + h.hotelId() + "/activate")
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertTrue(mapper.readTree(body).get("active").asBoolean());
    }

    @Test
    void partner_deactivatesHotel() throws Exception {
        OwnedHotel h = setupOwnedHotel("Deactivate");

        String body = mvc.perform(patch("/api/partner/hotels/" + h.hotelId() + "/deactivate")
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        assertFalse(mapper.readTree(body).get("active").asBoolean());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GUARDED FIELDS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partner_cannotModifyFeatured() throws Exception {
        OwnedHotel h = setupOwnedHotel("FeaturedGuard");
        mvc.perform(patch("/api/admin/places/" + h.hotelId() + "/featured")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        mvc.perform(put("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(basicInfoJson("Featured Guard Updated", uniqSlug())))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(body).get("featured").asBoolean(),
            "Featured flag must remain unaffected by partner updates");
    }

    @Test
    void partner_cannotModifyVerified() throws Exception {
        OwnedHotel h = setupOwnedHotel("VerifiedGuard");
        mvc.perform(patch("/api/admin/places/" + h.hotelId() + "/verified")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"value\":true}"))
            .andExpect(status().isOk());

        mvc.perform(put("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(basicInfoJson("Verified Guard Updated", uniqSlug())))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(body).get("verified").asBoolean(),
            "Verified flag must remain unaffected by partner updates");
    }

    @Test
    void partner_cannotModifyOwner() throws Exception {
        OwnedHotel h = setupOwnedHotel("OwnerGuard");

        mvc.perform(put("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(basicInfoJson("Owner Guard Updated", uniqSlug())))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertEquals(h.partner().profileId(), mapper.readTree(body).get("ownerProfileId").asLong(),
            "Owner must remain unaffected by partner updates");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ADMIN ASSIGN OWNER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void admin_assignsOwner() throws Exception {
        Long hotelId = createHotelPlace(uniq("AssignOwner"));
        PartnerCtx partner = createAndApprovePartner();

        JsonNode res = assignOwner(hotelId, partner.profileId());
        assertEquals(partner.profileId(), res.get("ownerProfileId").asLong());
    }

    @Test
    void notification_createdOnAssignment() throws Exception {
        Long hotelId = createHotelPlace(uniq("AssignNotify"));
        PartnerCtx partner = createAndApprovePartner();
        assignOwner(hotelId, partner.profileId());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "Hotel assigned to your account"));
    }

    @Test
    void notification_createdOnPropertyUpdate() throws Exception {
        OwnedHotel h = setupOwnedHotel("UpdateNotify");

        mvc.perform(put("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + h.partner().token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(basicInfoJson("Update Notify Hotel", uniqSlug())))
            .andExpect(status().isOk());

        String body = mvc.perform(get("/api/me/notifications")
                .header("Authorization", "Bearer " + h.partner().token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(containsTitle(mapper.readTree(body), "Property updated"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP / AUTH ENFORCEMENT
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownership_enforcedOnMutation() throws Exception {
        OwnedHotel h = setupOwnedHotel("OwnershipEnforce");
        PartnerCtx stranger = createAndApprovePartner();

        mvc.perform(put("/api/partner/hotels/" + h.hotelId())
                .header("Authorization", "Bearer " + stranger.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(basicInfoJson("Hijacked Name", uniqSlug())))
            .andExpect(status().isNotFound());
    }

    @Test
    void unauthenticated_returns401() throws Exception {
        mvc.perform(get("/api/partner/hotels"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void admin_stillHasUnrestrictedAccess() throws Exception {
        OwnedHotel h = setupOwnedHotel("AdminUnrestricted");

        mvc.perform(get("/api/admin/places/" + h.hotelId())
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(h.hotelId()));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private OwnedHotel setupOwnedHotel(String namePrefix) throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long hotelId = createHotelPlace(uniq(namePrefix));
        assignOwner(hotelId, partner.profileId());
        return new OwnedHotel(partner, hotelId);
    }

    private String adminToken() throws Exception {
        if (adminToken == null) adminToken = login("admin@planyourtrip.com", "admin123456");
        return adminToken;
    }

    private String login(String email, String password) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Partner Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = "partner-prop-" + counter.getAndIncrement() + "@test.com";
        String token = registerAndLogin(email);

        String profileReq = """
                {"businessName":"Test Hotel Co %d","businessType":"HOTEL","representativeName":"Partner Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(counter.get());
        String profileBody = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        Long profileId = mapper.readTree(profileBody).get("id").asLong();

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());

        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        return new PartnerCtx(token, profileId);
    }

    private Long createHotelPlace(String name) throws Exception {
        String req = """
                {
                  "name": "%s",
                  "categoryId": %d,
                  "subcategoryId": %d,
                  "administrativeUnitId": %d,
                  "address": "123 Test Street, Vung Tau",
                  "priceLevel": 2,
                  "featured": false,
                  "verified": false,
                  "status": "DRAFT"
                }
                """.formatted(name, accCategoryId, hotelSubcategoryId, locationId);

        String resp = mvc.perform(post("/api/admin/places")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(req))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        Long id = mapper.readTree(resp).get("id").asLong();

        adminPatchStatus(id, "APPROVED");
        adminPatchStatus(id, "PUBLISHED");
        return id;
    }

    private void adminPatchStatus(Long id, String status) throws Exception {
        mvc.perform(patch("/api/admin/places/" + id + "/status")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"" + status + "\"}"))
            .andExpect(status().isOk());
    }

    private JsonNode assignOwner(Long hotelId, Long partnerProfileId) throws Exception {
        String body = mvc.perform(post("/api/admin/hotels/" + hotelId + "/assign-owner")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"partnerProfileId\":" + partnerProfileId + "}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private String basicInfoJson(String name, String slug) {
        return """
                {"name":"%s","shortDescription":"New short description","description":"New long description","slug":"%s"}
                """.formatted(name, slug);
    }

    private String uniq(String prefix) {
        return prefix + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String uniqSlug() {
        return "partner-updated-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private boolean containsTitle(JsonNode arr, String title) {
        for (JsonNode n : arr) {
            if (title.equals(n.get("title").asText())) return true;
        }
        return false;
    }
}
