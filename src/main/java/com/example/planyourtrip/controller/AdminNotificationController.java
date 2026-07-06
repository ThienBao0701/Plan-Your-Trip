package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.NotificationDto.*;
import com.example.planyourtrip.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/notifications")
@Tag(name = "Admin - Notification")
public class AdminNotificationController {

    private final NotificationService service;

    public AdminNotificationController(NotificationService service) { this.service = service; }

    @PostMapping("/broadcast")
    @Operation(summary = "Broadcast a notification to all enabled users")
    public int broadcast(@RequestBody @Valid BroadcastRequest req) {
        return service.adminBroadcast(req);
    }

    @GetMapping
    @Operation(summary = "List all notifications (admin)")
    public List<NotificationResponse> getAll() {
        return service.adminGetAll();
    }
}
