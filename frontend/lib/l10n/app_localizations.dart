import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Trip'**
  String get appTitle;

  /// No description provided for @tabExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// No description provided for @tabTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tabTrips;

  /// No description provided for @tabPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get tabPlanner;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @tabExploreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Explore tab'**
  String get tabExploreSemantic;

  /// No description provided for @tabTripsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Trips tab'**
  String get tabTripsSemantic;

  /// No description provided for @tabPlannerSemantic.
  ///
  /// In en, this message translates to:
  /// **'Planner tab'**
  String get tabPlannerSemantic;

  /// No description provided for @tabProfileSemantic.
  ///
  /// In en, this message translates to:
  /// **'Profile tab'**
  String get tabProfileSemantic;

  /// No description provided for @bottomNavigationSemantic.
  ///
  /// In en, this message translates to:
  /// **'Primary navigation'**
  String get bottomNavigationSemantic;

  /// No description provided for @loadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loadingTitle;

  /// No description provided for @loadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Preparing your journey...'**
  String get loadingMessage;

  /// No description provided for @loadingSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Content is loading'**
  String get loadingSemanticLabel;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get emptyTitle;

  /// No description provided for @emptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Content will appear here when you get started.'**
  String get emptyMessage;

  /// No description provided for @emptyAction.
  ///
  /// In en, this message translates to:
  /// **'Explore now'**
  String get emptyAction;

  /// No description provided for @emptyStateSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Empty state'**
  String get emptyStateSemanticLabel;

  /// No description provided for @offlineTitle.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get offlineTitle;

  /// No description provided for @offlineMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again.'**
  String get offlineMessage;

  /// No description provided for @offlineAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get offlineAction;

  /// No description provided for @offlineStateSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline state'**
  String get offlineStateSemanticLabel;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not load this content.'**
  String get errorMessage;

  /// No description provided for @errorAction.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get errorAction;

  /// No description provided for @errorStateSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Recoverable error'**
  String get errorStateSemanticLabel;

  /// No description provided for @sessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpiredTitle;

  /// No description provided for @sessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Sign in again to continue. Unsaved local changes are kept.'**
  String get sessionExpiredMessage;

  /// No description provided for @sessionExpiredLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Log in again'**
  String get sessionExpiredLoginAction;

  /// No description provided for @sessionExpiredHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Return home'**
  String get sessionExpiredHomeAction;

  /// No description provided for @sessionExpiredSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpiredSemanticLabel;

  /// No description provided for @searchFieldSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchFieldSemanticLabel;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get plannerTitle;

  /// No description provided for @plannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open a trip timeline and continue planning.'**
  String get plannerSubtitle;

  /// No description provided for @plannerEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips to plan yet'**
  String get plannerEmptyTitle;

  /// No description provided for @plannerEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a trip before building a timeline.'**
  String get plannerEmptyMessage;

  /// No description provided for @plannerCreateTripAction.
  ///
  /// In en, this message translates to:
  /// **'Create a trip'**
  String get plannerCreateTripAction;

  /// No description provided for @plannerOpenTimelineAction.
  ///
  /// In en, this message translates to:
  /// **'Open timeline'**
  String get plannerOpenTimelineAction;

  /// No description provided for @plannerTripMeta.
  ///
  /// In en, this message translates to:
  /// **'{destination} · {days, plural, =1{1 day} other{{days} days}} · {travelers, plural, =1{1 traveler} other{{travelers} travelers}}'**
  String plannerTripMeta(String destination, int days, int travelers);

  /// No description provided for @plannerTripCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Trip planner card'**
  String get plannerTripCardSemantic;

  /// No description provided for @authLoginHero.
  ///
  /// In en, this message translates to:
  /// **'Every day away, one trip worth remembering.'**
  String get authLoginHero;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to continue your journey.'**
  String get authLoginSubtitle;

  /// No description provided for @authEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get authFullNameLabel;

  /// No description provided for @authConfirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authConfirmPasswordLabel;

  /// No description provided for @authLoginAction.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginAction;

  /// No description provided for @authDemoAction.
  ///
  /// In en, this message translates to:
  /// **'Use Demo Mode'**
  String get authDemoAction;

  /// No description provided for @authCreateAccountAction.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccountAction;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account?'**
  String get authNeedAccount;

  /// No description provided for @authForgotPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPasswordAction;

  /// No description provided for @authVerifyEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get authVerifyEmailAction;

  /// No description provided for @authDemoHint.
  ///
  /// In en, this message translates to:
  /// **'Demo account uses local mock data and never calls the backend.'**
  String get authDemoHint;

  /// No description provided for @authBackendHint.
  ///
  /// In en, this message translates to:
  /// **'Backend login uses only /auth/login.'**
  String get authBackendHint;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start your own travel planning space.'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterAction;

  /// No description provided for @authRegistrationComplete.
  ///
  /// In en, this message translates to:
  /// **'Registration complete. Please log in.'**
  String get authRegistrationComplete;

  /// No description provided for @authPasswordRequirement.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authPasswordRequirement;

  /// No description provided for @authTermsNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to the current terms and privacy information in this app.'**
  String get authTermsNote;

  /// No description provided for @authShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get authShowPassword;

  /// No description provided for @authHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get authHidePassword;

  /// No description provided for @authShowConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Show confirm password'**
  String get authShowConfirmPassword;

  /// No description provided for @authHideConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Hide confirm password'**
  String get authHideConfirmPassword;

  /// No description provided for @authValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name.'**
  String get authValidationName;

  /// No description provided for @authValidationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authValidationEmail;

  /// No description provided for @authValidationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get authValidationPasswordRequired;

  /// No description provided for @authValidationPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authValidationPasswordMin;

  /// No description provided for @authValidationConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get authValidationConfirmPassword;

  /// No description provided for @authValidationPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authValidationPasswordMismatch;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed.'**
  String get authLoginFailed;

  /// No description provided for @authRegistrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed.'**
  String get authRegistrationFailed;

  /// No description provided for @authUnsupportedForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Password reset is not connected to the backend yet.'**
  String get authUnsupportedForgotPassword;

  /// No description provided for @authUnsupportedVerification.
  ///
  /// In en, this message translates to:
  /// **'Email verification is not connected to the backend yet.'**
  String get authUnsupportedVerification;

  /// No description provided for @authUnsupportedResend.
  ///
  /// In en, this message translates to:
  /// **'Resending a verification code is not connected yet.'**
  String get authUnsupportedResend;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email for your account. This presentation is ready for a future reset endpoint.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordSendAction.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgotPasswordSendAction;

  /// No description provided for @forgotPasswordReturnAction.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get forgotPasswordReturnAction;

  /// No description provided for @forgotPasswordInfo.
  ///
  /// In en, this message translates to:
  /// **'Reset links cannot be sent until the backend endpoint is connected.'**
  String get forgotPasswordInfo;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code for {email}.'**
  String emailVerificationSubtitle(String email);

  /// No description provided for @emailVerificationDigitSemantic.
  ///
  /// In en, this message translates to:
  /// **'Verification digit {position}'**
  String emailVerificationDigitSemantic(int position);

  /// No description provided for @emailVerificationAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get emailVerificationAction;

  /// No description provided for @emailVerificationResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in 00:{seconds}'**
  String emailVerificationResendIn(int seconds);

  /// No description provided for @emailVerificationResendAction.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get emailVerificationResendAction;

  /// No description provided for @emailVerificationChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email address'**
  String get emailVerificationChangeEmail;

  /// No description provided for @emailVerificationIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Enter all 6 digits.'**
  String get emailVerificationIncomplete;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSettingsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get profileSettingsSemantic;

  /// No description provided for @profileDemoName.
  ///
  /// In en, this message translates to:
  /// **'Demo Traveler'**
  String get profileDemoName;

  /// No description provided for @profileRealAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Signed-in account'**
  String get profileRealAccountTitle;

  /// No description provided for @profileEmailMissing.
  ///
  /// In en, this message translates to:
  /// **'No email available'**
  String get profileEmailMissing;

  /// No description provided for @profileDemoStatus.
  ///
  /// In en, this message translates to:
  /// **'Demo data active'**
  String get profileDemoStatus;

  /// No description provided for @profileRealStatus.
  ///
  /// In en, this message translates to:
  /// **'Backend account'**
  String get profileRealStatus;

  /// No description provided for @profileBackendProfileUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Profile details are not connected to a backend endpoint yet.'**
  String get profileBackendProfileUnavailable;

  /// No description provided for @profileTripsStat.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get profileTripsStat;

  /// No description provided for @profileSavedPlacesStat.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get profileSavedPlacesStat;

  /// No description provided for @profileNotificationsStat.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotificationsStat;

  /// No description provided for @profileTravelPreferences.
  ///
  /// In en, this message translates to:
  /// **'Travel preferences'**
  String get profileTravelPreferences;

  /// No description provided for @profileDemoPreferences.
  ///
  /// In en, this message translates to:
  /// **'Food, Culture, Nature'**
  String get profileDemoPreferences;

  /// No description provided for @profileAccountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileAccountSection;

  /// No description provided for @profileLegalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get profileLegalSection;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileSavedPlaces.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get profileSavedPlaces;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get profileTerms;

  /// No description provided for @profileAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get profileAboutApp;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileLogoutSemantic.
  ///
  /// In en, this message translates to:
  /// **'Log out of this account'**
  String get profileLogoutSemantic;

  /// No description provided for @profileLogoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get profileLogoutConfirmTitle;

  /// No description provided for @profileLogoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This clears the saved session and removes any Authorization token from future requests.'**
  String get profileLogoutConfirmMessage;

  /// No description provided for @profileCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get profileCancel;

  /// No description provided for @profileConfirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileConfirmLogout;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Trip v1.0.0'**
  String get profileVersion;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get settingsLanguageRegion;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device default'**
  String get settingsLanguageDevice;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get settingsLanguageVietnamese;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get settingsTimeFormat;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsTripReminders.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders'**
  String get settingsTripReminders;

  /// No description provided for @settingsBookingUpdates.
  ///
  /// In en, this message translates to:
  /// **'Booking updates'**
  String get settingsBookingUpdates;

  /// No description provided for @settingsTravelTips.
  ///
  /// In en, this message translates to:
  /// **'Travel tips'**
  String get settingsTravelTips;

  /// No description provided for @settingsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Local preference only. Push registration is not connected.'**
  String get settingsLocalOnly;

  /// No description provided for @settingsStoredOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Stored on this device only.'**
  String get settingsStoredOnDevice;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsReduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingsReduceMotion;

  /// No description provided for @settingsAccountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account & security'**
  String get settingsAccountSecurity;

  /// No description provided for @settingsPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get settingsPasswordReset;

  /// No description provided for @settingsPasswordResetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Presentation flow only until the backend endpoint exists.'**
  String get settingsPasswordResetSubtitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsDemoData.
  ///
  /// In en, this message translates to:
  /// **'Demo data'**
  String get settingsDemoData;

  /// No description provided for @settingsResetDemoData.
  ///
  /// In en, this message translates to:
  /// **'Reset demo data'**
  String get settingsResetDemoData;

  /// No description provided for @settingsResetDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore original mock trips, places, and expenses.'**
  String get settingsResetDemoSubtitle;

  /// No description provided for @settingsResetDemoConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset demo data?'**
  String get settingsResetDemoConfirmTitle;

  /// No description provided for @settingsResetDemoConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This logs back into Demo Mode and restores the original mock travel data.'**
  String get settingsResetDemoConfirmMessage;

  /// No description provided for @settingsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get settingsReset;

  /// No description provided for @settingsDemoRestored.
  ///
  /// In en, this message translates to:
  /// **'Demo data restored.'**
  String get settingsDemoRestored;

  /// No description provided for @settingsConnectedReal.
  ///
  /// In en, this message translates to:
  /// **'Connected to backend'**
  String get settingsConnectedReal;

  /// No description provided for @savedPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved places'**
  String get savedPlacesTitle;

  /// No description provided for @savedPlacesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search saved places'**
  String get savedPlacesSearchHint;

  /// No description provided for @savedPlacesAllFilter.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get savedPlacesAllFilter;

  /// No description provided for @savedPlacesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String savedPlacesCount(int count);

  /// No description provided for @savedPlacesRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get savedPlacesRealEmptyTitle;

  /// No description provided for @savedPlacesRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved places are not connected to the backend yet for real accounts.'**
  String get savedPlacesRealEmptyMessage;

  /// No description provided for @savedPlacesDemoEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching saved places'**
  String get savedPlacesDemoEmptyTitle;

  /// No description provided for @savedPlacesDemoEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another filter or search term.'**
  String get savedPlacesDemoEmptyMessage;

  /// No description provided for @savedPlacesBookmarkSemantic.
  ///
  /// In en, this message translates to:
  /// **'Saved bookmark for {place}'**
  String savedPlacesBookmarkSemantic(String place);

  /// No description provided for @savedPlacesRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from local saved places.'**
  String get savedPlacesRemoved;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notificationsToday;

  /// No description provided for @notificationsEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notificationsEarlier;

  /// No description provided for @notificationsRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsRealEmptyTitle;

  /// No description provided for @notificationsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Server notifications are not connected yet for real accounts.'**
  String get notificationsRealEmptyMessage;

  /// No description provided for @notificationsDemoEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No demo notifications'**
  String get notificationsDemoEmptyTitle;

  /// No description provided for @notificationsDemoEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders and updates will appear here.'**
  String get notificationsDemoEmptyMessage;

  /// No description provided for @notificationUnreadSemantic.
  ///
  /// In en, this message translates to:
  /// **'Unread notification'**
  String get notificationUnreadSemantic;

  /// No description provided for @notificationReadSemantic.
  ///
  /// In en, this message translates to:
  /// **'Read notification'**
  String get notificationReadSemantic;

  /// No description provided for @notificationsSettingsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get notificationsSettingsSemantic;

  /// No description provided for @notificationScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Timeline starts soon'**
  String get notificationScheduleTitle;

  /// No description provided for @notificationScheduleMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Da Lat trip begins in 2 days.'**
  String get notificationScheduleMessage;

  /// No description provided for @notificationBookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking update'**
  String get notificationBookingTitle;

  /// No description provided for @notificationBookingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your demo stay is ready for the trip.'**
  String get notificationBookingMessage;

  /// No description provided for @notificationTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestion for you'**
  String get notificationTipsTitle;

  /// No description provided for @notificationTipsMessage.
  ///
  /// In en, this message translates to:
  /// **'Explore 5 favorite food stops near your saved places.'**
  String get notificationTipsMessage;

  /// No description provided for @notificationBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip budget'**
  String get notificationBudgetTitle;

  /// No description provided for @notificationBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'You have used 62% of the planned demo budget.'**
  String get notificationBudgetMessage;

  /// No description provided for @notificationYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notificationYesterday;

  /// No description provided for @notificationBudgetDate.
  ///
  /// In en, this message translates to:
  /// **'12 Jul'**
  String get notificationBudgetDate;

  /// No description provided for @commonBackSemantic.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get commonBackSemantic;

  /// No description provided for @demoModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode'**
  String get demoModeLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
