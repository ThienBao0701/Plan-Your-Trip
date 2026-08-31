import 'package:flutter/foundation.dart';

import '../../core/admin/admin_models.dart';
import '../../core/network/api_client.dart';
import 'admin_paged_state.dart';
import 'widgets/admin_widgets.dart';

/// Feature-scoped notifiers for the six D1b Admin surfaces.
///
/// One notifier per module, each owning only its own rows — the split proven
/// across the partner phases. `AdminState` holds workspace context and never
/// row data; these hold row data and never workspace context.
///
/// The filter values below are not invented: each list is exactly the set the
/// corresponding backend enum declares, so the UI cannot offer a filter the
/// server would reject.

// ── Dashboard ────────────────────────────────────────────────────────────────

/// `GET /api/admin/analytics/overview`.
///
/// Not paginated (it is a single aggregate object), so it does not extend
/// [AdminPagedState]. It renders only metrics the backend supplies and computes
/// nothing: no derived rates, no client-side revenue arithmetic.
class AdminDashboardState extends ChangeNotifier {
  final ApiClient api;

  AdminDashboardState({required this.api});

  AdminLoadStatus _status = AdminLoadStatus.idle;
  String? _errorMessage;
  AdminDashboardOverview? _overview;
  DateTime? _loadedAt;
  int _loadToken = 0;

  AdminLoadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  AdminDashboardOverview? get overview => _overview;

  /// When this client last received data. Client-side observation, labelled as
  /// such — the endpoint supplies no server timestamp, so nothing is implied
  /// about when the figures were computed.
  DateTime? get loadedAt => _loadedAt;

  bool get isLoading => _status == AdminLoadStatus.loading;
  bool get isReady => _status == AdminLoadStatus.ready;

  Future<void> load() async {
    final token = ++_loadToken;
    _status = AdminLoadStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getAdminOverview();
    if (token != _loadToken) return;

    if (!result.success || result.data == null) {
      _status = adminStatusFor(result.errorKind);
      _errorMessage = result.message;
      notifyListeners();
      return;
    }
    _overview = result.data;
    _loadedAt = DateTime.now();
    _status = AdminLoadStatus.ready;
    notifyListeners();
  }

  Future<void> refresh() => load();

  void reset() {
    _loadToken++;
    _status = AdminLoadStatus.idle;
    _errorMessage = null;
    _overview = null;
    _loadedAt = null;
    notifyListeners();
  }
}

// ── Bookings ─────────────────────────────────────────────────────────────────

class AdminBookingsState extends AdminPagedState<AdminBookingRow> {
  AdminBookingsState({required super.api})
      : super(defaultSortField: 'createdAt');

  /// `BookingStatus` — the backend enum, in full.
  static const List<String> statusValues = [
    'PENDING',
    'CONFIRMED',
    'CHECK_IN_READY',
    'CHECKED_IN',
    'CHECKED_OUT',
    'COMPLETED',
    'CANCELLED',
    'REFUNDED',
    'ARCHIVED',
    'NO_SHOW',
  ];

  /// `AdminPaging` allowlist for this endpoint. Sending anything else is a 400.
  static const List<String> sortFields = [
    'createdAt',
    'checkInDate',
    'checkOutDate',
    'finalPrice',
    'status',
    'bookingCode',
  ];

  String? _status;
  String? get statusFilter => _status;

  Future<void> setStatusFilter(String? value) {
    if (_status == value) return Future.value();
    _status = value;
    return load(resetToFirstPage: true);
  }

  @override
  Future<CollectionApiResult<AdminPage<AdminBookingRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      api.getAdminBookings(
        status: _status,
        page: page,
        size: size,
        sort: sort,
      );

  @override
  void reset() {
    _status = null;
    super.reset();
  }
}

// ── Payments ─────────────────────────────────────────────────────────────────

class AdminPaymentsState extends AdminPagedState<AdminPaymentRow> {
  AdminPaymentsState({required super.api})
      : super(defaultSortField: 'createdAt');

  /// `PaymentStatus` — the backend enum, in full.
  static const List<String> statusValues = [
    'PENDING',
    'PAID',
    'FAILED',
    'CANCELLED',
    'REFUNDED',
  ];

  static const List<String> sortFields = [
    'createdAt',
    'amount',
    'status',
    'paidAt',
    'refundedAt',
  ];

  String? _status;
  int? _bookingId;

  String? get statusFilter => _status;
  int? get bookingIdFilter => _bookingId;

  Future<void> setStatusFilter(String? value) {
    if (_status == value) return Future.value();
    _status = value;
    return load(resetToFirstPage: true);
  }

  Future<void> setBookingIdFilter(int? value) {
    if (_bookingId == value) return Future.value();
    _bookingId = value;
    return load(resetToFirstPage: true);
  }

  @override
  Future<CollectionApiResult<AdminPage<AdminPaymentRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      api.getAdminPayments(
        status: _status,
        bookingId: _bookingId,
        page: page,
        size: size,
        sort: sort,
      );

  @override
  void reset() {
    _status = null;
    _bookingId = null;
    super.reset();
  }
}

// ── Reviews ──────────────────────────────────────────────────────────────────

class AdminReviewsState extends AdminPagedState<AdminReviewRow> {
  AdminReviewsState({required super.api})
      : super(defaultSortField: 'createdAt');

  /// `ReviewStatus` — the backend enum, in full.
  static const List<String> statusValues = [
    'PENDING',
    'APPROVED',
    'REJECTED',
    'HIDDEN',
    'FLAGGED',
  ];

  static const List<String> sortFields = [
    'createdAt',
    'ratingOverall',
    'status',
    'approvedAt',
  ];

  String? _status;
  int? _placeId;

  String? get statusFilter => _status;
  int? get placeIdFilter => _placeId;

  Future<void> setStatusFilter(String? value) {
    if (_status == value) return Future.value();
    _status = value;
    return load(resetToFirstPage: true);
  }

  Future<void> setPlaceIdFilter(int? value) {
    if (_placeId == value) return Future.value();
    _placeId = value;
    return load(resetToFirstPage: true);
  }

  @override
  Future<CollectionApiResult<AdminPage<AdminReviewRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      api.getAdminReviews(
        status: _status,
        placeId: _placeId,
        page: page,
        size: size,
        sort: sort,
      );

  @override
  void reset() {
    _status = null;
    _placeId = null;
    super.reset();
  }
}

// ── Invoices ─────────────────────────────────────────────────────────────────

class AdminInvoicesState extends AdminPagedState<AdminInvoiceRow> {
  AdminInvoicesState({required super.api})
      : super(defaultSortField: 'createdAt');

  /// `InvoiceStatus` — the backend enum, in full.
  static const List<String> statusValues = [
    'ISSUED',
    'PAID',
    'CANCELLED',
    'REFUNDED',
  ];

  static const List<String> sortFields = [
    'createdAt',
    'status',
    'issuedAt',
    'totalAmount',
  ];

  String? _status;
  String? get statusFilter => _status;

  Future<void> setStatusFilter(String? value) {
    if (_status == value) return Future.value();
    _status = value;
    return load(resetToFirstPage: true);
  }

  @override
  Future<CollectionApiResult<AdminPage<AdminInvoiceRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      api.getAdminInvoices(
        status: _status,
        page: page,
        size: size,
        sort: sort,
      );

  @override
  void reset() {
    _status = null;
    super.reset();
  }
}

// ── Activity log ─────────────────────────────────────────────────────────────

/// `GET /api/admin/activity-logs`.
///
/// Ordering is fixed newest-first **by the backend** and is not client
/// controllable — the audit trail deliberately has no sort surface. This state
/// therefore exposes no sort API at all; [sortParameter] is never sent, and the
/// overridden [fetch] ignores its `sort` argument.
class AdminActivityLogState extends AdminPagedState<AdminActivityLogRow> {
  AdminActivityLogState({required super.api})
      : super(defaultSortField: 'createdAt');

  String? _action;
  String? _targetType;
  int? _actorUserId;

  String? get actionFilter => _action;
  String? get targetTypeFilter => _targetType;
  int? get actorUserIdFilter => _actorUserId;

  /// Actions D1a currently writes. Offered as suggestions only — the filter
  /// accepts any string because the backend matches exactly and new verbs will
  /// appear as more mutations are audited.
  static const List<String> knownActions = [
    'PARTNER_APPROVE',
    'PARTNER_REJECT',
    'PARTNER_SUSPEND',
    'REVIEW_MODERATE',
    'PAYMENT_REFUND',
    'BOOKING_STATUS_OVERRIDE',
    'BOOKING_REFUND_TO_CREDITS',
    'GIFT_CARD_ADJUST',
    'LOYALTY_GRANT',
    'TRAVEL_CREDIT_GRANT',
    'TRAVEL_CREDIT_DEDUCT',
  ];

  Future<void> setActionFilter(String? value) {
    if (_action == value) return Future.value();
    _action = value;
    return load(resetToFirstPage: true);
  }

  Future<void> setTargetTypeFilter(String? value) {
    if (_targetType == value) return Future.value();
    _targetType = value;
    return load(resetToFirstPage: true);
  }

  Future<void> setActorUserIdFilter(int? value) {
    if (_actorUserId == value) return Future.value();
    _actorUserId = value;
    return load(resetToFirstPage: true);
  }

  @override
  Future<CollectionApiResult<AdminPage<AdminActivityLogRow>>> fetch({
    required int page,
    required int size,
    required String sort,
  }) =>
      // `sort` is intentionally unused: the trail's ordering is server-fixed.
      api.getAdminActivityLogs(
        actorUserId: _actorUserId,
        action: _action,
        targetType: _targetType,
        page: page,
        size: size,
      );

  @override
  void reset() {
    _action = null;
    _targetType = null;
    _actorUserId = null;
    super.reset();
  }
}
