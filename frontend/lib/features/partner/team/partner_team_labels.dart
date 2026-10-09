import '../../../core/partner/partner_access_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_team_models.dart';
import '../../../l10n/app_localizations.dart';

/// The one place a team role, scope or status becomes words. Shared by the team
/// screen, the shell's identity header, the dashboard and settings, so a role is
/// never labelled two ways. Labels only: they decide nothing.
String partnerTeamRoleLabel(AppLocalizations l10n, PartnerTeamRole role) =>
    switch (role) {
      PartnerTeamRole.owner => l10n.partnerTeamRoleOwner,
      PartnerTeamRole.manager => l10n.partnerTeamRoleManager,
      PartnerTeamRole.revenue => l10n.partnerTeamRoleRevenue,
      PartnerTeamRole.reservations => l10n.partnerTeamRoleReservations,
      PartnerTeamRole.frontDesk => l10n.partnerTeamRoleFrontDesk,
      PartnerTeamRole.finance => l10n.partnerTeamRoleFinance,
      PartnerTeamRole.content => l10n.partnerTeamRoleContent,
      PartnerTeamRole.housekeeping => l10n.partnerTeamRoleHousekeeping,
      PartnerTeamRole.viewer => l10n.partnerTeamRoleViewer,
      PartnerTeamRole.unknown => l10n.partnerTeamRoleUnknown,
    };

String partnerScopeTypeLabel(AppLocalizations l10n, PartnerScopeType type) =>
    switch (type) {
      PartnerScopeType.company => l10n.partnerTeamScopeCompany,
      PartnerScopeType.property => l10n.partnerTeamScopeProperty,
      PartnerScopeType.unit => l10n.partnerTeamScopeUnit,
      PartnerScopeType.unknown => l10n.partnerTeamRoleUnknown,
    };

/// "Whole company", or the property / room type by name when the access
/// document names it (§11.7), or its number when the caller cannot see it.
String partnerScopeLabel(
        AppLocalizations l10n, PartnerScopeRef scope, PartnerAccess? access) =>
    switch (scope.type) {
      PartnerScopeType.company => l10n.partnerTeamScopeCompany,
      PartnerScopeType.property => access?.propertyName(scope.id) ??
          l10n.partnerTeamScopePropertyNumber(scope.id),
      PartnerScopeType.unit =>
        access?.unitName(scope.id) ?? l10n.partnerTeamScopeUnitNumber(scope.id),
      PartnerScopeType.unknown => l10n.partnerTeamRoleUnknown,
    };

String partnerMembershipStatusLabel(
        AppLocalizations l10n, PartnerMembershipStatus status) =>
    switch (status) {
      PartnerMembershipStatus.active => l10n.partnerTeamStatusActive,
      PartnerMembershipStatus.suspended => l10n.partnerTeamStatusSuspended,
      PartnerMembershipStatus.revoked => l10n.partnerTeamStatusRevoked,
      PartnerMembershipStatus.unknown => l10n.partnerTeamRoleUnknown,
    };

String partnerInvitationStatusLabel(
        AppLocalizations l10n, PartnerInvitationStatus status) =>
    switch (status) {
      PartnerInvitationStatus.pending => l10n.partnerInvitationStatusPending,
      PartnerInvitationStatus.accepted => l10n.partnerInvitationStatusAccepted,
      PartnerInvitationStatus.declined => l10n.partnerInvitationStatusDeclined,
      PartnerInvitationStatus.revoked => l10n.partnerInvitationStatusRevoked,
      PartnerInvitationStatus.expired => l10n.partnerInvitationStatusExpired,
      PartnerInvitationStatus.unknown => l10n.partnerTeamRoleUnknown,
    };

String partnerInvitationDeliveryLabel(
        AppLocalizations l10n, PartnerInvitationDelivery delivery) =>
    switch (delivery) {
      PartnerInvitationDelivery.queued => l10n.partnerInvitationDeliveryQueued,
      PartnerInvitationDelivery.sent => l10n.partnerInvitationDeliverySent,
      PartnerInvitationDelivery.failed => l10n.partnerInvitationDeliveryFailed,
      PartnerInvitationDelivery.unknown => l10n.partnerTeamRoleUnknown,
    };
