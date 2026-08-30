import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_dashboard_models.dart';
import '../../../core/partner/partner_finance_models.dart';
import '../../../core/partner/partner_state.dart';

/// One independently-loaded section of the module.
///
/// Sections are kept separate because the endpoints are separate: one failing
/// must not blank the others, and "this section failed" must never be rendered
/// as "this section is empty".
@immutable
class PartnerFinanceSection<T> {
  final T? data;
  final bool loading;
  final ApiErrorKind? errorKind;
  final String? message;

  const PartnerFinanceSection.idle()
      : data = null,
        loading = false,
        errorKind = null,
        message = null;

  const PartnerFinanceSection.loading()
      : data = null,
        loading = true,
        errorKind = null,
        message = null;

  const PartnerFinanceSection.ready(this.data)
      : loading = false,
        errorKind = null,
        message = null;

  const PartnerFinanceSection.failure(this.errorKind, [this.message])
      : data = null,
        loading = false;

  bool get hasData => data != null;
  bool get hasError => errorKind != null;

  static PartnerFinanceSection<T> from<T>(CollectionApiResult<T> result) =>
      result.success && result.data != null
          ? PartnerFinanceSection<T>.ready(result.data)
          : PartnerFinanceSection<T>.failure(
              result.errorKind ?? ApiErrorKind.network, result.message);
}

/// Where the module as a whole stands.
///
/// Derived from the *first* request only. A workspace-level failure (no
/// profile, not approved, expired session) is a module-level state; a single
/// section failing is not.
enum PartnerFinanceStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,

  /// 404 — no partner profile, or a property that is not the caller's.
  notFound,

  /// 400 — the requested range was rejected (`from` after `to`).
  invalidRange,
  error,
}

/// State for the Partner Finance module (C11).
///
/// ## What it does not do
///
/// It performs **no arithmetic on money**. Every figure — commission, net, tax,
/// refund rate, settlement totals — is read from the response. [PartnerMoney]
/// exposes no operators, so that is enforced by the compiler rather than by
/// discipline.
///
/// It also performs **no mutation**: `PartnerFinanceController` is read-only
/// end to end, so there is no payout, refund or invoice action to own.
///
/// ## Scope
///
/// Every endpoint accepts the same optional `hotelId`/`from`/`to`. The selected
/// property from [PartnerState] is passed as `hotelId`, so the backend does the
/// scoping — an unowned id is a 404 there, never a client-side filter. When no
/// property is selected the endpoints are genuinely partner-wide, and the screen
/// says so.
class PartnerFinanceState extends ChangeNotifier {
  final ApiClient api;

  /// The backend's own default window: `to` = today, `from` = `to - 29 days`.
  /// Matching it means the first load asks for exactly what the server would
  /// have chosen anyway.
  static const int defaultWindowDays = 30;

  PartnerFinanceState({required this.api});

  PartnerFinanceStatus _status = PartnerFinanceStatus.idle;
  String? _errorMessage;

  PartnerFinanceSection<PartnerFinanceOverview> _overview =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerCommission> _commission =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerFinanceRevenue> _revenue =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerSettlement> _settlement =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerPayouts> _payouts =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerInvoiceFinance> _invoices =
      const PartnerFinanceSection.idle();
  PartnerFinanceSection<PartnerRefunds> _refunds =
      const PartnerFinanceSection.idle();

  int? _hotelId;
  DateTime _from = _defaultFrom();
  DateTime _to = _today();

  int _loadToken = 0;

  PartnerFinanceStatus get status => _status;
  String? get errorMessage => _errorMessage;

  PartnerFinanceSection<PartnerFinanceOverview> get overview => _overview;
  PartnerFinanceSection<PartnerCommission> get commission => _commission;
  PartnerFinanceSection<PartnerFinanceRevenue> get revenue => _revenue;
  PartnerFinanceSection<PartnerSettlement> get settlement => _settlement;
  PartnerFinanceSection<PartnerPayouts> get payouts => _payouts;
  PartnerFinanceSection<PartnerInvoiceFinance> get invoices => _invoices;
  PartnerFinanceSection<PartnerRefunds> get refunds => _refunds;

  int? get hotelId => _hotelId;
  DateTime get from => _from;
  DateTime get to => _to;

  bool get isLoading => _status == PartnerFinanceStatus.loading;
  bool get isReady => _status == PartnerFinanceStatus.ready;
  bool get isRetryable =>
      _status == PartnerFinanceStatus.error ||
      _status == PartnerFinanceStatus.invalidRange;

  /// True when the request is partner-wide because no property is selected.
  bool get isPartnerWide => _hotelId == null;

  /// How many sections failed. Surfaced so a partly-loaded page says so.
  int get failedSections => [
        _overview,
        _commission,
        _revenue,
        _settlement,
        _payouts,
        _invoices,
        _refunds,
      ].where((s) => s.hasError).length;

  /// Loads every section for the current scope and window.
  ///
  /// The seven requests are independent and run concurrently. The module status
  /// is taken from the overview, because a workspace-level refusal (401/403/404)
  /// will be identical across all seven and should be shown once, not seven
  /// times.
  Future<void> load(PartnerState partner, int? propertyId) async {
    final token = ++_loadToken;
    if (propertyId != _hotelId) {
      // A property change invalidates every loaded figure before anything is
      // requested, so no previous property's money can stay on screen.
      _resetSections();
    }
    _hotelId = propertyId;
    _status = PartnerFinanceStatus.loading;
    _errorMessage = null;
    _markLoading();
    notifyListeners();

    // An id the workspace does not list is never sent; the backend would answer
    // 404 anyway, but a request for someone else's property should not leave
    // this client at all.
    final scoped =
        propertyId != null && partner.properties.any((p) => p.id == propertyId);
    final hotelId = scoped ? propertyId : null;
    _hotelId = hotelId;

    final results = await Future.wait([
      api.getPartnerFinanceOverview(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerCommissions(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerFinanceRevenue(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerSettlements(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerPayouts(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerInvoiceFinance(hotelId: hotelId, from: _from, to: _to),
      api.getPartnerRefunds(hotelId: hotelId, from: _from, to: _to),
    ]);
    if (token != _loadToken) return;

    final overviewResult =
        results[0] as CollectionApiResult<PartnerFinanceOverview>;

    _overview = PartnerFinanceSection.from(overviewResult);
    _commission = PartnerFinanceSection.from(
        results[1] as CollectionApiResult<PartnerCommission>);
    _revenue = PartnerFinanceSection.from(
        results[2] as CollectionApiResult<PartnerFinanceRevenue>);
    _settlement = PartnerFinanceSection.from(
        results[3] as CollectionApiResult<PartnerSettlement>);
    _payouts = PartnerFinanceSection.from(
        results[4] as CollectionApiResult<PartnerPayouts>);
    _invoices = PartnerFinanceSection.from(
        results[5] as CollectionApiResult<PartnerInvoiceFinance>);
    _refunds = PartnerFinanceSection.from(
        results[6] as CollectionApiResult<PartnerRefunds>);

    if (!overviewResult.success) {
      _status = switch (overviewResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerFinanceStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerFinanceStatus.forbidden,
        ApiErrorKind.notFound => PartnerFinanceStatus.notFound,
        // `resolveRange` answers an inverted range with a real 400.
        ApiErrorKind.validation => PartnerFinanceStatus.invalidRange,
        _ => PartnerFinanceStatus.error,
      };
      _errorMessage = overviewResult.message;
      notifyListeners();
      return;
    }

    _status = PartnerFinanceStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh(PartnerState partner) => load(partner, _hotelId);

  /// Applies a new window and reloads.
  ///
  /// An inverted range is refused here rather than spent on a round trip the
  /// backend would answer with 400 — but the same state is used either way, so
  /// the two paths look identical to the UI.
  Future<void> setRange(PartnerState partner, DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (start.isAfter(end)) {
      _status = PartnerFinanceStatus.invalidRange;
      _errorMessage = null;
      notifyListeners();
      return Future<void>.value();
    }
    _from = start;
    _to = end;
    return load(partner, _hotelId);
  }

  /// Resets to the backend's own default 30-day window.
  Future<void> resetRange(PartnerState partner) =>
      setRange(partner, _defaultFrom(), _today());

  void reset() {
    _loadToken++;
    _status = PartnerFinanceStatus.idle;
    _errorMessage = null;
    _hotelId = null;
    _from = _defaultFrom();
    _to = _today();
    _resetSections();
    notifyListeners();
  }

  void _markLoading() {
    _overview = const PartnerFinanceSection.loading();
    _commission = const PartnerFinanceSection.loading();
    _revenue = const PartnerFinanceSection.loading();
    _settlement = const PartnerFinanceSection.loading();
    _payouts = const PartnerFinanceSection.loading();
    _invoices = const PartnerFinanceSection.loading();
    _refunds = const PartnerFinanceSection.loading();
  }

  void _resetSections() {
    _overview = const PartnerFinanceSection.idle();
    _commission = const PartnerFinanceSection.idle();
    _revenue = const PartnerFinanceSection.idle();
    _settlement = const PartnerFinanceSection.idle();
    _payouts = const PartnerFinanceSection.idle();
    _invoices = const PartnerFinanceSection.idle();
    _refunds = const PartnerFinanceSection.idle();
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime _defaultFrom() =>
      _today().subtract(const Duration(days: defaultWindowDays - 1));
}
