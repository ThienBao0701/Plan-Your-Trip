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
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the email for your account. If it exists, we send a password reset link.';

  @override
  String get forgotPasswordSendAction => 'Send reset link';

  @override
  String get forgotPasswordReturnAction => 'Back to login';

  @override
  String get forgotPasswordInfo =>
      'For your security, the same answer is shown whether or not the address has an account.';

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
      'Your booking is created and held as pending. Complete payment to confirm it.';

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

  @override
  String get bookingsRealLoadingMessage => 'Loading your bookings…';

  @override
  String get bookingsRealErrorMessage =>
      'We couldn\'t load your bookings. Please try again.';

  @override
  String get bookingDetailLoadingMessage => 'Loading booking details…';

  @override
  String get bookingDetailErrorMessage =>
      'We couldn\'t load this booking. Please try again.';

  @override
  String get bookingDetailSpecialRequestLabel => 'Special request';

  @override
  String get bookingHistoryUncertainTitle =>
      'A booking may not have gone through';

  @override
  String get bookingHistoryUncertainBody =>
      'Your last booking couldn\'t be confirmed. Check the list below to see whether it was created before trying again.';

  @override
  String get bookingHistoryUncertainDismiss => 'Dismiss';

  @override
  String get paymentTitle => 'Payment';

  @override
  String get paymentPayNowAction => 'Pay now';

  @override
  String get paymentLoadingMessage => 'Loading payment…';

  @override
  String get paymentErrorMessage =>
      'We couldn\'t load the payment. Please try again.';

  @override
  String get paymentSandboxNotice =>
      'No live payment gateway is connected. The payment is created for real on the backend and settled in a sandbox — no card is charged and no external checkout opens.';

  @override
  String get paymentAmountToPayLabel => 'Amount to pay';

  @override
  String get paymentNoneTitle => 'No payment yet';

  @override
  String get paymentNoneMessage =>
      'Create a payment for this booking to continue.';

  @override
  String get paymentCreateAction => 'Create payment';

  @override
  String get paymentCreatingLabel => 'Creating payment…';

  @override
  String get paymentCodeLabel => 'Payment code';

  @override
  String get paymentMethodLabel => 'Method';

  @override
  String get paymentProcessingLabel => 'Processing…';

  @override
  String get paymentSuccessHeadline => 'Payment successful';

  @override
  String get paymentSuccessBody =>
      'Your payment went through and the booking is now confirmed.';

  @override
  String get paymentPendingHeadline => 'Payment pending';

  @override
  String get paymentPendingBody =>
      'The payment has been created and is awaiting completion.';

  @override
  String get paymentFailedHeadline => 'Payment failed';

  @override
  String get paymentFailedBody =>
      'This payment did not go through. You can start a new payment.';

  @override
  String get paymentCompleteSandboxAction => 'Complete payment (sandbox)';

  @override
  String get paymentFailSandboxAction => 'Simulate failed payment (sandbox)';

  @override
  String get paymentRefreshAction => 'Refresh status';

  @override
  String get paymentRetryNewAction => 'Start a new payment';

  @override
  String get paymentConfirmTitle => 'Complete this payment?';

  @override
  String get paymentConfirmMessage =>
      'This settles the payment on the backend (sandbox) and confirms your booking. No card is charged.';

  @override
  String get paymentConfirmAction => 'Complete payment';

  @override
  String get paymentStatusUnknownLabel => 'Unknown';

  @override
  String get paymentActionValidationMessage =>
      'The payment request was invalid. Please try again.';

  @override
  String get paymentActionForbiddenMessage =>
      'You don\'t have permission to pay for this booking.';

  @override
  String get paymentActionNotPayableMessage =>
      'This booking can\'t be paid right now. It may be cancelled, already paid, or no longer pending.';

  @override
  String get paymentActionConflictMessage =>
      'The payment changed on the server. Refresh and try again.';

  @override
  String get paymentActionServerErrorMessage =>
      'Something went wrong with the payment. Please try again.';

  @override
  String get paymentActionNetworkMessage =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get reviewStatusUnknown => 'Unknown';

  @override
  String get reviewsListLoadingMessage => 'Loading reviews…';

  @override
  String get reviewsListErrorMessage =>
      'We couldn\'t load reviews. Please try again.';

  @override
  String get placeReviewsTitle => 'Reviews';

  @override
  String get placeReviewsEmptyTitle => 'No reviews yet';

  @override
  String get placeReviewsEmptyMessage =>
      'This place has no published reviews yet.';

  @override
  String get reviewsMineTitle => 'My reviews';

  @override
  String get reviewsMineEmptyTitle => 'No reviews yet';

  @override
  String get reviewsMineEmptyMessage =>
      'Reviews you write for completed stays will appear here.';

  @override
  String reviewStarsSemantic(int rating) {
    return '$rating out of 5';
  }

  @override
  String writeReviewRateStarSemantic(int rating) {
    return 'Rate $rating out of 5';
  }

  @override
  String get reviewPartnerReplyTitle => 'Response from the property';

  @override
  String get reviewUnknownPlace => 'Place';

  @override
  String get reviewAnonymousReviewer => 'Guest';

  @override
  String get reviewRatingCleanliness => 'Cleanliness';

  @override
  String get reviewRatingService => 'Service';

  @override
  String get reviewRatingLocation => 'Location';

  @override
  String get reviewRatingValue => 'Value';

  @override
  String get reviewRatingFacilities => 'Facilities';

  @override
  String get writeReviewTitle => 'Write a review';

  @override
  String get writeReviewOverallLabel => 'Overall rating';

  @override
  String get writeReviewSubRatingsTitle => 'Rate the details (optional)';

  @override
  String get writeReviewTitleLabel => 'Title (optional)';

  @override
  String get writeReviewContentLabel => 'Your review (optional)';

  @override
  String get writeReviewSubmitAction => 'Submit review';

  @override
  String get writeReviewSubmittingLabel => 'Submitting review…';

  @override
  String get writeReviewModerationNote =>
      'Your review is submitted for moderation and becomes public once approved.';

  @override
  String get writeReviewPendingHeadline => 'Review submitted';

  @override
  String get writeReviewPendingBody =>
      'Thanks! Your review is pending moderation and will be published once approved.';

  @override
  String get writeReviewOverallRequiredHint =>
      'Tap a star to set your overall rating.';

  @override
  String get bookingDetailSeeReviewsAction => 'See hotel reviews';

  @override
  String get reviewSubmitValidationMessage =>
      'Please check your review and try again.';

  @override
  String get reviewSubmitForbiddenMessage =>
      'You can only review your own booking.';

  @override
  String get reviewSubmitAlreadyMessage =>
      'You\'ve already reviewed this booking.';

  @override
  String get reviewSubmitNotCompletedMessage =>
      'You can review a stay only after it\'s completed.';

  @override
  String get reviewSubmitServerErrorMessage =>
      'Something went wrong submitting your review. Please try again.';

  @override
  String get reviewSubmitNetworkMessage =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get notificationsRealLoadingMessage => 'Loading notifications…';

  @override
  String get notificationsRealErrorMessage =>
      'We couldn\'t load your notifications. Please try again.';

  @override
  String get notificationsRealSubtitle =>
      'Updates from your bookings, payments and reviews.';

  @override
  String get notificationActionForbiddenMessage =>
      'You don\'t have permission to change this notification.';

  @override
  String get notificationActionServerErrorMessage =>
      'Something went wrong updating your notifications. Please try again.';

  @override
  String get notificationActionNetworkMessage =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get recentlyViewedTitle => 'Recently viewed';

  @override
  String get recentlyViewedLoadingMessage => 'Loading recently viewed…';

  @override
  String get recentlyViewedErrorMessage =>
      'We couldn\'t load your recently viewed places. Please try again.';

  @override
  String get recentlyViewedEmptyTitle => 'Nothing here yet';

  @override
  String get recentlyViewedEmptyMessage => 'Places you view will appear here.';

  @override
  String get recentlyViewedUnknownPlace => 'Place';

  @override
  String recentlyViewedCardSemantic(String name) {
    return 'Open $name';
  }

  @override
  String recentlyViewedRatingSemantic(String rating, int count) {
    return 'Rated $rating from $count reviews';
  }

  @override
  String recentlyViewedRemoveSemantic(String name) {
    return 'Remove $name from recently viewed';
  }

  @override
  String get recentlyViewedClearSemantic => 'Clear recently viewed';

  @override
  String get recentlyViewedClearConfirmTitle => 'Clear recently viewed?';

  @override
  String get recentlyViewedClearConfirmMessage =>
      'This removes every place from your recently viewed list.';

  @override
  String get recentlyViewedClearConfirmAction => 'Clear all';

  @override
  String get recentlyViewedRemoveConfirmTitle => 'Remove from recently viewed?';

  @override
  String recentlyViewedRemoveConfirmMessage(String name) {
    return 'Remove $name from your recently viewed list?';
  }

  @override
  String get recentlyViewedRemoveConfirmAction => 'Remove';

  @override
  String get recentlyViewedClearedMessage => 'Recently viewed cleared.';

  @override
  String get recentlyViewedRemovedMessage => 'Removed from recently viewed.';

  @override
  String get recentlyViewedOpenErrorMessage =>
      'We couldn\'t open this place. Please try again.';

  @override
  String get recentlyViewedGoneMessage => 'This place is no longer available.';

  @override
  String get recentlyViewedForbiddenMessage =>
      'You don\'t have permission to do that.';

  @override
  String get recentlyViewedActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get recentlyViewedNetworkMessage =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get profileEditTitle => 'Profile & preferences';

  @override
  String get profileEditLoadingMessage => 'Loading your profile…';

  @override
  String get profileEditErrorMessage =>
      'We couldn\'t load your profile. Please try again.';

  @override
  String get profileEditMissingMessage => 'Your profile isn\'t available.';

  @override
  String get profileEditSaveAction => 'Save changes';

  @override
  String get profileEditSavedMessage => 'Profile updated.';

  @override
  String get profileEditSaveErrorMessage =>
      'We couldn\'t save your changes. Please try again.';

  @override
  String get profileEditForbiddenMessage =>
      'You don\'t have permission to do that.';

  @override
  String get profileEditNetworkMessage =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get profileEditIdentitySection => 'Account';

  @override
  String get profileEditPreferencesSection => 'Travel preferences';

  @override
  String get profileEditContactSection => 'Contact & documents';

  @override
  String get profileFieldAvatar => 'Avatar image URL';

  @override
  String get profileFieldLanguage => 'Preferred language';

  @override
  String get profileFieldCurrency => 'Preferred currency';

  @override
  String get profileFieldPaymentMethod => 'Preferred payment method';

  @override
  String get profileFieldNationality => 'Nationality';

  @override
  String get profileFieldEmergencyName => 'Emergency contact name';

  @override
  String get profileFieldEmergencyPhone => 'Emergency contact phone';

  @override
  String get profileFieldAccessibility => 'Accessibility needs';

  @override
  String get profileFieldDietaryPreference => 'Dietary preference';

  @override
  String get profileFieldTravelStyle => 'Travel style';

  @override
  String get profileEditPassportLabel => 'Passport number';

  @override
  String profileEditPassportWarning(String masked) {
    return 'Currently saved: $masked. Re-enter it to keep it — leaving this blank removes the saved passport when you save.';
  }

  @override
  String get profileEditPassportHint => 'Optional. Stored masked once saved.';

  @override
  String get profileEditMarketingLabel => 'Receive marketing updates';

  @override
  String get profileEditOptionalHint => 'Optional';

  @override
  String profileCompletionSemantic(int percent) {
    return 'Profile $percent% complete';
  }

  @override
  String profileRoleSemantic(String role) {
    return 'Account role: $role';
  }

  @override
  String get profileEditEmptyPreferences =>
      'Add your travel preferences to personalise your trips.';

  @override
  String get giftCardsRealClaimTitle => 'Claim a gift card';

  @override
  String get giftCardsRealClaimHelper =>
      'Enter a gift-card code you received to add it to your account.';

  @override
  String get giftCardsRealClaimSuccess => 'Gift card claimed.';

  @override
  String get giftCardsRealLoadingMessage => 'Loading your gift cards…';

  @override
  String get giftCardsRealErrorMessage =>
      'We couldn\'t load your gift cards. Please try again.';

  @override
  String get giftCardsRealEmptyMessage =>
      'Gift cards you purchase or receive will appear here.';

  @override
  String get giftCardsRealLoadMore => 'Load more';

  @override
  String get giftCardsRealActivateAction => 'Activate gift card';

  @override
  String get giftCardsRealActivateSuccess => 'Gift card activated.';

  @override
  String get giftCardsRealActionError =>
      'Something went wrong. Please try again.';

  @override
  String get giftCardsRealNotFound => 'That gift card could not be found.';

  @override
  String get giftCardsRealConflict =>
      'This gift card can\'t be used in its current state.';

  @override
  String get giftCardsRealNetwork =>
      'We couldn\'t reach the server. Please check your connection and try again.';

  @override
  String get giftCardsRealValidation =>
      'Please check the gift-card code and try again.';

  @override
  String get giftCardStatusUnknown => 'Unknown';

  @override
  String giftCardsRealBalanceSemantic(String balance) {
    return 'Current balance $balance';
  }

  @override
  String get loyaltyRealLoadingMessage => 'Loading your loyalty points…';

  @override
  String get loyaltyRealErrorMessage =>
      'We couldn\'t load your loyalty points. Please try again.';

  @override
  String get loyaltyRealLoadMore => 'Load more';

  @override
  String get loyaltyRealEarnNote =>
      'Points are earned automatically from completed bookings and reviews. They can\'t be redeemed directly here.';

  @override
  String get travelCreditRealLoadingMessage => 'Loading your travel credit…';

  @override
  String get travelCreditRealErrorMessage =>
      'We couldn\'t load your travel credit. Please try again.';

  @override
  String get travelCreditRealLoadMore => 'Load more';

  @override
  String get membershipRealLoadingMessage => 'Loading your membership…';

  @override
  String get membershipRealErrorMessage =>
      'We couldn\'t load your membership. Please try again.';

  @override
  String get membershipRealActiveMessage => 'Your membership is active.';

  @override
  String get membershipRealPreviewMessage =>
      'This is a live preview of the tier you qualify for. Enroll to activate it.';

  @override
  String get membershipRealEnrollAction => 'Enroll now';

  @override
  String get membershipRealEnrolledAction => 'Enrolled';

  @override
  String get membershipRealEnrollSemantic => 'Enroll in membership';

  @override
  String get membershipRealEnrollSuccess => 'You\'re enrolled in membership.';

  @override
  String get membershipRealEnrollError =>
      'We couldn\'t enroll you. Please try again.';

  @override
  String get membershipRealEnrollNeedsLoyalty =>
      'An active loyalty account is required to enroll in membership.';

  @override
  String get membershipRealNoBenefits =>
      'No benefits are listed for this tier yet.';

  @override
  String membershipRealPointsToNext(int points) {
    return '$points more points to the next tier';
  }

  @override
  String membershipRealBookingsToNext(int bookings) {
    return '$bookings more completed bookings to the next tier';
  }

  @override
  String get referralRealLoadingMessage => 'Loading your referral…';

  @override
  String get referralRealErrorMessage =>
      'We couldn\'t load your referral. Please try again.';

  @override
  String get referralRealUseHelper =>
      'Enter a friend\'s referral code. Rewards follow a qualifying booking.';

  @override
  String get referralRealUseSuccess =>
      'Referral code applied. Rewards follow a qualifying booking.';

  @override
  String get referralRealUseError =>
      'We couldn\'t apply that code. Please try again.';

  @override
  String get referralRealAlreadyUsed =>
      'You have already used a referral code and cannot use another.';

  @override
  String get referralRealCodeNotFound => 'That referral code was not found.';

  @override
  String get referralRealNoHistory =>
      'No referral activity yet. Share your code to get started.';

  @override
  String get couponsRealLoadingMessage => 'Loading your coupons…';

  @override
  String get couponsRealErrorMessage =>
      'We couldn\'t load your coupons. Please try again.';

  @override
  String get couponsRealClaimHelper =>
      'Enter a coupon code to add it to your account.';

  @override
  String get couponsRealClaimSuccess => 'Coupon claimed.';

  @override
  String get couponsRealClaimError =>
      'We couldn\'t claim that coupon. Please try again.';

  @override
  String get couponsRealNotFound => 'That coupon code was not found.';

  @override
  String get couponsRealInvalidCode =>
      'That coupon is inactive, expired, or not yet valid.';

  @override
  String get couponsRealLimitReached =>
      'You\'ve reached the usage limit for this coupon.';

  @override
  String get couponStatusAvailable => 'Available';

  @override
  String get couponStatusUsed => 'Used';

  @override
  String get couponStatusExpired => 'Expired';

  @override
  String get couponStatusRevoked => 'Revoked';

  @override
  String get couponStatusUnknown => 'Unknown';

  @override
  String couponDetailMinimumSpend(String amount) {
    return 'Minimum spend $amount';
  }

  @override
  String couponDetailValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String couponDetailUsagePerUser(int count) {
    return 'Up to $count use(s) per customer';
  }

  @override
  String get recommendationsTitle => 'Recommended for you';

  @override
  String get recommendationsLoadingMessage => 'Loading your recommendations…';

  @override
  String get recommendationsErrorMessage =>
      'We couldn\'t load your recommendations. Please try again.';

  @override
  String get recommendationsEmptyTitle => 'No recommendations yet';

  @override
  String get recommendationsEmptyMessage =>
      'Save places, browse hotels, and book trips — then regenerate to see picks tailored to you.';

  @override
  String get recommendationsGenerateSemantic => 'Regenerate recommendations';

  @override
  String get recommendationsGeneratedMessage =>
      'Your recommendations are up to date.';

  @override
  String get recommendationsGenerateErrorMessage =>
      'We couldn\'t refresh your recommendations. Please try again.';

  @override
  String get recommendationsLoadMore => 'Load more';

  @override
  String get recommendationsDismissedMessage => 'Recommendation dismissed.';

  @override
  String get recommendationsActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get recommendationsNetworkMessage =>
      'You appear to be offline. Please check your connection.';

  @override
  String get recommendationsGoneMessage =>
      'This recommendation is no longer available.';

  @override
  String get recommendationUntitled => 'Recommendation';

  @override
  String recommendationsDismissSemantic(String name) {
    return 'Dismiss $name';
  }

  @override
  String recommendationCardSemantic(String name) {
    return 'Recommendation: $name';
  }

  @override
  String recommendationScoreSemantic(int score) {
    return 'Match score $score out of 100';
  }

  @override
  String get recommendationTypePlace => 'Place';

  @override
  String get recommendationTypeHotel => 'Hotel';

  @override
  String get recommendationTypeRoom => 'Room';

  @override
  String get recommendationTypePromotion => 'Promotion';

  @override
  String get recommendationTypeCoupon => 'Coupon';

  @override
  String get recommendationTypeTripIdea => 'Trip idea';

  @override
  String get recommendationTypeOther => 'Suggestion';

  @override
  String get recommendationStateClicked => 'Viewed';

  @override
  String get recommendationStateConverted => 'Booked';

  @override
  String get recommendationDetailReason => 'Why we picked this';

  @override
  String recommendationDetailGenerated(String date) {
    return 'Suggested $date';
  }

  @override
  String recommendationDetailExpires(String date) {
    return 'Available until $date';
  }

  @override
  String get expensesTitle => 'Expenses';

  @override
  String get expensesLoadingMessage => 'Loading expenses…';

  @override
  String get expensesErrorMessage =>
      'We couldn\'t load this trip\'s expenses. Please try again.';

  @override
  String get expensesGoneMessage =>
      'This trip or expense is no longer available.';

  @override
  String get expensesForbiddenMessage =>
      'You don\'t have permission to manage expenses for this trip.';

  @override
  String get expensesInvalidMessage =>
      'Please check the amount, currency, title and date.';

  @override
  String get expensesNetworkMessage =>
      'You appear to be offline. Please check your connection.';

  @override
  String get expensesActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get expensesEmptyTitle => 'No expenses yet';

  @override
  String get expensesEmptyMessage =>
      'Track what you spend on this trip — add your first expense.';

  @override
  String get expensesAddAction => 'Add expense';

  @override
  String get expensesSaveAction => 'Save changes';

  @override
  String get expensesAddTitle => 'Add expense';

  @override
  String get expensesEditTitle => 'Edit expense';

  @override
  String get expensesAddSemantic => 'Add an expense';

  @override
  String get expensesCreatedMessage => 'Expense added.';

  @override
  String get expensesUpdatedMessage => 'Expense updated.';

  @override
  String get expensesDeletedMessage => 'Expense deleted.';

  @override
  String get expensesDeleteConfirmTitle => 'Delete expense?';

  @override
  String get expensesDeleteConfirmAction => 'Delete';

  @override
  String get expensesSummarySpent => 'Total spent';

  @override
  String get expensesSummaryOverBudget => 'Over budget';

  @override
  String get expenseUntitled => 'Expense';

  @override
  String get expenseFieldTitle => 'Title';

  @override
  String get expenseFieldAmount => 'Amount';

  @override
  String get expenseFieldCurrency => 'Currency';

  @override
  String get expenseFieldCategory => 'Category';

  @override
  String get expenseFieldDate => 'Date';

  @override
  String get expenseFieldNotes => 'Notes (optional)';

  @override
  String expensesDeleteConfirmMessage(String title) {
    return 'Delete \"$title\"? This can\'t be undone.';
  }

  @override
  String expensesDeleteSemantic(String title) {
    return 'Delete $title';
  }

  @override
  String expenseCardSemantic(String title) {
    return 'Expense: $title';
  }

  @override
  String expensesSummaryBudget(String amount) {
    return 'Budget $amount';
  }

  @override
  String expensesSummaryRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get conversationsTitle => 'Messages';

  @override
  String get conversationsLoadingMessage => 'Loading your messages…';

  @override
  String get conversationsErrorMessage =>
      'We couldn\'t load your messages. Please try again.';

  @override
  String get conversationsEmptyTitle => 'No messages yet';

  @override
  String get conversationsEmptyMessage =>
      'Open a booking and tap the message icon to chat with your host.';

  @override
  String get conversationStatusOpen => 'Open';

  @override
  String get conversationStatusClosed => 'Closed';

  @override
  String get conversationStatusArchived => 'Archived';

  @override
  String get conversationUntitled => 'Conversation';

  @override
  String get conversationLoadingMessage => 'Loading conversation…';

  @override
  String get conversationErrorMessage =>
      'We couldn\'t load this conversation. Please try again.';

  @override
  String get conversationForbiddenMessage =>
      'This conversation isn\'t available to you.';

  @override
  String get conversationGoneMessage =>
      'This conversation is no longer available.';

  @override
  String get conversationArchivedMessage =>
      'This conversation is archived and can\'t receive new messages.';

  @override
  String get conversationEmptyBodyMessage => 'Enter a message to send.';

  @override
  String get conversationNetworkMessage =>
      'You appear to be offline. Please check your connection.';

  @override
  String get conversationActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get conversationNoPartnerMessage =>
      'This booking\'s host can\'t be messaged yet.';

  @override
  String get conversationCloseConfirmTitle => 'Close conversation?';

  @override
  String get conversationCloseConfirmMessage =>
      'You can reopen it later by sending a new message.';

  @override
  String get conversationCloseAction => 'Close';

  @override
  String get conversationClosedMessage => 'Conversation closed.';

  @override
  String get conversationArchivedNote => 'This conversation is archived.';

  @override
  String get conversationNoMessagesTitle => 'No messages yet';

  @override
  String get conversationNoMessagesMessage =>
      'Say hello to start the conversation.';

  @override
  String get conversationSenderYou => 'You';

  @override
  String get conversationSenderHost => 'Host';

  @override
  String get conversationSenderSupport => 'Support';

  @override
  String get conversationSenderSystem => 'System';

  @override
  String get conversationSeen => 'Seen';

  @override
  String get conversationComposerHint => 'Write a message…';

  @override
  String get conversationSendSemantic => 'Send message';

  @override
  String get conversationMessageHostAction => 'Message host';

  @override
  String conversationBookingLabel(String code) {
    return 'Booking $code';
  }

  @override
  String conversationUnreadBadge(int count) {
    return '$count unread';
  }

  @override
  String conversationTileSemantic(String title, int count) {
    return 'Conversation $title, $count unread';
  }

  @override
  String conversationMessageSemantic(String sender, String body) {
    return '$sender said: $body';
  }

  @override
  String get aiContextTitle => 'AI trip context';

  @override
  String get aiContextLoadingMessage => 'Loading your trip context…';

  @override
  String get aiContextErrorMessage =>
      'We couldn\'t load your trip context. Please try again.';

  @override
  String get aiContextExplainer =>
      'A read-only snapshot of your travel data that an AI assistant would use. No message is generated here.';

  @override
  String get aiContextActivityTitle => 'Your activity';

  @override
  String get aiContextCurrentTripTitle => 'Current trip';

  @override
  String get aiContextBudgetTitle => 'Current trip budget';

  @override
  String get aiContextUpcomingTripsTitle => 'Upcoming trips';

  @override
  String get aiContextUntitledTrip => 'Untitled trip';

  @override
  String get aiContextOverBudget => 'Over budget';

  @override
  String get aiContextStatTrips => 'Trips';

  @override
  String get aiContextStatActiveTrips => 'Active';

  @override
  String get aiContextStatUpcomingTrips => 'Upcoming';

  @override
  String get aiContextStatCompletedTrips => 'Completed';

  @override
  String get aiContextStatPlannedDays => 'Planned days';

  @override
  String get aiContextStatBookings => 'Bookings';

  @override
  String get aiContextStatCollections => 'Collections';

  @override
  String get aiContextStatWishlist => 'Wishlist';

  @override
  String get aiContextStatReviews => 'Reviews';

  @override
  String get aiContextStatRecommendations => 'Recommendations';

  @override
  String aiContextGeneratedAt(String date) {
    return 'Snapshot taken $date';
  }

  @override
  String aiContextTripDays(int count) {
    return '$count days';
  }

  @override
  String aiContextStatSemantic(String label, int value) {
    return '$label: $value';
  }

  @override
  String aiContextSpent(String amount) {
    return 'Spent $amount';
  }

  @override
  String aiContextBudget(String amount) {
    return 'Budget $amount';
  }

  @override
  String aiContextRemaining(String amount) {
    return '$amount left';
  }

  @override
  String get documentsRealLoadingMessage => 'Loading documents…';

  @override
  String get documentsRealErrorMessage =>
      'We couldn\'t load this trip\'s documents. Please try again.';

  @override
  String get documentsRealForbiddenMessage =>
      'You don\'t have permission to manage documents for this trip.';

  @override
  String get documentsRealGoneMessage =>
      'This trip or document is no longer available.';

  @override
  String get documentsRealNetworkMessage =>
      'You appear to be offline. Please check your connection.';

  @override
  String get documentsRealActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get documentsRealCreatedMessage => 'Document attached.';

  @override
  String get documentsRealUpdatedMessage => 'Document updated.';

  @override
  String get documentsRealPinnedMessage => 'Document pinned.';

  @override
  String get documentsRealUnpinnedMessage => 'Document unpinned.';

  @override
  String get documentsRealUrlRequiredMessage => 'Enter a link to the document.';

  @override
  String get documentsRealAddSemantic => 'Attach a document';

  @override
  String get documentsRealTypeUnknown => 'Document';

  @override
  String get notesRealTitle => 'Notes';

  @override
  String get notesRealLoadingMessage => 'Loading notes…';

  @override
  String get notesRealErrorMessage =>
      'We couldn\'t load this trip\'s notes. Please try again.';

  @override
  String get notesRealForbiddenMessage =>
      'You don\'t have permission to manage notes for this trip.';

  @override
  String get notesRealGoneMessage =>
      'This trip or note is no longer available.';

  @override
  String get notesRealNetworkMessage =>
      'You appear to be offline. Please check your connection.';

  @override
  String get notesRealActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get notesRealCreatedMessage => 'Note added.';

  @override
  String get notesRealUpdatedMessage => 'Note updated.';

  @override
  String get notesRealDeletedMessage => 'Note deleted.';

  @override
  String get notesRealPinnedMessage => 'Note pinned.';

  @override
  String get notesRealUnpinnedMessage => 'Note unpinned.';

  @override
  String get notesRealContentRequiredMessage =>
      'Enter some content for this note.';

  @override
  String get notesRealAddSemantic => 'Add a note';

  @override
  String get notesRealMoodNone => 'No mood';

  @override
  String get notesRealCreateTitle => 'New note';

  @override
  String get notesRealEditTitle => 'Edit note';

  @override
  String get packingRealTitle => 'Packing';

  @override
  String get packingRealLoadingMessage => 'Loading packing checklist…';

  @override
  String get packingRealErrorMessage =>
      'We couldn\'t load this trip\'s packing checklist. Please try again.';

  @override
  String get packingRealForbiddenMessage =>
      'You don\'t have permission to manage the packing list for this trip.';

  @override
  String get packingRealGoneMessage =>
      'This trip or packing item is no longer available.';

  @override
  String get packingRealNetworkMessage =>
      'You appear to be offline. Please check your connection.';

  @override
  String get packingRealActionErrorMessage =>
      'Something went wrong. Please try again.';

  @override
  String get packingRealCreatedMessage => 'Packing item added.';

  @override
  String get packingRealUpdatedMessage => 'Packing item updated.';

  @override
  String get packingRealDeletedMessage => 'Packing item deleted.';

  @override
  String get packingRealLabelRequiredMessage => 'Enter a name for this item.';

  @override
  String get packingRealQuantityInvalidMessage => 'Quantity must be 1 or more.';

  @override
  String get packingRealAddSemantic => 'Add a packing item';

  @override
  String get packingRealCreateTitle => 'New packing item';

  @override
  String get packingRealEditTitle => 'Edit packing item';

  @override
  String get packingRealEmptyTitle => 'Nothing to pack yet';

  @override
  String get packingRealEmptyMessage =>
      'Add what you need to bring on this trip.';

  @override
  String packingRealDeleteConfirmMessage(String label) {
    return 'Delete $label from this checklist?';
  }

  @override
  String packingRealCheckSemantic(String label) {
    return 'Mark $label as packed';
  }

  @override
  String packingRealUncheckSemantic(String label) {
    return 'Mark $label as not packed';
  }

  @override
  String get remindersRealTitle => 'Trip reminders';

  @override
  String get remindersRealLoadingMessage => 'Loading reminders…';

  @override
  String get remindersRealErrorMessage =>
      'We couldn\'t load these reminders. Pull to refresh or try again.';

  @override
  String get remindersRealForbiddenMessage =>
      'You can view these reminders but only the trip owner or an editor can change them.';

  @override
  String get remindersRealGoneMessage =>
      'This reminder or trip is no longer available.';

  @override
  String get remindersRealNetworkMessage =>
      'No connection. Check your network and try again.';

  @override
  String get remindersRealActionErrorMessage =>
      'That didn\'t work. Please try again.';

  @override
  String get remindersRealCreatedMessage => 'Reminder added.';

  @override
  String get remindersRealUpdatedMessage => 'Reminder updated.';

  @override
  String get remindersRealCompletedMessage => 'Reminder marked complete.';

  @override
  String get remindersRealCancelledMessage => 'Reminder cancelled.';

  @override
  String get remindersRealDeletedMessage => 'Reminder deleted.';

  @override
  String get remindersRealTitleRequiredMessage => 'Enter a reminder title.';

  @override
  String get remindersRealAddSemantic => 'Add a reminder';

  @override
  String get remindersRealCreateTitle => 'New reminder';

  @override
  String get remindersRealEditTitle => 'Edit reminder';

  @override
  String get remindersRealEmptyTitle => 'No reminders yet';

  @override
  String get remindersRealEmptyMessage =>
      'Add a reminder to keep track of check-ins, flights, payments, and packing for this trip.';

  @override
  String remindersRealDeleteConfirmMessage(String title) {
    return 'Delete $title from this trip?';
  }

  @override
  String remindersRealCompleteSemantic(String title) {
    return 'Mark $title as complete';
  }

  @override
  String remindersRealCancelSemantic(String title) {
    return 'Cancel $title';
  }

  @override
  String get budgetRealTitle => 'Trip budget';

  @override
  String get budgetRealLoadingMessage => 'Loading budget…';

  @override
  String get budgetRealErrorMessage =>
      'We couldn\'t load this budget. Pull to refresh or try again.';

  @override
  String get budgetRealForbiddenMessage =>
      'Only the trip owner can set or change the budget.';

  @override
  String get budgetRealGoneMessage => 'This trip is no longer available.';

  @override
  String get budgetRealNetworkMessage =>
      'No connection. Check your network and try again.';

  @override
  String get budgetRealActionErrorMessage =>
      'That didn\'t work. Please try again.';

  @override
  String get budgetRealSavedMessage => 'Budget saved.';

  @override
  String get budgetRealDeletedMessage => 'Budget deleted.';

  @override
  String get budgetRealAmountInvalidMessage =>
      'Enter a budget amount of 0 or more.';

  @override
  String get budgetRealCurrencyRequiredMessage => 'Enter a currency.';

  @override
  String get budgetRealEmptyTitle => 'No budget set';

  @override
  String get budgetRealEmptyMessage =>
      'Set a total budget to track spending against it for this trip.';

  @override
  String get budgetRealSetTitle => 'Set trip budget';

  @override
  String get budgetRealEditTitle => 'Edit trip budget';

  @override
  String get budgetRealSaveAction => 'Save budget';

  @override
  String get budgetRealEditAction => 'Edit';

  @override
  String get budgetRealDeleteAction => 'Delete budget';

  @override
  String get budgetRealDeleteConfirmTitle => 'Delete budget?';

  @override
  String get budgetRealDeleteConfirmMessage =>
      'Remove the total budget for this trip? Expenses stay unchanged.';

  @override
  String get collaborationRealTitle => 'Collaboration';

  @override
  String get collaborationRealLoadingMessage => 'Loading collaborators…';

  @override
  String get collaborationRealErrorMessage =>
      'We couldn\'t load collaborators. Pull to refresh or try again.';

  @override
  String get collaborationRealForbiddenMessage =>
      'Only the trip owner can manage collaborators.';

  @override
  String get collaborationRealGoneMessage =>
      'This trip is no longer available.';

  @override
  String get collaborationRealNetworkMessage =>
      'No connection. Check your network and try again.';

  @override
  String get collaborationRealActionErrorMessage =>
      'That didn\'t work. Please try again.';

  @override
  String get collaborationRealInvitedMessage => 'Collaborator invited.';

  @override
  String get collaborationRealRoleUpdatedMessage => 'Role updated.';

  @override
  String get collaborationRealRemovedMessage => 'Collaborator removed.';

  @override
  String get collaborationRealPublicOnMessage => 'This trip is now public.';

  @override
  String get collaborationRealPublicOffMessage => 'This trip is private.';

  @override
  String get collaborationRealInvalidMessage =>
      'Enter a valid collaborator email that isn\'t your own.';

  @override
  String get collaborationRealUserNotFoundMessage =>
      'No registered user has that email.';

  @override
  String get collaborationRealAlreadyMemberMessage =>
      'This user is already a collaborator.';

  @override
  String get collaborationRealEmptyTitle => 'No collaborators yet';

  @override
  String get collaborationRealEmptyMessage =>
      'Invite someone by email to view or edit this trip together.';

  @override
  String get collaborationRealEmailLabel => 'Collaborator email';

  @override
  String get collaborationRealRoleLabel => 'Role';

  @override
  String get collaborationRealEditRoleTitle => 'Change role';

  @override
  String get collaborationRealOwnerBadge => 'You own this trip';

  @override
  String get collaborationRealPublicLabel => 'Public visibility';

  @override
  String get collaborationRealAddSemantic => 'Invite a collaborator';

  @override
  String collaborationRealRemoveConfirmMessage(String name) {
    return 'Remove $name from this trip? They lose access immediately.';
  }

  @override
  String get sharedTripsRealLoadingMessage => 'Loading shared trips…';

  @override
  String get sharedTripsRealErrorMessage =>
      'We couldn\'t load your shared trips. Pull to refresh or try again.';

  @override
  String get sharedTripsRealForbiddenMessage =>
      'You don\'t have access to these shared trips.';

  @override
  String get sharedTripsRealGoneMessage =>
      'These shared trips are no longer available.';

  @override
  String get sharedTripsRealEmptyTitle => 'No shared trips';

  @override
  String get sharedTripsRealEmptyMessage =>
      'Trips that others invite you to collaborate on will appear here.';

  @override
  String get sharedTripsRealUntitled => 'Untitled trip';

  @override
  String get sharedTripsRealEntryTitle => 'Shared with me';

  @override
  String get sharedTripsRealEntrySubtitle =>
      'Open trips others have invited you to.';

  @override
  String get sharedTripsRealEntrySemantic =>
      'Shared with me — trips others have invited you to collaborate on';

  @override
  String get interestRealTitle => 'My travel interests';

  @override
  String get interestRealEntryTitle => 'Travel interests';

  @override
  String get interestRealLoadingMessage => 'Loading your interests…';

  @override
  String get interestRealErrorMessage =>
      'We couldn\'t load your interests. Pull to refresh or try again.';

  @override
  String get interestRealForbiddenMessage =>
      'You don\'t have access to this interest profile.';

  @override
  String get interestRealGoneMessage =>
      'This interest profile is no longer available.';

  @override
  String get interestRealNetworkMessage =>
      'No connection. Check your network and try again.';

  @override
  String get interestRealEmptyTitle => 'No interests yet';

  @override
  String get interestRealEmptyMessage =>
      'Recalculate to build your interest profile from your bookings, wishlist, saved collections and reviews.';

  @override
  String get interestRealRecalculateAction => 'Recalculate';

  @override
  String get interestRealRecalculateSemantic =>
      'Recalculate my interest profile from my activity';

  @override
  String get interestRealRecalculatedMessage => 'Interests updated.';

  @override
  String get interestRealRecalculateErrorMessage =>
      'We couldn\'t update your interests. Please try again.';

  @override
  String interestRealSignalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Derived from $count signals',
      one: 'Derived from 1 signal',
      zero: 'No signals yet',
    );
    return '$_temp0';
  }

  @override
  String interestRealLastUpdated(String when) {
    return 'Last updated $when';
  }

  @override
  String get interestRealTravelStyles => 'Travel styles';

  @override
  String get interestRealWeather => 'Preferred weather';

  @override
  String get interestRealBudget => 'Budget level';

  @override
  String get interestRealCrowd => 'Crowd level';

  @override
  String get interestRealAccessibility => 'Accessibility';

  @override
  String get interestRealProvinces => 'Favorite destinations';

  @override
  String get interestRealCategories => 'Favorite categories';

  @override
  String get interestRealTags => 'Favorite tags';

  @override
  String get walletRealLoadingMessage => 'Loading your wallet…';

  @override
  String get walletRealErrorMessage =>
      'We couldn\'t load your wallet. Pull to refresh or try again.';

  @override
  String get walletRealForbiddenMessage =>
      'You don\'t have access to this wallet item.';

  @override
  String get walletRealGoneMessage =>
      'This wallet item is no longer available.';

  @override
  String get walletRealNetworkMessage =>
      'No connection. Check your network and try again.';

  @override
  String get walletRealActionErrorMessage =>
      'That didn\'t work. Please try again.';

  @override
  String get walletRealCreatedMessage => 'Wallet item added.';

  @override
  String get walletRealUpdatedMessage => 'Wallet item updated.';

  @override
  String get walletRealDeletedMessage => 'Wallet item deleted.';

  @override
  String get walletRealFavoritedMessage => 'Added to favorites.';

  @override
  String get walletRealUnfavoritedMessage => 'Removed from favorites.';

  @override
  String get walletRealArchivedMessage => 'Wallet item archived.';

  @override
  String get walletRealRestoredMessage => 'Wallet item restored.';

  @override
  String get walletRealTitleRequiredMessage =>
      'Enter a title for this wallet item.';

  @override
  String get walletRealAddSemantic => 'Add a wallet item';

  @override
  String get walletRealCreateTitle => 'New wallet item';

  @override
  String get walletRealEditTitle => 'Edit wallet item';

  @override
  String get walletRealUntitled => 'Untitled item';

  @override
  String get walletRealListEmptyTitle => 'Your wallet is empty';

  @override
  String get walletRealListEmptyMessage =>
      'Add a passport, visa, ticket, voucher, or receipt to keep it handy for your trips.';

  @override
  String get walletRealTitleField => 'Title';

  @override
  String get walletRealIssuerField => 'Issuer (optional)';

  @override
  String get walletRealReferenceField => 'Reference number (optional)';

  @override
  String get walletRealReferenceNote =>
      'The reference number is stored masked and cannot be shown again.';

  @override
  String walletRealReferenceHint(String masked) {
    return 'Current: $masked. Leave blank to keep it removed; re-enter to replace.';
  }

  @override
  String get walletRealValidFromField => 'Valid from';

  @override
  String get walletRealValidUntilField => 'Valid until';

  @override
  String get walletRealDateNone => 'Not set';

  @override
  String get walletRealSaveAction => 'Save item';

  @override
  String get walletRealEditAction => 'Edit';

  @override
  String get walletRealDeleteAction => 'Delete';

  @override
  String get walletRealArchiveAction => 'Archive';

  @override
  String get walletRealRestoreAction => 'Restore';

  @override
  String get walletRealDeleteConfirmTitle => 'Delete wallet item?';

  @override
  String walletRealDeleteConfirmMessage(String title) {
    return 'Delete $title from your wallet? The linked document, booking, or invoice is not affected.';
  }

  @override
  String walletRealFavoriteSemantic(String title) {
    return 'Add $title to favorites';
  }

  @override
  String walletRealUnfavoriteSemantic(String title) {
    return 'Remove $title from favorites';
  }

  @override
  String get partnerExtranetTitle => 'Partner Extranet';

  @override
  String get partnerWorkspaceUnnamed => 'Your workspace';

  @override
  String get partnerNavGroupOverview => 'Overview';

  @override
  String get partnerNavGroupProperty => 'Property';

  @override
  String get partnerNavGroupOperations => 'Operations';

  @override
  String get partnerNavGroupGrowth => 'Growth';

  @override
  String get partnerNavGroupBusiness => 'Business';

  @override
  String get partnerNavGroupAccount => 'Account';

  @override
  String get partnerNavDashboard => 'Dashboard';

  @override
  String get partnerNavHotels => 'Hotels';

  @override
  String get partnerNavRooms => 'Rooms';

  @override
  String get partnerNavCalendar => 'Calendar';

  @override
  String get partnerNavPricing => 'Pricing';

  @override
  String get partnerNavPromotions => 'Promotions';

  @override
  String get partnerNavBookings => 'Bookings';

  @override
  String get partnerNavMessages => 'Messages';

  @override
  String get partnerNavAnalytics => 'Analytics';

  @override
  String get partnerNavFinance => 'Finance';

  @override
  String get partnerNavReviews => 'Reviews';

  @override
  String get partnerNavNotifications => 'Notifications';

  @override
  String get partnerNavSettings => 'Settings';

  @override
  String get partnerNavMenuTooltip => 'Open partner menu';

  @override
  String partnerNavBadgeSemantic(String label, int count) {
    return '$label, $count pending';
  }

  @override
  String partnerTeamRoleLabel(String role) {
    return 'Your team role: $role';
  }

  @override
  String get partnerTeamRoleOwner => 'Owner';

  @override
  String get partnerTeamRoleManager => 'Manager';

  @override
  String get partnerTeamRoleFrontDesk => 'Front desk';

  @override
  String get partnerTeamRoleFinance => 'Finance';

  @override
  String get partnerTeamRoleViewer => 'Viewer';

  @override
  String get partnerTeamRoleUnknown => 'Not determined';

  @override
  String get partnerActionRetry => 'Try again';

  @override
  String get partnerActionRefresh => 'Refresh';

  @override
  String get partnerActionBack => 'Go back';

  @override
  String get partnerShellMobileHint =>
      'Use a larger screen for the full operations console.';

  @override
  String get partnerStatusLoadingTitle => 'Loading your workspace';

  @override
  String get partnerStatusLoadingMessage =>
      'Fetching your partner profile and today\'s activity.';

  @override
  String get partnerStatusReadyTitle => 'Workspace ready';

  @override
  String get partnerStatusReadyMessage =>
      'Your partner workspace is up to date.';

  @override
  String get partnerStatusDemoTitle => 'Not available in demo mode';

  @override
  String get partnerStatusDemoMessage =>
      'The Partner Extranet works only against the real backend. Sign in with a partner account to open it.';

  @override
  String get partnerStatusNotPartnerTitle => 'Partner access required';

  @override
  String get partnerStatusNotPartnerMessage =>
      'This account is not a partner account, so the Partner Extranet is unavailable.';

  @override
  String get partnerStatusOnboardingTitle => 'No partner profile yet';

  @override
  String get partnerStatusOnboardingMessage =>
      'This account has no partner business profile. One must be created and approved before the workspace opens.';

  @override
  String get partnerStatusAwaitingApprovalTitle => 'Waiting for approval';

  @override
  String get partnerStatusAwaitingApprovalMessage =>
      'Your partner profile is submitted. The workspace opens once an administrator approves it.';

  @override
  String get partnerStatusRejectedTitle => 'Partner profile rejected';

  @override
  String get partnerStatusRejectedMessage =>
      'Your partner application was rejected, so the workspace is closed.';

  @override
  String get partnerStatusSuspendedTitle => 'Partner account suspended';

  @override
  String get partnerStatusSuspendedMessage =>
      'An administrator suspended this partner account. Contact support to restore access.';

  @override
  String get partnerStatusTeamMemberTitle => 'Team access not supported yet';

  @override
  String get partnerStatusTeamMemberMessage =>
      'You belong to a partner team but do not own its profile. The extranet overview is currently available to the profile owner only.';

  @override
  String get partnerStatusUnauthorizedTitle => 'Sign in again';

  @override
  String get partnerStatusUnauthorizedMessage =>
      'Your session expired. Sign in again to reopen the workspace.';

  @override
  String get partnerStatusForbiddenTitle => 'Access refused';

  @override
  String get partnerStatusForbiddenMessage =>
      'The server refused this request for your account.';

  @override
  String get partnerStatusErrorTitle => 'Could not load the workspace';

  @override
  String get partnerStatusErrorMessage =>
      'We could not reach the partner service. Check your connection and try again.';

  @override
  String get partnerVerificationApproved => 'Approved';

  @override
  String get partnerVerificationSubmitted => 'Submitted';

  @override
  String get partnerVerificationDraft => 'Draft';

  @override
  String get partnerVerificationRejected => 'Rejected';

  @override
  String get partnerVerificationSuspended => 'Suspended';

  @override
  String get partnerVerificationUnknown => 'Unknown';

  @override
  String get partnerDashboardTodayHeading => 'Today at a glance';

  @override
  String partnerDashboardRepresentative(String name) {
    return 'Represented by $name';
  }

  @override
  String get partnerMetricArrivals => 'Arrivals today';

  @override
  String get partnerMetricDepartures => 'Departures today';

  @override
  String get partnerMetricUnreadMessages => 'Unread messages';

  @override
  String get partnerMetricPendingReviews => 'Pending reviews';

  @override
  String get partnerMetricActivePromotions => 'Active promotions';

  @override
  String get partnerMetricNotifications => 'Notifications';

  @override
  String get partnerMetricProperties => 'Properties';

  @override
  String get partnerMetricActiveRooms => 'Active rooms';

  @override
  String get partnerPropertyScopeHeading => 'Property scope';

  @override
  String get partnerPropertyScopeEmpty =>
      'No properties are assigned to this partner account yet.';

  @override
  String get partnerPropertyScopeUnavailable =>
      'The property list could not be loaded. Refresh to try again.';

  @override
  String partnerPropertyInactiveSemantic(String name) {
    return '$name, inactive';
  }

  @override
  String get partnerModulePlannedBadge => 'Planned';

  @override
  String get partnerModulePlannedMessage =>
      'This module is not built yet. It will be wired to the existing partner endpoints in a later phase; no data is shown until then.';

  @override
  String partnerModuleEndpointHint(String route) {
    return 'Route: $route';
  }

  @override
  String get partnerModuleReadOnlyForRole =>
      'Your team role will not be able to change settings in this module.';

  @override
  String get partnerDashboardScopeHeading => 'Reporting scope';

  @override
  String get partnerDashboardScopeHint =>
      'Applies to Performance, Occupancy and Revenue. Today\'s operations always cover every property.';

  @override
  String get partnerDashboardScopeToday => 'Today · all properties';

  @override
  String get partnerDashboardScopeAllProperties => 'All properties';

  @override
  String get partnerDashboardScopeLast30AllProperties =>
      'Last 30 days · all properties';

  @override
  String partnerDashboardScopeWindowAll(String window) {
    return '$window · all properties';
  }

  @override
  String partnerDashboardScopeWindowOne(String window) {
    return '$window · selected property';
  }

  @override
  String get partnerDashboardRangeLabel => 'Date range';

  @override
  String get partnerDashboardRangeLast7 => '7 days';

  @override
  String get partnerDashboardRangeLast30 => '30 days';

  @override
  String get partnerDashboardRangeLast90 => '90 days';

  @override
  String get partnerDashboardPropertyLabel => 'Property';

  @override
  String get partnerDashboardPropertyAll => 'All properties';

  @override
  String partnerDashboardPropertyCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties',
      one: '1 property',
    );
    return '$_temp0';
  }

  @override
  String partnerDashboardRoomCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active rooms',
      one: '1 active room',
    );
    return '$_temp0';
  }

  @override
  String partnerDashboardTeamRole(String role) {
    return 'Your role: $role';
  }

  @override
  String partnerDashboardActiveProperty(String name) {
    return 'Scoped to $name';
  }

  @override
  String partnerDashboardUpdatedAt(String time) {
    return 'Updated $time';
  }

  @override
  String get partnerDashboardNoActivityHint =>
      'No bookings fall in the selected window yet, so the performance figures below are zero.';

  @override
  String get partnerDashboardAttentionHeading => 'Needs attention';

  @override
  String get partnerDashboardAttentionClear =>
      'Nothing is waiting on you right now.';

  @override
  String partnerDashboardAttentionSemantic(String label, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items need attention',
      one: '1 item needs attention',
    );
    return '$label, $_temp0';
  }

  @override
  String get partnerDashboardQuickActionsHeading => 'Quick actions';

  @override
  String get partnerDashboardPerformanceHeading => 'Performance';

  @override
  String get partnerDashboardPerformanceEmpty =>
      'No bookings in this period, so there is nothing to report yet.';

  @override
  String get partnerDashboardOccupancyHeading => 'Occupancy';

  @override
  String get partnerDashboardOccupancyNoInventory =>
      'No room inventory is configured yet, so occupancy cannot be measured.';

  @override
  String get partnerDashboardOccupancyChartLabel => 'Occupancy per day';

  @override
  String get partnerDashboardRevenueHeading => 'Revenue';

  @override
  String get partnerDashboardRevenueChartLabel => 'Revenue per day';

  @override
  String get partnerDashboardFinanceHeading => 'Finance summary';

  @override
  String get partnerDashboardActivityHeading => 'Recent activity';

  @override
  String get partnerDashboardActivityEmpty =>
      'No activity has been recorded yet.';

  @override
  String partnerDashboardActivityBy(String actor) {
    return 'by $actor';
  }

  @override
  String get partnerDashboardActivityUnknownActor => 'Unknown user';

  @override
  String partnerDashboardActivityMore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count older entries',
      one: '1 older entry',
    );
    return '$_temp0';
  }

  @override
  String get partnerDashboardChartEmpty => 'No data points in this period.';

  @override
  String get partnerDashboardErrorUnauthorized =>
      'Your session expired. Sign in again to load this.';

  @override
  String get partnerDashboardErrorForbidden =>
      'Your partner profile is not approved for this data.';

  @override
  String get partnerDashboardErrorNotFound =>
      'This data is not available for your partner profile.';

  @override
  String get partnerDashboardErrorValidation =>
      'That date range is not valid. Choose a different period.';

  @override
  String get partnerDashboardErrorTimeout =>
      'This panel took too long to load.';

  @override
  String get partnerDashboardErrorNetwork =>
      'Could not reach the server for this panel.';

  @override
  String get partnerDashboardErrorServer =>
      'The server could not produce this data.';

  @override
  String get partnerDashboardErrorGeneric => 'This panel could not be loaded.';

  @override
  String get partnerValueUnavailable => '—';

  @override
  String get partnerKpiCurrentGuests => 'In house now';

  @override
  String get partnerKpiUpcoming => 'Upcoming';

  @override
  String get partnerKpiOccupancy => 'Occupancy';

  @override
  String get partnerKpiRevenueToday => 'Revenue today';

  @override
  String get partnerKpiRevenueMonth => 'Revenue this month';

  @override
  String get partnerKpiAverageStay => 'Average stay (nights)';

  @override
  String get partnerKpiTotalRevenue => 'Total revenue';

  @override
  String get partnerKpiTotalBookings => 'Total bookings';

  @override
  String get partnerKpiAdr => 'Average daily rate';

  @override
  String get partnerKpiAdrCaption => 'Per sold room night';

  @override
  String get partnerKpiConfirmed => 'Confirmed';

  @override
  String get partnerKpiCancelled => 'Cancelled';

  @override
  String get partnerKpiReviewAverage => 'Average rating';

  @override
  String partnerKpiReviewCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'From $count reviews',
      one: 'From 1 review',
      zero: 'No reviews',
    );
    return '$_temp0';
  }

  @override
  String get partnerKpiResponseRate => 'Message response rate';

  @override
  String get partnerOccupancyInventory => 'Room inventory';

  @override
  String get partnerOccupancySold => 'Sold rooms';

  @override
  String get partnerOccupancyAvailable => 'Available rooms';

  @override
  String get partnerOccupancyStopSell => 'Stop-sell days';

  @override
  String get partnerRevenueMonthToDate => 'Month to date';

  @override
  String get partnerRevenueLast30 => 'Last 30 days';

  @override
  String get partnerRevenueByProperty => 'Revenue by property';

  @override
  String get partnerFinanceGross => 'Gross revenue';

  @override
  String get partnerFinanceNet => 'Net revenue';

  @override
  String get partnerFinanceCommission => 'Platform commission';

  @override
  String get partnerFinanceTax => 'Estimated tax';

  @override
  String get partnerFinanceRefunded => 'Refunded';

  @override
  String get partnerFinancePendingSettlement => 'Pending settlement';

  @override
  String get partnerFinanceNextPayout => 'Next estimated payout';

  @override
  String partnerFinanceCompletedBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed bookings',
      one: '1 completed booking',
    );
    return '$_temp0';
  }

  @override
  String partnerFinancePaidBookings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count paid bookings',
      one: '1 paid booking',
    );
    return '$_temp0';
  }

  @override
  String partnerPropertiesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count properties',
      one: '1 property',
      zero: 'No properties',
    );
    return '$_temp0';
  }

  @override
  String get partnerPropertiesEmptyTitle => 'No properties yet';

  @override
  String get partnerPropertiesEmptyMessage =>
      'Your partner profile is approved, but no property has been assigned to it yet. Properties are assigned by the Plan Your Trip team.';

  @override
  String get partnerPropertiesSelectedSemantic => 'Selected property';

  @override
  String get partnerPropertyDetailHeading => 'Property details';

  @override
  String get partnerPropertyCloseDetail => 'Close details';

  @override
  String get partnerPropertyDetailNotFound =>
      'This property is no longer available to your account.';

  @override
  String get partnerPropertyActionsOwnerOnly =>
      'Listing actions are available to the profile owner. You can review every detail here.';

  @override
  String get partnerPropertyStatusDraft => 'Draft';

  @override
  String get partnerPropertyStatusPendingReview => 'Pending review';

  @override
  String get partnerPropertyStatusApproved => 'Approved';

  @override
  String get partnerPropertyStatusPublished => 'Published';

  @override
  String get partnerPropertyStatusHidden => 'Hidden';

  @override
  String get partnerPropertyStatusArchived => 'Archived';

  @override
  String get partnerPropertyStatusRejected => 'Rejected';

  @override
  String get partnerPropertyStatusUnknown => 'Unknown status';

  @override
  String get partnerPropertyActive => 'Listing on';

  @override
  String get partnerPropertyInactive => 'Listing off';

  @override
  String get partnerPropertyVerified => 'Verified';

  @override
  String get partnerPropertyNotVerified => 'Not verified';

  @override
  String get partnerPropertyFeatured => 'Featured';

  @override
  String get partnerPropertyNotFeatured => 'Not featured';

  @override
  String get partnerPropertyNotSet => 'Not set';

  @override
  String partnerPropertyRatingSummary(String rating, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$rating from $_temp0';
  }

  @override
  String get partnerPropertyVisibilityPublic =>
      'Guests can find and book this property now.';

  @override
  String get partnerPropertyVisibilityNotPublic =>
      'This property is not visible to guests right now.';

  @override
  String get partnerPropertyModerationNote =>
      'Verification and featuring are managed by the Plan Your Trip team and cannot be changed here.';

  @override
  String get partnerPropertyActivateAction => 'Turn listing on';

  @override
  String get partnerPropertyDeactivateAction => 'Turn listing off';

  @override
  String partnerPropertyActivatedMessage(String name) {
    return '$name is now listed.';
  }

  @override
  String partnerPropertyDeactivatedMessage(String name) {
    return '$name is no longer listed.';
  }

  @override
  String get partnerPropertyActionNotFound =>
      'That property is no longer available to your account.';

  @override
  String get partnerPropertyActionFailed =>
      'The change could not be saved. Nothing was altered.';

  @override
  String get partnerPropertyActionUncertain =>
      'The connection dropped before the server confirmed. Refresh to see the current state.';

  @override
  String get partnerPropertySectionIdentity => 'Identity';

  @override
  String get partnerPropertySectionLocation => 'Location';

  @override
  String get partnerPropertySectionContact => 'Contact';

  @override
  String get partnerPropertySectionPolicies => 'Policies';

  @override
  String get partnerPropertySectionVerification => 'Verification';

  @override
  String get partnerPropertySectionPerformance => 'Guest feedback';

  @override
  String get partnerPropertySectionMetadata => 'Record';

  @override
  String get partnerPropertyFieldSlug => 'URL slug';

  @override
  String get partnerPropertyFieldShortDescription => 'Short description';

  @override
  String get partnerPropertyFieldDescription => 'Description';

  @override
  String get partnerPropertyFieldAddress => 'Address';

  @override
  String get partnerPropertyFieldCoordinates => 'Coordinates';

  @override
  String get partnerPropertyFieldPhone => 'Phone';

  @override
  String get partnerPropertyFieldEmail => 'Email';

  @override
  String get partnerPropertyFieldWebsite => 'Website';

  @override
  String get partnerPropertyFieldFacebook => 'Facebook';

  @override
  String get partnerPropertyFieldInstagram => 'Instagram';

  @override
  String get partnerPropertyFieldCheckIn => 'Check-in from';

  @override
  String get partnerPropertyFieldCheckOut => 'Check-out by';

  @override
  String get partnerPropertyFieldChildrenPolicy => 'Children policy';

  @override
  String get partnerPropertyFieldPetPolicy => 'Pet policy';

  @override
  String get partnerPropertyFieldSmokingPolicy => 'Smoking policy';

  @override
  String get partnerPropertyFieldVerified => 'Verification status';

  @override
  String get partnerPropertyFieldFeatured => 'Featured placement';

  @override
  String get partnerPropertyFieldRating => 'Average rating';

  @override
  String get partnerPropertyFieldReviewCount => 'Reviews';

  @override
  String get partnerPropertyFieldOwner => 'Owned by';

  @override
  String get partnerPropertyFieldCreated => 'Created';

  @override
  String get partnerPropertyFieldUpdated => 'Last updated';

  @override
  String partnerRoomsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count room types',
      one: '1 room type',
    );
    return '$_temp0';
  }

  @override
  String partnerRoomsListedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count listed',
      one: '1 listed',
    );
    return '$_temp0';
  }

  @override
  String partnerRoomsSoldOutCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sold out',
      one: '1 sold out',
    );
    return '$_temp0';
  }

  @override
  String partnerRoomsForProperty(String name) {
    return 'Rooms at $name';
  }

  @override
  String get partnerRoomsNoPropertyContext => 'No property selected';

  @override
  String get partnerRoomsPropertyScope => 'Property scope';

  @override
  String get partnerRoomsSelectPropertyTitle => 'Choose a property';

  @override
  String get partnerRoomsSelectPropertyMessage =>
      'Rooms belong to a specific property, so pick one to see its room types.';

  @override
  String get partnerRoomsNoPropertiesTitle => 'No properties yet';

  @override
  String get partnerRoomsNoPropertiesMessage =>
      'Rooms live inside a property. Once a property is assigned to your profile, its room types appear here.';

  @override
  String get partnerRoomsPropertyUnavailableTitle => 'Property unavailable';

  @override
  String get partnerRoomsPropertyUnavailableMessage =>
      'This property is no longer available to your account, or it has no room configuration yet.';

  @override
  String get partnerRoomsEmptyTitle => 'No room types yet';

  @override
  String get partnerRoomsEmptyMessage =>
      'This property has no room types configured. They are set up by the Plan Your Trip team.';

  @override
  String get partnerRoomActionsOwnerOnly =>
      'Listing actions are available to the profile owner. You can review every room here.';

  @override
  String get partnerRoomDetailHeading => 'Room details';

  @override
  String get partnerRoomCloseDetail => 'Close room details';

  @override
  String get partnerRoomDetailNotFound =>
      'This room is no longer available to your account.';

  @override
  String get partnerRoomListed => 'Listed';

  @override
  String get partnerRoomUnlisted => 'Not listed';

  @override
  String get partnerRoomSoldOut => 'Sold out';

  @override
  String get partnerRoomListAction => 'List this room';

  @override
  String get partnerRoomUnlistAction => 'Stop listing';

  @override
  String partnerRoomListedMessage(String name) {
    return '$name is now listed.';
  }

  @override
  String partnerRoomUnlistedMessage(String name) {
    return '$name is no longer listed.';
  }

  @override
  String get partnerRoomActionNotFound =>
      'That room is no longer available to your account.';

  @override
  String get partnerRoomYes => 'Yes';

  @override
  String get partnerRoomNo => 'No';

  @override
  String partnerRoomGuestsValue(String count) {
    return 'Up to $count guests';
  }

  @override
  String partnerRoomInventoryValue(String available, String total) {
    return '$available of $total available';
  }

  @override
  String partnerRoomPriceFromValue(String price) {
    return 'From $price';
  }

  @override
  String partnerRoomSizeValue(String size) {
    return '$size m²';
  }

  @override
  String get partnerRoomSectionIdentity => 'Identity';

  @override
  String get partnerRoomSectionBeds => 'Beds';

  @override
  String get partnerRoomSectionCapacity => 'Capacity';

  @override
  String get partnerRoomSectionInventory => 'Inventory';

  @override
  String get partnerRoomSectionPricing => 'Price';

  @override
  String get partnerRoomSectionConditions => 'Booking conditions';

  @override
  String get partnerRoomSectionAmenities => 'Amenities';

  @override
  String get partnerRoomSectionMedia => 'Media';

  @override
  String get partnerRoomFieldCode => 'Room code';

  @override
  String get partnerRoomFieldType => 'Room type';

  @override
  String get partnerRoomFieldDescription => 'Description';

  @override
  String get partnerRoomFieldBedType => 'Bed type';

  @override
  String get partnerRoomFieldBedCount => 'Number of beds';

  @override
  String get partnerRoomFieldMaxGuests => 'Maximum guests';

  @override
  String get partnerRoomFieldMaxAdults => 'Maximum adults';

  @override
  String get partnerRoomFieldMaxChildren => 'Maximum children';

  @override
  String get partnerRoomFieldSize => 'Room size';

  @override
  String get partnerRoomFieldFloor => 'Floor';

  @override
  String get partnerRoomFieldQuantity => 'Total rooms';

  @override
  String get partnerRoomFieldAvailable => 'Currently available';

  @override
  String get partnerRoomFieldPriceFrom => 'Price from';

  @override
  String get partnerRoomFieldOriginalPrice => 'Original price';

  @override
  String get partnerRoomFieldBreakfast => 'Breakfast included';

  @override
  String get partnerRoomFieldFreeCancellation => 'Free cancellation';

  @override
  String get partnerRoomFieldInstantConfirmation => 'Instant confirmation';

  @override
  String get partnerRoomFieldSmoking => 'Smoking allowed';

  @override
  String get partnerRoomFieldImages => 'Gallery images';

  @override
  String get partnerRoomTypeStandard => 'Standard';

  @override
  String get partnerRoomTypeSuperior => 'Superior';

  @override
  String get partnerRoomTypeDeluxe => 'Deluxe';

  @override
  String get partnerRoomTypePremier => 'Premier';

  @override
  String get partnerRoomTypeExecutive => 'Executive';

  @override
  String get partnerRoomTypeSuite => 'Suite';

  @override
  String get partnerRoomTypeFamily => 'Family';

  @override
  String get partnerRoomTypeVilla => 'Villa';

  @override
  String get partnerRoomTypeBungalow => 'Bungalow';

  @override
  String get partnerRoomTypeUnknown => 'Unrecognised type';

  @override
  String get partnerBedTypeSingle => 'Single';

  @override
  String get partnerBedTypeDouble => 'Double';

  @override
  String get partnerBedTypeTwin => 'Twin';

  @override
  String get partnerBedTypeQueen => 'Queen';

  @override
  String get partnerBedTypeKing => 'King';

  @override
  String get partnerBedTypeSofaBed => 'Sofa bed';

  @override
  String get partnerBedTypeBunk => 'Bunk bed';

  @override
  String get partnerBedTypeUnknown => 'Unrecognised bed';

  @override
  String partnerInventoryForProperty(String name) {
    return 'Inventory at $name';
  }

  @override
  String get partnerInventoryNoPropertyContext => 'No property selected';

  @override
  String get partnerInventoryPropertyScope => 'Property scope';

  @override
  String get partnerInventoryRoomScope => 'Room type';

  @override
  String get partnerInventoryRangeLabel => 'Window';

  @override
  String get partnerInventoryRangeWeek => '7 days';

  @override
  String get partnerInventoryRangeFortnight => '14 days';

  @override
  String get partnerInventoryRangeMonth => '30 days';

  @override
  String partnerInventoryWindow(String from, String to, int count) {
    return '$from – $to · $count days';
  }

  @override
  String partnerInventoryBookableDays(int bookable, int total) {
    return '$bookable of $total days bookable';
  }

  @override
  String partnerInventoryTotalAvailable(String count) {
    return '$count room-nights available';
  }

  @override
  String partnerInventoryStopSellDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days stopped',
      one: '1 day stopped',
    );
    return '$_temp0';
  }

  @override
  String get partnerInventoryNoPropertiesTitle => 'No properties yet';

  @override
  String get partnerInventoryNoPropertiesMessage =>
      'Inventory belongs to a room in a property. Once a property is assigned to your profile, its calendar appears here.';

  @override
  String get partnerInventorySelectPropertyTitle => 'Choose a property';

  @override
  String get partnerInventorySelectPropertyMessage =>
      'Pick a property to see the inventory calendar for its room types.';

  @override
  String get partnerInventoryNoRoomsTitle => 'No room types yet';

  @override
  String get partnerInventoryNoRoomsMessage =>
      'This property has no room types, so there is no inventory to manage.';

  @override
  String get partnerInventorySelectRoomTitle => 'Choose a room type';

  @override
  String get partnerInventorySelectRoomMessage =>
      'Inventory is kept per room type. Pick one to see its calendar.';

  @override
  String get partnerInventoryInvalidRangeTitle => 'Invalid date range';

  @override
  String get partnerInventoryInvalidRangeMessage =>
      'The start date must not be after the end date.';

  @override
  String get partnerInventoryUnavailableTitle => 'Inventory unavailable';

  @override
  String get partnerInventoryUnavailableMessage =>
      'This property or room type is no longer available to your account.';

  @override
  String get partnerInventoryEmptyTitle => 'No inventory in this window';

  @override
  String get partnerInventoryEmptyMessage =>
      'No inventory rows have been set up for these dates. Try a different window.';

  @override
  String get partnerInventoryDate => 'Date';

  @override
  String get partnerInventoryStateColumn => 'Status';

  @override
  String get partnerInventoryTotal => 'Total';

  @override
  String get partnerInventoryAvailable => 'Available';

  @override
  String get partnerInventorySold => 'Sold';

  @override
  String get partnerInventoryBlocked => 'Blocked';

  @override
  String get partnerInventoryMaintenance => 'Maintenance';

  @override
  String get partnerInventoryRestrictions => 'Restrictions';

  @override
  String get partnerInventoryStopSell => 'Stop sell';

  @override
  String get partnerInventoryClosedArrival => 'No arrivals';

  @override
  String get partnerInventoryClosedDeparture => 'No departures';

  @override
  String get partnerInventoryStateBookable => 'Bookable';

  @override
  String get partnerInventoryStateSoldOut => 'Sold out';

  @override
  String get partnerInventoryStateStopped => 'Stopped';

  @override
  String get partnerInventoryInconsistent =>
      'These numbers do not add up to the total.';

  @override
  String partnerInventoryInconsistentSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days have counts that do not add up to their total',
      one: '1 day has counts that do not add up to its total',
    );
    return '$_temp0. Only the backend can correct this.';
  }

  @override
  String get partnerInventoryEditOwnerOnly =>
      'Changing availability is available to the profile owner. You can review the calendar here.';

  @override
  String get partnerInventorySaved => 'Saved.';

  @override
  String get partnerInventoryActionNotFound =>
      'That date is no longer available to your account.';

  @override
  String partnerRatesForProperty(String name) {
    return 'Rates at $name';
  }

  @override
  String partnerRatesForRoom(String room, String property) {
    return 'Rates for $room at $property';
  }

  @override
  String get partnerRatesNoPropertyContext => 'No property selected';

  @override
  String get partnerRatesPropertyScope => 'Property scope';

  @override
  String get partnerRatesRoomScope => 'Room type';

  @override
  String partnerRatesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rate plans',
      one: '1 rate plan',
    );
    return '$_temp0';
  }

  @override
  String partnerRatesActiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active',
      one: '1 active',
    );
    return '$_temp0';
  }

  @override
  String partnerRatesExpiredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expired',
      one: '1 expired',
    );
    return '$_temp0';
  }

  @override
  String get partnerRatesNoPropertiesTitle => 'No properties yet';

  @override
  String get partnerRatesNoPropertiesMessage =>
      'Rates belong to a room in a property. Once a property is assigned to your profile, its rate plans appear here.';

  @override
  String get partnerRatesSelectPropertyTitle => 'Choose a property';

  @override
  String get partnerRatesSelectPropertyMessage =>
      'Pick a property to see the rate plans for its room types.';

  @override
  String get partnerRatesNoRoomsTitle => 'No room types yet';

  @override
  String get partnerRatesNoRoomsMessage =>
      'This property has no room types, so there is nothing to price.';

  @override
  String get partnerRatesSelectRoomTitle => 'Choose a room type';

  @override
  String get partnerRatesSelectRoomMessage =>
      'Rate plans are kept per room type. Pick one to see its rates.';

  @override
  String get partnerRatesUnavailableTitle => 'Rates unavailable';

  @override
  String get partnerRatesUnavailableMessage =>
      'This property or room type is no longer available to your account.';

  @override
  String get partnerRatesEmptyTitle => 'No rate plans yet';

  @override
  String get partnerRatesEmptyMessage =>
      'This room type has no rate plans. They are set up by the Plan Your Trip team.';

  @override
  String get partnerRateDetailHeading => 'Rate plan details';

  @override
  String get partnerRateCloseDetail => 'Close rate plan details';

  @override
  String get partnerRateActionsOwnerOnly =>
      'Rate actions are available to the profile owner. You can review every plan here.';

  @override
  String get partnerRateCurrencyNote =>
      'Amounts are shown without a currency because the rate API does not supply one.';

  @override
  String get partnerRateValidityNote =>
      'Both dates are inclusive: a stay qualifies when every night falls inside this window.';

  @override
  String get partnerRateActive => 'Active';

  @override
  String get partnerRateInactive => 'Inactive';

  @override
  String get partnerRateExpired => 'Expired';

  @override
  String partnerRatePerNight(String amount) {
    return '$amount per night';
  }

  @override
  String partnerRateValidity(String from, String to) {
    return '$from – $to';
  }

  @override
  String partnerRatePriorityValue(String value) {
    return 'Priority $value';
  }

  @override
  String get partnerRateHasRestrictions => 'Has restrictions';

  @override
  String partnerRateNightsValue(String count) {
    return '$count nights';
  }

  @override
  String partnerRateDaysValue(String count) {
    return '$count days';
  }

  @override
  String get partnerRateActivateAction => 'Activate';

  @override
  String get partnerRateDeactivateAction => 'Deactivate';

  @override
  String partnerRateActivatedMessage(String name) {
    return '$name is now active.';
  }

  @override
  String partnerRateDeactivatedMessage(String name) {
    return '$name is now inactive.';
  }

  @override
  String get partnerRateActionNotFound =>
      'That rate plan is no longer available to your account.';

  @override
  String get partnerRateActionConflict =>
      'That change conflicts with another rate plan.';

  @override
  String get partnerRateTypeStandard => 'Standard';

  @override
  String get partnerRateTypePromotional => 'Promotional';

  @override
  String get partnerRateTypeMember => 'Member';

  @override
  String get partnerRateTypeEarlyBird => 'Early bird';

  @override
  String get partnerRateTypeLastMinute => 'Last minute';

  @override
  String get partnerRateTypeUnknown => 'Unrecognised type';

  @override
  String get partnerMealPlanRoomOnly => 'Room only';

  @override
  String get partnerMealPlanBreakfast => 'Breakfast';

  @override
  String get partnerMealPlanHalfBoard => 'Half board';

  @override
  String get partnerMealPlanFullBoard => 'Full board';

  @override
  String get partnerMealPlanAllInclusive => 'All inclusive';

  @override
  String get partnerMealPlanUnknown => 'Unrecognised meal plan';

  @override
  String get partnerCancellationFree => 'Free cancellation';

  @override
  String get partnerCancellationPartial => 'Partially refundable';

  @override
  String get partnerCancellationNonRefundable => 'Non-refundable';

  @override
  String get partnerCancellationCustom => 'Custom policy';

  @override
  String get partnerCancellationUnknown => 'Unrecognised policy';

  @override
  String get partnerRateSourceBase => 'Base rate';

  @override
  String get partnerRateSourceDerived => 'Derived rate';

  @override
  String get partnerRateSourceUnknown => 'Unrecognised source';

  @override
  String get partnerRateAdjustmentFixed => 'Fixed amount';

  @override
  String get partnerRateAdjustmentPercent => 'Percentage';

  @override
  String get partnerRateAdjustmentUnknown => 'Unrecognised adjustment';

  @override
  String get partnerRateSectionIdentity => 'Identity';

  @override
  String get partnerRateSectionPricing => 'Price';

  @override
  String get partnerRateSectionValidity => 'Validity';

  @override
  String get partnerRateSectionRestrictions => 'Stay restrictions';

  @override
  String get partnerRateSectionCancellation => 'Cancellation';

  @override
  String get partnerRateSectionInclusions => 'Inclusions';

  @override
  String get partnerRateSectionOccupancy => 'Occupancy prices';

  @override
  String get partnerRateFieldCode => 'Plan code';

  @override
  String get partnerRateFieldDescription => 'Description';

  @override
  String get partnerRateFieldPriority => 'Priority';

  @override
  String get partnerRateFieldPricePerNight => 'Price per night';

  @override
  String get partnerRateFieldExtraBedPrice => 'Extra bed price';

  @override
  String get partnerRateFieldAdjustmentType => 'Adjustment type';

  @override
  String get partnerRateFieldAdjustmentValue => 'Adjustment';

  @override
  String get partnerRateFieldParentPlan => 'Derived from plan';

  @override
  String get partnerRateFieldValidFrom => 'Valid from';

  @override
  String get partnerRateFieldValidTo => 'Valid to';

  @override
  String get partnerRateFieldMinStay => 'Minimum stay';

  @override
  String get partnerRateFieldMaxStay => 'Maximum stay';

  @override
  String get partnerRateFieldMinAdvance => 'Minimum advance booking';

  @override
  String get partnerRateFieldMaxAdvance => 'Maximum advance booking';

  @override
  String get partnerRateFieldClosedToArrival => 'Closed to arrival';

  @override
  String get partnerRateFieldClosedToDeparture => 'Closed to departure';

  @override
  String get partnerRateFieldPolicy => 'Cancellation policy';

  @override
  String get partnerRateFieldRefundable => 'Refundable';

  @override
  String get partnerRateFieldDeadlineHours => 'Cancellation deadline (hours)';

  @override
  String get partnerRateFieldPenaltyPercent => 'Cancellation penalty';

  @override
  String get partnerRateFieldMealPlan => 'Meal plan';

  @override
  String get partnerRateFieldOccupancyPricing => 'Occupancy pricing enabled';

  @override
  String get partnerRateFieldChildPricing => 'Child pricing enabled';

  @override
  String get partnerRateOccupancyEmpty =>
      'No occupancy prices are configured for this plan.';

  @override
  String partnerRateOccupancyLabel(String adults, String children) {
    return '$adults adults, $children children';
  }

  @override
  String get partnerPoliciesTitle => 'Policies & settings';

  @override
  String partnerPoliciesForProperty(String name) {
    return 'Policies for $name';
  }

  @override
  String get partnerPoliciesNoPropertyContext => 'No property selected';

  @override
  String get partnerPoliciesPropertyScope => 'Property scope';

  @override
  String get partnerPoliciesNoPropertiesTitle => 'No properties yet';

  @override
  String get partnerPoliciesNoPropertiesMessage =>
      'Guest policies belong to a property. Once a property is assigned to your profile, its policies appear here.';

  @override
  String get partnerPoliciesSelectPropertyTitle => 'Choose a property';

  @override
  String get partnerPoliciesSelectPropertyMessage =>
      'Pick a property to review and edit its guest policies.';

  @override
  String get partnerPoliciesUnavailableTitle => 'Policies unavailable';

  @override
  String get partnerPoliciesUnavailableMessage =>
      'This property is no longer available to your account.';

  @override
  String get partnerPoliciesPropertySection => 'Guest policies';

  @override
  String get partnerPoliciesPropertyScopeNote =>
      'Applies to this property only. Guests see these on the listing.';

  @override
  String get partnerPoliciesLiveWarning =>
      'These take effect immediately for every guest, including guests who already hold a booking — the platform does not freeze policies at booking time.';

  @override
  String get partnerPoliciesOwnerOnly =>
      'Guest policies can be changed by the profile owner. You can review them here.';

  @override
  String get partnerPoliciesCheckIn => 'Check-in from';

  @override
  String get partnerPoliciesCheckOut => 'Check-out by';

  @override
  String get partnerPoliciesTimeHelper => '24-hour time, for example 14:00';

  @override
  String get partnerPoliciesTimeRequired => 'Required';

  @override
  String get partnerPoliciesHouseRules => 'House rules';

  @override
  String get partnerPoliciesHouseRulesNote =>
      'Optional. Leave a rule empty to remove it.';

  @override
  String get partnerPoliciesRuleHint => 'Leave empty for no rule';

  @override
  String get partnerPoliciesChildren => 'Children policy';

  @override
  String get partnerPoliciesPets => 'Pet policy';

  @override
  String get partnerPoliciesSmoking => 'Smoking policy';

  @override
  String get partnerPoliciesSettingsSection => 'Workspace notifications';

  @override
  String get partnerPoliciesSettingsScopeNote =>
      'Applies to your whole partner account, not to one property.';

  @override
  String get partnerPoliciesSettingsRoleNote =>
      'Notification settings can be changed by an owner or manager. You can review them here.';

  @override
  String get partnerPoliciesSettingsUnavailable =>
      'Your workspace settings are not available.';

  @override
  String partnerPoliciesSettingsUpdated(String time) {
    return 'Last updated $time';
  }

  @override
  String get partnerPoliciesLanguage => 'Default language';

  @override
  String get partnerPoliciesTimezone => 'Timezone';

  @override
  String get partnerPoliciesChannels => 'Delivery channels';

  @override
  String get partnerPoliciesChannelEmail => 'Email';

  @override
  String get partnerPoliciesChannelSms => 'SMS';

  @override
  String get partnerPoliciesChannelInApp => 'In-app';

  @override
  String get partnerPoliciesTopics => 'What to notify me about';

  @override
  String get partnerPoliciesTopicBooking => 'Bookings';

  @override
  String get partnerPoliciesTopicPayment => 'Payments';

  @override
  String get partnerPoliciesTopicReview => 'Reviews';

  @override
  String get partnerPoliciesTopicPromotion => 'Promotions';

  @override
  String get partnerPoliciesSave => 'Save changes';

  @override
  String get partnerPoliciesRevert => 'Discard';

  @override
  String get partnerPoliciesNoChanges => 'No unsaved changes.';

  @override
  String get partnerPoliciesSaved => 'Saved.';

  @override
  String get partnerPoliciesSaveForbidden =>
      'Your role does not allow this change.';

  @override
  String get partnerPoliciesSaveNotFound =>
      'That record is no longer available to your account.';

  @override
  String get partnerPoliciesSaveValidation =>
      'Check-in and check-out times are both required.';

  @override
  String get partnerAssetsSection => 'Photos & media';

  @override
  String get partnerAssetsDeferredBadge => 'Not available';

  @override
  String get partnerAssetsDeferredMessage =>
      'Photo management is not part of the partner API. Uploading, replacing, reordering and deleting media are admin-only operations, so the Plan Your Trip team maintains your listing images for now.';

  @override
  String get partnerPromotionsTitle => 'Promotions & vouchers';

  @override
  String get partnerPromotionsTabPromotions => 'Promotion rules';

  @override
  String get partnerPromotionsTabVoucherCheck => 'Voucher check';

  @override
  String get partnerPromotionsScopeNote =>
      'Every promotion on any property or room you own is listed here. The partner API does not narrow promotions to one property, so this list is not filtered by your selected property.';

  @override
  String partnerPromotionsCount(int count) {
    return '$count promotions';
  }

  @override
  String partnerPromotionsActiveCount(int count) {
    return '$count active';
  }

  @override
  String partnerPromotionsExpiredCount(int count) {
    return '$count past their end date';
  }

  @override
  String get partnerPromotionsCurrencyNote =>
      'The promotion API sends no currency, so promotion amounts appear without a symbol. The pricing preview below carries its own currency and shows it.';

  @override
  String get partnerPromotionsEmptyTitle => 'No promotions yet';

  @override
  String get partnerPromotionsEmptyMessage =>
      'Nothing currently targets your properties or rooms. Site-wide campaigns run by Plan Your Trip are not shown here because they are not yours to manage.';

  @override
  String get partnerPromotionsOwnerOnly =>
      'Only the partner account owner can change promotions. You can read them here.';

  @override
  String get partnerPromotionDetailHeading => 'Promotion details';

  @override
  String get partnerPromotionCloseDetail => 'Close promotion details';

  @override
  String get partnerPromotionSectionIdentity => 'Identity';

  @override
  String get partnerPromotionFieldCode => 'Promotion code';

  @override
  String get partnerPromotionFieldDescription => 'Description';

  @override
  String get partnerPromotionFieldType => 'Promotion type';

  @override
  String get partnerPromotionSectionDiscount => 'Discount';

  @override
  String get partnerPromotionFieldDiscountType => 'Discount type';

  @override
  String get partnerPromotionFieldDiscountValue => 'Discount value';

  @override
  String get partnerPromotionFieldMaxDiscount => 'Maximum discount';

  @override
  String get partnerPromotionSectionValidity => 'Validity';

  @override
  String get partnerPromotionFieldStart => 'Starts';

  @override
  String get partnerPromotionFieldEnd => 'Ends';

  @override
  String get partnerPromotionSectionConditions => 'Conditions';

  @override
  String get partnerPromotionFieldMinimumStay => 'Minimum stay';

  @override
  String get partnerPromotionFieldMinimumSpend => 'Minimum spend';

  @override
  String get partnerPromotionSectionApplication => 'How it applies';

  @override
  String get partnerPromotionFieldTarget => 'Applies to';

  @override
  String get partnerPromotionFieldPriority => 'Priority';

  @override
  String get partnerPromotionFieldStackable => 'Combines with others';

  @override
  String get partnerPromotionStackableNote =>
      'The pricing engine may add further promotions after this one.';

  @override
  String get partnerPromotionNonStackableNote =>
      'The pricing engine applies this promotion and then stops, so no lower-priority promotion is added after it.';

  @override
  String get partnerPromotionActive => 'Active';

  @override
  String get partnerPromotionInactive => 'Inactive';

  @override
  String get partnerPromotionExpired => 'Past end date';

  @override
  String get partnerPromotionScheduled => 'Starts later';

  @override
  String get partnerPromotionExclusivePill => 'Does not combine';

  @override
  String partnerPromotionValidity(String from, String to) {
    return '$from – $to';
  }

  @override
  String partnerPromotionPriorityValue(String count) {
    return 'Priority $count';
  }

  @override
  String get partnerPromotionHasConditions => 'Has conditions';

  @override
  String get partnerPromotionActivateAction => 'Activate';

  @override
  String get partnerPromotionDeactivateAction => 'Deactivate';

  @override
  String get partnerPromotionTypeGeneral => 'General';

  @override
  String get partnerPromotionTypeRoom => 'Room offer';

  @override
  String get partnerPromotionTypeHotel => 'Property offer';

  @override
  String get partnerPromotionTypeMember => 'Member';

  @override
  String get partnerPromotionTypeEarlyBird => 'Early bird';

  @override
  String get partnerPromotionTypeLastMinute => 'Last minute';

  @override
  String get partnerPromotionTypeWeekend => 'Weekend';

  @override
  String get partnerPromotionTypeHoliday => 'Holiday';

  @override
  String get partnerPromotionTypeUnknown => 'Unrecognised type';

  @override
  String get partnerDiscountTypePercentage => 'Percentage';

  @override
  String get partnerDiscountTypeFixed => 'Fixed amount';

  @override
  String get partnerDiscountTypeUnknown => 'Unrecognised discount';

  @override
  String get partnerPromotionTargetAll => 'Every property on Plan Your Trip';

  @override
  String get partnerPromotionTargetHotel => 'One of your properties';

  @override
  String get partnerPromotionTargetRoom => 'One of your rooms';

  @override
  String partnerPromotionTargetRoomNamed(String name) {
    return 'Room: $name';
  }

  @override
  String get partnerPromotionTargetUnknown => 'Unrecognised target';

  @override
  String get partnerPromotionPreviewHeading => 'Pricing preview';

  @override
  String get partnerPromotionPreviewNote =>
      'The backend calculates this. Every amount and every applied promotion comes straight from the pricing engine — nothing is worked out in the app.';

  @override
  String get partnerPromotionPreviewAction => 'Run preview';

  @override
  String get partnerPromotionPreviewInvalidRange =>
      'Check-out must be after check-in.';

  @override
  String partnerPromotionPreviewStay(String from, String to, String nights) {
    return '$from to $to · $nights nights';
  }

  @override
  String get partnerPromotionPreviewBase => 'Base price';

  @override
  String get partnerPromotionPreviewRatePlan => 'Rate plan price';

  @override
  String partnerPromotionPreviewRatePlanNamed(String name) {
    return 'Rate plan: $name';
  }

  @override
  String get partnerPromotionPreviewDiscount => 'Promotion discount';

  @override
  String get partnerPromotionPreviewTotal => 'Total for this stay';

  @override
  String get partnerPromotionPreviewAppliedHeading =>
      'Promotions the engine applied';

  @override
  String get partnerPromotionPreviewNoneApplied =>
      'The engine applied no promotion to this stay.';

  @override
  String get partnerPromotionPreviewUnnamed => 'Unnamed promotion';

  @override
  String partnerPromotionPreviewAppliedAmount(String amount) {
    return '-$amount';
  }

  @override
  String partnerPromotionActivatedMessage(String name) {
    return '$name is now active.';
  }

  @override
  String partnerPromotionDeactivatedMessage(String name) {
    return '$name is now inactive.';
  }

  @override
  String get partnerPromotionActionNotFound =>
      'That promotion is no longer available to your account.';

  @override
  String get partnerPromotionActionConflict =>
      'That promotion code is already in use. Promotion codes are unique across Plan Your Trip.';

  @override
  String get partnerPromotionActionValidation =>
      'The server rejected the promotion. Nothing was changed.';

  @override
  String get partnerPromotionActionIncomplete =>
      'This promotion is missing fields the update needs, so nothing was sent. Ask support to change it.';

  @override
  String get partnerVoucherCheckHeading => 'Check a booking voucher';

  @override
  String get partnerVoucherCheckNote =>
      'This is a booking pass, not a discount code. Checking it confirms a guest\'s booking — it does not check anyone in and changes nothing.';

  @override
  String get partnerVoucherCheckField => 'Voucher payload';

  @override
  String get partnerVoucherCheckAction => 'Check voucher';

  @override
  String get partnerVoucherCheckClear => 'Clear';

  @override
  String get partnerVoucherEligibleTitle => 'Valid — the guest can be admitted';

  @override
  String get partnerVoucherEligibleMessage =>
      'The signature is valid and this booking is ready for check-in.';

  @override
  String get partnerVoucherNotEligibleTitle =>
      'Valid — but not ready for check-in';

  @override
  String get partnerVoucherNotEligibleMessage =>
      'The signature is valid, but this booking cannot be checked in right now.';

  @override
  String get partnerVoucherNotRecognisedTitle => 'Not recognised';

  @override
  String get partnerVoucherNotRecognisedMessage =>
      'The server does not recognise this voucher for your account. It may have been altered, may not exist, or may belong to another partner — the server does not say which.';

  @override
  String get partnerVoucherEmptyTitle => 'Nothing to check';

  @override
  String get partnerVoucherEmptyMessage =>
      'Paste or scan a voucher payload first.';

  @override
  String get partnerVoucherFailedTitle => 'Could not check this voucher';

  @override
  String get partnerVoucherFieldBooking => 'Booking code';

  @override
  String get partnerVoucherFieldBookingStatus => 'Booking status';

  @override
  String get partnerVoucherFieldGuest => 'Guest name';

  @override
  String get partnerVoucherFieldProperty => 'Booked property';

  @override
  String get partnerVoucherFieldRoom => 'Booked room';

  @override
  String get partnerVoucherFieldStay => 'Stay';

  @override
  String get partnerVoucherFieldOccupancy => 'Occupancy';

  @override
  String partnerVoucherStayValue(String from, String to, String nights) {
    return '$from to $to · $nights nights';
  }

  @override
  String partnerVoucherOccupancyValue(String adults, String children) {
    return '$adults adults · $children children';
  }

  @override
  String get partnerVoucherReadOnlyNote =>
      'Checking only. Check-in itself happens on the booking, not on this screen.';

  @override
  String get partnerBookingsTitle => 'Bookings & front desk';

  @override
  String get partnerBookingsTabReservations => 'Reservations';

  @override
  String get partnerBookingsTabFrontDesk => 'Front desk';

  @override
  String get partnerBookingsScopeNote =>
      'This list covers every booking across all properties you own. The partner API accepts no property parameter, so it is not narrowed by your selected property — filter by room to focus on one property.';

  @override
  String get partnerBookingsEmptyTitle => 'No bookings yet';

  @override
  String get partnerBookingsEmptyMessage =>
      'Nothing has been booked at your properties yet. New reservations appear here as soon as guests make them.';

  @override
  String get partnerBookingsNoMatchTitle => 'No bookings match these filters';

  @override
  String get partnerBookingsNoMatchMessage =>
      'Nothing matched the filters you set. Clear them to see every booking again.';

  @override
  String get partnerBookingDetailHeading => 'Booking details';

  @override
  String get partnerBookingCloseDetail => 'Close booking details';

  @override
  String get partnerBookingNotFound =>
      'That booking is no longer available to your account.';

  @override
  String get partnerBookingColumnCode => 'Booking code';

  @override
  String get partnerBookingColumnGuest => 'Guest';

  @override
  String get partnerBookingColumnRoom => 'Room';

  @override
  String get partnerBookingColumnCheckIn => 'Check-in';

  @override
  String get partnerBookingColumnCheckOut => 'Check-out';

  @override
  String get partnerBookingColumnNights => 'Nights';

  @override
  String get partnerBookingColumnStatus => 'Status';

  @override
  String get partnerBookingColumnTotal => 'Total';

  @override
  String partnerBookingStayRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String partnerBookingNightsValue(String count) {
    return '$count nights';
  }

  @override
  String partnerBookingOccupancyValue(String adults, String children) {
    return '$adults adults · $children children';
  }

  @override
  String partnerBookingNightProgressValue(String current, String total) {
    return 'Night $current of $total';
  }

  @override
  String get partnerBookingStatusPending => 'Pending';

  @override
  String get partnerBookingStatusConfirmed => 'Confirmed';

  @override
  String get partnerBookingStatusCheckInReady => 'Ready to check in';

  @override
  String get partnerBookingStatusCheckedIn => 'Checked in';

  @override
  String get partnerBookingStatusCheckedOut => 'Checked out';

  @override
  String get partnerBookingStatusCompleted => 'Completed';

  @override
  String get partnerBookingStatusCancelled => 'Cancelled';

  @override
  String get partnerBookingStatusRefunded => 'Refunded';

  @override
  String get partnerBookingStatusArchived => 'Archived';

  @override
  String get partnerBookingStatusNoShow => 'No-show';

  @override
  String get partnerBookingStatusUnknown => 'Unrecognised status';

  @override
  String get partnerStayStateUpcoming => 'Upcoming stay';

  @override
  String get partnerStayStateReady => 'Ready for check-in';

  @override
  String get partnerStayStateInHouse => 'In house';

  @override
  String get partnerStayStateCheckedOut => 'Departed';

  @override
  String get partnerStayStateCompleted => 'Stay completed';

  @override
  String get partnerStayStateCancelled => 'Stay cancelled';

  @override
  String get partnerStayStateNoShow => 'Guest did not arrive';

  @override
  String get partnerStayStateExpired => 'Window passed';

  @override
  String get partnerStayStateUnknown => 'Unrecognised stay state';

  @override
  String get partnerStayWarningCancelled =>
      'This stay was cancelled, refunded, or recorded as a no-show.';

  @override
  String get partnerStayWarningCompleted => 'This stay is finished.';

  @override
  String get partnerStayWarningInHouse => 'The guest is currently staying.';

  @override
  String get partnerStayWarningCheckOutOverdue =>
      'Check-out is overdue — the departure date has passed and the guest is still checked in.';

  @override
  String get partnerStayWarningFuture => 'The stay has not started yet.';

  @override
  String get partnerStayWarningCheckInOverdue =>
      'Check-in is overdue — the arrival date has passed and the guest is not checked in.';

  @override
  String get partnerStayWarningUnknown =>
      'The server reported a warning this app does not recognise.';

  @override
  String get partnerBookingFilterGuest => 'Guest name or email';

  @override
  String get partnerBookingFilterCode => 'Booking code';

  @override
  String get partnerBookingFilterStatus => 'Booking status';

  @override
  String get partnerBookingFilterAnyStatus => 'Any status';

  @override
  String get partnerBookingFilterRoom => 'Room';

  @override
  String get partnerBookingFilterAnyRoom => 'Any room';

  @override
  String get partnerBookingFilterDates => 'Arrival dates';

  @override
  String get partnerBookingFilterClear => 'Clear filters';

  @override
  String get partnerBookingFilterArrivals => 'Arriving today';

  @override
  String get partnerBookingFilterDepartures => 'Departing today';

  @override
  String get partnerBookingFilterUpcoming => 'Upcoming';

  @override
  String get partnerBookingFilterInHouse => 'In house';

  @override
  String get partnerBookingFilterCancelled => 'Cancelled';

  @override
  String get partnerBookingFilterCompleted => 'Completed';

  @override
  String partnerBookingFilterRangeBoth(String from, String to) {
    return 'Arriving $from to $to';
  }

  @override
  String partnerBookingFilterRangeFrom(String from) {
    return 'Arriving on or after $from';
  }

  @override
  String partnerBookingFilterRangeTo(String to) {
    return 'Arriving on or before $to';
  }

  @override
  String partnerBookingPageRange(String from, String to, String total) {
    return 'Showing $from-$to of $total';
  }

  @override
  String partnerBookingPagePosition(String page, String total) {
    return 'Page $page of $total';
  }

  @override
  String get partnerBookingPagePrevious => 'Previous page';

  @override
  String get partnerBookingPageNext => 'Next page';

  @override
  String get partnerBookingSectionGuest => 'Guest';

  @override
  String get partnerBookingSectionStay => 'Stay';

  @override
  String get partnerBookingSectionRoom => 'Property & room';

  @override
  String get partnerBookingSectionPrice => 'Price';

  @override
  String get partnerBookingSectionRatePlan => 'Rate plan captured at booking';

  @override
  String get partnerBookingSectionPayment => 'Payment & invoice';

  @override
  String get partnerBookingSectionTimeline => 'Lifecycle timeline';

  @override
  String get partnerBookingSectionModifications => 'Change history';

  @override
  String get partnerBookingSectionAudit => 'Check-in & check-out record';

  @override
  String get partnerBookingFieldGuestName => 'Guest name';

  @override
  String get partnerBookingFieldGuestEmail => 'Guest email';

  @override
  String get partnerBookingFieldOccupancy => 'Occupancy';

  @override
  String get partnerBookingFieldSpecialRequest => 'Special request';

  @override
  String get partnerBookingFieldCheckIn => 'Check-in date';

  @override
  String get partnerBookingFieldCheckOut => 'Check-out date';

  @override
  String get partnerBookingFieldNights => 'Nights booked';

  @override
  String get partnerBookingFieldNightProgress => 'Stay progress';

  @override
  String get partnerBookingFieldActualCheckIn => 'Actually checked in';

  @override
  String get partnerBookingFieldActualCheckOut => 'Actually checked out';

  @override
  String get partnerBookingFieldProperty => 'Booked property';

  @override
  String get partnerBookingFieldRoom => 'Booked room';

  @override
  String get partnerBookingFieldRoomCode => 'Room code';

  @override
  String get partnerBookingFieldRoomCount => 'Rooms booked';

  @override
  String get partnerBookingFieldBasePrice => 'Base price';

  @override
  String get partnerBookingFieldRatePlanPrice => 'Rate plan price';

  @override
  String get partnerBookingFieldDiscount => 'Discount applied';

  @override
  String get partnerBookingFieldTotal => 'Total charged';

  @override
  String get partnerBookingPriceNote =>
      'Every amount here was calculated and stored by the backend when the booking was made. Nothing is recalculated in this app.';

  @override
  String get partnerBookingFieldRatePlanName => 'Rate plan';

  @override
  String get partnerBookingFieldRatePlanCode => 'Rate plan code';

  @override
  String get partnerBookingFieldMealPlan => 'Meal plan';

  @override
  String get partnerBookingFieldCancellationPolicy => 'Cancellation policy';

  @override
  String get partnerBookingFieldCancellationDeadline =>
      'Free-cancellation deadline';

  @override
  String get partnerBookingFieldRefundable => 'Refundable';

  @override
  String get partnerBookingFieldNightlySnapshot => 'Nightly rate captured';

  @override
  String get partnerBookingSnapshotNote =>
      'These values were captured when the booking was made. Editing a rate plan today does not change them.';

  @override
  String get partnerBookingNoPayments =>
      'No payment has been recorded against this booking.';

  @override
  String get partnerBookingPaymentUnnamed => 'Payment';

  @override
  String get partnerBookingFieldInvoice => 'Invoice number';

  @override
  String get partnerBookingFieldInvoiceStatus => 'Invoice status';

  @override
  String get partnerBookingFieldInvoiceTotal => 'Invoice total';

  @override
  String get partnerBookingPaymentReadOnlyNote =>
      'Payment details are read-only. The partner API offers no payment, refund, or settlement action, and card and gateway identifiers are never sent to this screen.';

  @override
  String get partnerBookingTimelineEmpty =>
      'The server recorded no lifecycle events for this booking.';

  @override
  String get partnerBookingEventCreated => 'Booking created';

  @override
  String get partnerBookingEventPaid => 'Payment completed';

  @override
  String get partnerBookingEventConfirmed => 'Booking confirmed';

  @override
  String get partnerBookingEventCheckedIn => 'Guest checked in';

  @override
  String get partnerBookingEventCheckedOut => 'Guest checked out';

  @override
  String get partnerBookingEventCompleted => 'Reservation completed';

  @override
  String get partnerBookingEventCancelled => 'Booking cancelled';

  @override
  String get partnerBookingEventArchived => 'Reservation archived';

  @override
  String get partnerBookingEventModified => 'Booking changed';

  @override
  String get partnerBookingEventReview => 'Guest submitted a review';

  @override
  String get partnerBookingModificationNote =>
      'Guests change their own bookings. This is the record of what changed — the partner API offers no way to change a booking from here.';

  @override
  String get partnerBookingModificationDates => 'Dates';

  @override
  String get partnerBookingModificationOccupancy => 'Occupancy';

  @override
  String get partnerBookingModificationRatePlan => 'Rate plan';

  @override
  String get partnerBookingModificationPrice => 'Price';

  @override
  String get partnerBookingNoAudit =>
      'No check-in or check-out has been recorded for this booking.';

  @override
  String get partnerBookingAuditCheckIn => 'Check-in recorded';

  @override
  String get partnerBookingAuditCheckOut => 'Check-out recorded';

  @override
  String partnerBookingAuditByUser(String userId) {
    return 'Staff #$userId';
  }

  @override
  String get partnerBookingActionCheckIn => 'Check in';

  @override
  String get partnerBookingActionCheckOut => 'Check out';

  @override
  String get partnerBookingActionNoShow => 'Mark as no-show';

  @override
  String get partnerBookingActionComplete => 'Complete reservation';

  @override
  String get partnerBookingActionsIrreversibleNote =>
      'These changes cannot be undone from the extranet, and the guest is notified.';

  @override
  String get partnerBookingNoActionsAvailable =>
      'No operational action is available for this booking\'s current status.';

  @override
  String get partnerBookingNoActionsClosed =>
      'This booking is closed, so no operational action remains.';

  @override
  String partnerBookingActionConfirm(String action, String code) {
    return '$action for booking $code? This cannot be undone from the extranet, and the guest is notified.';
  }

  @override
  String get partnerBookingActionConfirmCta => 'Confirm';

  @override
  String get partnerBookingActionCancel => 'Cancel';

  @override
  String partnerBookingActionSucceeded(String action, String code) {
    return '$action completed for booking $code.';
  }

  @override
  String get partnerBookingActionRejected =>
      'The server refused that change for this booking\'s current status. Nothing was altered.';

  @override
  String get partnerBookingActionValidation =>
      'The server rejected that request. Nothing was altered.';

  @override
  String get partnerBookingActionUncertain =>
      'The connection dropped before the server confirmed, and this change cannot be undone. Refresh to see the current status before trying again.';

  @override
  String get partnerFrontDeskHeading => 'Check a guest in or out';

  @override
  String get partnerFrontDeskNote =>
      'Scan the guest\'s voucher QR or type their booking code. This changes the booking and notifies the guest.';

  @override
  String get partnerFrontDeskField => 'Voucher payload or booking code';

  @override
  String get partnerFrontDeskFieldHelp =>
      'A scanned voucher is recorded as a QR scan; a typed booking code is recorded as manual.';

  @override
  String get partnerFrontDeskCheckInAction => 'Check guest in';

  @override
  String get partnerFrontDeskCheckOutAction => 'Check guest out';

  @override
  String get partnerFrontDeskClear => 'Clear';

  @override
  String partnerFrontDeskConfirm(String code) {
    return 'Proceed for $code? This changes the booking, notifies the guest, and cannot be undone from the extranet.';
  }

  @override
  String get partnerFrontDeskCheckedInTitle => 'Guest checked in';

  @override
  String get partnerFrontDeskCheckedOutTitle => 'Guest checked out';

  @override
  String get partnerFrontDeskIdempotentNote =>
      'Repeating this on the same booking is safe: the server keeps the original time and records nothing twice.';

  @override
  String get partnerFrontDeskNotRecognisedTitle => 'Not recognised';

  @override
  String get partnerFrontDeskNotRecognisedMessage =>
      'The server does not recognise that voucher or booking code for your account. It may have been altered, may not exist, or may belong to another partner — the server does not say which.';

  @override
  String get partnerFrontDeskRejectedTitle => 'Cannot do that yet';

  @override
  String get partnerFrontDeskRejectedMessage =>
      'This booking\'s status or dates do not allow that right now. Nothing was changed.';

  @override
  String get partnerFrontDeskInvalidTitle => 'Nothing to submit';

  @override
  String get partnerFrontDeskInvalidMessage =>
      'Scan or type a voucher payload or booking code first.';

  @override
  String get partnerFrontDeskFailedTitle => 'Could not complete this';

  @override
  String get partnerFrontDeskUncertainTitle => 'Outcome unknown';

  @override
  String get partnerFrontDeskUncertainMessage =>
      'The connection dropped before the server confirmed. Check the booking\'s status — running this again is safe if it did not go through.';

  @override
  String get partnerCalendarTitle => 'Calendar & inventory';

  @override
  String get partnerCalendarTabOverview => 'Property calendar';

  @override
  String get partnerCalendarTabInventory => 'Room inventory';

  @override
  String get partnerCalendarScopeNote =>
      'Every room in the selected property, night by night. The figures come from the same inventory records the Room inventory tab edits — this view only reads them.';

  @override
  String partnerCalendarWindowRange(String from, String to) {
    return '$from – $to';
  }

  @override
  String get partnerCalendarPreviousWeek => 'Previous week';

  @override
  String get partnerCalendarNextWeek => 'Next week';

  @override
  String get partnerCalendarToday => 'Today';

  @override
  String get partnerCalendarNoRoomsTitle => 'This property has no rooms';

  @override
  String get partnerCalendarNoRoomsMessage =>
      'There is nothing to schedule until the property has at least one room. Rooms are managed in the Rooms module.';

  @override
  String get partnerCalendarWindowEmptyMessage =>
      'No inventory records exist for any room in these dates. Nights without a record cannot be sold, because the availability check counts records and rejects a stay when any night is missing.';

  @override
  String partnerCalendarRoomsFailed(String failed, String total) {
    return '$failed of $total room calendars could not be loaded. Those rows are shown as unavailable to read, not as empty.';
  }

  @override
  String partnerCalendarRoomFailed(String room) {
    return '$room could not be loaded.';
  }

  @override
  String get partnerCalendarStateOpen => 'Open for sale';

  @override
  String get partnerCalendarStateSoldOut => 'Nothing left';

  @override
  String get partnerCalendarStateStopSell => 'Stop sell';

  @override
  String get partnerCalendarStateNoRecord => 'No record';

  @override
  String get partnerCalendarLegendHeading => 'What each night shows';

  @override
  String get partnerCalendarLegendClosedArrival => 'Closed to arrival';

  @override
  String get partnerCalendarLegendClosedDeparture => 'Closed to departure';

  @override
  String get partnerCalendarLegendOccupied => 'Rooms sold';

  @override
  String get partnerCalendarLegendNote =>
      'The number on each night is rooms still available. Closed to arrival blocks a stay from starting that night; closed to departure blocks it from ending on that night. Neither stops the night being sold within a longer stay.';

  @override
  String partnerCalendarSoldValue(String count) {
    return '$count sold';
  }

  @override
  String get partnerCalendarMetricSellable => 'nights open for sale';

  @override
  String get partnerCalendarMetricOccupied => 'nights with rooms sold';

  @override
  String get partnerCalendarMetricRestricted => 'nights with a restriction';

  @override
  String get partnerCalendarMetricMissing => 'nights with no record';

  @override
  String partnerCalendarNightHeading(String room, String date) {
    return '$room · $date';
  }

  @override
  String get partnerCalendarCloseNight => 'Close night details';

  @override
  String get partnerCalendarFieldAvailable => 'Available';

  @override
  String get partnerCalendarFieldSold => 'Sold';

  @override
  String get partnerCalendarFieldBlocked => 'Blocked';

  @override
  String get partnerCalendarFieldMaintenance => 'Maintenance';

  @override
  String get partnerCalendarFieldTotal => 'Total rooms';

  @override
  String get partnerCalendarInconsistentMessage =>
      'Available, sold, blocked and maintenance do not add up to the total for this night. The server\'s own numbers are shown unchanged.';

  @override
  String get partnerCalendarNoRecordExplanation =>
      'There is no inventory record for this night. That is not the same as being free: the availability check counts records, so any stay covering this night is rejected. Create the record in the Room inventory tab to make the night sellable.';

  @override
  String get partnerCalendarQuestionsHeading => 'What this night allows';

  @override
  String get partnerCalendarQuestionStock => 'Rooms are left';

  @override
  String get partnerCalendarQuestionSellable => 'The night can be sold';

  @override
  String get partnerCalendarQuestionArrival => 'A stay can start this night';

  @override
  String get partnerCalendarQuestionDeparture =>
      'A stay can end with this night';

  @override
  String get partnerCalendarQuestionsNote =>
      'These are four separate checks the server makes, not one. A night can be sellable inside a longer stay while still refusing an arrival or a departure.';

  @override
  String get partnerCalendarReasonNoStock =>
      'No rooms are left for this night.';

  @override
  String get partnerCalendarReasonStopSell => 'Stop sell is on for this night.';

  @override
  String get partnerCalendarReasonNotSellable =>
      'The night cannot be sold at all.';

  @override
  String get partnerCalendarReasonClosedArrival =>
      'Closed to arrival on this night.';

  @override
  String get partnerCalendarReasonClosedDeparture =>
      'Closed to departure on this night.';

  @override
  String get partnerCalendarReadOnlyNote =>
      'This calendar only reads. Stop sell, closed to arrival and closed to departure are changed in the Room inventory tab, so one place owns every write.';

  @override
  String get partnerCalendarManageRestrictions => 'Open room inventory';

  @override
  String partnerMetricWindow(String from, String to) {
    return '$from – $to';
  }

  @override
  String get partnerMetricAllProperties => 'All properties';

  @override
  String get partnerMetricChangeRange => 'Change dates';

  @override
  String get partnerMetricDefaultRange => 'Last 30 days';

  @override
  String get partnerMetricInvalidRange =>
      'The start date must not be after the end date. The server rejects that range.';

  @override
  String get partnerMetricScopeNotFound =>
      'That property is not available to your account.';

  @override
  String get partnerMetricNotLoaded => 'This section has not been loaded.';

  @override
  String get partnerMetricUnavailable => 'Not available';

  @override
  String partnerMetricSectionsFailed(String count) {
    return '$count section(s) could not be loaded. They are shown as unavailable, not as zero.';
  }

  @override
  String partnerMetricPeakDay(String date, String value) {
    return 'Highest day $date, $value';
  }

  @override
  String get partnerFinanceTitle => 'Finance & settlement';

  @override
  String get partnerFinanceTabOverview => 'Revenue & commission';

  @override
  String get partnerFinanceTabRevenue => 'Revenue';

  @override
  String get partnerFinanceTabSettlement => 'Settlement & payouts';

  @override
  String get partnerFinanceScopeAll =>
      'Figures cover every property you own. Select a property in the workspace to narrow them. Amounts are grouped numbers: the finance API sends no currency with them.';

  @override
  String get partnerFinanceScopeProperty =>
      'Figures cover the selected property only. Amounts are grouped numbers: the finance API sends no currency with them.';

  @override
  String get partnerFinanceEstimateNotice =>
      'These are derived estimates, not a statement of account. The platform commission is a fixed rate applied by the server, the tax figure is indicative only, and settlement periods are calculated from booking revenue rather than read from a settlement ledger.';

  @override
  String get partnerFinanceNoData =>
      'The server returned no figures for this window.';

  @override
  String get partnerFinanceOverviewHeading => 'Revenue and commission';

  @override
  String get partnerFinanceOverviewSubtitle =>
      'Bookings are counted by check-in date within the selected window.';

  @override
  String get partnerFinanceCommissionCaption =>
      'Calculated by the server at a fixed rate';

  @override
  String get partnerFinanceTaxCaption =>
      'Indicative only — not a tax calculation';

  @override
  String get partnerFinanceCompletedLabel => 'Completed bookings';

  @override
  String get partnerFinancePaidLabel => 'Bookings with a paid payment';

  @override
  String get partnerFinancePendingCaption =>
      'The whole window\'s net revenue: nothing tracks what has actually been settled';

  @override
  String get partnerFinanceNextPayoutCaption =>
      'An assumed monthly cadence, not a scheduled date';

  @override
  String get partnerFinanceCommissionHeading => 'Commission breakdown';

  @override
  String partnerFinanceRateNotice(String rate) {
    return 'The server applied a fixed platform rate of $rate. It is a constant in the service, not a negotiated rate, and this app never applies it itself.';
  }

  @override
  String get partnerFinanceRevenueHeading => 'Revenue breakdown';

  @override
  String get partnerFinanceRevenueSubtitle =>
      'Every figure is calculated and rounded by the server. Nothing on this screen is recalculated.';

  @override
  String get partnerFinanceRevenueEmpty =>
      'No revenue was recorded in this window.';

  @override
  String get partnerFinanceAverageBooking => 'Average booking value';

  @override
  String get partnerFinanceHighestBooking => 'Highest booking';

  @override
  String get partnerFinanceByDay => 'By day';

  @override
  String get partnerFinanceByMonth => 'By month';

  @override
  String get partnerFinanceByProperty => 'By property';

  @override
  String get partnerFinanceByRoom => 'By room';

  @override
  String get partnerFinanceSettlementHeading => 'Settlement';

  @override
  String get partnerFinanceSettlementSubtitle =>
      'Periods are calendar months calculated from booking revenue. No settlement ledger exists behind them.';

  @override
  String get partnerFinanceSettlementEmpty =>
      'No settlement period falls in this window.';

  @override
  String get partnerFinanceCurrentSettlement => 'Current period';

  @override
  String get partnerFinanceLastSettlement => 'Previous period';

  @override
  String get partnerFinancePending => 'Pending';

  @override
  String get partnerFinancePaid => 'Settled';

  @override
  String get partnerFinanceSettlementMismatch =>
      'The server reports a settled amount although no period below is marked settled. Both values are shown exactly as the server sent them; treat the settled total with caution.';

  @override
  String get partnerFinanceSettlementPeriods => 'Periods';

  @override
  String get partnerFinancePeriod => 'Period';

  @override
  String get partnerFinanceStatus => 'Status';

  @override
  String get partnerFinanceStatusPaid => 'Settled';

  @override
  String get partnerFinanceStatusPending => 'Pending';

  @override
  String get partnerFinanceStatusUnknown => 'Unrecognised';

  @override
  String get partnerFinancePayoutHeading => 'Payouts';

  @override
  String get partnerFinancePayoutSubtitle =>
      'The same calculated periods, split by status.';

  @override
  String get partnerFinancePayoutEmpty =>
      'No payout period falls in this window.';

  @override
  String get partnerFinanceEstimatedPayoutDate => 'Estimated payout date';

  @override
  String get partnerFinanceUpcomingPayouts => 'Upcoming';

  @override
  String get partnerFinanceCompletedPayouts => 'Completed';

  @override
  String get partnerFinancePayoutNoRecords =>
      'No payout records exist in the partner API — there is no reference, bank detail or payment provider information to show, and none is requested.';

  @override
  String get partnerFinanceInvoiceHeading => 'Invoices';

  @override
  String get partnerFinanceInvoiceEmpty =>
      'No invoice was issued in this window.';

  @override
  String get partnerFinanceInvoiceIssued => 'Issued';

  @override
  String get partnerFinanceInvoicePaid => 'Paid';

  @override
  String get partnerFinanceInvoiceCancelled => 'Cancelled';

  @override
  String get partnerFinanceInvoiceRefunded => 'Refunded';

  @override
  String get partnerFinanceInvoiceTotal => 'Total invoiced';

  @override
  String get partnerFinanceInvoiceNoDocuments =>
      'The partner API returns invoice counts only. There is no invoice list, no invoice number to open and no download, so none is offered here.';

  @override
  String get partnerFinanceRefundHeading => 'Refunds';

  @override
  String get partnerFinanceRefundEmpty =>
      'No refund was recorded in this window.';

  @override
  String get partnerFinanceRefundCount => 'Refunds';

  @override
  String get partnerFinanceRefundAmount => 'Refunded amount';

  @override
  String get partnerFinanceRefundRate => 'Refund rate';

  @override
  String get partnerFinanceRefundReadOnly =>
      'Refunds are read-only here. The partner API has no refund action, so refunds are started elsewhere.';

  @override
  String get partnerAnalyticsTitle => 'Performance analytics';

  @override
  String get partnerAnalyticsDashboardPointer =>
      'Revenue, occupancy and the headline totals live on the Dashboard, which already reports them. This page covers what the Dashboard does not.';

  @override
  String get partnerAnalyticsScopeAll =>
      'Figures cover every property you own. Select a property in the workspace to narrow them.';

  @override
  String get partnerAnalyticsScopeProperty =>
      'Figures cover the selected property only.';

  @override
  String get partnerAnalyticsBookingsHeading => 'Booking activity';

  @override
  String get partnerAnalyticsBookingsEmpty =>
      'No booking falls in this window.';

  @override
  String get partnerAnalyticsArrivals => 'Arrivals';

  @override
  String get partnerAnalyticsDepartures => 'Departures';

  @override
  String get partnerAnalyticsCancellations => 'Cancellations';

  @override
  String get partnerAnalyticsNoShows => 'No-shows';

  @override
  String get partnerAnalyticsAverageStay => 'Average stay';

  @override
  String get partnerAnalyticsAverageStayCaption =>
      'Nights, calculated by the server';

  @override
  String get partnerAnalyticsByStatus => 'By status';

  @override
  String get partnerAnalyticsRoomsHeading => 'Room performance';

  @override
  String get partnerAnalyticsRoomsEmpty =>
      'No room activity falls in this window.';

  @override
  String get partnerAnalyticsOccupancyEstimate => 'Occupancy estimate';

  @override
  String get partnerAnalyticsOccupancyCaption =>
      'The server calls this an estimate';

  @override
  String get partnerAnalyticsTopRoomsRevenue => 'Top rooms by revenue';

  @override
  String get partnerAnalyticsTopRoomsBookings => 'Top rooms by bookings';

  @override
  String get partnerAnalyticsAvailability => 'Availability summary';

  @override
  String get partnerAnalyticsPromotionsHeading => 'Promotion activity';

  @override
  String get partnerAnalyticsPromotionsSubtitle =>
      'Structural only: the server cannot yet attribute a discount to a booking.';

  @override
  String get partnerAnalyticsPromotionsEmpty =>
      'No promotion activity falls in this window.';

  @override
  String get partnerAnalyticsActivePromotions => 'Active promotions';

  @override
  String get partnerAnalyticsDiscountedBookings => 'Discounted bookings';

  @override
  String get partnerAnalyticsNoAttribution =>
      'The server cannot attribute discounts yet';

  @override
  String get partnerAnalyticsPromotionsByType => 'By type';

  @override
  String get partnerAnalyticsPromotionsByStatus => 'By status';

  @override
  String get partnerAnalyticsReviewsHeading => 'Review summary';

  @override
  String get partnerAnalyticsReviewsSubtitle =>
      'Rating and moderation totals. Individual reviews and replies are managed in the Reviews module.';

  @override
  String get partnerAnalyticsReviewsEmpty => 'No review falls in this window.';

  @override
  String get partnerAnalyticsAverageRating => 'Average rating';

  @override
  String get partnerAnalyticsApprovedOnly => 'Approved reviews only';

  @override
  String get partnerAnalyticsNoReviews => 'No reviews to average';

  @override
  String get partnerAnalyticsReviewCount => 'Total reviews';

  @override
  String get partnerAnalyticsReviewsApproved => 'Approved';

  @override
  String get partnerAnalyticsReviewsPending => 'Pending';

  @override
  String get partnerAnalyticsReviewsRejected => 'Rejected';

  @override
  String get partnerAnalyticsMessagesHeading => 'Message activity';

  @override
  String get partnerAnalyticsMessagesEmpty =>
      'No conversation falls in this window.';

  @override
  String get partnerAnalyticsOpenConversations => 'Open conversations';

  @override
  String get partnerAnalyticsClosedConversations => 'Closed conversations';

  @override
  String get partnerAnalyticsArchivedConversations => 'Archived conversations';

  @override
  String get partnerAnalyticsUnreadMessages => 'Unread for you';

  @override
  String get partnerAnalyticsResponseTime => 'Average response time';

  @override
  String get partnerAnalyticsNoResponses =>
      'No response time could be measured';

  @override
  String partnerAnalyticsMinutesValue(String value) {
    return '$value min';
  }

  @override
  String get partnerReviewsTitle => 'Guest reviews';

  @override
  String get partnerReviewsAnalyticsPointer =>
      'Ratings and moderation totals are on the Analytics page. This page is for replying.';

  @override
  String get partnerReviewsScopeNote =>
      'The published reviews for the selected property. Only published reviews can be replied to, and this is exactly the set the server allows a reply on.';

  @override
  String get partnerReviewsNoBodyNotice =>
      'The partner API does not return the text a guest wrote — only the rating, the title and the date. Replies are written against those.';

  @override
  String get partnerReviewsNoPropertyTitle => 'Select a property';

  @override
  String get partnerReviewsNoPropertyMessage =>
      'Reviews are listed per property. Choose one in the workspace to see its reviews.';

  @override
  String get partnerReviewsEmptyTitle => 'No published reviews yet';

  @override
  String get partnerReviewsEmptyMessage =>
      'Nothing has been published for this property. Reviews appear here once a guest writes one and it is approved.';

  @override
  String get partnerReviewsNoMatchTitle => 'Nothing matches this filter';

  @override
  String get partnerReviewsNoMatchMessage =>
      'This property has reviews, but none in the selected group.';

  @override
  String get partnerReviewsFilterAll => 'Show all';

  @override
  String partnerReviewsFilterAllCount(String count) {
    return 'All ($count)';
  }

  @override
  String partnerReviewsFilterNeedsReplyCount(String count) {
    return 'Needs a reply ($count)';
  }

  @override
  String partnerReviewsFilterRepliedCount(String count) {
    return 'Replied ($count)';
  }

  @override
  String get partnerReviewsNeedsReply => 'Needs a reply';

  @override
  String get partnerReviewsReplied => 'Replied';

  @override
  String get partnerReviewsNoTitle => 'Untitled review';

  @override
  String partnerReviewsRatingValue(String rating) {
    return 'Rated $rating out of 5';
  }

  @override
  String get partnerReviewsReplyHeading => 'Your reply';

  @override
  String get partnerReviewsCloseReply => 'Close reply';

  @override
  String get partnerReviewsCurrentReply => 'Currently published';

  @override
  String partnerReviewsRepliedAt(String date) {
    return 'replied $date';
  }

  @override
  String partnerReviewsEditedAt(String date) {
    return 'edited $date';
  }

  @override
  String get partnerReviewsReplyField => 'Reply to this guest';

  @override
  String get partnerReviewsReplyHelp =>
      'A review has one reply. Publishing again replaces it rather than adding a second.';

  @override
  String get partnerReviewsPublicNotice =>
      'Your reply is published publicly alongside the review, and there is no way to delete it afterwards — only to replace its wording. The guest is notified the first time you reply.';

  @override
  String get partnerReviewsPublishReply => 'Publish reply';

  @override
  String get partnerReviewsUpdateReply => 'Replace reply';

  @override
  String get partnerReviewsPublishConfirm =>
      'Publish this reply publicly? It cannot be deleted afterwards, only rewritten.';

  @override
  String get partnerReviewsReplyPublished => 'Your reply is published.';

  @override
  String get partnerReviewsReplyEmpty => 'Write a reply before publishing.';

  @override
  String get partnerReviewsReplyUncertain =>
      'The connection dropped before the server confirmed, and a reply cannot be deleted. Refresh to see whether it was published.';

  @override
  String get partnerReviewsNotFound =>
      'That review is no longer available to your account.';

  @override
  String get partnerReviewsNotApprovedNotice =>
      'Only a published review can be replied to. The server refuses a reply on any other status.';

  @override
  String get partnerSettingsTitle => 'Account & settings';

  @override
  String get partnerSettingsTabWorkspace => 'Policies & workspace';

  @override
  String get partnerSettingsTabTeam => 'Team';

  @override
  String get partnerSettingsTabPayout => 'Payout account';

  @override
  String get partnerSettingsTabProfile => 'Business profile';

  @override
  String get partnerTeamHeading => 'Team members';

  @override
  String get partnerTeamSubtitle =>
      'Everyone who can act in this partner workspace, and the role the server grants them.';

  @override
  String get partnerTeamEmpty => 'No team members are recorded.';

  @override
  String get partnerTeamOwnerOnly =>
      'Only the partner owner can add, change or remove team members. You can see the team here.';

  @override
  String get partnerTeamRoleField => 'Role';

  @override
  String get partnerTeamActive => 'Active';

  @override
  String get partnerTeamInactive => 'Inactive';

  @override
  String get partnerTeamActivate => 'Activate';

  @override
  String get partnerTeamDeactivate => 'Deactivate';

  @override
  String get partnerTeamRemove => 'Remove';

  @override
  String partnerTeamRemoveConfirm(String member) {
    return 'Remove $member from the team? This cannot be undone from here — they would have to be added again.';
  }

  @override
  String get partnerTeamInviteHeading => 'Add a team member';

  @override
  String get partnerTeamInviteNote =>
      'The server matches an existing Plan Your Trip account by email. It does not send an invitation, so the person must already have an account.';

  @override
  String get partnerTeamInviteEmail => 'Their account email';

  @override
  String get partnerTeamInviteAction => 'Add member';

  @override
  String get partnerPayoutHeading => 'Payout account';

  @override
  String get partnerPayoutSubtitle =>
      'Where settlements would be sent. Held as reference details only.';

  @override
  String get partnerPayoutNone => 'No payout account has been added yet.';

  @override
  String get partnerPayoutLoadFailed =>
      'The payout account could not be loaded. This is not the same as having none.';

  @override
  String get partnerPayoutHolder => 'Account holder';

  @override
  String get partnerPayoutBank => 'Bank';

  @override
  String get partnerPayoutAccountNumber => 'Account number';

  @override
  String partnerPayoutMasked(String last4) {
    return 'Ends in $last4';
  }

  @override
  String get partnerPayoutMethod => 'Payout method';

  @override
  String get partnerPayoutMethodBank => 'Bank transfer';

  @override
  String get partnerPayoutMethodManual => 'Manual';

  @override
  String get partnerPayoutMethodUnknown => 'Unrecognised method';

  @override
  String get partnerPayoutStatus => 'Verification status';

  @override
  String get partnerPayoutUpdated => 'Last updated';

  @override
  String get partnerPayoutNoExecutionNotice =>
      'No payout is ever sent from here, and the full account number is never stored: the server keeps only its last four digits and discards the rest as soon as it is submitted.';

  @override
  String get partnerPayoutRoleNotice =>
      'Only the partner owner or a finance team member can change these details. You can see them here.';

  @override
  String get partnerPayoutAdd => 'Add payout account';

  @override
  String get partnerPayoutReplace => 'Replace details';

  @override
  String get partnerPayoutCancelEdit => 'Cancel';

  @override
  String get partnerPayoutFormHeading => 'New payout details';

  @override
  String get partnerPayoutNumberHelp =>
      'At least 4 characters. Only the last four digits are kept.';

  @override
  String get partnerPayoutSave => 'Save payout details';

  @override
  String get partnerPayoutReplaceConfirm =>
      'Replace the payout details? The previous account number cannot be recovered, because it was never stored.';

  @override
  String get partnerProfileHeading => 'Business profile';

  @override
  String get partnerProfileBusinessName => 'Business name';

  @override
  String get partnerProfileRepresentative => 'Representative';

  @override
  String get partnerProfileVerification => 'Verification';

  @override
  String get partnerProfileYourRole => 'Your role';

  @override
  String get partnerProfileReadOnlyNotice =>
      'An approved business profile cannot be edited through the partner API — the server accepts changes only while a profile is a draft or has been rejected. Contact support to change these details.';

  @override
  String get partnerProfileStatusDraft => 'Draft';

  @override
  String get partnerProfileStatusSubmitted => 'Awaiting review';

  @override
  String get partnerProfileStatusApproved => 'Approved';

  @override
  String get partnerProfileStatusRejected => 'Rejected';

  @override
  String get partnerProfileStatusSuspended => 'Suspended';

  @override
  String get partnerProfileStatusUnknown => 'Unrecognised status';

  @override
  String get partnerAccountSaved => 'Saved.';

  @override
  String get partnerAccountNotFound =>
      'That record is no longer available to your account.';

  @override
  String get partnerAccountConflict =>
      'The server refused that because it conflicts with an existing record.';

  @override
  String get partnerAccountValidation => 'Check the details and try again.';

  @override
  String get partnerAccountUncertain =>
      'The connection dropped before the server confirmed. Refresh to see the current state before trying again.';

  @override
  String get adminConsoleTitle => 'Admin console';

  @override
  String adminSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get adminNavDashboard => 'Dashboard';

  @override
  String get adminNavBookings => 'Bookings';

  @override
  String get adminNavPayments => 'Payments';

  @override
  String get adminNavInvoices => 'Invoices';

  @override
  String get adminNavReviews => 'Reviews';

  @override
  String get adminNavActivityLog => 'Activity log';

  @override
  String get adminSectionOverview => 'Overview';

  @override
  String get adminSectionOperations => 'Operations';

  @override
  String get adminSectionFinance => 'Finance';

  @override
  String get adminSectionCommunity => 'Community';

  @override
  String get adminSectionAudit => 'Audit';

  @override
  String get adminAccessDeniedTitle => 'Administrator access required';

  @override
  String get adminAccessDeniedBody =>
      'This area is limited to administrator accounts.';

  @override
  String get adminAccessDeniedAction => 'Go back';

  @override
  String get adminMenu => 'Menu';

  @override
  String get adminLoading => 'Loading…';

  @override
  String get adminEmptyTitle => 'Nothing to show';

  @override
  String get adminEmptyMessage => 'No records match this view yet.';

  @override
  String get adminErrorUnauthorized =>
      'Your session has expired. Please sign in again.';

  @override
  String get adminErrorForbidden =>
      'This account does not have administrator access.';

  @override
  String get adminErrorNotFound => 'That record could not be found.';

  @override
  String get adminErrorGeneric => 'Could not load this view.';

  @override
  String get adminRetry => 'Try again';

  @override
  String get adminRefresh => 'Refresh';

  @override
  String get adminValueUnknown => '—';

  @override
  String get adminPaginationEmpty => 'No results';

  @override
  String adminPaginationRange(int first, int last, int total) {
    return 'Showing $first–$last of $total';
  }

  @override
  String adminPaginationPageOf(int page, int total) {
    return 'Page $page of $total';
  }

  @override
  String get adminPaginationPrevious => 'Previous page';

  @override
  String get adminPaginationNext => 'Next page';

  @override
  String get adminSortAscending => 'Sorted ascending';

  @override
  String get adminSortDescending => 'Sorted descending';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterStatus => 'Status';

  @override
  String get adminSortCreatedAt => 'Created';

  @override
  String get adminSortCheckIn => 'Check-in';

  @override
  String get adminSortCheckOut => 'Check-out';

  @override
  String get adminSortFinalPrice => 'Total';

  @override
  String get adminSortStatus => 'Status';

  @override
  String get adminSortBookingCode => 'Booking code';

  @override
  String get adminSortAmount => 'Amount';

  @override
  String get adminSortPaidAt => 'Paid';

  @override
  String get adminSortRefundedAt => 'Refunded';

  @override
  String get adminSortRating => 'Rating';

  @override
  String get adminSortApprovedAt => 'Approved';

  @override
  String get adminSortIssuedAt => 'Issued';

  @override
  String get adminSortTotalAmount => 'Total';

  @override
  String get adminDashboardTitle => 'Platform overview';

  @override
  String get adminDashboardTotalBookings => 'Total bookings';

  @override
  String get adminDashboardGrossRevenue => 'Gross revenue';

  @override
  String get adminDashboardActiveHotels => 'Active hotels';

  @override
  String get adminDashboardActiveRooms => 'Active rooms';

  @override
  String get adminDashboardTotalUsers => 'Users';

  @override
  String get adminDashboardTotalPartners => 'Partners';

  @override
  String get adminDashboardBookingsInRange => 'Bookings in range';

  @override
  String get adminDashboardRevenueInRange => 'Revenue in range';

  @override
  String get adminDashboardBookingsByStatus => 'Bookings by status';

  @override
  String get adminDashboardNoBookings => 'The platform has no bookings yet.';

  @override
  String adminDashboardRange(String from, String to) {
    return 'Range $from to $to';
  }

  @override
  String get adminDashboardRangeDefault => 'Backend default range';

  @override
  String adminDashboardLoadedAt(String time) {
    return 'Loaded at $time';
  }

  @override
  String get adminDashboardNoCurrency =>
      'Revenue is reported without a currency by this endpoint.';

  @override
  String get adminBookingsTitle => 'Bookings';

  @override
  String get adminBookingCode => 'Code';

  @override
  String get adminBookingHotel => 'Hotel';

  @override
  String get adminBookingRoom => 'Room';

  @override
  String get adminBookingStay => 'Stay';

  @override
  String adminBookingNights(int count) {
    return '$count nights';
  }

  @override
  String get adminBookingTotal => 'Total';

  @override
  String get adminBookingCreated => 'Created';

  @override
  String get adminBookingsEmpty => 'No bookings match these filters.';

  @override
  String get adminPaymentsTitle => 'Payments';

  @override
  String get adminPaymentCode => 'Payment';

  @override
  String get adminPaymentBooking => 'Booking';

  @override
  String get adminPaymentAmount => 'Amount';

  @override
  String get adminPaymentMethod => 'Method';

  @override
  String get adminPaymentProvider => 'Provider';

  @override
  String get adminPaymentPaidAt => 'Paid';

  @override
  String get adminPaymentRefundedAt => 'Refunded';

  @override
  String get adminPaymentFailureReason => 'Failure reason';

  @override
  String get adminPaymentsEmpty => 'No payments match these filters.';

  @override
  String get adminReviewsTitle => 'Reviews';

  @override
  String get adminReviewPlace => 'Place';

  @override
  String get adminReviewAuthor => 'Author';

  @override
  String get adminReviewRating => 'Rating';

  @override
  String get adminReviewContent => 'Review';

  @override
  String adminReviewReported(int count) {
    return 'Reported $count times';
  }

  @override
  String get adminReviewPartnerReply => 'Partner reply';

  @override
  String get adminReviewNoReply => 'No partner reply';

  @override
  String get adminReviewsEmpty => 'No reviews match these filters.';

  @override
  String get adminInvoicesTitle => 'Invoices';

  @override
  String get adminInvoiceNumber => 'Invoice';

  @override
  String get adminInvoiceBooking => 'Booking';

  @override
  String get adminInvoiceHotel => 'Hotel';

  @override
  String get adminInvoiceSubtotal => 'Subtotal';

  @override
  String get adminInvoiceDiscount => 'Discount';

  @override
  String get adminInvoiceTax => 'Tax';

  @override
  String get adminInvoiceTotal => 'Total';

  @override
  String get adminInvoiceIssuedAt => 'Issued';

  @override
  String get adminInvoicePaidAt => 'Paid';

  @override
  String get adminInvoicesEmpty => 'No invoices match these filters.';

  @override
  String get adminActivityTitle => 'Activity log';

  @override
  String get adminActivityActor => 'Actor';

  @override
  String get adminActivityAction => 'Action';

  @override
  String get adminActivityTarget => 'Target';

  @override
  String get adminActivityWhen => 'When';

  @override
  String get adminActivityDescription => 'Details';

  @override
  String get adminActivityBefore => 'Before';

  @override
  String get adminActivityAfter => 'After';

  @override
  String get adminActivitySystemActor => 'System';

  @override
  String get adminActivityEmpty => 'No administrative actions recorded yet.';

  @override
  String get adminActivityFixedOrder => 'Newest first, fixed by the server.';

  @override
  String get adminActivityFilterAction => 'Action';

  @override
  String get adminNavPartners => 'Partners';

  @override
  String get adminPartnersEmpty => 'No partners yet.';

  @override
  String get adminPartnersEmptyFiltered => 'No partners match these filters.';

  @override
  String get adminPartnerSearchLabel => 'Search partners';

  @override
  String get adminPartnerSearchHint =>
      'Business name, representative or contact email';

  @override
  String get adminPartnerSearchClear => 'Clear search';

  @override
  String get adminPartnerFilterBusinessType => 'Business type';

  @override
  String get adminPartnerSortBusinessName => 'Business name';

  @override
  String get adminPartnerSortSubmittedAt => 'Submitted';

  @override
  String get adminPartnerColBusiness => 'Business';

  @override
  String get adminPartnerColType => 'Type';

  @override
  String get adminPartnerColSubmitted => 'Submitted';

  @override
  String get adminPartnerColAction => 'Action';

  @override
  String get adminPartnerOpen => 'Open';

  @override
  String adminPartnerOpenSemantic(String business) {
    return 'Open partner $business';
  }

  @override
  String get adminPartnerBackToList => 'Back to partners';

  @override
  String get adminPartnerTabOverview => 'Overview';

  @override
  String get adminPartnerTabTeam => 'Team';

  @override
  String get adminPartnerTabActivity => 'Activity';

  @override
  String get adminPartnerTabSettings => 'Settings';

  @override
  String get adminPartnerNotFoundTitle => 'Partner not found';

  @override
  String get adminPartnerNotFoundMessage =>
      'No partner exists with this id. It may have been removed, or the link may be wrong.';

  @override
  String get adminPartnerSectionIdentity => 'Business identity';

  @override
  String get adminPartnerSectionVerification => 'Verification';

  @override
  String get adminPartnerSectionSummary => 'Summary';

  @override
  String get adminPartnerRepresentative => 'Representative';

  @override
  String get adminPartnerContactEmail => 'Business email';

  @override
  String get adminPartnerContactPhone => 'Phone';

  @override
  String get adminPartnerAddress => 'Address';

  @override
  String get adminPartnerTaxCode => 'Tax code';

  @override
  String get adminPartnerWebsite => 'Website';

  @override
  String get adminPartnerAccountEmail => 'Account email';

  @override
  String get adminPartnerApprovedAt => 'Approved';

  @override
  String get adminPartnerApprovedBy => 'Approved by';

  @override
  String get adminPartnerRejectedAt => 'Rejected';

  @override
  String get adminPartnerRejectionReason => 'Rejection reason';

  @override
  String get adminPartnerSuspensionReason => 'Suspension reason';

  @override
  String get adminPartnerOwnedProperties => 'Owned properties';

  @override
  String get adminPartnerTeamSize => 'Team members';

  @override
  String get adminPartnerPayoutStatus => 'Payout account';

  @override
  String get adminPartnerSummaryUnavailable => 'Summary could not be loaded.';

  @override
  String get adminPartnerPropertiesNotListed =>
      'Property details are managed outside partner management.';

  @override
  String get adminPartnerApprove => 'Approve';

  @override
  String get adminPartnerReject => 'Reject';

  @override
  String get adminPartnerSuspend => 'Suspend';

  @override
  String get adminPartnerCancel => 'Cancel';

  @override
  String get adminPartnerApproveTitle => 'Approve this partner?';

  @override
  String get adminPartnerApproveBody =>
      'The applicant gains partner access and becomes the owner of their organisation.';

  @override
  String get adminPartnerRejectTitle => 'Reject this application?';

  @override
  String get adminPartnerRejectBody =>
      'The partner is notified and can edit their profile and submit it again.';

  @override
  String get adminPartnerRejectReasonLabel => 'Reason';

  @override
  String get adminPartnerRejectReasonRequired => 'A reason is required.';

  @override
  String get adminPartnerActionUncertain =>
      'The result of the last action is unknown. This page has been reloaded — check the verification state before trying again.';

  @override
  String get adminPartnerSuspendedNotice =>
      'This partner is suspended. There is no way to restore them from the admin console.';

  @override
  String get adminPartnerSuspendTitle => 'Suspend this partner?';

  @override
  String get adminPartnerSuspendWarningIrreversible =>
      'This cannot be reversed from the admin console — there is no restore action.';

  @override
  String get adminPartnerSuspendWarningBookable =>
      'Their published properties stay visible and bookable to guests.';

  @override
  String get adminPartnerSuspendWarningOperations =>
      'They immediately lose access to bookings, rates, inventory and every other partner tool, so incoming bookings may go unhandled.';

  @override
  String get adminPartnerSuspendReasonLabel => 'Reason';

  @override
  String get adminPartnerSuspendReasonOptional => 'Optional';

  @override
  String get adminPartnerSuspendAcknowledge =>
      'I understand this cannot be undone here.';

  @override
  String get adminPartnerSuspendConfirm => 'Suspend partner';

  @override
  String get adminPartnerTeamEmpty => 'No team members.';

  @override
  String get adminPartnerTeamReadOnlyNotice =>
      'Read-only. Team members are managed by the partner.';

  @override
  String get adminPartnerTeamActive => 'Active';

  @override
  String get adminPartnerTeamActiveYes => 'Yes';

  @override
  String get adminPartnerTeamActiveNo => 'No';

  @override
  String get adminPartnerTeamJoined => 'Joined';

  @override
  String get adminPartnerActivityEmpty => 'No partner activity recorded.';

  @override
  String get adminPartnerActivityScopeNotice =>
      'This partner\'s own operations. Administrator actions appear in the console activity log.';

  @override
  String get adminPartnerActivityActor => 'By';

  @override
  String get adminPartnerActivityEntity => 'Entity';

  @override
  String get adminPartnerSettingsEmpty => 'Settings could not be loaded.';

  @override
  String get adminPartnerSettingsReadOnlyNotice =>
      'Read-only. Settings are managed by the partner.';

  @override
  String get adminPartnerSettingsLanguage => 'Default language';

  @override
  String get adminPartnerSettingsTimezone => 'Time zone';

  @override
  String get adminPartnerSettingsEmail => 'Email notifications';

  @override
  String get adminPartnerSettingsSms => 'SMS notifications';

  @override
  String get adminPartnerSettingsInApp => 'In-app notifications';

  @override
  String get adminPartnerSettingsBooking => 'Booking notifications';

  @override
  String get adminPartnerSettingsPayment => 'Payment notifications';

  @override
  String get adminPartnerSettingsReview => 'Review notifications';

  @override
  String get adminPartnerSettingsPromotion => 'Promotion notifications';

  @override
  String get adminNavCatalog => 'Catalog';

  @override
  String get adminSectionCatalog => 'Catalog';

  @override
  String get adminCatalogEmpty => 'No places yet.';

  @override
  String get adminCatalogEmptyFiltered => 'No places match these filters.';

  @override
  String get adminCatalogSearchLabel => 'Search places';

  @override
  String get adminCatalogSearchClear => 'Clear search';

  @override
  String get adminCatalogFilterFeatured => 'Featured';

  @override
  String get adminCatalogFilterVerified => 'Verified';

  @override
  String get adminCatalogSortLabel => 'Sort';

  @override
  String get adminCatalogSortNewest => 'Newest';

  @override
  String get adminCatalogSortRatingDesc => 'Highest rated';

  @override
  String get adminCatalogSortPriceAsc => 'Price: low to high';

  @override
  String get adminCatalogSortPriceDesc => 'Price: high to low';

  @override
  String get adminCatalogSortNameAsc => 'Name A–Z';

  @override
  String get adminCatalogOrderingNotice =>
      'Places with the same sort value may change order between pages.';

  @override
  String get adminCatalogColName => 'Name';

  @override
  String get adminCatalogColCategory => 'Category';

  @override
  String get adminCatalogColLocation => 'Location';

  @override
  String get adminCatalogColRating => 'Rating';

  @override
  String get adminCatalogColFlags => 'Flags';

  @override
  String adminCatalogOpenSemantic(String name) {
    return 'Open place $name';
  }

  @override
  String get adminCatalogBackToList => 'Back to catalog';

  @override
  String get adminCatalogNotFoundTitle => 'Place not found';

  @override
  String get adminCatalogNotFoundMessage =>
      'No place exists with this id. It may have been removed, or the link may be wrong.';

  @override
  String get adminCatalogActionUncertain =>
      'The result of the last action is unknown. This page has been reloaded — check the status before trying again.';

  @override
  String get adminCatalogSectionLifecycle => 'Lifecycle';

  @override
  String get adminCatalogSectionFlags => 'Verification and placement';

  @override
  String get adminCatalogSectionIdentity => 'Identity';

  @override
  String get adminCatalogSectionRooms => 'Rooms';

  @override
  String get adminCatalogSectionMedia => 'Gallery';

  @override
  String get adminCatalogPublicVisibility => 'Guest visibility';

  @override
  String get adminCatalogVisibleToGuests => 'Visible and bookable';

  @override
  String get adminCatalogHiddenFromGuests => 'Not visible to guests';

  @override
  String get adminCatalogNoTransitions =>
      'No status change is available from here.';

  @override
  String get adminCatalogArchivedNotice =>
      'This place is archived. There is no way to restore it from the admin console.';

  @override
  String get adminCatalogArchive => 'Archive';

  @override
  String get adminCatalogArchiveTitle => 'Archive this place?';

  @override
  String get adminCatalogArchiveWarningIrreversible =>
      'This cannot be reversed from the admin console — there is no restore action.';

  @override
  String get adminCatalogArchiveWarningVisibility =>
      'The place disappears from guest search and its public page immediately.';

  @override
  String get adminCatalogArchiveWarningRooms =>
      'Its rooms, rates and inventory are left untouched and are not released.';

  @override
  String get adminCatalogArchiveAcknowledge =>
      'I understand this cannot be undone here.';

  @override
  String get adminCatalogArchiveConfirm => 'Archive place';

  @override
  String get adminCatalogFlagsRequireApproved =>
      'Verified and featured can only be turned on for an approved or published place.';

  @override
  String get adminCatalogPriceLevel => 'Price level';

  @override
  String get adminCatalogTags => 'Tags';

  @override
  String get adminCatalogAmenities => 'Amenities';

  @override
  String get adminCatalogReadOnlyNotice =>
      'Read-only. Editing a place replaces its tags, opening hours and amenities wholesale, so it is not offered here.';

  @override
  String get adminCatalogNotAHotel =>
      'This place has no hotel detail, so it has no rooms.';

  @override
  String get adminCatalogRoomsEmpty => 'No rooms.';

  @override
  String get adminCatalogRoomsUnavailable => 'Rooms could not be loaded.';

  @override
  String get adminCatalogRoomActive => 'Active';

  @override
  String get adminCatalogRoomInactive => 'Inactive';

  @override
  String get adminCatalogRoomCode => 'Code';

  @override
  String get adminCatalogRoomType => 'Type';

  @override
  String get adminCatalogRoomQuantity => 'Rooms';

  @override
  String get adminCatalogRoomsBoundaryNotice =>
      'Inventory and rates are managed outside the catalog.';

  @override
  String get adminCatalogMediaCount => 'Images';

  @override
  String get adminCatalogMediaCover => 'Cover';

  @override
  String get adminCatalogMediaHasCover => 'Set';

  @override
  String get adminCatalogMediaNoCover => 'None';

  @override
  String get adminCatalogMediaReadOnlyNotice =>
      'Read-only. Media management is a separate admin surface.';

  @override
  String get adminNavMedia => 'Media';

  @override
  String get adminMediaPickOwnerTitle => 'Choose a place';

  @override
  String get adminMediaOwnerScopeNotice =>
      'Media is managed per place. The admin API can only read a place\'s gallery, so rooms, reviews and trip documents are not managed here.';

  @override
  String get adminMediaPlaceSearchLabel => 'Search places';

  @override
  String get adminMediaPlaceSearchClear => 'Clear search';

  @override
  String adminMediaPlaceSearchHint(int count) {
    return 'Showing the first $count matches. Narrow the search to find a specific place.';
  }

  @override
  String get adminMediaNoPlacesFound => 'No places match this search.';

  @override
  String adminMediaOpenGallerySemantic(String name) {
    return 'Open the gallery for $name';
  }

  @override
  String get adminMediaBackToPlaces => 'Back to places';

  @override
  String get adminMediaEmptyTitle => 'No media';

  @override
  String get adminMediaEmptyMessage =>
      'This place has no registered media yet.';

  @override
  String get adminMediaUrlRegistryNotice =>
      'Media is registered by URL. There is no file upload — paste an existing http or https address.';

  @override
  String get adminMediaAmbiguousOrderNotice =>
      'Two or more items share a position, so their order is undefined. Moving any item renumbers the whole gallery and resolves it.';

  @override
  String get adminMediaNoCoverNotice => 'No cover is set for this place.';

  @override
  String adminMediaCoverIs(int id) {
    return 'Cover: item $id';
  }

  @override
  String get adminMediaActionUncertain =>
      'The result of the last action is unknown. The gallery has been reloaded — check it before trying again, because deactivation cannot be undone here.';

  @override
  String get adminMediaDismissNotice => 'Dismiss';

  @override
  String adminMediaAssetSemantic(int id) {
    return 'Media item $id';
  }

  @override
  String get adminMediaUrl => 'URL';

  @override
  String get adminMediaUrlHelper =>
      'An absolute http or https address, including the host.';

  @override
  String get adminMediaUrlQueryHidden =>
      'A query string is present and is not shown here.';

  @override
  String get adminMediaThumbnailUrl => 'Thumbnail URL';

  @override
  String get adminMediaThumbnailUrlOptional => 'Thumbnail URL (optional)';

  @override
  String get adminMediaType => 'Type';

  @override
  String get adminMediaAltText => 'Alt text';

  @override
  String get adminMediaAltTextOptional => 'Alt text (optional)';

  @override
  String get adminMediaSortOrder => 'Position';

  @override
  String get adminMediaSortOrderOptional => 'Position (optional)';

  @override
  String get adminMediaActive => 'Active';

  @override
  String get adminMediaInactive => 'Inactive';

  @override
  String get adminMediaCover => 'Cover';

  @override
  String get adminMediaPreviewUnavailable => 'Preview unavailable';

  @override
  String get adminMediaPreviewNotAnImage => 'Not an image';

  @override
  String get adminMediaAdd => 'Add media';

  @override
  String get adminMediaAddTitle => 'Register media';

  @override
  String get adminMediaEdit => 'Edit';

  @override
  String get adminMediaEditTitle => 'Edit media';

  @override
  String get adminMediaSave => 'Save';

  @override
  String get adminMediaCreate => 'Register';

  @override
  String get adminMediaSetCover => 'Set as cover';

  @override
  String get adminMediaSetAsCover => 'Use as the cover image';

  @override
  String get adminMediaCoverReplacesPrevious =>
      'The place\'s current cover, if any, stops being the cover.';

  @override
  String get adminMediaCoverImageOnly => 'Only an image can be the cover.';

  @override
  String get adminMediaMoveUp => 'Move up';

  @override
  String get adminMediaMoveDown => 'Move down';

  @override
  String get adminMediaEditReplacesNotice =>
      'Saving replaces every field shown here. Clearing a box clears the stored value.';

  @override
  String get adminMediaUrlRequired => 'A URL is required.';

  @override
  String get adminMediaUrlInvalid =>
      'Enter an absolute http or https URL with a host.';

  @override
  String get adminMediaSortOrderInvalid =>
      'Position must be a whole number of 0 or more.';

  @override
  String get adminMediaDeactivate => 'Deactivate';

  @override
  String get adminMediaDeactivateTitle => 'Deactivate this media?';

  @override
  String get adminMediaDeactivateWarningHidden =>
      'It disappears from the place\'s public gallery immediately.';

  @override
  String get adminMediaDeactivateWarningNoRestore =>
      'There is no way to reactivate it from the admin console.';

  @override
  String get adminMediaDeactivateWarningCover =>
      'This item is the cover. The place will have no cover afterwards — nothing is promoted in its place.';

  @override
  String get adminMediaDeactivateAcknowledge =>
      'I understand this cannot be undone here.';

  @override
  String get adminMediaDeactivateConfirm => 'Deactivate media';

  @override
  String get adminCatalogManageMedia => 'Manage media';

  @override
  String adminCatalogManageMediaSemantic(String name) {
    return 'Open the media gallery for $name';
  }

  @override
  String get adminMediaBackToPlaceDetail => 'Back to place details';

  @override
  String adminMediaOwnerContext(int id) {
    return 'Place #$id — all media below belongs to this place';
  }

  @override
  String get adminMediaOwnerMismatch =>
      'This gallery could not be shown: the server returned media belonging to a different place. Nothing here can be changed until the response matches the place that was requested.';

  @override
  String get partnerMessagesTitle => 'Messages';

  @override
  String get partnerMessagesSubtitle =>
      'Guest messages about bookings at the properties you own.';

  @override
  String get partnerMessagesLoading => 'Loading conversations…';

  @override
  String get partnerMessagesEmptyTitle => 'No guest messages yet';

  @override
  String get partnerMessagesEmptyMessage =>
      'When a guest starts a conversation about one of their bookings, it appears here.';

  @override
  String get partnerMessagesUnpaginatedNotice =>
      'This inbox is not paginated — every conversation the server returned is shown.';

  @override
  String partnerMessagesUnreadBadge(int count) {
    return '$count unread';
  }

  @override
  String partnerMessagesUnreadTotal(int count, int total) {
    return '$count unread across $total conversations';
  }

  @override
  String get partnerMessagesNoPreview => 'No messages yet';

  @override
  String get partnerMessagesNoSubject => 'No subject';

  @override
  String partnerMessagesBookingLabel(String code) {
    return 'Booking $code';
  }

  @override
  String partnerMessagesGuestLabel(String name) {
    return 'Guest: $name';
  }

  @override
  String partnerMessagesOpenSemantic(String code) {
    return 'Open the conversation for booking $code';
  }

  @override
  String get partnerMessagesBackToInbox => 'Back to inbox';

  @override
  String get partnerMessagesThreadLoading => 'Loading conversation…';

  @override
  String get partnerMessagesThreadEmpty =>
      'This conversation has no messages yet.';

  @override
  String get partnerMessagesUnavailableTitle => 'Conversation not available';

  @override
  String get partnerMessagesUnavailableMessage =>
      'This conversation could not be opened. It may no longer exist. Return to the inbox and refresh.';

  @override
  String get partnerMessagesSenderHost => 'You';

  @override
  String get partnerMessagesSenderGuest => 'Guest';

  @override
  String get partnerMessagesSenderSupport => 'Support';

  @override
  String get partnerMessagesStatusOpen => 'Open';

  @override
  String get partnerMessagesStatusClosed => 'Closed';

  @override
  String get partnerMessagesStatusArchived => 'Archived';

  @override
  String get partnerMessagesComposerLabel => 'Reply to the guest';

  @override
  String get partnerMessagesComposerHint => 'Write your reply…';

  @override
  String get partnerMessagesSend => 'Send';

  @override
  String get partnerMessagesSending => 'Sending…';

  @override
  String get partnerMessagesSendEmpty => 'Write a message before sending.';

  @override
  String get partnerMessagesSent => 'Message sent.';

  @override
  String get partnerMessagesSendFailed => 'The message could not be sent.';

  @override
  String get partnerMessagesSendUncertain =>
      'The connection timed out and your message may already have been sent. Reopen this conversation to check before writing it again — it will not be sent automatically.';

  @override
  String get partnerMessagesArchivedNotice =>
      'This conversation was archived and can no longer receive messages.';

  @override
  String get partnerMessagesClosedNotice =>
      'This conversation is closed. Sending a reply reopens it for the guest.';

  @override
  String get partnerNotificationsTitle => 'Notifications';

  @override
  String get partnerNotificationsSubtitle =>
      'Everything your account has received, newest first.';

  @override
  String get partnerNotificationsLoading => 'Loading notifications…';

  @override
  String get partnerNotificationsEmptyTitle => 'No notifications yet';

  @override
  String get partnerNotificationsEmptyMessage =>
      'Updates about your properties, bookings, reviews and guest messages will appear here.';

  @override
  String get partnerNotificationsInboxNotice =>
      'This is your account\'s complete inbox. It can include platform announcements and personal travel updates as well as property activity — the server does not label notifications by audience.';

  @override
  String get partnerNotificationsUnpaginatedNotice =>
      'This inbox is not paginated — every notification the server returned is shown.';

  @override
  String get partnerNotificationsUnreadLabel => 'New';

  @override
  String get partnerNotificationsMarkRead => 'Mark as read';

  @override
  String get partnerNotificationsMarkAllRead => 'Mark all as read';

  @override
  String get partnerNotificationsMarkedRead => 'Marked as read.';

  @override
  String get partnerNotificationsMarkedAllRead =>
      'All notifications marked as read.';

  @override
  String get partnerNotificationsDelete => 'Delete';

  @override
  String get partnerNotificationsDeleteTitle => 'Delete this notification?';

  @override
  String get partnerNotificationsDeleteMessage =>
      'It will be removed from the server permanently. There is no archive and this cannot be undone.';

  @override
  String get partnerNotificationsDeleteCta => 'Delete permanently';

  @override
  String get partnerNotificationsDeleted => 'Notification deleted.';

  @override
  String get partnerNotificationsActionFailed =>
      'That could not be completed. Nothing was changed.';

  @override
  String get partnerNotificationsActionBusy =>
      'Please wait for the current action to finish.';

  @override
  String get partnerNotificationsActionNotFound =>
      'This notification no longer exists. Refresh to see the current list.';

  @override
  String get partnerNotificationsNoDestination =>
      'This notification does not link to a screen in the partner workspace.';

  @override
  String get partnerNotificationsTypeUnknown => 'Notification';

  @override
  String get adminReviewModerationNotice =>
      'Moderation changes what guests see. Every action is confirmed first and recorded in the activity log.';

  @override
  String get adminReviewApprove => 'Approve';

  @override
  String get adminReviewReject => 'Reject';

  @override
  String get adminReviewHide => 'Hide';

  @override
  String get adminReviewActionCurrent => 'This review already has that status.';

  @override
  String get adminReviewApproveTitle => 'Approve this review?';

  @override
  String get adminReviewApproveWarning =>
      'It becomes publicly visible, counts towards the place\'s rating, and its author is notified.';

  @override
  String get adminReviewApproveConfirm => 'Approve review';

  @override
  String get adminReviewRejectTitle => 'Reject this review?';

  @override
  String get adminReviewRejectWarning =>
      'It stays hidden from guests and its author is notified, together with the reason you give below.';

  @override
  String get adminReviewRejectConfirm => 'Reject review';

  @override
  String get adminReviewRejectReasonLabel => 'Reason for rejection';

  @override
  String get adminReviewRejectReasonHelp =>
      'Sent to the review\'s author. Keep it factual.';

  @override
  String get adminReviewRejectReasonRequired =>
      'Enter a reason before rejecting.';

  @override
  String get adminReviewHideTitle => 'Hide this review?';

  @override
  String get adminReviewHideWarning =>
      'It disappears from the place\'s public page and stops counting towards its rating. Its author is not notified.';

  @override
  String get adminReviewHideConfirm => 'Hide review';

  @override
  String get adminReviewModerated => 'Review updated.';

  @override
  String get adminReviewModerationFailed =>
      'The review could not be updated. Nothing was changed.';

  @override
  String get adminNavReferenceData => 'Reference data';

  @override
  String get adminReferenceTabAmenities => 'Amenities';

  @override
  String get adminReferenceTabCategories => 'Categories';

  @override
  String get adminReferenceCmsStatusNotice =>
      'CMS status controls whether an entry is marked active in this console. It does not currently filter public or customer API results — the backend stores the flag but no read applies it.';

  @override
  String get adminReferenceNoDeleteNotice =>
      'Reference entries cannot be deleted. The admin API provides list, create, update and CMS status only.';

  @override
  String get adminReferenceOrderingNotice =>
      'Rows appear in the order the server returned them. The backend applies no ordering and does not sort by sort order.';

  @override
  String get adminReferenceUpdateReplacesNotice =>
      'Saving replaces every field on this entry, so clearing a box clears the stored value.';

  @override
  String get adminReferenceSlugHelper =>
      'Leave blank and the server derives the slug from the name. It cannot be changed after the entry is created.';

  @override
  String get adminReferenceSlugFixedNotice =>
      'The slug is fixed after creation. Other parts of the system resolve this entry by slug, so it is not editable here.';

  @override
  String get adminReferenceTypeNotice =>
      'Type is used to target coupons and personalization rules, so it is chosen from existing values rather than typed.';

  @override
  String get adminReferenceParentGuardNotice =>
      'This category and everything beneath it are not offered, so a parent cannot be set to a child of itself.';

  @override
  String get adminReferenceStatusPublicNotice =>
      'This changes CMS status only. It does not guarantee the entry is removed from public or customer API results.';

  @override
  String get adminReferenceNewAmenity => 'New amenity';

  @override
  String get adminReferenceNewCategory => 'New category';

  @override
  String get adminReferenceRefresh => 'Refresh';

  @override
  String get adminReferenceEdit => 'Edit';

  @override
  String get adminReferenceSave => 'Save';

  @override
  String get adminReferenceCreate => 'Create';

  @override
  String get adminReferenceDismiss => 'Dismiss';

  @override
  String get adminReferenceAmenityCreateTitle => 'New amenity';

  @override
  String get adminReferenceAmenityEditTitle => 'Edit amenity';

  @override
  String get adminReferenceCategoryCreateTitle => 'New category';

  @override
  String get adminReferenceCategoryEditTitle => 'Edit category';

  @override
  String get adminReferenceFieldName => 'Name';

  @override
  String get adminReferenceFieldSlug => 'Slug';

  @override
  String get adminReferenceFieldIcon => 'Icon';

  @override
  String get adminReferenceFieldGroup => 'Group';

  @override
  String get adminReferenceFieldDescription => 'Description';

  @override
  String get adminReferenceFieldSortOrder => 'Sort order';

  @override
  String get adminReferenceFieldType => 'Type';

  @override
  String get adminReferenceFieldParent => 'Parent category';

  @override
  String get adminReferenceFieldColor => 'Colour';

  @override
  String get adminReferenceFieldCoverImageUrl => 'Cover image URL';

  @override
  String get adminReferenceParentNone => 'No parent (top level)';

  @override
  String get adminReferenceValueNotSet => 'Not set';

  @override
  String get adminReferenceNameRequired => 'Enter a name.';

  @override
  String get adminReferenceSortOrderInvalid =>
      'Enter a whole number, or leave blank.';

  @override
  String get adminReferenceColName => 'Name';

  @override
  String get adminReferenceColSlug => 'Slug';

  @override
  String get adminReferenceColGroup => 'Group';

  @override
  String get adminReferenceColType => 'Type';

  @override
  String get adminReferenceColParent => 'Parent';

  @override
  String get adminReferenceColSortOrder => 'Sort order';

  @override
  String get adminReferenceColCmsStatus => 'CMS status';

  @override
  String get adminReferenceColAction => 'Actions';

  @override
  String get adminReferenceStatusActive => 'Active in CMS';

  @override
  String get adminReferenceStatusInactive => 'Inactive in CMS';

  @override
  String get adminReferenceActivate => 'Activate in CMS';

  @override
  String get adminReferenceDeactivate => 'Deactivate in CMS';

  @override
  String get adminReferenceActivateTitle => 'Activate in CMS?';

  @override
  String get adminReferenceDeactivateTitle => 'Deactivate in CMS?';

  @override
  String adminReferenceActivateBody(String name) {
    return '$name will be marked active in the CMS.';
  }

  @override
  String adminReferenceDeactivateBody(String name) {
    return '$name will be marked inactive in the CMS.';
  }

  @override
  String get adminReferenceStatusConfirm => 'Update CMS status';

  @override
  String get adminReferenceMutationFailed =>
      'The entry could not be saved. Nothing was changed.';

  @override
  String get adminReferenceDuplicateSlug =>
      'That slug is already in use. Choose a different name or slug.';

  @override
  String get adminReferenceMutationUncertain =>
      'The result of the last action is unknown. This list has been reloaded — check it before trying again.';

  @override
  String get adminReferenceEmptyAmenities => 'No amenities yet.';

  @override
  String get adminReferenceEmptyCategories => 'No categories yet.';

  @override
  String adminReferenceEditSemantic(String name) {
    return 'Edit $name';
  }

  @override
  String get adminReferenceTabLocations => 'Locations';

  @override
  String get adminLocationNew => 'New location';

  @override
  String get adminLocationCreateTitle => 'New location';

  @override
  String get adminLocationEditTitle => 'Edit location';

  @override
  String get adminLocationColCode => 'Code';

  @override
  String get adminLocationColLevel => 'Level';

  @override
  String get adminLocationColCoordinates => 'Coordinates';

  @override
  String get adminLocationFieldCode => 'Code';

  @override
  String get adminLocationFieldOldName => 'Former name';

  @override
  String get adminLocationFieldFullPath => 'Full path';

  @override
  String get adminLocationFieldLevel => 'Level';

  @override
  String get adminLocationFieldCoordinates => 'Coordinates';

  @override
  String get adminLocationCodeHelper =>
      'Optional. A short business key other systems match this location by.';

  @override
  String get adminLocationCodeHelperFixed =>
      'A code can be replaced but not removed — other systems match this location by it.';

  @override
  String get adminLocationCodeCannotBeCleared =>
      'A code cannot be removed. Enter a replacement, or leave the existing one in place.';

  @override
  String get adminLocationReadOnlyNotice =>
      'The values below are stored by the server and are not editable here. They are saved back unchanged.';

  @override
  String get adminLocationFieldParent => 'Parent location';

  @override
  String get adminLocationParentHint => 'Choose a parent location';

  @override
  String get adminLocationParentRequired =>
      'This type needs a parent location. Only a COUNTRY can be top level.';

  @override
  String get adminLocationParentNoCandidates =>
      'No loaded location can be the parent of this type.';

  @override
  String get adminLocationParentCleared =>
      'The previous parent cannot hold this type, so it was cleared. Choose a new parent.';

  @override
  String get adminLocationParentGuardNotice =>
      'This location and everything beneath it are not offered, so it cannot be placed under itself.';

  @override
  String get adminLocationHierarchyRule =>
      'A COUNTRY is top level. A PROVINCE or CITY goes under a COUNTRY. An AREA goes under a PROVINCE or CITY.';

  @override
  String get adminLocationTypeReservedMarker => 'Reserved — not available';

  @override
  String get adminLocationTypeUnavailable =>
      'This type cannot be saved. WARD and COMMUNE are reserved; choose COUNTRY, PROVINCE, CITY or AREA.';

  @override
  String get adminLocationTypeBlockedByChildren =>
      'This location has child locations that cannot sit under this type. Keep the current type, or move those children first.';

  @override
  String get adminLocationFullPathGeneratedNotice =>
      'Generated by the server from the parent and name when saved. This preview is only a guide.';

  @override
  String get adminLocationEmpty => 'No locations yet.';

  @override
  String get adminLocationFilterEmpty => 'No locations match this search.';

  @override
  String get adminLocationFilterLabel => 'Search locations';

  @override
  String get adminLocationFilterHelper =>
      'Filters the locations already loaded, by name, slug, code or former name.';

  @override
  String get adminLocationFilterClear => 'Clear search';

  @override
  String get adminLocationDuplicateCodeOrSlug =>
      'That code or slug is already in use. Choose a different one.';

  @override
  String get surfaceTitlePartner => 'Plan Your Trip Partner';

  @override
  String get surfaceTitleAdmin => 'Plan Your Trip Admin';

  @override
  String get authPartnerLoginHero =>
      'Run your properties, bookings and payouts from one workspace.';

  @override
  String get authPartnerLoginTitle => 'Partner sign in';

  @override
  String get authPartnerLoginSubtitle =>
      'Sign in with your partner account to open the workspace.';

  @override
  String get authAdminLoginHero => 'Operate the Plan Your Trip platform.';

  @override
  String get authAdminLoginTitle => 'Admin sign in';

  @override
  String get authAdminLoginSubtitle =>
      'Sign in with an administrator account to open the console.';

  @override
  String get authStaffAccountRequired =>
      'Demo Mode and self sign-up are only available in the traveller app. This workspace needs an existing account.';

  @override
  String get surfaceAccessDeniedTitle =>
      'You don\'t have access to this application';

  @override
  String get surfaceAccessDeniedUser =>
      'This account can\'t use the traveller app. Sign out, then sign in with a traveller account.';

  @override
  String get surfaceAccessDeniedPartner =>
      'This account can\'t use the Partner workspace. Sign out, then sign in with a partner account.';

  @override
  String get surfaceAccessDeniedAdmin =>
      'This account can\'t use the Admin console. Sign out, then sign in with an administrator account.';

  @override
  String surfaceSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get surfaceSignOut => 'Sign out';

  @override
  String get surfaceConfigErrorTitle => 'This application isn\'t configured';

  @override
  String get surfaceConfigErrorBody =>
      'It couldn\'t tell which application to open. Start it with one of the documented entrypoints.';

  @override
  String get adminReviewModerationUncertain =>
      'The result of the last action is unknown. This page has been reloaded — check the review\'s status before trying again.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get authErrorNetwork =>
      'Cannot reach the server. Check your connection and try again.';

  @override
  String get authErrorTimeout =>
      'The server did not respond in time. Please try again.';

  @override
  String get authErrorServer =>
      'The service is temporarily unavailable. Please try again later.';

  @override
  String get authErrorValidation => 'Please check the highlighted fields.';

  @override
  String get authErrorEmailTaken =>
      'That email address already has an account.';

  @override
  String get authErrorInvalidCredentials => 'Email or password is incorrect.';

  @override
  String get authErrorAccountDisabled =>
      'This account is disabled. Contact support to restore access.';

  @override
  String get authErrorAccountUnavailable =>
      'This account cannot sign in. Contact support.';

  @override
  String get authErrorEmailNotVerified =>
      'Verify your email address before signing in.';

  @override
  String get authErrorTokenInvalid =>
      'This link is invalid or has already been used.';

  @override
  String get authErrorTokenExpired =>
      'This link has expired. Request a new one.';

  @override
  String get authErrorCurrentPassword => 'Your current password is incorrect.';

  @override
  String get authErrorPasswordUnchanged =>
      'Choose a password different from your current one.';

  @override
  String get authErrorEmailDelivery =>
      'Email delivery is unavailable right now. Please try again later.';

  @override
  String get authErrorSessionExpired =>
      'Your session has expired. Sign in again.';

  @override
  String get authValidationPasswordMax => 'Password must be at most 72 bytes.';

  @override
  String get authValidationTermsRequired =>
      'Accept the Partner terms to continue.';

  @override
  String get authValidationTokenRequired => 'Paste the token from your link.';

  @override
  String get authPartnerBecomeQuestion => 'New to Plan Your Trip?';

  @override
  String get authPartnerBecomeAction => 'Become a Partner';

  @override
  String get partnerRegisterTitle => 'Create your Partner account';

  @override
  String get partnerRegisterSubtitle =>
      'List your property and manage bookings, rates and payouts in one workspace.';

  @override
  String get partnerRegisterAction => 'Create Partner account';

  @override
  String get partnerRegisterTerms => 'I agree to the Partner terms';

  @override
  String get partnerRegisterTermsHint =>
      'The terms version you accept is recorded with your account.';

  @override
  String get partnerRegisterHaveAccount => 'Already have a Partner account?';

  @override
  String get partnerRegisterSignInAction => 'Sign in';

  @override
  String get verifyEmailTitle => 'Verify your email';

  @override
  String verifyEmailSubtitle(String email) {
    return 'Your Partner account for $email is created. Verify the address to sign in.';
  }

  @override
  String get verifyEmailNoDeliveryNotice =>
      'In local development no email is delivered. The backend logs a verification link marked [DEV ONLY — NO EMAIL SENT]; copy the token after #token= and paste it below.';

  @override
  String get verifyEmailTokenLabel => 'Verification token';

  @override
  String get verifyEmailAction => 'Verify email';

  @override
  String get verifyEmailSuccessTitle => 'Email verified successfully';

  @override
  String get verifyEmailSuccessBody =>
      'Your address is verified. You can sign in to the Partner workspace now.';

  @override
  String get verifyEmailAlreadyTitle => 'Already verified';

  @override
  String get verifyEmailAlreadyBody =>
      'This email address is already verified. You can sign in.';

  @override
  String get verifyEmailContinueAction => 'Continue to Partner sign in';

  @override
  String get verifyEmailResendAction => 'Resend verification';

  @override
  String verifyEmailResendCooldown(int seconds) {
    return 'You can request another verification link in $seconds seconds.';
  }

  @override
  String get verifyEmailResendAck =>
      'If that address is waiting for verification, a new link is on its way.';

  @override
  String get verifyEmailBackAction => 'Back to Partner sign in';

  @override
  String get forgotPasswordAck =>
      'If that address has an account, a password reset link is on its way.';

  @override
  String get forgotPasswordNoDeliveryNotice =>
      'In local development no email is delivered. The backend logs the reset link marked [DEV ONLY — NO EMAIL SENT].';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get resetPasswordSubtitle =>
      'Paste the token from your reset link and choose a new password.';

  @override
  String get resetPasswordTokenLabel => 'Reset token';

  @override
  String get resetPasswordNewLabel => 'New password';

  @override
  String get resetPasswordAction => 'Reset password';

  @override
  String get resetPasswordSuccessTitle => 'Password reset';

  @override
  String get resetPasswordSuccessBody =>
      'Your password has been changed and every other session was signed out.';

  @override
  String get resetPasswordBackAction => 'Back to sign in';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordSubtitle =>
      'Changing your password signs out every other device.';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordAction => 'Update password';

  @override
  String get changePasswordSuccess => 'Password changed successfully.';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountDetailsHeading => 'Account details';

  @override
  String get accountRoleLabel => 'Role';

  @override
  String get accountRolePartner => 'Partner';

  @override
  String get accountRoleAdmin => 'Administrator';

  @override
  String get accountRoleUser => 'Traveller';

  @override
  String get accountSecurityHeading => 'Security';

  @override
  String get accountSecurityBody => 'Update the password you use to sign in.';

  @override
  String get accountBackToWorkspace => 'Back to workspace';

  @override
  String get accountBackToConsole => 'Back to console';

  @override
  String get accountOpenAction => 'Account';

  @override
  String get partnerBusinessHeading => 'Business profile';

  @override
  String get partnerBusinessNoneTitle => 'No business profile yet';

  @override
  String get partnerBusinessNoneBody =>
      'Add your business information and submit it for review to open the Partner workspace.';

  @override
  String get partnerBusinessAddAction => 'Add business information';

  @override
  String get partnerBusinessEditAction => 'Edit business information';

  @override
  String get partnerBusinessSaveAction => 'Save';

  @override
  String get partnerBusinessSubmitAction => 'Save and submit for review';

  @override
  String get partnerBusinessSavedMessage => 'Business information saved.';

  @override
  String get partnerBusinessSubmittedMessage => 'Submitted for review.';

  @override
  String get partnerBusinessStatusDraftBody =>
      'Complete your business information and submit it for review.';

  @override
  String get partnerBusinessStatusSubmittedBody =>
      'Your Partner application is awaiting review by an administrator.';

  @override
  String get partnerBusinessStatusApprovedBody =>
      'Your Partner account is approved. The workspace is open.';

  @override
  String get partnerBusinessStatusRejectedBody =>
      'Your application was rejected. Update your business information and submit it again.';

  @override
  String get partnerBusinessStatusSuspendedBody =>
      'Your Partner access is currently suspended. Contact support.';

  @override
  String get partnerBusinessStatusUnknownBody =>
      'This profile has a status this app does not recognise.';

  @override
  String partnerBusinessRejectReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get partnerBusinessFieldName => 'Business name';

  @override
  String get partnerBusinessFieldType => 'Business type';

  @override
  String get partnerBusinessFieldRepresentative => 'Representative name';

  @override
  String get partnerBusinessFieldPhone => 'Business phone';

  @override
  String get partnerBusinessFieldEmail => 'Business email';

  @override
  String get partnerBusinessFieldAddress => 'Business address';

  @override
  String get partnerBusinessFieldTaxCode => 'Tax code';

  @override
  String get partnerBusinessFieldWebsite => 'Website';

  @override
  String partnerBusinessOptionalSuffix(String label) {
    return '$label (optional)';
  }

  @override
  String get partnerBusinessTypeHotel => 'Hotel';

  @override
  String get partnerBusinessTypeRestaurant => 'Restaurant';

  @override
  String get partnerBusinessTypeCafe => 'Cafe';

  @override
  String get partnerBusinessTypeTourOperator => 'Tour operator';

  @override
  String get partnerBusinessTypeTransport => 'Transport';

  @override
  String get partnerBusinessTypeOther => 'Other';

  @override
  String get partnerBusinessTypeUnknown => 'Unrecognised type';

  @override
  String get partnerBusinessValidationRequired => 'This field is required.';
}
