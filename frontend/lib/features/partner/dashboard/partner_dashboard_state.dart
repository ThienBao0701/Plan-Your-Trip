import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_dashboard_models.dart';
import '../../../core/partner/partner_models.dart';

/// Where one dashboard panel stands. Each panel loads and fails independently:
/// a finance outage must not blank the occupancy chart, and vice versa.
///
/// There is deliberately no `empty` member. Emptiness is a property of the
/// *data* (`totalBookings == 0`, an empty activity list), so it is derived at
/// render time from a `ready` section rather than being a fourth status that
/// every caller has to keep in sync with the payload.
enum PartnerSectionStatus { idle, loading, ready, failed }

/// One independently-loaded dashboard panel.
@immutable
class PartnerSection<T> {
  final PartnerSectionStatus status;
  final T? data;
  final ApiErrorKind? errorKind;
  final String? message;

  const PartnerSection._(this.status, this.data, this.errorKind, this.message);

  const PartnerSection.idle()
      : this._(PartnerSectionStatus.idle, null, null, null);

  const PartnerSection.loading()
      : this._(PartnerSectionStatus.loading, null, null, null);

  const PartnerSection.ready(T value)
      : this._(PartnerSectionStatus.ready, value, null, null);

  const PartnerSection.failed(ApiErrorKind? kind, [String? message])
      : this._(PartnerSectionStatus.failed, null, kind, message);

  bool get isLoading =>
      status == PartnerSectionStatus.loading ||
      status == PartnerSectionStatus.idle;
  bool get isReady => status == PartnerSectionStatus.ready && data != null;
  bool get isFailed => status == PartnerSectionStatus.failed;

  /// True when the failure is one the whole workspace should handle rather than
  /// this panel — the session is gone, or the profile is no longer admitted.
  bool get isSessionLevelFailure =>
      errorKind == ApiErrorKind.unauthorized ||
      errorKind == ApiErrorKind.forbidden ||
      errorKind == ApiErrorKind.notFound;

  static PartnerSection<T> fromResult<T>(CollectionApiResult<T> result) =>
      result.success && result.data != null
          ? PartnerSection.ready(result.data as T)
          : PartnerSection.failed(result.errorKind, result.message);
}

/// The dashboard's analytics window.
///
/// [last30] is the backend's own default (`resolveRange`: `to = today`,
/// `from = to - 29`). Selecting it sends **no** date parameters at all, so the
/// server applies its default rather than the client restating it — which also
/// makes "is this the default scope?" a precise question the state can answer.
enum PartnerDashboardRange {
  last7,
  last30,
  last90;

  bool get isBackendDefault => this == PartnerDashboardRange.last30;

  /// Inclusive day count the window covers.
  int get days => switch (this) {
        PartnerDashboardRange.last7 => 7,
        PartnerDashboardRange.last30 => 30,
        PartnerDashboardRange.last90 => 90,
      };

  /// Resolved `[from, to]` mirroring `resolveRange`: `to` is today and `from` is
  /// `to - (days - 1)`, so the window is inclusive on both ends.
  ({DateTime from, DateTime to}) resolve([DateTime? now]) {
    final today = now ?? DateTime.now();
    final to = DateTime(today.year, today.month, today.day);
    return (from: to.subtract(Duration(days: days - 1)), to: to);
  }
}

/// State for the Partner Dashboard.
///
/// A **feature-scoped** `ChangeNotifier`, deliberately separate from
/// `PartnerState`: `PartnerState` owns workspace identity, lifecycle status and
/// property scope, and must stay small. Dashboard payloads live and die with
/// this screen. This introduces no new state-management system — same
/// `ChangeNotifier` + `InheritedNotifier` paradigm the app already uses.
///
/// ## Request policy
///
/// Six endpoints load in parallel on a full refresh:
///   1. `GET /api/partner/dashboard`                  (unscoped, today)
///   2. `GET /api/partner/analytics/overview`         (scoped)
///   3. `GET /api/partner/analytics/occupancy`        (scoped)
///   4. `GET /api/partner/analytics/revenue`          (scoped)
///   5. `GET /api/partner/extranet/activity-logs`     (unscoped)
///   6. `GET /api/partner/extranet/menu`              (unscoped)
///
/// `GET /api/partner/finance/overview` is deliberately **not** a seventh call at
/// the default scope: `GET /api/partner/extranet/home`, which `PartnerState`
/// has already fetched, embeds the identical `PartnerFinanceOverviewResponse`
/// record as `financeSummary`, computed at exactly that scope. Requesting it
/// again would be the same bytes over a second connection. As soon as the
/// property or date scope narrows, the embedded copy no longer describes the
/// selection and the standalone endpoint is called with the active parameters.
class PartnerDashboardState extends ChangeNotifier {
  final ApiClient api;

  PartnerDashboardState({required this.api});

  PartnerDashboardRange _range = PartnerDashboardRange.last30;
  int? _hotelId;

  PartnerSection<PartnerBookingDashboard> _operations =
      const PartnerSection.idle();
  PartnerSection<PartnerAnalyticsOverview> _performance =
      const PartnerSection.idle();
  PartnerSection<PartnerOccupancyAnalytics> _occupancy =
      const PartnerSection.idle();
  PartnerSection<PartnerRevenueAnalytics> _revenue =
      const PartnerSection.idle();
  PartnerSection<PartnerFinanceOverview> _finance = const PartnerSection.idle();
  PartnerSection<List<PartnerActivityLogEntry>> _activity =
      const PartnerSection.idle();
  PartnerSection<List<PartnerMenuItem>> _menu = const PartnerSection.idle();

  DateTime? _lastLoadedAt;
  bool _loading = false;
  int _loadToken = 0;

  PartnerDashboardRange get range => _range;

  /// The property the analytics panels are scoped to. Null means "every
  /// property the backend authorizes", which is also the backend's default.
  int? get hotelId => _hotelId;

  /// True while the client is at the exact scope `extranet/home` used, i.e. the
  /// embedded `financeSummary` is a valid description of the selection.
  bool get isDefaultScope => _hotelId == null && _range.isBackendDefault;

  PartnerSection<PartnerBookingDashboard> get operations => _operations;
  PartnerSection<PartnerAnalyticsOverview> get performance => _performance;
  PartnerSection<PartnerOccupancyAnalytics> get occupancy => _occupancy;
  PartnerSection<PartnerRevenueAnalytics> get revenue => _revenue;
  PartnerSection<PartnerFinanceOverview> get finance => _finance;
  PartnerSection<List<PartnerActivityLogEntry>> get activity => _activity;
  PartnerSection<List<PartnerMenuItem>> get menu => _menu;

  bool get isLoading => _loading;

  /// When the last completed load finished — the dashboard shows this so a
  /// stale console is visibly stale rather than silently wrong.
  DateTime? get lastLoadedAt => _lastLoadedAt;

  /// Menu entries carrying a positive badge, in the backend's own order. These
  /// drive the "needs attention" rail; a null badge is never shown as zero.
  List<PartnerMenuItem> get attentionItems => _menu.isReady
      ? _menu.data!.where((item) => item.needsAttention).toList(growable: false)
      : const [];

  /// True when every panel failed with a session-level status. The screen then
  /// defers to the workspace-level view instead of showing seven identical
  /// error cards.
  bool get isWholeWorkspaceFailure {
    final sections = <PartnerSection<Object?>>[
      _operations,
      _performance,
      _occupancy,
      _revenue,
      _activity,
      _menu,
    ];
    return sections.every((s) => s.isFailed && s.isSessionLevelFailure);
  }

  /// The first session-level error kind seen, so the caller can decide whether
  /// this is a 401, a 403 or a 404 without reaching into each section.
  ApiErrorKind? get sessionFailureKind {
    for (final s in <PartnerSection<Object?>>[
      _operations,
      _performance,
      _occupancy,
      _revenue,
      _activity,
      _menu,
    ]) {
      if (s.isFailed && s.isSessionLevelFailure) return s.errorKind;
    }
    return null;
  }

  /// Loads or reloads every panel.
  ///
  /// [workspace] is `PartnerState.overview`, already fetched from
  /// `extranet/home`; its embedded `financeSummary` seeds the finance panel at
  /// the default scope. Passing null simply forces the standalone finance call.
  Future<void> load({PartnerWorkspaceOverview? workspace}) async {
    final token = ++_loadToken;
    _loading = true;
    _operations = const PartnerSection.loading();
    _performance = const PartnerSection.loading();
    _occupancy = const PartnerSection.loading();
    _revenue = const PartnerSection.loading();
    _finance = const PartnerSection.loading();
    _activity = const PartnerSection.loading();
    _menu = const PartnerSection.loading();
    notifyListeners();

    final seededFinance = isDefaultScope ? workspace?.financeSummary : null;

    // Only send date parameters when the selection differs from the backend's
    // own default window, so the server stays the single source of truth for
    // what "recent" means.
    final DateTime? from;
    final DateTime? to;
    if (_range.isBackendDefault) {
      from = null;
      to = null;
    } else {
      final resolved = _range.resolve();
      from = resolved.from;
      to = resolved.to;
    }

    final results = await Future.wait<Object>([
      api.getPartnerBookingDashboard(),
      api.getPartnerAnalyticsOverview(hotelId: _hotelId, from: from, to: to),
      api.getPartnerOccupancyAnalytics(hotelId: _hotelId, from: from, to: to),
      api.getPartnerRevenueAnalytics(hotelId: _hotelId, from: from, to: to),
      api.getPartnerActivityLogs(),
      api.getPartnerMenu(),
      if (seededFinance == null)
        api.getPartnerFinanceOverview(hotelId: _hotelId, from: from, to: to),
    ]);

    // A newer load started while this one was in flight; its results win.
    if (token != _loadToken) return;

    _operations = PartnerSection.fromResult(
        results[0] as CollectionApiResult<PartnerBookingDashboard>);
    _performance = PartnerSection.fromResult(
        results[1] as CollectionApiResult<PartnerAnalyticsOverview>);
    _occupancy = PartnerSection.fromResult(
        results[2] as CollectionApiResult<PartnerOccupancyAnalytics>);
    _revenue = PartnerSection.fromResult(
        results[3] as CollectionApiResult<PartnerRevenueAnalytics>);
    _activity = PartnerSection.fromResult(
        results[4] as CollectionApiResult<List<PartnerActivityLogEntry>>);
    _menu = PartnerSection.fromResult(
        results[5] as CollectionApiResult<List<PartnerMenuItem>>);
    _finance = seededFinance != null
        ? PartnerSection.ready(seededFinance)
        : PartnerSection.fromResult(
            results[6] as CollectionApiResult<PartnerFinanceOverview>);

    _lastLoadedAt = DateTime.now();
    _loading = false;
    notifyListeners();
  }

  /// Switches the analytics window and reloads. No-op when unchanged.
  Future<void> selectRange(
    PartnerDashboardRange next, {
    PartnerWorkspaceOverview? workspace,
  }) async {
    if (next == _range) return;
    _range = next;
    notifyListeners();
    await load(workspace: workspace);
  }

  /// Narrows the analytics panels to one property, or back to all of them.
  ///
  /// [authorizedIds] is `PartnerState.properties` — the list the backend itself
  /// returned. An id outside it is ignored rather than sent: the client must
  /// never invent scope, and an unowned `hotelId` is a 404 anyway.
  Future<void> selectProperty(
    int? propertyId, {
    required Iterable<int> authorizedIds,
    PartnerWorkspaceOverview? workspace,
  }) async {
    if (propertyId != null && !authorizedIds.contains(propertyId)) return;
    if (propertyId == _hotelId) return;
    _hotelId = propertyId;
    notifyListeners();
    await load(workspace: workspace);
  }

  /// Drops every payload. Called when the partner session identity changes.
  void reset() {
    _loadToken++;
    _range = PartnerDashboardRange.last30;
    _hotelId = null;
    _operations = const PartnerSection.idle();
    _performance = const PartnerSection.idle();
    _occupancy = const PartnerSection.idle();
    _revenue = const PartnerSection.idle();
    _finance = const PartnerSection.idle();
    _activity = const PartnerSection.idle();
    _menu = const PartnerSection.idle();
    _lastLoadedAt = null;
    _loading = false;
    notifyListeners();
  }
}
