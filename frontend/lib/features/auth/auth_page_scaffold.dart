import 'package:flutter/material.dart';

import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';

/// The frame every account screen shares: the Ocean Glass background, one
/// constrained glass card, and a back action when there is somewhere to go back
/// to.
///
/// It exists so registration, verification, password reset and password change
/// look like one flow instead of four screens, and so none of them re-invents
/// spacing, width or keyboard-inset handling.
class AuthPageScaffold extends StatelessWidget {
  final String title;

  /// Heading inside the card. Defaults to [title].
  final String? heading;

  final String? subtitle;

  /// Shown above the heading — a status icon for a success or error state.
  final IconData? icon;

  final List<Widget> children;

  /// Back action in the app bar. Null hides it, for a screen reached by link
  /// with nothing behind it.
  final VoidCallback? onBack;

  const AuthPageScaffold({
    super.key,
    required this.title,
    required this.children,
    this.heading,
    this.subtitle,
    this.icon,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: OceanGlassAppBar(
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: l10n.commonBackSemantic,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
        title: Text(title),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.paleCyan,
                            borderRadius: BorderRadius.circular(AppRadii.xxl),
                          ),
                          child: Icon(icon, color: AppColors.ocean, size: 34),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Text(
                      heading ?? title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short, non-alarming notice — used for the local-development "no email is
/// delivered" explanation and for generic acknowledgements.
class AuthNotice extends StatelessWidget {
  final String message;
  final IconData icon;

  const AuthNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.paleCyan.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
}

/// The submit button of an account form: one button that shows progress and
/// refuses a second tap while the first is in flight.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onPressed;
  final Key? buttonKey;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) => busy
      ? const Center(
          child: SizedBox.square(
            dimension: 44,
            child: CircularProgressIndicator(),
          ),
        )
      : OceanPrimaryButton(
          key: buttonKey,
          label: label,
          icon: icon,
          semanticLabel: label,
          onPressed: onPressed,
        );
}
