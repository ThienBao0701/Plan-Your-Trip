package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanTimelineDto.TripTimelineResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripTimelineService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Timeline", description = "Read-only merged view of a trip's days, items, documents and reminders")
@SecurityRequirement(name = "bearerAuth")
public class TripTimelineController {

    private final TripTimelineService service;

    public TripTimelineController(TripTimelineService service) { this.service = service; }

    @GetMapping("/{tripId}/timeline")
    @Operation(summary = "Get a trip's combined timeline, sorted by date/time ascending")
    public TripTimelineResponse getTimeline(@AuthUser Long uid, @PathVariable Long tripId) {
        return service.getTimeline(uid, tripId);
    }
}
