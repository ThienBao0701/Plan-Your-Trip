import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_inventory_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a per-day flag toggle.
enum PartnerInventoryActionResult {
  success,
  unauthorized,
  forbidden,

  /// Uniform 404 — the room is unknown/unowned, **or** the date simply has no
  /// inventory row (only the bulk endpoint creates rows). The backend does not
  /// distinguish these and neither may the UI.
  notFound,
  failed,

  /// May have been committed before the connection dropped.
  uncertain,
}

/// Where the Inventory module stands.
///
/// The chain is property → rooms → calendar, and each link has its own honest
/// stopping point rather than one generic "empty".
enum PartnerInventoryStatus {
  idle,

  /// The workspace authorises no properties.
  noProperties,

  /// A property must be chosen before rooms can be listed.
  noPropertySelected,

  loadingRooms,

  /// The property loaded but has no room types, so there is no calendar to show.
  noRooms,

  /// A room must be chosen.
  noRoomSelected,

  /// The chosen window is invalid (`from` after `to`). Caught client-side
  /// because the backend answers an inverted range with an empty 200.
  invalidRange,

  loading,
  ready,

  unauthorized,
  forbidden,

  /// 404 — the property or room is not available to this account.
  notFound,

  /// Network / timeout / 5xx / malformed. Retryable.
  error,
}

/// The inventory window. Both bounds are **inclusive**, matching
/// `findBetweenDates` (`BETWEEN :from AND :to`).
enum PartnerInventoryRange {
  week(7),
  fortnight(14),
  month(30);

  const PartnerInventoryRange(this.days);

  /// Number of days the window covers, counting both ends.
  final int days;

  /// `[from, to]` starting today. `to` is `from + (days - 1)` so a 7-day window
  /// really is seven rows, not eight.
  ({DateTime from, DateTime to}) resolve([DateTime? now]) {
    final today = now ?? DateTime.now();
    final from = DateTime(today.year, today.month, today.day);
    return (from: from, to: from.add(Duration(days: days - 1)));
  }
}

/// State for the Partner Inventory module.
///
/// Feature-scoped `ChangeNotifier`, same paradigm as C1–C3. It owns the date
/// window, the room filter and the calendar payload. [PartnerState] keeps its
/// single responsibility — workspace identity, team role and the **selected
/// property** — and is neither extended nor duplicated here.
///
/// Room selection lives in this class rather than `PartnerState` deliberately:
/// a room is an inventory-screen concern, whereas the property is workspace
/// context that C2/C3 and later modules all share.
class PartnerInventoryState extends ChangeNotifier {
  final ApiClient api;

  PartnerInventoryState({required this.api});

  PartnerInventoryStatus _status = PartnerInventoryStatus.idle;
  String? _errorMessage;

  List<PartnerRoom> _rooms = const [];
  int? _selectedRoomId;
  int? _loadedPropertyId;

  PartnerInventoryRange _range = PartnerInventoryRange.fortnight;

  /// An explicit window, when one has been set. Overrides [_range].
  ///
  /// The three presets are all forward-looking and can never invert, so without
  /// this seam the [PartnerInventoryStatus.invalidRange] guard would be
  /// unreachable and untestable. A custom window is also the natural next step
  /// for this screen (a partner asking for one specific month); the C4 UI ships
  /// presets only, so today this is exercised by tests and by callers that set
  /// it directly.
  DateTime? _customFrom;
  DateTime? _customTo;

  PartnerInventoryCalendar? _calendar;

  /// The date whose flag is currently being written, so only that row spins.
  DateTime? _pendingDate;
  int _loadToken = 0;

  PartnerInventoryStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PartnerRoom> get rooms => List.unmodifiable(_rooms);
  int? get selectedRoomId => _selectedRoomId;
  int? get loadedPropertyId => _loadedPropertyId;
  PartnerInventoryRange get range => _range;
  PartnerInventoryCalendar? get calendar => _calendar;
  DateTime? get pendingDate => _pendingDate;

  PartnerRoom? get selectedRoom {
    final id = _selectedRoomId;
    if (id == null) return null;
    for (final room in _rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  bool get isLoading =>
      _status == PartnerInventoryStatus.loading ||
      _status == PartnerInventoryStatus.loadingRooms;
  bool get isReady => _status == PartnerInventoryStatus.ready;

  /// The room and window are valid, but the backend holds no rows for them.
  /// A real answer — not an error, and not an invalid range.
  bool get isEmpty => isReady && (_calendar?.isEmpty ?? true);

  bool get isRetryable => _status == PartnerInventoryStatus.error;

  /// The window currently in force — the custom one if set, otherwise the
  /// preset. Both bounds are inclusive.
  ({DateTime from, DateTime to}) get window {
    final from = _customFrom;
    final to = _customTo;
    if (from != null && to != null) return (from: from, to: to);
    return _range.resolve();
  }

  /// True when the window came from [setCustomWindow] rather than a preset.
  bool get hasCustomWindow => _customFrom != null && _customTo != null;

  /// Sets an explicit inclusive window and reloads.
  ///
  /// An inverted window is accepted here and rejected by the load, so the
  /// screen reports [PartnerInventoryStatus.invalidRange] rather than the
  /// misleading empty 200 the backend would return for `from > to`.
  Future<void> setCustomWindow(DateTime from, DateTime to) async {
    _customFrom = DateTime(from.year, from.month, from.day);
    _customTo = DateTime(to.year, to.month, to.day);
    notifyListeners();
    await _loadCalendar(++_loadToken);
  }

  /// Loads the rooms of [propertyId], then the calendar of the selected room.
  ///
  /// [partner] supplies the authorized property list; anything outside it is
  /// refused before a request is made. The backend re-checks regardless — this
  /// simply refuses to ask a question the client has no business asking.
  Future<void> load(PartnerState partner, int? propertyId) async {
    if (partner.properties.isEmpty) {
      _finishWithoutData(PartnerInventoryStatus.noProperties);
      return;
    }
    if (propertyId == null) {
      _finishWithoutData(PartnerInventoryStatus.noPropertySelected);
      return;
    }
    if (!partner.properties.any((p) => p.id == propertyId)) {
      _finishWithoutData(PartnerInventoryStatus.notFound);
      return;
    }

    final token = ++_loadToken;
    final propertyChanged = propertyId != _loadedPropertyId;
    _status = PartnerInventoryStatus.loadingRooms;
    _errorMessage = null;
    if (propertyChanged) {
      // A room id from another property must never survive a property switch.
      _selectedRoomId = null;
      _calendar = null;
      _rooms = const [];
    }
    notifyListeners();

    final roomsResult = await api.getPartnerRooms(propertyId);
    if (token != _loadToken) return;

    if (!roomsResult.success) {
      _rooms = const [];
      _calendar = null;
      _loadedPropertyId = propertyId;
      _status = _statusForError(roomsResult.errorKind);
      _errorMessage = roomsResult.message;
      notifyListeners();
      return;
    }

    _rooms = roomsResult.data ?? const [];
    _loadedPropertyId = propertyId;

    if (_rooms.isEmpty) {
      _calendar = null;
      _selectedRoomId = null;
      _status = PartnerInventoryStatus.noRooms;
      notifyListeners();
      return;
    }

    // Keep a still-valid room selection; otherwise pick the first so a partner
    // with one room never has to choose.
    if (_selectedRoomId == null ||
        !_rooms.any((r) => r.id == _selectedRoomId)) {
      _selectedRoomId = _rooms.first.id;
    }

    await _loadCalendar(token);
  }

  Future<void> _loadCalendar(int token) async {
    final roomId = _selectedRoomId;
    if (roomId == null) {
      _finishWithoutData(PartnerInventoryStatus.noRoomSelected);
      return;
    }

    final resolved = window;
    // The backend answers an inverted range with an empty 200, which would read
    // as "no inventory". Refuse it here instead. Reachable via setCustomWindow;
    // the presets are all forward-looking and cannot invert.
    if (resolved.from.isAfter(resolved.to)) {
      _finishWithoutData(PartnerInventoryStatus.invalidRange);
      return;
    }

    _status = PartnerInventoryStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getPartnerInventory(
      roomId: roomId,
      from: resolved.from,
      to: resolved.to,
    );
    if (token != _loadToken) return;

    if (!result.success) {
      _calendar = null;
      _status = _statusForError(result.errorKind);
      _errorMessage = result.message;
      notifyListeners();
      return;
    }

    _calendar = result.data;
    _status = PartnerInventoryStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  /// Switches room within the loaded property. Ignores any id not in the list.
  Future<void> selectRoom(int roomId) async {
    if (roomId == _selectedRoomId) return;
    if (!_rooms.any((r) => r.id == roomId)) return;
    _selectedRoomId = roomId;
    _calendar = null;
    notifyListeners();
    await _loadCalendar(++_loadToken);
  }

  /// Switches the window and reloads.
  Future<void> selectRange(PartnerInventoryRange next) async {
    if (next == _range && !hasCustomWindow) return;
    _range = next;
    _customFrom = null;
    _customTo = null;
    notifyListeners();
    await _loadCalendar(++_loadToken);
  }

  /// Toggles one per-day flag.
  ///
  /// Only the three boolean flags are writable in C4. The numeric endpoints
  /// (`PUT .../{date}` and `POST .../bulk`) are deliberately not exposed: they
  /// replace **all five quantities at once**, including `soldInventory` and
  /// `availableInventory`, which the booking flow maintains atomically. With no
  /// optimistic locking on `RoomInventory`, submitting a stale form would
  /// silently erase a concurrent booking's decrement. A flag toggle writes one
  /// boolean and cannot.
  Future<PartnerInventoryActionResult> setFlag({
    required DateTime date,
    required PartnerInventoryFlag flag,
    required bool value,
  }) async {
    final roomId = _selectedRoomId;
    final calendar = _calendar;
    if (roomId == null || calendar == null) {
      return PartnerInventoryActionResult.notFound;
    }
    if (!calendar.days.any((d) => _sameDay(d.date, date))) {
      return PartnerInventoryActionResult.notFound;
    }
    if (_pendingDate != null) return PartnerInventoryActionResult.failed;

    _pendingDate = date;
    notifyListeners();

    final result = await api.setPartnerInventoryFlag(
      roomId: roomId,
      date: date,
      flag: flag,
      value: value,
    );

    _pendingDate = null;

    if (!result.success || result.data == null) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerInventoryActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerInventoryActionResult.forbidden,
        ApiErrorKind.notFound => PartnerInventoryActionResult.notFound,
        ApiErrorKind.uncertain => PartnerInventoryActionResult.uncertain,
        _ => PartnerInventoryActionResult.failed,
      };
    }

    // Replace the row wholesale from the server's own answer rather than
    // patching the local boolean — the response is the authoritative record.
    final updated = result.data!;
    _calendar = PartnerInventoryCalendar(
      roomId: calendar.roomId,
      roomCode: calendar.roomCode,
      roomName: calendar.roomName,
      days: [
        for (final day in calendar.days)
          _sameDay(day.date, date) ? updated : day,
      ],
    );
    notifyListeners();
    return PartnerInventoryActionResult.success;
  }

  void reset() {
    _loadToken++;
    _status = PartnerInventoryStatus.idle;
    _errorMessage = null;
    _rooms = const [];
    _selectedRoomId = null;
    _loadedPropertyId = null;
    _calendar = null;
    _pendingDate = null;
    _range = PartnerInventoryRange.fortnight;
    _customFrom = null;
    _customTo = null;
    notifyListeners();
  }

  PartnerInventoryStatus _statusForError(ApiErrorKind? kind) => switch (kind) {
        ApiErrorKind.unauthorized => PartnerInventoryStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerInventoryStatus.forbidden,
        ApiErrorKind.notFound => PartnerInventoryStatus.notFound,
        _ => PartnerInventoryStatus.error,
      };

  void _finishWithoutData(PartnerInventoryStatus status) {
    _loadToken++;
    _status = status;
    _calendar = null;
    _errorMessage = null;
    _pendingDate = null;
    notifyListeners();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
