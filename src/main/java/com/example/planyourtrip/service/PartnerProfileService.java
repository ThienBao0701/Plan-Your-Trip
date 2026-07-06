package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerProfileDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;

@Service
public class PartnerProfileService {

    private final PartnerProfileRepository partnerProfileRepo;
    private final UserRepository userRepo;
    private final NotificationService notificationService;

    public PartnerProfileService(PartnerProfileRepository partnerProfileRepo,
                                  UserRepository userRepo,
                                  NotificationService notificationService) {
        this.partnerProfileRepo = partnerProfileRepo;
        this.userRepo = userRepo;
        this.notificationService = notificationService;
    }

    @Transactional
    public PartnerProfileResponse createOrUpdateMyProfile(Long userId, PartnerProfileRequest req) {
        PartnerProfile profile = partnerProfileRepo.findByUserId(userId).orElse(null);

        if (profile == null) {
            User user = userRepo.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
            profile = new PartnerProfile();
            profile.setUser(user);
            profile.setVerificationStatus(PartnerVerificationStatus.DRAFT);
        } else if (profile.getVerificationStatus() != PartnerVerificationStatus.DRAFT
                && profile.getVerificationStatus() != PartnerVerificationStatus.REJECTED) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Profile cannot be edited in status " + profile.getVerificationStatus());
        }

        profile.setBusinessName(req.businessName());
        profile.setBusinessType(req.businessType());
        profile.setRepresentativeName(req.representativeName());
        profile.setPhone(req.phone());
        profile.setEmail(req.email());
        profile.setAddress(req.address());
        profile.setTaxCode(req.taxCode());
        profile.setWebsite(req.website());

        return toResponse(partnerProfileRepo.save(profile));
    }

    @Transactional(readOnly = true)
    public PartnerProfileResponse getMyProfile(Long userId) {
        return toResponse(myProfileOrThrow(userId));
    }

    @Transactional
    public PartnerSubmitResponse submitMyProfile(Long userId) {
        PartnerProfile profile = myProfileOrThrow(userId);
        if (profile.getVerificationStatus() != PartnerVerificationStatus.DRAFT
                && profile.getVerificationStatus() != PartnerVerificationStatus.REJECTED) {
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only draft or rejected profiles can be submitted");
        }

        profile.setVerificationStatus(PartnerVerificationStatus.SUBMITTED);
        profile.setSubmittedAt(Instant.now());
        profile.setRejectReason(null);
        profile = partnerProfileRepo.save(profile);

        PartnerProfile submitted = profile;
        userRepo.findAll().stream()
            .filter(u -> "ADMIN".equals(u.getRole()))
            .forEach(admin -> notificationService.create(admin.getId(), NotificationType.PARTNER, Priority.NORMAL,
                "New partner application submitted",
                submitted.getBusinessName() + " has submitted a partner application for review.",
                RelatedEntityType.PARTNER, submitted.getId()));

        return new PartnerSubmitResponse(profile.getId(), profile.getVerificationStatus().name(),
            profile.getSubmittedAt(), "Partner profile submitted for review");
    }

    @Transactional(readOnly = true)
    public List<PartnerProfileResponse> adminListProfiles() {
        return partnerProfileRepo.findAllByOrderByCreatedAtDesc().stream().map(this::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public PartnerProfileResponse adminGetProfile(Long id) {
        return toResponse(profileOrThrow(id));
    }

    @Transactional
    public PartnerProfileResponse adminApprove(Long adminUserId, Long id) {
        PartnerProfile profile = profileOrThrow(id);
        if (profile.getVerificationStatus() != PartnerVerificationStatus.SUBMITTED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only submitted profiles can be approved");

        User admin = userRepo.findById(adminUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Admin user not found"));

        profile.setVerificationStatus(PartnerVerificationStatus.APPROVED);
        profile.setApprovedAt(Instant.now());
        profile.setApprovedBy(admin);
        profile.setRejectReason(null);
        profile = partnerProfileRepo.save(profile);

        User owner = profile.getUser();
        if (!"ADMIN".equals(owner.getRole())) {
            owner.setRole("PARTNER");
            userRepo.save(owner);
        }

        notificationService.create(owner.getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Your partner profile has been approved", "Your partner profile has been approved.",
            RelatedEntityType.PARTNER, profile.getId());

        return toResponse(profile);
    }

    @Transactional
    public PartnerProfileResponse adminReject(Long id, PartnerRejectRequest req) {
        PartnerProfile profile = profileOrThrow(id);
        if (profile.getVerificationStatus() != PartnerVerificationStatus.SUBMITTED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only submitted profiles can be rejected");

        profile.setVerificationStatus(PartnerVerificationStatus.REJECTED);
        profile.setRejectedAt(Instant.now());
        profile.setRejectReason(req.rejectReason());
        profile = partnerProfileRepo.save(profile);

        notificationService.create(profile.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Your partner profile was rejected",
            "Your partner profile was rejected" + (req.rejectReason() != null && !req.rejectReason().isBlank()
                ? ": " + req.rejectReason() : "."),
            RelatedEntityType.PARTNER, profile.getId());

        return toResponse(profile);
    }

    @Transactional
    public PartnerProfileResponse adminSuspend(Long id, PartnerStatusRequest req) {
        PartnerProfile profile = profileOrThrow(id);
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "Only approved profiles can be suspended");

        profile.setVerificationStatus(PartnerVerificationStatus.SUSPENDED);
        if (req != null && req.reason() != null && !req.reason().isBlank())
            profile.setRejectReason(req.reason());
        profile = partnerProfileRepo.save(profile);

        notificationService.create(profile.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Your partner account has been suspended", "Your partner account has been suspended.",
            RelatedEntityType.PARTNER, profile.getId());

        return toResponse(profile);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerProfile myProfileOrThrow(Long userId) {
        return partnerProfileRepo.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
    }

    private PartnerProfile profileOrThrow(Long id) {
        return partnerProfileRepo.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found: " + id));
    }

    private PartnerProfileResponse toResponse(PartnerProfile p) {
        User approvedBy = p.getApprovedBy();
        return new PartnerProfileResponse(
            p.getId(),
            p.getUser().getId(), p.getUser().getFullName(), p.getUser().getEmail(),
            p.getBusinessName(), p.getBusinessType().name(),
            p.getRepresentativeName(), p.getPhone(), p.getEmail(), p.getAddress(),
            p.getTaxCode(), p.getWebsite(),
            p.getVerificationStatus().name(), p.getRejectReason(),
            p.getSubmittedAt(), p.getApprovedAt(), p.getRejectedAt(),
            approvedBy != null ? approvedBy.getId() : null,
            approvedBy != null ? approvedBy.getFullName() : null,
            p.getCreatedAt(), p.getUpdatedAt()
        );
    }
}
