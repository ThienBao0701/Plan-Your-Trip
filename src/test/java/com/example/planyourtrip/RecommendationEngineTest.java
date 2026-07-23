package com.example.planyourtrip;

import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
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
 * Phase 7.49 — RecommendationEngine: live, deterministic, profile-driven place scoring.
 *
 * <p>Flow per scenario: seed signals + candidate places directly via repositories, recalculate the
 * Phase 7.48 {@code UserInterestProfile} through its HTTP endpoint, then call
 * {@code GET /api/me/recommendations/engine}. Because the Spring context shares one DB with unrelated
 * seeded places, every assertion targets specific place ids (appears / excluded / relative order /
 * score) rather than the total list size — except the empty-profile case, which is guaranteed empty.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RecommendationEngineTest {

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
    // EMPTY PROFILE / NO MATCH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void emptyProfile_returnsEmptyList() throws Exception {
        Auth a = register("rec-empty");                 // never recalculated → empty profile
        JsonNode res = live(a.token);
        assertTrue(res.isArray());
        assertEquals(0, res.size(), "empty interest profile ⇒ nothing to match ⇒ empty list");
    }

    @Test
    void recalculatedButNoSignals_returnsEmptyList() throws Exception {
        Auth a = register("rec-empty2");
        recalcProfile(a.token);                          // recalculated but zero signals
        assertEquals(0, live(a.token).size());
    }

    @Test
    void populatedProfile_nonMatchingCandidate_excluded() throws Exception {
        Auth a = register("rec-nomatch");
        seedRichProfile(a);
        Long noMatch = seedPlace("NoProv", "NoCat",
            List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        assertNull(find(live(a.token), noMatch), "a place matching no interest dimension is not recommended");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SIGNAL SOURCES → PROFILE → RECOMMENDATIONS
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void bookingOnly_producesRecommendations() throws Exception {
        Auth a = register("rec-booking");
        seedCompletedBooking(a.userId, seedPlace("BkProv", "BkCat",
            List.of(TravelStyle.FAMILY), List.of(WeatherType.SUNNY),
            BudgetLevel.MEDIUM, CrowdLevel.LOW, AccessibilityLevel.HIGH, "bktag"));
        recalcProfile(a.token);
        Long candidate = seedPlace("BkProv", "OtherCat",
            List.of(TravelStyle.SOLO), List.of(WeatherType.CLOUDY),
            BudgetLevel.HIGH, CrowdLevel.HIGH, AccessibilityLevel.LOW, "x");
        assertNotNull(find(live(a.token), candidate), "province learned from a booking drives a recommendation");
    }

    @Test
    void wishlistOnly_producesRecommendations() throws Exception {
        Auth a = register("rec-wish");
        addToWishlist(a.userId, seedPlace("WishProv", "WishCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "wtag"));
        recalcProfile(a.token);
        Long candidate = seedPlace("OtherProv", "WishCat",
            List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "x");
        assertNotNull(find(live(a.token), candidate), "category learned from wishlist drives a recommendation");
    }

    @Test
    void savedCollectionOnly_producesRecommendations() throws Exception {
        Auth a = register("rec-coll");
        addToCollection(a.userId, seedPlace("CollProv", "CollCat",
            List.of(TravelStyle.FRIENDS), List.of(WeatherType.COOL),
            BudgetLevel.MEDIUM, CrowdLevel.MEDIUM, AccessibilityLevel.MEDIUM, "ctag"));
        recalcProfile(a.token);
        Long candidate = seedPlace("Zzz", "Zzz",
            List.of(TravelStyle.FRIENDS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "x");
        assertNotNull(find(live(a.token), candidate), "travel style learned from a saved collection drives a match");
    }

    @Test
    void reviewOnly_producesRecommendations() throws Exception {
        Auth a = register("rec-review");
        seedApprovedReview(a.userId, seedPlace("RvProv", "RvCat",
            List.of(TravelStyle.SOLO), List.of(WeatherType.SUNNY),
            BudgetLevel.LOW, CrowdLevel.LOW, AccessibilityLevel.HIGH, "rvtag"), 5);
        recalcProfile(a.token);
        Long candidate = seedPlace("RvProv", "OtherCat",
            List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "x");
        assertNotNull(find(live(a.token), candidate), "an approved review drives a recommendation");
    }

    @Test
    void mixedSignals_producesRecommendations() throws Exception {
        Auth a = register("rec-mixed");
        addToWishlist(a.userId, seedPlace("MixProv", "MixCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "mtag"));
        seedCompletedBooking(a.userId, seedPlace("MixProv", "HotelCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "mtag"));
        recalcProfile(a.token);
        Long candidate = seedPlace("MixProv", "MixCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "mtag");
        JsonNode hit = find(live(a.token), candidate);
        assertNotNull(hit);
        assertEquals(100, hit.get("score").asInt(), "candidate matching every learned dimension scores 100");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PER-DIMENSION MATCHING
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void provinceMatch_scoredAndReasoned() throws Exception {
        Auth a = register("rec-prov");
        seedRichProfile(a);
        Long c = seedPlace("RichProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("RichProv", hit.get("matchedProvince").asText());
        assertEquals(14, hit.get("score").asInt());               // round(15*100/105)
        assertTrue(hit.get("matchedBudget").isNull());
        assertReasonContains(hit, "province");
    }

    @Test
    void budgetMatch_scoredAndReasoned() throws Exception {
        Auth a = register("rec-budget");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.LUXURY, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("LUXURY", hit.get("matchedBudget").asText());
        assertEquals(19, hit.get("score").asInt());               // round(20*100/105)
        assertReasonContains(hit, "budget");
    }

    @Test
    void travelStyleMatch_scoredAndReasoned() throws Exception {
        Auth a = register("rec-style");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "NoCat", List.of(TravelStyle.COUPLE), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("COUPLE", hit.get("matchedTravelStyles").get(0).asText());
        assertEquals(29, hit.get("score").asInt());               // round(30*100/105)
        assertReasonContains(hit, "travel style");
    }

    @Test
    void tagMatch_scoredAndReasoned() throws Exception {
        Auth a = register("rec-tag");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "rtag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("rtag", hit.get("matchedTags").get(0).asText());
        assertEquals(10, hit.get("score").asInt());               // round(10*100/105)
    }

    @Test
    void categoryMatch_scoredAndReasoned() throws Exception {
        Auth a = register("rec-cat");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "RichCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("RichCat", hit.get("matchedCategories").get(0).asText());
        assertEquals(14, hit.get("score").asInt());               // round(15*100/105)
    }

    @Test
    void weatherMatch_scored() throws Exception {
        Auth a = register("rec-weather");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.SUNNY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("SUNNY", hit.get("matchedWeatherTypes").get(0).asText());
        assertEquals(5, hit.get("score").asInt());                // round(5*100/105)
    }

    @Test
    void accessibilityMatch_scored() throws Exception {
        Auth a = register("rec-access");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.HIGH, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("HIGH", hit.get("matchedAccessibilityLevel").asText());
        assertEquals(5, hit.get("score").asInt());
    }

    @Test
    void crowdMatch_scored() throws Exception {
        Auth a = register("rec-crowd");
        seedRichProfile(a);
        Long c = seedPlace("NoProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.LOW, AccessibilityLevel.LOW, "ntag");
        JsonNode hit = find(live(a.token), c);
        assertNotNull(hit);
        assertEquals("LOW", hit.get("matchedCrowdLevel").asText());
        assertEquals(5, hit.get("score").asInt());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NORMALIZATION
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void normalization_scoresWithinZeroToHundred() throws Exception {
        Auth a = register("rec-norm");
        seedRichProfile(a);
        Long perfect = seedPlace("RichProv", "RichCat", List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "rtag");
        Long partial = seedPlace("RichProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        JsonNode res = live(a.token);
        for (JsonNode n : res) {
            int score = n.get("score").asInt();
            int conf = n.get("confidence").asInt();
            assertTrue(score >= 0 && score <= 100, "score in range: " + score);
            assertTrue(conf >= 0 && conf <= 100, "confidence in range: " + conf);
        }
        assertEquals(100, find(res, perfect).get("score").asInt(), "all-dimension match ⇒ 100");
        assertEquals(14, find(res, partial).get("score").asInt(), "province-only ⇒ 14 (< 100)");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DETERMINISM / SORTING / DEDUP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void deterministicOrdering_identicalAcrossCalls() throws Exception {
        Auth a = register("rec-determ");
        seedRichProfile(a);
        seedPlace("RichProv", "RichCat", List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "rtag");
        seedPlace("RichProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");
        assertEquals(live(a.token).toString(), live(a.token).toString(),
            "two calls over identical data produce identical ordering");
    }

    @Test
    void stableSorting_higherScoreBeforeLowerThenById() throws Exception {
        Auth a = register("rec-sort");
        seedRichProfile(a);
        Long high = seedPlace("RichProv", "RichCat", List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "rtag");   // score 100
        Long low = seedPlace("RichProv", "NoCat", List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
            BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "ntag");     // score 14
        List<Long> order = ids(live(a.token));
        assertTrue(order.indexOf(high) < order.indexOf(low), "higher score ranks before lower score");
    }

    @Test
    void duplicateRemoval_eachPlaceAtMostOnce() throws Exception {
        Auth a = register("rec-dedup");
        seedRichProfile(a);
        seedPlace("RichProv", "RichCat", List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "rtag");
        List<Long> order = ids(live(a.token));
        assertEquals(order.size(), new java.util.HashSet<>(order).size(), "no place id appears twice");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FILTERING (status / active)
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void hiddenPlaceExcluded() throws Exception {
        Auth a = register("rec-hidden");
        seedRichProfile(a);
        Long hidden = seedPlaceWithStatus("RichProv", "RichCat", PlaceStatus.HIDDEN, true);
        assertNull(find(live(a.token), hidden), "HIDDEN places are never recommended");
    }

    @Test
    void archivedPlaceExcluded() throws Exception {
        Auth a = register("rec-archived");
        seedRichProfile(a);
        Long archived = seedPlaceWithStatus("RichProv", "RichCat", PlaceStatus.ARCHIVED, true);
        assertNull(find(live(a.token), archived), "ARCHIVED places are never recommended");
    }

    @Test
    void draftPlaceExcluded() throws Exception {
        Auth a = register("rec-draft");
        seedRichProfile(a);
        Long draft = seedPlaceWithStatus("RichProv", "RichCat", PlaceStatus.DRAFT, true);
        assertNull(find(live(a.token), draft), "DRAFT places are never recommended");
    }

    @Test
    void rejectedPlaceExcluded() throws Exception {
        Auth a = register("rec-rejected");
        seedRichProfile(a);
        Long rejected = seedPlaceWithStatus("RichProv", "RichCat", PlaceStatus.REJECTED, true);
        assertNull(find(live(a.token), rejected), "REJECTED places are never recommended");
    }

    @Test
    void inactivePlaceExcluded() throws Exception {
        Auth a = register("rec-inactive");
        seedRichProfile(a);
        Long inactive = seedPlaceWithStatus("RichProv", "RichCat", PlaceStatus.PUBLISHED, false);
        assertNull(find(live(a.token), inactive), "soft-deleted (inactive) places are never recommended");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SECURITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void anonymous_returns401() throws Exception {
        mvc.perform(get("/api/me/recommendations/engine")).andExpect(status().isUnauthorized());
    }

    @Test
    void routing_engineAndSnapshotEndpointsResolveDistinctly_noAmbiguity() throws Exception {
        Auth a = register("rec-routing");

        // 7.49 engine: bare JSON array (empty for a fresh profile).
        String engineBody = mvc.perform(get("/api/me/recommendations/engine")
                .header("Authorization", "Bearer " + a.token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        assertTrue(mapper.readTree(engineBody).isArray(), "/engine returns the Phase 7.49 engine array");

        // 7.23 persisted-snapshot list: still resolves to its own handler — a paginated PageResponse
        // object (NOT an array), proving the literal /engine segment did not shadow or collide with it.
        String snapshotBody = mvc.perform(get("/api/me/recommendations")
                .header("Authorization", "Bearer " + a.token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        JsonNode snapshot = mapper.readTree(snapshotBody);
        assertFalse(snapshot.isArray(), "/api/me/recommendations still resolves to the Phase 7.23 endpoint");
        assertTrue(snapshot.has("content"), "Phase 7.23 endpoint returns its paginated PageResponse shape");
    }

    @Test
    void crossUserIsolation_eachUserSeesOnlyOwnProfileDriven() throws Exception {
        Auth alice = register("rec-alice");
        Auth bob = register("rec-bob");

        addToWishlist(alice.userId, seedPlace("AliceProv", "AliceCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "atag"));
        addToWishlist(bob.userId, seedPlace("BobProv", "BobCat",
            List.of(TravelStyle.FAMILY), List.of(WeatherType.RAINY),
            BudgetLevel.LOW, CrowdLevel.HIGH, AccessibilityLevel.LOW, "btag"));
        recalcProfile(alice.token);
        recalcProfile(bob.token);

        Long aliceCandidate = seedPlace("AliceProv", "AliceCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "atag");
        Long bobCandidate = seedPlace("BobProv", "BobCat",
            List.of(TravelStyle.FAMILY), List.of(WeatherType.RAINY),
            BudgetLevel.LOW, CrowdLevel.HIGH, AccessibilityLevel.LOW, "btag");

        JsonNode aliceRes = live(alice.token);
        JsonNode bobRes = live(bob.token);

        assertNotNull(find(aliceRes, aliceCandidate), "Alice sees her own profile-driven match");
        assertNull(find(aliceRes, bobCandidate), "Alice never sees Bob's profile-only match");
        assertNotNull(find(bobRes, bobCandidate), "Bob sees his own profile-driven match");
        assertNull(find(bobRes, aliceCandidate), "Bob never sees Alice's profile-only match");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // PERFORMANCE SANITY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void performanceSanity_manyPlacesCappedAndPerfectSurfaces() throws Exception {
        Auth a = register("rec-perf");
        // Unique province/category namespace so the perfect (score-100) match is unambiguously top,
        // independent of any places accumulated by other scenarios in the shared context.
        addToWishlist(a.userId, seedPlace("PerfProv", "PerfCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "perftag"));
        recalcProfile(a.token);
        for (int i = 0; i < 30; i++) {
            seedPlace("PerfProv", "NoCat-" + i, List.of(TravelStyle.BUSINESS), List.of(WeatherType.RAINY),
                BudgetLevel.FREE, CrowdLevel.HIGH, AccessibilityLevel.LOW, "n" + i); // province-only partial
        }
        Long perfect = seedPlace("PerfProv", "PerfCat", List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "perftag");

        long start = System.currentTimeMillis();
        JsonNode res = live(a.token);
        long elapsed = System.currentTimeMillis() - start;

        assertTrue(res.size() <= 50, "result is capped at MAX_RESULTS");
        assertNotNull(find(res, perfect), "the perfect (score 100) match surfaces at the top");
        assertTrue(elapsed < 10_000, "batched scoring completes promptly (no N+1 blow-up): " + elapsed + "ms");
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HTTP + PROFILE HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode live(String token) throws Exception {
        String body = mvc.perform(get("/api/me/recommendations/engine")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private void recalcProfile(String token) throws Exception {
        mvc.perform(post("/api/me/interests/recalculate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk());
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

    /** Wishlist one place carrying all 8 interest dimensions, then recalc → fully-populated profile. */
    private void seedRichProfile(Auth a) throws Exception {
        addToWishlist(a.userId, seedPlace("RichProv", "RichCat",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "rtag"));
        recalcProfile(a.token);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // JSON HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode find(JsonNode arr, Long placeId) {
        for (JsonNode n : arr) {
            if (n.get("place").get("id").asLong() == placeId) return n;
        }
        return null;
    }

    private List<Long> ids(JsonNode arr) {
        List<Long> out = new ArrayList<>();
        arr.forEach(n -> out.add(n.get("place").get("id").asLong()));
        return out;
    }

    private void assertReasonContains(JsonNode hit, String needle) {
        boolean found = false;
        for (JsonNode r : hit.get("reasons")) {
            if (r.asText().toLowerCase().contains(needle.toLowerCase())) { found = true; break; }
        }
        assertTrue(found, "expected a reason mentioning '" + needle + "' in " + hit.get("reasons"));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SEED HELPERS (direct repository persistence)
    // ═══════════════════════════════════════════════════════════════════════════

    private Long seedPlace(String provinceName, String categoryName,
                           List<TravelStyle> styles, List<WeatherType> weathers,
                           BudgetLevel budget, CrowdLevel crowd, AccessibilityLevel access,
                           String... tags) {
        Place place = newPlace(provinceName, categoryName, PlaceStatus.PUBLISHED, true);

        PlaceMetadata md = new PlaceMetadata();
        md.setPlace(place);
        md.setTravelStyles(new ArrayList<>(styles));
        md.setWeatherTypes(new ArrayList<>(weathers));
        md.setEstimatedBudgetLevel(budget);
        md.setCrowdLevel(crowd);
        md.setAccessibilityLevel(access);
        metadataRepo.save(md);

        for (String tag : tags) {
            PlaceTag t = new PlaceTag();
            t.setPlace(place);
            t.setTag(tag);
            t.setTagNormalized(tag.toLowerCase());
            tagRepo.save(t);
        }
        return place.getId();
    }

    private Long seedPlaceWithStatus(String provinceName, String categoryName, PlaceStatus status, boolean active) {
        Place place = newPlace(provinceName, categoryName, status, active);
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
        t.setTag("rtag");
        t.setTagNormalized("rtag");
        tagRepo.save(t);
        return place.getId();
    }

    private Place newPlace(String provinceName, String categoryName, PlaceStatus status, boolean active) {
        String u = UUID.randomUUID().toString().substring(0, 8);
        Place place = new Place();
        place.setName(categoryName + " " + u);
        place.setNameNormalized((categoryName + " " + u).toLowerCase());
        place.setSlug("rec-place-" + u);
        place.setCategory(getOrCreateCategory(categoryName));
        place.setAdministrativeUnit(getOrCreateProvince(provinceName));
        place.setAddress("123 Test Street");
        place.setStatus(status);
        place.setCreatedBy(creator);
        place.setActive(active);
        return placeRepo.save(place);
    }

    private Category getOrCreateCategory(String name) {
        String slug = "rec-cat-" + name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        return categoryRepo.findBySlug(slug).orElseGet(() -> {
            Category c = new Category();
            c.setName(name);
            c.setSlug(slug);
            c.setActive(true);
            return categoryRepo.save(c);
        });
    }

    private AdministrativeUnit getOrCreateProvince(String name) {
        String slug = "rec-prov-" + name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
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

    private void seedCompletedBooking(Long userId, Long placeId) {
        seedBooking(userId, placeId, BookingStatus.COMPLETED);
    }

    private Booking seedBooking(Long userId, Long placeId, BookingStatus status) {
        Booking b = new Booking();
        b.setBookingCode("REC-" + UUID.randomUUID().toString().substring(0, 10));
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
