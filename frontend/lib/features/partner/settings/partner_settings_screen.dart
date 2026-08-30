import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/partner/partner_account_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../policies/partner_policies_screen.dart';
import '../properties/widgets/partner_property_widgets.dart';
import '../widgets/partner_metric_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_account_state.dart';

/// The `settings` destination — C6's module, extended rather than replaced.
///
/// ## The C6 / C12 boundary
///
/// | Tab | Owner |
/// |---|---|
/// | Policies & workspace | **C6**, embedded verbatim |
/// | Team | C12 |
/// | Payout account | C12 |
/// | Profile | C12, **read-only** |
///
/// C6's screen renders unchanged in the first tab; C12 neither wraps nor
/// reimplements its property-policy or notification editors.
///
/// ## Role rules, taken from `PartnerSettingsService`
///
///   * team add / update / remove → `requireOwner` → **OWNER only**;
///   * payout write → `PAYOUT_WRITE_ROLES` → **OWNER or FINANCE**;
///   * settings write → OWNER or MANAGER, which remains C6's.
///
/// ## Why the profile is read-only
///
/// `PartnerProfileService.createOrUpdateMyProfile` throws **422** unless the
/// profile is `DRAFT` or `REJECTED`, and `submitMyProfile` does the same. The
/// extranet is only reachable when the profile is `APPROVED`, so an editor here
/// could never succeed — it would be a control that always fails. The identity
/// is therefore displayed, with a note saying where changes have to go.
class PartnerSettingsScreen extends StatefulWidget {
  const PartnerSettingsScreen({super.key});

  @override
  State<PartnerSettingsScreen> createState() => _PartnerSettingsScreenState();
}

class _PartnerSettingsScreenState extends State<PartnerSettingsScreen>
    with SingleTickerProviderStateMixin {
  PartnerAccountState? _account;
  PartnerState? _partner;
  bool _requestedLoad = false;

  // Built eagerly: on a gated workspace `build` returns before the controller is
  // read, and a lazy `late final` would then be constructed inside `dispose()`.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    if (!identical(partner, _partner)) {
      _partner = partner;
      _account?.dispose();
      _account = PartnerAccountState(api: partner.api);
      _requestedLoad = false;
    }
    if (partner.isReady && !_requestedLoad) {
      _requestedLoad = true;
      final account = _account!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) account.load(partner);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _account?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final account = _account;

    if (!partner.isReady || account == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.partnerSettingsTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.ocean700,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.ocean700,
                tabs: [
                  Tab(text: l10n.partnerSettingsTabWorkspace),
                  Tab(text: l10n.partnerSettingsTabTeam),
                  Tab(text: l10n.partnerSettingsTabPayout),
                  Tab(text: l10n.partnerSettingsTabProfile),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: Listenable.merge([_tabs, account]),
          builder: (context, _) => switch (_tabs.index) {
            // C6, embedded verbatim — its own state, its own editors.
            0 => const PartnerPoliciesScreen(),
            1 => _TeamTab(partner: partner, account: account),
            2 => _PayoutTab(partner: partner, account: account),
            _ => _ProfileTab(partner: partner),
          },
        ),
      ],
    );
  }
}

class _TeamTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerAccountState account;

  const _TeamTab({required this.partner, required this.account});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = account.canManageTeam(partner.teamRole);

    final gate = _gate(context, account);
    if (gate != null) return gate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.partnerTeamHeading,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.partnerTeamSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!canManage) ...[
                PartnerMetricNotice(message: l10n.partnerTeamOwnerOnly),
                const SizedBox(height: AppSpacing.md),
              ],
              if (account.team.isEmpty)
                Text(
                  l10n.partnerTeamEmpty,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                )
              else
                for (final member in account.team)
                  _MemberRow(
                    partner: partner,
                    account: account,
                    member: member,
                    canManage: canManage,
                  ),
            ],
          ),
        ),
        if (canManage) ...[
          const SizedBox(height: AppSpacing.md),
          _InviteCard(partner: partner, account: account),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final PartnerState partner;
  final PartnerAccountState account;
  final PartnerTeamMember member;
  final bool canManage;

  const _MemberRow({
    required this.partner,
    required this.account,
    required this.member,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pending = account.pendingMemberId == member.id;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.userName.isEmpty
                          ? l10n.partnerPropertyNotSet
                          : member.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      member.userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              OceanStatusPill(
                label: partnerTeamRoleLabel(l10n, member.role),
                color: AppColors.ocean600,
                icon: Icons.badge_outlined,
              ),
              const SizedBox(width: AppSpacing.xxs),
              OceanStatusPill(
                label: member.active
                    ? l10n.partnerTeamActive
                    : l10n.partnerTeamInactive,
                color:
                    member.active ? AppColors.success : AppColors.textTertiary,
                icon: member.active
                    ? Icons.check_circle_outline_rounded
                    : Icons.pause_circle_outline_rounded,
              ),
            ],
          ),
          if (canManage) ...[
            const SizedBox(height: AppSpacing.xs),
            if (pending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<PartnerTeamRole>(
                      initialValue: partnerAssignableRoles.contains(member.role)
                          ? member.role
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.partnerTeamRoleField,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                      ),
                      items: [
                        for (final role in partnerAssignableRoles)
                          DropdownMenuItem(
                            value: role,
                            child: Text(partnerTeamRoleLabel(l10n, role)),
                          ),
                      ],
                      onChanged: (role) => role == null
                          ? null
                          : _run(
                              context,
                              () => account.updateMember(
                                  partner: partner,
                                  memberId: member.id,
                                  role: role),
                            ),
                    ),
                  ),
                  OceanSecondaryButton(
                    label: member.active
                        ? l10n.partnerTeamDeactivate
                        : l10n.partnerTeamActivate,
                    icon: member.active
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    fullWidth: false,
                    onPressed: () => _run(
                      context,
                      () => account.updateMember(
                          partner: partner,
                          memberId: member.id,
                          active: !member.active),
                    ),
                  ),
                  OceanSecondaryButton(
                    label: l10n.partnerTeamRemove,
                    icon: Icons.person_remove_outlined,
                    fullWidth: false,
                    onPressed: () => _confirmRemove(context),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    // Removal is irreversible: there is no endpoint to restore a member.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.partnerTeamRemove),
        content: Text(l10n.partnerTeamRemoveConfirm(
            member.userEmail.isEmpty ? member.userName : member.userEmail)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.partnerBookingActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerBookingActionConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      () => account.removeMember(partner: partner, memberId: member.id),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<PartnerAccountActionResult> Function() action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await action();
    if (!context.mounted) return;
    messenger?.showSnackBar(
        SnackBar(content: Text(partnerAccountResultMessage(l10n, result))));
  }
}

class _InviteCard extends StatefulWidget {
  final PartnerState partner;
  final PartnerAccountState account;

  const _InviteCard({required this.partner, required this.account});

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  final TextEditingController _email = TextEditingController();
  PartnerTeamRole _role = PartnerTeamRole.viewer;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerTeamInviteHeading,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            // The backend matches an existing user by email; it does not send
            // an invitation email of its own.
            l10n.partnerTeamInviteNote,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: l10n.partnerTeamInviteEmail,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<PartnerTeamRole>(
                  initialValue: _role,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.partnerTeamRoleField,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  items: [
                    for (final role in partnerAssignableRoles)
                      DropdownMenuItem(
                        value: role,
                        child: Text(partnerTeamRoleLabel(l10n, role)),
                      ),
                  ],
                  onChanged: (role) =>
                      setState(() => _role = role ?? PartnerTeamRole.viewer),
                ),
              ),
              OceanPrimaryButton(
                label: l10n.partnerTeamInviteAction,
                fullWidth: false,
                onPressed: widget.account.pendingMemberId != null
                    ? null
                    : () => _invite(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _invite(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await widget.account.addMember(
      partner: widget.partner,
      email: _email.text,
      role: _role,
    );
    if (!context.mounted) return;
    if (result == PartnerAccountActionResult.success) _email.clear();
    messenger?.showSnackBar(
        SnackBar(content: Text(partnerAccountResultMessage(l10n, result))));
  }
}

class _PayoutTab extends StatefulWidget {
  final PartnerState partner;
  final PartnerAccountState account;

  const _PayoutTab({required this.partner, required this.account});

  @override
  State<_PayoutTab> createState() => _PayoutTabState();
}

class _PayoutTabState extends State<_PayoutTab> {
  final TextEditingController _holder = TextEditingController();
  final TextEditingController _bank = TextEditingController();
  final TextEditingController _number = TextEditingController();
  PartnerPayoutMethod _method = PartnerPayoutMethod.bankTransfer;
  bool _editing = false;

  @override
  void dispose() {
    _holder.dispose();
    _bank.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final account = widget.account;
    final canEdit = account.canEditPayout(widget.partner.teamRole);

    final gate = _gate(context, account);
    if (gate != null) return gate;

    final payout = account.payout;
    final locale = Localizations.localeOf(context).toString();
    final dateTime = DateFormat.yMMMd(locale).add_Hm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.partnerPayoutHeading,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.partnerPayoutSubtitle,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              if (account.payoutErrorKind != null)
                PartnerMetricNotice(
                  warning: true,
                  message: l10n.partnerPayoutLoadFailed,
                )
              else if (!account.hasPayoutAccount)
                Text(
                  l10n.partnerPayoutNone,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                )
              else if (payout != null) ...[
                PartnerPropertyField(
                    label: l10n.partnerPayoutHolder,
                    value: payout.accountHolderName),
                PartnerPropertyField(
                    label: l10n.partnerPayoutBank, value: payout.bankName),
                PartnerPropertyField(
                  label: l10n.partnerPayoutAccountNumber,
                  // Only the last four digits exist server-side; the rest was
                  // discarded when it was first submitted.
                  value: payout.bankAccountLast4 == null
                      ? null
                      : l10n.partnerPayoutMasked(payout.bankAccountLast4!),
                ),
                PartnerPropertyField(
                    label: l10n.partnerPayoutMethod,
                    value: payout.payoutMethod),
                PartnerPropertyField(
                    label: l10n.partnerPayoutStatus, value: payout.status),
                PartnerPropertyField(
                  label: l10n.partnerPayoutUpdated,
                  value: payout.updatedAt == null
                      ? null
                      : dateTime.format(payout.updatedAt!),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              PartnerMetricNotice(message: l10n.partnerPayoutNoExecutionNotice),
              if (!canEdit) ...[
                const SizedBox(height: AppSpacing.sm),
                PartnerMetricNotice(message: l10n.partnerPayoutRoleNotice),
              ] else ...[
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OceanSecondaryButton(
                    label: _editing
                        ? l10n.partnerPayoutCancelEdit
                        : (account.hasPayoutAccount
                            ? l10n.partnerPayoutReplace
                            : l10n.partnerPayoutAdd),
                    icon: _editing ? Icons.close_rounded : Icons.edit_outlined,
                    fullWidth: false,
                    onPressed: () => setState(() => _editing = !_editing),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (canEdit && _editing) ...[
          const SizedBox(height: AppSpacing.md),
          _PayoutForm(
            holder: _holder,
            bank: _bank,
            number: _number,
            method: _method,
            saving: account.isSavingPayout,
            onMethodChanged: (m) => setState(() => _method = m),
            onSave: () => _save(context),
          ),
        ],
      ],
    );
  }

  Future<void> _save(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);

    // Replacing the payout account overwrites the stored one; the previous
    // number cannot be recovered because it was never kept.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.partnerPayoutReplace),
        content: Text(l10n.partnerPayoutReplaceConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.partnerBookingActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerBookingActionConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await widget.account.savePayoutAccount(
      partner: widget.partner,
      accountHolderName: _holder.text,
      bankName: _bank.text,
      bankAccountNumber: _number.text,
      payoutMethod: _method,
    );
    if (!context.mounted) return;
    if (result == PartnerAccountActionResult.success) {
      // The number is never retained on this side either.
      _number.clear();
      setState(() => _editing = false);
    }
    messenger?.showSnackBar(
        SnackBar(content: Text(partnerAccountResultMessage(l10n, result))));
  }
}

class _PayoutForm extends StatelessWidget {
  final TextEditingController holder;
  final TextEditingController bank;
  final TextEditingController number;
  final PartnerPayoutMethod method;
  final bool saving;
  final ValueChanged<PartnerPayoutMethod> onMethodChanged;
  final VoidCallback onSave;

  const _PayoutForm({
    required this.holder,
    required this.bank,
    required this.number,
    required this.method,
    required this.saving,
    required this.onMethodChanged,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerPayoutFormHeading,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Field(controller: holder, label: l10n.partnerPayoutHolder),
          _Field(controller: bank, label: l10n.partnerPayoutBank),
          _Field(
            controller: number,
            label: l10n.partnerPayoutAccountNumber,
            keyboardType: TextInputType.number,
            helper: l10n.partnerPayoutNumberHelp,
          ),
          DropdownButtonFormField<PartnerPayoutMethod>(
            initialValue: method,
            decoration: InputDecoration(
              labelText: l10n.partnerPayoutMethod,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
            ),
            items: [
              for (final m in PartnerPayoutMethod.selectable)
                DropdownMenuItem(
                  value: m,
                  child: Text(partnerPayoutMethodLabel(l10n, m)),
                ),
            ],
            onChanged: (m) => m == null ? null : onMethodChanged(m),
          ),
          const SizedBox(height: AppSpacing.md),
          if (saving)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OceanPrimaryButton(
                label: l10n.partnerPayoutSave,
                fullWidth: false,
                onPressed: onSave,
              ),
            ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? helper;

  const _Field({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.helper,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 2,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
          ),
        ),
      );
}

/// The partner identity, read-only.
class _ProfileTab extends StatelessWidget {
  final PartnerState partner;

  const _ProfileTab({required this.partner});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final overview = partner.overview;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.partnerProfileHeading,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          PartnerPropertyField(
              label: l10n.partnerProfileBusinessName,
              value: overview?.businessName),
          PartnerPropertyField(
              label: l10n.partnerProfileRepresentative,
              value: overview?.representativeName),
          PartnerPropertyField(
            label: l10n.partnerProfileVerification,
            value: overview == null
                ? null
                : partnerVerificationLabel(l10n, overview.verificationStatus),
          ),
          PartnerPropertyField(
            label: l10n.partnerProfileYourRole,
            value: partnerTeamRoleLabel(l10n, partner.teamRole),
          ),
          const SizedBox(height: AppSpacing.sm),
          // The profile API refuses any edit unless the profile is DRAFT or
          // REJECTED, and the extranet is only reachable once APPROVED — so an
          // editor here could never succeed.
          PartnerMetricNotice(message: l10n.partnerProfileReadOnlyNotice),
        ],
      ),
    );
  }
}

/// Shared gate for the two account tabs.
Widget? _gate(BuildContext context, PartnerAccountState account) {
  switch (account.status) {
    case PartnerAccountStatus.unauthorized:
      return const PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.unauthorized);
    case PartnerAccountStatus.forbidden:
      return PartnerWorkspaceStatusView(
        status: PartnerWorkspaceStatus.forbidden,
        detail: account.errorMessage,
      );
    case PartnerAccountStatus.notFound:
      return const PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired);
    case PartnerAccountStatus.error:
      return PartnerWorkspaceStatusView(
        status: PartnerWorkspaceStatus.error,
        detail: account.errorMessage,
      );
    case PartnerAccountStatus.idle:
    case PartnerAccountStatus.loading:
      return const _AccountLoading();
    case PartnerAccountStatus.ready:
      return null;
  }
}

class _AccountLoading extends StatelessWidget {
  const _AccountLoading();

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
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 44,
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

String partnerTeamRoleLabel(AppLocalizations l10n, PartnerTeamRole role) =>
    switch (role) {
      PartnerTeamRole.owner => l10n.partnerTeamRoleOwner,
      PartnerTeamRole.manager => l10n.partnerTeamRoleManager,
      PartnerTeamRole.frontDesk => l10n.partnerTeamRoleFrontDesk,
      PartnerTeamRole.finance => l10n.partnerTeamRoleFinance,
      PartnerTeamRole.viewer => l10n.partnerTeamRoleViewer,
      PartnerTeamRole.unknown => l10n.partnerTeamRoleUnknown,
    };

String partnerPayoutMethodLabel(
  AppLocalizations l10n,
  PartnerPayoutMethod method,
) =>
    switch (method) {
      PartnerPayoutMethod.bankTransfer => l10n.partnerPayoutMethodBank,
      PartnerPayoutMethod.manual => l10n.partnerPayoutMethodManual,
      PartnerPayoutMethod.unknown => l10n.partnerPayoutMethodUnknown,
    };

String partnerVerificationLabel(
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

String partnerAccountResultMessage(
  AppLocalizations l10n,
  PartnerAccountActionResult result,
) =>
    switch (result) {
      PartnerAccountActionResult.success => l10n.partnerAccountSaved,
      PartnerAccountActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerAccountActionResult.forbidden =>
        l10n.partnerDashboardErrorForbidden,
      PartnerAccountActionResult.notFound => l10n.partnerAccountNotFound,
      PartnerAccountActionResult.conflict => l10n.partnerAccountConflict,
      PartnerAccountActionResult.validation => l10n.partnerAccountValidation,
      PartnerAccountActionResult.uncertain => l10n.partnerAccountUncertain,
      PartnerAccountActionResult.failed => l10n.partnerPropertyActionFailed,
    };
