import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../home/app_shell.dart';
import 'email_verification_screen.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => showPassword = !showPassword);
  }

  Widget _buildLoginPanel() => _LoginPanel(
        formKey: _formKey,
        email: email,
        pass: pass,
        loading: loading,
        showPassword: showPassword,
        onTogglePassword: _togglePasswordVisibility,
        onLogin: () => _login(demo: false),
        onDemo: () => _login(demo: true),
        validateEmail: _validateEmail,
        validatePassword: _validatePassword,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BubbleBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: OceanContentConstraint(
                  maxWidth: wide ? 1040 : AppBreakpoints.maxContentWidth,
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: _HeroPanel(title: l10n.authLoginHero)),
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(child: _buildLoginPanel()),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroPanel(title: l10n.authLoginHero),
                            const SizedBox(height: AppSpacing.lg),
                            _buildLoginPanel(),
                          ],
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _login({required bool demo}) async {
    if (loading) return;
    final l10n = AppLocalizations.of(context)!;
    final app = AppScope.of(context);
    if (!demo && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => loading = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final result = demo
        ? await app.login(MockData.demoEmail, MockData.demoPassword)
        : await app.login(email.text.trim(), pass.text);
    if (!mounted) return;
    setState(() => loading = false);

    if (result['success'] == true) {
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(result['message'] as String? ?? l10n.authLoginFailed),
      ),
    );
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
    if ((value ?? '').isEmpty) return l10n.authValidationPasswordRequired;
    return null;
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;

  const _HeroPanel({required this.title});

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.ocean.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: const Icon(
                Icons.explore_rounded,
                color: AppColors.ocean,
                size: AppIconSizes.lg,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              AppLocalizations.of(context)!.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      );
}

class _LoginPanel extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController pass;
  final bool loading;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;
  final VoidCallback onDemo;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  const _LoginPanel({
    required this.formKey,
    required this.email,
    required this.pass,
    required this.loading,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onDemo,
    required this.validateEmail,
    required this.validatePassword,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.authLoginTitle,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.authLoginSubtitle,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('login-email-field'),
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: validateEmail,
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                prefixIcon: const Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('login-password-field'),
              controller: pass,
              obscureText: !showPassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              validator: validatePassword,
              onFieldSubmitted: (_) => onLogin(),
              decoration: InputDecoration(
                labelText: l10n.authPasswordLabel,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: Semantics(
                  button: true,
                  label: showPassword
                      ? l10n.authHidePassword
                      : l10n.authShowPassword,
                  child: IconButton(
                    tooltip: showPassword
                        ? l10n.authHidePassword
                        : l10n.authShowPassword,
                    icon: Icon(
                      showPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: loading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ForgotPasswordScreen(
                              initialEmail: email.text.trim(),
                            ),
                          ),
                        ),
                child: Text(l10n.authForgotPasswordAction),
              ),
            ),
            loading
                ? const Center(
                    child: SizedBox.square(
                        dimension: 44, child: CircularProgressIndicator()))
                : OceanPrimaryButton(
                    key: const Key('login-submit'),
                    label: l10n.authLoginAction,
                    icon: Icons.login_rounded,
                    semanticLabel: l10n.authLoginAction,
                    onPressed: onLogin,
                  ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              key: const Key('login-demo'),
              label: l10n.authDemoAction,
              icon: Icons.science_rounded,
              onPressed: loading ? null : onDemo,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.authDemoHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.authNeedAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RegisterScreen()),
                          ),
                  child: Text(l10n.authCreateAccountAction),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: loading
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmailVerificationScreen(
                            email: email.text.trim().isEmpty
                                ? l10n.authEmailLabel
                                : email.text.trim(),
                          ),
                        ),
                      ),
              icon: const Icon(Icons.mark_email_read_outlined),
              label: Text(l10n.authVerifyEmailAction),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.authBackendHint,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
