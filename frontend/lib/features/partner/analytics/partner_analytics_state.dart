import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_analytics_models.dart';
import '../../../core/partner/partner_state.dart';
import '../finance/partner_finance_state.dart' show PartnerFinanceSection;

/// Where the analytics module stands.
enum PartnerAnalyticsStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — no partner profile, or a property that is not the caller's.
  notFound,

  /// 400 — `from` after `to`.
  invalidRange,
  error,
}

/// State for the Partner Analytics module (C11).
///
/// ## Deliberately narrower than "all analytics"
///
/// C1's dashboard already owns `/analytics/overview`, `/analytics/revenue` and
/// `/analytics/occupancy`. Reloading them here would give the product two
/// screens computing the same KPI names from two states, and the first time they
/// disagreed — different window, different property — a partner would be right
/// to distrust both. So this module loads only the five endpoints that had no
/// client: bookings, rooms, promotions, reviews and messages.
///
/// It reuses [PartnerFinanceSection] rather than declaring a second identical
/// per-section wrapper.
class PartnerAnalyticsState extends ChangeNotifier {
  final ApiClient api;

  /// Mirrors the backend's own default window (`to` = today, `from` = `to − 29`).
  static const int defaultWindowDays = 30;

  PartnerAnalyticsState({required this.api});

  PartnerAnalyticsStatus _status = PartnerAnalyticsStatus.idle;
  String? _errorMessage;

  PartnerFinanceSection<PartnerBookingAnalytics> _bookings =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerRoomAnalytics> _rooms =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerPromotionAnalytics> _promotions =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerReviewAnalytics> _reviews =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerMessageAnalytics> _messages =
      const PartnerFinanceSection.idle();

  int? _hotelId;
  DateTime _from = _defaultFrom();
  DateTime _to = _today();

  int _loadToken = 0;

  PartnerAnalyticsStatus get status => _status;
  String? get errorMessage => _errorMessage;

  PartnerFinanceSection<PartnerBookingAnalytics> get bookings => _bookings;
  PartnerFinanceSection<PartnerRoomAnalytics> get rooms => _rooms;
  PartnerFinanceSection<PartnerPromotionAnalytics> get promotions =>
      _promotions;
  PartnerFinanceSection<PartnerReviewAnalytics> get reviews => _reviews;
  PartnerFinanceSection<PartnerMessageAnalytics> get messages => _messages;

  int? get hotelId => _hotelId;
  DateTime get from => _from;
  DateTime get to => _to;

  bool get isLoading => _status == PartnerAnalyticsStatus.loading;
  bool get isReady => _status == PartnerAnalyticsStatus.ready;
  bool get isRetryable =>
      _status == PartnerAnalyticsStatus.error ||
      _status == PartnerAnalyticsStatus.invalidRange;
  bool get isPartnerWide => _hotelId == null;

  int get failedSections => [
        _bookings,
        _rooms,
        _promotions,
        _reviews,
        _messages
      ].where((s) => s.hasError).length;

  /// Loads the five sections concurrently for the current scope and window.
  Future<void> load(PartnerState partner, int? propertyId) async {
    final token = ++_loadToken;
    if (propertyId != _hotelId) _resetSections();
    _status = PartnerAnalyticsStatus.loading;
    _errorMessage = null;
    _markLoading();
    notifyListeners();

    final scoped =
        propertyId != null && partner.properties.any((p) => p.id == propertyId);
    final hotelId = scoped ? propertyId : null;
    _hotelId = hotelId;

    final results = await Future.wait([
      api.getPartnerBookingAnalytics(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerRoomAnalytics(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerPromotionAnalytics(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerReviewAnalytics(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerMessageAnalytics(hotelId: hotelId, from: _from, to: _to),
    ]);
    if (token != _loadToken) return;

    final bookingsResult =
        results[0] as CollectionApiResult<PartnerBookingAnalytics>;

    _bookings = PartnerFinanceSection.from(bookingsResult);
    _rooms = PartnerFinanceSection.from(
        results[1] as CollectionApiResult<PartnerRoomAnalytics>);
    _promotions = PartnerFinanceSection.from(
        results[2] as CollectionApiResult<PartnerPromotionAnalytics>);
    _reviews = PartnerFinanceSection.from(
        results[3] as CollectionApiResult<PartnerReviewAnalytics>);
    _messages = PartnerFinanceSection.from(
        results[4] as CollectionApiResult<PartnerMessageAnalytics>);

    if (!bookingsResult.success) {
      _status = switch (bookingsResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerAnalyticsStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerAnalyticsStatus.forbidden,
        ApiErrorKind.notFound => PartnerAnalyticsStatus.notFound,
        ApiErrorKind.validation => PartnerAnalyticsStatus.invalidRange,
        _ => PartnerAnalyticsStatus.error,
      };
      _errorMessage = bookingsResult.message;
      notifyListeners();
      return;
    }

    _status = PartnerAnalyticsStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh(PartnerState partner) => load(partner, _hotelId);

  Future<void> setRange(PartnerState partner, DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (start.isAfter(end)) {
      _status = PartnerAnalyticsStatus.invalidRange;
      _errorMessage = null;
      notifyListeners();
      return Future<void>.value();
    }
    _from = start;
    _to = end;
    return load(partner, _hotelId);
  }

  Future<void> resetRange(PartnerState partner) =>
      setRange(partner, _defaultFrom(), _today());

  void reset() {
    _loadToken++;
    _status = PartnerAnalyticsStatus.idle;
    _errorMessage = null;
    _hotelId = null;
    _from = _defaultFrom();
    _to = _today();
    _resetSections();
    notifyListeners();
  }

  void _markLoading() {
    _bookings = const PartnerFinanceSection.loading();
    _rooms = const PartnerFinanceSection.loading();
    _promotions = const PartnerFinanceSection.loading();
    _reviews = const PartnerFinanceSection.loading();
    _messages = const PartnerFinanceSection.loading();
  }

  void _resetSections() {
    _bookings = const PartnerFinanceSection.idle();
    _rooms = const PartnerFinanceSection.idle();
    _promotions = const PartnerFinanceSection.idle();
    _reviews = const PartnerFinanceSection.idle();
    _messages = const PartnerFinanceSection.idle();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _defaultFrom() =>
      _today().subtract(const Duration(days: defaultWindowDays - 1));
}
