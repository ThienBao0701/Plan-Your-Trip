package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanDto.TripResponse;
import com.example.planyourtrip.service.TripCollaborationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

/**
 * Public, unauthenticated trip viewing — deliberately a separate controller (and a
 * separate {@code /api/trips/public} prefix, permitAll-listed in SecurityConfig)
 * from both {@link TripPlannerController} ({@code /api/me/trips/**}, always
 * authenticated) and the unrelated legacy {@code TripController} ({@code /api/trips}).
 */
@RestController
@RequestMapping("/api/trips/public")
@Tag(name = "Trips - Public", description = "Read-only public view of trips the owner has made public")
public class PublicTripController {

    private final TripCollaborationService service;

    public PublicTripController(TripCollaborationService service) { this.service = service; }

    @GetMapping("/{id}")
    @Operation(summary = "View a public trip without authentication", description = "Returns 404 if the trip does not exist or is not public.")
    public TripResponse get(@PathVariable Long id) {
        return service.getPublicTrip(id);
    }
}
