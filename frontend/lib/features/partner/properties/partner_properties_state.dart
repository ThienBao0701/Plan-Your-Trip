import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_property_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of an activate/deactivate request, in the project's established
/// "typed result enum, never an exception" convention.
enum PartnerPropertyActionResult {
  success,

  /// The session is gone (401).
  unauthorized,

  /// The partner profile is no longer approved (403).
  forbidden,

  /// Uniform 404 — the property is unknown *or* not owned by the caller. The
  /// two are indistinguishable by design and must be reported as one thing.
  notFound,

  /// Offline, timed out, 5xx, or an unreadable body.
  failed,

  /// The request may have been committed server-side before the connection
  /// dropped. Never presented as either success or a clean failure.
  uncertain,
}

/// Where the Properties module stands.
///
/// Deliberately separate from the workspace-level lifecycle in
/// [PartnerWorkspaceStatus]: "this partner is not approved" is a workspace
/// condition the shell already renders, whereas "the property list failed to
/// load" belongs to this screen.
enum PartnerPropertiesStatus {
  idle,
  loading,
  ready,

  /// 401 — the session expired.
  unauthorized,

  /// 403 — role admitted, profile not approved.
  forbidden,

  /// 404 — no partner profile at all.
  noProfile,

  /// Offline / timeout / 5xx / malformed. Retryable.
  error,
}

/// State for the Partner Properties module.
///
/// A feature-scoped `ChangeNotifier` under the same `AppScope`/`InheritedNotifier`
/// paradigm as everything else — no second state-management system, and no
/// growth of [PartnerState], which stays responsible for workspace identity and
/// the *selected* property only.
///
/// ## Division of responsibility with PartnerState
///
/// * [PartnerState] owns the authorized property list and the current
///   selection, because later modules (rooms, calendar, pricing) inherit that
///   context.
/// * This class owns list loading, the opened detail record, and per-action
///   status — none of which any other module needs.
///
/// Selecting a property here therefore calls through to
/// `PartnerState.selectProperty`, which ignores any id the backend did not
/// authorize. The client never invents scope; the backend re-checks regardless.
class PartnerPropertiesState extends ChangeNotifier {
  final ApiClient api;

  PartnerPropertiesState({required this.api});

  PartnerPropertiesStatus _status = PartnerPropertiesStatus.idle;
  List<PartnerProperty> _properties = const [];
  String? _errorMessage;

  int? _openPropertyId;
  PartnerPropertyDetail? _detail;
  bool _detailLoading = false;
  ApiErrorKind? _detailErrorKind;
  String? _detailErrorMessage;

  int? _pendingActionPropertyId;
  int _loadToken = 0;

  PartnerPropertiesStatus get status => _status;
  List<PartnerProperty> get properties => List.unmodifiable(_properties);
  String? get errorMessage => _errorMessage;

  bool get isLoading =>
      _status == PartnerPropertiesStatus.loading ||
      _status == PartnerPropertiesStatus.idle;
  bool get isReady => _status == PartnerPropertiesStatus.ready;

  /// True when the list loaded successfully and the partner owns nothing.
  /// Distinct from every failure state — "you have no properties yet" is an
  /// answer, not an error, and must never be shown as one.
  bool get isEmpty => isReady && _properties.isEmpty;

  /// True when the failure is retryable rather than a session/lifecycle fact.
  bool get isRetryable => _status == PartnerPropertiesStatus.error;

  /// The property whose detail panel is open, if any.
  int? get openPropertyId => _openPropertyId;
  PartnerPropertyDetail? get detail => _detail;
  bool get isDetailLoading => _detailLoading;
  ApiErrorKind? get detailErrorKind => _detailErrorKind;
  String? get detailErrorMessage => _detailErrorMessage;
  bool get hasDetailError => _detailErrorKind != null;

  /// The property currently running an activate/deactivate request, so only
  /// that row shows a spinner.
  int? get pendingActionPropertyId => _pendingActionPropertyId;

  /// Loads `GET /api/partner/hotels` and republishes it into [PartnerState] so
  /// the workspace and this screen never disagree about what is authorized.
  Future<void> load(PartnerState partner) async {
    final token = ++_loadToken;
    _status = PartnerPropertiesStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getPartnerProperties();
    if (token != _loadToken) return;

    if (!result.success) {
      _properties = const [];
      _status = switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerPropertiesStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerPropertiesStatus.forbidden,
        ApiErrorKind.notFound => PartnerPropertiesStatus.noProfile,
        _ => PartnerPropertiesStatus.error,
      };
      _errorMessage = result.message;
      notifyListeners();
      return;
    }

    _properties = result.data ?? const [];
    _status = PartnerPropertiesStatus.ready;
    _errorMessage = null;

    partner.replaceProperties(_properties);

    // A previously opened detail whose property is gone must not linger.
    final open = _openPropertyId;
    if (open != null && !_properties.any((p) => p.id == open)) {
      _clearDetail();
    }

    notifyListeners();
  }

  /// Opens one property's detail and makes it the workspace selection.
  ///
  /// [partner] is updated first so every other module sees the same context
  /// immediately, even while the detail request is still in flight.
  Future<void> openProperty(PartnerState partner, int propertyId) async {
    if (!_properties.any((p) => p.id == propertyId)) return;

    partner.selectProperty(propertyId);

    _openPropertyId = propertyId;
    _detail = null;
    _detailErrorKind = null;
    _detailErrorMessage = null;
    _detailLoading = true;
    notifyListeners();

    final result = await api.getPartnerProperty(propertyId);
    // Superseded by a later open, or the panel was closed.
    if (_openPropertyId != propertyId) return;

    _detailLoading = false;
    if (result.success && result.data != null) {
      _detail = result.data;
      _detailErrorKind = null;
      _detailErrorMessage = null;
    } else {
      _detail = null;
      _detailErrorKind = result.errorKind ?? ApiErrorKind.network;
      _detailErrorMessage = result.message;
    }
    notifyListeners();
  }

  /// Closes the detail panel. The workspace selection is intentionally left
  /// alone — closing a panel is not deselecting a property.
  void closeDetail() {
    if (_openPropertyId == null) return;
    _clearDetail();
    notifyListeners();
  }

  /// `PATCH /activate` or `/deactivate`, depending on [activate].
  ///
  /// The list row and the open detail are both refreshed from the response
  /// body, which is the full updated record — nothing is assumed to have
  /// changed, and a failure leaves the previous value visibly intact.
  Future<PartnerPropertyActionResult> setActive(
    int propertyId, {
    required bool activate,
  }) async {
    if (!_properties.any((p) => p.id == propertyId)) {
      return PartnerPropertyActionResult.notFound;
    }
    if (_pendingActionPropertyId != null) {
      return PartnerPropertyActionResult.failed;
    }

    _pendingActionPropertyId = propertyId;
    notifyListeners();

    final result = activate
        ? await api.activatePartnerProperty(propertyId)
        : await api.deactivatePartnerProperty(propertyId);

    _pendingActionPropertyId = null;

    if (!result.success || result.data == null) {
      notifyListeners();
      return switch (result.errorKind) {
        ApiErrorKind.unauthorized => PartnerPropertyActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerPropertyActionResult.forbidden,
        ApiErrorKind.notFound => PartnerPropertyActionResult.notFound,
        ApiErrorKind.uncertain => PartnerPropertyActionResult.uncertain,
        _ => PartnerPropertyActionResult.failed,
      };
    }

    final updated = result.data!;
    _properties = [
      for (final property in _properties)
        property.id == propertyId
            ? property.copyWithActive(updated.active)
            : property,
    ];
    if (_openPropertyId == propertyId) _detail = updated;

    notifyListeners();
    return PartnerPropertyActionResult.success;
  }

  /// Drops every payload. Called when the partner session identity changes.
  void reset() {
    _loadToken++;
    _status = PartnerPropertiesStatus.idle;
    _properties = const [];
    _errorMessage = null;
    _pendingActionPropertyId = null;
    _clearDetail();
    notifyListeners();
  }

  void _clearDetail() {
    _openPropertyId = null;
    _detail = null;
    _detailLoading = false;
    _detailErrorKind = null;
    _detailErrorMessage = null;
  }
}
