import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_promotion_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a promotion activate/deactivate.
enum PartnerPromotionActionResult {
  success,
  unauthorized,

  /// 403. `PartnerPromotionService` answers an `ALL`-target write with this.
  forbidden,

  /// Uniform 404 — unknown promotion, or one whose target this partner does not
  /// own. Indistinguishable by design.
  notFound,

  /// 409 — duplicate promotion code (`existsByCode` is a **global** check, not
  /// per-partner).
  conflict,

  /// 400 — e.g. `endDate must be after startDate`.
  validation,
  failed,

  /// May have been committed before the connection dropped.
  uncertain,

  /// The stored record is missing a field the write needs, so a lossless
  /// read-modify-write is impossible and nothing was sent.
  notRoundTrippable,
}

/// Where the Promotions module stands.
enum PartnerPromotionsStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — no partner profile.
  notFound,
  error,
}

/// State for the Partner Promotions module.
///
/// Feature-scoped `ChangeNotifier`, same paradigm as C1–C6. [PartnerState] keeps
/// workspace identity, team role and the selected property, and is neither
/// extended nor duplicated.
///
/// ## Scope note
///
/// `GET /api/partner/promotions` is **partner-wide**, not property-scoped: the
/// service collects every hotel and room the partner owns and returns promotions
/// targeting any of them. There is no `hotelId` parameter. The list is therefore
/// shown **unfiltered**, and the screen says so — silently narrowing it to the
/// selected property would misrepresent what the endpoint returned. The selected
/// property is used only to load rooms, which name `ROOM` targets and feed the
/// pricing preview.
class PartnerPromotionsState extends ChangeNotifier {
  final ApiClient api;

  PartnerPromotionsState({required this.api});

  PartnerPromotionsStatus _status = PartnerPromotionsStatus.idle;
  String? _errorMessage;

  List<PartnerPromotion> _promotions = const [];
  int? _openPromotionId;
  int? _pendingActionId;

  /// Rooms of the selected property, used to resolve `targetId` into a name and
  /// to offer the pricing preview. Empty when the property has none.
  List<PartnerRoom> _rooms = const [];
  int? _loadedPropertyId;

  PartnerPricingPreview? _preview;
  bool _previewLoading = false;
  ApiErrorKind? _previewErrorKind;
  int? _previewRoomId;

  int _loadToken = 0;

  PartnerPromotionsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PartnerPromotion> get promotions => List.unmodifiable(_promotions);
  List<PartnerRoom> get rooms => List.unmodifiable(_rooms);
  int? get loadedPropertyId => _loadedPropertyId;
  int? get openPromotionId => _openPromotionId;
  int? get pendingActionId => _pendingActionId;

  PartnerPricingPreview? get preview => _preview;
  bool get isPreviewLoading => _previewLoading;
  ApiErrorKind? get previewErrorKind => _previewErrorKind;
  int? get previewRoomId => _previewRoomId;

  bool get isLoading => _status == PartnerPromotionsStatus.loading;
  bool get isReady => _status == PartnerPromotionsStatus.ready;

  /// The partner owns no promotions. A real answer — the seeded partner is in
  /// exactly this state, because the only seeded promotion targets `ALL` and so
  /// belongs to nobody.
  bool get isEmpty => isReady && _promotions.isEmpty;

  bool get isRetryable => _status == PartnerPromotionsStatus.error;

  PartnerPromotion? get openPromotion {
    final id = _openPromotionId;
    if (id == null) return null;
    for (final promotion in _promotions) {
      if (promotion.id == id) return promotion;
    }
    return null;
  }

  int get activeCount => _promotions.where((p) => p.active).length;

  /// Promotions whose window has elapsed. Reported separately from
  /// [activeCount] because a promotion can be both active and expired.
  int get expiredCount => _promotions.where((p) => p.isExpired()).length;

  /// Resolves a `ROOM` target into its room name, when the room belongs to the
  /// property currently loaded. Returns null rather than guessing.
  String? roomNameFor(PartnerPromotion promotion) {
    if (promotion.targetType != PartnerPromotionTargetType.room) return null;
    for (final room in _rooms) {
      if (room.id == promotion.targetId) return room.roomName;
    }
    return null;
  }

  /// Loads the partner's promotions, plus the selected property's rooms so
  /// `ROOM` targets can be named and the preview has something to run against.
  ///
  /// The two requests are independent: a rooms failure must not blank the
  /// promotion list, which is not property-scoped in the first place.
  Future<void> load(PartnerState partner, int? propertyId) async {
    final token = ++_loadToken;
    _status = PartnerPromotionsStatus.loading;
    _errorMessage = null;
    if (propertyId != _loadedPropertyId) {
      // Rooms and any preview belong to the previous property.
      _rooms = const [];
      _clearPreview();
    }
    notifyListeners();

    final authorized =
        propertyId != null && partner.properties.any((p) => p.id == propertyId);

    final results = await Future.wait([
      api.getPartnerPromotions(),
      if (authorized) api.getPartnerRooms(propertyId),
    ]);
    if (token != _loadToken) return;

    final promotionsResult =
        results[0] as CollectionApiResult<List<PartnerPromotion>>;

    if (!promotionsResult.success) {
      _promotions = const [];
      _status = switch (promotionsResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerPromotionsStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerPromotionsStatus.forbidden,
        ApiErrorKind.notFound => PartnerPromotionsStatus.notFound,
        _ => PartnerPromotionsStatus.error,
      };
      _errorMessage = promotionsResult.message;
      _clearDetail();
      notifyListeners();
      return;
    }

    _promotions = promotionsResult.data ?? const [];
    _loadedPropertyId = propertyId;

    if (authorized && results.length > 1) {
      final roomsResult = results[1] as CollectionApiResult<List<PartnerRoom>>;
      _rooms = roomsResult.success ? (roomsResult.data ?? const []) : const [];
    } else {
      _rooms = const [];
    }

    // A detail panel open for a promotion that is no longer listed must not
    // linger.
    final open = _openPromotionId;
    if (open != null && !_promotions.any((p) => p.id == open)) {
      _clearDetail();
    }

    _status = PartnerPromotionsStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  /// Opens one promotion's detail. Refuses ids outside the loaded list.
  void openPromotionDetail(int id) {
    if (!_promotions.any((p) => p.id == id)) return;
    if (_openPromotionId == id) return;
    _openPromotionId = id;
    notifyListeners();
  }

  void closeDetail() {
    if (_openPromotionId == null) return;
    _clearDetail();
    notifyListeners();
  }

  /// Activates or deactivates a promotion.
  ///
  /// There is **no command endpoint** for this. `PUT /promotions/{id}` runs
  /// `PromotionService.fill`, a full replace of all sixteen request fields, so
  /// the write echoes the entire stored record and overrides only `active`.
  /// Every request field is present on the response, which is what makes that
  /// lossless — [PartnerPromotion.canRoundTrip] refuses the write otherwise
  /// rather than sending a body that would null unknown fields.
  Future<PartnerPromotionActionResult> setActive(
    int promotionId, {
    required bool active,
  }) async {
    PartnerPromotion? target;
    for (final promotion in _promotions) {
      if (promotion.id == promotionId) target = promotion;
    }
    if (target == null) return PartnerPromotionActionResult.notFound;
    if (!target.canRoundTrip) {
      return PartnerPromotionActionResult.notRoundTrippable;
    }
    if (_pendingActionId != null) return PartnerPromotionActionResult.failed;

    _pendingActionId = promotionId;
    notifyListeners();

    final result =
        await api.setPartnerPromotionActive(promotion: target, active: active);

    _pendingActionId = null;

    if (!result.success || result.data == null) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerPromotionActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerPromotionActionResult.forbidden,
        ApiErrorKind.notFound => PartnerPromotionActionResult.notFound,
        ApiErrorKind.conflict => PartnerPromotionActionResult.conflict,
        ApiErrorKind.validation => PartnerPromotionActionResult.validation,
        ApiErrorKind.uncertain => PartnerPromotionActionResult.uncertain,
        _ => PartnerPromotionActionResult.failed,
      };
    }

    // Replace from the server's own answer, not from the local guess.
    final updated = result.data!;
    _promotions = [
      for (final promotion in _promotions)
        promotion.id == promotionId ? updated : promotion,
    ];
    notifyListeners();
    return PartnerPromotionActionResult.success;
  }

  /// Runs the pricing engine's own breakdown for a room and stay, showing which
  /// promotions it actually applied.
  ///
  /// Rejects `checkOut <= checkIn` before requesting — a zero-night breakdown
  /// would be meaningless, and the client performs no pricing arithmetic of its
  /// own either way.
  Future<void> runPreview({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    if (!_rooms.any((r) => r.id == roomId)) return;

    final from = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final to = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (!to.isAfter(from)) {
      _preview = null;
      _previewLoading = false;
      _previewErrorKind = ApiErrorKind.validation;
      _previewRoomId = roomId;
      notifyListeners();
      return;
    }

    _previewRoomId = roomId;
    _previewLoading = true;
    _previewErrorKind = null;
    notifyListeners();

    final result = await api.getPartnerPricingPreview(
      roomId: roomId,
      checkIn: from,
      checkOut: to,
    );
    if (_previewRoomId != roomId) return;

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

  void reset() {
    _loadToken++;
    _status = PartnerPromotionsStatus.idle;
    _errorMessage = null;
    _promotions = const [];
    _rooms = const [];
    _loadedPropertyId = null;
    _pendingActionId = null;
    _clearDetail();
    _clearPreview();
    notifyListeners();
  }

  void _clearDetail() {
    _openPromotionId = null;
  }

  void _clearPreview() {
    _preview = null;
    _previewLoading = false;
    _previewErrorKind = null;
    _previewRoomId = null;
  }
}
