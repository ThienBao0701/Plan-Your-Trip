package com.example.planyourtrip.controller;

import com.example.planyourtrip.dto.ReviewDto.PartnerReplyRequest;
import com.example.planyourtrip.dto.ReviewDto.ReviewResponse;
import com.example.planyourtrip.security.AuthUser;
import com.example.planyourtrip.service.ReviewService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@Tag(name = "Partner - Reviews", description = "Approved partners reply to reviews for hotels they own")
@SecurityRequirement(name = "bearerAuth")
public class PartnerReviewController {

    private final ReviewService service;

    public PartnerReviewController(ReviewService service) { this.service = service; }

    @PutMapping("/api/partner/reviews/{reviewId}/reply")
    @Operation(summary = "Create or update the single partner reply to a review for one of my hotels",
        description = "PUT because a review has exactly one current partner reply: the first call creates it "
            + "and subsequent calls replace/update it in place (never a second reply). Requires an APPROVED "
            + "partner profile that owns the review's place; an unknown review, or a review whose place the "
            + "caller does not own, both return a uniform 404. Reply is allowed only on a published (APPROVED) "
            + "review — any other status returns 422. The customer is notified only on the first reply.")
    public ReviewResponse reply(@AuthUser Long uid, @PathVariable Long reviewId,
                                @RequestBody @Valid PartnerReplyRequest req) {
        return service.partnerReply(uid, reviewId, req);
    }
}
