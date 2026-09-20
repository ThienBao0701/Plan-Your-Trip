import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/auth/auth_error.dart';
import '../../core/auth/auth_messages.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'auth_page_scaffold.dart';
import 'auth_validators.dart';

/// The signed-in account changes its own password — `PUT /api/me/password`.
///
/// The account is the session's: the request carries the current password and
/// the new one, never an id. The backend ends every other session and returns a
/// fresh token, which `AppState.changePassword` stores so this session survives.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _showCurrent = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _submitting = false;
  bool _done = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    return AuthPageScaffold(
      title: l10n.changePasswordTitle,
      heading: l10n.changePasswordTitle,
      subtitle: l10n.changePasswordSubtitle,
      icon: Icons.password_rounded,
      onBack: _submitting ? null : () => Navigator.maybePop(context),
      children: [
        if (_done) ...[
          AuthNotice(
            key: const Key('change-password-success'),
            icon: Icons.check_circle_outline_rounded,
            message: l10n.changePasswordSuccess,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            key: const Key('change-password-return'),
            onPressed: () => Navigator.maybePop(context),
            child: Text(l10n.commonBackSemantic),
          ),
        ] else ...[
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('change-password-current'),
                  controller: _current,
                  obscureText: !_showCurrent,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      AuthValidators.existingPassword(l10n, value),
                  decoration: InputDecoration(
                    labelText: l10n.changePasswordCurrentLabel,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    errorText: failure == null
                        ? null
                        : authFieldMessage(failure, AuthFields.currentPassword),
                    suffixIcon: PasswordVisibilityToggle(
                      visible: _showCurrent,
                      onChanged: (value) =>
                          setState(() => _showCurrent = value),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('change-password-new'),
                  controller: _password,
                  obscureText: !_showPassword,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  validator: (value) => AuthValidators.newPassword(l10n, value),
                  decoration: InputDecoration(
                    labelText: l10n.resetPasswordNewLabel,
                    helperText: l10n.authPasswordRequirement,
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    errorText: failure == null
                        ? null
                        : authFieldMessage(failure, AuthFields.newPassword),
                    suffixIcon: PasswordVisibilityToggle(
                      visible: _showPassword,
                      onChanged: (value) =>
                          setState(() => _showPassword = value),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('change-password-confirm'),
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
                      onChanged: (value) =>
                          setState(() => _showConfirm = value),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthNotice(
              key: const Key('change-password-error'),
              icon: Icons.error_outline_rounded,
              message: authFailureMessage(l10n, failure),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AuthSubmitButton(
            buttonKey: const Key('change-password-submit'),
            label: l10n.changePasswordAction,
            icon: Icons.check_rounded,
            busy: _submitting,
            onPressed: _submit,
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final app = AppScope.of(context);
    setState(() => _submitting = true);
    final result = await app.changePassword(
      currentPassword: _current.text,
      newPassword: _password.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      setState(() => _failure = result.failure);
      return;
    }
    _current.clear();
    _password.clear();
    _confirm.clear();
    setState(() => _done = true);
  }
}
