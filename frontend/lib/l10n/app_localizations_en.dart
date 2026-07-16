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
  String get authLoginHero => 'Every day away, one trip worth remembering.';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Log in to continue your journey.';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authFullNameLabel => 'Full name';

  @override
  String get authConfirmPasswordLabel => 'Confirm password';

  @override
  String get authLoginAction => 'Login';

  @override
  String get authDemoAction => 'Use Demo Mode';

  @override
  String get authCreateAccountAction => 'Create account';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authNeedAccount => 'Need an account?';

  @override
  String get authForgotPasswordAction => 'Forgot password?';

  @override
  String get authVerifyEmailAction => 'Verify email';

  @override
  String get authDemoHint =>
      'Demo account uses local mock data and never calls the backend.';

  @override
  String get authBackendHint => 'Backend login uses only /auth/login.';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle => 'Start your own travel planning space.';

  @override
  String get authRegisterAction => 'Register';

  @override
  String get authRegistrationComplete =>
      'Registration complete. Please log in.';

  @override
  String get authPasswordRequirement =>
      'Password must be at least 8 characters.';

  @override
  String get authTermsNote =>
      'By continuing, you agree to the current terms and privacy information in this app.';

  @override
  String get authShowPassword => 'Show password';

  @override
  String get authHidePassword => 'Hide password';

  @override
  String get authShowConfirmPassword => 'Show confirm password';

  @override
  String get authHideConfirmPassword => 'Hide confirm password';

  @override
  String get authValidationName => 'Enter your full name.';

  @override
  String get authValidationEmail => 'Enter a valid email address.';

  @override
  String get authValidationPasswordRequired => 'Enter your password.';

  @override
  String get authValidationPasswordMin =>
      'Password must be at least 8 characters.';

  @override
  String get authValidationConfirmPassword => 'Confirm your password.';

  @override
  String get authValidationPasswordMismatch => 'Passwords do not match.';

  @override
  String get authLoginFailed => 'Login failed.';

  @override
  String get authRegistrationFailed => 'Registration failed.';

  @override
  String get authUnsupportedForgotPassword =>
      'Password reset is not connected to the backend yet.';

  @override
  String get authUnsupportedVerification =>
      'Email verification is not connected to the backend yet.';

  @override
  String get authUnsupportedResend =>
      'Resending a verification code is not connected yet.';

  @override
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the email for your account. This presentation is ready for a future reset endpoint.';

  @override
  String get forgotPasswordSendAction => 'Send reset link';

  @override
  String get forgotPasswordReturnAction => 'Back to login';

  @override
  String get forgotPasswordInfo =>
      'Reset links cannot be sent until the backend endpoint is connected.';

  @override
  String get emailVerificationTitle => 'Verify email';

  @override
  String emailVerificationSubtitle(String email) {
    return 'Enter the 6-digit code for $email.';
  }

  @override
  String emailVerificationDigitSemantic(int position) {
    return 'Verification digit $position';
  }

  @override
  String get emailVerificationAction => 'Verify';

  @override
  String emailVerificationResendIn(int seconds) {
    return 'Resend code in 00:$seconds';
  }

  @override
  String get emailVerificationResendAction => 'Resend code';

  @override
  String get emailVerificationChangeEmail => 'Change email address';

  @override
  String get emailVerificationIncomplete => 'Enter all 6 digits.';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSettingsSemantic => 'Open settings';

  @override
  String get profileDemoName => 'Demo Traveler';

  @override
  String get profileRealAccountTitle => 'Signed-in account';

  @override
  String get profileEmailMissing => 'No email available';

  @override
  String get profileDemoStatus => 'Demo data active';

  @override
  String get profileRealStatus => 'Backend account';

  @override
  String get profileBackendProfileUnavailable =>
      'Profile details are not connected to a backend endpoint yet.';

  @override
  String get profileTripsStat => 'Trips';

  @override
  String get profileSavedPlacesStat => 'Saved';

  @override
  String get profileNotificationsStat => 'Notifications';

  @override
  String get profileTravelPreferences => 'Travel preferences';

  @override
  String get profileDemoPreferences => 'Food, Culture, Nature';

  @override
  String get profileAccountSection => 'Account';

  @override
  String get profileLegalSection => 'Legal';

  @override
  String get profileSettings => 'Settings';

  @override
  String get profileSavedPlaces => 'Saved places';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profilePrivacyPolicy => 'Privacy Policy';

  @override
  String get profileTerms => 'Terms of Service';

  @override
  String get profileAboutApp => 'About App';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutSemantic => 'Log out of this account';

  @override
  String get profileLogoutConfirmTitle => 'Log out?';

  @override
  String get profileLogoutConfirmMessage =>
      'This clears the saved session and removes any Authorization token from future requests.';

  @override
  String get profileCancel => 'Cancel';

  @override
  String get profileConfirmLogout => 'Log out';

  @override
  String get profileVersion => 'Plan Your Trip v1.0.0';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageRegion => 'Language & region';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDevice => 'Device default';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageVietnamese => 'Vietnamese';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsTimeFormat => 'Time format';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsTripReminders => 'Trip reminders';

  @override
  String get settingsBookingUpdates => 'Booking updates';

  @override
  String get settingsTravelTips => 'Travel tips';

  @override
  String get settingsLocalOnly =>
      'Local preference only. Push registration is not connected.';

  @override
  String get settingsStoredOnDevice => 'Stored on this device only.';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsReduceMotion => 'Reduce motion';

  @override
  String get settingsAccountSecurity => 'Account & security';

  @override
  String get settingsPasswordReset => 'Password reset';

  @override
  String get settingsPasswordResetSubtitle =>
      'Presentation flow only until the backend endpoint exists.';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsDemoData => 'Demo data';

  @override
  String get settingsResetDemoData => 'Reset demo data';

  @override
  String get settingsResetDemoSubtitle =>
      'Restore original mock trips, places, and expenses.';

  @override
  String get settingsResetDemoConfirmTitle => 'Reset demo data?';

  @override
  String get settingsResetDemoConfirmMessage =>
      'This logs back into Demo Mode and restores the original mock travel data.';

  @override
  String get settingsReset => 'Reset';

  @override
  String get settingsDemoRestored => 'Demo data restored.';

  @override
  String get settingsConnectedReal => 'Connected to backend';

  @override
  String get savedPlacesTitle => 'Saved places';

  @override
  String get savedPlacesSearchHint => 'Search saved places';

  @override
  String get savedPlacesAllFilter => 'All';

  @override
  String savedPlacesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String get savedPlacesRealEmptyTitle => 'No saved places yet';

  @override
  String get savedPlacesRealEmptyMessage =>
      'Saved places are not connected to the backend yet for real accounts.';

  @override
  String get savedPlacesDemoEmptyTitle => 'No matching saved places';

  @override
  String get savedPlacesDemoEmptyMessage =>
      'Try another filter or search term.';

  @override
  String savedPlacesBookmarkSemantic(String place) {
    return 'Saved bookmark for $place';
  }

  @override
  String get savedPlacesRemoved => 'Removed from local saved places.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsToday => 'Today';

  @override
  String get notificationsEarlier => 'Earlier';

  @override
  String get notificationsRealEmptyTitle => 'No notifications';

  @override
  String get notificationsRealEmptyMessage =>
      'Server notifications are not connected yet for real accounts.';

  @override
  String get notificationsDemoEmptyTitle => 'No demo notifications';

  @override
  String get notificationsDemoEmptyMessage =>
      'Trip reminders and updates will appear here.';

  @override
  String get notificationUnreadSemantic => 'Unread notification';

  @override
  String get notificationReadSemantic => 'Read notification';

  @override
  String get notificationsSettingsSemantic => 'Open notification settings';

  @override
  String get notificationScheduleTitle => 'Timeline starts soon';

  @override
  String get notificationScheduleMessage =>
      'Your Da Lat trip begins in 2 days.';

  @override
  String get notificationBookingTitle => 'Booking update';

  @override
  String get notificationBookingMessage =>
      'Your demo stay is ready for the trip.';

  @override
  String get notificationTipsTitle => 'Suggestion for you';

  @override
  String get notificationTipsMessage =>
      'Explore 5 favorite food stops near your saved places.';

  @override
  String get notificationBudgetTitle => 'Trip budget';

  @override
  String get notificationBudgetMessage =>
      'You have used 62% of the planned demo budget.';

  @override
  String get notificationYesterday => 'Yesterday';

  @override
  String get notificationBudgetDate => '12 Jul';

  @override
  String get commonBackSemantic => 'Go back';

  @override
  String get demoModeLabel => 'Demo Mode';
}
