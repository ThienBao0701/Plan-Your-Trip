import 'package:flutter/material.dart';

import '../../core/mock/app_models.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../planner/planner_timeline.dart';

class TimelineScreen extends StatelessWidget {
  final Trip trip;

  const TimelineScreen({super.key, required this.trip});

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
        title: Text(l10n.plannerTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: PlannerTimelineBody(
            initialTripId: trip.id,
            lockTripSelection: true,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
          ),
        ),
      ),
    );
  }
}
