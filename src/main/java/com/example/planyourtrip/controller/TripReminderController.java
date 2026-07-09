package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.TripPlanTimelineDto.TripPlanReminderRequest;
import com.example.planyourtrip.dto.TripPlanTimelineDto.TripPlanReminderResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.TripPlanReminderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/me/trips")
@Tag(name = "Customer - Trip Reminders", description = "In-app reminder foundation for a trip (no push/email/scheduler yet)")
@SecurityRequirement(name = "bearerAuth")
public class TripReminderController {

    private final TripPlanReminderService service;

    public TripReminderController(TripPlanReminderService service) { this.service = service; }

    @GetMapping("/{tripId}/reminders")
    @Operation(summary = "List a trip's reminders, soonest first",
        description = "Cancelled reminders are hidden by default; pass includeCancelled=true to see them.")
    public List<TripPlanReminderResponse> list(@AuthUser Long uid, @PathVariable Long tripId,
                                                @RequestParam(defaultValue = "false") boolean includeCancelled) {
        return service.list(uid, tripId, includeCancelled);
    }

    @PostMapping("/{tripId}/reminders")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a reminder (owner or EDITOR collaborator)")
    public TripPlanReminderResponse create(@AuthUser Long uid, @PathVariable Long tripId,
                                            @Valid @RequestBody TripPlanReminderRequest req) {
        return service.create(uid, tripId, req);
    }

    @PutMapping("/reminders/{id}")
    @Operation(summary = "Update a reminder (owner or EDITOR collaborator)")
    public TripPlanReminderResponse update(@AuthUser Long uid, @PathVariable Long id,
                                            @Valid @RequestBody TripPlanReminderRequest req) {
        return service.update(uid, id, req);
    }

    @PatchMapping("/reminders/{id}/complete")
    @Operation(summary = "Mark a reminder as completed")
    public TripPlanReminderResponse complete(@AuthUser Long uid, @PathVariable Long id) {
        return service.complete(uid, id);
    }

    @PatchMapping("/reminders/{id}/cancel")
    @Operation(summary = "Cancel a reminder (kept in storage, hidden from the default list)")
    public TripPlanReminderResponse cancel(@AuthUser Long uid, @PathVariable Long id) {
        return service.cancel(uid, id);
    }

    @DeleteMapping("/reminders/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a reminder (owner or EDITOR collaborator)")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.delete(uid, id);
    }
}
