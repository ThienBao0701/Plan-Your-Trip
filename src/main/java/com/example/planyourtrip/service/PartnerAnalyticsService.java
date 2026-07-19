package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PartnerAnalyticsDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.*;
import com.example.planyourtrip.repository.*;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.EnumSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Read-only cross-domain analytics for approved partners, scoped to hotels they own.
 * Every method aggregates over data already produced by existing write flows
 * (Booking/Payment/Review/RoomInventory/Promotion/Conversation) — nothing here mutates state.
 */
@Service
@Transactional(readOnly = true)
public class PartnerAnalyticsService {

    private final PartnerProfileRepository partnerProfiles;
    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final BookingRepository bookingRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final ReviewRepository reviewRepo;
    private final PromotionRepository promotionRepo;
    private final ConversationRepository conversationRepo;
    private final MessageRepository messageRepo;

    private static final Set<BookingStatus> REVENUE_STATUSES =
        EnumSet.of(BookingStatus.CONFIRMED, BookingStatus.CHECK_IN_READY, BookingStatus.CHECKED_IN,
                   BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED, BookingStatus.ARCHIVED);

    private static final Set<BookingStatus> STAYED_STATUSES =
        EnumSet.of(BookingStatus.CHECKED_OUT, BookingStatus.COMPLETED);

    public PartnerAnalyticsService(PartnerProfileRepository partnerProfiles,
                                    PlaceRepository places,
                                    HotelDetailRepository hotelDetails,
                                    HotelRoomRepository rooms,
                                    BookingRepository bookingRepo,
                                    RoomInventoryRepository inventoryRepo,
                                    ReviewRepository reviewRepo,
                                    PromotionRepository promotionRepo,
                                    ConversationRepository conversationRepo,
                                    MessageRepository messageRepo) {
        this.partnerProfiles = partnerProfiles;
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.bookingRepo = bookingRepo;
        this.inventoryRepo = inventoryRepo;
        this.reviewRepo = reviewRepo;
        this.promotionRepo = promotionRepo;
        this.conversationRepo = conversationRepo;
        this.messageRepo = messageRepo;
    }

    // ── Overview ─────────────────────────────────────────────────────────────

    public PartnerAnalyticsOverviewResponse getOverview(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Booking> bookings = bookingsInRange(hotelIds, range[0], range[1]);

        BigDecimal totalRevenue = sumRevenue(bookings);
        long totalBookings = bookings.size();
        long confirmedBookings = countByStatus(bookings, BookingStatus.CONFIRMED);
        long cancelledBookings = countByStatus(bookings, BookingStatus.CANCELLED);
        long completedBookings = countByStatus(bookings, BookingStatus.COMPLETED);

        List<Long> roomIds = ownedRoomIds(hotelIds);
        double occupancyRate = computeOccupancyRate(roomIds, range[0], range[1]);
        double adr = computeADR(bookings, totalRevenue);
        double avgStay = computeAverageStay(bookings);

        List<Review> approvedReviews = reviewRepo.findByPlaceIdIn(hotelIds).stream()
            .filter(r -> r.getStatus() == ReviewStatus.APPROVED).toList();
        double reviewAverage = approvedReviews.isEmpty() ? 0.0 :
            approvedReviews.stream().mapToInt(Review::getRatingOverall).average().orElse(0.0);

        List<Conversation> convs = partnerConversationsInScope(profile.getId(), hotelId);
        long unreadMessages = convs.stream()
            .mapToLong(c -> messageRepo.countByConversationIdAndReadByPartnerFalse(c.getId())).sum();
        Double responseRate = computeResponseRate(convs);

        return new PartnerAnalyticsOverviewResponse(
            totalRevenue.setScale(2, RoundingMode.HALF_UP), totalBookings, confirmedBookings,
            cancelledBookings, completedBookings, round2(occupancyRate), round2(adr), round2(avgStay),
            round2(reviewAverage), approvedReviews.size(), unreadMessages,
            responseRate != null ? round2(responseRate) : null
        );
    }

    // ── Revenue ──────────────────────────────────────────────────────────────

    public RevenueAnalyticsResponse getRevenue(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Booking> revenueBookings = bookingsInRange(hotelIds, range[0], range[1]).stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus())).toList();

        List<TimeSeriesPoint> byDay = revenueByDay(revenueBookings, range[0], range[1]);
        List<MetricBreakdown> byRoom = revenueByRoom(revenueBookings);
        List<MetricBreakdown> byHotel = revenueByHotel(revenueBookings);

        LocalDate today = LocalDate.now();
        BigDecimal mtd = sumRevenue(bookingsInRange(hotelIds, today.withDayOfMonth(1), today));
        BigDecimal last30 = sumRevenue(bookingsInRange(hotelIds, today.minusDays(29), today));

        return new RevenueAnalyticsResponse(byDay, byRoom, byHotel,
            mtd.setScale(2, RoundingMode.HALF_UP), last30.setScale(2, RoundingMode.HALF_UP));
    }

    // ── Occupancy ────────────────────────────────────────────────────────────

    public OccupancyAnalyticsResponse getOccupancy(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Long> roomIds = ownedRoomIds(hotelIds);
        List<RoomInventory> inv = inventoryInRange(roomIds, range[0], range[1]);

        Map<LocalDate, List<RoomInventory>> byDate = inv.stream()
            .collect(Collectors.groupingBy(RoomInventory::getInventoryDate));
        List<TimeSeriesPoint> occupancyByDay = new ArrayList<>();
        for (LocalDate d = range[0]; !d.isAfter(range[1]); d = d.plusDays(1)) {
            List<RoomInventory> dayInv = byDate.getOrDefault(d, List.of());
            int total = dayInv.stream().mapToInt(RoomInventory::getTotalInventory).sum();
            int sold = dayInv.stream().mapToInt(RoomInventory::getSoldInventory).sum();
            double rate = total > 0 ? sold * 100.0 / total : 0.0;
            occupancyByDay.add(new TimeSeriesPoint(d, BigDecimal.valueOf(round2(rate))));
        }

        int totalRoomInventory = inv.stream().mapToInt(RoomInventory::getTotalInventory).sum();
        int soldRooms = inv.stream().mapToInt(RoomInventory::getSoldInventory).sum();
        int availableRooms = inv.stream().mapToInt(RoomInventory::getAvailableInventory).sum();
        long stopSellDaysCount = inv.stream().filter(RoomInventory::isStopSell).count();

        return new OccupancyAnalyticsResponse(occupancyByDay, totalRoomInventory, soldRooms, availableRooms,
            stopSellDaysCount);
    }

    // ── Bookings ─────────────────────────────────────────────────────────────

    public BookingAnalyticsResponse getBookingAnalytics(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Booking> bookings = bookingsInRange(hotelIds, range[0], range[1]);

        List<MetricBreakdown> byStatus = bookings.stream()
            .collect(Collectors.groupingBy(Booking::getStatus, Collectors.counting()))
            .entrySet().stream()
            .map(e -> new MetricBreakdown(e.getKey().name(), BigDecimal.valueOf(e.getValue()), e.getValue()))
            .sorted(Comparator.comparing(MetricBreakdown::label))
            .toList();

        Specification<Booking> departureSpec = Specification
            .where(BookingSpecification.withHotelIdIn(hotelIds))
            .and(BookingSpecification.withCheckOutDateRange(range[0], range[1]));
        List<Booking> departureBookings = bookingRepo.findAll(departureSpec);

        long arrivals = bookings.stream().filter(b -> b.getStatus() != BookingStatus.CANCELLED).count();
        long departures = departureBookings.stream().filter(b -> b.getStatus() != BookingStatus.CANCELLED).count();
        long cancellations = countByStatus(bookings, BookingStatus.CANCELLED);
        long noShows = countByStatus(bookings, BookingStatus.NO_SHOW);
        double avgStay = computeAverageStay(bookings);

        return new BookingAnalyticsResponse(byStatus, arrivals, departures, cancellations, noShows, round2(avgStay));
    }

    // ── Rooms ────────────────────────────────────────────────────────────────

    public RoomAnalyticsResponse getRoomAnalytics(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        LocalDate[] range = resolveRange(from, to);
        List<Booking> revenueBookings = bookingsInRange(hotelIds, range[0], range[1]).stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus())).toList();

        List<MetricBreakdown> byRevenue = revenueByRoom(revenueBookings);
        List<MetricBreakdown> byBookingCount = topRoomsByBookingCount(revenueBookings);

        List<Long> roomIds = ownedRoomIds(hotelIds);
        List<RoomInventory> inv = inventoryInRange(roomIds, range[0], range[1]);
        List<MetricBreakdown> availabilitySummary = roomAvailabilitySummary(inv);
        double occupancyEstimate = computeOccupancyRate(roomIds, range[0], range[1]);

        return new RoomAnalyticsResponse(byRevenue, byBookingCount, availabilitySummary, round2(occupancyEstimate));
    }

    // ── Promotions ───────────────────────────────────────────────────────────

    public PromotionAnalyticsResponse getPromotionAnalytics(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        resolveRange(from, to); // validated for API consistency; promotion state is current, not date-windowed (documented)

        List<Long> hotelDetailIds = hotelIds.stream()
            .map(id -> hotelDetails.findByPlaceId(id).orElse(null))
            .filter(Objects::nonNull).map(HotelDetail::getId).toList();
        List<Long> roomIds = ownedRoomIds(hotelIds);

        List<Promotion> promotions = (hotelDetailIds.isEmpty() && roomIds.isEmpty())
            ? List.of()
            : promotionRepo.findByOwnedTargets(
                PromotionTargetType.HOTEL, hotelDetailIds.isEmpty() ? List.of(-1L) : hotelDetailIds,
                PromotionTargetType.ROOM, roomIds.isEmpty() ? List.of(-1L) : roomIds);

        LocalDate today = LocalDate.now();
        long activePromotions = promotions.stream()
            .filter(p -> p.isActive() && !today.isBefore(p.getStartDate()) && !today.isAfter(p.getEndDate()))
            .count();

        List<MetricBreakdown> promotionsByType = promotions.stream()
            .collect(Collectors.groupingBy(Promotion::getPromotionType, Collectors.counting()))
            .entrySet().stream()
            .map(e -> new MetricBreakdown(e.getKey().name(), BigDecimal.valueOf(e.getValue()), e.getValue()))
            .sorted(Comparator.comparing(MetricBreakdown::label))
            .toList();

        List<MetricBreakdown> countByStatus = promotions.stream()
            .collect(Collectors.groupingBy(p -> promotionStatusLabel(p, today), Collectors.counting()))
            .entrySet().stream()
            .map(e -> new MetricBreakdown(e.getKey(), BigDecimal.valueOf(e.getValue()), e.getValue()))
            .sorted(Comparator.comparing(MetricBreakdown::label))
            .toList();

        // Bookings don't record which promotion (if any) discounted them, so exact
        // attribution of "bookings influenced by a promotion" isn't available yet —
        // structural analytics only, per the phase's documented scope.
        return new PromotionAnalyticsResponse(activePromotions, promotionsByType, null, countByStatus);
    }

    // ── Reviews ──────────────────────────────────────────────────────────────

    public ReviewAnalyticsResponse getReviewAnalytics(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        List<Long> hotelIds = resolveHotelScope(profile.getId(), hotelId);
        resolveRange(from, to); // validated for API consistency; reviews are all-time reputation data (documented)

        List<Review> reviews = hotelIds.isEmpty() ? List.of() : reviewRepo.findByPlaceIdIn(hotelIds);
        List<Review> approved = reviews.stream().filter(r -> r.getStatus() == ReviewStatus.APPROVED).toList();
        double avgRating = avgOverall(approved);

        long pending = reviews.stream().filter(r -> r.getStatus() == ReviewStatus.PENDING).count();
        long rejected = reviews.stream().filter(r -> r.getStatus() == ReviewStatus.REJECTED).count();

        List<ReviewPreview> latest = reviews.stream()
            .sorted(Comparator.comparing(Review::getCreatedAt).reversed())
            .limit(5)
            .map(r -> new ReviewPreview(r.getId(), r.getUser().getFullName(), r.getRatingOverall(),
                r.getTitle(), r.getStatus().name(), r.getCreatedAt()))
            .toList();

        return new ReviewAnalyticsResponse(round2(avgRating), reviews.size(), pending, approved.size(),
            rejected, latest);
    }

    /**
     * Phase 7.46 — detailed READ-ONLY review analytics for a SINGLE owned place.
     *
     * <p>Distinct from {@link #getReviewAnalytics} (a cross-owned-hotels summary): this drills into
     * one {@code placeId} the caller must own — an unknown place OR a place owned by someone else both
     * return a uniform 404 via {@link #resolveHotelScope} (no cross-partner leak). Reuses the shared
     * {@link #avgOverall} averaging + {@link #round2} rounding; adds category averages, a star
     * distribution and reply-rate. Population of every metric is documented on
     * {@code PlaceReviewAnalyticsResponse}. Nothing here mutates state.
     */
    public PlaceReviewAnalyticsResponse getPlaceReviewAnalytics(Long userId, Long placeId,
                                                                LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        resolveHotelScope(profile.getId(), placeId); // 404 if unknown or not owned (uniform, no leak)
        LocalDate[] range = resolveRange(from, to);

        Place place = places.findById(placeId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Place not found: " + placeId));

        List<Review> reviews = reviewRepo.findByPlaceIdIn(List.of(placeId));
        List<Review> approved = reviews.stream().filter(r -> r.getStatus() == ReviewStatus.APPROVED).toList();

        long total = reviews.size();
        long partnerReplyCount = reviews.stream().filter(r -> r.getPartnerRepliedAt() != null).count();
        double partnerReplyRate = total == 0 ? 0.0 : round2(partnerReplyCount * 100.0 / total);

        Map<Integer, Long> starDistribution = new LinkedHashMap<>();
        for (int star = 1; star <= 5; star++) {
            final int s = star;
            starDistribution.put(star, approved.stream().filter(r -> r.getRatingOverall() == s).count());
        }

        Instant latestReviewAt = reviews.stream()
            .map(Review::getCreatedAt).filter(Objects::nonNull)
            .max(Comparator.naturalOrder()).orElse(null);

        List<Review> inRange = reviews.stream().filter(r -> createdInRange(r, range[0], range[1])).toList();
        List<Review> approvedInRange = inRange.stream()
            .filter(r -> r.getStatus() == ReviewStatus.APPROVED).toList();

        return new PlaceReviewAnalyticsResponse(
            place.getId(), place.getName(),
            total,
            countStatus(reviews, ReviewStatus.APPROVED),
            countStatus(reviews, ReviewStatus.PENDING),
            countStatus(reviews, ReviewStatus.REJECTED),
            countStatus(reviews, ReviewStatus.HIDDEN),
            countStatus(reviews, ReviewStatus.REPORTED),
            round2(avgOverall(approved)),
            round2(avgCategory(approved, Review::getRatingCleanliness)),
            round2(avgCategory(approved, Review::getRatingService)),
            round2(avgCategory(approved, Review::getRatingLocation)),
            round2(avgCategory(approved, Review::getRatingValue)),
            round2(avgCategory(approved, Review::getRatingFacilities)),
            starDistribution,
            partnerReplyCount,
            partnerReplyRate,
            latestReviewAt,
            inRange.size(),
            round2(avgOverall(approvedInRange))
        );
    }

    // Shared review-metric helpers (reused by getReviewAnalytics + getPlaceReviewAnalytics) ──

    private long countStatus(List<Review> reviews, ReviewStatus status) {
        return reviews.stream().filter(r -> r.getStatus() == status).count();
    }

    /** Mean overall rating over the given reviews; 0.0 when the list is empty (never divides by zero). */
    private double avgOverall(List<Review> reviews) {
        return reviews.isEmpty() ? 0.0 : reviews.stream().mapToInt(Review::getRatingOverall).average().orElse(0.0);
    }

    /** Mean of one nullable category rating, ignoring reviews that left it null; 0.0 when none present. */
    private double avgCategory(List<Review> reviews, Function<Review, Integer> extractor) {
        return reviews.stream().map(extractor).filter(Objects::nonNull)
            .mapToInt(Integer::intValue).average().orElse(0.0);
    }

    private boolean createdInRange(Review r, LocalDate from, LocalDate to) {
        if (r.getCreatedAt() == null) return false;
        LocalDate d = LocalDate.ofInstant(r.getCreatedAt(), ZoneId.systemDefault());
        return !d.isBefore(from) && !d.isAfter(to);
    }

    // ── Messages ─────────────────────────────────────────────────────────────

    public MessageAnalyticsResponse getMessageAnalytics(Long userId, Long hotelId, LocalDate from, LocalDate to) {
        PartnerProfile profile = myApprovedProfileOrThrow(userId);
        resolveHotelScope(profile.getId(), hotelId); // validates hotelId ownership, if provided
        resolveRange(from, to); // validated for API consistency; conversation state is current inbox, not date-windowed (documented)

        List<Conversation> convs = partnerConversationsInScope(profile.getId(), hotelId);

        long open = convs.stream().filter(c -> c.getStatus() == ConversationStatus.OPEN).count();
        long closed = convs.stream().filter(c -> c.getStatus() == ConversationStatus.CLOSED).count();
        long archived = convs.stream().filter(c -> c.getStatus() == ConversationStatus.ARCHIVED).count();
        long unread = convs.stream()
            .mapToLong(c -> messageRepo.countByConversationIdAndReadByPartnerFalse(c.getId())).sum();
        Double avgResponseMinutes = computeAverageResponseTimeMinutes(convs);

        return new MessageAnalyticsResponse(open, closed, archived, unread, avgResponseMinutes);
    }

    // ── Ownership / scope helpers ────────────────────────────────────────────

    private PartnerProfile myApprovedProfileOrThrow(Long userId) {
        PartnerProfile profile = partnerProfiles.findByUserId(userId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Partner profile not found"));
        if (profile.getVerificationStatus() != PartnerVerificationStatus.APPROVED)
            throw new ApiException(HttpStatus.FORBIDDEN, "Partner profile is not approved");
        return profile;
    }

    private List<Long> resolveHotelScope(Long ownerId, Long hotelId) {
        List<Long> owned = places.findAllByOwnerId(ownerId).stream().map(Place::getId).toList();
        if (hotelId == null) return owned;
        if (!owned.contains(hotelId))
            throw new ApiException(HttpStatus.NOT_FOUND, "Hotel not found: " + hotelId);
        return List.of(hotelId);
    }

    private List<Long> ownedRoomIds(List<Long> hotelIds) {
        return hotelIds.stream()
            .map(id -> hotelDetails.findByPlaceId(id).orElse(null))
            .filter(Objects::nonNull)
            .flatMap(hd -> rooms.findAllByHotelDetailId(hd.getId()).stream())
            .map(HotelRoom::getId)
            .toList();
    }

    private LocalDate[] resolveRange(LocalDate from, LocalDate to) {
        LocalDate today = LocalDate.now();
        LocalDate resolvedTo = to != null ? to : today;
        LocalDate resolvedFrom = from != null ? from : resolvedTo.minusDays(29);
        if (resolvedFrom.isAfter(resolvedTo))
            throw new ApiException(HttpStatus.BAD_REQUEST, "from must not be after to");
        return new LocalDate[]{resolvedFrom, resolvedTo};
    }

    private List<Booking> bookingsInRange(List<Long> hotelIds, LocalDate from, LocalDate to) {
        Specification<Booking> spec = Specification
            .where(BookingSpecification.withHotelIdIn(hotelIds))
            .and(BookingSpecification.withCheckInDateRange(from, to));
        return bookingRepo.findAll(spec);
    }

    private List<RoomInventory> inventoryInRange(List<Long> roomIds, LocalDate from, LocalDate to) {
        return roomIds.isEmpty() ? List.of() : inventoryRepo.findByHotelRoomIdInAndInventoryDateBetween(roomIds, from, to);
    }

    private List<Conversation> partnerConversationsInScope(Long partnerProfileId, Long hotelId) {
        List<Conversation> all = conversationRepo.findByPartnerProfileIdOrderByLastMessageAtDesc(partnerProfileId);
        if (hotelId == null) return all;
        return all.stream().filter(c -> c.getBooking().getHotel().getId().equals(hotelId)).toList();
    }

    // ── Metric helpers ───────────────────────────────────────────────────────

    private BigDecimal sumRevenue(List<Booking> bookings) {
        return bookings.stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus()))
            .map(Booking::getFinalPrice)
            .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private long countByStatus(List<Booking> bookings, BookingStatus status) {
        return bookings.stream().filter(b -> b.getStatus() == status).count();
    }

    private double computeADR(List<Booking> bookings, BigDecimal totalRevenue) {
        long roomNights = bookings.stream()
            .filter(b -> REVENUE_STATUSES.contains(b.getStatus()))
            .mapToLong(b -> ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate()) * b.getNumberOfRooms())
            .sum();
        return roomNights > 0 ? totalRevenue.doubleValue() / roomNights : 0.0;
    }

    private double computeAverageStay(List<Booking> bookings) {
        List<Booking> stayed = bookings.stream().filter(b -> STAYED_STATUSES.contains(b.getStatus())).toList();
        return stayed.isEmpty() ? 0.0 : stayed.stream()
            .mapToLong(b -> ChronoUnit.DAYS.between(b.getCheckInDate(), b.getCheckOutDate()))
            .average().orElse(0.0);
    }

    private double computeOccupancyRate(List<Long> roomIds, LocalDate from, LocalDate to) {
        List<RoomInventory> inv = inventoryInRange(roomIds, from, to);
        int total = inv.stream().mapToInt(RoomInventory::getTotalInventory).sum();
        int sold = inv.stream().mapToInt(RoomInventory::getSoldInventory).sum();
        return total > 0 ? sold * 100.0 / total : 0.0;
    }

    private List<TimeSeriesPoint> revenueByDay(List<Booking> bookings, LocalDate from, LocalDate to) {
        Map<LocalDate, BigDecimal> byDate = bookings.stream()
            .collect(Collectors.groupingBy(Booking::getCheckInDate,
                Collectors.reducing(BigDecimal.ZERO, Booking::getFinalPrice, BigDecimal::add)));
        List<TimeSeriesPoint> points = new ArrayList<>();
        for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
            points.add(new TimeSeriesPoint(d, byDate.getOrDefault(d, BigDecimal.ZERO).setScale(2, RoundingMode.HALF_UP)));
        }
        return points;
    }

    private List<MetricBreakdown> revenueByRoom(List<Booking> bookings) {
        Map<Long, String> labels = new LinkedHashMap<>();
        Map<Long, BigDecimal> revenue = new LinkedHashMap<>();
        Map<Long, Long> counts = new LinkedHashMap<>();
        for (Booking b : bookings) {
            Long id = b.getRoom().getId();
            labels.putIfAbsent(id, b.getRoom().getRoomName());
            revenue.merge(id, b.getFinalPrice(), BigDecimal::add);
            counts.merge(id, 1L, Long::sum);
        }
        return labels.keySet().stream()
            .map(id -> new MetricBreakdown(labels.get(id), revenue.get(id).setScale(2, RoundingMode.HALF_UP), counts.get(id)))
            .sorted(Comparator.comparing(MetricBreakdown::value).reversed())
            .toList();
    }

    private List<MetricBreakdown> revenueByHotel(List<Booking> bookings) {
        Map<Long, String> labels = new LinkedHashMap<>();
        Map<Long, BigDecimal> revenue = new LinkedHashMap<>();
        Map<Long, Long> counts = new LinkedHashMap<>();
        for (Booking b : bookings) {
            Long id = b.getHotel().getId();
            labels.putIfAbsent(id, b.getHotel().getName());
            revenue.merge(id, b.getFinalPrice(), BigDecimal::add);
            counts.merge(id, 1L, Long::sum);
        }
        return labels.keySet().stream()
            .map(id -> new MetricBreakdown(labels.get(id), revenue.get(id).setScale(2, RoundingMode.HALF_UP), counts.get(id)))
            .sorted(Comparator.comparing(MetricBreakdown::value).reversed())
            .toList();
    }

    private List<MetricBreakdown> topRoomsByBookingCount(List<Booking> bookings) {
        Map<Long, String> labels = new LinkedHashMap<>();
        Map<Long, Long> counts = new LinkedHashMap<>();
        for (Booking b : bookings) {
            Long id = b.getRoom().getId();
            labels.putIfAbsent(id, b.getRoom().getRoomName());
            counts.merge(id, 1L, Long::sum);
        }
        return labels.keySet().stream()
            .map(id -> new MetricBreakdown(labels.get(id), BigDecimal.valueOf(counts.get(id)), counts.get(id)))
            .sorted(Comparator.comparing(MetricBreakdown::count).reversed())
            .toList();
    }

    private List<MetricBreakdown> roomAvailabilitySummary(List<RoomInventory> inv) {
        Map<Long, String> labels = new LinkedHashMap<>();
        Map<Long, Integer> available = new LinkedHashMap<>();
        Map<Long, Integer> total = new LinkedHashMap<>();
        for (RoomInventory ri : inv) {
            Long id = ri.getHotelRoom().getId();
            labels.putIfAbsent(id, ri.getHotelRoom().getRoomName());
            available.merge(id, ri.getAvailableInventory(), Integer::sum);
            total.merge(id, ri.getTotalInventory(), Integer::sum);
        }
        return labels.keySet().stream()
            .map(id -> new MetricBreakdown(labels.get(id), BigDecimal.valueOf(available.get(id)), total.get(id)))
            .sorted(Comparator.comparing(MetricBreakdown::label))
            .toList();
    }

    private String promotionStatusLabel(Promotion p, LocalDate today) {
        if (!p.isActive()) return "INACTIVE";
        if (today.isBefore(p.getStartDate())) return "SCHEDULED";
        if (today.isAfter(p.getEndDate())) return "EXPIRED";
        return "ACTIVE";
    }

    private Double computeResponseRate(List<Conversation> convs) {
        if (convs.isEmpty()) return null;
        long responded = convs.stream().filter(this::hasPartnerReply).count();
        return responded * 100.0 / convs.size();
    }

    private boolean hasPartnerReply(Conversation c) {
        return messageRepo.findByConversationIdOrderByCreatedAtAsc(c.getId())
            .stream().anyMatch(m -> m.getSenderRole() == MessageSenderRole.PARTNER);
    }

    /**
     * Average minutes between a guest's first unanswered message and the partner's next
     * reply, averaged across every such reply pair in the given conversations. Returns
     * null when there is no completed reply pair yet (nothing to average).
     */
    private Double computeAverageResponseTimeMinutes(List<Conversation> convs) {
        List<Long> deltasMinutes = new ArrayList<>();
        for (Conversation c : convs) {
            List<Message> messages = messageRepo.findByConversationIdOrderByCreatedAtAsc(c.getId());
            Instant pendingUserMessageAt = null;
            for (Message m : messages) {
                if (m.getSenderRole() == MessageSenderRole.USER) {
                    if (pendingUserMessageAt == null) pendingUserMessageAt = m.getCreatedAt();
                } else if (m.getSenderRole() == MessageSenderRole.PARTNER && pendingUserMessageAt != null) {
                    deltasMinutes.add(Duration.between(pendingUserMessageAt, m.getCreatedAt()).toMinutes());
                    pendingUserMessageAt = null;
                }
            }
        }
        return deltasMinutes.isEmpty() ? null : deltasMinutes.stream().mapToLong(Long::longValue).average().orElse(0.0);
    }

    private double round2(double value) {
        return Math.round(value * 100.0) / 100.0;
    }
}
