import 'package:flutter/foundation.dart';

import '../../core/admin/admin_models.dart';
import '../../core/network/api_client.dart';
import 'widgets/admin_widgets.dart';

/// D10 — the Admin Reference Data surfaces: amenities and categories.
///
/// <h4>Why this is not an `AdminPagedState`</h4>
///
/// Every other admin grid consumes the backend's `PageResponse<T>` envelope,
/// and `AdminPagedState` is typed on exactly that. `GET /api/admin/amenities`
/// and `GET /api/admin/categories` return a **bare JSON array** — no `page`, no
/// `size`, no `totalElements`. Reusing the paged base would mean manufacturing
/// an envelope the server never sent and rendering a pagination bar over a
/// single, complete list. So this hierarchy exists instead, modelled on
/// `AdminMediaState`, which is the console's other unpaginated, mutating
/// surface.
///
/// <h4>What it never does</h4>
///
/// There is no optimistic patching. Every confirmed mutation is followed by a
/// re-read, because the server owns `slug` derivation (an absent slug is
/// generated from the name), `createdAt`/`updatedAt`, and `active`. And there
/// is no delete — the backend exposes none, for either domain, for any role.
abstract class AdminReferenceListState<T> extends ChangeNotifier {
  final ApiClient api;

  AdminReferenceListState({required this.api});

  /// Guards against a slow earlier response overwriting a newer one — the same
  /// `_loadToken` convention the partner modules and `AdminPagedState` use.
  int _loadToken = 0;

  AdminLoadStatus _status = AdminLoadStatus.idle;
  String? _error;
  List<T> _items = const [];

  bool _mutating = false;
  String? _mutationError;
  bool _mutationUncertain = false;
  bool _mutationConflict = false;

  AdminLoadStatus get status => _status;
  String? get errorMessage => _error;
  List<T> get items => _items;

  bool get isLoading => _status == AdminLoadStatus.loading;
  bool get isReady => _status == AdminLoadStatus.ready;

  /// True only when the read succeeded and the server genuinely has no rows —
  /// never for a failure, so "nothing here" is never shown for an error.
  bool get isEmpty => isReady && _items.isEmpty;

  bool get isMutating => _mutating;
  String? get mutationError => _mutationError;

  /// True when a mutation went unanswered. The write may have landed, so the
  /// list is reloaded and the operator is told to look before retrying.
  bool get mutationUncertain => _mutationUncertain;

  /// True when the last mutation was refused with a 409. Both domains have
  /// exactly one conflict axis — a duplicate slug — so the UI can name the
  /// cause even when the server's own message does not survive sanitisation.
  bool get mutationConflict => _mutationConflict;

  /// Performs the list read. The only thing a subclass must supply.
  Future<CollectionApiResult<List<T>>> fetch();

  Future<void> load() async {
    final token = ++_loadToken;
    _status = AdminLoadStatus.loading;
    _error = null;
    notifyListeners();

    final result = await fetch();
    if (token != _loadToken) return;

    if (result.success && result.data != null) {
      // Kept in the order the server sent. The backend applies no ordering of
      // its own and `sortOrder` is stored but never used to sort anything, so
      // re-sorting here would invent a stable order the product has not
      // defined. The column is shown; the list is not rearranged.
      _items = result.data!;
      _status = AdminLoadStatus.ready;
      _error = null;
    } else {
      _items = const [];
      _status = adminStatusFor(result.errorKind);
      _error = result.message;
    }
    notifyListeners();
  }

  Future<void> refresh() => load();

  /// One path for every reference-data mutation.
  ///
  /// Single-flight: a second request is refused while one is in flight. A
  /// confirmed success re-reads the list rather than patching locally — the
  /// server may have derived the slug from the name, and it always stamps
  /// `updatedAt`. An `uncertain` outcome survives the reload, because the
  /// operator must look at the list before trying again.
  @protected
  Future<bool> mutate(
    Future<CollectionApiResult<Object?>> Function() send,
  ) async {
    if (_mutating) return false;
    _mutating = true;
    _mutationError = null;
    _mutationUncertain = false;
    _mutationConflict = false;
    notifyListeners();

    final result = await send();
    _mutating = false;

    if (result.success) {
      _mutationError = null;
      notifyListeners();
      await load();
      return true;
    }

    _mutationUncertain = result.errorKind == ApiErrorKind.uncertain;
    _mutationConflict = result.errorKind == ApiErrorKind.conflict;
    _mutationError = result.message;
    notifyListeners();
    if (_mutationUncertain) {
      await load();
      // load() clears the transient banners, but the uncertainty outlives the
      // reload: a blind retry of an unanswered create is how duplicates and
      // confusing 409s happen.
      _mutationUncertain = true;
      _mutationError = null;
      notifyListeners();
    }
    return false;
  }

  /// Clears a mutation banner the operator has read.
  void dismissMutationNotice() {
    if (!_mutationUncertain && !_mutationConflict && _mutationError == null) {
      return;
    }
    _mutationUncertain = false;
    _mutationConflict = false;
    _mutationError = null;
    notifyListeners();
  }

  /// Drops all rows. Called when the admin session ends.
  void reset() {
    _loadToken++;
    _status = AdminLoadStatus.idle;
    _error = null;
    _items = const [];
    _mutating = false;
    _mutationError = null;
    _mutationUncertain = false;
    _mutationConflict = false;
    notifyListeners();
  }
}

/// `/api/admin/amenities` — list, create, update, set CMS status.
class AdminAmenitiesState extends AdminReferenceListState<AdminAmenity> {
  AdminAmenitiesState({required super.api});

  @override
  Future<CollectionApiResult<List<AdminAmenity>>> fetch() =>
      api.getAdminAmenities();

  /// The values the group picker offers — the distinct groups actually present
  /// in the loaded rows, plus [current] so editing a row never silently
  /// rewrites its stored group. Falls back to the seeded vocabulary only when
  /// no row carries a group at all.
  List<String> groupOptions({String? current}) =>
      AdminReferenceVocabulary.optionsFrom(
        items.map((a) => a.groupName),
        fallback: AdminReferenceVocabulary.seededGroupNames,
        current: current,
      );

  Future<bool> create({
    required String name,
    String? slug,
    String? icon,
    String? groupName,
    String? description,
    int? sortOrder,
  }) =>
      mutate(() => api.createAdminAmenity(
            name: name,
            slug: slug,
            icon: icon,
            groupName: groupName,
            description: description,
            sortOrder: sortOrder,
          ));

  /// The row's existing slug is passed straight back through: slug is fixed
  /// after creation, so an update can never change it.
  Future<bool> update(
    AdminAmenity row, {
    required String name,
    String? icon,
    String? groupName,
    String? description,
    int? sortOrder,
  }) =>
      mutate(() => api.updateAdminAmenity(
            row.id,
            name: name,
            slug: row.slug,
            icon: icon,
            groupName: groupName,
            description: description,
            sortOrder: sortOrder,
          ));

  Future<bool> setActive(AdminAmenity row, {required bool active}) =>
      mutate(() => api.setAdminAmenityActive(row.id, active: active));
}

/// `/api/admin/categories` — list, create, update, set CMS status.
///
/// The flat list carries `parentId` only, so every hierarchy question the
/// parent picker asks is answered from the rows already loaded.
class AdminCategoriesState extends AdminReferenceListState<AdminCategory> {
  AdminCategoriesState({required super.api});

  @override
  Future<CollectionApiResult<List<AdminCategory>>> fetch() =>
      api.getAdminCategories();

  /// The values the type picker offers. `Category.type` is an unvalidated
  /// `String` on the backend that `CustomerCouponService` matches against
  /// `CouponDefinition.placeType`, so a free-text field here would let a typo
  /// silently break live coupon targeting. The picker is the guard.
  List<String> typeOptions({String? current}) =>
      AdminReferenceVocabulary.optionsFrom(
        items.map((c) => c.type),
        fallback: AdminReferenceVocabulary.seededCategoryTypes,
        current: current,
      );

  /// The row with this id among the loaded rows, or null.
  AdminCategory? byId(int? id) {
    if (id == null) return null;
    for (final c in items) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Display name of [row]'s parent, or null when it is a root or the parent
  /// is not among the loaded rows.
  String? parentNameOf(AdminCategory row) => byId(row.parentId)?.name;

  /// Every id reachable downwards from [categoryId], excluding itself.
  ///
  /// Computed by breadth-first walk over the `parentId` edges in the loaded
  /// rows, with a visited set — so an existing cycle in the data is traversed
  /// once and cannot hang the picker.
  Set<int> descendantIdsOf(int categoryId) {
    final childrenOf = <int, List<int>>{};
    for (final c in items) {
      final p = c.parentId;
      if (p != null) (childrenOf[p] ??= <int>[]).add(c.id);
    }
    final out = <int>{};
    final queue = <int>[...?childrenOf[categoryId]];
    while (queue.isNotEmpty) {
      final id = queue.removeAt(0);
      if (!out.add(id)) continue;
      queue.addAll(childrenOf[id] ?? const <int>[]);
    }
    return out;
  }

  /// The categories the parent picker may offer.
  ///
  /// On create ([editing] null) that is every loaded row. On update it excludes
  /// the category itself and all of its descendants, because either would make
  /// the row its own ancestor.
  ///
  /// **This is a client-side safety guard only.** `CategoryService.fill` sets
  /// the parent with no cycle check of any kind, so the backend will accept a
  /// cycle if one is ever sent. Nothing here should be read as a server
  /// guarantee — the picker simply does not offer the values that create one.
  List<AdminCategory> parentOptions({AdminCategory? editing}) {
    if (editing == null) return List<AdminCategory>.unmodifiable(items);
    final blocked = descendantIdsOf(editing.id)..add(editing.id);
    return List<AdminCategory>.unmodifiable(
      items.where((c) => !blocked.contains(c.id)),
    );
  }

  Future<bool> create({
    required String name,
    String? slug,
    int? parentId,
    String? type,
    String? icon,
    String? color,
    String? coverImageUrl,
    int? sortOrder,
  }) =>
      mutate(() => api.createAdminCategory(
            name: name,
            slug: slug,
            parentId: parentId,
            type: type,
            icon: icon,
            color: color,
            coverImageUrl: coverImageUrl,
            sortOrder: sortOrder,
          ));

  /// As with amenities, the row's slug is passed back unchanged.
  Future<bool> update(
    AdminCategory row, {
    required String name,
    int? parentId,
    String? type,
    String? icon,
    String? color,
    String? coverImageUrl,
    int? sortOrder,
  }) =>
      mutate(() => api.updateAdminCategory(
            row.id,
            name: name,
            slug: row.slug,
            parentId: parentId,
            type: type,
            icon: icon,
            color: color,
            coverImageUrl: coverImageUrl,
            sortOrder: sortOrder,
          ));

  Future<bool> setActive(AdminCategory row, {required bool active}) =>
      mutate(() => api.setAdminCategoryActive(row.id, active: active));
}

/// `/api/admin/locations` — list, create, update, set CMS status.
///
/// <h4>Why several fields are carried but never edited</h4>
///
/// `PUT` is a full replace, and four of the columns it rewrites are ones this
/// console deliberately does not let an operator change:
///
///  * `parentId` — the backend has no cycle guard and does not recompute a
///    subtree after a reparent, so a parent picker here could orphan a whole
///    branch from `/api/locations/roots`;
///  * `fullPath` — caller-supplied, never derived, and **customer-visible**: it
///    rides in `PlaceDto.LocationRef` and the traveller app parses it to show a
///    place's province;
///  * `level` — never derived and validated against nothing;
///  * `latitude`/`longitude` — no range or pairing validation exists.
///
/// So [update] takes only the five editable fields and passes the stored value
/// of every other one straight back. Nothing is cleared by omission.
class AdminLocationsState extends AdminReferenceListState<AdminLocation> {
  AdminLocationsState({required super.api});

  @override
  Future<CollectionApiResult<List<AdminLocation>>> fetch() =>
      api.getAdminLocations();

  // ── client-side filter ────────────────────────────────────────────────────
  //
  // `GET /api/admin/locations` is `repo.findAll()` with no page, sort, filter
  // or search parameter, so the filter is applied here over rows already held.
  // It covers name, slug, code and oldName — the same four columns the
  // backend's own public search query covers, so the two agree on what
  // "matches" means even though this one never leaves the client.

  String _filter = '';

  String get filter => _filter;
  bool get hasFilter => _filter.trim().isNotEmpty;

  void setFilter(String value) {
    if (value == _filter) return;
    _filter = value;
    notifyListeners();
  }

  void clearFilter() => setFilter('');

  /// The rows the grid renders — every loaded row when no filter is set.
  List<AdminLocation> get visibleItems {
    if (!hasFilter) return items;
    return items.where((l) => l.matchesFilter(_filter)).toList(growable: false);
  }

  /// True when rows exist but the filter matches none of them. Distinct from
  /// [isEmpty], so "no results for this search" is never shown as "no
  /// locations exist" — and neither is ever shown for a failed load.
  bool get isFilteredEmpty =>
      isReady && items.isNotEmpty && visibleItems.isEmpty;

  @override
  void reset() {
    _filter = '';
    super.reset();
  }

  // ── hierarchy (read-only) ─────────────────────────────────────────────────

  /// The row with this id among the loaded rows, or null.
  AdminLocation? byId(int? id) {
    if (id == null) return null;
    for (final l in items) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Display name of [row]'s parent, or null when it is a root or the parent is
  /// not among the loaded rows. Resolved from rows already held — the admin API
  /// has no per-id read, so a second request is not an option anyway.
  String? parentNameOf(AdminLocation row) => byId(row.parentId)?.name;

  // ── mutations ─────────────────────────────────────────────────────────────

  /// Creates a **root** location.
  ///
  /// D11 offers no parent control, so `parentId` is always null. `fullPath` is
  /// passed by the caller as the value it previewed, and `level`, `latitude`
  /// and `longitude` are left unset — the backend derives none of them and the
  /// console invents none.
  Future<bool> create({
    required String name,
    required String type,
    String? slug,
    String? code,
    String? oldName,
    String? fullPath,
    int? sortOrder,
  }) =>
      mutate(() => api.createAdminLocation(
            name: name,
            type: type,
            slug: slug,
            code: code,
            oldName: oldName,
            fullPath: fullPath,
            sortOrder: sortOrder,
          ));

  /// Updates the five editable fields and echoes everything else back.
  ///
  /// [code] follows the console's one extra rule: a stored code is never
  /// cleared. A caller passing null or blank for a row that has one keeps the
  /// stored value, so an accidental empty box cannot drop a business key that
  /// `DataInitializer` resolves rows by. Replacing it with a new value is
  /// allowed, and clearing a code that was already absent is a no-op.
  Future<bool> update(
    AdminLocation row, {
    required String name,
    required String type,
    String? code,
    String? oldName,
    int? sortOrder,
  }) {
    final trimmed = code?.trim();
    final nextCode = (trimmed == null || trimmed.isEmpty) ? row.code : trimmed;
    return mutate(() => api.updateAdminLocation(
          row.id,
          name: name,
          type: type,
          code: nextCode,
          oldName: oldName,
          sortOrder: sortOrder,
          // Preserved verbatim — see the class doc.
          slug: row.slug,
          parentId: row.parentId,
          fullPath: row.fullPath,
          level: row.level,
          latitude: row.latitude,
          longitude: row.longitude,
        ));
  }

  Future<bool> setActive(AdminLocation row, {required bool active}) =>
      mutate(() => api.setAdminLocationActive(row.id, active: active));
}
