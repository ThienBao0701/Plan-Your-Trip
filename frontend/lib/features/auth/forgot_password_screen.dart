import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/auth/auth_error.dart';
import '../../core/auth/auth_messages.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'auth_page_scaffold.dart';
import 'auth_validators.dart';

/// Password recovery — `POST /api/auth/forgot-password`.
///
/// Shared by all three surfaces: the backend picks the reset link's destination
/// from the account's own role, so this screen only asks for an address.
///
/// **Generic by contract.** The backend answers the same 202 whether or not the
/// address has an account, and issues at most one link per cooldown. This screen
/// shows that same acknowledgement without ever saying whether an account exists
/// — the only distinguishable outcome is 503, which is decided before any
/// address is looked up.
class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email =
      TextEditingController(text: widget.initialEmail);

  bool _submitting = false;
  bool _acknowledged = false;
  AuthFailure? _failure;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    return AuthPageScaffold(
      title: l10n.forgotPasswordTitle,
      heading: l10n.forgotPasswordTitle,
      subtitle: l10n.forgotPasswordSubtitle,
      icon: Icons.key_rounded,
      onBack: _submitting ? null : () => Navigator.maybePop(context),
      children: [
        if (_acknowledged) ...[
          AuthNotice(
            key: const Key('forgot-ack'),
            icon: Icons.outgoing_mail,
            message: l10n.forgotPasswordAck,
          ),
          const SizedBox(height: AppSpacing.md),
          AuthNotice(
            key: const Key('forgot-delivery-notice'),
            message: l10n.forgotPasswordNoDeliveryNotice,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextButton(
            key: const Key('forgot-return'),
            onPressed: () => Navigator.maybePop(context),
            child: Text(l10n.forgotPasswordReturnAction),
          ),
        ] else ...[
          Form(
            key: _formKey,
            child: TextFormField(
              key: const Key('forgot-email-field'),
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.done,
              validator: (value) => AuthValidators.email(l10n, value),
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
            ),
          ),
          if (failure != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthNotice(
              key: const Key('forgot-error'),
              icon: Icons.error_outline_rounded,
              message: authFailureMessage(l10n, failure),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AuthSubmitButton(
            buttonKey: const Key('forgot-submit'),
            label: l10n.forgotPasswordSendAction,
            icon: Icons.send_rounded,
            busy: _submitting,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.forgotPasswordInfo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final api = AppScope.of(context).api;
    setState(() => _submitting = true);
    final result = await api.requestPasswordReset(_email.text.trim());
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      setState(() => _failure = result.failure);
      return;
    }
    setState(() => _acknowledged = true);
  }
}
