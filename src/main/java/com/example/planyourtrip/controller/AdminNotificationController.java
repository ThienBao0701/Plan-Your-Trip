package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.NotificationDto.*;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.NotificationType;
import com.example.planyourtrip.model.Priority;
import com.example.planyourtrip.model.RelatedEntityType;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

@RestController
@RequestMapping("/api/admin/notifications")
@Tag(name = "Admin - Notification")
public class AdminNotificationController {

    private final NotificationService service;

    public AdminNotificationController(NotificationService service) { this.service = service; }

    @PostMapping("/broadcast")
    @Operation(summary = "Broadcast a notification to all enabled users")
    public int broadcast(@AuthUser Long uid, @RequestBody @Valid BroadcastRequest req) {
        return service.adminBroadcast(uid, req);
    }

    @GetMapping
    @Operation(summary = "Search notifications (admin, paged newest-first)")
    public PageResponse<NotificationResponse> getAll(
            @RequestParam(required = false) Long recipientUserId,
            @RequestParam(required = false) NotificationType type,
            @RequestParam(required = false) Priority priority,
            @RequestParam(required = false) Boolean read,
            @RequestParam(required = false) RelatedEntityType relatedEntityType,
            @RequestParam(required = false) Long relatedEntityId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sort) {
        return service.adminSearchPaged(recipientUserId, type, priority, read,
            relatedEntityType, relatedEntityId, from, to, page, size, sort);
    }
}
