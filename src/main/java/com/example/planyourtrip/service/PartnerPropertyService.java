package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerHotelDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PartnerPropertyService {

    private final PlaceRepository places;
    private final PartnerProfileRepository partnerProfiles;
    private final HotelDetailRepository hotelDetails;
    private final NotificationService notificationService;
    private final PartnerActivityLogService activityLogService;

    public PartnerPropertyService(PlaceRepository places,
                                   PartnerProfileRepository partnerProfiles,
                                   HotelDetailRepository hotelDetails,
                                   NotificationService notificationService,
                                   PartnerActivityLogService activityLogService) {
        this.places = places;
        this.partnerProfiles = partnerProfiles;
        this.hotelDetails = hotelDetails;
        this.notificationService = notificationService;
        this.activityLogService = activityLogService;
    }

    @Transactional(readOnly = true)
    public List<PartnerHotelSummaryResponse> getMyHotels(Long userId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        return places.findAllByOwnerId(profile.getId()).stream().map(this::toSummary).toList();
    }

    @Transactional(readOnly = true)
    public PartnerHotelResponse getHotel(Long userId, Long hotelId) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        return toResponse(ownedPlaceOrThrow(hotelId, profile.getId()));
    }

    @Transactional
    public PartnerHotelResponse updateBasicInformation(Long userId, Long hotelId, PartnerHotelUpdateRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());

        if (!place.getSlug().equals(req.slug()) && places.existsBySlug(req.slug()))
            throw new ApiException(HttpStatus.CONFLICT, "Slug already in use: " + req.slug());

        place.setName(req.name());
        place.setNameNormalized(SlugUtils.normalize(req.name()));
        place.setSlug(req.slug());
        place.setShortDescription(req.shortDescription());
        place.setDescription(req.description());

        Place saved = places.save(place);
        notifyPropertyUpdated(saved);
        activityLogService.log(profile.getId(), userId, "PROPERTY_UPDATED", "HOTEL", saved.getId(),
            "Updated basic information for " + saved.getName());
        return toResponse(saved);
    }

    @Transactional
    public PartnerHotelResponse updateContact(Long userId, Long hotelId, PartnerContactRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());

        place.setPhone(req.phone());
        place.setEmail(req.email());
        place.setWebsite(req.website());
        place.setFacebook(req.facebook());
        place.setInstagram(req.instagram());

        Place saved = places.save(place);
        notifyPropertyUpdated(saved);
        return toResponse(saved);
    }

    @Transactional
    public PartnerHotelResponse updatePolicies(Long userId, Long hotelId, PartnerPolicyRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());

        HotelDetail detail = hotelDetails.findByPlaceId(place.getId()).orElseGet(() -> {
            HotelDetail d = new HotelDetail();
            d.setPlace(place);
            d.setStarRating(1);
            return d;
        });
        detail.setCheckInTime(req.checkIn());
        detail.setCheckOutTime(req.checkOut());
        detail.setChildrenPolicy(req.childrenPolicy());
        detail.setPetPolicy(req.petPolicy());
        detail.setSmokingPolicy(req.smokingPolicy());
        hotelDetails.save(detail);

        notifyPropertyUpdated(place);
        return toResponse(place);
    }

    @Transactional
    public PartnerHotelResponse updateCoordinates(Long userId, Long hotelId, PartnerLocationRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());

        place.setLatitude(req.latitude());
        place.setLongitude(req.longitude());
        place.setAddress(req.address());

        Place saved = places.save(place);
        notifyPropertyUpdated(saved);
        return toResponse(saved);
    }

    @Transactional
    public PartnerHotelResponse activate(Long userId, Long hotelId) {
        return setActive(userId, hotelId, true);
    }

    @Transactional
    public PartnerHotelResponse deactivate(Long userId, Long hotelId) {
        return setActive(userId, hotelId, false);
    }

    @Transactional
    public PartnerHotelResponse assignOwner(Long hotelId, AssignOwnerRequest req) {
        Place place = places.findById(hotelId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId));
        PartnerProfile profile = partnerProfiles.findById(req.partnerProfileId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Partner profile not found: " + req.partnerProfileId()));

        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only an approved partner profile can own a hotel");

        place.setOwner(profile);
        Place saved = places.save(place);

        notificationService.create(profile.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Hotel assigned to your account",
            saved.getName() + " has been assigned to your account.",
            RelatedEntityType.HOTEL, saved.getId());

        return toResponse(saved);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private PartnerHotelResponse setActive(Long userId, Long hotelId, boolean active) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());
        place.setActive(active);
        Place saved = places.save(place);
        notifyPropertyUpdated(saved);
        return toResponse(saved);
    }

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private Place ownedPlaceOrThrow(Long hotelId, Long ownerId) {
        return places.findByIdAndOwnerId(hotelId, ownerId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId));
    }

    private void notifyPropertyUpdated(Place place) {
        PartnerProfile owner = place.getOwner();
        if (owner == null) return;
        notificationService.create(owner.getUser().getId(), NotificationType.PARTNER, Priority.NORMAL,
            "Property updated",
            place.getName() + " has been updated.",
            RelatedEntityType.HOTEL, place.getId());
    }

    private PartnerHotelSummaryResponse toSummary(Place p) {
        return new PartnerHotelSummaryResponse(
            p.getId(), p.getName(), p.getSlug(), p.getShortDescription(), p.getAddress(),
            p.isActive(), p.isFeatured(), p.isVerified(),
            p.getRatingAvg(), p.getReviewCount(), p.getStatus().name(),
            p.getCreatedAt(), p.getUpdatedAt()
        );
    }

    private PartnerHotelResponse toResponse(Place p) {
        HotelDetail d = hotelDetails.findByPlaceId(p.getId()).orElse(null);
        PartnerProfile owner = p.getOwner();
        return new PartnerHotelResponse(
            p.getId(), p.getName(), p.getSlug(), p.getShortDescription(), p.getDescription(),
            p.getAddress(), p.getLatitude(), p.getLongitude(),
            p.getPhone(), p.getEmail(), p.getWebsite(), p.getFacebook(), p.getInstagram(),
            d != null ? d.getCheckInTime() : null,
            d != null ? d.getCheckOutTime() : null,
            d != null ? d.getChildrenPolicy() : null,
            d != null ? d.getPetPolicy() : null,
            d != null ? d.getSmokingPolicy() : null,
            p.isActive(), p.isFeatured(), p.isVerified(),
            p.getRatingAvg(), p.getReviewCount(), p.getStatus().name(),
            owner != null ? owner.getId() : null,
            owner != null ? owner.getBusinessName() : null,
            p.getCreatedAt(), p.getUpdatedAt()
        );
    }
}
