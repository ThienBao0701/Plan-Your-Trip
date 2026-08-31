package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AdminActivityLogDto.AdminActivityLogResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.service.AdminActivityLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

/**
 * D1a — read surface for the administrative audit trail.
 *
 * <p>Read-only by construction: there is no create, update or delete mapping here, and
 * {@code AdminActivityLogRepository} exposes no delete method for one to call. Entries are written
 * only as a side effect of the audited mutation itself, inside that mutation's transaction.
 *
 * <p>Authorization is the existing single rule — {@code SecurityConfig} gates {@code /api/admin/**}
 * with {@code hasRole("ADMIN")}, so USER and PARTNER receive 403 here exactly as they do on every
 * other admin route. No new security configuration was introduced.
 */
@RestController
@RequestMapping("/api/admin/activity-logs")
@Tag(name = "Admin - Activity Log", description = "Append-only record of administrative actions")
@SecurityRequirement(name = "bearerAuth")
public class AdminActivityLogController {

    private final AdminActivityLogService service;

    public AdminActivityLogController(AdminActivityLogService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "Search the admin audit trail (newest first; all filters optional)")
    public PageResponse<AdminActivityLogResponse> search(
            @RequestParam(required = false) Long actorUserId,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) String targetType,
            @RequestParam(required = false) Long targetId,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant from,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) Instant to,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size) {
        return service.search(actorUserId, action, targetType, targetId, from, to, page, size);
    }
}
