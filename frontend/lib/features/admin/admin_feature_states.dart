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

  // ── Moderation (D8) ───────────────────────────────────────────────────────
  //
  // `PATCH /api/admin/reviews/{id}/moderate` is the only mutation this grid
  // performs. The backend imposes **no** transition rules — any status may
  // follow any other — so none is invented here. What the server does on top of
  // the status change (rating recalculation, notifying the author on APPROVED
  // and REJECTED, the `REVIEW_MODERATE` audit row) is its business and is not
  // mirrored client-side.

  /// The statuses this console can set. `ReviewStatus` also contains `PENDING`
  /// and `REPORTED`; neither is offered as an action because moving a review
  /// *back* to either is not a moderation decision the product defines.
  static const List<String> moderatableStatuses = [
    'APPROVED',
    'REJECTED',
    'HIDDEN',
  ];

  int? _moderatingId;
  String? _moderationError;
  bool _moderationUncertain = false;

  /// The review currently being moderated, or null. Single-flight: a second
  /// request is refused while one is in flight, because a repeat would notify
  /// the author twice and write a second audit row.
  int? get moderatingId => _moderatingId;
  bool get isModerating => _moderatingId != null;
  bool isModeratingReview(int reviewId) => _moderatingId == reviewId;

  String? get moderationError => _moderationError;

  /// True when a moderation request went unanswered. The write may have landed,
  /// so the page is reloaded and the operator is told to look before retrying.
  bool get moderationUncertain => _moderationUncertain;

  void clearModerationFeedback() {
    if (_moderationError == null && !_moderationUncertain) return;
    _moderationError = null;
    _moderationUncertain = false;
    notifyListeners();
  }

  /// Moderates one review.
  ///
  /// Returns true only on a confirmed 200. Nothing is changed locally on the
  /// way in: on success the current page is re-read, so the row, its
  /// `approvedAt`/`rejectedAt` stamps and the place's recalculated rating all
  /// come from the server. Reloading the *current* page (rather than resetting
  /// to the first) preserves where the operator was.
  Future<bool> moderate(
    int reviewId, {
    required String status,
    String? rejectReason,
  }) async {
    if (_moderatingId != null) return false;
    if (!moderatableStatuses.contains(status)) return false;

    _moderatingId = reviewId;
    _moderationError = null;
    _moderationUncertain = false;
    notifyListeners();

    final result = await api.moderateAdminReview(
      reviewId,
      status: status,
      rejectReason: rejectReason,
    );

    _moderatingId = null;

    if (result.success) {
      notifyListeners();
      // Re-read rather than patching the row: the status change also moves
      // server-side timestamps and the place's aggregate rating.
      await load();
      return true;
    }

    _moderationUncertain = result.errorKind == ApiErrorKind.uncertain;
    _moderationError = result.message;
    notifyListeners();

    if (_moderationUncertain) {
      await load();
      // load() clears transient state, but the uncertainty outlives it: the
      // author may already have been notified, so a blind retry is not safe.
      _moderationUncertain = true;
      _moderationError = null;
      notifyListeners();
    }
    return false;
  }

  @override
  void reset() {
    _status = null;
    _placeId = null;
    _moderatingId = null;
    _moderationError = null;
    _moderationUncertain = false;
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
