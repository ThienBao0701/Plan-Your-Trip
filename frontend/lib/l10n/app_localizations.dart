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

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the email for your account. If it exists, we send a password reset link.'**
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
  /// **'For your security, the same answer is shown whether or not the address has an account.'**
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

  /// No description provided for @bookingContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to booking'**
  String get bookingContinueAction;

  /// No description provided for @bookingContinueSemantic.
  ///
  /// In en, this message translates to:
  /// **'Continue to booking with the selected room'**
  String get bookingContinueSemantic;

  /// No description provided for @bookingStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String bookingStepLabel(int current, int total);

  /// No description provided for @bookingSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking summary'**
  String get bookingSummaryTitle;

  /// No description provided for @bookingSummaryStayTitle.
  ///
  /// In en, this message translates to:
  /// **'Your stay'**
  String get bookingSummaryStayTitle;

  /// No description provided for @bookingQuoteLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Fetching the latest price…'**
  String get bookingQuoteLoadingMessage;

  /// No description provided for @bookingQuoteErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the price. Please try again.'**
  String get bookingQuoteErrorMessage;

  /// No description provided for @bookingQuoteInvalidDatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be after check-in.'**
  String get bookingQuoteInvalidDatesMessage;

  /// No description provided for @bookingTripLinkedLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked to your trip'**
  String get bookingTripLinkedLabel;

  /// No description provided for @bookingGuestInfoContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to guest details'**
  String get bookingGuestInfoContinueAction;

  /// No description provided for @bookingGuestInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get bookingGuestInfoTitle;

  /// No description provided for @bookingGuestSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary guest'**
  String get bookingGuestSectionTitle;

  /// No description provided for @bookingGuestNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get bookingGuestNameLabel;

  /// No description provided for @bookingGuestEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get bookingGuestEmailLabel;

  /// No description provided for @bookingGuestPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get bookingGuestPhoneLabel;

  /// No description provided for @bookingGuestCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country or region (optional)'**
  String get bookingGuestCountryLabel;

  /// No description provided for @bookingArrivalTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated arrival time (optional)'**
  String get bookingArrivalTimeLabel;

  /// No description provided for @bookingArrivalTimeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 15:00'**
  String get bookingArrivalTimeHint;

  /// No description provided for @bookingGuestLocalOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, country and arrival time are saved on this device for now — the booking API doesn\'t store them yet.'**
  String get bookingGuestLocalOnlyNote;

  /// No description provided for @bookingSpecialRequestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Special requests'**
  String get bookingSpecialRequestsTitle;

  /// No description provided for @specialRequestLateCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Late check-in'**
  String get specialRequestLateCheckIn;

  /// No description provided for @specialRequestHighFloor.
  ///
  /// In en, this message translates to:
  /// **'High floor'**
  String get specialRequestHighFloor;

  /// No description provided for @specialRequestQuietRoom.
  ///
  /// In en, this message translates to:
  /// **'Quiet room'**
  String get specialRequestQuietRoom;

  /// No description provided for @specialRequestTwinBed.
  ///
  /// In en, this message translates to:
  /// **'Twin beds'**
  String get specialRequestTwinBed;

  /// No description provided for @specialRequestLargeBed.
  ///
  /// In en, this message translates to:
  /// **'Large bed'**
  String get specialRequestLargeBed;

  /// No description provided for @bookingSpecialRequestNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Other requests'**
  String get bookingSpecialRequestNoteLabel;

  /// No description provided for @bookingSpecialRequestNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Requests are noted but not guaranteed.'**
  String get bookingSpecialRequestNoteHelper;

  /// No description provided for @bookingValidationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the guest\'s full name.'**
  String get bookingValidationNameRequired;

  /// No description provided for @bookingValidationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a contact email.'**
  String get bookingValidationEmailRequired;

  /// No description provided for @bookingValidationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get bookingValidationEmailInvalid;

  /// No description provided for @bookingValidationPhoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get bookingValidationPhoneInvalid;

  /// No description provided for @bookingValidationTooLong.
  ///
  /// In en, this message translates to:
  /// **'This value is too long.'**
  String get bookingValidationTooLong;

  /// No description provided for @bookingReviewContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to review'**
  String get bookingReviewContinueAction;

  /// No description provided for @bookingReviewGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest details'**
  String get bookingReviewGuestTitle;

  /// No description provided for @bookingNoSpecialRequests.
  ///
  /// In en, this message translates to:
  /// **'No special requests'**
  String get bookingNoSpecialRequests;

  /// No description provided for @bookingDraftTermsAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I understand this prepares a booking draft only — no reservation, payment, or confirmation is made in this step.'**
  String get bookingDraftTermsAcknowledgement;

  /// No description provided for @bookingDraftNoReservationNote.
  ///
  /// In en, this message translates to:
  /// **'Preparing a draft does not create a reservation or take payment.'**
  String get bookingDraftNoReservationNote;

  /// No description provided for @bookingPrepareAction.
  ///
  /// In en, this message translates to:
  /// **'Prepare booking'**
  String get bookingPrepareAction;

  /// No description provided for @bookingPrepareSemantic.
  ///
  /// In en, this message translates to:
  /// **'Prepare your booking draft'**
  String get bookingPrepareSemantic;

  /// No description provided for @bookingDraftInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Please complete the guest details first.'**
  String get bookingDraftInvalidMessage;

  /// No description provided for @bookingDraftQuoteMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'The price is still loading. Please wait a moment.'**
  String get bookingDraftQuoteMissingMessage;

  /// No description provided for @bookingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking ready'**
  String get bookingReadyTitle;

  /// No description provided for @bookingReadyHeadline.
  ///
  /// In en, this message translates to:
  /// **'Your booking is ready to confirm'**
  String get bookingReadyHeadline;

  /// No description provided for @bookingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve prepared your booking details. This is a draft — no reservation has been made, no payment taken, and no confirmation number issued. Connecting the reservation and payment steps is coming next.'**
  String get bookingReadyBody;

  /// No description provided for @bookingReadySemantic.
  ///
  /// In en, this message translates to:
  /// **'Booking prepared and ready to confirm'**
  String get bookingReadySemantic;

  /// No description provided for @bookingReadyDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Back to explore'**
  String get bookingReadyDoneAction;

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

  /// No description provided for @wishlistBookmarkAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved {place} to your wishlist.'**
  String wishlistBookmarkAddedMessage(String place);

  /// No description provided for @wishlistBookmarkRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Removed {place} from your wishlist.'**
  String wishlistBookmarkRemovedMessage(String place);

  /// No description provided for @wishlistBookmarkNotPublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'{place} isn\'t published yet, so it can\'t be saved.'**
  String wishlistBookmarkNotPublishedMessage(String place);

  /// No description provided for @wishlistBookmarkNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again.'**
  String get wishlistBookmarkNetworkMessage;

  /// No description provided for @wishlistBookmarkServerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on our end. Please try again.'**
  String get wishlistBookmarkServerErrorMessage;

  /// No description provided for @wishlistBookmarkUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Saving isn\'t available right now.'**
  String get wishlistBookmarkUnavailableMessage;

  /// No description provided for @wishlistBookmarkSavingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Updating saved state for {place}'**
  String wishlistBookmarkSavingSemantic(String place);

  /// No description provided for @wishlistRealLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading your wishlist'**
  String get wishlistRealLoadingTitle;

  /// No description provided for @wishlistRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Fetching your saved places…'**
  String get wishlistRealLoadingMessage;

  /// No description provided for @wishlistRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wishlist is empty'**
  String get wishlistRealEmptyTitle;

  /// No description provided for @wishlistRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any place to save it here.'**
  String get wishlistRealEmptyMessage;

  /// No description provided for @wishlistRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your wishlist. Please try again.'**
  String get wishlistRealErrorMessage;

  /// No description provided for @wishlistRealPartialDetailsNote.
  ///
  /// In en, this message translates to:
  /// **'Limited details are available for this saved place.'**
  String get wishlistRealPartialDetailsNote;

  /// No description provided for @placeHydrationLoadingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Loading details for {place}'**
  String placeHydrationLoadingSemantic(String place);

  /// No description provided for @placeHydrationUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This place is no longer available.'**
  String get placeHydrationUnavailableMessage;

  /// No description provided for @placeHydrationErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load place details. Please try again.'**
  String get placeHydrationErrorMessage;

  /// No description provided for @tripsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your trips…'**
  String get tripsRealLoadingMessage;

  /// No description provided for @tripsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your trips. Please try again.'**
  String get tripsRealErrorMessage;

  /// No description provided for @tripsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t created any trips yet. Start planning your next adventure.'**
  String get tripsRealEmptyMessage;

  /// No description provided for @tripsRealSessionExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get tripsRealSessionExpiredTitle;

  /// No description provided for @tripsRealSessionExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again to see your trips.'**
  String get tripsRealSessionExpiredMessage;

  /// No description provided for @tripsRealSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get tripsRealSignInAction;

  /// No description provided for @tripRealPermissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get tripRealPermissionDeniedMessage;

  /// No description provided for @tripStatusPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get tripStatusPlanning;

  /// No description provided for @tripStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tripStatusActive;

  /// No description provided for @tripStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStatusCompleted;

  /// No description provided for @tripStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripStatusCancelled;

  /// No description provided for @tripStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripStatusUnknown;

  /// No description provided for @tripDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String tripDayLabel(int day);

  /// No description provided for @tripDetailRealTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get tripDetailRealTitle;

  /// No description provided for @tripDetailRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading trip details…'**
  String get tripDetailRealLoadingMessage;

  /// No description provided for @tripDetailRealUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip unavailable'**
  String get tripDetailRealUnavailableTitle;

  /// No description provided for @tripDetailRealUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is no longer available.'**
  String get tripDetailRealUnavailableMessage;

  /// No description provided for @tripDetailRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this trip. Please try again.'**
  String get tripDetailRealErrorMessage;

  /// No description provided for @tripDetailRealEditDisabledNote.
  ///
  /// In en, this message translates to:
  /// **'Editing this itinerary isn\'t available yet.'**
  String get tripDetailRealEditDisabledNote;

  /// No description provided for @tripDetailRealNoDaysMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip doesn\'t have any days yet.'**
  String get tripDetailRealNoDaysMessage;

  /// No description provided for @tripDetailRealNoItemsMessage.
  ///
  /// In en, this message translates to:
  /// **'No activities planned for this day yet.'**
  String get tripDetailRealNoItemsMessage;

  /// No description provided for @addToTripRealLoadingTrips.
  ///
  /// In en, this message translates to:
  /// **'Loading your trips…'**
  String get addToTripRealLoadingTrips;

  /// No description provided for @addToTripRealNoTripsMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any trips yet. Create one to start adding places.'**
  String get addToTripRealNoTripsMessage;

  /// No description provided for @addToTripRealSelectTripLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a trip'**
  String get addToTripRealSelectTripLabel;

  /// No description provided for @addToTripRealSelectDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Choose a day'**
  String get addToTripRealSelectDayLabel;

  /// No description provided for @addToTripRealNewDayOption.
  ///
  /// In en, this message translates to:
  /// **'New day (Day {day})'**
  String addToTripRealNewDayOption(int day);

  /// No description provided for @addToTripRealPlanningNote.
  ///
  /// In en, this message translates to:
  /// **'This adds the place to your trip plan. It isn\'t a booking.'**
  String get addToTripRealPlanningNote;

  /// No description provided for @addToTripRealAddingMessage.
  ///
  /// In en, this message translates to:
  /// **'Adding to your trip…'**
  String get addToTripRealAddingMessage;

  /// No description provided for @addToTripRealAddedMessage.
  ///
  /// In en, this message translates to:
  /// **'{place} was added to your trip.'**
  String addToTripRealAddedMessage(String place);

  /// No description provided for @addToTripRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t add this place. Please try again.'**
  String get addToTripRealErrorMessage;

  /// No description provided for @addToTripRealUnpublishedMessage.
  ///
  /// In en, this message translates to:
  /// **'This place can\'t be added to a trip right now.'**
  String get addToTripRealUnpublishedMessage;

  /// No description provided for @addToTripRealTripUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'That trip or place is no longer available.'**
  String get addToTripRealTripUnavailableMessage;

  /// No description provided for @createTripRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t create your trip. Please try again.'**
  String get createTripRealErrorMessage;

  /// No description provided for @searchRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Searching places…'**
  String get searchRealLoadingMessage;

  /// No description provided for @searchRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load places. Please try again.'**
  String get searchRealErrorMessage;

  /// No description provided for @searchRealNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'No places match your search. Try different keywords or filters.'**
  String get searchRealNoResultsMessage;

  /// No description provided for @searchRealEndOfResults.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the end of the results.'**
  String get searchRealEndOfResults;

  /// No description provided for @searchRealSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get searchRealSortLabel;

  /// No description provided for @searchRealRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum rating'**
  String get searchRealRatingLabel;

  /// No description provided for @searchRealPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Maximum price'**
  String get searchRealPriceLabel;

  /// No description provided for @searchRealSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get searchRealSortNewest;

  /// No description provided for @searchRealSortTopRated.
  ///
  /// In en, this message translates to:
  /// **'Top rated'**
  String get searchRealSortTopRated;

  /// No description provided for @searchRealSortPriceLow.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get searchRealSortPriceLow;

  /// No description provided for @searchRealSortPriceHigh.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get searchRealSortPriceHigh;

  /// No description provided for @searchRealSortName.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get searchRealSortName;

  /// No description provided for @searchRealRatingAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchRealRatingAny;

  /// No description provided for @searchRealRating3plus.
  ///
  /// In en, this message translates to:
  /// **'3.0+'**
  String get searchRealRating3plus;

  /// No description provided for @searchRealRating4plus.
  ///
  /// In en, this message translates to:
  /// **'4.0+'**
  String get searchRealRating4plus;

  /// No description provided for @searchRealRating45plus.
  ///
  /// In en, this message translates to:
  /// **'4.5+'**
  String get searchRealRating45plus;

  /// No description provided for @searchRealPriceAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get searchRealPriceAny;

  /// No description provided for @availabilityRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Checking real availability…'**
  String get availabilityRealLoadingMessage;

  /// No description provided for @availabilityRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load availability. Please try again.'**
  String get availabilityRealErrorMessage;

  /// No description provided for @availabilityRealInvalidDatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a check-out date after check-in to see rooms.'**
  String get availabilityRealInvalidDatesMessage;

  /// No description provided for @availabilityRealRoomCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room available} other{{count} rooms available}}'**
  String availabilityRealRoomCount(int count);

  /// No description provided for @availabilityRealPerNight.
  ///
  /// In en, this message translates to:
  /// **'{price} / night'**
  String availabilityRealPerNight(String price);

  /// No description provided for @availabilityRealOriginalPrice.
  ///
  /// In en, this message translates to:
  /// **'{price}'**
  String availabilityRealOriginalPrice(String price);

  /// No description provided for @availabilityRealTotalForNights.
  ///
  /// In en, this message translates to:
  /// **'{price} total · {nights, plural, =1{1 night} other{{nights} nights}}'**
  String availabilityRealTotalForNights(String price, int nights);

  /// No description provided for @availabilityRealFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get availabilityRealFreeCancellation;

  /// No description provided for @availabilityRealInstantConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Instant confirmation'**
  String get availabilityRealInstantConfirmation;

  /// No description provided for @placeDetailRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading place details…'**
  String get placeDetailRealLoadingMessage;

  /// No description provided for @placeDetailRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this place. Please try again.'**
  String get placeDetailRealErrorMessage;

  /// No description provided for @placeDetailRealNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This place is no longer available.'**
  String get placeDetailRealNotFoundMessage;

  /// No description provided for @placeGallerySemantic.
  ///
  /// In en, this message translates to:
  /// **'Photo gallery for {name}, {count, plural, =1{1 image} other{{count} images}}'**
  String placeGallerySemantic(String name, int count);

  /// No description provided for @placeGalleryClose.
  ///
  /// In en, this message translates to:
  /// **'Close photo'**
  String get placeGalleryClose;

  /// No description provided for @placeOpenNow.
  ///
  /// In en, this message translates to:
  /// **'Open now'**
  String get placeOpenNow;

  /// No description provided for @placeClosedNow.
  ///
  /// In en, this message translates to:
  /// **'Closed now'**
  String get placeClosedNow;

  /// No description provided for @placeOpeningHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening hours'**
  String get placeOpeningHoursTitle;

  /// No description provided for @placeOpeningHoursClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get placeOpeningHoursClosed;

  /// No description provided for @placeCoordinatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get placeCoordinatesTitle;

  /// No description provided for @placeCoordinatesValue.
  ///
  /// In en, this message translates to:
  /// **'{lat}, {long}'**
  String placeCoordinatesValue(String lat, String long);

  /// No description provided for @placeAmenitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get placeAmenitiesTitle;

  /// No description provided for @placeMetadataTitle.
  ///
  /// In en, this message translates to:
  /// **'Good to know'**
  String get placeMetadataTitle;

  /// No description provided for @metadataVisitDurationTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggested visit'**
  String get metadataVisitDurationTitle;

  /// No description provided for @metadataTravelStylesTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel styles'**
  String get metadataTravelStylesTitle;

  /// No description provided for @metadataBestSeasonsTitle.
  ///
  /// In en, this message translates to:
  /// **'Best seasons'**
  String get metadataBestSeasonsTitle;

  /// No description provided for @metadataBestVisitTimesTitle.
  ///
  /// In en, this message translates to:
  /// **'Best time of day'**
  String get metadataBestVisitTimesTitle;

  /// No description provided for @metadataWeatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get metadataWeatherTitle;

  /// No description provided for @metadataBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get metadataBudgetTitle;

  /// No description provided for @metadataDifficultyTitle.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get metadataDifficultyTitle;

  /// No description provided for @metadataAccessibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get metadataAccessibilityTitle;

  /// No description provided for @metadataCrowdTitle.
  ///
  /// In en, this message translates to:
  /// **'Crowd level'**
  String get metadataCrowdTitle;

  /// No description provided for @metadataHighlightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get metadataHighlightsTitle;

  /// No description provided for @metadataNotesTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get metadataNotesTitle;

  /// No description provided for @travelStyleSolo.
  ///
  /// In en, this message translates to:
  /// **'Solo'**
  String get travelStyleSolo;

  /// No description provided for @travelStyleCouple.
  ///
  /// In en, this message translates to:
  /// **'Couple'**
  String get travelStyleCouple;

  /// No description provided for @travelStyleFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get travelStyleFamily;

  /// No description provided for @travelStyleFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get travelStyleFriends;

  /// No description provided for @travelStyleBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get travelStyleBusiness;

  /// No description provided for @travelStyleBackpacker.
  ///
  /// In en, this message translates to:
  /// **'Backpacker'**
  String get travelStyleBackpacker;

  /// No description provided for @travelStyleLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get travelStyleLuxury;

  /// No description provided for @bestVisitTimeEarlyMorning.
  ///
  /// In en, this message translates to:
  /// **'Early morning'**
  String get bestVisitTimeEarlyMorning;

  /// No description provided for @bestVisitTimeMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get bestVisitTimeMorning;

  /// No description provided for @bestVisitTimeAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get bestVisitTimeAfternoon;

  /// No description provided for @bestVisitTimeSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get bestVisitTimeSunset;

  /// No description provided for @bestVisitTimeEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get bestVisitTimeEvening;

  /// No description provided for @bestVisitTimeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get bestVisitTimeNight;

  /// No description provided for @bestSeasonSpring.
  ///
  /// In en, this message translates to:
  /// **'Spring'**
  String get bestSeasonSpring;

  /// No description provided for @bestSeasonSummer.
  ///
  /// In en, this message translates to:
  /// **'Summer'**
  String get bestSeasonSummer;

  /// No description provided for @bestSeasonAutumn.
  ///
  /// In en, this message translates to:
  /// **'Autumn'**
  String get bestSeasonAutumn;

  /// No description provided for @bestSeasonWinter.
  ///
  /// In en, this message translates to:
  /// **'Winter'**
  String get bestSeasonWinter;

  /// No description provided for @bestSeasonAllYear.
  ///
  /// In en, this message translates to:
  /// **'All year'**
  String get bestSeasonAllYear;

  /// No description provided for @weatherSunny.
  ///
  /// In en, this message translates to:
  /// **'Sunny'**
  String get weatherSunny;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherRainy.
  ///
  /// In en, this message translates to:
  /// **'Rainy'**
  String get weatherRainy;

  /// No description provided for @weatherCool.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get weatherCool;

  /// No description provided for @weatherAny.
  ///
  /// In en, this message translates to:
  /// **'Any weather'**
  String get weatherAny;

  /// No description provided for @budgetFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get budgetFree;

  /// No description provided for @budgetLow.
  ///
  /// In en, this message translates to:
  /// **'Low budget'**
  String get budgetLow;

  /// No description provided for @budgetMedium.
  ///
  /// In en, this message translates to:
  /// **'Mid-range'**
  String get budgetMedium;

  /// No description provided for @budgetHigh.
  ///
  /// In en, this message translates to:
  /// **'High-end'**
  String get budgetHigh;

  /// No description provided for @budgetLuxury.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get budgetLuxury;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get difficultyModerate;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @accessibilityLow.
  ///
  /// In en, this message translates to:
  /// **'Limited access'**
  String get accessibilityLow;

  /// No description provided for @accessibilityMedium.
  ///
  /// In en, this message translates to:
  /// **'Moderate access'**
  String get accessibilityMedium;

  /// No description provided for @accessibilityHigh.
  ///
  /// In en, this message translates to:
  /// **'Fully accessible'**
  String get accessibilityHigh;

  /// No description provided for @crowdLow.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get crowdLow;

  /// No description provided for @crowdMedium.
  ///
  /// In en, this message translates to:
  /// **'Moderate crowd'**
  String get crowdMedium;

  /// No description provided for @crowdHigh.
  ///
  /// In en, this message translates to:
  /// **'Busy'**
  String get crowdHigh;

  /// No description provided for @flagRomantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get flagRomantic;

  /// No description provided for @flagFamilyFriendly.
  ///
  /// In en, this message translates to:
  /// **'Family-friendly'**
  String get flagFamilyFriendly;

  /// No description provided for @flagKidFriendly.
  ///
  /// In en, this message translates to:
  /// **'Kid-friendly'**
  String get flagKidFriendly;

  /// No description provided for @flagPetFriendly.
  ///
  /// In en, this message translates to:
  /// **'Pet-friendly'**
  String get flagPetFriendly;

  /// No description provided for @flagWheelchairFriendly.
  ///
  /// In en, this message translates to:
  /// **'Wheelchair-friendly'**
  String get flagWheelchairFriendly;

  /// No description provided for @flagPhotographySpot.
  ///
  /// In en, this message translates to:
  /// **'Photography spot'**
  String get flagPhotographySpot;

  /// No description provided for @flagSunsetSpot.
  ///
  /// In en, this message translates to:
  /// **'Sunset spot'**
  String get flagSunsetSpot;

  /// No description provided for @flagSunriseSpot.
  ///
  /// In en, this message translates to:
  /// **'Sunrise spot'**
  String get flagSunriseSpot;

  /// No description provided for @flagIndoor.
  ///
  /// In en, this message translates to:
  /// **'Indoor'**
  String get flagIndoor;

  /// No description provided for @flagOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get flagOutdoor;

  /// No description provided for @flagRainyDaySuitable.
  ///
  /// In en, this message translates to:
  /// **'Rainy-day friendly'**
  String get flagRainyDaySuitable;

  /// No description provided for @facilityGroupGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get facilityGroupGeneral;

  /// No description provided for @facilityGroupWellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get facilityGroupWellness;

  /// No description provided for @facilityGroupBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get facilityGroupBusiness;

  /// No description provided for @facilityGroupFood.
  ///
  /// In en, this message translates to:
  /// **'Food & drink'**
  String get facilityGroupFood;

  /// No description provided for @facilityGroupOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get facilityGroupOutdoor;

  /// No description provided for @facilityGroupFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get facilityGroupFamily;

  /// No description provided for @facilityGroupAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get facilityGroupAccessibility;

  /// No description provided for @hotelPoliciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get hotelPoliciesTitle;

  /// No description provided for @hotelPolicyCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get hotelPolicyCancellation;

  /// No description provided for @hotelPolicyPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get hotelPolicyPayment;

  /// No description provided for @hotelPolicyChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get hotelPolicyChildren;

  /// No description provided for @hotelPolicyPet.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get hotelPolicyPet;

  /// No description provided for @hotelPolicySmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get hotelPolicySmoking;

  /// No description provided for @hotelParkingFree.
  ///
  /// In en, this message translates to:
  /// **'Free parking'**
  String get hotelParkingFree;

  /// No description provided for @hotelParkingPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid parking'**
  String get hotelParkingPaid;

  /// No description provided for @hotelParkingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No parking'**
  String get hotelParkingUnavailable;

  /// No description provided for @hotelWifiFree.
  ///
  /// In en, this message translates to:
  /// **'Free Wi-Fi'**
  String get hotelWifiFree;

  /// No description provided for @hotelWifiPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid Wi-Fi'**
  String get hotelWifiPaid;

  /// No description provided for @hotelWifiUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No Wi-Fi'**
  String get hotelWifiUnavailable;

  /// No description provided for @hotelServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{service} (unavailable)'**
  String hotelServiceUnavailable(String service);

  /// No description provided for @roomSelectAction.
  ///
  /// In en, this message translates to:
  /// **'Select this room'**
  String get roomSelectAction;

  /// No description provided for @roomSelectSemantic.
  ///
  /// In en, this message translates to:
  /// **'Select {name}'**
  String roomSelectSemantic(String name);

  /// No description provided for @roomSelectedBadge.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get roomSelectedBadge;

  /// No description provided for @roomDetailImageSemantic.
  ///
  /// In en, this message translates to:
  /// **'Photos of {name}'**
  String roomDetailImageSemantic(String name);

  /// No description provided for @roomCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Room code {code}'**
  String roomCodeLabel(String code);

  /// No description provided for @roomBedConfig.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 {bed}} other{{count} {bed}}}'**
  String roomBedConfig(int count, String bed);

  /// No description provided for @roomOccupancyTitle.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get roomOccupancyTitle;

  /// No description provided for @roomOccupancyAdults.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 adult} other{{count} adults}}'**
  String roomOccupancyAdults(int count);

  /// No description provided for @roomOccupancyChildren.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 child} other{{count} children}}'**
  String roomOccupancyChildren(int count);

  /// No description provided for @roomPriceTitle.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get roomPriceTitle;

  /// No description provided for @hotelRoomCardSelectedSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, selected'**
  String hotelRoomCardSelectedSemantic(String name);

  /// No description provided for @roomRatePlansTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate plans'**
  String get roomRatePlansTitle;

  /// No description provided for @roomRatePlansLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading rate plans…'**
  String get roomRatePlansLoadingMessage;

  /// No description provided for @roomRatePlansErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load rate plans. Please try again.'**
  String get roomRatePlansErrorMessage;

  /// No description provided for @roomRatePlansInvalidDatesMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a check-out date after check-in to see rate plans.'**
  String get roomRatePlansInvalidDatesMessage;

  /// No description provided for @roomRatePlansEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rate plans'**
  String get roomRatePlansEmptyTitle;

  /// No description provided for @roomRatePlansEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This room has no sellable rate plans for the selected stay.'**
  String get roomRatePlansEmptyMessage;

  /// No description provided for @roomRatePlanSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rate plan {name}'**
  String roomRatePlanSemantic(String name);

  /// No description provided for @roomRatePlanSelectedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rate plan {name}, selected'**
  String roomRatePlanSelectedSemantic(String name);

  /// No description provided for @roomRatePlanIneligible.
  ///
  /// In en, this message translates to:
  /// **'Not available for the selected stay.'**
  String get roomRatePlanIneligible;

  /// No description provided for @ratePlanRefundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get ratePlanRefundable;

  /// No description provided for @ratePlanNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get ratePlanNonRefundable;

  /// No description provided for @ratePlanFinalNightly.
  ///
  /// In en, this message translates to:
  /// **'{price} / night'**
  String ratePlanFinalNightly(String price);

  /// No description provided for @ratePlanBaseNightly.
  ///
  /// In en, this message translates to:
  /// **'Base {price} / night'**
  String ratePlanBaseNightly(String price);

  /// No description provided for @ratePlanStaySubtotal.
  ///
  /// In en, this message translates to:
  /// **'{price} for {nights, plural, =1{1 night} other{{nights} nights}}'**
  String ratePlanStaySubtotal(String price, int nights);

  /// No description provided for @bookingCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create booking'**
  String get bookingCreateAction;

  /// No description provided for @bookingCreateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Create your booking'**
  String get bookingCreateSemantic;

  /// No description provided for @bookingCreatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Creating your booking…'**
  String get bookingCreatingLabel;

  /// No description provided for @bookingResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Your booking'**
  String get bookingResultTitle;

  /// No description provided for @bookingResultCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get bookingResultCodeLabel;

  /// No description provided for @bookingResultStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get bookingResultStatusLabel;

  /// No description provided for @bookingResultDoneAction.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get bookingResultDoneAction;

  /// No description provided for @bookingResultBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Room price'**
  String get bookingResultBaseLabel;

  /// No description provided for @bookingResultPaymentNextNote.
  ///
  /// In en, this message translates to:
  /// **'Your booking is created and held as pending. Complete payment to confirm it.'**
  String get bookingResultPaymentNextNote;

  /// No description provided for @bookingPriceChangedNote.
  ///
  /// In en, this message translates to:
  /// **'The final price confirmed by the server differs from the earlier quote. The amount shown above is the one that applies to your booking.'**
  String get bookingPriceChangedNote;

  /// No description provided for @bookingStatusPendingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusPendingLabel;

  /// No description provided for @bookingStatusConfirmedLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmedLabel;

  /// No description provided for @bookingStatusUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get bookingStatusUnknownLabel;

  /// No description provided for @bookingStatusPendingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Booking pending'**
  String get bookingStatusPendingHeadline;

  /// No description provided for @bookingStatusPendingBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve created your booking and are holding the room. It stays pending until payment and property confirmation — it is not yet a confirmed stay.'**
  String get bookingStatusPendingBody;

  /// No description provided for @bookingStatusConfirmedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get bookingStatusConfirmedHeadline;

  /// No description provided for @bookingStatusConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Your booking has been confirmed by the property.'**
  String get bookingStatusConfirmedBody;

  /// No description provided for @bookingStatusGenericHeadline.
  ///
  /// In en, this message translates to:
  /// **'Booking status: {status}'**
  String bookingStatusGenericHeadline(String status);

  /// No description provided for @bookingSubmitValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Some booking details couldn\'t be accepted. Please review your dates and guests and try again.'**
  String get bookingSubmitValidationMessage;

  /// No description provided for @bookingSubmitForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to create this booking.'**
  String get bookingSubmitForbiddenMessage;

  /// No description provided for @bookingSubmitRoomUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This room or rate plan is no longer available. Please go back and choose again.'**
  String get bookingSubmitRoomUnavailableMessage;

  /// No description provided for @bookingSubmitConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'This room was just taken for your dates. Please go back and try another room or dates.'**
  String get bookingSubmitConflictMessage;

  /// No description provided for @bookingSubmitUnprocessableMessage.
  ///
  /// In en, this message translates to:
  /// **'This room can\'t be booked for the selected dates. Please go back and adjust your stay.'**
  String get bookingSubmitUnprocessableMessage;

  /// No description provided for @bookingSubmitServerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong creating your booking. No booking was created — please try again.'**
  String get bookingSubmitServerErrorMessage;

  /// No description provided for @bookingSubmitNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get bookingSubmitNetworkMessage;

  /// No description provided for @bookingSubmitUncertainTitle.
  ///
  /// In en, this message translates to:
  /// **'Booking not confirmed'**
  String get bookingSubmitUncertainTitle;

  /// No description provided for @bookingSubmitUncertainBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t confirm whether your booking was created. Please don\'t submit again — check your bookings later to see if it went through.'**
  String get bookingSubmitUncertainBody;

  /// No description provided for @bookingSubmitUncertainAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this may create a duplicate booking'**
  String get bookingSubmitUncertainAcknowledge;

  /// No description provided for @bookingsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your bookings…'**
  String get bookingsRealLoadingMessage;

  /// No description provided for @bookingsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your bookings. Please try again.'**
  String get bookingsRealErrorMessage;

  /// No description provided for @bookingDetailLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading booking details…'**
  String get bookingDetailLoadingMessage;

  /// No description provided for @bookingDetailErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this booking. Please try again.'**
  String get bookingDetailErrorMessage;

  /// No description provided for @bookingDetailSpecialRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'Special request'**
  String get bookingDetailSpecialRequestLabel;

  /// No description provided for @bookingHistoryUncertainTitle.
  ///
  /// In en, this message translates to:
  /// **'A booking may not have gone through'**
  String get bookingHistoryUncertainTitle;

  /// No description provided for @bookingHistoryUncertainBody.
  ///
  /// In en, this message translates to:
  /// **'Your last booking couldn\'t be confirmed. Check the list below to see whether it was created before trying again.'**
  String get bookingHistoryUncertainBody;

  /// No description provided for @bookingHistoryUncertainDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get bookingHistoryUncertainDismiss;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @paymentPayNowAction.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get paymentPayNowAction;

  /// No description provided for @paymentLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading payment…'**
  String get paymentLoadingMessage;

  /// No description provided for @paymentErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load the payment. Please try again.'**
  String get paymentErrorMessage;

  /// No description provided for @paymentSandboxNotice.
  ///
  /// In en, this message translates to:
  /// **'No live payment gateway is connected. The payment is created for real on the backend and settled in a sandbox — no card is charged and no external checkout opens.'**
  String get paymentSandboxNotice;

  /// No description provided for @paymentAmountToPayLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount to pay'**
  String get paymentAmountToPayLabel;

  /// No description provided for @paymentNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No payment yet'**
  String get paymentNoneTitle;

  /// No description provided for @paymentNoneMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a payment for this booking to continue.'**
  String get paymentNoneMessage;

  /// No description provided for @paymentCreateAction.
  ///
  /// In en, this message translates to:
  /// **'Create payment'**
  String get paymentCreateAction;

  /// No description provided for @paymentCreatingLabel.
  ///
  /// In en, this message translates to:
  /// **'Creating payment…'**
  String get paymentCreatingLabel;

  /// No description provided for @paymentCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment code'**
  String get paymentCodeLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentMethodLabel;

  /// No description provided for @paymentProcessingLabel.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get paymentProcessingLabel;

  /// No description provided for @paymentSuccessHeadline.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessHeadline;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your payment went through and the booking is now confirmed.'**
  String get paymentSuccessBody;

  /// No description provided for @paymentPendingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPendingHeadline;

  /// No description provided for @paymentPendingBody.
  ///
  /// In en, this message translates to:
  /// **'The payment has been created and is awaiting completion.'**
  String get paymentPendingBody;

  /// No description provided for @paymentFailedHeadline.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailedHeadline;

  /// No description provided for @paymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'This payment did not go through. You can start a new payment.'**
  String get paymentFailedBody;

  /// No description provided for @paymentCompleteSandboxAction.
  ///
  /// In en, this message translates to:
  /// **'Complete payment (sandbox)'**
  String get paymentCompleteSandboxAction;

  /// No description provided for @paymentFailSandboxAction.
  ///
  /// In en, this message translates to:
  /// **'Simulate failed payment (sandbox)'**
  String get paymentFailSandboxAction;

  /// No description provided for @paymentRefreshAction.
  ///
  /// In en, this message translates to:
  /// **'Refresh status'**
  String get paymentRefreshAction;

  /// No description provided for @paymentRetryNewAction.
  ///
  /// In en, this message translates to:
  /// **'Start a new payment'**
  String get paymentRetryNewAction;

  /// No description provided for @paymentConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete this payment?'**
  String get paymentConfirmTitle;

  /// No description provided for @paymentConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This settles the payment on the backend (sandbox) and confirms your booking. No card is charged.'**
  String get paymentConfirmMessage;

  /// No description provided for @paymentConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Complete payment'**
  String get paymentConfirmAction;

  /// No description provided for @paymentStatusUnknownLabel.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get paymentStatusUnknownLabel;

  /// No description provided for @paymentActionValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'The payment request was invalid. Please try again.'**
  String get paymentActionValidationMessage;

  /// No description provided for @paymentActionForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to pay for this booking.'**
  String get paymentActionForbiddenMessage;

  /// No description provided for @paymentActionNotPayableMessage.
  ///
  /// In en, this message translates to:
  /// **'This booking can\'t be paid right now. It may be cancelled, already paid, or no longer pending.'**
  String get paymentActionNotPayableMessage;

  /// No description provided for @paymentActionConflictMessage.
  ///
  /// In en, this message translates to:
  /// **'The payment changed on the server. Refresh and try again.'**
  String get paymentActionConflictMessage;

  /// No description provided for @paymentActionServerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong with the payment. Please try again.'**
  String get paymentActionServerErrorMessage;

  /// No description provided for @paymentActionNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get paymentActionNetworkMessage;

  /// No description provided for @reviewStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get reviewStatusUnknown;

  /// No description provided for @reviewsListLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading reviews…'**
  String get reviewsListLoadingMessage;

  /// No description provided for @reviewsListErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load reviews. Please try again.'**
  String get reviewsListErrorMessage;

  /// No description provided for @placeReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get placeReviewsTitle;

  /// No description provided for @placeReviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get placeReviewsEmptyTitle;

  /// No description provided for @placeReviewsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This place has no published reviews yet.'**
  String get placeReviewsEmptyMessage;

  /// No description provided for @reviewsMineTitle.
  ///
  /// In en, this message translates to:
  /// **'My reviews'**
  String get reviewsMineTitle;

  /// No description provided for @reviewsMineEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsMineEmptyTitle;

  /// No description provided for @reviewsMineEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reviews you write for completed stays will appear here.'**
  String get reviewsMineEmptyMessage;

  /// No description provided for @reviewStarsSemantic.
  ///
  /// In en, this message translates to:
  /// **'{rating} out of 5'**
  String reviewStarsSemantic(int rating);

  /// No description provided for @writeReviewRateStarSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rate {rating} out of 5'**
  String writeReviewRateStarSemantic(int rating);

  /// No description provided for @reviewPartnerReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Response from the property'**
  String get reviewPartnerReplyTitle;

  /// No description provided for @reviewUnknownPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get reviewUnknownPlace;

  /// No description provided for @reviewAnonymousReviewer.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get reviewAnonymousReviewer;

  /// No description provided for @reviewRatingCleanliness.
  ///
  /// In en, this message translates to:
  /// **'Cleanliness'**
  String get reviewRatingCleanliness;

  /// No description provided for @reviewRatingService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get reviewRatingService;

  /// No description provided for @reviewRatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get reviewRatingLocation;

  /// No description provided for @reviewRatingValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get reviewRatingValue;

  /// No description provided for @reviewRatingFacilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get reviewRatingFacilities;

  /// No description provided for @writeReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Write a review'**
  String get writeReviewTitle;

  /// No description provided for @writeReviewOverallLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall rating'**
  String get writeReviewOverallLabel;

  /// No description provided for @writeReviewSubRatingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate the details (optional)'**
  String get writeReviewSubRatingsTitle;

  /// No description provided for @writeReviewTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get writeReviewTitleLabel;

  /// No description provided for @writeReviewContentLabel.
  ///
  /// In en, this message translates to:
  /// **'Your review (optional)'**
  String get writeReviewContentLabel;

  /// No description provided for @writeReviewSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get writeReviewSubmitAction;

  /// No description provided for @writeReviewSubmittingLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitting review…'**
  String get writeReviewSubmittingLabel;

  /// No description provided for @writeReviewModerationNote.
  ///
  /// In en, this message translates to:
  /// **'Your review is submitted for moderation and becomes public once approved.'**
  String get writeReviewModerationNote;

  /// No description provided for @writeReviewPendingHeadline.
  ///
  /// In en, this message translates to:
  /// **'Review submitted'**
  String get writeReviewPendingHeadline;

  /// No description provided for @writeReviewPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Your review is pending moderation and will be published once approved.'**
  String get writeReviewPendingBody;

  /// No description provided for @writeReviewOverallRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a star to set your overall rating.'**
  String get writeReviewOverallRequiredHint;

  /// No description provided for @bookingDetailSeeReviewsAction.
  ///
  /// In en, this message translates to:
  /// **'See hotel reviews'**
  String get bookingDetailSeeReviewsAction;

  /// No description provided for @reviewSubmitValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check your review and try again.'**
  String get reviewSubmitValidationMessage;

  /// No description provided for @reviewSubmitForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You can only review your own booking.'**
  String get reviewSubmitForbiddenMessage;

  /// No description provided for @reviewSubmitAlreadyMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reviewed this booking.'**
  String get reviewSubmitAlreadyMessage;

  /// No description provided for @reviewSubmitNotCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can review a stay only after it\'s completed.'**
  String get reviewSubmitNotCompletedMessage;

  /// No description provided for @reviewSubmitServerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong submitting your review. Please try again.'**
  String get reviewSubmitServerErrorMessage;

  /// No description provided for @reviewSubmitNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get reviewSubmitNetworkMessage;

  /// No description provided for @notificationsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications…'**
  String get notificationsRealLoadingMessage;

  /// No description provided for @notificationsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your notifications. Please try again.'**
  String get notificationsRealErrorMessage;

  /// No description provided for @notificationsRealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Updates from your bookings, payments and reviews.'**
  String get notificationsRealSubtitle;

  /// No description provided for @notificationActionForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to change this notification.'**
  String get notificationActionForbiddenMessage;

  /// No description provided for @notificationActionServerErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong updating your notifications. Please try again.'**
  String get notificationActionServerErrorMessage;

  /// No description provided for @notificationActionNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get notificationActionNetworkMessage;

  /// No description provided for @recentlyViewedTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewedTitle;

  /// No description provided for @recentlyViewedLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading recently viewed…'**
  String get recentlyViewedLoadingMessage;

  /// No description provided for @recentlyViewedErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your recently viewed places. Please try again.'**
  String get recentlyViewedErrorMessage;

  /// No description provided for @recentlyViewedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get recentlyViewedEmptyTitle;

  /// No description provided for @recentlyViewedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Places you view will appear here.'**
  String get recentlyViewedEmptyMessage;

  /// No description provided for @recentlyViewedUnknownPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get recentlyViewedUnknownPlace;

  /// No description provided for @recentlyViewedCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open {name}'**
  String recentlyViewedCardSemantic(String name);

  /// No description provided for @recentlyViewedRatingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} from {count} reviews'**
  String recentlyViewedRatingSemantic(String rating, int count);

  /// No description provided for @recentlyViewedRemoveSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from recently viewed'**
  String recentlyViewedRemoveSemantic(String name);

  /// No description provided for @recentlyViewedClearSemantic.
  ///
  /// In en, this message translates to:
  /// **'Clear recently viewed'**
  String get recentlyViewedClearSemantic;

  /// No description provided for @recentlyViewedClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear recently viewed?'**
  String get recentlyViewedClearConfirmTitle;

  /// No description provided for @recentlyViewedClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'This removes every place from your recently viewed list.'**
  String get recentlyViewedClearConfirmMessage;

  /// No description provided for @recentlyViewedClearConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get recentlyViewedClearConfirmAction;

  /// No description provided for @recentlyViewedRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from recently viewed?'**
  String get recentlyViewedRemoveConfirmTitle;

  /// No description provided for @recentlyViewedRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from your recently viewed list?'**
  String recentlyViewedRemoveConfirmMessage(String name);

  /// No description provided for @recentlyViewedRemoveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get recentlyViewedRemoveConfirmAction;

  /// No description provided for @recentlyViewedClearedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed cleared.'**
  String get recentlyViewedClearedMessage;

  /// No description provided for @recentlyViewedRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Removed from recently viewed.'**
  String get recentlyViewedRemovedMessage;

  /// No description provided for @recentlyViewedOpenErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t open this place. Please try again.'**
  String get recentlyViewedOpenErrorMessage;

  /// No description provided for @recentlyViewedGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This place is no longer available.'**
  String get recentlyViewedGoneMessage;

  /// No description provided for @recentlyViewedForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get recentlyViewedForbiddenMessage;

  /// No description provided for @recentlyViewedActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get recentlyViewedActionErrorMessage;

  /// No description provided for @recentlyViewedNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get recentlyViewedNetworkMessage;

  /// No description provided for @profileEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & preferences'**
  String get profileEditTitle;

  /// No description provided for @profileEditLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your profile…'**
  String get profileEditLoadingMessage;

  /// No description provided for @profileEditErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your profile. Please try again.'**
  String get profileEditErrorMessage;

  /// No description provided for @profileEditMissingMessage.
  ///
  /// In en, this message translates to:
  /// **'Your profile isn\'t available.'**
  String get profileEditMissingMessage;

  /// No description provided for @profileEditSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileEditSaveAction;

  /// No description provided for @profileEditSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileEditSavedMessage;

  /// No description provided for @profileEditSaveErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t save your changes. Please try again.'**
  String get profileEditSaveErrorMessage;

  /// No description provided for @profileEditForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do that.'**
  String get profileEditForbiddenMessage;

  /// No description provided for @profileEditNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get profileEditNetworkMessage;

  /// No description provided for @profileEditIdentitySection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileEditIdentitySection;

  /// No description provided for @profileEditPreferencesSection.
  ///
  /// In en, this message translates to:
  /// **'Travel preferences'**
  String get profileEditPreferencesSection;

  /// No description provided for @profileEditContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact & documents'**
  String get profileEditContactSection;

  /// No description provided for @profileFieldAvatar.
  ///
  /// In en, this message translates to:
  /// **'Avatar image URL'**
  String get profileFieldAvatar;

  /// No description provided for @profileFieldLanguage.
  ///
  /// In en, this message translates to:
  /// **'Preferred language'**
  String get profileFieldLanguage;

  /// No description provided for @profileFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Preferred currency'**
  String get profileFieldCurrency;

  /// No description provided for @profileFieldPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Preferred payment method'**
  String get profileFieldPaymentMethod;

  /// No description provided for @profileFieldNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get profileFieldNationality;

  /// No description provided for @profileFieldEmergencyName.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact name'**
  String get profileFieldEmergencyName;

  /// No description provided for @profileFieldEmergencyPhone.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact phone'**
  String get profileFieldEmergencyPhone;

  /// No description provided for @profileFieldAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility needs'**
  String get profileFieldAccessibility;

  /// No description provided for @profileFieldDietaryPreference.
  ///
  /// In en, this message translates to:
  /// **'Dietary preference'**
  String get profileFieldDietaryPreference;

  /// No description provided for @profileFieldTravelStyle.
  ///
  /// In en, this message translates to:
  /// **'Travel style'**
  String get profileFieldTravelStyle;

  /// No description provided for @profileEditPassportLabel.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get profileEditPassportLabel;

  /// No description provided for @profileEditPassportWarning.
  ///
  /// In en, this message translates to:
  /// **'Currently saved: {masked}. Re-enter it to keep it — leaving this blank removes the saved passport when you save.'**
  String profileEditPassportWarning(String masked);

  /// No description provided for @profileEditPassportHint.
  ///
  /// In en, this message translates to:
  /// **'Optional. Stored masked once saved.'**
  String get profileEditPassportHint;

  /// No description provided for @profileEditMarketingLabel.
  ///
  /// In en, this message translates to:
  /// **'Receive marketing updates'**
  String get profileEditMarketingLabel;

  /// No description provided for @profileEditOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get profileEditOptionalHint;

  /// No description provided for @profileCompletionSemantic.
  ///
  /// In en, this message translates to:
  /// **'Profile {percent}% complete'**
  String profileCompletionSemantic(int percent);

  /// No description provided for @profileRoleSemantic.
  ///
  /// In en, this message translates to:
  /// **'Account role: {role}'**
  String profileRoleSemantic(String role);

  /// No description provided for @profileEditEmptyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Add your travel preferences to personalise your trips.'**
  String get profileEditEmptyPreferences;

  /// No description provided for @giftCardsRealClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Claim a gift card'**
  String get giftCardsRealClaimTitle;

  /// No description provided for @giftCardsRealClaimHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter a gift-card code you received to add it to your account.'**
  String get giftCardsRealClaimHelper;

  /// No description provided for @giftCardsRealClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gift card claimed.'**
  String get giftCardsRealClaimSuccess;

  /// No description provided for @giftCardsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your gift cards…'**
  String get giftCardsRealLoadingMessage;

  /// No description provided for @giftCardsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your gift cards. Please try again.'**
  String get giftCardsRealErrorMessage;

  /// No description provided for @giftCardsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Gift cards you purchase or receive will appear here.'**
  String get giftCardsRealEmptyMessage;

  /// No description provided for @giftCardsRealLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get giftCardsRealLoadMore;

  /// No description provided for @giftCardsRealActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate gift card'**
  String get giftCardsRealActivateAction;

  /// No description provided for @giftCardsRealActivateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gift card activated.'**
  String get giftCardsRealActivateSuccess;

  /// No description provided for @giftCardsRealActionError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get giftCardsRealActionError;

  /// No description provided for @giftCardsRealNotFound.
  ///
  /// In en, this message translates to:
  /// **'That gift card could not be found.'**
  String get giftCardsRealNotFound;

  /// No description provided for @giftCardsRealConflict.
  ///
  /// In en, this message translates to:
  /// **'This gift card can\'t be used in its current state.'**
  String get giftCardsRealConflict;

  /// No description provided for @giftCardsRealNetwork.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t reach the server. Please check your connection and try again.'**
  String get giftCardsRealNetwork;

  /// No description provided for @giftCardsRealValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the gift-card code and try again.'**
  String get giftCardsRealValidation;

  /// No description provided for @giftCardStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get giftCardStatusUnknown;

  /// No description provided for @giftCardsRealBalanceSemantic.
  ///
  /// In en, this message translates to:
  /// **'Current balance {balance}'**
  String giftCardsRealBalanceSemantic(String balance);

  /// No description provided for @loyaltyRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your loyalty points…'**
  String get loyaltyRealLoadingMessage;

  /// No description provided for @loyaltyRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your loyalty points. Please try again.'**
  String get loyaltyRealErrorMessage;

  /// No description provided for @loyaltyRealLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loyaltyRealLoadMore;

  /// No description provided for @loyaltyRealEarnNote.
  ///
  /// In en, this message translates to:
  /// **'Points are earned automatically from completed bookings and reviews. They can\'t be redeemed directly here.'**
  String get loyaltyRealEarnNote;

  /// No description provided for @travelCreditRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your travel credit…'**
  String get travelCreditRealLoadingMessage;

  /// No description provided for @travelCreditRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your travel credit. Please try again.'**
  String get travelCreditRealErrorMessage;

  /// No description provided for @travelCreditRealLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get travelCreditRealLoadMore;

  /// No description provided for @membershipRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your membership…'**
  String get membershipRealLoadingMessage;

  /// No description provided for @membershipRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your membership. Please try again.'**
  String get membershipRealErrorMessage;

  /// No description provided for @membershipRealActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'Your membership is active.'**
  String get membershipRealActiveMessage;

  /// No description provided for @membershipRealPreviewMessage.
  ///
  /// In en, this message translates to:
  /// **'This is a live preview of the tier you qualify for. Enroll to activate it.'**
  String get membershipRealPreviewMessage;

  /// No description provided for @membershipRealEnrollAction.
  ///
  /// In en, this message translates to:
  /// **'Enroll now'**
  String get membershipRealEnrollAction;

  /// No description provided for @membershipRealEnrolledAction.
  ///
  /// In en, this message translates to:
  /// **'Enrolled'**
  String get membershipRealEnrolledAction;

  /// No description provided for @membershipRealEnrollSemantic.
  ///
  /// In en, this message translates to:
  /// **'Enroll in membership'**
  String get membershipRealEnrollSemantic;

  /// No description provided for @membershipRealEnrollSuccess.
  ///
  /// In en, this message translates to:
  /// **'You\'re enrolled in membership.'**
  String get membershipRealEnrollSuccess;

  /// No description provided for @membershipRealEnrollError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t enroll you. Please try again.'**
  String get membershipRealEnrollError;

  /// No description provided for @membershipRealEnrollNeedsLoyalty.
  ///
  /// In en, this message translates to:
  /// **'An active loyalty account is required to enroll in membership.'**
  String get membershipRealEnrollNeedsLoyalty;

  /// No description provided for @membershipRealNoBenefits.
  ///
  /// In en, this message translates to:
  /// **'No benefits are listed for this tier yet.'**
  String get membershipRealNoBenefits;

  /// No description provided for @membershipRealPointsToNext.
  ///
  /// In en, this message translates to:
  /// **'{points} more points to the next tier'**
  String membershipRealPointsToNext(int points);

  /// No description provided for @membershipRealBookingsToNext.
  ///
  /// In en, this message translates to:
  /// **'{bookings} more completed bookings to the next tier'**
  String membershipRealBookingsToNext(int bookings);

  /// No description provided for @referralRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your referral…'**
  String get referralRealLoadingMessage;

  /// No description provided for @referralRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your referral. Please try again.'**
  String get referralRealErrorMessage;

  /// No description provided for @referralRealUseHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter a friend\'s referral code. Rewards follow a qualifying booking.'**
  String get referralRealUseHelper;

  /// No description provided for @referralRealUseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied. Rewards follow a qualifying booking.'**
  String get referralRealUseSuccess;

  /// No description provided for @referralRealUseError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t apply that code. Please try again.'**
  String get referralRealUseError;

  /// No description provided for @referralRealAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'You have already used a referral code and cannot use another.'**
  String get referralRealAlreadyUsed;

  /// No description provided for @referralRealCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'That referral code was not found.'**
  String get referralRealCodeNotFound;

  /// No description provided for @referralRealNoHistory.
  ///
  /// In en, this message translates to:
  /// **'No referral activity yet. Share your code to get started.'**
  String get referralRealNoHistory;

  /// No description provided for @couponsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your coupons…'**
  String get couponsRealLoadingMessage;

  /// No description provided for @couponsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your coupons. Please try again.'**
  String get couponsRealErrorMessage;

  /// No description provided for @couponsRealClaimHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter a coupon code to add it to your account.'**
  String get couponsRealClaimHelper;

  /// No description provided for @couponsRealClaimSuccess.
  ///
  /// In en, this message translates to:
  /// **'Coupon claimed.'**
  String get couponsRealClaimSuccess;

  /// No description provided for @couponsRealClaimError.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t claim that coupon. Please try again.'**
  String get couponsRealClaimError;

  /// No description provided for @couponsRealNotFound.
  ///
  /// In en, this message translates to:
  /// **'That coupon code was not found.'**
  String get couponsRealNotFound;

  /// No description provided for @couponsRealInvalidCode.
  ///
  /// In en, this message translates to:
  /// **'That coupon is inactive, expired, or not yet valid.'**
  String get couponsRealInvalidCode;

  /// No description provided for @couponsRealLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the usage limit for this coupon.'**
  String get couponsRealLimitReached;

  /// No description provided for @couponStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get couponStatusAvailable;

  /// No description provided for @couponStatusUsed.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get couponStatusUsed;

  /// No description provided for @couponStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get couponStatusExpired;

  /// No description provided for @couponStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get couponStatusRevoked;

  /// No description provided for @couponStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get couponStatusUnknown;

  /// No description provided for @couponDetailMinimumSpend.
  ///
  /// In en, this message translates to:
  /// **'Minimum spend {amount}'**
  String couponDetailMinimumSpend(String amount);

  /// No description provided for @couponDetailValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until {date}'**
  String couponDetailValidUntil(String date);

  /// No description provided for @couponDetailUsagePerUser.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} use(s) per customer'**
  String couponDetailUsagePerUser(int count);

  /// No description provided for @recommendationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendationsTitle;

  /// No description provided for @recommendationsLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your recommendations…'**
  String get recommendationsLoadingMessage;

  /// No description provided for @recommendationsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your recommendations. Please try again.'**
  String get recommendationsErrorMessage;

  /// No description provided for @recommendationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recommendations yet'**
  String get recommendationsEmptyTitle;

  /// No description provided for @recommendationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Save places, browse hotels, and book trips — then regenerate to see picks tailored to you.'**
  String get recommendationsEmptyMessage;

  /// No description provided for @recommendationsGenerateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Regenerate recommendations'**
  String get recommendationsGenerateSemantic;

  /// No description provided for @recommendationsGeneratedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your recommendations are up to date.'**
  String get recommendationsGeneratedMessage;

  /// No description provided for @recommendationsGenerateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t refresh your recommendations. Please try again.'**
  String get recommendationsGenerateErrorMessage;

  /// No description provided for @recommendationsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get recommendationsLoadMore;

  /// No description provided for @recommendationsDismissedMessage.
  ///
  /// In en, this message translates to:
  /// **'Recommendation dismissed.'**
  String get recommendationsDismissedMessage;

  /// No description provided for @recommendationsActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get recommendationsActionErrorMessage;

  /// No description provided for @recommendationsNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection.'**
  String get recommendationsNetworkMessage;

  /// No description provided for @recommendationsGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This recommendation is no longer available.'**
  String get recommendationsGoneMessage;

  /// No description provided for @recommendationUntitled.
  ///
  /// In en, this message translates to:
  /// **'Recommendation'**
  String get recommendationUntitled;

  /// No description provided for @recommendationsDismissSemantic.
  ///
  /// In en, this message translates to:
  /// **'Dismiss {name}'**
  String recommendationsDismissSemantic(String name);

  /// No description provided for @recommendationCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Recommendation: {name}'**
  String recommendationCardSemantic(String name);

  /// No description provided for @recommendationScoreSemantic.
  ///
  /// In en, this message translates to:
  /// **'Match score {score} out of 100'**
  String recommendationScoreSemantic(int score);

  /// No description provided for @recommendationTypePlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get recommendationTypePlace;

  /// No description provided for @recommendationTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get recommendationTypeHotel;

  /// No description provided for @recommendationTypeRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get recommendationTypeRoom;

  /// No description provided for @recommendationTypePromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get recommendationTypePromotion;

  /// No description provided for @recommendationTypeCoupon.
  ///
  /// In en, this message translates to:
  /// **'Coupon'**
  String get recommendationTypeCoupon;

  /// No description provided for @recommendationTypeTripIdea.
  ///
  /// In en, this message translates to:
  /// **'Trip idea'**
  String get recommendationTypeTripIdea;

  /// No description provided for @recommendationTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Suggestion'**
  String get recommendationTypeOther;

  /// No description provided for @recommendationStateClicked.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get recommendationStateClicked;

  /// No description provided for @recommendationStateConverted.
  ///
  /// In en, this message translates to:
  /// **'Booked'**
  String get recommendationStateConverted;

  /// No description provided for @recommendationDetailReason.
  ///
  /// In en, this message translates to:
  /// **'Why we picked this'**
  String get recommendationDetailReason;

  /// No description provided for @recommendationDetailGenerated.
  ///
  /// In en, this message translates to:
  /// **'Suggested {date}'**
  String recommendationDetailGenerated(String date);

  /// No description provided for @recommendationDetailExpires.
  ///
  /// In en, this message translates to:
  /// **'Available until {date}'**
  String recommendationDetailExpires(String date);

  /// No description provided for @expensesTitle.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTitle;

  /// No description provided for @expensesLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading expenses…'**
  String get expensesLoadingMessage;

  /// No description provided for @expensesErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this trip\'s expenses. Please try again.'**
  String get expensesErrorMessage;

  /// No description provided for @expensesGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip or expense is no longer available.'**
  String get expensesGoneMessage;

  /// No description provided for @expensesForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to manage expenses for this trip.'**
  String get expensesForbiddenMessage;

  /// No description provided for @expensesInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check the amount, currency, title and date.'**
  String get expensesInvalidMessage;

  /// No description provided for @expensesNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection.'**
  String get expensesNetworkMessage;

  /// No description provided for @expensesActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get expensesActionErrorMessage;

  /// No description provided for @expensesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expensesEmptyTitle;

  /// No description provided for @expensesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Track what you spend on this trip — add your first expense.'**
  String get expensesEmptyMessage;

  /// No description provided for @expensesAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expensesAddAction;

  /// No description provided for @expensesSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get expensesSaveAction;

  /// No description provided for @expensesAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expensesAddTitle;

  /// No description provided for @expensesEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get expensesEditTitle;

  /// No description provided for @expensesAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add an expense'**
  String get expensesAddSemantic;

  /// No description provided for @expensesCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense added.'**
  String get expensesCreatedMessage;

  /// No description provided for @expensesUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense updated.'**
  String get expensesUpdatedMessage;

  /// No description provided for @expensesDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted.'**
  String get expensesDeletedMessage;

  /// No description provided for @expensesDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get expensesDeleteConfirmTitle;

  /// No description provided for @expensesDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get expensesDeleteConfirmAction;

  /// No description provided for @expensesSummarySpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get expensesSummarySpent;

  /// No description provided for @expensesSummaryOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get expensesSummaryOverBudget;

  /// No description provided for @expenseUntitled.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseUntitled;

  /// No description provided for @expenseFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get expenseFieldTitle;

  /// No description provided for @expenseFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenseFieldAmount;

  /// No description provided for @expenseFieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get expenseFieldCurrency;

  /// No description provided for @expenseFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenseFieldCategory;

  /// No description provided for @expenseFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenseFieldDate;

  /// No description provided for @expenseFieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get expenseFieldNotes;

  /// No description provided for @expensesDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This can\'t be undone.'**
  String expensesDeleteConfirmMessage(String title);

  /// No description provided for @expensesDeleteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Delete {title}'**
  String expensesDeleteSemantic(String title);

  /// No description provided for @expenseCardSemantic.
  ///
  /// In en, this message translates to:
  /// **'Expense: {title}'**
  String expenseCardSemantic(String title);

  /// No description provided for @expensesSummaryBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String expensesSummaryBudget(String amount);

  /// No description provided for @expensesSummaryRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String expensesSummaryRemaining(String amount);

  /// No description provided for @conversationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get conversationsTitle;

  /// No description provided for @conversationsLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your messages…'**
  String get conversationsLoadingMessage;

  /// No description provided for @conversationsErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your messages. Please try again.'**
  String get conversationsErrorMessage;

  /// No description provided for @conversationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get conversationsEmptyTitle;

  /// No description provided for @conversationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Open a booking and tap the message icon to chat with your host.'**
  String get conversationsEmptyMessage;

  /// No description provided for @conversationStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get conversationStatusOpen;

  /// No description provided for @conversationStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get conversationStatusClosed;

  /// No description provided for @conversationStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get conversationStatusArchived;

  /// No description provided for @conversationUntitled.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversationUntitled;

  /// No description provided for @conversationLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation…'**
  String get conversationLoadingMessage;

  /// No description provided for @conversationErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this conversation. Please try again.'**
  String get conversationErrorMessage;

  /// No description provided for @conversationForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'This conversation isn\'t available to you.'**
  String get conversationForbiddenMessage;

  /// No description provided for @conversationGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This conversation is no longer available.'**
  String get conversationGoneMessage;

  /// No description provided for @conversationArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'This conversation is archived and can\'t receive new messages.'**
  String get conversationArchivedMessage;

  /// No description provided for @conversationEmptyBodyMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a message to send.'**
  String get conversationEmptyBodyMessage;

  /// No description provided for @conversationNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection.'**
  String get conversationNetworkMessage;

  /// No description provided for @conversationActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get conversationActionErrorMessage;

  /// No description provided for @conversationNoPartnerMessage.
  ///
  /// In en, this message translates to:
  /// **'This booking\'s host can\'t be messaged yet.'**
  String get conversationNoPartnerMessage;

  /// No description provided for @conversationCloseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close conversation?'**
  String get conversationCloseConfirmTitle;

  /// No description provided for @conversationCloseConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'You can reopen it later by sending a new message.'**
  String get conversationCloseConfirmMessage;

  /// No description provided for @conversationCloseAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get conversationCloseAction;

  /// No description provided for @conversationClosedMessage.
  ///
  /// In en, this message translates to:
  /// **'Conversation closed.'**
  String get conversationClosedMessage;

  /// No description provided for @conversationArchivedNote.
  ///
  /// In en, this message translates to:
  /// **'This conversation is archived.'**
  String get conversationArchivedNote;

  /// No description provided for @conversationNoMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get conversationNoMessagesTitle;

  /// No description provided for @conversationNoMessagesMessage.
  ///
  /// In en, this message translates to:
  /// **'Say hello to start the conversation.'**
  String get conversationNoMessagesMessage;

  /// No description provided for @conversationSenderYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get conversationSenderYou;

  /// No description provided for @conversationSenderHost.
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get conversationSenderHost;

  /// No description provided for @conversationSenderSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get conversationSenderSupport;

  /// No description provided for @conversationSenderSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get conversationSenderSystem;

  /// No description provided for @conversationSeen.
  ///
  /// In en, this message translates to:
  /// **'Seen'**
  String get conversationSeen;

  /// No description provided for @conversationComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message…'**
  String get conversationComposerHint;

  /// No description provided for @conversationSendSemantic.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get conversationSendSemantic;

  /// No description provided for @conversationMessageHostAction.
  ///
  /// In en, this message translates to:
  /// **'Message host'**
  String get conversationMessageHostAction;

  /// No description provided for @conversationBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking {code}'**
  String conversationBookingLabel(String code);

  /// No description provided for @conversationUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String conversationUnreadBadge(int count);

  /// No description provided for @conversationTileSemantic.
  ///
  /// In en, this message translates to:
  /// **'Conversation {title}, {count} unread'**
  String conversationTileSemantic(String title, int count);

  /// No description provided for @conversationMessageSemantic.
  ///
  /// In en, this message translates to:
  /// **'{sender} said: {body}'**
  String conversationMessageSemantic(String sender, String body);

  /// No description provided for @aiContextTitle.
  ///
  /// In en, this message translates to:
  /// **'AI trip context'**
  String get aiContextTitle;

  /// No description provided for @aiContextLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your trip context…'**
  String get aiContextLoadingMessage;

  /// No description provided for @aiContextErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your trip context. Please try again.'**
  String get aiContextErrorMessage;

  /// No description provided for @aiContextExplainer.
  ///
  /// In en, this message translates to:
  /// **'A read-only snapshot of your travel data that an AI assistant would use. No message is generated here.'**
  String get aiContextExplainer;

  /// No description provided for @aiContextActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your activity'**
  String get aiContextActivityTitle;

  /// No description provided for @aiContextCurrentTripTitle.
  ///
  /// In en, this message translates to:
  /// **'Current trip'**
  String get aiContextCurrentTripTitle;

  /// No description provided for @aiContextBudgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Current trip budget'**
  String get aiContextBudgetTitle;

  /// No description provided for @aiContextUpcomingTripsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming trips'**
  String get aiContextUpcomingTripsTitle;

  /// No description provided for @aiContextUntitledTrip.
  ///
  /// In en, this message translates to:
  /// **'Untitled trip'**
  String get aiContextUntitledTrip;

  /// No description provided for @aiContextOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get aiContextOverBudget;

  /// No description provided for @aiContextStatTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get aiContextStatTrips;

  /// No description provided for @aiContextStatActiveTrips.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get aiContextStatActiveTrips;

  /// No description provided for @aiContextStatUpcomingTrips.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get aiContextStatUpcomingTrips;

  /// No description provided for @aiContextStatCompletedTrips.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get aiContextStatCompletedTrips;

  /// No description provided for @aiContextStatPlannedDays.
  ///
  /// In en, this message translates to:
  /// **'Planned days'**
  String get aiContextStatPlannedDays;

  /// No description provided for @aiContextStatBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get aiContextStatBookings;

  /// No description provided for @aiContextStatCollections.
  ///
  /// In en, this message translates to:
  /// **'Collections'**
  String get aiContextStatCollections;

  /// No description provided for @aiContextStatWishlist.
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get aiContextStatWishlist;

  /// No description provided for @aiContextStatReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get aiContextStatReviews;

  /// No description provided for @aiContextStatRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Recommendations'**
  String get aiContextStatRecommendations;

  /// No description provided for @aiContextGeneratedAt.
  ///
  /// In en, this message translates to:
  /// **'Snapshot taken {date}'**
  String aiContextGeneratedAt(String date);

  /// No description provided for @aiContextTripDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String aiContextTripDays(int count);

  /// No description provided for @aiContextStatSemantic.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String aiContextStatSemantic(String label, int value);

  /// No description provided for @aiContextSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String aiContextSpent(String amount);

  /// No description provided for @aiContextBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String aiContextBudget(String amount);

  /// No description provided for @aiContextRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String aiContextRemaining(String amount);

  /// No description provided for @documentsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading documents…'**
  String get documentsRealLoadingMessage;

  /// No description provided for @documentsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this trip\'s documents. Please try again.'**
  String get documentsRealErrorMessage;

  /// No description provided for @documentsRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to manage documents for this trip.'**
  String get documentsRealForbiddenMessage;

  /// No description provided for @documentsRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip or document is no longer available.'**
  String get documentsRealGoneMessage;

  /// No description provided for @documentsRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection.'**
  String get documentsRealNetworkMessage;

  /// No description provided for @documentsRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get documentsRealActionErrorMessage;

  /// No description provided for @documentsRealCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Document attached.'**
  String get documentsRealCreatedMessage;

  /// No description provided for @documentsRealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Document updated.'**
  String get documentsRealUpdatedMessage;

  /// No description provided for @documentsRealPinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Document pinned.'**
  String get documentsRealPinnedMessage;

  /// No description provided for @documentsRealUnpinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Document unpinned.'**
  String get documentsRealUnpinnedMessage;

  /// No description provided for @documentsRealUrlRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a link to the document.'**
  String get documentsRealUrlRequiredMessage;

  /// No description provided for @documentsRealAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Attach a document'**
  String get documentsRealAddSemantic;

  /// No description provided for @documentsRealTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentsRealTypeUnknown;

  /// No description provided for @notesRealTitle.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesRealTitle;

  /// No description provided for @notesRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading notes…'**
  String get notesRealLoadingMessage;

  /// No description provided for @notesRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this trip\'s notes. Please try again.'**
  String get notesRealErrorMessage;

  /// No description provided for @notesRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to manage notes for this trip.'**
  String get notesRealForbiddenMessage;

  /// No description provided for @notesRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip or note is no longer available.'**
  String get notesRealGoneMessage;

  /// No description provided for @notesRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection.'**
  String get notesRealNetworkMessage;

  /// No description provided for @notesRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get notesRealActionErrorMessage;

  /// No description provided for @notesRealCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Note added.'**
  String get notesRealCreatedMessage;

  /// No description provided for @notesRealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Note updated.'**
  String get notesRealUpdatedMessage;

  /// No description provided for @notesRealDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Note deleted.'**
  String get notesRealDeletedMessage;

  /// No description provided for @notesRealPinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Note pinned.'**
  String get notesRealPinnedMessage;

  /// No description provided for @notesRealUnpinnedMessage.
  ///
  /// In en, this message translates to:
  /// **'Note unpinned.'**
  String get notesRealUnpinnedMessage;

  /// No description provided for @notesRealContentRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter some content for this note.'**
  String get notesRealContentRequiredMessage;

  /// No description provided for @notesRealAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get notesRealAddSemantic;

  /// No description provided for @notesRealMoodNone.
  ///
  /// In en, this message translates to:
  /// **'No mood'**
  String get notesRealMoodNone;

  /// No description provided for @notesRealCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New note'**
  String get notesRealCreateTitle;

  /// No description provided for @notesRealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit note'**
  String get notesRealEditTitle;

  /// No description provided for @packingRealTitle.
  ///
  /// In en, this message translates to:
  /// **'Packing'**
  String get packingRealTitle;

  /// No description provided for @packingRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading packing checklist…'**
  String get packingRealLoadingMessage;

  /// No description provided for @packingRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this trip\'s packing checklist. Please try again.'**
  String get packingRealErrorMessage;

  /// No description provided for @packingRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to manage the packing list for this trip.'**
  String get packingRealForbiddenMessage;

  /// No description provided for @packingRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip or packing item is no longer available.'**
  String get packingRealGoneMessage;

  /// No description provided for @packingRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline. Please check your connection.'**
  String get packingRealNetworkMessage;

  /// No description provided for @packingRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get packingRealActionErrorMessage;

  /// No description provided for @packingRealCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Packing item added.'**
  String get packingRealCreatedMessage;

  /// No description provided for @packingRealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Packing item updated.'**
  String get packingRealUpdatedMessage;

  /// No description provided for @packingRealDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Packing item deleted.'**
  String get packingRealDeletedMessage;

  /// No description provided for @packingRealLabelRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this item.'**
  String get packingRealLabelRequiredMessage;

  /// No description provided for @packingRealQuantityInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Quantity must be 1 or more.'**
  String get packingRealQuantityInvalidMessage;

  /// No description provided for @packingRealAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a packing item'**
  String get packingRealAddSemantic;

  /// No description provided for @packingRealCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New packing item'**
  String get packingRealCreateTitle;

  /// No description provided for @packingRealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit packing item'**
  String get packingRealEditTitle;

  /// No description provided for @packingRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to pack yet'**
  String get packingRealEmptyTitle;

  /// No description provided for @packingRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add what you need to bring on this trip.'**
  String get packingRealEmptyMessage;

  /// No description provided for @packingRealDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {label} from this checklist?'**
  String packingRealDeleteConfirmMessage(String label);

  /// No description provided for @packingRealCheckSemantic.
  ///
  /// In en, this message translates to:
  /// **'Mark {label} as packed'**
  String packingRealCheckSemantic(String label);

  /// No description provided for @packingRealUncheckSemantic.
  ///
  /// In en, this message translates to:
  /// **'Mark {label} as not packed'**
  String packingRealUncheckSemantic(String label);

  /// No description provided for @remindersRealTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip reminders'**
  String get remindersRealTitle;

  /// No description provided for @remindersRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading reminders…'**
  String get remindersRealLoadingMessage;

  /// No description provided for @remindersRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load these reminders. Pull to refresh or try again.'**
  String get remindersRealErrorMessage;

  /// No description provided for @remindersRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You can view these reminders but only the trip owner or an editor can change them.'**
  String get remindersRealForbiddenMessage;

  /// No description provided for @remindersRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This reminder or trip is no longer available.'**
  String get remindersRealGoneMessage;

  /// No description provided for @remindersRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get remindersRealNetworkMessage;

  /// No description provided for @remindersRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Please try again.'**
  String get remindersRealActionErrorMessage;

  /// No description provided for @remindersRealCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder added.'**
  String get remindersRealCreatedMessage;

  /// No description provided for @remindersRealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated.'**
  String get remindersRealUpdatedMessage;

  /// No description provided for @remindersRealCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder marked complete.'**
  String get remindersRealCompletedMessage;

  /// No description provided for @remindersRealCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder cancelled.'**
  String get remindersRealCancelledMessage;

  /// No description provided for @remindersRealDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted.'**
  String get remindersRealDeletedMessage;

  /// No description provided for @remindersRealTitleRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a reminder title.'**
  String get remindersRealTitleRequiredMessage;

  /// No description provided for @remindersRealAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder'**
  String get remindersRealAddSemantic;

  /// No description provided for @remindersRealCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get remindersRealCreateTitle;

  /// No description provided for @remindersRealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get remindersRealEditTitle;

  /// No description provided for @remindersRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reminders yet'**
  String get remindersRealEmptyTitle;

  /// No description provided for @remindersRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a reminder to keep track of check-ins, flights, payments, and packing for this trip.'**
  String get remindersRealEmptyMessage;

  /// No description provided for @remindersRealDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {title} from this trip?'**
  String remindersRealDeleteConfirmMessage(String title);

  /// No description provided for @remindersRealCompleteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Mark {title} as complete'**
  String remindersRealCompleteSemantic(String title);

  /// No description provided for @remindersRealCancelSemantic.
  ///
  /// In en, this message translates to:
  /// **'Cancel {title}'**
  String remindersRealCancelSemantic(String title);

  /// No description provided for @budgetRealTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip budget'**
  String get budgetRealTitle;

  /// No description provided for @budgetRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading budget…'**
  String get budgetRealLoadingMessage;

  /// No description provided for @budgetRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load this budget. Pull to refresh or try again.'**
  String get budgetRealErrorMessage;

  /// No description provided for @budgetRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the trip owner can set or change the budget.'**
  String get budgetRealForbiddenMessage;

  /// No description provided for @budgetRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is no longer available.'**
  String get budgetRealGoneMessage;

  /// No description provided for @budgetRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get budgetRealNetworkMessage;

  /// No description provided for @budgetRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Please try again.'**
  String get budgetRealActionErrorMessage;

  /// No description provided for @budgetRealSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Budget saved.'**
  String get budgetRealSavedMessage;

  /// No description provided for @budgetRealDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted.'**
  String get budgetRealDeletedMessage;

  /// No description provided for @budgetRealAmountInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a budget amount of 0 or more.'**
  String get budgetRealAmountInvalidMessage;

  /// No description provided for @budgetRealCurrencyRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a currency.'**
  String get budgetRealCurrencyRequiredMessage;

  /// No description provided for @budgetRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budget set'**
  String get budgetRealEmptyTitle;

  /// No description provided for @budgetRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a total budget to track spending against it for this trip.'**
  String get budgetRealEmptyMessage;

  /// No description provided for @budgetRealSetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set trip budget'**
  String get budgetRealSetTitle;

  /// No description provided for @budgetRealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit trip budget'**
  String get budgetRealEditTitle;

  /// No description provided for @budgetRealSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save budget'**
  String get budgetRealSaveAction;

  /// No description provided for @budgetRealEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get budgetRealEditAction;

  /// No description provided for @budgetRealDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete budget'**
  String get budgetRealDeleteAction;

  /// No description provided for @budgetRealDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete budget?'**
  String get budgetRealDeleteConfirmTitle;

  /// No description provided for @budgetRealDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove the total budget for this trip? Expenses stay unchanged.'**
  String get budgetRealDeleteConfirmMessage;

  /// No description provided for @collaborationRealTitle.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get collaborationRealTitle;

  /// No description provided for @collaborationRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading collaborators…'**
  String get collaborationRealLoadingMessage;

  /// No description provided for @collaborationRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load collaborators. Pull to refresh or try again.'**
  String get collaborationRealErrorMessage;

  /// No description provided for @collaborationRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the trip owner can manage collaborators.'**
  String get collaborationRealForbiddenMessage;

  /// No description provided for @collaborationRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is no longer available.'**
  String get collaborationRealGoneMessage;

  /// No description provided for @collaborationRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get collaborationRealNetworkMessage;

  /// No description provided for @collaborationRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Please try again.'**
  String get collaborationRealActionErrorMessage;

  /// No description provided for @collaborationRealInvitedMessage.
  ///
  /// In en, this message translates to:
  /// **'Collaborator invited.'**
  String get collaborationRealInvitedMessage;

  /// No description provided for @collaborationRealRoleUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Role updated.'**
  String get collaborationRealRoleUpdatedMessage;

  /// No description provided for @collaborationRealRemovedMessage.
  ///
  /// In en, this message translates to:
  /// **'Collaborator removed.'**
  String get collaborationRealRemovedMessage;

  /// No description provided for @collaborationRealPublicOnMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is now public.'**
  String get collaborationRealPublicOnMessage;

  /// No description provided for @collaborationRealPublicOffMessage.
  ///
  /// In en, this message translates to:
  /// **'This trip is private.'**
  String get collaborationRealPublicOffMessage;

  /// No description provided for @collaborationRealInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid collaborator email that isn\'t your own.'**
  String get collaborationRealInvalidMessage;

  /// No description provided for @collaborationRealUserNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No registered user has that email.'**
  String get collaborationRealUserNotFoundMessage;

  /// No description provided for @collaborationRealAlreadyMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'This user is already a collaborator.'**
  String get collaborationRealAlreadyMemberMessage;

  /// No description provided for @collaborationRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No collaborators yet'**
  String get collaborationRealEmptyTitle;

  /// No description provided for @collaborationRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Invite someone by email to view or edit this trip together.'**
  String get collaborationRealEmptyMessage;

  /// No description provided for @collaborationRealEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Collaborator email'**
  String get collaborationRealEmailLabel;

  /// No description provided for @collaborationRealRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get collaborationRealRoleLabel;

  /// No description provided for @collaborationRealEditRoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get collaborationRealEditRoleTitle;

  /// No description provided for @collaborationRealOwnerBadge.
  ///
  /// In en, this message translates to:
  /// **'You own this trip'**
  String get collaborationRealOwnerBadge;

  /// No description provided for @collaborationRealPublicLabel.
  ///
  /// In en, this message translates to:
  /// **'Public visibility'**
  String get collaborationRealPublicLabel;

  /// No description provided for @collaborationRealAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Invite a collaborator'**
  String get collaborationRealAddSemantic;

  /// No description provided for @collaborationRealRemoveConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from this trip? They lose access immediately.'**
  String collaborationRealRemoveConfirmMessage(String name);

  /// No description provided for @sharedTripsRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading shared trips…'**
  String get sharedTripsRealLoadingMessage;

  /// No description provided for @sharedTripsRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your shared trips. Pull to refresh or try again.'**
  String get sharedTripsRealErrorMessage;

  /// No description provided for @sharedTripsRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to these shared trips.'**
  String get sharedTripsRealForbiddenMessage;

  /// No description provided for @sharedTripsRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'These shared trips are no longer available.'**
  String get sharedTripsRealGoneMessage;

  /// No description provided for @sharedTripsRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No shared trips'**
  String get sharedTripsRealEmptyTitle;

  /// No description provided for @sharedTripsRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Trips that others invite you to collaborate on will appear here.'**
  String get sharedTripsRealEmptyMessage;

  /// No description provided for @sharedTripsRealUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled trip'**
  String get sharedTripsRealUntitled;

  /// No description provided for @sharedTripsRealEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared with me'**
  String get sharedTripsRealEntryTitle;

  /// No description provided for @sharedTripsRealEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open trips others have invited you to.'**
  String get sharedTripsRealEntrySubtitle;

  /// No description provided for @sharedTripsRealEntrySemantic.
  ///
  /// In en, this message translates to:
  /// **'Shared with me — trips others have invited you to collaborate on'**
  String get sharedTripsRealEntrySemantic;

  /// No description provided for @interestRealTitle.
  ///
  /// In en, this message translates to:
  /// **'My travel interests'**
  String get interestRealTitle;

  /// No description provided for @interestRealEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel interests'**
  String get interestRealEntryTitle;

  /// No description provided for @interestRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your interests…'**
  String get interestRealLoadingMessage;

  /// No description provided for @interestRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your interests. Pull to refresh or try again.'**
  String get interestRealErrorMessage;

  /// No description provided for @interestRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this interest profile.'**
  String get interestRealForbiddenMessage;

  /// No description provided for @interestRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This interest profile is no longer available.'**
  String get interestRealGoneMessage;

  /// No description provided for @interestRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get interestRealNetworkMessage;

  /// No description provided for @interestRealEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No interests yet'**
  String get interestRealEmptyTitle;

  /// No description provided for @interestRealEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Recalculate to build your interest profile from your bookings, wishlist, saved collections and reviews.'**
  String get interestRealEmptyMessage;

  /// No description provided for @interestRealRecalculateAction.
  ///
  /// In en, this message translates to:
  /// **'Recalculate'**
  String get interestRealRecalculateAction;

  /// No description provided for @interestRealRecalculateSemantic.
  ///
  /// In en, this message translates to:
  /// **'Recalculate my interest profile from my activity'**
  String get interestRealRecalculateSemantic;

  /// No description provided for @interestRealRecalculatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Interests updated.'**
  String get interestRealRecalculatedMessage;

  /// No description provided for @interestRealRecalculateErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t update your interests. Please try again.'**
  String get interestRealRecalculateErrorMessage;

  /// No description provided for @interestRealSignalCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No signals yet} =1{Derived from 1 signal} other{Derived from {count} signals}}'**
  String interestRealSignalCount(int count);

  /// No description provided for @interestRealLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {when}'**
  String interestRealLastUpdated(String when);

  /// No description provided for @interestRealTravelStyles.
  ///
  /// In en, this message translates to:
  /// **'Travel styles'**
  String get interestRealTravelStyles;

  /// No description provided for @interestRealWeather.
  ///
  /// In en, this message translates to:
  /// **'Preferred weather'**
  String get interestRealWeather;

  /// No description provided for @interestRealBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget level'**
  String get interestRealBudget;

  /// No description provided for @interestRealCrowd.
  ///
  /// In en, this message translates to:
  /// **'Crowd level'**
  String get interestRealCrowd;

  /// No description provided for @interestRealAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get interestRealAccessibility;

  /// No description provided for @interestRealProvinces.
  ///
  /// In en, this message translates to:
  /// **'Favorite destinations'**
  String get interestRealProvinces;

  /// No description provided for @interestRealCategories.
  ///
  /// In en, this message translates to:
  /// **'Favorite categories'**
  String get interestRealCategories;

  /// No description provided for @interestRealTags.
  ///
  /// In en, this message translates to:
  /// **'Favorite tags'**
  String get interestRealTags;

  /// No description provided for @walletRealLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Loading your wallet…'**
  String get walletRealLoadingMessage;

  /// No description provided for @walletRealErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your wallet. Pull to refresh or try again.'**
  String get walletRealErrorMessage;

  /// No description provided for @walletRealForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this wallet item.'**
  String get walletRealForbiddenMessage;

  /// No description provided for @walletRealGoneMessage.
  ///
  /// In en, this message translates to:
  /// **'This wallet item is no longer available.'**
  String get walletRealGoneMessage;

  /// No description provided for @walletRealNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get walletRealNetworkMessage;

  /// No description provided for @walletRealActionErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'That didn\'t work. Please try again.'**
  String get walletRealActionErrorMessage;

  /// No description provided for @walletRealCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item added.'**
  String get walletRealCreatedMessage;

  /// No description provided for @walletRealUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item updated.'**
  String get walletRealUpdatedMessage;

  /// No description provided for @walletRealDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item deleted.'**
  String get walletRealDeletedMessage;

  /// No description provided for @walletRealFavoritedMessage.
  ///
  /// In en, this message translates to:
  /// **'Added to favorites.'**
  String get walletRealFavoritedMessage;

  /// No description provided for @walletRealUnfavoritedMessage.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites.'**
  String get walletRealUnfavoritedMessage;

  /// No description provided for @walletRealArchivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item archived.'**
  String get walletRealArchivedMessage;

  /// No description provided for @walletRealRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Wallet item restored.'**
  String get walletRealRestoredMessage;

  /// No description provided for @walletRealTitleRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Enter a title for this wallet item.'**
  String get walletRealTitleRequiredMessage;

  /// No description provided for @walletRealAddSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add a wallet item'**
  String get walletRealAddSemantic;

  /// No description provided for @walletRealCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New wallet item'**
  String get walletRealCreateTitle;

  /// No description provided for @walletRealEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit wallet item'**
  String get walletRealEditTitle;

  /// No description provided for @walletRealUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled item'**
  String get walletRealUntitled;

  /// No description provided for @walletRealListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is empty'**
  String get walletRealListEmptyTitle;

  /// No description provided for @walletRealListEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a passport, visa, ticket, voucher, or receipt to keep it handy for your trips.'**
  String get walletRealListEmptyMessage;

  /// No description provided for @walletRealTitleField.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get walletRealTitleField;

  /// No description provided for @walletRealIssuerField.
  ///
  /// In en, this message translates to:
  /// **'Issuer (optional)'**
  String get walletRealIssuerField;

  /// No description provided for @walletRealReferenceField.
  ///
  /// In en, this message translates to:
  /// **'Reference number (optional)'**
  String get walletRealReferenceField;

  /// No description provided for @walletRealReferenceNote.
  ///
  /// In en, this message translates to:
  /// **'The reference number is stored masked and cannot be shown again.'**
  String get walletRealReferenceNote;

  /// No description provided for @walletRealReferenceHint.
  ///
  /// In en, this message translates to:
  /// **'Current: {masked}. Leave blank to keep it removed; re-enter to replace.'**
  String walletRealReferenceHint(String masked);

  /// No description provided for @walletRealValidFromField.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get walletRealValidFromField;

  /// No description provided for @walletRealValidUntilField.
  ///
  /// In en, this message translates to:
  /// **'Valid until'**
  String get walletRealValidUntilField;

  /// No description provided for @walletRealDateNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get walletRealDateNone;

  /// No description provided for @walletRealSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save item'**
  String get walletRealSaveAction;

  /// No description provided for @walletRealEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get walletRealEditAction;

  /// No description provided for @walletRealDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get walletRealDeleteAction;

  /// No description provided for @walletRealArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get walletRealArchiveAction;

  /// No description provided for @walletRealRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get walletRealRestoreAction;

  /// No description provided for @walletRealDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet item?'**
  String get walletRealDeleteConfirmTitle;

  /// No description provided for @walletRealDeleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete {title} from your wallet? The linked document, booking, or invoice is not affected.'**
  String walletRealDeleteConfirmMessage(String title);

  /// No description provided for @walletRealFavoriteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Add {title} to favorites'**
  String walletRealFavoriteSemantic(String title);

  /// No description provided for @walletRealUnfavoriteSemantic.
  ///
  /// In en, this message translates to:
  /// **'Remove {title} from favorites'**
  String walletRealUnfavoriteSemantic(String title);

  /// No description provided for @partnerExtranetTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner Extranet'**
  String get partnerExtranetTitle;

  /// No description provided for @partnerWorkspaceUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Your workspace'**
  String get partnerWorkspaceUnnamed;

  /// No description provided for @partnerNavGroupOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get partnerNavGroupOverview;

  /// No description provided for @partnerNavGroupProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get partnerNavGroupProperty;

  /// No description provided for @partnerNavGroupOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get partnerNavGroupOperations;

  /// No description provided for @partnerNavGroupGrowth.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get partnerNavGroupGrowth;

  /// No description provided for @partnerNavGroupBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get partnerNavGroupBusiness;

  /// No description provided for @partnerNavGroupAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get partnerNavGroupAccount;

  /// No description provided for @partnerNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get partnerNavDashboard;

  /// No description provided for @partnerNavHotels.
  ///
  /// In en, this message translates to:
  /// **'Hotels'**
  String get partnerNavHotels;

  /// No description provided for @partnerNavRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get partnerNavRooms;

  /// No description provided for @partnerNavCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get partnerNavCalendar;

  /// No description provided for @partnerNavPricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get partnerNavPricing;

  /// No description provided for @partnerNavPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get partnerNavPromotions;

  /// No description provided for @partnerNavBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get partnerNavBookings;

  /// No description provided for @partnerNavMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get partnerNavMessages;

  /// No description provided for @partnerNavAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get partnerNavAnalytics;

  /// No description provided for @partnerNavFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get partnerNavFinance;

  /// No description provided for @partnerNavReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get partnerNavReviews;

  /// No description provided for @partnerNavNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get partnerNavNotifications;

  /// No description provided for @partnerNavSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get partnerNavSettings;

  /// No description provided for @partnerNavMenuTooltip.
  ///
  /// In en, this message translates to:
  /// **'Open partner menu'**
  String get partnerNavMenuTooltip;

  /// No description provided for @partnerNavBadgeSemantic.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} pending'**
  String partnerNavBadgeSemantic(String label, int count);

  /// No description provided for @partnerTeamRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Your team role: {role}'**
  String partnerTeamRoleLabel(String role);

  /// No description provided for @partnerTeamRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get partnerTeamRoleOwner;

  /// No description provided for @partnerTeamRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get partnerTeamRoleManager;

  /// No description provided for @partnerTeamRoleFrontDesk.
  ///
  /// In en, this message translates to:
  /// **'Front desk'**
  String get partnerTeamRoleFrontDesk;

  /// No description provided for @partnerTeamRoleFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get partnerTeamRoleFinance;

  /// No description provided for @partnerTeamRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get partnerTeamRoleViewer;

  /// No description provided for @partnerTeamRoleUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not determined'**
  String get partnerTeamRoleUnknown;

  /// No description provided for @partnerActionRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get partnerActionRetry;

  /// No description provided for @partnerActionRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get partnerActionRefresh;

  /// No description provided for @partnerActionBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get partnerActionBack;

  /// No description provided for @partnerShellMobileHint.
  ///
  /// In en, this message translates to:
  /// **'Use a larger screen for the full operations console.'**
  String get partnerShellMobileHint;

  /// No description provided for @partnerStatusLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading your workspace'**
  String get partnerStatusLoadingTitle;

  /// No description provided for @partnerStatusLoadingMessage.
  ///
  /// In en, this message translates to:
  /// **'Fetching your partner profile and today\'s activity.'**
  String get partnerStatusLoadingMessage;

  /// No description provided for @partnerStatusReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace ready'**
  String get partnerStatusReadyTitle;

  /// No description provided for @partnerStatusReadyMessage.
  ///
  /// In en, this message translates to:
  /// **'Your partner workspace is up to date.'**
  String get partnerStatusReadyMessage;

  /// No description provided for @partnerStatusDemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available in demo mode'**
  String get partnerStatusDemoTitle;

  /// No description provided for @partnerStatusDemoMessage.
  ///
  /// In en, this message translates to:
  /// **'The Partner Extranet works only against the real backend. Sign in with a partner account to open it.'**
  String get partnerStatusDemoMessage;

  /// No description provided for @partnerStatusNotPartnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner access required'**
  String get partnerStatusNotPartnerTitle;

  /// No description provided for @partnerStatusNotPartnerMessage.
  ///
  /// In en, this message translates to:
  /// **'This account is not a partner account, so the Partner Extranet is unavailable.'**
  String get partnerStatusNotPartnerMessage;

  /// No description provided for @partnerStatusOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'No partner profile yet'**
  String get partnerStatusOnboardingTitle;

  /// No description provided for @partnerStatusOnboardingMessage.
  ///
  /// In en, this message translates to:
  /// **'This account has no partner business profile. One must be created and approved before the workspace opens.'**
  String get partnerStatusOnboardingMessage;

  /// No description provided for @partnerStatusAwaitingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for approval'**
  String get partnerStatusAwaitingApprovalTitle;

  /// No description provided for @partnerStatusAwaitingApprovalMessage.
  ///
  /// In en, this message translates to:
  /// **'Your partner profile is submitted. The workspace opens once an administrator approves it.'**
  String get partnerStatusAwaitingApprovalMessage;

  /// No description provided for @partnerStatusRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner profile rejected'**
  String get partnerStatusRejectedTitle;

  /// No description provided for @partnerStatusRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your partner application was rejected, so the workspace is closed.'**
  String get partnerStatusRejectedMessage;

  /// No description provided for @partnerStatusSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner account suspended'**
  String get partnerStatusSuspendedTitle;

  /// No description provided for @partnerStatusSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'An administrator suspended this partner account. Contact support to restore access.'**
  String get partnerStatusSuspendedMessage;

  /// No description provided for @partnerStatusMembershipSuspendedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your team access is suspended'**
  String get partnerStatusMembershipSuspendedTitle;

  /// No description provided for @partnerStatusMembershipSuspendedMessage.
  ///
  /// In en, this message translates to:
  /// **'An owner or manager of this workspace suspended your membership. Your access returns when they reactivate it.'**
  String get partnerStatusMembershipSuspendedMessage;

  /// No description provided for @partnerStatusUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get partnerStatusUnauthorizedTitle;

  /// No description provided for @partnerStatusUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again to reopen the workspace.'**
  String get partnerStatusUnauthorizedMessage;

  /// No description provided for @partnerStatusForbiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'Access refused'**
  String get partnerStatusForbiddenTitle;

  /// No description provided for @partnerStatusForbiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'The server refused this request for your account.'**
  String get partnerStatusForbiddenMessage;

  /// No description provided for @partnerStatusErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not load the workspace'**
  String get partnerStatusErrorTitle;

  /// No description provided for @partnerStatusErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'We could not reach the partner service. Check your connection and try again.'**
  String get partnerStatusErrorMessage;

  /// No description provided for @partnerVerificationApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get partnerVerificationApproved;

  /// No description provided for @partnerVerificationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get partnerVerificationSubmitted;

  /// No description provided for @partnerVerificationDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get partnerVerificationDraft;

  /// No description provided for @partnerVerificationRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get partnerVerificationRejected;

  /// No description provided for @partnerVerificationSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get partnerVerificationSuspended;

  /// No description provided for @partnerVerificationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get partnerVerificationUnknown;

  /// No description provided for @partnerDashboardTodayHeading.
  ///
  /// In en, this message translates to:
  /// **'Today at a glance'**
  String get partnerDashboardTodayHeading;

  /// No description provided for @partnerDashboardRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Represented by {name}'**
  String partnerDashboardRepresentative(String name);

  /// No description provided for @partnerMetricArrivals.
  ///
  /// In en, this message translates to:
  /// **'Arrivals today'**
  String get partnerMetricArrivals;

  /// No description provided for @partnerMetricDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departures today'**
  String get partnerMetricDepartures;

  /// No description provided for @partnerMetricUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get partnerMetricUnreadMessages;

  /// No description provided for @partnerMetricPendingReviews.
  ///
  /// In en, this message translates to:
  /// **'Pending reviews'**
  String get partnerMetricPendingReviews;

  /// No description provided for @partnerMetricActivePromotions.
  ///
  /// In en, this message translates to:
  /// **'Active promotions'**
  String get partnerMetricActivePromotions;

  /// No description provided for @partnerMetricNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get partnerMetricNotifications;

  /// No description provided for @partnerMetricProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get partnerMetricProperties;

  /// No description provided for @partnerMetricActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'Active rooms'**
  String get partnerMetricActiveRooms;

  /// No description provided for @partnerPropertyScopeHeading.
  ///
  /// In en, this message translates to:
  /// **'Property scope'**
  String get partnerPropertyScopeHeading;

  /// No description provided for @partnerPropertyScopeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No properties are assigned to this partner account yet.'**
  String get partnerPropertyScopeEmpty;

  /// No description provided for @partnerPropertyScopeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The property list could not be loaded. Refresh to try again.'**
  String get partnerPropertyScopeUnavailable;

  /// No description provided for @partnerPropertyInactiveSemantic.
  ///
  /// In en, this message translates to:
  /// **'{name}, inactive'**
  String partnerPropertyInactiveSemantic(String name);

  /// No description provided for @partnerModulePlannedBadge.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get partnerModulePlannedBadge;

  /// No description provided for @partnerModulePlannedMessage.
  ///
  /// In en, this message translates to:
  /// **'This module is not built yet. It will be wired to the existing partner endpoints in a later phase; no data is shown until then.'**
  String get partnerModulePlannedMessage;

  /// No description provided for @partnerModuleEndpointHint.
  ///
  /// In en, this message translates to:
  /// **'Route: {route}'**
  String partnerModuleEndpointHint(String route);

  /// No description provided for @partnerModuleReadOnlyForRole.
  ///
  /// In en, this message translates to:
  /// **'Your team role will not be able to change settings in this module.'**
  String get partnerModuleReadOnlyForRole;

  /// No description provided for @partnerDashboardScopeHeading.
  ///
  /// In en, this message translates to:
  /// **'Reporting scope'**
  String get partnerDashboardScopeHeading;

  /// No description provided for @partnerDashboardScopeHint.
  ///
  /// In en, this message translates to:
  /// **'Applies to Performance, Occupancy and Revenue. Today\'s operations always cover every property.'**
  String get partnerDashboardScopeHint;

  /// No description provided for @partnerDashboardScopeToday.
  ///
  /// In en, this message translates to:
  /// **'Today · all properties'**
  String get partnerDashboardScopeToday;

  /// No description provided for @partnerDashboardScopeAllProperties.
  ///
  /// In en, this message translates to:
  /// **'All properties'**
  String get partnerDashboardScopeAllProperties;

  /// No description provided for @partnerDashboardScopeLast30AllProperties.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days · all properties'**
  String get partnerDashboardScopeLast30AllProperties;

  /// No description provided for @partnerDashboardScopeWindowAll.
  ///
  /// In en, this message translates to:
  /// **'{window} · all properties'**
  String partnerDashboardScopeWindowAll(String window);

  /// No description provided for @partnerDashboardScopeWindowOne.
  ///
  /// In en, this message translates to:
  /// **'{window} · selected property'**
  String partnerDashboardScopeWindowOne(String window);

  /// No description provided for @partnerDashboardRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get partnerDashboardRangeLabel;

  /// No description provided for @partnerDashboardRangeLast7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get partnerDashboardRangeLast7;

  /// No description provided for @partnerDashboardRangeLast30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get partnerDashboardRangeLast30;

  /// No description provided for @partnerDashboardRangeLast90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get partnerDashboardRangeLast90;

  /// No description provided for @partnerDashboardPropertyLabel.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get partnerDashboardPropertyLabel;

  /// No description provided for @partnerDashboardPropertyAll.
  ///
  /// In en, this message translates to:
  /// **'All properties'**
  String get partnerDashboardPropertyAll;

  /// No description provided for @partnerDashboardPropertyCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 property} other{{count} properties}}'**
  String partnerDashboardPropertyCount(int count);

  /// No description provided for @partnerDashboardRoomCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active room} other{{count} active rooms}}'**
  String partnerDashboardRoomCount(int count);

  /// No description provided for @partnerDashboardTeamRole.
  ///
  /// In en, this message translates to:
  /// **'Your role: {role}'**
  String partnerDashboardTeamRole(String role);

  /// No description provided for @partnerDashboardActiveProperty.
  ///
  /// In en, this message translates to:
  /// **'Scoped to {name}'**
  String partnerDashboardActiveProperty(String name);

  /// No description provided for @partnerDashboardUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String partnerDashboardUpdatedAt(String time);

  /// No description provided for @partnerDashboardNoActivityHint.
  ///
  /// In en, this message translates to:
  /// **'No bookings fall in the selected window yet, so the performance figures below are zero.'**
  String get partnerDashboardNoActivityHint;

  /// No description provided for @partnerDashboardAttentionHeading.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get partnerDashboardAttentionHeading;

  /// No description provided for @partnerDashboardAttentionClear.
  ///
  /// In en, this message translates to:
  /// **'Nothing is waiting on you right now.'**
  String get partnerDashboardAttentionClear;

  /// No description provided for @partnerDashboardAttentionSemantic.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count, plural, =1{1 item needs attention} other{{count} items need attention}}'**
  String partnerDashboardAttentionSemantic(String label, int count);

  /// No description provided for @partnerDashboardQuickActionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get partnerDashboardQuickActionsHeading;

  /// No description provided for @partnerDashboardPerformanceHeading.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get partnerDashboardPerformanceHeading;

  /// No description provided for @partnerDashboardPerformanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookings in this period, so there is nothing to report yet.'**
  String get partnerDashboardPerformanceEmpty;

  /// No description provided for @partnerDashboardOccupancyHeading.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get partnerDashboardOccupancyHeading;

  /// No description provided for @partnerDashboardOccupancyNoInventory.
  ///
  /// In en, this message translates to:
  /// **'No room inventory is configured yet, so occupancy cannot be measured.'**
  String get partnerDashboardOccupancyNoInventory;

  /// No description provided for @partnerDashboardOccupancyChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Occupancy per day'**
  String get partnerDashboardOccupancyChartLabel;

  /// No description provided for @partnerDashboardRevenueHeading.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get partnerDashboardRevenueHeading;

  /// No description provided for @partnerDashboardRevenueChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Revenue per day'**
  String get partnerDashboardRevenueChartLabel;

  /// No description provided for @partnerDashboardFinanceHeading.
  ///
  /// In en, this message translates to:
  /// **'Finance summary'**
  String get partnerDashboardFinanceHeading;

  /// No description provided for @partnerDashboardActivityHeading.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get partnerDashboardActivityHeading;

  /// No description provided for @partnerDashboardActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No activity has been recorded yet.'**
  String get partnerDashboardActivityEmpty;

  /// No description provided for @partnerDashboardActivityBy.
  ///
  /// In en, this message translates to:
  /// **'by {actor}'**
  String partnerDashboardActivityBy(String actor);

  /// No description provided for @partnerDashboardActivityUnknownActor.
  ///
  /// In en, this message translates to:
  /// **'Unknown user'**
  String get partnerDashboardActivityUnknownActor;

  /// No description provided for @partnerDashboardActivityMore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 older entry} other{{count} older entries}}'**
  String partnerDashboardActivityMore(int count);

  /// No description provided for @partnerDashboardChartEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data points in this period.'**
  String get partnerDashboardChartEmpty;

  /// No description provided for @partnerDashboardErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Sign in again to load this.'**
  String get partnerDashboardErrorUnauthorized;

  /// No description provided for @partnerDashboardErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your partner profile is not approved for this data.'**
  String get partnerDashboardErrorForbidden;

  /// No description provided for @partnerDashboardErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This data is not available for your partner profile.'**
  String get partnerDashboardErrorNotFound;

  /// No description provided for @partnerDashboardErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'That date range is not valid. Choose a different period.'**
  String get partnerDashboardErrorValidation;

  /// No description provided for @partnerDashboardErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'This panel took too long to load.'**
  String get partnerDashboardErrorTimeout;

  /// No description provided for @partnerDashboardErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server for this panel.'**
  String get partnerDashboardErrorNetwork;

  /// No description provided for @partnerDashboardErrorServer.
  ///
  /// In en, this message translates to:
  /// **'The server could not produce this data.'**
  String get partnerDashboardErrorServer;

  /// No description provided for @partnerDashboardErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'This panel could not be loaded.'**
  String get partnerDashboardErrorGeneric;

  /// No description provided for @partnerValueUnavailable.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get partnerValueUnavailable;

  /// No description provided for @partnerKpiCurrentGuests.
  ///
  /// In en, this message translates to:
  /// **'In house now'**
  String get partnerKpiCurrentGuests;

  /// No description provided for @partnerKpiUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get partnerKpiUpcoming;

  /// No description provided for @partnerKpiOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get partnerKpiOccupancy;

  /// No description provided for @partnerKpiRevenueToday.
  ///
  /// In en, this message translates to:
  /// **'Revenue today'**
  String get partnerKpiRevenueToday;

  /// No description provided for @partnerKpiRevenueMonth.
  ///
  /// In en, this message translates to:
  /// **'Revenue this month'**
  String get partnerKpiRevenueMonth;

  /// No description provided for @partnerKpiAverageStay.
  ///
  /// In en, this message translates to:
  /// **'Average stay (nights)'**
  String get partnerKpiAverageStay;

  /// No description provided for @partnerKpiTotalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total revenue'**
  String get partnerKpiTotalRevenue;

  /// No description provided for @partnerKpiTotalBookings.
  ///
  /// In en, this message translates to:
  /// **'Total bookings'**
  String get partnerKpiTotalBookings;

  /// No description provided for @partnerKpiAdr.
  ///
  /// In en, this message translates to:
  /// **'Average daily rate'**
  String get partnerKpiAdr;

  /// No description provided for @partnerKpiAdrCaption.
  ///
  /// In en, this message translates to:
  /// **'Per sold room night'**
  String get partnerKpiAdrCaption;

  /// No description provided for @partnerKpiConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get partnerKpiConfirmed;

  /// No description provided for @partnerKpiCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get partnerKpiCancelled;

  /// No description provided for @partnerKpiReviewAverage.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get partnerKpiReviewAverage;

  /// No description provided for @partnerKpiReviewCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No reviews} =1{From 1 review} other{From {count} reviews}}'**
  String partnerKpiReviewCount(int count);

  /// No description provided for @partnerKpiResponseRate.
  ///
  /// In en, this message translates to:
  /// **'Message response rate'**
  String get partnerKpiResponseRate;

  /// No description provided for @partnerOccupancyInventory.
  ///
  /// In en, this message translates to:
  /// **'Room inventory'**
  String get partnerOccupancyInventory;

  /// No description provided for @partnerOccupancySold.
  ///
  /// In en, this message translates to:
  /// **'Sold rooms'**
  String get partnerOccupancySold;

  /// No description provided for @partnerOccupancyAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available rooms'**
  String get partnerOccupancyAvailable;

  /// No description provided for @partnerOccupancyStopSell.
  ///
  /// In en, this message translates to:
  /// **'Stop-sell days'**
  String get partnerOccupancyStopSell;

  /// No description provided for @partnerRevenueMonthToDate.
  ///
  /// In en, this message translates to:
  /// **'Month to date'**
  String get partnerRevenueMonthToDate;

  /// No description provided for @partnerRevenueLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get partnerRevenueLast30;

  /// No description provided for @partnerRevenueByProperty.
  ///
  /// In en, this message translates to:
  /// **'Revenue by property'**
  String get partnerRevenueByProperty;

  /// No description provided for @partnerFinanceGross.
  ///
  /// In en, this message translates to:
  /// **'Gross revenue'**
  String get partnerFinanceGross;

  /// No description provided for @partnerFinanceNet.
  ///
  /// In en, this message translates to:
  /// **'Net revenue'**
  String get partnerFinanceNet;

  /// No description provided for @partnerFinanceCommission.
  ///
  /// In en, this message translates to:
  /// **'Platform commission'**
  String get partnerFinanceCommission;

  /// No description provided for @partnerFinanceTax.
  ///
  /// In en, this message translates to:
  /// **'Estimated tax'**
  String get partnerFinanceTax;

  /// No description provided for @partnerFinanceRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get partnerFinanceRefunded;

  /// No description provided for @partnerFinancePendingSettlement.
  ///
  /// In en, this message translates to:
  /// **'Pending settlement'**
  String get partnerFinancePendingSettlement;

  /// No description provided for @partnerFinanceNextPayout.
  ///
  /// In en, this message translates to:
  /// **'Next estimated payout'**
  String get partnerFinanceNextPayout;

  /// No description provided for @partnerFinanceCompletedBookings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 completed booking} other{{count} completed bookings}}'**
  String partnerFinanceCompletedBookings(int count);

  /// No description provided for @partnerFinancePaidBookings.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 paid booking} other{{count} paid bookings}}'**
  String partnerFinancePaidBookings(int count);

  /// No description provided for @partnerPropertiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No properties} =1{1 property} other{{count} properties}}'**
  String partnerPropertiesCount(int count);

  /// No description provided for @partnerPropertiesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties yet'**
  String get partnerPropertiesEmptyTitle;

  /// No description provided for @partnerPropertiesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create your first property to start preparing your listing. It is saved as a draft that only you and the Plan Your Trip team can see.'**
  String get partnerPropertiesEmptyMessage;

  /// No description provided for @partnerPropertiesSelectedSemantic.
  ///
  /// In en, this message translates to:
  /// **'Selected property'**
  String get partnerPropertiesSelectedSemantic;

  /// No description provided for @partnerPropertyDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Property details'**
  String get partnerPropertyDetailHeading;

  /// No description provided for @partnerPropertyCloseDetail.
  ///
  /// In en, this message translates to:
  /// **'Close details'**
  String get partnerPropertyCloseDetail;

  /// No description provided for @partnerPropertyDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This property is no longer available to your account.'**
  String get partnerPropertyDetailNotFound;

  /// No description provided for @partnerPropertyActionsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Listing actions are available to the profile owner. You can review every detail here.'**
  String get partnerPropertyActionsOwnerOnly;

  /// No description provided for @partnerPropertyStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get partnerPropertyStatusDraft;

  /// No description provided for @partnerPropertyStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending review'**
  String get partnerPropertyStatusPendingReview;

  /// No description provided for @partnerPropertyStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get partnerPropertyStatusApproved;

  /// No description provided for @partnerPropertyStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get partnerPropertyStatusPublished;

  /// No description provided for @partnerPropertyStatusHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get partnerPropertyStatusHidden;

  /// No description provided for @partnerPropertyStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get partnerPropertyStatusArchived;

  /// No description provided for @partnerPropertyStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get partnerPropertyStatusRejected;

  /// No description provided for @partnerPropertyStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown status'**
  String get partnerPropertyStatusUnknown;

  /// No description provided for @partnerPropertyActive.
  ///
  /// In en, this message translates to:
  /// **'Listing on'**
  String get partnerPropertyActive;

  /// No description provided for @partnerPropertyInactive.
  ///
  /// In en, this message translates to:
  /// **'Listing off'**
  String get partnerPropertyInactive;

  /// No description provided for @partnerPropertyVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get partnerPropertyVerified;

  /// No description provided for @partnerPropertyNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get partnerPropertyNotVerified;

  /// No description provided for @partnerPropertyFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get partnerPropertyFeatured;

  /// No description provided for @partnerPropertyNotFeatured.
  ///
  /// In en, this message translates to:
  /// **'Not featured'**
  String get partnerPropertyNotFeatured;

  /// No description provided for @partnerPropertyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get partnerPropertyNotSet;

  /// No description provided for @partnerPropertyRatingSummary.
  ///
  /// In en, this message translates to:
  /// **'{rating} from {count, plural, =1{1 review} other{{count} reviews}}'**
  String partnerPropertyRatingSummary(String rating, int count);

  /// No description provided for @partnerPropertyVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Guests can find and book this property now.'**
  String get partnerPropertyVisibilityPublic;

  /// No description provided for @partnerPropertyVisibilityNotPublic.
  ///
  /// In en, this message translates to:
  /// **'This property is not visible to guests right now.'**
  String get partnerPropertyVisibilityNotPublic;

  /// No description provided for @partnerPropertyModerationNote.
  ///
  /// In en, this message translates to:
  /// **'Verification and featuring are managed by the Plan Your Trip team and cannot be changed here.'**
  String get partnerPropertyModerationNote;

  /// No description provided for @partnerPropertyActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Turn listing on'**
  String get partnerPropertyActivateAction;

  /// No description provided for @partnerPropertyDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Turn listing off'**
  String get partnerPropertyDeactivateAction;

  /// No description provided for @partnerPropertyActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now listed.'**
  String partnerPropertyActivatedMessage(String name);

  /// No description provided for @partnerPropertyDeactivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer listed.'**
  String partnerPropertyDeactivatedMessage(String name);

  /// No description provided for @partnerPropertyActionNotFound.
  ///
  /// In en, this message translates to:
  /// **'That property is no longer available to your account.'**
  String get partnerPropertyActionNotFound;

  /// No description provided for @partnerPropertyActionFailed.
  ///
  /// In en, this message translates to:
  /// **'The change could not be saved. Nothing was altered.'**
  String get partnerPropertyActionFailed;

  /// No description provided for @partnerPropertyActionUncertain.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before the server confirmed. Refresh to see the current state.'**
  String get partnerPropertyActionUncertain;

  /// No description provided for @partnerPropertySectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get partnerPropertySectionIdentity;

  /// No description provided for @partnerPropertySectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get partnerPropertySectionLocation;

  /// No description provided for @partnerPropertySectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get partnerPropertySectionContact;

  /// No description provided for @partnerPropertySectionPolicies.
  ///
  /// In en, this message translates to:
  /// **'Policies'**
  String get partnerPropertySectionPolicies;

  /// No description provided for @partnerPropertySectionVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get partnerPropertySectionVerification;

  /// No description provided for @partnerPropertySectionPerformance.
  ///
  /// In en, this message translates to:
  /// **'Guest feedback'**
  String get partnerPropertySectionPerformance;

  /// No description provided for @partnerPropertySectionMetadata.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get partnerPropertySectionMetadata;

  /// No description provided for @partnerPropertyFieldSlug.
  ///
  /// In en, this message translates to:
  /// **'URL slug'**
  String get partnerPropertyFieldSlug;

  /// No description provided for @partnerPropertyFieldShortDescription.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get partnerPropertyFieldShortDescription;

  /// No description provided for @partnerPropertyFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get partnerPropertyFieldDescription;

  /// No description provided for @partnerPropertyFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get partnerPropertyFieldAddress;

  /// No description provided for @partnerPropertyFieldCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get partnerPropertyFieldCoordinates;

  /// No description provided for @partnerPropertyFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get partnerPropertyFieldPhone;

  /// No description provided for @partnerPropertyFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get partnerPropertyFieldEmail;

  /// No description provided for @partnerPropertyFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get partnerPropertyFieldWebsite;

  /// No description provided for @partnerPropertyFieldFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get partnerPropertyFieldFacebook;

  /// No description provided for @partnerPropertyFieldInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get partnerPropertyFieldInstagram;

  /// No description provided for @partnerPropertyFieldCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in from'**
  String get partnerPropertyFieldCheckIn;

  /// No description provided for @partnerPropertyFieldCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out by'**
  String get partnerPropertyFieldCheckOut;

  /// No description provided for @partnerPropertyFieldChildrenPolicy.
  ///
  /// In en, this message translates to:
  /// **'Children policy'**
  String get partnerPropertyFieldChildrenPolicy;

  /// No description provided for @partnerPropertyFieldPetPolicy.
  ///
  /// In en, this message translates to:
  /// **'Pet policy'**
  String get partnerPropertyFieldPetPolicy;

  /// No description provided for @partnerPropertyFieldSmokingPolicy.
  ///
  /// In en, this message translates to:
  /// **'Smoking policy'**
  String get partnerPropertyFieldSmokingPolicy;

  /// No description provided for @partnerPropertyFieldVerified.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get partnerPropertyFieldVerified;

  /// No description provided for @partnerPropertyFieldFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured placement'**
  String get partnerPropertyFieldFeatured;

  /// No description provided for @partnerPropertyFieldRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get partnerPropertyFieldRating;

  /// No description provided for @partnerPropertyFieldReviewCount.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get partnerPropertyFieldReviewCount;

  /// No description provided for @partnerPropertyFieldOwner.
  ///
  /// In en, this message translates to:
  /// **'Owned by'**
  String get partnerPropertyFieldOwner;

  /// No description provided for @partnerPropertyFieldCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get partnerPropertyFieldCreated;

  /// No description provided for @partnerPropertyFieldUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get partnerPropertyFieldUpdated;

  /// No description provided for @partnerPropertyAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add property'**
  String get partnerPropertyAddAction;

  /// No description provided for @partnerPropertyEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit property'**
  String get partnerPropertyEditAction;

  /// No description provided for @partnerPropertyEditorCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New property'**
  String get partnerPropertyEditorCreateTitle;

  /// No description provided for @partnerPropertyEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit property'**
  String get partnerPropertyEditorEditTitle;

  /// No description provided for @partnerPropertyEditorIntro.
  ///
  /// In en, this message translates to:
  /// **'Everything here is saved as a draft. Travellers cannot see a draft, and only the Plan Your Trip team can publish one.'**
  String get partnerPropertyEditorIntro;

  /// No description provided for @partnerPropertyEditorSectionBasics.
  ///
  /// In en, this message translates to:
  /// **'Property basics'**
  String get partnerPropertyEditorSectionBasics;

  /// No description provided for @partnerPropertyEditorSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get partnerPropertyEditorSectionLocation;

  /// No description provided for @partnerPropertyEditorSectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get partnerPropertyEditorSectionContact;

  /// No description provided for @partnerPropertyEditorSectionDetails.
  ///
  /// In en, this message translates to:
  /// **'Details and policies'**
  String get partnerPropertyEditorSectionDetails;

  /// No description provided for @partnerPropertyEditorSectionAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get partnerPropertyEditorSectionAmenities;

  /// No description provided for @partnerPropertyEditorSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get partnerPropertyEditorSaveDraft;

  /// No description provided for @partnerPropertyEditorSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get partnerPropertyEditorSaveChanges;

  /// No description provided for @partnerPropertyEditorCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get partnerPropertyEditorCancel;

  /// No description provided for @partnerPropertyFieldName.
  ///
  /// In en, this message translates to:
  /// **'Property name'**
  String get partnerPropertyFieldName;

  /// No description provided for @partnerPropertyFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Property type'**
  String get partnerPropertyFieldCategory;

  /// No description provided for @partnerPropertyFieldSubcategory.
  ///
  /// In en, this message translates to:
  /// **'Specific type'**
  String get partnerPropertyFieldSubcategory;

  /// No description provided for @partnerPropertyFieldLocationUnit.
  ///
  /// In en, this message translates to:
  /// **'Administrative area'**
  String get partnerPropertyFieldLocationUnit;

  /// No description provided for @partnerPropertyFieldLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get partnerPropertyFieldLatitude;

  /// No description provided for @partnerPropertyFieldLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get partnerPropertyFieldLongitude;

  /// No description provided for @partnerPropertyFieldStarRating.
  ///
  /// In en, this message translates to:
  /// **'Property rating'**
  String get partnerPropertyFieldStarRating;

  /// No description provided for @partnerPropertyFieldCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get partnerPropertyFieldCancellationPolicy;

  /// No description provided for @partnerPropertyFieldParking.
  ///
  /// In en, this message translates to:
  /// **'Parking'**
  String get partnerPropertyFieldParking;

  /// No description provided for @partnerPropertyFieldWifi.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi'**
  String get partnerPropertyFieldWifi;

  /// No description provided for @partnerPropertyFieldLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages spoken'**
  String get partnerPropertyFieldLanguages;

  /// No description provided for @partnerPropertyFieldPaymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get partnerPropertyFieldPaymentMethods;

  /// No description provided for @partnerPropertyFieldAmenities.
  ///
  /// In en, this message translates to:
  /// **'Property amenities'**
  String get partnerPropertyFieldAmenities;

  /// No description provided for @partnerPropertyStarRatingHelp.
  ///
  /// In en, this message translates to:
  /// **'Your own classification from 1 to 5. It is not a verified star rating.'**
  String get partnerPropertyStarRatingHelp;

  /// No description provided for @partnerPropertySlugHelp.
  ///
  /// In en, this message translates to:
  /// **'Set when the property is created, because it is part of its public address.'**
  String get partnerPropertySlugHelp;

  /// No description provided for @partnerPropertyListHelp.
  ///
  /// In en, this message translates to:
  /// **'Separate entries with a comma.'**
  String get partnerPropertyListHelp;

  /// No description provided for @partnerPropertyCoordinatesHelp.
  ///
  /// In en, this message translates to:
  /// **'Optional. Latitude between -90 and 90, longitude between -180 and 180.'**
  String get partnerPropertyCoordinatesHelp;

  /// No description provided for @partnerPropertyAmenitiesHelp.
  ///
  /// In en, this message translates to:
  /// **'Choose from the amenities the Plan Your Trip catalogue defines. Room amenities are set on each room later.'**
  String get partnerPropertyAmenitiesHelp;

  /// No description provided for @partnerPropertyAmenitiesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None selected} =1{1 selected} other{{count} selected}}'**
  String partnerPropertyAmenitiesSelected(int count);

  /// No description provided for @partnerPropertyDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft — not visible to travellers'**
  String get partnerPropertyDraftNotice;

  /// No description provided for @partnerPropertyFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get partnerPropertyFreeCancellation;

  /// No description provided for @partnerPropertyParkingAvailable.
  ///
  /// In en, this message translates to:
  /// **'Parking available'**
  String get partnerPropertyParkingAvailable;

  /// No description provided for @partnerPropertyParkingFree.
  ///
  /// In en, this message translates to:
  /// **'Parking is free'**
  String get partnerPropertyParkingFree;

  /// No description provided for @partnerPropertyWifiAvailable.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi available'**
  String get partnerPropertyWifiAvailable;

  /// No description provided for @partnerPropertyWifiFree.
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is free'**
  String get partnerPropertyWifiFree;

  /// No description provided for @partnerPropertyLocationCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get partnerPropertyLocationCountry;

  /// No description provided for @partnerPropertyLocationProvince.
  ///
  /// In en, this message translates to:
  /// **'Province or city'**
  String get partnerPropertyLocationProvince;

  /// No description provided for @partnerPropertyLocationArea.
  ///
  /// In en, this message translates to:
  /// **'Area (optional)'**
  String get partnerPropertyLocationArea;

  /// No description provided for @partnerPropertySelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get partnerPropertySelectPrompt;

  /// No description provided for @partnerPropertyReferenceLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the property options…'**
  String get partnerPropertyReferenceLoading;

  /// No description provided for @partnerPropertyReferenceError.
  ///
  /// In en, this message translates to:
  /// **'The property options could not be loaded, so nothing can be saved yet.'**
  String get partnerPropertyReferenceError;

  /// No description provided for @partnerPropertyValidationName.
  ///
  /// In en, this message translates to:
  /// **'Enter the property name.'**
  String get partnerPropertyValidationName;

  /// No description provided for @partnerPropertyValidationAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter the street address.'**
  String get partnerPropertyValidationAddress;

  /// No description provided for @partnerPropertyValidationCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a property type.'**
  String get partnerPropertyValidationCategory;

  /// No description provided for @partnerPropertyValidationLocation.
  ///
  /// In en, this message translates to:
  /// **'Choose the province, city or area the property is in.'**
  String get partnerPropertyValidationLocation;

  /// No description provided for @partnerPropertyValidationTime.
  ///
  /// In en, this message translates to:
  /// **'Enter a time as HH:MM.'**
  String get partnerPropertyValidationTime;

  /// No description provided for @partnerPropertyValidationLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude must be between -90 and 90.'**
  String get partnerPropertyValidationLatitude;

  /// No description provided for @partnerPropertyValidationLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude must be between -180 and 180.'**
  String get partnerPropertyValidationLongitude;

  /// No description provided for @partnerPropertyValidationEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get partnerPropertyValidationEmail;

  /// No description provided for @partnerPropertyValidationStarRating.
  ///
  /// In en, this message translates to:
  /// **'Choose a rating from 1 to 5.'**
  String get partnerPropertyValidationStarRating;

  /// No description provided for @partnerPropertyCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} was saved as a draft.'**
  String partnerPropertyCreatedMessage(String name);

  /// No description provided for @partnerPropertySavedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} was updated.'**
  String partnerPropertySavedMessage(String name);

  /// No description provided for @partnerPropertyErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get partnerPropertyErrorValidation;

  /// No description provided for @partnerPropertyErrorCategory.
  ///
  /// In en, this message translates to:
  /// **'That property type is not available. Choose another one.'**
  String get partnerPropertyErrorCategory;

  /// No description provided for @partnerPropertyErrorLocation.
  ///
  /// In en, this message translates to:
  /// **'A property cannot sit in that location. Choose a province, city or area.'**
  String get partnerPropertyErrorLocation;

  /// No description provided for @partnerPropertyErrorAmenity.
  ///
  /// In en, this message translates to:
  /// **'One of the selected amenities is not available any more. Reload the options and try again.'**
  String get partnerPropertyErrorAmenity;

  /// No description provided for @partnerPropertyErrorSlugConflict.
  ///
  /// In en, this message translates to:
  /// **'Another property already uses that address.'**
  String get partnerPropertyErrorSlugConflict;

  /// No description provided for @partnerPropertyErrorApproval.
  ///
  /// In en, this message translates to:
  /// **'Your business profile must be approved before you can manage properties.'**
  String get partnerPropertyErrorApproval;

  /// No description provided for @partnerPropertyGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Business profile approval required'**
  String get partnerPropertyGateTitle;

  /// No description provided for @partnerPropertyGateMessage.
  ///
  /// In en, this message translates to:
  /// **'You can add and edit properties once an administrator approves your business profile.'**
  String get partnerPropertyGateMessage;

  /// No description provided for @partnerPropertyGateAction.
  ///
  /// In en, this message translates to:
  /// **'Open my account'**
  String get partnerPropertyGateAction;

  /// No description provided for @partnerWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Property onboarding'**
  String get partnerWizardTitle;

  /// No description provided for @partnerWizardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set your property up step by step. Everything is kept as a draft until our team publishes it.'**
  String get partnerWizardSubtitle;

  /// No description provided for @partnerWizardStepOf.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String partnerWizardStepOf(int current, int total);

  /// No description provided for @partnerWizardStepSemantic.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}: {step}'**
  String partnerWizardStepSemantic(int current, int total, String step);

  /// No description provided for @partnerWizardStepBusinessProfile.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get partnerWizardStepBusinessProfile;

  /// No description provided for @partnerWizardStepBasics.
  ///
  /// In en, this message translates to:
  /// **'Property basics'**
  String get partnerWizardStepBasics;

  /// No description provided for @partnerWizardStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get partnerWizardStepLocation;

  /// No description provided for @partnerWizardStepContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get partnerWizardStepContact;

  /// No description provided for @partnerWizardStepAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get partnerWizardStepAmenities;

  /// No description provided for @partnerWizardStepPolicies.
  ///
  /// In en, this message translates to:
  /// **'Details and policies'**
  String get partnerWizardStepPolicies;

  /// No description provided for @partnerWizardStepReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get partnerWizardStepReview;

  /// No description provided for @partnerWizardProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Onboarding progress'**
  String get partnerWizardProgressLabel;

  /// No description provided for @partnerWizardActionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get partnerWizardActionContinue;

  /// No description provided for @partnerWizardActionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get partnerWizardActionBack;

  /// No description provided for @partnerWizardActionSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get partnerWizardActionSaveDraft;

  /// No description provided for @partnerWizardStepIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Complete this step before continuing.'**
  String get partnerWizardStepIncomplete;

  /// No description provided for @partnerWizardSaveBlockedCreate.
  ///
  /// In en, this message translates to:
  /// **'Your draft is stored once the basics, the location and the check-in times are complete — the server keeps a property only with all of them.'**
  String get partnerWizardSaveBlockedCreate;

  /// No description provided for @partnerWizardSaveBlockedClean.
  ///
  /// In en, this message translates to:
  /// **'Everything here is already saved.'**
  String get partnerWizardSaveBlockedClean;

  /// No description provided for @partnerWizardSavedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Saved just now'**
  String get partnerWizardSavedJustNow;

  /// No description provided for @partnerWizardSavedAt.
  ///
  /// In en, this message translates to:
  /// **'Saved at {time}'**
  String partnerWizardSavedAt(String time);

  /// No description provided for @partnerWizardSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get partnerWizardSaving;

  /// No description provided for @partnerWizardLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your property options…'**
  String get partnerWizardLoading;

  /// No description provided for @partnerWizardPropertyError.
  ///
  /// In en, this message translates to:
  /// **'This draft could not be opened. It may no longer be available to your account.'**
  String get partnerWizardPropertyError;

  /// No description provided for @partnerWizardDraftNotice.
  ///
  /// In en, this message translates to:
  /// **'Draft — not visible to travellers'**
  String get partnerWizardDraftNotice;

  /// No description provided for @partnerWizardProfileHeading.
  ///
  /// In en, this message translates to:
  /// **'Business profile readiness'**
  String get partnerWizardProfileHeading;

  /// No description provided for @partnerWizardProfileIntro.
  ///
  /// In en, this message translates to:
  /// **'Property management opens once an administrator approves your business profile. This step only checks it; your business details are edited in your account.'**
  String get partnerWizardProfileIntro;

  /// No description provided for @partnerWizardProfileApproved.
  ///
  /// In en, this message translates to:
  /// **'Your business profile is approved, so you can set up a property.'**
  String get partnerWizardProfileApproved;

  /// No description provided for @partnerWizardProfileBlocked.
  ///
  /// In en, this message translates to:
  /// **'Your business profile must be approved before you can set up a property.'**
  String get partnerWizardProfileBlocked;

  /// No description provided for @partnerWizardProfileEditAction.
  ///
  /// In en, this message translates to:
  /// **'Open business profile'**
  String get partnerWizardProfileEditAction;

  /// No description provided for @partnerWizardBasicsIntro.
  ///
  /// In en, this message translates to:
  /// **'What the property is called, and what kind of place it is.'**
  String get partnerWizardBasicsIntro;

  /// No description provided for @partnerWizardLocationIntro.
  ///
  /// In en, this message translates to:
  /// **'Where the property is. Travellers search by these places, so pick the smallest one that fits.'**
  String get partnerWizardLocationIntro;

  /// No description provided for @partnerWizardLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get partnerWizardLocationSelected;

  /// No description provided for @partnerWizardContactIntro.
  ///
  /// In en, this message translates to:
  /// **'How guests and our team reach this property. Every field here is optional.'**
  String get partnerWizardContactIntro;

  /// No description provided for @partnerWizardAmenitiesIntro.
  ///
  /// In en, this message translates to:
  /// **'What the property itself offers. Room amenities belong to each room and are set later.'**
  String get partnerWizardAmenitiesIntro;

  /// No description provided for @partnerWizardAmenitiesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search amenities'**
  String get partnerWizardAmenitiesSearch;

  /// No description provided for @partnerWizardAmenitiesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No property amenities match your search.'**
  String get partnerWizardAmenitiesEmpty;

  /// No description provided for @partnerWizardPoliciesIntro.
  ///
  /// In en, this message translates to:
  /// **'Check-in times and the rules that apply to the whole property.'**
  String get partnerWizardPoliciesIntro;

  /// No description provided for @partnerWizardReviewIntro.
  ///
  /// In en, this message translates to:
  /// **'Check everything, then save your draft.'**
  String get partnerWizardReviewIntro;

  /// No description provided for @partnerWizardReviewComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get partnerWizardReviewComplete;

  /// No description provided for @partnerWizardReviewIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get partnerWizardReviewIncomplete;

  /// No description provided for @partnerWizardReviewFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get partnerWizardReviewFix;

  /// No description provided for @partnerWizardReviewSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get partnerWizardReviewSavedTitle;

  /// No description provided for @partnerWizardReviewSavedBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is saved as a draft. It stays invisible to travellers until our team publishes it.'**
  String partnerWizardReviewSavedBody(String name);

  /// No description provided for @partnerWizardReviewDone.
  ///
  /// In en, this message translates to:
  /// **'Back to my properties'**
  String get partnerWizardReviewDone;

  /// No description provided for @partnerWizardLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Save changes before leaving?'**
  String get partnerWizardLeaveTitle;

  /// No description provided for @partnerWizardLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'This step has changes the draft does not have yet.'**
  String get partnerWizardLeaveBody;

  /// No description provided for @partnerWizardLeaveSave.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get partnerWizardLeaveSave;

  /// No description provided for @partnerWizardLeaveDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get partnerWizardLeaveDiscard;

  /// No description provided for @partnerWizardLeaveCancel.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get partnerWizardLeaveCancel;

  /// No description provided for @partnerPropertyContinueSetupAction.
  ///
  /// In en, this message translates to:
  /// **'Continue setup'**
  String get partnerPropertyContinueSetupAction;

  /// No description provided for @partnerPropertyDraftNotVisible.
  ///
  /// In en, this message translates to:
  /// **'Not visible to travellers'**
  String get partnerPropertyDraftNotVisible;

  /// No description provided for @partnerRoomsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 room type} other{{count} room types}}'**
  String partnerRoomsCount(int count);

  /// No description provided for @partnerRoomsListedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 listed} other{{count} listed}}'**
  String partnerRoomsListedCount(int count);

  /// No description provided for @partnerRoomsSoldOutCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sold out} other{{count} sold out}}'**
  String partnerRoomsSoldOutCount(int count);

  /// No description provided for @partnerRoomsForProperty.
  ///
  /// In en, this message translates to:
  /// **'Rooms at {name}'**
  String partnerRoomsForProperty(String name);

  /// No description provided for @partnerRoomsNoPropertyContext.
  ///
  /// In en, this message translates to:
  /// **'No property selected'**
  String get partnerRoomsNoPropertyContext;

  /// No description provided for @partnerRoomsPropertyScope.
  ///
  /// In en, this message translates to:
  /// **'Property scope'**
  String get partnerRoomsPropertyScope;

  /// No description provided for @partnerRoomsSelectPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a property'**
  String get partnerRoomsSelectPropertyTitle;

  /// No description provided for @partnerRoomsSelectPropertyMessage.
  ///
  /// In en, this message translates to:
  /// **'Rooms belong to a specific property, so pick one to see its room types.'**
  String get partnerRoomsSelectPropertyMessage;

  /// No description provided for @partnerRoomsNoPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties yet'**
  String get partnerRoomsNoPropertiesTitle;

  /// No description provided for @partnerRoomsNoPropertiesMessage.
  ///
  /// In en, this message translates to:
  /// **'Rooms live inside a property. Once a property is assigned to your profile, its room types appear here.'**
  String get partnerRoomsNoPropertiesMessage;

  /// No description provided for @partnerRoomsPropertyUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Property unavailable'**
  String get partnerRoomsPropertyUnavailableTitle;

  /// No description provided for @partnerRoomsPropertyUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This property is no longer available to your account, or it has no room configuration yet.'**
  String get partnerRoomsPropertyUnavailableMessage;

  /// No description provided for @partnerRoomsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No room types yet'**
  String get partnerRoomsEmptyTitle;

  /// No description provided for @partnerRoomsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This property has no room types configured. They are set up by the Plan Your Trip team.'**
  String get partnerRoomsEmptyMessage;

  /// No description provided for @partnerRoomActionsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Listing actions are available to the profile owner. You can review every room here.'**
  String get partnerRoomActionsOwnerOnly;

  /// No description provided for @partnerRoomDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Room details'**
  String get partnerRoomDetailHeading;

  /// No description provided for @partnerRoomCloseDetail.
  ///
  /// In en, this message translates to:
  /// **'Close room details'**
  String get partnerRoomCloseDetail;

  /// No description provided for @partnerRoomDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'This room is no longer available to your account.'**
  String get partnerRoomDetailNotFound;

  /// No description provided for @partnerRoomListed.
  ///
  /// In en, this message translates to:
  /// **'Listed'**
  String get partnerRoomListed;

  /// No description provided for @partnerRoomUnlisted.
  ///
  /// In en, this message translates to:
  /// **'Not listed'**
  String get partnerRoomUnlisted;

  /// No description provided for @partnerRoomSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get partnerRoomSoldOut;

  /// No description provided for @partnerRoomListAction.
  ///
  /// In en, this message translates to:
  /// **'List this room'**
  String get partnerRoomListAction;

  /// No description provided for @partnerRoomUnlistAction.
  ///
  /// In en, this message translates to:
  /// **'Stop listing'**
  String get partnerRoomUnlistAction;

  /// No description provided for @partnerRoomListedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now listed.'**
  String partnerRoomListedMessage(String name);

  /// No description provided for @partnerRoomUnlistedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is no longer listed.'**
  String partnerRoomUnlistedMessage(String name);

  /// No description provided for @partnerRoomActionNotFound.
  ///
  /// In en, this message translates to:
  /// **'That room is no longer available to your account.'**
  String get partnerRoomActionNotFound;

  /// No description provided for @partnerRoomYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get partnerRoomYes;

  /// No description provided for @partnerRoomNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get partnerRoomNo;

  /// No description provided for @partnerRoomGuestsValue.
  ///
  /// In en, this message translates to:
  /// **'Up to {count} guests'**
  String partnerRoomGuestsValue(String count);

  /// No description provided for @partnerRoomInventoryValue.
  ///
  /// In en, this message translates to:
  /// **'{available} of {total} available'**
  String partnerRoomInventoryValue(String available, String total);

  /// No description provided for @partnerRoomPriceFromValue.
  ///
  /// In en, this message translates to:
  /// **'From {price}'**
  String partnerRoomPriceFromValue(String price);

  /// No description provided for @partnerRoomSizeValue.
  ///
  /// In en, this message translates to:
  /// **'{size} m²'**
  String partnerRoomSizeValue(String size);

  /// No description provided for @partnerRoomSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get partnerRoomSectionIdentity;

  /// No description provided for @partnerRoomSectionBeds.
  ///
  /// In en, this message translates to:
  /// **'Beds'**
  String get partnerRoomSectionBeds;

  /// No description provided for @partnerRoomSectionCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get partnerRoomSectionCapacity;

  /// No description provided for @partnerRoomSectionInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get partnerRoomSectionInventory;

  /// No description provided for @partnerRoomSectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get partnerRoomSectionPricing;

  /// No description provided for @partnerRoomSectionConditions.
  ///
  /// In en, this message translates to:
  /// **'Booking conditions'**
  String get partnerRoomSectionConditions;

  /// No description provided for @partnerRoomSectionAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get partnerRoomSectionAmenities;

  /// No description provided for @partnerRoomSectionMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get partnerRoomSectionMedia;

  /// No description provided for @partnerRoomFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get partnerRoomFieldCode;

  /// No description provided for @partnerRoomFieldType.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get partnerRoomFieldType;

  /// No description provided for @partnerRoomFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get partnerRoomFieldDescription;

  /// No description provided for @partnerRoomFieldBedType.
  ///
  /// In en, this message translates to:
  /// **'Bed type'**
  String get partnerRoomFieldBedType;

  /// No description provided for @partnerRoomFieldBedCount.
  ///
  /// In en, this message translates to:
  /// **'Number of beds'**
  String get partnerRoomFieldBedCount;

  /// No description provided for @partnerRoomFieldMaxGuests.
  ///
  /// In en, this message translates to:
  /// **'Maximum guests'**
  String get partnerRoomFieldMaxGuests;

  /// No description provided for @partnerRoomFieldMaxAdults.
  ///
  /// In en, this message translates to:
  /// **'Maximum adults'**
  String get partnerRoomFieldMaxAdults;

  /// No description provided for @partnerRoomFieldMaxChildren.
  ///
  /// In en, this message translates to:
  /// **'Maximum children'**
  String get partnerRoomFieldMaxChildren;

  /// No description provided for @partnerRoomFieldSize.
  ///
  /// In en, this message translates to:
  /// **'Room size'**
  String get partnerRoomFieldSize;

  /// No description provided for @partnerRoomFieldFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get partnerRoomFieldFloor;

  /// No description provided for @partnerRoomFieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total rooms'**
  String get partnerRoomFieldQuantity;

  /// No description provided for @partnerRoomFieldAvailable.
  ///
  /// In en, this message translates to:
  /// **'Currently available'**
  String get partnerRoomFieldAvailable;

  /// No description provided for @partnerRoomFieldPriceFrom.
  ///
  /// In en, this message translates to:
  /// **'Price from'**
  String get partnerRoomFieldPriceFrom;

  /// No description provided for @partnerRoomFieldOriginalPrice.
  ///
  /// In en, this message translates to:
  /// **'Original price'**
  String get partnerRoomFieldOriginalPrice;

  /// No description provided for @partnerRoomFieldBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast included'**
  String get partnerRoomFieldBreakfast;

  /// No description provided for @partnerRoomFieldFreeCancellation.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get partnerRoomFieldFreeCancellation;

  /// No description provided for @partnerRoomFieldInstantConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Instant confirmation'**
  String get partnerRoomFieldInstantConfirmation;

  /// No description provided for @partnerRoomFieldSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking allowed'**
  String get partnerRoomFieldSmoking;

  /// No description provided for @partnerRoomFieldImages.
  ///
  /// In en, this message translates to:
  /// **'Gallery images'**
  String get partnerRoomFieldImages;

  /// No description provided for @partnerRoomTypeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get partnerRoomTypeStandard;

  /// No description provided for @partnerRoomTypeSuperior.
  ///
  /// In en, this message translates to:
  /// **'Superior'**
  String get partnerRoomTypeSuperior;

  /// No description provided for @partnerRoomTypeDeluxe.
  ///
  /// In en, this message translates to:
  /// **'Deluxe'**
  String get partnerRoomTypeDeluxe;

  /// No description provided for @partnerRoomTypePremier.
  ///
  /// In en, this message translates to:
  /// **'Premier'**
  String get partnerRoomTypePremier;

  /// No description provided for @partnerRoomTypeExecutive.
  ///
  /// In en, this message translates to:
  /// **'Executive'**
  String get partnerRoomTypeExecutive;

  /// No description provided for @partnerRoomTypeSuite.
  ///
  /// In en, this message translates to:
  /// **'Suite'**
  String get partnerRoomTypeSuite;

  /// No description provided for @partnerRoomTypeFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get partnerRoomTypeFamily;

  /// No description provided for @partnerRoomTypeVilla.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get partnerRoomTypeVilla;

  /// No description provided for @partnerRoomTypeBungalow.
  ///
  /// In en, this message translates to:
  /// **'Bungalow'**
  String get partnerRoomTypeBungalow;

  /// No description provided for @partnerRoomTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised type'**
  String get partnerRoomTypeUnknown;

  /// No description provided for @partnerBedTypeSingle.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get partnerBedTypeSingle;

  /// No description provided for @partnerBedTypeDouble.
  ///
  /// In en, this message translates to:
  /// **'Double'**
  String get partnerBedTypeDouble;

  /// No description provided for @partnerBedTypeTwin.
  ///
  /// In en, this message translates to:
  /// **'Twin'**
  String get partnerBedTypeTwin;

  /// No description provided for @partnerBedTypeQueen.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get partnerBedTypeQueen;

  /// No description provided for @partnerBedTypeKing.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get partnerBedTypeKing;

  /// No description provided for @partnerBedTypeSofaBed.
  ///
  /// In en, this message translates to:
  /// **'Sofa bed'**
  String get partnerBedTypeSofaBed;

  /// No description provided for @partnerBedTypeBunk.
  ///
  /// In en, this message translates to:
  /// **'Bunk bed'**
  String get partnerBedTypeBunk;

  /// No description provided for @partnerBedTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised bed'**
  String get partnerBedTypeUnknown;

  /// No description provided for @partnerInventoryForProperty.
  ///
  /// In en, this message translates to:
  /// **'Inventory at {name}'**
  String partnerInventoryForProperty(String name);

  /// No description provided for @partnerInventoryNoPropertyContext.
  ///
  /// In en, this message translates to:
  /// **'No property selected'**
  String get partnerInventoryNoPropertyContext;

  /// No description provided for @partnerInventoryPropertyScope.
  ///
  /// In en, this message translates to:
  /// **'Property scope'**
  String get partnerInventoryPropertyScope;

  /// No description provided for @partnerInventoryRoomScope.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get partnerInventoryRoomScope;

  /// No description provided for @partnerInventoryRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get partnerInventoryRangeLabel;

  /// No description provided for @partnerInventoryRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get partnerInventoryRangeWeek;

  /// No description provided for @partnerInventoryRangeFortnight.
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get partnerInventoryRangeFortnight;

  /// No description provided for @partnerInventoryRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get partnerInventoryRangeMonth;

  /// No description provided for @partnerInventoryWindow.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to} · {count} days'**
  String partnerInventoryWindow(String from, String to, int count);

  /// No description provided for @partnerInventoryBookableDays.
  ///
  /// In en, this message translates to:
  /// **'{bookable} of {total} days bookable'**
  String partnerInventoryBookableDays(int bookable, int total);

  /// No description provided for @partnerInventoryTotalAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} room-nights available'**
  String partnerInventoryTotalAvailable(String count);

  /// No description provided for @partnerInventoryStopSellDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day stopped} other{{count} days stopped}}'**
  String partnerInventoryStopSellDays(int count);

  /// No description provided for @partnerInventoryNoPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties yet'**
  String get partnerInventoryNoPropertiesTitle;

  /// No description provided for @partnerInventoryNoPropertiesMessage.
  ///
  /// In en, this message translates to:
  /// **'Inventory belongs to a room in a property. Once a property is assigned to your profile, its calendar appears here.'**
  String get partnerInventoryNoPropertiesMessage;

  /// No description provided for @partnerInventorySelectPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a property'**
  String get partnerInventorySelectPropertyTitle;

  /// No description provided for @partnerInventorySelectPropertyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick a property to see the inventory calendar for its room types.'**
  String get partnerInventorySelectPropertyMessage;

  /// No description provided for @partnerInventoryNoRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'No room types yet'**
  String get partnerInventoryNoRoomsTitle;

  /// No description provided for @partnerInventoryNoRoomsMessage.
  ///
  /// In en, this message translates to:
  /// **'This property has no room types, so there is no inventory to manage.'**
  String get partnerInventoryNoRoomsMessage;

  /// No description provided for @partnerInventorySelectRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a room type'**
  String get partnerInventorySelectRoomTitle;

  /// No description provided for @partnerInventorySelectRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'Inventory is kept per room type. Pick one to see its calendar.'**
  String get partnerInventorySelectRoomMessage;

  /// No description provided for @partnerInventoryInvalidRangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Invalid date range'**
  String get partnerInventoryInvalidRangeTitle;

  /// No description provided for @partnerInventoryInvalidRangeMessage.
  ///
  /// In en, this message translates to:
  /// **'The start date must not be after the end date.'**
  String get partnerInventoryInvalidRangeMessage;

  /// No description provided for @partnerInventoryUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory unavailable'**
  String get partnerInventoryUnavailableTitle;

  /// No description provided for @partnerInventoryUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This property or room type is no longer available to your account.'**
  String get partnerInventoryUnavailableMessage;

  /// No description provided for @partnerInventoryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No inventory in this window'**
  String get partnerInventoryEmptyTitle;

  /// No description provided for @partnerInventoryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No inventory rows have been set up for these dates. Try a different window.'**
  String get partnerInventoryEmptyMessage;

  /// No description provided for @partnerInventoryDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get partnerInventoryDate;

  /// No description provided for @partnerInventoryStateColumn.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get partnerInventoryStateColumn;

  /// No description provided for @partnerInventoryTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get partnerInventoryTotal;

  /// No description provided for @partnerInventoryAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get partnerInventoryAvailable;

  /// No description provided for @partnerInventorySold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get partnerInventorySold;

  /// No description provided for @partnerInventoryBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get partnerInventoryBlocked;

  /// No description provided for @partnerInventoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get partnerInventoryMaintenance;

  /// No description provided for @partnerInventoryRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Restrictions'**
  String get partnerInventoryRestrictions;

  /// No description provided for @partnerInventoryStopSell.
  ///
  /// In en, this message translates to:
  /// **'Stop sell'**
  String get partnerInventoryStopSell;

  /// No description provided for @partnerInventoryClosedArrival.
  ///
  /// In en, this message translates to:
  /// **'No arrivals'**
  String get partnerInventoryClosedArrival;

  /// No description provided for @partnerInventoryClosedDeparture.
  ///
  /// In en, this message translates to:
  /// **'No departures'**
  String get partnerInventoryClosedDeparture;

  /// No description provided for @partnerInventoryStateBookable.
  ///
  /// In en, this message translates to:
  /// **'Bookable'**
  String get partnerInventoryStateBookable;

  /// No description provided for @partnerInventoryStateSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Sold out'**
  String get partnerInventoryStateSoldOut;

  /// No description provided for @partnerInventoryStateStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get partnerInventoryStateStopped;

  /// No description provided for @partnerInventoryInconsistent.
  ///
  /// In en, this message translates to:
  /// **'These numbers do not add up to the total.'**
  String get partnerInventoryInconsistent;

  /// No description provided for @partnerInventoryInconsistentSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day has counts that do not add up to its total} other{{count} days have counts that do not add up to their total}}. Only the backend can correct this.'**
  String partnerInventoryInconsistentSummary(int count);

  /// No description provided for @partnerInventoryEditOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Changing availability is available to the profile owner. You can review the calendar here.'**
  String get partnerInventoryEditOwnerOnly;

  /// No description provided for @partnerInventorySaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get partnerInventorySaved;

  /// No description provided for @partnerInventoryActionNotFound.
  ///
  /// In en, this message translates to:
  /// **'That date is no longer available to your account.'**
  String get partnerInventoryActionNotFound;

  /// No description provided for @partnerRatesForProperty.
  ///
  /// In en, this message translates to:
  /// **'Rates at {name}'**
  String partnerRatesForProperty(String name);

  /// No description provided for @partnerRatesForRoom.
  ///
  /// In en, this message translates to:
  /// **'Rates for {room} at {property}'**
  String partnerRatesForRoom(String room, String property);

  /// No description provided for @partnerRatesNoPropertyContext.
  ///
  /// In en, this message translates to:
  /// **'No property selected'**
  String get partnerRatesNoPropertyContext;

  /// No description provided for @partnerRatesPropertyScope.
  ///
  /// In en, this message translates to:
  /// **'Property scope'**
  String get partnerRatesPropertyScope;

  /// No description provided for @partnerRatesRoomScope.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get partnerRatesRoomScope;

  /// No description provided for @partnerRatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 rate plan} other{{count} rate plans}}'**
  String partnerRatesCount(int count);

  /// No description provided for @partnerRatesActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 active} other{{count} active}}'**
  String partnerRatesActiveCount(int count);

  /// No description provided for @partnerRatesExpiredCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expired} other{{count} expired}}'**
  String partnerRatesExpiredCount(int count);

  /// No description provided for @partnerRatesNoPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties yet'**
  String get partnerRatesNoPropertiesTitle;

  /// No description provided for @partnerRatesNoPropertiesMessage.
  ///
  /// In en, this message translates to:
  /// **'Rates belong to a room in a property. Once a property is assigned to your profile, its rate plans appear here.'**
  String get partnerRatesNoPropertiesMessage;

  /// No description provided for @partnerRatesSelectPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a property'**
  String get partnerRatesSelectPropertyTitle;

  /// No description provided for @partnerRatesSelectPropertyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick a property to see the rate plans for its room types.'**
  String get partnerRatesSelectPropertyMessage;

  /// No description provided for @partnerRatesNoRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'No room types yet'**
  String get partnerRatesNoRoomsTitle;

  /// No description provided for @partnerRatesNoRoomsMessage.
  ///
  /// In en, this message translates to:
  /// **'This property has no room types, so there is nothing to price.'**
  String get partnerRatesNoRoomsMessage;

  /// No description provided for @partnerRatesSelectRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a room type'**
  String get partnerRatesSelectRoomTitle;

  /// No description provided for @partnerRatesSelectRoomMessage.
  ///
  /// In en, this message translates to:
  /// **'Rate plans are kept per room type. Pick one to see its rates.'**
  String get partnerRatesSelectRoomMessage;

  /// No description provided for @partnerRatesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Rates unavailable'**
  String get partnerRatesUnavailableTitle;

  /// No description provided for @partnerRatesUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This property or room type is no longer available to your account.'**
  String get partnerRatesUnavailableMessage;

  /// No description provided for @partnerRatesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No rate plans yet'**
  String get partnerRatesEmptyTitle;

  /// No description provided for @partnerRatesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This room type has no rate plans. They are set up by the Plan Your Trip team.'**
  String get partnerRatesEmptyMessage;

  /// No description provided for @partnerRateDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Rate plan details'**
  String get partnerRateDetailHeading;

  /// No description provided for @partnerRateCloseDetail.
  ///
  /// In en, this message translates to:
  /// **'Close rate plan details'**
  String get partnerRateCloseDetail;

  /// No description provided for @partnerRateActionsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Rate actions are available to the profile owner. You can review every plan here.'**
  String get partnerRateActionsOwnerOnly;

  /// No description provided for @partnerRateCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'Amounts are shown without a currency because the rate API does not supply one.'**
  String get partnerRateCurrencyNote;

  /// No description provided for @partnerRateValidityNote.
  ///
  /// In en, this message translates to:
  /// **'Both dates are inclusive: a stay qualifies when every night falls inside this window.'**
  String get partnerRateValidityNote;

  /// No description provided for @partnerRateActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get partnerRateActive;

  /// No description provided for @partnerRateInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get partnerRateInactive;

  /// No description provided for @partnerRateExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get partnerRateExpired;

  /// No description provided for @partnerRatePerNight.
  ///
  /// In en, this message translates to:
  /// **'{amount} per night'**
  String partnerRatePerNight(String amount);

  /// No description provided for @partnerRateValidity.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String partnerRateValidity(String from, String to);

  /// No description provided for @partnerRatePriorityValue.
  ///
  /// In en, this message translates to:
  /// **'Priority {value}'**
  String partnerRatePriorityValue(String value);

  /// No description provided for @partnerRateHasRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Has restrictions'**
  String get partnerRateHasRestrictions;

  /// No description provided for @partnerRateNightsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} nights'**
  String partnerRateNightsValue(String count);

  /// No description provided for @partnerRateDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String partnerRateDaysValue(String count);

  /// No description provided for @partnerRateActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get partnerRateActivateAction;

  /// No description provided for @partnerRateDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get partnerRateDeactivateAction;

  /// No description provided for @partnerRateActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now active.'**
  String partnerRateActivatedMessage(String name);

  /// No description provided for @partnerRateDeactivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now inactive.'**
  String partnerRateDeactivatedMessage(String name);

  /// No description provided for @partnerRateActionNotFound.
  ///
  /// In en, this message translates to:
  /// **'That rate plan is no longer available to your account.'**
  String get partnerRateActionNotFound;

  /// No description provided for @partnerRateActionConflict.
  ///
  /// In en, this message translates to:
  /// **'That change conflicts with another rate plan.'**
  String get partnerRateActionConflict;

  /// No description provided for @partnerRateTypeStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get partnerRateTypeStandard;

  /// No description provided for @partnerRateTypePromotional.
  ///
  /// In en, this message translates to:
  /// **'Promotional'**
  String get partnerRateTypePromotional;

  /// No description provided for @partnerRateTypeMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get partnerRateTypeMember;

  /// No description provided for @partnerRateTypeEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early bird'**
  String get partnerRateTypeEarlyBird;

  /// No description provided for @partnerRateTypeLastMinute.
  ///
  /// In en, this message translates to:
  /// **'Last minute'**
  String get partnerRateTypeLastMinute;

  /// No description provided for @partnerRateTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised type'**
  String get partnerRateTypeUnknown;

  /// No description provided for @partnerMealPlanRoomOnly.
  ///
  /// In en, this message translates to:
  /// **'Room only'**
  String get partnerMealPlanRoomOnly;

  /// No description provided for @partnerMealPlanBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get partnerMealPlanBreakfast;

  /// No description provided for @partnerMealPlanHalfBoard.
  ///
  /// In en, this message translates to:
  /// **'Half board'**
  String get partnerMealPlanHalfBoard;

  /// No description provided for @partnerMealPlanFullBoard.
  ///
  /// In en, this message translates to:
  /// **'Full board'**
  String get partnerMealPlanFullBoard;

  /// No description provided for @partnerMealPlanAllInclusive.
  ///
  /// In en, this message translates to:
  /// **'All inclusive'**
  String get partnerMealPlanAllInclusive;

  /// No description provided for @partnerMealPlanUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised meal plan'**
  String get partnerMealPlanUnknown;

  /// No description provided for @partnerCancellationFree.
  ///
  /// In en, this message translates to:
  /// **'Free cancellation'**
  String get partnerCancellationFree;

  /// No description provided for @partnerCancellationPartial.
  ///
  /// In en, this message translates to:
  /// **'Partially refundable'**
  String get partnerCancellationPartial;

  /// No description provided for @partnerCancellationNonRefundable.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable'**
  String get partnerCancellationNonRefundable;

  /// No description provided for @partnerCancellationCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom policy'**
  String get partnerCancellationCustom;

  /// No description provided for @partnerCancellationUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised policy'**
  String get partnerCancellationUnknown;

  /// No description provided for @partnerRateSourceBase.
  ///
  /// In en, this message translates to:
  /// **'Base rate'**
  String get partnerRateSourceBase;

  /// No description provided for @partnerRateSourceDerived.
  ///
  /// In en, this message translates to:
  /// **'Derived rate'**
  String get partnerRateSourceDerived;

  /// No description provided for @partnerRateSourceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised source'**
  String get partnerRateSourceUnknown;

  /// No description provided for @partnerRateAdjustmentFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get partnerRateAdjustmentFixed;

  /// No description provided for @partnerRateAdjustmentPercent.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get partnerRateAdjustmentPercent;

  /// No description provided for @partnerRateAdjustmentUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised adjustment'**
  String get partnerRateAdjustmentUnknown;

  /// No description provided for @partnerRateSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get partnerRateSectionIdentity;

  /// No description provided for @partnerRateSectionPricing.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get partnerRateSectionPricing;

  /// No description provided for @partnerRateSectionValidity.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get partnerRateSectionValidity;

  /// No description provided for @partnerRateSectionRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Stay restrictions'**
  String get partnerRateSectionRestrictions;

  /// No description provided for @partnerRateSectionCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation'**
  String get partnerRateSectionCancellation;

  /// No description provided for @partnerRateSectionInclusions.
  ///
  /// In en, this message translates to:
  /// **'Inclusions'**
  String get partnerRateSectionInclusions;

  /// No description provided for @partnerRateSectionOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy prices'**
  String get partnerRateSectionOccupancy;

  /// No description provided for @partnerRateFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Plan code'**
  String get partnerRateFieldCode;

  /// No description provided for @partnerRateFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get partnerRateFieldDescription;

  /// No description provided for @partnerRateFieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get partnerRateFieldPriority;

  /// No description provided for @partnerRateFieldPricePerNight.
  ///
  /// In en, this message translates to:
  /// **'Price per night'**
  String get partnerRateFieldPricePerNight;

  /// No description provided for @partnerRateFieldExtraBedPrice.
  ///
  /// In en, this message translates to:
  /// **'Extra bed price'**
  String get partnerRateFieldExtraBedPrice;

  /// No description provided for @partnerRateFieldAdjustmentType.
  ///
  /// In en, this message translates to:
  /// **'Adjustment type'**
  String get partnerRateFieldAdjustmentType;

  /// No description provided for @partnerRateFieldAdjustmentValue.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get partnerRateFieldAdjustmentValue;

  /// No description provided for @partnerRateFieldParentPlan.
  ///
  /// In en, this message translates to:
  /// **'Derived from plan'**
  String get partnerRateFieldParentPlan;

  /// No description provided for @partnerRateFieldValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid from'**
  String get partnerRateFieldValidFrom;

  /// No description provided for @partnerRateFieldValidTo.
  ///
  /// In en, this message translates to:
  /// **'Valid to'**
  String get partnerRateFieldValidTo;

  /// No description provided for @partnerRateFieldMinStay.
  ///
  /// In en, this message translates to:
  /// **'Minimum stay'**
  String get partnerRateFieldMinStay;

  /// No description provided for @partnerRateFieldMaxStay.
  ///
  /// In en, this message translates to:
  /// **'Maximum stay'**
  String get partnerRateFieldMaxStay;

  /// No description provided for @partnerRateFieldMinAdvance.
  ///
  /// In en, this message translates to:
  /// **'Minimum advance booking'**
  String get partnerRateFieldMinAdvance;

  /// No description provided for @partnerRateFieldMaxAdvance.
  ///
  /// In en, this message translates to:
  /// **'Maximum advance booking'**
  String get partnerRateFieldMaxAdvance;

  /// No description provided for @partnerRateFieldClosedToArrival.
  ///
  /// In en, this message translates to:
  /// **'Closed to arrival'**
  String get partnerRateFieldClosedToArrival;

  /// No description provided for @partnerRateFieldClosedToDeparture.
  ///
  /// In en, this message translates to:
  /// **'Closed to departure'**
  String get partnerRateFieldClosedToDeparture;

  /// No description provided for @partnerRateFieldPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get partnerRateFieldPolicy;

  /// No description provided for @partnerRateFieldRefundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get partnerRateFieldRefundable;

  /// No description provided for @partnerRateFieldDeadlineHours.
  ///
  /// In en, this message translates to:
  /// **'Cancellation deadline (hours)'**
  String get partnerRateFieldDeadlineHours;

  /// No description provided for @partnerRateFieldPenaltyPercent.
  ///
  /// In en, this message translates to:
  /// **'Cancellation penalty'**
  String get partnerRateFieldPenaltyPercent;

  /// No description provided for @partnerRateFieldMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get partnerRateFieldMealPlan;

  /// No description provided for @partnerRateFieldOccupancyPricing.
  ///
  /// In en, this message translates to:
  /// **'Occupancy pricing enabled'**
  String get partnerRateFieldOccupancyPricing;

  /// No description provided for @partnerRateFieldChildPricing.
  ///
  /// In en, this message translates to:
  /// **'Child pricing enabled'**
  String get partnerRateFieldChildPricing;

  /// No description provided for @partnerRateOccupancyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No occupancy prices are configured for this plan.'**
  String get partnerRateOccupancyEmpty;

  /// No description provided for @partnerRateOccupancyLabel.
  ///
  /// In en, this message translates to:
  /// **'{adults} adults, {children} children'**
  String partnerRateOccupancyLabel(String adults, String children);

  /// No description provided for @partnerPoliciesTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies & settings'**
  String get partnerPoliciesTitle;

  /// No description provided for @partnerPoliciesForProperty.
  ///
  /// In en, this message translates to:
  /// **'Policies for {name}'**
  String partnerPoliciesForProperty(String name);

  /// No description provided for @partnerPoliciesNoPropertyContext.
  ///
  /// In en, this message translates to:
  /// **'No property selected'**
  String get partnerPoliciesNoPropertyContext;

  /// No description provided for @partnerPoliciesPropertyScope.
  ///
  /// In en, this message translates to:
  /// **'Property scope'**
  String get partnerPoliciesPropertyScope;

  /// No description provided for @partnerPoliciesNoPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No properties yet'**
  String get partnerPoliciesNoPropertiesTitle;

  /// No description provided for @partnerPoliciesNoPropertiesMessage.
  ///
  /// In en, this message translates to:
  /// **'Guest policies belong to a property. Once a property is assigned to your profile, its policies appear here.'**
  String get partnerPoliciesNoPropertiesMessage;

  /// No description provided for @partnerPoliciesSelectPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a property'**
  String get partnerPoliciesSelectPropertyTitle;

  /// No description provided for @partnerPoliciesSelectPropertyMessage.
  ///
  /// In en, this message translates to:
  /// **'Pick a property to review and edit its guest policies.'**
  String get partnerPoliciesSelectPropertyMessage;

  /// No description provided for @partnerPoliciesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Policies unavailable'**
  String get partnerPoliciesUnavailableTitle;

  /// No description provided for @partnerPoliciesUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This property is no longer available to your account.'**
  String get partnerPoliciesUnavailableMessage;

  /// No description provided for @partnerPoliciesPropertySection.
  ///
  /// In en, this message translates to:
  /// **'Guest policies'**
  String get partnerPoliciesPropertySection;

  /// No description provided for @partnerPoliciesPropertyScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to this property only. Guests see these on the listing.'**
  String get partnerPoliciesPropertyScopeNote;

  /// No description provided for @partnerPoliciesLiveWarning.
  ///
  /// In en, this message translates to:
  /// **'These take effect immediately for every guest, including guests who already hold a booking — the platform does not freeze policies at booking time.'**
  String get partnerPoliciesLiveWarning;

  /// No description provided for @partnerPoliciesOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Guest policies can be changed by the profile owner. You can review them here.'**
  String get partnerPoliciesOwnerOnly;

  /// No description provided for @partnerPoliciesCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in from'**
  String get partnerPoliciesCheckIn;

  /// No description provided for @partnerPoliciesCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out by'**
  String get partnerPoliciesCheckOut;

  /// No description provided for @partnerPoliciesTimeHelper.
  ///
  /// In en, this message translates to:
  /// **'24-hour time, for example 14:00'**
  String get partnerPoliciesTimeHelper;

  /// No description provided for @partnerPoliciesTimeRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get partnerPoliciesTimeRequired;

  /// No description provided for @partnerPoliciesHouseRules.
  ///
  /// In en, this message translates to:
  /// **'House rules'**
  String get partnerPoliciesHouseRules;

  /// No description provided for @partnerPoliciesHouseRulesNote.
  ///
  /// In en, this message translates to:
  /// **'Optional. Leave a rule empty to remove it.'**
  String get partnerPoliciesHouseRulesNote;

  /// No description provided for @partnerPoliciesRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for no rule'**
  String get partnerPoliciesRuleHint;

  /// No description provided for @partnerPoliciesChildren.
  ///
  /// In en, this message translates to:
  /// **'Children policy'**
  String get partnerPoliciesChildren;

  /// No description provided for @partnerPoliciesPets.
  ///
  /// In en, this message translates to:
  /// **'Pet policy'**
  String get partnerPoliciesPets;

  /// No description provided for @partnerPoliciesSmoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking policy'**
  String get partnerPoliciesSmoking;

  /// No description provided for @partnerPoliciesSettingsSection.
  ///
  /// In en, this message translates to:
  /// **'Workspace notifications'**
  String get partnerPoliciesSettingsSection;

  /// No description provided for @partnerPoliciesSettingsScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to your whole partner account, not to one property.'**
  String get partnerPoliciesSettingsScopeNote;

  /// No description provided for @partnerPoliciesSettingsRoleNote.
  ///
  /// In en, this message translates to:
  /// **'Notification settings can be changed by an owner or manager. You can review them here.'**
  String get partnerPoliciesSettingsRoleNote;

  /// No description provided for @partnerPoliciesSettingsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your workspace settings are not available.'**
  String get partnerPoliciesSettingsUnavailable;

  /// No description provided for @partnerPoliciesSettingsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated {time}'**
  String partnerPoliciesSettingsUpdated(String time);

  /// No description provided for @partnerPoliciesLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default language'**
  String get partnerPoliciesLanguage;

  /// No description provided for @partnerPoliciesTimezone.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get partnerPoliciesTimezone;

  /// No description provided for @partnerPoliciesChannels.
  ///
  /// In en, this message translates to:
  /// **'Delivery channels'**
  String get partnerPoliciesChannels;

  /// No description provided for @partnerPoliciesChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get partnerPoliciesChannelEmail;

  /// No description provided for @partnerPoliciesChannelSms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get partnerPoliciesChannelSms;

  /// No description provided for @partnerPoliciesChannelInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app'**
  String get partnerPoliciesChannelInApp;

  /// No description provided for @partnerPoliciesTopics.
  ///
  /// In en, this message translates to:
  /// **'What to notify me about'**
  String get partnerPoliciesTopics;

  /// No description provided for @partnerPoliciesTopicBooking.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get partnerPoliciesTopicBooking;

  /// No description provided for @partnerPoliciesTopicPayment.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get partnerPoliciesTopicPayment;

  /// No description provided for @partnerPoliciesTopicReview.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get partnerPoliciesTopicReview;

  /// No description provided for @partnerPoliciesTopicPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get partnerPoliciesTopicPromotion;

  /// No description provided for @partnerPoliciesSave.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get partnerPoliciesSave;

  /// No description provided for @partnerPoliciesRevert.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get partnerPoliciesRevert;

  /// No description provided for @partnerPoliciesNoChanges.
  ///
  /// In en, this message translates to:
  /// **'No unsaved changes.'**
  String get partnerPoliciesNoChanges;

  /// No description provided for @partnerPoliciesSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get partnerPoliciesSaved;

  /// No description provided for @partnerPoliciesSaveForbidden.
  ///
  /// In en, this message translates to:
  /// **'Your role does not allow this change.'**
  String get partnerPoliciesSaveForbidden;

  /// No description provided for @partnerPoliciesSaveNotFound.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer available to your account.'**
  String get partnerPoliciesSaveNotFound;

  /// No description provided for @partnerPoliciesSaveValidation.
  ///
  /// In en, this message translates to:
  /// **'Check-in and check-out times are both required.'**
  String get partnerPoliciesSaveValidation;

  /// No description provided for @partnerAssetsSection.
  ///
  /// In en, this message translates to:
  /// **'Photos & media'**
  String get partnerAssetsSection;

  /// No description provided for @partnerAssetsDeferredBadge.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get partnerAssetsDeferredBadge;

  /// No description provided for @partnerAssetsDeferredMessage.
  ///
  /// In en, this message translates to:
  /// **'Photo management is not part of the partner API. Uploading, replacing, reordering and deleting media are admin-only operations, so the Plan Your Trip team maintains your listing images for now.'**
  String get partnerAssetsDeferredMessage;

  /// No description provided for @partnerPromotionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Promotions & vouchers'**
  String get partnerPromotionsTitle;

  /// No description provided for @partnerPromotionsTabPromotions.
  ///
  /// In en, this message translates to:
  /// **'Promotion rules'**
  String get partnerPromotionsTabPromotions;

  /// No description provided for @partnerPromotionsTabVoucherCheck.
  ///
  /// In en, this message translates to:
  /// **'Voucher check'**
  String get partnerPromotionsTabVoucherCheck;

  /// No description provided for @partnerPromotionsScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Every promotion on any property or room you own is listed here. The partner API does not narrow promotions to one property, so this list is not filtered by your selected property.'**
  String get partnerPromotionsScopeNote;

  /// No description provided for @partnerPromotionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} promotions'**
  String partnerPromotionsCount(int count);

  /// No description provided for @partnerPromotionsActiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String partnerPromotionsActiveCount(int count);

  /// No description provided for @partnerPromotionsExpiredCount.
  ///
  /// In en, this message translates to:
  /// **'{count} past their end date'**
  String partnerPromotionsExpiredCount(int count);

  /// No description provided for @partnerPromotionsCurrencyNote.
  ///
  /// In en, this message translates to:
  /// **'The promotion API sends no currency, so promotion amounts appear without a symbol. The pricing preview below carries its own currency and shows it.'**
  String get partnerPromotionsCurrencyNote;

  /// No description provided for @partnerPromotionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No promotions yet'**
  String get partnerPromotionsEmptyTitle;

  /// No description provided for @partnerPromotionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing currently targets your properties or rooms. Site-wide campaigns run by Plan Your Trip are not shown here because they are not yours to manage.'**
  String get partnerPromotionsEmptyMessage;

  /// No description provided for @partnerPromotionsOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the partner account owner can change promotions. You can read them here.'**
  String get partnerPromotionsOwnerOnly;

  /// No description provided for @partnerPromotionDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Promotion details'**
  String get partnerPromotionDetailHeading;

  /// No description provided for @partnerPromotionCloseDetail.
  ///
  /// In en, this message translates to:
  /// **'Close promotion details'**
  String get partnerPromotionCloseDetail;

  /// No description provided for @partnerPromotionSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get partnerPromotionSectionIdentity;

  /// No description provided for @partnerPromotionFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Promotion code'**
  String get partnerPromotionFieldCode;

  /// No description provided for @partnerPromotionFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get partnerPromotionFieldDescription;

  /// No description provided for @partnerPromotionFieldType.
  ///
  /// In en, this message translates to:
  /// **'Promotion type'**
  String get partnerPromotionFieldType;

  /// No description provided for @partnerPromotionSectionDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get partnerPromotionSectionDiscount;

  /// No description provided for @partnerPromotionFieldDiscountType.
  ///
  /// In en, this message translates to:
  /// **'Discount type'**
  String get partnerPromotionFieldDiscountType;

  /// No description provided for @partnerPromotionFieldDiscountValue.
  ///
  /// In en, this message translates to:
  /// **'Discount value'**
  String get partnerPromotionFieldDiscountValue;

  /// No description provided for @partnerPromotionFieldMaxDiscount.
  ///
  /// In en, this message translates to:
  /// **'Maximum discount'**
  String get partnerPromotionFieldMaxDiscount;

  /// No description provided for @partnerPromotionSectionValidity.
  ///
  /// In en, this message translates to:
  /// **'Validity'**
  String get partnerPromotionSectionValidity;

  /// No description provided for @partnerPromotionFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get partnerPromotionFieldStart;

  /// No description provided for @partnerPromotionFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get partnerPromotionFieldEnd;

  /// No description provided for @partnerPromotionSectionConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get partnerPromotionSectionConditions;

  /// No description provided for @partnerPromotionFieldMinimumStay.
  ///
  /// In en, this message translates to:
  /// **'Minimum stay'**
  String get partnerPromotionFieldMinimumStay;

  /// No description provided for @partnerPromotionFieldMinimumSpend.
  ///
  /// In en, this message translates to:
  /// **'Minimum spend'**
  String get partnerPromotionFieldMinimumSpend;

  /// No description provided for @partnerPromotionSectionApplication.
  ///
  /// In en, this message translates to:
  /// **'How it applies'**
  String get partnerPromotionSectionApplication;

  /// No description provided for @partnerPromotionFieldTarget.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get partnerPromotionFieldTarget;

  /// No description provided for @partnerPromotionFieldPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get partnerPromotionFieldPriority;

  /// No description provided for @partnerPromotionFieldStackable.
  ///
  /// In en, this message translates to:
  /// **'Combines with others'**
  String get partnerPromotionFieldStackable;

  /// No description provided for @partnerPromotionStackableNote.
  ///
  /// In en, this message translates to:
  /// **'The pricing engine may add further promotions after this one.'**
  String get partnerPromotionStackableNote;

  /// No description provided for @partnerPromotionNonStackableNote.
  ///
  /// In en, this message translates to:
  /// **'The pricing engine applies this promotion and then stops, so no lower-priority promotion is added after it.'**
  String get partnerPromotionNonStackableNote;

  /// No description provided for @partnerPromotionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get partnerPromotionActive;

  /// No description provided for @partnerPromotionInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get partnerPromotionInactive;

  /// No description provided for @partnerPromotionExpired.
  ///
  /// In en, this message translates to:
  /// **'Past end date'**
  String get partnerPromotionExpired;

  /// No description provided for @partnerPromotionScheduled.
  ///
  /// In en, this message translates to:
  /// **'Starts later'**
  String get partnerPromotionScheduled;

  /// No description provided for @partnerPromotionExclusivePill.
  ///
  /// In en, this message translates to:
  /// **'Does not combine'**
  String get partnerPromotionExclusivePill;

  /// No description provided for @partnerPromotionValidity.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String partnerPromotionValidity(String from, String to);

  /// No description provided for @partnerPromotionPriorityValue.
  ///
  /// In en, this message translates to:
  /// **'Priority {count}'**
  String partnerPromotionPriorityValue(String count);

  /// No description provided for @partnerPromotionHasConditions.
  ///
  /// In en, this message translates to:
  /// **'Has conditions'**
  String get partnerPromotionHasConditions;

  /// No description provided for @partnerPromotionActivateAction.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get partnerPromotionActivateAction;

  /// No description provided for @partnerPromotionDeactivateAction.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get partnerPromotionDeactivateAction;

  /// No description provided for @partnerPromotionTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get partnerPromotionTypeGeneral;

  /// No description provided for @partnerPromotionTypeRoom.
  ///
  /// In en, this message translates to:
  /// **'Room offer'**
  String get partnerPromotionTypeRoom;

  /// No description provided for @partnerPromotionTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Property offer'**
  String get partnerPromotionTypeHotel;

  /// No description provided for @partnerPromotionTypeMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get partnerPromotionTypeMember;

  /// No description provided for @partnerPromotionTypeEarlyBird.
  ///
  /// In en, this message translates to:
  /// **'Early bird'**
  String get partnerPromotionTypeEarlyBird;

  /// No description provided for @partnerPromotionTypeLastMinute.
  ///
  /// In en, this message translates to:
  /// **'Last minute'**
  String get partnerPromotionTypeLastMinute;

  /// No description provided for @partnerPromotionTypeWeekend.
  ///
  /// In en, this message translates to:
  /// **'Weekend'**
  String get partnerPromotionTypeWeekend;

  /// No description provided for @partnerPromotionTypeHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get partnerPromotionTypeHoliday;

  /// No description provided for @partnerPromotionTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised type'**
  String get partnerPromotionTypeUnknown;

  /// No description provided for @partnerDiscountTypePercentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get partnerDiscountTypePercentage;

  /// No description provided for @partnerDiscountTypeFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed amount'**
  String get partnerDiscountTypeFixed;

  /// No description provided for @partnerDiscountTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised discount'**
  String get partnerDiscountTypeUnknown;

  /// No description provided for @partnerPromotionTargetAll.
  ///
  /// In en, this message translates to:
  /// **'Every property on Plan Your Trip'**
  String get partnerPromotionTargetAll;

  /// No description provided for @partnerPromotionTargetHotel.
  ///
  /// In en, this message translates to:
  /// **'One of your properties'**
  String get partnerPromotionTargetHotel;

  /// No description provided for @partnerPromotionTargetRoom.
  ///
  /// In en, this message translates to:
  /// **'One of your rooms'**
  String get partnerPromotionTargetRoom;

  /// No description provided for @partnerPromotionTargetRoomNamed.
  ///
  /// In en, this message translates to:
  /// **'Room: {name}'**
  String partnerPromotionTargetRoomNamed(String name);

  /// No description provided for @partnerPromotionTargetUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised target'**
  String get partnerPromotionTargetUnknown;

  /// No description provided for @partnerPromotionPreviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Pricing preview'**
  String get partnerPromotionPreviewHeading;

  /// No description provided for @partnerPromotionPreviewNote.
  ///
  /// In en, this message translates to:
  /// **'The backend calculates this. Every amount and every applied promotion comes straight from the pricing engine — nothing is worked out in the app.'**
  String get partnerPromotionPreviewNote;

  /// No description provided for @partnerPromotionPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Run preview'**
  String get partnerPromotionPreviewAction;

  /// No description provided for @partnerPromotionPreviewInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'Check-out must be after check-in.'**
  String get partnerPromotionPreviewInvalidRange;

  /// No description provided for @partnerPromotionPreviewStay.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to} · {nights} nights'**
  String partnerPromotionPreviewStay(String from, String to, String nights);

  /// No description provided for @partnerPromotionPreviewBase.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get partnerPromotionPreviewBase;

  /// No description provided for @partnerPromotionPreviewRatePlan.
  ///
  /// In en, this message translates to:
  /// **'Rate plan price'**
  String get partnerPromotionPreviewRatePlan;

  /// No description provided for @partnerPromotionPreviewRatePlanNamed.
  ///
  /// In en, this message translates to:
  /// **'Rate plan: {name}'**
  String partnerPromotionPreviewRatePlanNamed(String name);

  /// No description provided for @partnerPromotionPreviewDiscount.
  ///
  /// In en, this message translates to:
  /// **'Promotion discount'**
  String get partnerPromotionPreviewDiscount;

  /// No description provided for @partnerPromotionPreviewTotal.
  ///
  /// In en, this message translates to:
  /// **'Total for this stay'**
  String get partnerPromotionPreviewTotal;

  /// No description provided for @partnerPromotionPreviewAppliedHeading.
  ///
  /// In en, this message translates to:
  /// **'Promotions the engine applied'**
  String get partnerPromotionPreviewAppliedHeading;

  /// No description provided for @partnerPromotionPreviewNoneApplied.
  ///
  /// In en, this message translates to:
  /// **'The engine applied no promotion to this stay.'**
  String get partnerPromotionPreviewNoneApplied;

  /// No description provided for @partnerPromotionPreviewUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Unnamed promotion'**
  String get partnerPromotionPreviewUnnamed;

  /// No description provided for @partnerPromotionPreviewAppliedAmount.
  ///
  /// In en, this message translates to:
  /// **'-{amount}'**
  String partnerPromotionPreviewAppliedAmount(String amount);

  /// No description provided for @partnerPromotionActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now active.'**
  String partnerPromotionActivatedMessage(String name);

  /// No description provided for @partnerPromotionDeactivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'{name} is now inactive.'**
  String partnerPromotionDeactivatedMessage(String name);

  /// No description provided for @partnerPromotionActionNotFound.
  ///
  /// In en, this message translates to:
  /// **'That promotion is no longer available to your account.'**
  String get partnerPromotionActionNotFound;

  /// No description provided for @partnerPromotionActionConflict.
  ///
  /// In en, this message translates to:
  /// **'That promotion code is already in use. Promotion codes are unique across Plan Your Trip.'**
  String get partnerPromotionActionConflict;

  /// No description provided for @partnerPromotionActionValidation.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the promotion. Nothing was changed.'**
  String get partnerPromotionActionValidation;

  /// No description provided for @partnerPromotionActionIncomplete.
  ///
  /// In en, this message translates to:
  /// **'This promotion is missing fields the update needs, so nothing was sent. Ask support to change it.'**
  String get partnerPromotionActionIncomplete;

  /// No description provided for @partnerVoucherCheckHeading.
  ///
  /// In en, this message translates to:
  /// **'Check a booking voucher'**
  String get partnerVoucherCheckHeading;

  /// No description provided for @partnerVoucherCheckNote.
  ///
  /// In en, this message translates to:
  /// **'This is a booking pass, not a discount code. Checking it confirms a guest\'s booking — it does not check anyone in and changes nothing.'**
  String get partnerVoucherCheckNote;

  /// No description provided for @partnerVoucherCheckField.
  ///
  /// In en, this message translates to:
  /// **'Voucher payload'**
  String get partnerVoucherCheckField;

  /// No description provided for @partnerVoucherCheckAction.
  ///
  /// In en, this message translates to:
  /// **'Check voucher'**
  String get partnerVoucherCheckAction;

  /// No description provided for @partnerVoucherCheckClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get partnerVoucherCheckClear;

  /// No description provided for @partnerVoucherEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Valid — the guest can be admitted'**
  String get partnerVoucherEligibleTitle;

  /// No description provided for @partnerVoucherEligibleMessage.
  ///
  /// In en, this message translates to:
  /// **'The signature is valid and this booking is ready for check-in.'**
  String get partnerVoucherEligibleMessage;

  /// No description provided for @partnerVoucherNotEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Valid — but not ready for check-in'**
  String get partnerVoucherNotEligibleTitle;

  /// No description provided for @partnerVoucherNotEligibleMessage.
  ///
  /// In en, this message translates to:
  /// **'The signature is valid, but this booking cannot be checked in right now.'**
  String get partnerVoucherNotEligibleMessage;

  /// No description provided for @partnerVoucherNotRecognisedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not recognised'**
  String get partnerVoucherNotRecognisedTitle;

  /// No description provided for @partnerVoucherNotRecognisedMessage.
  ///
  /// In en, this message translates to:
  /// **'The server does not recognise this voucher for your account. It may have been altered, may not exist, or may belong to another partner — the server does not say which.'**
  String get partnerVoucherNotRecognisedMessage;

  /// No description provided for @partnerVoucherEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to check'**
  String get partnerVoucherEmptyTitle;

  /// No description provided for @partnerVoucherEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Paste or scan a voucher payload first.'**
  String get partnerVoucherEmptyMessage;

  /// No description provided for @partnerVoucherFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not check this voucher'**
  String get partnerVoucherFailedTitle;

  /// No description provided for @partnerVoucherFieldBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get partnerVoucherFieldBooking;

  /// No description provided for @partnerVoucherFieldBookingStatus.
  ///
  /// In en, this message translates to:
  /// **'Booking status'**
  String get partnerVoucherFieldBookingStatus;

  /// No description provided for @partnerVoucherFieldGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest name'**
  String get partnerVoucherFieldGuest;

  /// No description provided for @partnerVoucherFieldProperty.
  ///
  /// In en, this message translates to:
  /// **'Booked property'**
  String get partnerVoucherFieldProperty;

  /// No description provided for @partnerVoucherFieldRoom.
  ///
  /// In en, this message translates to:
  /// **'Booked room'**
  String get partnerVoucherFieldRoom;

  /// No description provided for @partnerVoucherFieldStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get partnerVoucherFieldStay;

  /// No description provided for @partnerVoucherFieldOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get partnerVoucherFieldOccupancy;

  /// No description provided for @partnerVoucherStayValue.
  ///
  /// In en, this message translates to:
  /// **'{from} to {to} · {nights} nights'**
  String partnerVoucherStayValue(String from, String to, String nights);

  /// No description provided for @partnerVoucherOccupancyValue.
  ///
  /// In en, this message translates to:
  /// **'{adults} adults · {children} children'**
  String partnerVoucherOccupancyValue(String adults, String children);

  /// No description provided for @partnerVoucherReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Checking only. Check-in itself happens on the booking, not on this screen.'**
  String get partnerVoucherReadOnlyNote;

  /// No description provided for @partnerBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings & front desk'**
  String get partnerBookingsTitle;

  /// No description provided for @partnerBookingsTabReservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get partnerBookingsTabReservations;

  /// No description provided for @partnerBookingsTabFrontDesk.
  ///
  /// In en, this message translates to:
  /// **'Front desk'**
  String get partnerBookingsTabFrontDesk;

  /// No description provided for @partnerBookingsScopeNote.
  ///
  /// In en, this message translates to:
  /// **'This list covers every booking across all properties you own. The partner API accepts no property parameter, so it is not narrowed by your selected property — filter by room to focus on one property.'**
  String get partnerBookingsScopeNote;

  /// No description provided for @partnerBookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get partnerBookingsEmptyTitle;

  /// No description provided for @partnerBookingsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been booked at your properties yet. New reservations appear here as soon as guests make them.'**
  String get partnerBookingsEmptyMessage;

  /// No description provided for @partnerBookingsNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings match these filters'**
  String get partnerBookingsNoMatchTitle;

  /// No description provided for @partnerBookingsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing matched the filters you set. Clear them to see every booking again.'**
  String get partnerBookingsNoMatchMessage;

  /// No description provided for @partnerBookingDetailHeading.
  ///
  /// In en, this message translates to:
  /// **'Booking details'**
  String get partnerBookingDetailHeading;

  /// No description provided for @partnerBookingCloseDetail.
  ///
  /// In en, this message translates to:
  /// **'Close booking details'**
  String get partnerBookingCloseDetail;

  /// No description provided for @partnerBookingNotFound.
  ///
  /// In en, this message translates to:
  /// **'That booking is no longer available to your account.'**
  String get partnerBookingNotFound;

  /// No description provided for @partnerBookingColumnCode.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get partnerBookingColumnCode;

  /// No description provided for @partnerBookingColumnGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get partnerBookingColumnGuest;

  /// No description provided for @partnerBookingColumnRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get partnerBookingColumnRoom;

  /// No description provided for @partnerBookingColumnCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get partnerBookingColumnCheckIn;

  /// No description provided for @partnerBookingColumnCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get partnerBookingColumnCheckOut;

  /// No description provided for @partnerBookingColumnNights.
  ///
  /// In en, this message translates to:
  /// **'Nights'**
  String get partnerBookingColumnNights;

  /// No description provided for @partnerBookingColumnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get partnerBookingColumnStatus;

  /// No description provided for @partnerBookingColumnTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get partnerBookingColumnTotal;

  /// No description provided for @partnerBookingStayRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String partnerBookingStayRange(String from, String to);

  /// No description provided for @partnerBookingNightsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} nights'**
  String partnerBookingNightsValue(String count);

  /// No description provided for @partnerBookingOccupancyValue.
  ///
  /// In en, this message translates to:
  /// **'{adults} adults · {children} children'**
  String partnerBookingOccupancyValue(String adults, String children);

  /// No description provided for @partnerBookingNightProgressValue.
  ///
  /// In en, this message translates to:
  /// **'Night {current} of {total}'**
  String partnerBookingNightProgressValue(String current, String total);

  /// No description provided for @partnerBookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get partnerBookingStatusPending;

  /// No description provided for @partnerBookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get partnerBookingStatusConfirmed;

  /// No description provided for @partnerBookingStatusCheckInReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to check in'**
  String get partnerBookingStatusCheckInReady;

  /// No description provided for @partnerBookingStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get partnerBookingStatusCheckedIn;

  /// No description provided for @partnerBookingStatusCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get partnerBookingStatusCheckedOut;

  /// No description provided for @partnerBookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get partnerBookingStatusCompleted;

  /// No description provided for @partnerBookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get partnerBookingStatusCancelled;

  /// No description provided for @partnerBookingStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get partnerBookingStatusRefunded;

  /// No description provided for @partnerBookingStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get partnerBookingStatusArchived;

  /// No description provided for @partnerBookingStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No-show'**
  String get partnerBookingStatusNoShow;

  /// No description provided for @partnerBookingStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised status'**
  String get partnerBookingStatusUnknown;

  /// No description provided for @partnerStayStateUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming stay'**
  String get partnerStayStateUpcoming;

  /// No description provided for @partnerStayStateReady.
  ///
  /// In en, this message translates to:
  /// **'Ready for check-in'**
  String get partnerStayStateReady;

  /// No description provided for @partnerStayStateInHouse.
  ///
  /// In en, this message translates to:
  /// **'In house'**
  String get partnerStayStateInHouse;

  /// No description provided for @partnerStayStateCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Departed'**
  String get partnerStayStateCheckedOut;

  /// No description provided for @partnerStayStateCompleted.
  ///
  /// In en, this message translates to:
  /// **'Stay completed'**
  String get partnerStayStateCompleted;

  /// No description provided for @partnerStayStateCancelled.
  ///
  /// In en, this message translates to:
  /// **'Stay cancelled'**
  String get partnerStayStateCancelled;

  /// No description provided for @partnerStayStateNoShow.
  ///
  /// In en, this message translates to:
  /// **'Guest did not arrive'**
  String get partnerStayStateNoShow;

  /// No description provided for @partnerStayStateExpired.
  ///
  /// In en, this message translates to:
  /// **'Window passed'**
  String get partnerStayStateExpired;

  /// No description provided for @partnerStayStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised stay state'**
  String get partnerStayStateUnknown;

  /// No description provided for @partnerStayWarningCancelled.
  ///
  /// In en, this message translates to:
  /// **'This stay was cancelled, refunded, or recorded as a no-show.'**
  String get partnerStayWarningCancelled;

  /// No description provided for @partnerStayWarningCompleted.
  ///
  /// In en, this message translates to:
  /// **'This stay is finished.'**
  String get partnerStayWarningCompleted;

  /// No description provided for @partnerStayWarningInHouse.
  ///
  /// In en, this message translates to:
  /// **'The guest is currently staying.'**
  String get partnerStayWarningInHouse;

  /// No description provided for @partnerStayWarningCheckOutOverdue.
  ///
  /// In en, this message translates to:
  /// **'Check-out is overdue — the departure date has passed and the guest is still checked in.'**
  String get partnerStayWarningCheckOutOverdue;

  /// No description provided for @partnerStayWarningFuture.
  ///
  /// In en, this message translates to:
  /// **'The stay has not started yet.'**
  String get partnerStayWarningFuture;

  /// No description provided for @partnerStayWarningCheckInOverdue.
  ///
  /// In en, this message translates to:
  /// **'Check-in is overdue — the arrival date has passed and the guest is not checked in.'**
  String get partnerStayWarningCheckInOverdue;

  /// No description provided for @partnerStayWarningUnknown.
  ///
  /// In en, this message translates to:
  /// **'The server reported a warning this app does not recognise.'**
  String get partnerStayWarningUnknown;

  /// No description provided for @partnerBookingFilterGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest name or email'**
  String get partnerBookingFilterGuest;

  /// No description provided for @partnerBookingFilterCode.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get partnerBookingFilterCode;

  /// No description provided for @partnerBookingFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Booking status'**
  String get partnerBookingFilterStatus;

  /// No description provided for @partnerBookingFilterAnyStatus.
  ///
  /// In en, this message translates to:
  /// **'Any status'**
  String get partnerBookingFilterAnyStatus;

  /// No description provided for @partnerBookingFilterRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get partnerBookingFilterRoom;

  /// No description provided for @partnerBookingFilterAnyRoom.
  ///
  /// In en, this message translates to:
  /// **'Any room'**
  String get partnerBookingFilterAnyRoom;

  /// No description provided for @partnerBookingFilterDates.
  ///
  /// In en, this message translates to:
  /// **'Arrival dates'**
  String get partnerBookingFilterDates;

  /// No description provided for @partnerBookingFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get partnerBookingFilterClear;

  /// No description provided for @partnerBookingFilterArrivals.
  ///
  /// In en, this message translates to:
  /// **'Arriving today'**
  String get partnerBookingFilterArrivals;

  /// No description provided for @partnerBookingFilterDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departing today'**
  String get partnerBookingFilterDepartures;

  /// No description provided for @partnerBookingFilterUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get partnerBookingFilterUpcoming;

  /// No description provided for @partnerBookingFilterInHouse.
  ///
  /// In en, this message translates to:
  /// **'In house'**
  String get partnerBookingFilterInHouse;

  /// No description provided for @partnerBookingFilterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get partnerBookingFilterCancelled;

  /// No description provided for @partnerBookingFilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get partnerBookingFilterCompleted;

  /// No description provided for @partnerBookingFilterRangeBoth.
  ///
  /// In en, this message translates to:
  /// **'Arriving {from} to {to}'**
  String partnerBookingFilterRangeBoth(String from, String to);

  /// No description provided for @partnerBookingFilterRangeFrom.
  ///
  /// In en, this message translates to:
  /// **'Arriving on or after {from}'**
  String partnerBookingFilterRangeFrom(String from);

  /// No description provided for @partnerBookingFilterRangeTo.
  ///
  /// In en, this message translates to:
  /// **'Arriving on or before {to}'**
  String partnerBookingFilterRangeTo(String to);

  /// No description provided for @partnerBookingPageRange.
  ///
  /// In en, this message translates to:
  /// **'Showing {from}-{to} of {total}'**
  String partnerBookingPageRange(String from, String to, String total);

  /// No description provided for @partnerBookingPagePosition.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String partnerBookingPagePosition(String page, String total);

  /// No description provided for @partnerBookingPagePrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get partnerBookingPagePrevious;

  /// No description provided for @partnerBookingPageNext.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get partnerBookingPageNext;

  /// No description provided for @partnerBookingSectionGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get partnerBookingSectionGuest;

  /// No description provided for @partnerBookingSectionStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get partnerBookingSectionStay;

  /// No description provided for @partnerBookingSectionRoom.
  ///
  /// In en, this message translates to:
  /// **'Property & room'**
  String get partnerBookingSectionRoom;

  /// No description provided for @partnerBookingSectionPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get partnerBookingSectionPrice;

  /// No description provided for @partnerBookingSectionRatePlan.
  ///
  /// In en, this message translates to:
  /// **'Rate plan captured at booking'**
  String get partnerBookingSectionRatePlan;

  /// No description provided for @partnerBookingSectionPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment & invoice'**
  String get partnerBookingSectionPayment;

  /// No description provided for @partnerBookingSectionTimeline.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle timeline'**
  String get partnerBookingSectionTimeline;

  /// No description provided for @partnerBookingSectionModifications.
  ///
  /// In en, this message translates to:
  /// **'Change history'**
  String get partnerBookingSectionModifications;

  /// No description provided for @partnerBookingSectionAudit.
  ///
  /// In en, this message translates to:
  /// **'Check-in & check-out record'**
  String get partnerBookingSectionAudit;

  /// No description provided for @partnerBookingFieldGuestName.
  ///
  /// In en, this message translates to:
  /// **'Guest name'**
  String get partnerBookingFieldGuestName;

  /// No description provided for @partnerBookingFieldGuestEmail.
  ///
  /// In en, this message translates to:
  /// **'Guest email'**
  String get partnerBookingFieldGuestEmail;

  /// No description provided for @partnerBookingFieldOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get partnerBookingFieldOccupancy;

  /// No description provided for @partnerBookingFieldSpecialRequest.
  ///
  /// In en, this message translates to:
  /// **'Special request'**
  String get partnerBookingFieldSpecialRequest;

  /// No description provided for @partnerBookingFieldCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in date'**
  String get partnerBookingFieldCheckIn;

  /// No description provided for @partnerBookingFieldCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out date'**
  String get partnerBookingFieldCheckOut;

  /// No description provided for @partnerBookingFieldNights.
  ///
  /// In en, this message translates to:
  /// **'Nights booked'**
  String get partnerBookingFieldNights;

  /// No description provided for @partnerBookingFieldNightProgress.
  ///
  /// In en, this message translates to:
  /// **'Stay progress'**
  String get partnerBookingFieldNightProgress;

  /// No description provided for @partnerBookingFieldActualCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Actually checked in'**
  String get partnerBookingFieldActualCheckIn;

  /// No description provided for @partnerBookingFieldActualCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Actually checked out'**
  String get partnerBookingFieldActualCheckOut;

  /// No description provided for @partnerBookingFieldProperty.
  ///
  /// In en, this message translates to:
  /// **'Booked property'**
  String get partnerBookingFieldProperty;

  /// No description provided for @partnerBookingFieldRoom.
  ///
  /// In en, this message translates to:
  /// **'Booked room'**
  String get partnerBookingFieldRoom;

  /// No description provided for @partnerBookingFieldRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Room code'**
  String get partnerBookingFieldRoomCode;

  /// No description provided for @partnerBookingFieldRoomCount.
  ///
  /// In en, this message translates to:
  /// **'Rooms booked'**
  String get partnerBookingFieldRoomCount;

  /// No description provided for @partnerBookingFieldBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get partnerBookingFieldBasePrice;

  /// No description provided for @partnerBookingFieldRatePlanPrice.
  ///
  /// In en, this message translates to:
  /// **'Rate plan price'**
  String get partnerBookingFieldRatePlanPrice;

  /// No description provided for @partnerBookingFieldDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount applied'**
  String get partnerBookingFieldDiscount;

  /// No description provided for @partnerBookingFieldTotal.
  ///
  /// In en, this message translates to:
  /// **'Total charged'**
  String get partnerBookingFieldTotal;

  /// No description provided for @partnerBookingPriceNote.
  ///
  /// In en, this message translates to:
  /// **'Every amount here was calculated and stored by the backend when the booking was made. Nothing is recalculated in this app.'**
  String get partnerBookingPriceNote;

  /// No description provided for @partnerBookingFieldRatePlanName.
  ///
  /// In en, this message translates to:
  /// **'Rate plan'**
  String get partnerBookingFieldRatePlanName;

  /// No description provided for @partnerBookingFieldRatePlanCode.
  ///
  /// In en, this message translates to:
  /// **'Rate plan code'**
  String get partnerBookingFieldRatePlanCode;

  /// No description provided for @partnerBookingFieldMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Meal plan'**
  String get partnerBookingFieldMealPlan;

  /// No description provided for @partnerBookingFieldCancellationPolicy.
  ///
  /// In en, this message translates to:
  /// **'Cancellation policy'**
  String get partnerBookingFieldCancellationPolicy;

  /// No description provided for @partnerBookingFieldCancellationDeadline.
  ///
  /// In en, this message translates to:
  /// **'Free-cancellation deadline'**
  String get partnerBookingFieldCancellationDeadline;

  /// No description provided for @partnerBookingFieldRefundable.
  ///
  /// In en, this message translates to:
  /// **'Refundable'**
  String get partnerBookingFieldRefundable;

  /// No description provided for @partnerBookingFieldNightlySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Nightly rate captured'**
  String get partnerBookingFieldNightlySnapshot;

  /// No description provided for @partnerBookingSnapshotNote.
  ///
  /// In en, this message translates to:
  /// **'These values were captured when the booking was made. Editing a rate plan today does not change them.'**
  String get partnerBookingSnapshotNote;

  /// No description provided for @partnerBookingNoPayments.
  ///
  /// In en, this message translates to:
  /// **'No payment has been recorded against this booking.'**
  String get partnerBookingNoPayments;

  /// No description provided for @partnerBookingPaymentUnnamed.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get partnerBookingPaymentUnnamed;

  /// No description provided for @partnerBookingFieldInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice number'**
  String get partnerBookingFieldInvoice;

  /// No description provided for @partnerBookingFieldInvoiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Invoice status'**
  String get partnerBookingFieldInvoiceStatus;

  /// No description provided for @partnerBookingFieldInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Invoice total'**
  String get partnerBookingFieldInvoiceTotal;

  /// No description provided for @partnerBookingPaymentReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'Payment details are read-only. The partner API offers no payment, refund, or settlement action, and card and gateway identifiers are never sent to this screen.'**
  String get partnerBookingPaymentReadOnlyNote;

  /// No description provided for @partnerBookingTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'The server recorded no lifecycle events for this booking.'**
  String get partnerBookingTimelineEmpty;

  /// No description provided for @partnerBookingEventCreated.
  ///
  /// In en, this message translates to:
  /// **'Booking created'**
  String get partnerBookingEventCreated;

  /// No description provided for @partnerBookingEventPaid.
  ///
  /// In en, this message translates to:
  /// **'Payment completed'**
  String get partnerBookingEventPaid;

  /// No description provided for @partnerBookingEventConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking confirmed'**
  String get partnerBookingEventConfirmed;

  /// No description provided for @partnerBookingEventCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Guest checked in'**
  String get partnerBookingEventCheckedIn;

  /// No description provided for @partnerBookingEventCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Guest checked out'**
  String get partnerBookingEventCheckedOut;

  /// No description provided for @partnerBookingEventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reservation completed'**
  String get partnerBookingEventCompleted;

  /// No description provided for @partnerBookingEventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get partnerBookingEventCancelled;

  /// No description provided for @partnerBookingEventArchived.
  ///
  /// In en, this message translates to:
  /// **'Reservation archived'**
  String get partnerBookingEventArchived;

  /// No description provided for @partnerBookingEventModified.
  ///
  /// In en, this message translates to:
  /// **'Booking changed'**
  String get partnerBookingEventModified;

  /// No description provided for @partnerBookingEventReview.
  ///
  /// In en, this message translates to:
  /// **'Guest submitted a review'**
  String get partnerBookingEventReview;

  /// No description provided for @partnerBookingModificationNote.
  ///
  /// In en, this message translates to:
  /// **'Guests change their own bookings. This is the record of what changed — the partner API offers no way to change a booking from here.'**
  String get partnerBookingModificationNote;

  /// No description provided for @partnerBookingModificationDates.
  ///
  /// In en, this message translates to:
  /// **'Dates'**
  String get partnerBookingModificationDates;

  /// No description provided for @partnerBookingModificationOccupancy.
  ///
  /// In en, this message translates to:
  /// **'Occupancy'**
  String get partnerBookingModificationOccupancy;

  /// No description provided for @partnerBookingModificationRatePlan.
  ///
  /// In en, this message translates to:
  /// **'Rate plan'**
  String get partnerBookingModificationRatePlan;

  /// No description provided for @partnerBookingModificationPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get partnerBookingModificationPrice;

  /// No description provided for @partnerBookingNoAudit.
  ///
  /// In en, this message translates to:
  /// **'No check-in or check-out has been recorded for this booking.'**
  String get partnerBookingNoAudit;

  /// No description provided for @partnerBookingAuditCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in recorded'**
  String get partnerBookingAuditCheckIn;

  /// No description provided for @partnerBookingAuditCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out recorded'**
  String get partnerBookingAuditCheckOut;

  /// No description provided for @partnerBookingAuditByUser.
  ///
  /// In en, this message translates to:
  /// **'Staff #{userId}'**
  String partnerBookingAuditByUser(String userId);

  /// No description provided for @partnerBookingActionCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get partnerBookingActionCheckIn;

  /// No description provided for @partnerBookingActionCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check out'**
  String get partnerBookingActionCheckOut;

  /// No description provided for @partnerBookingActionNoShow.
  ///
  /// In en, this message translates to:
  /// **'Mark as no-show'**
  String get partnerBookingActionNoShow;

  /// No description provided for @partnerBookingActionComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete reservation'**
  String get partnerBookingActionComplete;

  /// No description provided for @partnerBookingActionsIrreversibleNote.
  ///
  /// In en, this message translates to:
  /// **'These changes cannot be undone from the extranet, and the guest is notified.'**
  String get partnerBookingActionsIrreversibleNote;

  /// No description provided for @partnerBookingNoActionsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No operational action is available for this booking\'s current status.'**
  String get partnerBookingNoActionsAvailable;

  /// No description provided for @partnerBookingNoActionsClosed.
  ///
  /// In en, this message translates to:
  /// **'This booking is closed, so no operational action remains.'**
  String get partnerBookingNoActionsClosed;

  /// No description provided for @partnerBookingActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'{action} for booking {code}? This cannot be undone from the extranet, and the guest is notified.'**
  String partnerBookingActionConfirm(String action, String code);

  /// No description provided for @partnerBookingActionConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get partnerBookingActionConfirmCta;

  /// No description provided for @partnerBookingActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get partnerBookingActionCancel;

  /// No description provided for @partnerBookingActionSucceeded.
  ///
  /// In en, this message translates to:
  /// **'{action} completed for booking {code}.'**
  String partnerBookingActionSucceeded(String action, String code);

  /// No description provided for @partnerBookingActionRejected.
  ///
  /// In en, this message translates to:
  /// **'The server refused that change for this booking\'s current status. Nothing was altered.'**
  String get partnerBookingActionRejected;

  /// No description provided for @partnerBookingActionValidation.
  ///
  /// In en, this message translates to:
  /// **'The server rejected that request. Nothing was altered.'**
  String get partnerBookingActionValidation;

  /// No description provided for @partnerBookingActionUncertain.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before the server confirmed, and this change cannot be undone. Refresh to see the current status before trying again.'**
  String get partnerBookingActionUncertain;

  /// No description provided for @partnerFrontDeskHeading.
  ///
  /// In en, this message translates to:
  /// **'Check a guest in or out'**
  String get partnerFrontDeskHeading;

  /// No description provided for @partnerFrontDeskNote.
  ///
  /// In en, this message translates to:
  /// **'Scan the guest\'s voucher QR or type their booking code. This changes the booking and notifies the guest.'**
  String get partnerFrontDeskNote;

  /// No description provided for @partnerFrontDeskField.
  ///
  /// In en, this message translates to:
  /// **'Voucher payload or booking code'**
  String get partnerFrontDeskField;

  /// No description provided for @partnerFrontDeskFieldHelp.
  ///
  /// In en, this message translates to:
  /// **'A scanned voucher is recorded as a QR scan; a typed booking code is recorded as manual.'**
  String get partnerFrontDeskFieldHelp;

  /// No description provided for @partnerFrontDeskCheckInAction.
  ///
  /// In en, this message translates to:
  /// **'Check guest in'**
  String get partnerFrontDeskCheckInAction;

  /// No description provided for @partnerFrontDeskCheckOutAction.
  ///
  /// In en, this message translates to:
  /// **'Check guest out'**
  String get partnerFrontDeskCheckOutAction;

  /// No description provided for @partnerFrontDeskClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get partnerFrontDeskClear;

  /// No description provided for @partnerFrontDeskConfirm.
  ///
  /// In en, this message translates to:
  /// **'Proceed for {code}? This changes the booking, notifies the guest, and cannot be undone from the extranet.'**
  String partnerFrontDeskConfirm(String code);

  /// No description provided for @partnerFrontDeskCheckedInTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest checked in'**
  String get partnerFrontDeskCheckedInTitle;

  /// No description provided for @partnerFrontDeskCheckedOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest checked out'**
  String get partnerFrontDeskCheckedOutTitle;

  /// No description provided for @partnerFrontDeskIdempotentNote.
  ///
  /// In en, this message translates to:
  /// **'Repeating this on the same booking is safe: the server keeps the original time and records nothing twice.'**
  String get partnerFrontDeskIdempotentNote;

  /// No description provided for @partnerFrontDeskNotRecognisedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not recognised'**
  String get partnerFrontDeskNotRecognisedTitle;

  /// No description provided for @partnerFrontDeskNotRecognisedMessage.
  ///
  /// In en, this message translates to:
  /// **'The server does not recognise that voucher or booking code for your account. It may have been altered, may not exist, or may belong to another partner — the server does not say which.'**
  String get partnerFrontDeskNotRecognisedMessage;

  /// No description provided for @partnerFrontDeskRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot do that yet'**
  String get partnerFrontDeskRejectedTitle;

  /// No description provided for @partnerFrontDeskRejectedMessage.
  ///
  /// In en, this message translates to:
  /// **'This booking\'s status or dates do not allow that right now. Nothing was changed.'**
  String get partnerFrontDeskRejectedMessage;

  /// No description provided for @partnerFrontDeskInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to submit'**
  String get partnerFrontDeskInvalidTitle;

  /// No description provided for @partnerFrontDeskInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'Scan or type a voucher payload or booking code first.'**
  String get partnerFrontDeskInvalidMessage;

  /// No description provided for @partnerFrontDeskFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not complete this'**
  String get partnerFrontDeskFailedTitle;

  /// No description provided for @partnerFrontDeskUncertainTitle.
  ///
  /// In en, this message translates to:
  /// **'Outcome unknown'**
  String get partnerFrontDeskUncertainTitle;

  /// No description provided for @partnerFrontDeskUncertainMessage.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before the server confirmed. Check the booking\'s status — running this again is safe if it did not go through.'**
  String get partnerFrontDeskUncertainMessage;

  /// No description provided for @partnerCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar & inventory'**
  String get partnerCalendarTitle;

  /// No description provided for @partnerCalendarTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Property calendar'**
  String get partnerCalendarTabOverview;

  /// No description provided for @partnerCalendarTabInventory.
  ///
  /// In en, this message translates to:
  /// **'Room inventory'**
  String get partnerCalendarTabInventory;

  /// No description provided for @partnerCalendarScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Every room in the selected property, night by night. The figures come from the same inventory records the Room inventory tab edits — this view only reads them.'**
  String get partnerCalendarScopeNote;

  /// No description provided for @partnerCalendarWindowRange.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String partnerCalendarWindowRange(String from, String to);

  /// No description provided for @partnerCalendarPreviousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get partnerCalendarPreviousWeek;

  /// No description provided for @partnerCalendarNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get partnerCalendarNextWeek;

  /// No description provided for @partnerCalendarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get partnerCalendarToday;

  /// No description provided for @partnerCalendarNoRoomsTitle.
  ///
  /// In en, this message translates to:
  /// **'This property has no rooms'**
  String get partnerCalendarNoRoomsTitle;

  /// No description provided for @partnerCalendarNoRoomsMessage.
  ///
  /// In en, this message translates to:
  /// **'There is nothing to schedule until the property has at least one room. Rooms are managed in the Rooms module.'**
  String get partnerCalendarNoRoomsMessage;

  /// No description provided for @partnerCalendarWindowEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No inventory records exist for any room in these dates. Nights without a record cannot be sold, because the availability check counts records and rejects a stay when any night is missing.'**
  String get partnerCalendarWindowEmptyMessage;

  /// No description provided for @partnerCalendarRoomsFailed.
  ///
  /// In en, this message translates to:
  /// **'{failed} of {total} room calendars could not be loaded. Those rows are shown as unavailable to read, not as empty.'**
  String partnerCalendarRoomsFailed(String failed, String total);

  /// No description provided for @partnerCalendarRoomFailed.
  ///
  /// In en, this message translates to:
  /// **'{room} could not be loaded.'**
  String partnerCalendarRoomFailed(String room);

  /// No description provided for @partnerCalendarStateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open for sale'**
  String get partnerCalendarStateOpen;

  /// No description provided for @partnerCalendarStateSoldOut.
  ///
  /// In en, this message translates to:
  /// **'Nothing left'**
  String get partnerCalendarStateSoldOut;

  /// No description provided for @partnerCalendarStateStopSell.
  ///
  /// In en, this message translates to:
  /// **'Stop sell'**
  String get partnerCalendarStateStopSell;

  /// No description provided for @partnerCalendarStateNoRecord.
  ///
  /// In en, this message translates to:
  /// **'No record'**
  String get partnerCalendarStateNoRecord;

  /// No description provided for @partnerCalendarLegendHeading.
  ///
  /// In en, this message translates to:
  /// **'What each night shows'**
  String get partnerCalendarLegendHeading;

  /// No description provided for @partnerCalendarLegendClosedArrival.
  ///
  /// In en, this message translates to:
  /// **'Closed to arrival'**
  String get partnerCalendarLegendClosedArrival;

  /// No description provided for @partnerCalendarLegendClosedDeparture.
  ///
  /// In en, this message translates to:
  /// **'Closed to departure'**
  String get partnerCalendarLegendClosedDeparture;

  /// No description provided for @partnerCalendarLegendOccupied.
  ///
  /// In en, this message translates to:
  /// **'Rooms sold'**
  String get partnerCalendarLegendOccupied;

  /// No description provided for @partnerCalendarLegendNote.
  ///
  /// In en, this message translates to:
  /// **'The number on each night is rooms still available. Closed to arrival blocks a stay from starting that night; closed to departure blocks it from ending on that night. Neither stops the night being sold within a longer stay.'**
  String get partnerCalendarLegendNote;

  /// No description provided for @partnerCalendarSoldValue.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String partnerCalendarSoldValue(String count);

  /// No description provided for @partnerCalendarMetricSellable.
  ///
  /// In en, this message translates to:
  /// **'nights open for sale'**
  String get partnerCalendarMetricSellable;

  /// No description provided for @partnerCalendarMetricOccupied.
  ///
  /// In en, this message translates to:
  /// **'nights with rooms sold'**
  String get partnerCalendarMetricOccupied;

  /// No description provided for @partnerCalendarMetricRestricted.
  ///
  /// In en, this message translates to:
  /// **'nights with a restriction'**
  String get partnerCalendarMetricRestricted;

  /// No description provided for @partnerCalendarMetricMissing.
  ///
  /// In en, this message translates to:
  /// **'nights with no record'**
  String get partnerCalendarMetricMissing;

  /// No description provided for @partnerCalendarNightHeading.
  ///
  /// In en, this message translates to:
  /// **'{room} · {date}'**
  String partnerCalendarNightHeading(String room, String date);

  /// No description provided for @partnerCalendarCloseNight.
  ///
  /// In en, this message translates to:
  /// **'Close night details'**
  String get partnerCalendarCloseNight;

  /// No description provided for @partnerCalendarFieldAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get partnerCalendarFieldAvailable;

  /// No description provided for @partnerCalendarFieldSold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get partnerCalendarFieldSold;

  /// No description provided for @partnerCalendarFieldBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get partnerCalendarFieldBlocked;

  /// No description provided for @partnerCalendarFieldMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get partnerCalendarFieldMaintenance;

  /// No description provided for @partnerCalendarFieldTotal.
  ///
  /// In en, this message translates to:
  /// **'Total rooms'**
  String get partnerCalendarFieldTotal;

  /// No description provided for @partnerCalendarInconsistentMessage.
  ///
  /// In en, this message translates to:
  /// **'Available, sold, blocked and maintenance do not add up to the total for this night. The server\'s own numbers are shown unchanged.'**
  String get partnerCalendarInconsistentMessage;

  /// No description provided for @partnerCalendarNoRecordExplanation.
  ///
  /// In en, this message translates to:
  /// **'There is no inventory record for this night. That is not the same as being free: the availability check counts records, so any stay covering this night is rejected. Create the record in the Room inventory tab to make the night sellable.'**
  String get partnerCalendarNoRecordExplanation;

  /// No description provided for @partnerCalendarQuestionsHeading.
  ///
  /// In en, this message translates to:
  /// **'What this night allows'**
  String get partnerCalendarQuestionsHeading;

  /// No description provided for @partnerCalendarQuestionStock.
  ///
  /// In en, this message translates to:
  /// **'Rooms are left'**
  String get partnerCalendarQuestionStock;

  /// No description provided for @partnerCalendarQuestionSellable.
  ///
  /// In en, this message translates to:
  /// **'The night can be sold'**
  String get partnerCalendarQuestionSellable;

  /// No description provided for @partnerCalendarQuestionArrival.
  ///
  /// In en, this message translates to:
  /// **'A stay can start this night'**
  String get partnerCalendarQuestionArrival;

  /// No description provided for @partnerCalendarQuestionDeparture.
  ///
  /// In en, this message translates to:
  /// **'A stay can end with this night'**
  String get partnerCalendarQuestionDeparture;

  /// No description provided for @partnerCalendarQuestionsNote.
  ///
  /// In en, this message translates to:
  /// **'These are four separate checks the server makes, not one. A night can be sellable inside a longer stay while still refusing an arrival or a departure.'**
  String get partnerCalendarQuestionsNote;

  /// No description provided for @partnerCalendarReasonNoStock.
  ///
  /// In en, this message translates to:
  /// **'No rooms are left for this night.'**
  String get partnerCalendarReasonNoStock;

  /// No description provided for @partnerCalendarReasonStopSell.
  ///
  /// In en, this message translates to:
  /// **'Stop sell is on for this night.'**
  String get partnerCalendarReasonStopSell;

  /// No description provided for @partnerCalendarReasonNotSellable.
  ///
  /// In en, this message translates to:
  /// **'The night cannot be sold at all.'**
  String get partnerCalendarReasonNotSellable;

  /// No description provided for @partnerCalendarReasonClosedArrival.
  ///
  /// In en, this message translates to:
  /// **'Closed to arrival on this night.'**
  String get partnerCalendarReasonClosedArrival;

  /// No description provided for @partnerCalendarReasonClosedDeparture.
  ///
  /// In en, this message translates to:
  /// **'Closed to departure on this night.'**
  String get partnerCalendarReasonClosedDeparture;

  /// No description provided for @partnerCalendarReadOnlyNote.
  ///
  /// In en, this message translates to:
  /// **'This calendar only reads. Stop sell, closed to arrival and closed to departure are changed in the Room inventory tab, so one place owns every write.'**
  String get partnerCalendarReadOnlyNote;

  /// No description provided for @partnerCalendarManageRestrictions.
  ///
  /// In en, this message translates to:
  /// **'Open room inventory'**
  String get partnerCalendarManageRestrictions;

  /// No description provided for @partnerMetricWindow.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String partnerMetricWindow(String from, String to);

  /// No description provided for @partnerMetricAllProperties.
  ///
  /// In en, this message translates to:
  /// **'All properties'**
  String get partnerMetricAllProperties;

  /// No description provided for @partnerMetricChangeRange.
  ///
  /// In en, this message translates to:
  /// **'Change dates'**
  String get partnerMetricChangeRange;

  /// No description provided for @partnerMetricDefaultRange.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get partnerMetricDefaultRange;

  /// No description provided for @partnerMetricInvalidRange.
  ///
  /// In en, this message translates to:
  /// **'The start date must not be after the end date. The server rejects that range.'**
  String get partnerMetricInvalidRange;

  /// No description provided for @partnerMetricScopeNotFound.
  ///
  /// In en, this message translates to:
  /// **'That property is not available to your account.'**
  String get partnerMetricScopeNotFound;

  /// No description provided for @partnerMetricNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'This section has not been loaded.'**
  String get partnerMetricNotLoaded;

  /// No description provided for @partnerMetricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get partnerMetricUnavailable;

  /// No description provided for @partnerMetricSectionsFailed.
  ///
  /// In en, this message translates to:
  /// **'{count} section(s) could not be loaded. They are shown as unavailable, not as zero.'**
  String partnerMetricSectionsFailed(String count);

  /// No description provided for @partnerMetricPeakDay.
  ///
  /// In en, this message translates to:
  /// **'Highest day {date}, {value}'**
  String partnerMetricPeakDay(String date, String value);

  /// No description provided for @partnerFinanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance & settlement'**
  String get partnerFinanceTitle;

  /// No description provided for @partnerFinanceTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Revenue & commission'**
  String get partnerFinanceTabOverview;

  /// No description provided for @partnerFinanceTabRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get partnerFinanceTabRevenue;

  /// No description provided for @partnerFinanceTabSettlement.
  ///
  /// In en, this message translates to:
  /// **'Settlement & payouts'**
  String get partnerFinanceTabSettlement;

  /// No description provided for @partnerFinanceScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Figures cover every property you own. Select a property in the workspace to narrow them. Amounts are grouped numbers: the finance API sends no currency with them.'**
  String get partnerFinanceScopeAll;

  /// No description provided for @partnerFinanceScopeProperty.
  ///
  /// In en, this message translates to:
  /// **'Figures cover the selected property only. Amounts are grouped numbers: the finance API sends no currency with them.'**
  String get partnerFinanceScopeProperty;

  /// No description provided for @partnerFinanceEstimateNotice.
  ///
  /// In en, this message translates to:
  /// **'These are derived estimates, not a statement of account. The platform commission is a fixed rate applied by the server, the tax figure is indicative only, and settlement periods are calculated from booking revenue rather than read from a settlement ledger.'**
  String get partnerFinanceEstimateNotice;

  /// No description provided for @partnerFinanceNoData.
  ///
  /// In en, this message translates to:
  /// **'The server returned no figures for this window.'**
  String get partnerFinanceNoData;

  /// No description provided for @partnerFinanceOverviewHeading.
  ///
  /// In en, this message translates to:
  /// **'Revenue and commission'**
  String get partnerFinanceOverviewHeading;

  /// No description provided for @partnerFinanceOverviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings are counted by check-in date within the selected window.'**
  String get partnerFinanceOverviewSubtitle;

  /// No description provided for @partnerFinanceCommissionCaption.
  ///
  /// In en, this message translates to:
  /// **'Calculated by the server at a fixed rate'**
  String get partnerFinanceCommissionCaption;

  /// No description provided for @partnerFinanceTaxCaption.
  ///
  /// In en, this message translates to:
  /// **'Indicative only — not a tax calculation'**
  String get partnerFinanceTaxCaption;

  /// No description provided for @partnerFinanceCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed bookings'**
  String get partnerFinanceCompletedLabel;

  /// No description provided for @partnerFinancePaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Bookings with a paid payment'**
  String get partnerFinancePaidLabel;

  /// No description provided for @partnerFinancePendingCaption.
  ///
  /// In en, this message translates to:
  /// **'The whole window\'s net revenue: nothing tracks what has actually been settled'**
  String get partnerFinancePendingCaption;

  /// No description provided for @partnerFinanceNextPayoutCaption.
  ///
  /// In en, this message translates to:
  /// **'An assumed monthly cadence, not a scheduled date'**
  String get partnerFinanceNextPayoutCaption;

  /// No description provided for @partnerFinanceCommissionHeading.
  ///
  /// In en, this message translates to:
  /// **'Commission breakdown'**
  String get partnerFinanceCommissionHeading;

  /// No description provided for @partnerFinanceRateNotice.
  ///
  /// In en, this message translates to:
  /// **'The server applied a fixed platform rate of {rate}. It is a constant in the service, not a negotiated rate, and this app never applies it itself.'**
  String partnerFinanceRateNotice(String rate);

  /// No description provided for @partnerFinanceRevenueHeading.
  ///
  /// In en, this message translates to:
  /// **'Revenue breakdown'**
  String get partnerFinanceRevenueHeading;

  /// No description provided for @partnerFinanceRevenueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every figure is calculated and rounded by the server. Nothing on this screen is recalculated.'**
  String get partnerFinanceRevenueSubtitle;

  /// No description provided for @partnerFinanceRevenueEmpty.
  ///
  /// In en, this message translates to:
  /// **'No revenue was recorded in this window.'**
  String get partnerFinanceRevenueEmpty;

  /// No description provided for @partnerFinanceAverageBooking.
  ///
  /// In en, this message translates to:
  /// **'Average booking value'**
  String get partnerFinanceAverageBooking;

  /// No description provided for @partnerFinanceHighestBooking.
  ///
  /// In en, this message translates to:
  /// **'Highest booking'**
  String get partnerFinanceHighestBooking;

  /// No description provided for @partnerFinanceByDay.
  ///
  /// In en, this message translates to:
  /// **'By day'**
  String get partnerFinanceByDay;

  /// No description provided for @partnerFinanceByMonth.
  ///
  /// In en, this message translates to:
  /// **'By month'**
  String get partnerFinanceByMonth;

  /// No description provided for @partnerFinanceByProperty.
  ///
  /// In en, this message translates to:
  /// **'By property'**
  String get partnerFinanceByProperty;

  /// No description provided for @partnerFinanceByRoom.
  ///
  /// In en, this message translates to:
  /// **'By room'**
  String get partnerFinanceByRoom;

  /// No description provided for @partnerFinanceSettlementHeading.
  ///
  /// In en, this message translates to:
  /// **'Settlement'**
  String get partnerFinanceSettlementHeading;

  /// No description provided for @partnerFinanceSettlementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Periods are calendar months calculated from booking revenue. No settlement ledger exists behind them.'**
  String get partnerFinanceSettlementSubtitle;

  /// No description provided for @partnerFinanceSettlementEmpty.
  ///
  /// In en, this message translates to:
  /// **'No settlement period falls in this window.'**
  String get partnerFinanceSettlementEmpty;

  /// No description provided for @partnerFinanceCurrentSettlement.
  ///
  /// In en, this message translates to:
  /// **'Current period'**
  String get partnerFinanceCurrentSettlement;

  /// No description provided for @partnerFinanceLastSettlement.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get partnerFinanceLastSettlement;

  /// No description provided for @partnerFinancePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get partnerFinancePending;

  /// No description provided for @partnerFinancePaid.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get partnerFinancePaid;

  /// No description provided for @partnerFinanceSettlementMismatch.
  ///
  /// In en, this message translates to:
  /// **'The server reports a settled amount although no period below is marked settled. Both values are shown exactly as the server sent them; treat the settled total with caution.'**
  String get partnerFinanceSettlementMismatch;

  /// No description provided for @partnerFinanceSettlementPeriods.
  ///
  /// In en, this message translates to:
  /// **'Periods'**
  String get partnerFinanceSettlementPeriods;

  /// No description provided for @partnerFinancePeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get partnerFinancePeriod;

  /// No description provided for @partnerFinanceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get partnerFinanceStatus;

  /// No description provided for @partnerFinanceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get partnerFinanceStatusPaid;

  /// No description provided for @partnerFinanceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get partnerFinanceStatusPending;

  /// No description provided for @partnerFinanceStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised'**
  String get partnerFinanceStatusUnknown;

  /// No description provided for @partnerFinancePayoutHeading.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get partnerFinancePayoutHeading;

  /// No description provided for @partnerFinancePayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The same calculated periods, split by status.'**
  String get partnerFinancePayoutSubtitle;

  /// No description provided for @partnerFinancePayoutEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payout period falls in this window.'**
  String get partnerFinancePayoutEmpty;

  /// No description provided for @partnerFinanceEstimatedPayoutDate.
  ///
  /// In en, this message translates to:
  /// **'Estimated payout date'**
  String get partnerFinanceEstimatedPayoutDate;

  /// No description provided for @partnerFinanceUpcomingPayouts.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get partnerFinanceUpcomingPayouts;

  /// No description provided for @partnerFinanceCompletedPayouts.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get partnerFinanceCompletedPayouts;

  /// No description provided for @partnerFinancePayoutNoRecords.
  ///
  /// In en, this message translates to:
  /// **'No payout records exist in the partner API — there is no reference, bank detail or payment provider information to show, and none is requested.'**
  String get partnerFinancePayoutNoRecords;

  /// No description provided for @partnerFinanceInvoiceHeading.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get partnerFinanceInvoiceHeading;

  /// No description provided for @partnerFinanceInvoiceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invoice was issued in this window.'**
  String get partnerFinanceInvoiceEmpty;

  /// No description provided for @partnerFinanceInvoiceIssued.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get partnerFinanceInvoiceIssued;

  /// No description provided for @partnerFinanceInvoicePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get partnerFinanceInvoicePaid;

  /// No description provided for @partnerFinanceInvoiceCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get partnerFinanceInvoiceCancelled;

  /// No description provided for @partnerFinanceInvoiceRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get partnerFinanceInvoiceRefunded;

  /// No description provided for @partnerFinanceInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total invoiced'**
  String get partnerFinanceInvoiceTotal;

  /// No description provided for @partnerFinanceInvoiceNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'The partner API returns invoice counts only. There is no invoice list, no invoice number to open and no download, so none is offered here.'**
  String get partnerFinanceInvoiceNoDocuments;

  /// No description provided for @partnerFinanceRefundHeading.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get partnerFinanceRefundHeading;

  /// No description provided for @partnerFinanceRefundEmpty.
  ///
  /// In en, this message translates to:
  /// **'No refund was recorded in this window.'**
  String get partnerFinanceRefundEmpty;

  /// No description provided for @partnerFinanceRefundCount.
  ///
  /// In en, this message translates to:
  /// **'Refunds'**
  String get partnerFinanceRefundCount;

  /// No description provided for @partnerFinanceRefundAmount.
  ///
  /// In en, this message translates to:
  /// **'Refunded amount'**
  String get partnerFinanceRefundAmount;

  /// No description provided for @partnerFinanceRefundRate.
  ///
  /// In en, this message translates to:
  /// **'Refund rate'**
  String get partnerFinanceRefundRate;

  /// No description provided for @partnerFinanceRefundReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Refunds are read-only here. The partner API has no refund action, so refunds are started elsewhere.'**
  String get partnerFinanceRefundReadOnly;

  /// No description provided for @partnerAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance analytics'**
  String get partnerAnalyticsTitle;

  /// No description provided for @partnerAnalyticsDashboardPointer.
  ///
  /// In en, this message translates to:
  /// **'Revenue, occupancy and the headline totals live on the Dashboard, which already reports them. This page covers what the Dashboard does not.'**
  String get partnerAnalyticsDashboardPointer;

  /// No description provided for @partnerAnalyticsScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Figures cover every property you own. Select a property in the workspace to narrow them.'**
  String get partnerAnalyticsScopeAll;

  /// No description provided for @partnerAnalyticsScopeProperty.
  ///
  /// In en, this message translates to:
  /// **'Figures cover the selected property only.'**
  String get partnerAnalyticsScopeProperty;

  /// No description provided for @partnerAnalyticsBookingsHeading.
  ///
  /// In en, this message translates to:
  /// **'Booking activity'**
  String get partnerAnalyticsBookingsHeading;

  /// No description provided for @partnerAnalyticsBookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No booking falls in this window.'**
  String get partnerAnalyticsBookingsEmpty;

  /// No description provided for @partnerAnalyticsArrivals.
  ///
  /// In en, this message translates to:
  /// **'Arrivals'**
  String get partnerAnalyticsArrivals;

  /// No description provided for @partnerAnalyticsDepartures.
  ///
  /// In en, this message translates to:
  /// **'Departures'**
  String get partnerAnalyticsDepartures;

  /// No description provided for @partnerAnalyticsCancellations.
  ///
  /// In en, this message translates to:
  /// **'Cancellations'**
  String get partnerAnalyticsCancellations;

  /// No description provided for @partnerAnalyticsNoShows.
  ///
  /// In en, this message translates to:
  /// **'No-shows'**
  String get partnerAnalyticsNoShows;

  /// No description provided for @partnerAnalyticsAverageStay.
  ///
  /// In en, this message translates to:
  /// **'Average stay'**
  String get partnerAnalyticsAverageStay;

  /// No description provided for @partnerAnalyticsAverageStayCaption.
  ///
  /// In en, this message translates to:
  /// **'Nights, calculated by the server'**
  String get partnerAnalyticsAverageStayCaption;

  /// No description provided for @partnerAnalyticsByStatus.
  ///
  /// In en, this message translates to:
  /// **'By status'**
  String get partnerAnalyticsByStatus;

  /// No description provided for @partnerAnalyticsRoomsHeading.
  ///
  /// In en, this message translates to:
  /// **'Room performance'**
  String get partnerAnalyticsRoomsHeading;

  /// No description provided for @partnerAnalyticsRoomsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No room activity falls in this window.'**
  String get partnerAnalyticsRoomsEmpty;

  /// No description provided for @partnerAnalyticsOccupancyEstimate.
  ///
  /// In en, this message translates to:
  /// **'Occupancy estimate'**
  String get partnerAnalyticsOccupancyEstimate;

  /// No description provided for @partnerAnalyticsOccupancyCaption.
  ///
  /// In en, this message translates to:
  /// **'The server calls this an estimate'**
  String get partnerAnalyticsOccupancyCaption;

  /// No description provided for @partnerAnalyticsTopRoomsRevenue.
  ///
  /// In en, this message translates to:
  /// **'Top rooms by revenue'**
  String get partnerAnalyticsTopRoomsRevenue;

  /// No description provided for @partnerAnalyticsTopRoomsBookings.
  ///
  /// In en, this message translates to:
  /// **'Top rooms by bookings'**
  String get partnerAnalyticsTopRoomsBookings;

  /// No description provided for @partnerAnalyticsAvailability.
  ///
  /// In en, this message translates to:
  /// **'Availability summary'**
  String get partnerAnalyticsAvailability;

  /// No description provided for @partnerAnalyticsPromotionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Promotion activity'**
  String get partnerAnalyticsPromotionsHeading;

  /// No description provided for @partnerAnalyticsPromotionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Structural only: the server cannot yet attribute a discount to a booking.'**
  String get partnerAnalyticsPromotionsSubtitle;

  /// No description provided for @partnerAnalyticsPromotionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No promotion activity falls in this window.'**
  String get partnerAnalyticsPromotionsEmpty;

  /// No description provided for @partnerAnalyticsActivePromotions.
  ///
  /// In en, this message translates to:
  /// **'Active promotions'**
  String get partnerAnalyticsActivePromotions;

  /// No description provided for @partnerAnalyticsDiscountedBookings.
  ///
  /// In en, this message translates to:
  /// **'Discounted bookings'**
  String get partnerAnalyticsDiscountedBookings;

  /// No description provided for @partnerAnalyticsNoAttribution.
  ///
  /// In en, this message translates to:
  /// **'The server cannot attribute discounts yet'**
  String get partnerAnalyticsNoAttribution;

  /// No description provided for @partnerAnalyticsPromotionsByType.
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get partnerAnalyticsPromotionsByType;

  /// No description provided for @partnerAnalyticsPromotionsByStatus.
  ///
  /// In en, this message translates to:
  /// **'By status'**
  String get partnerAnalyticsPromotionsByStatus;

  /// No description provided for @partnerAnalyticsReviewsHeading.
  ///
  /// In en, this message translates to:
  /// **'Review summary'**
  String get partnerAnalyticsReviewsHeading;

  /// No description provided for @partnerAnalyticsReviewsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rating and moderation totals. Individual reviews and replies are managed in the Reviews module.'**
  String get partnerAnalyticsReviewsSubtitle;

  /// No description provided for @partnerAnalyticsReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No review falls in this window.'**
  String get partnerAnalyticsReviewsEmpty;

  /// No description provided for @partnerAnalyticsAverageRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get partnerAnalyticsAverageRating;

  /// No description provided for @partnerAnalyticsApprovedOnly.
  ///
  /// In en, this message translates to:
  /// **'Approved reviews only'**
  String get partnerAnalyticsApprovedOnly;

  /// No description provided for @partnerAnalyticsNoReviews.
  ///
  /// In en, this message translates to:
  /// **'No reviews to average'**
  String get partnerAnalyticsNoReviews;

  /// No description provided for @partnerAnalyticsReviewCount.
  ///
  /// In en, this message translates to:
  /// **'Total reviews'**
  String get partnerAnalyticsReviewCount;

  /// No description provided for @partnerAnalyticsReviewsApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get partnerAnalyticsReviewsApproved;

  /// No description provided for @partnerAnalyticsReviewsPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get partnerAnalyticsReviewsPending;

  /// No description provided for @partnerAnalyticsReviewsRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get partnerAnalyticsReviewsRejected;

  /// No description provided for @partnerAnalyticsMessagesHeading.
  ///
  /// In en, this message translates to:
  /// **'Message activity'**
  String get partnerAnalyticsMessagesHeading;

  /// No description provided for @partnerAnalyticsMessagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversation falls in this window.'**
  String get partnerAnalyticsMessagesEmpty;

  /// No description provided for @partnerAnalyticsOpenConversations.
  ///
  /// In en, this message translates to:
  /// **'Open conversations'**
  String get partnerAnalyticsOpenConversations;

  /// No description provided for @partnerAnalyticsClosedConversations.
  ///
  /// In en, this message translates to:
  /// **'Closed conversations'**
  String get partnerAnalyticsClosedConversations;

  /// No description provided for @partnerAnalyticsArchivedConversations.
  ///
  /// In en, this message translates to:
  /// **'Archived conversations'**
  String get partnerAnalyticsArchivedConversations;

  /// No description provided for @partnerAnalyticsUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'Unread for you'**
  String get partnerAnalyticsUnreadMessages;

  /// No description provided for @partnerAnalyticsResponseTime.
  ///
  /// In en, this message translates to:
  /// **'Average response time'**
  String get partnerAnalyticsResponseTime;

  /// No description provided for @partnerAnalyticsNoResponses.
  ///
  /// In en, this message translates to:
  /// **'No response time could be measured'**
  String get partnerAnalyticsNoResponses;

  /// No description provided for @partnerAnalyticsMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{value} min'**
  String partnerAnalyticsMinutesValue(String value);

  /// No description provided for @partnerReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Guest reviews'**
  String get partnerReviewsTitle;

  /// No description provided for @partnerReviewsAnalyticsPointer.
  ///
  /// In en, this message translates to:
  /// **'Ratings and moderation totals are on the Analytics page. This page is for replying.'**
  String get partnerReviewsAnalyticsPointer;

  /// No description provided for @partnerReviewsScopeNote.
  ///
  /// In en, this message translates to:
  /// **'The published reviews for the selected property. Only published reviews can be replied to, and this is exactly the set the server allows a reply on.'**
  String get partnerReviewsScopeNote;

  /// No description provided for @partnerReviewsNoBodyNotice.
  ///
  /// In en, this message translates to:
  /// **'The partner API does not return the text a guest wrote — only the rating, the title and the date. Replies are written against those.'**
  String get partnerReviewsNoBodyNotice;

  /// No description provided for @partnerReviewsNoPropertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a property'**
  String get partnerReviewsNoPropertyTitle;

  /// No description provided for @partnerReviewsNoPropertyMessage.
  ///
  /// In en, this message translates to:
  /// **'Reviews are listed per property. Choose one in the workspace to see its reviews.'**
  String get partnerReviewsNoPropertyMessage;

  /// No description provided for @partnerReviewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No published reviews yet'**
  String get partnerReviewsEmptyTitle;

  /// No description provided for @partnerReviewsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been published for this property. Reviews appear here once a guest writes one and it is approved.'**
  String get partnerReviewsEmptyMessage;

  /// No description provided for @partnerReviewsNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches this filter'**
  String get partnerReviewsNoMatchTitle;

  /// No description provided for @partnerReviewsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'This property has reviews, but none in the selected group.'**
  String get partnerReviewsNoMatchMessage;

  /// No description provided for @partnerReviewsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get partnerReviewsFilterAll;

  /// No description provided for @partnerReviewsFilterAllCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String partnerReviewsFilterAllCount(String count);

  /// No description provided for @partnerReviewsFilterNeedsReplyCount.
  ///
  /// In en, this message translates to:
  /// **'Needs a reply ({count})'**
  String partnerReviewsFilterNeedsReplyCount(String count);

  /// No description provided for @partnerReviewsFilterRepliedCount.
  ///
  /// In en, this message translates to:
  /// **'Replied ({count})'**
  String partnerReviewsFilterRepliedCount(String count);

  /// No description provided for @partnerReviewsNeedsReply.
  ///
  /// In en, this message translates to:
  /// **'Needs a reply'**
  String get partnerReviewsNeedsReply;

  /// No description provided for @partnerReviewsReplied.
  ///
  /// In en, this message translates to:
  /// **'Replied'**
  String get partnerReviewsReplied;

  /// No description provided for @partnerReviewsNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Untitled review'**
  String get partnerReviewsNoTitle;

  /// No description provided for @partnerReviewsRatingValue.
  ///
  /// In en, this message translates to:
  /// **'Rated {rating} out of 5'**
  String partnerReviewsRatingValue(String rating);

  /// No description provided for @partnerReviewsReplyHeading.
  ///
  /// In en, this message translates to:
  /// **'Your reply'**
  String get partnerReviewsReplyHeading;

  /// No description provided for @partnerReviewsCloseReply.
  ///
  /// In en, this message translates to:
  /// **'Close reply'**
  String get partnerReviewsCloseReply;

  /// No description provided for @partnerReviewsCurrentReply.
  ///
  /// In en, this message translates to:
  /// **'Currently published'**
  String get partnerReviewsCurrentReply;

  /// No description provided for @partnerReviewsRepliedAt.
  ///
  /// In en, this message translates to:
  /// **'replied {date}'**
  String partnerReviewsRepliedAt(String date);

  /// No description provided for @partnerReviewsEditedAt.
  ///
  /// In en, this message translates to:
  /// **'edited {date}'**
  String partnerReviewsEditedAt(String date);

  /// No description provided for @partnerReviewsReplyField.
  ///
  /// In en, this message translates to:
  /// **'Reply to this guest'**
  String get partnerReviewsReplyField;

  /// No description provided for @partnerReviewsReplyHelp.
  ///
  /// In en, this message translates to:
  /// **'A review has one reply. Publishing again replaces it rather than adding a second.'**
  String get partnerReviewsReplyHelp;

  /// No description provided for @partnerReviewsPublicNotice.
  ///
  /// In en, this message translates to:
  /// **'Your reply is published publicly alongside the review, and there is no way to delete it afterwards — only to replace its wording. The guest is notified the first time you reply.'**
  String get partnerReviewsPublicNotice;

  /// No description provided for @partnerReviewsPublishReply.
  ///
  /// In en, this message translates to:
  /// **'Publish reply'**
  String get partnerReviewsPublishReply;

  /// No description provided for @partnerReviewsUpdateReply.
  ///
  /// In en, this message translates to:
  /// **'Replace reply'**
  String get partnerReviewsUpdateReply;

  /// No description provided for @partnerReviewsPublishConfirm.
  ///
  /// In en, this message translates to:
  /// **'Publish this reply publicly? It cannot be deleted afterwards, only rewritten.'**
  String get partnerReviewsPublishConfirm;

  /// No description provided for @partnerReviewsReplyPublished.
  ///
  /// In en, this message translates to:
  /// **'Your reply is published.'**
  String get partnerReviewsReplyPublished;

  /// No description provided for @partnerReviewsReplyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write a reply before publishing.'**
  String get partnerReviewsReplyEmpty;

  /// No description provided for @partnerReviewsReplyUncertain.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before the server confirmed, and a reply cannot be deleted. Refresh to see whether it was published.'**
  String get partnerReviewsReplyUncertain;

  /// No description provided for @partnerReviewsNotFound.
  ///
  /// In en, this message translates to:
  /// **'That review is no longer available to your account.'**
  String get partnerReviewsNotFound;

  /// No description provided for @partnerReviewsNotApprovedNotice.
  ///
  /// In en, this message translates to:
  /// **'Only a published review can be replied to. The server refuses a reply on any other status.'**
  String get partnerReviewsNotApprovedNotice;

  /// No description provided for @partnerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get partnerSettingsTitle;

  /// No description provided for @partnerSettingsTabWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Policies & workspace'**
  String get partnerSettingsTabWorkspace;

  /// No description provided for @partnerSettingsTabTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get partnerSettingsTabTeam;

  /// No description provided for @partnerSettingsTabPayout.
  ///
  /// In en, this message translates to:
  /// **'Payout account'**
  String get partnerSettingsTabPayout;

  /// No description provided for @partnerSettingsTabProfile.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get partnerSettingsTabProfile;

  /// No description provided for @partnerTeamHeading.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get partnerTeamHeading;

  /// No description provided for @partnerTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everyone who can act in this partner workspace, and the role the server grants them.'**
  String get partnerTeamSubtitle;

  /// No description provided for @partnerTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No team members are recorded.'**
  String get partnerTeamEmpty;

  /// No description provided for @partnerTeamOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the partner owner can add, change or remove team members. You can see the team here.'**
  String get partnerTeamOwnerOnly;

  /// No description provided for @partnerTeamRoleField.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get partnerTeamRoleField;

  /// No description provided for @partnerTeamActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get partnerTeamActive;

  /// No description provided for @partnerTeamInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get partnerTeamInactive;

  /// No description provided for @partnerTeamActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get partnerTeamActivate;

  /// No description provided for @partnerTeamDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get partnerTeamDeactivate;

  /// No description provided for @partnerTeamRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get partnerTeamRemove;

  /// No description provided for @partnerTeamRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {member} from the team? This cannot be undone from here — they would have to be added again.'**
  String partnerTeamRemoveConfirm(String member);

  /// No description provided for @partnerTeamInviteHeading.
  ///
  /// In en, this message translates to:
  /// **'Add a team member'**
  String get partnerTeamInviteHeading;

  /// No description provided for @partnerTeamInviteNote.
  ///
  /// In en, this message translates to:
  /// **'The server matches an existing Plan Your Trip account by email. It does not send an invitation, so the person must already have an account.'**
  String get partnerTeamInviteNote;

  /// No description provided for @partnerTeamInviteEmail.
  ///
  /// In en, this message translates to:
  /// **'Their account email'**
  String get partnerTeamInviteEmail;

  /// No description provided for @partnerTeamInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get partnerTeamInviteAction;

  /// No description provided for @partnerPayoutHeading.
  ///
  /// In en, this message translates to:
  /// **'Payout account'**
  String get partnerPayoutHeading;

  /// No description provided for @partnerPayoutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Where settlements would be sent. Held as reference details only.'**
  String get partnerPayoutSubtitle;

  /// No description provided for @partnerPayoutNone.
  ///
  /// In en, this message translates to:
  /// **'No payout account has been added yet.'**
  String get partnerPayoutNone;

  /// No description provided for @partnerPayoutLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The payout account could not be loaded. This is not the same as having none.'**
  String get partnerPayoutLoadFailed;

  /// No description provided for @partnerPayoutHolder.
  ///
  /// In en, this message translates to:
  /// **'Account holder'**
  String get partnerPayoutHolder;

  /// No description provided for @partnerPayoutBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get partnerPayoutBank;

  /// No description provided for @partnerPayoutAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get partnerPayoutAccountNumber;

  /// No description provided for @partnerPayoutMasked.
  ///
  /// In en, this message translates to:
  /// **'Ends in {last4}'**
  String partnerPayoutMasked(String last4);

  /// No description provided for @partnerPayoutMethod.
  ///
  /// In en, this message translates to:
  /// **'Payout method'**
  String get partnerPayoutMethod;

  /// No description provided for @partnerPayoutMethodBank.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get partnerPayoutMethodBank;

  /// No description provided for @partnerPayoutMethodManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get partnerPayoutMethodManual;

  /// No description provided for @partnerPayoutMethodUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised method'**
  String get partnerPayoutMethodUnknown;

  /// No description provided for @partnerPayoutStatus.
  ///
  /// In en, this message translates to:
  /// **'Verification status'**
  String get partnerPayoutStatus;

  /// No description provided for @partnerPayoutUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get partnerPayoutUpdated;

  /// No description provided for @partnerPayoutNoExecutionNotice.
  ///
  /// In en, this message translates to:
  /// **'No payout is ever sent from here, and the full account number is never stored: the server keeps only its last four digits and discards the rest as soon as it is submitted.'**
  String get partnerPayoutNoExecutionNotice;

  /// No description provided for @partnerPayoutRoleNotice.
  ///
  /// In en, this message translates to:
  /// **'Only the partner owner or a finance team member can change these details. You can see them here.'**
  String get partnerPayoutRoleNotice;

  /// No description provided for @partnerPayoutAdd.
  ///
  /// In en, this message translates to:
  /// **'Add payout account'**
  String get partnerPayoutAdd;

  /// No description provided for @partnerPayoutReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace details'**
  String get partnerPayoutReplace;

  /// No description provided for @partnerPayoutCancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get partnerPayoutCancelEdit;

  /// No description provided for @partnerPayoutFormHeading.
  ///
  /// In en, this message translates to:
  /// **'New payout details'**
  String get partnerPayoutFormHeading;

  /// No description provided for @partnerPayoutNumberHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 4 characters. Only the last four digits are kept.'**
  String get partnerPayoutNumberHelp;

  /// No description provided for @partnerPayoutSave.
  ///
  /// In en, this message translates to:
  /// **'Save payout details'**
  String get partnerPayoutSave;

  /// No description provided for @partnerPayoutReplaceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Replace the payout details? The previous account number cannot be recovered, because it was never stored.'**
  String get partnerPayoutReplaceConfirm;

  /// No description provided for @partnerProfileHeading.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get partnerProfileHeading;

  /// No description provided for @partnerProfileBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get partnerProfileBusinessName;

  /// No description provided for @partnerProfileRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Representative'**
  String get partnerProfileRepresentative;

  /// No description provided for @partnerProfileVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get partnerProfileVerification;

  /// No description provided for @partnerProfileYourRole.
  ///
  /// In en, this message translates to:
  /// **'Your role'**
  String get partnerProfileYourRole;

  /// No description provided for @partnerProfileReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'An approved business profile cannot be edited through the partner API — the server accepts changes only while a profile is a draft or has been rejected. Contact support to change these details.'**
  String get partnerProfileReadOnlyNotice;

  /// No description provided for @partnerProfileStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get partnerProfileStatusDraft;

  /// No description provided for @partnerProfileStatusSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Awaiting review'**
  String get partnerProfileStatusSubmitted;

  /// No description provided for @partnerProfileStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get partnerProfileStatusApproved;

  /// No description provided for @partnerProfileStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get partnerProfileStatusRejected;

  /// No description provided for @partnerProfileStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get partnerProfileStatusSuspended;

  /// No description provided for @partnerProfileStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised status'**
  String get partnerProfileStatusUnknown;

  /// No description provided for @partnerAccountSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get partnerAccountSaved;

  /// No description provided for @partnerAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'That record is no longer available to your account.'**
  String get partnerAccountNotFound;

  /// No description provided for @partnerAccountConflict.
  ///
  /// In en, this message translates to:
  /// **'The server refused that because it conflicts with an existing record.'**
  String get partnerAccountConflict;

  /// No description provided for @partnerAccountValidation.
  ///
  /// In en, this message translates to:
  /// **'Check the details and try again.'**
  String get partnerAccountValidation;

  /// No description provided for @partnerAccountUncertain.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before the server confirmed. Refresh to see the current state before trying again.'**
  String get partnerAccountUncertain;

  /// No description provided for @adminConsoleTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin console'**
  String get adminConsoleTitle;

  /// No description provided for @adminSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String adminSignedInAs(String email);

  /// No description provided for @adminNavDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminNavDashboard;

  /// No description provided for @adminNavBookings.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get adminNavBookings;

  /// No description provided for @adminNavPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get adminNavPayments;

  /// No description provided for @adminNavInvoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get adminNavInvoices;

  /// No description provided for @adminNavReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get adminNavReviews;

  /// No description provided for @adminNavActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get adminNavActivityLog;

  /// No description provided for @adminSectionOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminSectionOverview;

  /// No description provided for @adminSectionOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get adminSectionOperations;

  /// No description provided for @adminSectionFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get adminSectionFinance;

  /// No description provided for @adminSectionCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get adminSectionCommunity;

  /// No description provided for @adminSectionAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit'**
  String get adminSectionAudit;

  /// No description provided for @adminAccessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Administrator access required'**
  String get adminAccessDeniedTitle;

  /// No description provided for @adminAccessDeniedBody.
  ///
  /// In en, this message translates to:
  /// **'This area is limited to administrator accounts.'**
  String get adminAccessDeniedBody;

  /// No description provided for @adminAccessDeniedAction.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get adminAccessDeniedAction;

  /// No description provided for @adminMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get adminMenu;

  /// No description provided for @adminLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get adminLoading;

  /// No description provided for @adminEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show'**
  String get adminEmptyTitle;

  /// No description provided for @adminEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No records match this view yet.'**
  String get adminEmptyMessage;

  /// No description provided for @adminErrorUnauthorized.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please sign in again.'**
  String get adminErrorUnauthorized;

  /// No description provided for @adminErrorForbidden.
  ///
  /// In en, this message translates to:
  /// **'This account does not have administrator access.'**
  String get adminErrorForbidden;

  /// No description provided for @adminErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'That record could not be found.'**
  String get adminErrorNotFound;

  /// No description provided for @adminErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not load this view.'**
  String get adminErrorGeneric;

  /// No description provided for @adminRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get adminRetry;

  /// No description provided for @adminRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get adminRefresh;

  /// No description provided for @adminValueUnknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get adminValueUnknown;

  /// No description provided for @adminPaginationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get adminPaginationEmpty;

  /// No description provided for @adminPaginationRange.
  ///
  /// In en, this message translates to:
  /// **'Showing {first}–{last} of {total}'**
  String adminPaginationRange(int first, int last, int total);

  /// No description provided for @adminPaginationPageOf.
  ///
  /// In en, this message translates to:
  /// **'Page {page} of {total}'**
  String adminPaginationPageOf(int page, int total);

  /// No description provided for @adminPaginationPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get adminPaginationPrevious;

  /// No description provided for @adminPaginationNext.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get adminPaginationNext;

  /// No description provided for @adminSortAscending.
  ///
  /// In en, this message translates to:
  /// **'Sorted ascending'**
  String get adminSortAscending;

  /// No description provided for @adminSortDescending.
  ///
  /// In en, this message translates to:
  /// **'Sorted descending'**
  String get adminSortDescending;

  /// No description provided for @adminFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// No description provided for @adminFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminFilterStatus;

  /// No description provided for @adminSortCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get adminSortCreatedAt;

  /// No description provided for @adminSortCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get adminSortCheckIn;

  /// No description provided for @adminSortCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Check-out'**
  String get adminSortCheckOut;

  /// No description provided for @adminSortFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminSortFinalPrice;

  /// No description provided for @adminSortStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminSortStatus;

  /// No description provided for @adminSortBookingCode.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get adminSortBookingCode;

  /// No description provided for @adminSortAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminSortAmount;

  /// No description provided for @adminSortPaidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get adminSortPaidAt;

  /// No description provided for @adminSortRefundedAt.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get adminSortRefundedAt;

  /// No description provided for @adminSortRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get adminSortRating;

  /// No description provided for @adminSortApprovedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminSortApprovedAt;

  /// No description provided for @adminSortIssuedAt.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get adminSortIssuedAt;

  /// No description provided for @adminSortTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminSortTotalAmount;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Platform overview'**
  String get adminDashboardTitle;

  /// No description provided for @adminDashboardTotalBookings.
  ///
  /// In en, this message translates to:
  /// **'Total bookings'**
  String get adminDashboardTotalBookings;

  /// No description provided for @adminDashboardGrossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross revenue'**
  String get adminDashboardGrossRevenue;

  /// No description provided for @adminDashboardActiveHotels.
  ///
  /// In en, this message translates to:
  /// **'Active hotels'**
  String get adminDashboardActiveHotels;

  /// No description provided for @adminDashboardActiveRooms.
  ///
  /// In en, this message translates to:
  /// **'Active rooms'**
  String get adminDashboardActiveRooms;

  /// No description provided for @adminDashboardTotalUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminDashboardTotalUsers;

  /// No description provided for @adminDashboardTotalPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get adminDashboardTotalPartners;

  /// No description provided for @adminDashboardBookingsInRange.
  ///
  /// In en, this message translates to:
  /// **'Bookings in range'**
  String get adminDashboardBookingsInRange;

  /// No description provided for @adminDashboardRevenueInRange.
  ///
  /// In en, this message translates to:
  /// **'Revenue in range'**
  String get adminDashboardRevenueInRange;

  /// No description provided for @adminDashboardBookingsByStatus.
  ///
  /// In en, this message translates to:
  /// **'Bookings by status'**
  String get adminDashboardBookingsByStatus;

  /// No description provided for @adminDashboardNoBookings.
  ///
  /// In en, this message translates to:
  /// **'The platform has no bookings yet.'**
  String get adminDashboardNoBookings;

  /// No description provided for @adminDashboardRange.
  ///
  /// In en, this message translates to:
  /// **'Range {from} to {to}'**
  String adminDashboardRange(String from, String to);

  /// No description provided for @adminDashboardRangeDefault.
  ///
  /// In en, this message translates to:
  /// **'Backend default range'**
  String get adminDashboardRangeDefault;

  /// No description provided for @adminDashboardLoadedAt.
  ///
  /// In en, this message translates to:
  /// **'Loaded at {time}'**
  String adminDashboardLoadedAt(String time);

  /// No description provided for @adminDashboardNoCurrency.
  ///
  /// In en, this message translates to:
  /// **'Revenue is reported without a currency by this endpoint.'**
  String get adminDashboardNoCurrency;

  /// No description provided for @adminBookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get adminBookingsTitle;

  /// No description provided for @adminBookingCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get adminBookingCode;

  /// No description provided for @adminBookingHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get adminBookingHotel;

  /// No description provided for @adminBookingRoom.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get adminBookingRoom;

  /// No description provided for @adminBookingStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get adminBookingStay;

  /// No description provided for @adminBookingNights.
  ///
  /// In en, this message translates to:
  /// **'{count} nights'**
  String adminBookingNights(int count);

  /// No description provided for @adminBookingTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminBookingTotal;

  /// No description provided for @adminBookingCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get adminBookingCreated;

  /// No description provided for @adminBookingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bookings match these filters.'**
  String get adminBookingsEmpty;

  /// No description provided for @adminPaymentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get adminPaymentsTitle;

  /// No description provided for @adminPaymentCode.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get adminPaymentCode;

  /// No description provided for @adminPaymentBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get adminPaymentBooking;

  /// No description provided for @adminPaymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get adminPaymentAmount;

  /// No description provided for @adminPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get adminPaymentMethod;

  /// No description provided for @adminPaymentProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get adminPaymentProvider;

  /// No description provided for @adminPaymentPaidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get adminPaymentPaidAt;

  /// No description provided for @adminPaymentRefundedAt.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get adminPaymentRefundedAt;

  /// No description provided for @adminPaymentFailureReason.
  ///
  /// In en, this message translates to:
  /// **'Failure reason'**
  String get adminPaymentFailureReason;

  /// No description provided for @adminPaymentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments match these filters.'**
  String get adminPaymentsEmpty;

  /// No description provided for @adminReviewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get adminReviewsTitle;

  /// No description provided for @adminReviewPlace.
  ///
  /// In en, this message translates to:
  /// **'Place'**
  String get adminReviewPlace;

  /// No description provided for @adminReviewAuthor.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get adminReviewAuthor;

  /// No description provided for @adminReviewRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get adminReviewRating;

  /// No description provided for @adminReviewContent.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get adminReviewContent;

  /// No description provided for @adminReviewReported.
  ///
  /// In en, this message translates to:
  /// **'Reported {count} times'**
  String adminReviewReported(int count);

  /// No description provided for @adminReviewPartnerReply.
  ///
  /// In en, this message translates to:
  /// **'Partner reply'**
  String get adminReviewPartnerReply;

  /// No description provided for @adminReviewNoReply.
  ///
  /// In en, this message translates to:
  /// **'No partner reply'**
  String get adminReviewNoReply;

  /// No description provided for @adminReviewsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reviews match these filters.'**
  String get adminReviewsEmpty;

  /// No description provided for @adminInvoicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get adminInvoicesTitle;

  /// No description provided for @adminInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get adminInvoiceNumber;

  /// No description provided for @adminInvoiceBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get adminInvoiceBooking;

  /// No description provided for @adminInvoiceHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get adminInvoiceHotel;

  /// No description provided for @adminInvoiceSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get adminInvoiceSubtotal;

  /// No description provided for @adminInvoiceDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get adminInvoiceDiscount;

  /// No description provided for @adminInvoiceTax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get adminInvoiceTax;

  /// No description provided for @adminInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get adminInvoiceTotal;

  /// No description provided for @adminInvoiceIssuedAt.
  ///
  /// In en, this message translates to:
  /// **'Issued'**
  String get adminInvoiceIssuedAt;

  /// No description provided for @adminInvoicePaidAt.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get adminInvoicePaidAt;

  /// No description provided for @adminInvoicesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invoices match these filters.'**
  String get adminInvoicesEmpty;

  /// No description provided for @adminActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity log'**
  String get adminActivityTitle;

  /// No description provided for @adminActivityActor.
  ///
  /// In en, this message translates to:
  /// **'Actor'**
  String get adminActivityActor;

  /// No description provided for @adminActivityAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get adminActivityAction;

  /// No description provided for @adminActivityTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get adminActivityTarget;

  /// No description provided for @adminActivityWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get adminActivityWhen;

  /// No description provided for @adminActivityDescription.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get adminActivityDescription;

  /// No description provided for @adminActivityBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get adminActivityBefore;

  /// No description provided for @adminActivityAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get adminActivityAfter;

  /// No description provided for @adminActivitySystemActor.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get adminActivitySystemActor;

  /// No description provided for @adminActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No administrative actions recorded yet.'**
  String get adminActivityEmpty;

  /// No description provided for @adminActivityFixedOrder.
  ///
  /// In en, this message translates to:
  /// **'Newest first, fixed by the server.'**
  String get adminActivityFixedOrder;

  /// No description provided for @adminActivityFilterAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get adminActivityFilterAction;

  /// No description provided for @adminNavPartners.
  ///
  /// In en, this message translates to:
  /// **'Partners'**
  String get adminNavPartners;

  /// No description provided for @adminPartnersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No partners yet.'**
  String get adminPartnersEmpty;

  /// No description provided for @adminPartnersEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No partners match these filters.'**
  String get adminPartnersEmptyFiltered;

  /// No description provided for @adminPartnerSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search partners'**
  String get adminPartnerSearchLabel;

  /// No description provided for @adminPartnerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Business name, representative or contact email'**
  String get adminPartnerSearchHint;

  /// No description provided for @adminPartnerSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get adminPartnerSearchClear;

  /// No description provided for @adminPartnerFilterBusinessType.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get adminPartnerFilterBusinessType;

  /// No description provided for @adminPartnerSortBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get adminPartnerSortBusinessName;

  /// No description provided for @adminPartnerSortSubmittedAt.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get adminPartnerSortSubmittedAt;

  /// No description provided for @adminPartnerColBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get adminPartnerColBusiness;

  /// No description provided for @adminPartnerColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminPartnerColType;

  /// No description provided for @adminPartnerColSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get adminPartnerColSubmitted;

  /// No description provided for @adminPartnerColAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get adminPartnerColAction;

  /// No description provided for @adminPartnerOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get adminPartnerOpen;

  /// No description provided for @adminPartnerOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open partner {business}'**
  String adminPartnerOpenSemantic(String business);

  /// No description provided for @adminPartnerBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to partners'**
  String get adminPartnerBackToList;

  /// No description provided for @adminPartnerTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get adminPartnerTabOverview;

  /// No description provided for @adminPartnerTabTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get adminPartnerTabTeam;

  /// No description provided for @adminPartnerTabActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get adminPartnerTabActivity;

  /// No description provided for @adminPartnerTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get adminPartnerTabSettings;

  /// No description provided for @adminPartnerNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner not found'**
  String get adminPartnerNotFoundTitle;

  /// No description provided for @adminPartnerNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No partner exists with this id. It may have been removed, or the link may be wrong.'**
  String get adminPartnerNotFoundMessage;

  /// No description provided for @adminPartnerSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Business identity'**
  String get adminPartnerSectionIdentity;

  /// No description provided for @adminPartnerSectionVerification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get adminPartnerSectionVerification;

  /// No description provided for @adminPartnerSectionSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get adminPartnerSectionSummary;

  /// No description provided for @adminPartnerRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Representative'**
  String get adminPartnerRepresentative;

  /// No description provided for @adminPartnerContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Business email'**
  String get adminPartnerContactEmail;

  /// No description provided for @adminPartnerContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get adminPartnerContactPhone;

  /// No description provided for @adminPartnerAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get adminPartnerAddress;

  /// No description provided for @adminPartnerTaxCode.
  ///
  /// In en, this message translates to:
  /// **'Tax code'**
  String get adminPartnerTaxCode;

  /// No description provided for @adminPartnerWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get adminPartnerWebsite;

  /// No description provided for @adminPartnerAccountEmail.
  ///
  /// In en, this message translates to:
  /// **'Account email'**
  String get adminPartnerAccountEmail;

  /// No description provided for @adminPartnerApprovedAt.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get adminPartnerApprovedAt;

  /// No description provided for @adminPartnerApprovedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get adminPartnerApprovedBy;

  /// No description provided for @adminPartnerRejectedAt.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get adminPartnerRejectedAt;

  /// No description provided for @adminPartnerRejectionReason.
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get adminPartnerRejectionReason;

  /// No description provided for @adminPartnerSuspensionReason.
  ///
  /// In en, this message translates to:
  /// **'Suspension reason'**
  String get adminPartnerSuspensionReason;

  /// No description provided for @adminPartnerOwnedProperties.
  ///
  /// In en, this message translates to:
  /// **'Owned properties'**
  String get adminPartnerOwnedProperties;

  /// No description provided for @adminPartnerTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team members'**
  String get adminPartnerTeamSize;

  /// No description provided for @adminPartnerPayoutStatus.
  ///
  /// In en, this message translates to:
  /// **'Payout account'**
  String get adminPartnerPayoutStatus;

  /// No description provided for @adminPartnerSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Summary could not be loaded.'**
  String get adminPartnerSummaryUnavailable;

  /// No description provided for @adminPartnerPropertiesNotListed.
  ///
  /// In en, this message translates to:
  /// **'Property details are managed outside partner management.'**
  String get adminPartnerPropertiesNotListed;

  /// No description provided for @adminPartnerApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminPartnerApprove;

  /// No description provided for @adminPartnerReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminPartnerReject;

  /// No description provided for @adminPartnerSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get adminPartnerSuspend;

  /// No description provided for @adminPartnerCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get adminPartnerCancel;

  /// No description provided for @adminPartnerApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this partner?'**
  String get adminPartnerApproveTitle;

  /// No description provided for @adminPartnerApproveBody.
  ///
  /// In en, this message translates to:
  /// **'The applicant gains partner access and becomes the owner of their organisation.'**
  String get adminPartnerApproveBody;

  /// No description provided for @adminPartnerRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this application?'**
  String get adminPartnerRejectTitle;

  /// No description provided for @adminPartnerRejectBody.
  ///
  /// In en, this message translates to:
  /// **'The partner is notified and can edit their profile and submit it again.'**
  String get adminPartnerRejectBody;

  /// No description provided for @adminPartnerRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminPartnerRejectReasonLabel;

  /// No description provided for @adminPartnerRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'A reason is required.'**
  String get adminPartnerRejectReasonRequired;

  /// No description provided for @adminPartnerActionUncertain.
  ///
  /// In en, this message translates to:
  /// **'The result of the last action is unknown. This page has been reloaded — check the verification state before trying again.'**
  String get adminPartnerActionUncertain;

  /// No description provided for @adminPartnerSuspendedNotice.
  ///
  /// In en, this message translates to:
  /// **'This partner is suspended. There is no way to restore them from the admin console.'**
  String get adminPartnerSuspendedNotice;

  /// No description provided for @adminPartnerSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this partner?'**
  String get adminPartnerSuspendTitle;

  /// No description provided for @adminPartnerSuspendWarningIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This cannot be reversed from the admin console — there is no restore action.'**
  String get adminPartnerSuspendWarningIrreversible;

  /// No description provided for @adminPartnerSuspendWarningBookable.
  ///
  /// In en, this message translates to:
  /// **'Their published properties stay visible and bookable to guests.'**
  String get adminPartnerSuspendWarningBookable;

  /// No description provided for @adminPartnerSuspendWarningOperations.
  ///
  /// In en, this message translates to:
  /// **'They immediately lose access to bookings, rates, inventory and every other partner tool, so incoming bookings may go unhandled.'**
  String get adminPartnerSuspendWarningOperations;

  /// No description provided for @adminPartnerSuspendReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get adminPartnerSuspendReasonLabel;

  /// No description provided for @adminPartnerSuspendReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get adminPartnerSuspendReasonOptional;

  /// No description provided for @adminPartnerSuspendAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this cannot be undone here.'**
  String get adminPartnerSuspendAcknowledge;

  /// No description provided for @adminPartnerSuspendConfirm.
  ///
  /// In en, this message translates to:
  /// **'Suspend partner'**
  String get adminPartnerSuspendConfirm;

  /// No description provided for @adminPartnerTeamEmpty.
  ///
  /// In en, this message translates to:
  /// **'No team members.'**
  String get adminPartnerTeamEmpty;

  /// No description provided for @adminPartnerTeamReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Team members are managed by the partner.'**
  String get adminPartnerTeamReadOnlyNotice;

  /// No description provided for @adminPartnerTeamActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminPartnerTeamActive;

  /// No description provided for @adminPartnerTeamActiveYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get adminPartnerTeamActiveYes;

  /// No description provided for @adminPartnerTeamActiveNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get adminPartnerTeamActiveNo;

  /// No description provided for @adminPartnerTeamJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get adminPartnerTeamJoined;

  /// No description provided for @adminPartnerActivityEmpty.
  ///
  /// In en, this message translates to:
  /// **'No partner activity recorded.'**
  String get adminPartnerActivityEmpty;

  /// No description provided for @adminPartnerActivityScopeNotice.
  ///
  /// In en, this message translates to:
  /// **'This partner\'s own operations. Administrator actions appear in the console activity log.'**
  String get adminPartnerActivityScopeNotice;

  /// No description provided for @adminPartnerActivityActor.
  ///
  /// In en, this message translates to:
  /// **'By'**
  String get adminPartnerActivityActor;

  /// No description provided for @adminPartnerActivityEntity.
  ///
  /// In en, this message translates to:
  /// **'Entity'**
  String get adminPartnerActivityEntity;

  /// No description provided for @adminPartnerSettingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Settings could not be loaded.'**
  String get adminPartnerSettingsEmpty;

  /// No description provided for @adminPartnerSettingsReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Settings are managed by the partner.'**
  String get adminPartnerSettingsReadOnlyNotice;

  /// No description provided for @adminPartnerSettingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default language'**
  String get adminPartnerSettingsLanguage;

  /// No description provided for @adminPartnerSettingsTimezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get adminPartnerSettingsTimezone;

  /// No description provided for @adminPartnerSettingsEmail.
  ///
  /// In en, this message translates to:
  /// **'Email notifications'**
  String get adminPartnerSettingsEmail;

  /// No description provided for @adminPartnerSettingsSms.
  ///
  /// In en, this message translates to:
  /// **'SMS notifications'**
  String get adminPartnerSettingsSms;

  /// No description provided for @adminPartnerSettingsInApp.
  ///
  /// In en, this message translates to:
  /// **'In-app notifications'**
  String get adminPartnerSettingsInApp;

  /// No description provided for @adminPartnerSettingsBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking notifications'**
  String get adminPartnerSettingsBooking;

  /// No description provided for @adminPartnerSettingsPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment notifications'**
  String get adminPartnerSettingsPayment;

  /// No description provided for @adminPartnerSettingsReview.
  ///
  /// In en, this message translates to:
  /// **'Review notifications'**
  String get adminPartnerSettingsReview;

  /// No description provided for @adminPartnerSettingsPromotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion notifications'**
  String get adminPartnerSettingsPromotion;

  /// No description provided for @adminNavCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get adminNavCatalog;

  /// No description provided for @adminSectionCatalog.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get adminSectionCatalog;

  /// No description provided for @adminCatalogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No places yet.'**
  String get adminCatalogEmpty;

  /// No description provided for @adminCatalogEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No places match these filters.'**
  String get adminCatalogEmptyFiltered;

  /// No description provided for @adminCatalogSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search places'**
  String get adminCatalogSearchLabel;

  /// No description provided for @adminCatalogSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get adminCatalogSearchClear;

  /// No description provided for @adminCatalogFilterFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get adminCatalogFilterFeatured;

  /// No description provided for @adminCatalogFilterVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get adminCatalogFilterVerified;

  /// No description provided for @adminCatalogSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get adminCatalogSortLabel;

  /// No description provided for @adminCatalogSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get adminCatalogSortNewest;

  /// No description provided for @adminCatalogSortRatingDesc.
  ///
  /// In en, this message translates to:
  /// **'Highest rated'**
  String get adminCatalogSortRatingDesc;

  /// No description provided for @adminCatalogSortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price: low to high'**
  String get adminCatalogSortPriceAsc;

  /// No description provided for @adminCatalogSortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price: high to low'**
  String get adminCatalogSortPriceDesc;

  /// No description provided for @adminCatalogSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A–Z'**
  String get adminCatalogSortNameAsc;

  /// No description provided for @adminCatalogOrderingNotice.
  ///
  /// In en, this message translates to:
  /// **'Places with the same sort value may change order between pages.'**
  String get adminCatalogOrderingNotice;

  /// No description provided for @adminCatalogColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminCatalogColName;

  /// No description provided for @adminCatalogColCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get adminCatalogColCategory;

  /// No description provided for @adminCatalogColLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get adminCatalogColLocation;

  /// No description provided for @adminCatalogColRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get adminCatalogColRating;

  /// No description provided for @adminCatalogColFlags.
  ///
  /// In en, this message translates to:
  /// **'Flags'**
  String get adminCatalogColFlags;

  /// No description provided for @adminCatalogOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open place {name}'**
  String adminCatalogOpenSemantic(String name);

  /// No description provided for @adminCatalogBackToList.
  ///
  /// In en, this message translates to:
  /// **'Back to catalog'**
  String get adminCatalogBackToList;

  /// No description provided for @adminCatalogNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Place not found'**
  String get adminCatalogNotFoundTitle;

  /// No description provided for @adminCatalogNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'No place exists with this id. It may have been removed, or the link may be wrong.'**
  String get adminCatalogNotFoundMessage;

  /// No description provided for @adminCatalogActionUncertain.
  ///
  /// In en, this message translates to:
  /// **'The result of the last action is unknown. This page has been reloaded — check the status before trying again.'**
  String get adminCatalogActionUncertain;

  /// No description provided for @adminCatalogSectionLifecycle.
  ///
  /// In en, this message translates to:
  /// **'Lifecycle'**
  String get adminCatalogSectionLifecycle;

  /// No description provided for @adminCatalogSectionFlags.
  ///
  /// In en, this message translates to:
  /// **'Verification and placement'**
  String get adminCatalogSectionFlags;

  /// No description provided for @adminCatalogSectionIdentity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get adminCatalogSectionIdentity;

  /// No description provided for @adminCatalogSectionRooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get adminCatalogSectionRooms;

  /// No description provided for @adminCatalogSectionMedia.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get adminCatalogSectionMedia;

  /// No description provided for @adminCatalogPublicVisibility.
  ///
  /// In en, this message translates to:
  /// **'Guest visibility'**
  String get adminCatalogPublicVisibility;

  /// No description provided for @adminCatalogVisibleToGuests.
  ///
  /// In en, this message translates to:
  /// **'Visible and bookable'**
  String get adminCatalogVisibleToGuests;

  /// No description provided for @adminCatalogHiddenFromGuests.
  ///
  /// In en, this message translates to:
  /// **'Not visible to guests'**
  String get adminCatalogHiddenFromGuests;

  /// No description provided for @adminCatalogNoTransitions.
  ///
  /// In en, this message translates to:
  /// **'No status change is available from here.'**
  String get adminCatalogNoTransitions;

  /// No description provided for @adminCatalogArchivedNotice.
  ///
  /// In en, this message translates to:
  /// **'This place is archived. There is no way to restore it from the admin console.'**
  String get adminCatalogArchivedNotice;

  /// No description provided for @adminCatalogArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get adminCatalogArchive;

  /// No description provided for @adminCatalogArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this place?'**
  String get adminCatalogArchiveTitle;

  /// No description provided for @adminCatalogArchiveWarningIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This cannot be reversed from the admin console — there is no restore action.'**
  String get adminCatalogArchiveWarningIrreversible;

  /// No description provided for @adminCatalogArchiveWarningVisibility.
  ///
  /// In en, this message translates to:
  /// **'The place disappears from guest search and its public page immediately.'**
  String get adminCatalogArchiveWarningVisibility;

  /// No description provided for @adminCatalogArchiveWarningRooms.
  ///
  /// In en, this message translates to:
  /// **'Its rooms, rates and inventory are left untouched and are not released.'**
  String get adminCatalogArchiveWarningRooms;

  /// No description provided for @adminCatalogArchiveAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this cannot be undone here.'**
  String get adminCatalogArchiveAcknowledge;

  /// No description provided for @adminCatalogArchiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive place'**
  String get adminCatalogArchiveConfirm;

  /// No description provided for @adminCatalogFlagsRequireApproved.
  ///
  /// In en, this message translates to:
  /// **'Verified and featured can only be turned on for an approved or published place.'**
  String get adminCatalogFlagsRequireApproved;

  /// No description provided for @adminCatalogPriceLevel.
  ///
  /// In en, this message translates to:
  /// **'Price level'**
  String get adminCatalogPriceLevel;

  /// No description provided for @adminCatalogTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get adminCatalogTags;

  /// No description provided for @adminCatalogAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get adminCatalogAmenities;

  /// No description provided for @adminCatalogReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Editing a place replaces its tags, opening hours and amenities wholesale, so it is not offered here.'**
  String get adminCatalogReadOnlyNotice;

  /// No description provided for @adminCatalogNotAHotel.
  ///
  /// In en, this message translates to:
  /// **'This place has no hotel detail, so it has no rooms.'**
  String get adminCatalogNotAHotel;

  /// No description provided for @adminCatalogRoomsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No rooms.'**
  String get adminCatalogRoomsEmpty;

  /// No description provided for @adminCatalogRoomsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Rooms could not be loaded.'**
  String get adminCatalogRoomsUnavailable;

  /// No description provided for @adminCatalogRoomActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminCatalogRoomActive;

  /// No description provided for @adminCatalogRoomInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminCatalogRoomInactive;

  /// No description provided for @adminCatalogRoomCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get adminCatalogRoomCode;

  /// No description provided for @adminCatalogRoomType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminCatalogRoomType;

  /// No description provided for @adminCatalogRoomQuantity.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get adminCatalogRoomQuantity;

  /// No description provided for @adminCatalogRoomsBoundaryNotice.
  ///
  /// In en, this message translates to:
  /// **'Inventory and rates are managed outside the catalog.'**
  String get adminCatalogRoomsBoundaryNotice;

  /// No description provided for @adminCatalogMediaCount.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get adminCatalogMediaCount;

  /// No description provided for @adminCatalogMediaCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get adminCatalogMediaCover;

  /// No description provided for @adminCatalogMediaHasCover.
  ///
  /// In en, this message translates to:
  /// **'Set'**
  String get adminCatalogMediaHasCover;

  /// No description provided for @adminCatalogMediaNoCover.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get adminCatalogMediaNoCover;

  /// No description provided for @adminCatalogMediaReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'Read-only. Media management is a separate admin surface.'**
  String get adminCatalogMediaReadOnlyNotice;

  /// No description provided for @adminNavMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get adminNavMedia;

  /// No description provided for @adminMediaPickOwnerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a place'**
  String get adminMediaPickOwnerTitle;

  /// No description provided for @adminMediaOwnerScopeNotice.
  ///
  /// In en, this message translates to:
  /// **'Media is managed per place. The admin API can only read a place\'s gallery, so rooms, reviews and trip documents are not managed here.'**
  String get adminMediaOwnerScopeNotice;

  /// No description provided for @adminMediaPlaceSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search places'**
  String get adminMediaPlaceSearchLabel;

  /// No description provided for @adminMediaPlaceSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get adminMediaPlaceSearchClear;

  /// No description provided for @adminMediaPlaceSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Showing the first {count} matches. Narrow the search to find a specific place.'**
  String adminMediaPlaceSearchHint(int count);

  /// No description provided for @adminMediaNoPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places match this search.'**
  String get adminMediaNoPlacesFound;

  /// No description provided for @adminMediaOpenGallerySemantic.
  ///
  /// In en, this message translates to:
  /// **'Open the gallery for {name}'**
  String adminMediaOpenGallerySemantic(String name);

  /// No description provided for @adminMediaBackToPlaces.
  ///
  /// In en, this message translates to:
  /// **'Back to places'**
  String get adminMediaBackToPlaces;

  /// No description provided for @adminMediaEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No media'**
  String get adminMediaEmptyTitle;

  /// No description provided for @adminMediaEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'This place has no registered media yet.'**
  String get adminMediaEmptyMessage;

  /// No description provided for @adminMediaUrlRegistryNotice.
  ///
  /// In en, this message translates to:
  /// **'Media is registered by URL. There is no file upload — paste an existing http or https address.'**
  String get adminMediaUrlRegistryNotice;

  /// No description provided for @adminMediaAmbiguousOrderNotice.
  ///
  /// In en, this message translates to:
  /// **'Two or more items share a position, so their order is undefined. Moving any item renumbers the whole gallery and resolves it.'**
  String get adminMediaAmbiguousOrderNotice;

  /// No description provided for @adminMediaNoCoverNotice.
  ///
  /// In en, this message translates to:
  /// **'No cover is set for this place.'**
  String get adminMediaNoCoverNotice;

  /// No description provided for @adminMediaCoverIs.
  ///
  /// In en, this message translates to:
  /// **'Cover: item {id}'**
  String adminMediaCoverIs(int id);

  /// No description provided for @adminMediaActionUncertain.
  ///
  /// In en, this message translates to:
  /// **'The result of the last action is unknown. The gallery has been reloaded — check it before trying again, because deactivation cannot be undone here.'**
  String get adminMediaActionUncertain;

  /// No description provided for @adminMediaDismissNotice.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminMediaDismissNotice;

  /// No description provided for @adminMediaAssetSemantic.
  ///
  /// In en, this message translates to:
  /// **'Media item {id}'**
  String adminMediaAssetSemantic(int id);

  /// No description provided for @adminMediaUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get adminMediaUrl;

  /// No description provided for @adminMediaUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'An absolute http or https address, including the host.'**
  String get adminMediaUrlHelper;

  /// No description provided for @adminMediaUrlQueryHidden.
  ///
  /// In en, this message translates to:
  /// **'A query string is present and is not shown here.'**
  String get adminMediaUrlQueryHidden;

  /// No description provided for @adminMediaThumbnailUrl.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get adminMediaThumbnailUrl;

  /// No description provided for @adminMediaThumbnailUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL (optional)'**
  String get adminMediaThumbnailUrlOptional;

  /// No description provided for @adminMediaType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminMediaType;

  /// No description provided for @adminMediaAltText.
  ///
  /// In en, this message translates to:
  /// **'Alt text'**
  String get adminMediaAltText;

  /// No description provided for @adminMediaAltTextOptional.
  ///
  /// In en, this message translates to:
  /// **'Alt text (optional)'**
  String get adminMediaAltTextOptional;

  /// No description provided for @adminMediaSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get adminMediaSortOrder;

  /// No description provided for @adminMediaSortOrderOptional.
  ///
  /// In en, this message translates to:
  /// **'Position (optional)'**
  String get adminMediaSortOrderOptional;

  /// No description provided for @adminMediaActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminMediaActive;

  /// No description provided for @adminMediaInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminMediaInactive;

  /// No description provided for @adminMediaCover.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get adminMediaCover;

  /// No description provided for @adminMediaPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Preview unavailable'**
  String get adminMediaPreviewUnavailable;

  /// No description provided for @adminMediaPreviewNotAnImage.
  ///
  /// In en, this message translates to:
  /// **'Not an image'**
  String get adminMediaPreviewNotAnImage;

  /// No description provided for @adminMediaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add media'**
  String get adminMediaAdd;

  /// No description provided for @adminMediaAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Register media'**
  String get adminMediaAddTitle;

  /// No description provided for @adminMediaEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminMediaEdit;

  /// No description provided for @adminMediaEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit media'**
  String get adminMediaEditTitle;

  /// No description provided for @adminMediaSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminMediaSave;

  /// No description provided for @adminMediaCreate.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get adminMediaCreate;

  /// No description provided for @adminMediaSetCover.
  ///
  /// In en, this message translates to:
  /// **'Set as cover'**
  String get adminMediaSetCover;

  /// No description provided for @adminMediaSetAsCover.
  ///
  /// In en, this message translates to:
  /// **'Use as the cover image'**
  String get adminMediaSetAsCover;

  /// No description provided for @adminMediaCoverReplacesPrevious.
  ///
  /// In en, this message translates to:
  /// **'The place\'s current cover, if any, stops being the cover.'**
  String get adminMediaCoverReplacesPrevious;

  /// No description provided for @adminMediaCoverImageOnly.
  ///
  /// In en, this message translates to:
  /// **'Only an image can be the cover.'**
  String get adminMediaCoverImageOnly;

  /// No description provided for @adminMediaMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get adminMediaMoveUp;

  /// No description provided for @adminMediaMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get adminMediaMoveDown;

  /// No description provided for @adminMediaEditReplacesNotice.
  ///
  /// In en, this message translates to:
  /// **'Saving replaces every field shown here. Clearing a box clears the stored value.'**
  String get adminMediaEditReplacesNotice;

  /// No description provided for @adminMediaUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'A URL is required.'**
  String get adminMediaUrlRequired;

  /// No description provided for @adminMediaUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an absolute http or https URL with a host.'**
  String get adminMediaUrlInvalid;

  /// No description provided for @adminMediaSortOrderInvalid.
  ///
  /// In en, this message translates to:
  /// **'Position must be a whole number of 0 or more.'**
  String get adminMediaSortOrderInvalid;

  /// No description provided for @adminMediaDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminMediaDeactivate;

  /// No description provided for @adminMediaDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate this media?'**
  String get adminMediaDeactivateTitle;

  /// No description provided for @adminMediaDeactivateWarningHidden.
  ///
  /// In en, this message translates to:
  /// **'It disappears from the place\'s public gallery immediately.'**
  String get adminMediaDeactivateWarningHidden;

  /// No description provided for @adminMediaDeactivateWarningNoRestore.
  ///
  /// In en, this message translates to:
  /// **'There is no way to reactivate it from the admin console.'**
  String get adminMediaDeactivateWarningNoRestore;

  /// No description provided for @adminMediaDeactivateWarningCover.
  ///
  /// In en, this message translates to:
  /// **'This item is the cover. The place will have no cover afterwards — nothing is promoted in its place.'**
  String get adminMediaDeactivateWarningCover;

  /// No description provided for @adminMediaDeactivateAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand this cannot be undone here.'**
  String get adminMediaDeactivateAcknowledge;

  /// No description provided for @adminMediaDeactivateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deactivate media'**
  String get adminMediaDeactivateConfirm;

  /// No description provided for @adminCatalogManageMedia.
  ///
  /// In en, this message translates to:
  /// **'Manage media'**
  String get adminCatalogManageMedia;

  /// No description provided for @adminCatalogManageMediaSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open the media gallery for {name}'**
  String adminCatalogManageMediaSemantic(String name);

  /// No description provided for @adminMediaBackToPlaceDetail.
  ///
  /// In en, this message translates to:
  /// **'Back to place details'**
  String get adminMediaBackToPlaceDetail;

  /// No description provided for @adminMediaOwnerContext.
  ///
  /// In en, this message translates to:
  /// **'Place #{id} — all media below belongs to this place'**
  String adminMediaOwnerContext(int id);

  /// No description provided for @adminMediaOwnerMismatch.
  ///
  /// In en, this message translates to:
  /// **'This gallery could not be shown: the server returned media belonging to a different place. Nothing here can be changed until the response matches the place that was requested.'**
  String get adminMediaOwnerMismatch;

  /// No description provided for @partnerMessagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get partnerMessagesTitle;

  /// No description provided for @partnerMessagesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Guest messages about bookings at the properties you own.'**
  String get partnerMessagesSubtitle;

  /// No description provided for @partnerMessagesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading conversations…'**
  String get partnerMessagesLoading;

  /// No description provided for @partnerMessagesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No guest messages yet'**
  String get partnerMessagesEmptyTitle;

  /// No description provided for @partnerMessagesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'When a guest starts a conversation about one of their bookings, it appears here.'**
  String get partnerMessagesEmptyMessage;

  /// No description provided for @partnerMessagesUnpaginatedNotice.
  ///
  /// In en, this message translates to:
  /// **'This inbox is not paginated — every conversation the server returned is shown.'**
  String get partnerMessagesUnpaginatedNotice;

  /// No description provided for @partnerMessagesUnreadBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String partnerMessagesUnreadBadge(int count);

  /// No description provided for @partnerMessagesUnreadTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} unread across {total} conversations'**
  String partnerMessagesUnreadTotal(int count, int total);

  /// No description provided for @partnerMessagesNoPreview.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get partnerMessagesNoPreview;

  /// No description provided for @partnerMessagesNoSubject.
  ///
  /// In en, this message translates to:
  /// **'No subject'**
  String get partnerMessagesNoSubject;

  /// No description provided for @partnerMessagesBookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking {code}'**
  String partnerMessagesBookingLabel(String code);

  /// No description provided for @partnerMessagesGuestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest: {name}'**
  String partnerMessagesGuestLabel(String name);

  /// No description provided for @partnerMessagesOpenSemantic.
  ///
  /// In en, this message translates to:
  /// **'Open the conversation for booking {code}'**
  String partnerMessagesOpenSemantic(String code);

  /// No description provided for @partnerMessagesBackToInbox.
  ///
  /// In en, this message translates to:
  /// **'Back to inbox'**
  String get partnerMessagesBackToInbox;

  /// No description provided for @partnerMessagesThreadLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading conversation…'**
  String get partnerMessagesThreadLoading;

  /// No description provided for @partnerMessagesThreadEmpty.
  ///
  /// In en, this message translates to:
  /// **'This conversation has no messages yet.'**
  String get partnerMessagesThreadEmpty;

  /// No description provided for @partnerMessagesUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Conversation not available'**
  String get partnerMessagesUnavailableTitle;

  /// No description provided for @partnerMessagesUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'This conversation could not be opened. It may no longer exist. Return to the inbox and refresh.'**
  String get partnerMessagesUnavailableMessage;

  /// No description provided for @partnerMessagesSenderHost.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get partnerMessagesSenderHost;

  /// No description provided for @partnerMessagesSenderGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get partnerMessagesSenderGuest;

  /// No description provided for @partnerMessagesSenderSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get partnerMessagesSenderSupport;

  /// No description provided for @partnerMessagesStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get partnerMessagesStatusOpen;

  /// No description provided for @partnerMessagesStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get partnerMessagesStatusClosed;

  /// No description provided for @partnerMessagesStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get partnerMessagesStatusArchived;

  /// No description provided for @partnerMessagesComposerLabel.
  ///
  /// In en, this message translates to:
  /// **'Reply to the guest'**
  String get partnerMessagesComposerLabel;

  /// No description provided for @partnerMessagesComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Write your reply…'**
  String get partnerMessagesComposerHint;

  /// No description provided for @partnerMessagesSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get partnerMessagesSend;

  /// No description provided for @partnerMessagesSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get partnerMessagesSending;

  /// No description provided for @partnerMessagesSendEmpty.
  ///
  /// In en, this message translates to:
  /// **'Write a message before sending.'**
  String get partnerMessagesSendEmpty;

  /// No description provided for @partnerMessagesSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent.'**
  String get partnerMessagesSent;

  /// No description provided for @partnerMessagesSendFailed.
  ///
  /// In en, this message translates to:
  /// **'The message could not be sent.'**
  String get partnerMessagesSendFailed;

  /// No description provided for @partnerMessagesSendUncertain.
  ///
  /// In en, this message translates to:
  /// **'The connection timed out and your message may already have been sent. Reopen this conversation to check before writing it again — it will not be sent automatically.'**
  String get partnerMessagesSendUncertain;

  /// No description provided for @partnerMessagesArchivedNotice.
  ///
  /// In en, this message translates to:
  /// **'This conversation was archived and can no longer receive messages.'**
  String get partnerMessagesArchivedNotice;

  /// No description provided for @partnerMessagesClosedNotice.
  ///
  /// In en, this message translates to:
  /// **'This conversation is closed. Sending a reply reopens it for the guest.'**
  String get partnerMessagesClosedNotice;

  /// No description provided for @partnerNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get partnerNotificationsTitle;

  /// No description provided for @partnerNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything your account has received, newest first.'**
  String get partnerNotificationsSubtitle;

  /// No description provided for @partnerNotificationsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading notifications…'**
  String get partnerNotificationsLoading;

  /// No description provided for @partnerNotificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get partnerNotificationsEmptyTitle;

  /// No description provided for @partnerNotificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Updates about your properties, bookings, reviews and guest messages will appear here.'**
  String get partnerNotificationsEmptyMessage;

  /// No description provided for @partnerNotificationsInboxNotice.
  ///
  /// In en, this message translates to:
  /// **'This is your account\'s complete inbox. It can include platform announcements and personal travel updates as well as property activity — the server does not label notifications by audience.'**
  String get partnerNotificationsInboxNotice;

  /// No description provided for @partnerNotificationsUnpaginatedNotice.
  ///
  /// In en, this message translates to:
  /// **'This inbox is not paginated — every notification the server returned is shown.'**
  String get partnerNotificationsUnpaginatedNotice;

  /// No description provided for @partnerNotificationsUnreadLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get partnerNotificationsUnreadLabel;

  /// No description provided for @partnerNotificationsMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark as read'**
  String get partnerNotificationsMarkRead;

  /// No description provided for @partnerNotificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get partnerNotificationsMarkAllRead;

  /// No description provided for @partnerNotificationsMarkedRead.
  ///
  /// In en, this message translates to:
  /// **'Marked as read.'**
  String get partnerNotificationsMarkedRead;

  /// No description provided for @partnerNotificationsMarkedAllRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get partnerNotificationsMarkedAllRead;

  /// No description provided for @partnerNotificationsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get partnerNotificationsDelete;

  /// No description provided for @partnerNotificationsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this notification?'**
  String get partnerNotificationsDeleteTitle;

  /// No description provided for @partnerNotificationsDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from the server permanently. There is no archive and this cannot be undone.'**
  String get partnerNotificationsDeleteMessage;

  /// No description provided for @partnerNotificationsDeleteCta.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get partnerNotificationsDeleteCta;

  /// No description provided for @partnerNotificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted.'**
  String get partnerNotificationsDeleted;

  /// No description provided for @partnerNotificationsActionFailed.
  ///
  /// In en, this message translates to:
  /// **'That could not be completed. Nothing was changed.'**
  String get partnerNotificationsActionFailed;

  /// No description provided for @partnerNotificationsActionBusy.
  ///
  /// In en, this message translates to:
  /// **'Please wait for the current action to finish.'**
  String get partnerNotificationsActionBusy;

  /// No description provided for @partnerNotificationsActionNotFound.
  ///
  /// In en, this message translates to:
  /// **'This notification no longer exists. Refresh to see the current list.'**
  String get partnerNotificationsActionNotFound;

  /// No description provided for @partnerNotificationsNoDestination.
  ///
  /// In en, this message translates to:
  /// **'This notification does not link to a screen in the partner workspace.'**
  String get partnerNotificationsNoDestination;

  /// No description provided for @partnerNotificationsTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get partnerNotificationsTypeUnknown;

  /// No description provided for @adminReviewModerationNotice.
  ///
  /// In en, this message translates to:
  /// **'Moderation changes what guests see. Every action is confirmed first and recorded in the activity log.'**
  String get adminReviewModerationNotice;

  /// No description provided for @adminReviewApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get adminReviewApprove;

  /// No description provided for @adminReviewReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get adminReviewReject;

  /// No description provided for @adminReviewHide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get adminReviewHide;

  /// No description provided for @adminReviewActionCurrent.
  ///
  /// In en, this message translates to:
  /// **'This review already has that status.'**
  String get adminReviewActionCurrent;

  /// No description provided for @adminReviewApproveTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve this review?'**
  String get adminReviewApproveTitle;

  /// No description provided for @adminReviewApproveWarning.
  ///
  /// In en, this message translates to:
  /// **'It becomes publicly visible, counts towards the place\'s rating, and its author is notified.'**
  String get adminReviewApproveWarning;

  /// No description provided for @adminReviewApproveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve review'**
  String get adminReviewApproveConfirm;

  /// No description provided for @adminReviewRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this review?'**
  String get adminReviewRejectTitle;

  /// No description provided for @adminReviewRejectWarning.
  ///
  /// In en, this message translates to:
  /// **'It stays hidden from guests and its author is notified, together with the reason you give below.'**
  String get adminReviewRejectWarning;

  /// No description provided for @adminReviewRejectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reject review'**
  String get adminReviewRejectConfirm;

  /// No description provided for @adminReviewRejectReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection'**
  String get adminReviewRejectReasonLabel;

  /// No description provided for @adminReviewRejectReasonHelp.
  ///
  /// In en, this message translates to:
  /// **'Sent to the review\'s author. Keep it factual.'**
  String get adminReviewRejectReasonHelp;

  /// No description provided for @adminReviewRejectReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason before rejecting.'**
  String get adminReviewRejectReasonRequired;

  /// No description provided for @adminReviewHideTitle.
  ///
  /// In en, this message translates to:
  /// **'Hide this review?'**
  String get adminReviewHideTitle;

  /// No description provided for @adminReviewHideWarning.
  ///
  /// In en, this message translates to:
  /// **'It disappears from the place\'s public page and stops counting towards its rating. Its author is not notified.'**
  String get adminReviewHideWarning;

  /// No description provided for @adminReviewHideConfirm.
  ///
  /// In en, this message translates to:
  /// **'Hide review'**
  String get adminReviewHideConfirm;

  /// No description provided for @adminReviewModerated.
  ///
  /// In en, this message translates to:
  /// **'Review updated.'**
  String get adminReviewModerated;

  /// No description provided for @adminReviewModerationFailed.
  ///
  /// In en, this message translates to:
  /// **'The review could not be updated. Nothing was changed.'**
  String get adminReviewModerationFailed;

  /// No description provided for @adminNavReferenceData.
  ///
  /// In en, this message translates to:
  /// **'Reference data'**
  String get adminNavReferenceData;

  /// No description provided for @adminReferenceTabAmenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get adminReferenceTabAmenities;

  /// No description provided for @adminReferenceTabCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get adminReferenceTabCategories;

  /// No description provided for @adminReferenceCmsStatusNotice.
  ///
  /// In en, this message translates to:
  /// **'CMS status controls whether an entry is marked active in this console. It does not currently filter public or customer API results — the backend stores the flag but no read applies it.'**
  String get adminReferenceCmsStatusNotice;

  /// No description provided for @adminReferenceNoDeleteNotice.
  ///
  /// In en, this message translates to:
  /// **'Reference entries cannot be deleted. The admin API provides list, create, update and CMS status only.'**
  String get adminReferenceNoDeleteNotice;

  /// No description provided for @adminReferenceOrderingNotice.
  ///
  /// In en, this message translates to:
  /// **'Rows appear in the order the server returned them. The backend applies no ordering and does not sort by sort order.'**
  String get adminReferenceOrderingNotice;

  /// No description provided for @adminReferenceUpdateReplacesNotice.
  ///
  /// In en, this message translates to:
  /// **'Saving replaces every field on this entry, so clearing a box clears the stored value.'**
  String get adminReferenceUpdateReplacesNotice;

  /// No description provided for @adminReferenceSlugHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank and the server derives the slug from the name. It cannot be changed after the entry is created.'**
  String get adminReferenceSlugHelper;

  /// No description provided for @adminReferenceSlugFixedNotice.
  ///
  /// In en, this message translates to:
  /// **'The slug is fixed after creation. Other parts of the system resolve this entry by slug, so it is not editable here.'**
  String get adminReferenceSlugFixedNotice;

  /// No description provided for @adminReferenceTypeNotice.
  ///
  /// In en, this message translates to:
  /// **'Type is used to target coupons and personalization rules, so it is chosen from existing values rather than typed.'**
  String get adminReferenceTypeNotice;

  /// No description provided for @adminReferenceParentGuardNotice.
  ///
  /// In en, this message translates to:
  /// **'This category and everything beneath it are not offered, so a parent cannot be set to a child of itself.'**
  String get adminReferenceParentGuardNotice;

  /// No description provided for @adminReferenceStatusPublicNotice.
  ///
  /// In en, this message translates to:
  /// **'This changes CMS status only. It does not guarantee the entry is removed from public or customer API results.'**
  String get adminReferenceStatusPublicNotice;

  /// No description provided for @adminReferenceNewAmenity.
  ///
  /// In en, this message translates to:
  /// **'New amenity'**
  String get adminReferenceNewAmenity;

  /// No description provided for @adminReferenceNewCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get adminReferenceNewCategory;

  /// No description provided for @adminReferenceRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get adminReferenceRefresh;

  /// No description provided for @adminReferenceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get adminReferenceEdit;

  /// No description provided for @adminReferenceSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get adminReferenceSave;

  /// No description provided for @adminReferenceCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get adminReferenceCreate;

  /// No description provided for @adminReferenceDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get adminReferenceDismiss;

  /// No description provided for @adminReferenceAmenityCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New amenity'**
  String get adminReferenceAmenityCreateTitle;

  /// No description provided for @adminReferenceAmenityEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit amenity'**
  String get adminReferenceAmenityEditTitle;

  /// No description provided for @adminReferenceCategoryCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get adminReferenceCategoryCreateTitle;

  /// No description provided for @adminReferenceCategoryEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get adminReferenceCategoryEditTitle;

  /// No description provided for @adminReferenceFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminReferenceFieldName;

  /// No description provided for @adminReferenceFieldSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get adminReferenceFieldSlug;

  /// No description provided for @adminReferenceFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get adminReferenceFieldIcon;

  /// No description provided for @adminReferenceFieldGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get adminReferenceFieldGroup;

  /// No description provided for @adminReferenceFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminReferenceFieldDescription;

  /// No description provided for @adminReferenceFieldSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get adminReferenceFieldSortOrder;

  /// No description provided for @adminReferenceFieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminReferenceFieldType;

  /// No description provided for @adminReferenceFieldParent.
  ///
  /// In en, this message translates to:
  /// **'Parent category'**
  String get adminReferenceFieldParent;

  /// No description provided for @adminReferenceFieldColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get adminReferenceFieldColor;

  /// No description provided for @adminReferenceFieldCoverImageUrl.
  ///
  /// In en, this message translates to:
  /// **'Cover image URL'**
  String get adminReferenceFieldCoverImageUrl;

  /// No description provided for @adminReferenceParentNone.
  ///
  /// In en, this message translates to:
  /// **'No parent (top level)'**
  String get adminReferenceParentNone;

  /// No description provided for @adminReferenceValueNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get adminReferenceValueNotSet;

  /// No description provided for @adminReferenceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get adminReferenceNameRequired;

  /// No description provided for @adminReferenceSortOrderInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number, or leave blank.'**
  String get adminReferenceSortOrderInvalid;

  /// No description provided for @adminReferenceColName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get adminReferenceColName;

  /// No description provided for @adminReferenceColSlug.
  ///
  /// In en, this message translates to:
  /// **'Slug'**
  String get adminReferenceColSlug;

  /// No description provided for @adminReferenceColGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get adminReferenceColGroup;

  /// No description provided for @adminReferenceColType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminReferenceColType;

  /// No description provided for @adminReferenceColParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get adminReferenceColParent;

  /// No description provided for @adminReferenceColSortOrder.
  ///
  /// In en, this message translates to:
  /// **'Sort order'**
  String get adminReferenceColSortOrder;

  /// No description provided for @adminReferenceColCmsStatus.
  ///
  /// In en, this message translates to:
  /// **'CMS status'**
  String get adminReferenceColCmsStatus;

  /// No description provided for @adminReferenceColAction.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get adminReferenceColAction;

  /// No description provided for @adminReferenceStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active in CMS'**
  String get adminReferenceStatusActive;

  /// No description provided for @adminReferenceStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive in CMS'**
  String get adminReferenceStatusInactive;

  /// No description provided for @adminReferenceActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate in CMS'**
  String get adminReferenceActivate;

  /// No description provided for @adminReferenceDeactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate in CMS'**
  String get adminReferenceDeactivate;

  /// No description provided for @adminReferenceActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate in CMS?'**
  String get adminReferenceActivateTitle;

  /// No description provided for @adminReferenceDeactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Deactivate in CMS?'**
  String get adminReferenceDeactivateTitle;

  /// No description provided for @adminReferenceActivateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be marked active in the CMS.'**
  String adminReferenceActivateBody(String name);

  /// No description provided for @adminReferenceDeactivateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will be marked inactive in the CMS.'**
  String adminReferenceDeactivateBody(String name);

  /// No description provided for @adminReferenceStatusConfirm.
  ///
  /// In en, this message translates to:
  /// **'Update CMS status'**
  String get adminReferenceStatusConfirm;

  /// No description provided for @adminReferenceMutationFailed.
  ///
  /// In en, this message translates to:
  /// **'The entry could not be saved. Nothing was changed.'**
  String get adminReferenceMutationFailed;

  /// No description provided for @adminReferenceDuplicateSlug.
  ///
  /// In en, this message translates to:
  /// **'That slug is already in use. Choose a different name or slug.'**
  String get adminReferenceDuplicateSlug;

  /// No description provided for @adminReferenceMutationUncertain.
  ///
  /// In en, this message translates to:
  /// **'The result of the last action is unknown. This list has been reloaded — check it before trying again.'**
  String get adminReferenceMutationUncertain;

  /// No description provided for @adminReferenceEmptyAmenities.
  ///
  /// In en, this message translates to:
  /// **'No amenities yet.'**
  String get adminReferenceEmptyAmenities;

  /// No description provided for @adminReferenceEmptyCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet.'**
  String get adminReferenceEmptyCategories;

  /// No description provided for @adminReferenceEditSemantic.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String adminReferenceEditSemantic(String name);

  /// No description provided for @adminReferenceTabLocations.
  ///
  /// In en, this message translates to:
  /// **'Locations'**
  String get adminReferenceTabLocations;

  /// No description provided for @adminLocationNew.
  ///
  /// In en, this message translates to:
  /// **'New location'**
  String get adminLocationNew;

  /// No description provided for @adminLocationCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'New location'**
  String get adminLocationCreateTitle;

  /// No description provided for @adminLocationEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit location'**
  String get adminLocationEditTitle;

  /// No description provided for @adminLocationColCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get adminLocationColCode;

  /// No description provided for @adminLocationColLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get adminLocationColLevel;

  /// No description provided for @adminLocationColCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get adminLocationColCoordinates;

  /// No description provided for @adminLocationFieldCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get adminLocationFieldCode;

  /// No description provided for @adminLocationFieldOldName.
  ///
  /// In en, this message translates to:
  /// **'Former name'**
  String get adminLocationFieldOldName;

  /// No description provided for @adminLocationFieldFullPath.
  ///
  /// In en, this message translates to:
  /// **'Full path'**
  String get adminLocationFieldFullPath;

  /// No description provided for @adminLocationFieldLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get adminLocationFieldLevel;

  /// No description provided for @adminLocationFieldCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get adminLocationFieldCoordinates;

  /// No description provided for @adminLocationCodeHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. A short business key other systems match this location by.'**
  String get adminLocationCodeHelper;

  /// No description provided for @adminLocationCodeHelperFixed.
  ///
  /// In en, this message translates to:
  /// **'A code can be replaced but not removed — other systems match this location by it.'**
  String get adminLocationCodeHelperFixed;

  /// No description provided for @adminLocationCodeCannotBeCleared.
  ///
  /// In en, this message translates to:
  /// **'A code cannot be removed. Enter a replacement, or leave the existing one in place.'**
  String get adminLocationCodeCannotBeCleared;

  /// No description provided for @adminLocationReadOnlyNotice.
  ///
  /// In en, this message translates to:
  /// **'The values below are stored by the server and are not editable here. They are saved back unchanged.'**
  String get adminLocationReadOnlyNotice;

  /// No description provided for @adminLocationFieldParent.
  ///
  /// In en, this message translates to:
  /// **'Parent location'**
  String get adminLocationFieldParent;

  /// No description provided for @adminLocationParentHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a parent location'**
  String get adminLocationParentHint;

  /// No description provided for @adminLocationParentRequired.
  ///
  /// In en, this message translates to:
  /// **'This type needs a parent location. Only a COUNTRY can be top level.'**
  String get adminLocationParentRequired;

  /// No description provided for @adminLocationParentNoCandidates.
  ///
  /// In en, this message translates to:
  /// **'No loaded location can be the parent of this type.'**
  String get adminLocationParentNoCandidates;

  /// No description provided for @adminLocationParentCleared.
  ///
  /// In en, this message translates to:
  /// **'The previous parent cannot hold this type, so it was cleared. Choose a new parent.'**
  String get adminLocationParentCleared;

  /// No description provided for @adminLocationParentGuardNotice.
  ///
  /// In en, this message translates to:
  /// **'This location and everything beneath it are not offered, so it cannot be placed under itself.'**
  String get adminLocationParentGuardNotice;

  /// No description provided for @adminLocationHierarchyRule.
  ///
  /// In en, this message translates to:
  /// **'A COUNTRY is top level. A PROVINCE or CITY goes under a COUNTRY. An AREA goes under a PROVINCE or CITY.'**
  String get adminLocationHierarchyRule;

  /// No description provided for @adminLocationTypeReservedMarker.
  ///
  /// In en, this message translates to:
  /// **'Reserved — not available'**
  String get adminLocationTypeReservedMarker;

  /// No description provided for @adminLocationTypeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This type cannot be saved. WARD and COMMUNE are reserved; choose COUNTRY, PROVINCE, CITY or AREA.'**
  String get adminLocationTypeUnavailable;

  /// No description provided for @adminLocationTypeBlockedByChildren.
  ///
  /// In en, this message translates to:
  /// **'This location has child locations that cannot sit under this type. Keep the current type, or move those children first.'**
  String get adminLocationTypeBlockedByChildren;

  /// No description provided for @adminLocationFullPathGeneratedNotice.
  ///
  /// In en, this message translates to:
  /// **'Generated by the server from the parent and name when saved. This preview is only a guide.'**
  String get adminLocationFullPathGeneratedNotice;

  /// No description provided for @adminLocationEmpty.
  ///
  /// In en, this message translates to:
  /// **'No locations yet.'**
  String get adminLocationEmpty;

  /// No description provided for @adminLocationFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No locations match this search.'**
  String get adminLocationFilterEmpty;

  /// No description provided for @adminLocationFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Search locations'**
  String get adminLocationFilterLabel;

  /// No description provided for @adminLocationFilterHelper.
  ///
  /// In en, this message translates to:
  /// **'Filters the locations already loaded, by name, slug, code or former name.'**
  String get adminLocationFilterHelper;

  /// No description provided for @adminLocationFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get adminLocationFilterClear;

  /// No description provided for @adminLocationDuplicateCodeOrSlug.
  ///
  /// In en, this message translates to:
  /// **'That code or slug is already in use. Choose a different one.'**
  String get adminLocationDuplicateCodeOrSlug;

  /// No description provided for @surfaceTitlePartner.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Trip Partner'**
  String get surfaceTitlePartner;

  /// No description provided for @surfaceTitleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Plan Your Trip Admin'**
  String get surfaceTitleAdmin;

  /// No description provided for @authPartnerLoginHero.
  ///
  /// In en, this message translates to:
  /// **'Run your properties, bookings and payouts from one workspace.'**
  String get authPartnerLoginHero;

  /// No description provided for @authPartnerLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Partner sign in'**
  String get authPartnerLoginTitle;

  /// No description provided for @authPartnerLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your partner account to open the workspace.'**
  String get authPartnerLoginSubtitle;

  /// No description provided for @authAdminLoginHero.
  ///
  /// In en, this message translates to:
  /// **'Operate the Plan Your Trip platform.'**
  String get authAdminLoginHero;

  /// No description provided for @authAdminLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin sign in'**
  String get authAdminLoginTitle;

  /// No description provided for @authAdminLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with an administrator account to open the console.'**
  String get authAdminLoginSubtitle;

  /// No description provided for @authStaffAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode and self sign-up are only available in the traveller app. This workspace needs an existing account.'**
  String get authStaffAccountRequired;

  /// No description provided for @surfaceAccessDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to this application'**
  String get surfaceAccessDeniedTitle;

  /// No description provided for @surfaceAccessDeniedUser.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t use the traveller app. Sign out, then sign in with a traveller account.'**
  String get surfaceAccessDeniedUser;

  /// No description provided for @surfaceAccessDeniedPartner.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t use the Partner workspace. Sign out, then sign in with a partner account.'**
  String get surfaceAccessDeniedPartner;

  /// No description provided for @surfaceAccessDeniedAdmin.
  ///
  /// In en, this message translates to:
  /// **'This account can\'t use the Admin console. Sign out, then sign in with an administrator account.'**
  String get surfaceAccessDeniedAdmin;

  /// No description provided for @surfaceSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String surfaceSignedInAs(String email);

  /// No description provided for @surfaceSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get surfaceSignOut;

  /// No description provided for @surfaceConfigErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'This application isn\'t configured'**
  String get surfaceConfigErrorTitle;

  /// No description provided for @surfaceConfigErrorBody.
  ///
  /// In en, this message translates to:
  /// **'It couldn\'t tell which application to open. Start it with one of the documented entrypoints.'**
  String get surfaceConfigErrorBody;

  /// No description provided for @adminReviewModerationUncertain.
  ///
  /// In en, this message translates to:
  /// **'The result of the last action is unknown. This page has been reloaded — check the review\'s status before trying again.'**
  String get adminReviewModerationUncertain;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server did not respond in time. Please try again.'**
  String get authErrorTimeout;

  /// No description provided for @authErrorServer.
  ///
  /// In en, this message translates to:
  /// **'The service is temporarily unavailable. Please try again later.'**
  String get authErrorServer;

  /// No description provided for @authErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check the highlighted fields.'**
  String get authErrorValidation;

  /// No description provided for @authErrorEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'That email address already has an account.'**
  String get authErrorEmailTaken;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Email or password is incorrect.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorAccountDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Contact support to restore access.'**
  String get authErrorAccountDisabled;

  /// No description provided for @authErrorAccountUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This account cannot sign in. Contact support.'**
  String get authErrorAccountUnavailable;

  /// No description provided for @authErrorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Verify your email address before signing in.'**
  String get authErrorEmailNotVerified;

  /// No description provided for @authErrorTokenInvalid.
  ///
  /// In en, this message translates to:
  /// **'This link is invalid or has already been used.'**
  String get authErrorTokenInvalid;

  /// No description provided for @authErrorTokenExpired.
  ///
  /// In en, this message translates to:
  /// **'This link has expired. Request a new one.'**
  String get authErrorTokenExpired;

  /// No description provided for @authErrorCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Your current password is incorrect.'**
  String get authErrorCurrentPassword;

  /// No description provided for @authErrorPasswordUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Choose a password different from your current one.'**
  String get authErrorPasswordUnchanged;

  /// No description provided for @authErrorEmailDelivery.
  ///
  /// In en, this message translates to:
  /// **'Email delivery is unavailable right now. Please try again later.'**
  String get authErrorEmailDelivery;

  /// No description provided for @authErrorSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Sign in again.'**
  String get authErrorSessionExpired;

  /// No description provided for @authValidationPasswordMax.
  ///
  /// In en, this message translates to:
  /// **'Password must be at most 72 bytes.'**
  String get authValidationPasswordMax;

  /// No description provided for @authValidationTermsRequired.
  ///
  /// In en, this message translates to:
  /// **'Accept the Partner terms to continue.'**
  String get authValidationTermsRequired;

  /// No description provided for @authValidationTokenRequired.
  ///
  /// In en, this message translates to:
  /// **'Paste the token from your link.'**
  String get authValidationTokenRequired;

  /// No description provided for @authPartnerBecomeQuestion.
  ///
  /// In en, this message translates to:
  /// **'New to Plan Your Trip?'**
  String get authPartnerBecomeQuestion;

  /// No description provided for @authPartnerBecomeAction.
  ///
  /// In en, this message translates to:
  /// **'Become a Partner'**
  String get authPartnerBecomeAction;

  /// No description provided for @partnerRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your Partner account'**
  String get partnerRegisterTitle;

  /// No description provided for @partnerRegisterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'List your property and manage bookings, rates and payouts in one workspace.'**
  String get partnerRegisterSubtitle;

  /// No description provided for @partnerRegisterAction.
  ///
  /// In en, this message translates to:
  /// **'Create Partner account'**
  String get partnerRegisterAction;

  /// No description provided for @partnerRegisterTerms.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Partner terms'**
  String get partnerRegisterTerms;

  /// No description provided for @partnerRegisterTermsHint.
  ///
  /// In en, this message translates to:
  /// **'The terms version you accept is recorded with your account.'**
  String get partnerRegisterTermsHint;

  /// No description provided for @partnerRegisterHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have a Partner account?'**
  String get partnerRegisterHaveAccount;

  /// No description provided for @partnerRegisterSignInAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get partnerRegisterSignInAction;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your Partner account for {email} is created. Verify the address to sign in.'**
  String verifyEmailSubtitle(String email);

  /// No description provided for @verifyEmailNoDeliveryNotice.
  ///
  /// In en, this message translates to:
  /// **'In local development no email is delivered. The backend logs a verification link marked [DEV ONLY — NO EMAIL SENT]; copy the token after #token= and paste it below.'**
  String get verifyEmailNoDeliveryNotice;

  /// No description provided for @verifyEmailTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification token'**
  String get verifyEmailTokenLabel;

  /// No description provided for @verifyEmailAction.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmailAction;

  /// No description provided for @verifyEmailSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully'**
  String get verifyEmailSuccessTitle;

  /// No description provided for @verifyEmailSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your address is verified. You can sign in to the Partner workspace now.'**
  String get verifyEmailSuccessBody;

  /// No description provided for @verifyEmailAlreadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Already verified'**
  String get verifyEmailAlreadyTitle;

  /// No description provided for @verifyEmailAlreadyBody.
  ///
  /// In en, this message translates to:
  /// **'This email address is already verified. You can sign in.'**
  String get verifyEmailAlreadyBody;

  /// No description provided for @verifyEmailContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue to Partner sign in'**
  String get verifyEmailContinueAction;

  /// No description provided for @verifyEmailResendAction.
  ///
  /// In en, this message translates to:
  /// **'Resend verification'**
  String get verifyEmailResendAction;

  /// No description provided for @verifyEmailResendCooldown.
  ///
  /// In en, this message translates to:
  /// **'You can request another verification link in {seconds} seconds.'**
  String verifyEmailResendCooldown(int seconds);

  /// No description provided for @verifyEmailResendAck.
  ///
  /// In en, this message translates to:
  /// **'If that address is waiting for verification, a new link is on its way.'**
  String get verifyEmailResendAck;

  /// No description provided for @verifyEmailBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back to Partner sign in'**
  String get verifyEmailBackAction;

  /// No description provided for @forgotPasswordAck.
  ///
  /// In en, this message translates to:
  /// **'If that address has an account, a password reset link is on its way.'**
  String get forgotPasswordAck;

  /// No description provided for @forgotPasswordNoDeliveryNotice.
  ///
  /// In en, this message translates to:
  /// **'In local development no email is delivered. The backend logs the reset link marked [DEV ONLY — NO EMAIL SENT].'**
  String get forgotPasswordNoDeliveryNotice;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Paste the token from your reset link and choose a new password.'**
  String get resetPasswordSubtitle;

  /// No description provided for @resetPasswordTokenLabel.
  ///
  /// In en, this message translates to:
  /// **'Reset token'**
  String get resetPasswordTokenLabel;

  /// No description provided for @resetPasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordNewLabel;

  /// No description provided for @resetPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordAction;

  /// No description provided for @resetPasswordSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset'**
  String get resetPasswordSuccessTitle;

  /// No description provided for @resetPasswordSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been changed and every other session was signed out.'**
  String get resetPasswordSuccessBody;

  /// No description provided for @resetPasswordBackAction.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get resetPasswordBackAction;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changing your password signs out every other device.'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordAction;

  /// No description provided for @changePasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully.'**
  String get changePasswordSuccess;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountDetailsHeading.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetailsHeading;

  /// No description provided for @accountRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get accountRoleLabel;

  /// No description provided for @accountRolePartner.
  ///
  /// In en, this message translates to:
  /// **'Partner'**
  String get accountRolePartner;

  /// No description provided for @accountRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get accountRoleAdmin;

  /// No description provided for @accountRoleUser.
  ///
  /// In en, this message translates to:
  /// **'Traveller'**
  String get accountRoleUser;

  /// No description provided for @accountSecurityHeading.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get accountSecurityHeading;

  /// No description provided for @accountSecurityBody.
  ///
  /// In en, this message translates to:
  /// **'Update the password you use to sign in.'**
  String get accountSecurityBody;

  /// No description provided for @accountBackToWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Back to workspace'**
  String get accountBackToWorkspace;

  /// No description provided for @accountBackToConsole.
  ///
  /// In en, this message translates to:
  /// **'Back to console'**
  String get accountBackToConsole;

  /// No description provided for @accountOpenAction.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountOpenAction;

  /// No description provided for @partnerBusinessHeading.
  ///
  /// In en, this message translates to:
  /// **'Business profile'**
  String get partnerBusinessHeading;

  /// No description provided for @partnerBusinessNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'No business profile yet'**
  String get partnerBusinessNoneTitle;

  /// No description provided for @partnerBusinessNoneBody.
  ///
  /// In en, this message translates to:
  /// **'Add your business information and submit it for review to open the Partner workspace.'**
  String get partnerBusinessNoneBody;

  /// No description provided for @partnerBusinessAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add business information'**
  String get partnerBusinessAddAction;

  /// No description provided for @partnerBusinessEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit business information'**
  String get partnerBusinessEditAction;

  /// No description provided for @partnerBusinessSaveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get partnerBusinessSaveAction;

  /// No description provided for @partnerBusinessSubmitAction.
  ///
  /// In en, this message translates to:
  /// **'Save and submit for review'**
  String get partnerBusinessSubmitAction;

  /// No description provided for @partnerBusinessSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Business information saved.'**
  String get partnerBusinessSavedMessage;

  /// No description provided for @partnerBusinessSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Submitted for review.'**
  String get partnerBusinessSubmittedMessage;

  /// No description provided for @partnerBusinessStatusDraftBody.
  ///
  /// In en, this message translates to:
  /// **'Complete your business information and submit it for review.'**
  String get partnerBusinessStatusDraftBody;

  /// No description provided for @partnerBusinessStatusSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'Your Partner application is awaiting review by an administrator.'**
  String get partnerBusinessStatusSubmittedBody;

  /// No description provided for @partnerBusinessStatusApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your Partner account is approved. The workspace is open.'**
  String get partnerBusinessStatusApprovedBody;

  /// No description provided for @partnerBusinessStatusRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your application was rejected. Update your business information and submit it again.'**
  String get partnerBusinessStatusRejectedBody;

  /// No description provided for @partnerBusinessStatusSuspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your Partner access is currently suspended. Contact support.'**
  String get partnerBusinessStatusSuspendedBody;

  /// No description provided for @partnerBusinessStatusUnknownBody.
  ///
  /// In en, this message translates to:
  /// **'This profile has a status this app does not recognise.'**
  String get partnerBusinessStatusUnknownBody;

  /// No description provided for @partnerBusinessRejectReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String partnerBusinessRejectReason(String reason);

  /// No description provided for @partnerBusinessFieldName.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get partnerBusinessFieldName;

  /// No description provided for @partnerBusinessFieldType.
  ///
  /// In en, this message translates to:
  /// **'Business type'**
  String get partnerBusinessFieldType;

  /// No description provided for @partnerBusinessFieldRepresentative.
  ///
  /// In en, this message translates to:
  /// **'Representative name'**
  String get partnerBusinessFieldRepresentative;

  /// No description provided for @partnerBusinessFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Business phone'**
  String get partnerBusinessFieldPhone;

  /// No description provided for @partnerBusinessFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Business email'**
  String get partnerBusinessFieldEmail;

  /// No description provided for @partnerBusinessFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Business address'**
  String get partnerBusinessFieldAddress;

  /// No description provided for @partnerBusinessFieldTaxCode.
  ///
  /// In en, this message translates to:
  /// **'Tax code'**
  String get partnerBusinessFieldTaxCode;

  /// No description provided for @partnerBusinessFieldWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get partnerBusinessFieldWebsite;

  /// No description provided for @partnerBusinessOptionalSuffix.
  ///
  /// In en, this message translates to:
  /// **'{label} (optional)'**
  String partnerBusinessOptionalSuffix(String label);

  /// No description provided for @partnerBusinessTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get partnerBusinessTypeHotel;

  /// No description provided for @partnerBusinessTypeRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get partnerBusinessTypeRestaurant;

  /// No description provided for @partnerBusinessTypeCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get partnerBusinessTypeCafe;

  /// No description provided for @partnerBusinessTypeTourOperator.
  ///
  /// In en, this message translates to:
  /// **'Tour operator'**
  String get partnerBusinessTypeTourOperator;

  /// No description provided for @partnerBusinessTypeTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get partnerBusinessTypeTransport;

  /// No description provided for @partnerBusinessTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get partnerBusinessTypeOther;

  /// No description provided for @partnerBusinessTypeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unrecognised type'**
  String get partnerBusinessTypeUnknown;

  /// No description provided for @partnerBusinessValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get partnerBusinessValidationRequired;

  /// No description provided for @partnerNavTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get partnerNavTeam;

  /// No description provided for @partnerTeamRoleRevenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get partnerTeamRoleRevenue;

  /// No description provided for @partnerTeamRoleReservations.
  ///
  /// In en, this message translates to:
  /// **'Reservations'**
  String get partnerTeamRoleReservations;

  /// No description provided for @partnerTeamRoleContent.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get partnerTeamRoleContent;

  /// No description provided for @partnerTeamRoleHousekeeping.
  ///
  /// In en, this message translates to:
  /// **'Housekeeping'**
  String get partnerTeamRoleHousekeeping;

  /// No description provided for @partnerTeamScopeField.
  ///
  /// In en, this message translates to:
  /// **'Applies to'**
  String get partnerTeamScopeField;

  /// No description provided for @partnerTeamScopeCompany.
  ///
  /// In en, this message translates to:
  /// **'Whole company'**
  String get partnerTeamScopeCompany;

  /// No description provided for @partnerTeamScopeProperty.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get partnerTeamScopeProperty;

  /// No description provided for @partnerTeamScopeUnit.
  ///
  /// In en, this message translates to:
  /// **'Room type'**
  String get partnerTeamScopeUnit;

  /// No description provided for @partnerTeamScopePropertyNumber.
  ///
  /// In en, this message translates to:
  /// **'Property #{id}'**
  String partnerTeamScopePropertyNumber(int id);

  /// No description provided for @partnerTeamScopeUnitNumber.
  ///
  /// In en, this message translates to:
  /// **'Room type #{id}'**
  String partnerTeamScopeUnitNumber(int id);

  /// No description provided for @partnerTeamScopeChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get partnerTeamScopeChoose;

  /// No description provided for @partnerTeamScopeChooseRole.
  ///
  /// In en, this message translates to:
  /// **'Choose a role first'**
  String get partnerTeamScopeChooseRole;

  /// No description provided for @partnerTeamScopeNoRooms.
  ///
  /// In en, this message translates to:
  /// **'No room types in this property'**
  String get partnerTeamScopeNoRooms;

  /// No description provided for @partnerTeamScopeNoneForRole.
  ///
  /// In en, this message translates to:
  /// **'You cannot grant this role at any scope you manage.'**
  String get partnerTeamScopeNoneForRole;

  /// No description provided for @partnerTeamStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get partnerTeamStatusActive;

  /// No description provided for @partnerTeamStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get partnerTeamStatusSuspended;

  /// No description provided for @partnerTeamStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get partnerTeamStatusRevoked;

  /// No description provided for @partnerInvitationStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get partnerInvitationStatusPending;

  /// No description provided for @partnerInvitationStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get partnerInvitationStatusAccepted;

  /// No description provided for @partnerInvitationStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get partnerInvitationStatusDeclined;

  /// No description provided for @partnerInvitationStatusRevoked.
  ///
  /// In en, this message translates to:
  /// **'Revoked'**
  String get partnerInvitationStatusRevoked;

  /// No description provided for @partnerInvitationStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get partnerInvitationStatusExpired;

  /// No description provided for @partnerInvitationDeliveryQueued.
  ///
  /// In en, this message translates to:
  /// **'Email not confirmed yet'**
  String get partnerInvitationDeliveryQueued;

  /// No description provided for @partnerInvitationDeliverySent.
  ///
  /// In en, this message translates to:
  /// **'Email sent'**
  String get partnerInvitationDeliverySent;

  /// No description provided for @partnerInvitationDeliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Email not delivered'**
  String get partnerInvitationDeliveryFailed;

  /// No description provided for @partnerTeamScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get partnerTeamScreenTitle;

  /// No description provided for @partnerTeamScreenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Who can work in this partner workspace, with which role and where. Changes take effect on the member\'s next request.'**
  String get partnerTeamScreenSubtitle;

  /// No description provided for @partnerTeamCountMembers.
  ///
  /// In en, this message translates to:
  /// **'Members: {count}'**
  String partnerTeamCountMembers(int count);

  /// No description provided for @partnerTeamCountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended: {count}'**
  String partnerTeamCountSuspended(int count);

  /// No description provided for @partnerTeamCountPending.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations: {count}'**
  String partnerTeamCountPending(int count);

  /// No description provided for @partnerTeamReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You can see the team but not change it. Team changes need a team-management permission.'**
  String get partnerTeamReadOnly;

  /// No description provided for @partnerTeamNoAccess.
  ///
  /// In en, this message translates to:
  /// **'Your role does not include seeing the team.'**
  String get partnerTeamNoAccess;

  /// No description provided for @partnerTeamAccessUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Your access could not be loaded, so team actions are unavailable. Refresh to try again.'**
  String get partnerTeamAccessUnavailable;

  /// No description provided for @partnerTeamLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading the team'**
  String get partnerTeamLoading;

  /// No description provided for @partnerTeamLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The team could not be loaded.'**
  String get partnerTeamLoadFailed;

  /// No description provided for @partnerTeamMembersHeading.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get partnerTeamMembersHeading;

  /// No description provided for @partnerTeamMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Active and suspended members you can see. Removed members are kept as history and not listed.'**
  String get partnerTeamMembersSubtitle;

  /// No description provided for @partnerTeamMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members in your view yet.'**
  String get partnerTeamMembersEmpty;

  /// No description provided for @partnerTeamColumnMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get partnerTeamColumnMember;

  /// No description provided for @partnerTeamColumnAccess.
  ///
  /// In en, this message translates to:
  /// **'Role and scope'**
  String get partnerTeamColumnAccess;

  /// No description provided for @partnerTeamColumnStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get partnerTeamColumnStatus;

  /// No description provided for @partnerTeamYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get partnerTeamYou;

  /// No description provided for @partnerTeamPrimaryOwner.
  ///
  /// In en, this message translates to:
  /// **'Primary owner'**
  String get partnerTeamPrimaryOwner;

  /// No description provided for @partnerTeamPrimaryOwnerProtected.
  ///
  /// In en, this message translates to:
  /// **'Primary owner — protected, cannot be changed from the workspace'**
  String get partnerTeamPrimaryOwnerProtected;

  /// No description provided for @partnerTeamPendingOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner confirmation pending'**
  String get partnerTeamPendingOwner;

  /// No description provided for @partnerTeamGrantLabel.
  ///
  /// In en, this message translates to:
  /// **'{role} · {scope}'**
  String partnerTeamGrantLabel(String role, String scope);

  /// No description provided for @partnerTeamMemberActions.
  ///
  /// In en, this message translates to:
  /// **'Actions for {name}'**
  String partnerTeamMemberActions(String name);

  /// No description provided for @partnerTeamEditAccess.
  ///
  /// In en, this message translates to:
  /// **'Edit role and scope'**
  String get partnerTeamEditAccess;

  /// No description provided for @partnerTeamSuspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get partnerTeamSuspend;

  /// No description provided for @partnerTeamReactivate.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get partnerTeamReactivate;

  /// No description provided for @partnerTeamRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from team'**
  String get partnerTeamRemoveAction;

  /// No description provided for @partnerTeamLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave this workspace'**
  String get partnerTeamLeave;

  /// No description provided for @partnerTeamCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get partnerTeamCancel;

  /// No description provided for @partnerTeamReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get partnerTeamReasonLabel;

  /// No description provided for @partnerTeamOwnerStepUpHint.
  ///
  /// In en, this message translates to:
  /// **'Changes involving an owner ask you to confirm your password.'**
  String get partnerTeamOwnerStepUpHint;

  /// No description provided for @partnerTeamSuspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this member?'**
  String get partnerTeamSuspendTitle;

  /// No description provided for @partnerTeamSuspendBody.
  ///
  /// In en, this message translates to:
  /// **'{name} loses access on their next request. Their role and scope are kept for a later reactivation.'**
  String partnerTeamSuspendBody(String name);

  /// No description provided for @partnerTeamReactivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate this member?'**
  String get partnerTeamReactivateTitle;

  /// No description provided for @partnerTeamReactivateBody.
  ///
  /// In en, this message translates to:
  /// **'{name} gets their previous role and scope back.'**
  String partnerTeamReactivateBody(String name);

  /// No description provided for @partnerTeamRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this member?'**
  String get partnerTeamRemoveTitle;

  /// No description provided for @partnerTeamRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'{name} loses access. The membership is kept as history and cannot be restored; to work with them again, send a new invitation.'**
  String partnerTeamRemoveBody(String name);

  /// No description provided for @partnerTeamLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this workspace?'**
  String get partnerTeamLeaveTitle;

  /// No description provided for @partnerTeamLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You lose access to this partner workspace at once. To come back, an owner or manager has to invite you again.'**
  String get partnerTeamLeaveBody;

  /// No description provided for @partnerTeamSaved.
  ///
  /// In en, this message translates to:
  /// **'Role and scope saved.'**
  String get partnerTeamSaved;

  /// No description provided for @partnerTeamSuspended.
  ///
  /// In en, this message translates to:
  /// **'Member suspended.'**
  String get partnerTeamSuspended;

  /// No description provided for @partnerTeamReactivated.
  ///
  /// In en, this message translates to:
  /// **'Member reactivated.'**
  String get partnerTeamReactivated;

  /// No description provided for @partnerTeamRemoved.
  ///
  /// In en, this message translates to:
  /// **'Member removed.'**
  String get partnerTeamRemoved;

  /// No description provided for @partnerTeamLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the workspace.'**
  String get partnerTeamLeft;

  /// No description provided for @partnerTeamConcurrentReloaded.
  ///
  /// In en, this message translates to:
  /// **'This member changed since you opened it. The list was refreshed — review it and try again.'**
  String get partnerTeamConcurrentReloaded;

  /// No description provided for @partnerTeamGrantAdd.
  ///
  /// In en, this message translates to:
  /// **'Add another role or scope'**
  String get partnerTeamGrantAdd;

  /// No description provided for @partnerTeamGrantRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this grant'**
  String get partnerTeamGrantRemove;

  /// No description provided for @partnerInvitesHeading.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get partnerInvitesHeading;

  /// No description provided for @partnerInvitesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invitations you can see. Accepting one creates a new membership with exactly the invited roles.'**
  String get partnerInvitesSubtitle;

  /// No description provided for @partnerInvitesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No invitations.'**
  String get partnerInvitesEmpty;

  /// No description provided for @partnerInvitesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Invitations could not be loaded.'**
  String get partnerInvitesUnavailable;

  /// No description provided for @partnerInviteAction.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get partnerInviteAction;

  /// No description provided for @partnerInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite to the team'**
  String get partnerInviteTitle;

  /// No description provided for @partnerInviteBody.
  ///
  /// In en, this message translates to:
  /// **'The address receives a link to join with a Partner account that uses it. Nobody joins until they accept, and no account is created or changed.'**
  String get partnerInviteBody;

  /// No description provided for @partnerInviteEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get partnerInviteEmailLabel;

  /// No description provided for @partnerInviteEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an email address.'**
  String get partnerInviteEmailRequired;

  /// No description provided for @partnerInviteEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get partnerInviteEmailInvalid;

  /// No description provided for @partnerInviteGrantsLabel.
  ///
  /// In en, this message translates to:
  /// **'Role and scope'**
  String get partnerInviteGrantsLabel;

  /// No description provided for @partnerInviteReview.
  ///
  /// In en, this message translates to:
  /// **'You are about to grant'**
  String get partnerInviteReview;

  /// No description provided for @partnerInviteLimits.
  ///
  /// In en, this message translates to:
  /// **'Invitations last 7 days. A company can have up to 20 pending, an address can be invited or resent once a minute, and each invitation can be resent 5 times.'**
  String get partnerInviteLimits;

  /// No description provided for @partnerInviteSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send invitation'**
  String get partnerInviteSubmit;

  /// No description provided for @partnerInviteRecorded.
  ///
  /// In en, this message translates to:
  /// **'Invitation request recorded. Its delivery status appears in the list.'**
  String get partnerInviteRecorded;

  /// No description provided for @partnerInviteResend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get partnerInviteResend;

  /// No description provided for @partnerInviteResent.
  ///
  /// In en, this message translates to:
  /// **'A new link was requested; the previous link no longer works.'**
  String get partnerInviteResent;

  /// No description provided for @partnerInviteRevoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get partnerInviteRevoke;

  /// No description provided for @partnerInviteRevokeTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this invitation?'**
  String get partnerInviteRevokeTitle;

  /// No description provided for @partnerInviteRevokeBody.
  ///
  /// In en, this message translates to:
  /// **'The link sent to {email} stops working.'**
  String partnerInviteRevokeBody(String email);

  /// No description provided for @partnerInviteRevoked.
  ///
  /// In en, this message translates to:
  /// **'Invitation revoked.'**
  String get partnerInviteRevoked;

  /// No description provided for @partnerInviteExpires.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String partnerInviteExpires(String date);

  /// No description provided for @partnerInviteInvitedBy.
  ///
  /// In en, this message translates to:
  /// **'Invited by {name}'**
  String partnerInviteInvitedBy(String name);

  /// No description provided for @partnerInviteResends.
  ///
  /// In en, this message translates to:
  /// **'Resent {count}/{max}'**
  String partnerInviteResends(int count, int max);

  /// No description provided for @partnerInviteResendAfter.
  ///
  /// In en, this message translates to:
  /// **'Can be resent after {time}'**
  String partnerInviteResendAfter(String time);

  /// No description provided for @partnerInviteResendLimit.
  ///
  /// In en, this message translates to:
  /// **'Resend limit reached — revoke it and send a new invitation.'**
  String get partnerInviteResendLimit;

  /// No description provided for @partnerTeamErrorEmailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Email delivery is not available right now, so nothing was sent or created. Try again later.'**
  String get partnerTeamErrorEmailUnavailable;

  /// No description provided for @partnerTeamErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many invitations for now: wait a minute between sends, keep at most 20 pending and resend at most 5 times.'**
  String get partnerTeamErrorRateLimited;

  /// No description provided for @partnerTeamErrorAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'This address already belongs to a team member.'**
  String get partnerTeamErrorAlreadyMember;

  /// No description provided for @partnerTeamErrorOwnerProtected.
  ///
  /// In en, this message translates to:
  /// **'Only an owner can manage owners, and the primary owner cannot be changed from the workspace.'**
  String get partnerTeamErrorOwnerProtected;

  /// No description provided for @partnerTeamErrorNotDelegable.
  ///
  /// In en, this message translates to:
  /// **'You cannot grant or manage this role or scope.'**
  String get partnerTeamErrorNotDelegable;

  /// No description provided for @partnerTeamErrorSelf.
  ///
  /// In en, this message translates to:
  /// **'You cannot change your own membership. You can leave the workspace instead.'**
  String get partnerTeamErrorSelf;

  /// No description provided for @partnerTeamErrorStepUp.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password to make changes involving an owner.'**
  String get partnerTeamErrorStepUp;

  /// No description provided for @partnerTeamErrorLastOwner.
  ///
  /// In en, this message translates to:
  /// **'The company must keep at least one active owner.'**
  String get partnerTeamErrorLastOwner;

  /// No description provided for @partnerTeamErrorConcurrent.
  ///
  /// In en, this message translates to:
  /// **'Someone changed this in the meantime. Reload and try again.'**
  String get partnerTeamErrorConcurrent;

  /// No description provided for @partnerTeamErrorWorkspaceConflict.
  ///
  /// In en, this message translates to:
  /// **'This person already belongs to another partner workspace.'**
  String get partnerTeamErrorWorkspaceConflict;

  /// No description provided for @partnerTeamErrorInvitationNotPending.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer pending. The list was refreshed.'**
  String get partnerTeamErrorInvitationNotPending;

  /// No description provided for @partnerTeamErrorInvitationStale.
  ///
  /// In en, this message translates to:
  /// **'A scope of this invitation no longer belongs to the company. Revoke it and invite again.'**
  String get partnerTeamErrorInvitationStale;

  /// No description provided for @partnerTeamErrorScopeInvalid.
  ///
  /// In en, this message translates to:
  /// **'That role cannot be granted at that scope.'**
  String get partnerTeamErrorScopeInvalid;

  /// No description provided for @partnerTeamErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Your role does not allow this.'**
  String get partnerTeamErrorPermission;

  /// No description provided for @partnerTeamErrorReason.
  ///
  /// In en, this message translates to:
  /// **'The reason must not contain passwords, secrets, keys, tokens or card or account numbers.'**
  String get partnerTeamErrorReason;

  /// No description provided for @partnerTeamErrorEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get partnerTeamErrorEmail;

  /// No description provided for @partnerTeamErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Some details are not valid. Check them and try again.'**
  String get partnerTeamErrorValidation;

  /// No description provided for @partnerTeamErrorSession.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Sign in again.'**
  String get partnerTeamErrorSession;

  /// No description provided for @partnerTeamErrorGone.
  ///
  /// In en, this message translates to:
  /// **'This is no longer available. The list was refreshed.'**
  String get partnerTeamErrorGone;

  /// No description provided for @partnerTeamErrorUncertain.
  ///
  /// In en, this message translates to:
  /// **'The connection dropped before an answer arrived. The list was refreshed — check whether the change was made.'**
  String get partnerTeamErrorUncertain;

  /// No description provided for @partnerTeamErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the server. Check the connection and try again.'**
  String get partnerTeamErrorNetwork;

  /// No description provided for @partnerTeamErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong on the server. Try again.'**
  String get partnerTeamErrorServer;

  /// No description provided for @partnerEditGrantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit role and scope'**
  String get partnerEditGrantsTitle;

  /// No description provided for @partnerEditGrantsBody.
  ///
  /// In en, this message translates to:
  /// **'These replace the member\'s current grants. You can only grant roles and scopes you manage.'**
  String get partnerEditGrantsBody;

  /// No description provided for @partnerEditGrantsSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get partnerEditGrantsSubmit;

  /// No description provided for @partnerStepUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get partnerStepUpTitle;

  /// No description provided for @partnerStepUpBody.
  ///
  /// In en, this message translates to:
  /// **'Changes involving an owner need a recent sign-in. Enter your password to continue.'**
  String get partnerStepUpBody;

  /// No description provided for @partnerStepUpPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get partnerStepUpPasswordLabel;

  /// No description provided for @partnerStepUpPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get partnerStepUpPasswordRequired;

  /// No description provided for @partnerStepUpConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get partnerStepUpConfirm;

  /// No description provided for @partnerAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Join a partner team'**
  String get partnerAcceptTitle;

  /// No description provided for @partnerAcceptGuidance.
  ///
  /// In en, this message translates to:
  /// **'You opened a team invitation. Sign in with a Partner account that uses the invited address. A traveller account cannot be used — if the invited address is your traveller account, ask the person who invited you to use another (for example, work) address.'**
  String get partnerAcceptGuidance;

  /// No description provided for @partnerAcceptJoinNote.
  ///
  /// In en, this message translates to:
  /// **'Accepting joins the invited partner workspace with the role and scope chosen by the team. It does not create a company of your own.'**
  String get partnerAcceptJoinNote;

  /// No description provided for @partnerAcceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get partnerAcceptAction;

  /// No description provided for @partnerAcceptDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get partnerAcceptDecline;

  /// No description provided for @partnerAcceptDeclineTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this invitation?'**
  String get partnerAcceptDeclineTitle;

  /// No description provided for @partnerAcceptDeclineBody.
  ///
  /// In en, this message translates to:
  /// **'The link stops working. The team would have to invite you again.'**
  String get partnerAcceptDeclineBody;

  /// No description provided for @partnerAcceptDeclined.
  ///
  /// In en, this message translates to:
  /// **'You declined the invitation.'**
  String get partnerAcceptDeclined;

  /// No description provided for @partnerAcceptSuccess.
  ///
  /// In en, this message translates to:
  /// **'You joined the team. Your workspace opens with the role and scope you were invited with.'**
  String get partnerAcceptSuccess;

  /// No description provided for @partnerAcceptOpenWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Open the workspace'**
  String get partnerAcceptOpenWorkspace;

  /// No description provided for @partnerAcceptNoLink.
  ///
  /// In en, this message translates to:
  /// **'No invitation link is open. Open the link from the invitation email — it only works once.'**
  String get partnerAcceptNoLink;

  /// No description provided for @partnerAcceptMineHeading.
  ///
  /// In en, this message translates to:
  /// **'Invitations addressed to you'**
  String get partnerAcceptMineHeading;

  /// No description provided for @partnerAcceptErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'This invitation link is invalid or has already been used. Ask the team for a new invitation.'**
  String get partnerAcceptErrorInvalid;

  /// No description provided for @partnerAcceptErrorExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired. Ask the team for a new invitation.'**
  String get partnerAcceptErrorExpired;

  /// No description provided for @partnerAcceptErrorPartnerAccount.
  ///
  /// In en, this message translates to:
  /// **'Join with a verified Partner account that uses the invited address. A traveller or administrator account cannot be used.'**
  String get partnerAcceptErrorPartnerAccount;

  /// No description provided for @partnerAcceptErrorMismatch.
  ///
  /// In en, this message translates to:
  /// **'This invitation was sent to a different address. Sign in with the Partner account that uses the invited address.'**
  String get partnerAcceptErrorMismatch;

  /// No description provided for @partnerAcceptErrorOwnCompany.
  ///
  /// In en, this message translates to:
  /// **'This account already has a company of its own, so it cannot join another workspace. Use a different Partner account.'**
  String get partnerAcceptErrorOwnCompany;

  /// No description provided for @partnerAcceptErrorOtherWorkspace.
  ///
  /// In en, this message translates to:
  /// **'This account already belongs to a partner workspace. Leave it first, or use a different Partner account.'**
  String get partnerAcceptErrorOtherWorkspace;

  /// No description provided for @partnerAcceptErrorUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This company cannot accept new members right now.'**
  String get partnerAcceptErrorUnavailable;

  /// No description provided for @partnerAcceptErrorStale.
  ///
  /// In en, this message translates to:
  /// **'This invitation is no longer valid. Ask the team for a new invitation.'**
  String get partnerAcceptErrorStale;
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
