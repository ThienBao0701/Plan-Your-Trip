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
      'The wishlist (quick-saved places) is not connected to the backend yet for real accounts. Saved collections are synced with your account below.';

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
  String get savedPlacesSubtitle =>
      'Your saved travel shortlist, resolved from current public place data.';

  @override
  String get savedPlacesDemoBoundary =>
      'Demo Mode saves are local presentation data. They are not synchronized with the wishlist API.';

  @override
  String get savedPlacesEmptyTitle => 'No saved places yet';

  @override
  String get savedPlacesEmptyMessage =>
      'Save a public place from Explore, search, category discovery, or place details.';

  @override
  String savedPlacesCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved places',
      one: '1 saved place',
    );
    return '$_temp0';
  }

  @override
  String get savedPlacesFilterSemantic => 'Saved place filters';

  @override
  String get savedPlacesSortNewest => 'Newest saved';

  @override
  String get savedPlacesSortName => 'Name';

  @override
  String savedPlacesCollectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count collections',
      one: '1 collection',
    );
    return '$_temp0';
  }

  @override
  String savedPlacesCollectionCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved collections',
      one: '1 saved collection',
    );
    return '$_temp0';
  }

  @override
  String savedPlacesAllSavedTab(int count) {
    return 'All saved ($count)';
  }

  @override
  String savedPlacesCollectionsTab(int count) {
    return 'Collections ($count)';
  }

  @override
  String get savedPlacesSectionTabsSemantic => 'Saved places sections';

  @override
  String get savedPlacesWishlistBoundaryTitle => 'Wishlist and notes';

  @override
  String get savedPlacesWishlistBoundaryMessage =>
      'The wishlist and private notes are local Demo Mode data until backend persistence is connected.';

  @override
  String get savedPlacesCollectionsTitle => 'Collections';

  @override
  String get savedPlacesCollectionsBoundaryMessage =>
      'Collections sync with /api/me/collections for real accounts; Demo Mode uses local data only. Adding a place to a collection never changes the wishlist.';

  @override
  String get savedPlacesCollectionNetworkErrorMessage =>
      'Could not reach the backend. Check your connection and try again.';

  @override
  String get savedPlacesCollectionServerErrorMessage =>
      'The backend had a problem completing this action. Please try again.';

  @override
  String get savedPlacesCollectionUnauthenticatedMessage =>
      'Your session expired. Please sign in again to continue.';

  @override
  String get savedPlacesCollectionPlaceHydrationMessage =>
      'Full place details are not synced yet for real collections. View details and Add to trip arrive in a later phase.';

  @override
  String get savedPlacesCollectionAddPlaceDeferredTitle =>
      'Adding places arrives later';

  @override
  String get savedPlacesCollectionAddPlaceDeferredMessage =>
      'Choosing a saved place to add to a real collection is not available yet. This will be connected in a later phase.';

  @override
  String get savedPlacesCollectionCreateAction => 'Create collection';

  @override
  String get savedPlacesCollectionCreateSemantic => 'Create a saved collection';

  @override
  String get savedPlacesCollectionsEmptyTitle => 'No collections yet';

  @override
  String get savedPlacesCollectionsEmptyMessage =>
      'Create a private collection for a destination, weekend idea, or shortlist.';

  @override
  String savedPlacesCollectionItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$_temp0';
  }

  @override
  String savedPlacesCollectionItemCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places in collection',
      one: '1 place in collection',
    );
    return '$_temp0';
  }

  @override
  String savedPlacesCollectionCardSemantic(String collection, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$collection, $_temp0';
  }

  @override
  String get savedPlacesCollectionPrivateLabel => 'Private';

  @override
  String get savedPlacesCollectionVisibleLabel => 'Visible';

  @override
  String savedPlacesCollectionUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get savedPlacesCollectionOpenAction => 'Open';

  @override
  String savedPlacesCollectionOpenSemantic(String collection) {
    return 'Open collection $collection';
  }

  @override
  String get savedPlacesCollectionEditAction => 'Edit';

  @override
  String savedPlacesCollectionEditSemantic(String collection) {
    return 'Edit collection $collection';
  }

  @override
  String savedPlacesCollectionDeleteSemantic(String collection) {
    return 'Delete collection $collection';
  }

  @override
  String savedPlacesCollectionDetailSemantic(String collection, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '$collection, $_temp0';
  }

  @override
  String get savedPlacesCollectionBackAction => 'Collections';

  @override
  String get savedPlacesCollectionBackSemantic => 'Back to saved collections';

  @override
  String get savedPlacesCollectionAddSavedAction => 'Add saved place';

  @override
  String savedPlacesCollectionAddSavedSemantic(String collection) {
    return 'Add a saved place to $collection';
  }

  @override
  String get savedPlacesCollectionEmptyTitle => 'Collection is empty';

  @override
  String get savedPlacesCollectionEmptyMessage =>
      'Add an already-saved public place. This will not change your wishlist.';

  @override
  String savedPlacesCollectionPlaceSemantic(String place, String date) {
    return '$place, added $date';
  }

  @override
  String savedPlacesCollectionAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String get savedPlacesCollectionRemovePlaceAction => 'Remove';

  @override
  String savedPlacesCollectionRemovePlaceSemantic(String place) {
    return 'Remove $place from this collection';
  }

  @override
  String get savedPlacesCollectionStaleItemTitle =>
      'Collection item unavailable';

  @override
  String savedPlacesCollectionStaleItemMessage(int placeId) {
    return 'Place reference $placeId no longer resolves to public place data.';
  }

  @override
  String get savedPlacesCollectionRemoveStaleSemantic =>
      'Remove unavailable place from collection';

  @override
  String savedPlacesCollectionMembershipIn(String collection) {
    return 'In $collection';
  }

  @override
  String savedPlacesCollectionMembershipOut(String collection) {
    return 'Not in $collection';
  }

  @override
  String savedPlacesCollectionRemoveMembershipSemantic(
      String place, String collection) {
    return 'Remove $place from $collection';
  }

  @override
  String savedPlacesCollectionAddMembershipSemantic(
      String place, String collection) {
    return 'Add $place to $collection';
  }

  @override
  String get savedPlacesCollectionInAction => 'Added';

  @override
  String get savedPlacesCollectionAddAction => 'Add';

  @override
  String get savedPlacesCollectionEditTitle => 'Edit collection';

  @override
  String get savedPlacesCollectionCreateTitle => 'Create collection';

  @override
  String get savedPlacesCollectionNameLabel => 'Collection name';

  @override
  String savedPlacesCollectionNameHelper(int maxLength) {
    return 'Required, up to $maxLength characters.';
  }

  @override
  String get savedPlacesCollectionDescriptionLabel => 'Description';

  @override
  String savedPlacesCollectionDescriptionHelper(int maxLength) {
    return 'Optional, up to $maxLength characters.';
  }

  @override
  String get savedPlacesCollectionCoverLabel => 'Cover image URL';

  @override
  String savedPlacesCollectionCoverHelper(int maxLength) {
    return 'Optional URL text, up to $maxLength characters.';
  }

  @override
  String get savedPlacesCollectionPrivateHelper =>
      'All collection endpoints are owner-scoped in this phase.';

  @override
  String get savedPlacesCollectionSaveAction => 'Save collection';

  @override
  String savedPlacesCollectionCreatedMessage(String collection) {
    return 'Created collection $collection.';
  }

  @override
  String savedPlacesCollectionUpdatedMessage(String collection) {
    return 'Updated collection $collection.';
  }

  @override
  String savedPlacesCollectionDeleteTitle(String collection) {
    return 'Delete $collection?';
  }

  @override
  String savedPlacesCollectionDeleteMessage(String collection) {
    return 'Delete $collection? Only collection membership is removed. Places, wishlist notes, trips, bookings, reviews, and documents are preserved.';
  }

  @override
  String get savedPlacesCollectionDeleteAction => 'Delete collection';

  @override
  String savedPlacesCollectionDeletedMessage(String collection) {
    return 'Deleted collection $collection.';
  }

  @override
  String savedPlacesCollectionAddSavedTitle(String collection) {
    return 'Add saved places to $collection';
  }

  @override
  String get savedPlacesCollectionAddSavedMessage =>
      'Only current saved places are listed. Collection membership stays separate from the wishlist.';

  @override
  String savedPlacesManageCollectionsTitle(String place) {
    return 'Collections for $place';
  }

  @override
  String get savedPlacesManageCollectionsMessage =>
      'Add or remove this saved place from private Demo Mode collections.';

  @override
  String get savedPlacesCollectionSavedMessage => 'Collection updated.';

  @override
  String get savedPlacesCollectionsRealUnavailableMessage =>
      'Saved collections are not connected to the backend yet for real accounts.';

  @override
  String savedPlacesCollectionInvalidNameMessage(int maxLength) {
    return 'Collection name is required and limited to $maxLength characters.';
  }

  @override
  String savedPlacesCollectionInvalidDescriptionMessage(int maxLength) {
    return 'Collection description is limited to $maxLength characters.';
  }

  @override
  String savedPlacesCollectionInvalidCoverMessage(int maxLength) {
    return 'Collection cover URL is limited to $maxLength characters.';
  }

  @override
  String savedPlacesCollectionLimitMessage(int maxCount) {
    return 'You have reached the local limit of $maxCount collections.';
  }

  @override
  String get savedPlacesCollectionNotFoundMessage =>
      'This collection is unavailable.';

  @override
  String get savedPlacesCollectionPlaceNotFoundMessage =>
      'This place cannot be added because it no longer resolves to public place data.';

  @override
  String savedPlacesCollectionDuplicatePlaceMessage(
      String place, String collection) {
    return '$place is already in $collection.';
  }

  @override
  String get savedPlacesCollectionItemNotFoundMessage =>
      'This place is not in the selected collection.';

  @override
  String savedPlacesCollectionItemLimitMessage(int maxCount) {
    return 'This collection has reached the local limit of $maxCount places.';
  }

  @override
  String savedPlacesCollectionAddedPlaceMessage(
      String place, String collection) {
    return 'Added $place to $collection.';
  }

  @override
  String savedPlacesCollectionRemovedPlaceMessage(
      String place, String collection) {
    return 'Removed $place from $collection.';
  }

  @override
  String get savedPlacesAddToCollectionAction => 'Collections';

  @override
  String savedPlacesManageCollectionsSemantic(String place) {
    return 'Manage collections for $place';
  }

  @override
  String savedPlacesSavedOn(String date) {
    return 'Saved $date';
  }

  @override
  String savedPlacesNote(String note) {
    return 'Note: $note';
  }

  @override
  String get savedPlacesEditNoteAction => 'Edit note';

  @override
  String savedPlacesEditNoteSemantic(String place) {
    return 'Edit private note for $place';
  }

  @override
  String savedPlacesEditNoteTitle(String place) {
    return 'Private note for $place';
  }

  @override
  String get savedPlacesNoteFieldLabel => 'Private note';

  @override
  String savedPlacesNoteFieldHelper(int maxLength) {
    return 'Up to $maxLength characters. Leave blank to clear it.';
  }

  @override
  String get savedPlacesNoteSaveAction => 'Save note';

  @override
  String savedPlacesNoteSavedMessage(String place) {
    return 'Updated the private note for $place.';
  }

  @override
  String get savedPlacesNoteTooLongMessage =>
      'Private notes are limited to 500 characters.';

  @override
  String savedPlacesSaveSemantic(String place) {
    return 'Save $place';
  }

  @override
  String savedPlacesRemoveSemantic(String place) {
    return 'Remove saved place $place';
  }

  @override
  String savedPlacesSavedMessage(String place) {
    return 'Saved $place locally.';
  }

  @override
  String savedPlacesAlreadySavedMessage(String place) {
    return '$place is already saved.';
  }

  @override
  String savedPlacesRemovedPlace(String place) {
    return 'Removed $place from local saved places.';
  }

  @override
  String get savedPlacesActionForbiddenMessage =>
      'This saved place belongs to another traveler.';

  @override
  String get savedPlacesMissingTitle => 'Saved place unavailable';

  @override
  String get savedPlacesMissingMessage =>
      'This saved place no longer resolves to a public place.';

  @override
  String savedPlacesMissingRecordMessage(int placeId) {
    return 'Saved place reference $placeId no longer resolves to public place data.';
  }

  @override
  String get savedPlacesRemoveAction => 'Remove';

  @override
  String get savedPlacesRemoveConfirmTitle => 'Remove saved place?';

  @override
  String savedPlacesRemoveConfirmMessage(String place) {
    return 'Remove $place from your local saved places? The place, trips, bookings, reviews, and wallet items will not be deleted.';
  }

  @override
  String get savedPlacesRemoveConfirmAction => 'Remove saved place';

  @override
  String get savedPlacesViewDetailsAction => 'Details';

  @override
  String savedPlacesOpenDetailSemantic(String place) {
    return 'Open details for $place';
  }

  @override
  String get savedPlacesHotelAction => 'View rooms';

  @override
  String savedPlacesCardSemantic(String place, String date) {
    return '$place, saved $date';
  }

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
  String get notificationCenterSubtitle =>
      'A local in-app activity stream for bookings, payments, trips, reviews, rewards, wallet documents, and account notices.';

  @override
  String get notificationCenterSemantic => 'Notification and activity center';

  @override
  String get notificationRealBoundary =>
      'Real accounts will use the committed in-app notification API when the frontend repository layer is connected. Push delivery, device tokens, and external notification permissions are not connected in this UI phase.';

  @override
  String get notificationDemoModeLabel => 'Local Demo Mode';

  @override
  String get notificationPreferenceBoundary =>
      'Notification toggles are local device preferences only. They do not register push tokens or sync server preferences.';

  @override
  String notificationUnreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
      one: '1 unread',
      zero: '0 unread',
    );
    return '$_temp0';
  }

  @override
  String notificationUnreadCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
      zero: 'No unread notifications',
    );
    return '$_temp0';
  }

  @override
  String notificationTotalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notices',
      one: '1 notice',
      zero: '0 notices',
    );
    return '$_temp0';
  }

  @override
  String get notificationMarkAllReadSemantic =>
      'Mark all demo notifications as read';

  @override
  String notificationMarkAllReadResult(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marked $count notifications as read.',
      one: 'Marked 1 notification as read.',
      zero: 'No unread notifications changed.',
    );
    return '$_temp0';
  }

  @override
  String get notificationFilterSemantic => 'Notification filters';

  @override
  String get notificationFilterAll => 'All';

  @override
  String get notificationFilterUnread => 'Unread';

  @override
  String get notificationFilterBookings => 'Bookings';

  @override
  String get notificationFilterPayments => 'Payments';

  @override
  String get notificationFilterTrips => 'Trips';

  @override
  String get notificationFilterReviews => 'Reviews';

  @override
  String get notificationFilterRewards => 'Rewards';

  @override
  String get notificationFilterWallet => 'Wallet';

  @override
  String get notificationFilterSystem => 'System';

  @override
  String get notificationFilterEmptyMessage =>
      'No notifications match this filter.';

  @override
  String get notificationReadLabel => 'Read';

  @override
  String get notificationUnreadLabel => 'Unread';

  @override
  String notificationCardSemantic(
      String readState, String type, String title, String time) {
    return '$readState. $type notification. $title. $time.';
  }

  @override
  String get notificationMissingTitle => 'Notification unavailable';

  @override
  String get notificationMissingMessage =>
      'This local notification is no longer available.';

  @override
  String get notificationCreatedAtLabel => 'Created';

  @override
  String get notificationReadAtLabel => 'Read at';

  @override
  String get notificationPrivacyNote =>
      'Private booking and payment references are masked or omitted in this activity view.';

  @override
  String get notificationOpenTargetSemantic => 'Open notification target';

  @override
  String get notificationDeleteAction => 'Delete notification';

  @override
  String get notificationDeleteSemantic => 'Delete this demo notification';

  @override
  String get notificationDeleteConfirmTitle => 'Delete notification?';

  @override
  String get notificationDeleteConfirmMessage =>
      'Delete this local demo notification? The linked booking, payment, trip, review, reward, or wallet item will not be deleted.';

  @override
  String get notificationDeleteConfirmAction => 'Delete notification';

  @override
  String get notificationDeletedMessage =>
      'Notification deleted from local demo data.';

  @override
  String get notificationTargetUnavailable =>
      'This notification has no linked screen.';

  @override
  String get notificationTargetMissing =>
      'The linked item is no longer available in local demo data.';

  @override
  String get notificationNoTargetAction => 'No linked screen';

  @override
  String get notificationOpenBooking => 'View booking';

  @override
  String get notificationOpenPayment => 'View payment status';

  @override
  String get notificationOpenTrip => 'View trip';

  @override
  String get notificationOpenTripCompanion => 'View companions';

  @override
  String get notificationOpenTripDocuments => 'View trip documents';

  @override
  String get notificationOpenReview => 'View review';

  @override
  String get notificationOpenRewards => 'View rewards';

  @override
  String get notificationOpenWallet => 'View travel wallet';

  @override
  String get notificationTypeBooking => 'Booking';

  @override
  String get notificationTypePayment => 'Payment';

  @override
  String get notificationTypeReservation => 'Reservation';

  @override
  String get notificationTypeSystem => 'System';

  @override
  String get notificationTypePromotion => 'Promotion';

  @override
  String get notificationTypeReview => 'Review';

  @override
  String get notificationTypePartner => 'Partner';

  @override
  String get notificationTypeAdmin => 'Admin';

  @override
  String get notificationTypeMessage => 'Message';

  @override
  String get notificationTypeTrip => 'Trip';

  @override
  String get notificationPriorityLow => 'Low';

  @override
  String get notificationPriorityNormal => 'Normal';

  @override
  String get notificationPriorityHigh => 'High';

  @override
  String get notificationPriorityUrgent => 'Urgent';

  @override
  String get notificationDemoBookingModifiedTitle => 'Booking changes saved';

  @override
  String get notificationDemoBookingModifiedMessage =>
      'Your pending Da Lat stay keeps the same booking code while the local modification preview updates its stay snapshot.';

  @override
  String get notificationDemoPaymentSuccessTitle => 'Demo payment completed';

  @override
  String get notificationDemoPaymentSuccessMessage =>
      'The local checkout preview recorded a paid MOCK payment. No real charge was made.';

  @override
  String get notificationDemoPaymentFailedTitle =>
      'Demo payment needs attention';

  @override
  String get notificationDemoPaymentFailedMessage =>
      'A local payment preview did not complete. Review the booking before trying another demo checkout action.';

  @override
  String get notificationDemoTripCollaborationTitle =>
      'Trip collaboration updated';

  @override
  String get notificationDemoTripCollaborationMessage =>
      'Your Da Lat trip companion list has a local collaboration update ready to review.';

  @override
  String get notificationDemoItineraryReminderTitle =>
      'Itinerary reminder delivered';

  @override
  String get notificationDemoItineraryReminderMessage =>
      'The UI-9 reminder remains a trip reminder record; this is only the delivered in-app notification copy.';

  @override
  String get notificationDemoReviewReplyTitle =>
      'Property replied to your review';

  @override
  String get notificationDemoReviewReplyMessage =>
      'The villa host response is available in your review detail without exposing moderation internals.';

  @override
  String get notificationDemoRewardTitle => 'Benefit update available';

  @override
  String get notificationDemoRewardMessage =>
      'A local rewards and benefits notice is ready in the rewards hub.';

  @override
  String get notificationDemoWalletTitle => 'Wallet document notice';

  @override
  String get notificationDemoWalletMessage =>
      'A masked travel document note is available in your Travel Wallet.';

  @override
  String get notificationDemoSystemTitle => 'Account notice';

  @override
  String get notificationDemoSystemMessage =>
      'Local demo account activity is shown here without push registration or device-token storage.';

  @override
  String profileNotificationsUnreadBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread notifications',
      one: '1 unread notification',
      zero: 'No unread notifications',
    );
    return '$_temp0';
  }

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
  String get hotelsTitle => 'Hotels';

  @override
  String get hotelsSubtitle =>
      'Search accommodation from public place data, then review one room and one local quote.';

  @override
  String get hotelsDestinationLabel => 'Destination';

  @override
  String get hotelsDestinationHint => 'City, hotel, or area';

  @override
  String get hotelsCheckInLabel => 'Check-in';

  @override
  String get hotelsCheckOutLabel => 'Check-out';

  @override
  String get hotelsAdultsLabel => 'Adults';

  @override
  String get hotelsChildrenLabel => 'Children';

  @override
  String get hotelsSearchAction => 'Search stays';

  @override
  String get hotelsSearchSemantic => 'Search hotel stays';

  @override
  String hotelsTripPrefillLabel(String trip) {
    return 'Prefilled from $trip';
  }

  @override
  String get hotelsLocalPreviewMessage =>
      'Hotel discovery uses local accommodation place data. Availability, quotes, and bookings are presentation-only in this UI phase.';

  @override
  String hotelsResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hotels',
      one: '1 hotel',
      zero: 'No hotels',
    );
    return '$_temp0';
  }

  @override
  String get hotelsEmptyTitle => 'No stays found';

  @override
  String get hotelsEmptyMessage => 'Try a different destination or guest mix.';

  @override
  String get hotelsValidationPastCheckIn => 'Check-in cannot be before today.';

  @override
  String get hotelsValidationCheckout => 'Check-out must be after check-in.';

  @override
  String get hotelsValidationAdults => 'At least one adult is required.';

  @override
  String get hotelsValidationChildren => 'Children cannot be negative.';

  @override
  String get hotelsValidationExtraBeds => 'Extra beds cannot be negative.';

  @override
  String get hotelDetailTitle => 'Hotel details';

  @override
  String hotelStars(int stars) {
    String _temp0 = intl.Intl.pluralLogic(
      stars,
      locale: localeName,
      other: '$stars stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String hotelCheckInOutMeta(String checkIn, String checkOut) {
    return 'Check-in $checkIn · Check-out $checkOut';
  }

  @override
  String hotelAvailableRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count matching rooms',
      one: '1 matching room',
      zero: 'No matching rooms',
    );
    return '$_temp0';
  }

  @override
  String get hotelBreakfastIncluded => 'Breakfast';

  @override
  String get hotelAirportShuttle => 'Airport shuttle';

  @override
  String hotelDistanceBeach(int meters) {
    return '$meters m to beach';
  }

  @override
  String hotelDistanceCenter(int meters) {
    return '$meters m to city center';
  }

  @override
  String hotelLanguages(String languages) {
    return 'Languages: $languages';
  }

  @override
  String hotelPaymentMethods(String methods) {
    return 'Payment methods: $methods';
  }

  @override
  String get hotelFacilitiesTitle => 'Facilities';

  @override
  String get hotelServicesTitle => 'Services';

  @override
  String get hotelRoomPreviewTitle => 'Room preview';

  @override
  String get hotelCheckAvailabilityAction => 'Check availability';

  @override
  String hotelCheckAvailabilitySemantic(String hotel) {
    return 'Check availability for $hotel';
  }

  @override
  String get hotelViewRoomsAction => 'View rooms';

  @override
  String hotelCardSemantic(String hotel) {
    return 'Hotel card for $hotel';
  }

  @override
  String hotelFromPrice(String price) {
    return 'From $price';
  }

  @override
  String get hotelRoomsTitle => 'Rooms and rates';

  @override
  String get hotelAvailableRoomsTitle => 'Available rooms';

  @override
  String get hotelNoAvailabilityTitle => 'No matching rooms';

  @override
  String get hotelNoAvailabilityMessage =>
      'No local room result fits the selected guests. Change dates or guest count.';

  @override
  String get hotelRatePlansTitle => 'Choose a rate plan';

  @override
  String get hotelContinueReviewAction => 'Review booking';

  @override
  String get hotelContinueReviewSemantic => 'Continue to booking review';

  @override
  String hotelNights(int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return '$_temp0';
  }

  @override
  String hotelGuestSummary(int adults, int children) {
    String _temp0 = intl.Intl.pluralLogic(
      adults,
      locale: localeName,
      other: '$adults adults',
      one: '1 adult',
    );
    String _temp1 = intl.Intl.pluralLogic(
      children,
      locale: localeName,
      other: '$children children',
      one: '1 child',
      zero: 'no children',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get hotelOneRoomOnly => '1 room';

  @override
  String get hotelAddAdultAction => 'Add adult';

  @override
  String get hotelExtendStayAction => 'Add night';

  @override
  String hotelRoomCardSemantic(String room) {
    return 'Room card for $room';
  }

  @override
  String hotelMaxGuests(int guests) {
    String _temp0 = intl.Intl.pluralLogic(
      guests,
      locale: localeName,
      other: '$guests guests max',
      one: '1 guest max',
    );
    return '$_temp0';
  }

  @override
  String hotelRoomSize(int size) {
    return '$size sqm';
  }

  @override
  String hotelBedCount(int count, String label) {
    return '$count × $label';
  }

  @override
  String hotelRatePlanSemantic(String plan) {
    return 'Rate plan $plan';
  }

  @override
  String get roomTypeStandard => 'Standard';

  @override
  String get roomTypeSuperior => 'Superior';

  @override
  String get roomTypeDeluxe => 'Deluxe';

  @override
  String get roomTypePremier => 'Premier';

  @override
  String get roomTypeExecutive => 'Executive';

  @override
  String get roomTypeSuite => 'Suite';

  @override
  String get roomTypeFamily => 'Family';

  @override
  String get roomTypeVilla => 'Villa';

  @override
  String get roomTypeBungalow => 'Bungalow';

  @override
  String get bedTypeSingle => 'Single bed';

  @override
  String get bedTypeDouble => 'Double bed';

  @override
  String get bedTypeTwin => 'Twin beds';

  @override
  String get bedTypeQueen => 'Queen bed';

  @override
  String get bedTypeKing => 'King bed';

  @override
  String get bedTypeSofaBed => 'Sofa bed';

  @override
  String get bedTypeBunk => 'Bunk bed';

  @override
  String get mealPlanRoomOnly => 'Room only';

  @override
  String get mealPlanBreakfast => 'Breakfast';

  @override
  String get mealPlanHalfBoard => 'Half board';

  @override
  String get mealPlanFullBoard => 'Full board';

  @override
  String get mealPlanAllInclusive => 'All inclusive';

  @override
  String get cancellationFree => 'Free cancellation';

  @override
  String get cancellationFreeDeadlinePassed =>
      'Free-cancellation window passed';

  @override
  String get cancellationPartial => 'Partially refundable';

  @override
  String get cancellationNonRefundable => 'Non-refundable';

  @override
  String get cancellationCustom => 'Custom policy';

  @override
  String get bookingReviewTitle => 'Booking review';

  @override
  String get bookingSelectedPlanTitle => 'Selected rate plan';

  @override
  String bookingQuoteExpiry(String time) {
    return 'Quote expires at $time';
  }

  @override
  String get bookingAccountTitle => 'Account';

  @override
  String get bookingAccountReadOnly =>
      'This identity is read-only here and is not sent with unsupported guest-profile fields.';

  @override
  String get bookingSpecialRequestLabel => 'Special request';

  @override
  String get bookingSpecialRequestHelper =>
      'Optional note only. No payment or guest profile is collected.';

  @override
  String get bookingPriceTitle => 'Pricing quote';

  @override
  String get bookingPriceSemantic => 'Booking price quote';

  @override
  String get bookingFinalNightlyRate => 'Final nightly rate';

  @override
  String get bookingStaySubtotal => 'Stay subtotal';

  @override
  String get bookingPromotionDiscount => 'Promotion discount';

  @override
  String get bookingFinalQuotedPrice => 'Final quoted price';

  @override
  String get bookingCustomerBenefitsExcluded =>
      'Coupons, loyalty, travel credit, and gift cards are outside this UI phase.';

  @override
  String get bookingQuoteNoReservation =>
      'A quote does not create a booking or reserve inventory.';

  @override
  String get bookingQuoteUnavailable => 'Quote unavailable';

  @override
  String get bookingInventoryUnavailable =>
      'Inventory is unavailable for this quote.';

  @override
  String get bookingQuoteExpired =>
      'This quote has expired. Refresh criteria before confirming.';

  @override
  String get bookingDemoBoundaryMessage =>
      'Demo mode can create a clearly local booking. It is not synchronized with the backend.';

  @override
  String get bookingRealUnavailableMessage =>
      'Online booking is not connected yet for real accounts.';

  @override
  String get bookingTermsAcknowledgement =>
      'I understand checkout does not collect card details or reserve real inventory in this UI phase.';

  @override
  String get bookingConfirmAction => 'Confirm demo booking';

  @override
  String get bookingConfirmSemantic => 'Continue to secure checkout';

  @override
  String get bookingDuplicatePrevented =>
      'Duplicate booking creation was blocked.';

  @override
  String get bookingContinueAction => 'Continue to booking';

  @override
  String get bookingContinueSemantic =>
      'Continue to booking with the selected room';

  @override
  String bookingStepLabel(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get bookingSummaryTitle => 'Booking summary';

  @override
  String get bookingSummaryStayTitle => 'Your stay';

  @override
  String get bookingQuoteLoadingMessage => 'Fetching the latest price…';

  @override
  String get bookingQuoteErrorMessage =>
      'We couldn\'t load the price. Please try again.';

  @override
  String get bookingQuoteInvalidDatesMessage =>
      'Check-out must be after check-in.';

  @override
  String get bookingTripLinkedLabel => 'Linked to your trip';

  @override
  String get bookingGuestInfoContinueAction => 'Continue to guest details';

  @override
  String get bookingGuestInfoTitle => 'Guest details';

  @override
  String get bookingGuestSectionTitle => 'Primary guest';

  @override
  String get bookingGuestNameLabel => 'Full name';

  @override
  String get bookingGuestEmailLabel => 'Email';

  @override
  String get bookingGuestPhoneLabel => 'Phone (optional)';

  @override
  String get bookingGuestCountryLabel => 'Country or region (optional)';

  @override
  String get bookingArrivalTimeLabel => 'Estimated arrival time (optional)';

  @override
  String get bookingArrivalTimeHint => 'e.g. 15:00';

  @override
  String get bookingGuestLocalOnlyNote =>
      'Name, phone, country and arrival time are saved on this device for now — the booking API doesn\'t store them yet.';

  @override
  String get bookingSpecialRequestsTitle => 'Special requests';

  @override
  String get specialRequestLateCheckIn => 'Late check-in';

  @override
  String get specialRequestHighFloor => 'High floor';

  @override
  String get specialRequestQuietRoom => 'Quiet room';

  @override
  String get specialRequestTwinBed => 'Twin beds';

  @override
  String get specialRequestLargeBed => 'Large bed';

  @override
  String get bookingSpecialRequestNoteLabel => 'Other requests';

  @override
  String get bookingSpecialRequestNoteHelper =>
      'Optional. Requests are noted but not guaranteed.';

  @override
  String get bookingValidationNameRequired =>
      'Please enter the guest\'s full name.';

  @override
  String get bookingValidationEmailRequired => 'Please enter a contact email.';

  @override
  String get bookingValidationEmailInvalid => 'Enter a valid email address.';

  @override
  String get bookingValidationPhoneInvalid => 'Enter a valid phone number.';

  @override
  String get bookingValidationTooLong => 'This value is too long.';

  @override
  String get bookingReviewContinueAction => 'Continue to review';

  @override
  String get bookingReviewGuestTitle => 'Guest details';

  @override
  String get bookingNoSpecialRequests => 'No special requests';

  @override
  String get bookingDraftTermsAcknowledgement =>
      'I understand this prepares a booking draft only — no reservation, payment, or confirmation is made in this step.';

  @override
  String get bookingDraftNoReservationNote =>
      'Preparing a draft does not create a reservation or take payment.';

  @override
  String get bookingPrepareAction => 'Prepare booking';

  @override
  String get bookingPrepareSemantic => 'Prepare your booking draft';

  @override
  String get bookingDraftInvalidMessage =>
      'Please complete the guest details first.';

  @override
  String get bookingDraftQuoteMissingMessage =>
      'The price is still loading. Please wait a moment.';

  @override
  String get bookingReadyTitle => 'Booking ready';

  @override
  String get bookingReadyHeadline => 'Your booking is ready to confirm';

  @override
  String get bookingReadyBody =>
      'We\'ve prepared your booking details. This is a draft — no reservation has been made, no payment taken, and no confirmation number issued. Connecting the reservation and payment steps is coming next.';

  @override
  String get bookingReadySemantic => 'Booking prepared and ready to confirm';

  @override
  String get bookingReadyDoneAction => 'Back to explore';

  @override
  String get checkoutTitle => 'Secure checkout';

  @override
  String get checkoutContinueAction => 'Continue to secure checkout';

  @override
  String get checkoutSecureTitle => 'Secure checkout';

  @override
  String get checkoutSemantic => 'Secure booking checkout';

  @override
  String get checkoutRealModeLabel => 'Real account';

  @override
  String get checkoutSecureBoundaryPill => 'No card fields';

  @override
  String get checkoutWholeStayTotal => 'Whole-stay total';

  @override
  String get checkoutStaySnapshotTitle => 'Stay snapshot';

  @override
  String get checkoutProviderTitle => 'Payment provider';

  @override
  String get checkoutProviderHelper =>
      'Backend contracts expose hosted provider sessions. UI-13 does not open an external gateway or collect credentials.';

  @override
  String get checkoutMockProviderSubtitle =>
      'Local demo provider for presentation only.';

  @override
  String get checkoutHostedProviderSubtitle =>
      'Hosted provider handoff is proven by backend contracts but not opened in this UI phase.';

  @override
  String get checkoutSecurityTitle => 'Payment security';

  @override
  String get checkoutDemoSecurityBoundary =>
      'Demo Mode can create a local payment attempt for presentation. No money is charged and no gateway callback is sent.';

  @override
  String get checkoutRealUnavailableMessage =>
      'Real checkout requires API/repository integration and hosted-provider handoff wiring. This UI will not simulate success.';

  @override
  String get checkoutNoSensitiveFields =>
      'This app does not ask for card number, expiry, CVV, PIN, bank password, OTP, payment token, or gateway secret.';

  @override
  String get checkoutBenefitsBoundaryTitle => 'Rewards and wallet';

  @override
  String get checkoutBenefitsReadOnlyDemo =>
      'Travel credits, loyalty, coupons, gift cards, and wallet items are read-only here unless a backend checkout contract explicitly applies them.';

  @override
  String get checkoutBenefitsReadOnlyReal =>
      'Rewards and wallet balances are not connected to real checkout in this UI phase.';

  @override
  String get checkoutCreateDemoPaymentAction =>
      'Create demo booking and payment';

  @override
  String get checkoutRealUnavailableAction => 'Real payment unavailable';

  @override
  String get checkoutSubmitSemantic =>
      'Create a local demo booking and payment attempt';

  @override
  String get paymentStatusTitle => 'Payment status';

  @override
  String get paymentRealUnavailableTitle => 'Payment not connected';

  @override
  String get paymentRealUnavailableMessage =>
      'Real payment status requires the backend API/repository integration. No local success is simulated for real accounts.';

  @override
  String get paymentMissingTitle => 'Payment unavailable';

  @override
  String get paymentMissingMessage =>
      'This local payment attempt is no longer available.';

  @override
  String get paymentDemoFailureReason => 'Demo provider declined the payment.';

  @override
  String get paymentStatusSemantic => 'Payment status detail';

  @override
  String get paymentDemoLocalOnly =>
      'This payment status is local Demo Mode presentation data and is not a real charge.';

  @override
  String get paymentDetailsTitle => 'Payment details';

  @override
  String get paymentProviderLabel => 'Provider';

  @override
  String get paymentSessionStatusLabel => 'Gateway session';

  @override
  String get paymentAmountLabel => 'Amount';

  @override
  String get paymentCreatedLabel => 'Payment created';

  @override
  String get paymentHoldExpiresLabel => 'Hold expires';

  @override
  String get paymentPaidAtLabel => 'Paid at';

  @override
  String get paymentFailedAtLabel => 'Failed at';

  @override
  String get paymentCancelledAtLabel => 'Cancelled at';

  @override
  String get paymentRefundedAtLabel => 'Refunded at';

  @override
  String get paymentReferenceLabel => 'Provider reference';

  @override
  String get paymentMaskedReferenceSemantic => 'Masked provider reference';

  @override
  String get paymentFailureReasonLabel => 'Failure reason';

  @override
  String get paymentNoRefundInference =>
      'Cancellation and payment status are separate. A cancelled booking is not shown as refunded unless a refund status is present.';

  @override
  String get paymentActionsTitle => 'Payment actions';

  @override
  String get paymentCompleteDemoAction => 'Complete demo payment';

  @override
  String get paymentCompleteDemoSemantic => 'Complete this local demo payment';

  @override
  String get paymentFailDemoAction => 'Fail demo payment';

  @override
  String get paymentCancelDemoAction => 'Cancel payment session';

  @override
  String get paymentRetryAction => 'Retry payment';

  @override
  String get paymentContinueAction => 'Continue payment';

  @override
  String get paymentStatusAction => 'Payment status';

  @override
  String get paymentContinueConfirmationAction => 'Continue to confirmation';

  @override
  String get paymentPendingBoundary =>
      'Pending demo payments can be completed, failed, or cancelled locally. Real provider callbacks are not simulated.';

  @override
  String get paymentTerminalBoundary =>
      'Terminal payment states are shown as immutable snapshots. Retry is available only when backend rules allow a new attempt.';

  @override
  String get paymentProviderMock => 'Mock provider';

  @override
  String get paymentProviderVnpay => 'VNPay';

  @override
  String get paymentProviderPayos => 'PayOS';

  @override
  String get paymentProviderMomo => 'MoMo';

  @override
  String get paymentProviderStripe => 'Stripe';

  @override
  String get paymentProviderApplePay => 'Apple Pay';

  @override
  String get paymentProviderGooglePay => 'Google Pay';

  @override
  String get paymentProviderManual => 'Manual';

  @override
  String get paymentSessionStatusNew => 'New';

  @override
  String get paymentSessionStatusPending => 'Pending';

  @override
  String get paymentSessionStatusAuthorized => 'Authorized';

  @override
  String get paymentSessionStatusCaptured => 'Captured';

  @override
  String get paymentSessionStatusFailed => 'Failed';

  @override
  String get paymentSessionStatusCancelled => 'Cancelled';

  @override
  String get paymentSessionStatusExpired => 'Expired';

  @override
  String get paymentResultSuccessTitle => 'Payment completed';

  @override
  String get paymentResultPendingTitle => 'Payment pending';

  @override
  String get paymentResultFailedTitle => 'Payment failed';

  @override
  String get paymentResultCancelledTitle => 'Payment cancelled';

  @override
  String get paymentResultExpiredTitle => 'Payment expired';

  @override
  String get paymentActionSuccess => 'Payment state updated.';

  @override
  String get paymentActionUnavailable =>
      'Payment action is unavailable for this account.';

  @override
  String get paymentDuplicatePrevented =>
      'Duplicate checkout submission was blocked.';

  @override
  String get paymentActionInvalidState =>
      'This payment state cannot perform that action.';

  @override
  String get bookingConfirmationTitle => 'Demo booking confirmed';

  @override
  String get bookingDemoStatus => 'Local demo booking';

  @override
  String bookingLocalCode(String code) {
    return 'Local code $code';
  }

  @override
  String get bookingConfirmationLocalOnly =>
      'This booking is local demo presentation data. It is not synced with the backend and does not hold inventory.';

  @override
  String get bookingAddItineraryAction => 'Add to itinerary';

  @override
  String get bookingAddItinerarySemantic =>
      'Add this booking to the trip itinerary';

  @override
  String get bookingItineraryAdded => 'Added to itinerary';

  @override
  String get bookingItineraryAlreadyAdded =>
      'This stay is already in the itinerary.';

  @override
  String get bookingItineraryAddedMessage => 'Stay added to the itinerary.';

  @override
  String bookingItineraryNote(String code) {
    return 'Local demo booking $code.';
  }

  @override
  String get bookingViewBookingAction => 'View booking';

  @override
  String get bookingReturnHomeAction => 'Return home';

  @override
  String get myBookingsTitle => 'My Bookings';

  @override
  String get myBookingsDemoLocalOnly =>
      'Only local demo bookings appear here. Real booking management is not connected yet.';

  @override
  String get myBookingsRealEmptyTitle => 'Bookings not connected';

  @override
  String get myBookingsRealEmptyMessage =>
      'Real account bookings will appear after the backend integration is wired.';

  @override
  String get myBookingsEmptyTitle => 'No bookings';

  @override
  String get myBookingsEmptyMessage =>
      'Demo bookings appear here after confirmation or from the seeded local stay examples.';

  @override
  String get myBookingCardSemantic => 'Booking card';

  @override
  String get bookingDetailsTitle => 'Booking details';

  @override
  String get bookingDetailMissingTitle => 'Booking unavailable';

  @override
  String get bookingDetailMissingMessage =>
      'This local booking is no longer available.';

  @override
  String get bookingDetailSemantic => 'Booking detail';

  @override
  String get bookingPaymentUnavailableAction => 'Payment unavailable';

  @override
  String get bookingPaymentUnavailable =>
      'Payment actions are not connected in this UI phase.';

  @override
  String get bookingStayOverviewTitle => 'Stay overview';

  @override
  String get bookingSnapshotTitle => 'Room and rate snapshot';

  @override
  String get bookingPolicyTitle => 'Cancellation policy';

  @override
  String get bookingTimelineTitle => 'Status timeline';

  @override
  String get bookingActionsTitle => 'Booking actions';

  @override
  String get bookingCodeLabel => 'Booking code';

  @override
  String get bookingCodeSemantic => 'Local booking reference';

  @override
  String get bookingDatesLabel => 'Stay dates';

  @override
  String get bookingNightsLabel => 'Nights';

  @override
  String get bookingGuestsLabel => 'Guests';

  @override
  String get bookingRoomsLabel => 'Rooms';

  @override
  String bookingRoomsValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms',
      one: '1 room',
    );
    return '$_temp0';
  }

  @override
  String get bookingCreatedLabel => 'Created';

  @override
  String get bookingConfirmedLabel => 'Confirmed';

  @override
  String get bookingCancelledAtLabel => 'Cancelled';

  @override
  String get bookingCancellationReasonLabel => 'Cancellation reason';

  @override
  String get bookingHotelLabel => 'Hotel';

  @override
  String get bookingRoomLabel => 'Room';

  @override
  String get bookingRoomCodeLabel => 'Room code';

  @override
  String get bookingRatePlanLabel => 'Rate plan';

  @override
  String get bookingMealPlanLabel => 'Meal plan';

  @override
  String get bookingTotalLabel => 'Total';

  @override
  String get bookingPaymentStatusLabel => 'Payment status';

  @override
  String get bookingPaymentStatusPending => 'Payment pending';

  @override
  String get bookingPaymentStatusPaid => 'Paid';

  @override
  String get bookingPaymentStatusFailed => 'Payment failed';

  @override
  String get bookingPaymentStatusCancelled => 'Payment cancelled';

  @override
  String get bookingPaymentStatusRefunded => 'Refunded';

  @override
  String get bookingCancellationPolicyLabel => 'Policy type';

  @override
  String get bookingPolicySummaryLabel => 'Policy summary';

  @override
  String get bookingCancellationDeadlineLabel => 'Deadline';

  @override
  String bookingCancellationDeadlineValue(String date) {
    return 'Cancellation deadline: $date';
  }

  @override
  String get bookingRefundableLabel => 'Refundability';

  @override
  String get bookingRefundableYes => 'Refundable';

  @override
  String get bookingRefundableNo => 'Non-refundable';

  @override
  String get bookingCancellationDeadlinePassedPolicy =>
      'The free-cancellation window has passed. Cancellation can still be requested for eligible booking statuses, but the backend policy preview treats this as a full-penalty cancellation.';

  @override
  String get bookingRefundBoundary =>
      'Refund calculation and payout are not simulated in local Demo Mode.';

  @override
  String get bookingViewReviewAction => 'View review';

  @override
  String get bookingViewPlaceAction => 'View hotel';

  @override
  String get bookingUnsupportedMessage =>
      'Settled-booking changes, rescheduling, invoice downloads, refunds, and property messaging require backend integration and are not simulated locally.';

  @override
  String get bookingModifyAction => 'Modify booking';

  @override
  String get bookingModifyTitle => 'Modify booking';

  @override
  String get bookingModifySemantic => 'Modify this pending demo booking';

  @override
  String get bookingModifyIntro =>
      'Only pending demo bookings can be changed locally. Confirmed, paid, checked-in, completed, cancelled, refunded, archived, and no-show bookings stay locked.';

  @override
  String get bookingModifyAvailableLabel => 'Pending changes available';

  @override
  String get bookingModifyUnavailableLabel => 'Changes unavailable';

  @override
  String get bookingModifyDemoLabel => 'Local Demo Mode';

  @override
  String get bookingModifyDemoBoundary =>
      'This updates only deterministic local presentation data and never claims live availability.';

  @override
  String get bookingModifyEditTitle => 'Edit supported fields';

  @override
  String get bookingModifyEditableFields =>
      'Backend-supported fields in this UI phase are check-in, check-out, adults, children, extra beds, and rate plan. Hotel, room, room count, and benefits stay unchanged.';

  @override
  String get bookingModifyReviewTitle => 'Review changes';

  @override
  String get bookingModifyReviewInstruction =>
      'Review the current and proposed values before confirming. The original booking is unchanged until confirmation succeeds.';

  @override
  String get bookingModifyCurrentLabel => 'Current';

  @override
  String get bookingModifyProposedLabel => 'Proposed';

  @override
  String get bookingModifyUnchangedLabel => 'Unchanged';

  @override
  String get bookingModifyChangedLabel => 'Changed';

  @override
  String get bookingModifyCheckInLabel => 'Check-in date';

  @override
  String get bookingModifyCheckOutLabel => 'Check-out date';

  @override
  String get bookingModifyAdultsLabel => 'Adults';

  @override
  String get bookingModifyChildrenLabel => 'Children';

  @override
  String get bookingModifyExtraBedsLabel => 'Extra beds';

  @override
  String get bookingModifyRatePlanLabel => 'Rate plan';

  @override
  String get bookingModifyRatePlanHelper =>
      'Only eligible rate plans on the same room can be selected.';

  @override
  String get bookingModifyDateHelp => 'Use YYYY-MM-DD.';

  @override
  String get bookingModifyRequiredField => 'This field is required.';

  @override
  String get bookingModifyRoomUnchanged => 'Same room';

  @override
  String get bookingModifyRoomCountUnchanged =>
      'Room and room count are not editable in the backend modification contract.';

  @override
  String get bookingModifyContinueReviewAction => 'Review changes';

  @override
  String get bookingModifyConfirmAction => 'Confirm changes';

  @override
  String get bookingModifyBackToEditAction => 'Back to edit';

  @override
  String get bookingModifySuccessMessage => 'Demo booking modified locally.';

  @override
  String get bookingModifyUnavailableReal =>
      'Real booking modification requires backend API integration.';

  @override
  String get bookingModifyUnavailableNotFound =>
      'This booking is no longer available.';

  @override
  String get bookingModifyUnavailableForbidden =>
      'This booking belongs to another traveler.';

  @override
  String get bookingModifyUnavailableOnlyPending =>
      'Only pending bookings can be changed.';

  @override
  String get bookingModifyUnavailablePaymentStarted =>
      'This local booking already has a payment attempt, so its stay snapshot is locked for UI safety.';

  @override
  String get bookingModifyUnavailableRoomRate =>
      'The room or rate-plan snapshot is no longer available.';

  @override
  String get bookingModifyUnavailableStarted =>
      'This stay has already started.';

  @override
  String get bookingModifyInvalidDates =>
      'Choose a future check-in date and a check-out date after check-in.';

  @override
  String get bookingModifyInvalidGuests =>
      'Guest counts must be valid and nonnegative.';

  @override
  String get bookingModifyCapacityExceeded =>
      'Guest counts exceed this room\'s capacity.';

  @override
  String get bookingModifyQuoteUnavailable =>
      'A safe local modification quote is unavailable for these values.';

  @override
  String get bookingModifyNoChanges =>
      'Change at least one supported field before review.';

  @override
  String get bookingModifyStale =>
      'This booking changed while you were editing. Reopen the form and review the latest values.';

  @override
  String get bookingModifyBoundariesTitle => 'Modification boundaries';

  @override
  String get bookingModifyPriceBoundaryLabel => 'Price impact';

  @override
  String get bookingModifyPriceBoundary =>
      'The new total is a deterministic local demo estimate shaped like the backend canonical whole-stay total. It is not a live backend quote.';

  @override
  String get bookingModifyAvailabilityBoundaryLabel => 'Availability';

  @override
  String get bookingModifyAvailabilityBoundary =>
      'Local Demo Mode does not decrement inventory or create a new hold. Live availability remains a backend responsibility.';

  @override
  String get bookingModifyPaymentBoundaryLabel => 'Payment';

  @override
  String get bookingModifyPaymentBoundary =>
      'Modification does not mark payment paid, failed, cancelled, or refunded and does not create a payment attempt.';

  @override
  String get bookingModifySnapshotBoundary =>
      'No customer-safe policy summary is available for this rate snapshot.';

  @override
  String get bookingModifyLiveRepricingTitle => 'Live backend quote';

  @override
  String get bookingModifyLiveRepricingUnavailable =>
      'Live repricing and overlap-adjusted inventory checks are shown as an honest integration boundary until networking is connected.';

  @override
  String get bookingCancelAction => 'Cancel booking';

  @override
  String get bookingCancelSemantic => 'Cancel this demo booking';

  @override
  String get bookingCancelConfirmTitle => 'Cancel demo booking?';

  @override
  String bookingCancelConfirmMessage(String code) {
    return 'Cancel local booking $code? The stay remains in history and no backend request is sent.';
  }

  @override
  String get bookingCancelReasonLabel => 'Cancellation reason';

  @override
  String get bookingCancelReasonHelper =>
      'Optional local note. The backend contract does not require a reason.';

  @override
  String get bookingCancellationLocalWarning =>
      'This changes only local Demo Mode presentation data.';

  @override
  String get bookingCancelledMessage => 'Demo booking cancelled locally.';

  @override
  String get bookingCancellationUnavailableReal =>
      'Real booking cancellation requires backend integration.';

  @override
  String get bookingCancellationUnavailableForbidden =>
      'This booking belongs to another traveler.';

  @override
  String get bookingCancellationUnavailableAlready =>
      'This booking is already cancelled.';

  @override
  String get bookingCancellationUnavailableCompleted =>
      'Completed and historical stays cannot be cancelled.';

  @override
  String get bookingCancellationUnavailableStarted =>
      'Check-in has started, so customer cancellation is unavailable.';

  @override
  String get bookingCancellationUnavailableGeneric =>
      'Cancellation is unavailable for this booking status.';

  @override
  String get bookingSectionAll => 'All';

  @override
  String get bookingSectionUpcoming => 'Upcoming';

  @override
  String get bookingSectionActive => 'Active';

  @override
  String get bookingSectionHistory => 'History';

  @override
  String get bookingSectionCancelled => 'Cancelled';

  @override
  String get bookingStatusPending => 'Pending';

  @override
  String get bookingStatusConfirmed => 'Confirmed';

  @override
  String get bookingStatusCheckInReady => 'Check-in ready';

  @override
  String get bookingStatusCheckedIn => 'Checked in';

  @override
  String get bookingStatusCheckedOut => 'Checked out';

  @override
  String get bookingStatusCompleted => 'Completed';

  @override
  String get bookingStatusCancelled => 'Cancelled';

  @override
  String get bookingStatusRefunded => 'Refunded';

  @override
  String get bookingStatusArchived => 'Archived';

  @override
  String get bookingStatusNoShow => 'No-show';

  @override
  String get bookingTimelineCreated => 'Booking created';

  @override
  String get bookingTimelinePaid => 'Payment completed';

  @override
  String get bookingTimelineConfirmed => 'Booking confirmed';

  @override
  String get bookingTimelineModified => 'Booking modified';

  @override
  String get bookingTimelineCheckedIn => 'Guest checked in';

  @override
  String get bookingTimelineCheckedOut => 'Guest checked out';

  @override
  String get bookingTimelineCompleted => 'Stay completed';

  @override
  String get bookingTimelineCancelled => 'Booking cancelled';

  @override
  String get bookingTimelineArchived => 'Booking archived';

  @override
  String get bookingTimelineRefunded => 'Payment refunded';

  @override
  String get bookingTimelineUnknown => 'Status updated';

  @override
  String get rewardsTitle => 'Rewards & Benefits';

  @override
  String get rewardsDemoSubtitle =>
      'Local demo rewards for previewing credits, points, coupons, referrals, and gift cards.';

  @override
  String get rewardsRealUnavailableMessage =>
      'Rewards endpoints are not connected yet for real accounts.';

  @override
  String get rewardsRealEmptyTitle => 'Rewards not connected';

  @override
  String get rewardsNotConnected => 'Not connected';

  @override
  String rewardsCountValue(int count) {
    return '$count items';
  }

  @override
  String get rewardsHistoryEmptyTitle => 'No history';

  @override
  String get rewardsHistoryEmptyMessage =>
      'Reward history will appear here when available.';

  @override
  String get rewardsActionUnavailable =>
      'This reward action is not connected for real accounts.';

  @override
  String get rewardsCodeBlank => 'Enter a code first.';

  @override
  String get rewardsCodeDuplicate => 'This code is already used or claimed.';

  @override
  String get rewardsCodeRejected => 'This demo code is not eligible.';

  @override
  String rewardsExpiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String get travelCreditsTitle => 'Travel Credits';

  @override
  String get travelCreditsSubtitle =>
      'Promotional monetary credit, separate from travel wallet documents.';

  @override
  String get travelCreditsSemantic => 'Open Travel Credits';

  @override
  String get travelCreditsBalance => 'Available travel credit';

  @override
  String get travelCreditsBalanceSemantic => 'Travel credit balance';

  @override
  String get travelCreditsLocalOnly =>
      'Demo credits are local preview data and are not synchronized.';

  @override
  String get travelCreditsNoCashOut =>
      'Cash-out, withdrawal, and transfer controls are intentionally unavailable.';

  @override
  String get travelCreditsTransactions => 'Credit transactions';

  @override
  String get creditTxnGrant => 'Grant';

  @override
  String get creditTxnPromotion => 'Promotion';

  @override
  String get creditTxnRefund => 'Refund credit';

  @override
  String get creditTxnAdjustment => 'Adjustment';

  @override
  String get creditTxnRedemption => 'Redemption';

  @override
  String get creditTxnExpiration => 'Expiration';

  @override
  String get creditTxnReversal => 'Reversal';

  @override
  String get loyaltyTitle => 'Loyalty Points';

  @override
  String get loyaltySubtitle =>
      'Integer point balance and immutable transaction history.';

  @override
  String get loyaltySemantic => 'Open Loyalty Points';

  @override
  String get loyaltyBalanceSemantic => 'Loyalty point balance';

  @override
  String get loyaltyCurrentBalance => 'Current balance';

  @override
  String get loyaltyLifetimeEarned => 'Lifetime earned';

  @override
  String loyaltyPointsValue(int points) {
    return '$points points';
  }

  @override
  String get pointsUnit => 'points';

  @override
  String get loyaltyNoDirectRedeem =>
      'Points are not money and direct redemption is not connected in UI-7.';

  @override
  String get loyaltyTransactions => 'Point transactions';

  @override
  String get loyaltyTxnEarnBooking => 'Earn from booking';

  @override
  String get loyaltyTxnEarnReview => 'Earn from review';

  @override
  String get loyaltyTxnGrant => 'Grant';

  @override
  String get loyaltyTxnAdjustment => 'Adjustment';

  @override
  String get loyaltyTxnReversal => 'Reversal';

  @override
  String get loyaltyTxnRedemptionDebit => 'Redemption debit';

  @override
  String get loyaltyTxnRedemptionRelease => 'Redemption release';

  @override
  String get loyaltyTxnRedemptionRefund => 'Redemption refund';

  @override
  String get membershipTitle => 'Membership';

  @override
  String get membershipSubtitle =>
      'Tier progress, benefits metadata, and tier history.';

  @override
  String get membershipSemantic => 'Open Membership';

  @override
  String get membershipRealUnavailable =>
      'Membership enrollment is not connected yet for real accounts.';

  @override
  String get membershipTierSemantic => 'Membership tier and progress';

  @override
  String get membershipActiveStatus => 'Active';

  @override
  String get membershipPreviewStatus => 'Preview';

  @override
  String get membershipExpiredStatus => 'Expired';

  @override
  String get membershipActiveMessage =>
      'This demo membership is active locally.';

  @override
  String get membershipPreviewMessage =>
      'Preview benefits before demo enrollment.';

  @override
  String membershipProgressSemantic(int percent) {
    return 'Membership progress $percent percent';
  }

  @override
  String get membershipHighestTier =>
      'Highest tier reached. No fictional next tier is shown.';

  @override
  String membershipNextTier(String tier) {
    return 'Next tier: $tier';
  }

  @override
  String get membershipEnrollAction => 'Enroll locally';

  @override
  String get membershipEnrolledAction => 'Enrolled locally';

  @override
  String get membershipEnrollSemantic => 'Enroll in local demo membership';

  @override
  String get membershipEnrollSuccess => 'Demo membership enrolled locally.';

  @override
  String get membershipBenefitsTitle => 'Benefits metadata';

  @override
  String get membershipHistoryTitle => 'Tier history';

  @override
  String get membershipTierBronze => 'Bronze';

  @override
  String get membershipTierSilver => 'Silver';

  @override
  String get membershipTierGold => 'Gold';

  @override
  String get membershipTierPlatinum => 'Platinum';

  @override
  String get membershipTierDiamond => 'Diamond';

  @override
  String get benefitPointsMultiplier => 'Points multiplier';

  @override
  String get benefitMemberCoupons => 'Member-only coupons';

  @override
  String get benefitPrioritySupport => 'Priority support';

  @override
  String get benefitEarlyAccess => 'Early access';

  @override
  String get benefitLateCheckout => 'Late checkout';

  @override
  String get benefitEarlyCheckin => 'Early check-in';

  @override
  String get benefitRoomUpgrade => 'Room upgrade';

  @override
  String get benefitFreeBreakfast => 'Free breakfast';

  @override
  String get benefitAirportTransfer => 'Airport transfer';

  @override
  String get benefitCustom => 'Custom benefit';

  @override
  String get couponsTitle => 'Coupons';

  @override
  String get couponsSubtitle =>
      'Claimed coupons and read-only eligibility previews.';

  @override
  String get couponsSemantic => 'Open Coupons';

  @override
  String get couponsRealUnavailable =>
      'Coupon claiming is not connected yet for real accounts.';

  @override
  String get couponClaimTitle => 'Claim demo coupon';

  @override
  String get couponCodeLabel => 'Coupon code';

  @override
  String get couponClaimHelper =>
      'Use LOCAL300 for the local demo claim. Coupons are not applied to bookings.';

  @override
  String get couponClaimAction => 'Claim coupon';

  @override
  String get couponClaimSemantic => 'Claim local demo coupon';

  @override
  String get couponClaimSuccess => 'Demo coupon claimed locally.';

  @override
  String get couponsEmptyTitle => 'No coupons';

  @override
  String get couponsEmptyMessage =>
      'Coupons will appear after they are claimed or connected.';

  @override
  String couponCardSemantic(String code) {
    return 'Coupon $code';
  }

  @override
  String get couponPreviewReadOnly =>
      'Preview is read-only and does not mark the coupon used.';

  @override
  String couponPercentageValue(int percent) {
    return '$percent% off';
  }

  @override
  String couponFixedValue(String amount) {
    return '$amount off';
  }

  @override
  String get couponAmountUnavailable => 'Amount unavailable';

  @override
  String get couponTargetAll => 'All';

  @override
  String get couponTargetHotel => 'Hotel';

  @override
  String get couponTargetRoom => 'Room';

  @override
  String get couponTargetPlaceType => 'Place type';

  @override
  String get referralTitle => 'Referral';

  @override
  String get referralSubtitle =>
      'Referral code, statistics, and local demo code use.';

  @override
  String get referralSemantic => 'Open Referral';

  @override
  String get referralRealUnavailable =>
      'Referral actions are not connected yet for real accounts.';

  @override
  String get referralCodeSemantic => 'Referral code';

  @override
  String get referralYourCode => 'Your referral code';

  @override
  String referralStats(int successful, int pending) {
    return '$successful successful · $pending pending';
  }

  @override
  String get referralCopyAction => 'Copy code';

  @override
  String get referralCopiedAction => 'Copied';

  @override
  String get referralCopySemantic => 'Copy referral code';

  @override
  String get referralUseCodeTitle => 'Use referral code';

  @override
  String get referralCodeLabel => 'Referral code';

  @override
  String get referralUseCodeHelper =>
      'Using a code creates a pending local referral only. No reward is granted immediately.';

  @override
  String get referralUseCodeAction => 'Use code';

  @override
  String get referralUseCodeSemantic => 'Use local demo referral code';

  @override
  String get referralUseSuccess => 'Referral code recorded locally as pending.';

  @override
  String get referralOwnCodeRejected =>
      'You cannot use your own referral code.';

  @override
  String get referralHistoryTitle => 'Referral history';

  @override
  String get referralUsedNoReward =>
      'USED means pending qualification; no reward was granted.';

  @override
  String get referralRoleInviter => 'Inviter';

  @override
  String get referralRoleInvitee => 'Invitee';

  @override
  String get referralStatusUsed => 'Used';

  @override
  String get referralStatusRewarded => 'Rewarded';

  @override
  String get giftCardsTitle => 'Gift Cards';

  @override
  String get giftCardsSubtitle =>
      'Masked cards, balances, details, and read-only previews.';

  @override
  String get giftCardsSemantic => 'Open Gift Cards';

  @override
  String get giftCardsRealUnavailable =>
      'Gift-card actions are not connected yet for real accounts.';

  @override
  String get giftCardClaimTitle => 'Claim demo gift card';

  @override
  String get giftCardCodeLabel => 'Gift-card code';

  @override
  String get giftCardClaimHelper =>
      'Use GIFTDEMO for a local demo claim. No purchase or payment flow exists.';

  @override
  String get giftCardClaimAction => 'Claim gift card';

  @override
  String get giftCardClaimSemantic => 'Claim local demo gift card';

  @override
  String get giftCardClaimSuccess => 'Demo gift card claimed locally.';

  @override
  String get giftCardsEmptyTitle => 'No gift cards';

  @override
  String get giftCardsEmptyMessage =>
      'Gift cards will appear after they are claimed or connected.';

  @override
  String giftCardCardSemantic(String code) {
    return 'Gift card $code';
  }

  @override
  String get giftCardBalance => 'Card balance';

  @override
  String get giftCardTransactionsTitle => 'Gift-card transactions';

  @override
  String get giftCardPreviewAction => 'Preview only';

  @override
  String get giftCardPreviewSemantic =>
      'Preview gift card without changing balance';

  @override
  String get giftCardPreviewReadOnly =>
      'Gift-card preview is read-only and does not change balance.';

  @override
  String get giftCardActivateAction => 'Activate locally';

  @override
  String get giftCardActivateSuccess => 'Demo gift card activated locally.';

  @override
  String get giftCardStatusIssued => 'Issued';

  @override
  String get giftCardStatusActive => 'Active';

  @override
  String get giftCardStatusPartiallyRedeemed => 'Partially redeemed';

  @override
  String get giftCardStatusFullyRedeemed => 'Fully redeemed';

  @override
  String get giftCardStatusExpired => 'Expired';

  @override
  String get giftCardStatusCancelled => 'Cancelled';

  @override
  String get giftCardTxnIssue => 'Issue';

  @override
  String get giftCardTxnActivation => 'Activation';

  @override
  String get giftCardTxnRedemption => 'Redemption';

  @override
  String get giftCardTxnRefund => 'Refund';

  @override
  String get giftCardTxnExpiry => 'Expiry';

  @override
  String get commonBackSemantic => 'Go back';

  @override
  String get demoModeLabel => 'Demo Mode';

  @override
  String get travelWalletTitle => 'Travel Wallet';

  @override
  String get walletDemoSubtitle =>
      'Local demo organizer for passports, visas, tickets, vouchers, receipts, and booking confirmations.';

  @override
  String get walletPrivacyNotice =>
      'Sensitive document numbers are masked before storage. UI-8 does not upload files, scan documents, or synchronize wallet data.';

  @override
  String get walletRealEmptyTitle => 'Travel Wallet is not connected yet';

  @override
  String get walletRealEmptyMessage =>
      'Real accounts will show wallet documents after backend integration. No demo wallet data is shown for real sessions.';

  @override
  String get walletSummaryTotal => 'Total';

  @override
  String get walletSummaryActive => 'Active';

  @override
  String get walletSummaryUpcoming => 'Upcoming';

  @override
  String get walletSummaryExpiringSoon => 'Expiring soon';

  @override
  String get walletSummaryExpired => 'Expired';

  @override
  String get walletSummaryFavorites => 'Favorites';

  @override
  String get walletSummaryArchived => 'Archived';

  @override
  String get walletSummaryUnlinked => 'Unlinked';

  @override
  String walletSummarySemantic(String label, int count) {
    return '$label: $count';
  }

  @override
  String get walletSearchHint =>
      'Search title, issuer, masked reference, or trip';

  @override
  String get walletFilterCategory => 'Category';

  @override
  String get walletFilterType => 'Item type';

  @override
  String get walletFilterStatus => 'Status';

  @override
  String get walletFilterLinkedTrip => 'Linked trip';

  @override
  String get walletFilterAll => 'All';

  @override
  String get walletFavoritesOnly => 'Favorites only';

  @override
  String get walletArchivedOnly => 'Archived only';

  @override
  String get walletCreateItemAction => 'Add wallet item';

  @override
  String get walletImportBookingAction => 'Import booking';

  @override
  String get walletNoBookingsToImport =>
      'No local demo bookings are available to import.';

  @override
  String get walletEmptyTitle => 'No wallet items match';

  @override
  String get walletEmptyMessage =>
      'Adjust search or filters, or add local demo metadata.';

  @override
  String get walletSectionFavorites => 'Favorites';

  @override
  String get walletSectionExpiringSoon => 'Expiring soon';

  @override
  String get walletSectionUpcoming => 'Upcoming';

  @override
  String get walletSectionActive => 'Active';

  @override
  String get walletSectionExpired => 'Expired';

  @override
  String get walletSectionArchived => 'Archived';

  @override
  String get walletSectionByCategory => 'By category';

  @override
  String get walletSectionByTrip => 'By trip';

  @override
  String walletItemSemantic(String title) {
    return 'Wallet item $title';
  }

  @override
  String get walletSourceMetadata => 'Metadata only';

  @override
  String get walletSourceTripDocument => 'Trip document';

  @override
  String get walletSourceBooking => 'Booking';

  @override
  String get walletSourceInvoice => 'Invoice';

  @override
  String get walletReferenceLabel => 'Masked reference';

  @override
  String walletMaskedReference(String reference) {
    return 'Masked reference $reference';
  }

  @override
  String get walletValidityLabel => 'Validity';

  @override
  String get walletNoValidity => 'No validity dates supplied';

  @override
  String walletValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String walletValidFrom(String date) {
    return 'Valid from $date';
  }

  @override
  String walletValidPeriod(String from, String until) {
    return '$from - $until';
  }

  @override
  String get walletLinkedTripLabel => 'Linked trip';

  @override
  String get walletReminderLabel => 'Expiry reminder';

  @override
  String get walletReminderEnabled => 'Local reminder preference enabled';

  @override
  String get walletReminderDisabled => 'Local reminder preference disabled';

  @override
  String get walletReminderEnableAction => 'Enable reminder';

  @override
  String get walletReminderDisableAction => 'Disable reminder';

  @override
  String get walletFavoriteAction => 'Favorite';

  @override
  String get walletUnfavoriteAction => 'Unfavorite';

  @override
  String get walletArchiveAction => 'Archive';

  @override
  String get walletRestoreAction => 'Restore';

  @override
  String get walletDeleteAction => 'Delete';

  @override
  String get walletEditAction => 'Edit';

  @override
  String get walletSaveAction => 'Save';

  @override
  String get walletCreateTitle => 'Add wallet metadata';

  @override
  String get walletEditTitle => 'Edit wallet metadata';

  @override
  String get walletTitleLabel => 'Title';

  @override
  String get walletIssuerLabel => 'Issuer';

  @override
  String get walletReferenceInputLabel => 'Reference number';

  @override
  String get walletReferencePrivacyHelper =>
      'Reference input is masked immediately and the raw value is not retained.';

  @override
  String get walletTypeLabel => 'Wallet item type';

  @override
  String get walletStatusLabel => 'Stored status';

  @override
  String get walletNoValue => 'Not supplied';

  @override
  String get walletUpdatedLabel => 'Updated';

  @override
  String get walletDeleteConfirmTitle => 'Delete wallet item?';

  @override
  String walletDeleteConfirmMessage(String title) {
    return 'Delete $title from the local demo wallet? The linked trip, booking, or document will not be deleted.';
  }

  @override
  String get walletSavedMessage => 'Wallet item saved locally.';

  @override
  String get walletDeletedMessage => 'Wallet item deleted locally.';

  @override
  String get walletDuplicateMessage => 'That local item already exists.';

  @override
  String get walletActionRejectedMessage =>
      'That wallet action cannot be completed with the current data.';

  @override
  String get walletInvalidDateMessage =>
      'Valid-until date cannot be before valid-from date.';

  @override
  String get walletNotFoundMessage =>
      'The selected wallet item no longer exists.';

  @override
  String get walletActionUnavailable =>
      'Travel Wallet actions are not connected for real accounts in this UI phase.';

  @override
  String get walletTitleRequiredMessage => 'Enter a title before saving.';

  @override
  String get walletBookingImportedMessage =>
      'Booking confirmation saved to the local demo wallet.';

  @override
  String get walletBookingAlreadyImportedMessage =>
      'That booking is already in the local demo wallet.';

  @override
  String get walletSaveBookingAction => 'Save to Travel Wallet';

  @override
  String get walletSaveBookingSemantic =>
      'Save this local demo booking to Travel Wallet';

  @override
  String get walletTypePassport => 'Passport';

  @override
  String get walletTypeVisa => 'Visa';

  @override
  String get walletTypeBoardingPass => 'Boarding pass';

  @override
  String get walletTypeFlightTicket => 'Flight ticket';

  @override
  String get walletTypeTrainTicket => 'Train ticket';

  @override
  String get walletTypeBusTicket => 'Bus ticket';

  @override
  String get walletTypeHotelVoucher => 'Hotel voucher';

  @override
  String get walletTypeTourVoucher => 'Tour voucher';

  @override
  String get walletTypeInsurance => 'Insurance';

  @override
  String get walletTypeBookingConfirmation => 'Booking confirmation';

  @override
  String get walletTypeInvoice => 'Invoice';

  @override
  String get walletTypeReceipt => 'Receipt';

  @override
  String get walletTypeItinerary => 'Itinerary';

  @override
  String get walletTypeOther => 'Other';

  @override
  String get walletCategoryIdentity => 'Identity';

  @override
  String get walletCategoryTransport => 'Transport';

  @override
  String get walletCategoryAccommodation => 'Accommodation';

  @override
  String get walletCategoryActivity => 'Activity';

  @override
  String get walletCategoryInsurance => 'Insurance';

  @override
  String get walletCategoryFinancial => 'Financial';

  @override
  String get walletCategoryOther => 'Other';

  @override
  String get walletStatusActive => 'Active';

  @override
  String get walletStatusUpcoming => 'Upcoming';

  @override
  String get walletStatusExpired => 'Expired';

  @override
  String get walletStatusCancelled => 'Cancelled';

  @override
  String get walletStatusArchived => 'Archived';

  @override
  String get tripDocumentsAction => 'Documents';

  @override
  String get tripDocumentsTitle => 'Trip Documents';

  @override
  String tripDocumentsDemoSubtitle(String trip) {
    return 'Local demo metadata for $trip. No file upload is performed.';
  }

  @override
  String get tripDocumentsRealEmptyTitle =>
      'Trip documents are not connected yet';

  @override
  String get tripDocumentsRealEmptyMessage =>
      'Real trip documents will appear after backend integration. No seeded demo documents are shown for real sessions.';

  @override
  String get tripDocumentsEmptyTitle => 'No documents';

  @override
  String get tripDocumentsEmptyMessage =>
      'Add local demo metadata for tickets, bookings, receipts, or documents.';

  @override
  String get tripDocumentsTripDeletedMessage =>
      'This trip is no longer available.';

  @override
  String get tripDocumentAddAction => 'Add document';

  @override
  String get tripDocumentCreateTitle => 'Add trip document';

  @override
  String get tripDocumentEditTitle => 'Edit trip document';

  @override
  String get tripDocumentTitleLabel => 'Document title';

  @override
  String get tripDocumentNotesLabel => 'Notes';

  @override
  String get tripDocumentTypeLabel => 'Document type';

  @override
  String get tripDocumentMediaLabel => 'Media label';

  @override
  String get tripDocumentMediaUrlLabel => 'Safe URL reference';

  @override
  String get tripDocumentMediaHelper =>
      'Only http or https references with a host are accepted. UI-8 does not upload files.';

  @override
  String get tripDocumentUploaderLabel => 'Uploader';

  @override
  String get tripDocumentNoUploadNotice =>
      'This phase stores local demo metadata only. It does not upload files, parse PDFs, scan images, or share documents.';

  @override
  String get tripDocumentPinned => 'Pinned';

  @override
  String get tripDocumentUnpinned => 'Not pinned';

  @override
  String get tripDocumentPinAction => 'Pin';

  @override
  String get tripDocumentUnpinAction => 'Unpin';

  @override
  String get tripDocumentDeleteAction => 'Delete document';

  @override
  String get tripDocumentSaveToWalletAction => 'Save to wallet';

  @override
  String get tripDocumentUnsafeUrlMessage =>
      'Use a valid http or https URL with a host.';

  @override
  String get tripDocumentSafeLinkLabel => 'Safe link';

  @override
  String get tripDocumentSavedMessage => 'Trip document saved locally.';

  @override
  String get tripDocumentDeletedMessage => 'Trip document deleted locally.';

  @override
  String get tripDocumentWalletImportedMessage =>
      'Trip document saved to the local demo wallet.';

  @override
  String get tripDocumentWalletDuplicateMessage =>
      'That trip document is already in the local demo wallet.';

  @override
  String get tripDocumentDeleteConfirmTitle => 'Delete trip document?';

  @override
  String tripDocumentDeleteConfirmMessage(String title) {
    return 'Delete $title from this local demo trip? Linked wallet items will be removed, but the trip remains unchanged.';
  }

  @override
  String tripDocumentCardSemantic(String title) {
    return 'Trip document $title';
  }

  @override
  String get docTypeFlightTicket => 'Flight ticket';

  @override
  String get docTypeHotelBooking => 'Hotel booking';

  @override
  String get docTypeTrainTicket => 'Train ticket';

  @override
  String get docTypeBusTicket => 'Bus ticket';

  @override
  String get docTypePassport => 'Passport';

  @override
  String get docTypeVisa => 'Visa';

  @override
  String get docTypeInsurance => 'Insurance';

  @override
  String get docTypeTour => 'Tour';

  @override
  String get docTypeReceipt => 'Receipt';

  @override
  String get docTypePdf => 'PDF';

  @override
  String get docTypeImage => 'Image';

  @override
  String get docTypeOther => 'Other';

  @override
  String get tripCompanionAction => 'Trip companion';

  @override
  String get tripCompanionTitle => 'Trip Companion';

  @override
  String tripCompanionSubtitle(String trip) {
    return 'Local demo tools for $trip: sharing, notes, packing, reminders, and documents.';
  }

  @override
  String get tripCompanionRealEmptyTitle =>
      'Trip companion is not connected yet';

  @override
  String get tripCompanionRealEmptyMessage =>
      'Real collaboration, notes, packing, and reminders will appear after backend integration. No seeded demo data is shown for real sessions.';

  @override
  String tripCompanionPermissionLabel(String role) {
    return 'Access: $role';
  }

  @override
  String get tripCompanionReadOnlyNotice =>
      'This trip is read-only for your current local role.';

  @override
  String get tripCompanionNoAccessRole => 'No access';

  @override
  String get tripCompanionCountCollaborators => 'Collaborators';

  @override
  String get tripCompanionCountNotes => 'Notes';

  @override
  String get tripCompanionCountPacking => 'To pack';

  @override
  String get tripCompanionCountReminders => 'Pending reminders';

  @override
  String get tripCompanionCountDocuments => 'Documents';

  @override
  String get tripCompanionCollaborationTitle => 'Collaboration';

  @override
  String get tripCompanionCollaborationSubtitle =>
      'Manage local demo collaborators, roles, and trip privacy.';

  @override
  String get tripCompanionNotesTitle => 'Notes & Journal';

  @override
  String get tripCompanionNotesSubtitle =>
      'Capture pinned notes, ideas, memories, and journal entries.';

  @override
  String get tripCompanionPackingTitle => 'Packing Checklist';

  @override
  String get tripCompanionPackingSubtitle =>
      'Track what is packed, assigned, and still pending.';

  @override
  String get tripCompanionRemindersTitle => 'Reminders';

  @override
  String get tripCompanionRemindersSubtitle =>
      'Manage in-app reminder records without delivery scheduling.';

  @override
  String get tripCompanionDocumentsSubtitle =>
      'Open the existing trip document metadata screen.';

  @override
  String tripCompanionOpenSemantic(String module) {
    return 'Open $module';
  }

  @override
  String get sharedWithMeTitle => 'Shared with me';

  @override
  String get sharedWithMeSubtitle =>
      'Active local demo trips shared by another owner.';

  @override
  String get sharedWithMeRealEmptyTitle => 'Shared trips are not connected yet';

  @override
  String get sharedWithMeRealEmptyMessage =>
      'Real shared trips will appear after backend integration. No demo shared trips are shown for real sessions.';

  @override
  String get sharedWithMeEmptyTitle => 'No shared trips';

  @override
  String get sharedWithMeEmptyMessage =>
      'Trips shared with you will appear here in Demo Mode.';

  @override
  String get sharedWithMeSummaryReadOnlyNotice =>
      'This summary is local demo presentation only. Full shared-trip tools will open when the backend provides the complete trip record.';

  @override
  String sharedWithMeOwnerLabel(String owner) {
    return 'Owner: $owner';
  }

  @override
  String sharedWithMeRoleLabel(String role) {
    return 'Role: $role';
  }

  @override
  String sharedWithMeCount(int count) {
    return '$count shared trips';
  }

  @override
  String get collaborationPrivacyPrivate => 'Private local demo trip';

  @override
  String get collaborationPrivacyPublic => 'Public local demo visibility';

  @override
  String get collaborationPrivacyNotice =>
      'Only the owner can manage collaborators and public/private state. Demo visibility does not publish a real share link.';

  @override
  String get collaborationInviteTitle => 'Invite collaborator';

  @override
  String get collaborationInviteEmailLabel => 'Demo user email';

  @override
  String get collaborationInviteAction => 'Invite';

  @override
  String get collaborationRoleViewer => 'Viewer';

  @override
  String get collaborationRoleEditor => 'Editor';

  @override
  String get collaborationOwnerRole => 'Owner';

  @override
  String get collaborationActiveLabel => 'Active';

  @override
  String get collaborationInactiveLabel => 'Inactive';

  @override
  String get collaborationChangeRoleAction => 'Role';

  @override
  String get collaborationRemoveAction => 'Remove';

  @override
  String get collaborationRemoveConfirmTitle => 'Remove collaborator?';

  @override
  String collaborationRemoveConfirmMessage(String name) {
    return 'Remove $name from this local demo trip? Their authored notes stay as history.';
  }

  @override
  String get collaborationPublicToggleLabel => 'Public demo visibility';

  @override
  String get collaborationNoShareUrlNotice =>
      'No public URL, QR code, or external share delivery is created in this UI phase.';

  @override
  String get tripToolSavedMessage => 'Trip companion changes saved locally.';

  @override
  String get tripToolUnavailableMessage =>
      'Trip companion actions are not connected for real accounts in this UI phase.';

  @override
  String get tripToolForbiddenMessage =>
      'Your current role cannot perform this action.';

  @override
  String get tripToolBlankMessage => 'Required text cannot be empty.';

  @override
  String get tripToolInvalidEmailMessage => 'Enter a valid email address.';

  @override
  String get tripToolDuplicateMessage => 'That local record already exists.';

  @override
  String get tripToolRejectedMessage =>
      'That action cannot be completed with the current trip data.';

  @override
  String get tripToolUnsafeUrlMessage =>
      'Use a valid http or https URL with a host and no credentials.';

  @override
  String get tripToolNotFoundMessage =>
      'The selected record is no longer available.';

  @override
  String get tripToolInvalidQuantityMessage =>
      'Quantity must be an integer of at least 1.';

  @override
  String get tripToolInvalidReorderMessage =>
      'Packing reorder must contain each current item exactly once.';

  @override
  String get tripToolInvalidDateMessage => 'Use a valid local date and time.';

  @override
  String get notesSearchHint => 'Search notes, authors, or journal text';

  @override
  String get notesAddAction => 'Add note';

  @override
  String get notesEditAction => 'Edit note';

  @override
  String get notesContentLabel => 'Content';

  @override
  String get notesTitleLabel => 'Title';

  @override
  String get notesTypeLabel => 'Note type';

  @override
  String get notesMoodLabel => 'Mood';

  @override
  String get notesPhotoUrlLabel => 'Safe photo URL';

  @override
  String get notesPhotoMetadataLabel => 'Photo URL metadata';

  @override
  String get notesLinkedDayLabel => 'Linked day';

  @override
  String get notesLinkedItemLabel => 'Linked activity';

  @override
  String get notesEmptyTitle => 'No notes match';

  @override
  String get notesEmptyMessage =>
      'Add a local demo note or adjust search and filters.';

  @override
  String get notesPinAction => 'Pin';

  @override
  String get notesUnpinAction => 'Unpin';

  @override
  String get notesDeleteAction => 'Delete note';

  @override
  String get notesDeleteConfirmTitle => 'Delete note?';

  @override
  String notesDeleteConfirmMessage(String title) {
    return 'Delete $title from the local demo journal?';
  }

  @override
  String get noteTypeNote => 'Note';

  @override
  String get noteTypeJournal => 'Journal';

  @override
  String get noteTypeReminder => 'Reminder note';

  @override
  String get noteTypeIdea => 'Idea';

  @override
  String get noteTypeMemory => 'Memory';

  @override
  String get moodHappy => 'Happy';

  @override
  String get moodExcited => 'Excited';

  @override
  String get moodCalm => 'Calm';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodStressed => 'Stressed';

  @override
  String get moodNeutral => 'Neutral';

  @override
  String get packingSearchHint => 'Search packing items, notes, or assignees';

  @override
  String get packingAddAction => 'Add packing item';

  @override
  String get packingEditAction => 'Edit item';

  @override
  String get packingLabelField => 'Item label';

  @override
  String get packingQuantityField => 'Quantity';

  @override
  String get packingCategoryLabel => 'Packing category';

  @override
  String get packingAssigneeLabel => 'Assigned to';

  @override
  String get packingNotesField => 'Notes';

  @override
  String get packingEmptyTitle => 'No packing items match';

  @override
  String get packingEmptyMessage =>
      'Add local demo packing items or adjust filters.';

  @override
  String packingProgressValue(int checked, int total, int percent) {
    return '$checked of $total packed ($percent%)';
  }

  @override
  String packingUncheckedCount(int count) {
    return '$count still unpacked';
  }

  @override
  String get packingDeleteAction => 'Delete item';

  @override
  String get packingDeleteConfirmTitle => 'Delete packing item?';

  @override
  String packingDeleteConfirmMessage(String label) {
    return 'Delete $label from this local demo checklist?';
  }

  @override
  String get packingMoveUpAction => 'Move up';

  @override
  String get packingMoveDownAction => 'Move down';

  @override
  String get packingUnassignedLabel => 'Unassigned';

  @override
  String get packingCategoryDocuments => 'Documents';

  @override
  String get packingCategoryClothes => 'Clothes';

  @override
  String get packingCategoryToiletries => 'Toiletries';

  @override
  String get packingCategoryElectronics => 'Electronics';

  @override
  String get packingCategoryMedicine => 'Medicine';

  @override
  String get packingCategoryMoney => 'Money';

  @override
  String get packingCategoryFood => 'Food';

  @override
  String get packingCategoryBaby => 'Baby';

  @override
  String get packingCategoryPet => 'Pet';

  @override
  String get packingCategoryOther => 'Other';

  @override
  String get remindersIncludeCancelled => 'Include cancelled';

  @override
  String get remindersAddAction => 'Add reminder';

  @override
  String get remindersEditAction => 'Edit reminder';

  @override
  String get reminderTitleField => 'Reminder title';

  @override
  String get reminderMessageField => 'Message';

  @override
  String get reminderAtField => 'Local date and time';

  @override
  String get reminderTypeLabel => 'Reminder type';

  @override
  String get reminderStatusPending => 'Pending';

  @override
  String get reminderStatusCompleted => 'Completed';

  @override
  String get reminderStatusCancelled => 'Cancelled';

  @override
  String get reminderOverdue => 'Overdue';

  @override
  String get reminderEmptyTitle => 'No reminders match';

  @override
  String get reminderEmptyMessage =>
      'Add local in-app reminder records or include cancelled items.';

  @override
  String get reminderCompleteAction => 'Complete';

  @override
  String get reminderCancelAction => 'Cancel reminder';

  @override
  String get reminderDeleteAction => 'Delete reminder';

  @override
  String get reminderDeleteConfirmTitle => 'Delete reminder?';

  @override
  String reminderDeleteConfirmMessage(String title) {
    return 'Delete $title from this local demo trip?';
  }

  @override
  String get reminderTypeCustom => 'Custom';

  @override
  String get reminderTypeDocument => 'Document';

  @override
  String get reminderTypeCheckIn => 'Check-in';

  @override
  String get reminderTypeFlight => 'Flight';

  @override
  String get reminderTypeActivity => 'Activity';

  @override
  String get reminderTypePayment => 'Payment';

  @override
  String get reminderTypePacking => 'Packing';

  @override
  String get reminderTypeOther => 'Other';

  @override
  String get reminderLocalTimeHelper =>
      'Format: yyyy-MM-dd HH:mm. Stored as UTC for future API mapping.';

  @override
  String get reminderNoDeliveryNotice =>
      'These are in-app reminder records only. UI-9 does not schedule push, email, SMS, or OS notifications.';

  @override
  String get reviewsTitle => 'Reviews';

  @override
  String get reviewsSubtitle =>
      'Browse local demo review summaries shaped by the committed customer review contract.';

  @override
  String get reviewsRealUnavailableTitle => 'Reviews are not connected yet';

  @override
  String get reviewsRealUnavailableMessage =>
      'Review APIs are not wired in this UI phase. No local review data is shown for real sessions.';

  @override
  String get reviewSummaryTitle => 'Traveler trust';

  @override
  String reviewSummarySemantic(String place) {
    return 'Review summary for $place';
  }

  @override
  String get reviewPublicVisibilityNotice =>
      'Public lists use approved, sanitized review summaries only.';

  @override
  String get reviewNoReviewsTitle => 'No approved reviews yet';

  @override
  String get reviewNoReviewsMessage =>
      'Approved local demo reviews will appear here without exposing booking details.';

  @override
  String get reviewSeeAllAction => 'See all reviews';

  @override
  String get reviewWriteAction => 'Write review';

  @override
  String reviewWriteSemantic(String place) {
    return 'Write a review for $place';
  }

  @override
  String reviewAggregateAverage(String average) {
    return '$average average';
  }

  @override
  String reviewRatingSemantic(String rating) {
    return 'Average rating $rating out of 5';
  }

  @override
  String reviewRatingOutOfFive(int rating) {
    return '$rating out of 5';
  }

  @override
  String reviewCountExact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count approved reviews',
      one: '1 approved review',
    );
    return '$_temp0';
  }

  @override
  String reviewVerifiedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verified stays',
      one: '1 verified stay',
    );
    return '$_temp0';
  }

  @override
  String get reviewDistributionSemantic => 'Rating distribution';

  @override
  String reviewStars(int rating) {
    return 'Rating $rating';
  }

  @override
  String reviewCategoryAverage(String category, String average) {
    return '$category: $average';
  }

  @override
  String get reviewCategoryCleanliness => 'Cleanliness';

  @override
  String get reviewCategoryService => 'Service';

  @override
  String get reviewCategoryLocation => 'Location';

  @override
  String get reviewCategoryValue => 'Value';

  @override
  String get reviewCategoryFacilities => 'Facilities';

  @override
  String get reviewFiltersTitle => 'Review controls';

  @override
  String get reviewSortLabel => 'Sort';

  @override
  String get reviewSortNewest => 'Newest';

  @override
  String get reviewSortOldest => 'Oldest';

  @override
  String get reviewSortHighest => 'Highest rating';

  @override
  String get reviewSortLowest => 'Lowest rating';

  @override
  String get reviewSortHelpful => 'Most helpful';

  @override
  String get reviewFilterRating => 'Rating';

  @override
  String get reviewFilterVerifiedOnly => 'Verified stays only';

  @override
  String get reviewFilteredEmptyTitle => 'No reviews match';

  @override
  String get reviewFilteredEmptyMessage =>
      'Adjust the local filters to see approved demo review summaries.';

  @override
  String get reviewDetailTitle => 'Review detail';

  @override
  String get reviewNotFoundTitle => 'Review unavailable';

  @override
  String get reviewNotFoundMessage =>
      'This review is no longer available in local demo state.';

  @override
  String reviewCardSemantic(String place, int rating) {
    return 'Review for $place, $rating out of 5';
  }

  @override
  String get reviewVerifiedStay => 'Verified stay';

  @override
  String get reviewUntitled => 'Untitled review';

  @override
  String reviewAuthorLine(String author) {
    return 'By $author';
  }

  @override
  String get reviewPublicSummaryOnly =>
      'The public backend contract exposes sanitized summaries only. Full review text is shown only in the author\'s review view.';

  @override
  String get reviewUnsupportedActionsNotice =>
      'Customer edit/delete, helpful voting, reporting, media upload/delete, and partner-response mutation are not available in this local user app phase.';

  @override
  String get reviewMediaTitle => 'Review media';

  @override
  String reviewMediaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count media items',
      one: '1 media item',
    );
    return '$_temp0';
  }

  @override
  String reviewMediaCountSemantic(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count review media items',
      one: '1 review media item',
    );
    return '$_temp0';
  }

  @override
  String reviewMoreMediaCount(int count) {
    return '+$count more';
  }

  @override
  String reviewMediaGallerySemantic(int count) {
    return 'Review media gallery with $count items';
  }

  @override
  String reviewMediaItemSemantic(
      int index, int total, String type, String description) {
    return 'Review media $index of $total, $type, $description';
  }

  @override
  String reviewMediaIndex(int index, int total) {
    return '$index of $total';
  }

  @override
  String get reviewMediaTypePhoto => 'Photo';

  @override
  String get reviewMediaTypeVideo => 'Video';

  @override
  String get reviewMediaTypeDocument => 'Document';

  @override
  String get reviewCoverMedia => 'Cover image';

  @override
  String get reviewMediaUnavailable => 'Media unavailable';

  @override
  String get reviewImageUnavailable => 'Image unavailable';

  @override
  String get reviewVideoPreviewUnavailable => 'Video preview unavailable';

  @override
  String get reviewUnsupportedMedia => 'Unsupported media';

  @override
  String get reviewPartnerResponseTitle => 'Response from the property';

  @override
  String get reviewPropertyResponseIndicator => 'Property response';

  @override
  String reviewPartnerResponseSemantic(String review) {
    return 'Property response for $review';
  }

  @override
  String reviewRespondedOn(String date) {
    return 'Responded on $date';
  }

  @override
  String get reviewMediaAttachmentTitle => 'Review media';

  @override
  String get reviewMediaAttachmentUnavailable =>
      'Photo and video attachments will be available when the review media API is connected.';

  @override
  String get reviewUploadRequiresBackend =>
      'This local demo submits text-only reviews; it does not upload files or accept typed media URLs.';

  @override
  String get reviewDetailMetadataTitle => 'Review metadata';

  @override
  String get reviewLinkedBookingLabel => 'Linked booking';

  @override
  String get reviewCreatedAtLabel => 'Submitted';

  @override
  String get reviewApprovedAtLabel => 'Approved';

  @override
  String get reviewRejectedAtLabel => 'Rejected';

  @override
  String get reviewRejectReasonLabel => 'Safe rejection reason';

  @override
  String get reviewHelpfulCountLabel => 'Helpful count';

  @override
  String get reviewReportedCountLabel => 'Reported count';

  @override
  String get reviewWriteTitle => 'Write a review';

  @override
  String get reviewIneligibleTitle => 'Review not available';

  @override
  String get reviewBackendCreateNotice =>
      'A local demo review maps to the booking-scoped customer review route and starts as Pending. It is not sent to the backend.';

  @override
  String get reviewOverallRatingLabel => 'Overall rating';

  @override
  String get reviewTitleLabel => 'Title';

  @override
  String get reviewTitleHelper => 'Optional. Maximum 200 characters.';

  @override
  String get reviewContentLabel => 'Review text';

  @override
  String get reviewContentHelper => 'Optional. Maximum 5000 characters.';

  @override
  String get reviewCategoryRatingsTitle => 'Optional category ratings';

  @override
  String get reviewCategorySkipped => 'Not rated';

  @override
  String get reviewSubmitAction => 'Submit local demo review';

  @override
  String get reviewSubmittedMessage =>
      'Local demo review submitted as Pending.';

  @override
  String get reviewUnavailableMessage =>
      'Review integration is not enabled for real sessions in this UI phase.';

  @override
  String get reviewIneligibleCompletedOnly =>
      'Only completed local demo bookings owned by you can be reviewed.';

  @override
  String get reviewDuplicateMessage =>
      'A review already exists for this booking.';

  @override
  String get reviewInvalidRatingMessage => 'Ratings must be between 1 and 5.';

  @override
  String get reviewTitleTooLongMessage =>
      'Review title must be 200 characters or fewer.';

  @override
  String get reviewContentTooLongMessage =>
      'Review text must be 5000 characters or fewer.';

  @override
  String get myReviewsTitle => 'My Reviews';

  @override
  String get myReviewsSubtitle =>
      'Your local demo review history. Statuses mirror the committed backend review statuses.';

  @override
  String get myReviewsRealEmptyTitle => 'My Reviews is not connected yet';

  @override
  String get myReviewsRealEmptyMessage =>
      'Real sessions do not show seeded review history until the customer review API is wired.';

  @override
  String get myReviewsEmptyTitle => 'No local reviews yet';

  @override
  String get myReviewsEmptyMessage =>
      'Completed demo bookings can create one local pending review each.';

  @override
  String reviewSectionHeader(String title, int count) {
    return '$title ($count)';
  }

  @override
  String get reviewStatusPending => 'Pending';

  @override
  String get reviewStatusApproved => 'Approved';

  @override
  String get reviewStatusRejected => 'Rejected';

  @override
  String get reviewStatusHidden => 'Hidden';

  @override
  String get reviewStatusReported => 'Reported';

  @override
  String wishlistBookmarkAddedMessage(String place) {
    return 'Saved $place to your wishlist.';
  }

  @override
  String wishlistBookmarkRemovedMessage(String place) {
    return 'Removed $place from your wishlist.';
  }

  @override
  String wishlistBookmarkNotPublishedMessage(String place) {
    return '$place isn\'t published yet, so it can\'t be saved.';
  }

  @override
  String get wishlistBookmarkNetworkMessage =>
      'Couldn\'t reach the server. Check your connection and try again.';

  @override
  String get wishlistBookmarkServerErrorMessage =>
      'Something went wrong on our end. Please try again.';

  @override
  String get wishlistBookmarkUnavailableMessage =>
      'Saving isn\'t available right now.';

  @override
  String wishlistBookmarkSavingSemantic(String place) {
    return 'Updating saved state for $place';
  }

  @override
  String get wishlistRealLoadingTitle => 'Loading your wishlist';

  @override
  String get wishlistRealLoadingMessage => 'Fetching your saved places…';

  @override
  String get wishlistRealEmptyTitle => 'Your wishlist is empty';

  @override
  String get wishlistRealEmptyMessage =>
      'Tap the bookmark on any place to save it here.';

  @override
  String get wishlistRealErrorMessage =>
      'We couldn\'t load your wishlist. Please try again.';

  @override
  String get wishlistRealPartialDetailsNote =>
      'Limited details are available for this saved place.';

  @override
  String placeHydrationLoadingSemantic(String place) {
    return 'Loading details for $place';
  }

  @override
  String get placeHydrationUnavailableMessage =>
      'This place is no longer available.';

  @override
  String get placeHydrationErrorMessage =>
      'Couldn\'t load place details. Please try again.';

  @override
  String get tripsRealLoadingMessage => 'Loading your trips…';

  @override
  String get tripsRealErrorMessage =>
      'We couldn\'t load your trips. Please try again.';

  @override
  String get tripsRealEmptyMessage =>
      'You haven\'t created any trips yet. Start planning your next adventure.';

  @override
  String get tripsRealSessionExpiredTitle => 'Session expired';

  @override
  String get tripsRealSessionExpiredMessage =>
      'Please sign in again to see your trips.';

  @override
  String get tripsRealSignInAction => 'Sign in';

  @override
  String get tripRealPermissionDeniedMessage =>
      'You don\'t have permission to do that.';

  @override
  String get tripStatusPlanning => 'Planning';

  @override
  String get tripStatusActive => 'Active';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get tripStatusCancelled => 'Cancelled';

  @override
  String get tripStatusUnknown => 'Trip';

  @override
  String tripDayLabel(int day) {
    return 'Day $day';
  }

  @override
  String get tripDetailRealTitle => 'Trip';

  @override
  String get tripDetailRealLoadingMessage => 'Loading trip details…';

  @override
  String get tripDetailRealUnavailableTitle => 'Trip unavailable';

  @override
  String get tripDetailRealUnavailableMessage =>
      'This trip is no longer available.';

  @override
  String get tripDetailRealErrorMessage =>
      'We couldn\'t load this trip. Please try again.';

  @override
  String get tripDetailRealEditDisabledNote =>
      'Editing this itinerary isn\'t available yet.';

  @override
  String get tripDetailRealNoDaysMessage =>
      'This trip doesn\'t have any days yet.';

  @override
  String get tripDetailRealNoItemsMessage =>
      'No activities planned for this day yet.';

  @override
  String get addToTripRealLoadingTrips => 'Loading your trips…';

  @override
  String get addToTripRealNoTripsMessage =>
      'You don\'t have any trips yet. Create one to start adding places.';

  @override
  String get addToTripRealSelectTripLabel => 'Choose a trip';

  @override
  String get addToTripRealSelectDayLabel => 'Choose a day';

  @override
  String addToTripRealNewDayOption(int day) {
    return 'New day (Day $day)';
  }

  @override
  String get addToTripRealPlanningNote =>
      'This adds the place to your trip plan. It isn\'t a booking.';

  @override
  String get addToTripRealAddingMessage => 'Adding to your trip…';

  @override
  String addToTripRealAddedMessage(String place) {
    return '$place was added to your trip.';
  }

  @override
  String get addToTripRealErrorMessage =>
      'We couldn\'t add this place. Please try again.';

  @override
  String get addToTripRealUnpublishedMessage =>
      'This place can\'t be added to a trip right now.';

  @override
  String get addToTripRealTripUnavailableMessage =>
      'That trip or place is no longer available.';

  @override
  String get createTripRealErrorMessage =>
      'We couldn\'t create your trip. Please try again.';

  @override
  String get searchRealLoadingMessage => 'Searching places…';

  @override
  String get searchRealErrorMessage =>
      'We couldn\'t load places. Please try again.';

  @override
  String get searchRealNoResultsMessage =>
      'No places match your search. Try different keywords or filters.';

  @override
  String get searchRealEndOfResults =>
      'You\'ve reached the end of the results.';

  @override
  String get searchRealSortLabel => 'Sort by';

  @override
  String get searchRealRatingLabel => 'Minimum rating';

  @override
  String get searchRealPriceLabel => 'Maximum price';

  @override
  String get searchRealSortNewest => 'Newest';

  @override
  String get searchRealSortTopRated => 'Top rated';

  @override
  String get searchRealSortPriceLow => 'Price: low to high';

  @override
  String get searchRealSortPriceHigh => 'Price: high to low';

  @override
  String get searchRealSortName => 'Name A–Z';

  @override
  String get searchRealRatingAny => 'Any';

  @override
  String get searchRealRating3plus => '3.0+';

  @override
  String get searchRealRating4plus => '4.0+';

  @override
  String get searchRealRating45plus => '4.5+';

  @override
  String get searchRealPriceAny => 'Any';

  @override
  String get availabilityRealLoadingMessage => 'Checking real availability…';

  @override
  String get availabilityRealErrorMessage =>
      'We couldn\'t load availability. Please try again.';

  @override
  String get availabilityRealInvalidDatesMessage =>
      'Choose a check-out date after check-in to see rooms.';

  @override
  String availabilityRealRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rooms available',
      one: '1 room available',
    );
    return '$_temp0';
  }

  @override
  String availabilityRealPerNight(String price) {
    return '$price / night';
  }

  @override
  String availabilityRealOriginalPrice(String price) {
    return '$price';
  }

  @override
  String availabilityRealTotalForNights(String price, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return '$price total · $_temp0';
  }

  @override
  String get availabilityRealFreeCancellation => 'Free cancellation';

  @override
  String get availabilityRealInstantConfirmation => 'Instant confirmation';

  @override
  String get placeDetailRealLoadingMessage => 'Loading place details…';

  @override
  String get placeDetailRealErrorMessage =>
      'We couldn\'t load this place. Please try again.';

  @override
  String get placeDetailRealNotFoundMessage =>
      'This place is no longer available.';

  @override
  String placeGallerySemantic(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images',
      one: '1 image',
    );
    return 'Photo gallery for $name, $_temp0';
  }

  @override
  String get placeGalleryClose => 'Close photo';

  @override
  String get placeOpenNow => 'Open now';

  @override
  String get placeClosedNow => 'Closed now';

  @override
  String get placeOpeningHoursTitle => 'Opening hours';

  @override
  String get placeOpeningHoursClosed => 'Closed';

  @override
  String get placeCoordinatesTitle => 'Location';

  @override
  String placeCoordinatesValue(String lat, String long) {
    return '$lat, $long';
  }

  @override
  String get placeAmenitiesTitle => 'Amenities';

  @override
  String get placeMetadataTitle => 'Good to know';

  @override
  String get metadataVisitDurationTitle => 'Suggested visit';

  @override
  String get metadataTravelStylesTitle => 'Travel styles';

  @override
  String get metadataBestSeasonsTitle => 'Best seasons';

  @override
  String get metadataBestVisitTimesTitle => 'Best time of day';

  @override
  String get metadataWeatherTitle => 'Weather';

  @override
  String get metadataBudgetTitle => 'Budget';

  @override
  String get metadataDifficultyTitle => 'Difficulty';

  @override
  String get metadataAccessibilityTitle => 'Accessibility';

  @override
  String get metadataCrowdTitle => 'Crowd level';

  @override
  String get metadataHighlightsTitle => 'Highlights';

  @override
  String get metadataNotesTitle => 'Notes';

  @override
  String get travelStyleSolo => 'Solo';

  @override
  String get travelStyleCouple => 'Couple';

  @override
  String get travelStyleFamily => 'Family';

  @override
  String get travelStyleFriends => 'Friends';

  @override
  String get travelStyleBusiness => 'Business';

  @override
  String get travelStyleBackpacker => 'Backpacker';

  @override
  String get travelStyleLuxury => 'Luxury';

  @override
  String get bestVisitTimeEarlyMorning => 'Early morning';

  @override
  String get bestVisitTimeMorning => 'Morning';

  @override
  String get bestVisitTimeAfternoon => 'Afternoon';

  @override
  String get bestVisitTimeSunset => 'Sunset';

  @override
  String get bestVisitTimeEvening => 'Evening';

  @override
  String get bestVisitTimeNight => 'Night';

  @override
  String get bestSeasonSpring => 'Spring';

  @override
  String get bestSeasonSummer => 'Summer';

  @override
  String get bestSeasonAutumn => 'Autumn';

  @override
  String get bestSeasonWinter => 'Winter';

  @override
  String get bestSeasonAllYear => 'All year';

  @override
  String get weatherSunny => 'Sunny';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String get weatherRainy => 'Rainy';

  @override
  String get weatherCool => 'Cool';

  @override
  String get weatherAny => 'Any weather';

  @override
  String get budgetFree => 'Free';

  @override
  String get budgetLow => 'Low budget';

  @override
  String get budgetMedium => 'Mid-range';

  @override
  String get budgetHigh => 'High-end';

  @override
  String get budgetLuxury => 'Luxury';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyModerate => 'Moderate';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get accessibilityLow => 'Limited access';

  @override
  String get accessibilityMedium => 'Moderate access';

  @override
  String get accessibilityHigh => 'Fully accessible';

  @override
  String get crowdLow => 'Quiet';

  @override
  String get crowdMedium => 'Moderate crowd';

  @override
  String get crowdHigh => 'Busy';

  @override
  String get flagRomantic => 'Romantic';

  @override
  String get flagFamilyFriendly => 'Family-friendly';

  @override
  String get flagKidFriendly => 'Kid-friendly';

  @override
  String get flagPetFriendly => 'Pet-friendly';

  @override
  String get flagWheelchairFriendly => 'Wheelchair-friendly';

  @override
  String get flagPhotographySpot => 'Photography spot';

  @override
  String get flagSunsetSpot => 'Sunset spot';

  @override
  String get flagSunriseSpot => 'Sunrise spot';

  @override
  String get flagIndoor => 'Indoor';

  @override
  String get flagOutdoor => 'Outdoor';

  @override
  String get flagRainyDaySuitable => 'Rainy-day friendly';

  @override
  String get facilityGroupGeneral => 'General';

  @override
  String get facilityGroupWellness => 'Wellness';

  @override
  String get facilityGroupBusiness => 'Business';

  @override
  String get facilityGroupFood => 'Food & drink';

  @override
  String get facilityGroupOutdoor => 'Outdoor';

  @override
  String get facilityGroupFamily => 'Family';

  @override
  String get facilityGroupAccessibility => 'Accessibility';

  @override
  String get hotelPoliciesTitle => 'Policies';

  @override
  String get hotelPolicyCancellation => 'Cancellation';

  @override
  String get hotelPolicyPayment => 'Payment';

  @override
  String get hotelPolicyChildren => 'Children';

  @override
  String get hotelPolicyPet => 'Pets';

  @override
  String get hotelPolicySmoking => 'Smoking';

  @override
  String get hotelParkingFree => 'Free parking';

  @override
  String get hotelParkingPaid => 'Paid parking';

  @override
  String get hotelParkingUnavailable => 'No parking';

  @override
  String get hotelWifiFree => 'Free Wi-Fi';

  @override
  String get hotelWifiPaid => 'Paid Wi-Fi';

  @override
  String get hotelWifiUnavailable => 'No Wi-Fi';

  @override
  String hotelServiceUnavailable(String service) {
    return '$service (unavailable)';
  }

  @override
  String get roomSelectAction => 'Select this room';

  @override
  String roomSelectSemantic(String name) {
    return 'Select $name';
  }

  @override
  String get roomSelectedBadge => 'Selected';

  @override
  String roomDetailImageSemantic(String name) {
    return 'Photos of $name';
  }

  @override
  String roomCodeLabel(String code) {
    return 'Room code $code';
  }

  @override
  String roomBedConfig(int count, String bed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count $bed',
      one: '1 $bed',
    );
    return '$_temp0';
  }

  @override
  String get roomOccupancyTitle => 'Occupancy';

  @override
  String roomOccupancyAdults(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count adults',
      one: '1 adult',
    );
    return '$_temp0';
  }

  @override
  String roomOccupancyChildren(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count children',
      one: '1 child',
    );
    return '$_temp0';
  }

  @override
  String get roomPriceTitle => 'Price';

  @override
  String hotelRoomCardSelectedSemantic(String name) {
    return '$name, selected';
  }

  @override
  String get roomRatePlansTitle => 'Rate plans';

  @override
  String get roomRatePlansLoadingMessage => 'Loading rate plans…';

  @override
  String get roomRatePlansErrorMessage =>
      'We couldn\'t load rate plans. Please try again.';

  @override
  String get roomRatePlansInvalidDatesMessage =>
      'Choose a check-out date after check-in to see rate plans.';

  @override
  String get roomRatePlansEmptyTitle => 'No rate plans';

  @override
  String get roomRatePlansEmptyMessage =>
      'This room has no sellable rate plans for the selected stay.';

  @override
  String roomRatePlanSemantic(String name) {
    return 'Rate plan $name';
  }

  @override
  String roomRatePlanSelectedSemantic(String name) {
    return 'Rate plan $name, selected';
  }

  @override
  String get roomRatePlanIneligible => 'Not available for the selected stay.';

  @override
  String get ratePlanRefundable => 'Refundable';

  @override
  String get ratePlanNonRefundable => 'Non-refundable';

  @override
  String ratePlanFinalNightly(String price) {
    return '$price / night';
  }

  @override
  String ratePlanBaseNightly(String price) {
    return 'Base $price / night';
  }

  @override
  String ratePlanStaySubtotal(String price, int nights) {
    String _temp0 = intl.Intl.pluralLogic(
      nights,
      locale: localeName,
      other: '$nights nights',
      one: '1 night',
    );
    return '$price for $_temp0';
  }

  @override
  String get bookingCreateAction => 'Create booking';

  @override
  String get bookingCreateSemantic => 'Create your booking';

  @override
  String get bookingCreatingLabel => 'Creating your booking…';

  @override
  String get bookingResultTitle => 'Your booking';

  @override
  String get bookingResultCodeLabel => 'Booking code';

  @override
  String get bookingResultStatusLabel => 'Status';

  @override
  String get bookingResultDoneAction => 'Done';

  @override
  String get bookingResultBaseLabel => 'Room price';

  @override
  String get bookingResultPaymentNextNote =>
      'Your booking is created. Payment is the next step and isn\'t available in the app yet — the property will follow up, or you can pay once payment is enabled.';

  @override
  String get bookingPriceChangedNote =>
      'The final price confirmed by the server differs from the earlier quote. The amount shown above is the one that applies to your booking.';

  @override
  String get bookingStatusPendingLabel => 'Pending';

  @override
  String get bookingStatusConfirmedLabel => 'Confirmed';

  @override
  String get bookingStatusUnknownLabel => 'Unknown';

  @override
  String get bookingStatusPendingHeadline => 'Booking pending';

  @override
  String get bookingStatusPendingBody =>
      'We\'ve created your booking and are holding the room. It stays pending until payment and property confirmation — it is not yet a confirmed stay.';

  @override
  String get bookingStatusConfirmedHeadline => 'Booking confirmed';

  @override
  String get bookingStatusConfirmedBody =>
      'Your booking has been confirmed by the property.';

  @override
  String bookingStatusGenericHeadline(String status) {
    return 'Booking status: $status';
  }

  @override
  String get bookingSubmitValidationMessage =>
      'Some booking details couldn\'t be accepted. Please review your dates and guests and try again.';

  @override
  String get bookingSubmitForbiddenMessage =>
      'You don\'t have permission to create this booking.';

  @override
  String get bookingSubmitRoomUnavailableMessage =>
      'This room or rate plan is no longer available. Please go back and choose again.';

  @override
  String get bookingSubmitConflictMessage =>
      'This room was just taken for your dates. Please go back and try another room or dates.';

  @override
  String get bookingSubmitUnprocessableMessage =>
      'This room can\'t be booked for the selected dates. Please go back and adjust your stay.';

  @override
  String get bookingSubmitServerErrorMessage =>
      'Something went wrong creating your booking. No booking was created — please try again.';

  @override
  String get bookingSubmitNetworkMessage =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get bookingSubmitUncertainTitle => 'Booking not confirmed';

  @override
  String get bookingSubmitUncertainBody =>
      'We couldn\'t confirm whether your booking was created. Please don\'t submit again — check your bookings later to see if it went through.';

  @override
  String get bookingSubmitUncertainAcknowledge =>
      'I understand this may create a duplicate booking';
}
