import 'package:flutter/material.dart';

import '../../design/app_breakpoints.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../planner/planner_tab_screen.dart';
import '../profile/profile_screen.dart';
import '../trips/trips_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  late final List<Widget> _pages = const [
    HomeScreen(),
    TripsScreen(),
    PlannerTabScreen(),
    ProfileScreen(),
  ];
  late final List<GlobalKey> _tabKeys =
      List.generate(_pages.length, (index) => GlobalKey());

  void _selectTab(int nextIndex) {
    if (nextIndex == index) return;
    setState(() => index = nextIndex);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      OceanNavigationDestination(
        label: l10n?.tabExplore ?? 'Explore',
        semanticLabel: l10n?.tabExploreSemantic ?? 'Explore tab',
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore_rounded,
      ),
      OceanNavigationDestination(
        label: l10n?.tabTrips ?? 'Trips',
        semanticLabel: l10n?.tabTripsSemantic ?? 'Trips tab',
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
      ),
      OceanNavigationDestination(
        label: l10n?.tabPlanner ?? 'Planner',
        semanticLabel: l10n?.tabPlannerSemantic ?? 'Planner tab',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month_rounded,
      ),
      OceanNavigationDestination(
        label: l10n?.tabProfile ?? 'Profile',
        semanticLabel: l10n?.tabProfileSemantic ?? 'Profile tab',
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final i in _paintOrder)
                _PreservedTab(
                  contentKey: ValueKey('shell-tab-$i'),
                  active: index == i,
                  child: OceanContentConstraint(
                    maxWidth: AppBreakpoints.maxShellWidth,
                    child: KeyedSubtree(key: _tabKeys[i], child: _pages[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: OceanBottomNavigationBar(
        currentIndex: index,
        destinations: destinations,
        onTap: _selectTab,
      ),
    );
  }

  Iterable<int> get _paintOrder sync* {
    for (var i = 0; i < _pages.length; i++) {
      if (i != index) yield i;
    }
    yield index;
  }
}

class _PreservedTab extends StatelessWidget {
  final Key contentKey;
  final bool active;
  final Widget child;

  const _PreservedTab({
    required this.contentKey,
    required this.active,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Offstage(
        offstage: !active,
        child: TickerMode(
          enabled: active,
          child: SizedBox.expand(
            key: contentKey,
            child: child,
          ),
        ),
      );
}
