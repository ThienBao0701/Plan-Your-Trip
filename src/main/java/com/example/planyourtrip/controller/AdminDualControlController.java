package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AdminDualControlDto.DualControlApprovalResponse;
import com.example.planyourtrip.dto.AdminDualControlDto.DualControlRejectRequest;
import com.example.planyourtrip.dto.AdminDualControlDto.DualControlRequestResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.model.DualControlStatus;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.AdminDualControlService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/**
 * RBAC R6 — the dual-control queue (RBAC V1.1 §22.6). In R6 every request is an A16 property move, so every
 * operation needs A16 {@code admin.place.owner.assign} ({@code AdminEndpointRules}); approving also needs a session
 * fresh within 15 minutes. Who may decide what is the service's job: {@link AdminDualControlService}.
 */
@RestController
@RequestMapping("/api/admin/dual-control/requests")
@Tag(name = "Admin - Dual control", description = "Second-administrator approval of dual-controlled actions")
@SecurityRequirement(name = "bearerAuth")
public class AdminDualControlController {

    private final AdminDualControlService service;

    public AdminDualControlController(AdminDualControlService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List dual-control requests, newest first; status filters by the state a reader sees")
    public PageResponse<DualControlRequestResponse> list(
            @AuthUser Long uid,
            @RequestParam(required = false) DualControlStatus status,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer size,
            @RequestParam(required = false) String sort) {
        return service.list(uid, status, page, size, sort);
    }

    @GetMapping("/{id}")
    @Operation(summary = "One dual-control request with its immutable proposal")
    public DualControlRequestResponse get(@AuthUser Long uid, @PathVariable Long id) {
        return service.get(uid, id);
    }

    @PostMapping("/{id}/approve")
    @Operation(summary = "Approve another administrator's request; the stored action runs in the same transaction")
    public DualControlApprovalResponse approve(@AuthUser Long uid, @PathVariable Long id) {
        return service.approve(uid, id);
    }

    @PostMapping("/{id}/reject")
    @Operation(summary = "Reject another administrator's request, with a reason")
    public DualControlRequestResponse reject(@AuthUser Long uid, @PathVariable Long id,
                                             @Valid @RequestBody DualControlRejectRequest req) {
        return service.reject(uid, id, req.reason());
    }

    @PostMapping("/{id}/cancel")
    @Operation(summary = "Cancel your own pending request")
    public DualControlRequestResponse cancel(@AuthUser Long uid, @PathVariable Long id) {
        return service.cancel(uid, id);
    }
}
