package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileRequest;
import com.example.planyourtrip.dto.CustomerProfileDto.CustomerProfileResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.CustomerProfile;
import com.example.planyourtrip.model.User;
import com.example.planyourtrip.repository.CustomerProfileRepository;
import com.example.planyourtrip.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Customer-side travel profile — distinct from {@link User} (authentication identity)
 * and intended as a shared foundation for booking, recommendations, loyalty,
 * promotions and future AI personalization.
 *
 * <p>Passport information is never stored in full: {@link CustomerProfileRequest#passportNumber()}
 * is masked once on write and only the masked value is ever persisted or returned,
 * mirroring the "store only last4" convention already established for partner payout
 * accounts (Phase 6.9).
 */
@Service
public class CustomerProfileService {

    private static final int COMPLETION_FIELD_COUNT = 11;

    private final CustomerProfileRepository profileRepo;
    private final UserRepository userRepo;

    public CustomerProfileService(CustomerProfileRepository profileRepo, UserRepository userRepo) {
        this.profileRepo = profileRepo;
        this.userRepo = userRepo;
    }

    @Transactional
    public CustomerProfileResponse getMyProfile(Long userId) {
        return toResponse(getOrCreateProfile(userId));
    }

    @Transactional
    public CustomerProfileResponse updateMyProfile(Long userId, CustomerProfileRequest req) {
        CustomerProfile profile = getOrCreateProfile(userId);

        profile.setAvatarUrl(req.avatarUrl());
        if (req.preferredLanguage() != null && !req.preferredLanguage().isBlank())
            profile.setPreferredLanguage(req.preferredLanguage());
        if (req.preferredCurrency() != null && !req.preferredCurrency().isBlank())
            profile.setPreferredCurrency(req.preferredCurrency());
        profile.setPreferredPaymentMethod(req.preferredPaymentMethod());
        profile.setNationality(req.nationality());
        profile.setPassportNumberMasked(maskPassport(req.passportNumber()));
        profile.setEmergencyContactName(req.emergencyContactName());
        profile.setEmergencyContactPhone(req.emergencyContactPhone());
        profile.setAccessibilityNeeds(req.accessibilityNeeds());
        profile.setDietaryPreference(req.dietaryPreference());
        profile.setTravelStyle(req.travelStyle());
        profile.setMarketingConsent(req.marketingConsent());

        profile.setProfileCompleted(computeCompletionPercentage(profile) == 100);

        return toResponse(profileRepo.save(profile));
    }

    /** Admin visibility only — strictly read-only, never creates or mutates a row. */
    @Transactional(readOnly = true)
    public CustomerProfileResponse adminGetProfile(Long targetUserId) {
        User user = userRepo.findById(targetUserId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + targetUserId));
        return profileRepo.findByUserId(user.getId())
            .map(this::toResponse)
            .orElseGet(() -> emptyResponse(user.getId()));
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private CustomerProfile getOrCreateProfile(Long userId) {
        return profileRepo.findByUserId(userId).orElseGet(() -> {
            User user = userRepo.findById(userId)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found"));
            CustomerProfile profile = new CustomerProfile();
            profile.setUser(user);
            return profileRepo.save(profile);
        });
    }

    private String maskPassport(String passportNumber) {
        if (passportNumber == null || passportNumber.isBlank()) return null;
        String trimmed = passportNumber.trim();
        if (trimmed.length() <= 4) return "*".repeat(trimmed.length());
        String last4 = trimmed.substring(trimmed.length() - 4);
        return "*".repeat(trimmed.length() - 4) + last4;
    }

    private int computeCompletionPercentage(CustomerProfile p) {
        int filled = 0;
        if (notBlank(p.getAvatarUrl())) filled++;
        if (notBlank(p.getPreferredLanguage())) filled++;
        if (notBlank(p.getPreferredCurrency())) filled++;
        if (notBlank(p.getPreferredPaymentMethod())) filled++;
        if (notBlank(p.getNationality())) filled++;
        if (notBlank(p.getPassportNumberMasked())) filled++;
        if (notBlank(p.getEmergencyContactName())) filled++;
        if (notBlank(p.getEmergencyContactPhone())) filled++;
        if (notBlank(p.getAccessibilityNeeds())) filled++;
        if (notBlank(p.getDietaryPreference())) filled++;
        if (notBlank(p.getTravelStyle())) filled++;
        return (int) Math.round(filled * 100.0 / COMPLETION_FIELD_COUNT);
    }

    private boolean notBlank(String s) {
        return s != null && !s.isBlank();
    }

    private CustomerProfileResponse toResponse(CustomerProfile p) {
        return new CustomerProfileResponse(
            p.getId(), p.getUser().getId(), p.getAvatarUrl(),
            p.getPreferredLanguage(), p.getPreferredCurrency(), p.getPreferredPaymentMethod(),
            p.getNationality(), p.getPassportNumberMasked(),
            p.getEmergencyContactName(), p.getEmergencyContactPhone(),
            p.getAccessibilityNeeds(), p.getDietaryPreference(), p.getTravelStyle(),
            p.isMarketingConsent(), p.isProfileCompleted(), computeCompletionPercentage(p),
            p.getCreatedAt(), p.getUpdatedAt()
        );
    }

    private CustomerProfileResponse emptyResponse(Long userId) {
        return new CustomerProfileResponse(
            null, userId, null, "en", "VND", null, null, null,
            null, null, null, null, null, false, false, 0, null, null
        );
    }
}
