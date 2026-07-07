package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.PromotionDto.PromotionRequest;
import com.example.planyourtrip.dto.PromotionDto.PromotionResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.PartnerPromotionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/partner/promotions")
@Tag(name = "Partner - Promotions", description = "Approved partners manage promotions targeting hotels/rooms they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerPromotionController {

    private final PartnerPromotionService service;

    public PartnerPromotionController(PartnerPromotionService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my promotions")
    public List<PromotionResponse> getMyPromotions(@AuthUser Long uid) {
        return service.getMyPromotions(uid);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get one of my promotions")
    public PromotionResponse getPromotion(@AuthUser Long uid, @PathVariable Long id) {
        return service.getPromotion(uid, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Create a promotion targeting a hotel or room I own")
    public PromotionResponse createPromotion(@AuthUser Long uid, @Valid @RequestBody PromotionRequest req) {
        return service.createPromotion(uid, req);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a promotion I own")
    public PromotionResponse updatePromotion(@AuthUser Long uid, @PathVariable Long id,
                                              @Valid @RequestBody PromotionRequest req) {
        return service.updatePromotion(uid, id, req);
    }

    @DeleteMapping("/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Delete a promotion I own")
    public void deletePromotion(@AuthUser Long uid, @PathVariable Long id) {
        service.deletePromotion(uid, id);
    }
}
