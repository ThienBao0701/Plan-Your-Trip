import 'package:flutter/foundation.dart';

import '../../core/admin/admin_models.dart';
import '../../core/network/api_client.dart';
import 'widgets/admin_widgets.dart';

/// The Admin Media surface — one place's gallery at a time.
///
/// <h4>Why this is scoped to a place</h4>
///
/// `AdminMediaController` exposes exactly one admin read, and it is
/// `GET /api/admin/places/{placeId}/media`. `POST /api/admin/media` will happily
/// accept `ROOM`, `REVIEW` or `TRIP_DOCUMENT`, but nothing in the admin API
/// reads those back — an asset created against one would be invisible to the
/// console that created it, and therefore impossible to edit, re-cover,
/// reorder or deactivate afterwards. So the console offers the one owner it can
/// manage end to end, and [AdminMediaOwnerType.isAdminManageable] records why.
///
/// <h4>What it never does</h4>
///
/// There is no local reordering, no local cover promotion and no optimistic
/// patching: every mutation is followed by a re-read of the gallery, because
/// the server owns `sortOrder`, `cover` and `active` and a mutation can change
/// rows the caller did not name (setting a cover clears the previous one).
class AdminMediaState extends ChangeNotifier {
  final ApiClient api;

  AdminMediaState({required this.api});

  /// Guards both the picker and the gallery against a slow response for a
  /// selection the operator has already moved away from.
  int _loadToken = 0;
  int _searchToken = 0;

  // ── owner (place) selection ───────────────────────────────────────────────

  String _placeQuery = '';
  List<AdminPlaceRow> _placeOptions = const [];
  AdminLoadStatus _placeSearchStatus = AdminLoadStatus.idle;
  String? _placeSearchError;

  /// The gallery currently open, as a canonical id — never a widget, a row
  /// object or a piece of display text. D3D added the second entry point (a
  /// place's detail screen), and both routes converge here.
  AdminMediaOwner? _owner;

  /// A picker, not a grid: the first page of matches is enough to choose from,
  /// and the UI says so rather than implying the list is complete.
  static const int placeOptionLimit = 20;

  String get placeQuery => _placeQuery;
  List<AdminPlaceRow> get placeOptions => _placeOptions;
  AdminLoadStatus get placeSearchStatus => _placeSearchStatus;
  String? get placeSearchError => _placeSearchError;
  AdminMediaOwner? get owner => _owner;
  bool get hasSelection => _owner != null;

  /// True when the last authoritative read returned an asset that does not
  /// belong to [owner]. The gallery is not rendered and no mutation is
  /// permitted in that state: the console does not repair server data, and it
  /// does not act on rows it cannot vouch for.
  bool get ownerMismatch => _ownerMismatch;
  bool _ownerMismatch = false;

  /// Set by any successful mutation, cleared when a gallery is opened. The
  /// shell reads it to decide whether a place's detail actually needs
  /// re-reading on the way back — so an untouched visit costs no extra GET.
  bool get galleryChanged => _galleryChanged;
  bool _galleryChanged = false;

  /// The owner types this console can manage — `PLACE` alone. Exposed so the UI
  /// and its tests read the same source rather than restating the rule.
  static List<AdminMediaOwnerType> get manageableOwnerTypes =>
      AdminMediaOwnerType.manageable;

  // ── gallery ───────────────────────────────────────────────────────────────

  AdminLoadStatus _status = AdminLoadStatus.idle;
  String? _error;
  List<AdminMediaAsset> _items = const [];

  AdminLoadStatus get status => _status;
  String? get errorMessage => _error;
  List<AdminMediaAsset> get items => _items;

  bool get isLoading => _status == AdminLoadStatus.loading;
  bool get isReady => _status == AdminLoadStatus.ready;
  bool get isEmpty => _items.isEmpty;

  /// The active cover, when the gallery has one. A gallery may legitimately
  /// have **none** — deactivating the cover clears the flag and nothing is
  /// promoted — so this is nullable rather than an index.
  AdminMediaAsset? get coverAsset {
    for (final a in _items) {
      if (a.cover && a.active) return a;
    }
    return null;
  }

  /// The admin read orders by `sortOrder` alone, with no id tiebreaker (unlike
  /// the public read, which adds one). Two rows sharing a position therefore
  /// have no defined order, and the UI says so instead of pretending the list
  /// is stable. A reorder from this console always renumbers 0..n-1, so it
  /// resolves the tie rather than preserving it.
  bool get hasAmbiguousOrder {
    final seen = <int>{};
    for (final a in _items) {
      if (!seen.add(a.sortOrder)) return true;
    }
    return false;
  }

  // ── mutation ──────────────────────────────────────────────────────────────

  bool _mutating = false;
  String? _mutationError;
  bool _mutationUncertain = false;

  bool get isMutating => _mutating;
  String? get mutationError => _mutationError;
  bool get mutationUncertain => _mutationUncertain;

  // ── owner selection ───────────────────────────────────────────────────────

  /// Looks a place up through the catalog's own list endpoint. This is the same
  /// read D3C-A uses; no new contract is involved, and no per-row call is made.
  Future<void> searchPlaces(String query) async {
    final trimmed = query.trim();
    _placeQuery = trimmed;
    final token = ++_searchToken;
    _placeSearchStatus = AdminLoadStatus.loading;
    _placeSearchError = null;
    notifyListeners();

    final result = await api.getAdminPlaces(
      query: trimmed.isEmpty ? null : trimmed,
      page: 0,
      size: placeOptionLimit,
    );
    if (token != _searchToken) return;

    if (result.success && result.data != null) {
      _placeOptions = result.data!.content;
      _placeSearchStatus = AdminLoadStatus.ready;
    } else {
      _placeOptions = const [];
      _placeSearchStatus = adminStatusFor(result.errorKind);
      _placeSearchError = result.message;
    }
    notifyListeners();
  }

  /// Picker entry point. Only [AdminPlaceRow.id] is carried forward; the name
  /// is display-only.
  Future<void> selectPlace(AdminPlaceRow place) =>
      openPlace(placeId: place.id, placeName: place.name);

  /// D3D — the entry point used when a place is already open elsewhere.
  ///
  /// Takes the id the caller already holds authoritatively. It is deliberately
  /// not derived from any rendered text, and nothing in the media UI can change
  /// it afterwards: switching galleries means opening another one.
  Future<void> openPlace({required int placeId, String? placeName}) {
    _owner = AdminMediaOwner.place(id: placeId, name: placeName);
    _items = const [];
    _ownerMismatch = false;
    _galleryChanged = false;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();
    return load();
  }

  /// Returns to the picker. The gallery is dropped rather than kept around, so
  /// a later selection can never render the previous place's assets.
  void clearSelection() {
    _loadToken++;
    _owner = null;
    _items = const [];
    _ownerMismatch = false;
    _galleryChanged = false;
    _status = AdminLoadStatus.idle;
    _error = null;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();
  }

  // ── gallery ───────────────────────────────────────────────────────────────

  Future<void> load() async {
    final place = _owner;
    if (place == null) return;

    final token = ++_loadToken;
    _status = AdminLoadStatus.loading;
    _error = null;
    _ownerMismatch = false;
    notifyListeners();

    final result = await api.getAdminPlaceMedia(place.id);
    if (token != _loadToken) return;

    if (result.success && result.data != null) {
      final rows = result.data!;
      // D3D — every row is checked against the owner this screen is bound to.
      // The endpoint is place-scoped, so a foreign row means the response does
      // not match the request; rendering it would put another place's assets
      // under this place's actions. Nothing is filtered or corrected: the
      // gallery refuses to load and says so.
      if (rows.any((a) => !place.owns(a))) {
        _items = const [];
        _ownerMismatch = true;
        _status = AdminLoadStatus.error;
        _error = null;
        notifyListeners();
        return;
      }
      _items = rows;
      _status = AdminLoadStatus.ready;
    } else {
      _items = const [];
      _status = adminStatusFor(result.errorKind);
      _error = result.message;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  // ── mutations ─────────────────────────────────────────────────────────────

  /// `POST /api/admin/media` against the selected place.
  ///
  /// The owner is never taken from the form: it is the place the operator is
  /// already looking at, so a create cannot silently target something else.
  Future<bool> createMedia({
    required String url,
    required AdminMediaType mediaType,
    String? thumbnailUrl,
    String? altText,
    int? sortOrder,
    bool cover = false,
  }) {
    final place = _owner;
    if (place == null || _ownerMismatch) return Future.value(false);
    return _mutate(() => api.createAdminMedia(
          ownerType: place.type.wire,
          ownerId: place.id,
          url: url,
          mediaType: mediaType.wire,
          thumbnailUrl: thumbnailUrl,
          altText: altText,
          sortOrder: sortOrder,
          cover: cover ? true : null,
        ));
  }

  /// D3D — every write target must be a row this gallery actually loaded, for
  /// the owner this screen is bound to.
  ///
  /// Without it, a mutation takes whatever asset object it is handed: a stale
  /// row kept from a previously open place, or an id assembled anywhere else,
  /// would reach the backend under the current operator's session. Membership
  /// is checked by identity *and* by owner, so neither half alone is enough.
  bool ownsAsset(AdminMediaAsset asset) {
    final place = _owner;
    if (place == null || _ownerMismatch) return false;
    if (!place.owns(asset)) return false;
    return _items.any((a) => a.id == asset.id);
  }

  /// `PUT /api/admin/media/{id}`.
  ///
  /// `ownerType`/`ownerId` come from the asset itself, because the backend
  /// ignores them and an update may not re-target an asset.
  Future<bool> updateMedia(
    AdminMediaAsset asset, {
    required String url,
    required AdminMediaType mediaType,
    String? thumbnailUrl,
    String? altText,
    int? sortOrder,
    bool? cover,
  }) {
    final ownerId = asset.ownerId;
    if (ownerId == null || !ownsAsset(asset)) return Future.value(false);
    return _mutate(() => api.updateAdminMedia(
          asset.id,
          ownerType: asset.ownerType.wire,
          ownerId: ownerId,
          url: url,
          mediaType: mediaType.wire,
          thumbnailUrl: thumbnailUrl,
          altText: altText,
          sortOrder: sortOrder,
          cover: cover,
        ));
  }

  /// Takes the asset rather than a bare id: an id alone carries no owner, so
  /// there would be nothing to check it against.
  Future<bool> deactivateMedia(AdminMediaAsset asset) {
    if (!ownsAsset(asset)) return Future.value(false);
    return _mutate(() => api.deactivateAdminMedia(asset.id));
  }

  /// Only an active IMAGE can become the cover; the backend answers 404 for an
  /// inactive asset and 400 for a non-image, so the UI does not offer either.
  Future<bool> setCover(AdminMediaAsset asset) {
    if (!canSetCover(asset)) return Future.value(false);
    return _mutate(() => api.setAdminMediaCover(asset.id));
  }

  bool canSetCover(AdminMediaAsset asset) =>
      ownsAsset(asset) &&
      asset.active &&
      asset.mediaType.canBeCover &&
      !asset.cover;

  /// Moves one asset one position and submits the **whole** gallery's ordering.
  ///
  /// The backend rejects a repeated `sortOrder`, so a single-row patch is not
  /// expressible: positions are renumbered 0..n-1 across the gallery, which is
  /// also what resolves any pre-existing tie. Nothing is reordered locally —
  /// the list is re-read afterwards.
  Future<bool> moveMedia(AdminMediaAsset asset, {required bool up}) {
    if (!ownsAsset(asset)) return Future.value(false);
    final index = _items.indexWhere((a) => a.id == asset.id);
    if (index < 0) return Future.value(false);
    final target = up ? index - 1 : index + 1;
    if (target < 0 || target >= _items.length) return Future.value(false);

    final reordered = [..._items];
    final moved = reordered.removeAt(index);
    reordered.insert(target, moved);

    return _mutate(() => api.reorderAdminMedia([
          for (var i = 0; i < reordered.length; i++)
            AdminMediaOrder(mediaId: reordered[i].id, sortOrder: i),
        ])).then((ok) => ok);
  }

  bool canMoveUp(AdminMediaAsset asset) =>
      _items.length > 1 && _items.first.id != asset.id;

  bool canMoveDown(AdminMediaAsset asset) =>
      _items.length > 1 && _items.last.id != asset.id;

  /// One path for every media mutation.
  ///
  /// A success re-reads the gallery rather than patching locally, because a
  /// mutation routinely changes rows it was not given: setting a cover clears
  /// the previous one, deactivating a cover clears the flag, and a reorder
  /// rewrites every position. An `uncertain` outcome survives that reload — the
  /// operator must look before retrying, since deactivation has no undo.
  Future<bool> _mutate(
    Future<CollectionApiResult<Object?>> Function() send,
  ) async {
    if (_mutating) return false;
    _mutating = true;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();

    final result = await send();
    _mutating = false;

    if (result.success) {
      _mutationError = null;
      // Recorded before the reload: the place's own detail carries a cover URL
      // and a gallery list, and this is what tells the shell they are now out
      // of date. A visit that changed nothing leaves it false and costs no
      // extra read.
      _galleryChanged = true;
      notifyListeners();
      await load();
      return true;
    }

    _mutationUncertain = result.errorKind == ApiErrorKind.uncertain;
    _mutationError = result.message;
    notifyListeners();
    if (_mutationUncertain) {
      await load();
      // load() clears the transient banners, but the uncertainty outlives the
      // reload: there is no reactivate endpoint, so a blind retry after an
      // unanswered deactivate is exactly what must not happen.
      _mutationUncertain = true;
      _mutationError = null;
      notifyListeners();
    }
    return false;
  }

  /// Clears a mutation banner the operator has read.
  void dismissMutationNotice() {
    if (!_mutationUncertain && _mutationError == null) return;
    _mutationUncertain = false;
    _mutationError = null;
    notifyListeners();
  }
}
