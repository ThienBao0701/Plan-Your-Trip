import 'package:flutter/material.dart';

import '../../app/app_surface.dart';
import '../../app/surface_gate.dart';
import '../../app/surface_scope.dart';
import '../../app/routing/surface_router.dart';
import '../../core/app_state.dart';
import '../../core/auth/auth_error.dart';
import '../../core/auth/auth_messages.dart';
import '../../core/mock/mock_data.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

/// Sign-in, shared by all three application surfaces.
///
/// The running surface ([SurfaceScope]) decides the copy and which secondary
/// actions exist: only the traveller app offers Demo Mode and self sign-up. On
/// every surface a successful sign-in returns to that surface's root, whose gate
/// admits or refuses the account — sign-in never picks a destination by role and
/// never leaves the surface.
class LoginScreen extends StatefulWidget {
  /// True when this screen is the signed-out face of a `SurfaceGate` rather
  /// than a route pushed on top of other screens. A successful sign-in then only
  /// changes the session: the gate rebuilds into the shell, or the access-denied
  /// screen, at the location that was requested, so this screen must not
  /// navigate.
  final bool embeddedInSurfaceGate;

  const LoginScreen({super.key, this.embeddedInSurfaceGate = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;
  bool showPassword = false;

  /// Set when sign-in was refused with EMAIL_NOT_VERIFIED, so the screen can
  /// offer the one action that helps: verifying that address.
  String? pendingVerificationEmail;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() => showPassword = !showPassword);
  }

  Widget _buildLoginPanel(AppSurface surface, AppLocalizations l10n) =>
      _LoginPanel(
        formKey: _formKey,
        email: email,
        pass: pass,
        loading: loading,
        showPassword: showPassword,
        title: switch (surface) {
          AppSurface.user => l10n.authLoginTitle,
          AppSurface.partner => l10n.authPartnerLoginTitle,
          AppSurface.admin => l10n.authAdminLoginTitle,
        },
        subtitle: switch (surface) {
          AppSurface.user => l10n.authLoginSubtitle,
          AppSurface.partner => l10n.authPartnerLoginSubtitle,
          AppSurface.admin => l10n.authAdminLoginSubtitle,
        },
        showRegistration: surface.offersSelfRegistration,
        onTogglePassword: _togglePasswordVisibility,
        onLogin: () => _login(demo: false),
        onDemo: surface.offersDemoMode ? () => _login(demo: true) : null,
        onForgotPassword: _openForgotPassword,
        onVerifyEmail: () => _openVerification(email.text.trim()),
        // Partner is the only surface that offers self-registration of a staff
        // account, and it creates a PARTNER account server-side.
        onBecomePartner: surface == AppSurface.partner
            ? () => SurfaceNavigation.open(context, SurfaceRouter.register)
            : null,
        pendingVerificationEmail: pendingVerificationEmail,
        validateEmail: _validateEmail,
        validatePassword: _validatePassword,
      );

  /// Opens password recovery at the surface's own `/forgot-password` when it has
  /// one, and as a plain push otherwise (the traveller settings entry point).
  void _openForgotPassword() {
    final surface = SurfaceScope.maybeOf(context);
    final router =
        surface == null ? null : SurfaceRouter.of(surface);
    if (router != null &&
        router.publicLocations.contains(SurfaceRouter.forgotPassword)) {
      SurfaceNavigation.open(context, SurfaceRouter.forgotPassword);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ForgotPasswordScreen(initialEmail: email.text.trim()),
      ),
    );
  }

  void _openVerification(String address) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: SurfaceRouter.verifyEmail),
        builder: (_) => VerifyEmailScreen(
          email: address.isEmpty ? null : address,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Presentation only: a LoginScreen mounted outside any surface app (an
    // isolated widget test) keeps the traveller copy it always had. Where a
    // sign-in leads is decided in [_login], and that fails closed.
    final surface = SurfaceScope.maybeOf(context) ?? AppSurface.user;
    final heroTitle = switch (surface) {
      AppSurface.user => l10n.authLoginHero,
      AppSurface.partner => l10n.authPartnerLoginHero,
      AppSurface.admin => l10n.authAdminLoginHero,
    };
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
                            Expanded(child: _HeroPanel(title: heroTitle)),
                            const SizedBox(width: AppSpacing.xl),
                            Expanded(child: _buildLoginPanel(surface, l10n)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroPanel(title: heroTitle),
                            const SizedBox(height: AppSpacing.lg),
                            _buildLoginPanel(surface, l10n),
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

    setState(() {
      loading = true;
      pendingVerificationEmail = null;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final home = SurfaceNavigation.home(context);
    final address = email.text.trim();
    final result = demo
        ? await app.login(MockData.demoEmail, MockData.demoPassword)
        : await app.login(address, pass.text);
    if (!mounted) return;
    setState(() => loading = false);

    if (result['success'] == true) {
      if (widget.embeddedInSurfaceGate) return;
      nav.pushReplacement(home);
      return;
    }

    // Phase A answers a refused sign-in with a stable code; it is mapped to
    // localized copy centrally, and only falls back to the server's own text.
    final failure = result['failure'];
    final message = failure is AuthFailure
        ? authSignInFailureMessage(l10n, failure)
        : result['message'] as String? ?? l10n.authLoginFailed;
    if (failure is AuthFailure &&
        failure.code == AuthErrorCode.emailNotVerified &&
        !demo) {
      setState(() => pendingVerificationEmail = address);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
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
  final String title;
  final String subtitle;
  final bool showRegistration;
  final VoidCallback onTogglePassword;
  final VoidCallback onLogin;

  /// Null on a surface without Demo Mode, which removes the demo action.
  final VoidCallback? onDemo;

  final VoidCallback onForgotPassword;
  final VoidCallback onVerifyEmail;

  /// Null on every surface but Partner, which is the only one whose sign-in
  /// offers creating a staff account.
  final VoidCallback? onBecomePartner;

  /// Set after a sign-in refused with EMAIL_NOT_VERIFIED: the address to verify.
  final String? pendingVerificationEmail;

  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;

  const _LoginPanel({
    required this.formKey,
    required this.email,
    required this.pass,
    required this.loading,
    required this.showPassword,
    required this.title,
    required this.subtitle,
    required this.showRegistration,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onDemo,
    required this.onForgotPassword,
    required this.onVerifyEmail,
    required this.onBecomePartner,
    required this.pendingVerificationEmail,
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
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
                key: const Key('login-forgot-password'),
                onPressed: loading ? null : onForgotPassword,
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
            if (onDemo != null) ...[
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
            ] else
              Text(
                l10n.authStaffAccountRequired,
                key: const Key('login-account-required'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            if (pendingVerificationEmail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              OceanSecondaryButton(
                key: const Key('login-verify-email'),
                label: l10n.authVerifyEmailAction,
                icon: Icons.mark_email_read_outlined,
                onPressed: loading ? null : onVerifyEmail,
              ),
            ],
            if (showRegistration) ...[
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
                key: const Key('login-verify-email-entry'),
                onPressed: loading ? null : onVerifyEmail,
                icon: const Icon(Icons.mark_email_read_outlined),
                label: Text(l10n.authVerifyEmailAction),
              ),
            ],
            if (onBecomePartner != null) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.authPartnerBecomeQuestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    key: const Key('login-become-partner'),
                    onPressed: loading ? null : onBecomePartner,
                    child: Text(l10n.authPartnerBecomeAction),
                  ),
                ],
              ),
            ],
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
