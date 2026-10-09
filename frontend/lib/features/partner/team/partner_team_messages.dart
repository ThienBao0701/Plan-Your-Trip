import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../l10n/app_localizations.dart';

/// The one place a team or invitation failure becomes words (the pattern of
/// `core/partner/property_messages.dart`). It branches on the backend's stable
/// `code` — never on its English prose — and never echoes what the operator
/// typed: a refused reason or address is described, not repeated.
String partnerTeamFailureMessage(AppLocalizations l10n, ApiFailure failure) {
  switch (failure.code) {
    case 'EMAIL_DELIVERY_UNAVAILABLE':
      return l10n.partnerTeamErrorEmailUnavailable;
    case 'INVITATION_RATE_LIMITED':
      return l10n.partnerTeamErrorRateLimited;
    case 'ALREADY_MEMBER':
      return l10n.partnerTeamErrorAlreadyMember;
    case 'OWNER_PROTECTED':
      return l10n.partnerTeamErrorOwnerProtected;
    case 'ROLE_NOT_DELEGABLE':
      return l10n.partnerTeamErrorNotDelegable;
    case 'SELF_MODIFICATION_FORBIDDEN':
      return l10n.partnerTeamErrorSelf;
    case 'STEP_UP_REQUIRED':
      return l10n.partnerTeamErrorStepUp;
    case 'LAST_OWNER_REQUIRED':
      return l10n.partnerTeamErrorLastOwner;
    case 'CONCURRENT_MODIFICATION':
      return l10n.partnerTeamErrorConcurrent;
    case 'WORKSPACE_CONFLICT':
      return l10n.partnerTeamErrorWorkspaceConflict;
    case 'INVITATION_NOT_PENDING':
      return l10n.partnerTeamErrorInvitationNotPending;
    case 'INVITATION_STALE':
      return l10n.partnerTeamErrorInvitationStale;
    case 'SCOPE_INVALID':
      return l10n.partnerTeamErrorScopeInvalid;
    case 'PERMISSION_DENIED':
      return l10n.partnerTeamErrorPermission;
    case 'VALIDATION_FAILED':
      if (failure.blames('reason')) return l10n.partnerTeamErrorReason;
      if (failure.blames('email')) return l10n.partnerTeamErrorEmail;
      return l10n.partnerTeamErrorValidation;
  }
  return _byKind(l10n, failure.kind);
}

/// The invitee's side (`POST /api/me/partner-invitations/accept|decline`,
/// RBAC V1.1 §14, §26 E16–E19). The invited address is never echoed.
String partnerInvitationAcceptMessage(
    AppLocalizations l10n, ApiFailure failure) {
  switch (failure.code) {
    case 'INVITATION_INVALID':
      return l10n.partnerAcceptErrorInvalid;
    case 'INVITATION_EXPIRED':
      return l10n.partnerAcceptErrorExpired;
    case 'PARTNER_ACCOUNT_REQUIRED':
      return l10n.partnerAcceptErrorPartnerAccount;
    case 'INVITATION_ACCOUNT_MISMATCH':
      return l10n.partnerAcceptErrorMismatch;
    case 'WORKSPACE_CONFLICT':
      return failure.reason == 'OWN_PROFILE_EXISTS'
          ? l10n.partnerAcceptErrorOwnCompany
          : l10n.partnerAcceptErrorOtherWorkspace;
    case 'WORKSPACE_UNAVAILABLE':
      return l10n.partnerAcceptErrorUnavailable;
    case 'INVITATION_STALE':
      return l10n.partnerAcceptErrorStale;
    case 'VALIDATION_FAILED':
      return l10n.partnerAcceptErrorInvalid;
  }
  return _byKind(l10n, failure.kind);
}

/// Whether an acceptance failure means this link can never succeed, so the
/// screen drops the token (a network failure or 5xx keeps it for a retry).
bool partnerInvitationFailureIsFinal(ApiFailure failure) =>
    switch (failure.code) {
      'INVITATION_INVALID' ||
      'INVITATION_EXPIRED' ||
      'INVITATION_STALE' ||
      'VALIDATION_FAILED' =>
        true,
      _ => false,
    };

String _byKind(AppLocalizations l10n, ApiErrorKind kind) => switch (kind) {
      ApiErrorKind.unauthorized => l10n.partnerTeamErrorSession,
      ApiErrorKind.forbidden => l10n.partnerTeamErrorPermission,
      ApiErrorKind.notFound => l10n.partnerTeamErrorGone,
      ApiErrorKind.conflict => l10n.partnerTeamErrorConcurrent,
      ApiErrorKind.validation ||
      ApiErrorKind.unprocessable =>
        l10n.partnerTeamErrorValidation,
      ApiErrorKind.uncertain => l10n.partnerTeamErrorUncertain,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        l10n.partnerTeamErrorNetwork,
      ApiErrorKind.server ||
      ApiErrorKind.malformed =>
        l10n.partnerTeamErrorServer,
    };
