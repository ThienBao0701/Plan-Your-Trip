import 'package:flutter/material.dart';

import '../../core/app_role.dart';
import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../core/network/api_client.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/change_password_screen.dart';

/// The account area shared by the Partner and Admin surfaces.
///
/// It shows only what the backend actually exposes about the signed-in account —
/// `GET /api/me` returns name, email and role — plus whatever section the surface
/// adds (the Partner's business profile). Nothing security-internal is displayed:
/// no password, no token, no session version.
///
/// It is a plain screen rather than a shell destination, so it is reachable
/// before a Partner's business profile is approved, when the workspace itself is
/// still closed.
class AccountScreen extends StatefulWidget {
  final String title;

  /// Label of the back action, e.g. "Back to workspace".
  final String backLabel;

  final VoidCallback onBack;

  /// Surface-specific content shown under the account details.
  final List<Widget> sections;

  const AccountScreen({
    super.key,
    required this.title,
    required this.backLabel,
    required this.onBack,
    this.sections = const [],
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  AccountIdentityRecord? _identity;
  ApiErrorKind? _errorKind;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = AppScope.of(context).api;
    setState(() {
      _loading = true;
      _errorKind = null;
    });
    final result = await api.getAccountIdentity();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _identity = result.data;
      _errorKind = result.success ? null : result.errorKind;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: widget.backLabel,
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(widget.title),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: OceanContentConstraint(
              maxWidth: AppBreakpoints.maxContentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detailsCard(context, l10n),
                  const SizedBox(height: AppSpacing.lg),
                  _securityCard(context, l10n),
                  for (final section in widget.sections) ...[
                    const SizedBox(height: AppSpacing.lg),
                    section,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailsCard(BuildContext context, AppLocalizations l10n) {
    final app = AppScope.of(context);
    final identity = _identity;
    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.accountDetailsHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(
                child: SizedBox.square(
                  dimension: 32,
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (identity == null)
            _AccountError(kind: _errorKind, onRetry: _load)
          else ...[
            AccountField(
              key: const Key('account-name'),
              label: l10n.authFullNameLabel,
              value: identity.fullName,
            ),
            AccountField(
              key: const Key('account-email'),
              label: l10n.authEmailLabel,
              value: identity.email.isEmpty ? app.email : identity.email,
            ),
            AccountField(
              key: const Key('account-role'),
              label: l10n.accountRoleLabel,
              value: _roleLabel(l10n, AppRole.parse(identity.role)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _securityCard(BuildContext context, AppLocalizations l10n) =>
      OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountSecurityHeading,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.accountSecurityBody,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            OceanSecondaryButton(
              key: const Key('account-change-password'),
              label: l10n.changePasswordTitle,
              icon: Icons.password_rounded,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChangePasswordScreen(),
                ),
              ),
            ),
          ],
        ),
      );

  String _roleLabel(AppLocalizations l10n, AppRole role) => switch (role) {
        AppRole.partner => l10n.accountRolePartner,
        AppRole.admin => l10n.accountRoleAdmin,
        AppRole.user => l10n.accountRoleUser,
        AppRole.unknown => l10n.partnerVerificationUnknown,
      };
}

/// One read-only account attribute.
class AccountField extends StatelessWidget {
  final String label;
  final String? value;

  const AccountField({super.key, required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            value == null || value!.isEmpty ? '—' : value!,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// Why the account could not be read, and a way to try again.
class _AccountError extends StatelessWidget {
  final ApiErrorKind? kind;
  final VoidCallback onRetry;

  const _AccountError({required this.kind, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (kind) {
      ApiErrorKind.unauthorized => l10n.authErrorSessionExpired,
      ApiErrorKind.forbidden => l10n.authErrorAccountUnavailable,
      ApiErrorKind.network || ApiErrorKind.timeout => l10n.authErrorNetwork,
      ApiErrorKind.server => l10n.authErrorServer,
      _ => l10n.authErrorGeneric,
    };
    return Column(
      key: const Key('account-error'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.md),
        OceanSecondaryButton(
          key: const Key('account-retry'),
          label: l10n.partnerActionRetry,
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
