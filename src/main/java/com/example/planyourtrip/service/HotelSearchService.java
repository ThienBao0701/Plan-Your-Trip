package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelSearchDto.HotelSearchResponse;
import com.example.planyourtrip.dto.HotelSearchDto.MatchedRoomResponse;
import com.example.planyourtrip.dto.PageResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class HotelSearchService {

    private final PlaceRepository placeRepo;
    private final HotelDetailRepository hotelDetailRepo;
    private final HotelRoomRepository roomRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final MediaAssetRepository mediaRepo;

    public HotelSearchService(PlaceRepository placeRepo,
                               HotelDetailRepository hotelDetailRepo,
                               HotelRoomRepository roomRepo,
                               RoomInventoryRepository inventoryRepo,
                               MediaAssetRepository mediaRepo) {
        this.placeRepo = placeRepo;
        this.hotelDetailRepo = hotelDetailRepo;
        this.roomRepo = roomRepo;
        this.inventoryRepo = inventoryRepo;
        this.mediaRepo = mediaRepo;
    }

    public PageResponse<HotelSearchResponse> search(
            String q, Long locationId,
            LocalDate checkIn, LocalDate checkOut,
            int guests, int rooms,
            Double minRating, BigDecimal maxPrice,
            Boolean freeCancellation, Boolean breakfastIncluded,
            int page, int size, String sort) {

        if (checkIn == null)  throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn is required");
        if (checkOut == null) throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut is required");
        if (!checkIn.isBefore(checkOut))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn must be before checkOut");
        if (guests < 1) throw new ApiException(HttpStatus.BAD_REQUEST, "guests must be >= 1");
        if (rooms < 1)  throw new ApiException(HttpStatus.BAD_REQUEST, "rooms must be >= 1");

        long nights = ChronoUnit.DAYS.between(checkIn, checkOut);

        Specification<Place> spec = Specification
            .where(PlaceSpecification.withStatus(PlaceStatus.PUBLISHED))
            .and(hasHotelDetail())
            .and(PlaceSpecification.withKeyword(q))
            .and(PlaceSpecification.withLocationId(locationId))
            .and(PlaceSpecification.withMinRating(minRating));

        List<Place> candidates = placeRepo.findAll(spec);

        List<HotelSearchResponse> results = new ArrayList<>();
        for (Place place : candidates) {
            buildHotelResponse(place, checkIn, checkOut, nights, guests, rooms)
                .ifPresent(results::add);
        }

        if (maxPrice != null) {
            results = results.stream()
                .filter(r -> r.lowestPrice() != null && r.lowestPrice().compareTo(maxPrice) <= 0)
                .collect(Collectors.toList());
        }
        if (Boolean.TRUE.equals(freeCancellation)) {
            results = results.stream()
                .filter(HotelSearchResponse::freeCancellation)
                .collect(Collectors.toList());
        }
        if (Boolean.TRUE.equals(breakfastIncluded)) {
            results = results.stream()
                .filter(HotelSearchResponse::breakfastIncluded)
                .collect(Collectors.toList());
        }

        sortResults(results, sort);

        int total = results.size();
        int start = page * size;
        List<HotelSearchResponse> pageContent = (start >= total)
            ? Collections.emptyList()
            : results.subList(start, Math.min(start + size, total));

        int totalPages = (total == 0) ? 0 : (int) Math.ceil((double) total / size);
        return new PageResponse<>(pageContent, page, size, total, totalPages);
    }

    private Optional<HotelSearchResponse> buildHotelResponse(
            Place place, LocalDate checkIn, LocalDate checkOut,
            long nights, int guestCount, int roomCount) {

        HotelDetail detail = hotelDetailRepo.findByPlaceId(place.getId()).orElse(null);
        if (detail == null) return Optional.empty();

        List<HotelRoom> activeRooms = roomRepo.findAllByHotelDetailIdAndActiveTrue(detail.getId());

        List<MatchedRoomResponse> matched = new ArrayList<>();
        for (HotelRoom room : activeRooms) {
            if (!isRoomAvailable(room, checkIn, checkOut, nights, guestCount, roomCount)) continue;
            String coverUrl = resolveCoverUrl(MediaOwnerType.ROOM, room.getId());
            matched.add(new MatchedRoomResponse(
                room.getId(), room.getRoomName(), room.getRoomType(), room.getBedType(),
                room.getMaxGuests(), room.getPriceFrom(), room.getOriginalPrice(),
                room.getAvailableQuantity(), room.isBreakfastIncluded(), room.isFreeCancellation(),
                coverUrl
            ));
        }

        if (matched.isEmpty()) return Optional.empty();

        BigDecimal lowestPrice = matched.stream()
            .map(MatchedRoomResponse::priceFrom)
            .filter(Objects::nonNull)
            .min(Comparator.naturalOrder())
            .orElse(null);

        return Optional.of(new HotelSearchResponse(
            place.getId(), place.getName(), place.getSlug(), place.getAddress(),
            place.getAdministrativeUnit().getName(), place.getGoogleMapUrl(),
            place.getLatitude(), place.getLongitude(),
            place.getRatingAvg(), place.getReviewCount(),
            detail.getStarRating(), detail.getDistanceToBeachMeters(),
            resolveCoverUrl(MediaOwnerType.PLACE, place.getId()),
            place.isFeatured(), place.isVerified(),
            lowestPrice, "VND",
            matched.size(),
            matched.stream().anyMatch(MatchedRoomResponse::freeCancellation),
            matched.stream().anyMatch(MatchedRoomResponse::breakfastIncluded),
            matched
        ));
    }

    private boolean isRoomAvailable(
            HotelRoom room, LocalDate checkIn, LocalDate checkOut,
            long nights, int guestCount, int roomCount) {

        if (room.getMaxGuests() == null || room.getMaxGuests() < guestCount) return false;
        if (room.getAvailableQuantity() == null || room.getAvailableQuantity() < roomCount) return false;

        List<RoomInventory> inventories = inventoryRepo.findBetweenDates(
            room.getId(), checkIn, checkOut.minusDays(1));

        if (inventories.size() < nights) return false;

        LocalDate lastNight = checkOut.minusDays(1);

        for (RoomInventory inv : inventories) {
            if (inv.getAvailableInventory() < roomCount) return false;
            if (inv.isStopSell()) return false;
            if (inv.getInventoryDate().equals(checkIn) && inv.isClosedArrival()) return false;
            if (inv.getInventoryDate().equals(lastNight) && inv.isClosedDeparture()) return false;
        }

        return true;
    }

    private void sortResults(List<HotelSearchResponse> results, String sort) {
        Comparator<HotelSearchResponse> cmp;
        if ("rating_desc".equals(sort)) {
            cmp = Comparator.comparingDouble(HotelSearchResponse::ratingAvg).reversed();
        } else if ("price_asc".equals(sort)) {
            cmp = Comparator.comparing(HotelSearchResponse::lowestPrice,
                Comparator.nullsLast(Comparator.naturalOrder()));
        } else if ("price_desc".equals(sort)) {
            cmp = Comparator.comparing(HotelSearchResponse::lowestPrice,
                Comparator.nullsLast(Comparator.reverseOrder()));
        } else if ("name_asc".equals(sort)) {
            cmp = Comparator.comparing(HotelSearchResponse::name);
        } else {
            // recommended: featured first, verified second, then rating desc
            cmp = Comparator
                .comparingInt((HotelSearchResponse r) -> r.featured() ? 0 : 1)
                .thenComparingInt(r -> r.verified() ? 0 : 1)
                .thenComparingDouble(r -> -r.ratingAvg());
        }
        results.sort(cmp);
    }

    private String resolveCoverUrl(MediaOwnerType ownerType, Long ownerId) {
        List<MediaAsset> media = mediaRepo
            .findByOwnerTypeAndOwnerIdAndActiveTrueOrderBySortOrderAsc(ownerType, ownerId);
        return media.stream()
            .filter(m -> m.isCover() && m.getMediaType() == MediaType.IMAGE)
            .findFirst()
            .or(() -> media.stream().filter(m -> m.getMediaType() == MediaType.IMAGE).findFirst())
            .map(MediaAsset::getUrl)
            .orElse(null);
    }

    private static Specification<Place> hasHotelDetail() {
        return (root, query, cb) -> {
            var sub = query.subquery(Long.class);
            var hdRoot = sub.from(HotelDetail.class);
            sub.select(cb.literal(1L))
               .where(cb.equal(hdRoot.get("place").get("id"), root.get("id")));
            return cb.exists(sub);
        };
    }
}
