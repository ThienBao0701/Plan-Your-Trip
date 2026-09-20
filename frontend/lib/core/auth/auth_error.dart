/// The account-lifecycle error contract, as the backend actually sends it.
///
/// Phase A's `GlobalExceptionHandler` answers every failure with
/// `{timestamp, status, error, message, path}` plus — when it has them — a stable
/// `code` and a `fieldErrors` list of `{field, message}`. The `code` is what a
/// screen should branch on: it is a fixed identifier, while `message` is English
/// prose meant for a developer or a fallback.
///
/// Nothing here formats anything for a person: see `auth_messages.dart`, which is
/// the single place that turns a failure into localized copy.
library;

/// One invalid field, named by the backend.
class AuthFieldError {
  final String field;
  final String message;

  const AuthFieldError({required this.field, required this.message});
}

/// Every `code` Phase A emits on an account endpoint, plus the transport-level
/// outcomes a client has to distinguish. Anything unrecognised is [unknown], so a
/// code added later degrades to the generic message instead of being mistaken for
/// a different one.
enum AuthErrorCode {
  validationFailed('VALIDATION_FAILED'),
  emailAlreadyRegistered('EMAIL_ALREADY_REGISTERED'),
  invalidCredentials('INVALID_CREDENTIALS'),
  accountDisabled('ACCOUNT_DISABLED'),
  accountUnavailable('ACCOUNT_UNAVAILABLE'),
  emailNotVerified('EMAIL_NOT_VERIFIED'),
  tokenInvalid('TOKEN_INVALID'),
  tokenExpired('TOKEN_EXPIRED'),
  currentPasswordIncorrect('CURRENT_PASSWORD_INCORRECT'),
  passwordUnchanged('PASSWORD_UNCHANGED'),
  emailDeliveryUnavailable('EMAIL_DELIVERY_UNAVAILABLE'),

  /// No `code` in the body, or one this build does not know.
  unknown(null),

  /// The request never produced a server answer.
  network(null),
  timeout(null),

  /// The session is gone or was refused (401/403 without a recognised code).
  unauthorized(null),
  forbidden(null),

  /// 5xx, or a body that could not be read.
  server(null),
  malformed(null);

  const AuthErrorCode(this.wireValue);

  /// The exact string the backend sends, or null for client-side outcomes.
  final String? wireValue;

  /// Exact match on the backend's `code`; unrecognised values fail closed to
  /// [unknown] rather than being guessed at.
  static AuthErrorCode parse(Object? raw) {
    if (raw is! String) return AuthErrorCode.unknown;
    for (final code in values) {
      if (code.wireValue != null && code.wireValue == raw) return code;
    }
    return AuthErrorCode.unknown;
  }
}

/// A failed account call: what went wrong, and which fields the backend refused.
class AuthFailure {
  final AuthErrorCode code;

  /// The backend's own `message`, kept only as a fallback for [AuthErrorCode.unknown]
  /// and for field errors. Never a stack trace: the backend's handler emits prose only.
  final String? serverMessage;

  final List<AuthFieldError> fieldErrors;

  /// The HTTP status, when there was a response.
  final int? status;

  const AuthFailure({
    required this.code,
    this.serverMessage,
    this.fieldErrors = const [],
    this.status,
  });

  const AuthFailure.network()
      : code = AuthErrorCode.network,
        serverMessage = null,
        fieldErrors = const [],
        status = null;

  const AuthFailure.timeout()
      : code = AuthErrorCode.timeout,
        serverMessage = null,
        fieldErrors = const [],
        status = null;

  const AuthFailure.malformed()
      : code = AuthErrorCode.malformed,
        serverMessage = null,
        fieldErrors = const [],
        status = null;

  /// Builds a failure from a response status and its decoded body.
  ///
  /// The body's `code` wins when it is one this build knows. Otherwise the status
  /// decides, so a 401 without a code is still an authentication failure rather
  /// than a generic one.
  factory AuthFailure.fromResponse(int status, Map<String, dynamic>? body) {
    final parsed = AuthErrorCode.parse(body?['code']);
    final code = parsed != AuthErrorCode.unknown ? parsed : _codeForStatus(status);
    return AuthFailure(
      code: code,
      serverMessage: _stringOrNull(body?['message']),
      fieldErrors: _fieldErrors(body?['fieldErrors']),
      status: status,
    );
  }

  /// The first error reported for [field], or null.
  AuthFieldError? fieldError(String field) {
    for (final error in fieldErrors) {
      if (error.field == field) return error;
    }
    return null;
  }

  static AuthErrorCode _codeForStatus(int status) => switch (status) {
        400 => AuthErrorCode.validationFailed,
        401 => AuthErrorCode.unauthorized,
        403 => AuthErrorCode.forbidden,
        409 => AuthErrorCode.unknown,
        >= 500 => AuthErrorCode.server,
        _ => AuthErrorCode.unknown,
      };

  static List<AuthFieldError> _fieldErrors(Object? raw) {
    if (raw is! List) return const [];
    final errors = <AuthFieldError>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final field = _stringOrNull(entry['field']);
      final message = _stringOrNull(entry['message']);
      if (field != null && message != null) {
        errors.add(AuthFieldError(field: field, message: message));
      }
    }
    return errors;
  }

  static String? _stringOrNull(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// The outcome of an account call that returns nothing but success.
class AuthResult<T> {
  final T? data;
  final AuthFailure? failure;

  const AuthResult.success([this.data]) : failure = null;

  const AuthResult.failed(AuthFailure this.failure) : data = null;

  bool get success => failure == null;
}
