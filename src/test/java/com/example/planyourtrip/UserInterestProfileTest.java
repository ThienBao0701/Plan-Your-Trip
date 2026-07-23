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
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Phase 7.48 — UserInterestProfile: derived, persisted, deterministic interest aggregation.
 *
 * <p>Signal data (places + metadata + tags, wishlist / saved collections / completed bookings /
 * approved reviews) is seeded directly through repositories for full determinism; the profile itself
 * is exercised only through the {@code /api/me/interests} HTTP surface. Each scenario registers its
 * own throwaway user, so profiles never collide.
 */
@SpringBootTest
@AutoConfigureMockMvc
class UserInterestProfileTest {

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

    private User creator;   // createdBy for seeded places (reuse the seeded admin)
    private HotelRoom seededRoom;

    @BeforeEach
    void setup() {
        creator = userRepo.findByEmail("admin@planyourtrip.com").orElseThrow();
        Long hotelPlaceId = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow().getId();
        Long detailId = hotelDetailRepo.findByPlaceId(hotelPlaceId).orElseThrow().getId();
        seededRoom = hotelRoomRepo.findAllByHotelDetailId(detailId).stream()
            .findFirst().orElseThrow();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EMPTY USER
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void emptyUser_getReturnsEmptyProfile_notNull() throws Exception {
        Auth a = register("uip-empty");

        JsonNode res = getInterests(a.token);

        assertEquals(a.userId, res.get("userId").asLong());
        assertEquals(0, res.get("signalCount").asInt());
        assertTrue(res.get("lastRecalculatedAt").isNull(), "never recalculated → null timestamp");
        assertEquals(0, res.get("preferredTravelStyles").size());
        assertEquals(0, res.get("favoriteProvinces").size());
        assertEquals(0, res.get("favoriteCategories").size());
        assertEquals(0, res.get("favoriteTags").size());
        assertTrue(res.get("preferredBudgetLevel").isNull());
        assertTrue(res.get("preferredCrowdLevel").isNull());
        assertTrue(res.get("preferredAccessibilityLevel").isNull());
    }

    @Test
    void emptyUser_recalculate_producesEmptyButTimestampedProfile() throws Exception {
        Auth a = register("uip-empty-recalc");

        JsonNode res = recalculate(a.token);

        assertEquals(0, res.get("signalCount").asInt());
        assertFalse(res.get("lastRecalculatedAt").isNull(), "recalculate always stamps the time");
        assertEquals(0, res.get("favoriteProvinces").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HEAVY USER — full aggregation across all four signal sources
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void heavyUser_recalculate_aggregatesAllSignalSources() throws Exception {
        Auth a = register("uip-heavy");

        // Wishlist: a beach place in Da Nang, LUXURY / SUNNY / crowd LOW.
        Place beach = seedPlace("Da Nang", "Beaches",
            List.of(TravelStyle.COUPLE, TravelStyle.LUXURY), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "beach", "romantic");
        addToWishlist(a.userId, beach);

        // Saved collection: a museum in Da Nang, FAMILY / CLOUDY.
        Place museum = seedPlace("Da Nang", "Museums",
            List.of(TravelStyle.FAMILY), List.of(WeatherType.CLOUDY),
            BudgetLevel.LOW, CrowdLevel.MEDIUM, AccessibilityLevel.HIGH, "history");
        addToCollection(a.userId, museum);

        // Completed booking: a hotel in Da Nang, COUPLE / SUNNY, LUXURY.
        Place hotel = seedPlace("Da Nang", "Beaches",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "beach");
        seedCompletedBooking(a.userId, hotel);

        // Approved 5★ review: a spa in Hue, COUPLE.
        Place spa = seedPlace("Hue", "Spas",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.HIGH, CrowdLevel.LOW, AccessibilityLevel.MEDIUM, "wellness");
        seedApprovedReview(a.userId, spa, 5);

        JsonNode res = recalculate(a.token);

        assertEquals(4, res.get("signalCount").asInt(), "one signal per source");

        // COUPLE appears in 3 of 4 places → must rank first among travel styles.
        List<String> styles = texts(res.get("preferredTravelStyles"));
        assertEquals("COUPLE", styles.get(0));
        assertTrue(styles.containsAll(List.of("COUPLE", "LUXURY", "FAMILY")));

        // Da Nang appears in 3 places, Hue in 1 → Da Nang first, both present, no dupes.
        List<String> provinces = texts(res.get("favoriteProvinces"));
        assertEquals("Da Nang", provinces.get(0));
        assertEquals(List.of("Da Nang", "Hue"), provinces);

        // Beaches (2) ranks above Museums/Spas (1 each).
        List<String> categories = texts(res.get("favoriteCategories"));
        assertEquals("Beaches", categories.get(0));
        assertTrue(categories.containsAll(List.of("Beaches", "Museums", "Spas")));

        // Tags aggregated across places (beach x2, romantic, history, wellness), de-duplicated.
        List<String> tags = texts(res.get("favoriteTags"));
        assertEquals("beach", tags.get(0));
        assertTrue(tags.containsAll(List.of("beach", "romantic", "history", "wellness")));

        // Modal enums: LUXURY budget (2), LOW crowd (3), HIGH accessibility (3).
        assertEquals("LUXURY", res.get("preferredBudgetLevel").asText());
        assertEquals("LOW", res.get("preferredCrowdLevel").asText());
        assertEquals("HIGH", res.get("preferredAccessibilityLevel").asText());
        assertEquals("SUNNY", texts(res.get("preferredWeatherTypes")).get(0));

        assertFalse(res.get("lastRecalculatedAt").isNull());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // GET AFTER RECALC — persistence
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void get_afterRecalculate_returnsPersistedProfile() throws Exception {
        Auth a = register("uip-persist");
        Place p = seedPlace("Sapa", "Mountains",
            List.of(TravelStyle.BACKPACKER), List.of(WeatherType.COOL),
            BudgetLevel.LOW, CrowdLevel.LOW, AccessibilityLevel.LOW, "trekking");
        addToWishlist(a.userId, p);

        recalculate(a.token);

        JsonNode res = getInterests(a.token); // fresh GET — must read the persisted row
        assertEquals(1, res.get("signalCount").asInt());
        assertFalse(res.get("lastRecalculatedAt").isNull());
        assertEquals(List.of("Sapa"), texts(res.get("favoriteProvinces")));
        assertEquals(List.of("Mountains"), texts(res.get("favoriteCategories")));
        assertEquals("BACKPACKER", texts(res.get("preferredTravelStyles")).get(0));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DETERMINISM
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void recalculate_isDeterministic_sameInputsSameFieldValues() throws Exception {
        Auth a = register("uip-determ");
        addToWishlist(a.userId, seedPlace("Hanoi", "Temples",
            List.of(TravelStyle.SOLO, TravelStyle.FRIENDS), List.of(WeatherType.CLOUDY),
            BudgetLevel.MEDIUM, CrowdLevel.HIGH, AccessibilityLevel.MEDIUM, "culture", "old-quarter"));
        addToCollection(a.userId, seedPlace("Hanoi", "Markets",
            List.of(TravelStyle.SOLO), List.of(WeatherType.CLOUDY),
            BudgetLevel.MEDIUM, CrowdLevel.HIGH, AccessibilityLevel.MEDIUM, "food"));

        JsonNode first = recalculate(a.token);
        JsonNode second = recalculate(a.token);

        // Every derived field identical across recalculations (only the timestamp may advance).
        assertEquals(first.get("preferredTravelStyles"), second.get("preferredTravelStyles"));
        assertEquals(first.get("preferredWeatherTypes"), second.get("preferredWeatherTypes"));
        assertEquals(first.get("favoriteProvinces"), second.get("favoriteProvinces"));
        assertEquals(first.get("favoriteCategories"), second.get("favoriteCategories"));
        assertEquals(first.get("favoriteTags"), second.get("favoriteTags"));
        assertEquals(first.get("preferredBudgetLevel"), second.get("preferredBudgetLevel"));
        assertEquals(first.get("preferredCrowdLevel"), second.get("preferredCrowdLevel"));
        assertEquals(first.get("preferredAccessibilityLevel"), second.get("preferredAccessibilityLevel"));
        assertEquals(first.get("signalCount"), second.get("signalCount"));
        // SOLO (2) ranks ahead of FRIENDS (1) — stable ordering.
        assertEquals("SOLO", texts(first.get("preferredTravelStyles")).get(0));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // OWNERSHIP
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void ownership_recalculatingOneUserDoesNotLeakIntoAnother() throws Exception {
        Auth alice = register("uip-alice");
        Auth bob = register("uip-bob");

        addToWishlist(alice.userId, seedPlace("Nha Trang", "Beaches",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.HIGH, CrowdLevel.LOW, AccessibilityLevel.HIGH, "beach"));

        JsonNode aliceProfile = recalculate(alice.token);
        assertEquals(1, aliceProfile.get("signalCount").asInt());
        assertEquals(List.of("Nha Trang"), texts(aliceProfile.get("favoriteProvinces")));

        // Bob has no signals — his profile is empty and shows his own id.
        JsonNode bobProfile = getInterests(bob.token);
        assertEquals(bob.userId, bobProfile.get("userId").asLong());
        assertEquals(0, bobProfile.get("signalCount").asInt());
        assertEquals(0, bobProfile.get("favoriteProvinces").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NULL SAFETY
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void nullSafety_placeWithoutMetadataOrTags_doesNotFail() throws Exception {
        Auth a = register("uip-nullsafe");
        // A place with NO metadata row and NO tags — only province/category are derivable.
        Place bare = seedBarePlace("Can Tho", "Rivers");
        addToWishlist(a.userId, bare);

        JsonNode res = recalculate(a.token);

        assertEquals(1, res.get("signalCount").asInt());
        assertEquals(List.of("Can Tho"), texts(res.get("favoriteProvinces")));
        assertEquals(List.of("Rivers"), texts(res.get("favoriteCategories")));
        // No metadata → enum modes null, style/weather lists empty; no NPE.
        assertTrue(res.get("preferredBudgetLevel").isNull());
        assertEquals(0, res.get("preferredTravelStyles").size());
        assertEquals(0, res.get("favoriteTags").size());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NO DUPLICATE VALUES
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void noDuplicateValues_repeatedProvinceCategoryTagCollapse() throws Exception {
        Auth a = register("uip-nodup");
        // Three places, all same province + category + shared "beach" tag across sources.
        addToWishlist(a.userId, seedPlace("Phu Quoc", "Beaches",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "beach", "island"));
        addToCollection(a.userId, seedPlace("Phu Quoc", "Beaches",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "beach"));
        seedCompletedBooking(a.userId, seedPlace("Phu Quoc", "Beaches",
            List.of(TravelStyle.COUPLE), List.of(WeatherType.SUNNY),
            BudgetLevel.LUXURY, CrowdLevel.LOW, AccessibilityLevel.HIGH, "beach", "island"));

        JsonNode res = recalculate(a.token);

        assertEquals(3, res.get("signalCount").asInt());
        assertEquals(List.of("Phu Quoc"), texts(res.get("favoriteProvinces")), "no duplicate province");
        assertEquals(List.of("Beaches"), texts(res.get("favoriteCategories")), "no duplicate category");
        assertNoDuplicates(texts(res.get("favoriteTags")));
        assertNoDuplicates(texts(res.get("preferredTravelStyles")));
        assertEquals(List.of("COUPLE"), texts(res.get("preferredTravelStyles")));
        assertTrue(texts(res.get("favoriteTags")).containsAll(List.of("beach", "island")));
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH
    // ═══════════════════════════════════════════════════════════════════════════

    @Test
    void unauthenticated_get_returns401() throws Exception {
        mvc.perform(get("/api/me/interests")).andExpect(status().isUnauthorized());
    }

    @Test
    void unauthenticated_recalculate_returns401() throws Exception {
        mvc.perform(post("/api/me/interests/recalculate")).andExpect(status().isUnauthorized());
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // HTTP HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private JsonNode getInterests(String token) throws Exception {
        String body = mvc.perform(get("/api/me/interests")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
    }

    private JsonNode recalculate(String token) throws Exception {
        String body = mvc.perform(post("/api/me/interests/recalculate")
                .header("Authorization", "Bearer " + token))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        return mapper.readTree(body);
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
    // SEED HELPERS (direct repository persistence for determinism)
    // ═══════════════════════════════════════════════════════════════════════════

    private Place seedPlace(String provinceName, String categoryName,
                            List<TravelStyle> styles, List<WeatherType> weathers,
                            BudgetLevel budget, CrowdLevel crowd, AccessibilityLevel access,
                            String... tags) {
        Place place = seedBarePlace(provinceName, categoryName);

        PlaceMetadata md = new PlaceMetadata();
        md.setPlace(place);
        md.setTravelStyles(new java.util.ArrayList<>(styles));
        md.setWeatherTypes(new java.util.ArrayList<>(weathers));
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
        return place;
    }

    /** A published place with a province + category but no metadata and no tags. */
    private Place seedBarePlace(String provinceName, String categoryName) {
        String u = UUID.randomUUID().toString().substring(0, 8);
        Place place = new Place();
        place.setName(categoryName + " " + u);
        place.setNameNormalized((categoryName + " " + u).toLowerCase());
        place.setSlug("uip-place-" + u);
        place.setCategory(getOrCreateCategory(categoryName));
        place.setAdministrativeUnit(getOrCreateProvince(provinceName));
        place.setAddress("123 Test Street");
        place.setStatus(PlaceStatus.PUBLISHED);
        place.setCreatedBy(creator);
        place.setActive(true);
        return placeRepo.save(place);
    }

    private Category getOrCreateCategory(String name) {
        String slug = "uip-cat-" + name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        return categoryRepo.findBySlug(slug).orElseGet(() -> {
            Category c = new Category();
            c.setName(name);
            c.setSlug(slug);
            c.setActive(true);
            return categoryRepo.save(c);
        });
    }

    private AdministrativeUnit getOrCreateProvince(String name) {
        String slug = "uip-prov-" + name.toLowerCase().replaceAll("[^a-z0-9]+", "-");
        return unitRepo.findBySlug(slug).orElseGet(() -> {
            AdministrativeUnit u = new AdministrativeUnit();
            u.setName(name);
            u.setSlug(slug);
            u.setNameNormalized(name.toLowerCase());
            u.setType(UnitType.PROVINCE);
            u.setLevel(1);
            u.setActive(true);
            return unitRepo.save(u);
        });
    }

    private void addToWishlist(Long userId, Place place) {
        Wishlist wl = wishlistRepo.findByUserId(userId).orElseGet(() -> {
            Wishlist fresh = new Wishlist();
            fresh.setUser(userRepo.findById(userId).orElseThrow());
            return wishlistRepo.save(fresh);
        });
        WishlistItem item = new WishlistItem();
        item.setWishlist(wl);
        item.setPlace(place);
        wishlistItemRepo.save(item);
    }

    private void addToCollection(Long userId, Place place) {
        SavedCollection col = collectionRepo.findByOwnerIdOrderBySortOrderAscCreatedAtAsc(userId)
            .stream().findFirst().orElseGet(() -> {
                SavedCollection fresh = new SavedCollection();
                fresh.setOwner(userRepo.findById(userId).orElseThrow());
                fresh.setName("My Places");
                return collectionRepo.save(fresh);
            });
        SavedCollectionPlace scp = new SavedCollectionPlace();
        scp.setCollection(col);
        scp.setPlace(place);
        scp.setPosition((int) collectionPlaceRepo.findByCollectionIdOrderByPositionAsc(col.getId()).size());
        collectionPlaceRepo.save(scp);
    }

    private Booking seedCompletedBooking(Long userId, Place place) {
        return seedBooking(userId, place, BookingStatus.COMPLETED);
    }

    private Booking seedBooking(Long userId, Place place, BookingStatus status) {
        Booking b = new Booking();
        b.setBookingCode("UIP-" + UUID.randomUUID().toString().substring(0, 10));
        b.setUser(userRepo.findById(userId).orElseThrow());
        b.setHotel(place);
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

    private void seedApprovedReview(Long userId, Place place, int rating) {
        // Backing booking is CONFIRMED (not a completed-booking signal) so the review is the
        // single isolated signal from this place in the aggregation.
        Booking b = seedBooking(userId, place, BookingStatus.CONFIRMED);
        Review r = new Review();
        r.setBooking(b);
        r.setUser(userRepo.findById(userId).orElseThrow());
        r.setPlace(place);
        r.setRatingOverall(rating);
        r.setStatus(ReviewStatus.APPROVED);
        reviewRepo.save(r);
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // ASSERT HELPERS
    // ═══════════════════════════════════════════════════════════════════════════

    private List<String> texts(JsonNode arr) {
        List<String> out = new java.util.ArrayList<>();
        arr.forEach(n -> out.add(n.asText()));
        return out;
    }

    private void assertNoDuplicates(List<String> values) {
        assertEquals(values.size(), new java.util.HashSet<>(values).size(),
            "list must not contain duplicate values: " + values);
    }
}
