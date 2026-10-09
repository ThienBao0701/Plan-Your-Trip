/// A refused write, as the backend actually describes one.
///
/// Phase A gave every error one body: `{timestamp, status, error, message, path}`
/// plus, when the server has them, a stable `code` and a `fieldErrors` list of
/// `{field, message}`. Phase B parses that for the account endpoints
/// (`core/auth/auth_error.dart`); this is the same reading for every other
/// write, keeping the [ApiErrorKind] vocabulary the collection endpoints
/// already use so one call site never has to learn two.
///
/// Nothing here is copy: a failure becomes words in exactly one place per
/// feature (for properties, `core/partner/property_messages.dart`).
library;

import 'api_client.dart' show ApiErrorKind;

/// One invalid field, named by the backend.
class ApiFieldError {
  final String field;
  final String message;

  const ApiFieldError({required this.field, required this.message});
}

class ApiFailure {
  /// How the call failed, in the same terms as every other client result.
  final ApiErrorKind kind;

  /// The backend's stable `code` (`VALIDATION_FAILED`, `CATEGORY_INVALID`,
  /// `SLUG_CONFLICT`, …), or null when it sent none. Screens branch on this,
  /// never on [serverMessage].
  final String? code;

  /// The backend's own English prose. Kept for the fields it names and as a
  /// last resort; never shown as a screen's primary message.
  final String? serverMessage;

  final List<ApiFieldError> fieldErrors;

  /// The HTTP status, when there was a response at all.
  final int? status;

  /// RBAC R5 — the sub-reason of [code] the backend sends with some conflicts,
  /// e.g. `OWN_PROFILE_EXISTS` or `MEMBERSHIP_EXISTS` for `WORKSPACE_CONFLICT`.
  final String? reason;

  const ApiFailure({
    required this.kind,
    this.code,
    this.serverMessage,
    this.fieldErrors = const [],
    this.status,
    this.reason,
  });

  const ApiFailure.of(this.kind)
      : code = null,
        serverMessage = null,
        fieldErrors = const [],
        status = null,
        reason = null;

  /// Reads a response body into a failure. [kind] comes from the status, so an
  /// unknown `code` still lands in the right category.
  factory ApiFailure.fromResponse(
    int status,
    Map<String, dynamic>? body,
    ApiErrorKind kind,
  ) =>
      ApiFailure(
        kind: kind,
        code: _stringOrNull(body?['code']),
        serverMessage: _stringOrNull(body?['message']),
        fieldErrors: _fieldErrors(body?['fieldErrors']),
        status: status,
        reason: _stringOrNull(body?['reason']),
      );

  /// The first error reported for [field], or null.
  ApiFieldError? fieldError(String field) {
    for (final error in fieldErrors) {
      if (error.field == field) return error;
    }
    return null;
  }

  /// Whether the backend blamed [field].
  bool blames(String field) => fieldError(field) != null;

  /// True when the request may have been committed even though no answer
  /// arrived. Never reported as a clean success or a clean failure.
  bool get isUncertain => kind == ApiErrorKind.uncertain;

  static List<ApiFieldError> _fieldErrors(Object? raw) {
    if (raw is! List) return const [];
    final errors = <ApiFieldError>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final field = _stringOrNull(entry['field']);
      final message = _stringOrNull(entry['message']);
      if (field != null && message != null) {
        errors.add(ApiFieldError(field: field, message: message));
      }
    }
    return errors;
  }

  static String? _stringOrNull(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// The outcome of a write: the server's own updated record, or why it refused.
class ApiWriteResult<T> {
  final T? data;
  final ApiFailure? failure;

  const ApiWriteResult.success(this.data) : failure = null;

  const ApiWriteResult.failed(ApiFailure this.failure) : data = null;

  /// A failure with no server answer to read — offline, timed out, unreadable.
  factory ApiWriteResult.of(ApiErrorKind kind) =>
      ApiWriteResult.failed(ApiFailure.of(kind));

  bool get success => failure == null;
}
