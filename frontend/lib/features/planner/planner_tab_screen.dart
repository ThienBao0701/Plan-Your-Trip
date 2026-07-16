import 'package:flutter/material.dart';

import '../../design/app_spacing.dart';
import 'planner_timeline.dart';

class PlannerTabScreen extends StatelessWidget {
  const PlannerTabScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlannerTimelineBody(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
      );
}
