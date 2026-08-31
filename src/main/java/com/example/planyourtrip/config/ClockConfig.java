package com.example.planyourtrip.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Clock;

/**
 * H-FIX 3 — a single injectable time source.
 *
 * <p>Business code that decides a calendar day (check-in and check-out windows) must not call
 * {@code LocalDate.now()}, because that silently binds the decision to the server's timezone and to
 * the wall clock, making it both wrong on a host in another zone and untestable around midnight.
 * Those call sites take this {@link Clock} instead and combine it with the property's configured zone
 * — see {@code PartnerBusinessZoneService}.
 *
 * <p>{@link Clock#systemDefaultZone()} keeps the default behaviour identical to what the application
 * did before on a correctly-configured host. Its zone is used only as a fallback when a property has
 * no resolvable timezone; the authoritative zone is always the partner's own setting. Tests replace
 * this bean with a fixed clock to pin both the instant and the zone.
 */
@Configuration
public class ClockConfig {

    @Bean
    public Clock clock() {
        return Clock.systemDefaultZone();
    }
}
