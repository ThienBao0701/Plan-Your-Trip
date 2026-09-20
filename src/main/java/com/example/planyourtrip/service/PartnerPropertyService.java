package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerHotelDto.*;
import com.example.planyourtrip.dto.PlaceDto.AmenityRef;
import com.example.planyourtrip.dto.PlaceDto.CategoryRef;
import com.example.planyourtrip.dto.PlaceDto.LocationRef;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.AdministrativeUnitRepository;
import com.example.planyourtrip.repository.AmenityRepository;
import com.example.planyourtrip.repository.CategoryRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.PartnerProfileRepository;
import com.example.planyourtrip.repository.PlaceAmenityRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.UserRepository;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.EnumSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/**
 * The partner's own properties: the canonical {@link Place} + {@link HotelDetail} pair, created and
 * edited by the approved partner that owns it.
 *
 * <h2>Phase C — what this service guarantees</h2>
 *
 * <ul>
 *   <li><b>The caller is the tenant.</b> Every method starts at
 *       {@link #myApprovedProfileOrThrow}, which resolves the {@code PartnerProfile} from the
 *       authenticated user id and refuses anything but {@code APPROVED}. No request body carries an
 *       owner, a partner id or an author, so none can be spoofed.</li>
 *   <li><b>One property is reachable only through its owner.</b> {@link #ownedPlaceOrThrow} goes
 *       through {@code findByIdAndOwnerId}, so another partner's property answers exactly like an id
 *       that does not exist — 404, leaking neither its data nor its existence.</li>
 *   <li><b>A created property is a draft.</b> {@code status = DRAFT} is set here and there is no
 *       field, anywhere in this contract, that moves it. Publication stays an administrative
 *       decision (see {@code PlaceService.updateStatus}), and Phase A's
 *       {@link PublicListingVisibility} keeps everything but {@code PUBLISHED} out of the public
 *       APIs.</li>
 *   <li><b>Reference data is the catalogue's, not the caller's.</b> Category, administrative unit
 *       and amenities are resolved by id against the admin-managed tables and refused when they are
 *       inactive or of a kind a property may not use. Nothing is created from a partner request,
 *       and an unknown id is never silently ignored.</li>
 * </ul>
 *
 * <p>Phase C implements create, read and update. <b>There is no delete</b>: sixteen tables carry a
 * foreign key to {@code places}, {@code ARCHIVED} is an administrative moderation state, and
 * {@code active=false} deliberately does not mean "not public" — so no safe partner-owned deletion
 * semantics exist in the current domain to reuse. See {@code PARTNER_PROPERTY.md}.
 */
@Service
public class PartnerPropertyService {

    /**
     * The {@code Category.type} a property must be classified under. The seeded catalogue puts
     * "Accommodation" and its eight children (Hotel, Resort, Homestay, Villa, Hostel, Apartment,
     * Camping, Glamping) under exactly this type, and it is the same string the coupon and
     * personalization engines already target places by.
     */
    static final String ACCOMMODATION_TYPE = "ACCOMMODATION";

    /**
     * Where a property may sit in the D13 hierarchy: a province, a city, or an area inside one.
     *
     * <p>{@code COUNTRY} is deliberately absent — "this hotel is in Vietnam" is not a location a
     * guest can search, and the D13 matrix makes a country a root container rather than a place.
     * {@code WARD} and {@code COMMUNE} are not assignable at all
     * ({@link LocationService#isAssignable}).
     */
    static final Set<UnitType> PROPERTY_LOCATION_TYPES =
        EnumSet.of(UnitType.PROVINCE, UnitType.CITY, UnitType.AREA);

    /**
     * The amenity groups that describe a property rather than one of its rooms or another kind of
     * place. {@code ROOM} belongs to {@code HotelRoom}, and {@code RESTAURANT}, {@code CAFE} and
     * {@code ATTRACTION} to the place types a partner cannot own here.
     */
    static final Set<String> PROPERTY_AMENITY_GROUPS = Set.of("GENERAL", "HOTEL");

    private final PlaceRepository places;
    private final PartnerProfileRepository partnerProfiles;
    private final HotelDetailRepository hotelDetails;
    private final NotificationService notificationService;
    private final PartnerActivityLogService activityLogService;
    private final AdminActivityLogService adminAudit;
    private final CategoryRepository categories;
    private final AdministrativeUnitRepository locations;
    private final AmenityRepository amenities;
    private final PlaceAmenityRepository placeAmenities;
    private final UserRepository users;
    private final PlaceSlugService slugs;

    public PartnerPropertyService(PlaceRepository places,
                                   PartnerProfileRepository partnerProfiles,
                                   HotelDetailRepository hotelDetails,
                                   NotificationService notificationService,
                                   PartnerActivityLogService activityLogService,
                                   AdminActivityLogService adminAudit,
                                   CategoryRepository categories,
                                   AdministrativeUnitRepository locations,
                                   AmenityRepository amenities,
                                   PlaceAmenityRepository placeAmenities,
                                   UserRepository users,
                                   PlaceSlugService slugs) {
        this.places = places;
        this.partnerProfiles = partnerProfiles;
        this.hotelDetails = hotelDetails;
        this.notificationService = notificationService;
        this.activityLogService = activityLogService;
        this.adminAudit = adminAudit;
        this.categories = categories;
        this.locations = locations;
        this.amenities = amenities;
        this.placeAmenities = placeAmenities;
        this.users = users;
        this.slugs = slugs;
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

    /**
     * Phase C — creates one draft property: the {@link Place}, its {@link HotelDetail} and its
     * amenity links, in a single transaction. A failure anywhere leaves no half-built property.
     *
     * <p>The owner is the caller's approved profile and the author is the caller; the slug is
     * derived from the name and made unique; the status is {@code DRAFT}. The {@code active} flag
     * keeps the entity's own default ({@code true}) — it is a listing switch inside the workspace,
     * not publication, which depends on the status alone.
     */
    @Transactional
    public PartnerHotelResponse createProperty(Long userId, PartnerHotelCreateRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        User author = users.findById(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + userId));

        Category category = accommodationCategoryOrThrow(req.categoryId());
        Category subcategory = subcategoryOrThrow(category, req.subcategoryId());
        AdministrativeUnit unit = propertyLocationOrThrow(req.administrativeUnitId());
        List<Amenity> selected = propertyAmenitiesOrThrow(req.amenityIds());

        Place place = new Place();
        place.setName(req.name().trim());
        place.setNameNormalized(SlugUtils.normalize(req.name()));
        place.setSlug(slugs.uniqueSlugForName(req.name(), null));
        place.setCategory(category);
        place.setSubcategory(subcategory);
        place.setAdministrativeUnit(unit);
        place.setAddress(req.address().trim());
        place.setLatitude(req.latitude());
        place.setLongitude(req.longitude());
        place.setShortDescription(req.shortDescription());
        place.setDescription(req.description());
        place.setPhone(req.phone());
        place.setEmail(req.email());
        place.setWebsite(req.website());
        // Owner is the partner profile, exactly as an administrative assignment sets it
        // (assignOwner). Place.ownerUser is the admin catalogue's separate "contact user" field and
        // is deliberately left alone: partner ownership is one concept with one column.
        place.setOwner(profile);
        place.setCreatedBy(author);
        place.setStatus(PlaceStatus.DRAFT);

        Place saved = places.save(place);

        HotelDetail detail = new HotelDetail();
        detail.setPlace(saved);
        detail.setStarRating(req.starRating());
        detail.setCheckInTime(req.checkIn());
        detail.setCheckOutTime(req.checkOut());
        detail.setChildrenPolicy(req.childrenPolicy());
        detail.setPetPolicy(req.petPolicy());
        detail.setSmokingPolicy(req.smokingPolicy());
        detail.setCancellationPolicy(req.cancellationPolicy());
        if (req.freeCancellation() != null) detail.setFreeCancellation(req.freeCancellation());
        if (req.parkingAvailable() != null) detail.setParkingAvailable(req.parkingAvailable());
        if (req.parkingFree() != null) detail.setParkingFree(req.parkingFree());
        detail.setParkingDescription(req.parkingDescription());
        if (req.wifiAvailable() != null) detail.setWifiAvailable(req.wifiAvailable());
        if (req.wifiFree() != null) detail.setWifiFree(req.wifiFree());
        detail.setInternetDescription(req.internetDescription());
        detail.setLanguages(cleanList(req.languages()));
        detail.setPaymentMethods(cleanList(req.paymentMethods()));
        hotelDetails.save(detail);

        linkAmenities(saved, selected);

        activityLogService.log(profile.getId(), userId, "PROPERTY_CREATED", "HOTEL", saved.getId(),
            "Created draft property " + saved.getName());
        return toResponse(saved);
    }

    @Transactional
    public PartnerHotelResponse updateBasicInformation(Long userId, Long hotelId, PartnerHotelUpdateRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());

        if (!place.getSlug().equals(req.slug()) && places.existsBySlug(req.slug()))
            throw new ApiException(HttpStatus.CONFLICT, "SLUG_CONFLICT", "slug",
                "Slug already in use: " + req.slug());

        place.setName(req.name());
        place.setNameNormalized(SlugUtils.normalize(req.name()));
        place.setSlug(req.slug());
        place.setShortDescription(req.shortDescription());
        place.setDescription(req.description());

        // Phase C — the classification is replaced only when the caller sends one, so a client that
        // knows nothing about categories cannot clear the property's own.
        if (req.categoryId() != null) {
            Category category = accommodationCategoryOrThrow(req.categoryId());
            place.setCategory(category);
            place.setSubcategory(subcategoryOrThrow(category, req.subcategoryId()));
        }

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
            // hotel_details.star_rating is NOT NULL with a 1..5 check, so a row cannot be created
            // without one. A property created through this service always declares its own; this
            // fallback exists only for a place that predates it (an administrative import, say) and
            // is the same value that path has always used. It is a placeholder, not a rating.
            d.setStarRating(req.starRating() != null ? req.starRating() : 1);
            return d;
        });
        detail.setCheckInTime(req.checkIn());
        detail.setCheckOutTime(req.checkOut());
        detail.setChildrenPolicy(req.childrenPolicy());
        detail.setPetPolicy(req.petPolicy());
        detail.setSmokingPolicy(req.smokingPolicy());
        // Phase C additions — null means "leave what is stored alone".
        if (req.starRating() != null) detail.setStarRating(req.starRating());
        if (req.cancellationPolicy() != null) detail.setCancellationPolicy(req.cancellationPolicy());
        if (req.freeCancellation() != null) detail.setFreeCancellation(req.freeCancellation());
        if (req.parkingAvailable() != null) detail.setParkingAvailable(req.parkingAvailable());
        if (req.parkingFree() != null) detail.setParkingFree(req.parkingFree());
        if (req.parkingDescription() != null) detail.setParkingDescription(req.parkingDescription());
        if (req.wifiAvailable() != null) detail.setWifiAvailable(req.wifiAvailable());
        if (req.wifiFree() != null) detail.setWifiFree(req.wifiFree());
        if (req.internetDescription() != null) detail.setInternetDescription(req.internetDescription());
        if (req.languages() != null) detail.setLanguages(cleanList(req.languages()));
        if (req.paymentMethods() != null) detail.setPaymentMethods(cleanList(req.paymentMethods()));
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
        // Phase C — as with the classification, the administrative unit moves only when the caller
        // sends one; a property can never end up without one.
        if (req.administrativeUnitId() != null) {
            place.setAdministrativeUnit(propertyLocationOrThrow(req.administrativeUnitId()));
        }

        Place saved = places.save(place);
        notifyPropertyUpdated(saved);
        return toResponse(saved);
    }

    /**
     * Phase C — replaces the property's amenity set with exactly what was sent.
     *
     * <p>Every id is resolved against the admin-managed catalogue first, so an unknown, inactive or
     * room-level amenity refuses the whole request instead of being dropped from it. Repeats in the
     * request collapse to one link, which is what the {@code uk_place_amenity} constraint says too.
     */
    @Transactional
    public PartnerHotelResponse updateAmenities(Long userId, Long hotelId, PartnerAmenitiesRequest req) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        Place place = ownedPlaceOrThrow(hotelId, profile.getId());
        List<Amenity> selected = propertyAmenitiesOrThrow(req.amenityIds());

        placeAmenities.deleteAllByPlaceId(place.getId());
        linkAmenities(place, selected);

        activityLogService.log(profile.getId(), userId, "PROPERTY_UPDATED", "HOTEL", place.getId(),
            "Updated amenities for " + place.getName());
        return toResponse(place);
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
    public PartnerHotelResponse assignOwner(Long adminUserId, Long hotelId, AssignOwnerRequest req) {
        Place place = places.findById(hotelId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId));
        PartnerProfile profile = partnerProfiles.findById(req.partnerProfileId())
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Partner profile not found: " + req.partnerProfileId()));

        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Only an approved partner profile can own a hotel");

        PartnerProfile previousOwner = place.getOwner();
        place.setOwner(profile);
        Place saved = places.save(place);

        // D1c - this is an authorization change, not a catalogue edit: it hands a partner account
        // the extranet, rates, inventory and booking data for a property. Recorded with both the
        // outgoing and incoming profile ids so a mis-assignment can be traced and undone.
        adminAudit.record(adminUserId, "HOTEL_ASSIGN_OWNER", "PLACE", saved.getId(),
            "Admin assigned hotel " + saved.getId() + " to partner profile " + profile.getId(),
            previousOwner == null ? null : "partnerProfile:" + previousOwner.getId(),
            "partnerProfile:" + profile.getId());

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

    // ── Reference data ────────────────────────────────────────────────────────
    //
    // All four refusals below are 422 with a stable code and the request field that caused them, so
    // a form can mark the offending control. 404 is deliberately not used here: on these endpoints
    // it already means "that property is not yours or does not exist", and a rejected catalogue id
    // is a different thing that must not be confused with it.

    private Category accommodationCategoryOrThrow(Long id) {
        Category category = categories.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CATEGORY_INVALID",
                "categoryId", "Category not found: " + id));
        if (!category.isActive())
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CATEGORY_INVALID", "categoryId",
                "Category is not available: " + id);
        if (!ACCOMMODATION_TYPE.equals(category.getType()))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "CATEGORY_INVALID", "categoryId",
                "A property must use an accommodation category: " + id);
        return category;
    }

    /** The subcategory for [category], or null when none was asked for. */
    private Category subcategoryOrThrow(Category category, Long subcategoryId) {
        if (subcategoryId == null) return null;
        Category subcategory = categories.findById(subcategoryId)
            .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SUBCATEGORY_INVALID",
                "subcategoryId", "Category not found: " + subcategoryId));
        if (!subcategory.isActive())
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SUBCATEGORY_INVALID",
                "subcategoryId", "Category is not available: " + subcategoryId);
        // The same rule the admin catalogue applies (PlaceService.fillPlace).
        if (subcategory.getParent() == null
                || !subcategory.getParent().getId().equals(category.getId()))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SUBCATEGORY_INVALID",
                "subcategoryId", "Subcategory must be a direct child of the specified category");
        return subcategory;
    }

    private AdministrativeUnit propertyLocationOrThrow(Long id) {
        AdministrativeUnit unit = locations.findById(id)
            .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LOCATION_INVALID",
                "administrativeUnitId", "Administrative unit not found: " + id));
        if (!unit.isActive())
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LOCATION_INVALID",
                "administrativeUnitId", "Administrative unit is not available: " + id);
        if (!PROPERTY_LOCATION_TYPES.contains(unit.getType()))
            throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "LOCATION_INVALID",
                "administrativeUnitId",
                "A property must sit in a province, city or area, not a " + unit.getType());
        return unit;
    }

    /** The amenities for [ids], in request order, without repeats; empty for null or an empty list. */
    private List<Amenity> propertyAmenitiesOrThrow(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return List.of();
        List<Amenity> resolved = new ArrayList<>();
        for (Long id : new LinkedHashSet<>(ids)) {
            if (id == null)
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "AMENITY_INVALID",
                    "amenityIds", "Amenity id must not be null");
            Amenity amenity = amenities.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "AMENITY_INVALID",
                    "amenityIds", "Amenity not found: " + id));
            if (!amenity.isActive())
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "AMENITY_INVALID",
                    "amenityIds", "Amenity is not available: " + id);
            if (!PROPERTY_AMENITY_GROUPS.contains(amenity.getGroupName()))
                throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "AMENITY_INVALID",
                    "amenityIds", "Amenity " + id + " does not describe a property");
            resolved.add(amenity);
        }
        return resolved;
    }

    private void linkAmenities(Place place, List<Amenity> selected) {
        for (Amenity amenity : selected) {
            PlaceAmenity link = new PlaceAmenity();
            link.setPlace(place);
            link.setAmenity(amenity);
            placeAmenities.save(link);
        }
    }

    /** Trims, drops blanks and collapses repeats, preserving the order given. */
    private List<String> cleanList(List<String> values) {
        if (values == null) return new ArrayList<>();
        Set<String> seen = new LinkedHashSet<>();
        for (String value : values) {
            if (value == null) continue;
            String trimmed = value.trim();
            if (!trimmed.isEmpty()) seen.add(trimmed);
        }
        return new ArrayList<>(seen);
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
            toCategoryRef(p.getCategory()), toCategoryRef(p.getSubcategory()),
            toLocationRef(p.getAdministrativeUnit()),
            p.getCreatedAt(), p.getUpdatedAt()
        );
    }

    private PartnerHotelResponse toResponse(Place p) {
        HotelDetail d = hotelDetails.findByPlaceId(p.getId()).orElse(null);
        PartnerProfile owner = p.getOwner();
        List<AmenityRef> amenityRefs = placeAmenities.findAllByPlaceId(p.getId()).stream()
            .map(link -> toAmenityRef(link.getAmenity()))
            .toList();
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
            toCategoryRef(p.getCategory()), toCategoryRef(p.getSubcategory()),
            toLocationRef(p.getAdministrativeUnit()),
            d != null ? d.getStarRating() : null,
            d != null ? d.getCancellationPolicy() : null,
            d != null ? d.isFreeCancellation() : null,
            d != null ? d.getPaymentPolicy() : null,
            d != null ? d.isPrepaymentRequired() : null,
            d != null ? d.isParkingAvailable() : null,
            d != null ? d.isParkingFree() : null,
            d != null ? d.getParkingDescription() : null,
            d != null ? d.isWifiAvailable() : null,
            d != null ? d.isWifiFree() : null,
            d != null ? d.getInternetDescription() : null,
            d != null ? List.copyOf(d.getLanguages()) : null,
            d != null ? List.copyOf(d.getPaymentMethods()) : null,
            amenityRefs,
            p.getCreatedAt(), p.getUpdatedAt()
        );
    }

    private CategoryRef toCategoryRef(Category c) {
        return c == null ? null
            : new CategoryRef(c.getId(), c.getName(), c.getSlug(), c.getType(), c.getIcon(), c.getColor());
    }

    private LocationRef toLocationRef(AdministrativeUnit u) {
        return u == null ? null : new LocationRef(u.getId(), u.getName(), u.getSlug(), u.getFullPath());
    }

    private AmenityRef toAmenityRef(Amenity a) {
        return new AmenityRef(a.getId(), a.getName(), a.getSlug(), a.getIcon(), a.getGroupName());
    }
}
