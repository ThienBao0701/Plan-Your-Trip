import 'package:flutter/material.dart';

import '../../../core/admin/admin_models.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../admin_partner_states.dart';
import '../widgets/admin_widgets.dart';

/// One partner, across the four sections the D2B contract freeze permits:
/// Overview, Team, Activity, Settings.
///
/// Everything here is **read-only** except the three lifecycle transitions.
/// There is no profile editor because no `PUT /api/admin/partners/{id}` exists;
/// no team controls because invite/role/remove are partner-side operations; no
/// settings save because no admin settings mutation exists; and no property
/// list because no admin endpoint returns one — only the count on Overview.
class AdminPartnerDetailScreen extends StatefulWidget {
  final AdminPartnerDetailState state;
  final VoidCallback onBack;

  const AdminPartnerDetailScreen({
    super.key,
    required this.state,
    required this.onBack,
  });

  @override
  State<AdminPartnerDetailScreen> createState() =>
      _AdminPartnerDetailScreenState();
}

class _AdminPartnerDetailScreenState extends State<AdminPartnerDetailScreen>
    with SingleTickerProviderStateMixin {
  // Constructed in initState rather than as a `late final` initialiser. On the
  // not-found path the tabs are never built, so a lazy field would still be
  // uninitialised when dispose() touched it — and the initialiser would then
  // run against a deactivated element, looking up TickerMode from a tree that
  // is already coming down.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;

    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        // The canonical read gates everything. Until it succeeds the
        // sub-resources are not even requested, because /team and
        // /activity-logs answer 200 with an empty body for a partner that does
        // not exist — rendering those would invent a partner.
        if (!state.isReady) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BackBar(onBack: widget.onBack, title: l10n.adminNavPartners),
              Expanded(
                // A partner that does not exist gets its own panel rather than
                // the shared kit's generic "not found": the operator needs to
                // know it was *this partner* that could not be resolved, not
                // that some request failed. The shared AdminStateView keeps its
                // wording for every other state, and for the five grids that
                // already depend on it.
                child: state.isNotFound
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: OceanEmptyState(
                            title: l10n.adminPartnerNotFoundTitle,
                            message: l10n.adminPartnerNotFoundMessage,
                          ),
                        ),
                      )
                    : AdminStateView(
                        status: state.profileStatus,
                        message: state.profileError,
                        onRetry: state.refresh,
                      ),
              ),
            ],
          );
        }

        final partner = state.profile!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackBar(
              onBack: widget.onBack,
              title: partner.businessName ?? l10n.adminValueUnknown,
              trailing: AdminStatusChip(status: partner.status.wire),
            ),
            if (state.mutationUncertain)
              _Banner(
                tone: _BannerTone.warning,
                message: l10n.adminPartnerActionUncertain,
              ),
            if (state.mutationError != null && !state.mutationUncertain)
              _Banner(tone: _BannerTone.error, message: state.mutationError!),
            _ActionBar(state: state),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabs: [
                Tab(text: l10n.adminPartnerTabOverview),
                Tab(text: l10n.adminPartnerTabTeam),
                Tab(text: l10n.adminPartnerTabActivity),
                Tab(text: l10n.adminPartnerTabSettings),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _OverviewTab(state: state),
                  _TeamTab(state: state),
                  _ActivityTab(state: state),
                  _SettingsTab(state: state),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BackBar extends StatelessWidget {
  final VoidCallback onBack;
  final String title;
  final Widget? trailing;

  const _BackBar({required this.onBack, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.adminPartnerBackToList,
            onPressed: onBack,
          ),
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            trailing!,
          ],
        ],
      ),
    );
  }
}

enum _BannerTone { warning, error }

class _Banner extends StatelessWidget {
  final _BannerTone tone;
  final String message;

  const _Banner({required this.tone, required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = tone == _BannerTone.warning
        ? scheme.tertiaryContainer
        : scheme.errorContainer;
    final fg = tone == _BannerTone.warning
        ? scheme.onTertiaryContainer
        : scheme.onErrorContainer;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
              tone == _BannerTone.warning
                  ? Icons.help_outline
                  : Icons.error_outline,
              size: 18,
              color: fg),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: fg)),
          ),
        ],
      ),
    );
  }
}

/// The lifecycle controls. Each appears only in the state the backend accepts —
/// approve and reject from SUBMITTED, suspend from APPROVED — because every
/// other state answers 422, and a permanently visible button that mostly fails
/// is worse than no button.
class _ActionBar extends StatelessWidget {
  final AdminPartnerDetailState state;

  const _ActionBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    if (!state.canApproveOrReject && !state.canSuspend) {
      if (state.status.isTerminalSuspension) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
          child: Text(l10n.adminPartnerSuspendedNotice,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.error)),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          if (state.canApproveOrReject) ...[
            FilledButton.icon(
              onPressed:
                  state.isMutating ? null : () => _confirmApprove(context),
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.adminPartnerApprove),
            ),
            OutlinedButton.icon(
              onPressed: state.isMutating ? null : () => _promptReject(context),
              icon: const Icon(Icons.close, size: 18),
              label: Text(l10n.adminPartnerReject),
            ),
          ],
          if (state.canSuspend)
            OutlinedButton.icon(
              onPressed: state.isMutating ? null : () => _promptSuspend(context),
              icon: const Icon(Icons.block, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error),
              ),
              label: Text(l10n.adminPartnerSuspend),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmApprove(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.adminPartnerApproveTitle),
        content: Text(l10n.adminPartnerApproveBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.adminPartnerCancel)),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.adminPartnerApprove)),
        ],
      ),
    );
    if (ok == true) await state.approve();
  }

  Future<void> _promptReject(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => _ReasonDialog(
        title: l10n.adminPartnerRejectTitle,
        body: l10n.adminPartnerRejectBody,
        label: l10n.adminPartnerRejectReasonLabel,
        confirm: l10n.adminPartnerReject,
        cancel: l10n.adminPartnerCancel,
        emptyError: l10n.adminPartnerRejectReasonRequired,
        // The backend's PartnerRejectRequest declares rejectReason, so it is
        // required here too rather than sending a blank one.
        required: true,
      ),
    );
    if (reason != null) await state.reject(reason);
  }

  Future<void> _promptSuspend(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _SuspendDialog(),
    );
    if (reason != null) {
      await state.suspend(reason: reason.isEmpty ? null : reason);
    }
  }
}

/// A confirmation that collects a reason. Returns the reason, or null if
/// cancelled — an empty string is a valid "no reason given" when [required] is
/// false.
class _ReasonDialog extends StatefulWidget {
  final String title;
  final String body;
  final String label;
  final String confirm;
  final String cancel;
  final String emptyError;
  final bool required;

  const _ReasonDialog({
    required this.title,
    required this.body,
    required this.label,
    required this.confirm,
    required this.cancel,
    required this.emptyError,
    required this.required,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (widget.required && value.isEmpty) {
      setState(() => _error = widget.emptyError);
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.body),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(widget.cancel)),
        FilledButton(onPressed: _submit, child: Text(widget.confirm)),
      ],
    );
  }
}

/// Suspension is the one control on this screen that cannot be undone.
///
/// The backend has no reactivate endpoint at all (D2B finding D2A-F1), and
/// suspending does not unpublish the partner's properties, which stay
/// searchable and bookable while the only account that could service those
/// bookings is locked out (D2A-F2). Both facts are stated, and the operator has
/// to tick an explicit acknowledgement before the confirm button enables. There
/// is deliberately no Restore control anywhere in this console, because there
/// is nothing for one to call.
class _SuspendDialog extends StatefulWidget {
  const _SuspendDialog();

  @override
  State<_SuspendDialog> createState() => _SuspendDialogState();
}

class _SuspendDialogState extends State<_SuspendDialog> {
  final TextEditingController _reason = TextEditingController();
  bool _acknowledged = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: scheme.error),
      title: Text(l10n.adminPartnerSuspendTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Consequence(text: l10n.adminPartnerSuspendWarningIrreversible),
            _Consequence(text: l10n.adminPartnerSuspendWarningBookable),
            _Consequence(text: l10n.adminPartnerSuspendWarningOperations),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.adminPartnerSuspendReasonLabel,
                helperText: l10n.adminPartnerSuspendReasonOptional,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            CheckboxListTile(
              value: _acknowledged,
              onChanged: (v) => setState(() => _acknowledged = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.adminPartnerSuspendAcknowledge,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.adminPartnerCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error),
          onPressed: _acknowledged
              ? () => Navigator.of(context).pop(_reason.text.trim())
              : null,
          child: Text(l10n.adminPartnerSuspendConfirm),
        ),
      ],
    );
  }
}

class _Consequence extends StatelessWidget {
  final String text;

  const _Consequence({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(
              child: Text(text,
                  style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

// ── Tabs ─────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final AdminPartnerDetailState state;

  const _OverviewTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final p = state.profile!;
    final d = state.detail;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminPartnerSectionIdentity,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(
                    label: l10n.adminPartnerColBusiness,
                    value: AdminFormats.text(context, p.businessName),
                    emphasise: true),
                AdminCardRow(
                    label: l10n.adminPartnerColType,
                    value: AdminFormats.text(context, p.businessType)),
                AdminCardRow(
                    label: l10n.adminPartnerRepresentative,
                    value: AdminFormats.text(context, p.representativeName)),
                AdminCardRow(
                    label: l10n.adminPartnerContactEmail,
                    value: AdminFormats.text(context, p.email)),
                AdminCardRow(
                    label: l10n.adminPartnerContactPhone,
                    value: AdminFormats.text(context, p.phone)),
                AdminCardRow(
                    label: l10n.adminPartnerAddress,
                    value: AdminFormats.text(context, p.address)),
                AdminCardRow(
                    label: l10n.adminPartnerTaxCode,
                    value: AdminFormats.text(context, p.taxCode)),
                AdminCardRow(
                    label: l10n.adminPartnerWebsite,
                    value: AdminFormats.text(context, p.website)),
                AdminCardRow(
                    label: l10n.adminPartnerAccountEmail,
                    value: AdminFormats.text(context, p.userEmail)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminPartnerSectionVerification,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                AdminCardRow(
                    label: l10n.adminFilterStatus, value: p.status.wire),
                AdminCardRow(
                    label: l10n.adminPartnerColSubmitted,
                    value: AdminFormats.dateTime(context, p.submittedAt)),
                AdminCardRow(
                    label: l10n.adminPartnerApprovedAt,
                    value: AdminFormats.dateTime(context, p.approvedAt)),
                AdminCardRow(
                    label: l10n.adminPartnerApprovedBy,
                    value: AdminFormats.text(context, p.approvedByName)),
                AdminCardRow(
                    label: l10n.adminPartnerRejectedAt,
                    value: AdminFormats.dateTime(context, p.rejectedAt)),
                if (p.statusReason != null)
                  AdminCardRow(
                    // The backend stores a rejection reason and a suspension
                    // reason in the same column, so the label follows the
                    // current status rather than always saying "rejection".
                    label: p.status == AdminPartnerStatus.suspended
                        ? l10n.adminPartnerSuspensionReason
                        : l10n.adminPartnerRejectionReason,
                    value: p.statusReason!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.adminPartnerSectionSummary,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                if (state.detailStatus == AdminLoadStatus.loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: LinearProgressIndicator(),
                  )
                else if (d == null)
                  Text(l10n.adminPartnerSummaryUnavailable,
                      style: Theme.of(context).textTheme.bodySmall)
                else ...[
                  AdminCardRow(
                      label: l10n.adminPartnerOwnedProperties,
                      value: AdminFormats.count(d.ownedHotelCount)),
                  AdminCardRow(
                      label: l10n.adminPartnerTeamSize,
                      value: AdminFormats.count(d.teamMemberCount)),
                  AdminCardRow(
                      label: l10n.adminPartnerPayoutStatus,
                      value:
                          AdminFormats.text(context, d.payoutAccountStatus)),
                ],
                const SizedBox(height: AppSpacing.xs),
                // No property list exists on the admin API, so the count is
                // deliberately the whole story here rather than a link that
                // would have nothing to open.
                Text(l10n.adminPartnerPropertiesNotListed,
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TeamTab extends StatelessWidget {
  final AdminPartnerDetailState state;

  const _TeamTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (state.teamStatus != AdminLoadStatus.ready) {
      return AdminStateView(
        status: state.teamStatus,
        emptyMessage: l10n.adminPartnerTeamEmpty,
        onRetry: state.refresh,
      );
    }
    if (state.team.isEmpty) {
      return AdminStateView(
        status: AdminLoadStatus.ready,
        emptyMessage: l10n.adminPartnerTeamEmpty,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(l10n.adminPartnerTeamReadOnlyNotice,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        for (final m in state.team)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OceanGlassCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AdminFormats.text(context, m.userName),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        AdminStatusChip(status: m.role),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AdminCardRow(
                        label: l10n.adminPartnerAccountEmail,
                        value: AdminFormats.text(context, m.userEmail)),
                    AdminCardRow(
                        label: l10n.adminPartnerTeamActive,
                        value: m.active
                            ? l10n.adminPartnerTeamActiveYes
                            : l10n.adminPartnerTeamActiveNo),
                    AdminCardRow(
                        label: l10n.adminPartnerTeamJoined,
                        value: AdminFormats.date(context, m.joinedAt)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final AdminPartnerDetailState state;

  const _ActivityTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ready = state.activityStatus == AdminLoadStatus.ready;
    final rows = state.activity.content;

    final body = ready && rows.isNotEmpty
        ? ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Named explicitly so it is never mistaken for the administrative
              // audit trail, which answers a different question and lives on
              // the console's own Activity log screen.
              Text(l10n.adminPartnerActivityScopeNotice,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              for (final r in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: OceanGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AdminFormats.text(context, r.action),
                              style: Theme.of(context).textTheme.titleSmall),
                          if (r.description != null) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(r.description!,
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          AdminCardRow(
                              label: l10n.adminPartnerActivityActor,
                              value: AdminFormats.text(context, r.actorName)),
                          AdminCardRow(
                              label: l10n.adminPartnerActivityEntity,
                              value: AdminFormats.text(context, r.entityType)),
                          AdminCardRow(
                              label: l10n.adminSortCreatedAt,
                              value:
                                  AdminFormats.dateTime(context, r.createdAt)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          )
        : AdminStateView(
            status: state.activityStatus,
            emptyMessage: l10n.adminPartnerActivityEmpty,
            onRetry: () => state.loadActivity(page: 0),
          );

    return AdminGridScaffold(
      isLoading: state.activityStatus == AdminLoadStatus.loading,
      page: ready ? state.activity : null,
      onPageChanged: state.goToActivityPage,
      body: body,
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final AdminPartnerDetailState state;

  const _SettingsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = state.settings;
    if (state.settingsStatus != AdminLoadStatus.ready || s == null) {
      return AdminStateView(
        status: state.settingsStatus,
        emptyMessage: l10n.adminPartnerSettingsEmpty,
        onRetry: state.refresh,
      );
    }
    String yesNo(bool v) =>
        v ? l10n.adminPartnerTeamActiveYes : l10n.adminPartnerTeamActiveNo;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // No admin settings mutation endpoint exists, so there is no save
        // control and the notice says so rather than leaving it implicit.
        Text(l10n.adminPartnerSettingsReadOnlyNotice,
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        OceanGlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminCardRow(
                    label: l10n.adminPartnerSettingsLanguage,
                    value: AdminFormats.text(context, s.defaultLanguage)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsTimezone,
                    value: AdminFormats.text(context, s.timezone)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsEmail,
                    value: yesNo(s.notificationEmailEnabled)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsSms,
                    value: yesNo(s.notificationSmsEnabled)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsInApp,
                    value: yesNo(s.notificationInAppEnabled)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsBooking,
                    value: yesNo(s.bookingNotificationEnabled)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsPayment,
                    value: yesNo(s.paymentNotificationEnabled)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsReview,
                    value: yesNo(s.reviewNotificationEnabled)),
                AdminCardRow(
                    label: l10n.adminPartnerSettingsPromotion,
                    value: yesNo(s.promotionNotificationEnabled)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
