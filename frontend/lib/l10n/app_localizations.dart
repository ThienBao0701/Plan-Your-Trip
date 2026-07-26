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

  /// No description provided for @plannerTripSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Select trip'**
  String get plannerTripSelectorLabel;

  /// No description provided for @plannerTripSelectorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Trip selector'**
  String get plannerTripSelectorSemantic;

  /// No description provided for @plannerModeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Planner presentation mode'**
  String get plannerModeSemantic;

  /// No description provided for @plannerTimelineMode.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get plannerTimelineMode;

  /// No description provided for @plannerRouteMode.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get plannerRouteMode;

  /// No description provided for @plannerDaySelectorSemantic.
  ///
  /// In en, this message translates to:
  /// **'Day selector'**
  String get plannerDaySelectorSemantic;

  /// No description provided for @plannerDaySemantic.
  ///
  /// In en, this message translates to:
  /// **'Select day {day}'**
  String plannerDaySemantic(int day);

  /// No description provided for @plannerQuickAddAction.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get plannerQuickAddAction;

  /// No description provided for @plannerQuickAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Quick add an activity or place'**
  String get plannerQuickAddSemantic;

  /// No description provided for @plannerAddActivityAction.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get plannerAddActivityAction;

  /// No description provided for @plannerAddActivitySemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a manual activity'**
  String get plannerAddActivitySemantic;

  /// No description provided for @plannerEmptyDayTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities this day'**
  String get plannerEmptyDayTitle;

  /// No description provided for @plannerEmptyDayMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a place or manual activity to build this day.'**
  String get plannerEmptyDayMessage;

  /// No description provided for @plannerActivityCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{title}, {time}'**
  String plannerActivityCardSemantic(String title, String time);

  /// No description provided for @plannerInvalidTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invalid time'**
  String get plannerInvalidTimeLabel;

  /// No description provided for @plannerRouteFallbackSemantic.
  ///
  /// In en, this message translates to:
  /// **'Planner route fallback'**
  String get plannerRouteFallbackSemantic;

  /// No description provided for @plannerRouteUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Live maps, route geometry, traffic, distance, and travel time are not connected yet. Timeline data remains local.'**
  String get plannerRouteUnavailableMessage;

  /// No description provided for @plannerRoutePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Day stops'**
  String get plannerRoutePreviewTitle;

  /// No description provided for @plannerBackToTimelineAction.
  ///
  /// In en, this message translates to:
  /// **'Back to timeline'**
  String get plannerBackToTimelineAction;

  /// No description provided for @plannerLocalOnlyMessage.
  ///
  /// In en, this message translates to:
  /// **'Planner changes are local to this app state and are not synchronized to a backend.'**
  String get plannerLocalOnlyMessage;

  /// No description provided for @activityAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get activityAddTitle;

  /// No description provided for @activityEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit activity'**
  String get activityEditTitle;

  /// No description provided for @activityCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get activityCloseAction;

  /// No description provided for @activityTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity title'**
  String get activityTitleLabel;

  /// No description provided for @activityNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get activityNotesLabel;

  /// No description provided for @activityDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get activityDayLabel;

  /// No description provided for @activityStartTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get activityStartTimeLabel;

  /// No description provided for @activityEndTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get activityEndTimeLabel;

  /// No description provided for @activityTimeHint.
  ///
  /// In en, this message translates to:
  /// **'Use HH:mm'**
  String get activityTimeHint;

  /// No description provided for @activityCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get activityCategoryLabel;

  /// No description provided for @activityAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get activityAddAction;

  /// No description provided for @activitySaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get activitySaveAction;

  /// No description provided for @activityAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add this activity'**
  String get activityAddSemantic;

  /// No description provided for @activitySaveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Save this activity'**
  String get activitySaveSemantic;

  /// No description provided for @activityTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an activity title.'**
  String get activityTitleRequired;

  /// No description provided for @activityInvalidTimeRange.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid time range where end time is later than start time.'**
  String get activityInvalidTimeRange;

  /// No description provided for @activityOutOfRangeDay.
  ///
  /// In en, this message translates to:
  /// **'Select a day inside this trip.'**
  String get activityOutOfRangeDay;

  /// No description provided for @activitySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this activity for the selected trip day.'**
  String get activitySaveFailed;

  /// No description provided for @activityAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Activity added locally.'**
  String get activityAddedMessage;

  /// No description provided for @activitySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Activity updated locally.'**
  String get activitySavedMessage;

  /// No description provided for @activityDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity details'**
  String get activityDetailTitle;

  /// No description provided for @activityEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get activityEditAction;

  /// No description provided for @activityEditSemantic.
  ///
  /// In en, this message translates to:
  /// **'Edit {title}'**
  String activityEditSemantic(String title);

  /// No description provided for @activityViewPlaceAction.
  ///
  /// In en, this message translates to:
  /// **'View place'**
  String get activityViewPlaceAction;

  /// No description provided for @activityEstimatedCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost'**
  String get activityEstimatedCostLabel;

  /// No description provided for @activityDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete activity'**
  String get activityDeleteAction;

  /// No description provided for @activityDeleteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}'**
  String activityDeleteSemantic(String title);

  /// No description provided for @activityDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete activity?'**
  String get activityDeleteConfirmTitle;

  /// No description provided for @activityDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from this trip day?'**
  String activityDeleteConfirmMessage(String title);

  /// No description provided for @activityDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Activity deleted.'**
  String get activityDeletedMessage;

  /// No description provided for @activityConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get activityConflictTitle;

  /// No description provided for @activityConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" overlaps {time}. Change time or keep both activities explicitly.'**
  String activityConflictMessage(String title, String time);

  /// No description provided for @activityConflictChangeTime.
  ///
  /// In en, this message translates to:
  /// **'Change time'**
  String get activityConflictChangeTime;

  /// No description provided for @activityConflictAddAnyway.
  ///
  /// In en, this message translates to:
  /// **'Add anyway'**
  String get activityConflictAddAnyway;

  /// No description provided for @activityConflictSaveAnyway.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get activityConflictSaveAnyway;

  /// No description provided for @activityConflictKeepBothTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep both activities?'**
  String get activityConflictKeepBothTitle;

  /// No description provided for @activityConflictKeepBothMessage.
  ///
  /// In en, this message translates to:
  /// **'This will preserve both overlapping activities. No activity will be moved or overwritten.'**
  String get activityConflictKeepBothMessage;

  /// No description provided for @activityConflictKeepBothAction.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get activityConflictKeepBothAction;

  /// No description provided for @quickAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quickAddTitle;

  /// No description provided for @quickAddSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search places or activities'**
  String get quickAddSearchHint;

  /// No description provided for @quickAddSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for {day}'**
  String quickAddSuggestionsTitle(String day);

  /// No description provided for @quickAddPlaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add {place} to an actual trip day.'**
  String quickAddPlaceSubtitle(String place);

  /// No description provided for @quickAddNoTripTitle.
  ///
  /// In en, this message translates to:
  /// **'No trip available'**
  String get quickAddNoTripTitle;

  /// No description provided for @quickAddNoTripMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a trip before adding this place to a timeline.'**
  String get quickAddNoTripMessage;

  /// No description provided for @quickAddNoPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get quickAddNoPlacesTitle;

  /// No description provided for @quickAddNoPlacesMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another local search term.'**
  String get quickAddNoPlacesMessage;

  /// No description provided for @quickAddSelectTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Select trip'**
  String get quickAddSelectTripLabel;

  /// No description provided for @quickAddSelectDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Select day'**
  String get quickAddSelectDayLabel;

  /// No description provided for @quickAddSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Add to Day {day}'**
  String quickAddSubmitAction(int day);

  /// No description provided for @quickAddAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'{place} added to {trip} · Day {day}'**
  String quickAddAddedMessage(String place, String trip, int day);

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
  /// **'The wishlist (quick-saved places) is not connected to the backend yet for real accounts. Saved collections are synced with your account below.'**
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

  /// No description provided for @savedPlacesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your saved travel shortlist, resolved from current public place data.'**
  String get savedPlacesSubtitle;

  /// No description provided for @savedPlacesDemoBoundary.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode saves are local presentation data. They are not synchronized with the wishlist API.'**
  String get savedPlacesDemoBoundary;

  /// No description provided for @savedPlacesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get savedPlacesEmptyTitle;

  /// No description provided for @savedPlacesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Save a public place from Explore, search, category discovery, or place details.'**
  String get savedPlacesEmptyMessage;

  /// No description provided for @savedPlacesCountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved place} other{{count} saved places}}'**
  String savedPlacesCountSemantic(int count);

  /// No description provided for @savedPlacesFilterSemantic.
  ///
  /// In en, this message translates to:
  /// **'Saved place filters'**
  String get savedPlacesFilterSemantic;

  /// No description provided for @savedPlacesSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest saved'**
  String get savedPlacesSortNewest;

  /// No description provided for @savedPlacesSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get savedPlacesSortName;

  /// No description provided for @savedPlacesCollectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 collection} other{{count} collections}}'**
  String savedPlacesCollectionCount(int count);

  /// No description provided for @savedPlacesCollectionCountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 saved collection} other{{count} saved collections}}'**
  String savedPlacesCollectionCountSemantic(int count);

  /// No description provided for @savedPlacesAllSavedTab.
  ///
  /// In en, this message translates to:
  /// **'All saved ({count})'**
  String savedPlacesAllSavedTab(int count);

  /// No description provided for @savedPlacesCollectionsTab.
  ///
  /// In en, this message translates to:
  /// **'Collections ({count})'**
  String savedPlacesCollectionsTab(int count);

  /// No description provided for @savedPlacesSectionTabsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Saved places sections'**
  String get savedPlacesSectionTabsSemantic;

  /// No description provided for @savedPlacesWishlistBoundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Wishlist and notes'**
  String get savedPlacesWishlistBoundaryTitle;

  /// No description provided for @savedPlacesWishlistBoundaryMessage.
  ///
  /// In en, this message translates to:
  /// **'The wishlist and private notes are local Demo Mode data until backend persistence is connected.'**
  String get savedPlacesWishlistBoundaryMessage;

  /// No description provided for @savedPlacesCollectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get savedPlacesCollectionsTitle;

  /// No description provided for @savedPlacesCollectionsBoundaryMessage.
  ///
  /// In en, this message translates to:
  /// **'Collections sync with /api/me/collections for real accounts; Demo Mode uses local data only. Adding a place to a collection never changes the wishlist.'**
  String get savedPlacesCollectionsBoundaryMessage;

  /// No description provided for @savedPlacesCollectionNetworkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the backend. Check your connection and try again.'**
  String get savedPlacesCollectionNetworkErrorMessage;

  /// No description provided for @savedPlacesCollectionServerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The backend had a problem completing this action. Please try again.'**
  String get savedPlacesCollectionServerErrorMessage;

  /// No description provided for @savedPlacesCollectionUnauthenticatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Please sign in again to continue.'**
  String get savedPlacesCollectionUnauthenticatedMessage;

  /// No description provided for @savedPlacesCollectionPlaceHydrationMessage.
  ///
  /// In en, this message translates to:
  /// **'Full place details are not synced yet for real collections. View details and Add to trip arrive in a later phase.'**
  String get savedPlacesCollectionPlaceHydrationMessage;

  /// No description provided for @savedPlacesCollectionAddPlaceDeferredTitle.
  ///
  /// In en, this message translates to:
  /// **'Adding places arrives later'**
  String get savedPlacesCollectionAddPlaceDeferredTitle;

  /// No description provided for @savedPlacesCollectionAddPlaceDeferredMessage.
  ///
  /// In en, this message translates to:
  /// **'Choosing a saved place to add to a real collection is not available yet. This will be connected in a later phase.'**
  String get savedPlacesCollectionAddPlaceDeferredMessage;

  /// No description provided for @savedPlacesCollectionCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create collection'**
  String get savedPlacesCollectionCreateAction;

  /// No description provided for @savedPlacesCollectionCreateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create a saved collection'**
  String get savedPlacesCollectionCreateSemantic;

  /// No description provided for @savedPlacesCollectionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No collections yet'**
  String get savedPlacesCollectionsEmptyTitle;

  /// No description provided for @savedPlacesCollectionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a private collection for a destination, weekend idea, or shortlist.'**
  String get savedPlacesCollectionsEmptyMessage;

  /// No description provided for @savedPlacesCollectionItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place} other{{count} places}}'**
  String savedPlacesCollectionItemCount(int count);

  /// No description provided for @savedPlacesCollectionItemCountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 place in collection} other{{count} places in collection}}'**
  String savedPlacesCollectionItemCountSemantic(int count);

  /// No description provided for @savedPlacesCollectionCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{collection}, {count, plural, =1{1 place} other{{count} places}}'**
  String savedPlacesCollectionCardSemantic(String collection, int count);

  /// No description provided for @savedPlacesCollectionPrivateLabel.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get savedPlacesCollectionPrivateLabel;

  /// No description provided for @savedPlacesCollectionVisibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get savedPlacesCollectionVisibleLabel;

  /// No description provided for @savedPlacesCollectionUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String savedPlacesCollectionUpdated(String date);

  /// No description provided for @savedPlacesCollectionOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get savedPlacesCollectionOpenAction;

  /// No description provided for @savedPlacesCollectionOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open collection {collection}'**
  String savedPlacesCollectionOpenSemantic(String collection);

  /// No description provided for @savedPlacesCollectionEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get savedPlacesCollectionEditAction;

  /// No description provided for @savedPlacesCollectionEditSemantic.
  ///
  /// In en, this message translates to:
  /// **'Edit collection {collection}'**
  String savedPlacesCollectionEditSemantic(String collection);

  /// No description provided for @savedPlacesCollectionDeleteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Delete collection {collection}'**
  String savedPlacesCollectionDeleteSemantic(String collection);

  /// No description provided for @savedPlacesCollectionDetailSemantic.
  ///
  /// In en, this message translates to:
  /// **'{collection}, {count, plural, =1{1 place} other{{count} places}}'**
  String savedPlacesCollectionDetailSemantic(String collection, int count);

  /// No description provided for @savedPlacesCollectionBackAction.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get savedPlacesCollectionBackAction;

  /// No description provided for @savedPlacesCollectionBackSemantic.
  ///
  /// In en, this message translates to:
  /// **'Back to saved collections'**
  String get savedPlacesCollectionBackSemantic;

  /// No description provided for @savedPlacesCollectionAddSavedAction.
  ///
  /// In en, this message translates to:
  /// **'Add saved place'**
  String get savedPlacesCollectionAddSavedAction;

  /// No description provided for @savedPlacesCollectionAddSavedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a saved place to {collection}'**
  String savedPlacesCollectionAddSavedSemantic(String collection);

  /// No description provided for @savedPlacesCollectionEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection is empty'**
  String get savedPlacesCollectionEmptyTitle;

  /// No description provided for @savedPlacesCollectionEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an already-saved public place. This will not change your wishlist.'**
  String get savedPlacesCollectionEmptyMessage;

  /// No description provided for @savedPlacesCollectionPlaceSemantic.
  ///
  /// In en, this message translates to:
  /// **'{place}, added {date}'**
  String savedPlacesCollectionPlaceSemantic(String place, String date);

  /// No description provided for @savedPlacesCollectionAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String savedPlacesCollectionAddedOn(String date);

  /// No description provided for @savedPlacesCollectionRemovePlaceAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get savedPlacesCollectionRemovePlaceAction;

  /// No description provided for @savedPlacesCollectionRemovePlaceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove {place} from this collection'**
  String savedPlacesCollectionRemovePlaceSemantic(String place);

  /// No description provided for @savedPlacesCollectionStaleItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Collection item unavailable'**
  String get savedPlacesCollectionStaleItemTitle;

  /// No description provided for @savedPlacesCollectionStaleItemMessage.
  ///
  /// In en, this message translates to:
  /// **'Place reference {placeId} no longer resolves to public place data.'**
  String savedPlacesCollectionStaleItemMessage(int placeId);

  /// No description provided for @savedPlacesCollectionRemoveStaleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove unavailable place from collection'**
  String get savedPlacesCollectionRemoveStaleSemantic;

  /// No description provided for @savedPlacesCollectionMembershipIn.
  ///
  /// In en, this message translates to:
  /// **'In {collection}'**
  String savedPlacesCollectionMembershipIn(String collection);

  /// No description provided for @savedPlacesCollectionMembershipOut.
  ///
  /// In en, this message translates to:
  /// **'Not in {collection}'**
  String savedPlacesCollectionMembershipOut(String collection);

  /// No description provided for @savedPlacesCollectionRemoveMembershipSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove {place} from {collection}'**
  String savedPlacesCollectionRemoveMembershipSemantic(
      String place, String collection);

  /// No description provided for @savedPlacesCollectionAddMembershipSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add {place} to {collection}'**
  String savedPlacesCollectionAddMembershipSemantic(
      String place, String collection);

  /// No description provided for @savedPlacesCollectionInAction.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get savedPlacesCollectionInAction;

  /// No description provided for @savedPlacesCollectionAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get savedPlacesCollectionAddAction;

  /// No description provided for @savedPlacesCollectionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit collection'**
  String get savedPlacesCollectionEditTitle;

  /// No description provided for @savedPlacesCollectionCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create collection'**
  String get savedPlacesCollectionCreateTitle;

  /// No description provided for @savedPlacesCollectionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Collection name'**
  String get savedPlacesCollectionNameLabel;

  /// No description provided for @savedPlacesCollectionNameHelper.
  ///
  /// In en, this message translates to:
  /// **'Required, up to {maxLength} characters.'**
  String savedPlacesCollectionNameHelper(int maxLength);

  /// No description provided for @savedPlacesCollectionDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get savedPlacesCollectionDescriptionLabel;

  /// No description provided for @savedPlacesCollectionDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional, up to {maxLength} characters.'**
  String savedPlacesCollectionDescriptionHelper(int maxLength);

  /// No description provided for @savedPlacesCollectionCoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL'**
  String get savedPlacesCollectionCoverLabel;

  /// No description provided for @savedPlacesCollectionCoverHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional URL text, up to {maxLength} characters.'**
  String savedPlacesCollectionCoverHelper(int maxLength);

  /// No description provided for @savedPlacesCollectionPrivateHelper.
  ///
  /// In en, this message translates to:
  /// **'All collection endpoints are owner-scoped in this phase.'**
  String get savedPlacesCollectionPrivateHelper;

  /// No description provided for @savedPlacesCollectionSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save collection'**
  String get savedPlacesCollectionSaveAction;

  /// No description provided for @savedPlacesCollectionCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Created collection {collection}.'**
  String savedPlacesCollectionCreatedMessage(String collection);

  /// No description provided for @savedPlacesCollectionUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated collection {collection}.'**
  String savedPlacesCollectionUpdatedMessage(String collection);

  /// No description provided for @savedPlacesCollectionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {collection}?'**
  String savedPlacesCollectionDeleteTitle(String collection);

  /// No description provided for @savedPlacesCollectionDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {collection}? Only collection membership is removed. Places, wishlist notes, trips, bookings, reviews, and documents are preserved.'**
  String savedPlacesCollectionDeleteMessage(String collection);

  /// No description provided for @savedPlacesCollectionDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete collection'**
  String get savedPlacesCollectionDeleteAction;

  /// No description provided for @savedPlacesCollectionDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted collection {collection}.'**
  String savedPlacesCollectionDeletedMessage(String collection);

  /// No description provided for @savedPlacesCollectionAddSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Add saved places to {collection}'**
  String savedPlacesCollectionAddSavedTitle(String collection);

  /// No description provided for @savedPlacesCollectionAddSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Only current saved places are listed. Collection membership stays separate from the wishlist.'**
  String get savedPlacesCollectionAddSavedMessage;

  /// No description provided for @savedPlacesManageCollectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Collections for {place}'**
  String savedPlacesManageCollectionsTitle(String place);

  /// No description provided for @savedPlacesManageCollectionsMessage.
  ///
  /// In en, this message translates to:
  /// **'Add or remove this saved place from private Demo Mode collections.'**
  String get savedPlacesManageCollectionsMessage;

  /// No description provided for @savedPlacesCollectionSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Collection updated.'**
  String get savedPlacesCollectionSavedMessage;

  /// No description provided for @savedPlacesCollectionsRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved collections are not connected to the backend yet for real accounts.'**
  String get savedPlacesCollectionsRealUnavailableMessage;

  /// No description provided for @savedPlacesCollectionInvalidNameMessage.
  ///
  /// In en, this message translates to:
  /// **'Collection name is required and limited to {maxLength} characters.'**
  String savedPlacesCollectionInvalidNameMessage(int maxLength);

  /// No description provided for @savedPlacesCollectionInvalidDescriptionMessage.
  ///
  /// In en, this message translates to:
  /// **'Collection description is limited to {maxLength} characters.'**
  String savedPlacesCollectionInvalidDescriptionMessage(int maxLength);

  /// No description provided for @savedPlacesCollectionInvalidCoverMessage.
  ///
  /// In en, this message translates to:
  /// **'Collection cover URL is limited to {maxLength} characters.'**
  String savedPlacesCollectionInvalidCoverMessage(int maxLength);

  /// No description provided for @savedPlacesCollectionLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You have reached the local limit of {maxCount} collections.'**
  String savedPlacesCollectionLimitMessage(int maxCount);

  /// No description provided for @savedPlacesCollectionNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This collection is unavailable.'**
  String get savedPlacesCollectionNotFoundMessage;

  /// No description provided for @savedPlacesCollectionPlaceNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This place cannot be added because it no longer resolves to public place data.'**
  String get savedPlacesCollectionPlaceNotFoundMessage;

  /// No description provided for @savedPlacesCollectionDuplicatePlaceMessage.
  ///
  /// In en, this message translates to:
  /// **'{place} is already in {collection}.'**
  String savedPlacesCollectionDuplicatePlaceMessage(
      String place, String collection);

  /// No description provided for @savedPlacesCollectionItemNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This place is not in the selected collection.'**
  String get savedPlacesCollectionItemNotFoundMessage;

  /// No description provided for @savedPlacesCollectionItemLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'This collection has reached the local limit of {maxCount} places.'**
  String savedPlacesCollectionItemLimitMessage(int maxCount);

  /// No description provided for @savedPlacesCollectionAddedPlaceMessage.
  ///
  /// In en, this message translates to:
  /// **'Added {place} to {collection}.'**
  String savedPlacesCollectionAddedPlaceMessage(
      String place, String collection);

  /// No description provided for @savedPlacesCollectionRemovedPlaceMessage.
  ///
  /// In en, this message translates to:
  /// **'Removed {place} from {collection}.'**
  String savedPlacesCollectionRemovedPlaceMessage(
      String place, String collection);

  /// No description provided for @savedPlacesAddToCollectionAction.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get savedPlacesAddToCollectionAction;

  /// No description provided for @savedPlacesManageCollectionsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Manage collections for {place}'**
  String savedPlacesManageCollectionsSemantic(String place);

  /// No description provided for @savedPlacesSavedOn.
  ///
  /// In en, this message translates to:
  /// **'Saved {date}'**
  String savedPlacesSavedOn(String date);

  /// No description provided for @savedPlacesNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String savedPlacesNote(String note);

  /// No description provided for @savedPlacesEditNoteAction.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get savedPlacesEditNoteAction;

  /// No description provided for @savedPlacesEditNoteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Edit private note for {place}'**
  String savedPlacesEditNoteSemantic(String place);

  /// No description provided for @savedPlacesEditNoteTitle.
  ///
  /// In en, this message translates to:
  /// **'Private note for {place}'**
  String savedPlacesEditNoteTitle(String place);

  /// No description provided for @savedPlacesNoteFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get savedPlacesNoteFieldLabel;

  /// No description provided for @savedPlacesNoteFieldHelper.
  ///
  /// In en, this message translates to:
  /// **'Up to {maxLength} characters. Leave blank to clear it.'**
  String savedPlacesNoteFieldHelper(int maxLength);

  /// No description provided for @savedPlacesNoteSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get savedPlacesNoteSaveAction;

  /// No description provided for @savedPlacesNoteSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated the private note for {place}.'**
  String savedPlacesNoteSavedMessage(String place);

  /// No description provided for @savedPlacesNoteTooLongMessage.
  ///
  /// In en, this message translates to:
  /// **'Private notes are limited to 500 characters.'**
  String get savedPlacesNoteTooLongMessage;

  /// No description provided for @savedPlacesSaveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Save {place}'**
  String savedPlacesSaveSemantic(String place);

  /// No description provided for @savedPlacesRemoveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove saved place {place}'**
  String savedPlacesRemoveSemantic(String place);

  /// No description provided for @savedPlacesSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved {place} locally.'**
  String savedPlacesSavedMessage(String place);

  /// No description provided for @savedPlacesAlreadySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{place} is already saved.'**
  String savedPlacesAlreadySavedMessage(String place);

  /// No description provided for @savedPlacesRemovedPlace.
  ///
  /// In en, this message translates to:
  /// **'Removed {place} from local saved places.'**
  String savedPlacesRemovedPlace(String place);

  /// No description provided for @savedPlacesActionForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'This saved place belongs to another traveler.'**
  String get savedPlacesActionForbiddenMessage;

  /// No description provided for @savedPlacesMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved place unavailable'**
  String get savedPlacesMissingTitle;

  /// No description provided for @savedPlacesMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'This saved place no longer resolves to a public place.'**
  String get savedPlacesMissingMessage;

  /// No description provided for @savedPlacesMissingRecordMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved place reference {placeId} no longer resolves to public place data.'**
  String savedPlacesMissingRecordMessage(int placeId);

  /// No description provided for @savedPlacesRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get savedPlacesRemoveAction;

  /// No description provided for @savedPlacesRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove saved place?'**
  String get savedPlacesRemoveConfirmTitle;

  /// No description provided for @savedPlacesRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {place} from your local saved places? The place, trips, bookings, reviews, and wallet items will not be deleted.'**
  String savedPlacesRemoveConfirmMessage(String place);

  /// No description provided for @savedPlacesRemoveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Remove saved place'**
  String get savedPlacesRemoveConfirmAction;

  /// No description provided for @savedPlacesViewDetailsAction.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get savedPlacesViewDetailsAction;

  /// No description provided for @savedPlacesOpenDetailSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open details for {place}'**
  String savedPlacesOpenDetailSemantic(String place);

  /// No description provided for @savedPlacesHotelAction.
  ///
  /// In en, this message translates to:
  /// **'View rooms'**
  String get savedPlacesHotelAction;

  /// No description provided for @savedPlacesCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{place}, saved {date}'**
  String savedPlacesCardSemantic(String place, String date);

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

  /// No description provided for @notificationCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A local in-app activity stream for bookings, payments, trips, reviews, rewards, wallet documents, and account notices.'**
  String get notificationCenterSubtitle;

  /// No description provided for @notificationCenterSemantic.
  ///
  /// In en, this message translates to:
  /// **'Notification and activity center'**
  String get notificationCenterSemantic;

  /// No description provided for @notificationRealBoundary.
  ///
  /// In en, this message translates to:
  /// **'Real accounts will use the committed in-app notification API when the frontend repository layer is connected. Push delivery, device tokens, and external notification permissions are not connected in this UI phase.'**
  String get notificationRealBoundary;

  /// No description provided for @notificationDemoModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Local Demo Mode'**
  String get notificationDemoModeLabel;

  /// No description provided for @notificationPreferenceBoundary.
  ///
  /// In en, this message translates to:
  /// **'Notification toggles are local device preferences only. They do not register push tokens or sync server preferences.'**
  String get notificationPreferenceBoundary;

  /// No description provided for @notificationUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 unread} =1{1 unread} other{{count} unread}}'**
  String notificationUnreadCount(int count);

  /// No description provided for @notificationUnreadCountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread notifications} =1{1 unread notification} other{{count} unread notifications}}'**
  String notificationUnreadCountSemantic(int count);

  /// No description provided for @notificationTotalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 notices} =1{1 notice} other{{count} notices}}'**
  String notificationTotalCount(int count);

  /// No description provided for @notificationMarkAllReadSemantic.
  ///
  /// In en, this message translates to:
  /// **'Mark all demo notifications as read'**
  String get notificationMarkAllReadSemantic;

  /// No description provided for @notificationMarkAllReadResult.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread notifications changed.} =1{Marked 1 notification as read.} other{Marked {count} notifications as read.}}'**
  String notificationMarkAllReadResult(int count);

  /// No description provided for @notificationFilterSemantic.
  ///
  /// In en, this message translates to:
  /// **'Notification filters'**
  String get notificationFilterSemantic;

  /// No description provided for @notificationFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationFilterAll;

  /// No description provided for @notificationFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationFilterUnread;

  /// No description provided for @notificationFilterBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get notificationFilterBookings;

  /// No description provided for @notificationFilterPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get notificationFilterPayments;

  /// No description provided for @notificationFilterTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get notificationFilterTrips;

  /// No description provided for @notificationFilterReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get notificationFilterReviews;

  /// No description provided for @notificationFilterRewards.
  ///
  /// In en, this message translates to:
  /// **'Rewards'**
  String get notificationFilterRewards;

  /// No description provided for @notificationFilterWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get notificationFilterWallet;

  /// No description provided for @notificationFilterSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationFilterSystem;

  /// No description provided for @notificationFilterEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No notifications match this filter.'**
  String get notificationFilterEmptyMessage;

  /// No description provided for @notificationReadLabel.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get notificationReadLabel;

  /// No description provided for @notificationUnreadLabel.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationUnreadLabel;

  /// No description provided for @notificationCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'{readState}. {type} notification. {title}. {time}.'**
  String notificationCardSemantic(
      String readState, String type, String title, String time);

  /// No description provided for @notificationMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification unavailable'**
  String get notificationMissingTitle;

  /// No description provided for @notificationMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'This local notification is no longer available.'**
  String get notificationMissingMessage;

  /// No description provided for @notificationCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get notificationCreatedAtLabel;

  /// No description provided for @notificationReadAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Read at'**
  String get notificationReadAtLabel;

  /// No description provided for @notificationPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Private booking and payment references are masked or omitted in this activity view.'**
  String get notificationPrivacyNote;

  /// No description provided for @notificationOpenTargetSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open notification target'**
  String get notificationOpenTargetSemantic;

  /// No description provided for @notificationDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get notificationDeleteAction;

  /// No description provided for @notificationDeleteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Delete this demo notification'**
  String get notificationDeleteSemantic;

  /// No description provided for @notificationDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete notification?'**
  String get notificationDeleteConfirmTitle;

  /// No description provided for @notificationDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this local demo notification? The linked booking, payment, trip, review, reward, or wallet item will not be deleted.'**
  String get notificationDeleteConfirmMessage;

  /// No description provided for @notificationDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete notification'**
  String get notificationDeleteConfirmAction;

  /// No description provided for @notificationDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted from local demo data.'**
  String get notificationDeletedMessage;

  /// No description provided for @notificationTargetUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This notification has no linked screen.'**
  String get notificationTargetUnavailable;

  /// No description provided for @notificationTargetMissing.
  ///
  /// In en, this message translates to:
  /// **'The linked item is no longer available in local demo data.'**
  String get notificationTargetMissing;

  /// No description provided for @notificationNoTargetAction.
  ///
  /// In en, this message translates to:
  /// **'No linked screen'**
  String get notificationNoTargetAction;

  /// No description provided for @notificationOpenBooking.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get notificationOpenBooking;

  /// No description provided for @notificationOpenPayment.
  ///
  /// In en, this message translates to:
  /// **'View payment status'**
  String get notificationOpenPayment;

  /// No description provided for @notificationOpenTrip.
  ///
  /// In en, this message translates to:
  /// **'View trip'**
  String get notificationOpenTrip;

  /// No description provided for @notificationOpenTripCompanion.
  ///
  /// In en, this message translates to:
  /// **'View companions'**
  String get notificationOpenTripCompanion;

  /// No description provided for @notificationOpenTripDocuments.
  ///
  /// In en, this message translates to:
  /// **'View trip documents'**
  String get notificationOpenTripDocuments;

  /// No description provided for @notificationOpenReview.
  ///
  /// In en, this message translates to:
  /// **'View review'**
  String get notificationOpenReview;

  /// No description provided for @notificationOpenRewards.
  ///
  /// In en, this message translates to:
  /// **'View rewards'**
  String get notificationOpenRewards;

  /// No description provided for @notificationOpenWallet.
  ///
  /// In en, this message translates to:
  /// **'View travel wallet'**
  String get notificationOpenWallet;

  /// No description provided for @notificationTypeBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get notificationTypeBooking;

  /// No description provided for @notificationTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get notificationTypePayment;

  /// No description provided for @notificationTypeReservation.
  ///
  /// In en, this message translates to:
  /// **'Reservation'**
  String get notificationTypeReservation;

  /// No description provided for @notificationTypeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get notificationTypeSystem;

  /// No description provided for @notificationTypePromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get notificationTypePromotion;

  /// No description provided for @notificationTypeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get notificationTypeReview;

  /// No description provided for @notificationTypePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get notificationTypePartner;

  /// No description provided for @notificationTypeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get notificationTypeAdmin;

  /// No description provided for @notificationTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notificationTypeMessage;

  /// No description provided for @notificationTypeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get notificationTypeTrip;

  /// No description provided for @notificationPriorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get notificationPriorityLow;

  /// No description provided for @notificationPriorityNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get notificationPriorityNormal;

  /// No description provided for @notificationPriorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get notificationPriorityHigh;

  /// No description provided for @notificationPriorityUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get notificationPriorityUrgent;

  /// No description provided for @notificationDemoBookingModifiedTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking changes saved'**
  String get notificationDemoBookingModifiedTitle;

  /// No description provided for @notificationDemoBookingModifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your pending Da Lat stay keeps the same booking code while the local modification preview updates its stay snapshot.'**
  String get notificationDemoBookingModifiedMessage;

  /// No description provided for @notificationDemoPaymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo payment completed'**
  String get notificationDemoPaymentSuccessTitle;

  /// No description provided for @notificationDemoPaymentSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'The local checkout preview recorded a paid MOCK payment. No real charge was made.'**
  String get notificationDemoPaymentSuccessMessage;

  /// No description provided for @notificationDemoPaymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo payment needs attention'**
  String get notificationDemoPaymentFailedTitle;

  /// No description provided for @notificationDemoPaymentFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'A local payment preview did not complete. Review the booking before trying another demo checkout action.'**
  String get notificationDemoPaymentFailedMessage;

  /// No description provided for @notificationDemoTripCollaborationTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip collaboration updated'**
  String get notificationDemoTripCollaborationTitle;

  /// No description provided for @notificationDemoTripCollaborationMessage.
  ///
  /// In en, this message translates to:
  /// **'Your Da Lat trip companion list has a local collaboration update ready to review.'**
  String get notificationDemoTripCollaborationMessage;

  /// No description provided for @notificationDemoItineraryReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Itinerary reminder delivered'**
  String get notificationDemoItineraryReminderTitle;

  /// No description provided for @notificationDemoItineraryReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'The UI-9 reminder remains a trip reminder record; this is only the delivered in-app notification copy.'**
  String get notificationDemoItineraryReminderMessage;

  /// No description provided for @notificationDemoReviewReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Property replied to your review'**
  String get notificationDemoReviewReplyTitle;

  /// No description provided for @notificationDemoReviewReplyMessage.
  ///
  /// In en, this message translates to:
  /// **'The villa host response is available in your review detail without exposing moderation internals.'**
  String get notificationDemoReviewReplyMessage;

  /// No description provided for @notificationDemoRewardTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefit update available'**
  String get notificationDemoRewardTitle;

  /// No description provided for @notificationDemoRewardMessage.
  ///
  /// In en, this message translates to:
  /// **'A local rewards and benefits notice is ready in the rewards hub.'**
  String get notificationDemoRewardMessage;

  /// No description provided for @notificationDemoWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet document notice'**
  String get notificationDemoWalletTitle;

  /// No description provided for @notificationDemoWalletMessage.
  ///
  /// In en, this message translates to:
  /// **'A masked travel document note is available in your Travel Wallet.'**
  String get notificationDemoWalletMessage;

  /// No description provided for @notificationDemoSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'Account notice'**
  String get notificationDemoSystemTitle;

  /// No description provided for @notificationDemoSystemMessage.
  ///
  /// In en, this message translates to:
  /// **'Local demo account activity is shown here without push registration or device-token storage.'**
  String get notificationDemoSystemMessage;

  /// No description provided for @profileNotificationsUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No unread notifications} =1{1 unread notification} other{{count} unread notifications}}'**
  String profileNotificationsUnreadBadge(int count);

  /// No description provided for @exploreHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Where will you wander?'**
  String get exploreHeroTitle;

  /// No description provided for @exploreHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Curated places are local preview content. Personal trips stay local until a backend exists.'**
  String get exploreHeroSubtitle;

  /// No description provided for @exploreSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search cities, places, cafes, hotels...'**
  String get exploreSearchHint;

  /// No description provided for @exploreSearchActionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open search results'**
  String get exploreSearchActionSemantic;

  /// No description provided for @exploreFiltersSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open search filters'**
  String get exploreFiltersSemantic;

  /// No description provided for @exploreNoUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trip'**
  String get exploreNoUpcomingTitle;

  /// No description provided for @exploreNoUpcomingMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a local demo trip when you are ready to plan.'**
  String get exploreNoUpcomingMessage;

  /// No description provided for @exploreCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore by category'**
  String get exploreCategoriesTitle;

  /// No description provided for @exploreRecommendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended places'**
  String get exploreRecommendedTitle;

  /// No description provided for @exploreSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get exploreSeeAll;

  /// No description provided for @exploreNoPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'No places available'**
  String get exploreNoPlacesTitle;

  /// No description provided for @exploreNoPlacesMessage.
  ///
  /// In en, this message translates to:
  /// **'Curated Explore content will appear here when local data is available.'**
  String get exploreNoPlacesMessage;

  /// No description provided for @exploreUpcomingTripSemantic.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trip summary'**
  String get exploreUpcomingTripSemantic;

  /// No description provided for @explorePlanningProgress.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No activities planned yet} =1{1 planned activity} other{{count} planned activities}}'**
  String explorePlanningProgress(int count);

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore places'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search hotels, food, cafes, attractions...'**
  String get searchHint;

  /// No description provided for @searchClearSemantic.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get searchClearSemantic;

  /// No description provided for @searchModeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Search presentation mode'**
  String get searchModeSemantic;

  /// No description provided for @searchListMode.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get searchListMode;

  /// No description provided for @searchMapMode.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get searchMapMode;

  /// No description provided for @searchResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No places} =1{1 place} other{{count} places}}'**
  String searchResultCount(int count);

  /// No description provided for @searchClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get searchClearFilters;

  /// No description provided for @searchEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword, category, or tag.'**
  String get searchEmptyMessage;

  /// No description provided for @searchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get searchFiltersTitle;

  /// No description provided for @searchSortTitle.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get searchSortTitle;

  /// No description provided for @searchSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevant'**
  String get searchSortRelevance;

  /// No description provided for @searchSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get searchSortRating;

  /// No description provided for @searchSortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get searchSortDuration;

  /// No description provided for @searchTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get searchTagsTitle;

  /// No description provided for @searchApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get searchApplyFilters;

  /// No description provided for @searchBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to list'**
  String get searchBackToList;

  /// No description provided for @mapFallbackSemantic.
  ///
  /// In en, this message translates to:
  /// **'Non-live map preview'**
  String get mapFallbackSemantic;

  /// No description provided for @mapUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Map provider not connected'**
  String get mapUnavailableTitle;

  /// No description provided for @mapUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Live maps, routing, traffic, and exact coordinates are not connected yet. This preview is schematic only.'**
  String get mapUnavailableMessage;

  /// No description provided for @placeReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String placeReviewCount(int count);

  /// No description provided for @placeAddToTrip.
  ///
  /// In en, this message translates to:
  /// **'Add to trip'**
  String get placeAddToTrip;

  /// No description provided for @placeAddToTripSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add {place} to a trip'**
  String placeAddToTripSemantic(String place);

  /// No description provided for @placeHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get placeHighlightsTitle;

  /// No description provided for @placeUsefulInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Useful information'**
  String get placeUsefulInfoTitle;

  /// No description provided for @placeDurationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String placeDurationMinutes(int minutes);

  /// No description provided for @placeDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String placeDurationHours(int hours);

  /// No description provided for @placeDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String placeDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @savedPlacesDemoLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Saved places are local to this demo session.'**
  String get savedPlacesDemoLocalOnly;

  /// No description provided for @tripsTitle.
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get tripsTitle;

  /// No description provided for @tripsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Smart local sections derived from trip dates.'**
  String get tripsSubtitle;

  /// No description provided for @tripsCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create a trip'**
  String get tripsCreateAction;

  /// No description provided for @tripsCreateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create a new trip'**
  String get tripsCreateSemantic;

  /// No description provided for @tripsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get tripsEmptyTitle;

  /// No description provided for @tripsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first local trip to get started.'**
  String get tripsEmptyMessage;

  /// No description provided for @tripsRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Personal trip history is not connected to a backend repository yet.'**
  String get tripsRealUnavailableMessage;

  /// No description provided for @tripsOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get tripsOngoing;

  /// No description provided for @tripsUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripsUpcoming;

  /// No description provided for @tripsPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get tripsPast;

  /// No description provided for @tripsOngoingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trips are happening today.'**
  String get tripsOngoingEmpty;

  /// No description provided for @tripsUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming trips yet.'**
  String get tripsUpcomingEmpty;

  /// No description provided for @tripsPastEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet.'**
  String get tripsPastEmpty;

  /// No description provided for @tripCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Trip card for {trip}'**
  String tripCardSemantic(String trip);

  /// No description provided for @tripActionsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Actions for {trip}'**
  String tripActionsSemantic(String trip);

  /// No description provided for @tripEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get tripEditAction;

  /// No description provided for @tripDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete trip'**
  String get tripDeleteAction;

  /// No description provided for @tripDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete trip?'**
  String get tripDeleteConfirmTitle;

  /// No description provided for @tripDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{trip}\"? This also removes its timeline items and expenses.'**
  String tripDeleteConfirmMessage(String trip);

  /// No description provided for @tripDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip deleted.'**
  String get tripDeletedMessage;

  /// No description provided for @tripCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip created locally.'**
  String get tripCreatedMessage;

  /// No description provided for @tripDayCount.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day} other{{days} days}}'**
  String tripDayCount(int days);

  /// No description provided for @tripTravelerCount.
  ///
  /// In en, this message translates to:
  /// **'{travelers, plural, =1{1 traveler} other{{travelers} travelers}}'**
  String tripTravelerCount(int travelers);

  /// No description provided for @tripDateTravelerMeta.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end} · {travelers, plural, =1{1 traveler} other{{travelers} travelers}}'**
  String tripDateTravelerMeta(String start, String end, int travelers);

  /// No description provided for @tripDaysAway.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Starts today} =1{Starts tomorrow} other{Starts in {days} days}}'**
  String tripDaysAway(int days);

  /// No description provided for @createTripTitle.
  ///
  /// In en, this message translates to:
  /// **'New trip'**
  String get createTripTitle;

  /// No description provided for @createBackStep.
  ///
  /// In en, this message translates to:
  /// **'Back to previous step'**
  String get createBackStep;

  /// No description provided for @createCloseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Close create trip flow'**
  String get createCloseSemantic;

  /// No description provided for @createStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step}/3'**
  String createStepLabel(int step);

  /// No description provided for @createContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get createContinueAction;

  /// No description provided for @createContinueSemantic.
  ///
  /// In en, this message translates to:
  /// **'Continue to next create trip step'**
  String get createContinueSemantic;

  /// No description provided for @createSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Create trip'**
  String get createSubmitAction;

  /// No description provided for @createSubmitSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create this trip'**
  String get createSubmitSemantic;

  /// No description provided for @createDestinationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a destination.'**
  String get createDestinationRequired;

  /// No description provided for @createDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter start and end dates in dd/mm/yyyy format.'**
  String get createDatesRequired;

  /// No description provided for @createInvalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before start date.'**
  String get createInvalidDateRange;

  /// No description provided for @createInvalidTravelers.
  ///
  /// In en, this message translates to:
  /// **'Traveler count must be between 1 and 20.'**
  String get createInvalidTravelers;

  /// No description provided for @createDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard trip draft?'**
  String get createDiscardTitle;

  /// No description provided for @createDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your entered trip details will be lost.'**
  String get createDiscardMessage;

  /// No description provided for @createDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get createDiscardAction;

  /// No description provided for @createDestinationTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you want to go?'**
  String get createDestinationTitle;

  /// No description provided for @createDestinationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a supported destination from local data or type your own.'**
  String get createDestinationSubtitle;

  /// No description provided for @createDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get createDestinationLabel;

  /// No description provided for @createTripNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip name'**
  String get createTripNameLabel;

  /// No description provided for @createDestinationSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggested destinations'**
  String get createDestinationSuggestions;

  /// No description provided for @createDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'When will you go?'**
  String get createDatesTitle;

  /// No description provided for @createDatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter dates and traveler count for this local trip.'**
  String get createDatesSubtitle;

  /// No description provided for @createStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get createStartDateLabel;

  /// No description provided for @createEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get createEndDateLabel;

  /// No description provided for @createDateFormatHint.
  ///
  /// In en, this message translates to:
  /// **'Use dd/mm/yyyy'**
  String get createDateFormatHint;

  /// No description provided for @createTravelersLabel.
  ///
  /// In en, this message translates to:
  /// **'Travelers'**
  String get createTravelersLabel;

  /// No description provided for @createDecreaseTravelers.
  ///
  /// In en, this message translates to:
  /// **'Decrease travelers'**
  String get createDecreaseTravelers;

  /// No description provided for @createIncreaseTravelers.
  ///
  /// In en, this message translates to:
  /// **'Increase travelers'**
  String get createIncreaseTravelers;

  /// No description provided for @createBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget (VND)'**
  String get createBudgetLabel;

  /// No description provided for @createPersonalizationTitle.
  ///
  /// In en, this message translates to:
  /// **'Shape the trip your way'**
  String get createPersonalizationTitle;

  /// No description provided for @createPersonalizationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'These preferences are local draft presentation only.'**
  String get createPersonalizationSubtitle;

  /// No description provided for @createPreferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get createPreferencesTitle;

  /// No description provided for @createPreferenceFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get createPreferenceFood;

  /// No description provided for @createPreferenceCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get createPreferenceCulture;

  /// No description provided for @createPreferenceNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get createPreferenceNature;

  /// No description provided for @createPreferenceRelax.
  ///
  /// In en, this message translates to:
  /// **'Relax'**
  String get createPreferenceRelax;

  /// No description provided for @createPreferenceAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get createPreferenceAdventure;

  /// No description provided for @createPreferenceShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get createPreferenceShopping;

  /// No description provided for @createPaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get createPaceTitle;

  /// No description provided for @createPaceSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get createPaceSlow;

  /// No description provided for @createPaceBalanced.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get createPaceBalanced;

  /// No description provided for @createPacePacked.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get createPacePacked;

  /// No description provided for @createBudgetStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget style'**
  String get createBudgetStyleTitle;

  /// No description provided for @createBudgetSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get createBudgetSaving;

  /// No description provided for @createBudgetComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get createBudgetComfort;

  /// No description provided for @createBudgetPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get createBudgetPremium;

  /// No description provided for @createNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get createNotesLabel;

  /// No description provided for @createPersonalizationLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Preferences are kept in this draft only and are not sent to any backend.'**
  String get createPersonalizationLocalOnly;

  /// No description provided for @createReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get createReviewTitle;

  /// No description provided for @createReviewSummary.
  ///
  /// In en, this message translates to:
  /// **'{title} · {destination} · {start} to {end} · {travelers, plural, =1{1 traveler} other{{travelers} travelers}}'**
  String createReviewSummary(String title, String destination, String start,
      String end, int travelers);

  /// No description provided for @createConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get createConfirmAction;

  /// No description provided for @editTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {trip}'**
  String editTripTitle(String trip);

  /// No description provided for @editTripHeading.
  ///
  /// In en, this message translates to:
  /// **'Update your trip'**
  String get editTripHeading;

  /// No description provided for @editTripSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Update trip'**
  String get editTripSaveAction;

  /// No description provided for @editTripUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip updated.'**
  String get editTripUpdatedMessage;

  /// No description provided for @editMoveActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Move activities?'**
  String get editMoveActivitiesTitle;

  /// No description provided for @editMoveActivitiesMessage.
  ///
  /// In en, this message translates to:
  /// **'This shorter trip has {days, plural, =1{1 day} other{{days} days}}. Activities from removed days will move to the new last day.'**
  String editMoveActivitiesMessage(int days);

  /// No description provided for @editMoveActivitiesAction.
  ///
  /// In en, this message translates to:
  /// **'Move to last day'**
  String get editMoveActivitiesAction;

  /// No description provided for @tripOverviewProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip progress'**
  String get tripOverviewProgressTitle;

  /// No description provided for @tripOverviewProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String tripOverviewProgressValue(int percent);

  /// No description provided for @tripOverviewTimelineAction.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get tripOverviewTimelineAction;

  /// No description provided for @tripOverviewExpensesAction.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get tripOverviewExpensesAction;

  /// No description provided for @tripOverviewActivitiesMetric.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get tripOverviewActivitiesMetric;

  /// No description provided for @tripOverviewSpentMetric.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get tripOverviewSpentMetric;

  /// No description provided for @tripOverviewBudgetMetric.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get tripOverviewBudgetMetric;

  /// No description provided for @tripOverviewNextTitle.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tripOverviewNextTitle;

  /// No description provided for @tripOverviewNoActivitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No activities yet'**
  String get tripOverviewNoActivitiesTitle;

  /// No description provided for @tripOverviewNoActivitiesMessage.
  ///
  /// In en, this message translates to:
  /// **'Open the existing timeline to add activities.'**
  String get tripOverviewNoActivitiesMessage;

  /// No description provided for @tripOverviewDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String tripOverviewDayLabel(int day);

  /// No description provided for @categoryFoodTitle.
  ///
  /// In en, this message translates to:
  /// **'Food & cafes'**
  String get categoryFoodTitle;

  /// No description provided for @categoryFoodSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse local food and cafe places from supported category roots.'**
  String get categoryFoodSubtitle;

  /// No description provided for @categoryFoodSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search food, cafes, or local dishes'**
  String get categoryFoodSearchHint;

  /// No description provided for @categoryThingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Things to do'**
  String get categoryThingsTitle;

  /// No description provided for @categoryThingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attractions and entertainment stay distinct for future backend mapping.'**
  String get categoryThingsSubtitle;

  /// No description provided for @categoryThingsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search attractions or entertainment'**
  String get categoryThingsSearchHint;

  /// No description provided for @categoryTransportTitle.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryTransportTitle;

  /// No description provided for @categoryTransportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse transport listings without live routes, fares, or schedules.'**
  String get categoryTransportSubtitle;

  /// No description provided for @categoryTransportSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transport providers'**
  String get categoryTransportSearchHint;

  /// No description provided for @categoryRootAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryRootAll;

  /// No description provided for @categoryRootFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryRootFood;

  /// No description provided for @categoryRootCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get categoryRootCafe;

  /// No description provided for @categoryRootAttraction.
  ///
  /// In en, this message translates to:
  /// **'Attractions'**
  String get categoryRootAttraction;

  /// No description provided for @categoryRootEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryRootEntertainment;

  /// No description provided for @categoryRootTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get categoryRootTransportation;

  /// No description provided for @categoryFiltersSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open category filters'**
  String get categoryFiltersSemantic;

  /// No description provided for @categoryFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Category filters'**
  String get categoryFiltersTitle;

  /// No description provided for @categoryFilterRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get categoryFilterRating;

  /// No description provided for @categoryFilterRating45.
  ///
  /// In en, this message translates to:
  /// **'4.5+ rating'**
  String get categoryFilterRating45;

  /// No description provided for @categoryFilterPrice.
  ///
  /// In en, this message translates to:
  /// **'Price level'**
  String get categoryFilterPrice;

  /// No description provided for @categoryFilterPriceAny.
  ///
  /// In en, this message translates to:
  /// **'Any price'**
  String get categoryFilterPriceAny;

  /// No description provided for @categoryFilterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get categoryFilterApply;

  /// No description provided for @categoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No category results'**
  String get categoryEmptyTitle;

  /// No description provided for @categoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another keyword, root category, rating, or price level.'**
  String get categoryEmptyMessage;

  /// No description provided for @categoryLocalPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'These public category results are local preview content and are not personal server data.'**
  String get categoryLocalPreviewMessage;

  /// No description provided for @categoryTransportUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Routes not connected'**
  String get categoryTransportUnavailableTitle;

  /// No description provided for @categoryTransportUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Live routes, fares, schedules, travel times, geolocation, and ticket booking are not connected yet.'**
  String get categoryTransportUnavailableMessage;

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip budget'**
  String get budgetTitle;

  /// No description provided for @budgetHeading.
  ///
  /// In en, this message translates to:
  /// **'Budget overview'**
  String get budgetHeading;

  /// No description provided for @budgetTripSelectorLabel.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get budgetTripSelectorLabel;

  /// No description provided for @budgetNoTripTitle.
  ///
  /// In en, this message translates to:
  /// **'No trip budget yet'**
  String get budgetNoTripTitle;

  /// No description provided for @budgetNoTripMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a trip before tracking a trip-scoped budget.'**
  String get budgetNoTripMessage;

  /// No description provided for @budgetOverviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Budget overview'**
  String get budgetOverviewSemantic;

  /// No description provided for @budgetTotalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get budgetTotalBudget;

  /// No description provided for @budgetSetAction.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get budgetSetAction;

  /// No description provided for @budgetSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set trip budget'**
  String get budgetSetTitle;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget amount'**
  String get budgetAmountLabel;

  /// No description provided for @budgetNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get budgetNotSet;

  /// No description provided for @budgetSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetSpent;

  /// No description provided for @budgetLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get budgetLeft;

  /// No description provided for @budgetOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by'**
  String get budgetOverBy;

  /// No description provided for @budgetProgressSemantic.
  ///
  /// In en, this message translates to:
  /// **'Budget progress {percent} percent used'**
  String budgetProgressSemantic(int percent);

  /// No description provided for @budgetProgressMissingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Budget progress unavailable because no budget is set'**
  String get budgetProgressMissingSemantic;

  /// No description provided for @budgetProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String budgetProgressLabel(int percent);

  /// No description provided for @budgetOverMessage.
  ///
  /// In en, this message translates to:
  /// **'Over budget by {amount}'**
  String budgetOverMessage(String amount);

  /// No description provided for @budgetMissingBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget not configured'**
  String get budgetMissingBudgetTitle;

  /// No description provided for @budgetMissingBudgetMessage.
  ///
  /// In en, this message translates to:
  /// **'Expenses can be tracked before a total budget is set.'**
  String get budgetMissingBudgetMessage;

  /// No description provided for @budgetNoExpensesTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get budgetNoExpensesTitle;

  /// No description provided for @budgetNoExpensesMessage.
  ///
  /// In en, this message translates to:
  /// **'Add expenses to build this trip\'s local spending history.'**
  String get budgetNoExpensesMessage;

  /// No description provided for @budgetByCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get budgetByCategoryTitle;

  /// No description provided for @budgetHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Expense history'**
  String get budgetHistoryTitle;

  /// No description provided for @budgetMixedCurrencyWarning.
  ///
  /// In en, this message translates to:
  /// **'This trip has expenses outside {currency}. Totals show only {currency} to avoid mixing currencies.'**
  String budgetMixedCurrencyWarning(String currency);

  /// No description provided for @budgetSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Budget updated locally.'**
  String get budgetSavedMessage;

  /// No description provided for @budgetSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this budget.'**
  String get budgetSaveFailed;

  /// No description provided for @expenseAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseAddSemantic;

  /// No description provided for @expenseAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseAddAction;

  /// No description provided for @expenseAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expenseAddTitle;

  /// No description provided for @expenseEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get expenseEditTitle;

  /// No description provided for @expenseSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get expenseSaveAction;

  /// No description provided for @expenseSaveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Save this expense'**
  String get expenseSaveSemantic;

  /// No description provided for @expenseTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense title'**
  String get expenseTitleLabel;

  /// No description provided for @expenseTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an expense title.'**
  String get expenseTitleRequired;

  /// No description provided for @expenseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseAmountLabel;

  /// No description provided for @expenseAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use a finite amount above 0.'**
  String get expenseAmountInvalid;

  /// No description provided for @expenseCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get expenseCurrencyLabel;

  /// No description provided for @expenseCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseCategoryLabel;

  /// No description provided for @expenseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expense date'**
  String get expenseDateLabel;

  /// No description provided for @expenseLinkedDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked day'**
  String get expenseLinkedDayLabel;

  /// No description provided for @expenseNoLinkedDay.
  ///
  /// In en, this message translates to:
  /// **'No linked day'**
  String get expenseNoLinkedDay;

  /// No description provided for @expenseLinkedDayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Linked day must belong to the selected trip.'**
  String get expenseLinkedDayInvalid;

  /// No description provided for @expenseLinkedItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked activity'**
  String get expenseLinkedItemLabel;

  /// No description provided for @expenseNoLinkedItem.
  ///
  /// In en, this message translates to:
  /// **'No linked activity'**
  String get expenseNoLinkedItem;

  /// No description provided for @expenseLinkedItemInvalid.
  ///
  /// In en, this message translates to:
  /// **'Linked activity must belong to the selected trip.'**
  String get expenseLinkedItemInvalid;

  /// No description provided for @expenseNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get expenseNotesLabel;

  /// No description provided for @expenseTripRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a valid trip.'**
  String get expenseTripRequired;

  /// No description provided for @expenseDateOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'Expense date must be inside the selected trip date range.'**
  String get expenseDateOutOfRange;

  /// No description provided for @expenseSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this expense for the selected trip.'**
  String get expenseSaveFailed;

  /// No description provided for @expenseAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense added locally.'**
  String get expenseAddedMessage;

  /// No description provided for @expenseSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense updated locally.'**
  String get expenseSavedMessage;

  /// No description provided for @expenseTileSemantic.
  ///
  /// In en, this message translates to:
  /// **'Expense {title}'**
  String expenseTileSemantic(String title);

  /// No description provided for @expenseActionsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Actions for expense {title}'**
  String expenseActionsSemantic(String title);

  /// No description provided for @expenseEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get expenseEditAction;

  /// No description provided for @expenseDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get expenseDeleteAction;

  /// No description provided for @expenseDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get expenseDeleteConfirmTitle;

  /// No description provided for @expenseDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" from this trip budget?'**
  String expenseDeleteConfirmMessage(String title);

  /// No description provided for @expenseDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted.'**
  String get expenseDeletedMessage;

  /// No description provided for @expenseCategoryAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get expenseCategoryAccommodation;

  /// No description provided for @expenseCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get expenseCategoryFood;

  /// No description provided for @expenseCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expenseCategoryTransport;

  /// No description provided for @expenseCategoryAttraction.
  ///
  /// In en, this message translates to:
  /// **'Attraction'**
  String get expenseCategoryAttraction;

  /// No description provided for @expenseCategoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get expenseCategoryShopping;

  /// No description provided for @expenseCategoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get expenseCategoryHealth;

  /// No description provided for @expenseCategoryVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get expenseCategoryVisa;

  /// No description provided for @expenseCategoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get expenseCategoryInsurance;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenseCategoryOther;

  /// No description provided for @hotelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get hotelsTitle;

  /// No description provided for @hotelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Search accommodation from public place data, then review one room and one local quote.'**
  String get hotelsSubtitle;

  /// No description provided for @hotelsDestinationLabel.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get hotelsDestinationLabel;

  /// No description provided for @hotelsDestinationHint.
  ///
  /// In en, this message translates to:
  /// **'City, hotel, or area'**
  String get hotelsDestinationHint;

  /// No description provided for @hotelsCheckInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get hotelsCheckInLabel;

  /// No description provided for @hotelsCheckOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get hotelsCheckOutLabel;

  /// No description provided for @hotelsAdultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get hotelsAdultsLabel;

  /// No description provided for @hotelsChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get hotelsChildrenLabel;

  /// No description provided for @hotelsSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search stays'**
  String get hotelsSearchAction;

  /// No description provided for @hotelsSearchSemantic.
  ///
  /// In en, this message translates to:
  /// **'Search hotel stays'**
  String get hotelsSearchSemantic;

  /// No description provided for @hotelsTripPrefillLabel.
  ///
  /// In en, this message translates to:
  /// **'Prefilled from {trip}'**
  String hotelsTripPrefillLabel(String trip);

  /// No description provided for @hotelsLocalPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Hotel discovery uses local accommodation place data. Availability, quotes, and bookings are presentation-only in this UI phase.'**
  String get hotelsLocalPreviewMessage;

  /// No description provided for @hotelsResultCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No hotels} =1{1 hotel} other{{count} hotels}}'**
  String hotelsResultCount(int count);

  /// No description provided for @hotelsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No stays found'**
  String get hotelsEmptyTitle;

  /// No description provided for @hotelsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Try a different destination or guest mix.'**
  String get hotelsEmptyMessage;

  /// No description provided for @hotelsValidationPastCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in cannot be before today.'**
  String get hotelsValidationPastCheckIn;

  /// No description provided for @hotelsValidationCheckout.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be after check-in.'**
  String get hotelsValidationCheckout;

  /// No description provided for @hotelsValidationAdults.
  ///
  /// In en, this message translates to:
  /// **'At least one adult is required.'**
  String get hotelsValidationAdults;

  /// No description provided for @hotelsValidationChildren.
  ///
  /// In en, this message translates to:
  /// **'Children cannot be negative.'**
  String get hotelsValidationChildren;

  /// No description provided for @hotelsValidationExtraBeds.
  ///
  /// In en, this message translates to:
  /// **'Extra beds cannot be negative.'**
  String get hotelsValidationExtraBeds;

  /// No description provided for @hotelDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Hotel details'**
  String get hotelDetailTitle;

  /// No description provided for @hotelStars.
  ///
  /// In en, this message translates to:
  /// **'{stars, plural, =1{1 star} other{{stars} stars}}'**
  String hotelStars(int stars);

  /// No description provided for @hotelCheckInOutMeta.
  ///
  /// In en, this message translates to:
  /// **'Check-in {checkIn} · Check-out {checkOut}'**
  String hotelCheckInOutMeta(String checkIn, String checkOut);

  /// No description provided for @hotelAvailableRooms.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No matching rooms} =1{1 matching room} other{{count} matching rooms}}'**
  String hotelAvailableRooms(int count);

  /// No description provided for @hotelBreakfastIncluded.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get hotelBreakfastIncluded;

  /// No description provided for @hotelAirportShuttle.
  ///
  /// In en, this message translates to:
  /// **'Airport shuttle'**
  String get hotelAirportShuttle;

  /// No description provided for @hotelDistanceBeach.
  ///
  /// In en, this message translates to:
  /// **'{meters} m to beach'**
  String hotelDistanceBeach(int meters);

  /// No description provided for @hotelDistanceCenter.
  ///
  /// In en, this message translates to:
  /// **'{meters} m to city center'**
  String hotelDistanceCenter(int meters);

  /// No description provided for @hotelLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages: {languages}'**
  String hotelLanguages(String languages);

  /// No description provided for @hotelPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods: {methods}'**
  String hotelPaymentMethods(String methods);

  /// No description provided for @hotelFacilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get hotelFacilitiesTitle;

  /// No description provided for @hotelServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get hotelServicesTitle;

  /// No description provided for @hotelRoomPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Room preview'**
  String get hotelRoomPreviewTitle;

  /// No description provided for @hotelCheckAvailabilityAction.
  ///
  /// In en, this message translates to:
  /// **'Check availability'**
  String get hotelCheckAvailabilityAction;

  /// No description provided for @hotelCheckAvailabilitySemantic.
  ///
  /// In en, this message translates to:
  /// **'Check availability for {hotel}'**
  String hotelCheckAvailabilitySemantic(String hotel);

  /// No description provided for @hotelViewRoomsAction.
  ///
  /// In en, this message translates to:
  /// **'View rooms'**
  String get hotelViewRoomsAction;

  /// No description provided for @hotelCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Hotel card for {hotel}'**
  String hotelCardSemantic(String hotel);

  /// No description provided for @hotelFromPrice.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String hotelFromPrice(String price);

  /// No description provided for @hotelRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rooms and rates'**
  String get hotelRoomsTitle;

  /// No description provided for @hotelAvailableRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Available rooms'**
  String get hotelAvailableRoomsTitle;

  /// No description provided for @hotelNoAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching rooms'**
  String get hotelNoAvailabilityTitle;

  /// No description provided for @hotelNoAvailabilityMessage.
  ///
  /// In en, this message translates to:
  /// **'No local room result fits the selected guests. Change dates or guest count.'**
  String get hotelNoAvailabilityMessage;

  /// No description provided for @hotelRatePlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a rate plan'**
  String get hotelRatePlansTitle;

  /// No description provided for @hotelContinueReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review booking'**
  String get hotelContinueReviewAction;

  /// No description provided for @hotelContinueReviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Continue to booking review'**
  String get hotelContinueReviewSemantic;

  /// No description provided for @hotelNights.
  ///
  /// In en, this message translates to:
  /// **'{nights, plural, =1{1 night} other{{nights} nights}}'**
  String hotelNights(int nights);

  /// No description provided for @hotelGuestSummary.
  ///
  /// In en, this message translates to:
  /// **'{adults, plural, =1{1 adult} other{{adults} adults}} · {children, plural, =0{no children} =1{1 child} other{{children} children}}'**
  String hotelGuestSummary(int adults, int children);

  /// No description provided for @hotelOneRoomOnly.
  ///
  /// In en, this message translates to:
  /// **'1 room'**
  String get hotelOneRoomOnly;

  /// No description provided for @hotelAddAdultAction.
  ///
  /// In en, this message translates to:
  /// **'Add adult'**
  String get hotelAddAdultAction;

  /// No description provided for @hotelExtendStayAction.
  ///
  /// In en, this message translates to:
  /// **'Add night'**
  String get hotelExtendStayAction;

  /// No description provided for @hotelRoomCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Room card for {room}'**
  String hotelRoomCardSemantic(String room);

  /// No description provided for @hotelMaxGuests.
  ///
  /// In en, this message translates to:
  /// **'{guests, plural, =1{1 guest max} other{{guests} guests max}}'**
  String hotelMaxGuests(int guests);

  /// No description provided for @hotelRoomSize.
  ///
  /// In en, this message translates to:
  /// **'{size} sqm'**
  String hotelRoomSize(int size);

  /// No description provided for @hotelBedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} × {label}'**
  String hotelBedCount(int count, String label);

  /// No description provided for @hotelRatePlanSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rate plan {plan}'**
  String hotelRatePlanSemantic(String plan);

  /// No description provided for @roomTypeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get roomTypeStandard;

  /// No description provided for @roomTypeSuperior.
  ///
  /// In en, this message translates to:
  /// **'Superior'**
  String get roomTypeSuperior;

  /// No description provided for @roomTypeDeluxe.
  ///
  /// In en, this message translates to:
  /// **'Deluxe'**
  String get roomTypeDeluxe;

  /// No description provided for @roomTypePremier.
  ///
  /// In en, this message translates to:
  /// **'Premier'**
  String get roomTypePremier;

  /// No description provided for @roomTypeExecutive.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get roomTypeExecutive;

  /// No description provided for @roomTypeSuite.
  ///
  /// In en, this message translates to:
  /// **'Suite'**
  String get roomTypeSuite;

  /// No description provided for @roomTypeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get roomTypeFamily;

  /// No description provided for @roomTypeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get roomTypeVilla;

  /// No description provided for @roomTypeBungalow.
  ///
  /// In en, this message translates to:
  /// **'Bungalow'**
  String get roomTypeBungalow;

  /// No description provided for @bedTypeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single bed'**
  String get bedTypeSingle;

  /// No description provided for @bedTypeDouble.
  ///
  /// In en, this message translates to:
  /// **'Double bed'**
  String get bedTypeDouble;

  /// No description provided for @bedTypeTwin.
  ///
  /// In en, this message translates to:
  /// **'Twin beds'**
  String get bedTypeTwin;

  /// No description provided for @bedTypeQueen.
  ///
  /// In en, this message translates to:
  /// **'Queen bed'**
  String get bedTypeQueen;

  /// No description provided for @bedTypeKing.
  ///
  /// In en, this message translates to:
  /// **'King bed'**
  String get bedTypeKing;

  /// No description provided for @bedTypeSofaBed.
  ///
  /// In en, this message translates to:
  /// **'Sofa bed'**
  String get bedTypeSofaBed;

  /// No description provided for @bedTypeBunk.
  ///
  /// In en, this message translates to:
  /// **'Bunk bed'**
  String get bedTypeBunk;

  /// No description provided for @mealPlanRoomOnly.
  ///
  /// In en, this message translates to:
  /// **'Room only'**
  String get mealPlanRoomOnly;

  /// No description provided for @mealPlanBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealPlanBreakfast;

  /// No description provided for @mealPlanHalfBoard.
  ///
  /// In en, this message translates to:
  /// **'Half board'**
  String get mealPlanHalfBoard;

  /// No description provided for @mealPlanFullBoard.
  ///
  /// In en, this message translates to:
  /// **'Full board'**
  String get mealPlanFullBoard;

  /// No description provided for @mealPlanAllInclusive.
  ///
  /// In en, this message translates to:
  /// **'All inclusive'**
  String get mealPlanAllInclusive;

  /// No description provided for @cancellationFree.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get cancellationFree;

  /// No description provided for @cancellationFreeDeadlinePassed.
  ///
  /// In en, this message translates to:
  /// **'Free-cancellation window passed'**
  String get cancellationFreeDeadlinePassed;

  /// No description provided for @cancellationPartial.
  ///
  /// In en, this message translates to:
  /// **'Partially refundable'**
  String get cancellationPartial;

  /// No description provided for @cancellationNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get cancellationNonRefundable;

  /// No description provided for @cancellationCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom policy'**
  String get cancellationCustom;

  /// No description provided for @bookingReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking review'**
  String get bookingReviewTitle;

  /// No description provided for @bookingSelectedPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected rate plan'**
  String get bookingSelectedPlanTitle;

  /// No description provided for @bookingQuoteExpiry.
  ///
  /// In en, this message translates to:
  /// **'Quote expires at {time}'**
  String bookingQuoteExpiry(String time);

  /// No description provided for @bookingAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get bookingAccountTitle;

  /// No description provided for @bookingAccountReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This identity is read-only here and is not sent with unsupported guest-profile fields.'**
  String get bookingAccountReadOnly;

  /// No description provided for @bookingSpecialRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Special request'**
  String get bookingSpecialRequestLabel;

  /// No description provided for @bookingSpecialRequestHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional note only. No payment or guest profile is collected.'**
  String get bookingSpecialRequestHelper;

  /// No description provided for @bookingPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing quote'**
  String get bookingPriceTitle;

  /// No description provided for @bookingPriceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Booking price quote'**
  String get bookingPriceSemantic;

  /// No description provided for @bookingFinalNightlyRate.
  ///
  /// In en, this message translates to:
  /// **'Final nightly rate'**
  String get bookingFinalNightlyRate;

  /// No description provided for @bookingStaySubtotal.
  ///
  /// In en, this message translates to:
  /// **'Stay subtotal'**
  String get bookingStaySubtotal;

  /// No description provided for @bookingPromotionDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promotion discount'**
  String get bookingPromotionDiscount;

  /// No description provided for @bookingFinalQuotedPrice.
  ///
  /// In en, this message translates to:
  /// **'Final quoted price'**
  String get bookingFinalQuotedPrice;

  /// No description provided for @bookingCustomerBenefitsExcluded.
  ///
  /// In en, this message translates to:
  /// **'Coupons, loyalty, travel credit, and gift cards are outside this UI phase.'**
  String get bookingCustomerBenefitsExcluded;

  /// No description provided for @bookingQuoteNoReservation.
  ///
  /// In en, this message translates to:
  /// **'A quote does not create a booking or reserve inventory.'**
  String get bookingQuoteNoReservation;

  /// No description provided for @bookingQuoteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Quote unavailable'**
  String get bookingQuoteUnavailable;

  /// No description provided for @bookingInventoryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Inventory is unavailable for this quote.'**
  String get bookingInventoryUnavailable;

  /// No description provided for @bookingQuoteExpired.
  ///
  /// In en, this message translates to:
  /// **'This quote has expired. Refresh criteria before confirming.'**
  String get bookingQuoteExpired;

  /// No description provided for @bookingDemoBoundaryMessage.
  ///
  /// In en, this message translates to:
  /// **'Demo mode can create a clearly local booking. It is not synchronized with the backend.'**
  String get bookingDemoBoundaryMessage;

  /// No description provided for @bookingRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Online booking is not connected yet for real accounts.'**
  String get bookingRealUnavailableMessage;

  /// No description provided for @bookingTermsAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I understand checkout does not collect card details or reserve real inventory in this UI phase.'**
  String get bookingTermsAcknowledgement;

  /// No description provided for @bookingConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm demo booking'**
  String get bookingConfirmAction;

  /// No description provided for @bookingConfirmSemantic.
  ///
  /// In en, this message translates to:
  /// **'Continue to secure checkout'**
  String get bookingConfirmSemantic;

  /// No description provided for @bookingDuplicatePrevented.
  ///
  /// In en, this message translates to:
  /// **'Duplicate booking creation was blocked.'**
  String get bookingDuplicatePrevented;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get checkoutTitle;

  /// No description provided for @checkoutContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to secure checkout'**
  String get checkoutContinueAction;

  /// No description provided for @checkoutSecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Secure checkout'**
  String get checkoutSecureTitle;

  /// No description provided for @checkoutSemantic.
  ///
  /// In en, this message translates to:
  /// **'Secure booking checkout'**
  String get checkoutSemantic;

  /// No description provided for @checkoutRealModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Real account'**
  String get checkoutRealModeLabel;

  /// No description provided for @checkoutSecureBoundaryPill.
  ///
  /// In en, this message translates to:
  /// **'No card fields'**
  String get checkoutSecureBoundaryPill;

  /// No description provided for @checkoutWholeStayTotal.
  ///
  /// In en, this message translates to:
  /// **'Whole-stay total'**
  String get checkoutWholeStayTotal;

  /// No description provided for @checkoutStaySnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay snapshot'**
  String get checkoutStaySnapshotTitle;

  /// No description provided for @checkoutProviderTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment provider'**
  String get checkoutProviderTitle;

  /// No description provided for @checkoutProviderHelper.
  ///
  /// In en, this message translates to:
  /// **'Backend contracts expose hosted provider sessions. UI-13 does not open an external gateway or collect credentials.'**
  String get checkoutProviderHelper;

  /// No description provided for @checkoutMockProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local demo provider for presentation only.'**
  String get checkoutMockProviderSubtitle;

  /// No description provided for @checkoutHostedProviderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hosted provider handoff is proven by backend contracts but not opened in this UI phase.'**
  String get checkoutHostedProviderSubtitle;

  /// No description provided for @checkoutSecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment security'**
  String get checkoutSecurityTitle;

  /// No description provided for @checkoutDemoSecurityBoundary.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode can create a local payment attempt for presentation. No money is charged and no gateway callback is sent.'**
  String get checkoutDemoSecurityBoundary;

  /// No description provided for @checkoutRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Real checkout requires API/repository integration and hosted-provider handoff wiring. This UI will not simulate success.'**
  String get checkoutRealUnavailableMessage;

  /// No description provided for @checkoutNoSensitiveFields.
  ///
  /// In en, this message translates to:
  /// **'This app does not ask for card number, expiry, CVV, PIN, bank password, OTP, payment token, or gateway secret.'**
  String get checkoutNoSensitiveFields;

  /// No description provided for @checkoutBenefitsBoundaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards and wallet'**
  String get checkoutBenefitsBoundaryTitle;

  /// No description provided for @checkoutBenefitsReadOnlyDemo.
  ///
  /// In en, this message translates to:
  /// **'Travel credits, loyalty, coupons, gift cards, and wallet items are read-only here unless a backend checkout contract explicitly applies them.'**
  String get checkoutBenefitsReadOnlyDemo;

  /// No description provided for @checkoutBenefitsReadOnlyReal.
  ///
  /// In en, this message translates to:
  /// **'Rewards and wallet balances are not connected to real checkout in this UI phase.'**
  String get checkoutBenefitsReadOnlyReal;

  /// No description provided for @checkoutCreateDemoPaymentAction.
  ///
  /// In en, this message translates to:
  /// **'Create demo booking and payment'**
  String get checkoutCreateDemoPaymentAction;

  /// No description provided for @checkoutRealUnavailableAction.
  ///
  /// In en, this message translates to:
  /// **'Real payment unavailable'**
  String get checkoutRealUnavailableAction;

  /// No description provided for @checkoutSubmitSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create a local demo booking and payment attempt'**
  String get checkoutSubmitSemantic;

  /// No description provided for @paymentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatusTitle;

  /// No description provided for @paymentRealUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not connected'**
  String get paymentRealUnavailableTitle;

  /// No description provided for @paymentRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Real payment status requires the backend API/repository integration. No local success is simulated for real accounts.'**
  String get paymentRealUnavailableMessage;

  /// No description provided for @paymentMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment unavailable'**
  String get paymentMissingTitle;

  /// No description provided for @paymentMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'This local payment attempt is no longer available.'**
  String get paymentMissingMessage;

  /// No description provided for @paymentDemoFailureReason.
  ///
  /// In en, this message translates to:
  /// **'Demo provider declined the payment.'**
  String get paymentDemoFailureReason;

  /// No description provided for @paymentStatusSemantic.
  ///
  /// In en, this message translates to:
  /// **'Payment status detail'**
  String get paymentStatusSemantic;

  /// No description provided for @paymentDemoLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'This payment status is local Demo Mode presentation data and is not a real charge.'**
  String get paymentDemoLocalOnly;

  /// No description provided for @paymentDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment details'**
  String get paymentDetailsTitle;

  /// No description provided for @paymentProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get paymentProviderLabel;

  /// No description provided for @paymentSessionStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Gateway session'**
  String get paymentSessionStatusLabel;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get paymentAmountLabel;

  /// No description provided for @paymentCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment created'**
  String get paymentCreatedLabel;

  /// No description provided for @paymentHoldExpiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Hold expires'**
  String get paymentHoldExpiresLabel;

  /// No description provided for @paymentPaidAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid at'**
  String get paymentPaidAtLabel;

  /// No description provided for @paymentFailedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Failed at'**
  String get paymentFailedAtLabel;

  /// No description provided for @paymentCancelledAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled at'**
  String get paymentCancelledAtLabel;

  /// No description provided for @paymentRefundedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded at'**
  String get paymentRefundedAtLabel;

  /// No description provided for @paymentReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider reference'**
  String get paymentReferenceLabel;

  /// No description provided for @paymentMaskedReferenceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Masked provider reference'**
  String get paymentMaskedReferenceSemantic;

  /// No description provided for @paymentFailureReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Failure reason'**
  String get paymentFailureReasonLabel;

  /// No description provided for @paymentNoRefundInference.
  ///
  /// In en, this message translates to:
  /// **'Cancellation and payment status are separate. A cancelled booking is not shown as refunded unless a refund status is present.'**
  String get paymentNoRefundInference;

  /// No description provided for @paymentActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment actions'**
  String get paymentActionsTitle;

  /// No description provided for @paymentCompleteDemoAction.
  ///
  /// In en, this message translates to:
  /// **'Complete demo payment'**
  String get paymentCompleteDemoAction;

  /// No description provided for @paymentCompleteDemoSemantic.
  ///
  /// In en, this message translates to:
  /// **'Complete this local demo payment'**
  String get paymentCompleteDemoSemantic;

  /// No description provided for @paymentFailDemoAction.
  ///
  /// In en, this message translates to:
  /// **'Fail demo payment'**
  String get paymentFailDemoAction;

  /// No description provided for @paymentCancelDemoAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel payment session'**
  String get paymentCancelDemoAction;

  /// No description provided for @paymentRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Retry payment'**
  String get paymentRetryAction;

  /// No description provided for @paymentContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue payment'**
  String get paymentContinueAction;

  /// No description provided for @paymentStatusAction.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get paymentStatusAction;

  /// No description provided for @paymentContinueConfirmationAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to confirmation'**
  String get paymentContinueConfirmationAction;

  /// No description provided for @paymentPendingBoundary.
  ///
  /// In en, this message translates to:
  /// **'Pending demo payments can be completed, failed, or cancelled locally. Real provider callbacks are not simulated.'**
  String get paymentPendingBoundary;

  /// No description provided for @paymentTerminalBoundary.
  ///
  /// In en, this message translates to:
  /// **'Terminal payment states are shown as immutable snapshots. Retry is available only when backend rules allow a new attempt.'**
  String get paymentTerminalBoundary;

  /// No description provided for @paymentProviderMock.
  ///
  /// In en, this message translates to:
  /// **'Mock provider'**
  String get paymentProviderMock;

  /// No description provided for @paymentProviderVnpay.
  ///
  /// In en, this message translates to:
  /// **'VNPay'**
  String get paymentProviderVnpay;

  /// No description provided for @paymentProviderPayos.
  ///
  /// In en, this message translates to:
  /// **'PayOS'**
  String get paymentProviderPayos;

  /// No description provided for @paymentProviderMomo.
  ///
  /// In en, this message translates to:
  /// **'MoMo'**
  String get paymentProviderMomo;

  /// No description provided for @paymentProviderStripe.
  ///
  /// In en, this message translates to:
  /// **'Stripe'**
  String get paymentProviderStripe;

  /// No description provided for @paymentProviderApplePay.
  ///
  /// In en, this message translates to:
  /// **'Apple Pay'**
  String get paymentProviderApplePay;

  /// No description provided for @paymentProviderGooglePay.
  ///
  /// In en, this message translates to:
  /// **'Google Pay'**
  String get paymentProviderGooglePay;

  /// No description provided for @paymentProviderManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get paymentProviderManual;

  /// No description provided for @paymentSessionStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get paymentSessionStatusNew;

  /// No description provided for @paymentSessionStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get paymentSessionStatusPending;

  /// No description provided for @paymentSessionStatusAuthorized.
  ///
  /// In en, this message translates to:
  /// **'Authorized'**
  String get paymentSessionStatusAuthorized;

  /// No description provided for @paymentSessionStatusCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured'**
  String get paymentSessionStatusCaptured;

  /// No description provided for @paymentSessionStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentSessionStatusFailed;

  /// No description provided for @paymentSessionStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get paymentSessionStatusCancelled;

  /// No description provided for @paymentSessionStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get paymentSessionStatusExpired;

  /// No description provided for @paymentResultSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment completed'**
  String get paymentResultSuccessTitle;

  /// No description provided for @paymentResultPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentResultPendingTitle;

  /// No description provided for @paymentResultFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentResultFailedTitle;

  /// No description provided for @paymentResultCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentResultCancelledTitle;

  /// No description provided for @paymentResultExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment expired'**
  String get paymentResultExpiredTitle;

  /// No description provided for @paymentActionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Payment state updated.'**
  String get paymentActionSuccess;

  /// No description provided for @paymentActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Payment action is unavailable for this account.'**
  String get paymentActionUnavailable;

  /// No description provided for @paymentDuplicatePrevented.
  ///
  /// In en, this message translates to:
  /// **'Duplicate checkout submission was blocked.'**
  String get paymentDuplicatePrevented;

  /// No description provided for @paymentActionInvalidState.
  ///
  /// In en, this message translates to:
  /// **'This payment state cannot perform that action.'**
  String get paymentActionInvalidState;

  /// No description provided for @bookingConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Demo booking confirmed'**
  String get bookingConfirmationTitle;

  /// No description provided for @bookingDemoStatus.
  ///
  /// In en, this message translates to:
  /// **'Local demo booking'**
  String get bookingDemoStatus;

  /// No description provided for @bookingLocalCode.
  ///
  /// In en, this message translates to:
  /// **'Local code {code}'**
  String bookingLocalCode(String code);

  /// No description provided for @bookingConfirmationLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'This booking is local demo presentation data. It is not synced with the backend and does not hold inventory.'**
  String get bookingConfirmationLocalOnly;

  /// No description provided for @bookingAddItineraryAction.
  ///
  /// In en, this message translates to:
  /// **'Add to itinerary'**
  String get bookingAddItineraryAction;

  /// No description provided for @bookingAddItinerarySemantic.
  ///
  /// In en, this message translates to:
  /// **'Add this booking to the trip itinerary'**
  String get bookingAddItinerarySemantic;

  /// No description provided for @bookingItineraryAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to itinerary'**
  String get bookingItineraryAdded;

  /// No description provided for @bookingItineraryAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This stay is already in the itinerary.'**
  String get bookingItineraryAlreadyAdded;

  /// No description provided for @bookingItineraryAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Stay added to the itinerary.'**
  String get bookingItineraryAddedMessage;

  /// No description provided for @bookingItineraryNote.
  ///
  /// In en, this message translates to:
  /// **'Local demo booking {code}.'**
  String bookingItineraryNote(String code);

  /// No description provided for @bookingViewBookingAction.
  ///
  /// In en, this message translates to:
  /// **'View booking'**
  String get bookingViewBookingAction;

  /// No description provided for @bookingReturnHomeAction.
  ///
  /// In en, this message translates to:
  /// **'Return home'**
  String get bookingReturnHomeAction;

  /// No description provided for @myBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookingsTitle;

  /// No description provided for @myBookingsDemoLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Only local demo bookings appear here. Real booking management is not connected yet.'**
  String get myBookingsDemoLocalOnly;

  /// No description provided for @myBookingsRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings not connected'**
  String get myBookingsRealEmptyTitle;

  /// No description provided for @myBookingsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Real account bookings will appear after the backend integration is wired.'**
  String get myBookingsRealEmptyMessage;

  /// No description provided for @myBookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings'**
  String get myBookingsEmptyTitle;

  /// No description provided for @myBookingsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Demo bookings appear here after confirmation or from the seeded local stay examples.'**
  String get myBookingsEmptyMessage;

  /// No description provided for @myBookingCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Booking card'**
  String get myBookingCardSemantic;

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetailsTitle;

  /// No description provided for @bookingDetailMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking unavailable'**
  String get bookingDetailMissingTitle;

  /// No description provided for @bookingDetailMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'This local booking is no longer available.'**
  String get bookingDetailMissingMessage;

  /// No description provided for @bookingDetailSemantic.
  ///
  /// In en, this message translates to:
  /// **'Booking detail'**
  String get bookingDetailSemantic;

  /// No description provided for @bookingPaymentUnavailableAction.
  ///
  /// In en, this message translates to:
  /// **'Payment unavailable'**
  String get bookingPaymentUnavailableAction;

  /// No description provided for @bookingPaymentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Payment actions are not connected in this UI phase.'**
  String get bookingPaymentUnavailable;

  /// No description provided for @bookingStayOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay overview'**
  String get bookingStayOverviewTitle;

  /// No description provided for @bookingSnapshotTitle.
  ///
  /// In en, this message translates to:
  /// **'Room and rate snapshot'**
  String get bookingSnapshotTitle;

  /// No description provided for @bookingPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get bookingPolicyTitle;

  /// No description provided for @bookingTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Status timeline'**
  String get bookingTimelineTitle;

  /// No description provided for @bookingActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking actions'**
  String get bookingActionsTitle;

  /// No description provided for @bookingCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get bookingCodeLabel;

  /// No description provided for @bookingCodeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Local booking reference'**
  String get bookingCodeSemantic;

  /// No description provided for @bookingDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Stay dates'**
  String get bookingDatesLabel;

  /// No description provided for @bookingNightsLabel.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get bookingNightsLabel;

  /// No description provided for @bookingGuestsLabel.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get bookingGuestsLabel;

  /// No description provided for @bookingRoomsLabel.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get bookingRoomsLabel;

  /// No description provided for @bookingRoomsValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room} other{{count} rooms}}'**
  String bookingRoomsValue(int count);

  /// No description provided for @bookingCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get bookingCreatedLabel;

  /// No description provided for @bookingConfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingConfirmedLabel;

  /// No description provided for @bookingCancelledAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingCancelledAtLabel;

  /// No description provided for @bookingCancellationReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get bookingCancellationReasonLabel;

  /// No description provided for @bookingHotelLabel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get bookingHotelLabel;

  /// No description provided for @bookingRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get bookingRoomLabel;

  /// No description provided for @bookingRoomCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get bookingRoomCodeLabel;

  /// No description provided for @bookingRatePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate plan'**
  String get bookingRatePlanLabel;

  /// No description provided for @bookingMealPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get bookingMealPlanLabel;

  /// No description provided for @bookingTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get bookingTotalLabel;

  /// No description provided for @bookingPaymentStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment status'**
  String get bookingPaymentStatusLabel;

  /// No description provided for @bookingPaymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get bookingPaymentStatusPending;

  /// No description provided for @bookingPaymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get bookingPaymentStatusPaid;

  /// No description provided for @bookingPaymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get bookingPaymentStatusFailed;

  /// No description provided for @bookingPaymentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get bookingPaymentStatusCancelled;

  /// No description provided for @bookingPaymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get bookingPaymentStatusRefunded;

  /// No description provided for @bookingCancellationPolicyLabel.
  ///
  /// In en, this message translates to:
  /// **'Policy type'**
  String get bookingCancellationPolicyLabel;

  /// No description provided for @bookingPolicySummaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Policy summary'**
  String get bookingPolicySummaryLabel;

  /// No description provided for @bookingCancellationDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get bookingCancellationDeadlineLabel;

  /// No description provided for @bookingCancellationDeadlineValue.
  ///
  /// In en, this message translates to:
  /// **'Cancellation deadline: {date}'**
  String bookingCancellationDeadlineValue(String date);

  /// No description provided for @bookingRefundableLabel.
  ///
  /// In en, this message translates to:
  /// **'Refundability'**
  String get bookingRefundableLabel;

  /// No description provided for @bookingRefundableYes.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get bookingRefundableYes;

  /// No description provided for @bookingRefundableNo.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get bookingRefundableNo;

  /// No description provided for @bookingCancellationDeadlinePassedPolicy.
  ///
  /// In en, this message translates to:
  /// **'The free-cancellation window has passed. Cancellation can still be requested for eligible booking statuses, but the backend policy preview treats this as a full-penalty cancellation.'**
  String get bookingCancellationDeadlinePassedPolicy;

  /// No description provided for @bookingRefundBoundary.
  ///
  /// In en, this message translates to:
  /// **'Refund calculation and payout are not simulated in local Demo Mode.'**
  String get bookingRefundBoundary;

  /// No description provided for @bookingViewReviewAction.
  ///
  /// In en, this message translates to:
  /// **'View review'**
  String get bookingViewReviewAction;

  /// No description provided for @bookingViewPlaceAction.
  ///
  /// In en, this message translates to:
  /// **'View hotel'**
  String get bookingViewPlaceAction;

  /// No description provided for @bookingUnsupportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Settled-booking changes, rescheduling, invoice downloads, refunds, and property messaging require backend integration and are not simulated locally.'**
  String get bookingUnsupportedMessage;

  /// No description provided for @bookingModifyAction.
  ///
  /// In en, this message translates to:
  /// **'Modify booking'**
  String get bookingModifyAction;

  /// No description provided for @bookingModifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Modify booking'**
  String get bookingModifyTitle;

  /// No description provided for @bookingModifySemantic.
  ///
  /// In en, this message translates to:
  /// **'Modify this pending demo booking'**
  String get bookingModifySemantic;

  /// No description provided for @bookingModifyIntro.
  ///
  /// In en, this message translates to:
  /// **'Only pending demo bookings can be changed locally. Confirmed, paid, checked-in, completed, cancelled, refunded, archived, and no-show bookings stay locked.'**
  String get bookingModifyIntro;

  /// No description provided for @bookingModifyAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending changes available'**
  String get bookingModifyAvailableLabel;

  /// No description provided for @bookingModifyUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Changes unavailable'**
  String get bookingModifyUnavailableLabel;

  /// No description provided for @bookingModifyDemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Local Demo Mode'**
  String get bookingModifyDemoLabel;

  /// No description provided for @bookingModifyDemoBoundary.
  ///
  /// In en, this message translates to:
  /// **'This updates only deterministic local presentation data and never claims live availability.'**
  String get bookingModifyDemoBoundary;

  /// No description provided for @bookingModifyEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit supported fields'**
  String get bookingModifyEditTitle;

  /// No description provided for @bookingModifyEditableFields.
  ///
  /// In en, this message translates to:
  /// **'Backend-supported fields in this UI phase are check-in, check-out, adults, children, extra beds, and rate plan. Hotel, room, room count, and benefits stay unchanged.'**
  String get bookingModifyEditableFields;

  /// No description provided for @bookingModifyReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get bookingModifyReviewTitle;

  /// No description provided for @bookingModifyReviewInstruction.
  ///
  /// In en, this message translates to:
  /// **'Review the current and proposed values before confirming. The original booking is unchanged until confirmation succeeds.'**
  String get bookingModifyReviewInstruction;

  /// No description provided for @bookingModifyCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get bookingModifyCurrentLabel;

  /// No description provided for @bookingModifyProposedLabel.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get bookingModifyProposedLabel;

  /// No description provided for @bookingModifyUnchangedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unchanged'**
  String get bookingModifyUnchangedLabel;

  /// No description provided for @bookingModifyChangedLabel.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get bookingModifyChangedLabel;

  /// No description provided for @bookingModifyCheckInLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-in date'**
  String get bookingModifyCheckInLabel;

  /// No description provided for @bookingModifyCheckOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Check-out date'**
  String get bookingModifyCheckOutLabel;

  /// No description provided for @bookingModifyAdultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get bookingModifyAdultsLabel;

  /// No description provided for @bookingModifyChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get bookingModifyChildrenLabel;

  /// No description provided for @bookingModifyExtraBedsLabel.
  ///
  /// In en, this message translates to:
  /// **'Extra beds'**
  String get bookingModifyExtraBedsLabel;

  /// No description provided for @bookingModifyRatePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Rate plan'**
  String get bookingModifyRatePlanLabel;

  /// No description provided for @bookingModifyRatePlanHelper.
  ///
  /// In en, this message translates to:
  /// **'Only eligible rate plans on the same room can be selected.'**
  String get bookingModifyRatePlanHelper;

  /// No description provided for @bookingModifyDateHelp.
  ///
  /// In en, this message translates to:
  /// **'Use YYYY-MM-DD.'**
  String get bookingModifyDateHelp;

  /// No description provided for @bookingModifyRequiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get bookingModifyRequiredField;

  /// No description provided for @bookingModifyRoomUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Same room'**
  String get bookingModifyRoomUnchanged;

  /// No description provided for @bookingModifyRoomCountUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Room and room count are not editable in the backend modification contract.'**
  String get bookingModifyRoomCountUnchanged;

  /// No description provided for @bookingModifyContinueReviewAction.
  ///
  /// In en, this message translates to:
  /// **'Review changes'**
  String get bookingModifyContinueReviewAction;

  /// No description provided for @bookingModifyConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm changes'**
  String get bookingModifyConfirmAction;

  /// No description provided for @bookingModifyBackToEditAction.
  ///
  /// In en, this message translates to:
  /// **'Back to edit'**
  String get bookingModifyBackToEditAction;

  /// No description provided for @bookingModifySuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Demo booking modified locally.'**
  String get bookingModifySuccessMessage;

  /// No description provided for @bookingModifyUnavailableReal.
  ///
  /// In en, this message translates to:
  /// **'Real booking modification requires backend API integration.'**
  String get bookingModifyUnavailableReal;

  /// No description provided for @bookingModifyUnavailableNotFound.
  ///
  /// In en, this message translates to:
  /// **'This booking is no longer available.'**
  String get bookingModifyUnavailableNotFound;

  /// No description provided for @bookingModifyUnavailableForbidden.
  ///
  /// In en, this message translates to:
  /// **'This booking belongs to another traveler.'**
  String get bookingModifyUnavailableForbidden;

  /// No description provided for @bookingModifyUnavailableOnlyPending.
  ///
  /// In en, this message translates to:
  /// **'Only pending bookings can be changed.'**
  String get bookingModifyUnavailableOnlyPending;

  /// No description provided for @bookingModifyUnavailablePaymentStarted.
  ///
  /// In en, this message translates to:
  /// **'This local booking already has a payment attempt, so its stay snapshot is locked for UI safety.'**
  String get bookingModifyUnavailablePaymentStarted;

  /// No description provided for @bookingModifyUnavailableRoomRate.
  ///
  /// In en, this message translates to:
  /// **'The room or rate-plan snapshot is no longer available.'**
  String get bookingModifyUnavailableRoomRate;

  /// No description provided for @bookingModifyUnavailableStarted.
  ///
  /// In en, this message translates to:
  /// **'This stay has already started.'**
  String get bookingModifyUnavailableStarted;

  /// No description provided for @bookingModifyInvalidDates.
  ///
  /// In en, this message translates to:
  /// **'Choose a future check-in date and a check-out date after check-in.'**
  String get bookingModifyInvalidDates;

  /// No description provided for @bookingModifyInvalidGuests.
  ///
  /// In en, this message translates to:
  /// **'Guest counts must be valid and nonnegative.'**
  String get bookingModifyInvalidGuests;

  /// No description provided for @bookingModifyCapacityExceeded.
  ///
  /// In en, this message translates to:
  /// **'Guest counts exceed this room\'s capacity.'**
  String get bookingModifyCapacityExceeded;

  /// No description provided for @bookingModifyQuoteUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A safe local modification quote is unavailable for these values.'**
  String get bookingModifyQuoteUnavailable;

  /// No description provided for @bookingModifyNoChanges.
  ///
  /// In en, this message translates to:
  /// **'Change at least one supported field before review.'**
  String get bookingModifyNoChanges;

  /// No description provided for @bookingModifyStale.
  ///
  /// In en, this message translates to:
  /// **'This booking changed while you were editing. Reopen the form and review the latest values.'**
  String get bookingModifyStale;

  /// No description provided for @bookingModifyBoundariesTitle.
  ///
  /// In en, this message translates to:
  /// **'Modification boundaries'**
  String get bookingModifyBoundariesTitle;

  /// No description provided for @bookingModifyPriceBoundaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Price impact'**
  String get bookingModifyPriceBoundaryLabel;

  /// No description provided for @bookingModifyPriceBoundary.
  ///
  /// In en, this message translates to:
  /// **'The new total is a deterministic local demo estimate shaped like the backend canonical whole-stay total. It is not a live backend quote.'**
  String get bookingModifyPriceBoundary;

  /// No description provided for @bookingModifyAvailabilityBoundaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get bookingModifyAvailabilityBoundaryLabel;

  /// No description provided for @bookingModifyAvailabilityBoundary.
  ///
  /// In en, this message translates to:
  /// **'Local Demo Mode does not decrement inventory or create a new hold. Live availability remains a backend responsibility.'**
  String get bookingModifyAvailabilityBoundary;

  /// No description provided for @bookingModifyPaymentBoundaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bookingModifyPaymentBoundaryLabel;

  /// No description provided for @bookingModifyPaymentBoundary.
  ///
  /// In en, this message translates to:
  /// **'Modification does not mark payment paid, failed, cancelled, or refunded and does not create a payment attempt.'**
  String get bookingModifyPaymentBoundary;

  /// No description provided for @bookingModifySnapshotBoundary.
  ///
  /// In en, this message translates to:
  /// **'No customer-safe policy summary is available for this rate snapshot.'**
  String get bookingModifySnapshotBoundary;

  /// No description provided for @bookingModifyLiveRepricingTitle.
  ///
  /// In en, this message translates to:
  /// **'Live backend quote'**
  String get bookingModifyLiveRepricingTitle;

  /// No description provided for @bookingModifyLiveRepricingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Live repricing and overlap-adjusted inventory checks are shown as an honest integration boundary until networking is connected.'**
  String get bookingModifyLiveRepricingUnavailable;

  /// No description provided for @bookingCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get bookingCancelAction;

  /// No description provided for @bookingCancelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Cancel this demo booking'**
  String get bookingCancelSemantic;

  /// No description provided for @bookingCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel demo booking?'**
  String get bookingCancelConfirmTitle;

  /// No description provided for @bookingCancelConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Cancel local booking {code}? The stay remains in history and no backend request is sent.'**
  String bookingCancelConfirmMessage(String code);

  /// No description provided for @bookingCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get bookingCancelReasonLabel;

  /// No description provided for @bookingCancelReasonHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional local note. The backend contract does not require a reason.'**
  String get bookingCancelReasonHelper;

  /// No description provided for @bookingCancellationLocalWarning.
  ///
  /// In en, this message translates to:
  /// **'This changes only local Demo Mode presentation data.'**
  String get bookingCancellationLocalWarning;

  /// No description provided for @bookingCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Demo booking cancelled locally.'**
  String get bookingCancelledMessage;

  /// No description provided for @bookingCancellationUnavailableReal.
  ///
  /// In en, this message translates to:
  /// **'Real booking cancellation requires backend integration.'**
  String get bookingCancellationUnavailableReal;

  /// No description provided for @bookingCancellationUnavailableForbidden.
  ///
  /// In en, this message translates to:
  /// **'This booking belongs to another traveler.'**
  String get bookingCancellationUnavailableForbidden;

  /// No description provided for @bookingCancellationUnavailableAlready.
  ///
  /// In en, this message translates to:
  /// **'This booking is already cancelled.'**
  String get bookingCancellationUnavailableAlready;

  /// No description provided for @bookingCancellationUnavailableCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed and historical stays cannot be cancelled.'**
  String get bookingCancellationUnavailableCompleted;

  /// No description provided for @bookingCancellationUnavailableStarted.
  ///
  /// In en, this message translates to:
  /// **'Check-in has started, so customer cancellation is unavailable.'**
  String get bookingCancellationUnavailableStarted;

  /// No description provided for @bookingCancellationUnavailableGeneric.
  ///
  /// In en, this message translates to:
  /// **'Cancellation is unavailable for this booking status.'**
  String get bookingCancellationUnavailableGeneric;

  /// No description provided for @bookingSectionAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bookingSectionAll;

  /// No description provided for @bookingSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingSectionUpcoming;

  /// No description provided for @bookingSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bookingSectionActive;

  /// No description provided for @bookingSectionHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get bookingSectionHistory;

  /// No description provided for @bookingSectionCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingSectionCancelled;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusCheckInReady.
  ///
  /// In en, this message translates to:
  /// **'Check-in ready'**
  String get bookingStatusCheckInReady;

  /// No description provided for @bookingStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get bookingStatusCheckedIn;

  /// No description provided for @bookingStatusCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get bookingStatusCheckedOut;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get bookingStatusRefunded;

  /// No description provided for @bookingStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get bookingStatusArchived;

  /// No description provided for @bookingStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get bookingStatusNoShow;

  /// No description provided for @bookingTimelineCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking created'**
  String get bookingTimelineCreated;

  /// No description provided for @bookingTimelinePaid.
  ///
  /// In en, this message translates to:
  /// **'Payment completed'**
  String get bookingTimelinePaid;

  /// No description provided for @bookingTimelineConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingTimelineConfirmed;

  /// No description provided for @bookingTimelineModified.
  ///
  /// In en, this message translates to:
  /// **'Booking modified'**
  String get bookingTimelineModified;

  /// No description provided for @bookingTimelineCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Guest checked in'**
  String get bookingTimelineCheckedIn;

  /// No description provided for @bookingTimelineCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Guest checked out'**
  String get bookingTimelineCheckedOut;

  /// No description provided for @bookingTimelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'Stay completed'**
  String get bookingTimelineCompleted;

  /// No description provided for @bookingTimelineCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingTimelineCancelled;

  /// No description provided for @bookingTimelineArchived.
  ///
  /// In en, this message translates to:
  /// **'Booking archived'**
  String get bookingTimelineArchived;

  /// No description provided for @bookingTimelineRefunded.
  ///
  /// In en, this message translates to:
  /// **'Payment refunded'**
  String get bookingTimelineRefunded;

  /// No description provided for @bookingTimelineUnknown.
  ///
  /// In en, this message translates to:
  /// **'Status updated'**
  String get bookingTimelineUnknown;

  /// No description provided for @rewardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards & Benefits'**
  String get rewardsTitle;

  /// No description provided for @rewardsDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local demo rewards for previewing credits, points, coupons, referrals, and gift cards.'**
  String get rewardsDemoSubtitle;

  /// No description provided for @rewardsRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Rewards endpoints are not connected yet for real accounts.'**
  String get rewardsRealUnavailableMessage;

  /// No description provided for @rewardsRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Rewards not connected'**
  String get rewardsRealEmptyTitle;

  /// No description provided for @rewardsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get rewardsNotConnected;

  /// No description provided for @rewardsCountValue.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String rewardsCountValue(int count);

  /// No description provided for @rewardsHistoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No history'**
  String get rewardsHistoryEmptyTitle;

  /// No description provided for @rewardsHistoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reward history will appear here when available.'**
  String get rewardsHistoryEmptyMessage;

  /// No description provided for @rewardsActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This reward action is not connected for real accounts.'**
  String get rewardsActionUnavailable;

  /// No description provided for @rewardsCodeBlank.
  ///
  /// In en, this message translates to:
  /// **'Enter a code first.'**
  String get rewardsCodeBlank;

  /// No description provided for @rewardsCodeDuplicate.
  ///
  /// In en, this message translates to:
  /// **'This code is already used or claimed.'**
  String get rewardsCodeDuplicate;

  /// No description provided for @rewardsCodeRejected.
  ///
  /// In en, this message translates to:
  /// **'This demo code is not eligible.'**
  String get rewardsCodeRejected;

  /// No description provided for @rewardsExpiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String rewardsExpiresOn(String date);

  /// No description provided for @travelCreditsTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Credits'**
  String get travelCreditsTitle;

  /// No description provided for @travelCreditsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Promotional monetary credit, separate from travel wallet documents.'**
  String get travelCreditsSubtitle;

  /// No description provided for @travelCreditsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open Travel Credits'**
  String get travelCreditsSemantic;

  /// No description provided for @travelCreditsBalance.
  ///
  /// In en, this message translates to:
  /// **'Available travel credit'**
  String get travelCreditsBalance;

  /// No description provided for @travelCreditsBalanceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Travel credit balance'**
  String get travelCreditsBalanceSemantic;

  /// No description provided for @travelCreditsLocalOnly.
  ///
  /// In en, this message translates to:
  /// **'Demo credits are local preview data and are not synchronized.'**
  String get travelCreditsLocalOnly;

  /// No description provided for @travelCreditsNoCashOut.
  ///
  /// In en, this message translates to:
  /// **'Cash-out, withdrawal, and transfer controls are intentionally unavailable.'**
  String get travelCreditsNoCashOut;

  /// No description provided for @travelCreditsTransactions.
  ///
  /// In en, this message translates to:
  /// **'Credit transactions'**
  String get travelCreditsTransactions;

  /// No description provided for @creditTxnGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get creditTxnGrant;

  /// No description provided for @creditTxnPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get creditTxnPromotion;

  /// No description provided for @creditTxnRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund credit'**
  String get creditTxnRefund;

  /// No description provided for @creditTxnAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get creditTxnAdjustment;

  /// No description provided for @creditTxnRedemption.
  ///
  /// In en, this message translates to:
  /// **'Redemption'**
  String get creditTxnRedemption;

  /// No description provided for @creditTxnExpiration.
  ///
  /// In en, this message translates to:
  /// **'Expiration'**
  String get creditTxnExpiration;

  /// No description provided for @creditTxnReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get creditTxnReversal;

  /// No description provided for @loyaltyTitle.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Points'**
  String get loyaltyTitle;

  /// No description provided for @loyaltySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Integer point balance and immutable transaction history.'**
  String get loyaltySubtitle;

  /// No description provided for @loyaltySemantic.
  ///
  /// In en, this message translates to:
  /// **'Open Loyalty Points'**
  String get loyaltySemantic;

  /// No description provided for @loyaltyBalanceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loyalty point balance'**
  String get loyaltyBalanceSemantic;

  /// No description provided for @loyaltyCurrentBalance.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get loyaltyCurrentBalance;

  /// No description provided for @loyaltyLifetimeEarned.
  ///
  /// In en, this message translates to:
  /// **'Lifetime earned'**
  String get loyaltyLifetimeEarned;

  /// No description provided for @loyaltyPointsValue.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String loyaltyPointsValue(int points);

  /// No description provided for @pointsUnit.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get pointsUnit;

  /// No description provided for @loyaltyNoDirectRedeem.
  ///
  /// In en, this message translates to:
  /// **'Points are not money and direct redemption is not connected in UI-7.'**
  String get loyaltyNoDirectRedeem;

  /// No description provided for @loyaltyTransactions.
  ///
  /// In en, this message translates to:
  /// **'Point transactions'**
  String get loyaltyTransactions;

  /// No description provided for @loyaltyTxnEarnBooking.
  ///
  /// In en, this message translates to:
  /// **'Earn from booking'**
  String get loyaltyTxnEarnBooking;

  /// No description provided for @loyaltyTxnEarnReview.
  ///
  /// In en, this message translates to:
  /// **'Earn from review'**
  String get loyaltyTxnEarnReview;

  /// No description provided for @loyaltyTxnGrant.
  ///
  /// In en, this message translates to:
  /// **'Grant'**
  String get loyaltyTxnGrant;

  /// No description provided for @loyaltyTxnAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get loyaltyTxnAdjustment;

  /// No description provided for @loyaltyTxnReversal.
  ///
  /// In en, this message translates to:
  /// **'Reversal'**
  String get loyaltyTxnReversal;

  /// No description provided for @loyaltyTxnRedemptionDebit.
  ///
  /// In en, this message translates to:
  /// **'Redemption debit'**
  String get loyaltyTxnRedemptionDebit;

  /// No description provided for @loyaltyTxnRedemptionRelease.
  ///
  /// In en, this message translates to:
  /// **'Redemption release'**
  String get loyaltyTxnRedemptionRelease;

  /// No description provided for @loyaltyTxnRedemptionRefund.
  ///
  /// In en, this message translates to:
  /// **'Redemption refund'**
  String get loyaltyTxnRedemptionRefund;

  /// No description provided for @membershipTitle.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membershipTitle;

  /// No description provided for @membershipSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tier progress, benefits metadata, and tier history.'**
  String get membershipSubtitle;

  /// No description provided for @membershipSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open Membership'**
  String get membershipSemantic;

  /// No description provided for @membershipRealUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Membership enrollment is not connected yet for real accounts.'**
  String get membershipRealUnavailable;

  /// No description provided for @membershipTierSemantic.
  ///
  /// In en, this message translates to:
  /// **'Membership tier and progress'**
  String get membershipTierSemantic;

  /// No description provided for @membershipActiveStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get membershipActiveStatus;

  /// No description provided for @membershipPreviewStatus.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get membershipPreviewStatus;

  /// No description provided for @membershipExpiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get membershipExpiredStatus;

  /// No description provided for @membershipActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'This demo membership is active locally.'**
  String get membershipActiveMessage;

  /// No description provided for @membershipPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Preview benefits before demo enrollment.'**
  String get membershipPreviewMessage;

  /// No description provided for @membershipProgressSemantic.
  ///
  /// In en, this message translates to:
  /// **'Membership progress {percent} percent'**
  String membershipProgressSemantic(int percent);

  /// No description provided for @membershipHighestTier.
  ///
  /// In en, this message translates to:
  /// **'Highest tier reached. No fictional next tier is shown.'**
  String get membershipHighestTier;

  /// No description provided for @membershipNextTier.
  ///
  /// In en, this message translates to:
  /// **'Next tier: {tier}'**
  String membershipNextTier(String tier);

  /// No description provided for @membershipEnrollAction.
  ///
  /// In en, this message translates to:
  /// **'Enroll locally'**
  String get membershipEnrollAction;

  /// No description provided for @membershipEnrolledAction.
  ///
  /// In en, this message translates to:
  /// **'Enrolled locally'**
  String get membershipEnrolledAction;

  /// No description provided for @membershipEnrollSemantic.
  ///
  /// In en, this message translates to:
  /// **'Enroll in local demo membership'**
  String get membershipEnrollSemantic;

  /// No description provided for @membershipEnrollSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demo membership enrolled locally.'**
  String get membershipEnrollSuccess;

  /// No description provided for @membershipBenefitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Benefits metadata'**
  String get membershipBenefitsTitle;

  /// No description provided for @membershipHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Tier history'**
  String get membershipHistoryTitle;

  /// No description provided for @membershipTierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get membershipTierBronze;

  /// No description provided for @membershipTierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get membershipTierSilver;

  /// No description provided for @membershipTierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get membershipTierGold;

  /// No description provided for @membershipTierPlatinum.
  ///
  /// In en, this message translates to:
  /// **'Platinum'**
  String get membershipTierPlatinum;

  /// No description provided for @membershipTierDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond'**
  String get membershipTierDiamond;

  /// No description provided for @benefitPointsMultiplier.
  ///
  /// In en, this message translates to:
  /// **'Points multiplier'**
  String get benefitPointsMultiplier;

  /// No description provided for @benefitMemberCoupons.
  ///
  /// In en, this message translates to:
  /// **'Member-only coupons'**
  String get benefitMemberCoupons;

  /// No description provided for @benefitPrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get benefitPrioritySupport;

  /// No description provided for @benefitEarlyAccess.
  ///
  /// In en, this message translates to:
  /// **'Early access'**
  String get benefitEarlyAccess;

  /// No description provided for @benefitLateCheckout.
  ///
  /// In en, this message translates to:
  /// **'Late checkout'**
  String get benefitLateCheckout;

  /// No description provided for @benefitEarlyCheckin.
  ///
  /// In en, this message translates to:
  /// **'Early check-in'**
  String get benefitEarlyCheckin;

  /// No description provided for @benefitRoomUpgrade.
  ///
  /// In en, this message translates to:
  /// **'Room upgrade'**
  String get benefitRoomUpgrade;

  /// No description provided for @benefitFreeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Free breakfast'**
  String get benefitFreeBreakfast;

  /// No description provided for @benefitAirportTransfer.
  ///
  /// In en, this message translates to:
  /// **'Airport transfer'**
  String get benefitAirportTransfer;

  /// No description provided for @benefitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom benefit'**
  String get benefitCustom;

  /// No description provided for @couponsTitle.
  ///
  /// In en, this message translates to:
  /// **'Coupons'**
  String get couponsTitle;

  /// No description provided for @couponsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Claimed coupons and read-only eligibility previews.'**
  String get couponsSubtitle;

  /// No description provided for @couponsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open Coupons'**
  String get couponsSemantic;

  /// No description provided for @couponsRealUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Coupon claiming is not connected yet for real accounts.'**
  String get couponsRealUnavailable;

  /// No description provided for @couponClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim demo coupon'**
  String get couponClaimTitle;

  /// No description provided for @couponCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Coupon code'**
  String get couponCodeLabel;

  /// No description provided for @couponClaimHelper.
  ///
  /// In en, this message translates to:
  /// **'Use LOCAL300 for the local demo claim. Coupons are not applied to bookings.'**
  String get couponClaimHelper;

  /// No description provided for @couponClaimAction.
  ///
  /// In en, this message translates to:
  /// **'Claim coupon'**
  String get couponClaimAction;

  /// No description provided for @couponClaimSemantic.
  ///
  /// In en, this message translates to:
  /// **'Claim local demo coupon'**
  String get couponClaimSemantic;

  /// No description provided for @couponClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demo coupon claimed locally.'**
  String get couponClaimSuccess;

  /// No description provided for @couponsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No coupons'**
  String get couponsEmptyTitle;

  /// No description provided for @couponsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Coupons will appear after they are claimed or connected.'**
  String get couponsEmptyMessage;

  /// No description provided for @couponCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Coupon {code}'**
  String couponCardSemantic(String code);

  /// No description provided for @couponPreviewReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Preview is read-only and does not mark the coupon used.'**
  String get couponPreviewReadOnly;

  /// No description provided for @couponPercentageValue.
  ///
  /// In en, this message translates to:
  /// **'{percent}% off'**
  String couponPercentageValue(int percent);

  /// No description provided for @couponFixedValue.
  ///
  /// In en, this message translates to:
  /// **'{amount} off'**
  String couponFixedValue(String amount);

  /// No description provided for @couponAmountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Amount unavailable'**
  String get couponAmountUnavailable;

  /// No description provided for @couponTargetAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get couponTargetAll;

  /// No description provided for @couponTargetHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get couponTargetHotel;

  /// No description provided for @couponTargetRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get couponTargetRoom;

  /// No description provided for @couponTargetPlaceType.
  ///
  /// In en, this message translates to:
  /// **'Place type'**
  String get couponTargetPlaceType;

  /// No description provided for @referralTitle.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referralTitle;

  /// No description provided for @referralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Referral code, statistics, and local demo code use.'**
  String get referralSubtitle;

  /// No description provided for @referralSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open Referral'**
  String get referralSemantic;

  /// No description provided for @referralRealUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Referral actions are not connected yet for real accounts.'**
  String get referralRealUnavailable;

  /// No description provided for @referralCodeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCodeSemantic;

  /// No description provided for @referralYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get referralYourCode;

  /// No description provided for @referralStats.
  ///
  /// In en, this message translates to:
  /// **'{successful} successful · {pending} pending'**
  String referralStats(int successful, int pending);

  /// No description provided for @referralCopyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get referralCopyAction;

  /// No description provided for @referralCopiedAction.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get referralCopiedAction;

  /// No description provided for @referralCopySemantic.
  ///
  /// In en, this message translates to:
  /// **'Copy referral code'**
  String get referralCopySemantic;

  /// No description provided for @referralUseCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Use referral code'**
  String get referralUseCodeTitle;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral code'**
  String get referralCodeLabel;

  /// No description provided for @referralUseCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Using a code creates a pending local referral only. No reward is granted immediately.'**
  String get referralUseCodeHelper;

  /// No description provided for @referralUseCodeAction.
  ///
  /// In en, this message translates to:
  /// **'Use code'**
  String get referralUseCodeAction;

  /// No description provided for @referralUseCodeSemantic.
  ///
  /// In en, this message translates to:
  /// **'Use local demo referral code'**
  String get referralUseCodeSemantic;

  /// No description provided for @referralUseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Referral code recorded locally as pending.'**
  String get referralUseSuccess;

  /// No description provided for @referralOwnCodeRejected.
  ///
  /// In en, this message translates to:
  /// **'You cannot use your own referral code.'**
  String get referralOwnCodeRejected;

  /// No description provided for @referralHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Referral history'**
  String get referralHistoryTitle;

  /// No description provided for @referralUsedNoReward.
  ///
  /// In en, this message translates to:
  /// **'USED means pending qualification; no reward was granted.'**
  String get referralUsedNoReward;

  /// No description provided for @referralRoleInviter.
  ///
  /// In en, this message translates to:
  /// **'Inviter'**
  String get referralRoleInviter;

  /// No description provided for @referralRoleInvitee.
  ///
  /// In en, this message translates to:
  /// **'Invitee'**
  String get referralRoleInvitee;

  /// No description provided for @referralStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get referralStatusUsed;

  /// No description provided for @referralStatusRewarded.
  ///
  /// In en, this message translates to:
  /// **'Rewarded'**
  String get referralStatusRewarded;

  /// No description provided for @giftCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift Cards'**
  String get giftCardsTitle;

  /// No description provided for @giftCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Masked cards, balances, details, and read-only previews.'**
  String get giftCardsSubtitle;

  /// No description provided for @giftCardsSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open Gift Cards'**
  String get giftCardsSemantic;

  /// No description provided for @giftCardsRealUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Gift-card actions are not connected yet for real accounts.'**
  String get giftCardsRealUnavailable;

  /// No description provided for @giftCardClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim demo gift card'**
  String get giftCardClaimTitle;

  /// No description provided for @giftCardCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Gift-card code'**
  String get giftCardCodeLabel;

  /// No description provided for @giftCardClaimHelper.
  ///
  /// In en, this message translates to:
  /// **'Use GIFTDEMO for a local demo claim. No purchase or payment flow exists.'**
  String get giftCardClaimHelper;

  /// No description provided for @giftCardClaimAction.
  ///
  /// In en, this message translates to:
  /// **'Claim gift card'**
  String get giftCardClaimAction;

  /// No description provided for @giftCardClaimSemantic.
  ///
  /// In en, this message translates to:
  /// **'Claim local demo gift card'**
  String get giftCardClaimSemantic;

  /// No description provided for @giftCardClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demo gift card claimed locally.'**
  String get giftCardClaimSuccess;

  /// No description provided for @giftCardsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No gift cards'**
  String get giftCardsEmptyTitle;

  /// No description provided for @giftCardsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Gift cards will appear after they are claimed or connected.'**
  String get giftCardsEmptyMessage;

  /// No description provided for @giftCardCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Gift card {code}'**
  String giftCardCardSemantic(String code);

  /// No description provided for @giftCardBalance.
  ///
  /// In en, this message translates to:
  /// **'Card balance'**
  String get giftCardBalance;

  /// No description provided for @giftCardTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Gift-card transactions'**
  String get giftCardTransactionsTitle;

  /// No description provided for @giftCardPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview only'**
  String get giftCardPreviewAction;

  /// No description provided for @giftCardPreviewSemantic.
  ///
  /// In en, this message translates to:
  /// **'Preview gift card without changing balance'**
  String get giftCardPreviewSemantic;

  /// No description provided for @giftCardPreviewReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Gift-card preview is read-only and does not change balance.'**
  String get giftCardPreviewReadOnly;

  /// No description provided for @giftCardActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate locally'**
  String get giftCardActivateAction;

  /// No description provided for @giftCardActivateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Demo gift card activated locally.'**
  String get giftCardActivateSuccess;

  /// No description provided for @giftCardStatusIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get giftCardStatusIssued;

  /// No description provided for @giftCardStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get giftCardStatusActive;

  /// No description provided for @giftCardStatusPartiallyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Partially redeemed'**
  String get giftCardStatusPartiallyRedeemed;

  /// No description provided for @giftCardStatusFullyRedeemed.
  ///
  /// In en, this message translates to:
  /// **'Fully redeemed'**
  String get giftCardStatusFullyRedeemed;

  /// No description provided for @giftCardStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get giftCardStatusExpired;

  /// No description provided for @giftCardStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get giftCardStatusCancelled;

  /// No description provided for @giftCardTxnIssue.
  ///
  /// In en, this message translates to:
  /// **'Issue'**
  String get giftCardTxnIssue;

  /// No description provided for @giftCardTxnActivation.
  ///
  /// In en, this message translates to:
  /// **'Activation'**
  String get giftCardTxnActivation;

  /// No description provided for @giftCardTxnRedemption.
  ///
  /// In en, this message translates to:
  /// **'Redemption'**
  String get giftCardTxnRedemption;

  /// No description provided for @giftCardTxnRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get giftCardTxnRefund;

  /// No description provided for @giftCardTxnExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get giftCardTxnExpiry;

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

  /// No description provided for @travelWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Wallet'**
  String get travelWalletTitle;

  /// No description provided for @walletDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local demo organizer for passports, visas, tickets, vouchers, receipts, and booking confirmations.'**
  String get walletDemoSubtitle;

  /// No description provided for @walletPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Sensitive document numbers are masked before storage. UI-8 does not upload files, scan documents, or synchronize wallet data.'**
  String get walletPrivacyNotice;

  /// No description provided for @walletRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Wallet is not connected yet'**
  String get walletRealEmptyTitle;

  /// No description provided for @walletRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Real accounts will show wallet documents after backend integration. No demo wallet data is shown for real sessions.'**
  String get walletRealEmptyMessage;

  /// No description provided for @walletSummaryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get walletSummaryTotal;

  /// No description provided for @walletSummaryActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get walletSummaryActive;

  /// No description provided for @walletSummaryUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get walletSummaryUpcoming;

  /// No description provided for @walletSummaryExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get walletSummaryExpiringSoon;

  /// No description provided for @walletSummaryExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get walletSummaryExpired;

  /// No description provided for @walletSummaryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get walletSummaryFavorites;

  /// No description provided for @walletSummaryArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get walletSummaryArchived;

  /// No description provided for @walletSummaryUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get walletSummaryUnlinked;

  /// No description provided for @walletSummarySemantic.
  ///
  /// In en, this message translates to:
  /// **'{label}: {count}'**
  String walletSummarySemantic(String label, int count);

  /// No description provided for @walletSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title, issuer, masked reference, or trip'**
  String get walletSearchHint;

  /// No description provided for @walletFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get walletFilterCategory;

  /// No description provided for @walletFilterType.
  ///
  /// In en, this message translates to:
  /// **'Item type'**
  String get walletFilterType;

  /// No description provided for @walletFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get walletFilterStatus;

  /// No description provided for @walletFilterLinkedTrip.
  ///
  /// In en, this message translates to:
  /// **'Linked trip'**
  String get walletFilterLinkedTrip;

  /// No description provided for @walletFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get walletFilterAll;

  /// No description provided for @walletFavoritesOnly.
  ///
  /// In en, this message translates to:
  /// **'Favorites only'**
  String get walletFavoritesOnly;

  /// No description provided for @walletArchivedOnly.
  ///
  /// In en, this message translates to:
  /// **'Archived only'**
  String get walletArchivedOnly;

  /// No description provided for @walletCreateItemAction.
  ///
  /// In en, this message translates to:
  /// **'Add wallet item'**
  String get walletCreateItemAction;

  /// No description provided for @walletImportBookingAction.
  ///
  /// In en, this message translates to:
  /// **'Import booking'**
  String get walletImportBookingAction;

  /// No description provided for @walletNoBookingsToImport.
  ///
  /// In en, this message translates to:
  /// **'No local demo bookings are available to import.'**
  String get walletNoBookingsToImport;

  /// No description provided for @walletEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallet items match'**
  String get walletEmptyTitle;

  /// No description provided for @walletEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Adjust search or filters, or add local demo metadata.'**
  String get walletEmptyMessage;

  /// No description provided for @walletSectionFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get walletSectionFavorites;

  /// No description provided for @walletSectionExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring soon'**
  String get walletSectionExpiringSoon;

  /// No description provided for @walletSectionUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get walletSectionUpcoming;

  /// No description provided for @walletSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get walletSectionActive;

  /// No description provided for @walletSectionExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get walletSectionExpired;

  /// No description provided for @walletSectionArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get walletSectionArchived;

  /// No description provided for @walletSectionByCategory.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get walletSectionByCategory;

  /// No description provided for @walletSectionByTrip.
  ///
  /// In en, this message translates to:
  /// **'By trip'**
  String get walletSectionByTrip;

  /// No description provided for @walletItemSemantic.
  ///
  /// In en, this message translates to:
  /// **'Wallet item {title}'**
  String walletItemSemantic(String title);

  /// No description provided for @walletSourceMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata only'**
  String get walletSourceMetadata;

  /// No description provided for @walletSourceTripDocument.
  ///
  /// In en, this message translates to:
  /// **'Trip document'**
  String get walletSourceTripDocument;

  /// No description provided for @walletSourceBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get walletSourceBooking;

  /// No description provided for @walletSourceInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get walletSourceInvoice;

  /// No description provided for @walletReferenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Masked reference'**
  String get walletReferenceLabel;

  /// No description provided for @walletMaskedReference.
  ///
  /// In en, this message translates to:
  /// **'Masked reference {reference}'**
  String walletMaskedReference(String reference);

  /// No description provided for @walletValidityLabel.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get walletValidityLabel;

  /// No description provided for @walletNoValidity.
  ///
  /// In en, this message translates to:
  /// **'No validity dates supplied'**
  String get walletNoValidity;

  /// No description provided for @walletValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String walletValidUntil(String date);

  /// No description provided for @walletValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from {date}'**
  String walletValidFrom(String date);

  /// No description provided for @walletValidPeriod.
  ///
  /// In en, this message translates to:
  /// **'{from} - {until}'**
  String walletValidPeriod(String from, String until);

  /// No description provided for @walletLinkedTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked trip'**
  String get walletLinkedTripLabel;

  /// No description provided for @walletReminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminder'**
  String get walletReminderLabel;

  /// No description provided for @walletReminderEnabled.
  ///
  /// In en, this message translates to:
  /// **'Local reminder preference enabled'**
  String get walletReminderEnabled;

  /// No description provided for @walletReminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Local reminder preference disabled'**
  String get walletReminderDisabled;

  /// No description provided for @walletReminderEnableAction.
  ///
  /// In en, this message translates to:
  /// **'Enable reminder'**
  String get walletReminderEnableAction;

  /// No description provided for @walletReminderDisableAction.
  ///
  /// In en, this message translates to:
  /// **'Disable reminder'**
  String get walletReminderDisableAction;

  /// No description provided for @walletFavoriteAction.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get walletFavoriteAction;

  /// No description provided for @walletUnfavoriteAction.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get walletUnfavoriteAction;

  /// No description provided for @walletArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get walletArchiveAction;

  /// No description provided for @walletRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get walletRestoreAction;

  /// No description provided for @walletDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get walletDeleteAction;

  /// No description provided for @walletEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get walletEditAction;

  /// No description provided for @walletSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get walletSaveAction;

  /// No description provided for @walletCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add wallet metadata'**
  String get walletCreateTitle;

  /// No description provided for @walletEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit wallet metadata'**
  String get walletEditTitle;

  /// No description provided for @walletTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get walletTitleLabel;

  /// No description provided for @walletIssuerLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get walletIssuerLabel;

  /// No description provided for @walletReferenceInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference number'**
  String get walletReferenceInputLabel;

  /// No description provided for @walletReferencePrivacyHelper.
  ///
  /// In en, this message translates to:
  /// **'Reference input is masked immediately and the raw value is not retained.'**
  String get walletReferencePrivacyHelper;

  /// No description provided for @walletTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet item type'**
  String get walletTypeLabel;

  /// No description provided for @walletStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Stored status'**
  String get walletStatusLabel;

  /// No description provided for @walletNoValue.
  ///
  /// In en, this message translates to:
  /// **'Not supplied'**
  String get walletNoValue;

  /// No description provided for @walletUpdatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get walletUpdatedLabel;

  /// No description provided for @walletDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet item?'**
  String get walletDeleteConfirmTitle;

  /// No description provided for @walletDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {title} from the local demo wallet? The linked trip, booking, or document will not be deleted.'**
  String walletDeleteConfirmMessage(String title);

  /// No description provided for @walletSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item saved locally.'**
  String get walletSavedMessage;

  /// No description provided for @walletDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item deleted locally.'**
  String get walletDeletedMessage;

  /// No description provided for @walletDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'That local item already exists.'**
  String get walletDuplicateMessage;

  /// No description provided for @walletActionRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'That wallet action cannot be completed with the current data.'**
  String get walletActionRejectedMessage;

  /// No description provided for @walletInvalidDateMessage.
  ///
  /// In en, this message translates to:
  /// **'Valid-until date cannot be before valid-from date.'**
  String get walletInvalidDateMessage;

  /// No description provided for @walletNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected wallet item no longer exists.'**
  String get walletNotFoundMessage;

  /// No description provided for @walletActionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Travel Wallet actions are not connected for real accounts in this UI phase.'**
  String get walletActionUnavailable;

  /// No description provided for @walletTitleRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a title before saving.'**
  String get walletTitleRequiredMessage;

  /// No description provided for @walletBookingImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmation saved to the local demo wallet.'**
  String get walletBookingImportedMessage;

  /// No description provided for @walletBookingAlreadyImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'That booking is already in the local demo wallet.'**
  String get walletBookingAlreadyImportedMessage;

  /// No description provided for @walletSaveBookingAction.
  ///
  /// In en, this message translates to:
  /// **'Save to Travel Wallet'**
  String get walletSaveBookingAction;

  /// No description provided for @walletSaveBookingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Save this local demo booking to Travel Wallet'**
  String get walletSaveBookingSemantic;

  /// No description provided for @walletTypePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get walletTypePassport;

  /// No description provided for @walletTypeVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get walletTypeVisa;

  /// No description provided for @walletTypeBoardingPass.
  ///
  /// In en, this message translates to:
  /// **'Boarding pass'**
  String get walletTypeBoardingPass;

  /// No description provided for @walletTypeFlightTicket.
  ///
  /// In en, this message translates to:
  /// **'Flight ticket'**
  String get walletTypeFlightTicket;

  /// No description provided for @walletTypeTrainTicket.
  ///
  /// In en, this message translates to:
  /// **'Train ticket'**
  String get walletTypeTrainTicket;

  /// No description provided for @walletTypeBusTicket.
  ///
  /// In en, this message translates to:
  /// **'Bus ticket'**
  String get walletTypeBusTicket;

  /// No description provided for @walletTypeHotelVoucher.
  ///
  /// In en, this message translates to:
  /// **'Hotel voucher'**
  String get walletTypeHotelVoucher;

  /// No description provided for @walletTypeTourVoucher.
  ///
  /// In en, this message translates to:
  /// **'Tour voucher'**
  String get walletTypeTourVoucher;

  /// No description provided for @walletTypeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get walletTypeInsurance;

  /// No description provided for @walletTypeBookingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmation'**
  String get walletTypeBookingConfirmation;

  /// No description provided for @walletTypeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get walletTypeInvoice;

  /// No description provided for @walletTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get walletTypeReceipt;

  /// No description provided for @walletTypeItinerary.
  ///
  /// In en, this message translates to:
  /// **'Itinerary'**
  String get walletTypeItinerary;

  /// No description provided for @walletTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get walletTypeOther;

  /// No description provided for @walletCategoryIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get walletCategoryIdentity;

  /// No description provided for @walletCategoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get walletCategoryTransport;

  /// No description provided for @walletCategoryAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get walletCategoryAccommodation;

  /// No description provided for @walletCategoryActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get walletCategoryActivity;

  /// No description provided for @walletCategoryInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get walletCategoryInsurance;

  /// No description provided for @walletCategoryFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get walletCategoryFinancial;

  /// No description provided for @walletCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get walletCategoryOther;

  /// No description provided for @walletStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get walletStatusActive;

  /// No description provided for @walletStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get walletStatusUpcoming;

  /// No description provided for @walletStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get walletStatusExpired;

  /// No description provided for @walletStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get walletStatusCancelled;

  /// No description provided for @walletStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get walletStatusArchived;

  /// No description provided for @tripDocumentsAction.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tripDocumentsAction;

  /// No description provided for @tripDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Documents'**
  String get tripDocumentsTitle;

  /// No description provided for @tripDocumentsDemoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local demo metadata for {trip}. No file upload is performed.'**
  String tripDocumentsDemoSubtitle(String trip);

  /// No description provided for @tripDocumentsRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip documents are not connected yet'**
  String get tripDocumentsRealEmptyTitle;

  /// No description provided for @tripDocumentsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Real trip documents will appear after backend integration. No seeded demo documents are shown for real sessions.'**
  String get tripDocumentsRealEmptyMessage;

  /// No description provided for @tripDocumentsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get tripDocumentsEmptyTitle;

  /// No description provided for @tripDocumentsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add local demo metadata for tickets, bookings, receipts, or documents.'**
  String get tripDocumentsEmptyMessage;

  /// No description provided for @tripDocumentsTripDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is no longer available.'**
  String get tripDocumentsTripDeletedMessage;

  /// No description provided for @tripDocumentAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get tripDocumentAddAction;

  /// No description provided for @tripDocumentCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add trip document'**
  String get tripDocumentCreateTitle;

  /// No description provided for @tripDocumentEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit trip document'**
  String get tripDocumentEditTitle;

  /// No description provided for @tripDocumentTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Document title'**
  String get tripDocumentTitleLabel;

  /// No description provided for @tripDocumentNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tripDocumentNotesLabel;

  /// No description provided for @tripDocumentTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Document type'**
  String get tripDocumentTypeLabel;

  /// No description provided for @tripDocumentMediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media label'**
  String get tripDocumentMediaLabel;

  /// No description provided for @tripDocumentMediaUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe URL reference'**
  String get tripDocumentMediaUrlLabel;

  /// No description provided for @tripDocumentMediaHelper.
  ///
  /// In en, this message translates to:
  /// **'Only http or https references with a host are accepted. UI-8 does not upload files.'**
  String get tripDocumentMediaHelper;

  /// No description provided for @tripDocumentUploaderLabel.
  ///
  /// In en, this message translates to:
  /// **'Uploader'**
  String get tripDocumentUploaderLabel;

  /// No description provided for @tripDocumentNoUploadNotice.
  ///
  /// In en, this message translates to:
  /// **'This phase stores local demo metadata only. It does not upload files, parse PDFs, scan images, or share documents.'**
  String get tripDocumentNoUploadNotice;

  /// No description provided for @tripDocumentPinned.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get tripDocumentPinned;

  /// No description provided for @tripDocumentUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Not pinned'**
  String get tripDocumentUnpinned;

  /// No description provided for @tripDocumentPinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get tripDocumentPinAction;

  /// No description provided for @tripDocumentUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get tripDocumentUnpinAction;

  /// No description provided for @tripDocumentDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete document'**
  String get tripDocumentDeleteAction;

  /// No description provided for @tripDocumentSaveToWalletAction.
  ///
  /// In en, this message translates to:
  /// **'Save to wallet'**
  String get tripDocumentSaveToWalletAction;

  /// No description provided for @tripDocumentUnsafeUrlMessage.
  ///
  /// In en, this message translates to:
  /// **'Use a valid http or https URL with a host.'**
  String get tripDocumentUnsafeUrlMessage;

  /// No description provided for @tripDocumentSafeLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe link'**
  String get tripDocumentSafeLinkLabel;

  /// No description provided for @tripDocumentSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip document saved locally.'**
  String get tripDocumentSavedMessage;

  /// No description provided for @tripDocumentDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip document deleted locally.'**
  String get tripDocumentDeletedMessage;

  /// No description provided for @tripDocumentWalletImportedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip document saved to the local demo wallet.'**
  String get tripDocumentWalletImportedMessage;

  /// No description provided for @tripDocumentWalletDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'That trip document is already in the local demo wallet.'**
  String get tripDocumentWalletDuplicateMessage;

  /// No description provided for @tripDocumentDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete trip document?'**
  String get tripDocumentDeleteConfirmTitle;

  /// No description provided for @tripDocumentDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {title} from this local demo trip? Linked wallet items will be removed, but the trip remains unchanged.'**
  String tripDocumentDeleteConfirmMessage(String title);

  /// No description provided for @tripDocumentCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Trip document {title}'**
  String tripDocumentCardSemantic(String title);

  /// No description provided for @docTypeFlightTicket.
  ///
  /// In en, this message translates to:
  /// **'Flight ticket'**
  String get docTypeFlightTicket;

  /// No description provided for @docTypeHotelBooking.
  ///
  /// In en, this message translates to:
  /// **'Hotel booking'**
  String get docTypeHotelBooking;

  /// No description provided for @docTypeTrainTicket.
  ///
  /// In en, this message translates to:
  /// **'Train ticket'**
  String get docTypeTrainTicket;

  /// No description provided for @docTypeBusTicket.
  ///
  /// In en, this message translates to:
  /// **'Bus ticket'**
  String get docTypeBusTicket;

  /// No description provided for @docTypePassport.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get docTypePassport;

  /// No description provided for @docTypeVisa.
  ///
  /// In en, this message translates to:
  /// **'Visa'**
  String get docTypeVisa;

  /// No description provided for @docTypeInsurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get docTypeInsurance;

  /// No description provided for @docTypeTour.
  ///
  /// In en, this message translates to:
  /// **'Tour'**
  String get docTypeTour;

  /// No description provided for @docTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get docTypeReceipt;

  /// No description provided for @docTypePdf.
  ///
  /// In en, this message translates to:
  /// **'PDF'**
  String get docTypePdf;

  /// No description provided for @docTypeImage.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get docTypeImage;

  /// No description provided for @docTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get docTypeOther;

  /// No description provided for @tripCompanionAction.
  ///
  /// In en, this message translates to:
  /// **'Trip companion'**
  String get tripCompanionAction;

  /// No description provided for @tripCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip Companion'**
  String get tripCompanionTitle;

  /// No description provided for @tripCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Local demo tools for {trip}: sharing, notes, packing, reminders, and documents.'**
  String tripCompanionSubtitle(String trip);

  /// No description provided for @tripCompanionRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip companion is not connected yet'**
  String get tripCompanionRealEmptyTitle;

  /// No description provided for @tripCompanionRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Real collaboration, notes, packing, and reminders will appear after backend integration. No seeded demo data is shown for real sessions.'**
  String get tripCompanionRealEmptyMessage;

  /// No description provided for @tripCompanionPermissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Access: {role}'**
  String tripCompanionPermissionLabel(String role);

  /// No description provided for @tripCompanionReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This trip is read-only for your current local role.'**
  String get tripCompanionReadOnlyNotice;

  /// No description provided for @tripCompanionNoAccessRole.
  ///
  /// In en, this message translates to:
  /// **'No access'**
  String get tripCompanionNoAccessRole;

  /// No description provided for @tripCompanionCountCollaborators.
  ///
  /// In en, this message translates to:
  /// **'Collaborators'**
  String get tripCompanionCountCollaborators;

  /// No description provided for @tripCompanionCountNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get tripCompanionCountNotes;

  /// No description provided for @tripCompanionCountPacking.
  ///
  /// In en, this message translates to:
  /// **'To pack'**
  String get tripCompanionCountPacking;

  /// No description provided for @tripCompanionCountReminders.
  ///
  /// In en, this message translates to:
  /// **'Pending reminders'**
  String get tripCompanionCountReminders;

  /// No description provided for @tripCompanionCountDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tripCompanionCountDocuments;

  /// No description provided for @tripCompanionCollaborationTitle.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get tripCompanionCollaborationTitle;

  /// No description provided for @tripCompanionCollaborationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage local demo collaborators, roles, and trip privacy.'**
  String get tripCompanionCollaborationSubtitle;

  /// No description provided for @tripCompanionNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes & Journal'**
  String get tripCompanionNotesTitle;

  /// No description provided for @tripCompanionNotesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture pinned notes, ideas, memories, and journal entries.'**
  String get tripCompanionNotesSubtitle;

  /// No description provided for @tripCompanionPackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Packing Checklist'**
  String get tripCompanionPackingTitle;

  /// No description provided for @tripCompanionPackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track what is packed, assigned, and still pending.'**
  String get tripCompanionPackingSubtitle;

  /// No description provided for @tripCompanionRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get tripCompanionRemindersTitle;

  /// No description provided for @tripCompanionRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage in-app reminder records without delivery scheduling.'**
  String get tripCompanionRemindersSubtitle;

  /// No description provided for @tripCompanionDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open the existing trip document metadata screen.'**
  String get tripCompanionDocumentsSubtitle;

  /// No description provided for @tripCompanionOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open {module}'**
  String tripCompanionOpenSemantic(String module);

  /// No description provided for @sharedWithMeTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get sharedWithMeTitle;

  /// No description provided for @sharedWithMeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active local demo trips shared by another owner.'**
  String get sharedWithMeSubtitle;

  /// No description provided for @sharedWithMeRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared trips are not connected yet'**
  String get sharedWithMeRealEmptyTitle;

  /// No description provided for @sharedWithMeRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Real shared trips will appear after backend integration. No demo shared trips are shown for real sessions.'**
  String get sharedWithMeRealEmptyMessage;

  /// No description provided for @sharedWithMeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shared trips'**
  String get sharedWithMeEmptyTitle;

  /// No description provided for @sharedWithMeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Trips shared with you will appear here in Demo Mode.'**
  String get sharedWithMeEmptyMessage;

  /// No description provided for @sharedWithMeSummaryReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'This summary is local demo presentation only. Full shared-trip tools will open when the backend provides the complete trip record.'**
  String get sharedWithMeSummaryReadOnlyNotice;

  /// No description provided for @sharedWithMeOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner: {owner}'**
  String sharedWithMeOwnerLabel(String owner);

  /// No description provided for @sharedWithMeRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String sharedWithMeRoleLabel(String role);

  /// No description provided for @sharedWithMeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} shared trips'**
  String sharedWithMeCount(int count);

  /// No description provided for @collaborationPrivacyPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private local demo trip'**
  String get collaborationPrivacyPrivate;

  /// No description provided for @collaborationPrivacyPublic.
  ///
  /// In en, this message translates to:
  /// **'Public local demo visibility'**
  String get collaborationPrivacyPublic;

  /// No description provided for @collaborationPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Only the owner can manage collaborators and public/private state. Demo visibility does not publish a real share link.'**
  String get collaborationPrivacyNotice;

  /// No description provided for @collaborationInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite collaborator'**
  String get collaborationInviteTitle;

  /// No description provided for @collaborationInviteEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Demo user email'**
  String get collaborationInviteEmailLabel;

  /// No description provided for @collaborationInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get collaborationInviteAction;

  /// No description provided for @collaborationRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get collaborationRoleViewer;

  /// No description provided for @collaborationRoleEditor.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get collaborationRoleEditor;

  /// No description provided for @collaborationOwnerRole.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get collaborationOwnerRole;

  /// No description provided for @collaborationActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get collaborationActiveLabel;

  /// No description provided for @collaborationInactiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get collaborationInactiveLabel;

  /// No description provided for @collaborationChangeRoleAction.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get collaborationChangeRoleAction;

  /// No description provided for @collaborationRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get collaborationRemoveAction;

  /// No description provided for @collaborationRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove collaborator?'**
  String get collaborationRemoveConfirmTitle;

  /// No description provided for @collaborationRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this local demo trip? Their authored notes stay as history.'**
  String collaborationRemoveConfirmMessage(String name);

  /// No description provided for @collaborationPublicToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Public demo visibility'**
  String get collaborationPublicToggleLabel;

  /// No description provided for @collaborationNoShareUrlNotice.
  ///
  /// In en, this message translates to:
  /// **'No public URL, QR code, or external share delivery is created in this UI phase.'**
  String get collaborationNoShareUrlNotice;

  /// No description provided for @tripToolSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip companion changes saved locally.'**
  String get tripToolSavedMessage;

  /// No description provided for @tripToolUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Trip companion actions are not connected for real accounts in this UI phase.'**
  String get tripToolUnavailableMessage;

  /// No description provided for @tripToolForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Your current role cannot perform this action.'**
  String get tripToolForbiddenMessage;

  /// No description provided for @tripToolBlankMessage.
  ///
  /// In en, this message translates to:
  /// **'Required text cannot be empty.'**
  String get tripToolBlankMessage;

  /// No description provided for @tripToolInvalidEmailMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get tripToolInvalidEmailMessage;

  /// No description provided for @tripToolDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'That local record already exists.'**
  String get tripToolDuplicateMessage;

  /// No description provided for @tripToolRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'That action cannot be completed with the current trip data.'**
  String get tripToolRejectedMessage;

  /// No description provided for @tripToolUnsafeUrlMessage.
  ///
  /// In en, this message translates to:
  /// **'Use a valid http or https URL with a host and no credentials.'**
  String get tripToolUnsafeUrlMessage;

  /// No description provided for @tripToolNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'The selected record is no longer available.'**
  String get tripToolNotFoundMessage;

  /// No description provided for @tripToolInvalidQuantityMessage.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be an integer of at least 1.'**
  String get tripToolInvalidQuantityMessage;

  /// No description provided for @tripToolInvalidReorderMessage.
  ///
  /// In en, this message translates to:
  /// **'Packing reorder must contain each current item exactly once.'**
  String get tripToolInvalidReorderMessage;

  /// No description provided for @tripToolInvalidDateMessage.
  ///
  /// In en, this message translates to:
  /// **'Use a valid local date and time.'**
  String get tripToolInvalidDateMessage;

  /// No description provided for @notesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes, authors, or journal text'**
  String get notesSearchHint;

  /// No description provided for @notesAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get notesAddAction;

  /// No description provided for @notesEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get notesEditAction;

  /// No description provided for @notesContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get notesContentLabel;

  /// No description provided for @notesTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notesTitleLabel;

  /// No description provided for @notesTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Note type'**
  String get notesTypeLabel;

  /// No description provided for @notesMoodLabel.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get notesMoodLabel;

  /// No description provided for @notesPhotoUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe photo URL'**
  String get notesPhotoUrlLabel;

  /// No description provided for @notesPhotoMetadataLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo URL metadata'**
  String get notesPhotoMetadataLabel;

  /// No description provided for @notesLinkedDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked day'**
  String get notesLinkedDayLabel;

  /// No description provided for @notesLinkedItemLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked activity'**
  String get notesLinkedItemLabel;

  /// No description provided for @notesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notes match'**
  String get notesEmptyTitle;

  /// No description provided for @notesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a local demo note or adjust search and filters.'**
  String get notesEmptyMessage;

  /// No description provided for @notesPinAction.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get notesPinAction;

  /// No description provided for @notesUnpinAction.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get notesUnpinAction;

  /// No description provided for @notesDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete note'**
  String get notesDeleteAction;

  /// No description provided for @notesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete note?'**
  String get notesDeleteConfirmTitle;

  /// No description provided for @notesDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {title} from the local demo journal?'**
  String notesDeleteConfirmMessage(String title);

  /// No description provided for @noteTypeNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteTypeNote;

  /// No description provided for @noteTypeJournal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get noteTypeJournal;

  /// No description provided for @noteTypeReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder note'**
  String get noteTypeReminder;

  /// No description provided for @noteTypeIdea.
  ///
  /// In en, this message translates to:
  /// **'Idea'**
  String get noteTypeIdea;

  /// No description provided for @noteTypeMemory.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get noteTypeMemory;

  /// No description provided for @moodHappy.
  ///
  /// In en, this message translates to:
  /// **'Happy'**
  String get moodHappy;

  /// No description provided for @moodExcited.
  ///
  /// In en, this message translates to:
  /// **'Excited'**
  String get moodExcited;

  /// No description provided for @moodCalm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get moodCalm;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodStressed.
  ///
  /// In en, this message translates to:
  /// **'Stressed'**
  String get moodStressed;

  /// No description provided for @moodNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get moodNeutral;

  /// No description provided for @packingSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search packing items, notes, or assignees'**
  String get packingSearchHint;

  /// No description provided for @packingAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add packing item'**
  String get packingAddAction;

  /// No description provided for @packingEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get packingEditAction;

  /// No description provided for @packingLabelField.
  ///
  /// In en, this message translates to:
  /// **'Item label'**
  String get packingLabelField;

  /// No description provided for @packingQuantityField.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get packingQuantityField;

  /// No description provided for @packingCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Packing category'**
  String get packingCategoryLabel;

  /// No description provided for @packingAssigneeLabel.
  ///
  /// In en, this message translates to:
  /// **'Assigned to'**
  String get packingAssigneeLabel;

  /// No description provided for @packingNotesField.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get packingNotesField;

  /// No description provided for @packingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No packing items match'**
  String get packingEmptyTitle;

  /// No description provided for @packingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add local demo packing items or adjust filters.'**
  String get packingEmptyMessage;

  /// No description provided for @packingProgressValue.
  ///
  /// In en, this message translates to:
  /// **'{checked} of {total} packed ({percent}%)'**
  String packingProgressValue(int checked, int total, int percent);

  /// No description provided for @packingUncheckedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} still unpacked'**
  String packingUncheckedCount(int count);

  /// No description provided for @packingDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get packingDeleteAction;

  /// No description provided for @packingDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete packing item?'**
  String get packingDeleteConfirmTitle;

  /// No description provided for @packingDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {label} from this local demo checklist?'**
  String packingDeleteConfirmMessage(String label);

  /// No description provided for @packingMoveUpAction.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get packingMoveUpAction;

  /// No description provided for @packingMoveDownAction.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get packingMoveDownAction;

  /// No description provided for @packingUnassignedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get packingUnassignedLabel;

  /// No description provided for @packingCategoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get packingCategoryDocuments;

  /// No description provided for @packingCategoryClothes.
  ///
  /// In en, this message translates to:
  /// **'Clothes'**
  String get packingCategoryClothes;

  /// No description provided for @packingCategoryToiletries.
  ///
  /// In en, this message translates to:
  /// **'Toiletries'**
  String get packingCategoryToiletries;

  /// No description provided for @packingCategoryElectronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get packingCategoryElectronics;

  /// No description provided for @packingCategoryMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get packingCategoryMedicine;

  /// No description provided for @packingCategoryMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get packingCategoryMoney;

  /// No description provided for @packingCategoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get packingCategoryFood;

  /// No description provided for @packingCategoryBaby.
  ///
  /// In en, this message translates to:
  /// **'Baby'**
  String get packingCategoryBaby;

  /// No description provided for @packingCategoryPet.
  ///
  /// In en, this message translates to:
  /// **'Pet'**
  String get packingCategoryPet;

  /// No description provided for @packingCategoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get packingCategoryOther;

  /// No description provided for @remindersIncludeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Include cancelled'**
  String get remindersIncludeCancelled;

  /// No description provided for @remindersAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get remindersAddAction;

  /// No description provided for @remindersEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get remindersEditAction;

  /// No description provided for @reminderTitleField.
  ///
  /// In en, this message translates to:
  /// **'Reminder title'**
  String get reminderTitleField;

  /// No description provided for @reminderMessageField.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get reminderMessageField;

  /// No description provided for @reminderAtField.
  ///
  /// In en, this message translates to:
  /// **'Local date and time'**
  String get reminderAtField;

  /// No description provided for @reminderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder type'**
  String get reminderTypeLabel;

  /// No description provided for @reminderStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reminderStatusPending;

  /// No description provided for @reminderStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get reminderStatusCompleted;

  /// No description provided for @reminderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get reminderStatusCancelled;

  /// No description provided for @reminderOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get reminderOverdue;

  /// No description provided for @reminderEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders match'**
  String get reminderEmptyTitle;

  /// No description provided for @reminderEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add local in-app reminder records or include cancelled items.'**
  String get reminderEmptyMessage;

  /// No description provided for @reminderCompleteAction.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get reminderCompleteAction;

  /// No description provided for @reminderCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel reminder'**
  String get reminderCancelAction;

  /// No description provided for @reminderDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder'**
  String get reminderDeleteAction;

  /// No description provided for @reminderDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete reminder?'**
  String get reminderDeleteConfirmTitle;

  /// No description provided for @reminderDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {title} from this local demo trip?'**
  String reminderDeleteConfirmMessage(String title);

  /// No description provided for @reminderTypeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reminderTypeCustom;

  /// No description provided for @reminderTypeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get reminderTypeDocument;

  /// No description provided for @reminderTypeCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get reminderTypeCheckIn;

  /// No description provided for @reminderTypeFlight.
  ///
  /// In en, this message translates to:
  /// **'Flight'**
  String get reminderTypeFlight;

  /// No description provided for @reminderTypeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get reminderTypeActivity;

  /// No description provided for @reminderTypePayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get reminderTypePayment;

  /// No description provided for @reminderTypePacking.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get reminderTypePacking;

  /// No description provided for @reminderTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reminderTypeOther;

  /// No description provided for @reminderLocalTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'Format: yyyy-MM-dd HH:mm. Stored as UTC for future API mapping.'**
  String get reminderLocalTimeHelper;

  /// No description provided for @reminderNoDeliveryNotice.
  ///
  /// In en, this message translates to:
  /// **'These are in-app reminder records only. UI-9 does not schedule push, email, SMS, or OS notifications.'**
  String get reminderNoDeliveryNotice;

  /// No description provided for @reviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviewsTitle;

  /// No description provided for @reviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse local demo review summaries shaped by the committed customer review contract.'**
  String get reviewsSubtitle;

  /// No description provided for @reviewsRealUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews are not connected yet'**
  String get reviewsRealUnavailableTitle;

  /// No description provided for @reviewsRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Review APIs are not wired in this UI phase. No local review data is shown for real sessions.'**
  String get reviewsRealUnavailableMessage;

  /// No description provided for @reviewSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Traveler trust'**
  String get reviewSummaryTitle;

  /// No description provided for @reviewSummarySemantic.
  ///
  /// In en, this message translates to:
  /// **'Review summary for {place}'**
  String reviewSummarySemantic(String place);

  /// No description provided for @reviewPublicVisibilityNotice.
  ///
  /// In en, this message translates to:
  /// **'Public lists use approved, sanitized review summaries only.'**
  String get reviewPublicVisibilityNotice;

  /// No description provided for @reviewNoReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'No approved reviews yet'**
  String get reviewNoReviewsTitle;

  /// No description provided for @reviewNoReviewsMessage.
  ///
  /// In en, this message translates to:
  /// **'Approved local demo reviews will appear here without exposing booking details.'**
  String get reviewNoReviewsMessage;

  /// No description provided for @reviewSeeAllAction.
  ///
  /// In en, this message translates to:
  /// **'See all reviews'**
  String get reviewSeeAllAction;

  /// No description provided for @reviewWriteAction.
  ///
  /// In en, this message translates to:
  /// **'Write review'**
  String get reviewWriteAction;

  /// No description provided for @reviewWriteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Write a review for {place}'**
  String reviewWriteSemantic(String place);

  /// No description provided for @reviewAggregateAverage.
  ///
  /// In en, this message translates to:
  /// **'{average} average'**
  String reviewAggregateAverage(String average);

  /// No description provided for @reviewRatingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Average rating {rating} out of 5'**
  String reviewRatingSemantic(String rating);

  /// No description provided for @reviewRatingOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5'**
  String reviewRatingOutOfFive(int rating);

  /// No description provided for @reviewCountExact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 approved review} other{{count} approved reviews}}'**
  String reviewCountExact(int count);

  /// No description provided for @reviewVerifiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 verified stay} other{{count} verified stays}}'**
  String reviewVerifiedCount(int count);

  /// No description provided for @reviewDistributionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rating distribution'**
  String get reviewDistributionSemantic;

  /// No description provided for @reviewStars.
  ///
  /// In en, this message translates to:
  /// **'Rating {rating}'**
  String reviewStars(int rating);

  /// No description provided for @reviewCategoryAverage.
  ///
  /// In en, this message translates to:
  /// **'{category}: {average}'**
  String reviewCategoryAverage(String category, String average);

  /// No description provided for @reviewCategoryCleanliness.
  ///
  /// In en, this message translates to:
  /// **'Cleanliness'**
  String get reviewCategoryCleanliness;

  /// No description provided for @reviewCategoryService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get reviewCategoryService;

  /// No description provided for @reviewCategoryLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reviewCategoryLocation;

  /// No description provided for @reviewCategoryValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get reviewCategoryValue;

  /// No description provided for @reviewCategoryFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get reviewCategoryFacilities;

  /// No description provided for @reviewFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Review controls'**
  String get reviewFiltersTitle;

  /// No description provided for @reviewSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get reviewSortLabel;

  /// No description provided for @reviewSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get reviewSortNewest;

  /// No description provided for @reviewSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get reviewSortOldest;

  /// No description provided for @reviewSortHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest rating'**
  String get reviewSortHighest;

  /// No description provided for @reviewSortLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest rating'**
  String get reviewSortLowest;

  /// No description provided for @reviewSortHelpful.
  ///
  /// In en, this message translates to:
  /// **'Most helpful'**
  String get reviewSortHelpful;

  /// No description provided for @reviewFilterRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get reviewFilterRating;

  /// No description provided for @reviewFilterVerifiedOnly.
  ///
  /// In en, this message translates to:
  /// **'Verified stays only'**
  String get reviewFilterVerifiedOnly;

  /// No description provided for @reviewFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews match'**
  String get reviewFilteredEmptyTitle;

  /// No description provided for @reviewFilteredEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Adjust the local filters to see approved demo review summaries.'**
  String get reviewFilteredEmptyMessage;

  /// No description provided for @reviewDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Review detail'**
  String get reviewDetailTitle;

  /// No description provided for @reviewNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Review unavailable'**
  String get reviewNotFoundTitle;

  /// No description provided for @reviewNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This review is no longer available in local demo state.'**
  String get reviewNotFoundMessage;

  /// No description provided for @reviewCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Review for {place}, {rating} out of 5'**
  String reviewCardSemantic(String place, int rating);

  /// No description provided for @reviewVerifiedStay.
  ///
  /// In en, this message translates to:
  /// **'Verified stay'**
  String get reviewVerifiedStay;

  /// No description provided for @reviewUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled review'**
  String get reviewUntitled;

  /// No description provided for @reviewAuthorLine.
  ///
  /// In en, this message translates to:
  /// **'By {author}'**
  String reviewAuthorLine(String author);

  /// No description provided for @reviewPublicSummaryOnly.
  ///
  /// In en, this message translates to:
  /// **'The public backend contract exposes sanitized summaries only. Full review text is shown only in the author\'s review view.'**
  String get reviewPublicSummaryOnly;

  /// No description provided for @reviewUnsupportedActionsNotice.
  ///
  /// In en, this message translates to:
  /// **'Customer edit/delete, helpful voting, reporting, media upload/delete, and partner-response mutation are not available in this local user app phase.'**
  String get reviewUnsupportedActionsNotice;

  /// No description provided for @reviewMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Review media'**
  String get reviewMediaTitle;

  /// No description provided for @reviewMediaCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 media item} other{{count} media items}}'**
  String reviewMediaCount(int count);

  /// No description provided for @reviewMediaCountSemantic.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review media item} other{{count} review media items}}'**
  String reviewMediaCountSemantic(int count);

  /// No description provided for @reviewMoreMediaCount.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String reviewMoreMediaCount(int count);

  /// No description provided for @reviewMediaGallerySemantic.
  ///
  /// In en, this message translates to:
  /// **'Review media gallery with {count} items'**
  String reviewMediaGallerySemantic(int count);

  /// No description provided for @reviewMediaItemSemantic.
  ///
  /// In en, this message translates to:
  /// **'Review media {index} of {total}, {type}, {description}'**
  String reviewMediaItemSemantic(
      int index, int total, String type, String description);

  /// No description provided for @reviewMediaIndex.
  ///
  /// In en, this message translates to:
  /// **'{index} of {total}'**
  String reviewMediaIndex(int index, int total);

  /// No description provided for @reviewMediaTypePhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get reviewMediaTypePhoto;

  /// No description provided for @reviewMediaTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get reviewMediaTypeVideo;

  /// No description provided for @reviewMediaTypeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get reviewMediaTypeDocument;

  /// No description provided for @reviewCoverMedia.
  ///
  /// In en, this message translates to:
  /// **'Cover image'**
  String get reviewCoverMedia;

  /// No description provided for @reviewMediaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Media unavailable'**
  String get reviewMediaUnavailable;

  /// No description provided for @reviewImageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get reviewImageUnavailable;

  /// No description provided for @reviewVideoPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video preview unavailable'**
  String get reviewVideoPreviewUnavailable;

  /// No description provided for @reviewUnsupportedMedia.
  ///
  /// In en, this message translates to:
  /// **'Unsupported media'**
  String get reviewUnsupportedMedia;

  /// No description provided for @reviewPartnerResponseTitle.
  ///
  /// In en, this message translates to:
  /// **'Response from the property'**
  String get reviewPartnerResponseTitle;

  /// No description provided for @reviewPropertyResponseIndicator.
  ///
  /// In en, this message translates to:
  /// **'Property response'**
  String get reviewPropertyResponseIndicator;

  /// No description provided for @reviewPartnerResponseSemantic.
  ///
  /// In en, this message translates to:
  /// **'Property response for {review}'**
  String reviewPartnerResponseSemantic(String review);

  /// No description provided for @reviewRespondedOn.
  ///
  /// In en, this message translates to:
  /// **'Responded on {date}'**
  String reviewRespondedOn(String date);

  /// No description provided for @reviewMediaAttachmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Review media'**
  String get reviewMediaAttachmentTitle;

  /// No description provided for @reviewMediaAttachmentUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Photo and video attachments will be available when the review media API is connected.'**
  String get reviewMediaAttachmentUnavailable;

  /// No description provided for @reviewUploadRequiresBackend.
  ///
  /// In en, this message translates to:
  /// **'This local demo submits text-only reviews; it does not upload files or accept typed media URLs.'**
  String get reviewUploadRequiresBackend;

  /// No description provided for @reviewDetailMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Review metadata'**
  String get reviewDetailMetadataTitle;

  /// No description provided for @reviewLinkedBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked booking'**
  String get reviewLinkedBookingLabel;

  /// No description provided for @reviewCreatedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get reviewCreatedAtLabel;

  /// No description provided for @reviewApprovedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get reviewApprovedAtLabel;

  /// No description provided for @reviewRejectedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get reviewRejectedAtLabel;

  /// No description provided for @reviewRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe rejection reason'**
  String get reviewRejectReasonLabel;

  /// No description provided for @reviewHelpfulCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Helpful count'**
  String get reviewHelpfulCountLabel;

  /// No description provided for @reviewReportedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Reported count'**
  String get reviewReportedCountLabel;

  /// No description provided for @reviewWriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get reviewWriteTitle;

  /// No description provided for @reviewIneligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Review not available'**
  String get reviewIneligibleTitle;

  /// No description provided for @reviewBackendCreateNotice.
  ///
  /// In en, this message translates to:
  /// **'A local demo review maps to the booking-scoped customer review route and starts as Pending. It is not sent to the backend.'**
  String get reviewBackendCreateNotice;

  /// No description provided for @reviewOverallRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall rating'**
  String get reviewOverallRatingLabel;

  /// No description provided for @reviewTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reviewTitleLabel;

  /// No description provided for @reviewTitleHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Maximum 200 characters.'**
  String get reviewTitleHelper;

  /// No description provided for @reviewContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Review text'**
  String get reviewContentLabel;

  /// No description provided for @reviewContentHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Maximum 5000 characters.'**
  String get reviewContentHelper;

  /// No description provided for @reviewCategoryRatingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Optional category ratings'**
  String get reviewCategoryRatingsTitle;

  /// No description provided for @reviewCategorySkipped.
  ///
  /// In en, this message translates to:
  /// **'Not rated'**
  String get reviewCategorySkipped;

  /// No description provided for @reviewSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit local demo review'**
  String get reviewSubmitAction;

  /// No description provided for @reviewSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Local demo review submitted as Pending.'**
  String get reviewSubmittedMessage;

  /// No description provided for @reviewUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Review integration is not enabled for real sessions in this UI phase.'**
  String get reviewUnavailableMessage;

  /// No description provided for @reviewIneligibleCompletedOnly.
  ///
  /// In en, this message translates to:
  /// **'Only completed local demo bookings owned by you can be reviewed.'**
  String get reviewIneligibleCompletedOnly;

  /// No description provided for @reviewDuplicateMessage.
  ///
  /// In en, this message translates to:
  /// **'A review already exists for this booking.'**
  String get reviewDuplicateMessage;

  /// No description provided for @reviewInvalidRatingMessage.
  ///
  /// In en, this message translates to:
  /// **'Ratings must be between 1 and 5.'**
  String get reviewInvalidRatingMessage;

  /// No description provided for @reviewTitleTooLongMessage.
  ///
  /// In en, this message translates to:
  /// **'Review title must be 200 characters or fewer.'**
  String get reviewTitleTooLongMessage;

  /// No description provided for @reviewContentTooLongMessage.
  ///
  /// In en, this message translates to:
  /// **'Review text must be 5000 characters or fewer.'**
  String get reviewContentTooLongMessage;

  /// No description provided for @myReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get myReviewsTitle;

  /// No description provided for @myReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your local demo review history. Statuses mirror the committed backend review statuses.'**
  String get myReviewsSubtitle;

  /// No description provided for @myReviewsRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Reviews is not connected yet'**
  String get myReviewsRealEmptyTitle;

  /// No description provided for @myReviewsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Real sessions do not show seeded review history until the customer review API is wired.'**
  String get myReviewsRealEmptyMessage;

  /// No description provided for @myReviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No local reviews yet'**
  String get myReviewsEmptyTitle;

  /// No description provided for @myReviewsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Completed demo bookings can create one local pending review each.'**
  String get myReviewsEmptyMessage;

  /// No description provided for @reviewSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'{title} ({count})'**
  String reviewSectionHeader(String title, int count);

  /// No description provided for @reviewStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get reviewStatusPending;

  /// No description provided for @reviewStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get reviewStatusApproved;

  /// No description provided for @reviewStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get reviewStatusRejected;

  /// No description provided for @reviewStatusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get reviewStatusHidden;

  /// No description provided for @reviewStatusReported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get reviewStatusReported;
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
