package com.example.planyourtrip;

import com.example.planyourtrip.model.AdministrativeUnit;
import com.example.planyourtrip.model.Amenity;
import com.example.planyourtrip.model.Category;
import com.example.planyourtrip.model.UnitType;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.AmenityRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.security.JwtService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase C — partner property CRUD on the canonical {@code Place} + {@code HotelDetail} model.
 *
 * <p>What this class is here to prove, in the backend's own words rather than a client's:
 *
 * <ul>
 *   <li><b>Only an approved partner may create.</b> An unapproved profile, a plain user, an
 *       administrator without a partner profile and an account whose stored role is not one of the
 *       three known ones are each refused, with the status the canonical authorization produces.</li>
 *   <li><b>A tenant sees and touches only its own.</b> Every read and every mutation of another
 *       partner's property answers 404 — the same answer an id that does not exist gets — and the
 *       target's data is re-read afterwards to show it did not change.</li>
 *   <li><b>A created property is a draft and stays one.</b> No field of this contract moves the
 *       status; a {@code status} sent in the body changes nothing; and the public place API does not
 *       return the draft while it keeps returning a published place.</li>
 *   <li><b>Reference data is the catalogue's.</b> Unknown, inactive, non-accommodation, wrongly
 *       parented, country-level and room-level ids are refused rather than silently ignored.</li>
 * </ul>
 *
 * <p>Like {@code PartnerPropertyTest}, every scenario provisions its own throwaway partner and
 * property rather than mutating seeded data, and the class is deliberately not {@code @Transactional}
 * so each request commits exactly as it would in production.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerPropertyCrudTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository locationRepo;
    @Autowired AmenityRepository amenityRepo;
    @Autowired UserRepository userRepo;
    @Autowired JwtService jwt;

    private static final AtomicInteger counter = new AtomicInteger(1);

    private String adminToken;

    private Long accommodationCategoryId;
    private Long hotelSubcategoryId;
    private Long resortSubcategoryId;
    private Long foodCategoryId;
    private Long restaurantSubcategoryId;
    private Long areaLocationId;
    private Long cityLocationId;
    private Long countryLocationId;
    private Long generalAmenityId;
    private Long hotelAmenityId;
    private Long roomAmenityId;

    @BeforeEach
    void setup() {
        accommodationCategoryId = categoryRepo.findBySlug("accommodation").orElseThrow().getId();
        hotelSubcategoryId = categoryRepo.findBySlug("hotel").orElseThrow().getId();
        resortSubcategoryId = categoryRepo.findBySlug("resort").orElseThrow().getId();
        foodCategoryId = categoryRepo.findBySlug("food").orElseThrow().getId();
        restaurantSubcategoryId = categoryRepo.findBySlug("restaurant").orElseThrow().getId();
        areaLocationId = locationRepo.findByCode("VT").orElseThrow().getId();
        cityLocationId = locationRepo.findByCode("DNG").orElseThrow().getId();
        countryLocationId = locationRepo.findByCode("VN").orElseThrow().getId();
        generalAmenityId = amenityRepo.findBySlug("free-wifi").orElseThrow().getId();
        hotelAmenityId = amenityRepo.findBySlug("swimming-pool").orElseThrow().getId();
        roomAmenityId = amenityRepo.findBySlug("private-bathroom").orElseThrow().getId();
    }

    private record PartnerCtx(String token, Long profileId, Long userId) {}

    // ═══════════════════════════════════════════════════════════════════════════
    // CREATE
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void approvedPartner_createsDraftProperty() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String name = uniq("Bay View Stay");

        JsonNode created = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(name))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());

        assertEquals("DRAFT", created.get("status").asText(), "a new property is a draft");
        assertEquals(name, created.get("name").asText());
        assertEquals(partner.profileId(), created.get("ownerProfileId").asLong());
        assertFalse(created.get("slug").asText().isBlank(), "the slug is derived server-side");
        assertFalse(created.get("featured").asBoolean());
        assertFalse(created.get("verified").asBoolean());

        // The catalogue references came back resolved, not echoed.
        assertEquals(accommodationCategoryId, created.get("category").get("id").asLong());
        assertEquals(hotelSubcategoryId, created.get("subcategory").get("id").asLong());
        assertEquals(areaLocationId, created.get("administrativeUnit").get("id").asLong());

        // The HotelDetail row exists with what was sent — not a fabricated default.
        assertEquals(3, created.get("starRating").asInt());
        assertEquals("14:00:00", created.get("checkIn").asText());
        assertEquals("12:00:00", created.get("checkOut").asText());
        assertEquals("Free cancellation up to 24 hours before arrival.",
            created.get("cancellationPolicy").asText());
        assertTrue(created.get("wifiAvailable").asBoolean());
        assertEquals(List.of("Vietnamese", "English"), strings(created.get("languages")));
        assertEquals(List.of("Cash", "Visa"), strings(created.get("paymentMethods")));
        assertEquals(2, created.get("amenities").size());

        // And it is really persisted: a fresh read by id returns the same record.
        JsonNode reread = getProperty(partner.token(), created.get("id").asLong(), 200);
        assertEquals(name, reread.get("name").asText());
        assertEquals("DRAFT", reread.get("status").asText());
        assertEquals(3, reread.get("starRating").asInt());

        // …and it is listed for its owner.
        assertTrue(listIds(partner.token()).contains(created.get("id").asLong()));
    }

    @Test
    void unapprovedPartner_cannotCreateProperty() throws Exception {
        // Submitted, waiting for an administrator: the gate is APPROVED, nothing less.
        String token = registerAndLogin(uniqueEmail());
        Long profileId = createProfile(token);
        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        assertNotNull(profileId);

        mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(uniq("Unapproved Stay")))))
            .andExpect(status().isForbidden());
    }

    @Test
    void partnerRoleWithoutProfile_cannotCreateProperty() throws Exception {
        // The PARTNER role opens the URL; the missing profile closes the endpoint. This is the same
        // answer an administrator gets, and it is what keeps the create path tied to one profile
        // rather than to a role.
        String email = uniqueEmail();
        String token = registerAndLogin(email);
        User user = userRepo.findByEmail(email).orElseThrow();
        user.setRole("PARTNER");
        userRepo.saveAndFlush(user);

        mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(uniq("No Profile Stay")))))
            .andExpect(status().isNotFound());
    }

    @Test
    void user_cannotCreateProperty() throws Exception {
        String token = registerAndLogin(uniqueEmail());

        mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(uniq("Traveller Stay")))))
            .andExpect(status().isForbidden());
    }

    @Test
    void admin_cannotUsePartnerCreateEndpoint() throws Exception {
        // SecurityConfig lets ADMIN through /api/partner/** at the URL level, and the service then
        // resolves the caller's own partner profile — which an administrator does not have. The
        // canonical answer is therefore 404, and no property is created for anyone.
        mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + adminToken())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(uniq("Admin Stay")))))
            .andExpect(status().isNotFound());
    }

    @Test
    void unknownRole_cannotCreateProperty() throws Exception {
        // S4 (Phase A) — a stored role that is not USER, PARTNER or ADMIN grants no authority. The
        // account cannot even sign in, so the token is minted directly to prove the filter, not the
        // login endpoint, is what refuses it.
        PartnerCtx partner = createAndApprovePartner();
        User user = userRepo.findById(partner.userId()).orElseThrow();
        user.setRole("SUPER_PARTNER");
        userRepo.saveAndFlush(user);
        String forgedRoleToken = jwt.createToken(user.getId(), user.getEmail(), user.getTokenVersion());

        mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + forgedRoleToken)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(uniq("Unknown Role Stay")))))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void unauthenticated_cannotCreateProperty() throws Exception {
        mvc.perform(post("/api/partner/hotels")
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(uniq("Anonymous Stay")))))
            .andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void partnerReadsOwnPropertyAndNotAnother() throws Exception {
        PartnerCtx a = createAndApprovePartner();
        PartnerCtx b = createAndApprovePartner();
        Long propertyId = createProperty(a, uniq("A Owned"));

        getProperty(a.token(), propertyId, 200);
        // Uniform 404: indistinguishable from an id that was never issued.
        getProperty(b.token(), propertyId, 404);
        getProperty(b.token(), 99_999_999L, 404);

        assertFalse(listIds(b.token()).contains(propertyId),
            "another partner's property is not in my list");
    }

    @Test
    void partnerUpdatesOwnBasicsAndAnotherCannot() throws Exception {
        PartnerCtx a = createAndApprovePartner();
        PartnerCtx b = createAndApprovePartner();
        Long propertyId = createProperty(a, uniq("Basics Owned"));
        String slug = getProperty(a.token(), propertyId, 200).get("slug").asText();

        JsonNode updated = mapper.readTree(mvc.perform(put("/api/partner/hotels/" + propertyId)
                .header("Authorization", "Bearer " + a.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of(
                    "name", "Renamed By Owner",
                    "shortDescription", "Updated summary",
                    "description", "Updated description",
                    "slug", slug,
                    "categoryId", accommodationCategoryId,
                    "subcategoryId", resortSubcategoryId))))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals("Renamed By Owner", updated.get("name").asText());
        assertEquals(resortSubcategoryId, updated.get("subcategory").get("id").asLong());

        mvc.perform(put("/api/partner/hotels/" + propertyId)
                .header("Authorization", "Bearer " + b.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("name", "Hijacked", "slug", "hijacked-" + UUID.randomUUID()))))
            .andExpect(status().isNotFound());

        assertEquals("Renamed By Owner",
            getProperty(a.token(), propertyId, 200).get("name").asText(),
            "the refused request changed nothing");
    }

    @Test
    void anotherPartnerCannotMutateContactLocationPoliciesOrAmenities() throws Exception {
        PartnerCtx a = createAndApprovePartner();
        PartnerCtx b = createAndApprovePartner();
        Long propertyId = createProperty(a, uniq("Guarded"));

        mvc.perform(put("/api/partner/hotels/" + propertyId + "/contact")
                .header("Authorization", "Bearer " + b.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("phone", "0900000000", "email", "attacker@example.com"))))
            .andExpect(status().isNotFound());

        mvc.perform(put("/api/partner/hotels/" + propertyId + "/location")
                .header("Authorization", "Bearer " + b.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("address", "1 Attacker Street",
                    "administrativeUnitId", cityLocationId))))
            .andExpect(status().isNotFound());

        mvc.perform(put("/api/partner/hotels/" + propertyId + "/policies")
                .header("Authorization", "Bearer " + b.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("checkIn", "06:00:00", "checkOut", "07:00:00"))))
            .andExpect(status().isNotFound());

        mvc.perform(put("/api/partner/hotels/" + propertyId + "/amenities")
                .header("Authorization", "Bearer " + b.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("amenityIds", List.of(hotelAmenityId)))))
            .andExpect(status().isNotFound());

        // Nothing moved: the owner still sees exactly what it created.
        JsonNode mine = getProperty(a.token(), propertyId, 200);
        assertEquals("stay@example.com", mine.get("email").asText());
        assertEquals("15 Thuy Van, Vung Tau", mine.get("address").asText());
        assertEquals(areaLocationId, mine.get("administrativeUnit").get("id").asLong());
        assertEquals("14:00:00", mine.get("checkIn").asText());
        assertEquals(2, mine.get("amenities").size());
    }

    @Test
    void partnerCannotChangeOwnerOrModerationFlags() throws Exception {
        PartnerCtx a = createAndApprovePartner();
        PartnerCtx b = createAndApprovePartner();

        Map<String, Object> body = createBody(uniq("Owner Spoof"));
        body.put("ownerProfileId", b.profileId());
        body.put("ownerUserId", b.userId());
        body.put("createdById", b.userId());
        body.put("featured", true);
        body.put("verified", true);

        JsonNode created = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + a.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(body)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());

        assertEquals(a.profileId(), created.get("ownerProfileId").asLong(),
            "the owner comes from the authenticated principal, never the body");
        assertFalse(created.get("featured").asBoolean());
        assertFalse(created.get("verified").asBoolean());
        getProperty(b.token(), created.get("id").asLong(), 404);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REFERENCE DATA VALIDATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void invalidCategoryIsRejected() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        // A category that is not an accommodation one.
        Map<String, Object> wrongType = createBody(uniq("Wrong Type"));
        wrongType.put("categoryId", foodCategoryId);
        wrongType.put("subcategoryId", restaurantSubcategoryId);
        assertEquals("CATEGORY_INVALID", code(createExpecting(partner, wrongType, 422)));

        // A category id that does not exist.
        Map<String, Object> unknown = createBody(uniq("Unknown Category"));
        unknown.put("categoryId", 99_999_999L);
        unknown.remove("subcategoryId");
        assertEquals("CATEGORY_INVALID", code(createExpecting(partner, unknown, 422)));

        // A deactivated accommodation category.
        Category inactive = saveInactiveCategory();
        Map<String, Object> deactivated = createBody(uniq("Inactive Category"));
        deactivated.put("categoryId", inactive.getId());
        deactivated.remove("subcategoryId");
        assertEquals("CATEGORY_INVALID", code(createExpecting(partner, deactivated, 422)));
    }

    @Test
    void subcategoryMustBeAChildOfTheCategory() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        Map<String, Object> body = createBody(uniq("Orphan Subcategory"));
        body.put("subcategoryId", restaurantSubcategoryId);
        JsonNode error = createExpecting(partner, body, 422);
        assertEquals("SUBCATEGORY_INVALID", code(error));
        assertEquals("subcategoryId", error.get("fieldErrors").get(0).get("field").asText());
    }

    @Test
    void invalidLocationIsRejected() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        Map<String, Object> unknown = createBody(uniq("Unknown Location"));
        unknown.put("administrativeUnitId", 99_999_999L);
        assertEquals("LOCATION_INVALID", code(createExpecting(partner, unknown, 422)));

        // A country is a container, not a place a property sits in (D13).
        Map<String, Object> country = createBody(uniq("Country Location"));
        country.put("administrativeUnitId", countryLocationId);
        assertEquals("LOCATION_INVALID", code(createExpecting(partner, country, 422)));

        Map<String, Object> deactivated = createBody(uniq("Inactive Location"));
        deactivated.put("administrativeUnitId", saveInactiveLocation().getId());
        assertEquals("LOCATION_INVALID", code(createExpecting(partner, deactivated, 422)));
    }

    @Test
    void invalidCoordinatesAreRejected() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        Map<String, Object> tooFarNorth = createBody(uniq("Bad Latitude"));
        tooFarNorth.put("latitude", 95.0);
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, tooFarNorth, 400)));

        Map<String, Object> tooFarEast = createBody(uniq("Bad Longitude"));
        tooFarEast.put("longitude", 200.0);
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, tooFarEast, 400)));

        // Absent coordinates stay allowed: a draft may not know them yet.
        Map<String, Object> none = createBody(uniq("No Coordinates"));
        none.remove("latitude");
        none.remove("longitude");
        JsonNode created = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(none)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());
        assertTrue(created.get("latitude").isNull());
    }

    @Test
    void invalidContactAndRequiredFieldsAreRejected() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        Map<String, Object> badEmail = createBody(uniq("Bad Email"));
        badEmail.put("email", "not-an-email");
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, badEmail, 400)));

        Map<String, Object> noName = createBody(uniq("No Name"));
        noName.put("name", "   ");
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, noName, 400)));

        Map<String, Object> noAddress = createBody(uniq("No Address"));
        noAddress.remove("address");
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, noAddress, 400)));

        Map<String, Object> noCheckIn = createBody(uniq("No Check-in"));
        noCheckIn.remove("checkIn");
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, noCheckIn, 400)));

        Map<String, Object> noStars = createBody(uniq("No Stars"));
        noStars.remove("starRating");
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, noStars, 400)));

        Map<String, Object> sixStars = createBody(uniq("Six Stars"));
        sixStars.put("starRating", 6);
        assertEquals("VALIDATION_FAILED", code(createExpecting(partner, sixStars, 400)));
    }

    @Test
    void duplicateNamesGetDistinctSlugsAndATakenSlugIsRefused() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        String sharedName = uniq("Twin Towers Hotel");

        String firstSlug = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(sharedName))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString()).get("slug").asText();

        JsonNode second = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(sharedName))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());

        assertNotEquals(firstSlug, second.get("slug").asText(), "slugs stay unique");
        assertTrue(second.get("slug").asText().startsWith(firstSlug + "-"));

        // Editing basics onto a slug that is already taken is a conflict, named as one.
        JsonNode conflict = mapper.readTree(mvc.perform(put("/api/partner/hotels/" + second.get("id").asLong())
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("name", sharedName, "slug", firstSlug))))
            .andExpect(status().isConflict())
            .andReturn().getResponse().getContentAsString());
        assertEquals("SLUG_CONFLICT", code(conflict));
    }

    @Test
    void amenitiesAreValidatedAndDeduplicated() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        Map<String, Object> unknown = createBody(uniq("Unknown Amenity"));
        unknown.put("amenityIds", List.of(generalAmenityId, 99_999_999L));
        assertEquals("AMENITY_INVALID", code(createExpecting(partner, unknown, 422)));

        // A room-level amenity describes a room, not the property.
        Map<String, Object> roomLevel = createBody(uniq("Room Amenity"));
        roomLevel.put("amenityIds", List.of(roomAmenityId));
        assertEquals("AMENITY_INVALID", code(createExpecting(partner, roomLevel, 422)));

        Map<String, Object> deactivated = createBody(uniq("Inactive Amenity"));
        deactivated.put("amenityIds", List.of(saveInactiveAmenity().getId()));
        assertEquals("AMENITY_INVALID", code(createExpecting(partner, deactivated, 422)));

        // Repeats collapse to one link rather than violating uk_place_amenity.
        Map<String, Object> repeated = createBody(uniq("Repeated Amenity"));
        repeated.put("amenityIds", List.of(generalAmenityId, generalAmenityId, hotelAmenityId));
        JsonNode created = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(repeated)))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString());
        assertEquals(2, created.get("amenities").size());

        // Replacing the set is wholesale, and a refused replacement leaves the old set intact.
        Long propertyId = created.get("id").asLong();
        JsonNode replaced = mapper.readTree(mvc.perform(put("/api/partner/hotels/" + propertyId + "/amenities")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("amenityIds", List.of(hotelAmenityId)))))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertEquals(1, replaced.get("amenities").size());
        assertEquals(hotelAmenityId, replaced.get("amenities").get(0).get("id").asLong());

        mvc.perform(put("/api/partner/hotels/" + propertyId + "/amenities")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(Map.of("amenityIds", List.of(roomAmenityId)))))
            .andExpect(status().isUnprocessableEntity());
        assertEquals(1, getProperty(partner.token(), propertyId, 200).get("amenities").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // STATUS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void statusInTheBodyChangesNothing() throws Exception {
        PartnerCtx partner = createAndApprovePartner();

        for (String forced : List.of("PUBLISHED", "APPROVED", "HIDDEN", "ARCHIVED", "REJECTED")) {
            Map<String, Object> body = createBody(uniq("Forced " + forced));
            body.put("status", forced);
            JsonNode created = mapper.readTree(mvc.perform(post("/api/partner/hotels")
                    .header("Authorization", "Bearer " + partner.token())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(json(body)))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString());
            assertEquals("DRAFT", created.get("status").asText(),
                "a status in the body is not part of this contract: " + forced);
        }
    }

    @Test
    void partnerHasNoPublishEndpoint() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long propertyId = createProperty(partner, uniq("No Publish"));

        // There is no status route on the partner surface at all. What an unmapped path answers is
        // the framework's business (this application currently reports 500 for one, which predates
        // Phase C); what matters here is that nothing succeeded and nothing was published.
        int unmapped = mvc.perform(patch("/api/partner/hotels/" + propertyId + "/status")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PUBLISHED\"}"))
            .andReturn().getResponse().getStatus();
        assertTrue(unmapped >= 400, "no partner status route may succeed, got " + unmapped);
        assertEquals("DRAFT", getProperty(partner.token(), propertyId, 200).get("status").asText());

        // …and the administrative one refuses a partner outright.
        mvc.perform(patch("/api/admin/places/" + propertyId + "/status")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"status\":\"PUBLISHED\"}"))
            .andExpect(status().isForbidden());

        // Turning the listing on is not publication: the status is untouched.
        JsonNode activated = mapper.readTree(mvc.perform(patch("/api/partner/hotels/" + propertyId + "/activate")
                .header("Authorization", "Bearer " + partner.token()))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(activated.get("active").asBoolean());
        assertEquals("DRAFT", activated.get("status").asText());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PUBLIC VISIBILITY (Phase A, S2 — must not regress)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void newDraftPropertyIsNotPubliclyDiscoverable() throws Exception {
        PartnerCtx partner = createAndApprovePartner();
        Long propertyId = createProperty(partner, uniq("Invisible Draft"));
        String slug = getProperty(partner.token(), propertyId, 200).get("slug").asText();

        mvc.perform(get("/api/places/" + propertyId)).andExpect(status().isNotFound());
        mvc.perform(get("/api/places/slug/" + slug)).andExpect(status().isNotFound());

        JsonNode published = mapper.readTree(mvc.perform(get("/api/places"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        for (JsonNode place : published) {
            assertNotEquals(propertyId, place.get("id").asLong(),
                "a draft must not appear in the public list");
        }
    }

    @Test
    void publishedPlacesRemainPubliclyDiscoverable() throws Exception {
        JsonNode published = mapper.readTree(mvc.perform(get("/api/places"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        assertTrue(published.size() > 0, "the seeded published catalogue is still public");

        Long id = published.get(0).get("id").asLong();
        mvc.perform(get("/api/places/" + id)).andExpect(status().isOk());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private Map<String, Object> createBody(String name) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("name", name);
        body.put("shortDescription", "A quiet beachfront stay");
        body.put("description", "A longer description of the property.");
        body.put("categoryId", accommodationCategoryId);
        body.put("subcategoryId", hotelSubcategoryId);
        body.put("administrativeUnitId", areaLocationId);
        body.put("address", "15 Thuy Van, Vung Tau");
        body.put("latitude", 10.3459);
        body.put("longitude", 107.0843);
        body.put("phone", "0254123456");
        body.put("email", "stay@example.com");
        body.put("website", "https://stay.example.com");
        body.put("starRating", 3);
        body.put("checkIn", "14:00:00");
        body.put("checkOut", "12:00:00");
        body.put("childrenPolicy", "Children of all ages are welcome.");
        body.put("petPolicy", "Pets are not allowed.");
        body.put("smokingPolicy", "Non-smoking property.");
        body.put("cancellationPolicy", "Free cancellation up to 24 hours before arrival.");
        body.put("freeCancellation", true);
        body.put("parkingAvailable", true);
        body.put("parkingFree", true);
        body.put("wifiAvailable", true);
        body.put("wifiFree", true);
        body.put("languages", List.of("Vietnamese", "English"));
        body.put("paymentMethods", List.of("Cash", "Visa"));
        body.put("amenityIds", List.of(generalAmenityId, hotelAmenityId));
        return body;
    }

    private Long createProperty(PartnerCtx partner, String name) throws Exception {
        String body = mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(createBody(name))))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private JsonNode createExpecting(PartnerCtx partner, Map<String, Object> body, int status)
            throws Exception {
        String response = mvc.perform(post("/api/partner/hotels")
                .header("Authorization", "Bearer " + partner.token())
                .contentType(MediaType.APPLICATION_JSON)
                .content(json(body)))
            .andExpect(status().is(status))
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(response);
    }

    private JsonNode getProperty(String token, Long propertyId, int status) throws Exception {
        String body = mvc.perform(get("/api/partner/hotels/" + propertyId)
                .header("Authorization", "Bearer " + token))
            .andExpect(status().is(status))
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private List<Long> listIds(String token) throws Exception {
        JsonNode array = mapper.readTree(mvc.perform(get("/api/partner/hotels")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString());
        return java.util.stream.StreamSupport.stream(array.spliterator(), false)
            .map(node -> node.get("id").asLong())
            .toList();
    }

    private String code(JsonNode errorBody) {
        JsonNode code = errorBody.get("code");
        return code == null ? null : code.asText();
    }

    private List<String> strings(JsonNode array) {
        return java.util.stream.StreamSupport.stream(array.spliterator(), false)
            .map(JsonNode::asText)
            .toList();
    }

    private String json(Object body) throws Exception {
        return mapper.writeValueAsString(body);
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

    private String uniqueEmail() {
        return "partner-crud-" + counter.getAndIncrement() + "-"
            + UUID.randomUUID().toString().substring(0, 8) + "@test.com";
    }

    private String registerAndLogin(String email) throws Exception {
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"Property Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("token").asText();
    }

    private Long createProfile(String token) throws Exception {
        String profileReq = """
                {"businessName":"Property Co %s","businessType":"HOTEL","representativeName":"Property Tester",
                 "phone":"0901234567","email":"contact@example.com","address":"123 Le Loi, Da Nang"}
                """.formatted(UUID.randomUUID().toString().substring(0, 8));
        String body = mvc.perform(post("/api/partner/profile")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(profileReq))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private PartnerCtx createAndApprovePartner() throws Exception {
        String email = uniqueEmail();
        String token = registerAndLogin(email);
        Long profileId = createProfile(token);

        mvc.perform(post("/api/partner/profile/submit")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
        mvc.perform(post("/api/admin/partners/" + profileId + "/approve")
                .header("Authorization", "Bearer " + adminToken()))
            .andExpect(status().isOk());

        Long userId = userRepo.findByEmail(email).orElseThrow().getId();
        return new PartnerCtx(token, profileId, userId);
    }

    /** A deactivated accommodation category, created for this test alone. */
    private Category saveInactiveCategory() {
        Category category = new Category();
        category.setParent(categoryRepo.findById(accommodationCategoryId).orElseThrow());
        category.setName("Retired Accommodation " + counter.getAndIncrement());
        category.setSlug("retired-accommodation-" + UUID.randomUUID().toString().substring(0, 8));
        category.setType("ACCOMMODATION");
        category.setActive(false);
        return categoryRepo.saveAndFlush(category);
    }

    /** A deactivated area, created for this test alone. */
    private AdministrativeUnit saveInactiveLocation() {
        AdministrativeUnit unit = new AdministrativeUnit();
        unit.setParent(locationRepo.findById(cityLocationId).orElseThrow());
        unit.setName("Retired Area " + counter.getAndIncrement());
        unit.setSlug("retired-area-" + UUID.randomUUID().toString().substring(0, 8));
        unit.setType(UnitType.AREA);
        unit.setLevel(3);
        unit.setActive(false);
        return locationRepo.saveAndFlush(unit);
    }

    /** A deactivated property-level amenity, created for this test alone. */
    private Amenity saveInactiveAmenity() {
        Amenity amenity = new Amenity();
        amenity.setName("Retired Amenity " + counter.getAndIncrement());
        amenity.setSlug("retired-amenity-" + UUID.randomUUID().toString().substring(0, 8));
        amenity.setGroupName("HOTEL");
        amenity.setActive(false);
        return amenityRepo.saveAndFlush(amenity);
    }

    private String uniq(String prefix) {
        return prefix + " " + UUID.randomUUID().toString().substring(0, 8);
    }
}
