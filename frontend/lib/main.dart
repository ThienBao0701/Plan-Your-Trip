import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'design/app_theme.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/home/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.restore();
  runApp(AppScope(notifier: state, child: const PlanYourTripApp()));
}

class PlanYourTripApp extends StatelessWidget {
  const PlanYourTripApp({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Plan Your Trip',
        theme: AppTheme.light(),
        home: app.email == null ? const OnboardingScreen() : const AppShell());
  }
}
