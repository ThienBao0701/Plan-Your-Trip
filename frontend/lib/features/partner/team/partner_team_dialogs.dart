import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/partner/partner_access_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_room_models.dart';
import '../../../core/partner/partner_team_models.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import 'partner_step_up_dialog.dart';
import 'partner_team_labels.dart';
import 'partner_team_messages.dart';
import 'partner_team_state.dart';

/// Runs [action]; when the server asks for a fresh session
/// (`STEP_UP_REQUIRED`), confirms the password and runs it **once** more. A
/// declined or failed step-up returns the original refusal.
Future<PartnerTeamActionResult> runWithStepUp(
  BuildContext context,
  Future<PartnerTeamActionResult> Function() action,
) async {
  final first = await action();
  if (!first.stepUpRequired || !context.mounted) return first;
  final confirmed = await showPartnerStepUpDialog(context);
  if (!confirmed) return first;
  return action();
}

/// One editable grant row: a role, a scope type and its target.
class _GrantDraft {
  PartnerTeamRole? role;
  PartnerScopeType? scopeType;
  int? propertyId;
  int? unitId;

  _GrantDraft({this.role, this.scopeType});

  factory _GrantDraft.of(PartnerTeamGrant grant, PartnerAccess? access) {
    final draft = _GrantDraft(role: grant.role, scopeType: grant.scope.type);
    switch (grant.scope.type) {
      case PartnerScopeType.property:
        draft.propertyId = grant.scope.id;
      case PartnerScopeType.unit:
        draft.unitId = grant.scope.id;
        for (final unit in access?.units ?? const <PartnerAccessUnit>[]) {
          if (unit.id == grant.scope.id) draft.propertyId = unit.propertyId;
        }
      default:
        break;
    }
    return draft;
  }

  PartnerTeamGrant? build(int? companyId) {
    final role = this.role;
    final type = scopeType;
    if (role == null || type == null) return null;
    final id = switch (type) {
      PartnerScopeType.company => companyId,
      PartnerScopeType.property => propertyId,
      PartnerScopeType.unit => unitId,
      PartnerScopeType.unknown => null,
    };
    if (id == null) return null;
    return PartnerTeamGrant(role: role, scope: PartnerScopeRef(type, id));
  }
}

/// Edits a list of grants with only the choices this actor can hand out:
///
///  * roles from [PartnerTeamCapabilities.grantableRoles] (an owner offers all
///    nine; anyone else the six below MANAGER, §10.3);
///  * scope types the role may sit at (§11.3) — and COMPANY only when the actor
///    holds [permissionKey] at company scope, so a property scope never becomes
///    company scope;
///  * properties [permissionKey] covers in the access document, and room types
///    of those properties.
///
/// The server re-validates everything; this only avoids offering what it would
/// always refuse.
class PartnerGrantEditor extends StatefulWidget {
  final PartnerTeamCapabilities capabilities;
  final String permissionKey;
  final ApiClient api;
  final List<PartnerTeamGrant> initial;
  final ValueChanged<List<PartnerTeamGrant>?> onChanged;
  final bool enabled;

  const PartnerGrantEditor({
    super.key,
    required this.capabilities,
    required this.permissionKey,
    required this.api,
    required this.onChanged,
    this.initial = const [],
    this.enabled = true,
  });

  @override
  State<PartnerGrantEditor> createState() => _PartnerGrantEditorState();
}

class _PartnerGrantEditorState extends State<PartnerGrantEditor> {
  late final List<_GrantDraft> _rows = widget.initial.isEmpty
      ? [_GrantDraft()]
      : widget.initial
          .map((g) => _GrantDraft.of(g, widget.capabilities.access))
          .toList();
  final Map<int, List<PartnerRoom>> _rooms = {};
  final Set<int> _loadingRooms = {};

  PartnerAccess? get _access => widget.capabilities.access;

  @override
  void initState() {
    super.initState();
    for (final row in _rows) {
      if (row.scopeType == PartnerScopeType.unit && row.propertyId != null) {
        _loadRooms(row.propertyId!);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  List<PartnerScopeType> _scopeTypesFor(PartnerTeamRole? role) {
    if (role == null) return const [];
    final allowed = PartnerTeamRoles.scopesFor(role);
    final properties = widget.capabilities.propertiesFor(widget.permissionKey);
    return [
      if (allowed.contains(PartnerScopeType.company) &&
          widget.capabilities.offersCompanyScope(widget.permissionKey))
        PartnerScopeType.company,
      if (allowed.contains(PartnerScopeType.property) && properties.isNotEmpty)
        PartnerScopeType.property,
      if (allowed.contains(PartnerScopeType.unit) && properties.isNotEmpty)
        PartnerScopeType.unit,
    ];
  }

  Future<void> _loadRooms(int propertyId) async {
    if (_rooms.containsKey(propertyId) || _loadingRooms.contains(propertyId)) {
      return;
    }
    setState(() => _loadingRooms.add(propertyId));
    final result = await widget.api.getPartnerRooms(propertyId);
    if (!mounted) return;
    setState(() {
      _loadingRooms.remove(propertyId);
      _rooms[propertyId] =
          result.success ? (result.data ?? const []) : const [];
    });
  }

  void _emit() {
    final grants = <PartnerTeamGrant>{};
    for (final row in _rows) {
      final grant = row.build(_access?.companyId);
      if (grant == null) {
        widget.onChanged(null);
        return;
      }
      grants.add(grant);
    }
    widget.onChanged(grants.isEmpty ? null : grants.toList());
  }

  void _update(VoidCallback change) {
    setState(change);
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final roles = widget.capabilities.grantableRoles;
    final properties = widget.capabilities.propertiesFor(widget.permissionKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rows.length; i++) ...[
          _GrantRow(
            index: i,
            row: _rows[i],
            roles: roles,
            scopeTypes: _scopeTypesFor(_rows[i].role),
            properties: properties,
            rooms: _rows[i].propertyId == null
                ? null
                : _rooms[_rows[i].propertyId],
            loadingRooms: _rows[i].propertyId != null &&
                _loadingRooms.contains(_rows[i].propertyId),
            enabled: widget.enabled,
            onRole: (role) => _update(() {
              _rows[i].role = role;
              final types = _scopeTypesFor(role);
              if (!types.contains(_rows[i].scopeType)) {
                _rows[i].scopeType = types.length == 1 ? types.first : null;
                _rows[i].propertyId = null;
                _rows[i].unitId = null;
              }
            }),
            onScopeType: (type) => _update(() {
              _rows[i].scopeType = type;
              _rows[i].unitId = null;
              if (type == PartnerScopeType.company) _rows[i].propertyId = null;
            }),
            onProperty: (propertyId) {
              _update(() {
                _rows[i].propertyId = propertyId;
                _rows[i].unitId = null;
              });
              if (propertyId != null &&
                  _rows[i].scopeType == PartnerScopeType.unit) {
                _loadRooms(propertyId);
              }
            },
            onUnit: (unitId) => _update(() => _rows[i].unitId = unitId),
            onRemove: _rows.length > 1
                ? () => _update(() => _rows.removeAt(i))
                : null,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: const Key('partner-grant-add'),
            onPressed: widget.enabled
                ? () => _update(() => _rows.add(_GrantDraft()))
                : null,
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.partnerTeamGrantAdd),
          ),
        ),
      ],
    );
  }
}

class _GrantRow extends StatelessWidget {
  final int index;
  final _GrantDraft row;
  final List<PartnerTeamRole> roles;
  final List<PartnerScopeType> scopeTypes;
  final List<PartnerAccessProperty> properties;
  final List<PartnerRoom>? rooms;
  final bool loadingRooms;
  final bool enabled;
  final ValueChanged<PartnerTeamRole?> onRole;
  final ValueChanged<PartnerScopeType?> onScopeType;
  final ValueChanged<int?> onProperty;
  final ValueChanged<int?> onUnit;
  final VoidCallback? onRemove;

  const _GrantRow({
    required this.index,
    required this.row,
    required this.roles,
    required this.scopeTypes,
    required this.properties,
    required this.rooms,
    required this.loadingRooms,
    required this.enabled,
    required this.onRole,
    required this.onScopeType,
    required this.onProperty,
    required this.onUnit,
    required this.onRemove,
  });

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.sm)),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needsProperty = row.scopeType == PartnerScopeType.property ||
        row.scopeType == PartnerScopeType.unit;
    final fields = <Widget>[
      DropdownButtonFormField<PartnerTeamRole>(
        key: Key('partner-grant-role-$index'),
        initialValue: roles.contains(row.role) ? row.role : null,
        isExpanded: true,
        decoration: _decoration(l10n.partnerTeamRoleField),
        items: [
          for (final role in roles)
            DropdownMenuItem(
                value: role, child: Text(partnerTeamRoleLabel(l10n, role))),
        ],
        onChanged: enabled ? onRole : null,
      ),
      DropdownButtonFormField<PartnerScopeType>(
        key: Key('partner-grant-scope-$index-${row.role?.name}'),
        initialValue: scopeTypes.contains(row.scopeType) ? row.scopeType : null,
        isExpanded: true,
        decoration: _decoration(l10n.partnerTeamScopeField),
        hint: Text(row.role == null
            ? l10n.partnerTeamScopeChooseRole
            : l10n.partnerTeamScopeChoose),
        items: [
          for (final type in scopeTypes)
            DropdownMenuItem(
                value: type, child: Text(partnerScopeTypeLabel(l10n, type))),
        ],
        onChanged: enabled && scopeTypes.isNotEmpty ? onScopeType : null,
      ),
      if (needsProperty)
        DropdownButtonFormField<int>(
          key: Key('partner-grant-property-$index'),
          initialValue: properties.any((p) => p.id == row.propertyId)
              ? row.propertyId
              : null,
          isExpanded: true,
          decoration: _decoration(l10n.partnerTeamScopeProperty),
          items: [
            for (final property in properties)
              DropdownMenuItem(
                  value: property.id,
                  child: Text(property.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: enabled ? onProperty : null,
        ),
      if (row.scopeType == PartnerScopeType.unit && row.propertyId != null)
        loadingRooms
            ? const LinearProgressIndicator()
            : DropdownButtonFormField<int>(
                key: Key('partner-grant-unit-$index'),
                initialValue: (rooms ?? const <PartnerRoom>[])
                        .any((r) => r.id == row.unitId)
                    ? row.unitId
                    : null,
                isExpanded: true,
                decoration: _decoration(l10n.partnerTeamScopeUnit),
                hint: Text((rooms ?? const <PartnerRoom>[]).isEmpty
                    ? l10n.partnerTeamScopeNoRooms
                    : l10n.partnerTeamScopeChoose),
                items: [
                  for (final room in rooms ?? const <PartnerRoom>[])
                    DropdownMenuItem(
                        value: room.id,
                        child: Text(room.roomName,
                            overflow: TextOverflow.ellipsis)),
                ],
                onChanged: enabled ? onUnit : null,
              ),
    ];
    if (row.role != null && scopeTypes.isEmpty) {
      fields.add(Text(
        l10n.partnerTeamScopeNoneForRole,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: AppColors.warning),
      ));
    }
    return Container(
      key: Key('partner-grant-row-$index'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.xs),
                  fields[i],
                ],
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: l10n.partnerTeamGrantRemove,
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

/// The grants about to be sent, in words — the review step before submitting.
class PartnerGrantSummary extends StatelessWidget {
  final List<PartnerTeamGrant> grants;
  final PartnerAccess? access;

  const PartnerGrantSummary(
      {super.key, required this.grants, required this.access});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final grant in grants)
          OceanStatusPill(
            label: l10n.partnerTeamGrantLabel(
              partnerTeamRoleLabel(l10n, grant.role),
              partnerScopeLabel(l10n, grant.scope, access),
            ),
            icon: grant.role == PartnerTeamRole.owner
                ? Icons.shield_outlined
                : Icons.badge_outlined,
            color: grant.role == PartnerTeamRole.owner
                ? AppColors.warning
                : AppColors.ocean600,
          ),
      ],
    );
  }
}

/// A short, structured error under a form — never server prose, never input.
class PartnerTeamErrorText extends StatelessWidget {
  final ApiFailure failure;
  final String Function(AppLocalizations, ApiFailure) describe;

  const PartnerTeamErrorText(
      {super.key,
      required this.failure,
      this.describe = partnerTeamFailureMessage});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('partner-team-form-error'),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: AppColors.danger.withValues(alpha: .35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Expanded(child: Text(describe(l10n, failure))),
          ],
        ),
      ),
    );
  }
}

/// `POST /api/partner/team/invitations` — address, grants, review, send.
///
/// Returns true when the server recorded the request (202). That is not proof
/// of delivery: the email goes out after the invitation commits, and the list
/// shows its delivery status. Nothing is added to the list locally.
Future<bool> showPartnerInviteDialog(
  BuildContext context, {
  required PartnerTeamState team,
  required PartnerTeamCapabilities capabilities,
}) async {
  final sent = await showDialog<bool>(
    context: context,
    builder: (_) => _InviteDialog(team: team, capabilities: capabilities),
  );
  return sent ?? false;
}

class _InviteDialog extends StatefulWidget {
  final PartnerTeamState team;
  final PartnerTeamCapabilities capabilities;

  const _InviteDialog({required this.team, required this.capabilities});

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  List<PartnerTeamGrant>? _grants;
  ApiFailure? _failure;
  bool _busy = false;

  static final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final grants = _grants;
    if (grants == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final email = _email.text.trim().toLowerCase();
    final result = await runWithStepUp(
        context, () => widget.team.invite(email: email, grants: grants));
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _failure = result.ignored ? null : result.failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final grants = _grants;
    return AlertDialog(
      key: const Key('partner-invite-dialog'),
      title: Text(l10n.partnerInviteTitle),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.partnerInviteBody,
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('partner-invite-email'),
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration:
                      InputDecoration(labelText: l10n.partnerInviteEmailLabel),
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return l10n.partnerInviteEmailRequired;
                    if (email.length > 254 || !_emailShape.hasMatch(email)) {
                      return l10n.partnerInviteEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l10n.partnerInviteGrantsLabel,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                PartnerGrantEditor(
                  capabilities: widget.capabilities,
                  permissionKey: PartnerPermissionKeys.teamInvite,
                  api: widget.team.api,
                  enabled: !_busy,
                  onChanged: (value) => setState(() => _grants = value),
                ),
                if (grants != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.partnerInviteReview,
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  PartnerGrantSummary(
                      grants: grants, access: widget.capabilities.access),
                  if (PartnerTeamCapabilities.involvesOwner(
                      grants: grants)) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.partnerTeamOwnerStepUpHint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.partnerInviteLimits,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
                if (_failure != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  PartnerTeamErrorText(failure: _failure!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.partnerTeamCancel),
        ),
        FilledButton(
          key: const Key('partner-invite-submit'),
          onPressed: _busy || grants == null ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.partnerInviteSubmit),
        ),
      ],
    );
  }
}

/// `PUT /api/partner/team/{id}/grants` with the version the list showed.
///
/// Returns the action's result, or null when the dialog was cancelled. A
/// `CONCURRENT_MODIFICATION` closes the dialog: the list has been re-read, and
/// the operator reviews the current record before trying again.
Future<PartnerTeamActionResult?> showPartnerEditGrantsDialog(
  BuildContext context, {
  required PartnerTeamState team,
  required PartnerTeamCapabilities capabilities,
  required PartnerTeamMember member,
}) =>
    showDialog<PartnerTeamActionResult>(
      context: context,
      builder: (_) => _EditGrantsDialog(
          team: team, capabilities: capabilities, member: member),
    );

class _EditGrantsDialog extends StatefulWidget {
  final PartnerTeamState team;
  final PartnerTeamCapabilities capabilities;
  final PartnerTeamMember member;

  const _EditGrantsDialog(
      {required this.team, required this.capabilities, required this.member});

  @override
  State<_EditGrantsDialog> createState() => _EditGrantsDialogState();
}

class _EditGrantsDialogState extends State<_EditGrantsDialog> {
  final _reason = TextEditingController();
  List<PartnerTeamGrant>? _grants;
  ApiFailure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final grants = _grants;
    if (_busy || grants == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await runWithStepUp(
      context,
      () => widget.team
          .replaceGrants(widget.member, grants, reason: _reason.text),
    );
    if (!mounted) return;
    if (result.success ||
        result.code == PartnerTeamCodes.concurrentModification) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() {
      _busy = false;
      _failure = result.ignored ? null : result.failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final member = widget.member;
    final grants = _grants;
    return AlertDialog(
      key: const Key('partner-edit-grants-dialog'),
      title: Text(l10n.partnerEditGrantsTitle),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                member.userName.isEmpty
                    ? member.userEmail
                    : '${member.userName} · ${member.userEmail}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.partnerEditGrantsBody,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.md),
              PartnerGrantEditor(
                capabilities: widget.capabilities,
                permissionKey: PartnerPermissionKeys.teamRoleAssign,
                api: widget.team.api,
                initial: member.grants,
                enabled: !_busy,
                onChanged: (value) => setState(() => _grants = value),
              ),
              if (grants != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.partnerInviteReview,
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xs),
                PartnerGrantSummary(
                    grants: grants, access: widget.capabilities.access),
                if (PartnerTeamCapabilities.involvesOwner(
                    member: member, grants: grants)) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.partnerTeamOwnerStepUpHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.sm),
              TextField(
                key: const Key('partner-edit-grants-reason'),
                controller: _reason,
                enabled: !_busy,
                maxLength: 500,
                decoration:
                    InputDecoration(labelText: l10n.partnerTeamReasonLabel),
              ),
              if (_failure != null) ...[
                const SizedBox(height: AppSpacing.sm),
                PartnerTeamErrorText(failure: _failure!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.partnerTeamCancel),
        ),
        FilledButton(
          key: const Key('partner-edit-grants-submit'),
          onPressed: _busy || grants == null ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.partnerEditGrantsSubmit),
        ),
      ],
    );
  }
}

/// A confirmation, optionally collecting the free-text reason the backend
/// accepts (suspend, remove, revoke). Returns null when cancelled; otherwise the
/// reason (possibly empty).
Future<String?> showPartnerConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool withReason = false,
  bool destructive = false,
}) =>
    showDialog<String>(
      context: context,
      builder: (dialogContext) => _ConfirmDialog(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        withReason: withReason,
        destructive: destructive,
      ),
    );

class _ConfirmDialog extends StatefulWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final bool withReason;
  final bool destructive;

  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.withReason,
    required this.destructive,
  });

  @override
  State<_ConfirmDialog> createState() => _ConfirmDialogState();
}

class _ConfirmDialogState extends State<_ConfirmDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const Key('partner-team-confirm'),
      title: Text(widget.title),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.body),
            if (widget.withReason) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('partner-team-confirm-reason'),
                controller: _reason,
                maxLength: 500,
                decoration:
                    InputDecoration(labelText: l10n.partnerTeamReasonLabel),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.partnerTeamCancel),
        ),
        FilledButton(
          key: const Key('partner-team-confirm-action'),
          style: widget.destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.danger)
              : null,
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
