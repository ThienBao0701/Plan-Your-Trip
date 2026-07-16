import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.authRegisterAction),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: OceanContentConstraint(
              child: OceanGlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color:
                                AppColors.turquoise500.withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(AppRadii.xxl),
                          ),
                          child: const Icon(
                            Icons.flight_takeoff_rounded,
                            color: AppColors.turquoise600,
                            size: AppIconSizes.lg,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.authRegisterTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.authRegisterSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        key: const Key('register-name-field'),
                        controller: name,
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                        decoration: InputDecoration(
                          labelText: l10n.authFullNameLabel,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('register-email-field'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                        decoration: InputDecoration(
                          labelText: l10n.authEmailLabel,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('register-password-field'),
                        controller: pass,
                        obscureText: !showPassword,
                        textInputAction: TextInputAction.next,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          labelText: l10n.authPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: _PasswordToggle(
                            label: showPassword
                                ? l10n.authHidePassword
                                : l10n.authShowPassword,
                            visible: showPassword,
                            onPressed: () => setState(
                              () => showPassword = !showPassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        key: const Key('register-confirm-field'),
                        controller: confirm,
                        obscureText: !showConfirmPassword,
                        textInputAction: TextInputAction.done,
                        validator: _validateConfirmPassword,
                        onFieldSubmitted: (_) => _register(),
                        decoration: InputDecoration(
                          labelText: l10n.authConfirmPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_reset_rounded),
                          suffixIcon: _PasswordToggle(
                            label: showConfirmPassword
                                ? l10n.authHideConfirmPassword
                                : l10n.authShowConfirmPassword,
                            visible: showConfirmPassword,
                            onPressed: () => setState(
                              () => showConfirmPassword = !showConfirmPassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              color: AppColors.ocean, size: AppIconSizes.sm),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              l10n.authPasswordRequirement,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      loading
                          ? const Center(
                              child: SizedBox.square(
                                dimension: AppSpacing.minTouchTarget,
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : OceanPrimaryButton(
                              key: const Key('register-submit'),
                              label: l10n.authRegisterAction,
                              icon: Icons.person_add_alt_1_rounded,
                              onPressed: _register,
                            ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(child: Text(l10n.authAlreadyHaveAccount)),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => Navigator.maybePop(context),
                            child: Text(l10n.authLoginAction),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.authTermsNote,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    setState(() => loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final result =
        await app.register(name.text.trim(), email.text.trim(), pass.text);
    if (!mounted) return;
    setState(() => loading = false);

    if (result['success'] == true) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authRegistrationComplete)),
      );
      nav.pop();
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content:
            Text(result['message'] as String? ?? l10n.authRegistrationFailed),
      ),
    );
  }

  String? _validateName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if ((value ?? '').trim().length < 2) return l10n.authValidationName;
    return null;
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final address = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      return l10n.authValidationEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if ((value ?? '').length < 8) return l10n.authValidationPasswordMin;
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if ((value ?? '').isEmpty) return l10n.authValidationConfirmPassword;
    if (value != pass.text) return l10n.authValidationPasswordMismatch;
    return null;
  }
}

class _PasswordToggle extends StatelessWidget {
  final String label;
  final bool visible;
  final VoidCallback onPressed;

  const _PasswordToggle({
    required this.label,
    required this.visible,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(
            visible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          ),
        ),
      );
}
