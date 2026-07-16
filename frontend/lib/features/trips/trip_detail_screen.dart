import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../planner/planner_utils.dart';
import '../expenses/expenses_screen.dart';
import '../places/places_screen.dart';
import '../timeline/timeline_screen.dart';
import 'edit_trip_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Trip trip;

  @override
  void initState() {
    super.initState();
    trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final currentTrip = app.tripById(trip.id) ?? trip;
    trip = currentTrip;
    final items = app.timeline.where((item) => item.tripId == trip.id).toList()
      ..sort((a, b) {
        final day = a.dayNumber.compareTo(b.dayNumber);
        return day == 0 ? compareTimelineItems(a, b) : day;
      });
    final expenses = app.expensesForTrip(trip.id);
    final spent =
        expenses.fold<double>(0, (sum, expense) => sum + expense.amount);
    final money = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(trip.destination),
        actions: [
          IconButton(
            tooltip: l10n.tripEditAction,
            onPressed: _edit,
            icon: const Icon(Icons.edit_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.tripActionsSemantic(trip.title),
            onSelected: (value) {
              if (value == 'delete') _delete(context, app);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  l10n.tripDeleteAction,
                  style: const TextStyle(color: AppColors.coral),
                ),
              ),
            ],
          ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
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
                    _TripHero(trip: trip),
                    const SizedBox(height: AppSpacing.lg),
                    OceanGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OceanStatusPill(
                            label: l10n.tripDayCount(trip.days),
                            icon: Icons.calendar_month_rounded,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            trip.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.tripDateTravelerMeta(
                              date.format(trip.startDate),
                              date.format(trip.endDate),
                              trip.travelers,
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          if (trip.notes.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(trip.notes,
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ProgressCard(
                      completed: items.length,
                      target: (trip.days * 2).clamp(1, 999),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _QuickActions(
                      onTimeline: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TimelineScreen(trip: trip),
                        ),
                      ),
                      onExplore: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PlacesScreen(initialQuery: trip.destination),
                        ),
                      ),
                      onExpenses: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ExpensesScreen(filterTripId: trip.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SummaryGrid(
                      activityCount: items.length,
                      spent: money.format(spent),
                      budget:
                          trip.budget > 0 ? money.format(trip.budget) : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.tripOverviewNextTitle,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    if (items.isEmpty)
                      OceanEmptyState(
                        title: l10n.tripOverviewNoActivitiesTitle,
                        message: l10n.tripOverviewNoActivitiesMessage,
                        actionLabel: l10n.plannerOpenTimelineAction,
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimelineScreen(trip: trip),
                          ),
                        ),
                      )
                    else
                      _NextActivity(item: items.first),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<Trip>(
      context,
      MaterialPageRoute(builder: (_) => EditTripScreen(trip: trip)),
    );
    if (updated != null && mounted) setState(() => trip = updated);
  }

  Future<void> _delete(BuildContext context, AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tripDeleteConfirmTitle),
        content: Text(l10n.tripDeleteConfirmMessage(trip.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.tripDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    app.deleteTrip(trip.id);
    if (!context.mounted) return;
    nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(l10n.tripDeletedMessage)));
  }
}

class _TripHero extends StatelessWidget {
  final Trip trip;

  const _TripHero({required this.trip});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.xxl),
        child: Image.network(
          trip.imageUrl,
          height: 260,
          width: double.infinity,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (_, __, ___) => Container(
            height: 260,
            color: AppColors.paleCyan,
            alignment: Alignment.center,
            child: const Icon(
              Icons.landscape_rounded,
              color: AppColors.ocean,
              size: AppIconSizes.xl,
            ),
          ),
        ),
      );
}

class _ProgressCard extends StatelessWidget {
  final int completed;
  final int target;

  const _ProgressCard({required this.completed, required this.target});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = (completed / target).clamp(0.0, 1.0);
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.tripOverviewProgressTitle,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.tripOverviewProgressValue((progress * 100).round()),
            style: Theme.of(context)
                .textTheme
                .displaySmall
                ?.copyWith(color: AppColors.ocean),
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(value: progress, minHeight: 8),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final VoidCallback onTimeline;
  final VoidCallback onExplore;
  final VoidCallback onExpenses;

  const _QuickActions({
    required this.onTimeline,
    required this.onExplore,
    required this.onExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.timeline_rounded,
            label: l10n.tripOverviewTimelineAction,
            onTap: onTimeline,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionCard(
            icon: Icons.explore_rounded,
            label: l10n.tabExplore,
            onTap: onExplore,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _ActionCard(
            icon: Icons.receipt_long_rounded,
            label: l10n.tripOverviewExpensesAction,
            onTap: onExpenses,
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => OceanGlassCard(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.ocean.withValues(alpha: .12),
              child: Icon(icon, color: AppColors.ocean),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      );
}

class _SummaryGrid extends StatelessWidget {
  final int activityCount;
  final String spent;
  final String? budget;

  const _SummaryGrid({
    required this.activityCount,
    required this.spent,
    required this.budget,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _MetricCard(
          icon: Icons.local_activity_rounded,
          label: l10n.tripOverviewActivitiesMetric,
          value: '$activityCount',
        ),
        _MetricCard(
          icon: Icons.payments_rounded,
          label: l10n.tripOverviewSpentMetric,
          value: spent,
        ),
        if (budget != null)
          _MetricCard(
            icon: Icons.savings_rounded,
            label: l10n.tripOverviewBudgetMetric,
            value: budget!,
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 190,
        child: OceanGlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.ocean),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
}

class _NextActivity extends StatelessWidget {
  final TimelineItem item;

  const _NextActivity({required this.item});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Row(
        children: [
          Column(
            children: [
              Text(
                item.startTime,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppColors.ocean),
              ),
              Container(
                width: 2,
                height: 44,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                color: AppColors.ocean.withValues(alpha: .28),
              ),
              Text(item.endTime, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          CircleAvatar(
            backgroundColor: AppColors.ocean.withValues(alpha: .10),
            child: const Icon(Icons.place_rounded, color: AppColors.ocean),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium),
                Text(
                  l10n.tripOverviewDayLabel(item.dayNumber),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
