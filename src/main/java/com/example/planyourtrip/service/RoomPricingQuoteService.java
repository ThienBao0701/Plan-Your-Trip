package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.PromotionDto.PricingBreakdownResponse;
import com.example.planyourtrip.dto.RatePlanDto.RatePlanPricingBreakdownResponse;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteRequest;
import com.example.planyourtrip.dto.RoomPricingQuoteDto.RoomPricingQuoteResponse;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.Place;
import com.example.planyourtrip.model.PlaceStatus;
import com.example.planyourtrip.model.RatePlan;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Phase 7.32 — orchestrates a STATELESS, READ-ONLY pricing quote for a room and stay.
 *
 * <p>This is pure read infrastructure: it NEVER creates a booking, decrements inventory,
 * creates an {@code InventoryReservation}, mutates any ledger, or consumes any customer
 * benefit (coupon / loyalty / travel credit / gift card). It only orchestrates existing
 * services — it copies none of their logic:
 * <ul>
 *   <li>rate-plan selection &amp; per-plan breakdown → {@link RatePlanPricingService}
 *       (the SAME {@code resolveForBooking} used by checkout / search / partner preview);</li>
 *   <li>promotion discount → {@link PricingEngineService} (the SAME 5-arg overload used by
 *       {@code BookingService.create});</li>
 *   <li>inventory availability → {@link RoomInventoryRepository} read queries (NO pessimistic
 *       {@code lockForUpdate}, so a quote never acquires the Phase 7.28 booking lock).</li>
 * </ul>
 *
 * <p>Because it composes exactly the stages checkout uses up to (but excluding) the
 * customer-specific discount chain, {@code finalQuotedPrice} equals the amount
 * {@code BookingService} feeds into that chain — the quoted price matches the pre-benefit
 * booking price by construction.
 */
@Service
@Transactional(readOnly = true)
public class RoomPricingQuoteService {

    /** How long a quote is presented as valid. A quote holds NOTHING; this is informational. */
    static final Duration QUOTE_TTL = Duration.ofMinutes(15);

    private static final String PRICE_DISCLAIMER =
        "This quote does not hold inventory or lock the price; both may change until a booking is created.";
    private static final String BENEFITS_NOTE =
        "Coupon, loyalty, travel-credit and gift-card discounts are not included and apply only at checkout.";

    private final HotelRoomRepository roomRepo;
    private final RoomInventoryRepository inventoryRepo;
    private final RatePlanPricingService ratePlanPricingService;
    private final PricingEngineService pricingEngineService;

    public RoomPricingQuoteService(HotelRoomRepository roomRepo,
                                   RoomInventoryRepository inventoryRepo,
                                   RatePlanPricingService ratePlanPricingService,
                                   PricingEngineService pricingEngineService) {
        this.roomRepo               = roomRepo;
        this.inventoryRepo          = inventoryRepo;
        this.ratePlanPricingService = ratePlanPricingService;
        this.pricingEngineService   = pricingEngineService;
    }

    public RoomPricingQuoteResponse quote(Long roomId, RoomPricingQuoteRequest req) {
        // ── 1. Validate the request ───────────────────────────────────────────
        LocalDate checkIn  = req.checkIn();
        LocalDate checkOut = req.checkOut();
        if (checkIn == null || checkOut == null)
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn and checkOut are required");
        if (!checkOut.isAfter(checkIn))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkOut must be after checkIn");
        if (checkIn.isBefore(LocalDate.now()))
            throw new ApiException(HttpStatus.BAD_REQUEST, "checkIn cannot be in the past");

        int adults   = req.adults()   != null ? req.adults()   : 1;
        int children = req.children() != null ? req.children() : 0;
        int extraBeds= req.extraBeds()!= null ? req.extraBeds(): 0;
        if (adults < 1)   throw new ApiException(HttpStatus.BAD_REQUEST, "adults must be at least 1");
        if (children < 0) throw new ApiException(HttpStatus.BAD_REQUEST, "children cannot be negative");
        if (extraBeds < 0)throw new ApiException(HttpStatus.BAD_REQUEST, "extraBeds cannot be negative");

        // ── 2. Room must exist and be publicly sellable ───────────────────────
        // Reuse the exact visibility rule enforced elsewhere: an ACTIVE room whose hotel Place
        // is PUBLISHED. Unpublished/hidden listings return 404 (never leak their existence).
        HotelRoom room = roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
        Place hotel = room.getHotelDetail().getPlace();
        if (!room.isActive() || hotel.getStatus() != PlaceStatus.PUBLISHED)
            throw new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId);

        long nights = ChronoUnit.DAYS.between(checkIn, checkOut);
        Long placeId = hotel.getId();
        Long hotelId = room.getHotelDetail().getId();

        // ── 3. Read-only inventory availability (NO lock, NO mutation) ─────────
        InventoryAvailability inv = readAvailability(roomId, checkIn, checkOut, nights);
        List<String> warnings = new ArrayList<>();
        warnings.add(PRICE_DISCLAIMER);
        warnings.add(BENEFITS_NOTE);

        Instant now = Instant.now();
        Instant expiresAt = now.plus(QUOTE_TTL);

        // ── 4. Resolve the rate plan (SAME selection as checkout/search) ───────
        // Explicit ratePlanId → validated (belongs to room + eligible) or 422 thrown here.
        // Omitted → best eligible plan is selected (or Optional.empty when none is eligible).
        // Inventory is NOT part of this resolution (checkInventory=false); it is reported
        // separately via inventoryAvailable so pricing is deterministic regardless of stock.
        Optional<RatePlanPricingService.BookingRateResolution> resolution =
            ratePlanPricingService.resolveForBooking(room, req.ratePlanId(), checkIn, checkOut, adults, children, extraBeds);

        if (!inv.available)
            warnings.add("No inventory is currently available for the selected dates; the room may not be bookable.");

        // ── 5a. No eligible rate plan → clear ineligible quote (still 200) ─────
        if (resolution.isEmpty()) {
            return new RoomPricingQuoteResponse(
                roomId, room.getRoomName(), room.getRoomCode(), placeId, hotelId,
                checkIn, checkOut, (int) nights, adults, children, extraBeds,
                null, null, null, null, null, null, null,
                null, null, null, null, null, null,
                null, null, null, null, "VND",
                inv.available, inv.availableRooms,
                now, expiresAt, warnings,
                "No rate plan is eligible for the selected stay dates and occupancy");
        }

        // ── 5b. Selected plan → granular breakdown + promotion stage ──────────
        RatePlan plan = resolution.get().plan();
        RatePlanPricingBreakdownResponse b =
            ratePlanPricingService.quoteBreakdown(roomId, plan.getId(), checkIn, checkOut, adults, children, extraBeds);

        // Promotion discount via the UNCHANGED pricing engine (5-arg overload), fed the resolved
        // rate-plan stay subtotal — identical to BookingService.create. finalPrice() is the
        // rate-plan subtotal minus the promotion discount (floored at zero): the amount that
        // enters the customer-discount chain at checkout.
        PricingBreakdownResponse pricing = pricingEngineService.calculate(
            roomId, checkIn, checkOut, b.staySubtotal(), plan.getRateName());

        return new RoomPricingQuoteResponse(
            roomId, room.getRoomName(), room.getRoomCode(), placeId, hotelId,
            checkIn, checkOut, (int) nights, adults, children, extraBeds,
            plan.getId(), plan.getCode(), plan.getRateName(),
            b.mealPlan(), b.cancellationPolicy(), b.refundable(), b.cancellationDeadline(),
            b.baseNightlyRate(), b.derivedAdjustment(), b.occupancyAdjustment(),
            b.childSupplement(), b.extraBedSupplement(), b.finalNightlyRate(),
            b.staySubtotal(),
            pricing.promotionDiscount(),
            pricing.finalPrice(),   // totalBeforeCustomerBenefits
            pricing.finalPrice(),   // finalQuotedPrice (headline; == pre-benefit total)
            pricing.currency(),
            inv.available, inv.availableRooms,
            now, expiresAt, warnings, null);
    }

    /** Read-only availability over the stay window — reuses existing inventory rows, never locks. */
    private InventoryAvailability readAvailability(Long roomId, LocalDate checkIn, LocalDate checkOut, long nights) {
        List<RoomInventory> rows = inventoryRepo.findBetweenDates(roomId, checkIn, checkOut.minusDays(1));
        long sellableNights = rows.stream()
            .filter(r -> !r.isStopSell() && r.getAvailableInventory() > 0)
            .count();
        boolean available = sellableNights == nights;
        int availableRooms = available
            ? rows.stream().filter(r -> !r.isStopSell())
                .mapToInt(RoomInventory::getAvailableInventory).min().orElse(0)
            : 0;
        return new InventoryAvailability(available, availableRooms);
    }

    private record InventoryAvailability(boolean available, int availableRooms) {}
}
