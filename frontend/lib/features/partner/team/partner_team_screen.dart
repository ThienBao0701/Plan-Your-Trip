import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/app_state.dart';
import '../../../core/partner/partner_access_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../core/partner/partner_team_models.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_metric_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_team_dialogs.dart';
import 'partner_team_labels.dart';
import 'partner_team_messages.dart';
import 'partner_team_state.dart';

/// RBAC R5 — the `team` destination: members, their grants and status, and the
/// team's invitations, against the R4 API (RBAC V1.1 §13–§19, §25.3).
///
/// What the screen offers comes from the access document
/// ([PartnerTeamCapabilities]); what actually happens is the server's answer.
/// Every change re-reads both lists, and a refusal is shown in words mapped
/// from its code. Nothing here holds an invitation token.
class PartnerTeamScreen extends StatefulWidget {
  /// Width from which members render as a table rather than cards.
  static const double tableBreakpoint = 720;

  const PartnerTeamScreen({super.key});

  @override
  State<PartnerTeamScreen> createState() => _PartnerTeamScreenState();
}

class _PartnerTeamScreenState extends State<PartnerTeamScreen> {
  PartnerTeamState? _team;
  PartnerState? _partner;
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    if (!identical(partner, _partner)) {
      _partner = partner;
      _team?.dispose();
      _team = PartnerTeamState(api: partner.api);
      _requestedLoad = false;
    }
    final caps = PartnerTeamCapabilities(partner.access);
    if (partner.isReady && caps.canView && !_requestedLoad) {
      _requestedLoad = true;
      final team = _team!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) team.load();
      });
    }
  }

  @override
  void dispose() {
    _team?.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Shows the outcome of an action. A permission refusal also refreshes the
  /// access document (§23 F8): the caller's own access may have changed.
  void _report(PartnerTeamActionResult result, String success) {
    final l10n = AppLocalizations.of(context)!;
    if (result.ignored) return;
    if (result.success) {
      _snack(success);
      return;
    }
    final failure = result.failure!;
    if (failure.code == 'PERMISSION_DENIED' ||
        failure.code == 'ROLE_NOT_DELEGABLE') {
      _partner?.refreshAccess();
    }
    if (failure.code == PartnerTeamCodes.concurrentModification) {
      _snack(l10n.partnerTeamConcurrentReloaded);
      return;
    }
    _snack(partnerTeamFailureMessage(l10n, failure));
  }

  Future<void> _invite(PartnerTeamCapabilities caps) async {
    final team = _team!;
    final sent =
        await showPartnerInviteDialog(context, team: team, capabilities: caps);
    if (!mounted || !sent) return;
    _snack(AppLocalizations.of(context)!.partnerInviteRecorded);
  }

  Future<void> _edit(
      PartnerTeamCapabilities caps, PartnerTeamMember member) async {
    final result = await showPartnerEditGrantsDialog(context,
        team: _team!, capabilities: caps, member: member);
    if (!mounted || result == null) return;
    _report(result, AppLocalizations.of(context)!.partnerTeamSaved);
  }

  Future<void> _suspend(PartnerTeamMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showPartnerConfirmDialog(
      context,
      title: l10n.partnerTeamSuspendTitle,
      body: member.involvesOwner
          ? '${l10n.partnerTeamSuspendBody(_name(member))} ${l10n.partnerTeamOwnerStepUpHint}'
          : l10n.partnerTeamSuspendBody(_name(member)),
      confirmLabel: l10n.partnerTeamSuspend,
      withReason: true,
    );
    if (!mounted || reason == null) return;
    final result = await runWithStepUp(
        context, () => _team!.suspend(member, reason: reason));
    if (mounted) _report(result, l10n.partnerTeamSuspended);
  }

  Future<void> _reactivate(PartnerTeamMember member) async {
    final l10n = AppLocalizations.of(context)!;
    if (member.involvesOwner) {
      final confirmed = await showPartnerConfirmDialog(
        context,
        title: l10n.partnerTeamReactivateTitle,
        body:
            '${l10n.partnerTeamReactivateBody(_name(member))} ${l10n.partnerTeamOwnerStepUpHint}',
        confirmLabel: l10n.partnerTeamReactivate,
      );
      if (!mounted || confirmed == null) return;
    }
    final result =
        await runWithStepUp(context, () => _team!.reactivate(member));
    if (mounted) _report(result, l10n.partnerTeamReactivated);
  }

  Future<void> _remove(PartnerTeamMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showPartnerConfirmDialog(
      context,
      title: l10n.partnerTeamRemoveTitle,
      body: l10n.partnerTeamRemoveBody(_name(member)),
      confirmLabel: l10n.partnerTeamRemoveAction,
      withReason: true,
      destructive: true,
    );
    if (!mounted || reason == null) return;
    final result = await runWithStepUp(
        context, () => _team!.remove(member, reason: reason));
    if (mounted) _report(result, l10n.partnerTeamRemoved);
  }

  Future<void> _resend(PartnerTeamInvitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    final result =
        await runWithStepUp(context, () => _team!.resend(invitation));
    if (mounted) _report(result, l10n.partnerInviteResent);
  }

  Future<void> _revoke(PartnerTeamInvitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await showPartnerConfirmDialog(
      context,
      title: l10n.partnerInviteRevokeTitle,
      body: l10n.partnerInviteRevokeBody(invitation.email),
      confirmLabel: l10n.partnerInviteRevoke,
      withReason: true,
      destructive: true,
    );
    if (!mounted || reason == null) return;
    final result = await _team!.revoke(invitation, reason: reason);
    if (mounted) _report(result, l10n.partnerInviteRevoked);
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showPartnerConfirmDialog(
      context,
      title: l10n.partnerTeamLeaveTitle,
      body: l10n.partnerTeamLeaveBody,
      confirmLabel: l10n.partnerTeamLeave,
      destructive: true,
    );
    if (!mounted || confirmed == null) return;
    final result = await _team!.leave();
    if (!mounted) return;
    if (result.success) {
      // The membership is gone: reload the workspace, which now resolves to
      // whatever the account still has (usually onboarding).
      final app = AppScope.of(context);
      final partner = _partner!;
      _snack(l10n.partnerTeamLeft);
      partner.reset();
      await partner.loadWorkspace(app);
      return;
    }
    _report(result, l10n.partnerTeamLeft);
  }

  String _name(PartnerTeamMember member) =>
      member.userName.isEmpty ? member.userEmail : member.userName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final team = _team;
    if (!partner.isReady || team == null) {
      return PartnerWorkspaceStatusView(
          status: partner.status, detail: partner.errorMessage);
    }
    final caps = PartnerTeamCapabilities(partner.access);
    if (!caps.canView) {
      return _NoTeamAccess(
          canLeave: caps.canLeave,
          onLeave: _leave,
          accessLoaded: partner.access != null);
    }
    return AnimatedBuilder(
      animation: team,
      builder: (context, _) {
        final header = _Header(
          team: team,
          caps: caps,
          onInvite: () => _invite(caps),
          onRefresh: team.load,
          onLeave: _leave,
        );
        final body = switch (team.status) {
          PartnerTeamStatus.idle ||
          PartnerTeamStatus.loading =>
            const _TeamSkeleton(),
          PartnerTeamStatus.unauthorized => const PartnerWorkspaceStatusView(
              key: Key('partner-team-unauthorized'),
              status: PartnerWorkspaceStatus.unauthorized,
            ),
          PartnerTeamStatus.forbidden => PartnerWorkspaceStatusView(
              key: const Key('partner-team-forbidden'),
              status: PartnerWorkspaceStatus.forbidden,
              onPrimaryAction: team.load,
            ),
          PartnerTeamStatus.error => PartnerMetricNotice(
              key: const Key('partner-team-error'),
              message: l10n.partnerTeamLoadFailed,
              warning: true,
              onRetry: team.load,
            ),
          PartnerTeamStatus.ready => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MembersSection(
                  team: team,
                  caps: caps,
                  access: partner.access,
                  onEdit: (m) => _edit(caps, m),
                  onSuspend: _suspend,
                  onReactivate: _reactivate,
                  onRemove: _remove,
                ),
                const SizedBox(height: AppSpacing.md),
                _InvitationsSection(
                  team: team,
                  caps: caps,
                  access: partner.access,
                  onResend: _resend,
                  onRevoke: _revoke,
                ),
              ],
            ),
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [header, const SizedBox(height: AppSpacing.md), body],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final PartnerTeamState team;
  final PartnerTeamCapabilities caps;
  final VoidCallback onInvite;
  final VoidCallback onRefresh;
  final VoidCallback onLeave;

  const _Header({
    required this.team,
    required this.caps,
    required this.onInvite,
    required this.onRefresh,
    required this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final ready = team.status == PartnerTeamStatus.ready;
    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerTeamScreenTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(l10n.partnerTeamScreenSubtitle,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary)),
          if (ready) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  key: const Key('partner-team-count-members'),
                  label: l10n.partnerTeamCountMembers(team.members.length),
                  icon: Icons.groups_outlined,
                  color: AppColors.ocean600,
                ),
                if (team.suspendedMembers.isNotEmpty)
                  OceanStatusPill(
                    label: l10n.partnerTeamCountSuspended(
                        team.suspendedMembers.length),
                    icon: Icons.pause_circle_outline_rounded,
                    color: AppColors.textTertiary,
                  ),
                if (!team.invitationsUnavailable)
                  OceanStatusPill(
                    key: const Key('partner-team-count-invitations'),
                    label: l10n.partnerTeamCountPending(
                        team.pendingInvitations.length),
                    icon: Icons.mark_email_unread_outlined,
                    color: AppColors.turquoise600,
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (caps.canInvite)
                OceanPrimaryButton(
                  key: const Key('partner-team-invite'),
                  label: l10n.partnerInviteAction,
                  icon: Icons.person_add_alt_1_outlined,
                  fullWidth: false,
                  onPressed: ready && !team.isBusy(PartnerTeamState.inviteKey)
                      ? onInvite
                      : null,
                ),
              OceanSecondaryButton(
                key: const Key('partner-team-refresh'),
                label: l10n.partnerActionRefresh,
                icon: Icons.refresh_rounded,
                fullWidth: false,
                onPressed:
                    team.status == PartnerTeamStatus.loading ? null : onRefresh,
              ),
              if (caps.canLeave)
                OceanSecondaryButton(
                  key: const Key('partner-team-leave'),
                  label: l10n.partnerTeamLeave,
                  icon: Icons.logout_rounded,
                  fullWidth: false,
                  onPressed:
                      team.isBusy(PartnerTeamState.leaveKey) ? null : onLeave,
                ),
            ],
          ),
          if (!caps.canInvite && caps.canView) ...[
            const SizedBox(height: AppSpacing.sm),
            PartnerMetricNotice(
                key: const Key('partner-team-readonly'),
                message: l10n.partnerTeamReadOnly),
          ],
        ],
      ),
    );
  }
}

/// What a member row can do, decided once per row.
class _MemberActions {
  final bool edit;
  final bool suspend;
  final bool reactivate;
  final bool remove;

  const _MemberActions(
      {required this.edit,
      required this.suspend,
      required this.reactivate,
      required this.remove});

  factory _MemberActions.of(
      PartnerTeamCapabilities caps, PartnerTeamMember member) {
    final active = member.status == PartnerMembershipStatus.active;
    final suspended = member.status == PartnerMembershipStatus.suspended;
    final assign = caps.canManage(member, PartnerPermissionKeys.teamRoleAssign);
    final status = caps.canManage(member, PartnerPermissionKeys.teamSuspend);
    return _MemberActions(
      edit: assign && member.version != null,
      suspend: status && active,
      reactivate: status && suspended,
      remove: caps.canManage(member, PartnerPermissionKeys.teamRemove),
    );
  }

  bool get any => edit || suspend || reactivate || remove;
}

class _MembersSection extends StatelessWidget {
  final PartnerTeamState team;
  final PartnerTeamCapabilities caps;
  final PartnerAccess? access;
  final ValueChanged<PartnerTeamMember> onEdit;
  final ValueChanged<PartnerTeamMember> onSuspend;
  final ValueChanged<PartnerTeamMember> onReactivate;
  final ValueChanged<PartnerTeamMember> onRemove;

  const _MembersSection({
    required this.team,
    required this.caps,
    required this.access,
    required this.onEdit,
    required this.onSuspend,
    required this.onReactivate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = [...team.activeMembers, ...team.suspendedMembers];
    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
              title: l10n.partnerTeamMembersHeading,
              subtitle: l10n.partnerTeamMembersSubtitle),
          const SizedBox(height: AppSpacing.md),
          if (members.isEmpty)
            Text(
              l10n.partnerTeamMembersEmpty,
              key: const Key('partner-team-members-empty'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= PartnerTeamScreen.tableBreakpoint;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (wide) const _MemberTableHeader(),
                    for (final member in members)
                      _MemberRow(
                        key: Key('partner-team-member-${member.id}'),
                        member: member,
                        access: access,
                        wide: wide,
                        busy:
                            team.isBusy(PartnerTeamState.memberKey(member.id)),
                        actions: _MemberActions.of(caps, member),
                        onEdit: () => onEdit(member),
                        onSuspend: () => onSuspend(member),
                        onReactivate: () => onReactivate(member),
                        onRemove: () => onRemove(member),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MemberTableHeader extends StatelessWidget {
  const _MemberTableHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w800,
          letterSpacing: .6,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
              flex: 4,
              child: Text(l10n.partnerTeamColumnMember.toUpperCase(),
                  style: style)),
          Expanded(
              flex: 5,
              child: Text(l10n.partnerTeamColumnAccess.toUpperCase(),
                  style: style)),
          Expanded(
              flex: 2,
              child: Text(l10n.partnerTeamColumnStatus.toUpperCase(),
                  style: style)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  final PartnerTeamMember member;
  final PartnerAccess? access;
  final bool wide;
  final bool busy;
  final _MemberActions actions;
  final VoidCallback onEdit;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onRemove;

  const _MemberRow({
    super.key,
    required this.member,
    required this.access,
    required this.wide,
    required this.busy,
    required this.actions,
    required this.onEdit,
    required this.onSuspend,
    required this.onReactivate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final suspended = member.status == PartnerMembershipStatus.suspended;

    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          member.userName.isEmpty ? member.userEmail : member.userName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        if (member.userName.isNotEmpty)
          Text(
            member.userEmail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xxs,
          runSpacing: AppSpacing.xxs,
          children: [
            if (member.isSelf)
              OceanStatusPill(
                key: Key('partner-team-self-${member.id}'),
                label: l10n.partnerTeamYou,
                icon: Icons.person_outline_rounded,
                color: AppColors.turquoise600,
              ),
            if (member.primaryOwner)
              OceanStatusPill(
                key: Key('partner-team-primary-${member.id}'),
                label: l10n.partnerTeamPrimaryOwner,
                icon: Icons.lock_outline_rounded,
                color: AppColors.warning,
                semanticLabel: l10n.partnerTeamPrimaryOwnerProtected,
              ),
            if (member.pendingOwnerConfirmation)
              OceanStatusPill(
                label: l10n.partnerTeamPendingOwner,
                icon: Icons.hourglass_top_rounded,
                color: AppColors.warning,
              ),
          ],
        ),
      ],
    );

    final grants = member.grants.isEmpty
        ? [
            PartnerTeamGrant(
                role: member.role,
                scope: PartnerScopeRef(
                    PartnerScopeType.company, member.partnerProfileId))
          ]
        : member.grants;
    final accessChips = Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        for (final grant in grants)
          OceanStatusPill(
            label: l10n.partnerTeamGrantLabel(
              partnerTeamRoleLabel(l10n, grant.role),
              partnerScopeLabel(l10n, grant.scope, access),
            ),
            icon: grant.scope.type == PartnerScopeType.company
                ? Icons.business_outlined
                : Icons.apartment_outlined,
            color: AppColors.ocean600,
          ),
      ],
    );

    final status = OceanStatusPill(
      label: partnerMembershipStatusLabel(l10n, member.status),
      icon: suspended
          ? Icons.pause_circle_outline_rounded
          : Icons.check_circle_outline_rounded,
      color: suspended ? AppColors.textTertiary : AppColors.success,
    );

    final menu = busy
        ? const Padding(
            padding: EdgeInsets.all(AppSpacing.sm),
            child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
          )
        : actions.any
            ? PopupMenuButton<String>(
                key: Key('partner-team-member-menu-${member.id}'),
                tooltip: l10n.partnerTeamMemberActions(member.userName.isEmpty
                    ? member.userEmail
                    : member.userName),
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) => switch (value) {
                  'edit' => onEdit(),
                  'suspend' => onSuspend(),
                  'reactivate' => onReactivate(),
                  'remove' => onRemove(),
                  _ => null,
                },
                itemBuilder: (_) => [
                  if (actions.edit)
                    PopupMenuItem(
                      key: Key('partner-team-edit-${member.id}'),
                      value: 'edit',
                      child: Text(l10n.partnerTeamEditAccess),
                    ),
                  if (actions.suspend)
                    PopupMenuItem(
                      key: Key('partner-team-suspend-${member.id}'),
                      value: 'suspend',
                      child: Text(l10n.partnerTeamSuspend),
                    ),
                  if (actions.reactivate)
                    PopupMenuItem(
                      key: Key('partner-team-reactivate-${member.id}'),
                      value: 'reactivate',
                      child: Text(l10n.partnerTeamReactivate),
                    ),
                  if (actions.remove)
                    PopupMenuItem(
                      key: Key('partner-team-remove-${member.id}'),
                      value: 'remove',
                      child: Text(l10n.partnerTeamRemoveAction,
                          style: const TextStyle(color: AppColors.danger)),
                    ),
                ],
              )
            : const SizedBox(width: 48);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: suspended
            ? AppColors.surfaceMuted.withValues(alpha: .6)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: identity),
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 5, child: accessChips),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    flex: 2,
                    child:
                        Align(alignment: Alignment.centerLeft, child: status)),
                menu,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(child: identity), menu],
                ),
                const SizedBox(height: AppSpacing.xs),
                accessChips,
                const SizedBox(height: AppSpacing.xs),
                Align(alignment: Alignment.centerLeft, child: status),
              ],
            ),
    );
  }
}

class _InvitationsSection extends StatelessWidget {
  final PartnerTeamState team;
  final PartnerTeamCapabilities caps;
  final PartnerAccess? access;
  final ValueChanged<PartnerTeamInvitation> onResend;
  final ValueChanged<PartnerTeamInvitation> onRevoke;

  const _InvitationsSection({
    required this.team,
    required this.caps,
    required this.access,
    required this.onResend,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Pending first, then the closed ones the server still lists, newest first.
    final invitations = [
      ...team.invitations.where((i) => i.isPending),
      ...team.invitations.where((i) => !i.isPending),
    ];
    return OceanGlassCard(
      key: const Key('partner-team-invitations'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(
              title: l10n.partnerInvitesHeading,
              subtitle: l10n.partnerInvitesSubtitle),
          const SizedBox(height: AppSpacing.md),
          if (team.invitationsUnavailable)
            PartnerMetricNotice(
              key: const Key('partner-team-invitations-unavailable'),
              message: l10n.partnerInvitesUnavailable,
              warning: true,
              onRetry: team.load,
            )
          else if (invitations.isEmpty)
            Text(
              l10n.partnerInvitesEmpty,
              key: const Key('partner-team-invitations-empty'),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            for (final invitation in invitations)
              _InvitationRow(
                key: Key('partner-team-invitation-${invitation.id}'),
                invitation: invitation,
                access: access,
                canManage: caps.canInvite,
                busy:
                    team.isBusy(PartnerTeamState.invitationKey(invitation.id)),
                onResend: () => onResend(invitation),
                onRevoke: () => onRevoke(invitation),
              ),
        ],
      ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  final PartnerTeamInvitation invitation;
  final PartnerAccess? access;
  final bool canManage;
  final bool busy;
  final VoidCallback onResend;
  final VoidCallback onRevoke;

  const _InvitationRow({
    super.key,
    required this.invitation,
    required this.access,
    required this.canManage,
    required this.busy,
    required this.onResend,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(locale).add_Hm();
    final pending = invitation.isPending;
    final now = DateTime.now();
    final availableAt = invitation.resendAvailableAt;
    final coolingDown = availableAt != null && availableAt.isAfter(now);
    final canResend = canManage &&
        pending &&
        !invitation.resendLimitReached &&
        !coolingDown &&
        !busy;
    final delivery = invitation.delivery;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  invitation.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              OceanStatusPill(
                key: Key('partner-team-invitation-status-${invitation.id}'),
                label: partnerInvitationStatusLabel(l10n, invitation.status),
                icon: pending ? Icons.schedule_rounded : Icons.history_rounded,
                color:
                    pending ? AppColors.turquoise600 : AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xxs,
            runSpacing: AppSpacing.xxs,
            children: [
              for (final grant in invitation.grants)
                OceanStatusPill(
                  label: l10n.partnerTeamGrantLabel(
                    partnerTeamRoleLabel(l10n, grant.role),
                    partnerScopeLabel(l10n, grant.scope, access),
                  ),
                  icon: Icons.badge_outlined,
                  color: AppColors.ocean600,
                ),
              if (pending)
                OceanStatusPill(
                  key: Key('partner-team-invitation-delivery-${invitation.id}'),
                  label: partnerInvitationDeliveryLabel(l10n, delivery),
                  icon: delivery == PartnerInvitationDelivery.failed
                      ? Icons.report_gmailerrorred_outlined
                      : Icons.outgoing_mail,
                  color: delivery == PartnerInvitationDelivery.failed
                      ? AppColors.danger
                      : delivery == PartnerInvitationDelivery.sent
                          ? AppColors.success
                          : AppColors.textTertiary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (invitation.expiresAt != null && pending)
                l10n.partnerInviteExpires(
                    dateFormat.format(invitation.expiresAt!.toLocal())),
              l10n.partnerInviteResends(
                  invitation.resendCount, PartnerTeamInvitation.maxResends),
              if (invitation.invitedByName != null)
                l10n.partnerInviteInvitedBy(invitation.invitedByName!),
            ].join(' · '),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (pending && canManage) ...[
            const SizedBox(height: AppSpacing.xs),
            if (invitation.resendLimitReached)
              Text(l10n.partnerInviteResendLimit,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.warning))
            else if (coolingDown)
              Text(
                l10n.partnerInviteResendAfter(
                    DateFormat.Hm(locale).format(availableAt.toLocal())),
                key: Key('partner-team-invitation-cooldown-${invitation.id}'),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            const SizedBox(height: AppSpacing.xxs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                TextButton.icon(
                  key: Key('partner-team-resend-${invitation.id}'),
                  onPressed: canResend ? onResend : null,
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send_outlined),
                  label: Text(l10n.partnerInviteResend),
                ),
                TextButton.icon(
                  key: Key('partner-team-revoke-${invitation.id}'),
                  onPressed: busy ? null : onRevoke,
                  icon: const Icon(Icons.cancel_outlined,
                      color: AppColors.danger),
                  label: Text(l10n.partnerInviteRevoke,
                      style: const TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 2),
        Text(subtitle,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary)),
      ],
    );
  }
}

class _TeamSkeleton extends StatelessWidget {
  const _TeamSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      key: const Key('partner-team-loading'),
      label: l10n.partnerTeamLoading,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppRadii.sm)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the caller holds no team view (§23 F4): nothing about the team is
/// requested or revealed. A member may still leave the workspace.
class _NoTeamAccess extends StatelessWidget {
  final bool canLeave;
  final bool accessLoaded;
  final VoidCallback onLeave;

  const _NoTeamAccess(
      {required this.canLeave,
      required this.onLeave,
      required this.accessLoaded});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      key: const Key('partner-team-no-access'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PartnerMetricNotice(
              message: accessLoaded
                  ? l10n.partnerTeamNoAccess
                  : l10n.partnerTeamAccessUnavailable),
          if (canLeave) ...[
            const SizedBox(height: AppSpacing.md),
            OceanSecondaryButton(
              key: const Key('partner-team-leave'),
              label: l10n.partnerTeamLeave,
              icon: Icons.logout_rounded,
              onPressed: onLeave,
            ),
          ],
        ],
      ),
    );
  }
}
