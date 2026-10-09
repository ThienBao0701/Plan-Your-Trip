import 'package:flutter/material.dart';

import '../../../core/admin/admin_access_models.dart';
import '../../../core/network/api_client.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../partner/team/partner_step_up_dialog.dart';
import '../admin_access_state.dart';
import '../widgets/admin_widgets.dart';

/// RBAC R6 — administrators and their admin profiles (RBAC V1.1 §7, §25.4).
///
/// Shown only to callers whose access document grants `admin.access.manage`
/// (only `PLATFORM_OWNER` holds it); the server refuses everyone else
/// regardless. An administrator's own row cannot be edited (AP-1), a change
/// that would leave no platform owner is refused (AP-2), and a change needs a
/// fresh session: the password step-up dialog opens once and the change is
/// retried once.
class AdminAccessScreen extends StatefulWidget {
  final AdminAccessManagementState state;

  const AdminAccessScreen({super.key, required this.state});

  @override
  State<AdminAccessScreen> createState() => _AdminAccessScreenState();
}

class _AdminAccessScreenState extends State<AdminAccessScreen> {
  AdminAccessManagementState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _state.addListener(_changed);
  }

  @override
  void didUpdateWidget(AdminAccessScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.state, widget.state)) {
      oldWidget.state.removeListener(_changed);
      widget.state.addListener(_changed);
    }
  }

  @override
  void dispose() {
    _state.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _edit(AdminAccount account) async {
    final l10n = AppLocalizations.of(context)!;
    final edit = await showDialog<_ProfileEdit>(
      context: context,
      builder: (_) => _EditProfilesDialog(account: account),
    );
    if (edit == null || !mounted) return;

    var result = await _state.replaceProfiles(account.userId, edit.profiles,
        reason: edit.reason);
    if (result != null && result.stepUpRequired && mounted) {
      final confirmed = await showPartnerStepUpDialog(context);
      if (!confirmed || !mounted) return;
      result = await _state.replaceProfiles(account.userId, edit.profiles,
          reason: edit.reason);
    }
    if (result == null || !mounted) return;
    final message =
        result.success ? l10n.adminAccessSaved : _failureMessage(l10n, result);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static String _failureMessage(
      AppLocalizations l10n, AdminProfileChangeResult result) {
    switch (result.code) {
      case 'LAST_PLATFORM_OWNER_REQUIRED':
        return l10n.adminAccessErrorLastOwner;
      case 'SELF_MODIFICATION_FORBIDDEN':
        return l10n.adminAccessErrorSelf;
      case 'PERMISSION_DENIED':
        return l10n.adminAccessErrorPermission;
      case 'STEP_UP_REQUIRED':
        return l10n.adminAccessErrorStepUp;
      case 'VALIDATION_FAILED':
        return l10n.adminAccessErrorValidation;
    }
    return switch (result.failure?.kind) {
      ApiErrorKind.uncertain => l10n.adminAccessErrorUncertain,
      ApiErrorKind.notFound => l10n.adminAccessErrorGone,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        l10n.adminAccessErrorNetwork,
      _ => l10n.adminErrorGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ready = _state.status == AdminLoadStatus.ready;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.adminAccessSubtitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
              IconButton(
                key: const Key('admin-access-refresh'),
                tooltip: l10n.adminAccessRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: _state.status == AdminLoadStatus.loading
                    ? null
                    : _state.load,
              ),
            ],
          ),
        ),
        Expanded(
          child: !ready || _state.admins.isEmpty
              ? AdminStateView(
                  key: const Key('admin-access-state'),
                  status: _state.status,
                  emptyTitle: l10n.adminAccessEmptyTitle,
                  emptyMessage: l10n.adminAccessEmptyMessage,
                  onRetry: _state.load,
                )
              : ListView.builder(
                  key: const Key('admin-access-list'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _state.admins.length,
                  itemBuilder: (context, i) {
                    final account = _state.admins[i];
                    // A profile this build cannot name would be dropped by a
                    // save, i.e. silently revoked, so such a row is read-only.
                    final unknown =
                        account.profiles.contains(AdminProfile.unknown);
                    return _AdminAccountCard(
                      account: account,
                      busy: _state.isBusy(account.userId),
                      onEdit:
                          account.self || unknown ? null : () => _edit(account),
                      lockedHint: account.self
                          ? l10n.adminAccessSelfHint
                          : l10n.adminAccessUnknownHint,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AdminAccountCard extends StatelessWidget {
  final AdminAccount account;
  final bool busy;

  /// Null for the caller's own row — nobody changes their own profiles
  /// (AP-1) — and for a row holding a profile this build does not know.
  final VoidCallback? onEdit;

  /// Why [onEdit] is null.
  final String lockedHint;

  const _AdminAccountCard({
    required this.account,
    required this.busy,
    required this.onEdit,
    required this.lockedHint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      key: Key('admin-access-account-${account.userId}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account.fullName,
                          style: theme.textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis),
                      Text(account.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (busy)
                  const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Tooltip(
                    message: onEdit == null ? lockedHint : l10n.adminAccessEdit,
                    child: TextButton.icon(
                      key: Key('admin-access-edit-${account.userId}'),
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.adminAccessEdit),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xxs,
              runSpacing: AppSpacing.xxs,
              children: [
                if (account.self)
                  OceanStatusPill(
                    key: Key('admin-access-self-${account.userId}'),
                    label: l10n.adminAccessYou,
                    color: theme.colorScheme.primary,
                  ),
                if (!account.enabled)
                  OceanStatusPill(
                    label: l10n.adminAccessDisabled,
                    color: theme.colorScheme.error,
                  ),
                if (account.profiles.isEmpty)
                  OceanStatusPill(
                    key: Key('admin-access-none-${account.userId}'),
                    label: l10n.adminAccessNoProfiles,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                for (final profile in account.profiles)
                  OceanStatusPill(
                    label: adminProfileLabel(l10n, profile),
                    color: profile == AdminProfile.platformOwner
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.secondary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileEdit {
  final List<AdminProfile> profiles;
  final String? reason;

  const _ProfileEdit(this.profiles, this.reason);
}

class _EditProfilesDialog extends StatefulWidget {
  final AdminAccount account;

  const _EditProfilesDialog({required this.account});

  @override
  State<_EditProfilesDialog> createState() => _EditProfilesDialogState();
}

class _EditProfilesDialogState extends State<_EditProfilesDialog> {
  late final Set<AdminProfile> _selected = {
    ...widget.account.profiles.where((p) => p != AdminProfile.unknown),
  };
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return AlertDialog(
      key: const Key('admin-access-dialog'),
      title: Text(l10n.adminAccessEditTitle(widget.account.fullName)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.adminAccessEditHint,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: AppSpacing.xs),
              for (final profile in AdminProfile.assignable)
                CheckboxListTile(
                  key: Key('admin-access-profile-${profile.wire}'),
                  value: _selected.contains(profile),
                  onChanged: (on) => setState(() => on == true
                      ? _selected.add(profile)
                      : _selected.remove(profile)),
                  title: Text(adminProfileLabel(l10n, profile)),
                  subtitle: Text(adminProfileDescription(l10n, profile)),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const Key('admin-access-reason'),
                controller: _reason,
                maxLength: 500,
                decoration: InputDecoration(labelText: l10n.adminAccessReason),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.adminAccessCancel),
        ),
        FilledButton(
          key: const Key('admin-access-save'),
          onPressed: () => Navigator.of(context).pop(_ProfileEdit(
            AdminProfile.assignable.where(_selected.contains).toList(),
            _reason.text,
          )),
          child: Text(l10n.adminAccessSave),
        ),
      ],
    );
  }
}

/// The one place an admin profile becomes words.
String adminProfileLabel(AppLocalizations l10n, AdminProfile profile) =>
    switch (profile) {
      AdminProfile.platformOwner => l10n.adminProfilePlatformOwner,
      AdminProfile.partnerOperations => l10n.adminProfilePartnerOperations,
      AdminProfile.contentCatalogue => l10n.adminProfileContentCatalogue,
      AdminProfile.bookingSupport => l10n.adminProfileBookingSupport,
      AdminProfile.financeOperations => l10n.adminProfileFinanceOperations,
      AdminProfile.growthMarketing => l10n.adminProfileGrowthMarketing,
      AdminProfile.trustSafety => l10n.adminProfileTrustSafety,
      AdminProfile.reviewModeration => l10n.adminProfileReviewModeration,
      AdminProfile.analytics => l10n.adminProfileAnalytics,
      AdminProfile.locationCatalogue => l10n.adminProfileLocationCatalogue,
      AdminProfile.techSupport => l10n.adminProfileTechSupport,
      AdminProfile.unknown => l10n.adminValueUnknown,
    };

/// One line on what the profile is for (RBAC V1.1 §7 "Purpose").
String adminProfileDescription(AppLocalizations l10n, AdminProfile profile) =>
    switch (profile) {
      AdminProfile.platformOwner => l10n.adminProfilePlatformOwnerHint,
      AdminProfile.partnerOperations => l10n.adminProfilePartnerOperationsHint,
      AdminProfile.contentCatalogue => l10n.adminProfileContentCatalogueHint,
      AdminProfile.bookingSupport => l10n.adminProfileBookingSupportHint,
      AdminProfile.financeOperations => l10n.adminProfileFinanceOperationsHint,
      AdminProfile.growthMarketing => l10n.adminProfileGrowthMarketingHint,
      AdminProfile.trustSafety => l10n.adminProfileTrustSafetyHint,
      AdminProfile.reviewModeration => l10n.adminProfileReviewModerationHint,
      AdminProfile.analytics => l10n.adminProfileAnalyticsHint,
      AdminProfile.locationCatalogue => l10n.adminProfileLocationCatalogueHint,
      AdminProfile.techSupport => l10n.adminProfileTechSupportHint,
      AdminProfile.unknown => '',
    };
