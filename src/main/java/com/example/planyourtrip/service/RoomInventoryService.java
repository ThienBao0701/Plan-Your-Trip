package com.example.planyourtrip.service;

import com.example.planyourtrip.dto.RoomInventoryDto.*;
import com.example.planyourtrip.exception.ApiException;
import com.example.planyourtrip.model.HotelRoom;
import com.example.planyourtrip.model.RoomInventory;
import com.example.planyourtrip.repository.HotelRoomRepository;
import com.example.planyourtrip.repository.RoomInventoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Room-inventory reads and numeric writes.
 *
 * <h2>H-FIX 1 — concurrency strategy: pessimistic, matching the booking path</h2>
 *
 * {@code BookingService} reserves inventory by taking {@link RoomInventoryRepository#lockForUpdate}
 * (a {@code SELECT ... FOR UPDATE} over the exact night rows, ordered by date) and then issuing the
 * bulk {@code decrementInventory} / {@code restoreInventory} JPQL updates. Before this fix the write
 * paths below read the same rows with a plain finder and overwrote every counter, taking no lock —
 * so a partner or admin saving a calendar could silently erase a booking's decrement (lost update,
 * i.e. oversell). A lock only protects data when <em>every</em> writer takes it.
 *
 * <p><strong>Why not {@code @Version} instead.</strong> Optimistic locking would not have worked
 * here: the booking path mutates inventory through {@code @Modifying} bulk JPQL, which bypasses the
 * persistence context and therefore never increments a version column. A stale writer's version
 * would still match and the clobber would still commit. Adding {@code @Version} would have looked
 * like a fix while changing nothing. These writes now take the <em>same</em> pessimistic lock as the
 * booking path, in the same deterministic {@code inventoryDate} order, so the two serialize on the
 * database rows themselves and cannot deadlock against each other.
 *
 * <h2>H-FIX 1B — {@code soldInventory} is booking-derived</h2>
 *
 * {@code soldInventory} is only ever moved by {@code decrementInventory} / {@code restoreInventory},
 * which trade units against {@code availableInventory}. It is authoritative booking state, not an
 * operator-editable field, so {@link Authority#PARTNER} writes may not change it — see
 * {@link #resolveSold}.
 *
 * <h2>H-FIX 1C — the invariant</h2>
 *
 * The counters may not over-allocate the room; see {@link #validateCounts}.
 */
@Service
@Transactional(readOnly = true)
public class RoomInventoryService {

    /**
     * Who is performing a numeric write, which decides whether {@code soldInventory} may change.
     *
     * <p>{@link #ADMIN} keeps the pre-existing behaviour of the admin inventory endpoints, which are
     * a data-administration surface and must retain the ability to correct a sold count.
     * {@link #PARTNER} is the extranet calendar, where sold is read-only.
     */
    public enum Authority { ADMIN, PARTNER }

    private final RoomInventoryRepository inventoryRepo;
    private final HotelRoomRepository roomRepo;
    private final AdminActivityLogService adminAudit;

    public RoomInventoryService(RoomInventoryRepository inventoryRepo,
                                 HotelRoomRepository roomRepo,
                                 AdminActivityLogService adminAudit) {
        this.inventoryRepo = inventoryRepo;
        this.roomRepo      = roomRepo;
        this.adminAudit    = adminAudit;
    }

    // ── D3H · audited administrative writes ───────────────────────────────────
    //
    // Inventory is the one surface on this service where the two audiences already diverge, and the
    // audit follows that existing seam rather than inventing a new one. The Authority overloads
    // below are shared: PartnerCalendarService reaches update(..., PARTNER) and
    // bulkUpsert(..., PARTNER) for a partner's own calendar, so recording in those bodies would
    // file partner calendar work as administrative activity. These wrappers are the admin entry
    // points and are the only place an admin actor is known.
    //
    // Counters are small bounded ints and dates, so they are safe to record verbatim; there is no
    // operator free text on this surface at all.

    @Transactional
    public RoomInventoryResponse adminCreate(Long adminUserId, Long roomId, RoomInventoryRequest req) {
        RoomInventoryResponse created = create(roomId, req);
        adminAudit.record(adminUserId, "ROOM_INVENTORY_CREATE", "ROOM_INVENTORY", created.id(),
            "Admin created inventory for room " + roomId + " on " + created.inventoryDate(),
            null, summarise(created));
        return created;
    }

    @Transactional
    public RoomInventoryResponse adminUpdate(Long adminUserId, Long roomId, LocalDate date,
                                              RoomInventoryRequest req) {
        // Snapshot before the lock-read-modify-write below mutates the managed row. toResponse
        // yields a record of copies, so this string cannot drift under us.
        String before = inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date)
            .map(inv -> summarise(toResponse(inv))).orElse(null);
        RoomInventoryResponse updated = update(roomId, date, req, Authority.ADMIN);
        adminAudit.record(adminUserId, "ROOM_INVENTORY_UPDATE", "ROOM_INVENTORY", updated.id(),
            "Admin updated inventory for room " + roomId + " on " + date, before, summarise(updated));
        return updated;
    }

    @Transactional
    public List<RoomInventoryResponse> adminBulkUpsert(Long adminUserId, Long roomId,
                                                        BulkInventoryRequest req) {
        List<RoomInventoryResponse> saved = bulkUpsert(roomId, req, Authority.ADMIN);
        // A bulk save has no single mutated child row, so the target is the room whose calendar was
        // rewritten — the object an investigator would actually look up. Naming one arbitrary
        // RoomInventory id out of N would be a worse answer than naming the room. The affected span
        // and row count go in the description; the per-row detail stays in the calendar itself.
        LocalDate first = saved.stream().map(RoomInventoryResponse::inventoryDate)
            .filter(java.util.Objects::nonNull).min(LocalDate::compareTo).orElse(null);
        LocalDate last = saved.stream().map(RoomInventoryResponse::inventoryDate)
            .filter(java.util.Objects::nonNull).max(LocalDate::compareTo).orElse(null);
        adminAudit.record(adminUserId, "ROOM_INVENTORY_BULK_UPSERT", "HOTEL_ROOM", roomId,
            "Admin bulk-upserted " + saved.size() + " inventory day(s) for room " + roomId
                + (first == null ? "" : " covering " + first + ".." + last),
            null, "days:" + saved.size() + " window:" + first + ".." + last);
        return saved;
    }

    /** Bounded counters and flags only — this surface carries no operator-supplied text. */
    private static String summarise(RoomInventoryResponse r) {
        return "date:" + r.inventoryDate()
            + " total:" + r.totalInventory()
            + " available:" + r.availableInventory()
            + " blocked:" + r.blockedInventory()
            + " sold:" + r.soldInventory()
            + " maintenance:" + r.maintenanceInventory()
            + " stopSell:" + r.stopSell()
            + " closedArrival:" + r.closedArrival()
            + " closedDeparture:" + r.closedDeparture();
    }

    public InventoryCalendarResponse getCalendar(Long roomId,
                                                  LocalDate from,
                                                  LocalDate to) {
        HotelRoom room = roomOrThrow(roomId);
        List<RoomInventory> records = (from != null && to != null)
            ? inventoryRepo.findBetweenDates(roomId, from, to)
            : inventoryRepo.findByHotelRoomIdOrderByInventoryDateAsc(roomId);
        return new InventoryCalendarResponse(
            roomId, room.getRoomCode(), room.getRoomName(),
            records.stream().map(this::toResponse).toList()
        );
    }

    @Transactional
    public RoomInventoryResponse create(Long roomId, RoomInventoryRequest req) {
        roomOrThrow(roomId);
        // A row that does not exist yet has no sold units; ADMIN may seed a non-zero count.
        validateCounts(req, req.soldInventory());
        if (inventoryRepo.existsByHotelRoomIdAndInventoryDate(roomId, req.inventoryDate())) {
            throw new ApiException(HttpStatus.CONFLICT,
                "Inventory already exists for room " + roomId + " on " + req.inventoryDate());
        }
        HotelRoom room = roomOrThrow(roomId);
        RoomInventory inv = new RoomInventory();
        inv.setHotelRoom(room);
        fill(inv, req, req.soldInventory());
        return toResponse(inventoryRepo.save(inv));
    }

    /** Admin numeric write — {@code soldInventory} remains writable. */
    @Transactional
    public RoomInventoryResponse update(Long roomId, LocalDate date, RoomInventoryRequest req) {
        return update(roomId, date, req, Authority.ADMIN);
    }

    @Transactional
    public RoomInventoryResponse update(Long roomId, LocalDate date, RoomInventoryRequest req,
                                         Authority authority) {
        roomOrThrow(roomId);
        // Lock BEFORE the read so the read-modify-write below is atomic against a concurrent
        // booking decrement over the same night. Half-open [date, date+1) matches the booking
        // path's own window, so both contend on exactly the same row.
        inventoryRepo.lockForUpdate(roomId, date, date.plusDays(1));
        RoomInventory inv = inventoryRepo.findByHotelRoomIdAndInventoryDate(roomId, date)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND,
                "Inventory not found for room " + roomId + " on " + date));
        int sold = resolveSold(req, inv.getSoldInventory(), authority);
        validateCounts(req, sold);
        fill(inv, req, sold);
        return toResponse(inventoryRepo.save(inv));
    }

    /** Admin bulk upsert — {@code soldInventory} remains writable. */
    @Transactional
    public List<RoomInventoryResponse> bulkUpsert(Long roomId, BulkInventoryRequest req) {
        return bulkUpsert(roomId, req, Authority.ADMIN);
    }

    @Transactional
    public List<RoomInventoryResponse> bulkUpsert(Long roomId, BulkInventoryRequest req,
                                                   Authority authority) {
        HotelRoom room = roomOrThrow(roomId);

        // Lock the whole requested span up front, in one deterministic date-ordered statement, so a
        // multi-date save cannot interleave with a booking mid-way and cannot deadlock against it.
        // Rows that do not exist yet cannot be locked; those are protected instead by the
        // uk_room_inventory_date unique constraint, which turns a concurrent double-insert into a
        // constraint violation rather than a duplicate row.
        req.items().stream().map(RoomInventoryRequest::inventoryDate)
            .filter(java.util.Objects::nonNull)
            .min(LocalDate::compareTo)
            .ifPresent(min -> {
                LocalDate max = req.items().stream().map(RoomInventoryRequest::inventoryDate)
                    .filter(java.util.Objects::nonNull)
                    .max(LocalDate::compareTo).orElse(min);
                inventoryRepo.lockForUpdate(roomId, min, max.plusDays(1));
            });

        List<RoomInventoryResponse> results = new ArrayList<>();
        for (RoomInventoryRequest item : req.items()) {
            RoomInventory inv = inventoryRepo
                .findByHotelRoomIdAndInventoryDate(roomId, item.inventoryDate())
                .orElseGet(() -> {
                    RoomInventory fresh = new RoomInventory();
                    fresh.setHotelRoom(room);
                    return fresh;
                });
            // A row being created here has no sold units yet, so 0 is its authoritative value.
            int persistedSold = inv.getId() == null ? 0 : inv.getSoldInventory();
            int sold = resolveSold(item, persistedSold, authority);
            validateCounts(item, sold);
            fill(inv, item, sold);
            results.add(toResponse(inventoryRepo.save(inv)));
        }
        return results;
    }

    /**
     * Decides the {@code soldInventory} a write will persist.
     *
     * <p>{@link Authority#ADMIN} may set it. {@link Authority#PARTNER} may not: the value is derived
     * from bookings, so the persisted count always wins. A partner request that echoes the correct
     * current value succeeds unchanged — which is what a read-modify-write of a fresh calendar does.
     * A request carrying a <em>different</em> value is rejected with 409 rather than silently
     * ignored, because the only ways to produce one are a stale read (exactly the lost-update the
     * lock above prevents) or an attempt to edit booking state; both deserve to be told, not
     * quietly discarded.
     */
    private int resolveSold(RoomInventoryRequest req, int persistedSold, Authority authority) {
        if (authority == Authority.ADMIN) return req.soldInventory();
        if (req.soldInventory() != persistedSold) {
            throw new ApiException(HttpStatus.CONFLICT,
                "soldInventory is derived from bookings and cannot be modified here; "
                    + "the current value for " + req.inventoryDate() + " is " + persistedSold
                    + ". Re-read the calendar and resubmit.");
        }
        return persistedSold;
    }

    private void fill(RoomInventory inv, RoomInventoryRequest req, int sold) {
        inv.setInventoryDate(req.inventoryDate());
        inv.setTotalInventory(req.totalInventory());
        inv.setAvailableInventory(req.availableInventory());
        inv.setBlockedInventory(req.blockedInventory());
        inv.setSoldInventory(sold);
        inv.setMaintenanceInventory(req.maintenanceInventory());
        inv.setStopSell(req.stopSell());
        inv.setClosedArrival(req.closedArrival());
        inv.setClosedDeparture(req.closedDeparture());
    }

    /**
     * Enforces the counter invariant: the four counters may not <em>over-allocate</em> the room.
     *
     * <p>{@code available + sold + blocked + maintenance <= total}.
     *
     * <p>The bound is {@code <=} rather than {@code ==}, and that distinction was settled by reading
     * the domain rather than by assumption. Equality holds for every seeded row
     * ({@code 18 + 0 + 1 + 1 == 20}) and is conserved by the booking path, because
     * {@code decrementInventory} / {@code restoreInventory} only trade units between
     * {@code available} and {@code sold}. But equality is <em>not</em> a rule the system actually
     * imposes: provisioning legitimately writes a night as {@code total=3, available=1} with the
     * other counters at zero, meaning "three units exist, one is currently sellable" and leaving the
     * remainder simply unaccounted. Demanding equality would reject that valid operation.
     *
     * <p>What must never be allowed is the opposite direction. Before this fix each counter was only
     * bounded individually, so {@code total=20} with all four counters at {@code 20} — sum 80 —
     * was accepted, describing a room whose parts claim four times its own capacity. That is the
     * over-allocation this check now rejects; under-allocation is wasteful but never oversells.
     *
     * <p>{@code sold} is passed in rather than read from {@code req} because for a partner write it
     * is the persisted value, not the submitted one, that will be stored.
     */
    private void validateCounts(RoomInventoryRequest req, int sold) {
        int total = req.totalInventory();
        List<String> errors = new ArrayList<>();
        if (req.availableInventory()   > total) errors.add("availableInventory exceeds totalInventory");
        if (req.blockedInventory()     > total) errors.add("blockedInventory exceeds totalInventory");
        if (sold                       > total) errors.add("soldInventory exceeds totalInventory");
        if (req.maintenanceInventory() > total) errors.add("maintenanceInventory exceeds totalInventory");
        if (errors.isEmpty()) {
            int sum = req.availableInventory() + sold
                + req.blockedInventory() + req.maintenanceInventory();
            if (sum > total) {
                errors.add("availableInventory + soldInventory + blockedInventory + "
                    + "maintenanceInventory must not exceed totalInventory (got " + sum
                    + " vs totalInventory " + total + ")");
            }
        }
        if (!errors.isEmpty()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, String.join("; ", errors));
        }
    }

    RoomInventoryResponse toResponse(RoomInventory inv) {
        return new RoomInventoryResponse(
            inv.getId(),
            inv.getHotelRoom().getId(),
            inv.getInventoryDate(),
            inv.getTotalInventory(),
            inv.getAvailableInventory(),
            inv.getBlockedInventory(),
            inv.getSoldInventory(),
            inv.getMaintenanceInventory(),
            inv.isStopSell(),
            inv.isClosedArrival(),
            inv.isClosedDeparture(),
            inv.getCreatedAt(),
            inv.getUpdatedAt()
        );
    }

    private HotelRoom roomOrThrow(Long roomId) {
        return roomRepo.findById(roomId)
            .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "Room not found: " + roomId));
    }
}
