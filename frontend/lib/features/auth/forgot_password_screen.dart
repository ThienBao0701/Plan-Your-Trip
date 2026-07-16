import 'package:flutter/material.dart';

import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';

typedef ForgotPasswordSubmit = Future<bool> Function(String email);

class ForgotPasswordScreen extends StatefulWidget {
  final String initialEmail;
  final ForgotPasswordSubmit? onSubmit;

  const ForgotPasswordScreen({
    super.key,
    this.initialEmail = '',
    this.onSubmit,
  });

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController email =
      TextEditingController(text: widget.initialEmail);
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
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
        title: Text(l10n.forgotPasswordTitle),
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
              maxWidth: AppBreakpoints.maxContentWidth,
              child: OceanGlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.paleCyan,
                          borderRadius: BorderRadius.circular(AppRadii.xxl),
                        ),
                        child: const Icon(
                          Icons.key_rounded,
                          color: AppColors.ocean,
                          size: AppIconSizes.lg,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.forgotPasswordTitle,
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.xs),
                      Text(l10n.forgotPasswordSubtitle,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        key: const Key('forgot-email-field'),
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        validator: _validateEmail,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: l10n.authEmailLabel,
                          prefixIcon: const Icon(Icons.mail_outline_rounded),
                        ),
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
                              key: const Key('forgot-submit'),
                              label: l10n.forgotPasswordSendAction,
                              icon: Icons.send_rounded,
                              onPressed: _submit,
                            ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton.icon(
                        onPressed:
                            loading ? null : () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        label: Text(l10n.forgotPasswordReturnAction),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppColors.textTertiary,
                              size: AppIconSizes.sm),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              l10n.forgotPasswordInfo,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
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

  Future<void> _submit() async {
    if (loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (widget.onSubmit == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authUnsupportedForgotPassword)),
      );
      return;
    }
    setState(() => loading = true);
    final supported = await widget.onSubmit!(email.text.trim());
    if (!mounted) return;
    setState(() => loading = false);
    if (!supported) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.authUnsupportedForgotPassword)),
      );
    }
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    final address = value?.trim() ?? '';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      return l10n.authValidationEmail;
    }
    return null;
  }
}
