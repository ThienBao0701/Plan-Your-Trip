package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.ConversationDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.ConversationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/conversations")
@Tag(name = "Conversations - Admin", description = "Admins can view and mediate every conversation")
@SecurityRequirement(name = "bearerAuth")
public class AdminConversationController {

    private final ConversationService service;

    public AdminConversationController(ConversationService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List all conversations")
    public List<ConversationSummaryResponse> getAll() {
        return service.adminGetAll();
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
    public ConversationResponse archive(@PathVariable Long id) {
        return service.archiveByAdmin(id);
    }
}
