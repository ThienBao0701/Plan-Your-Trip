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
@RequestMapping("/api/me/conversations")
@Tag(name = "Conversations - User", description = "Message a partner about your own bookings")
@SecurityRequirement(name = "bearerAuth")
public class UserConversationController {

    private final ConversationService service;

    public UserConversationController(ConversationService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my conversations")
    public List<ConversationSummaryResponse> getMine(@AuthUser Long uid) {
        return service.getMyConversations(uid);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my conversations")
    public ConversationResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getConversationForUser(uid, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Start (or reuse) a conversation for one of my own bookings")
    public ConversationResponse create(@AuthUser Long uid, @Valid @RequestBody ConversationRequest req) {
        return service.createConversation(uid, req);
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Send a message as the guest")
    public MessageResponse sendMessage(@AuthUser Long uid, @PathVariable Long id,
                                        @Valid @RequestBody MessageRequest req) {
        return service.sendUserMessage(uid, id, req);
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark my messages as read")
    public ConversationResponse markRead(@AuthUser Long uid, @PathVariable Long id) {
        return service.markReadByUser(uid, id);
    }

    @PatchMapping("/{id}/close")
    @Operation(summary = "Close this conversation")
    public ConversationResponse close(@AuthUser Long uid, @PathVariable Long id) {
        return service.closeByUser(uid, id);
    }
}
