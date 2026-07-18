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
  /// **'I understand this UI does not collect payment or reserve inventory.'**
  String get bookingTermsAcknowledgement;

  /// No description provided for @bookingConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Confirm demo booking'**
  String get bookingConfirmAction;

  /// No description provided for @bookingConfirmSemantic.
  ///
  /// In en, this message translates to:
  /// **'Confirm this demo booking'**
  String get bookingConfirmSemantic;

  /// No description provided for @bookingDuplicatePrevented.
  ///
  /// In en, this message translates to:
  /// **'Duplicate booking creation was blocked.'**
  String get bookingDuplicatePrevented;

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
  /// **'This booking exists only in local demo state. It is not paid, synced, or holding inventory.'**
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
  /// **'Only local demo bookings appear here. Real booking endpoints are not connected in UI-6.'**
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
  /// **'Demo bookings will appear here after confirmation.'**
  String get myBookingsEmptyMessage;

  /// No description provided for @myBookingCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Booking card {code}'**
  String myBookingCardSemantic(String code);

  /// No description provided for @bookingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get bookingDetailsTitle;

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

  /// No description provided for @bookingCancelReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancellation reason'**
  String get bookingCancelReasonLabel;

  /// No description provided for @bookingCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Demo booking cancelled locally.'**
  String get bookingCancelledMessage;

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
