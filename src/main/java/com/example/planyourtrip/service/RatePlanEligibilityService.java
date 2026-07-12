package com.example.planyourtrip.service;

import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.RatePlan;
import com.example.planyourtrip.model.RateSourceType;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/**
 * Phase 7.29 — SINGLE source of truth for whether a rate plan may be sold for a given
 * stay/occupancy. Availability search, pricing preview, booking creation and partner
 * preview all delegate here so the rules cannot drift between them.
 *
 * <p>Inventory availability is checked by REUSING the existing
 * {@link RoomInventoryRepository#countNightsWithSufficientInventory} query (no new
 * inventory query, no new lock) and is SKIPPED in booking mode where availability has
 * already been confirmed under the Phase 7.28 pessimistic lock — so this service never
 * introduces a new lock-ordering hazard.
 */
@Service
@Transactional(readOnly = true)
public class RatePlanEligibilityService {

    private final RoomInventoryRepository inventoryRepo;

    public RatePlanEligibilityService(RoomInventoryRepository inventoryRepo) {
        this.inventoryRepo = inventoryRepo;
    }

    public record Result(boolean eligible, String reason) {
        static Result ok() { return new Result(true, "Eligible"); }
        static Result no(String reason) { return new Result(false, reason); }
    }

    /**
     * @param checkInventory when true, also require sufficient room inventory for the stay.
     *                       Pass false from the booking transaction (availability already
     *                       confirmed under lock) to avoid re-querying/re-locking inventory.
     */
    public Result evaluate(RatePlan plan, LocalDate checkIn, LocalDate checkOut,
                           int adults, int children, int extraBeds, boolean checkInventory) {
        if (checkIn == null || checkOut == null)
            return plan.isActive() ? Result.ok() : Result.no("Rate plan is inactive");
        if (!checkOut.isAfter(checkIn))
            return Result.no("checkOut must be after checkIn");

        if (!plan.isActive())
            return Result.no("Rate plan is inactive");

        long nights = ChronoUnit.DAYS.between(checkIn, checkOut);
        LocalDate lastNight = checkOut.minusDays(1);

        // Stay inside plan date range.
        if (plan.getStartDate().isAfter(checkIn) || plan.getEndDate().isBefore(lastNight))
            return Result.no("Stay is outside the rate plan's date range");

        // Min / max stay.
        if (plan.getMinStayNights() != null && nights < plan.getMinStayNights())
            return Result.no("Minimum stay is " + plan.getMinStayNights() + " night(s)");
        if (plan.getMaxStayNights() != null && nights > plan.getMaxStayNights())
            return Result.no("Maximum stay is " + plan.getMaxStayNights() + " night(s)");

        // Advance-booking window.
        long daysAhead = ChronoUnit.DAYS.between(LocalDate.now(), checkIn);
        if (plan.getMinAdvanceBookingDays() != null && daysAhead < plan.getMinAdvanceBookingDays())
            return Result.no("Must be booked at least " + plan.getMinAdvanceBookingDays() + " day(s) in advance");
        if (plan.getMaxAdvanceBookingDays() != null && daysAhead > plan.getMaxAdvanceBookingDays())
            return Result.no("Cannot be booked more than " + plan.getMaxAdvanceBookingDays() + " day(s) in advance");

        // Closed to arrival / departure.
        if (plan.isClosedToArrival())
            return Result.no("Rate plan is closed to arrival");
        if (plan.isClosedToDeparture())
            return Result.no("Rate plan is closed to departure");

        // Room capacity supports the guests.
        HotelRoom room = plan.getHotelRoom();
        if (room.getMaxAdults() != null && adults > room.getMaxAdults())
            return Result.no("Adults exceed room capacity");
        if (room.getMaxGuests() != null && (adults + children) > room.getMaxGuests())
            return Result.no("Total guests exceed room capacity");

        // Derived plan is only eligible when its parent is eligible for the same stay.
        if (plan.getSourceType() == RateSourceType.DERIVED && plan.getParentRatePlan() != null) {
            Result parent = evaluate(plan.getParentRatePlan(), checkIn, checkOut, adults, children, extraBeds, false);
            if (!parent.eligible())
                return Result.no("Parent plan not eligible: " + parent.reason());
        }

        // Inventory availability (skipped in booking mode — already confirmed under lock).
        if (checkInventory) {
            long available = inventoryRepo.countNightsWithSufficientInventory(room.getId(), checkIn, checkOut, 1);
            if (available < nights)
                return Result.no("No inventory available for the selected dates");
        }

        return Result.ok();
    }
}
