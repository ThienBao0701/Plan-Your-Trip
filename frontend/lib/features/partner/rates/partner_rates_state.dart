import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_rate_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a rate-plan activate/deactivate.
enum PartnerRateActionResult {
  success,
  unauthorized,
  forbidden,

  /// Uniform 404 — the plan is unknown or not owned. Indistinguishable by design.
  notFound,

  /// 409. Not produced by activate/deactivate today, but the classification
  /// exists so a conflict can never be reported as a generic failure.
  conflict,
  failed,

  /// May have been committed before the connection dropped.
  uncertain,
}

/// Where the Rates module stands. The chain is property → rooms → rate plans,
/// and each link stops honestly rather than collapsing into one "empty".
enum PartnerRatesStatus {
  idle,
  noProperties,
  noPropertySelected,
  loadingRooms,

  /// The property has no room types, so there is nothing to price.
  noRooms,
  noRoomSelected,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — property, room or plan not available to this account.
  notFound,
  error,
}

/// State for the Partner Rates module.
///
/// Feature-scoped `ChangeNotifier`, same paradigm as C1–C4. It owns the rate
/// list, the selected room and plan, the preview stay window and mutation
/// state. [PartnerState] keeps workspace identity, team role and the selected
/// **property**, and is neither extended nor duplicated.
class PartnerRatesState extends ChangeNotifier {
  final ApiClient api;

  PartnerRatesState({required this.api});

  PartnerRatesStatus _status = PartnerRatesStatus.idle;
  String? _errorMessage;

  List<PartnerRoom> _rooms = const [];
  int? _selectedRoomId;
  int? _loadedPropertyId;

  List<PartnerRatePlan> _plans = const [];

  int? _openPlanId;
  List<PartnerOccupancyPrice> _occupancyPrices = const [];
  bool _detailLoading = false;
  ApiErrorKind? _detailErrorKind;

  PartnerRatePreview? _preview;
  bool _previewLoading = false;
  ApiErrorKind? _previewErrorKind;

  /// Preview stay. `checkIn`/`checkOut` are a **half-open night range** —
  /// nights = checkOut − checkIn — which is not the same shape as a rate plan's
  /// own inclusive validity window.
  DateTime? _previewCheckIn;
  DateTime? _previewCheckOut;

  int? _pendingActionPlanId;
  int _loadToken = 0;

  PartnerRatesStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PartnerRoom> get rooms => List.unmodifiable(_rooms);
  int? get selectedRoomId => _selectedRoomId;
  int? get loadedPropertyId => _loadedPropertyId;
  List<PartnerRatePlan> get plans => List.unmodifiable(_plans);

  int? get openPlanId => _openPlanId;
  List<PartnerOccupancyPrice> get occupancyPrices =>
      List.unmodifiable(_occupancyPrices);
  bool get isDetailLoading => _detailLoading;
  ApiErrorKind? get detailErrorKind => _detailErrorKind;

  PartnerRatePreview? get preview => _preview;
  bool get isPreviewLoading => _previewLoading;
  ApiErrorKind? get previewErrorKind => _previewErrorKind;
  DateTime? get previewCheckIn => _previewCheckIn;
  DateTime? get previewCheckOut => _previewCheckOut;

  int? get pendingActionPlanId => _pendingActionPlanId;

  PartnerRoom? get selectedRoom {
    final id = _selectedRoomId;
    if (id == null) return null;
    for (final room in _rooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  /// The rate plan whose detail panel is open, resolved from the loaded list.
  PartnerRatePlan? get openedPlan {
    final id = _openPlanId;
    if (id == null) return null;
    for (final plan in _plans) {
      if (plan.id == id) return plan;
    }
    return null;
  }

  bool get isLoading =>
      _status == PartnerRatesStatus.loading ||
      _status == PartnerRatesStatus.loadingRooms;
  bool get isReady => _status == PartnerRatesStatus.ready;

  /// The room is fine and simply has no rate plans. A real answer — live seed
  /// data has rooms in exactly this state.
  bool get isEmpty => isReady && _plans.isEmpty;

  bool get isRetryable => _status == PartnerRatesStatus.error;

  int get activePlanCount => _plans.where((p) => p.active).length;

  /// Plans whose validity window has elapsed. Reported separately from
  /// [activePlanCount] because an expired plan can still be flagged active.
  int get expiredPlanCount => _plans.where((p) => p.isExpired()).length;

  /// Loads the rooms of [propertyId], then the rate plans of the selected room.
  Future<void> load(PartnerState partner, int? propertyId) async {
    if (partner.properties.isEmpty) {
      _finishWithoutData(PartnerRatesStatus.noProperties);
      return;
    }
    if (propertyId == null) {
      _finishWithoutData(PartnerRatesStatus.noPropertySelected);
      return;
    }
    if (!partner.properties.any((p) => p.id == propertyId)) {
      _finishWithoutData(PartnerRatesStatus.notFound);
      return;
    }

    final token = ++_loadToken;
    final propertyChanged = propertyId != _loadedPropertyId;
    _status = PartnerRatesStatus.loadingRooms;
    _errorMessage = null;
    if (propertyChanged) {
      // A room or plan from another property must never survive the switch.
      _selectedRoomId = null;
      _plans = const [];
      _rooms = const [];
      _clearDetail();
      _clearPreview();
    }
    notifyListeners();

    final roomsResult = await api.getPartnerRooms(propertyId);
    if (token != _loadToken) return;

    if (!roomsResult.success) {
      _rooms = const [];
      _plans = const [];
      _loadedPropertyId = propertyId;
      _status = _statusForError(roomsResult.errorKind);
      _errorMessage = roomsResult.message;
      notifyListeners();
      return;
    }

    _rooms = roomsResult.data ?? const [];
    _loadedPropertyId = propertyId;

    if (_rooms.isEmpty) {
      _plans = const [];
      _selectedRoomId = null;
      _status = PartnerRatesStatus.noRooms;
      notifyListeners();
      return;
    }

    if (_selectedRoomId == null ||
        !_rooms.any((r) => r.id == _selectedRoomId)) {
      _selectedRoomId = _rooms.first.id;
    }

    await _loadPlans(token);
  }

  Future<void> _loadPlans(int token) async {
    final roomId = _selectedRoomId;
    if (roomId == null) {
      _finishWithoutData(PartnerRatesStatus.noRoomSelected);
      return;
    }

    _status = PartnerRatesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getPartnerRatePlans(roomId);
    if (token != _loadToken) return;

    if (!result.success) {
      _plans = const [];
      _status = _statusForError(result.errorKind);
      _errorMessage = result.message;
      _clearDetail();
      _clearPreview();
      notifyListeners();
      return;
    }

    _plans = result.data ?? const [];
    _status = PartnerRatesStatus.ready;
    _errorMessage = null;

    // A plan panel left open for a plan that is no longer listed must not
    // linger — switching room must not leak the previous room's plan.
    final open = _openPlanId;
    if (open != null && !_plans.any((p) => p.id == open)) {
      _clearDetail();
      _clearPreview();
    }
    notifyListeners();
  }

  /// Switches room within the loaded property. Ignores unknown ids.
  Future<void> selectRoom(int roomId) async {
    if (roomId == _selectedRoomId) return;
    if (!_rooms.any((r) => r.id == roomId)) return;
    _selectedRoomId = roomId;
    _plans = const [];
    _clearDetail();
    _clearPreview();
    notifyListeners();
    await _loadPlans(++_loadToken);
  }

  /// Opens one plan and loads its occupancy prices. Refuses unlisted ids.
  Future<void> openPlan(int planId) async {
    if (!_plans.any((p) => p.id == planId)) return;

    _openPlanId = planId;
    _occupancyPrices = const [];
    _detailErrorKind = null;
    _detailLoading = true;
    _clearPreview();
    notifyListeners();

    final result = await api.getPartnerOccupancyPrices(planId);
    if (_openPlanId != planId) return;

    _detailLoading = false;
    if (result.success) {
      _occupancyPrices = result.data ?? const [];
      _detailErrorKind = null;
    } else {
      _occupancyPrices = const [];
      _detailErrorKind = result.errorKind ?? ApiErrorKind.network;
    }
    notifyListeners();
  }

  void closePlan() {
    if (_openPlanId == null) return;
    _clearDetail();
    _clearPreview();
    notifyListeners();
  }

  /// Runs the backend's pricing preview for the open plan over a stay.
  ///
  /// Rejects `checkOut <= checkIn` before requesting: the endpoint answers such
  /// a stay with 200 rather than 400, and a zero- or negative-night breakdown
  /// would be meaningless.
  Future<void> runPreview({
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int extraBeds = 0,
  }) async {
    final planId = _openPlanId;
    if (planId == null) return;

    _previewCheckIn = DateTime(checkIn.year, checkIn.month, checkIn.day);
    _previewCheckOut = DateTime(checkOut.year, checkOut.month, checkOut.day);

    if (!_previewCheckOut!.isAfter(_previewCheckIn!)) {
      _preview = null;
      _previewLoading = false;
      _previewErrorKind = ApiErrorKind.validation;
      notifyListeners();
      return;
    }

    _previewLoading = true;
    _previewErrorKind = null;
    notifyListeners();

    final result = await api.getPartnerRatePreview(
      ratePlanId: planId,
      checkIn: _previewCheckIn!,
      checkOut: _previewCheckOut!,
      adults: adults,
      children: children,
      extraBeds: extraBeds,
    );
    if (_openPlanId != planId) return;

    _previewLoading = false;
    if (result.success && result.data != null) {
      _preview = result.data;
      _previewErrorKind = null;
    } else {
      _preview = null;
      _previewErrorKind = result.errorKind ?? ApiErrorKind.network;
    }
    notifyListeners();
  }

  /// Activates or deactivates a plan.
  ///
  /// This is the only rate mutation C5 exposes. It sends no body, flips one
  /// boolean and returns the full record, so it cannot corrupt a plan's
  /// configuration the way the full-replace `PUT` could.
  ///
  /// It does **not** alter existing bookings: `BookingService` snapshots the
  /// plan's name, nightly rate and adjustment onto the booking at creation, so
  /// changing a plan afterwards never re-prices a stay already sold.
  Future<PartnerRateActionResult> setActive(
    int planId, {
    required bool activate,
  }) async {
    if (!_plans.any((p) => p.id == planId)) {
      return PartnerRateActionResult.notFound;
    }
    if (_pendingActionPlanId != null) return PartnerRateActionResult.failed;

    _pendingActionPlanId = planId;
    notifyListeners();

    final result = activate
        ? await api.activatePartnerRatePlan(planId)
        : await api.deactivatePartnerRatePlan(planId);

    _pendingActionPlanId = null;

    if (!result.success || result.data == null) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerRateActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerRateActionResult.forbidden,
        ApiErrorKind.notFound => PartnerRateActionResult.notFound,
        ApiErrorKind.conflict => PartnerRateActionResult.conflict,
        ApiErrorKind.uncertain => PartnerRateActionResult.uncertain,
        _ => PartnerRateActionResult.failed,
      };
    }

    final updated = result.data!;
    _plans = [
      for (final plan in _plans)
        plan.id == planId ? plan.copyWithActive(updated.active) : plan,
    ];
    notifyListeners();
    return PartnerRateActionResult.success;
  }

  void reset() {
    _loadToken++;
    _status = PartnerRatesStatus.idle;
    _errorMessage = null;
    _rooms = const [];
    _selectedRoomId = null;
    _loadedPropertyId = null;
    _plans = const [];
    _pendingActionPlanId = null;
    _clearDetail();
    _clearPreview();
    notifyListeners();
  }

  PartnerRatesStatus _statusForError(ApiErrorKind? kind) => switch (kind) {
        ApiErrorKind.unauthorized => PartnerRatesStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerRatesStatus.forbidden,
        ApiErrorKind.notFound => PartnerRatesStatus.notFound,
        _ => PartnerRatesStatus.error,
      };

  void _finishWithoutData(PartnerRatesStatus status) {
    _loadToken++;
    _status = status;
    _plans = const [];
    _errorMessage = null;
    _pendingActionPlanId = null;
    _clearDetail();
    _clearPreview();
    notifyListeners();
  }

  void _clearDetail() {
    _openPlanId = null;
    _occupancyPrices = const [];
    _detailLoading = false;
    _detailErrorKind = null;
  }

  void _clearPreview() {
    _preview = null;
    _previewLoading = false;
    _previewErrorKind = null;
    _previewCheckIn = null;
    _previewCheckOut = null;
  }
}
