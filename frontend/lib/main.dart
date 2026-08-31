import 'package:flutter/material.dart';
import 'core/app_state.dart';
import 'core/admin/admin_state.dart';
import 'core/partner/partner_state.dart';
import 'design/app_theme.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/role_home.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.restore();
  // PartnerState is a sibling notifier under the same InheritedNotifier
  // paradigm, not a second state-management system. It mirrors the session so
  // partner data is dropped whenever the account or mode changes.
  final partner = PartnerState(api: state.api)..bindSession(state);
  // AdminState is a third sibling under the same InheritedNotifier paradigm --
  // not a third state-management system. Like PartnerState it mirrors the
  // session, so admin context is dropped whenever the account or mode changes.
  final admin = AdminState(api: state.api)..bindSession(state);
  runApp(
    AppScope(
      notifier: state,
      child: PartnerScope(
        notifier: partner,
        child: AdminScope(
          notifier: admin,
          child: const PlanYourTripApp(),
        ),
      ),
    ),
  );
}

class PlanYourTripApp extends StatelessWidget {
  const PlanYourTripApp({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        theme: AppTheme.light(),
        locale: app.localeOverride,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: app.email == null ? const OnboardingScreen() : const RoleHome());
  }
}
