package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.ConversationDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.ConversationStatus;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.ConversationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/admin/conversations")
@Tag(name = "Conversations - Admin", description = "Admins can view and mediate every conversation")
@SecurityRequirement(name = "bearerAuth")
public class AdminConversationController {

    private final ConversationService service;

    public AdminConversationController(ConversationService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "Search conversations (admin, paged newest-activity-first)")
    public PageResponse<ConversationSummaryResponse> getAll(
            @RequestParam(required = false) ConversationStatus status,
            @RequestParam(required = false) Long userId,
            @RequestParam(required = false) Long partnerProfileId,
            @RequestParam(required = false) Long bookingId,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sort) {
        return service.adminSearchPaged(status, userId, partnerProfileId, bookingId,
            page, size, sort);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get any conversation by ID")
    public ConversationResponse getById(@PathVariable Long id) {
        return service.adminGetById(id);
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Send a message as support/admin (notifies both user and partner)")
    public MessageResponse sendMessage(@AuthUser Long uid, @PathVariable Long id,
                                        @Valid @RequestBody MessageRequest req) {
        return service.sendAdminMessage(uid, id, req);
    }

    @PatchMapping("/{id}/archive")
    @Operation(summary = "Archive a conversation")
    public ConversationResponse archive(@AuthUser Long uid, @PathVariable Long id) {
        return service.archiveByAdmin(uid, id);
    }
}
