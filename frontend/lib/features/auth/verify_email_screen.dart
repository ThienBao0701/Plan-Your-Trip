import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/routing/auth_link_token.dart';
import '../../app/routing/surface_router.dart';
import '../../app/surface_gate.dart';
import '../../core/app_state.dart';
import '../../core/auth/auth_error.dart';
import '../../core/auth/auth_messages.dart';
import '../../core/auth/auth_models.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'auth_page_scaffold.dart';
import 'auth_validators.dart';

/// Email verification — `POST /api/auth/verify-email`.
///
/// The token arrives in the link's fragment (`/verify-email#token=…`). It is read
/// once, consumed, and cleared from the address bar immediately afterwards, so it
/// is neither left in the browser's history nor carried into the next
/// navigation. It is never logged, stored or sent anywhere but that endpoint.
///
/// Locally no email is delivered: the backend logs the link. The screen says so
/// plainly and accepts a pasted token, rather than claiming a message was sent.
class VerifyEmailScreen extends StatefulWidget {
  /// The address being verified, when it is known (straight after registering).
  final String? email;

  /// True when this follows a registration on this device, which changes the
  /// copy from "verify your email" to "you are nearly done".
  final bool justRegistered;

  /// The token from the link. Defaults to reading the current URL's fragment;
  /// tests pass one explicitly.
  final String? initialToken;

  /// How long the resend action stays disabled, matching the backend's issuance
  /// cooldown (`app.auth.token-issue-cooldown`, 60 seconds by default).
  final Duration resendCooldown;

  const VerifyEmailScreen({
    super.key,
    this.email,
    this.justRegistered = false,
    this.initialToken,
    this.resendCooldown = const Duration(seconds: 60),
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _token =
      TextEditingController(text: widget.initialToken ?? AuthLinkToken.read() ?? '');

  /// Only used when the screen was opened from a link, so no address is known:
  /// resending needs one, and the backend's answer is the same for every address.
  late final TextEditingController _resendEmail =
      TextEditingController(text: widget.email ?? '');

  bool _verifying = false;
  bool _resending = false;
  int _cooldown = 0;
  Timer? _timer;

  EmailVerificationOutcome? _outcome;
  AuthFailure? _failure;
  String? _resendAck;

  @override
  void initState() {
    super.initState();
    // A token that came in the URL is taken out of the address bar right away;
    // it stays only in this field until it is used.
    if (widget.initialToken == null && _token.text.isNotEmpty) {
      AuthLinkToken.clear(SurfaceRouter.verifyEmail);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _token.dispose();
    _resendEmail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final outcome = _outcome;
    if (outcome != null) return _verifiedView(l10n, outcome);

    final failure = _failure;
    final email = widget.email;
    return AuthPageScaffold(
      title: l10n.verifyEmailTitle,
      heading: l10n.verifyEmailTitle,
      subtitle: email == null ? null : l10n.verifyEmailSubtitle(email),
      icon: Icons.mark_email_unread_outlined,
      onBack: _busy ? null : () => SurfaceNavigation.goHome(context),
      children: [
        AuthNotice(
          key: const Key('verify-email-delivery-notice'),
          message: l10n.verifyEmailNoDeliveryNotice,
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: _formKey,
          child: TextFormField(
            key: const Key('verify-email-token'),
            controller: _token,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthValidators.linkToken(l10n, value),
            onFieldSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: l10n.verifyEmailTokenLabel,
              prefixIcon: const Icon(Icons.vpn_key_outlined),
            ),
          ),
        ),
        if (failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthNotice(
            key: const Key('verify-email-error'),
            icon: Icons.error_outline_rounded,
            message: authFailureMessage(l10n, failure),
          ),
        ],
        if (widget.email == null) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: const Key('verify-email-address'),
            controller: _resendEmail,
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.authEmailLabel,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
            ),
          ),
        ],
        if (_resendAck != null) ...[
          const SizedBox(height: AppSpacing.md),
          AuthNotice(
            key: const Key('verify-email-resend-ack'),
            icon: Icons.outgoing_mail,
            message: _resendAck!,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AuthSubmitButton(
          buttonKey: const Key('verify-email-submit'),
          label: l10n.verifyEmailAction,
          icon: Icons.verified_outlined,
          busy: _verifying,
          onPressed: _verify,
        ),
        const SizedBox(height: AppSpacing.sm),
        OceanSecondaryButton(
          key: const Key('verify-email-resend'),
          label: l10n.verifyEmailResendAction,
          icon: Icons.refresh_rounded,
          onPressed: _canResend ? _resend : null,
        ),
        if (_cooldown > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.verifyEmailResendCooldown(_cooldown),
            key: const Key('verify-email-cooldown'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          key: const Key('verify-email-back'),
          onPressed: _busy ? null : () => SurfaceNavigation.goHome(context),
          child: Text(l10n.verifyEmailBackAction),
        ),
      ],
    );
  }

  Widget _verifiedView(AppLocalizations l10n, EmailVerificationOutcome outcome) {
    final alreadyVerified = outcome == EmailVerificationOutcome.alreadyVerified;
    return AuthPageScaffold(
      title: l10n.verifyEmailTitle,
      heading: alreadyVerified
          ? l10n.verifyEmailAlreadyTitle
          : l10n.verifyEmailSuccessTitle,
      subtitle: alreadyVerified
          ? l10n.verifyEmailAlreadyBody
          : l10n.verifyEmailSuccessBody,
      icon: Icons.verified_rounded,
      children: [
        OceanPrimaryButton(
          key: const Key('verify-email-continue'),
          label: l10n.verifyEmailContinueAction,
          icon: Icons.login_rounded,
          semanticLabel: l10n.verifyEmailContinueAction,
          onPressed: () => SurfaceNavigation.goHome(context),
        ),
      ],
    );
  }

  bool get _busy => _verifying || _resending;

  /// The address a resend would use: the one this screen was opened for, or the
  /// one typed when it was opened from a link.
  String get _addressForResend =>
      (widget.email ?? _resendEmail.text).trim();

  bool get _canResend =>
      !_busy && _cooldown == 0 && _addressForResend.isNotEmpty;

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _failure = null;
      _resendAck = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final api = AppScope.of(context).api;
    setState(() => _verifying = true);
    final result = await api.verifyEmail(_token.text.trim());
    if (!mounted) return;
    setState(() => _verifying = false);

    final record = result.data;
    if (!result.success || record == null) {
      setState(() => _failure = result.failure);
      return;
    }
    // Consumed: the token is of no further use and is dropped from the field.
    _token.clear();
    AuthLinkToken.clear(SurfaceRouter.verifyEmail);
    setState(() => _outcome = record.outcome);
  }

  /// Asks for a new link. The backend answers the same way for every address, so
  /// the acknowledgement here says nothing about whether the account exists.
  Future<void> _resend() async {
    final email = _addressForResend;
    if (_busy || email.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _resending = true;
      _failure = null;
      _resendAck = null;
    });
    final result = await AppScope.of(context).api.resendVerification(email);
    if (!mounted) return;
    setState(() => _resending = false);

    if (!result.success) {
      setState(() => _failure = result.failure);
      return;
    }
    setState(() => _resendAck = l10n.verifyEmailResendAck);
    _startCooldown();
  }

  /// Keeps the client from asking again before the backend would issue anything.
  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = widget.resendCooldown.inSeconds);
    if (_cooldown == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown = _cooldown > 0 ? _cooldown - 1 : 0);
      if (_cooldown == 0) timer.cancel();
    });
  }
}
