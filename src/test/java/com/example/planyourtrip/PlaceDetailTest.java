package com.example.planyourtrip;

import com.example.planyourtrip.model.MediaOwnerType;
import com.example.planyourtrip.model.PlaceOpeningHour;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.repository.MediaAssetRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.util.OpeningHourUtils;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalTime;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class PlaceDetailTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired MediaAssetRepository mediaAssetRepo;

    // ─── Integration: GET /api/places/{id} ────────────────────────────────────

    @Test
    void getDetail_publishedPlace_returns200WithAllExpectedFields() throws Exception {
        Long id = placeRepo.findBySlug("grand-palace-hotel-vung-tau")
            .orElseThrow().getId();

        String body = mvc.perform(get("/api/places/" + id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(id))
            .andExpect(jsonPath("$.slug").value("grand-palace-hotel-vung-tau"))
            .andExpect(jsonPath("$.description").isString())
            .andExpect(jsonPath("$.location").exists())
            .andExpect(jsonPath("$.tags").isArray())
            .andExpect(jsonPath("$.amenities").isArray())
            .andExpect(jsonPath("$.openingHours").isArray())
            .andExpect(jsonPath("$.groupedOpeningHours").isArray())
            .andExpect(jsonPath("$.coverImageUrl").isString())
            .andExpect(jsonPath("$.galleryImages").isArray())
            .andExpect(jsonPath("$.similarPlaces").isArray())
            .andReturn().getResponse().getContentAsString();

        JsonNode node = objectMapper.readTree(body);
        // coverImageUrl must be the one marked cover=true in seed data
        assertEquals(
            "https://cdn.planyourtrip.vn/places/grand-palace-hotel/exterior.jpg",
            node.get("coverImageUrl").asText()
        );
        // galleryImages should have 3 entries (all active images)
        assertEquals(3, node.get("galleryImages").size());
        // groupedOpeningHours: hotel has allDays(00:00–23:59) → should be 1 group "Monday - Sunday"
        assertTrue(node.get("groupedOpeningHours").size() >= 1);
    }

    @Test
    void getDetail_nonExistentId_returns404() throws Exception {
        mvc.perform(get("/api/places/99999"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404))
            .andExpect(jsonPath("$.message").isString());
    }

    @Test
    void getDetail_draftPlace_returns404() throws Exception {
        mvc.perform(get("/api/places/999998"))
            .andExpect(status().isNotFound());
    }

    @Test
    void getDetail_similarPlaces_doesNotContainSelf() throws Exception {
        Long id = placeRepo.findBySlug("grand-palace-hotel-vung-tau")
            .orElseThrow().getId();

        String body = mvc.perform(get("/api/places/" + id))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();

        JsonNode similar = objectMapper.readTree(body).get("similarPlaces");
        for (JsonNode place : similar) {
            assertNotEquals(id.longValue(), place.get("id").asLong(),
                "Self must not appear in similarPlaces");
        }
    }

    @Test
    void coverImage_fallback_usesFirstWhenNoCoverMarked() throws Exception {
        // The Dreamer Café has 2 images, neither marked cover=true → fallback to first by sortOrder
        Long id = placeRepo.findBySlug("the-dreamer-cafe-da-lat")
            .orElseThrow().getId();

        String body = mvc.perform(get("/api/places/" + id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.coverImageUrl").isString())
            .andReturn().getResponse().getContentAsString();

        String cover = objectMapper.readTree(body).get("coverImageUrl").asText();
        // Must be the first image (sortOrder=1, garden.jpg)
        assertEquals(
            "https://cdn.planyourtrip.vn/places/the-dreamer-cafe/garden.jpg", cover
        );
    }

    @Test
    void coverImage_null_whenNoMediaExist() throws Exception {
        // Ha Long place is seeded with no media assets → coverImageUrl must be absent/null
        // Filter to PUBLISHED only: other tests may create non-published places with no media
        Long id = placeRepo.findAll().stream()
            .filter(p -> p.getStatus() == PlaceStatus.PUBLISHED
                && mediaAssetRepo
                    .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(MediaOwnerType.PLACE, p.getId())
                    .isEmpty())
            .findFirst()
            .orElseThrow(() -> new AssertionError("Expected a PUBLISHED place with no media assets"))
            .getId();

        mvc.perform(get("/api/places/" + id))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.coverImageUrl").doesNotExist());
    }

    @Test
    void getDetailBySlug_publishedPlace_returns200() throws Exception {
        mvc.perform(get("/api/places/slug/ba-na-hills-cau-vang"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.slug").value("ba-na-hills-cau-vang"))
            .andExpect(jsonPath("$.coverImageUrl").value(
                "https://cdn.planyourtrip.vn/places/ba-na-hills/golden-bridge.jpg"))
            .andExpect(jsonPath("$.galleryImages").isArray());
    }

    @Test
    void getDetailBySlug_unknownSlug_returns404() throws Exception {
        mvc.perform(get("/api/places/slug/this-does-not-exist"))
            .andExpect(status().isNotFound());
    }

    // ─── Unit: OpeningHourUtils.isOpenNow ─────────────────────────────────────

    private PlaceOpeningHour hour(int day, int openH, int openM, int closeH, int closeM, boolean closed) {
        PlaceOpeningHour h = new PlaceOpeningHour();
        h.setDayOfWeek(day);
        h.setOpenTime(closed ? null : LocalTime.of(openH, openM));
        h.setCloseTime(closed ? null : LocalTime.of(closeH, closeM));
        h.setClosed(closed);
        return h;
    }

    @Test
    void openNow_normalHours_isOpenDuringBusinessHours() {
        List<PlaceOpeningHour> hours = List.of(hour(1, 8, 0, 22, 0, false));
        assertTrue(OpeningHourUtils.isOpenNow(hours, LocalTime.of(12, 0), 1));
    }

    @Test
    void openNow_normalHours_isClosedBeforeOpen() {
        List<PlaceOpeningHour> hours = List.of(hour(1, 8, 0, 22, 0, false));
        assertFalse(OpeningHourUtils.isOpenNow(hours, LocalTime.of(7, 59), 1));
    }

    @Test
    void openNow_normalHours_isClosedAfterClose() {
        List<PlaceOpeningHour> hours = List.of(hour(1, 8, 0, 22, 0, false));
        assertFalse(OpeningHourUtils.isOpenNow(hours, LocalTime.of(22, 0), 1));
    }

    @Test
    void openNow_overnightHours_isOpenBeforeMidnight() {
        List<PlaceOpeningHour> hours = List.of(hour(5, 18, 0, 2, 0, false));
        assertTrue(OpeningHourUtils.isOpenNow(hours, LocalTime.of(23, 30), 5));
    }

    @Test
    void openNow_overnightHours_isOpenAfterMidnight() {
        List<PlaceOpeningHour> hours = List.of(hour(5, 18, 0, 2, 0, false));
        assertTrue(OpeningHourUtils.isOpenNow(hours, LocalTime.of(1, 0), 5));
    }

    @Test
    void openNow_overnightHours_isClosedMidDay() {
        List<PlaceOpeningHour> hours = List.of(hour(5, 18, 0, 2, 0, false));
        assertFalse(OpeningHourUtils.isOpenNow(hours, LocalTime.of(10, 0), 5));
    }

    @Test
    void openNow_closedDay_isFalse() {
        List<PlaceOpeningHour> hours = List.of(hour(7, 0, 0, 0, 0, true));
        assertFalse(OpeningHourUtils.isOpenNow(hours, LocalTime.of(12, 0), 7));
    }

    @Test
    void openNow_noDayRecord_isFalse() {
        List<PlaceOpeningHour> hours = List.of(hour(1, 8, 0, 22, 0, false));
        assertFalse(OpeningHourUtils.isOpenNow(hours, LocalTime.of(12, 0), 6));
    }

    // ─── Unit: OpeningHourUtils.group ─────────────────────────────────────────

    @Test
    void groupOpeningHours_consecutiveSameSchedule_mergedIntoOneGroup() {
        List<PlaceOpeningHour> hours = List.of(
            hour(1, 8, 0, 22, 0, false),
            hour(2, 8, 0, 22, 0, false),
            hour(3, 8, 0, 22, 0, false),
            hour(4, 8, 0, 22, 0, false),
            hour(5, 8, 0, 22, 0, false),
            hour(6, 7, 30, 22, 30, false),
            hour(7, 7, 30, 22, 30, false)
        );
        var groups = OpeningHourUtils.group(hours);
        assertEquals(2, groups.size());
        assertEquals("Monday - Friday", groups.get(0).days());
        assertEquals("Saturday - Sunday", groups.get(1).days());
    }

    @Test
    void groupOpeningHours_allSameSchedule_singleGroup() {
        List<PlaceOpeningHour> hours = List.of(
            hour(1, 0, 0, 23, 59, false),
            hour(2, 0, 0, 23, 59, false),
            hour(3, 0, 0, 23, 59, false),
            hour(4, 0, 0, 23, 59, false),
            hour(5, 0, 0, 23, 59, false),
            hour(6, 0, 0, 23, 59, false),
            hour(7, 0, 0, 23, 59, false)
        );
        var groups = OpeningHourUtils.group(hours);
        assertEquals(1, groups.size());
        assertEquals("Monday - Sunday", groups.get(0).days());
    }

    @Test
    void groupOpeningHours_emptyList_returnsEmpty() {
        var groups = OpeningHourUtils.group(List.of());
        assertTrue(groups.isEmpty());
    }
}
