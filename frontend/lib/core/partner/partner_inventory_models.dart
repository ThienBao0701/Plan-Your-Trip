/// Typed models for the Partner Inventory module (C4), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree and verified
/// against the running backend:
///   * `controller/PartnerCalendarController` — `/api/partner/calendar/**`
///     (the backend calls this surface **calendar**, not "inventory")
///   * `dto/RoomInventoryDto.InventoryCalendarResponse` / `RoomInventoryResponse`
///   * `service/RoomInventoryService`, `repository/RoomInventoryRepository`
///
/// ## Semantics that are easy to get wrong, established from source + live probe
///
/// **Date range is inclusive on BOTH ends.** `findBetweenDates` is
/// `inventoryDate BETWEEN :from AND :to`. Verified live: `from=to` returns 1
/// row, Aug 29→31 returns 3, Aug 29→Sep 4 returns 7. Note this differs from the
/// *booking* queries in the same repository, which use `>= checkIn AND <
/// checkOut` (half-open nights) — the calendar is not a night range.
///
/// **A partial range is silently ignored.** `getCalendar` only applies the range
/// when *both* `from` and `to` are non-null; supplying one returns the room's
/// entire history. The client therefore always sends both or neither.
///
/// **An inverted range is not an error.** `from > to` returns HTTP 200 with an
/// empty list, which would read as "no inventory". The client validates the
/// range itself rather than showing that as an empty state.
///
/// **The five quantities are stored, not derived.** `totalInventory`,
/// `availableInventory`, `blockedInventory`, `soldInventory` and
/// `maintenanceInventory` are five independent columns. The backend validates
/// only that each is `<= total` — it does **not** require them to sum to total,
/// so they can be internally inconsistent and the UI must not present a
/// computed remainder as fact.
///
/// **These are NOT the room record's quantities.** `HotelRoomResponse.quantity`
/// / `availableQuantity` (C3) are separate columns on `HotelRoom` and carry
/// different values for the same room in live data. The two models are never
/// mixed.
library;

/// One day of inventory — `dto/RoomInventoryDto.RoomInventoryResponse`.
///
/// Every numeric field is a primitive `int` in the record, so none is nullable.
class PartnerInventoryDay {
  final int id;
  final int roomId;
  final DateTime date;

  /// Physical rooms of this type on this date.
  final int totalInventory;

  /// Sellable rooms. Maintained by **both** the partner (calendar edits) and the
  /// booking flow — `RoomInventoryRepository.decrementInventory` reduces it and
  /// raises [soldInventory] atomically under a pessimistic lock when a booking
  /// is created, and `restoreInventory` reverses that on cancellation.
  final int availableInventory;

  final int blockedInventory;

  /// Rooms consumed by confirmed bookings. Backend-maintained.
  final int soldInventory;

  final int maintenanceInventory;

  /// Hard close for the date. Checked by `countAvailableNights` /
  /// `countNightsWithSufficientInventory`, so it blocks a stay outright and is
  /// genuinely independent of the quantities.
  final bool stopSell;

  /// Closed to arrival — `HotelSearchService` rejects a stay whose **check-in**
  /// falls on this date. Not a general close.
  final bool closedArrival;

  /// Closed to departure — `HotelSearchService` rejects a stay whose **last
  /// night** falls on this date.
  final bool closedDeparture;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerInventoryDay({
    required this.id,
    required this.roomId,
    required this.date,
    required this.totalInventory,
    required this.availableInventory,
    required this.blockedInventory,
    required this.soldInventory,
    required this.maintenanceInventory,
    required this.stopSell,
    required this.closedArrival,
    required this.closedDeparture,
    this.createdAt,
    this.updatedAt,
  });

  /// Whether a guest can actually book this date, using the backend's own rule:
  /// `availableInventory > 0 AND stopSell = false`
  /// (`RoomInventoryRepository.countAvailableNights`).
  ///
  /// CTA/CTD are deliberately excluded — they constrain *which* stays may start
  /// or end here, not whether the date is sellable at all.
  bool get isBookable => availableInventory > 0 && !stopSell;

  /// Nothing left to sell, as distinct from deliberately closed. Kept separate
  /// from [stopSell] because the two have different causes and different fixes.
  bool get isSoldOut => availableInventory == 0 && !stopSell;

  /// Any restriction is in force for this date.
  bool get hasRestriction => stopSell || closedArrival || closedDeparture;

  /// The four non-available buckets. Presented as a stated figure, never as
  /// "total minus available" — the backend does not guarantee they reconcile.
  int get accountedInventory =>
      availableInventory +
      blockedInventory +
      soldInventory +
      maintenanceInventory;

  /// True when the five stored numbers do not add up. Surfaced as a caution
  /// rather than silently corrected, because only the backend can resolve it.
  bool get isInconsistent => accountedInventory != totalInventory;

  /// A copy with one flag replaced, for folding a PATCH response into the grid.
  PartnerInventoryDay copyWithFlags({
    bool? stopSell,
    bool? closedArrival,
    bool? closedDeparture,
  }) =>
      PartnerInventoryDay(
        id: id,
        roomId: roomId,
        date: date,
        totalInventory: totalInventory,
        availableInventory: availableInventory,
        blockedInventory: blockedInventory,
        soldInventory: soldInventory,
        maintenanceInventory: maintenanceInventory,
        stopSell: stopSell ?? this.stopSell,
        closedArrival: closedArrival ?? this.closedArrival,
        closedDeparture: closedDeparture ?? this.closedDeparture,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static PartnerInventoryDay? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final date = _asDate(json['inventoryDate']);
    if (id == null || date == null) return null;
    return PartnerInventoryDay(
      id: id,
      roomId: _asInt(json['roomId']) ?? 0,
      date: date,
      totalInventory: _asInt(json['totalInventory']) ?? 0,
      availableInventory: _asInt(json['availableInventory']) ?? 0,
      blockedInventory: _asInt(json['blockedInventory']) ?? 0,
      soldInventory: _asInt(json['soldInventory']) ?? 0,
      maintenanceInventory: _asInt(json['maintenanceInventory']) ?? 0,
      stopSell: json['stopSell'] == true,
      closedArrival: json['closedArrival'] == true,
      closedDeparture: json['closedDeparture'] == true,
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// `dto/RoomInventoryDto.InventoryCalendarResponse` — the room's identity plus
/// its inventory rows for the requested window.
class PartnerInventoryCalendar {
  final int roomId;
  final String? roomCode;
  final String? roomName;
  final List<PartnerInventoryDay> days;

  const PartnerInventoryCalendar({
    required this.roomId,
    required this.days,
    this.roomCode,
    this.roomName,
  });

  bool get isEmpty => days.isEmpty;

  int get bookableDays => days.where((d) => d.isBookable).length;
  int get stopSellDays => days.where((d) => d.stopSell).length;
  int get soldOutDays => days.where((d) => d.isSoldOut).length;
  int get inconsistentDays => days.where((d) => d.isInconsistent).length;

  /// Total sellable room-nights across the window — a straight sum of a
  /// backend-supplied field, not a derived business metric.
  int get totalAvailable =>
      days.fold(0, (sum, day) => sum + day.availableInventory);

  static PartnerInventoryCalendar? fromJson(Map<String, dynamic> json) {
    final roomId = _asInt(json['roomId']);
    if (roomId == null) return null;
    final raw = json['inventory'];
    final days = <PartnerInventoryDay>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        final day = PartnerInventoryDay.fromJson(entry);
        if (day != null) days.add(day);
      }
    }
    return PartnerInventoryCalendar(
      roomId: roomId,
      roomCode: _asString(json['roomCode']),
      roomName: _asString(json['roomName']),
      days: List.unmodifiable(days),
    );
  }
}

/// Which per-day flag a toggle targets. Each maps to its own PATCH endpoint.
enum PartnerInventoryFlag { stopSell, closedArrival, closedDeparture }

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// `inventoryDate` is a `LocalDate` — a calendar day with no time or zone.
/// Parsed as a plain local date so it can never shift across a timezone
/// boundary the way `DateTime.parse(...).toLocal()` on an instant would.
DateTime? _asDate(Object? value) {
  if (value is! String) return null;
  final parts = value.split('-');
  if (parts.length < 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2].substring(0, 2));
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

/// `createdAt` / `updatedAt` are true `Instant`s, so these do convert to local.
DateTime? _asInstant(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
