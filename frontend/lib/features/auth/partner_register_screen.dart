import 'package:flutter/material.dart';

import '../../app/routing/surface_router.dart';
import '../../app/surface_gate.dart';
import '../../core/app_state.dart';
import '../../core/auth/auth_error.dart';
import '../../core/auth/auth_messages.dart';
import '../../core/auth/auth_models.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'auth_page_scaffold.dart';
import 'auth_validators.dart';
import 'verify_email_screen.dart';

/// Partner self-registration — `POST /api/auth/partner/register`.
///
/// The backend decides the role: nothing here sends one, and the response
/// carries no session, because a self-registered Partner cannot sign in until it
/// has verified its email. On success this screen hands over to
/// [VerifyEmailScreen] for that address.
///
/// Terms acceptance is explicit and must be ticked; the *version* accepted is
/// recorded server-side from its own configuration, so no version string is
/// hard-coded here.
class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _submitting = false;

  /// The last refusal, kept so the form can mark the fields the server named.
  /// The typed values stay exactly as entered.
  AuthFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final failure = _failure;
    return AuthPageScaffold(
      title: l10n.authPartnerBecomeAction,
      heading: l10n.partnerRegisterTitle,
      subtitle: l10n.partnerRegisterSubtitle,
      icon: Icons.storefront_rounded,
      onBack: _submitting ? null : () => SurfaceNavigation.goHome(context),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('partner-register-name'),
                controller: _name,
                textInputAction: TextInputAction.next,
                validator: (value) => AuthValidators.fullName(l10n, value),
                decoration: InputDecoration(
                  labelText: l10n.authFullNameLabel,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  errorText: _serverError(AuthFields.fullName),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('partner-register-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: (value) => AuthValidators.email(l10n, value),
                decoration: InputDecoration(
                  labelText: l10n.authEmailLabel,
                  prefixIcon: const Icon(Icons.mail_outline_rounded),
                  errorText: _serverError(AuthFields.email),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('partner-register-password'),
                controller: _password,
                obscureText: !_showPassword,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: (value) => AuthValidators.newPassword(l10n, value),
                decoration: InputDecoration(
                  labelText: l10n.authPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  helperText: l10n.authPasswordRequirement,
                  errorText: _serverError(AuthFields.password),
                  suffixIcon: PasswordVisibilityToggle(
                    visible: _showPassword,
                    onChanged: (value) => setState(() => _showPassword = value),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const Key('partner-register-confirm'),
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
              const SizedBox(height: AppSpacing.sm),
              FormField<bool>(
                initialValue: _acceptTerms,
                validator: (_) => _acceptTerms
                    ? null
                    : l10n.authValidationTermsRequired,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A plain Checkbox rather than a CheckboxListTile: the card
                    // this form sits in paints its own background, which would
                    // hide a ListTile's ink.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          key: const Key('partner-register-terms'),
                          value: _acceptTerms,
                          onChanged: _submitting
                              ? null
                              : (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                  field.didChange(_acceptTerms);
                                },
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l10n.partnerRegisterTerms,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                l10n.partnerRegisterTermsHint,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: Text(
                          field.errorText!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthNotice(
            key: const Key('partner-register-error'),
            icon: Icons.error_outline_rounded,
            message: authFailureMessage(l10n, failure),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AuthSubmitButton(
          buttonKey: const Key('partner-register-submit'),
          label: l10n.partnerRegisterAction,
          icon: Icons.how_to_reg_rounded,
          busy: _submitting,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.partnerRegisterHaveAccount,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            TextButton(
              key: const Key('partner-register-signin'),
              onPressed:
                  _submitting ? null : () => SurfaceNavigation.goHome(context),
              child: Text(l10n.partnerRegisterSignInAction),
            ),
          ],
        ),
      ],
    );
  }

  /// The reason the backend gave for one field, shown on that field. English
  /// only — the localized summary is shown alongside it.
  String? _serverError(String field) {
    final failure = _failure;
    return failure == null ? null : authFieldMessage(failure, field);
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _failure = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final app = AppScope.of(context);
    final email = _email.text.trim();
    setState(() => _submitting = true);
    final result = await app.api.registerPartner(
      fullName: _name.text,
      email: email,
      password: _password.text,
      acceptTerms: _acceptTerms,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    final registration = result.data;
    if (!result.success || registration == null) {
      setState(() => _failure = result.failure);
      return;
    }
    _openVerification(registration);
  }

  void _openVerification(PartnerRegistrationRecord registration) {
    SurfaceRouter.reportLocation(SurfaceRouter.verifyEmail);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: SurfaceRouter.verifyEmail),
        builder: (_) => VerifyEmailScreen(
          email: registration.email,
          justRegistered: true,
        ),
      ),
    );
  }
}
