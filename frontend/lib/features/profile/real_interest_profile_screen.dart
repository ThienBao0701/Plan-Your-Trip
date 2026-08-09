import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/enum_labels.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI52 — Real Mode Interest Profile (`GET /api/me/interests`). A read-only,
/// backend-derived aggregation of the customer's travel interests (styles,
/// weather, budget, crowd, accessibility, favorite provinces/categories/tags)
/// with a single safe [AppState.recalculateRealInterestProfile] action that
/// re-derives it from the user's own bookings/wishlist/collections/reviews.
/// There is no per-dimension editing (the backend derives; it does not accept
/// manual overrides), so none is shown.
class RealInterestProfileScreen extends StatelessWidget {
  const RealInterestProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const _RealInterestProfileView();
}

class _RealInterestProfileView extends StatefulWidget {
  const _RealInterestProfileView();

  @override
  State<_RealInterestProfileView> createState() =>
      _RealInterestProfileViewState();
}

class _RealInterestProfileViewState extends State<_RealInterestProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealInterestProfile();
    });
  }

  Future<void> _recalculate() async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.recalculateRealInterestProfile();
    if (!mounted) return;
    if (outcome == InterestProfileOutcome.busy ||
        outcome == InterestProfileOutcome.demoUnavailable) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          outcome == InterestProfileOutcome.success
              ? l10n.interestRealRecalculatedMessage
              : l10n.interestRealRecalculateErrorMessage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.interestRealTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realInterestError == InterestProfileOutcome.sessionExpired &&
        !app.realInterestLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('interest-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realInterestLoading && !app.realInterestLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.interestRealLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('interest-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.interestRealLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realInterestError != null && !app.realInterestLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('interest-error'),
          message: app.realInterestError == InterestProfileOutcome.forbidden
              ? l10n.interestRealForbiddenMessage
              : app.realInterestError == InterestProfileOutcome.notFound
                  ? l10n.interestRealGoneMessage
                  : app.realInterestError == InterestProfileOutcome.network
                      ? l10n.interestRealNetworkMessage
                      : l10n.interestRealErrorMessage,
          onReload: () => app.loadRealInterestProfile(refresh: true),
        ),
      );
    }
    final profile = app.realInterestProfile ?? const RealInterestProfile();
    final recalculating = app.realInterestRecalculating;
    return RefreshIndicator(
      onRefresh: () => app.loadRealInterestProfile(refresh: true),
      child: ListView(
        key: const Key('interest-content'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (recalculating)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Semantics(
                      liveRegion: true,
                      label: l10n.interestRealRecalculateSemantic,
                      child: const Center(
                        child: SizedBox(
                          key: Key('interest-recalculating'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        ),
                      ),
                    ),
                  ),
                if (profile.isEmpty)
                  OceanEmptyState(
                    key: const Key('interest-empty'),
                    title: l10n.interestRealEmptyTitle,
                    message: l10n.interestRealEmptyMessage,
                    actionLabel: recalculating
                        ? null
                        : l10n.interestRealRecalculateAction,
                    onAction: recalculating ? null : _recalculate,
                  )
                else ...[
                  _MetaFooter(profile: profile),
                  const SizedBox(height: AppSpacing.md),
                  _EnumSection(
                    key: const Key('interest-section-travel-styles'),
                    icon: Icons.hiking_rounded,
                    title: l10n.interestRealTravelStyles,
                    tokens: profile.preferredTravelStyles,
                    labeller: travelStyleLabel,
                    color: AppColors.ocean,
                  ),
                  _EnumSection(
                    key: const Key('interest-section-weather'),
                    icon: Icons.wb_sunny_rounded,
                    title: l10n.interestRealWeather,
                    tokens: profile.preferredWeatherTypes,
                    labeller: weatherTypeLabel,
                    color: AppColors.turquoise600,
                  ),
                  _EnumSection(
                    key: const Key('interest-section-budget'),
                    icon: Icons.savings_rounded,
                    title: l10n.interestRealBudget,
                    tokens: profile.preferredBudgetLevel == null
                        ? const []
                        : [profile.preferredBudgetLevel!],
                    labeller: budgetLevelLabel,
                    color: AppColors.success,
                  ),
                  _EnumSection(
                    key: const Key('interest-section-crowd'),
                    icon: Icons.groups_rounded,
                    title: l10n.interestRealCrowd,
                    tokens: profile.preferredCrowdLevel == null
                        ? const []
                        : [profile.preferredCrowdLevel!],
                    labeller: crowdLevelLabel,
                    color: AppColors.slate,
                  ),
                  _EnumSection(
                    key: const Key('interest-section-accessibility'),
                    icon: Icons.accessible_rounded,
                    title: l10n.interestRealAccessibility,
                    tokens: profile.preferredAccessibilityLevel == null
                        ? const []
                        : [profile.preferredAccessibilityLevel!],
                    labeller: accessibilityLevelLabel,
                    color: AppColors.coral,
                  ),
                  _StringSection(
                    key: const Key('interest-section-provinces'),
                    icon: Icons.place_rounded,
                    title: l10n.interestRealProvinces,
                    values: profile.favoriteProvinces,
                    color: AppColors.ocean,
                  ),
                  _StringSection(
                    key: const Key('interest-section-categories'),
                    icon: Icons.category_rounded,
                    title: l10n.interestRealCategories,
                    values: profile.favoriteCategories,
                    color: AppColors.turquoise600,
                  ),
                  _StringSection(
                    key: const Key('interest-section-tags'),
                    icon: Icons.sell_rounded,
                    title: l10n.interestRealTags,
                    values: profile.favoriteTags,
                    color: AppColors.slate,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OceanPrimaryButton(
                    key: const Key('interest-recalculate'),
                    label: l10n.interestRealRecalculateAction,
                    icon: Icons.refresh_rounded,
                    semanticLabel: l10n.interestRealRecalculateSemantic,
                    onPressed: recalculating ? null : _recalculate,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}

class _MetaFooter extends StatelessWidget {
  final RealInterestProfile profile;

  const _MetaFooter({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final when = profile.lastRecalculatedAt;
    final whenText = when == null
        ? null
        : DateFormat.yMMMd(locale).add_jm().format(when.toLocal());
    return OceanGlassCard(
      key: const Key('interest-meta'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.interestRealSignalCount(profile.signalCount),
            style: theme.textTheme.titleSmall,
          ),
          if (whenText != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.interestRealLastUpdated(whenText),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A section of raw enum tokens rendered as localized chips (via [labeller]).
/// Hidden entirely when [tokens] is empty.
class _EnumSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> tokens;
  final String Function(AppLocalizations, String) labeller;
  final Color color;

  const _EnumSection({
    super.key,
    required this.icon,
    required this.title,
    required this.tokens,
    required this.labeller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _SectionShell(
      icon: icon,
      title: title,
      chips: [
        for (final token in tokens)
          OceanStatusPill(
            label: labeller(l10n, token),
            icon: icon,
            color: color,
          ),
      ],
    );
  }
}

/// A section of free-form server strings (provinces / categories / tags) shown
/// verbatim as chips. Hidden entirely when [values] is empty.
class _StringSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> values;
  final Color color;

  const _StringSection({
    super.key,
    required this.icon,
    required this.title,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final shown = values.where((v) => v.trim().isNotEmpty).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return _SectionShell(
      icon: icon,
      title: title,
      chips: [
        for (final value in shown)
          OceanStatusPill(label: value.trim(), icon: icon, color: color),
      ],
    );
  }
}

class _SectionShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> chips;

  const _SectionShell({
    required this.icon,
    required this.title,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: chips,
          ),
        ],
      ),
    );
  }
}
