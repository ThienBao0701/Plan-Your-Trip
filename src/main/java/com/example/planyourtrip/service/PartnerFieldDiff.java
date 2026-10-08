package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.HotelRoomDto.HotelRoomRequest;
import com.example.planyourtrip.dto.RoomInventoryDto.RoomInventoryRequest;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.security.rbac.PartnerPermission;

import java.math.BigDecimal;
import java.util.EnumSet;
import java.util.Objects;
import java.util.Set;

/**
 * RBAC R3b — B9 field-diff for the two mixed-payload endpoints (RBAC V1.1 §24 B9, G10).
 *
 * <p>The permission a write needs is decided by the fields it actually changes, compared with the stored value —
 * never by which fields the client happened to send, and never by a blanket permission for the whole payload:
 * <ul>
 *   <li>{@code PUT /rooms/{roomId}} (a full replace): P23 if a content field differs, P24 if a commercial field
 *       differs, P25 if the {@code active} switch differs;</li>
 *   <li>calendar {@code PUT …/{date}} and {@code POST …/bulk}: P27 if a count differs, P28 if a restriction flag
 *       differs ({@code soldInventory} is not partner-editable at all).</li>
 * </ul>
 * An empty result means the write changes nothing; the caller then needs any one of the endpoint's permissions.
 */
public final class PartnerFieldDiff {

    private PartnerFieldDiff() {}

    /** The permissions {@code req} needs against the stored room and its stored amenity slugs. */
    public static Set<PartnerPermission> room(HotelRoom stored, Set<String> storedAmenitySlugs, HotelRoomRequest req,
                                              Set<String> requestedAmenitySlugs) {
        EnumSet<PartnerPermission> needed = EnumSet.noneOf(PartnerPermission.class);
        boolean content = !Objects.equals(stored.getRoomName(), req.roomName())
            || !Objects.equals(stored.getRoomCode(), req.roomCode())
            || stored.getRoomType() != req.roomType()
            || !Objects.equals(stored.getDescription(), req.description())
            || stored.getBedType() != req.bedType()
            || !Objects.equals(stored.getBedCount(), req.bedCount())
            || !Objects.equals(stored.getMaxAdults(), req.maxAdults())
            || !Objects.equals(stored.getMaxChildren(), req.maxChildren())
            || !Objects.equals(stored.getMaxGuests(), req.maxGuests())
            || !Objects.equals(stored.getRoomSizeSqm(), req.roomSizeSqm())
            || !Objects.equals(stored.getFloorNumber(), req.floorNumber())
            || stored.isSmokingAllowed() != req.smokingAllowed()
            || !storedAmenitySlugs.equals(requestedAmenitySlugs);
        boolean commercial = !sameAmount(stored.getPriceFrom(), req.priceFrom())
            || !sameAmount(stored.getOriginalPrice(), req.originalPrice())
            || !Objects.equals(stored.getQuantity(), req.quantity())
            || !Objects.equals(stored.getAvailableQuantity(), req.availableQuantity())
            || stored.isFreeCancellation() != req.freeCancellation()
            || stored.isBreakfastIncluded() != req.breakfastIncluded()
            || stored.isInstantConfirmation() != req.instantConfirmation();
        if (content) needed.add(PartnerPermission.ROOM_CONTENT_EDIT);
        if (commercial) needed.add(PartnerPermission.ROOM_COMMERCIAL_EDIT);
        if (req.active() != null && req.active() != stored.isActive()) needed.add(PartnerPermission.ROOM_STATUS_TOGGLE);
        return needed;
    }

    /**
     * The permissions one calendar day of {@code req} needs against the stored day, or against an empty day (all
     * counts 0, no restriction) when the day does not exist yet.
     */
    public static Set<PartnerPermission> inventoryDay(RoomInventory stored, RoomInventoryRequest req) {
        EnumSet<PartnerPermission> needed = EnumSet.noneOf(PartnerPermission.class);
        int total = stored == null ? 0 : stored.getTotalInventory();
        int available = stored == null ? 0 : stored.getAvailableInventory();
        int blocked = stored == null ? 0 : stored.getBlockedInventory();
        int maintenance = stored == null ? 0 : stored.getMaintenanceInventory();
        boolean stopSell = stored != null && stored.isStopSell();
        boolean closedArrival = stored != null && stored.isClosedArrival();
        boolean closedDeparture = stored != null && stored.isClosedDeparture();
        if (total != req.totalInventory() || available != req.availableInventory()
                || blocked != req.blockedInventory() || maintenance != req.maintenanceInventory()) {
            needed.add(PartnerPermission.INVENTORY_ALLOTMENT_EDIT);
        }
        if (stopSell != req.stopSell() || closedArrival != req.closedArrival()
                || closedDeparture != req.closedDeparture()) {
            needed.add(PartnerPermission.INVENTORY_RESTRICTION_EDIT);
        }
        return needed;
    }

    private static boolean sameAmount(BigDecimal a, BigDecimal b) {
        if (a == null || b == null) return a == b;
        return a.compareTo(b) == 0;
    }
}
