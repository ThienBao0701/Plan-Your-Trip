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
  /// **'Expenses'**
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
