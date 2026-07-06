package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.NotificationDto.*;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@Tag(name = "Notification")
public class NotificationController {

    private final NotificationService service;

    public NotificationController(NotificationService service) { this.service = service; }

    @GetMapping("/api/me/notifications")
    @Operation(summary = "List current user's notifications")
    public List<NotificationSummaryResponse> getMine(@AuthUser Long uid) {
        return service.getMine(uid);
    }

    @GetMapping("/api/me/notifications/unread")
    @Operation(summary = "List current user's unread notifications")
    public List<NotificationSummaryResponse> getUnread(@AuthUser Long uid) {
        return service.getUnread(uid);
    }

    @GetMapping("/api/me/notifications/unread-count")
    @Operation(summary = "Count current user's unread notifications")
    public long getUnreadCount(@AuthUser Long uid) {
        return service.countUnread(uid);
    }

    @PatchMapping("/api/me/notifications/{id}/read")
    @Operation(summary = "Mark a notification as read (owner only)")
    public NotificationResponse markRead(@AuthUser Long uid, @PathVariable Long id) {
        return service.markRead(uid, id);
    }

    @PatchMapping("/api/me/notifications/read-all")
    @Operation(summary = "Mark all of the current user's notifications as read")
    public int markAllRead(@AuthUser Long uid) {
        return service.markAllRead(uid);
    }

    @DeleteMapping("/api/me/notifications/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a notification (owner only)")
    public void delete(@AuthUser Long uid, @PathVariable Long id) {
        service.delete(uid, id);
    }
}
