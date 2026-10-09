import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/routing/invitation_link.dart';
import '../../../app/surface_gate.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/partner/partner_state.dart';
import '../../../core/partner/partner_team_models.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../../auth/auth_page_scaffold.dart';
import '../../auth/login_screen.dart';
import 'partner_team_labels.dart';
import 'partner_team_messages.dart';

/// RBAC R5 — the invitation link opened by someone who is **signed out**
/// (`/accept-invitation`, RBAC V1.1 §14).
///
/// The token is captured from the fragment and cleared from the address bar at
/// once ([PartnerInvitationLink]), then the ordinary Partner sign-in is shown
/// with the same guidance for everyone — it reveals nothing about any account.
/// Signing in rebuilds the gate at this location into [AcceptInvitationScreen],
/// which finds the token in memory. Creating a Partner account goes through the
/// usual registration and email verification; the invitee then opens the
/// emailed link again (the token is deliberately not kept across that).
class PartnerInvitationSignInScreen extends StatefulWidget {
  const PartnerInvitationSignInScreen({super.key});

  @override
  State<PartnerInvitationSignInScreen> createState() =>
      _PartnerInvitationSignInScreenState();
}

class _PartnerInvitationSignInScreenState
    extends State<PartnerInvitationSignInScreen> {
  @override
  void initState() {
    super.initState();
    PartnerInvitationLink.capture();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LoginScreen(
      embeddedInSurfaceGate: true,
      notice: AuthNotice(
        key: const Key('partner-invitation-guidance'),
        icon: Icons.mark_email_unread_outlined,
        message: l10n.partnerAcceptGuidance,
      ),
    );
  }
}

/// RBAC R5 — the invitation link for a **signed-in** Partner account
/// (`POST /api/me/partner-invitations/accept|decline`).
///
/// Accepting joins the invited workspace with exactly the invited grants — it
/// does not create a company. The server decides everything: the account must be
/// a verified PARTNER account using the invited address, with no company of its
/// own and no active membership elsewhere. Each refusal is explained without
/// echoing the invited address. A final refusal (used, revoked, superseded,
/// expired or stale link) drops the token; a network failure keeps it for a
/// retry. The token is never shown, logged or stored.
class AcceptInvitationScreen extends StatefulWidget {
  /// Tests pass a token directly; otherwise it is read from the link.
  final String? initialToken;

  const AcceptInvitationScreen({super.key, this.initialToken});

  @override
  State<AcceptInvitationScreen> createState() => _AcceptInvitationScreenState();
}

enum _Outcome { none, accepted, declined }

class _AcceptInvitationScreenState extends State<AcceptInvitationScreen> {
  String? _token;
  bool _busy = false;
  ApiFailure? _failure;
  _Outcome _outcome = _Outcome.none;
  List<PartnerMyInvitation>? _mine;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken != null) {
      PartnerInvitationLink.debugSet(widget.initialToken);
    } else {
      PartnerInvitationLink.capture();
    }
    _token = PartnerInvitationLink.pending;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMine());
  }

  /// §14 AC-5 — the caller's own open invitations, for context. No token in it.
  Future<void> _loadMine() async {
    final partner = PartnerScope.maybeOf(context);
    if (partner == null) return;
    final result = await partner.api.getMyPartnerInvitations();
    if (!mounted || !result.success) return;
    setState(() => _mine = result.data);
  }

  Future<void> _accept() async {
    final token = _token;
    final partner = PartnerScope.maybeOf(context);
    if (_busy || token == null || partner == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await partner.api.acceptPartnerInvitation(token);
    if (!mounted) return;
    if (result.success) {
      PartnerInvitationLink.clear();
      partner.reset();
      setState(() {
        _token = null;
        _busy = false;
        _outcome = _Outcome.accepted;
      });
      return;
    }
    final failure = result.failure!;
    if (partnerInvitationFailureIsFinal(failure)) {
      PartnerInvitationLink.clear();
      _token = null;
    }
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  Future<void> _decline() async {
    final token = _token;
    final partner = PartnerScope.maybeOf(context);
    if (_busy || token == null || partner == null) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.partnerAcceptDeclineTitle),
        content: Text(l10n.partnerAcceptDeclineBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.partnerTeamCancel)),
          FilledButton(
            key: const Key('partner-accept-decline-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerAcceptDecline),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await partner.api.declinePartnerInvitation(token);
    if (!mounted) return;
    if (result.success || partnerInvitationFailureIsFinal(result.failure!)) {
      PartnerInvitationLink.clear();
      _token = null;
    }
    setState(() {
      _busy = false;
      if (result.success) {
        _outcome = _Outcome.declined;
      } else {
        _failure = result.failure;
      }
    });
  }

  void _openWorkspace() {
    PartnerInvitationLink.clear();
    SurfaceNavigation.goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    final children = <Widget>[];

    switch (_outcome) {
      case _Outcome.accepted:
        children.addAll([
          AuthNotice(
            key: const Key('partner-accept-success'),
            icon: Icons.check_circle_outline_rounded,
            message: l10n.partnerAcceptSuccess,
          ),
          const SizedBox(height: AppSpacing.lg),
          OceanPrimaryButton(
            key: const Key('partner-accept-open-workspace'),
            label: l10n.partnerAcceptOpenWorkspace,
            icon: Icons.arrow_forward_rounded,
            onPressed: _openWorkspace,
          ),
        ]);
      case _Outcome.declined:
        children.addAll([
          AuthNotice(
            key: const Key('partner-accept-declined'),
            icon: Icons.do_not_disturb_on_outlined,
            message: l10n.partnerAcceptDeclined,
          ),
          const SizedBox(height: AppSpacing.lg),
          OceanSecondaryButton(
            label: l10n.partnerAcceptOpenWorkspace,
            icon: Icons.arrow_forward_rounded,
            onPressed: _openWorkspace,
          ),
        ]);
      case _Outcome.none:
        children.add(AuthNotice(
          key: const Key('partner-invitation-guidance'),
          icon: Icons.info_outline_rounded,
          message: l10n.partnerAcceptJoinNote,
        ));
        if (failure != null) {
          children.addAll([
            const SizedBox(height: AppSpacing.md),
            Semantics(
              liveRegion: true,
              child: AuthNotice(
                key: const Key('partner-accept-error'),
                icon: Icons.error_outline_rounded,
                message: partnerInvitationAcceptMessage(l10n, failure),
              ),
            ),
          ]);
        }
        children.add(const SizedBox(height: AppSpacing.lg));
        if (_token != null) {
          children.addAll([
            OceanPrimaryButton(
              key: const Key('partner-accept-submit'),
              label: l10n.partnerAcceptAction,
              icon: Icons.how_to_reg_outlined,
              onPressed: _busy ? null : _accept,
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              key: const Key('partner-accept-decline'),
              label: l10n.partnerAcceptDecline,
              icon: Icons.close_rounded,
              onPressed: _busy ? null : _decline,
            ),
          ]);
          if (_busy) {
            children.addAll(const [
              SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator()
            ]);
          }
        } else {
          children.addAll([
            AuthNotice(
              key: const Key('partner-accept-no-link'),
              icon: Icons.link_off_rounded,
              message: l10n.partnerAcceptNoLink,
            ),
            const SizedBox(height: AppSpacing.md),
            OceanSecondaryButton(
              key: const Key('partner-accept-open-workspace'),
              label: l10n.partnerAcceptOpenWorkspace,
              icon: Icons.arrow_forward_rounded,
              onPressed: _openWorkspace,
            ),
          ]);
        }
        final mine = _mine;
        if (mine != null && mine.isNotEmpty) {
          children.addAll([
            const SizedBox(height: AppSpacing.lg),
            _MyInvitations(invitations: mine),
          ]);
        }
    }

    return AuthPageScaffold(
      title: l10n.partnerAcceptTitle,
      heading: l10n.partnerAcceptTitle,
      icon: Icons.group_add_outlined,
      onBack: _busy ? null : _openWorkspace,
      children: children,
    );
  }
}

/// Invitations addressed to the caller's own address (§14 AC-5): company,
/// role and scope, expiry. Accepting still needs the emailed link.
class _MyInvitations extends StatelessWidget {
  final List<PartnerMyInvitation> invitations;

  const _MyInvitations({required this.invitations});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      key: const Key('partner-accept-mine'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.partnerAcceptMineHeading, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.xs),
        for (final invitation in invitations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.companyName,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(
                  [
                    for (final grant in invitation.grants)
                      l10n.partnerTeamGrantLabel(
                        partnerTeamRoleLabel(l10n, grant.role),
                        grant.scopeName ??
                            partnerScopeTypeLabel(l10n, grant.scopeType),
                      ),
                    if (invitation.expiresAt != null)
                      l10n.partnerInviteExpires(DateFormat.yMMMd(locale)
                          .format(invitation.expiresAt!.toLocal())),
                  ].join(' · '),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
