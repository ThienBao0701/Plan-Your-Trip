import 'dart:ui';

import 'package:flutter/material.dart';

import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_glass.dart';
import '../../design/app_gradients.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_motion.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';

String _t(
  BuildContext context,
  String Function(AppLocalizations l10n) pick,
  String fallback,
) {
  final l10n = AppLocalizations.of(context);
  return l10n == null ? fallback : pick(l10n);
}

class BubbleBackground extends StatelessWidget {
  final Widget child;
  const BubbleBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) => const DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.page),
        child: SizedBox.expand(),
      ).withChild(child);
}

extension _DecoratedBoxChild on DecoratedBox {
  Widget withChild(Widget child) => DecoratedBox(
        decoration: decoration,
        position: position,
        child: child,
      );
}

class OceanContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const OceanContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) => Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

class OceanGlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? color;
  final Gradient? gradient;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const OceanGlassSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.xl,
    this.blur = AppGlass.blur,
    this.color,
    this.gradient = AppGradients.glassSurface,
    this.border,
    this.boxShadow,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final decorated = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.glass,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border ??
            Border.all(
              color: AppColors.glassStroke.withValues(
                alpha: AppGlass.borderOpacity,
              ),
            ),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    Widget content = ClipRRect(
      borderRadius: borderRadius,
      child: blur <= 0
          ? decorated
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: decorated,
            ),
    );

    content = RepaintBoundary(child: content);
    if (semanticLabel != null) {
      content =
          Semantics(label: semanticLabel, container: true, child: content);
    }
    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

class OceanGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const OceanGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadii.xxl,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => OceanGlassSurface(
        padding: padding,
        radius: radius,
        onTap: onTap,
        semanticLabel: semanticLabel,
        boxShadow: AppShadows.soft,
        child: child,
      );
}

class OceanPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool fullWidth;

  const OceanPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.semanticLabel,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final content = _OceanButtonContent(label: label, icon: icon);
    final button = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppGradients.oceanAction : null,
          color: enabled ? null : AppColors.disabled,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          boxShadow: enabled ? AppShadows.soft : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: content,
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

class OceanSecondaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool fullWidth;

  const OceanSecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.semanticLabel,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(
            color: enabled ? AppColors.ocean : AppColors.disabled,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: _OceanButtonContent(
                label: label,
                icon: icon,
                color: enabled ? AppColors.ocean : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: ExcludeSemantics(
        child: fullWidth
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

class _OceanButtonContent extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _OceanButtonContent({
    required this.label,
    this.icon,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: AppIconSizes.sm),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      );
}

class OceanStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final String? semanticLabel;

  const OceanStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.ocean,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: semanticLabel ?? label,
        container: true,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: AppIconSizes.xs),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class OceanSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String? semanticLabel;

  const OceanSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        textField: true,
        label: semanticLabel ??
            _t(context, (l10n) => l10n.searchFieldSemanticLabel, 'Search'),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).deleteButtonTooltip,
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_rounded),
                  ),
          ),
        ),
      );
}

class OceanGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final Widget? leading;

  const OceanGlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) => AppBar(
        title: title,
        leading: leading,
        actions: actions,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppGlass.lightBlur,
              sigmaY: AppGlass.lightBlur,
            ),
            child: Container(color: AppColors.glassSubtle),
          ),
        ),
      );
}

class OceanGlassBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const OceanGlassBottomSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.sm,
            right: AppSpacing.sm,
            bottom: AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: OceanGlassSurface(
            radius: AppRadii.sheet,
            padding: padding,
            boxShadow: AppShadows.medium,
            child: child,
          ),
        ),
      );
}

class OceanStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool showProgress;
  final String semanticLabel;
  final bool primaryAction;

  const OceanStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.semanticLabel,
    this.actionLabel,
    this.onAction,
    this.showProgress = false,
    this.primaryAction = true,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        liveRegion: showProgress,
        label: semanticLabel,
        child: OceanGlassCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= AppBreakpoints.tablet;
              final visual = _StateVisual(
                icon: icon,
                showProgress: showProgress,
                progressSemanticLabel: showProgress ? semanticLabel : null,
              );
              final copy = _StateCopy(
                title: title,
                message: message,
                actionLabel: actionLabel,
                onAction: onAction,
                primaryAction: primaryAction,
              );
              if (wide) {
                return Row(
                  children: [
                    visual,
                    const SizedBox(width: AppSpacing.xl),
                    Expanded(child: copy),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  visual,
                  const SizedBox(height: AppSpacing.lg),
                  copy,
                ],
              );
            },
          ),
        ),
      );
}

class _StateVisual extends StatelessWidget {
  final IconData icon;
  final bool showProgress;
  final String? progressSemanticLabel;

  const _StateVisual({
    required this.icon,
    required this.showProgress,
    this.progressSemanticLabel,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 128,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: AppColors.paleCyan,
                    borderRadius: BorderRadius.circular(AppRadii.sheet),
                  ),
                ),
                Icon(icon, size: AppIconSizes.xl, color: AppColors.ocean),
                if (showProgress)
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      semanticsLabel: progressSemanticLabel,
                    ),
                  ),
              ],
            ),
            if (showProgress) ...[
              const SizedBox(height: AppSpacing.md),
              const _SkeletonLine(width: 112),
              const SizedBox(height: AppSpacing.xs),
              const _SkeletonLine(width: 92),
            ],
          ],
        ),
      );
}

class _StateCopy extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool primaryAction;

  const _StateCopy({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.primaryAction,
  });

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            primaryAction
                ? OceanPrimaryButton(
                    label: actionLabel!,
                    icon: Icons.chevron_right_rounded,
                    onPressed: onAction,
                  )
                : OceanSecondaryButton(
                    label: actionLabel!,
                    icon: Icons.chevron_right_rounded,
                    onPressed: onAction,
                  ),
          ],
        ],
      );
}

class _SkeletonLine extends StatelessWidget {
  final double width;

  const _SkeletonLine({required this.width});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      );
}

class OceanLoadingState extends StatelessWidget {
  final String? title;
  final String? message;

  const OceanLoadingState({super.key, this.title, this.message});

  @override
  Widget build(BuildContext context) => OceanStateView(
        icon: Icons.flight_takeoff_rounded,
        title: title ?? _t(context, (l10n) => l10n.loadingTitle, 'Loading'),
        message: message ??
            _t(
              context,
              (l10n) => l10n.loadingMessage,
              'Preparing your journey...',
            ),
        showProgress: true,
        semanticLabel: _t(
          context,
          (l10n) => l10n.loadingSemanticLabel,
          'Content is loading',
        ),
      );
}

class OceanEmptyState extends StatelessWidget {
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const OceanEmptyState({
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => OceanStateView(
        icon: Icons.luggage_rounded,
        title: title ?? _t(context, (l10n) => l10n.emptyTitle, 'No data yet'),
        message: message ??
            _t(
              context,
              (l10n) => l10n.emptyMessage,
              'Content will appear here when you get started.',
            ),
        actionLabel: actionLabel,
        onAction: onAction,
        primaryAction: false,
        semanticLabel: _t(
          context,
          (l10n) => l10n.emptyStateSemanticLabel,
          'Empty state',
        ),
      );
}

class OceanOfflineState extends StatelessWidget {
  final VoidCallback onRetry;

  const OceanOfflineState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => OceanStateView(
        icon: Icons.cloud_off_rounded,
        title: _t(context, (l10n) => l10n.offlineTitle, 'You are offline'),
        message: _t(
          context,
          (l10n) => l10n.offlineMessage,
          'Check your connection and try again.',
        ),
        actionLabel: _t(context, (l10n) => l10n.offlineAction, 'Try again'),
        onAction: onRetry,
        semanticLabel: _t(
          context,
          (l10n) => l10n.offlineStateSemanticLabel,
          'Offline state',
        ),
      );
}

class OceanRecoverableErrorState extends StatelessWidget {
  final VoidCallback? onReload;
  final String? message;

  const OceanRecoverableErrorState({
    super.key,
    this.onReload,
    this.message,
  });

  @override
  Widget build(BuildContext context) => OceanStateView(
        icon: Icons.error_outline_rounded,
        title: _t(
          context,
          (l10n) => l10n.errorTitle,
          'Something went wrong',
        ),
        message: message ??
            _t(
              context,
              (l10n) => l10n.errorMessage,
              'We could not load this content.',
            ),
        actionLabel: onReload == null
            ? null
            : _t(context, (l10n) => l10n.errorAction, 'Reload'),
        onAction: onReload,
        semanticLabel: _t(
          context,
          (l10n) => l10n.errorStateSemanticLabel,
          'Recoverable error',
        ),
      );
}

class OceanSessionExpiredState extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback? onReturnHome;

  const OceanSessionExpiredState({
    super.key,
    required this.onLogin,
    this.onReturnHome,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: _t(
          context,
          (l10n) => l10n.sessionExpiredSemanticLabel,
          'Session expired',
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.disabled,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _StateVisual(
              icon: Icons.shield_outlined,
              showProgress: false,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              _t(
                context,
                (l10n) => l10n.sessionExpiredTitle,
                'Session expired',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _t(
                context,
                (l10n) => l10n.sessionExpiredMessage,
                'Sign in again to continue. Unsaved local changes are kept.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              label: _t(
                context,
                (l10n) => l10n.sessionExpiredLoginAction,
                'Log in again',
              ),
              icon: Icons.login_rounded,
              onPressed: onLogin,
            ),
            if (onReturnHome != null) ...[
              const SizedBox(height: AppSpacing.xs),
              OceanSecondaryButton(
                label: _t(
                  context,
                  (l10n) => l10n.sessionExpiredHomeAction,
                  'Return home',
                ),
                icon: Icons.home_rounded,
                onPressed: onReturnHome,
              ),
            ],
          ],
        ),
      );
}

Future<T?> showOceanSessionExpiredSheet<T>(
  BuildContext context, {
  required VoidCallback onLogin,
  VoidCallback? onReturnHome,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => OceanGlassBottomSheet(
      child: OceanSessionExpiredState(
        onLogin: onLogin,
        onReturnHome: onReturnHome,
      ),
    ),
  );
}

class OceanNavigationDestination {
  final String label;
  final String semanticLabel;
  final IconData icon;
  final IconData selectedIcon;

  const OceanNavigationDestination({
    required this.label,
    required this.semanticLabel,
    required this.icon,
    required this.selectedIcon,
  });
}

class OceanBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final List<OceanNavigationDestination> destinations;
  final ValueChanged<int>? onTap;

  const OceanBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.destinations,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      container: true,
      label: _t(
        context,
        (l10n) => l10n.bottomNavigationSemantic,
        'Primary navigation',
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,
          boxShadow: AppShadows.nav,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.sm,
              AppSpacing.xs,
            ),
            child: OceanContentConstraint(
              maxWidth: AppBreakpoints.maxContentWidth,
              child: OceanGlassSurface(
                blur: AppGlass.lightBlur,
                radius: AppRadii.sheet,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                boxShadow: AppShadows.soft,
                child: Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _OceanNavigationItem(
                          destination: destinations[i],
                          selected: i == currentIndex,
                          reduceMotion: reduceMotion,
                          onTap: () => onTap?.call(i),
                        ),
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
}

class _OceanNavigationItem extends StatelessWidget {
  final OceanNavigationDestination destination;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback? onTap;

  const _OceanNavigationItem({
    required this.destination,
    required this.selected,
    required this.reduceMotion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: destination.semanticLabel,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              onTap: onTap,
              child: AnimatedContainer(
                duration: reduceMotion ? Duration.zero : AppMotion.fast,
                curve: AppMotion.curve,
                constraints: const BoxConstraints(
                  minHeight: AppSpacing.minTouchTarget,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xxs,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.ocean.withValues(alpha: .10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      selected ? destination.selectedIcon : destination.icon,
                      color:
                          selected ? AppColors.ocean : AppColors.textSecondary,
                      size: AppIconSizes.md,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Flexible(
                      child: Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? AppColors.ocean
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// Legacy FE-1 wrappers. New UI-1 code should use the Ocean* classes above.

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        padding: padding,
        radius: radius,
        onTap: onTap,
        child: child,
      );
}

class GlassButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;

  const GlassButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OceanPrimaryButton(
        label: text,
        icon: icon ?? Icons.auto_awesome_rounded,
        onPressed: onPressed,
      );
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: AppColors.surfaceOverlay,
        ),
      );
}

class GlassSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onTap;

  const GlassSearchBar({super.key, required this.hint, this.onTap});

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        radius: AppRadii.xl,
        onTap: onTap,
        semanticLabel: _t(
          context,
          (l10n) => l10n.searchFieldSemanticLabel,
          'Search',
        ),
        child: Row(children: [
          const Icon(Icons.search_rounded, color: AppColors.ocean),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(hint, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const Icon(Icons.tune_rounded, color: AppColors.slate),
        ]),
      );
}

class PremiumLoading extends StatelessWidget {
  const PremiumLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(width: 280, child: OceanLoadingState()),
      );
}

class PremiumErrorState extends StatelessWidget {
  final String message;

  const PremiumErrorState(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 360,
          child: OceanRecoverableErrorState(message: message),
        ),
      );
}

class PremiumEmptyState extends StatelessWidget {
  final String message;

  const PremiumEmptyState(this.message, {super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: SizedBox(
          width: 360,
          child: OceanEmptyState(message: message),
        ),
      );
}

class PremiumScaffold extends StatelessWidget {
  final Widget body;
  final int index;
  final ValueChanged<int>? onNav;

  const PremiumScaffold({
    super.key,
    required this.body,
    this.index = 0,
    this.onNav,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        body: BubbleBackground(child: SafeArea(child: body)),
        bottomNavigationBar:
            GlassBottomNavigationBar(currentIndex: index, onTap: onNav),
      );
}

class GlassBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const GlassBottomNavigationBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => OceanBottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        destinations: const [
          OceanNavigationDestination(
            label: 'Home',
            semanticLabel: 'Home tab',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
          ),
          OceanNavigationDestination(
            label: 'Places',
            semanticLabel: 'Places tab',
            icon: Icons.place_outlined,
            selectedIcon: Icons.place_rounded,
          ),
          OceanNavigationDestination(
            label: 'Trips',
            semanticLabel: 'Trips tab',
            icon: Icons.map_outlined,
            selectedIcon: Icons.map_rounded,
          ),
          OceanNavigationDestination(
            label: 'Budget',
            semanticLabel: 'Budget tab',
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
          ),
          OceanNavigationDestination(
            label: 'Profile',
            semanticLabel: 'Profile tab',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
        ],
      );
}
