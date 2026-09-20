package com.example.planyourtrip;

import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.example.planyourtrip.util.SlugUtils;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityManager;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/**
 * Phase A (S2) — public property endpoints show only PUBLISHED properties.
 *
 * <p>Before Phase A, {@code /api/places/{id}/availability}, {@code GET /api/rooms/{id}/pricing} and the
 * three public rate-plan endpoints loaded their place or room by id without checking publication, so a
 * DRAFT property's rooms, images, amenities and prices were readable by walking sequential ids. Each is
 * now resolved through {@code PublicListingVisibility}: every non-published status is a 404 that carries
 * none of the property's data, exactly like an id that does not exist.
 *
 * <p>Each test builds its own properties (place, hotel detail, active room, base rate plan, inventory for
 * the stay) and rolls them back. Requests are unauthenticated — these endpoints are public.
 */
@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class PublicListingVisibilityTest {

    private static final EnumSet<PlaceStatus> NOT_PUBLIC = EnumSet.complementOf(EnumSet.of(PlaceStatus.PUBLISHED));

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired EntityManager em;
    @Autowired PlaceRepository places;
    @Autowired CategoryRepository categories;
    @Autowired AdministrativeUnitRepository locations;
    @Autowired UserRepository users;
    @Autowired HotelDetailRepository hotelDetails;
    @Autowired HotelRoomRepository rooms;
    @Autowired RatePlanRepository ratePlans;
    @Autowired RoomInventoryRepository inventory;

    private LocalDate checkIn;
    private LocalDate checkOut;

    /** One property: its place, its active room and that room's base rate plan. */
    private record Listing(Place place, HotelRoom room, RatePlan plan) {}

    @BeforeEach
    void stay() {
        checkIn = LocalDate.now().plusDays(40);
        checkOut = checkIn.plusDays(2);
    }

    @Test
    void aPublishedPropertyIsServedByEveryPublicEndpoint() throws Exception {
        Listing published = listing(PlaceStatus.PUBLISHED);
        for (Map.Entry<String, MockHttpServletRequestBuilder> probe : probes(published).entrySet()) {
            MvcResult result = mvc.perform(probe.getValue()).andReturn();
            assertEquals(200, result.getResponse().getStatus(),
                probe.getKey() + " -> " + result.getResponse().getContentAsString());
        }
        JsonNode availability = json(mvc.perform(availability(published.place().getId())).andReturn());
        assertTrue(availability.get("availableRooms").toString().contains(published.room().getRoomName()));
    }

    @Test
    void everyNonPublishedStatusIsHiddenFromEveryPublicEndpoint() throws Exception {
        for (PlaceStatus status : NOT_PUBLIC) {
            Listing hidden = listing(status);
            for (Map.Entry<String, MockHttpServletRequestBuilder> probe : probes(hidden).entrySet()) {
                MvcResult result = mvc.perform(probe.getValue()).andReturn();
                String body = result.getResponse().getContentAsString(StandardCharsets.UTF_8);
                assertEquals(404, result.getResponse().getStatus(), status + " " + probe.getKey() + " -> " + body);
                assertNoListingData(hidden, body, status + " " + probe.getKey());
            }
        }
    }

    @Test
    void aHiddenPropertyIsIndistinguishableFromAMissingId() throws Exception {
        Listing draft = listing(PlaceStatus.DRAFT);
        long missingRoom = Long.MAX_VALUE - 7;
        long missingPlace = Long.MAX_VALUE - 9;

        assertEquals("Room not found: " + draft.room().getId(),
            json(mvc.perform(pricing(draft.room().getId())).andReturn()).get("message").asText());
        assertEquals("Room not found: " + missingRoom,
            json(mvc.perform(pricing(missingRoom)).andReturn()).get("message").asText());

        assertEquals("Place not found: " + draft.place().getId(),
            json(mvc.perform(availability(draft.place().getId())).andReturn()).get("message").asText());
        assertEquals("Place not found: " + missingPlace,
            json(mvc.perform(availability(missingPlace)).andReturn()).get("message").asText());
    }

    @Test
    void mixingAPublishedIdWithADraftIdLeaksNothing() throws Exception {
        Listing published = listing(PlaceStatus.PUBLISHED);
        Listing draft = listing(PlaceStatus.DRAFT);

        // A draft plan requested through a published room: the plan does not belong to that room.
        for (String kind : new String[] {"preview", "cancellation-preview"}) {
            MvcResult viaPublishedRoom = mvc.perform(ratePlanAction(published.room().getId(), draft.plan().getId(), kind)).andReturn();
            assertEquals(404, viaPublishedRoom.getResponse().getStatus(), kind);
            assertNoListingData(draft, viaPublishedRoom.getResponse().getContentAsString(), kind + " via published room");

            // A published plan requested through a draft room: the room is not public.
            MvcResult viaDraftRoom = mvc.perform(ratePlanAction(draft.room().getId(), published.plan().getId(), kind)).andReturn();
            assertEquals(404, viaDraftRoom.getResponse().getStatus(), kind);
        }

        // The published property's availability never includes the draft's room.
        String availability = mvc.perform(availability(published.place().getId())).andReturn()
            .getResponse().getContentAsString();
        assertFalse(availability.contains(draft.room().getRoomName()));
    }

    @Test
    void anInactiveRoomOfAPublishedPropertyIsNotPubliclySellable() throws Exception {
        Listing published = listing(PlaceStatus.PUBLISHED);
        HotelRoom inactive = room(published.place(), false);
        RatePlan plan = ratePlan(inactive);

        assertEquals(404, mvc.perform(pricing(inactive.getId())).andReturn().getResponse().getStatus());
        assertEquals(404, mvc.perform(get("/api/rooms/" + inactive.getId() + "/rate-plans")).andReturn().getResponse().getStatus());
        assertEquals(404, mvc.perform(ratePlanAction(inactive.getId(), plan.getId(), "preview")).andReturn().getResponse().getStatus());
        assertEquals(404, mvc.perform(quote(inactive.getId())).andReturn().getResponse().getStatus());

        String availability = mvc.perform(availability(published.place().getId())).andReturn()
            .getResponse().getContentAsString();
        assertTrue(availability.contains(published.room().getRoomName()));
        assertFalse(availability.contains(inactive.getRoomName()));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // probes
    // ══════════════════════════════════════════════════════════════════════════

    private Map<String, MockHttpServletRequestBuilder> probes(Listing l) throws Exception {
        Long placeId = l.place().getId();
        Long roomId = l.room().getId();
        Long planId = l.plan().getId();
        Map<String, MockHttpServletRequestBuilder> m = new LinkedHashMap<>();
        m.put("place detail", get("/api/places/" + placeId));
        m.put("place media", get("/api/places/" + placeId + "/media"));
        m.put("availability", availability(placeId));
        m.put("legacy pricing", pricing(roomId));
        m.put("rate plans", get("/api/rooms/" + roomId + "/rate-plans")
            .param("checkIn", checkIn.toString()).param("checkOut", checkOut.toString()));
        m.put("rate plan preview", ratePlanAction(roomId, planId, "preview"));
        m.put("cancellation preview", ratePlanAction(roomId, planId, "cancellation-preview"));
        m.put("pricing quote", quote(roomId));
        return m;
    }

    private MockHttpServletRequestBuilder availability(long placeId) {
        return get("/api/places/" + placeId + "/availability")
            .param("checkIn", checkIn.toString()).param("checkOut", checkOut.toString()).param("adults", "2");
    }

    private MockHttpServletRequestBuilder pricing(long roomId) {
        return get("/api/rooms/" + roomId + "/pricing")
            .param("checkIn", checkIn.toString()).param("checkOut", checkOut.toString());
    }

    private MockHttpServletRequestBuilder ratePlanAction(long roomId, long planId, String kind) {
        return get("/api/rooms/" + roomId + "/rate-plans/" + planId + "/" + kind)
            .param("checkIn", checkIn.toString()).param("checkOut", checkOut.toString());
    }

    private MockHttpServletRequestBuilder quote(long roomId) throws Exception {
        return post("/api/rooms/" + roomId + "/pricing/quote")
            .contentType(MediaType.APPLICATION_JSON)
            .content(mapper.writeValueAsString(Map.of(
                "checkIn", checkIn.toString(), "checkOut", checkOut.toString(), "adults", 2)));
    }

    private void assertNoListingData(Listing l, String body, String label) {
        assertFalse(body.contains(l.place().getName()), label + ": place name leaked");
        assertFalse(body.contains(l.room().getRoomName()), label + ": room name leaked");
        assertFalse(body.contains(l.plan().getRateName()), label + ": rate plan leaked");
        assertFalse(body.contains("4242420"), label + ": price leaked");
    }

    private JsonNode json(MvcResult result) throws Exception {
        return mapper.readTree(result.getResponse().getContentAsString(StandardCharsets.UTF_8));
    }

    // ══════════════════════════════════════════════════════════════════════════
    // fixtures
    // ══════════════════════════════════════════════════════════════════════════

    private Listing listing(PlaceStatus status) {
        String tag = UUID.randomUUID().toString().substring(0, 8);
        Place p = new Place();
        p.setName("S2 Probe Hotel " + tag);
        p.setNameNormalized(SlugUtils.normalize(p.getName()));
        p.setSlug("s2-probe-hotel-" + tag);
        Category accommodation = categories.findBySlug("accommodation").orElseThrow();
        p.setCategory(accommodation);
        p.setSubcategory(categories.findBySlug("hotel").orElse(null));
        p.setAdministrativeUnit(locations.findByParentIsNull().get(0));
        p.setAddress("1 Probe Street");
        p.setShortDescription("S2 probe " + tag);
        p.setStatus(status);
        p.setCreatedBy(users.findByEmail("admin@planyourtrip.com").orElseThrow());
        places.saveAndFlush(p);

        HotelDetail d = new HotelDetail();
        d.setPlace(p);
        d.setStarRating(3);
        d.setCheckInTime(LocalTime.of(14, 0));
        d.setCheckOutTime(LocalTime.of(12, 0));
        hotelDetails.saveAndFlush(d);

        HotelRoom room = room(p, true);
        RatePlan plan = ratePlan(room);
        em.flush();
        return new Listing(p, room, plan);
    }

    private HotelRoom room(Place place, boolean active) {
        String tag = UUID.randomUUID().toString().substring(0, 8);
        HotelRoom r = new HotelRoom();
        r.setHotelDetail(hotelDetails.findByPlaceId(place.getId()).orElseThrow());
        r.setRoomName("S2 Probe Room " + tag);
        r.setRoomCode("S2-" + tag);
        r.setRoomType(RoomType.DELUXE);
        r.setMaxAdults(2);
        r.setMaxGuests(3);
        r.setPriceFrom(new BigDecimal("4242420.00"));
        r.setQuantity(5);
        r.setAvailableQuantity(5);
        r.setActive(active);
        rooms.saveAndFlush(r);
        for (LocalDate night = checkIn; night.isBefore(checkOut); night = night.plusDays(1)) {
            RoomInventory inv = new RoomInventory();
            inv.setHotelRoom(r);
            inv.setInventoryDate(night);
            inv.setTotalInventory(5);
            inv.setAvailableInventory(5);
            inventory.save(inv);
        }
        return r;
    }

    private RatePlan ratePlan(HotelRoom room) {
        RatePlan plan = new RatePlan();
        plan.setHotelRoom(room);
        plan.setRateName("S2 Probe Rate " + UUID.randomUUID().toString().substring(0, 8));
        plan.setRateType(RatePlanType.STANDARD);
        plan.setPricePerNight(new BigDecimal("4242420.00"));
        plan.setStartDate(LocalDate.now());
        plan.setEndDate(LocalDate.now().plusDays(120));
        plan.setActive(true);
        return ratePlans.saveAndFlush(plan);
    }
}
