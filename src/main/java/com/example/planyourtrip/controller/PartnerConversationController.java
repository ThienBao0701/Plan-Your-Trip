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
@RequestMapping("/api/partner/conversations")
@Tag(name = "Conversations - Partner", description = "Approved partners message guests about bookings at hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerConversationController {

    private final ConversationService service;

    public PartnerConversationController(ConversationService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List conversations for hotels I own")
    public List<ConversationSummaryResponse> getMine(@AuthUser Long uid) {
        return service.getPartnerConversations(uid);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my conversations")
    public ConversationResponse getById(@AuthUser Long uid, @PathVariable Long id) {
        return service.getConversationForPartner(uid, id);
    }

    @PostMapping("/{id}/messages")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Send a message as the host")
    public MessageResponse sendMessage(@AuthUser Long uid, @PathVariable Long id,
                                        @Valid @RequestBody MessageRequest req) {
        return service.sendPartnerMessage(uid, id, req);
    }

    @PatchMapping("/{id}/read")
    @Operation(summary = "Mark my messages as read")
    public ConversationResponse markRead(@AuthUser Long uid, @PathVariable Long id) {
        return service.markReadByPartner(uid, id);
    }

    @PatchMapping("/{id}/close")
    @Operation(summary = "Close this conversation")
    public ConversationResponse close(@AuthUser Long uid, @PathVariable Long id) {
        return service.closeByPartner(uid, id);
    }
}
