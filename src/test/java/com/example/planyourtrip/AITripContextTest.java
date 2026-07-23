package com.example.planyourtrip;

import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.50 — AITripContext: read-only aggregation of existing service outputs.
 *
 * <p>Signals are seeded via the same repositories/HTTP endpoints the reused services read, then
 * {@code GET /api/me/ai/context} is asserted to surface each section. Cross-cutting tests prove the
 * aggregate is deterministic (modulo {@code contextGeneratedAt}), mutation-free, and consistent with
 * the dedicated endpoints it reuses.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AITripContextTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;

    @Autowired UserRepository userRepo;
    @Autowired PlaceRepository placeRepo;
    @Autowired CategoryRepository categoryRepo;
    @Autowired AdministrativeUnitRepository unitRepo;
    @Autowired PlaceMetadataRepository metadataRepo;
    @Autowired PlaceTagRepository tagRepo;
    @Autowired WishlistRepository wishlistRepo;
    @Autowired WishlistItemRepository wishlistItemRepo;
    @Autowired SavedCollectionRepository collectionRepo;
    @Autowired SavedCollectionPlaceRepository collectionPlaceRepo;
    @Autowired BookingRepository bookingRepo;
    @Autowired ReviewRepository reviewRepo;
    @Autowired HotelDetailRepository hotelDetailRepo;
    @Autowired HotelRoomRepository hotelRoomRepo;

    private static final AtomicInteger COUNTER = new AtomicInteger(1);
    private User creator;
    private HotelRoom seededRoom;

    @BeforeEach
    void setup() {
        creator = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow();
        Long hotelPlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(hotelPlaceId).orElseThrow().getId();
        seededRoom = hotelRoomRepo.findAllByHotelDetailId(detailId).stream().findFirst().orElseThrow();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anonymous_returns401() throws Exception {
        mvc.perform(get("/api/me/ai/context")).andExpect(status().isUnauthorized());
    }

    @Test
    void crossUserIsolation_contextContainsOnlyOwnData() throws Exception {
        Auth alice = register("ctx-alice");
        Auth bob = register("ctx-bob");
        Long aliceTrip = createTrip(alice.token, "Alice Trip", "ACTIVE",
            LocalDate.now().minusDays(1), LocalDate.now().plusDays(2));
        addToWishlist(alice.userId, seedPlace("AProv", "ACat"));

        JsonNode aliceCtx = context(alice.token);
        JsonNode bobCtx = context(bob.token);

        assertEquals(aliceTrip, aliceCtx.get("currentTrip").get("id").asLong());
        assertTrue(bobCtx.get("currentTrip").isNull(), "Bob has no trips");
        assertEquals(0, bobCtx.get("bookings").size());
        assertEquals(0, bobCtx.get("wishlistSummary").get("itemCount").asInt());
        assertEquals(0, bobCtx.get("upcomingTrips").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EMPTY / NEW USER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void newUser_allSectionsPresentNotNull() throws Exception {
        Auth a = register("ctx-new");
        JsonNode c = context(a.token);
        for (String field : List.of("userProfile", "interestProfile", "recommendations", "upcomingTrips",
                "bookings", "savedCollections", "wishlistSummary", "recentReviews", "activitySummary",
                "preferences", "contextGeneratedAt")) {
            assertTrue(c.has(field), "missing section: " + field);
            assertFalse(c.get(field).isNull(), "section should not be null: " + field);
        }
        assertTrue(c.get("currentTrip").isNull(), "no current trip for a new user");
        assertTrue(c.get("budgetSummary").isNull(), "no budget summary without a current trip");
        assertFalse(c.get("contextGeneratedAt").asText().isBlank());
    }

    @Test
    void emptyUser_listsEmptyAndActivityAllZero() throws Exception {
        Auth a = register("ctx-empty");
        JsonNode c = context(a.token);
        assertEquals(0, c.get("recommendations").size());
        assertEquals(0, c.get("bookings").size());
        assertEquals(0, c.get("savedCollections").size());
        assertEquals(0, c.get("recentReviews").size());
        assertEquals(0, c.get("upcomingTrips").size());
        JsonNode act = c.get("activitySummary");
        for (String k : List.of("totalTrips", "activeTrips", "upcomingTrips", "completedTrips",
                "totalPlannedDays", "totalBookings", "savedCollections", "wishlistItems", "reviews",
                "recommendations")) {
            assertEquals(0, act.get(k).asInt(), k + " should be 0");
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // INDIVIDUAL SECTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void userProfile_present() throws Exception {
        Auth a = register("ctx-profile");
        JsonNode c = context(a.token);
        assertFalse(c.get("userProfile").isNull());
        assertEquals(a.userId, c.get("userProfile").get("userId").asLong());
    }

    @Test
    void interestProfile_reflectsRecalc() throws Exception {
        Auth a = register("ctx-interest");
        addToWishlist(a.userId, seedPlace("Hue", "Temples"));
        recalcInterests(a.token);
        JsonNode c = context(a.token);
        JsonNode ip = c.get("interestProfile");
        assertEquals(a.userId, ip.get("userId").asLong());
        assertTrue(texts(ip.get("favoriteProvinces")).contains("Hue"));
        assertFalse(ip.get("lastRecalculatedAt").isNull());
    }

    @Test
    void recommendations_present_afterProfileAndCandidate() throws Exception {
        Auth a = register("ctx-rec");
        addToWishlist(a.userId, seedRichPlace("RecProv", "RecCat", "rtag"));
        recalcInterests(a.token);
        Long candidate = seedRichPlace("RecProv", "RecCat", "rtag");
        JsonNode c = context(a.token);
        assertTrue(c.get("recommendations").size() > 0, "engine surfaces at least one recommendation");
        assertTrue(containsPlaceId(c.get("recommendations"), candidate));
    }

    @Test
    void activeTrip_becomesCurrentTrip_withBudgetSummary() throws Exception {
        Auth a = register("ctx-active");
        Long tripId = createTrip(a.token, "Now Trip", "ACTIVE",
            LocalDate.now().minusDays(2), LocalDate.now().plusDays(3));
        JsonNode c = context(a.token);
        assertEquals(tripId, c.get("currentTrip").get("id").asLong());
        assertFalse(c.get("budgetSummary").isNull(), "budget summary exists for the current trip");
        assertEquals(tripId, c.get("budgetSummary").get("tripPlanId").asLong());
    }

    @Test
    void futureTrip_isUpcomingNotCurrent() throws Exception {
        Auth a = register("ctx-upcoming");
        Long future = createTrip(a.token, "Later Trip", "PLANNING",
            LocalDate.now().plusDays(10), LocalDate.now().plusDays(15));
        JsonNode c = context(a.token);
        assertTrue(c.get("currentTrip").isNull(), "a future trip is not current");
        assertTrue(c.get("budgetSummary").isNull());
        assertTrue(tripIds(c.get("upcomingTrips")).contains(future));
    }

    @Test
    void multipleBookings_present() throws Exception {
        Auth a = register("ctx-bookings");
        Long b1 = seedCompletedBooking(a.userId, seedPlace("BkP1", "BkC1"));
        Long b2 = seedCompletedBooking(a.userId, seedPlace("BkP2", "BkC2"));
        JsonNode c = context(a.token);
        List<Long> ids = jsonIds(c.get("bookings"));
        assertTrue(ids.contains(b1) && ids.contains(b2));
        assertEquals(2, c.get("activitySummary").get("totalBookings").asInt());
    }

    @Test
    void savedCollections_present() throws Exception {
        Auth a = register("ctx-coll");
        addToCollection(a.userId, seedPlace("CProv", "CCat"));
        JsonNode c = context(a.token);
        assertTrue(c.get("savedCollections").size() >= 1);
        assertEquals(c.get("savedCollections").size(), c.get("activitySummary").get("savedCollections").asInt());
    }

    @Test
    void wishlistSummary_countMatchesItems() throws Exception {
        Auth a = register("ctx-wish");
        addToWishlist(a.userId, seedPlace("W1", "WC1"));
        addToWishlist(a.userId, seedPlace("W2", "WC2"));
        JsonNode c = context(a.token);
        JsonNode ws = c.get("wishlistSummary");
        assertEquals(2, ws.get("itemCount").asInt());
        assertEquals(2, ws.get("items").size());
        assertEquals(2, c.get("activitySummary").get("wishlistItems").asInt());
    }

    @Test
    void recentReviews_cappedAtFive() throws Exception {
        Auth a = register("ctx-reviews");
        for (int i = 0; i < 6; i++) seedApprovedReview(a.userId, seedPlace("RvP" + i, "RvC" + i), 5);
        JsonNode c = context(a.token);
        assertEquals(5, c.get("recentReviews").size(), "recentReviews capped at RECENT_REVIEWS_LIMIT");
        assertEquals(6, c.get("activitySummary").get("reviews").asInt(), "activitySummary counts all reviews");
    }

    @Test
    void preferences_present() throws Exception {
        Auth a = register("ctx-prefs");
        JsonNode c = context(a.token);
        assertFalse(c.get("preferences").isNull());
        assertEquals(a.userId, c.get("preferences").get("userId").asLong());
    }

    @Test
    void activitySummary_countsAcrossSections() throws Exception {
        Auth a = register("ctx-activity");
        createTrip(a.token, "T-active", "ACTIVE", LocalDate.now().minusDays(1), LocalDate.now().plusDays(1));
        createTrip(a.token, "T-future", "PLANNING", LocalDate.now().plusDays(5), LocalDate.now().plusDays(6));
        createTrip(a.token, "T-done", "COMPLETED", LocalDate.now().minusDays(10), LocalDate.now().minusDays(8));
        seedCompletedBooking(a.userId, seedPlace("ActP", "ActC"));
        addToWishlist(a.userId, seedPlace("ActW", "ActWC"));
        JsonNode act = context(a.token).get("activitySummary");
        assertEquals(3, act.get("totalTrips").asInt());
        assertEquals(1, act.get("activeTrips").asInt());
        assertEquals(1, act.get("upcomingTrips").asInt());
        assertEquals(1, act.get("completedTrips").asInt());
        assertEquals(1, act.get("totalBookings").asInt());
        assertEquals(1, act.get("wishlistItems").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CROSS-CUTTING GUARANTEES
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deterministicOutput_identicalExceptTimestamp() throws Exception {
        Auth a = register("ctx-determ");
        createTrip(a.token, "D", "ACTIVE", LocalDate.now().minusDays(1), LocalDate.now().plusDays(2));
        addToWishlist(a.userId, seedPlace("DProv", "DCat"));
        recalcInterests(a.token);
        context(a.token); // warm-up: first access lazily initializes the CustomerProfile singleton
        ObjectNode first = (ObjectNode) context(a.token);
        ObjectNode second = (ObjectNode) context(a.token);
        first.remove("contextGeneratedAt");
        second.remove("contextGeneratedAt");
        assertEquals(first, second, "context is deterministic apart from contextGeneratedAt");
    }

    @Test
    void noMutation_contextDoesNotRecalculateOrPersist() throws Exception {
        Auth a = register("ctx-nomut");
        addToWishlist(a.userId, seedPlace("NP", "NC"));
        long tripsBefore = 0; // fresh user has no trips

        // Interest profile never recalculated → lastRecalculatedAt null. Context must NOT change that.
        assertTrue(interests(a.token).get("lastRecalculatedAt").isNull());
        context(a.token);
        context(a.token);
        assertTrue(interests(a.token).get("lastRecalculatedAt").isNull(),
            "building the context must not recalculate/persist the interest profile");
        assertEquals(tripsBefore, context(a.token).get("activitySummary").get("totalTrips").asInt());
    }

    @Test
    void responseConsistency_sectionsMatchDedicatedEndpoints() throws Exception {
        Auth a = register("ctx-consistency");
        addToWishlist(a.userId, seedRichPlace("CoProv", "CoCat", "ctag"));
        recalcInterests(a.token);
        seedRichPlace("CoProv", "CoCat", "ctag");
        seedCompletedBooking(a.userId, seedPlace("CoBkP", "CoBkC"));

        JsonNode c = context(a.token);
        assertEquals(getJson(a.token, "/api/me/bookings"), c.get("bookings"),
            "context.bookings == GET /api/me/bookings");
        assertEquals(getJson(a.token, "/api/me/interests"), c.get("interestProfile"),
            "context.interestProfile == GET /api/me/interests");
        assertEquals(getJson(a.token, "/api/me/recommendations/engine"), c.get("recommendations"),
            "context.recommendations == GET /api/me/recommendations/engine");
    }

    @Test
    void contextGeneratedAt_presentAndNonDecreasing() throws Exception {
        Auth a = register("ctx-ts");
        String t1 = context(a.token).get("contextGeneratedAt").asText();
        String t2 = context(a.token).get("contextGeneratedAt").asText();
        assertFalse(t1.isBlank());
        assertTrue(t2.compareTo(t1) >= 0, "timestamp does not go backwards");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HTTP HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode context(String token) throws Exception {
        return getJson(token, "/api/me/ai/context");
    }

    private JsonNode interests(String token) throws Exception {
        return getJson(token, "/api/me/interests");
    }

    private JsonNode getJson(String token, String url) throws Exception {
        String body = mvc.perform(get(url).header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void recalcInterests(String token) throws Exception {
        mvc.perform(post("/api/me/interests/recalculate").header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
    }

    private Long createTrip(String token, String title, String status, LocalDate start, LocalDate end) throws Exception {
        String json = String.format(
            "{\"title\":\"%s\",\"destination\":\"Test\",\"startDate\":\"%s\",\"endDate\":\"%s\",\"status\":\"%s\",\"isPublic\":false}",
            title, start, end, status);
        String body = mvc.perform(post("/api/me/trips")
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON).content(json))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body).get("id").asLong();
    }

    private record Auth(String token, Long userId) {}

    private Auth register(String prefix) throws Exception {
        String email = prefix + "-" + COUNTER.getAndIncrement() + "@test.com";
        String body = mvc.perform(post("/api/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"fullName\":\"" + prefix + " Tester\",\"email\":\"" + email
                    + "\",\"password\":\"password123\"}"))
            .andExpect(status().isCreated())
            .andReturn().getResponse().getContentAsString();
        String token = mapper.readTree(body).get("token").asText();
        Long uid = userRepo.findByEmail(email).orElseThrow().getId();
        return new Auth(token, uid);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // JSON HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private List<String> texts(JsonNode arr) {
        List<String> out = new ArrayList<>();
        arr.forEach(n -> out.add(n.asText()));
        return out;
    }

    private List<Long> jsonIds(JsonNode arr) {
        List<Long> out = new ArrayList<>();
        arr.forEach(n -> out.add(n.get("id").asLong()));
        return out;
    }

    private List<Long> tripIds(JsonNode arr) {
        return jsonIds(arr);
    }

    private boolean containsPlaceId(JsonNode recArr, Long placeId) {
        for (JsonNode n : recArr) if (n.get("place").get("id").asLong() == placeId) return true;
        return false;
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    /** A published place with a rich metadata (all interest dimensions) + tag — used for recommendations. */
    private Long seedRichPlace(String province, String category, String tag) {
        Place place = newPlace(province, category);
        PlaceMetadata md = new PlaceMetadata();
        md.setPlace(place);
        md.setTravelStyles(new ArrayList<>(List.of(TravelStyle.COUPLE)));
        md.setWeatherTypes(new ArrayList<>(List.of(WeatherType.SUNNY)));
        md.setEstimatedBudgetLevel(BudgetLevel.LUXURY);
        md.setCrowdLevel(CrowdLevel.LOW);
        md.setAccessibilityLevel(AccessibilityLevel.HIGH);
        metadataRepo.save(md);
        PlaceTag t = new PlaceTag();
        t.setPlace(place);
        t.setTag(tag);
        t.setTagNormalized(tag.toLowerCase());
        tagRepo.save(t);
        return place.getId();
    }

    /** A published place with province + category only (no metadata). */
    private Long seedPlace(String province, String category) {
        return newPlace(province, category).getId();
    }

    private Place newPlace(String province, String category) {
        String u = UUID.randomUUID().toString().substring(0, 8);
        Place place = new Place();
        place.setName(category + " " + u);
        place.setNameNormalized((category + " " + u).toLowerCase());
        place.setSlug("ctx-place-" + u);
        place.setCategory(getOrCreateCategory(category));
        place.setAdministrativeUnit(getOrCreateProvince(province));
        place.setAddress("123 Test Street");
        place.setStatus(PlaceStatus.PUBLISHED);
        place.setCreatedBy(creator);
        place.setActive(true);
        return placeRepo.save(place);
    }

    private Category getOrCreateCategory(String name) {
        String slug = "ctx-cat-" + name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        return categoryRepo.findBySlug(slug).orElseGet(() -> {
            Category c = new Category();
            c.setName(name);
            c.setSlug(slug);
            c.setActive(true);
            return categoryRepo.save(c);
        });
    }

    private AdministrativeUnit getOrCreateProvince(String name) {
        String slug = "ctx-prov-" + name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        return unitRepo.findBySlug(slug).orElseGet(() -> {
            AdministrativeUnit un = new AdministrativeUnit();
            un.setName(name);
            un.setSlug(slug);
            un.setNameNormalized(name.toLowerCase());
            un.setType(UnitType.PROVINCE);
            un.setLevel(1);
            un.setActive(true);
            return unitRepo.save(un);
        });
    }

    private void addToWishlist(Long userId, Long placeId) {
        Wishlist wl = wishlistRepo.findByUserId(userId).orElseGet(() -> {
            Wishlist fresh = new Wishlist();
            fresh.setUser(userRepo.findById(userId).orElseThrow());
            return wishlistRepo.save(fresh);
        });
        WishlistItem item = new WishlistItem();
        item.setWishlist(wl);
        item.setPlace(placeRepo.findById(placeId).orElseThrow());
        wishlistItemRepo.save(item);
    }

    private void addToCollection(Long userId, Long placeId) {
        SavedCollection col = collectionRepo.findByOwnerIdOrderBySortOrderAscCreatedAtAsc(userId)
            .stream().findFirst().orElseGet(() -> {
                SavedCollection fresh = new SavedCollection();
                fresh.setOwner(userRepo.findById(userId).orElseThrow());
                fresh.setName("My Places");
                return collectionRepo.save(fresh);
            });
        SavedCollectionPlace scp = new SavedCollectionPlace();
        scp.setCollection(col);
        scp.setPlace(placeRepo.findById(placeId).orElseThrow());
        scp.setPosition((int) collectionPlaceRepo.findByCollectionIdOrderByPositionAsc(col.getId()).size());
        collectionPlaceRepo.save(scp);
    }

    private Long seedCompletedBooking(Long userId, Long placeId) {
        return seedBooking(userId, placeId, BookingStatus.COMPLETED).getId();
    }

    private Booking seedBooking(Long userId, Long placeId, BookingStatus status) {
        Booking b = new Booking();
        b.setBookingCode("CTX-" + UUID.randomUUID().toString().substring(0, 10));
        b.setUser(userRepo.findById(userId).orElseThrow());
        b.setHotel(placeRepo.findById(placeId).orElseThrow());
        b.setRoom(seededRoom);
        b.setCheckInDate(LocalDate.now().minusDays(10));
        b.setCheckOutDate(LocalDate.now().minusDays(8));
        b.setAdults(2);
        b.setChildren(0);
        b.setNumberOfRooms(1);
        b.setStatus(status);
        b.setCurrency("VND");
        b.setBasePrice(new BigDecimal("1000000"));
        b.setDiscountAmount(BigDecimal.ZERO);
        b.setFinalPrice(new BigDecimal("1000000"));
        return bookingRepo.save(b);
    }

    private void seedApprovedReview(Long userId, Long placeId, int rating) {
        Booking b = seedBooking(userId, placeId, BookingStatus.CONFIRMED);
        Review r = new Review();
        r.setBooking(b);
        r.setUser(userRepo.findById(userId).orElseThrow());
        r.setPlace(placeRepo.findById(placeId).orElseThrow());
        r.setRatingOverall(rating);
        r.setStatus(ReviewStatus.APPROVED);
        reviewRepo.save(r);
    }
}
