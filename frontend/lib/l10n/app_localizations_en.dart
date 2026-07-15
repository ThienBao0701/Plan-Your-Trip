// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Plan Your Trip';

  @override
  String get tabExplore => 'Explore';

  @override
  String get tabTrips => 'Trips';

  @override
  String get tabPlanner => 'Planner';

  @override
  String get tabProfile => 'Profile';

  @override
  String get tabExploreSemantic => 'Explore tab';

  @override
  String get tabTripsSemantic => 'Trips tab';

  @override
  String get tabPlannerSemantic => 'Planner tab';

  @override
  String get tabProfileSemantic => 'Profile tab';

  @override
  String get bottomNavigationSemantic => 'Primary navigation';

  @override
  String get loadingTitle => 'Loading';

  @override
  String get loadingMessage => 'Preparing your journey...';

  @override
  String get loadingSemanticLabel => 'Content is loading';

  @override
  String get emptyTitle => 'No data yet';

  @override
  String get emptyMessage => 'Content will appear here when you get started.';

  @override
  String get emptyAction => 'Explore now';

  @override
  String get emptyStateSemanticLabel => 'Empty state';

  @override
  String get offlineTitle => 'You are offline';

  @override
  String get offlineMessage => 'Check your connection and try again.';

  @override
  String get offlineAction => 'Try again';

  @override
  String get offlineStateSemanticLabel => 'Offline state';

  @override
  String get errorTitle => 'Something went wrong';

  @override
  String get errorMessage => 'We could not load this content.';

  @override
  String get errorAction => 'Reload';

  @override
  String get errorStateSemanticLabel => 'Recoverable error';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get sessionExpiredMessage =>
      'Sign in again to continue. Unsaved local changes are kept.';

  @override
  String get sessionExpiredLoginAction => 'Log in again';

  @override
  String get sessionExpiredHomeAction => 'Return home';

  @override
  String get sessionExpiredSemanticLabel => 'Session expired';

  @override
  String get searchFieldSemanticLabel => 'Search';

  @override
  String get plannerTitle => 'Planner';

  @override
  String get plannerSubtitle => 'Open a trip timeline and continue planning.';

  @override
  String get plannerEmptyTitle => 'No trips to plan yet';

  @override
  String get plannerEmptyMessage => 'Create a trip before building a timeline.';

  @override
  String get plannerCreateTripAction => 'Create a trip';

  @override
  String get plannerOpenTimelineAction => 'Open timeline';

  @override
  String plannerTripMeta(String destination, int days, int travelers) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    String _temp1 = intl.Intl.pluralLogic(
      travelers,
      locale: localeName,
      other: '$travelers travelers',
      one: '1 traveler',
    );
    return '$destination · $_temp0 · $_temp1';
  }

  @override
  String get plannerTripCardSemantic => 'Trip planner card';

  @override
  String get demoModeLabel => 'Demo Mode';
}
