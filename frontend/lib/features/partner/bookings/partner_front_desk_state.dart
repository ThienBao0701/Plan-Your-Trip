import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_booking_models.dart';

/// Where a front-desk check-in / check-out attempt stands.
enum PartnerFrontDeskStatus {
  idle,
  working,

  /// 200. The booking is now — or already was — in the target state.
  /// [PartnerFrontDeskState.result] carries the server's own message, which
  /// distinguishes a fresh transition from an idempotent repeat.
  done,

  /// Uniform 404: an invalid signature, an unknown booking, **or** one belonging
  /// to another partner. The backend does not say which, and neither may the UI.
  notRecognised,

  /// 422 — the booking's status is ineligible, or today falls outside the
  /// configured check-in/check-out window. The server's message says which; it
  /// is shown verbatim.
  rejected,

  /// 400 — neither or both of voucher payload and booking code were supplied.
  invalidInput,

  unauthorized,
  forbidden,

  /// The request may have been committed before the connection dropped. Both
  /// endpoints are idempotent, so re-running is safe.
  uncertain,

  error,
}

/// State for the front-desk check-in and check-out console.
///
/// Deliberately a **separate** notifier from `PartnerBookingsState`. The two
/// address bookings differently and cannot share a selection: the bookings list
/// works by numeric booking id through `PATCH /bookings/{id}/…`, while this
/// console works by scanned voucher payload or typed booking code through
/// `POST /bookings/check-in|check-out` — the endpoints that are idempotent and
/// that write the immutable check-in / check-out audit rows.
///
/// Both surfaces reach the same `BookingStatusEngineService`, so neither invents
/// a second state machine.
class PartnerFrontDeskState extends ChangeNotifier {
  final ApiClient api;

  PartnerFrontDeskState({required this.api});

  PartnerFrontDeskStatus _status = PartnerFrontDeskStatus.idle;
  PartnerFrontDeskResult? _result;
  String? _errorMessage;
  String _input = '';
  bool _checkIn = true;

  PartnerFrontDeskStatus get status => _status;
  PartnerFrontDeskResult? get result => _result;
  String? get errorMessage => _errorMessage;
  String get input => _input;

  /// True when the console is set to check a guest in, false to check them out.
  bool get isCheckIn => _checkIn;

  bool get isWorking => _status == PartnerFrontDeskStatus.working;
  bool get canSubmit => _input.trim().isNotEmpty && !isWorking;

  /// A scanned voucher looks like `PYT-V1.<bookingCode>.<signature>`; anything
  /// else is treated as a typed booking code. The backend derives the audit
  /// method from exactly this distinction — a payload records `QR_SCAN`, a bare
  /// code records `MANUAL` — so the UI must classify the input the same way and
  /// send it in the matching field.
  bool get looksLikeVoucherPayload {
    final trimmed = _input.trim();
    return trimmed.startsWith('PYT-V1.') && trimmed.split('.').length >= 3;
  }

  void setInput(String value) {
    _input = value;
    if (_status != PartnerFrontDeskStatus.idle) {
      // A new code invalidates the previous answer — never leave a "checked in"
      // verdict standing beside a different booking's code.
      _status = PartnerFrontDeskStatus.idle;
      _result = null;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Switches between check-in and check-out. Clears any standing verdict,
  /// because it belonged to the other operation.
  void setCheckIn(bool value) {
    if (_checkIn == value) return;
    _checkIn = value;
    _status = PartnerFrontDeskStatus.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Performs the check-in or check-out.
  ///
  /// This **mutates a booking** and notifies the guest, so the caller is
  /// expected to have confirmed with the operator first.
  Future<void> submit() async {
    final trimmed = _input.trim();
    if (trimmed.isEmpty) {
      _status = PartnerFrontDeskStatus.invalidInput;
      _result = null;
      _errorMessage = null;
      notifyListeners();
      return;
    }
    if (isWorking) return;

    _status = PartnerFrontDeskStatus.working;
    _result = null;
    _errorMessage = null;
    notifyListeners();

    final asPayload = looksLikeVoucherPayload;
    final response = await api.runPartnerFrontDeskAction(
      checkIn: _checkIn,
      voucherPayload: asPayload ? trimmed : null,
      bookingCode: asPayload ? null : trimmed,
    );

    if (response.success && response.data != null) {
      _result = response.data;
      _errorMessage = null;
      _status = PartnerFrontDeskStatus.done;
      notifyListeners();
      return;
    }

    _result = null;
    _errorMessage = response.message;
    _status = switch (response.errorKind) {
      ApiErrorKind.notFound => PartnerFrontDeskStatus.notRecognised,
      ApiErrorKind.unprocessable => PartnerFrontDeskStatus.rejected,
      ApiErrorKind.validation => PartnerFrontDeskStatus.invalidInput,
      ApiErrorKind.unauthorized => PartnerFrontDeskStatus.unauthorized,
      ApiErrorKind.forbidden => PartnerFrontDeskStatus.forbidden,
      ApiErrorKind.uncertain => PartnerFrontDeskStatus.uncertain,
      _ => PartnerFrontDeskStatus.error,
    };
    notifyListeners();
  }

  void clear() {
    _input = '';
    _status = PartnerFrontDeskStatus.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  void reset() => clear();
}
