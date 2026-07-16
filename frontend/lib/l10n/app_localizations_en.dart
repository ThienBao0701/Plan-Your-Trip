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
  String get plannerTripSelectorLabel => 'Select trip';

  @override
  String get plannerTripSelectorSemantic => 'Trip selector';

  @override
  String get plannerModeSemantic => 'Planner presentation mode';

  @override
  String get plannerTimelineMode => 'Timeline';

  @override
  String get plannerRouteMode => 'Route';

  @override
  String get plannerDaySelectorSemantic => 'Day selector';

  @override
  String plannerDaySemantic(int day) {
    return 'Select day $day';
  }

  @override
  String get plannerQuickAddAction => 'Quick Add';

  @override
  String get plannerQuickAddSemantic => 'Quick add an activity or place';

  @override
  String get plannerAddActivityAction => 'Add activity';

  @override
  String get plannerAddActivitySemantic => 'Add a manual activity';

  @override
  String get plannerEmptyDayTitle => 'No activities this day';

  @override
  String get plannerEmptyDayMessage =>
      'Add a place or manual activity to build this day.';

  @override
  String plannerActivityCardSemantic(String title, String time) {
    return '$title, $time';
  }

  @override
  String get plannerInvalidTimeLabel => 'Invalid time';

  @override
  String get plannerRouteFallbackSemantic => 'Planner route fallback';

  @override
  String get plannerRouteUnavailableMessage =>
      'Live maps, route geometry, traffic, distance, and travel time are not connected yet. Timeline data remains local.';

  @override
  String get plannerRoutePreviewTitle => 'Day stops';

  @override
  String get plannerBackToTimelineAction => 'Back to timeline';

  @override
  String get plannerLocalOnlyMessage =>
      'Planner changes are local to this app state and are not synchronized to a backend.';

  @override
  String get activityAddTitle => 'Add activity';

  @override
  String get activityEditTitle => 'Edit activity';

  @override
  String get activityCloseAction => 'Close';

  @override
  String get activityTitleLabel => 'Activity title';

  @override
  String get activityNotesLabel => 'Notes';

  @override
  String get activityDayLabel => 'Day';

  @override
  String get activityStartTimeLabel => 'Start time';

  @override
  String get activityEndTimeLabel => 'End time';

  @override
  String get activityTimeHint => 'Use HH:mm';

  @override
  String get activityCategoryLabel => 'Category';

  @override
  String get activityAddAction => 'Add activity';

  @override
  String get activitySaveAction => 'Save changes';

  @override
  String get activityAddSemantic => 'Add this activity';

  @override
  String get activitySaveSemantic => 'Save this activity';

  @override
  String get activityTitleRequired => 'Enter an activity title.';

  @override
  String get activityInvalidTimeRange =>
      'Enter a valid time range where end time is later than start time.';

  @override
  String get activityOutOfRangeDay => 'Select a day inside this trip.';

  @override
  String get activitySaveFailed =>
      'Could not save this activity for the selected trip day.';

  @override
  String get activityAddedMessage => 'Activity added locally.';

  @override
  String get activitySavedMessage => 'Activity updated locally.';

  @override
  String get activityDetailTitle => 'Activity details';

  @override
  String get activityEditAction => 'Edit';

  @override
  String activityEditSemantic(String title) {
    return 'Edit $title';
  }

  @override
  String get activityViewPlaceAction => 'View place';

  @override
  String get activityEstimatedCostLabel => 'Estimated cost';

  @override
  String get activityDeleteAction => 'Delete activity';

  @override
  String activityDeleteSemantic(String title) {
    return 'Delete $title';
  }

  @override
  String get activityDeleteConfirmTitle => 'Delete activity?';

  @override
  String activityDeleteConfirmMessage(String title) {
    return 'Delete \"$title\" from this trip day?';
  }

  @override
  String get activityDeletedMessage => 'Activity deleted.';

  @override
  String get activityConflictTitle => 'Schedule conflict';

  @override
  String activityConflictMessage(String title, String time) {
    return '\"$title\" overlaps $time. Change time or keep both activities explicitly.';
  }

  @override
  String get activityConflictChangeTime => 'Change time';

  @override
  String get activityConflictAddAnyway => 'Add anyway';

  @override
  String get activityConflictSaveAnyway => 'Save anyway';

  @override
  String get activityConflictKeepBothTitle => 'Keep both activities?';

  @override
  String get activityConflictKeepBothMessage =>
      'This will preserve both overlapping activities. No activity will be moved or overwritten.';

  @override
  String get activityConflictKeepBothAction => 'Keep both';

  @override
  String get quickAddTitle => 'Quick Add';

  @override
  String get quickAddSearchHint => 'Search places or activities';

  @override
  String quickAddSuggestionsTitle(String day) {
    return 'Suggestions for $day';
  }

  @override
  String quickAddPlaceSubtitle(String place) {
    return 'Add $place to an actual trip day.';
  }

  @override
  String get quickAddNoTripTitle => 'No trip available';

  @override
  String get quickAddNoTripMessage =>
      'Create a trip before adding this place to a timeline.';

  @override
  String get quickAddNoPlacesTitle => 'No places found';

  @override
  String get quickAddNoPlacesMessage => 'Try another local search term.';

  @override
  String get quickAddSelectTripLabel => 'Select trip';

  @override
  String get quickAddSelectDayLabel => 'Select day';

  @override
  String quickAddSubmitAction(int day) {
    return 'Add to Day $day';
  }

  @override
  String quickAddAddedMessage(String place, String trip, int day) {
    return '$place added to $trip · Day $day';
  }

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
  String get exploreHeroTitle => 'Where will you wander?';

  @override
  String get exploreHeroSubtitle =>
      'Curated places are local preview content. Personal trips stay local until a backend exists.';

  @override
  String get exploreSearchHint => 'Search cities, places, cafes, hotels...';

  @override
  String get exploreSearchActionSemantic => 'Open search results';

  @override
  String get exploreFiltersSemantic => 'Open search filters';

  @override
  String get exploreNoUpcomingTitle => 'No upcoming trip';

  @override
  String get exploreNoUpcomingMessage =>
      'Create a local demo trip when you are ready to plan.';

  @override
  String get exploreCategoriesTitle => 'Explore by category';

  @override
  String get exploreRecommendedTitle => 'Recommended places';

  @override
  String get exploreSeeAll => 'See all';

  @override
  String get exploreNoPlacesTitle => 'No places available';

  @override
  String get exploreNoPlacesMessage =>
      'Curated Explore content will appear here when local data is available.';

  @override
  String get exploreUpcomingTripSemantic => 'Upcoming trip summary';

  @override
  String explorePlanningProgress(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count planned activities',
      one: '1 planned activity',
      zero: 'No activities planned yet',
    );
    return '$_temp0';
  }

  @override
  String get searchTitle => 'Explore places';

  @override
  String get searchHint => 'Search hotels, food, cafes, attractions...';

  @override
  String get searchClearSemantic => 'Clear search';

  @override
  String get searchModeSemantic => 'Search presentation mode';

  @override
  String get searchListMode => 'List';

  @override
  String get searchMapMode => 'Map';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
      zero: 'No places',
    );
    return '$_temp0';
  }

  @override
  String get searchClearFilters => 'Clear filters';

  @override
  String get searchEmptyTitle => 'No places found';

  @override
  String get searchEmptyMessage => 'Try a different keyword, category, or tag.';

  @override
  String get searchFiltersTitle => 'Filters';

  @override
  String get searchSortTitle => 'Sort';

  @override
  String get searchSortRelevance => 'Relevant';

  @override
  String get searchSortRating => 'Rating';

  @override
  String get searchSortDuration => 'Duration';

  @override
  String get searchTagsTitle => 'Tags';

  @override
  String get searchApplyFilters => 'Apply filters';

  @override
  String get searchBackToList => 'Back to list';

  @override
  String get mapFallbackSemantic => 'Non-live map preview';

  @override
  String get mapUnavailableTitle => 'Map provider not connected';

  @override
  String get mapUnavailableMessage =>
      'Live maps, routing, traffic, and exact coordinates are not connected yet. This preview is schematic only.';

  @override
  String placeReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get placeAddToTrip => 'Add to trip';

  @override
  String placeAddToTripSemantic(String place) {
    return 'Add $place to a trip';
  }

  @override
  String get placeHighlightsTitle => 'Highlights';

  @override
  String get placeUsefulInfoTitle => 'Useful information';

  @override
  String placeDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String placeDurationHours(int hours) {
    return '$hours h';
  }

  @override
  String placeDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get savedPlacesDemoLocalOnly =>
      'Saved places are local to this demo session.';

  @override
  String get tripsTitle => 'My trips';

  @override
  String get tripsSubtitle => 'Smart local sections derived from trip dates.';

  @override
  String get tripsCreateAction => 'Create a trip';

  @override
  String get tripsCreateSemantic => 'Create a new trip';

  @override
  String get tripsEmptyTitle => 'No trips yet';

  @override
  String get tripsEmptyMessage =>
      'Create your first local trip to get started.';

  @override
  String get tripsRealUnavailableMessage =>
      'Personal trip history is not connected to a backend repository yet.';

  @override
  String get tripsOngoing => 'Ongoing';

  @override
  String get tripsUpcoming => 'Upcoming';

  @override
  String get tripsPast => 'Past';

  @override
  String get tripsOngoingEmpty => 'No trips are happening today.';

  @override
  String get tripsUpcomingEmpty => 'No upcoming trips yet.';

  @override
  String get tripsPastEmpty => 'No completed trips yet.';

  @override
  String tripCardSemantic(String trip) {
    return 'Trip card for $trip';
  }

  @override
  String tripActionsSemantic(String trip) {
    return 'Actions for $trip';
  }

  @override
  String get tripEditAction => 'Edit trip';

  @override
  String get tripDeleteAction => 'Delete trip';

  @override
  String get tripDeleteConfirmTitle => 'Delete trip?';

  @override
  String tripDeleteConfirmMessage(String trip) {
    return 'Delete \"$trip\"? This also removes its timeline items and expenses.';
  }

  @override
  String get tripDeletedMessage => 'Trip deleted.';

  @override
  String get tripCreatedMessage => 'Trip created locally.';

  @override
  String tripDayCount(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String tripTravelerCount(int travelers) {
    String _temp0 = intl.Intl.pluralLogic(
      travelers,
      locale: localeName,
      other: '$travelers travelers',
      one: '1 traveler',
    );
    return '$_temp0';
  }

  @override
  String tripDateTravelerMeta(String start, String end, int travelers) {
    String _temp0 = intl.Intl.pluralLogic(
      travelers,
      locale: localeName,
      other: '$travelers travelers',
      one: '1 traveler',
    );
    return '$start - $end · $_temp0';
  }

  @override
  String tripDaysAway(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Starts in $days days',
      one: 'Starts tomorrow',
      zero: 'Starts today',
    );
    return '$_temp0';
  }

  @override
  String get createTripTitle => 'New trip';

  @override
  String get createBackStep => 'Back to previous step';

  @override
  String get createCloseSemantic => 'Close create trip flow';

  @override
  String createStepLabel(int step) {
    return 'Step $step/3';
  }

  @override
  String get createContinueAction => 'Continue';

  @override
  String get createContinueSemantic => 'Continue to next create trip step';

  @override
  String get createSubmitAction => 'Create trip';

  @override
  String get createSubmitSemantic => 'Create this trip';

  @override
  String get createDestinationRequired => 'Please enter a destination.';

  @override
  String get createDatesRequired =>
      'Enter start and end dates in dd/mm/yyyy format.';

  @override
  String get createInvalidDateRange => 'End date cannot be before start date.';

  @override
  String get createInvalidTravelers =>
      'Traveler count must be between 1 and 20.';

  @override
  String get createDiscardTitle => 'Discard trip draft?';

  @override
  String get createDiscardMessage => 'Your entered trip details will be lost.';

  @override
  String get createDiscardAction => 'Discard';

  @override
  String get createDestinationTitle => 'Where do you want to go?';

  @override
  String get createDestinationSubtitle =>
      'Choose a supported destination from local data or type your own.';

  @override
  String get createDestinationLabel => 'Destination';

  @override
  String get createTripNameLabel => 'Trip name';

  @override
  String get createDestinationSuggestions => 'Suggested destinations';

  @override
  String get createDatesTitle => 'When will you go?';

  @override
  String get createDatesSubtitle =>
      'Enter dates and traveler count for this local trip.';

  @override
  String get createStartDateLabel => 'Start date';

  @override
  String get createEndDateLabel => 'End date';

  @override
  String get createDateFormatHint => 'Use dd/mm/yyyy';

  @override
  String get createTravelersLabel => 'Travelers';

  @override
  String get createDecreaseTravelers => 'Decrease travelers';

  @override
  String get createIncreaseTravelers => 'Increase travelers';

  @override
  String get createBudgetLabel => 'Budget (VND)';

  @override
  String get createPersonalizationTitle => 'Shape the trip your way';

  @override
  String get createPersonalizationSubtitle =>
      'These preferences are local draft presentation only.';

  @override
  String get createPreferencesTitle => 'Preferences';

  @override
  String get createPreferenceFood => 'Food';

  @override
  String get createPreferenceCulture => 'Culture';

  @override
  String get createPreferenceNature => 'Nature';

  @override
  String get createPreferenceRelax => 'Relax';

  @override
  String get createPreferenceAdventure => 'Adventure';

  @override
  String get createPreferenceShopping => 'Shopping';

  @override
  String get createPaceTitle => 'Pace';

  @override
  String get createPaceSlow => 'Slow';

  @override
  String get createPaceBalanced => 'Balanced';

  @override
  String get createPacePacked => 'Packed';

  @override
  String get createBudgetStyleTitle => 'Budget style';

  @override
  String get createBudgetSaving => 'Saving';

  @override
  String get createBudgetComfort => 'Comfort';

  @override
  String get createBudgetPremium => 'Premium';

  @override
  String get createNotesLabel => 'Notes';

  @override
  String get createPersonalizationLocalOnly =>
      'Preferences are kept in this draft only and are not sent to any backend.';

  @override
  String get createReviewTitle => 'Review';

  @override
  String createReviewSummary(String title, String destination, String start,
      String end, int travelers) {
    String _temp0 = intl.Intl.pluralLogic(
      travelers,
      locale: localeName,
      other: '$travelers travelers',
      one: '1 traveler',
    );
    return '$title · $destination · $start to $end · $_temp0';
  }

  @override
  String get createConfirmAction => 'Confirm';

  @override
  String editTripTitle(String trip) {
    return 'Edit $trip';
  }

  @override
  String get editTripHeading => 'Update your trip';

  @override
  String get editTripSaveAction => 'Update trip';

  @override
  String get editTripUpdatedMessage => 'Trip updated.';

  @override
  String get editMoveActivitiesTitle => 'Move activities?';

  @override
  String editMoveActivitiesMessage(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '1 day',
    );
    return 'This shorter trip has $_temp0. Activities from removed days will move to the new last day.';
  }

  @override
  String get editMoveActivitiesAction => 'Move to last day';

  @override
  String get tripOverviewProgressTitle => 'Trip progress';

  @override
  String tripOverviewProgressValue(int percent) {
    return '$percent% complete';
  }

  @override
  String get tripOverviewTimelineAction => 'Timeline';

  @override
  String get tripOverviewExpensesAction => 'Budget';

  @override
  String get tripOverviewActivitiesMetric => 'Activities';

  @override
  String get tripOverviewSpentMetric => 'Spent';

  @override
  String get tripOverviewBudgetMetric => 'Budget';

  @override
  String get tripOverviewNextTitle => 'Next';

  @override
  String get tripOverviewNoActivitiesTitle => 'No activities yet';

  @override
  String get tripOverviewNoActivitiesMessage =>
      'Open the existing timeline to add activities.';

  @override
  String tripOverviewDayLabel(int day) {
    return 'Day $day';
  }

  @override
  String get categoryFoodTitle => 'Food & cafes';

  @override
  String get categoryFoodSubtitle =>
      'Browse local food and cafe places from supported category roots.';

  @override
  String get categoryFoodSearchHint => 'Search food, cafes, or local dishes';

  @override
  String get categoryThingsTitle => 'Things to do';

  @override
  String get categoryThingsSubtitle =>
      'Attractions and entertainment stay distinct for future backend mapping.';

  @override
  String get categoryThingsSearchHint => 'Search attractions or entertainment';

  @override
  String get categoryTransportTitle => 'Transportation';

  @override
  String get categoryTransportSubtitle =>
      'Browse transport listings without live routes, fares, or schedules.';

  @override
  String get categoryTransportSearchHint => 'Search transport providers';

  @override
  String get categoryRootAll => 'All';

  @override
  String get categoryRootFood => 'Food';

  @override
  String get categoryRootCafe => 'Cafe';

  @override
  String get categoryRootAttraction => 'Attractions';

  @override
  String get categoryRootEntertainment => 'Entertainment';

  @override
  String get categoryRootTransportation => 'Transportation';

  @override
  String get categoryFiltersSemantic => 'Open category filters';

  @override
  String get categoryFiltersTitle => 'Category filters';

  @override
  String get categoryFilterRating => 'Rating';

  @override
  String get categoryFilterRating45 => '4.5+ rating';

  @override
  String get categoryFilterPrice => 'Price level';

  @override
  String get categoryFilterPriceAny => 'Any price';

  @override
  String get categoryFilterApply => 'Apply filters';

  @override
  String get categoryEmptyTitle => 'No category results';

  @override
  String get categoryEmptyMessage =>
      'Try another keyword, root category, rating, or price level.';

  @override
  String get categoryLocalPreviewMessage =>
      'These public category results are local preview content and are not personal server data.';

  @override
  String get categoryTransportUnavailableTitle => 'Routes not connected';

  @override
  String get categoryTransportUnavailableMessage =>
      'Live routes, fares, schedules, travel times, geolocation, and ticket booking are not connected yet.';

  @override
  String get budgetTitle => 'Trip budget';

  @override
  String get budgetHeading => 'Budget overview';

  @override
  String get budgetTripSelectorLabel => 'Trip';

  @override
  String get budgetNoTripTitle => 'No trip budget yet';

  @override
  String get budgetNoTripMessage =>
      'Create a trip before tracking a trip-scoped budget.';

  @override
  String get budgetOverviewSemantic => 'Budget overview';

  @override
  String get budgetTotalBudget => 'Total budget';

  @override
  String get budgetSetAction => 'Set budget';

  @override
  String get budgetSetTitle => 'Set trip budget';

  @override
  String get budgetAmountLabel => 'Budget amount';

  @override
  String get budgetNotSet => 'Not set';

  @override
  String get budgetSpent => 'Spent';

  @override
  String get budgetLeft => 'Left';

  @override
  String get budgetOverBy => 'Over by';

  @override
  String budgetProgressSemantic(int percent) {
    return 'Budget progress $percent percent used';
  }

  @override
  String get budgetProgressMissingSemantic =>
      'Budget progress unavailable because no budget is set';

  @override
  String budgetProgressLabel(int percent) {
    return '$percent% used';
  }

  @override
  String budgetOverMessage(String amount) {
    return 'Over budget by $amount';
  }

  @override
  String get budgetMissingBudgetTitle => 'Budget not configured';

  @override
  String get budgetMissingBudgetMessage =>
      'Expenses can be tracked before a total budget is set.';

  @override
  String get budgetNoExpensesTitle => 'No expenses yet';

  @override
  String get budgetNoExpensesMessage =>
      'Add expenses to build this trip\'s local spending history.';

  @override
  String get budgetByCategoryTitle => 'By category';

  @override
  String get budgetHistoryTitle => 'Expense history';

  @override
  String budgetMixedCurrencyWarning(String currency) {
    return 'This trip has expenses outside $currency. Totals show only $currency to avoid mixing currencies.';
  }

  @override
  String get budgetSavedMessage => 'Budget updated locally.';

  @override
  String get budgetSaveFailed => 'Could not save this budget.';

  @override
  String get expenseAddSemantic => 'Add expense';

  @override
  String get expenseAddAction => 'Add expense';

  @override
  String get expenseAddTitle => 'Add expense';

  @override
  String get expenseEditTitle => 'Edit expense';

  @override
  String get expenseSaveAction => 'Save expense';

  @override
  String get expenseSaveSemantic => 'Save this expense';

  @override
  String get expenseTitleLabel => 'Expense title';

  @override
  String get expenseTitleRequired => 'Enter an expense title.';

  @override
  String get expenseAmountLabel => 'Amount';

  @override
  String get expenseAmountInvalid => 'Use a finite amount above 0.';

  @override
  String get expenseCurrencyLabel => 'Currency';

  @override
  String get expenseCategoryLabel => 'Category';

  @override
  String get expenseDateLabel => 'Expense date';

  @override
  String get expenseLinkedDayLabel => 'Linked day';

  @override
  String get expenseNoLinkedDay => 'No linked day';

  @override
  String get expenseLinkedDayInvalid =>
      'Linked day must belong to the selected trip.';

  @override
  String get expenseLinkedItemLabel => 'Linked activity';

  @override
  String get expenseNoLinkedItem => 'No linked activity';

  @override
  String get expenseLinkedItemInvalid =>
      'Linked activity must belong to the selected trip.';

  @override
  String get expenseNotesLabel => 'Notes';

  @override
  String get expenseTripRequired => 'Select a valid trip.';

  @override
  String get expenseDateOutOfRange =>
      'Expense date must be inside the selected trip date range.';

  @override
  String get expenseSaveFailed =>
      'Could not save this expense for the selected trip.';

  @override
  String get expenseAddedMessage => 'Expense added locally.';

  @override
  String get expenseSavedMessage => 'Expense updated locally.';

  @override
  String expenseTileSemantic(String title) {
    return 'Expense $title';
  }

  @override
  String expenseActionsSemantic(String title) {
    return 'Actions for expense $title';
  }

  @override
  String get expenseEditAction => 'Edit';

  @override
  String get expenseDeleteAction => 'Delete';

  @override
  String get expenseDeleteConfirmTitle => 'Delete expense?';

  @override
  String expenseDeleteConfirmMessage(String title) {
    return 'Delete \"$title\" from this trip budget?';
  }

  @override
  String get expenseDeletedMessage => 'Expense deleted.';

  @override
  String get expenseCategoryAccommodation => 'Accommodation';

  @override
  String get expenseCategoryFood => 'Food';

  @override
  String get expenseCategoryTransport => 'Transport';

  @override
  String get expenseCategoryAttraction => 'Attraction';

  @override
  String get expenseCategoryShopping => 'Shopping';

  @override
  String get expenseCategoryHealth => 'Health';

  @override
  String get expenseCategoryVisa => 'Visa';

  @override
  String get expenseCategoryInsurance => 'Insurance';

  @override
  String get expenseCategoryOther => 'Other';

  @override
  String get commonBackSemantic => 'Go back';

  @override
  String get demoModeLabel => 'Demo Mode';
}
