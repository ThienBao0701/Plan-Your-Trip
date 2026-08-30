import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_booking_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a booking lifecycle action.
enum PartnerBookingActionResult {
  success,
  unauthorized,

  /// 403 — the partner profile exists but is not APPROVED.
  forbidden,

  /// Uniform 404 — unknown booking, or one belonging to another partner.
  /// Indistinguishable by design.
  notFound,

  /// 422 — an illegal status transition, an ineligible status, or a stay
  /// outside the check-in/check-out window. The booking is untouched.
  rejected,

  /// 400 — the request itself was malformed.
  validation,

  failed,

  /// The transition may have committed before the connection dropped. It cannot
  /// be undone, so the caller must re-read rather than retry.
  uncertain,
}

/// Where the Bookings module stands.
enum PartnerBookingsStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — no partner profile.
  notFound,
  error,
}

/// State for the Partner Bookings module.
///
/// Feature-scoped `ChangeNotifier`, the same paradigm as C1–C7. [PartnerState]
/// keeps workspace identity, team role and the selected property; none of that
/// is copied here.
///
/// ## Scope: the list is partner-wide, and the room filter is the only property
/// narrowing the backend actually supports
///
/// `GET /api/partner/bookings` accepts **no `hotelId`** — the service resolves
/// every hotel the partner owns and filters on that whole set. Worse for
/// client-side grouping, `PartnerBookingSummaryResponse` carries **no hotelId
/// either**, so a summary row cannot even be attributed to a property locally.
///
/// What the backend *does* support is `roomId`. Rooms belong to exactly one
/// property, so offering the selected property's rooms as a filter is a real,
/// server-side way to narrow to that property — and it is applied only when the
/// operator picks a room. Nothing is silently scoped.
class PartnerBookingsState extends ChangeNotifier {
  final ApiClient api;

  PartnerBookingsState({required this.api});

  PartnerBookingsStatus _status = PartnerBookingsStatus.idle;
  String? _errorMessage;

  PartnerBookingPage _page = PartnerBookingPage.empty;
  PartnerBookingQuery _query = const PartnerBookingQuery();

  /// Rooms of the selected property, used to offer the `roomId` filter.
  List<PartnerRoom> _rooms = const [];
  int? _loadedPropertyId;

  int? _openBookingId;
  PartnerBookingDetail? _detail;
  PartnerGuestStay? _stay;
  bool _detailLoading = false;
  ApiErrorKind? _detailErrorKind;

  int? _pendingActionBookingId;
  PartnerBookingAction? _pendingAction;

  int _loadToken = 0;
  int _detailToken = 0;

  PartnerBookingsStatus get status => _status;
  String? get errorMessage => _errorMessage;
  PartnerBookingPage get page => _page;
  List<PartnerBookingSummary> get bookings => _page.content;
  PartnerBookingQuery get query => _query;
  List<PartnerRoom> get rooms => List.unmodifiable(_rooms);
  int? get loadedPropertyId => _loadedPropertyId;

  int? get openBookingId => _openBookingId;
  PartnerBookingDetail? get detail => _detail;
  PartnerGuestStay? get stay => _stay;
  bool get isDetailLoading => _detailLoading;
  ApiErrorKind? get detailErrorKind => _detailErrorKind;

  int? get pendingActionBookingId => _pendingActionBookingId;
  PartnerBookingAction? get pendingAction => _pendingAction;

  bool get isLoading => _status == PartnerBookingsStatus.loading;
  bool get isReady => _status == PartnerBookingsStatus.ready;
  bool get isRetryable => _status == PartnerBookingsStatus.error;

  /// No bookings matched. Distinguished from [isUnfilteredEmpty] so the UI can
  /// tell "you have no bookings" apart from "this filter matched nothing".
  bool get isEmpty => isReady && _page.content.isEmpty;

  bool get isUnfilteredEmpty => isEmpty && !_query.hasActiveFilters;

  /// The booking currently opened in the detail panel, as it appears in the
  /// list. Null once it falls off the page.
  PartnerBookingSummary? get openSummary {
    final id = _openBookingId;
    if (id == null) return null;
    for (final booking in _page.content) {
      if (booking.id == id) return booking;
    }
    return null;
  }

  /// Which lifecycle actions the opened booking's status permits.
  ///
  /// Derived from `BookingStatusEngineService.ALLOWED`; the backend re-checks
  /// every one of them and answers 422 if the client got it wrong.
  List<PartnerBookingAction> availableActionsFor(PartnerBookingStatus status) =>
      PartnerBookingAction.values
          .where((action) => action.isAvailableFor(status))
          .toList(growable: false);

  /// Loads one page of bookings, plus the selected property's rooms so the
  /// `roomId` filter has something to offer.
  ///
  /// The two requests are independent: a rooms failure must not blank the
  /// booking list, which is not property-scoped in the first place.
  Future<void> load(PartnerState partner, int? propertyId) async {
    final token = ++_loadToken;
    _status = PartnerBookingsStatus.loading;
    _errorMessage = null;
    if (propertyId != _loadedPropertyId) {
      // Rooms — and any room filter built from them — belong to the previous
      // property. Dropping the filter here is what stops a stale room id from
      // silently scoping the next property's list.
      _rooms = const [];
      _query = _query.copyWith(clearRoom: true, page: 0);
      _closeDetail();
    }
    notifyListeners();

    final authorized =
        propertyId != null && partner.properties.any((p) => p.id == propertyId);

    final results = await Future.wait([
      api.getPartnerBookings(_query),
      if (authorized) api.getPartnerRooms(propertyId),
    ]);
    if (token != _loadToken) return;

    final pageResult = results[0] as CollectionApiResult<PartnerBookingPage>;

    if (!pageResult.success || pageResult.data == null) {
      _page = PartnerBookingPage.empty;
      _status = switch (pageResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerBookingsStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerBookingsStatus.forbidden,
        ApiErrorKind.notFound => PartnerBookingsStatus.notFound,
        _ => PartnerBookingsStatus.error,
      };
      _errorMessage = pageResult.message;
      _closeDetail();
      notifyListeners();
      return;
    }

    _page = pageResult.data!;
    _loadedPropertyId = propertyId;

    if (authorized && results.length > 1) {
      final roomsResult = results[1] as CollectionApiResult<List<PartnerRoom>>;
      _rooms = roomsResult.success ? (roomsResult.data ?? const []) : const [];
    } else {
      _rooms = const [];
    }

    // A detail panel open for a booking that is no longer on this page must not
    // linger beside unrelated rows.
    final open = _openBookingId;
    if (open != null && !_page.content.any((b) => b.id == open)) {
      _closeDetail();
    }

    _status = PartnerBookingsStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  /// Applies a new filter set and reloads from page 0.
  ///
  /// Any filter change resets paging — staying on page 4 of a different result
  /// set would show an empty page and look like a failure.
  Future<void> applyQuery(PartnerState partner, PartnerBookingQuery next) {
    _query = next.copyWith(page: 0);
    return load(partner, _loadedPropertyId);
  }

  Future<void> clearFilters(PartnerState partner) => applyQuery(
        partner,
        PartnerBookingQuery(size: _query.size),
      );

  /// Moves to another page of the same result set.
  Future<void> goToPage(PartnerState partner, int page) {
    if (page < 0 || (page > 0 && page >= _page.totalPages)) {
      return Future<void>.value();
    }
    _query = _query.copyWith(page: page);
    return load(partner, _loadedPropertyId);
  }

  Future<void> nextPage(PartnerState partner) =>
      _page.hasNext ? goToPage(partner, _page.page + 1) : Future<void>.value();

  Future<void> previousPage(PartnerState partner) => _page.hasPrevious
      ? goToPage(partner, _page.page - 1)
      : Future<void>.value();

  /// Opens one booking's detail.
  ///
  /// Two endpoints are read concurrently because they own different things:
  /// `/bookings/{id}` carries price, payments and the invoice; `/stays/{id}`
  /// carries the derived stay state, modification history, check-in/out audit
  /// and operational warnings. Both are read-only and ownership-scoped
  /// identically, so neither can leak what the other would not.
  Future<void> openBooking(int bookingId) async {
    if (!_page.content.any((b) => b.id == bookingId)) return;

    final token = ++_detailToken;
    _openBookingId = bookingId;
    _detail = null;
    _stay = null;
    _detailLoading = true;
    _detailErrorKind = null;
    notifyListeners();

    final results = await Future.wait([
      api.getPartnerBookingDetail(bookingId),
      api.getPartnerGuestStay(bookingId),
    ]);
    if (token != _detailToken) return;

    final detailResult =
        results[0] as CollectionApiResult<PartnerBookingDetail>;
    final stayResult = results[1] as CollectionApiResult<PartnerGuestStay>;

    _detailLoading = false;

    if (!detailResult.success || detailResult.data == null) {
      _detail = null;
      _stay = null;
      _detailErrorKind = detailResult.errorKind ?? ApiErrorKind.network;
      notifyListeners();
      return;
    }

    _detail = detailResult.data;
    // The stay projection is supplementary: losing it degrades the panel rather
    // than failing it, because the booking half is the operational core.
    _stay = stayResult.success ? stayResult.data : null;
    _detailErrorKind = null;
    notifyListeners();
  }

  void closeDetail() {
    if (_openBookingId == null) return;
    _closeDetail();
    notifyListeners();
  }

  /// Re-reads the currently opened booking. Used after a lifecycle action, and
  /// after an uncertain one, where re-reading is the only way to learn the
  /// truth.
  Future<void> refreshOpenBooking() async {
    final id = _openBookingId;
    if (id == null) return;
    _detailToken++;
    final token = _detailToken;

    _detailLoading = true;
    notifyListeners();

    final results = await Future.wait([
      api.getPartnerBookingDetail(id),
      api.getPartnerGuestStay(id),
    ]);
    if (token != _detailToken) return;

    final detailResult =
        results[0] as CollectionApiResult<PartnerBookingDetail>;
    final stayResult = results[1] as CollectionApiResult<PartnerGuestStay>;

    _detailLoading = false;
    if (detailResult.success && detailResult.data != null) {
      _detail = detailResult.data;
      _stay = stayResult.success ? stayResult.data : null;
      _detailErrorKind = null;
    } else {
      _detailErrorKind = detailResult.errorKind ?? ApiErrorKind.network;
    }
    notifyListeners();
  }

  /// Runs a lifecycle action against one booking.
  ///
  /// Every transition is one-way — `BookingStatusEngineService` defines no edge
  /// back — so the caller is expected to have confirmed with the operator
  /// first. Nothing is guessed locally: on success the list row is replaced
  /// from the server's own response and the open detail is re-read.
  Future<PartnerBookingActionResult> runAction({
    required PartnerState partner,
    required int bookingId,
    required PartnerBookingAction action,
  }) async {
    if (!_page.content.any((b) => b.id == bookingId)) {
      return PartnerBookingActionResult.notFound;
    }
    if (_pendingActionBookingId != null) {
      return PartnerBookingActionResult.failed;
    }

    _pendingActionBookingId = bookingId;
    _pendingAction = action;
    notifyListeners();

    final result =
        await api.runPartnerBookingAction(bookingId: bookingId, action: action);

    _pendingActionBookingId = null;
    _pendingAction = null;

    if (!result.success || result.data == null) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerBookingActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerBookingActionResult.forbidden,
        ApiErrorKind.notFound => PartnerBookingActionResult.notFound,
        // The engine answers an illegal transition with 422, never 409.
        ApiErrorKind.unprocessable => PartnerBookingActionResult.rejected,
        ApiErrorKind.validation => PartnerBookingActionResult.validation,
        ApiErrorKind.uncertain => PartnerBookingActionResult.uncertain,
        _ => PartnerBookingActionResult.failed,
      };
    }

    // Patch the row from the server's answer so the table reflects the real new
    // status without a full reload.
    final updated = result.data!;
    _page = PartnerBookingPage(
      content: [
        for (final booking in _page.content)
          if (booking.id == bookingId)
            PartnerBookingSummary(
              id: booking.id,
              bookingCode: booking.bookingCode,
              roomId: booking.roomId,
              roomName: booking.roomName,
              roomCode: booking.roomCode,
              guestName: booking.guestName,
              guestEmail: booking.guestEmail,
              checkIn: booking.checkIn,
              checkOut: booking.checkOut,
              nights: booking.nights,
              status: updated.status,
              finalPrice: booking.finalPrice,
              currency: booking.currency,
              createdAt: booking.createdAt,
            )
          else
            booking,
      ],
      page: _page.page,
      size: _page.size,
      totalElements: _page.totalElements,
      totalPages: _page.totalPages,
    );
    notifyListeners();

    if (_openBookingId == bookingId) {
      // The timeline, audit rows and derived stay state all changed server-side.
      await refreshOpenBooking();
    }
    return PartnerBookingActionResult.success;
  }

  void reset() {
    _loadToken++;
    _detailToken++;
    _status = PartnerBookingsStatus.idle;
    _errorMessage = null;
    _page = PartnerBookingPage.empty;
    _query = const PartnerBookingQuery();
    _rooms = const [];
    _loadedPropertyId = null;
    _pendingActionBookingId = null;
    _pendingAction = null;
    _closeDetail();
    notifyListeners();
  }

  void _closeDetail() {
    _openBookingId = null;
    _detail = null;
    _stay = null;
    _detailLoading = false;
    _detailErrorKind = null;
  }
}
