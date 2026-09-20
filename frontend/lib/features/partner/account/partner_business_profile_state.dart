import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_error.dart';
import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_models.dart';

/// Where the business profile read stands.
enum PartnerBusinessProfileStatus {
  idle,
  loading,

  /// Loaded — [PartnerBusinessProfileState.profile] holds it.
  ready,

  /// 404 from `GET /api/partner/profile`: this account has no business profile
  /// yet, which is the normal state right after registering.
  missing,

  /// 401 — the session is gone.
  unauthorized,

  /// Network failure, timeout or an unreadable response. Retryable.
  error,
}

/// The Partner's own business profile: read, edit and submit for review.
///
/// This is the account-side half of partner onboarding and stops there. It
/// touches only `/api/partner/profile`, the one partner route that does not
/// require an approved profile, and it never claims approval: submitting moves
/// the profile to SUBMITTED and an administrator decides the rest.
class PartnerBusinessProfileState extends ChangeNotifier {
  final ApiClient api;

  PartnerBusinessProfileState({required this.api});

  PartnerBusinessProfileStatus _status = PartnerBusinessProfileStatus.idle;
  PartnerProfile? _profile;
  String? _errorMessage;
  bool _saving = false;

  PartnerBusinessProfileStatus get status => _status;
  PartnerProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  /// True while a save or submit is in flight, so a form can refuse a second one.
  bool get saving => _saving;

  /// Whether the backend would accept an edit: only DRAFT and REJECTED profiles,
  /// plus an account that has none yet.
  bool get canEdit =>
      _status == PartnerBusinessProfileStatus.missing ||
      (_profile?.isEditable ?? false);

  Future<void> load() async {
    if (_status == PartnerBusinessProfileStatus.loading) return;
    _status = PartnerBusinessProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await api.getPartnerProfile();
    if (result.success && result.data != null) {
      _profile = result.data;
      _status = PartnerBusinessProfileStatus.ready;
    } else if (result.errorKind == ApiErrorKind.notFound) {
      // A legitimate state, not a failure: no profile has been created yet.
      _profile = null;
      _status = PartnerBusinessProfileStatus.missing;
    } else if (result.errorKind == ApiErrorKind.unauthorized) {
      _status = PartnerBusinessProfileStatus.unauthorized;
      _errorMessage = result.message;
    } else {
      _status = PartnerBusinessProfileStatus.error;
      _errorMessage = result.message;
    }
    notifyListeners();
  }

  /// Creates or updates the profile. The caller shows the failure; this only
  /// adopts a successful result.
  Future<AuthResult<PartnerProfile>> save(PartnerProfileDraft draft) async {
    if (_saving) {
      return const AuthResult.failed(AuthFailure(code: AuthErrorCode.unknown));
    }
    _saving = true;
    notifyListeners();

    final result = await api.savePartnerProfile(draft);
    final saved = result.data;
    if (result.success && saved != null) {
      _profile = saved;
      _status = PartnerBusinessProfileStatus.ready;
      _errorMessage = null;
    }
    _saving = false;
    notifyListeners();
    return result;
  }

  /// Submits the profile for administrator review. The response carries the new
  /// status, which is adopted verbatim — the client never decides it.
  Future<AuthResult<PartnerProfileSubmission>> submit() async {
    if (_saving) {
      return const AuthResult.failed(AuthFailure(code: AuthErrorCode.unknown));
    }
    _saving = true;
    notifyListeners();

    final result = await api.submitPartnerProfile();
    final submission = result.data;
    final current = _profile;
    if (result.success && submission != null && current != null) {
      _profile = PartnerProfile(
        id: current.id,
        userId: current.userId,
        businessName: current.businessName,
        representativeName: current.representativeName,
        verificationStatus: submission.verificationStatus,
        businessType: current.businessType,
        email: current.email,
        phone: current.phone,
        address: current.address,
        taxCode: current.taxCode,
        website: current.website,
        rejectReason: null,
        submittedAt: submission.submittedAt,
        approvedAt: current.approvedAt,
      );
      _status = PartnerBusinessProfileStatus.ready;
    }
    _saving = false;
    notifyListeners();
    return result;
  }
}
