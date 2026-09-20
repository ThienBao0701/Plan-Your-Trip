/// The one place a refused property write becomes something a person reads.
///
/// Screens call [propertyFailureMessage] rather than switching on codes
/// themselves, so one refusal says the same thing everywhere. Nothing here
/// exposes a status line, an exception name or the server's own prose as the
/// primary message: an unrecognised failure falls back to the generic copy.
library;

import '../../l10n/app_localizations.dart';
import '../network/api_client.dart';
import '../network/api_failure.dart';

/// The stable `code` values `PartnerPropertyService` emits, exactly as spelled
/// on the wire.
class PropertyErrorCodes {
  const PropertyErrorCodes._();

  static const String validationFailed = 'VALIDATION_FAILED';
  static const String categoryInvalid = 'CATEGORY_INVALID';
  static const String subcategoryInvalid = 'SUBCATEGORY_INVALID';
  static const String locationInvalid = 'LOCATION_INVALID';
  static const String amenityInvalid = 'AMENITY_INVALID';
  static const String slugConflict = 'SLUG_CONFLICT';
}

String propertyFailureMessage(AppLocalizations l10n, ApiFailure failure) {
  // The backend's own code wins when it sent one: it is the precise reason.
  switch (failure.code) {
    case PropertyErrorCodes.validationFailed:
      return l10n.partnerPropertyErrorValidation;
    case PropertyErrorCodes.categoryInvalid:
    case PropertyErrorCodes.subcategoryInvalid:
      return l10n.partnerPropertyErrorCategory;
    case PropertyErrorCodes.locationInvalid:
      return l10n.partnerPropertyErrorLocation;
    case PropertyErrorCodes.amenityInvalid:
      return l10n.partnerPropertyErrorAmenity;
    case PropertyErrorCodes.slugConflict:
      return l10n.partnerPropertyErrorSlugConflict;
  }
  // Otherwise the transport/status classification decides.
  return switch (failure.kind) {
    ApiErrorKind.validation => l10n.partnerPropertyErrorValidation,
    ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
    // 403 on these endpoints means one thing: the business profile is not
    // approved. The workspace shell says the same, in the same words.
    ApiErrorKind.forbidden => l10n.partnerPropertyErrorApproval,
    ApiErrorKind.notFound => l10n.partnerPropertyActionNotFound,
    ApiErrorKind.conflict => l10n.partnerPropertyErrorSlugConflict,
    ApiErrorKind.unprocessable => l10n.partnerPropertyErrorValidation,
    ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
    ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
    ApiErrorKind.server => l10n.partnerDashboardErrorServer,
    // The request may have been committed before the connection dropped;
    // never reported as either success or a clean failure.
    ApiErrorKind.uncertain => l10n.partnerPropertyActionUncertain,
    ApiErrorKind.malformed => l10n.partnerDashboardErrorGeneric,
  };
}

/// The reason the backend gave for one field, or null when it named none.
///
/// Shown on the control that caused it, in the backend's English wording,
/// always alongside the localized summary rather than instead of it.
String? propertyFieldMessage(ApiFailure? failure, String field) =>
    failure?.fieldError(field)?.message;
