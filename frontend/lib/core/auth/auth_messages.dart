import '../../l10n/app_localizations.dart';
import 'auth_error.dart';

/// The one place an [AuthFailure] becomes something a person reads.
///
/// Screens call [authFailureMessage] instead of switching on codes themselves,
/// so a code is mapped once and every account screen says the same thing about
/// the same failure. Nothing here exposes a status line, an exception name or any
/// other implementation detail: unrecognised failures fall back to the generic
/// message rather than printing the server's prose.
String authFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure.code) {
      AuthErrorCode.validationFailed => l10n.authErrorValidation,
      AuthErrorCode.emailAlreadyRegistered => l10n.authErrorEmailTaken,
      AuthErrorCode.invalidCredentials => l10n.authErrorInvalidCredentials,
      AuthErrorCode.accountDisabled => l10n.authErrorAccountDisabled,
      AuthErrorCode.accountUnavailable => l10n.authErrorAccountUnavailable,
      AuthErrorCode.emailNotVerified => l10n.authErrorEmailNotVerified,
      AuthErrorCode.tokenInvalid => l10n.authErrorTokenInvalid,
      AuthErrorCode.tokenExpired => l10n.authErrorTokenExpired,
      AuthErrorCode.currentPasswordIncorrect => l10n.authErrorCurrentPassword,
      AuthErrorCode.passwordUnchanged => l10n.authErrorPasswordUnchanged,
      AuthErrorCode.emailDeliveryUnavailable => l10n.authErrorEmailDelivery,
      AuthErrorCode.unauthorized => l10n.authErrorSessionExpired,
      AuthErrorCode.forbidden => l10n.authErrorAccountUnavailable,
      AuthErrorCode.network => l10n.authErrorNetwork,
      AuthErrorCode.timeout => l10n.authErrorTimeout,
      AuthErrorCode.server => l10n.authErrorServer,
      AuthErrorCode.malformed || AuthErrorCode.unknown => l10n.authErrorGeneric,
    };

/// The same mapping, for a **sign-in** refusal.
///
/// On the sign-in screen a bare 401 or 403 means the credentials were refused,
/// not that a session ran out, so those degrade to "email or password is
/// incorrect" instead of the session-expired copy that is right everywhere else.
/// Every recognised code still maps exactly as elsewhere.
String authSignInFailureMessage(AppLocalizations l10n, AuthFailure failure) =>
    switch (failure.code) {
      AuthErrorCode.unauthorized ||
      AuthErrorCode.forbidden ||
      AuthErrorCode.unknown =>
        l10n.authErrorInvalidCredentials,
      _ => authFailureMessage(l10n, failure),
    };

/// The reason the backend gave for one field, or null when it did not name it.
///
/// Used to mark a field after a submit the client's own validators let through —
/// a contract drift, or a rule only the server knows. The server's wording is
/// shown because it is the precise reason; it is English-only, so the localized
/// [authFailureMessage] is always shown alongside it rather than replaced by it.
String? authFieldMessage(AuthFailure failure, String field) =>
    failure.fieldError(field)?.message;

/// Whether this failure blames [field].
bool authFailureBlames(AuthFailure failure, String field) =>
    failure.fieldError(field) != null;

/// Field names as the backend's `fieldErrors` spell them.
class AuthFields {
  const AuthFields._();

  static const String fullName = 'fullName';
  static const String email = 'email';
  static const String password = 'password';
  static const String newPassword = 'newPassword';
  static const String currentPassword = 'currentPassword';
  static const String acceptTerms = 'acceptTerms';
  static const String token = 'token';
}
