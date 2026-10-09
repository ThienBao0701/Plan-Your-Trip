import 'package:flutter/material.dart';

import '../../../core/app_state.dart';
import '../../../core/auth/auth_messages.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// RBAC R5 — the password re-confirmation of RBAC V1.1 §18 O-7 / §23 F13.
///
/// Owner-level team changes need a session issued within the last 15 minutes;
/// an older one gets 403 `STEP_UP_REQUIRED`. This dialog asks for the password,
/// calls `POST /api/me/step-up` through [AppState.stepUp] (which adopts the
/// fresh token) and returns true on success, so the caller can retry its action
/// **once**. The password lives only in this dialog's text field: it is never
/// stored, logged or shown again, and the field is cleared when the dialog
/// closes.
Future<bool> showPartnerStepUpDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _StepUpDialog(),
  );
  return confirmed ?? false;
}

class _StepUpDialog extends StatefulWidget {
  const _StepUpDialog();

  @override
  State<_StepUpDialog> createState() => _StepUpDialogState();
}

class _StepUpDialogState extends State<_StepUpDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscured = true;
  String? _error;

  @override
  void dispose() {
    _password.clear();
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    if (_password.text.isEmpty) {
      setState(() => _error = l10n.partnerStepUpPasswordRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await AppScope.of(context).stepUp(_password.text);
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _error = authFailureMessage(l10n, result.failure!);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      key: const Key('partner-step-up-dialog'),
      title: Text(l10n.partnerStepUpTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.partnerStepUpBody),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('partner-step-up-password'),
              controller: _password,
              obscureText: _obscured,
              autofillHints: const [AutofillHints.password],
              enabled: !_busy,
              onSubmitted: (_) => _confirm(),
              decoration: InputDecoration(
                labelText: l10n.partnerStepUpPasswordLabel,
                errorText: _error,
                suffixIcon: IconButton(
                  tooltip:
                      _obscured ? l10n.authShowPassword : l10n.authHidePassword,
                  icon: Icon(_obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.partnerTeamCancel),
        ),
        FilledButton(
          key: const Key('partner-step-up-confirm'),
          onPressed: _busy ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.partnerStepUpConfirm),
        ),
      ],
    );
  }
}
