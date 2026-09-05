import 'package:flutter/foundation.dart';

import '../../core/admin/admin_models.dart';
import '../../core/network/api_client.dart';
import 'admin_paged_state.dart';
import 'widgets/admin_widgets.dart';

/// The paginated Admin place roster — `GET /api/admin/places`.
///
/// <h4>Why this one does not behave like the other admin grids</h4>
///
/// Every other admin grid was converted in D1a/D1c and speaks
/// `AdminPaging`'s contract: `size` is clamped to 200, `sort` is `field,dir`,
/// and an unknown field is a 400. The place endpoint predates all of that and
/// disagrees on each point — `size` is bean-validated `@Max(100)` so an
/// oversized request is a **400 rather than a clamp**, and `sort` is a closed
/// token vocabulary whose unrecognised values are silently ignored.
///
/// This class consumes that contract as it actually is rather than papering
/// over it: [maxPageSize] is lowered to the backend's real ceiling, and the
/// sort control offers only the five tokens the backend switch recognises.
class AdminCatalogPlacesState extends AdminPagedState<AdminPlaceRow> {
  AdminCatalogPlacesState({required super.api})
      : super(defaultSortField: ApiClient.adminCatalogSortTokens.first);

  /// The backend's own `@Max(100)`, not [AdminPagedState.maxPageSize]'s 200.
  /// Asking for more is rejected outright, so the console never asks.
  static const int maxPageSize = ApiClient.adminCatalogMaxPageSize;

  /// `PlaceService.resolveSort` — the whole vocabulary.
  static const List<String> sortTokens = ApiClient.adminCatalogSortTokens;

  /// The seven `PlaceStatus` values, in lifecycle order.
  static const List<String> statusValues = [
    'DRAFT',
    'PENDING_REVIEW',
    'APPROVED',
    'PUBLISHED',
    'HIDDEN',
    'REJECTED',
    'ARCHIVED',
  ];

  String? _statusFilter;
  bool? _featuredFilter;
  bool? _verifiedFilter;
  String _query = '';

  String? get statusFilter => _statusFilter;
  bool? get featuredFilter => _featuredFilter;
  bool? get verifiedFilter => _verifiedFilter;
  String get query => _query;

  bool get hasFilters =>
      _statusFilter != null ||
      _featuredFilter != null ||
      _verifiedFilter != null ||
      _query.isNotEmpty;

  /// This endpoint has no ordering tiebreaker, so two rows sharing the sort key
  /// can swap places between requests. The console surfaces that rather than
  /// hiding it — a client-side stable re-sort would be a fiction layered over a
  /// server-side property.
  bool get orderingIsUnstable => true;

  @override
  Future<CollectionApiResult<AdminPage<AdminPlaceRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      api.getAdminPlaces(
        query: _query.isEmpty ? null : _query,
        status: _statusFilter,
        featured: _featuredFilter,
        verified: _verifiedFilter,
        page: page,
        size: size > maxPageSize ? maxPageSize : size,
        // [sortParameter] would produce `token,desc`; this endpoint wants the
        // bare token, so the field alone is sent.
        sort: sortField,
      );

  Future<void> setStatusFilter(String? status) {
    if (status == _statusFilter) return Future.value();
    _statusFilter = status;
    return load(resetToFirstPage: true);
  }

  Future<void> setFeaturedFilter(bool? value) {
    if (value == _featuredFilter) return Future.value();
    _featuredFilter = value;
    return load(resetToFirstPage: true);
  }

  Future<void> setVerifiedFilter(bool? value) {
    if (value == _verifiedFilter) return Future.value();
    _verifiedFilter = value;
    return load(resetToFirstPage: true);
  }

  Future<void> setQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == _query) return Future.value();
    _query = trimmed;
    return load(resetToFirstPage: true);
  }

  /// The sort token, not a `field,dir` pair. Direction is baked into the token
  /// (`rating_desc`, `price_asc`), so the shared sort control's descending flag
  /// is meaningless here and is ignored.
  Future<void> setSortToken(String token) {
    if (!sortTokens.contains(token)) return Future.value();
    return setSort(token, false);
  }

  @override
  void reset() {
    _statusFilter = null;
    _featuredFilter = null;
    _verifiedFilter = null;
    _query = '';
    super.reset();
  }
}

/// One place's catalog detail, plus its rooms when it is a hotel.
///
/// The canonical `GET /api/admin/places/{id}` gates everything: rooms are only
/// requested once the place is known to exist, and a 404 there becomes
/// [isNotFound] for the whole screen.
class AdminPlaceDetailState extends ChangeNotifier {
  final ApiClient api;
  final int placeId;

  AdminPlaceDetailState({required this.api, required this.placeId});

  int _loadToken = 0;

  AdminLoadStatus _status = AdminLoadStatus.idle;
  AdminLoadStatus _roomsStatus = AdminLoadStatus.idle;
  String? _error;
  AdminPlaceDetail? _place;
  List<AdminCatalogRoom> _rooms = const [];

  /// True when the rooms endpoint answered 404 — this place has no hotel
  /// detail, which is an ordinary catalog fact rather than an error.
  bool _notAHotel = false;

  bool _mutating = false;
  String? _mutationError;
  bool _mutationUncertain = false;

  AdminLoadStatus get status => _status;
  AdminLoadStatus get roomsStatus => _roomsStatus;
  String? get error => _error;
  AdminPlaceDetail? get place => _place;
  List<AdminCatalogRoom> get rooms => _rooms;
  bool get notAHotel => _notAHotel;

  bool get isReady => _status == AdminLoadStatus.ready;
  bool get isNotFound => _status == AdminLoadStatus.notFound;
  bool get isMutating => _mutating;
  String? get mutationError => _mutationError;
  bool get mutationUncertain => _mutationUncertain;

  AdminPlaceStatus get placeStatus =>
      _place?.status ?? AdminPlaceStatus.unknown;

  /// Exactly the transitions the backend's own table permits from here.
  List<AdminPlaceStatus> get allowedTransitions =>
      isReady ? placeStatus.allowedNext : const [];

  /// `validateFeaturedVerified` refuses to set either flag true outside
  /// APPROVED/PUBLISHED. Clearing is always allowed, so the control is offered
  /// whenever the flag is currently on.
  bool canSetVerified(bool target) =>
      isReady && (!target || placeStatus.canSetFlagsTrue);

  bool canSetFeatured(bool target) =>
      isReady && (!target || placeStatus.canSetFlagsTrue);

  Future<void> load() async {
    final token = ++_loadToken;
    _status = AdminLoadStatus.loading;
    _error = null;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();

    final result = await api.getAdminPlace(placeId);
    if (token != _loadToken) return;

    if (!result.success || result.data == null) {
      _status = adminStatusFor(result.errorKind);
      _error = result.message;
      _roomsStatus = AdminLoadStatus.idle;
      _rooms = const [];
      _place = null;
      notifyListeners();
      return;
    }

    _place = result.data;
    _status = AdminLoadStatus.ready;
    notifyListeners();

    // Only hotels have rooms. Asking anyway and reading the 404 is how the
    // backend actually reports it, but the embedded hotelDetail block tells us
    // up front and saves a request that is guaranteed to fail.
    if (_place!.isHotel) {
      await _loadRooms(token);
    } else {
      _notAHotel = true;
      _roomsStatus = AdminLoadStatus.ready;
      _rooms = const [];
      notifyListeners();
    }
  }

  Future<void> refresh() => load();

  Future<void> _loadRooms(int token) async {
    _roomsStatus = AdminLoadStatus.loading;
    notifyListeners();
    final r = await api.getAdminPlaceRooms(placeId);
    if (token != _loadToken) return;
    if (r.success) {
      _rooms = r.data ?? const [];
      _notAHotel = false;
      _roomsStatus = AdminLoadStatus.ready;
    } else if (r.errorKind == ApiErrorKind.notFound) {
      // No hotel detail for this place: not a failure to report.
      _notAHotel = true;
      _rooms = const [];
      _roomsStatus = AdminLoadStatus.ready;
    } else {
      _roomsStatus = adminStatusFor(r.errorKind);
    }
    notifyListeners();
  }

  Future<bool> changeStatus(AdminPlaceStatus target) {
    if (!placeStatus.canTransitionTo(target)) return Future.value(false);
    return _mutate(() => api.setAdminPlaceStatus(placeId, status: target.wire));
  }

  Future<bool> setVerified(bool value) =>
      _mutate(() => api.setAdminPlaceVerified(placeId, value: value));

  Future<bool> setFeatured(bool value) =>
      _mutate(() => api.setAdminPlaceFeatured(placeId, value: value));

  Future<bool> _mutate(
      Future<CollectionApiResult<AdminPlaceRow>> Function() send) async {
    if (_mutating) return false;
    _mutating = true;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();

    final result = await send();
    _mutating = false;

    if (result.success) {
      _mutationError = null;
      notifyListeners();
      // Reload rather than patching locally: a status change can alter which
      // transitions are legal next and whether the flags may be set at all.
      await load();
      return true;
    }

    _mutationUncertain = result.errorKind == ApiErrorKind.uncertain;
    _mutationError = result.message;
    notifyListeners();
    if (_mutationUncertain) {
      await load();
      // load() clears the transient banners, but the uncertainty outlives the
      // reload: archiving cannot be undone, so the operator must not simply
      // retry without looking.
      _mutationUncertain = true;
      _mutationError = null;
      notifyListeners();
    }
    return false;
  }
}
