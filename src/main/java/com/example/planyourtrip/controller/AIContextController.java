package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.AITripContextDto.AITripContextResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.AITripContextService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Phase 7.50 — AI Trip Context endpoint.
 *
 * <p>Mounted at {@code GET /api/me/ai/context}. The {@code /api/me/ai} prefix reserves room for future
 * AI-facing read endpoints without disturbing existing modules.
 *
 * <p>Authenticated-only (401 otherwise) and strictly own-scoped: the context is assembled solely from
 * the acting user's {@link AuthUser} id — there is no path/query user parameter, so no cross-user leak.
 */
@RestController
@RequestMapping("/api/me/ai")
@Tag(name = "Customer - AI Context",
     description = "Read-only, single-source-of-truth aggregate for AI capabilities")
@SecurityRequirement(name = "bearerAuth")
public class AIContextController {

    private final AITripContextService service;

    public AIContextController(AITripContextService service) {
        this.service = service;
    }

    @GetMapping("/context")
    @Operation(summary = "My aggregated AI trip context (read-only, no persistence)")
    public AITripContextResponse context(@AuthUser Long uid) {
        return service.buildContext(uid);
    }
}
