import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_inventory_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';

/// How one room-night may be sold, derived **only** from fields the backend
/// sends.
///
/// The names come from `HotelSearchService.isRoomAvailable` and
/// `RoomInventoryRepository.countNightsWithSufficientInventory`, which together
/// are the only definition of "available" the product has:
///
/// ```java
/// if (inventories.size() < nights)                     return false; // → noRecord
/// if (inv.getAvailableInventory() < roomCount)         return false; // → soldOut
/// if (inv.isStopSell())                                return false; // → stopSell
/// if (date.equals(checkIn)  && inv.isClosedArrival())  return false; // arrival only
/// if (date.equals(lastNight)&& inv.isClosedDeparture())return false; // last night only
/// ```
///
/// "Has stock", "sellable tonight", "may start a stay" and "may end a stay" are
/// therefore four different questions, and the calendar answers them separately
/// rather than collapsing them into one "available" colour.
enum PartnerNightState {
  /// No `RoomInventory` row exists for this date.
  ///
  /// **This is not "available by default".** The availability check counts rows
  /// and rejects the stay when fewer rows than nights come back, so a missing
  /// day makes every stay covering it unbookable.
  noRecord,

  /// `stopSell = true` — the night is withheld from sale regardless of stock.
  stopSell,

  /// `availableInventory == 0` with no stop-sell — nothing left to sell.
  soldOut,

  /// `availableInventory > 0 && !stopSell` — sellable for this night.
  open;

  /// Whether a stay may include this night at all. Arrival and departure
  /// restrictions are asked separately — see [PartnerCalendarCell].
  bool get isSellable => this == PartnerNightState.open;
}

/// One room-night in the grid.
///
/// A thin projection over C4's [PartnerInventoryDay]; it introduces **no second
/// inventory model** and stores no numbers of its own beyond what the day
/// already carries. [day] is null exactly when the backend returned no row for
/// this date.
@immutable
class PartnerCalendarCell {
  final int roomId;
  final DateTime date;
  final PartnerInventoryDay? day;

  const PartnerCalendarCell({
    required this.roomId,
    required this.date,
    this.day,
  });

  PartnerNightState get state {
    final d = day;
    if (d == null) return PartnerNightState.noRecord;
    if (d.stopSell) return PartnerNightState.stopSell;
    if (d.availableInventory <= 0) return PartnerNightState.soldOut;
    return PartnerNightState.open;
  }

  /// Whether a stay could **begin** on this night. `closedArrival` is checked by
  /// the backend only against the stay's `checkIn` date.
  bool get canStartStay => state.isSellable && !(day?.closedArrival ?? false);

  /// Whether a stay could **end** with this night — i.e. whether this may be the
  /// last night before check-out. `closedDeparture` is checked by the backend
  /// only against `checkOut - 1`, so it restricts the final *night*, not the
  /// departure date itself.
  bool get canEndStay => state.isSellable && !(day?.closedDeparture ?? false);

  /// Rooms the backend records as sold for this night.
  ///
  /// `RoomInventoryRepository.decrementInventory` moves quantity from
  /// `availableInventory` into `soldInventory` across `[checkIn, checkOut)` when
  /// a booking is created, and `restoreInventory` reverses it on cancellation.
  /// This is therefore the backend's **own** per-night occupancy figure — the
  /// calendar never infers occupancy by matching booking rows to dates.
  int get sold => day?.soldInventory ?? 0;

  bool get isOccupied => sold > 0;

  bool get hasRestriction => day?.hasRestriction ?? false;

  /// True when the row's parts do not add up to its total — surfaced, never
  /// silently corrected. C4 owns the same check.
  bool get isInconsistent => day?.isInconsistent ?? false;
}

/// One room's row across the visible window.
@immutable
class PartnerCalendarRow {
  final PartnerRoom room;
  final List<PartnerCalendarCell> cells;

  /// Set when this room's calendar request failed; the row is then rendered as
  /// unknown rather than as empty, which would read as "no inventory".
  final ApiErrorKind? errorKind;

  const PartnerCalendarRow({
    required this.room,
    required this.cells,
    this.errorKind,
  });

  bool get hasError => errorKind != null;

  int get sellableNights => cells.where((c) => c.state.isSellable).length;
  int get missingNights =>
      cells.where((c) => c.state == PartnerNightState.noRecord).length;
  int get restrictedNights => cells.where((c) => c.hasRestriction).length;
  int get occupiedNights => cells.where((c) => c.isOccupied).length;
}

/// Where the calendar module stands.
enum PartnerCalendarStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — no partner profile, or the property is not the caller's.
  notFound,
  error,
}

/// State for the Partner property calendar (C9).
///
/// ## What this owns, and what it deliberately does not
///
/// It orchestrates a **multi-room, multi-day view**: the date window, the rooms
/// on show, one [PartnerInventoryCalendar] per room, and the selected cell. It
/// is **not** a second inventory store: every number comes from C4's
/// [PartnerInventoryDay], fetched through C4's existing
/// `ApiClient.getPartnerInventory`. C9 adds no endpoint and no parsing.
///
/// It performs **no mutation at all**. Stop-sell, closed-to-arrival and
/// closed-to-departure already have controls in the C4 Inventory view, and
/// duplicating them here would mean two code paths writing the same rows.
/// Numeric inventory editing is withheld on purpose: `RoomInventory` carries no
/// `@Version`, so two partners editing the same row would silently overwrite one
/// another. (The *booking* path is safe — `BookingService.create` takes a
/// pessimistic `SELECT … FOR UPDATE` over the exact rows — but that lock does
/// not protect partner edits.)
///
/// ## Request shape
///
/// The backend exposes only a per-room calendar
/// (`GET /api/partner/calendar/rooms/{roomId}`). There is a multi-room query in
/// `RoomInventoryRepository`, but only `PartnerAnalyticsService` uses it and no
/// controller exposes it — so a property with N rooms costs **N requests per
/// window**, issued concurrently, not N×days. Reported as a scalability note
/// rather than worked around by inventing an endpoint.
class PartnerCalendarState extends ChangeNotifier {
  final ApiClient api;

  /// How many days the grid shows at once.
  static const int windowDays = 14;

  PartnerCalendarState({required this.api});

  PartnerCalendarStatus _status = PartnerCalendarStatus.idle;
  String? _errorMessage;

  List<PartnerRoom> _rooms = const [];
  List<PartnerCalendarRow> _rows = const [];
  int? _loadedPropertyId;

  DateTime _windowStart = _today();
  PartnerCalendarCell? _selectedCell;

  int _loadToken = 0;

  PartnerCalendarStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PartnerRoom> get rooms => List.unmodifiable(_rooms);
  List<PartnerCalendarRow> get rows => List.unmodifiable(_rows);
  int? get loadedPropertyId => _loadedPropertyId;
  PartnerCalendarCell? get selectedCell => _selectedCell;

  bool get isLoading => _status == PartnerCalendarStatus.loading;
  bool get isReady => _status == PartnerCalendarStatus.ready;
  bool get isRetryable => _status == PartnerCalendarStatus.error;

  /// The property has no rooms, so there is nothing to schedule.
  bool get hasNoRooms => isReady && _rooms.isEmpty;

  /// Rooms exist but not one of them returned a single inventory row in this
  /// window — a real answer, and a different one from "no rooms".
  bool get isWindowEmpty =>
      isReady &&
      _rooms.isNotEmpty &&
      _rows.every(
          (r) => r.cells.every((c) => c.state == PartnerNightState.noRecord));

  DateTime get windowStart => _windowStart;

  /// Inclusive end of the window. The backend's `from`/`to` are inclusive on
  /// both ends (`BETWEEN :from AND :to`), so the last day shown is the last day
  /// requested.
  DateTime get windowEnd =>
      _windowStart.add(const Duration(days: windowDays - 1));

  /// The visible days, in order.
  List<DateTime> get days => [
        for (var i = 0; i < windowDays; i++)
          _windowStart.add(Duration(days: i)),
      ];

  bool isToday(DateTime date) => _isSameDay(date, _today());

  /// Whether the window currently includes today.
  bool get showsToday {
    final today = _today();
    return !today.isBefore(_windowStart) && !today.isAfter(windowEnd);
  }

  /// Loads the rooms of [propertyId] and one calendar per room.
  ///
  /// A property change discards the previous property's rooms, rows and cell
  /// selection before anything is requested, so no stale schedule can be shown
  /// and no stale room id can be sent.
  Future<void> load(PartnerState partner, int? propertyId) async {
    final token = ++_loadToken;
    _status = PartnerCalendarStatus.loading;
    _errorMessage = null;
    if (propertyId != _loadedPropertyId) {
      _rooms = const [];
      _rows = const [];
      _selectedCell = null;
    }
    notifyListeners();

    final authorized =
        propertyId != null && partner.properties.any((p) => p.id == propertyId);
    if (!authorized) {
      // Nothing is requested for a property the workspace does not list — an
      // unowned id must never reach the wire.
      _rooms = const [];
      _rows = const [];
      _selectedCell = null;
      _loadedPropertyId = propertyId;
      _status = PartnerCalendarStatus.ready;
      notifyListeners();
      return;
    }

    final roomsResult = await api.getPartnerRooms(propertyId);
    if (token != _loadToken) return;

    if (!roomsResult.success) {
      _rooms = const [];
      _rows = const [];
      _selectedCell = null;
      _status = switch (roomsResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerCalendarStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerCalendarStatus.forbidden,
        ApiErrorKind.notFound => PartnerCalendarStatus.notFound,
        _ => PartnerCalendarStatus.error,
      };
      _errorMessage = roomsResult.message;
      notifyListeners();
      return;
    }

    _rooms = roomsResult.data ?? const [];
    _loadedPropertyId = propertyId;

    if (_rooms.isEmpty) {
      _rows = const [];
      _selectedCell = null;
      _status = PartnerCalendarStatus.ready;
      notifyListeners();
      return;
    }

    await _loadRows(token);
  }

  /// Re-reads every visible room for the current window.
  Future<void> refresh(PartnerState partner) =>
      load(partner, _loadedPropertyId);

  /// Fetches one calendar per room, concurrently.
  ///
  /// Each room is independent: one room failing leaves its row marked with the
  /// failure instead of blanking the whole grid, because an empty row and a
  /// failed row mean very different things to an operator.
  Future<void> _loadRows(int token) async {
    final from = _windowStart;
    final to = windowEnd;

    final results = await Future.wait([
      for (final room in _rooms)
        api.getPartnerInventory(roomId: room.id, from: from, to: to),
    ]);
    if (token != _loadToken) return;

    final rows = <PartnerCalendarRow>[];
    for (var i = 0; i < _rooms.length; i++) {
      final room = _rooms[i];
      final result = results[i];
      if (!result.success || result.data == null) {
        rows.add(PartnerCalendarRow(
          room: room,
          cells: const [],
          errorKind: result.errorKind ?? ApiErrorKind.network,
        ));
        continue;
      }
      rows.add(PartnerCalendarRow(
        room: room,
        cells: _cellsFor(room.id, result.data!),
      ));
    }

    _rows = List.unmodifiable(rows);
    // A selection from the previous window or property no longer exists.
    final selected = _selectedCell;
    if (selected != null && !_stillVisible(selected)) _selectedCell = null;

    _status = PartnerCalendarStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  /// Maps the returned rows onto the visible days.
  ///
  /// The response contains **only days that exist** — `getCalendar` does not
  /// fill gaps — so every day without a row becomes a
  /// [PartnerNightState.noRecord] cell rather than being omitted, which is what
  /// keeps every row the same width and tells the truth about missing days.
  List<PartnerCalendarCell> _cellsFor(
    int roomId,
    PartnerInventoryCalendar calendar,
  ) {
    final byDate = <String, PartnerInventoryDay>{
      for (final day in calendar.days) _key(day.date): day,
    };
    return [
      for (final date in days)
        PartnerCalendarCell(
          roomId: roomId,
          date: date,
          day: byDate[_key(date)],
        ),
    ];
  }

  bool _stillVisible(PartnerCalendarCell cell) =>
      _rooms.any((r) => r.id == cell.roomId) &&
      days.any((d) => _isSameDay(d, cell.date));

  /// Moves the window by whole weeks, keeping the day-of-week alignment stable
  /// so columns do not shuffle under the operator.
  Future<void> shiftWeeks(PartnerState partner, int weeks) {
    _windowStart = _windowStart.add(Duration(days: 7 * weeks));
    _selectedCell = null;
    return _reloadWindow(partner);
  }

  Future<void> goToToday(PartnerState partner) {
    final today = _today();
    if (_isSameDay(today, _windowStart)) return Future<void>.value();
    _windowStart = today;
    _selectedCell = null;
    return _reloadWindow(partner);
  }

  Future<void> _reloadWindow(PartnerState partner) async {
    if (_rooms.isEmpty) {
      notifyListeners();
      return load(partner, _loadedPropertyId);
    }
    final token = ++_loadToken;
    _status = PartnerCalendarStatus.loading;
    notifyListeners();
    await _loadRows(token);
  }

  /// Opens one room-night. Refuses a cell outside the loaded grid.
  void selectCell(int roomId, DateTime date) {
    for (final row in _rows) {
      if (row.room.id != roomId) continue;
      for (final cell in row.cells) {
        if (!_isSameDay(cell.date, date)) continue;
        _selectedCell = cell;
        notifyListeners();
        return;
      }
    }
  }

  void clearSelection() {
    if (_selectedCell == null) return;
    _selectedCell = null;
    notifyListeners();
  }

  PartnerRoom? roomFor(int roomId) {
    for (final room in _rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  // ── Window totals, counted from the loaded cells only ──────────────────

  int get totalSellableNights =>
      _rows.fold(0, (sum, row) => sum + row.sellableNights);
  int get totalMissingNights =>
      _rows.fold(0, (sum, row) => sum + row.missingNights);
  int get totalRestrictedNights =>
      _rows.fold(0, (sum, row) => sum + row.restrictedNights);
  int get totalOccupiedNights =>
      _rows.fold(0, (sum, row) => sum + row.occupiedNights);

  /// How many room calendars failed in the current window.
  int get failedRooms => _rows.where((r) => r.hasError).length;

  void reset() {
    _loadToken++;
    _status = PartnerCalendarStatus.idle;
    _errorMessage = null;
    _rooms = const [];
    _rows = const [];
    _loadedPropertyId = null;
    _windowStart = _today();
    _selectedCell = null;
    notifyListeners();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _key(DateTime date) => '${date.year}-${date.month}-${date.day}';
}
