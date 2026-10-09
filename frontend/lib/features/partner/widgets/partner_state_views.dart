import 'package:flutter/material.dart';

import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';

/// One view per [PartnerWorkspaceStatus], so every partner screen shows the
/// same thing for the same condition.
///
/// Built on the existing `OceanStateView` rather than a new state widget
/// family: the traveller app already standardises loading/empty/error here, and
/// the extranet should not fork that.
///
/// Only statuses the backend can actually produce are represented. There is no
/// speculative "pending payout", "verification in review by tier", or any other
/// workflow the API does not expose.
class PartnerWorkspaceStatusView extends StatelessWidget {
  final PartnerWorkspaceStatus status;

  /// Server-supplied detail (e.g. a rejection reason or a 403 message), when
  /// one was safe to show.
  final String? detail;

  /// Retry, sign in, or dismiss — whichever the status calls for. Null hides
  /// the action.
  final VoidCallback? onPrimaryAction;

  const PartnerWorkspaceStatusView({
    super.key,
    required this.status,
    this.detail,
    this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final spec = _specFor(l10n);
    return OceanStateView(
      icon: spec.icon,
      title: spec.title,
      message: detail == null || detail!.isEmpty
          ? spec.message
          : '${spec.message}\n\n$detail',
      semanticLabel: spec.title,
      actionLabel: onPrimaryAction == null ? null : spec.actionLabel,
      onAction: onPrimaryAction,
      showProgress: status == PartnerWorkspaceStatus.loading,
      primaryAction: status != PartnerWorkspaceStatus.notPartner,
    );
  }

  _StatusSpec _specFor(AppLocalizations l10n) => switch (status) {
        PartnerWorkspaceStatus.idle ||
        PartnerWorkspaceStatus.loading =>
          _StatusSpec(
            icon: Icons.hourglass_empty_rounded,
            title: l10n.partnerStatusLoadingTitle,
            message: l10n.partnerStatusLoadingMessage,
            actionLabel: l10n.partnerActionRetry,
          ),
        PartnerWorkspaceStatus.ready => _StatusSpec(
            icon: Icons.check_circle_outline_rounded,
            title: l10n.partnerStatusReadyTitle,
            message: l10n.partnerStatusReadyMessage,
            actionLabel: l10n.partnerActionRefresh,
          ),
        PartnerWorkspaceStatus.demoUnavailable => _StatusSpec(
            icon: Icons.science_outlined,
            title: l10n.partnerStatusDemoTitle,
            message: l10n.partnerStatusDemoMessage,
            actionLabel: l10n.partnerActionBack,
          ),
        PartnerWorkspaceStatus.notPartner => _StatusSpec(
            icon: Icons.lock_outline_rounded,
            title: l10n.partnerStatusNotPartnerTitle,
            message: l10n.partnerStatusNotPartnerMessage,
            actionLabel: l10n.partnerActionBack,
          ),
        PartnerWorkspaceStatus.onboardingRequired => _StatusSpec(
            icon: Icons.storefront_outlined,
            title: l10n.partnerStatusOnboardingTitle,
            message: l10n.partnerStatusOnboardingMessage,
            actionLabel: l10n.partnerActionBack,
          ),
        PartnerWorkspaceStatus.awaitingApproval => _StatusSpec(
            icon: Icons.pending_actions_outlined,
            title: l10n.partnerStatusAwaitingApprovalTitle,
            message: l10n.partnerStatusAwaitingApprovalMessage,
            actionLabel: l10n.partnerActionRefresh,
          ),
        PartnerWorkspaceStatus.rejected => _StatusSpec(
            icon: Icons.cancel_outlined,
            title: l10n.partnerStatusRejectedTitle,
            message: l10n.partnerStatusRejectedMessage,
            actionLabel: l10n.partnerActionRefresh,
          ),
        PartnerWorkspaceStatus.suspended => _StatusSpec(
            icon: Icons.gpp_bad_outlined,
            title: l10n.partnerStatusSuspendedTitle,
            message: l10n.partnerStatusSuspendedMessage,
            actionLabel: l10n.partnerActionRefresh,
          ),
        PartnerWorkspaceStatus.membershipSuspended => _StatusSpec(
            icon: Icons.person_off_outlined,
            title: l10n.partnerStatusMembershipSuspendedTitle,
            message: l10n.partnerStatusMembershipSuspendedMessage,
            actionLabel: l10n.partnerActionRefresh,
          ),
        PartnerWorkspaceStatus.unauthorized => _StatusSpec(
            icon: Icons.person_off_outlined,
            title: l10n.partnerStatusUnauthorizedTitle,
            message: l10n.partnerStatusUnauthorizedMessage,
            actionLabel: l10n.partnerActionBack,
          ),
        PartnerWorkspaceStatus.forbidden => _StatusSpec(
            icon: Icons.block_outlined,
            title: l10n.partnerStatusForbiddenTitle,
            message: l10n.partnerStatusForbiddenMessage,
            actionLabel: l10n.partnerActionRetry,
          ),
        PartnerWorkspaceStatus.error => _StatusSpec(
            icon: Icons.error_outline_rounded,
            title: l10n.partnerStatusErrorTitle,
            message: l10n.partnerStatusErrorMessage,
            actionLabel: l10n.partnerActionRetry,
          ),
      };
}

class _StatusSpec {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;

  const _StatusSpec({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
  });
}

/// A pill for a `PartnerVerificationStatus`, paired with an icon so state is
/// never communicated by colour alone.
class PartnerVerificationPill extends StatelessWidget {
  final PartnerVerificationStatus status;

  const PartnerVerificationPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, color, icon) = switch (status) {
      PartnerVerificationStatus.approved => (
          l10n.partnerVerificationApproved,
          AppColors.success,
          Icons.verified_rounded,
        ),
      PartnerVerificationStatus.submitted => (
          l10n.partnerVerificationSubmitted,
          AppColors.info,
          Icons.pending_outlined,
        ),
      PartnerVerificationStatus.draft => (
          l10n.partnerVerificationDraft,
          AppColors.textTertiary,
          Icons.edit_note_rounded,
        ),
      PartnerVerificationStatus.rejected => (
          l10n.partnerVerificationRejected,
          AppColors.danger,
          Icons.cancel_outlined,
        ),
      PartnerVerificationStatus.suspended => (
          l10n.partnerVerificationSuspended,
          AppColors.warning,
          Icons.gpp_bad_outlined,
        ),
      PartnerVerificationStatus.unknown => (
          l10n.partnerVerificationUnknown,
          AppColors.textTertiary,
          Icons.help_outline_rounded,
        ),
    };
    return OceanStatusPill(label: label, color: color, icon: icon);
  }
}

/// A labelled operational metric. Deliberately dense and typographic rather
/// than decorative — this is an operations console, not a marketing page.
class PartnerMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const PartnerMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent = AppColors.ocean,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: accent),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
