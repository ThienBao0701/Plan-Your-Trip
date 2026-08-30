import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_promotion_models.dart';

/// Where the booking-voucher check stands.
enum PartnerVoucherCheckStatus {
  /// Nothing has been checked yet.
  idle,

  checking,

  /// The signature verified, the booking exists and it belongs to this partner.
  /// [PartnerVoucherVerification.eligible] then says whether the guest may be
  /// admitted.
  verified,

  /// Uniform 404. The signature was invalid, **or** the booking is unknown,
  /// **or** it belongs to another partner — the backend deliberately does not
  /// distinguish these, and neither may the UI.
  notRecognised,

  /// The field was empty, so nothing was sent.
  empty,

  unauthorized,
  forbidden,
  error,
}

/// State for the partner booking-voucher check.
///
/// Deliberately a **separate** notifier from `PartnerPromotionsState`, because
/// the two domains are unrelated: a promotion is an automatic discount rule,
/// while a voucher here is a signed **booking** QR payload used to admit a
/// guest. It carries no discount and is not a coupon.
///
/// This surface is strictly read-only. `PartnerVoucherVerificationService.verify`
/// is `@Transactional(readOnly = true)` and mutates nothing; actual check-in is a
/// separate booking operation and is not part of this phase.
class PartnerVouchersState extends ChangeNotifier {
  final ApiClient api;

  PartnerVouchersState({required this.api});

  PartnerVoucherCheckStatus _status = PartnerVoucherCheckStatus.idle;
  PartnerVoucherVerification? _result;
  String? _errorMessage;
  String _payload = '';

  PartnerVoucherCheckStatus get status => _status;
  PartnerVoucherVerification? get result => _result;
  String? get errorMessage => _errorMessage;
  String get payload => _payload;

  bool get isChecking => _status == PartnerVoucherCheckStatus.checking;
  bool get canSubmit => _payload.trim().isNotEmpty && !isChecking;

  void setPayload(String value) {
    _payload = value;
    if (_status != PartnerVoucherCheckStatus.idle) {
      // A new payload invalidates the previous answer — never leave a stale
      // "verified" beside a different code.
      _status = PartnerVoucherCheckStatus.idle;
      _result = null;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Verifies the payload. Read-only: nothing is checked in, nothing is stored.
  Future<void> verify() async {
    final trimmed = _payload.trim();
    if (trimmed.isEmpty) {
      _status = PartnerVoucherCheckStatus.empty;
      _result = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (isChecking) return;

    _status = PartnerVoucherCheckStatus.checking;
    _result = null;
    _errorMessage = null;
    notifyListeners();

    final response = await api.verifyPartnerVoucher(trimmed);

    if (response.success && response.data != null) {
      _result = response.data;
      _errorMessage = null;
      _status = PartnerVoucherCheckStatus.verified;
      notifyListeners();
      return;
    }

    _result = null;
    _errorMessage = response.message;
    _status = switch (response.errorKind) {
      // The uniform 404 is the interesting one: it means "not recognised for
      // this account" and nothing more precise may be claimed.
      ApiErrorKind.notFound => PartnerVoucherCheckStatus.notRecognised,
      ApiErrorKind.unauthorized => PartnerVoucherCheckStatus.unauthorized,
      ApiErrorKind.forbidden => PartnerVoucherCheckStatus.forbidden,
      _ => PartnerVoucherCheckStatus.error,
    };
    notifyListeners();
  }

  void clear() {
    _payload = '';
    _status = PartnerVoucherCheckStatus.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  void reset() => clear();
}
