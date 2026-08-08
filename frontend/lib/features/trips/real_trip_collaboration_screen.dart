import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'trip_companion_screen.dart' show collaboratorRoleLabel;

/// UI48 — Real Mode trip collaboration
/// (`/api/me/trips/{tripId}/collaborators` + public/private toggle, Phase 7.5).
/// Owner-only management: lists collaborators, invites by email, changes a
/// collaborator's role, removes a collaborator, and toggles the trip's public
/// visibility. A non-owner viewer gets an honest owner-only forbidden state.
/// Invitations are immediately active — the backend has no accept/reject flow,
/// so none is shown.
class RealTripCollaborationScreen extends StatefulWidget {
  final int tripId;
  final String? tripTitle;
  final bool? isPublic;

  const RealTripCollaborationScreen({
    super.key,
    required this.tripId,
    this.tripTitle,
    this.isPublic,
  });

  @override
  State<RealTripCollaborationScreen> createState() =>
      _RealTripCollaborationScreenState();
}

class _RealTripCollaborationScreenState
    extends State<RealTripCollaborationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        AppScope.of(context).loadRealCollaborators(
          widget.tripId,
          seedIsPublic: widget.isPublic,
        );
      }
    });
  }

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForOutcome(AppLocalizations l10n, CollaborationOutcome o) {
    return switch (o) {
      CollaborationOutcome.forbidden => l10n.collaborationRealForbiddenMessage,
      CollaborationOutcome.notFound =>
        l10n.collaborationRealUserNotFoundMessage,
      CollaborationOutcome.conflict =>
        l10n.collaborationRealAlreadyMemberMessage,
      CollaborationOutcome.validation => l10n.collaborationRealInvalidMessage,
      CollaborationOutcome.network => l10n.collaborationRealNetworkMessage,
      _ => l10n.collaborationRealActionErrorMessage,
    };
  }

  Future<void> _openForm(AppState app, RealCollaborator? existing) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await showModalBottomSheet<CollaborationOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CollaboratorFormSheet(
        tripId: widget.tripId,
        existing: existing,
      ),
    );
    if (!mounted || outcome == null) return;
    switch (outcome) {
      case CollaborationOutcome.success:
        _snack(existing == null
            ? l10n.collaborationRealInvitedMessage
            : l10n.collaborationRealRoleUpdatedMessage);
      case CollaborationOutcome.sessionExpired:
        _reauth();
      case CollaborationOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _remove(AppState app, RealCollaborator c) async {
    final l10n = AppLocalizations.of(context)!;
    final name =
        c.userFullName.trim().isEmpty ? c.userEmail : c.userFullName.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.collaborationRemoveConfirmTitle),
        content: Text(l10n.collaborationRealRemoveConfirmMessage(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('collab-remove-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.person_remove_alt_1_rounded),
            label: Text(l10n.collaborationRemoveAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.removeRealCollaborator(widget.tripId, c.id);
    if (!mounted) return;
    switch (outcome) {
      case CollaborationOutcome.success:
        _snack(l10n.collaborationRealRemovedMessage);
      case CollaborationOutcome.sessionExpired:
        _reauth();
      case CollaborationOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _togglePublic(AppState app, bool makePublic) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.setRealTripPublic(widget.tripId, makePublic);
    if (!mounted) return;
    switch (outcome) {
      case CollaborationOutcome.success:
        _snack(makePublic
            ? l10n.collaborationRealPublicOnMessage
            : l10n.collaborationRealPublicOffMessage);
      case CollaborationOutcome.sessionExpired:
        _reauth();
      case CollaborationOutcome.busy:
        break;
      default:
        _snack(_messageForOutcome(l10n, outcome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(widget.tripTitle?.trim().isNotEmpty == true
            ? widget.tripTitle!.trim()
            : l10n.collaborationRealTitle),
        actions: [
          if (app.realCollabLoaded)
            IconButton(
              key: const Key('collab-invite'),
              tooltip: l10n.collaborationRealAddSemantic,
              onPressed: app.realCollabMutationInFlight
                  ? null
                  : () => _openForm(app, null),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realCollabError == CollaborationOutcome.sessionExpired &&
        !app.realCollabLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('collab-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realCollabLoading && !app.realCollabLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.collaborationRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('collab-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.collaborationRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realCollabError != null && !app.realCollabLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('collab-error'),
          message: app.realCollabError == CollaborationOutcome.forbidden
              ? l10n.collaborationRealForbiddenMessage
              : app.realCollabError == CollaborationOutcome.notFound
                  ? l10n.collaborationRealGoneMessage
                  : l10n.collaborationRealErrorMessage,
          onReload: () =>
              app.loadRealCollaborators(widget.tripId, refresh: true),
        ),
      );
    }
    final collaborators = app.realCollaboratorsFor(widget.tripId);
    final isPublic = app.realCollabIsPublicFor(widget.tripId) ?? false;
    return RefreshIndicator(
      onRefresh: () => app.loadRealCollaborators(widget.tripId, refresh: true),
      child: ListView(
        key: const Key('collab-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ShareCard(
                  isPublic: isPublic,
                  busy: app.realCollabMutationInFlight,
                  onChanged: (v) => _togglePublic(app, v),
                ),
                const SizedBox(height: AppSpacing.md),
                if (collaborators.isEmpty)
                  OceanEmptyState(
                    key: const Key('collab-empty'),
                    title: l10n.collaborationRealEmptyTitle,
                    message: l10n.collaborationRealEmptyMessage,
                    actionLabel: l10n.collaborationInviteAction,
                    onAction: app.realCollabMutationInFlight
                        ? null
                        : () => _openForm(app, null),
                  )
                else
                  for (final c in collaborators)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _CollaboratorCard(
                        collaborator: c,
                        busy: app.realCollabMutationInFlight,
                        onRole: () => _openForm(app, c),
                        onRemove: () => _remove(app, c),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}

/// Localized role label for a real collaborator, falling back to the raw wire
/// code if the backend sent an unrecognised role.
String realCollaboratorRoleLabel(AppLocalizations l10n, RealCollaborator c) {
  final view = c.roleView;
  if (view != null) return collaboratorRoleLabel(l10n, view);
  return c.role.trim().isEmpty ? l10n.collaborationRoleViewer : c.role;
}

class _ShareCard extends StatelessWidget {
  final bool isPublic;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _ShareCard({
    required this.isPublic,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      key: const Key('collab-share-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  l10n.collaborationRealOwnerBadge,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.collaborationRealPublicLabel,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      isPublic
                          ? l10n.collaborationRealPublicOnMessage
                          : l10n.collaborationRealPublicOffMessage,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                toggled: isPublic,
                label: l10n.collaborationRealPublicLabel,
                child: Switch(
                  key: const Key('collab-public-toggle'),
                  value: isPublic,
                  onChanged: busy ? null : onChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollaboratorCard extends StatelessWidget {
  final RealCollaborator collaborator;
  final bool busy;
  final VoidCallback onRole;
  final VoidCallback onRemove;

  const _CollaboratorCard({
    required this.collaborator,
    required this.busy,
    required this.onRole,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = collaborator.userFullName.trim().isEmpty
        ? collaborator.userEmail
        : collaborator.userFullName.trim();
    final isEditor = collaborator.roleView == TripCollaboratorRole.editor;
    return OceanGlassCard(
      key: Key('collab-card-${collaborator.id}'),
      semanticLabel: name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleMedium),
          if (collaborator.userEmail.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              collaborator.userEmail.trim(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: realCollaboratorRoleLabel(l10n, collaborator),
                icon: isEditor ? Icons.edit_rounded : Icons.visibility_rounded,
                color: isEditor ? AppColors.ocean : AppColors.slate,
              ),
              OceanStatusPill(
                label: collaborator.active
                    ? l10n.collaborationActiveLabel
                    : l10n.collaborationInactiveLabel,
                icon: collaborator.active
                    ? Icons.check_circle_rounded
                    : Icons.pause_circle_rounded,
                color: collaborator.active
                    ? AppColors.success
                    : AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OceanSecondaryButton(
                key: Key('collab-role-${collaborator.id}'),
                label: l10n.collaborationChangeRoleAction,
                icon: Icons.manage_accounts_rounded,
                fullWidth: false,
                onPressed: busy ? null : onRole,
                semanticLabel: l10n.collaborationChangeRoleAction,
              ),
              OceanSecondaryButton(
                key: Key('collab-remove-${collaborator.id}'),
                label: l10n.collaborationRemoveAction,
                icon: Icons.person_remove_alt_1_rounded,
                fullWidth: false,
                onPressed: busy ? null : onRemove,
                semanticLabel: l10n.collaborationRemoveAction,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollaboratorFormSheet extends StatefulWidget {
  final int tripId;
  final RealCollaborator? existing;

  const _CollaboratorFormSheet({required this.tripId, this.existing});

  @override
  State<_CollaboratorFormSheet> createState() => _CollaboratorFormSheetState();
}

class _CollaboratorFormSheetState extends State<_CollaboratorFormSheet> {
  late final TextEditingController _email;
  late TripCollaboratorRole _role;
  bool _emailError = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _email = TextEditingController(text: c?.userEmail ?? '');
    _role = c?.roleView ?? TripCollaboratorRole.viewer;
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.of(context);
    final existing = widget.existing;
    final email = existing != null ? existing.userEmail : _email.text.trim();
    setState(() => _emailError = email.isEmpty);
    if (email.isEmpty) return;
    final payload = RealCollaboratorPayload(email: email, role: _role);
    final outcome = existing == null
        ? await app.inviteRealCollaborator(widget.tripId, payload)
        : await app.updateRealCollaboratorRole(
            widget.tripId, existing.id, payload);
    if (!mounted) return;
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final saving = app.realCollabMutationInFlight;
    final isEdit = widget.existing != null;
    return SafeArea(
      child: Padding(
        key: const Key('collab-form-content'),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit
                    ? l10n.collaborationRealEditRoleTitle
                    : l10n.collaborationInviteTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              if (isEdit)
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.collaborationRealEmailLabel,
                    prefixIcon: const Icon(Icons.email_rounded),
                  ),
                  child: Text(widget.existing!.userEmail),
                )
              else ...[
                GlassTextField(
                  key: const Key('collab-field-email'),
                  controller: _email,
                  hint: l10n.collaborationRealEmailLabel,
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                if (_emailError)
                  _fieldError(context, l10n.collaborationRealInvalidMessage),
              ],
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<TripCollaboratorRole>(
                key: const Key('collab-field-role'),
                initialValue: _role,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.collaborationRealRoleLabel,
                  prefixIcon: const Icon(Icons.badge_rounded),
                ),
                items: [
                  for (final r in TripCollaboratorRole.values)
                    DropdownMenuItem(
                      value: r,
                      child: Text(collaboratorRoleLabel(l10n, r)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('collab-form-save'),
                label: isEdit
                    ? l10n.collaborationChangeRoleAction
                    : l10n.collaborationInviteAction,
                icon: Icons.check_rounded,
                onPressed: saving ? null : _submit,
                semanticLabel: isEdit
                    ? l10n.collaborationChangeRoleAction
                    : l10n.collaborationInviteAction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldError(BuildContext context, String message) => Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.xxs, left: AppSpacing.sm),
        child: Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.danger),
        ),
      );
}
