import 'package:flutter/foundation.dart';

import '../../core/admin/admin_models.dart';
import '../../core/network/api_client.dart';
import 'admin_paged_state.dart';
import 'widgets/admin_widgets.dart';

/// The paginated Admin Partner roster — `GET /api/admin/partners`.
///
/// Paging, sorting and stale-response protection all come from
/// [AdminPagedState]; this class contributes only the endpoint and the three
/// filters the backend actually supports. There is no date filter because the
/// endpoint has none, and no client-side filtering of any kind: the grid shows
/// exactly the page the server returned.
class AdminPartnersState extends AdminPagedState<AdminPartnerRow> {
  AdminPartnersState({required super.api})
      : super(defaultSortField: 'createdAt');

  /// Mirrors `PartnerProfileService.PARTNER_SORT_FIELDS` exactly. Offering a
  /// field the allowlist omits would give the operator a control that answers
  /// 400.
  static const List<String> sortFields = [
    'createdAt',
    'updatedAt',
    'businessName',
    'verificationStatus',
    'submittedAt',
    'approvedAt',
    'rejectedAt',
    'id',
  ];

  /// The five `PartnerVerificationStatus` values, in lifecycle order.
  static const List<String> statusValues = [
    'DRAFT',
    'SUBMITTED',
    'APPROVED',
    'REJECTED',
    'SUSPENDED',
  ];

  /// `BusinessType` exactly as the backend enum declares it.
  static const List<String> businessTypeValues = [
    'HOTEL',
    'RESTAURANT',
    'CAFE',
    'TOUR_OPERATOR',
    'TRANSPORT',
    'OTHER',
  ];

  String? _statusFilter;
  String? _businessTypeFilter;
  String _query = '';

  String? get statusFilter => _statusFilter;
  String? get businessTypeFilter => _businessTypeFilter;
  String get query => _query;

  bool get hasFilters =>
      _statusFilter != null || _businessTypeFilter != null || _query.isNotEmpty;

  @override
  Future<CollectionApiResult<AdminPage<AdminPartnerRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      api.getAdminPartners(
        verificationStatus: _statusFilter,
        businessType: _businessTypeFilter,
        query: _query.isEmpty ? null : _query,
        page: page,
        size: size,
        sort: sort,
      );

  Future<void> setStatusFilter(String? status) {
    if (status == _statusFilter) return Future.value();
    _statusFilter = status;
    return load(resetToFirstPage: true);
  }

  Future<void> setBusinessTypeFilter(String? type) {
    if (type == _businessTypeFilter) return Future.value();
    _businessTypeFilter = type;
    return load(resetToFirstPage: true);
  }

  Future<void> setQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == _query) return Future.value();
    _query = trimmed;
    return load(resetToFirstPage: true);
  }

  Future<void> clearFilters() {
    if (!hasFilters) return Future.value();
    _statusFilter = null;
    _businessTypeFilter = null;
    _query = '';
    return load(resetToFirstPage: true);
  }

  @override
  void reset() {
    _statusFilter = null;
    _businessTypeFilter = null;
    _query = '';
    super.reset();
  }
}

/// One partner's detail, across the four sections the D2B freeze permits.
///
/// <h4>Why the canonical read gates the others</h4>
///
/// `GET /{id}/team` and `GET /{id}/activity-logs` answer **200 with an empty
/// body** for a partner id that does not exist — they query child tables with
/// no existence check (D2B finding D2A-F3). Loading all four sections in
/// parallel would therefore render "this partner has no team, no activity" for
/// a partner that was never there.
///
/// So [load] resolves the canonical `GET /{id}` first. Only when that succeeds
/// are the sub-resources fetched, and a 404 there becomes [profileStatus] =
/// `notFound` for the whole screen. After that gate, each section carries its
/// own status so one failing tab does not blank the others.
class AdminPartnerDetailState extends ChangeNotifier {
  final ApiClient api;
  final int partnerId;

  AdminPartnerDetailState({required this.api, required this.partnerId});

  static const int activityPageSize = 20;

  int _loadToken = 0;

  AdminLoadStatus _profileStatus = AdminLoadStatus.idle;
  AdminLoadStatus _detailStatus = AdminLoadStatus.idle;
  AdminLoadStatus _teamStatus = AdminLoadStatus.idle;
  AdminLoadStatus _settingsStatus = AdminLoadStatus.idle;
  AdminLoadStatus _activityStatus = AdminLoadStatus.idle;

  String? _profileError;
  AdminPartnerRow? _profile;
  AdminPartnerDetail? _detail;
  List<AdminPartnerTeamMember> _team = const [];
  AdminPartnerSettings? _settings;
  AdminPage<AdminPartnerActivityRow> _activity =
      AdminPage.empty<AdminPartnerActivityRow>();
  int _activityPageIndex = 0;

  /// Set while a lifecycle mutation is in flight, so the action bar can disable
  /// itself rather than allowing a double submit.
  bool _mutating = false;
  String? _mutationError;

  /// True when a mutation's outcome is genuinely unknown (a timeout, or a
  /// success that did not decode). Never rendered as either success or failure.
  bool _mutationUncertain = false;

  AdminLoadStatus get profileStatus => _profileStatus;
  AdminLoadStatus get detailStatus => _detailStatus;
  AdminLoadStatus get teamStatus => _teamStatus;
  AdminLoadStatus get settingsStatus => _settingsStatus;
  AdminLoadStatus get activityStatus => _activityStatus;

  String? get profileError => _profileError;
  AdminPartnerRow? get profile => _profile;
  AdminPartnerDetail? get detail => _detail;
  List<AdminPartnerTeamMember> get team => _team;
  AdminPartnerSettings? get settings => _settings;
  AdminPage<AdminPartnerActivityRow> get activity => _activity;

  bool get isMutating => _mutating;
  String? get mutationError => _mutationError;
  bool get mutationUncertain => _mutationUncertain;

  bool get isLoading => _profileStatus == AdminLoadStatus.loading;
  bool get isReady => _profileStatus == AdminLoadStatus.ready;
  bool get isNotFound => _profileStatus == AdminLoadStatus.notFound;

  AdminPartnerStatus get status =>
      _profile?.status ?? AdminPartnerStatus.unknown;

  /// The action bar renders only for a state the backend accepts. Every other
  /// state would answer 422, so no control is offered.
  bool get canApproveOrReject => isReady && status.canApproveOrReject;
  bool get canSuspend => isReady && status.canSuspend;

  Future<void> load() async {
    final token = ++_loadToken;
    _profileStatus = AdminLoadStatus.loading;
    _profileError = null;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();

    final result = await api.getAdminPartner(partnerId);
    if (token != _loadToken) return;

    if (!result.success || result.data == null) {
      _profileStatus = adminStatusFor(result.errorKind);
      _profileError = result.message;
      // The partner is not established, so the sub-resources are not requested
      // at all — their empty 200 would be indistinguishable from real data.
      _detailStatus = AdminLoadStatus.idle;
      _teamStatus = AdminLoadStatus.idle;
      _settingsStatus = AdminLoadStatus.idle;
      _activityStatus = AdminLoadStatus.idle;
      _detail = null;
      _team = const [];
      _settings = null;
      _activity = AdminPage.empty<AdminPartnerActivityRow>();
      notifyListeners();
      return;
    }

    _profile = result.data;
    _profileStatus = AdminLoadStatus.ready;
    notifyListeners();

    await Future.wait([
      _loadDetail(token),
      _loadTeam(token),
      _loadSettings(token),
      loadActivity(page: 0, token: token),
    ]);
  }

  Future<void> refresh() => load();

  Future<void> _loadDetail(int token) async {
    _detailStatus = AdminLoadStatus.loading;
    notifyListeners();
    final r = await api.getAdminPartnerDetail(partnerId);
    if (token != _loadToken) return;
    _detail = r.data;
    _detailStatus =
        r.success && r.data != null ? AdminLoadStatus.ready : adminStatusFor(r.errorKind);
    notifyListeners();
  }

  Future<void> _loadTeam(int token) async {
    _teamStatus = AdminLoadStatus.loading;
    notifyListeners();
    final r = await api.getAdminPartnerTeam(partnerId);
    if (token != _loadToken) return;
    _team = r.data ?? const [];
    _teamStatus =
        r.success ? AdminLoadStatus.ready : adminStatusFor(r.errorKind);
    notifyListeners();
  }

  Future<void> _loadSettings(int token) async {
    _settingsStatus = AdminLoadStatus.loading;
    notifyListeners();
    final r = await api.getAdminPartnerSettings(partnerId);
    if (token != _loadToken) return;
    _settings = r.data;
    _settingsStatus = r.success && r.data != null
        ? AdminLoadStatus.ready
        : adminStatusFor(r.errorKind);
    notifyListeners();
  }

  Future<void> loadActivity({required int page, int? token}) async {
    final t = token ?? _loadToken;
    if (page < 0) return;
    _activityStatus = AdminLoadStatus.loading;
    notifyListeners();
    final r = await api.getAdminPartnerActivity(partnerId,
        page: page, size: activityPageSize);
    if (t != _loadToken) return;
    if (r.success && r.data != null) {
      _activity = r.data!;
      _activityPageIndex = _activity.page;
      _activityStatus = AdminLoadStatus.ready;
    } else {
      _activityStatus = adminStatusFor(r.errorKind);
    }
    notifyListeners();
  }

  Future<void> goToActivityPage(int page) {
    if (page == _activityPageIndex) return Future.value();
    return loadActivity(page: page);
  }

  /// `POST /{id}/approve`. Returns true only on a confirmed success.
  Future<bool> approve() => _mutate(() => api.approveAdminPartner(partnerId));

  /// `POST /{id}/reject` — the backend requires a reason.
  Future<bool> reject(String reason) =>
      _mutate(() => api.rejectAdminPartner(partnerId, reason: reason));

  /// `POST /{id}/suspend` — **irreversible**, and the caller is expected to
  /// have obtained an explicit acknowledgement first.
  Future<bool> suspend({String? reason}) =>
      _mutate(() => api.suspendAdminPartner(partnerId, reason: reason));

  Future<bool> _mutate(
      Future<CollectionApiResult<AdminPartnerRow>> Function() send) async {
    if (_mutating) return false;
    _mutating = true;
    _mutationError = null;
    _mutationUncertain = false;
    notifyListeners();

    final result = await send();
    _mutating = false;

    if (result.success && result.data != null) {
      // Adopt the server's own updated profile rather than assuming the new
      // state, then reload so the counts and the partner's activity log reflect
      // whatever else the transition did server-side.
      _profile = result.data;
      _mutationError = null;
      notifyListeners();
      await load();
      return true;
    }

    _mutationUncertain = result.errorKind == ApiErrorKind.uncertain;
    _mutationError = result.message;
    notifyListeners();
    if (_mutationUncertain) {
      // The action may have committed. Re-read rather than leaving the screen
      // showing a state that might already be stale.
      await load();
      // load() clears the transient banners, but the uncertainty outlives the
      // reload: the operator still does not know whether the action took
      // effect, and that is exactly when they must not simply retry. Restored
      // after the reload rather than suppressed by it.
      _mutationUncertain = true;
      _mutationError = null;
      notifyListeners();
    }
    return false;
  }
}
