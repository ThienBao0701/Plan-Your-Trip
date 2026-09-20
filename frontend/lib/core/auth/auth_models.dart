/// Typed responses of the Phase A account endpoints.
///
/// Each mirrors one backend record exactly (`AuthDtos`), so the transport layer
/// stops at `ApiClient` and no screen reads raw JSON.
library;

import '../app_role.dart';

/// `POST /api/auth/partner/register` — 201, and deliberately no session: the
/// account cannot sign in until its email is verified.
class PartnerRegistrationRecord {
  final String email;

  /// The backend's lifecycle word, e.g. `PENDING_VERIFICATION`.
  final String status;

  final bool verificationRequired;
  final String? message;

  const PartnerRegistrationRecord({
    required this.email,
    required this.status,
    required this.verificationRequired,
    this.message,
  });

  static PartnerRegistrationRecord? fromJson(Map<String, dynamic> json) {
    final email = json['email'];
    if (email is! String || email.isEmpty) return null;
    return PartnerRegistrationRecord(
      email: email,
      status: json['status'] is String ? json['status'] as String : '',
      verificationRequired: json['verificationRequired'] == true,
      message: json['message'] is String ? json['message'] as String : null,
    );
  }
}

/// What `POST /api/auth/verify-email` reports for a token it accepted.
enum EmailVerificationOutcome {
  verified,
  alreadyVerified,

  /// A 200 whose `status` this build does not recognise — treated as success
  /// without claiming which kind.
  unknown;

  static EmailVerificationOutcome parse(Object? raw) => switch (raw) {
        'VERIFIED' => EmailVerificationOutcome.verified,
        'ALREADY_VERIFIED' => EmailVerificationOutcome.alreadyVerified,
        _ => EmailVerificationOutcome.unknown,
      };
}

class EmailVerificationRecord {
  final EmailVerificationOutcome outcome;
  final String? message;

  const EmailVerificationRecord({required this.outcome, this.message});

  static EmailVerificationRecord fromJson(Map<String, dynamic> json) =>
      EmailVerificationRecord(
        outcome: EmailVerificationOutcome.parse(json['status']),
        message: json['message'] is String ? json['message'] as String : null,
      );
}

/// A session handed back by an endpoint that re-issues one — today only
/// `PUT /api/me/password`, which ends older sessions and returns a fresh token
/// so the caller's own session survives.
class AuthSessionRecord {
  final String token;
  final String? email;
  final String? fullName;
  final AppRole role;

  const AuthSessionRecord({
    required this.token,
    required this.role,
    this.email,
    this.fullName,
  });

  static AuthSessionRecord? fromJson(Map<String, dynamic> json) {
    final token = json['token'];
    if (token is! String || token.isEmpty) return null;
    final user = json['user'];
    final map = user is Map<String, dynamic> ? user : const <String, dynamic>{};
    return AuthSessionRecord(
      token: token,
      role: AppRole.parse(map['role']),
      email: map['email'] is String ? map['email'] as String : null,
      fullName: map['fullName'] is String ? map['fullName'] as String : null,
    );
  }
}
