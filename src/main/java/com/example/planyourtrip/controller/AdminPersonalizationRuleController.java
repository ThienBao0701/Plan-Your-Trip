package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PersonalizationDto.*;
import com.example.planyourtrip.service.PersonalizationRuleService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Phase 7.23 — Personalized Offers &amp; Rule-Based Recommendations.
 * Admin CRUD + activate/deactivate for {@link com.example.planyourtrip.model.PersonalizationRule}.
 * Access is restricted to ROLE_ADMIN by SecurityConfig's blanket
 * {@code /api/admin/**} rule — no per-controller annotation needed, matching
 * every other admin controller.
 */
@RestController
@RequestMapping("/api/admin/personalization-rules")
@Tag(name = "Admin - Personalization Rules", description = "Personalization rule CRUD and activation")
@SecurityRequirement(name = "bearerAuth")
public class AdminPersonalizationRuleController {

    private final PersonalizationRuleService service;

    public AdminPersonalizationRuleController(PersonalizationRuleService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List all personalization rules (highest priority first)")
    public List<PersonalizationRuleResponse> list() {
        return service.getAll();
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a personalization rule by id")
    public PersonalizationRuleResponse get(@PathVariable Long id) {
        return service.getById(id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a personalization rule (duplicate ruleCode rejected with 409)")
    public PersonalizationRuleResponse create(@Valid @RequestBody PersonalizationRuleRequest req) {
        return service.create(req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a personalization rule")
    public PersonalizationRuleResponse update(@PathVariable Long id,
                                              @Valid @RequestBody PersonalizationRuleRequest req) {
        return service.update(id, req);
    }

    @PatchMapping("/{id}/activate")
    @Operation(summary = "Activate a personalization rule")
    public PersonalizationRuleResponse activate(@PathVariable Long id) {
        return service.activate(id);
    }

    @PatchMapping("/{id}/deactivate")
    @Operation(summary = "Deactivate a personalization rule")
    public PersonalizationRuleResponse deactivate(@PathVariable Long id) {
        return service.deactivate(id);
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a personalization rule")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
