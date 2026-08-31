package com.example.planyourtrip.service;

import com.example.planyourtrip.model.Booking;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.PartnerSettings;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.repository.PartnerSettingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.time.ZoneId;

/**
 * H-FIX 3 — resolves the calendar day a partner operation happens on, in the property's own timezone.
 *
 * <p>Check-in and check-out are calendar-day decisions: "has the early window opened", "has the stay
 * ended". Both previously called {@code LocalDate.now()}, which answers those questions in the
 * <em>server's</em> timezone. On the development machine the server runs at {@code +07:00}, the same
 * offset as the seeded {@code Asia/Ho_Chi_Minh} property, so the two agreed and the bug was invisible.
 * On a UTC host — the normal deployment — they diverge for the seven hours after local midnight, and a
 * guest arriving late in the evening would be told their check-in window has not opened yet.
 *
 * <p>The authoritative zone is the one the operator configured: {@code PartnerSettings.timezone},
 * belonging to the {@link PartnerProfile} that owns the booking's hotel. No zone is hardcoded here,
 * and the server's own zone is only ever a last-resort fallback, never a business input.
 *
 * <p>Resolution deliberately never throws. A booking whose hotel has no owner, a partner with no
 * settings row, or a settings row holding an unparseable zone all fall back to the injected
 * {@link Clock}'s zone: a check-in must not fail because of a misconfigured preference. An
 * unparseable value is logged as a warning so it is visible rather than silent.
 *
 * <p>The {@link Clock} is injected so tests can pin both instant and zone; see
 * {@code PartnerCheckInOutTimezoneTest}.
 */
@Service
@Transactional(readOnly = true)
public class PartnerBusinessZoneService {

    private static final Logger log = LoggerFactory.getLogger(PartnerBusinessZoneService.class);

    private final PartnerSettingsRepository settingsRepo;
    private final Clock clock;

    public PartnerBusinessZoneService(PartnerSettingsRepository settingsRepo, Clock clock) {
        this.settingsRepo = settingsRepo;
        this.clock = clock;
    }

    /** Today's date in the property's configured zone — the date every window check must use. */
    public LocalDate todayFor(Booking booking) {
        return LocalDate.now(clock.withZone(zoneFor(booking)));
    }

    /**
     * The configured zone for the booking's property, or the server zone when none is resolvable.
     */
    public ZoneId zoneFor(Booking booking) {
        Long profileId = ownerProfileId(booking);
        if (profileId == null) return clock.getZone();
        return settingsRepo.findByPartnerProfileId(profileId)
            .map(PartnerSettings::getTimezone)
            .map(this::parseOrNull)
            .orElseGet(clock::getZone);
    }

    private Long ownerProfileId(Booking booking) {
        if (booking == null) return null;
        Place hotel = booking.getHotel();
        if (hotel == null) return null;
        PartnerProfile owner = hotel.getOwner();
        return owner != null ? owner.getId() : null;
    }

    /** Returns null (not an exception) for a blank or unrecognised zone id, so the caller can fall back. */
    private ZoneId parseOrNull(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            return ZoneId.of(raw.trim());
        } catch (DateTimeException ex) {
            log.warn("PartnerSettings.timezone '{}' is not a valid zone id; falling back to {}",
                raw, clock.getZone());
            return null;
        }
    }
}
