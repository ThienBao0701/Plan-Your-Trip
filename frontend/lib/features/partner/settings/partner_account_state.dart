import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_account_models.dart';
import '../../../core/partner/partner_models.dart' show PartnerTeamRole;
import '../../../core/partner/partner_state.dart';

/// Outcome of a payout mutation.
enum PartnerAccountActionResult {
  success,
  unauthorized,

  /// 403 — either the profile is not APPROVED, or the caller's role is not
  /// allowed. `PartnerSettingsService` answers both with 403, and the message it
  /// returns is what tells them apart, so it is shown verbatim.
  forbidden,

  /// 404 — no partner profile, or no such member.
  notFound,

  /// 409 — a conflicting change.
  conflict,

  /// 400 — validation, such as a malformed email or a too-short account number.
  validation,

  failed,

  /// May have committed before the connection dropped. Payout replacement is
  /// irreversible, so the caller must re-read.
  uncertain,
}

/// Where the account module stands.
enum PartnerAccountStatus {
  idle,
  loading,
  ready,
  unauthorized,
  forbidden,
  notFound,
  error,
}

/// State for the Partner payout account (C12).
///
/// ## Scope, and what it does not touch
///
/// C6 owns property policies and workspace notification settings, and this
/// notifier does not read or write either. It covers the payout account of
/// `PartnerSettingsController`. The team moved to its own destination in RBAC
/// R5 (`features/partner/team/`), built on the R4 team and invitation API.
///
/// The payout rule shapes the UI only (`PAYOUT_WRITE_ROLES` = OWNER or
/// FINANCE). Every request is re-authorized server-side, and a 403 is surfaced
/// with the server's own message rather than being pre-empted.
class PartnerAccountState extends ChangeNotifier {
  final ApiClient api;

  PartnerAccountState({required this.api});

  PartnerAccountStatus _status = PartnerAccountStatus.idle;
  String? _errorMessage;

  PartnerPayoutAccount? _payout;

  /// Set when the payout read failed. Distinguished from "no account yet",
  /// which is a 404 and a legitimate state for a partner who never added one.
  ApiErrorKind? _payoutErrorKind;

  bool _hasPayoutAccount = false;
  bool _savingPayout = false;

  int _loadToken = 0;

  PartnerAccountStatus get status => _status;
  String? get errorMessage => _errorMessage;
  PartnerPayoutAccount? get payout => _payout;
  ApiErrorKind? get payoutErrorKind => _payoutErrorKind;

  /// True when the partner has a payout account on file.
  bool get hasPayoutAccount => _hasPayoutAccount;

  bool get isSavingPayout => _savingPayout;

  bool get isLoading => _status == PartnerAccountStatus.loading;
  bool get isReady => _status == PartnerAccountStatus.ready;
  bool get isRetryable => _status == PartnerAccountStatus.error;

  /// UX shaping only — mirrors `PAYOUT_WRITE_ROLES`.
  bool canEditPayout(PartnerTeamRole role) =>
      role == PartnerTeamRole.owner || role == PartnerTeamRole.finance;

  /// Loads the payout account. A 404 is "no account yet", not a failure; a
  /// payout the caller may not read is reported on the payout tab only.
  Future<void> load(PartnerState partner) async {
    final token = ++_loadToken;
    _status = PartnerAccountStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final payoutResult = await api.getPartnerPayoutAccount();
    if (token != _loadToken) return;

    if (payoutResult.errorKind == ApiErrorKind.unauthorized) {
      _status = PartnerAccountStatus.unauthorized;
      _errorMessage = payoutResult.message;
      notifyListeners();
      return;
    }

    if (payoutResult.success && payoutResult.data != null) {
      _payout = payoutResult.data;
      _hasPayoutAccount = true;
      _payoutErrorKind = null;
    } else if (payoutResult.errorKind == ApiErrorKind.notFound) {
      // A partner who has never added an account. Not a failure.
      _payout = null;
      _hasPayoutAccount = false;
      _payoutErrorKind = null;
    } else {
      _payout = null;
      _hasPayoutAccount = false;
      _payoutErrorKind = payoutResult.errorKind ?? ApiErrorKind.network;
    }

    _status = PartnerAccountStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> refresh(PartnerState partner) => load(partner);

  /// Replaces the payout account. OWNER or FINANCE.
  ///
  /// The account number is sent once; the backend keeps only its last four
  /// digits and discards the rest, so nothing sensitive is stored here either —
  /// this state never retains the value it passed through.
  Future<PartnerAccountActionResult> savePayoutAccount({
    required PartnerState partner,
    required String accountHolderName,
    required String bankName,
    required String bankAccountNumber,
    required PartnerPayoutMethod payoutMethod,
  }) async {
    if (_savingPayout) return PartnerAccountActionResult.failed;
    _savingPayout = true;
    notifyListeners();

    final result = await api.updatePartnerPayoutAccount(
      accountHolderName: accountHolderName,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      payoutMethod: payoutMethod,
    );
    _savingPayout = false;

    if (!result.success || result.data == null) {
      _errorMessage = result.message;
      notifyListeners();
      return _map(result.errorKind);
    }

    _payout = result.data;
    _hasPayoutAccount = true;
    _payoutErrorKind = null;
    notifyListeners();
    return PartnerAccountActionResult.success;
  }

  PartnerAccountActionResult _map(ApiErrorKind? kind) => switch (kind) {
        ApiErrorKind.unauthorized => PartnerAccountActionResult.unauthorized,
        ApiErrorKind.forbidden => PartnerAccountActionResult.forbidden,
        ApiErrorKind.notFound => PartnerAccountActionResult.notFound,
        ApiErrorKind.conflict => PartnerAccountActionResult.conflict,
        ApiErrorKind.validation => PartnerAccountActionResult.validation,
        ApiErrorKind.uncertain => PartnerAccountActionResult.uncertain,
        _ => PartnerAccountActionResult.failed,
      };

  void reset() {
    _loadToken++;
    _status = PartnerAccountStatus.idle;
    _errorMessage = null;
    _payout = null;
    _payoutErrorKind = null;
    _hasPayoutAccount = false;
    _savingPayout = false;
    notifyListeners();
  }
}
