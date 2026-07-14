import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../expenses/expenses_screen.dart';
import '../places/places_screen.dart';
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
    PlacesScreen(),
    TripsScreen(),
    ExpensesScreen(),
    ProfileScreen()
  ];

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PremiumScaffold(
        index: index,
        onNav: (i) => setState(() => index = i),
        body: Stack(children: [
          IndexedStack(index: index, children: _pages),
          if (app.demoMode)
            Positioned(
                top: 8,
                right: 16,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .72),
                        borderRadius: BorderRadius.circular(999)),
                    child: const Text('Demo Mode',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12))))
        ]));
  }
}
