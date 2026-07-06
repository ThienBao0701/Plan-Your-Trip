package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelDetailDto;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.dto.PlaceDetailResponse;
import com.example.planyourtrip.dto.PlaceDetailResponse.ImageRef;
import com.example.planyourtrip.dto.PlaceDto.*;
import com.example.planyourtrip.dto.PlaceMetadataDto.PlaceMetadataRequest;
import com.example.planyourtrip.dto.PlaceMetadataDto.PlaceMetadataResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import com.example.planyourtrip.util.OpeningHourUtils;
import com.example.planyourtrip.util.SlugUtils;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static com.example.planyourtrip.model.PlaceStatus.*;

@Service
@Transactional(readOnly = true)
public class PlaceService {

    private static final ZoneId VIETNAM = ZoneId.of("Asia/Ho_Chi_Minh");

    /** Allowed status transitions. Anything not in the set for a given status is forbidden. */
    private static final Map<PlaceStatus, Set<PlaceStatus>> ALLOWED_TRANSITIONS = Map.of(
        DRAFT,          Set.of(PENDING_REVIEW, APPROVED, PUBLISHED, HIDDEN, ARCHIVED),
        PENDING_REVIEW, Set.of(APPROVED, REJECTED, HIDDEN, ARCHIVED),
        APPROVED,       Set.of(PUBLISHED, HIDDEN, ARCHIVED),
        PUBLISHED,      Set.of(HIDDEN, ARCHIVED),
        HIDDEN,         Set.of(PUBLISHED, ARCHIVED),
        REJECTED,       Set.of(DRAFT, ARCHIVED),
        ARCHIVED,       Set.of()
    );

    private final PlaceRepository places;
    private final PlaceTagRepository tags;
    private final PlaceOpeningHourRepository hours;
    private final PlaceAmenityRepository placeAmenities;
    private final MediaAssetRepository mediaAssets;
    private final PlaceMetadataRepository metadataRepo;
    private final HotelDetailService hotelDetailService;
    private final CategoryRepository categories;
    private final AdministrativeUnitRepository locations;
    private final AmenityRepository amenities;
    private final UserRepository users;

    public PlaceService(PlaceRepository places, PlaceTagRepository tags,
                        PlaceOpeningHourRepository hours, PlaceAmenityRepository placeAmenities,
                        MediaAssetRepository mediaAssets,
                        PlaceMetadataRepository metadataRepo,
                        HotelDetailService hotelDetailService,
                        CategoryRepository categories, AdministrativeUnitRepository locations,
                        AmenityRepository amenities, UserRepository users) {
        this.places = places;
        this.tags = tags;
        this.hours = hours;
        this.placeAmenities = placeAmenities;
        this.mediaAssets = mediaAssets;
        this.metadataRepo = metadataRepo;
        this.hotelDetailService = hotelDetailService;
        this.categories = categories;
        this.locations = locations;
        this.amenities = amenities;
        this.users = users;
    }

    // ─── Public ───────────────────────────────────────────────────────────────

    public List<PlaceSummaryResponse> listPublished() {
        return places.findByStatus(PUBLISHED)
                .stream().map(this::toSummary).toList();
    }

    public PlaceDetailResponse getDetail(Long id) {
        Place p = places.findByIdAndStatus(id, PUBLISHED)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + id));
        return toDetail(p);
    }

    public PlaceDetailResponse getDetailBySlug(String slug) {
        Place p = places.findBySlugAndStatus(slug, PUBLISHED)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + slug));
        return toDetail(p);
    }

    public PageResponse<PlaceSummaryResponse> searchPublished(
            String q, Long categoryId, String categorySlug, Long subcategoryId,
            Long locationId, Double minRating, Integer maxPriceLevel,
            Boolean featured, Boolean verified,
            int page, int size, String sort) {

        Specification<Place> spec = Specification
            .where(PlaceSpecification.withStatus(PUBLISHED))
            .and(PlaceSpecification.withKeyword(q))
            .and(PlaceSpecification.withCategoryId(categoryId))
            .and(PlaceSpecification.withCategorySlug(categorySlug))
            .and(PlaceSpecification.withSubcategoryId(subcategoryId))
            .and(PlaceSpecification.withLocationId(locationId))
            .and(PlaceSpecification.withMinRating(minRating))
            .and(PlaceSpecification.withMaxPriceLevel(maxPriceLevel))
            .and(PlaceSpecification.withFeatured(featured))
            .and(PlaceSpecification.withVerified(verified));

        Pageable pageable = PageRequest.of(page, size, resolveSort(sort));
        return PageResponse.of(places.findAll(spec, pageable).map(this::toSummary));
    }

    // ─── Admin ────────────────────────────────────────────────────────────────

    public PlaceDetailResponse getAdminDetail(Long id) {
        Place p = places.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + id));
        return toDetail(p);
    }

    public List<PlaceSummaryResponse> listAll() {
        return places.findAllWithDetails().stream().map(this::toSummary).toList();
    }

    public PageResponse<PlaceSummaryResponse> searchAdmin(
            String q, Long categoryId, PlaceStatus status,
            Long locationId, Boolean featured, Boolean verified,
            int page, int size, String sort) {

        Specification<Place> spec = Specification
            .where(PlaceSpecification.withStatus(status))
            .and(PlaceSpecification.withKeyword(q))
            .and(PlaceSpecification.withCategoryId(categoryId))
            .and(PlaceSpecification.withLocationId(locationId))
            .and(PlaceSpecification.withFeatured(featured))
            .and(PlaceSpecification.withVerified(verified));

        Pageable pageable = PageRequest.of(page, size, resolveSort(sort));
        return PageResponse.of(places.findAll(spec, pageable).map(this::toSummary));
    }

    @Transactional
    public PlaceResponse create(PlaceRequest req, Long adminId) {
        User admin = userOrThrow(adminId);

        PlaceStatus effectiveStatus = req.status() != null ? req.status() : DRAFT;
        validateFeaturedVerified(req.featured(), req.verified(), effectiveStatus);

        String slug = findUniqueSlug(SlugUtils.toSlug(req.name()), null);

        Place p = new Place();
        fillPlace(p, req, slug);
        p.setCreatedBy(admin);
        if (req.status() != null) p.setStatus(req.status());

        Place saved = places.save(p);
        saveSubEntities(saved, req);
        return toResponse(saved);
    }

    @Transactional
    public PlaceResponse update(Long id, PlaceRequest req) {
        Place p = placeOrThrow(id);

        PlaceStatus effectiveStatus = req.status() != null ? req.status() : p.getStatus();
        validateFeaturedVerified(req.featured(), req.verified(), effectiveStatus);

        if (req.status() != null) validateTransition(p.getStatus(), req.status());

        String baseSlug = SlugUtils.toSlug(req.name());
        String newSlug = baseSlug.equals(p.getSlug()) ? p.getSlug() : findUniqueSlug(baseSlug, p.getId());

        fillPlace(p, req, newSlug);
        if (req.status() != null) p.setStatus(req.status());

        Place saved = places.save(p);
        tags.deleteAllByPlaceId(id);
        hours.deleteAllByPlaceId(id);
        placeAmenities.deleteAllByPlaceId(id);
        saveSubEntities(saved, req);
        return toResponse(saved);
    }

    @Transactional
    public PlaceResponse updateStatus(Long id, PlaceStatus newStatus, Long adminId) {
        Place p = placeOrThrow(id);
        validateTransition(p.getStatus(), newStatus);

        p.setStatus(newStatus);

        if (newStatus == APPROVED || newStatus == PUBLISHED) {
            p.setApprovedBy(userOrThrow(adminId));
            if (p.getApprovedAt() == null) p.setApprovedAt(Instant.now());
        }

        return toResponse(places.save(p));
    }

    @Transactional
    public PlaceResponse updateFeatured(Long id, boolean featured) {
        Place p = placeOrThrow(id);
        if (featured) validateFeaturedVerified(true, false, p.getStatus());
        p.setFeatured(featured);
        return toResponse(places.save(p));
    }

    @Transactional
    public PlaceResponse updateVerified(Long id, boolean verified) {
        Place p = placeOrThrow(id);
        if (verified) validateFeaturedVerified(false, true, p.getStatus());
        p.setVerified(verified);
        return toResponse(places.save(p));
    }

    // ─── Detail builder ───────────────────────────────────────────────────────

    private PlaceDetailResponse toDetail(Place p) {
        List<PlaceTagResponse> tagList = tags.findAllByPlaceId(p.getId())
            .stream().map(t -> new PlaceTagResponse(t.getId(), t.getTag())).toList();

        List<AmenityRef> amenityList = placeAmenities.findAllByPlaceId(p.getId())
            .stream().map(pa -> toAmenityRef(pa.getAmenity())).toList();

        List<PlaceOpeningHour> hourEntities = hours.findAllByPlaceId(p.getId());
        List<PlaceOpeningHourResponse> openingHourList = hourEntities.stream()
            .map(h -> new PlaceOpeningHourResponse(
                h.getId(), h.getDayOfWeek(), h.getOpenTime(), h.getCloseTime(), h.isClosed()))
            .toList();

        List<PlaceDetailResponse.OpeningHourGroupResponse> grouped =
            OpeningHourUtils.group(hourEntities);

        List<MediaAsset> imgList = mediaAssets
            .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(MediaOwnerType.PLACE, p.getId());

        String coverImageUrl = imgList.stream()
            .filter(m -> m.isCover() && m.getMediaType() == MediaType.IMAGE)
            .findFirst()
            .or(() -> imgList.stream().filter(m -> m.getMediaType() == MediaType.IMAGE).findFirst())
            .map(MediaAsset::getUrl)
            .orElse(null);

        List<ImageRef> gallery = imgList.stream()
            .map(img -> new ImageRef(
                img.getId(), img.getUrl(), img.getThumbnailUrl(),
                img.getAltText(), img.getSortOrder(), img.isCover()))
            .toList();

        ZonedDateTime nowVN = ZonedDateTime.now(VIETNAM);
        boolean openNow = OpeningHourUtils.isOpenNow(
            hourEntities, nowVN.toLocalTime(), nowVN.getDayOfWeek().getValue());

        List<PlaceSummaryResponse> similar = findSimilarPlaces(p);

        PlaceMetadataResponse metadata = metadataRepo.findByPlaceId(p.getId())
            .map(this::toMetadataResponse)
            .orElse(null);

        HotelDetailDto.HotelDetailResponse hotelDetail = resolveHotelDetail(p);

        return new PlaceDetailResponse(
            p.getId(), p.getName(), p.getSlug(),
            p.getShortDescription(), p.getDescription(),
            p.getAddress(), p.getGoogleMapUrl(), p.getLatitude(), p.getLongitude(),
            toCategoryRef(p.getCategory()),
            toCategoryRef(p.getSubcategory()),
            toLocationRef(p.getAdministrativeUnit()),
            p.getRatingAvg(), p.getReviewCount(), p.getPriceLevel(),
            p.isFeatured(), p.isVerified(), p.getStatus(),
            tagList, amenityList, openingHourList, grouped,
            coverImageUrl, gallery, openNow, similar, metadata, hotelDetail
        );
    }

    @Transactional
    public PlaceMetadataResponse upsertMetadata(Long placeId, PlaceMetadataRequest req) {
        Place place = placeOrThrow(placeId);
        PlaceMetadata m = metadataRepo.findByPlaceId(placeId).orElseGet(() -> {
            PlaceMetadata fresh = new PlaceMetadata();
            fresh.setPlace(place);
            return fresh;
        });
        m.getTravelStyles().clear();
        if (req.travelStyles() != null) m.getTravelStyles().addAll(req.travelStyles());
        m.getBestVisitTimes().clear();
        if (req.bestVisitTimes() != null) m.getBestVisitTimes().addAll(req.bestVisitTimes());
        m.getBestSeasons().clear();
        if (req.bestSeasons() != null) m.getBestSeasons().addAll(req.bestSeasons());
        m.getWeatherTypes().clear();
        if (req.weatherTypes() != null) m.getWeatherTypes().addAll(req.weatherTypes());
        m.setEstimatedVisitMinutes(req.estimatedVisitMinutes());
        m.setEstimatedBudgetLevel(req.estimatedBudgetLevel());
        m.setDifficultyLevel(req.difficultyLevel());
        m.setAccessibilityLevel(req.accessibilityLevel());
        m.setCrowdLevel(req.crowdLevel());
        m.setRomantic(req.romantic());
        m.setFamilyFriendly(req.familyFriendly());
        m.setKidFriendly(req.kidFriendly());
        m.setPetFriendly(req.petFriendly());
        m.setWheelchairFriendly(req.wheelchairFriendly());
        m.setPhotographySpot(req.photographySpot());
        m.setSunsetSpot(req.sunsetSpot());
        m.setSunriseSpot(req.sunriseSpot());
        m.setIndoor(req.indoor());
        m.setOutdoor(req.outdoor());
        m.setRainyDaySuitable(req.rainyDaySuitable());
        m.setNotes(req.notes());
        return toMetadataResponse(metadataRepo.save(m));
    }

    private PlaceMetadataResponse toMetadataResponse(PlaceMetadata m) {
        return new PlaceMetadataResponse(
            m.getId(),
            List.copyOf(m.getTravelStyles()),
            List.copyOf(m.getBestVisitTimes()),
            List.copyOf(m.getBestSeasons()),
            List.copyOf(m.getWeatherTypes()),
            m.getEstimatedVisitMinutes(),
            m.getEstimatedBudgetLevel(),
            m.getDifficultyLevel(),
            m.getAccessibilityLevel(),
            m.getCrowdLevel(),
            m.isRomantic(),
            m.isFamilyFriendly(),
            m.isKidFriendly(),
            m.isPetFriendly(),
            m.isWheelchairFriendly(),
            m.isPhotographySpot(),
            m.isSunsetSpot(),
            m.isSunriseSpot(),
            m.isIndoor(),
            m.isOutdoor(),
            m.isRainyDaySuitable(),
            m.getNotes(),
            m.getCreatedAt(),
            m.getUpdatedAt()
        );
    }

    private HotelDetailDto.HotelDetailResponse resolveHotelDetail(Place p) {
        return hotelDetailService.resolveForPlace(p, true);
    }

    private List<PlaceSummaryResponse> findSimilarPlaces(Place target) {
        Long catId    = target.getCategory().getId();
        Long subcatId = target.getSubcategory() != null ? target.getSubcategory().getId() : null;
        Long locId    = target.getAdministrativeUnit().getId();

        Specification<Place> catOrSubcat = subcatId != null
            ? PlaceSpecification.withCategoryId(catId).or(PlaceSpecification.withSubcategoryId(subcatId))
            : PlaceSpecification.withCategoryId(catId);

        Specification<Place> spec = Specification
            .where(PlaceSpecification.withStatus(PUBLISHED))
            .and((root, q, cb) -> cb.notEqual(root.get("id"), target.getId()))
            .and(catOrSubcat);

        Pageable pageable = PageRequest.of(0, 20,
            Sort.by(Sort.Direction.DESC, "featured", "verified", "ratingAvg"));

        List<Place> candidates = places.findAll(spec, pageable).getContent();

        return candidates.stream()
            .sorted(Comparator.comparingInt((Place p) -> {
                boolean sameSubcat = subcatId != null && p.getSubcategory() != null
                    && subcatId.equals(p.getSubcategory().getId());
                boolean sameLoc = locId.equals(p.getAdministrativeUnit().getId());
                if (sameSubcat && sameLoc) return 0;
                if (p.getCategory().getId().equals(catId) && sameLoc) return 1;
                if (p.getCategory().getId().equals(catId)) return 2;
                return 3;
            }))
            .limit(6)
            .map(this::toSummary)
            .toList();
    }

    // ─── Validation helpers ───────────────────────────────────────────────────

    private void validateTransition(PlaceStatus from, PlaceStatus to) {
        if (from == to) return;
        Set<PlaceStatus> allowed = ALLOWED_TRANSITIONS.getOrDefault(from, Set.of());
        if (!allowed.contains(to)) {
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "Invalid status transition: " + from + " → " + to);
        }
    }

    private void validateFeaturedVerified(boolean featured, boolean verified, PlaceStatus status) {
        Set<PlaceStatus> eligibleStatuses = Set.of(APPROVED, PUBLISHED);
        if (featured && !eligibleStatuses.contains(status))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "featured=true is only allowed for APPROVED or PUBLISHED places");
        if (verified && !eligibleStatuses.contains(status))
            throw new ApiException(HttpStatus.BAD_REQUEST,
                "verified=true is only allowed for APPROVED or PUBLISHED places");
    }

    // ─── Slug helpers ─────────────────────────────────────────────────────────

    /** Returns base if available; otherwise tries base-2, base-3, … until unique. */
    private String findUniqueSlug(String base, Long excludeId) {
        String candidate = base;
        int suffix = 2;
        while (isSlugTaken(candidate, excludeId)) {
            candidate = base + "-" + suffix++;
        }
        return candidate;
    }

    private boolean isSlugTaken(String slug, Long excludeId) {
        if (excludeId == null) return places.existsBySlug(slug);
        return places.existsBySlugAndIdNot(slug, excludeId);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private Sort resolveSort(String sort) {
        return switch (sort == null ? "" : sort) {
            case "newest"      -> Sort.by(Sort.Direction.DESC, "createdAt");
            case "rating_desc" -> Sort.by(Sort.Direction.DESC, "ratingAvg");
            case "price_asc"   -> Sort.by(Sort.Direction.ASC,  "priceLevel");
            case "price_desc"  -> Sort.by(Sort.Direction.DESC, "priceLevel");
            case "name_asc"    -> Sort.by(Sort.Direction.ASC,  "name");
            default            -> Sort.by(Sort.Direction.DESC, "createdAt");
        };
    }

    private void fillPlace(Place p, PlaceRequest req, String slug) {
        p.setName(req.name());
        p.setNameNormalized(SlugUtils.normalize(req.name()));
        p.setSlug(slug);
        p.setCategory(categoryOrThrow(req.categoryId()));

        if (req.subcategoryId() != null) {
            Category subcat = categoryOrThrow(req.subcategoryId());
            if (subcat.getParent() == null || !subcat.getParent().getId().equals(p.getCategory().getId())) {
                throw new ApiException(HttpStatus.BAD_REQUEST,
                    "Subcategory must be a direct child of the specified category");
            }
            p.setSubcategory(subcat);
        } else {
            p.setSubcategory(null);
        }

        p.setAdministrativeUnit(locationOrThrow(req.administrativeUnitId()));
        p.setAddress(req.address());
        p.setGoogleMapUrl(req.googleMapUrl());
        p.setLatitude(req.latitude());
        p.setLongitude(req.longitude());
        p.setShortDescription(req.shortDescription());
        p.setDescription(req.description());
        p.setPriceLevel(req.priceLevel());
        p.setFeatured(req.featured());
        p.setVerified(req.verified());
        p.setOwnerUser(req.ownerUserId() != null ? userOrThrow(req.ownerUserId()) : null);
    }

    private void saveSubEntities(Place place, PlaceRequest req) {
        if (req.tags() != null) {
            req.tags().stream()
                    .filter(t -> t != null && !t.isBlank())
                    .distinct()
                    .forEach(t -> {
                        PlaceTag tag = new PlaceTag();
                        tag.setPlace(place);
                        tag.setTag(t.trim());
                        tag.setTagNormalized(SlugUtils.normalize(t.trim()));
                        tags.save(tag);
                    });
        }
        if (req.amenityIds() != null) {
            req.amenityIds().stream().distinct().forEach(aid -> {
                Amenity amenity = amenities.findById(aid)
                        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Amenity not found: " + aid));
                PlaceAmenity pa = new PlaceAmenity();
                pa.setPlace(place);
                pa.setAmenity(amenity);
                placeAmenities.save(pa);
            });
        }
        if (req.openingHours() != null) {
            req.openingHours().forEach(hr -> {
                if (!hr.closed() && (hr.openTime() == null || hr.closeTime() == null))
                    throw new ApiException(HttpStatus.BAD_REQUEST,
                            "openTime and closeTime are required when closed is false");
                PlaceOpeningHour h = new PlaceOpeningHour();
                h.setPlace(place);
                h.setDayOfWeek(hr.dayOfWeek());
                h.setOpenTime(hr.openTime());
                h.setCloseTime(hr.closeTime());
                h.setClosed(hr.closed());
                hours.save(h);
            });
        }
    }

    // ─── Mappers ──────────────────────────────────────────────────────────────

    PlaceSummaryResponse toSummary(Place p) {
        String coverImageUrl = resolveCoverUrl(p.getId());
        return new PlaceSummaryResponse(
                p.getId(), p.getName(), p.getSlug(),
                toCategoryRef(p.getCategory()),
                toCategoryRef(p.getSubcategory()),
                toLocationRef(p.getAdministrativeUnit()),
                p.getAddress(), p.getGoogleMapUrl(), p.getLatitude(), p.getLongitude(),
                p.getShortDescription(),
                p.getPriceLevel(), p.getRatingAvg(), p.getReviewCount(),
                p.getStatus(), p.isFeatured(), p.isVerified(),
                coverImageUrl,
                p.getCreatedAt()
        );
    }

    private String resolveCoverUrl(Long placeId) {
        List<MediaAsset> media = mediaAssets
            .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(MediaOwnerType.PLACE, placeId);
        return media.stream()
            .filter(m -> m.isCover() && m.getMediaType() == MediaType.IMAGE)
            .findFirst()
            .or(() -> media.stream().filter(m -> m.getMediaType() == MediaType.IMAGE).findFirst())
            .map(MediaAsset::getUrl)
            .orElse(null);
    }

    private PlaceResponse toResponse(Place p) {
        List<PlaceTagResponse> tagList = tags.findAllByPlaceId(p.getId())
                .stream().map(t -> new PlaceTagResponse(t.getId(), t.getTag())).toList();
        List<AmenityRef> amenityList = placeAmenities.findAllByPlaceId(p.getId())
                .stream().map(pa -> toAmenityRef(pa.getAmenity())).toList();
        List<PlaceOpeningHourResponse> hourList = hours.findAllByPlaceId(p.getId())
                .stream().map(h -> new PlaceOpeningHourResponse(
                        h.getId(), h.getDayOfWeek(), h.getOpenTime(), h.getCloseTime(), h.isClosed()
                )).toList();

        return new PlaceResponse(
                p.getId(), p.getName(), p.getSlug(),
                toCategoryRef(p.getCategory()),
                toCategoryRef(p.getSubcategory()),
                toLocationRef(p.getAdministrativeUnit()),
                p.getAddress(), p.getGoogleMapUrl(), p.getLatitude(), p.getLongitude(),
                p.getShortDescription(), p.getDescription(),
                p.getPriceLevel(), p.getRatingAvg(), p.getReviewCount(),
                p.getStatus(), p.isFeatured(), p.isVerified(),
                tagList, amenityList, hourList,
                p.getCreatedAt(), p.getUpdatedAt()
        );
    }

    private CategoryRef toCategoryRef(Category c) {
        if (c == null) return null;
        return new CategoryRef(c.getId(), c.getName(), c.getSlug(), c.getType(), c.getIcon(), c.getColor());
    }

    private LocationRef toLocationRef(AdministrativeUnit u) {
        if (u == null) return null;
        return new LocationRef(u.getId(), u.getName(), u.getSlug(), u.getFullPath());
    }

    private AmenityRef toAmenityRef(Amenity a) {
        return new AmenityRef(a.getId(), a.getName(), a.getSlug(), a.getIcon(), a.getGroupName());
    }

    // ─── Lookups ──────────────────────────────────────────────────────────────

    private Place placeOrThrow(Long id) {
        return places.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + id));
    }

    private Category categoryOrThrow(Long id) {
        return categories.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Category not found: " + id));
    }

    private AdministrativeUnit locationOrThrow(Long id) {
        return locations.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Administrative unit not found: " + id));
    }

    private User userOrThrow(Long id) {
        return users.findById(id)
                .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "User not found: " + id));
    }
}
