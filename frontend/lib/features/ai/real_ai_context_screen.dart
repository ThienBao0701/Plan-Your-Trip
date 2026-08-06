import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';

/// UI42 — Real Mode AI Trip Context (`GET /api/me/ai/context`). A read-only
/// snapshot of the aggregated data an AI assistant would use — activity counts,
/// the current/upcoming trips, and the current trip's budget. The backend
/// produces NO AI response, prompt, or generation, so none is shown or invented;
/// all totals are backend-computed (never recalculated client-side).
class RealAiContextScreen extends StatefulWidget {
  const RealAiContextScreen({super.key});

  @override
  State<RealAiContextScreen> createState() => _RealAiContextScreenState();
}

class _RealAiContextScreenState extends State<RealAiContextScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealAiContext();
    });
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
        title: Text(l10n.aiContextTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realAiContextError == AiContextOutcome.sessionExpired &&
        !app.realAiContextLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('ai-context-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realAiContextLoading && !app.realAiContextLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.aiContextLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(key: Key('ai-context-loading')),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.aiContextLoadingMessage),
            ],
          ),
        ),
      );
    }
    final ctx = app.realAiContext;
    if (ctx == null) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('ai-context-error'),
          message: l10n.aiContextErrorMessage,
          onReload: () => app.loadRealAiContext(refresh: true),
        ),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    return RefreshIndicator(
      onRefresh: () => app.loadRealAiContext(refresh: true),
      child: ListView(
        key: const Key('ai-context-content'),
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
                OceanGlassCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.ocean),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.aiContextExplainer,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SectionTitle(l10n.aiContextActivityTitle),
                const SizedBox(height: AppSpacing.sm),
                _ActivityGrid(summary: ctx.activitySummary),
                if (ctx.currentTrip != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(l10n.aiContextCurrentTripTitle),
                  const SizedBox(height: AppSpacing.sm),
                  _TripCard(
                    trip: ctx.currentTrip!,
                    locale: locale,
                    keyValue: 'ai-context-current-trip',
                  ),
                ],
                if (ctx.budgetSummary != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(l10n.aiContextBudgetTitle),
                  const SizedBox(height: AppSpacing.sm),
                  _BudgetCard(summary: ctx.budgetSummary!, locale: locale),
                ],
                if (ctx.upcomingTrips.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _SectionTitle(l10n.aiContextUpcomingTripsTitle),
                  const SizedBox(height: AppSpacing.sm),
                  for (final t in ctx.upcomingTrips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _TripCard(
                        trip: t,
                        locale: locale,
                        keyValue: 'ai-context-upcoming-${t.id}',
                      ),
                    ),
                ],
                const SizedBox(height: AppSpacing.md),
                if (ctx.contextGeneratedAt != null)
                  Text(
                    l10n.aiContextGeneratedAt(
                      DateFormat.yMMMd(locale).add_jm().format(
                            ctx.contextGeneratedAt!.toLocal(),
                          ),
                    ),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
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

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: Theme.of(context).textTheme.titleMedium,
      );
}

class _ActivityGrid extends StatelessWidget {
  final RealAiActivitySummary summary;
  const _ActivityGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = <(String, int)>[
      (l10n.aiContextStatTrips, summary.totalTrips),
      (l10n.aiContextStatActiveTrips, summary.activeTrips),
      (l10n.aiContextStatUpcomingTrips, summary.upcomingTrips),
      (l10n.aiContextStatCompletedTrips, summary.completedTrips),
      (l10n.aiContextStatPlannedDays, summary.totalPlannedDays),
      (l10n.aiContextStatBookings, summary.totalBookings),
      (l10n.aiContextStatCollections, summary.savedCollections),
      (l10n.aiContextStatWishlist, summary.wishlistItems),
      (l10n.aiContextStatReviews, summary.reviews),
      (l10n.aiContextStatRecommendations, summary.recommendations),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final s in stats)
          _StatChip(key: Key('ai-stat-${s.$1}'), label: s.$1, value: s.$2),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  const _StatChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.aiContextStatSemantic(label, value),
      child: OceanGlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final RealAiTripRef trip;
  final String locale;
  final String keyValue;

  const _TripCard({
    required this.trip,
    required this.locale,
    required this.keyValue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final range = (trip.startDate != null && trip.endDate != null)
        ? '${DateFormat.MMMd(locale).format(trip.startDate!)} – '
            '${DateFormat.MMMd(locale).format(trip.endDate!)}'
        : null;
    return OceanGlassCard(
      key: Key(keyValue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trip.title.trim().isEmpty ? l10n.aiContextUntitledTrip : trip.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if ((trip.destination ?? '').trim().isNotEmpty)
                OceanStatusPill(
                  label: trip.destination!.trim(),
                  icon: Icons.place_rounded,
                ),
              if (range != null)
                OceanStatusPill(
                  label: range,
                  icon: Icons.event_rounded,
                  color: AppColors.turquoise600,
                ),
              OceanStatusPill(
                label: l10n.aiContextTripDays(trip.dayCount),
                icon: Icons.calendar_today_rounded,
                color: AppColors.slate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final RealExpenseSummary summary;
  final String locale;

  const _BudgetCard({required this.summary, required this.locale});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fmt = NumberFormat('#,##0.##', locale);
    return OceanGlassCard(
      key: const Key('ai-context-budget'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiContextSpent(fmt.format(summary.totalSpent)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (summary.hasBudget) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  label: l10n.aiContextBudget(fmt.format(summary.totalBudget)),
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.ocean,
                ),
                if (summary.overBudget)
                  OceanStatusPill(
                    label: l10n.aiContextOverBudget,
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.danger,
                  )
                else
                  OceanStatusPill(
                    label: l10n.aiContextRemaining(
                      fmt.format(summary.remainingBudget),
                    ),
                    icon: Icons.savings_rounded,
                    color: AppColors.success,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
