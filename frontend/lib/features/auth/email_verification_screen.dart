import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';

typedef EmailCodeVerify = Future<bool> Function(String code);
typedef EmailCodeResend = Future<bool> Function();

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final EmailCodeVerify? onVerify;
  final EmailCodeResend? onResend;
  final Duration initialCountdown;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.onVerify,
    this.onResend,
    this.initialCountdown = const Duration(seconds: 45),
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  late int countdown = widget.initialCountdown.inSeconds;
  late final List<TextEditingController> controllers =
      List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> nodes = List.generate(6, (_) => FocusNode());
  Timer? timer;
  bool loading = false;
  bool resending = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    timer?.cancel();
    for (final controller in controllers) {
      controller.dispose();
    }
    for (final node in nodes) {
      node.dispose();
    }
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
        title: Text(l10n.emailVerificationTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: OceanContentConstraint(
              maxWidth: AppBreakpoints.maxContentWidth,
              child: OceanGlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 86,
                        height: 86,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.paleCyan,
                          borderRadius: BorderRadius.circular(AppRadii.sheet),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          color: AppColors.turquoise600,
                          size: AppIconSizes.xl,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.emailVerificationTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.emailVerificationSubtitle(widget.email),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          Expanded(child: _OtpDigit(index: i, state: this)),
                          if (i != 5) const SizedBox(width: AppSpacing.xs),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    loading
                        ? const Center(
                            child: SizedBox.square(
                              dimension: AppSpacing.minTouchTarget,
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : OceanPrimaryButton(
                            key: const Key('verification-submit'),
                            label: l10n.emailVerificationAction,
                            icon: Icons.verified_rounded,
                            onPressed: _verify,
                          ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: countdown == 0 && !loading && !resending
                          ? _resend
                          : null,
                      child: Text(countdown > 0
                          ? l10n.emailVerificationResendIn(countdown)
                          : l10n.emailVerificationResendAction),
                    ),
                    TextButton(
                      onPressed:
                          loading ? null : () => Navigator.maybePop(context),
                      child: Text(l10n.emailVerificationChangeEmail),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      _applyCode(value);
      return;
    }
    if (value.isNotEmpty && index < nodes.length - 1) {
      nodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      nodes[index - 1].requestFocus();
    }
  }

  void _applyCode(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '').split('');
    for (var i = 0; i < controllers.length; i++) {
      controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final next =
        digits.length >= nodes.length ? nodes.length - 1 : digits.length;
    nodes[next].requestFocus();
  }

  void _startCountdown() {
    timer?.cancel();
    if (countdown <= 0) return;
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (countdown <= 1) {
        timer?.cancel();
        timer = null;
        setState(() => countdown = 0);
        return;
      }
      setState(() => countdown--);
    });
  }

  Future<void> _verify() async {
    if (loading) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final code = controllers.map((controller) => controller.text).join();
    if (code.length != 6) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.emailVerificationIncomplete)),
      );
      return;
    }
    if (widget.onVerify == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authUnsupportedVerification)),
      );
      return;
    }
    setState(() => loading = true);
    final supported = await widget.onVerify!(code);
    if (!mounted) return;
    setState(() => loading = false);
    if (!supported) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authUnsupportedVerification)),
      );
    }
  }

  Future<void> _resend() async {
    if (resending) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (widget.onResend == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authUnsupportedResend)),
      );
      return;
    }
    setState(() => resending = true);
    final supported = await widget.onResend!();
    if (!mounted) return;
    setState(() => resending = false);
    if (!supported) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authUnsupportedResend)),
      );
      return;
    }
    setState(() => countdown = widget.initialCountdown.inSeconds);
    _startCountdown();
  }
}

class _OtpDigit extends StatelessWidget {
  final int index;
  final _EmailVerificationScreenState state;

  const _OtpDigit({required this.index, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      textField: true,
      label: l10n.emailVerificationDigitSemantic(index + 1),
      child: TextField(
        key: Key('otp-$index'),
        controller: state.controllers[index],
        focusNode: state.nodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        textInputAction:
            index == 5 ? TextInputAction.done : TextInputAction.next,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: Theme.of(context).textTheme.headlineMedium,
        decoration: const InputDecoration(counterText: ''),
        onChanged: (value) => state._onDigitChanged(index, value),
      ),
    );
  }
}
