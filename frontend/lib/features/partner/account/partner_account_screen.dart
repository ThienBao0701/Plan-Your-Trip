import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/partner/partner_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../account/account_screen.dart';
import 'partner_business_profile_screen.dart';
import 'partner_business_profile_state.dart';

/// The Partner account area: account details, security, and the business profile
/// that decides whether the workspace opens.
///
/// It is deliberately reachable while the workspace is closed — a Partner whose
/// profile is missing, in review, rejected or suspended still needs somewhere to
/// see why and to act on it.
class PartnerAccountScreen extends StatefulWidget {
  final VoidCallback onBack;

  const PartnerAccountScreen({super.key, required this.onBack});

  @override
  State<PartnerAccountScreen> createState() => _PartnerAccountScreenState();
}

class _PartnerAccountScreenState extends State<PartnerAccountScreen> {
  PartnerBusinessProfileState? _business;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_business != null) return;
    final state = PartnerBusinessProfileState(api: AppScope.of(context).api);
    _business = state;
    state.load();
  }

  @override
  void dispose() {
    _business?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final business = _business;
    return AccountScreen(
      title: l10n.accountTitle,
      backLabel: l10n.accountBackToWorkspace,
      onBack: widget.onBack,
      sections: [
        if (business != null) PartnerBusinessProfileCard(state: business),
      ],
    );
  }
}

/// The business profile as a status card: where the application stands, what it
/// says, and the one action that is possible from here.
class PartnerBusinessProfileCard extends StatelessWidget {
  final PartnerBusinessProfileState state;

  const PartnerBusinessProfileCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        return OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.partnerBusinessHeading,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              ..._body(context, l10n),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _body(BuildContext context, AppLocalizations l10n) {
    switch (state.status) {
      case PartnerBusinessProfileStatus.idle:
      case PartnerBusinessProfileStatus.loading:
        return const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: SizedBox.square(
                dimension: 32,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ];
      case PartnerBusinessProfileStatus.unauthorized:
        return [
          Text(l10n.authErrorSessionExpired,
              style: Theme.of(context).textTheme.bodyMedium),
        ];
      case PartnerBusinessProfileStatus.error:
        return [
          Text(
            state.errorMessage ?? l10n.authErrorNetwork,
            key: const Key('business-profile-load-error'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OceanSecondaryButton(
            key: const Key('business-profile-retry'),
            label: l10n.partnerActionRetry,
            icon: Icons.refresh_rounded,
            onPressed: state.load,
          ),
        ];
      case PartnerBusinessProfileStatus.missing:
        return [
          Text(
            l10n.partnerBusinessNoneTitle,
            key: const Key('business-profile-missing'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.partnerBusinessNoneBody,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          OceanPrimaryButton(
            key: const Key('business-profile-add'),
            label: l10n.partnerBusinessAddAction,
            icon: Icons.add_business_rounded,
            semanticLabel: l10n.partnerBusinessAddAction,
            onPressed: () => _openForm(context),
          ),
        ];
      case PartnerBusinessProfileStatus.ready:
        return _readyBody(context, l10n);
    }
  }

  List<Widget> _readyBody(BuildContext context, AppLocalizations l10n) {
    final profile = state.profile;
    if (profile == null) return const [];
    final theme = Theme.of(context);
    return [
      Row(
        children: [
          OceanStatusPill(
            key: const Key('business-profile-status'),
            label: partnerProfileStatusLabel(l10n, profile.verificationStatus),
            icon: _statusIcon(profile.verificationStatus),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        _statusBody(l10n, profile.verificationStatus),
        key: const Key('business-profile-status-body'),
        style: theme.textTheme.bodyMedium,
      ),
      if (profile.rejectReason != null && profile.rejectReason!.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.partnerBusinessRejectReason(profile.rejectReason!),
          key: const Key('business-profile-reject-reason'),
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AccountField(
        label: l10n.partnerBusinessFieldName,
        value: profile.businessName,
      ),
      AccountField(
        label: l10n.partnerBusinessFieldType,
        value: partnerBusinessTypeLabel(l10n, profile.businessTypeValue),
      ),
      AccountField(
        label: l10n.partnerBusinessFieldRepresentative,
        value: profile.representativeName,
      ),
      AccountField(
        label: l10n.partnerBusinessFieldPhone,
        value: profile.phone,
      ),
      AccountField(
        label: l10n.partnerBusinessFieldAddress,
        value: profile.address,
      ),
      if (state.canEdit) ...[
        const SizedBox(height: AppSpacing.sm),
        OceanPrimaryButton(
          key: const Key('business-profile-edit'),
          label: l10n.partnerBusinessEditAction,
          icon: Icons.edit_outlined,
          semanticLabel: l10n.partnerBusinessEditAction,
          onPressed: () => _openForm(context),
        ),
      ] else ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.partnerProfileReadOnlyNotice,
          key: const Key('business-profile-read-only'),
          style: theme.textTheme.bodySmall,
        ),
      ],
    ];
  }

  String _statusBody(
    AppLocalizations l10n,
    PartnerVerificationStatus status,
  ) =>
      switch (status) {
        PartnerVerificationStatus.draft => l10n.partnerBusinessStatusDraftBody,
        PartnerVerificationStatus.submitted =>
          l10n.partnerBusinessStatusSubmittedBody,
        PartnerVerificationStatus.approved =>
          l10n.partnerBusinessStatusApprovedBody,
        PartnerVerificationStatus.rejected =>
          l10n.partnerBusinessStatusRejectedBody,
        PartnerVerificationStatus.suspended =>
          l10n.partnerBusinessStatusSuspendedBody,
        PartnerVerificationStatus.unknown =>
          l10n.partnerBusinessStatusUnknownBody,
      };

  IconData _statusIcon(PartnerVerificationStatus status) => switch (status) {
        PartnerVerificationStatus.draft => Icons.edit_note_rounded,
        PartnerVerificationStatus.submitted => Icons.hourglass_top_rounded,
        PartnerVerificationStatus.approved => Icons.verified_rounded,
        PartnerVerificationStatus.rejected => Icons.cancel_outlined,
        PartnerVerificationStatus.suspended => Icons.pause_circle_outline,
        PartnerVerificationStatus.unknown => Icons.help_outline_rounded,
      };

  Future<void> _openForm(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PartnerBusinessProfileScreen(state: state),
      ),
    );
    await state.load();
  }
}

/// The localized label of a profile's verification status.
String partnerProfileStatusLabel(
  AppLocalizations l10n,
  PartnerVerificationStatus status,
) =>
    switch (status) {
      PartnerVerificationStatus.draft => l10n.partnerProfileStatusDraft,
      PartnerVerificationStatus.submitted => l10n.partnerProfileStatusSubmitted,
      PartnerVerificationStatus.approved => l10n.partnerProfileStatusApproved,
      PartnerVerificationStatus.rejected => l10n.partnerProfileStatusRejected,
      PartnerVerificationStatus.suspended => l10n.partnerProfileStatusSuspended,
      PartnerVerificationStatus.unknown => l10n.partnerProfileStatusUnknown,
    };
