package com.example.planyourtrip.service;

import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.PartnerProfile;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.Promotion;
import com.example.planyourtrip.model.PromotionTargetType;
import com.example.planyourtrip.repository.BookingRepository;
import com.example.planyourtrip.repository.ConversationRepository;
import com.example.planyourtrip.repository.HotelDetailRepository;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.PartnerTeamMemberRepository;
import com.example.planyourtrip.repository.PlaceRepository;
import com.example.planyourtrip.repository.PromotionRepository;
import com.example.planyourtrip.repository.RatePlanOccupancyPriceRepository;
import com.example.planyourtrip.repository.RatePlanRepository;
import com.example.planyourtrip.repository.ReviewRepository;
import com.example.planyourtrip.security.rbac.ResourceType;
import com.example.planyourtrip.security.rbac.ScopePath;
import com.example.planyourtrip.security.rbac.ScopeRef;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * RBAC V1.1 §11.2 — where a partner resource lives, read from the database.
 *
 * <p>This is the only source of a resource's scope: the company is always the stored owner of the property
 * ({@code places.owner_partner_profile_id}), reached through the resource's own relations. Nothing a client
 * sends — a company id, a property id, a scope — is consulted. A resource that does not exist, or whose
 * property has no partner owner, has no target, which the evaluator answers like a missing id.
 *
 * <p>{@code Place.ownerUser} is never used. A conversation is resolved through its booking's property, not
 * through the denormalized {@code conversations.partner_profile_id} (§16 PA-4), so a property that moved to
 * another company never exposes its conversations to the previous one.
 */
@Service
@Transactional(readOnly = true)
public class PartnerResourceTargetResolver {

    private final PlaceRepository places;
    private final HotelDetailRepository hotelDetails;
    private final HotelRoomRepository rooms;
    private final RatePlanRepository ratePlans;
    private final RatePlanOccupancyPriceRepository occupancyPrices;
    private final BookingRepository bookings;
    private final PromotionRepository promotions;
    private final ConversationRepository conversations;
    private final ReviewRepository reviews;
    private final PartnerTeamMemberRepository teamMembers;

    public PartnerResourceTargetResolver(PlaceRepository places,
                                         HotelDetailRepository hotelDetails,
                                         HotelRoomRepository rooms,
                                         RatePlanRepository ratePlans,
                                         RatePlanOccupancyPriceRepository occupancyPrices,
                                         BookingRepository bookings,
                                         PromotionRepository promotions,
                                         ConversationRepository conversations,
                                         ReviewRepository reviews,
                                         PartnerTeamMemberRepository teamMembers) {
        this.places = places;
        this.hotelDetails = hotelDetails;
        this.rooms = rooms;
        this.ratePlans = ratePlans;
        this.occupancyPrices = occupancyPrices;
        this.bookings = bookings;
        this.promotions = promotions;
        this.conversations = conversations;
        this.reviews = reviews;
        this.teamMembers = teamMembers;
    }

    /** The stored location of the resource of {@code type} with {@code id}, or empty. */
    public Optional<ScopePath> resolve(ResourceType type, Long id) {
        if (type == null || id == null) return Optional.empty();
        return switch (type) {
            case PROPERTY -> places.findById(id).flatMap(PartnerResourceTargetResolver::pathOf);
            case ROOM, CALENDAR -> rooms.findById(id).flatMap(PartnerResourceTargetResolver::pathOf);
            case RATE_PLAN -> ratePlans.findById(id)
                .flatMap(plan -> Optional.ofNullable(plan.getHotelRoom()))
                .flatMap(PartnerResourceTargetResolver::pathOf);
            case OCCUPANCY_PRICE -> occupancyPrices.findById(id)
                .flatMap(price -> Optional.ofNullable(price.getRatePlan()))
                .flatMap(plan -> Optional.ofNullable(plan.getHotelRoom()))
                .flatMap(PartnerResourceTargetResolver::pathOf);
            case BOOKING -> bookings.findById(id)
                .flatMap(booking -> propertyPathOf(booking.getHotel()));
            case PROMOTION -> promotions.findById(id).flatMap(this::pathOf);
            case CONVERSATION -> conversations.findById(id)
                .flatMap(conversation -> Optional.ofNullable(conversation.getBooking()))
                .flatMap(booking -> propertyPathOf(booking.getHotel()));
            case REVIEW -> reviews.findById(id).flatMap(review -> propertyPathOf(review.getPlace()));
            case MEMBERSHIP -> teamMembers.findById(id)
                .flatMap(member -> companyPathOf(member.getPartnerProfile()));
        };
    }

    /** The stored location of the booking with {@code bookingCode} (voucher and code-based check-in). */
    public Optional<ScopePath> resolveBookingCode(String bookingCode) {
        if (bookingCode == null || bookingCode.isBlank()) return Optional.empty();
        return bookings.findByBookingCode(bookingCode).flatMap(booking -> propertyPathOf(booking.getHotel()));
    }

    /**
     * Where a promotion target named in a request body lives. A {@code HOTEL} target is a
     * {@code hotel_details.id} resolved through its place — never read as a {@code places.id} (§11.2); a
     * {@code ROOM} target is a {@code hotel_rooms.id}; {@code ALL} is not a partner scope.
     */
    public Optional<ScopePath> resolvePromotionTarget(PromotionTargetType targetType, Long targetId) {
        if (targetType == null || targetId == null) return Optional.empty();
        return switch (targetType) {
            case HOTEL -> hotelDetails.findById(targetId)
                .flatMap(detail -> propertyPathOf(detail.getPlace()));
            case ROOM -> rooms.findById(targetId).flatMap(PartnerResourceTargetResolver::pathOf);
            case ALL -> Optional.empty();
        };
    }

    /**
     * Turns a stored grant scope into a usable path for the company holding the grant (§12.3). A scope
     * naming another company, or a property or unit that the company does not own today, resolves to
     * nothing — so a grant can never reach outside its company, even if the property moved (§16 PA-4).
     */
    public Optional<ScopePath> resolveGrantScope(Long companyId, ScopeRef scope) {
        if (companyId == null || scope == null) return Optional.empty();
        Optional<ScopePath> path = switch (scope.type()) {
            case COMPANY -> Optional.of(ScopePath.company(scope.id()));
            case PROPERTY -> resolve(ResourceType.PROPERTY, scope.id());
            case UNIT -> resolve(ResourceType.ROOM, scope.id());
        };
        return path.filter(resolved -> resolved.companyId().equals(companyId));
    }

    private Optional<ScopePath> pathOf(Promotion promotion) {
        return resolvePromotionTarget(promotion.getTargetType(), promotion.getTargetId());
    }

    private static Optional<ScopePath> pathOf(HotelRoom room) {
        if (room.getHotelDetail() == null) return Optional.empty();
        Place place = room.getHotelDetail().getPlace();
        return propertyPathOf(place).map(property ->
            ScopePath.unit(property.companyId(), property.propertyId(), room.getId()));
    }

    private static Optional<ScopePath> pathOf(Place place) {
        return propertyPathOf(place);
    }

    private static Optional<ScopePath> propertyPathOf(Place place) {
        if (place == null || place.getOwner() == null) return Optional.empty();
        return Optional.of(ScopePath.property(place.getOwner().getId(), place.getId()));
    }

    private static Optional<ScopePath> companyPathOf(PartnerProfile company) {
        return company == null ? Optional.empty() : Optional.of(ScopePath.company(company.getId()));
    }
}
