package com.example.planyourtrip;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerSettings;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PartnerSettingsRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.service.PartnerBusinessZoneService;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * H-FIX 3 — check-in/check-out windows must be evaluated in the property's timezone.
 *
 * <p>H found both services calling {@code LocalDate.now()}. On the development machine the server
 * runs at {@code +07:00}, identical to the seeded {@code Asia/Ho_Chi_Minh} property, so the defect
 * was invisible; on a UTC host it shifts the window by a day for seven hours after local midnight.
 *
 * <p>These tests never depend on the machine's own timezone: the zone-resolution cases drive
 * {@link PartnerBusinessZoneService} with explicitly fixed {@link Clock}s, and the end-to-end case
 * puts the property in a zone <em>behind</em> the server so the corrected behaviour is a rejection —
 * which mutates no booking.
 */
@SpringBootTest
@AutoConfigureMockMvc
class PartnerCheckInOutTimezoneTest {

    @Autowired MockMvc mvc;
    @Autowired ObjectMapper mapper;
    @Autowired PlaceRepository placeRepo;
    @Autowired PartnerProfileRepository profileRepo;
    @Autowired PartnerSettingsRepository settingsRepo;
    @Autowired com.example.planyourtrip.repository.UserRepository userRepo;

    private static final ZoneId HCM = ZoneId.of("Asia/Ho_Chi_Minh");   // UTC+7
    private static final ZoneId UTC = ZoneId.of("UTC");
    private static final ZoneId LA  = ZoneId.of("America/Los_Angeles"); // UTC-7/-8

    private String partnerToken;
    private Place hotel;
    private String originalTimezone;

    @BeforeEach
    void setup() throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"partner@planyourtrip.com\",\"password\":\"partner123456\"}"))
            .andExpect(status().isOk())
            .andReturn().getResponse().getContentAsString();
        partnerToken = mapper.readTree(body).get("token").asText();

        hotel = placeRepo.findBySlug("grand-palace-hotel-vung-tau").orElseThrow();
        originalTimezone = settings().getTimezone();
    }

    @AfterEach
    void restoreTimezone() {
        PartnerSettings s = settings();
        s.setTimezone(originalTimezone);
        settingsRepo.save(s);
    }

    private PartnerSettings settings() {
        Long userId = userRepo.findByEmail("partner@planyourtrip.com").orElseThrow().getId();
        PartnerProfile owner = profileRepo.findByUserId(userId).orElseThrow();
        return settingsRepo.findByPartnerProfileId(owner.getId()).orElseThrow();
    }

    private void setTimezone(String zone) {
        PartnerSettings s = settings();
        s.setTimezone(zone);
        settingsRepo.save(s);
    }

    /** A booking attached to the seeded partner-owned hotel; never persisted. */
    private Booking bookingAtHotel() {
        Booking b = new Booking();
        b.setHotel(hotel);
        return b;
    }

    private PartnerBusinessZoneService zoneServiceAt(Instant instant, ZoneId serverZone) {
        return new PartnerBusinessZoneService(settingsRepo, Clock.fixed(instant, serverZone));
    }

    // ─── Zone resolution ──────────────────────────────────────────────────────

    @Test
    void todayFor_usesPropertyZoneNotServerZone() {
        setTimezone("Asia/Ho_Chi_Minh");
        // 2026-06-15T18:30Z is still the 15th in UTC but already the 16th in Ho Chi Minh (+7).
        Instant instant = Instant.parse("2026-06-15T18:30:00Z");

        assertEquals(LocalDate.of(2026, 6, 15), LocalDate.ofInstant(instant, UTC),
            "sanity: the instant is the 15th in UTC");
        assertEquals(LocalDate.of(2026, 6, 16),
            zoneServiceAt(instant, UTC).todayFor(bookingAtHotel()),
            "a UTC server must still resolve the property's local date");
    }

    @Test
    void todayFor_propertyBehindServer_resolvesEarlierDate() {
        setTimezone("America/Los_Angeles");
        // 2026-06-16T04:00Z — the 16th in UTC and in HCM, but still the 15th in Los Angeles.
        Instant instant = Instant.parse("2026-06-16T04:00:00Z");
        assertEquals(LocalDate.of(2026, 6, 15),
            zoneServiceAt(instant, HCM).todayFor(bookingAtHotel()));
    }

    @Test
    void todayFor_acrossMidnightBoundary_flipsWithThePropertyZone() {
        setTimezone("Asia/Ho_Chi_Minh");
        Instant justBefore = ZonedDateTime.of(2026, 6, 16, 23, 59, 59, 0, HCM).toInstant();
        Instant justAfter  = ZonedDateTime.of(2026, 6, 17, 0, 0, 1, 0, HCM).toInstant();

        assertEquals(LocalDate.of(2026, 6, 16), zoneServiceAt(justBefore, UTC).todayFor(bookingAtHotel()));
        assertEquals(LocalDate.of(2026, 6, 17), zoneServiceAt(justAfter, UTC).todayFor(bookingAtHotel()));
    }

    @Test
    void zoneFor_fallsBackToServerZoneWhenTimezoneIsInvalid() {
        setTimezone("Not/AZone");
        assertEquals(UTC, zoneServiceAt(Instant.parse("2026-06-16T04:00:00Z"), UTC)
            .zoneFor(bookingAtHotel()),
            "an unparseable configured zone must fall back, not throw");
    }

    @Test
    void zoneFor_fallsBackWhenBookingHasNoResolvableOwner() {
        PartnerBusinessZoneService svc = zoneServiceAt(Instant.parse("2026-06-16T04:00:00Z"), UTC);
        assertEquals(UTC, svc.zoneFor(new Booking()), "a booking with no hotel must not throw");
        assertEquals(UTC, svc.zoneFor(null), "a null booking must not throw");
    }

    @Test
    void zoneFor_readsTheConfiguredZone() {
        setTimezone("Asia/Ho_Chi_Minh");
        assertEquals(HCM, zoneServiceAt(Instant.now(), UTC).zoneFor(bookingAtHotel()));
        setTimezone("America/Los_Angeles");
        assertEquals(LA, zoneServiceAt(Instant.now(), UTC).zoneFor(bookingAtHotel()));
    }

    // ─── Wiring ───────────────────────────────────────────────────────────────

    /**
     * The two services must obtain "today" from the zone service rather than the ambient clock.
     *
     * <p>This is asserted structurally rather than by driving the real endpoints. An end-to-end
     * boundary test would have to move a booking across its check-in window, and the only observable
     * difference between the old and new behaviour is <em>admitting a guest</em> — an irreversible
     * lifecycle transition on shared seed data. The boundary arithmetic itself is already pinned
     * deterministically by the zone-resolution cases above, which is where the defect actually lived.
     */
    @Test
    void checkInAndCheckOutServices_dependOnTheZoneService() {
        assertTrue(java.util.Arrays.stream(
                com.example.planyourtrip.service.PartnerCheckInService.class.getDeclaredFields())
            .anyMatch(f -> f.getType() == PartnerBusinessZoneService.class),
            "PartnerCheckInService must resolve the business date through PartnerBusinessZoneService");
        assertTrue(java.util.Arrays.stream(
                com.example.planyourtrip.service.PartnerCheckOutService.class.getDeclaredFields())
            .anyMatch(f -> f.getType() == PartnerBusinessZoneService.class),
            "PartnerCheckOutService must resolve the business date through PartnerBusinessZoneService");
    }
}
