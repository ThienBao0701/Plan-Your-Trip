import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_policy_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_policies_state.dart';
import 'widgets/partner_policy_widgets.dart';

/// The Partner Policies module — guest-facing property policies plus workspace
/// notification settings.
///
/// ## Backend contract (verified in `backend-v1`/`develop` and live on :8081)
///
/// | Domain | Endpoint | Scope | Write rule |
/// |---|---|---|---|
/// | Property policies | `PUT /api/partner/hotels/{id}/policies` | one property | **owner only** |
/// | Workspace settings | `GET/PUT /api/partner/settings` | whole partner | **OWNER or MANAGER** |
///
/// Property policies are read back from `GET /api/partner/hotels/{id}` — there
/// is no dedicated policy GET.
///
/// ## Why this phase ships real edit forms
///
/// Both request records carry **every** field the form shows (5 and 9). Unlike
/// the property `PUT` (C2) and the rate-plan `PUT` (C5), which null out omitted
/// optional fields, nothing here can be silently erased by omission — so a full
/// editor is safe to build.
///
/// ## Assets
///
/// **Not implemented, because no partner asset API exists.** Every media
/// mutation (`POST /api/admin/media`, `PUT`, `deactivate`, `cover`, `reorder`)
/// sits under `/api/admin/**`, gated on `hasRole("ADMIN")`; a PARTNER receives
/// 403 on all of them, verified live. `GET /api/places/{id}/media` is a public
/// read for a published place, not a management surface. No upload, delete or
/// reorder affordance is shown, because none would work.
class PartnerPoliciesScreen extends StatefulWidget {
  const PartnerPoliciesScreen({super.key});

  @override
  State<PartnerPoliciesScreen> createState() => _PartnerPoliciesScreenState();
}

class _PartnerPoliciesScreenState extends State<PartnerPoliciesScreen> {
  PartnerPoliciesState? _policies;
  PartnerState? _partner;
  int? _syncedPropertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _policies?.dispose();
      _policies = PartnerPoliciesState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final policies = _policies!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) policies.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _policies?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final policies = _policies;
    if (partner == null || policies == null) return;
    await policies.load(partner, partner.selectedPropertyId);
  }

  @override
  Widget build(BuildContext context) {
    final partner = PartnerScope.of(context);
    final policies = _policies;

    if (!partner.isReady || policies == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: policies,
      builder: (context, _) => _PoliciesBody(
        partner: partner,
        policies: policies,
        onReload: _reload,
      ),
    );
  }
}

class _PoliciesBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerPoliciesState policies;
  final Future<void> Function() onReload;

  const _PoliciesBody({
    required this.partner,
    required this.policies,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (policies.status) {
      case PartnerPoliciesStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerPoliciesStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: policies.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerPoliciesStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: policies.errorMessage,
          onPrimaryAction: onReload,
        );
      default:
        break;
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PoliciesHeader(
            partner: partner, policies: policies, onReload: onReload),
        const SizedBox(height: AppSpacing.md),
        if (partner.properties.length > 1) ...[
          _PropertySwitcher(partner: partner, policies: policies),
          const SizedBox(height: AppSpacing.md),
        ],
        _body(context, l10n, isWide),
      ],
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, bool isWide) {
    switch (policies.status) {
      case PartnerPoliciesStatus.noProperties:
        return OceanStateView(
          icon: Icons.apartment_outlined,
          title: l10n.partnerPoliciesNoPropertiesTitle,
          message: l10n.partnerPoliciesNoPropertiesMessage,
          semanticLabel: l10n.partnerPoliciesNoPropertiesTitle,
        );
      case PartnerPoliciesStatus.noPropertySelected:
        return OceanStateView(
          icon: Icons.touch_app_outlined,
          title: l10n.partnerPoliciesSelectPropertyTitle,
          message: l10n.partnerPoliciesSelectPropertyMessage,
          semanticLabel: l10n.partnerPoliciesSelectPropertyTitle,
        );
      case PartnerPoliciesStatus.notFound:
        return OceanStateView(
          icon: Icons.error_outline_rounded,
          title: l10n.partnerPoliciesUnavailableTitle,
          message: l10n.partnerPoliciesUnavailableMessage,
          semanticLabel: l10n.partnerPoliciesUnavailableTitle,
          actionLabel: l10n.partnerActionRetry,
          onAction: onReload,
        );
      case PartnerPoliciesStatus.idle:
      case PartnerPoliciesStatus.loading:
        return const _PoliciesLoading();
      case PartnerPoliciesStatus.ready:
        final left = _PropertyPolicyCard(partner: partner, policies: policies);
        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkspaceSettingsCard(partner: partner, policies: policies),
            const SizedBox(height: AppSpacing.md),
            const _AssetsDeferredCard(),
          ],
        );
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [left, const SizedBox(height: AppSpacing.md), right],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _PoliciesHeader extends StatelessWidget {
  final PartnerState partner;
  final PartnerPoliciesState policies;
  final Future<void> Function() onReload;

  const _PoliciesHeader({
    required this.partner,
    required this.policies,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final property = partner.selectedProperty;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerPoliciesTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  property == null
                      ? l10n.partnerPoliciesNoPropertyContext
                      : l10n.partnerPoliciesForProperty(property.name),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: policies.isLoading ? null : onReload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.partnerActionRefresh,
          ),
        ],
      ),
    );
  }
}

class _PropertySwitcher extends StatelessWidget {
  final PartnerState partner;
  final PartnerPoliciesState policies;

  const _PropertySwitcher({required this.partner, required this.policies});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partnerPoliciesPropertyScope,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final property in partner.properties)
                ChoiceChip(
                  label: Text(property.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  selected: partner.selectedPropertyId == property.id,
                  onSelected: policies.isLoading
                      ? null
                      : (_) => partner.selectProperty(property.id),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: partner.selectedPropertyId == property.id
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.ocean700,
                  backgroundColor: AppColors.surfaceMuted,
                  showCheckmark: false,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PoliciesLoading extends StatelessWidget {
  const _PoliciesLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Guest-facing property policies — `PUT /hotels/{id}/policies`, owner-only.
class _PropertyPolicyCard extends StatelessWidget {
  final PartnerState partner;
  final PartnerPoliciesState policies;

  const _PropertyPolicyCard({required this.partner, required this.policies});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = policies.draftPolicies;
    final canEdit =
        PartnerPolicyPermissions.canEditPropertyPolicies(partner.teamRole);

    if (draft == null) return const SizedBox.shrink();

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerPoliciesPropertySection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.partnerPoliciesPropertyScopeNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Policy changes are live for everyone, including guests who already
          // hold a booking — the backend does not snapshot them onto bookings.
          PartnerPolicyNotice(
            message: l10n.partnerPoliciesLiveWarning,
            warning: true,
          ),
          if (!canEdit) ...[
            const SizedBox(height: AppSpacing.xs),
            PartnerPolicyNotice(message: l10n.partnerPoliciesOwnerOnly),
          ],
          const SizedBox(height: AppSpacing.md),

          PartnerPolicyTimeField(
            label: l10n.partnerPoliciesCheckIn,
            value: draft.checkIn,
            enabled: canEdit && !policies.isSavingPolicies,
            // The backend rejects a write without both times (@NotNull).
            required: true,
            onChanged: policies.setCheckIn,
          ),
          const SizedBox(height: AppSpacing.sm),
          PartnerPolicyTimeField(
            label: l10n.partnerPoliciesCheckOut,
            value: draft.checkOut,
            enabled: canEdit && !policies.isSavingPolicies,
            required: true,
            onChanged: policies.setCheckOut,
          ),
          const SizedBox(height: AppSpacing.md),

          Text(
            l10n.partnerPoliciesHouseRules,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.partnerPoliciesHouseRulesNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          PartnerPolicyTextField(
            label: l10n.partnerPoliciesChildren,
            value: draft.childrenPolicy,
            enabled: canEdit && !policies.isSavingPolicies,
            onChanged: policies.setChildrenPolicy,
          ),
          const SizedBox(height: AppSpacing.sm),
          PartnerPolicyTextField(
            label: l10n.partnerPoliciesPets,
            value: draft.petPolicy,
            enabled: canEdit && !policies.isSavingPolicies,
            onChanged: policies.setPetPolicy,
          ),
          const SizedBox(height: AppSpacing.sm),
          PartnerPolicyTextField(
            label: l10n.partnerPoliciesSmoking,
            value: draft.smokingPolicy,
            enabled: canEdit && !policies.isSavingPolicies,
            onChanged: policies.setSmokingPolicy,
          ),

          if (policies.policiesErrorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            PartnerPolicyNotice(
              message: policies.policiesErrorMessage!,
              warning: true,
            ),
          ],

          if (canEdit) ...[
            const SizedBox(height: AppSpacing.md),
            PartnerPolicySaveBar(
              dirty: policies.policiesDirty,
              saving: policies.isSavingPolicies,
              canSave: policies.canSubmitPolicies,
              onRevert: policies.revertPolicies,
              onSave: () => _save(context),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await policies.savePolicies();
    if (!context.mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(_messageFor(l10n, result))));
  }
}

/// Workspace notification settings — `PUT /settings`, OWNER or MANAGER.
class _WorkspaceSettingsCard extends StatelessWidget {
  final PartnerState partner;
  final PartnerPoliciesState policies;

  const _WorkspaceSettingsCard({
    required this.partner,
    required this.policies,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final draft = policies.draftSettings;
    final canEdit =
        PartnerPolicyPermissions.canEditWorkspaceSettings(partner.teamRole);
    final formats =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm();

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerPoliciesSettingsSection,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.partnerPoliciesSettingsScopeNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (draft == null) ...[
            PartnerPolicyNotice(
              message: _settingsErrorText(l10n, policies.settingsLoadErrorKind),
              warning: true,
            ),
          ] else ...[
            if (!canEdit)
              PartnerPolicyNotice(
                  message: l10n.partnerPoliciesSettingsRoleNote),
            if (!canEdit) const SizedBox(height: AppSpacing.sm),

            // Language and timezone are free-text on the backend with no
            // validated set, so they are shown rather than edited.
            PartnerPolicyReadOnlyRow(
              label: l10n.partnerPoliciesLanguage,
              value: draft.defaultLanguage,
            ),
            PartnerPolicyReadOnlyRow(
              label: l10n.partnerPoliciesTimezone,
              value: draft.timezone,
            ),
            const SizedBox(height: AppSpacing.md),

            Text(
              l10n.partnerPoliciesChannels,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesChannelEmail,
              value: draft.notificationEmailEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.email, v),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesChannelSms,
              value: draft.notificationSmsEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.sms, v),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesChannelInApp,
              value: draft.notificationInAppEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.inApp, v),
            ),

            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.partnerPoliciesTopics,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesTopicBooking,
              value: draft.bookingNotificationEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.booking, v),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesTopicPayment,
              value: draft.paymentNotificationEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.payment, v),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesTopicReview,
              value: draft.reviewNotificationEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.review, v),
            ),
            PartnerPolicySwitch(
              label: l10n.partnerPoliciesTopicPromotion,
              value: draft.promotionNotificationEnabled,
              enabled: canEdit && !policies.isSavingSettings,
              onChanged: (v) =>
                  policies.toggleSetting(PartnerSettingsToggle.promotion, v),
            ),

            if (draft.updatedAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.partnerPoliciesSettingsUpdated(
                    formats.format(draft.updatedAt!)),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],

            if (policies.settingsErrorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              PartnerPolicyNotice(
                message: policies.settingsErrorMessage!,
                warning: true,
              ),
            ],

            if (canEdit) ...[
              const SizedBox(height: AppSpacing.md),
              PartnerPolicySaveBar(
                dirty: policies.settingsDirty,
                saving: policies.isSavingSettings,
                canSave: true,
                onRevert: policies.revertSettings,
                onSave: () => _save(context),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _settingsErrorText(AppLocalizations l10n, ApiErrorKind? kind) =>
      switch (kind) {
        ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
        ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
        ApiErrorKind.notFound => l10n.partnerPoliciesSettingsUnavailable,
        ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
        ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
        _ => l10n.partnerDashboardErrorGeneric,
      };

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await policies.saveSettings();
    if (!context.mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(_messageFor(l10n, result))));
  }
}

/// States plainly that asset management has no backend behind it, rather than
/// showing controls that would 403.
class _AssetsDeferredCard extends StatelessWidget {
  const _AssetsDeferredCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  size: 18, color: AppColors.textTertiary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.partnerAssetsSection,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              OceanStatusPill(
                label: l10n.partnerAssetsDeferredBadge,
                color: AppColors.textTertiary,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.partnerAssetsDeferredMessage,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _messageFor(AppLocalizations l10n, PartnerPolicySaveResult result) =>
    switch (result) {
      PartnerPolicySaveResult.success => l10n.partnerPoliciesSaved,
      PartnerPolicySaveResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerPolicySaveResult.forbidden => l10n.partnerPoliciesSaveForbidden,
      PartnerPolicySaveResult.notFound => l10n.partnerPoliciesSaveNotFound,
      PartnerPolicySaveResult.validation => l10n.partnerPoliciesSaveValidation,
      PartnerPolicySaveResult.uncertain => l10n.partnerPropertyActionUncertain,
      PartnerPolicySaveResult.failed => l10n.partnerPropertyActionFailed,
    };
