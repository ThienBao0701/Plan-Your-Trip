package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteRequest;
import com.example.planyourtrip.dto.CustomerPricingQuoteDto.CustomerPricingQuoteResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.CustomerPricingQuoteService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/**
 * Phase 7.33 — AUTHENTICATED customer pricing quote. Completes the customer-specific
 * preview that the Phase 7.32 public quote deliberately deferred: it takes the same
 * priority-based rate plan + promotion base and LAYERS the calling customer's own
 * coupon / loyalty / travel-credit / gift-card benefit previews on top, producing a
 * full {@code estimatedPayable}.
 *
 * <p>Strictly read-only — never creates a booking, holds inventory, or consumes /
 * reserves any benefit. Authenticated customers only (the caller's identity comes
 * from the JWT via {@link AuthUser}); a customer can only ever preview using their
 * OWN coupons, loyalty account and travel credits.
 */
@RestController
@RequestMapping("/api/me")
@Tag(name = "Customer - Pricing", description = "Authenticated pricing quote including your own customer benefits")
@SecurityRequirement(name = "bearerAuth")
public class CustomerPricingController {

    private final CustomerPricingQuoteService service;

    public CustomerPricingController(CustomerPricingQuoteService service) {
        this.service = service;
    }

    @PostMapping("/rooms/{roomId}/pricing/quote")
    @Operation(summary = "Authenticated read-only pricing quote including your coupon/loyalty/travel-credit/gift-card previews",
        description = "Reuses the public rate-plan + promotion quote and layers the calling customer's own benefit "
            + "previews (coupon → loyalty → travel credit → gift card) to estimate the payable. Never mutates state: "
            + "no booking, inventory hold, coupon claim, loyalty reservation, credit or gift-card redemption, ledger "
            + "row or notification. An ineligible benefit is reported in eligibilityFailures and simply not applied; "
            + "a coupon id that is not yours returns 404.")
    public CustomerPricingQuoteResponse quote(@AuthUser Long uid,
                                              @PathVariable Long roomId,
                                              @Valid @RequestBody CustomerPricingQuoteRequest request) {
        return service.quote(uid, roomId, request);
    }
}
