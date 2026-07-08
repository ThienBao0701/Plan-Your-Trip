package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.RecentlyViewedDto.RecentlyViewedItemResponse;
import com.example.planyourtrip.dto.RecentlyViewedDto.RecentlyViewedResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.RecentlyViewedService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/me/recently-viewed")
@Tag(name = "Customer - Recently Viewed", description = "Places recently viewed by the current customer")
@SecurityRequirement(name = "bearerAuth")
public class RecentlyViewedController {

    private final RecentlyViewedService service;

    public RecentlyViewedController(RecentlyViewedService service) { this.service = service; }

    @GetMapping
    @Operation(summary = "List my recently viewed places, newest first")
    public RecentlyViewedResponse get(@AuthUser Long uid) {
        return service.getMine(uid);
    }

    @PostMapping("/{placeId}")
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "Record (or refresh) a view of a published place")
    public RecentlyViewedItemResponse record(@AuthUser Long uid, @PathVariable Long placeId) {
        return service.recordView(uid, placeId);
    }

    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Clear my entire recently viewed list")
    public void clearAll(@AuthUser Long uid) {
        service.clearMine(uid);
    }

    @DeleteMapping("/{placeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "Remove one place from my recently viewed list")
    public void removeOne(@AuthUser Long uid, @PathVariable Long placeId) {
        service.removeOne(uid, placeId);
    }
}
