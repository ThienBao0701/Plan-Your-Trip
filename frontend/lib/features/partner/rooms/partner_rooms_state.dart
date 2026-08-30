import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a room activate/deactivate, in the project's established
/// "typed result enum, never an exception" convention.
enum PartnerRoomActionResult {
  success,
  unauthorized,
  forbidden,

  /// Uniform 404 — the room is unknown *or* belongs to a property this partner
  /// does not own. `ownedRoomOrThrow` makes the two indistinguishable.
  notFound,
  failed,

  /// The request may have been committed before the connection dropped.
  uncertain,
}

/// Where the Rooms module stands.
///
/// [noPropertySelected] is a first-class state rather than an error, because
/// `GET /api/partner/rooms` takes a **required** `hotelId`: without a property
/// there is no request to make, and inventing one would mean picking a property
/// on the partner's behalf.
enum PartnerRoomsStatus {
  idle,

  /// No property is selected, so no room query is possible yet.
  noPropertySelected,

  /// The workspace authorises no properties at all.
  noProperties,

  loading,
  ready,

  /// 401 — session expired.
  unauthorized,

  /// 403 — partner profile not approved.
  forbidden,

  /// 404 — the selected hotel is not owned/known, or it has no `HotelDetail`
  /// row. `PartnerRoomService` returns 404 for both.
  propertyUnavailable,

  /// Offline / timeout / 5xx / malformed. Retryable.
  error,
}

/// State for the Partner Rooms module.
///
/// Feature-scoped `ChangeNotifier` in the same `AppScope`/`InheritedNotifier`
/// paradigm as C1 and C2 — no second state-management system, and no growth of
/// [PartnerState].
///
/// ## Property context
///
/// [PartnerState] remains the single owner of the selected property; this class
/// **reads** it and never stores a second copy. Every load is keyed on the id
/// passed in by the screen, which reads it from `PartnerState.selectedPropertyId`.
/// The last loaded id is remembered only so the screen can tell when the
/// workspace selection moved underneath it and reload.
class PartnerRoomsState extends ChangeNotifier {
  final ApiClient api;

  PartnerRoomsState({required this.api});

  PartnerRoomsStatus _status = PartnerRoomsStatus.idle;
  List<PartnerRoom> _rooms = const [];
  String? _errorMessage;

  /// The property id the current [_rooms] were loaded for. Not a second source
  /// of truth for selection — purely "what is on screen right now".
  int? _loadedPropertyId;

  int? _openRoomId;
  PartnerRoom? _detail;
  bool _detailLoading = false;
  ApiErrorKind? _detailErrorKind;
  String? _detailErrorMessage;

  int? _pendingActionRoomId;
  int _loadToken = 0;

  PartnerRoomsStatus get status => _status;
  List<PartnerRoom> get rooms => List.unmodifiable(_rooms);
  String? get errorMessage => _errorMessage;
  int? get loadedPropertyId => _loadedPropertyId;

  bool get isLoading => _status == PartnerRoomsStatus.loading;
  bool get isReady => _status == PartnerRoomsStatus.ready;

  /// The property is fine and simply has no rooms configured. Distinct from
  /// every failure and from "no property selected".
  bool get isEmpty => isReady && _rooms.isEmpty;

  bool get isRetryable => _status == PartnerRoomsStatus.error;

  int? get openRoomId => _openRoomId;
  PartnerRoom? get detail => _detail;
  bool get isDetailLoading => _detailLoading;
  ApiErrorKind? get detailErrorKind => _detailErrorKind;
  String? get detailErrorMessage => _detailErrorMessage;
  bool get hasDetailError => _detailErrorKind != null;

  int? get pendingActionRoomId => _pendingActionRoomId;

  /// Rooms currently listed to guests.
  int get activeCount => _rooms.where((r) => r.active).length;

  /// Rooms whose whole allocation is unsellable. An operational signal that is
  /// deliberately separate from [activeCount] — a sold-out room is still listed.
  int get soldOutCount => _rooms.where((r) => r.isSoldOut).length;

  /// Loads the rooms of [propertyId].
  ///
  /// [partner] supplies the authorized property list; an id outside it is
  /// refused before any request is made. The backend would return 404 anyway —
  /// this simply refuses to ask a question the client has no business asking.
  Future<void> load(PartnerState partner, int? propertyId) async {
    if (partner.properties.isEmpty) {
      _finishWithoutData(PartnerRoomsStatus.noProperties);
      return;
    }
    if (propertyId == null) {
      _finishWithoutData(PartnerRoomsStatus.noPropertySelected);
      return;
    }
    if (!partner.properties.any((p) => p.id == propertyId)) {
      // Never trust an id the workspace does not authorize, wherever it came
      // from. This is UX hygiene, not authorization — the backend re-checks.
      _finishWithoutData(PartnerRoomsStatus.propertyUnavailable);
      return;
    }

    final token = ++_loadToken;
    _status = PartnerRoomsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getPartnerRooms(propertyId);
    if (token != _loadToken) return;

    if (!result.success) {
      _rooms = const [];
      _loadedPropertyId = propertyId;
      _status = switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerRoomsStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerRoomsStatus.forbidden,
        ApiErrorKind.notFound => PartnerRoomsStatus.propertyUnavailable,
        _ => PartnerRoomsStatus.error,
      };
      _errorMessage = result.message;
      _clearDetail();
      notifyListeners();
      return;
    }

    _rooms = result.data ?? const [];
    _loadedPropertyId = propertyId;
    _status = PartnerRoomsStatus.ready;
    _errorMessage = null;

    // A detail panel left open for a room that is no longer in this property's
    // list must not linger — switching property must not leak the previous
    // property's room on screen.
    final open = _openRoomId;
    if (open != null && !_rooms.any((r) => r.id == open)) {
      _clearDetail();
    }

    notifyListeners();
  }

  /// Opens one room's detail. Refuses any id not in the loaded list.
  Future<void> openRoom(int roomId) async {
    if (!_rooms.any((r) => r.id == roomId)) return;

    _openRoomId = roomId;
    _detail = null;
    _detailErrorKind = null;
    _detailErrorMessage = null;
    _detailLoading = true;
    notifyListeners();

    final result = await api.getPartnerRoom(roomId);
    if (_openRoomId != roomId) return;

    _detailLoading = false;
    if (result.success && result.data != null) {
      _detail = result.data;
      _detailErrorKind = null;
      _detailErrorMessage = null;
    } else {
      _detail = null;
      _detailErrorKind = result.errorKind ?? ApiErrorKind.network;
      _detailErrorMessage = result.message;
    }
    notifyListeners();
  }

  void closeDetail() {
    if (_openRoomId == null) return;
    _clearDetail();
    notifyListeners();
  }

  /// `PATCH /activate` or `/deactivate`.
  ///
  /// The row and any open detail are refreshed from the response body — the
  /// full updated record — so nothing is assumed and a failure leaves the
  /// previous value visibly intact.
  Future<PartnerRoomActionResult> setActive(
    int roomId, {
    required bool activate,
  }) async {
    if (!_rooms.any((r) => r.id == roomId)) {
      return PartnerRoomActionResult.notFound;
    }
    if (_pendingActionRoomId != null) return PartnerRoomActionResult.failed;

    _pendingActionRoomId = roomId;
    notifyListeners();

    final result = activate
        ? await api.activatePartnerRoom(roomId)
        : await api.deactivatePartnerRoom(roomId);

    _pendingActionRoomId = null;

    if (!result.success || result.data == null) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerRoomActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerRoomActionResult.forbidden,
        ApiErrorKind.notFound => PartnerRoomActionResult.notFound,
        ApiErrorKind.uncertain => PartnerRoomActionResult.uncertain,
        _ => PartnerRoomActionResult.failed,
      };
    }

    final updated = result.data!;
    _rooms = [
      for (final room in _rooms)
        room.id == roomId ? room.copyWithActive(updated.active) : room,
    ];
    if (_openRoomId == roomId) _detail = updated;

    notifyListeners();
    return PartnerRoomActionResult.success;
  }

  void reset() {
    _loadToken++;
    _status = PartnerRoomsStatus.idle;
    _rooms = const [];
    _loadedPropertyId = null;
    _errorMessage = null;
    _pendingActionRoomId = null;
    _clearDetail();
    notifyListeners();
  }

  void _finishWithoutData(PartnerRoomsStatus status) {
    _loadToken++;
    _status = status;
    _rooms = const [];
    _loadedPropertyId = null;
    _errorMessage = null;
    _clearDetail();
    notifyListeners();
  }

  void _clearDetail() {
    _openRoomId = null;
    _detail = null;
    _detailLoading = false;
    _detailErrorKind = null;
    _detailErrorMessage = null;
  }
}
