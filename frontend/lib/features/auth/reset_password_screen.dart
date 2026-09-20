import 'package:flutter/material.dart';

import '../../app/routing/auth_link_token.dart';
import '../../app/routing/surface_router.dart';
import '../../app/surface_gate.dart';
import '../../core/app_state.dart';
import '../../core/auth/auth_error.dart';
import '../../core/auth/auth_messages.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'auth_page_scaffold.dart';
import 'auth_validators.dart';

/// Setting a new password from a reset link — `POST /api/auth/reset-password`.
///
/// Like verification, the one-time token comes from the link's fragment, is
/// cleared from the address bar as soon as it is read, and is never stored.
/// A successful reset ends every session of the account (the backend bumps its
/// token version), so the only way on from here is signing in again.
class ResetPasswordScreen extends StatefulWidget {
  /// The token from the link; defaults to the current URL's fragment.
  final String? initialToken;

  const ResetPasswordScreen({super.key, this.initialToken});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _token = TextEditingController(
      text: widget.initialToken ?? AuthLinkToken.read() ?? '');
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _showPassword = false;
  bool _showConfirm = false;
  bool _submitting = false;
  bool _done = false;
  AuthFailure? _failure;

  @override
  void initState() {
    super.initState();
    if (widget.initialToken == null && _token.text.isNotEmpty) {
      AuthLinkToken.clear(SurfaceRouter.resetPassword);
    }
  }

  @override
  void dispose() {
    _token.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_done) {
      return AuthPageScaffold(
        title: l10n.resetPasswordTitle,
        heading: l10n.resetPasswordSuccessTitle,
        subtitle: l10n.resetPasswordSuccessBody,
        icon: Icons.lock_reset_rounded,
        children: [
          OceanPrimaryButton(
            key: const Key('reset-password-continue'),
            label: l10n.resetPasswordBackAction,
            icon: Icons.login_rounded,
            semanticLabel: l10n.resetPasswordBackAction,
            onPressed: () => SurfaceNavigation.goHome(context),
          ),
        ],
      );
    }

    final failure = _failure;
    return AuthPageScaffold(
      title: l10n.resetPasswordTitle,
      heading: l10n.resetPasswordTitle,
      subtitle: l10n.resetPasswordSubtitle,
      icon: Icons.lock_reset_rounded,
      onBack: _submitting ? null : () => SurfaceNavigation.goHome(context),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('reset-password-token'),
                controller: _token,
                textInputAction: TextInputAction.next,
                validator: (value) => AuthValidators.linkToken(l10n, value),
                decoration: InputDecoration(
                  labelText: l10n.resetPasswordTokenLabel,
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('reset-password-new'),
                controller: _password,
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (value) => AuthValidators.newPassword(l10n, value),
                decoration: InputDecoration(
                  labelText: l10n.resetPasswordNewLabel,
                  helperText: l10n.authPasswordRequirement,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  errorText: failure == null
                      ? null
                      : authFieldMessage(failure, AuthFields.newPassword),
                  suffixIcon: PasswordVisibilityToggle(
                    visible: _showPassword,
                    onChanged: (value) => setState(() => _showPassword = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('reset-password-confirm'),
                controller: _confirm,
                obscureText: !_showConfirm,
                textInputAction: TextInputAction.done,
                validator: (value) =>
                    AuthValidators.confirmation(l10n, value, _password.text),
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.authConfirmPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: PasswordVisibilityToggle(
                    visible: _showConfirm,
                    confirmation: true,
                    onChanged: (value) => setState(() => _showConfirm = value),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthNotice(
            key: const Key('reset-password-error'),
            icon: Icons.error_outline_rounded,
            message: authFailureMessage(l10n, failure),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AuthSubmitButton(
          buttonKey: const Key('reset-password-submit'),
          label: l10n.resetPasswordAction,
          icon: Icons.check_rounded,
          busy: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          key: const Key('reset-password-back'),
          onPressed:
              _submitting ? null : () => SurfaceNavigation.goHome(context),
          child: Text(l10n.resetPasswordBackAction),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final api = AppScope.of(context).api;
    setState(() => _submitting = true);
    final result = await api.resetPassword(
      token: _token.text.trim(),
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      setState(() => _failure = result.failure);
      return;
    }
    _token.clear();
    _password.clear();
    _confirm.clear();
    AuthLinkToken.clear(SurfaceRouter.resetPassword);
    setState(() => _done = true);
  }
}
