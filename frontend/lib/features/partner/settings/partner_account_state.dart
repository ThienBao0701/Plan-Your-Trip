import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_account_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_state.dart';

/// Outcome of a team or payout mutation.
enum PartnerAccountActionResult {
  success,
  unauthorized,

  /// 403 — either the profile is not APPROVED, or the caller's role is not
  /// allowed. `PartnerSettingsService` answers both with 403, and the message it
  /// returns is what tells them apart, so it is shown verbatim.
  forbidden,

  /// 404 — no partner profile, or no such member.
  notFound,

  /// 409 — e.g. that user is already on the team.
  conflict,

  /// 400 — validation, such as a malformed email or a too-short account number.
  validation,

  failed,

  /// May have committed before the connection dropped. Team removal and payout
  /// replacement are both irreversible, so the caller must re-read.
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

/// State for the Partner team and payout account (C12).
///
/// ## Scope, and what it does not touch
///
/// C6 owns property policies and workspace notification settings, and this
/// notifier does not read or write either. It covers only the two
/// `PartnerSettingsController` surfaces that had no client: the team list and
/// its mutations, and the payout account.
///
/// ## The role rules are the backend's, mirrored exactly
///
/// Read from `PartnerSettingsService`:
///   * team add / update / remove → `requireOwner`, so **OWNER only**;
///   * payout write → `PAYOUT_WRITE_ROLES` = **OWNER or FINANCE**;
///   * settings write → OWNER or MANAGER, which stays C6's.
///
/// These shape the UI only. Every request is re-authorized server-side, and a
/// 403 is surfaced with the server's own message rather than being pre-empted
/// into a claim the client cannot make.
class PartnerAccountState extends ChangeNotifier {
  final ApiClient api;

  PartnerAccountState({required this.api});

  PartnerAccountStatus _status = PartnerAccountStatus.idle;
  String? _errorMessage;

  List<PartnerTeamMember> _team = const [];

  PartnerPayoutAccount? _payout;

  /// Set when the payout read failed. Distinguished from "no account yet",
  /// which is a 404 and a legitimate state for a partner who never added one.
  ApiErrorKind? _payoutErrorKind;

  bool _hasPayoutAccount = false;
  int? _pendingMemberId;
  bool _savingPayout = false;

  int _loadToken = 0;

  PartnerAccountStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PartnerTeamMember> get team => List.unmodifiable(_team);
  PartnerPayoutAccount? get payout => _payout;
  ApiErrorKind? get payoutErrorKind => _payoutErrorKind;

  /// True when the partner has a payout account on file.
  bool get hasPayoutAccount => _hasPayoutAccount;

  int? get pendingMemberId => _pendingMemberId;
  bool get isSavingPayout => _savingPayout;

  bool get isLoading => _status == PartnerAccountStatus.loading;
  bool get isReady => _status == PartnerAccountStatus.ready;
  bool get isRetryable => _status == PartnerAccountStatus.error;

  /// UX shaping only — mirrors `requireOwner` on the three team mutations.
  bool canManageTeam(PartnerTeamRole role) => role == PartnerTeamRole.owner;

  /// UX shaping only — mirrors `PAYOUT_WRITE_ROLES`.
  bool canEditPayout(PartnerTeamRole role) =>
      role == PartnerTeamRole.owner || role == PartnerTeamRole.finance;

  /// Loads the team and the payout account together.
  ///
  /// They are independent: a payout failure leaves the team readable, and a
  /// payout 404 is recorded as "no account yet" rather than as an error.
  Future<void> load(PartnerState partner) async {
    final token = ++_loadToken;
    _status = PartnerAccountStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final results = await Future.wait([
      api.getPartnerTeamMembers(),
      api.getPartnerPayoutAccount(),
    ]);
    if (token != _loadToken) return;

    final teamResult =
        results[0] as CollectionApiResult<List<PartnerTeamMember>>;
    final payoutResult =
        results[1] as CollectionApiResult<PartnerPayoutAccount>;

    if (!teamResult.success) {
      _team = const [];
      _status = switch (teamResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerAccountStatus.unauthorized,
        ApiErrorKind.forbidden => PartnerAccountStatus.forbidden,
        ApiErrorKind.notFound => PartnerAccountStatus.notFound,
        _ => PartnerAccountStatus.error,
      };
      _errorMessage = teamResult.message;
      notifyListeners();
      return;
    }

    _team = teamResult.data ?? const [];

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

  /// Invites a member. OWNER only, enforced by the backend.
  Future<PartnerAccountActionResult> addMember({
    required PartnerState partner,
    required String email,
    required PartnerTeamRole role,
  }) async {
    if (email.trim().isEmpty) return PartnerAccountActionResult.validation;
    if (partnerTeamRoleWire(role) == null) {
      return PartnerAccountActionResult.validation;
    }
    if (_pendingMemberId != null) return PartnerAccountActionResult.failed;

    _pendingMemberId = -1;
    notifyListeners();

    final result = await api.addPartnerTeamMember(email: email, role: role);
    _pendingMemberId = null;

    if (!result.success) {
      _errorMessage = result.message;
      notifyListeners();
      return _map(result.errorKind);
    }
    await load(partner);
    return PartnerAccountActionResult.success;
  }

  /// Changes a member's role, or activates/deactivates them. OWNER only.
  Future<PartnerAccountActionResult> updateMember({
    required PartnerState partner,
    required int memberId,
    PartnerTeamRole? role,
    bool? active,
  }) async {
    if (role == null && active == null) {
      return PartnerAccountActionResult.validation;
    }
    if (role != null && partnerTeamRoleWire(role) == null) {
      return PartnerAccountActionResult.validation;
    }
    if (_pendingMemberId != null) return PartnerAccountActionResult.failed;

    _pendingMemberId = memberId;
    notifyListeners();

    final result = await api.updatePartnerTeamMember(
        memberId: memberId, role: role, active: active);
    _pendingMemberId = null;

    if (!result.success) {
      _errorMessage = result.message;
      notifyListeners();
      return _map(result.errorKind);
    }
    await load(partner);
    return PartnerAccountActionResult.success;
  }

  /// Removes a member. OWNER only, and **irreversible** — there is no endpoint
  /// to restore one, so the caller must confirm first.
  Future<PartnerAccountActionResult> removeMember({
    required PartnerState partner,
    required int memberId,
  }) async {
    if (_pendingMemberId != null) return PartnerAccountActionResult.failed;

    _pendingMemberId = memberId;
    notifyListeners();

    final result = await api.removePartnerTeamMember(memberId);
    _pendingMemberId = null;

    if (!result.success) {
      _errorMessage = result.message;
      notifyListeners();
      return _map(result.errorKind);
    }
    await load(partner);
    return PartnerAccountActionResult.success;
  }

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
    _team = const [];
    _payout = null;
    _payoutErrorKind = null;
    _hasPayoutAccount = false;
    _pendingMemberId = null;
    _savingPayout = false;
    notifyListeners();
  }
}
