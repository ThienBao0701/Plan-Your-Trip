import 'package:flutter/widgets.dart';
import 'mock/app_models.dart';
import 'mock/mock_data.dart';
import 'network/api_client.dart';
import 'storage/preference_storage.dart';
import 'storage/session_storage.dart';

class AppState extends ChangeNotifier {
  final ApiClient api;
  final SessionStorage storage;
  final PreferenceStorage preferences;
  final DateTime Function() now;
  final String Function(int sequence) _bookingCodeGenerator;
  int _bookingSequence = 0;

  AppState({
    ApiClient? api,
    SessionStorage? storage,
    PreferenceStorage? preferences,
    DateTime Function()? now,
    String Function(int sequence)? bookingCodeGenerator,
  })  : api = api ?? ApiClient(),
        storage = storage ?? SessionStorage(),
        preferences = preferences ?? PreferenceStorage(),
        now = now ?? DateTime.now,
        _bookingCodeGenerator = bookingCodeGenerator ??
            ((sequence) => 'PYT-DEMO-${sequence.toString().padLeft(4, '0')}');

  bool demoMode = true;
  String? email;
  Locale? localeOverride;
  bool tripRemindersEnabled = true;
  bool bookingUpdatesEnabled = true;
  bool travelTipsEnabled = false;
  bool reduceMotionEnabled = false;

  List<Place> places = List.from(MockData.places);
  List<SavedPlaceRecord> savedPlaces = List.from(MockData.demoSavedPlaces);
  List<SavedCollectionRecord> savedCollections =
      List.from(MockData.demoSavedCollections);
  List<SavedCollectionPlaceRecord> savedCollectionPlaces =
      List.from(MockData.demoSavedCollectionPlaces);

  // ── Real Mode Saved Collections (/api/me/collections, UI-17) ─────────────
  // Kept entirely separate from the demo-only fields above — never merged.
  List<CollectionSummaryRecord> realSavedCollections = [];
  bool realSavedCollectionsLoading = false;
  bool realSavedCollectionsLoaded = false;
  SavedCollectionActionResult? realSavedCollectionsError;
  int? realSelectedCollectionId;
  CollectionDetailRecord? realSelectedCollectionDetail;
  bool realCollectionDetailLoading = false;
  SavedCollectionActionResult? realCollectionDetailError;
  bool realCollectionCreateInFlight = false;
  bool realCollectionUpdateInFlight = false;
  bool realCollectionDeleteInFlight = false;
  bool realCollectionPlaceActionInFlight = false;

  // ── Real Mode Wishlist (/api/me/wishlist, UI-18) ─────────────────────────
  // Parallel to the demo-only [savedPlaces] list — never merged. A 401 here
  // never calls logout()/clears state; the caller shows a re-auth prompt.
  List<WishlistItemRecord> realWishlist = [];
  bool realWishlistLoading = false;
  bool realWishlistLoaded = false;
  WishlistActionResult? realWishlistError;
  // Per-placeId in-flight guard: many bookmark buttons for different places can
  // be live at once, so a single bool would over-block unrelated toggles.
  final Set<int> realWishlistActionInFlight = <int>{};

  // ── Real place-detail hydration cache (UI19) ──────────────────────────────
  // Partial saved records (wishlist / collection) only carry a summary; a full
  // [Place] is fetched on demand from the public place-detail endpoint and
  // cached for the authenticated session. Cleared on logout / mode / user
  // change so no stale place survives. Only successful hydrations are cached.
  final Map<int, Place> _hydratedRealPlaces = <int, Place>{};
  // In-flight requests keyed by placeId: a second caller for the same place
  // awaits the same Future, so concurrent taps issue a single HTTP request.
  final Map<int, Future<PlaceHydrationResult>> _hydrationInFlight =
      <int, Future<PlaceHydrationResult>>{};

  // ── Real Mode Trips (/api/me/trips, UI-20 TripPlan planner) ───────────────
  // Parallel to the demo-only [trips]/[timeline] lists — never merged. A 401
  // here never calls logout()/clears session; the caller shows a re-auth sheet.
  List<TripSummaryRecord> realTrips = [];
  bool realTripsLoading = false;
  bool realTripsLoaded = false;
  bool realTripsRefreshing = false;
  TripActionResult? realTripsError;
  int? realSelectedTripId;
  TripDetailRecord? realSelectedTripDetail;
  bool realTripDetailLoading = false;
  TripActionResult? realTripDetailError;
  bool realTripCreateInFlight = false;
  // Add-day / add-item run from a single modal at a time, so one bool guards
  // double-submission for both.
  bool realTripActionInFlight = false;

  List<Trip> trips = List.from(MockData.trips);
  List<TimelineItem> timeline = List.from(MockData.timeline);
  List<Expense> expenses = List.from(MockData.expenses);
  List<DemoBooking> demoBookings = List.from(MockData.demoBookings);
  TravelCreditAccount? travelCreditAccount = MockData.travelCreditAccount;
  List<TravelCreditTransaction> travelCreditTransactions =
      List.from(MockData.travelCreditTransactions);
  LoyaltyAccount? loyaltyAccount = MockData.loyaltyAccount;
  List<LoyaltyTransaction> loyaltyTransactions =
      List.from(MockData.loyaltyTransactions);
  MembershipAccount? membershipAccount = MockData.membershipAccount;
  MembershipProgress? membershipProgress = MockData.membershipProgress;
  List<MembershipBenefit> membershipBenefits =
      List.from(MockData.membershipBenefits);
  List<MembershipHistoryItem> membershipHistory =
      List.from(MockData.membershipHistory);
  List<CustomerCoupon> coupons = List.from(MockData.coupons);
  ReferralSummary? referralSummary = MockData.referralSummary;
  List<ReferralHistoryItem> referralHistory =
      List.from(MockData.referralHistory);
  List<GiftCard> giftCards = List.from(MockData.giftCards);
  List<TravelWalletItem> travelWalletItems =
      List.from(MockData.travelWalletItems);
  List<TripDocument> tripDocuments = List.from(MockData.tripDocuments);
  List<TripCollaborator> tripCollaborators =
      List.from(MockData.tripCollaborators);
  List<SharedTripSummary> sharedTrips = List.from(MockData.sharedTrips);
  List<TripNote> tripNotes = List.from(MockData.tripNotes);
  List<PackingItem> packingItems = List.from(MockData.packingItems);
  List<TripReminder> tripReminders = List.from(MockData.tripReminders);
  List<TravelerReview> reviews = List.from(MockData.reviews);
  List<DemoPaymentAttempt> demoPaymentAttempts =
      List.from(MockData.demoPaymentAttempts);
  List<UserNotification> userNotifications =
      List.from(MockData.demoNotifications);
  Set<int> publicTripIds = Set<int>.from(MockData.publicTripIds);
  List<Category> get categories => MockData.categories;

  // ── Session ──────────────────────────────────────────────────────────────

  Future<void> restore() async {
    final savedEmail = await storage.email();
    final savedToken = await storage.token();
    final savedDemo = await storage.demo();
    api.token = savedToken;
    api.demoMode = savedDemo;
    demoMode = savedDemo;
    email = savedDemo || savedToken != null ? savedEmail : null;
    _applyPersonalDataMode();
    localeOverride = await preferences.locale();
    tripRemindersEnabled = await preferences.tripReminders();
    bookingUpdatesEnabled = await preferences.bookingUpdates();
    travelTipsEnabled = await preferences.travelTips();
    reduceMotionEnabled = await preferences.reduceMotion();
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String e, String p) async {
    final r = await api.login(e.trim(), p);
    if (r['success'] == true) {
      email = e.trim();
      demoMode = r['demo'] == true;
      _applyPersonalDataMode();
      await storage.save(
          email: email!, token: r['token'] as String?, demo: demoMode);
      notifyListeners();
    }
    return r;
  }

  Future<Map<String, dynamic>> register(String name, String e, String p) =>
      api.register(name, e, p);

  Future<void> logout() async {
    await storage.clear();
    api.token = null;
    api.demoMode = true;
    email = null;
    demoMode = true;
    places = List.from(MockData.places);
    savedPlaces = List.from(MockData.demoSavedPlaces);
    savedCollections = List.from(MockData.demoSavedCollections);
    savedCollectionPlaces = List.from(MockData.demoSavedCollectionPlaces);
    _resetRealSavedCollectionsState();
    _resetRealWishlistState();
    clearRealPlaceHydrationCache();
    _resetRealTripsState();
    trips = List.from(MockData.trips);
    timeline = List.from(MockData.timeline);
    expenses = List.from(MockData.expenses);
    demoBookings = List.from(MockData.demoBookings);
    travelWalletItems = List.from(MockData.travelWalletItems);
    tripDocuments = List.from(MockData.tripDocuments);
    tripCollaborators = List.from(MockData.tripCollaborators);
    sharedTrips = List.from(MockData.sharedTrips);
    tripNotes = List.from(MockData.tripNotes);
    packingItems = List.from(MockData.packingItems);
    tripReminders = List.from(MockData.tripReminders);
    reviews = List.from(MockData.reviews);
    demoPaymentAttempts = List.from(MockData.demoPaymentAttempts);
    userNotifications = List.from(MockData.demoNotifications);
    publicTripIds = Set<int>.from(MockData.publicTripIds);
    _applyRewardDataMode();
    notifyListeners();
  }

  void _resetRealSavedCollectionsState() {
    realSavedCollections = [];
    realSavedCollectionsLoading = false;
    realSavedCollectionsLoaded = false;
    realSavedCollectionsError = null;
    realSelectedCollectionId = null;
    realSelectedCollectionDetail = null;
    realCollectionDetailLoading = false;
    realCollectionDetailError = null;
    realCollectionCreateInFlight = false;
    realCollectionUpdateInFlight = false;
    realCollectionDeleteInFlight = false;
    realCollectionPlaceActionInFlight = false;
  }

  void _resetRealWishlistState() {
    realWishlist = [];
    realWishlistLoading = false;
    realWishlistLoaded = false;
    realWishlistError = null;
    realWishlistActionInFlight.clear();
  }

  /// Drops every hydrated real place and abandons in-flight hydration tracking.
  /// Called on logout / mode / user change so one account never sees another's
  /// (or a stale) hydrated place. In-flight Futures are allowed to complete but
  /// their results are no longer cached (the map they'd remove themselves from
  /// is already empty).
  void clearRealPlaceHydrationCache() {
    _hydratedRealPlaces.clear();
    _hydrationInFlight.clear();
  }

  void _resetRealTripsState() {
    realTrips = [];
    realTripsLoading = false;
    realTripsLoaded = false;
    realTripsRefreshing = false;
    realTripsError = null;
    realSelectedTripId = null;
    realSelectedTripDetail = null;
    realTripDetailLoading = false;
    realTripDetailError = null;
    realTripCreateInFlight = false;
    realTripActionInFlight = false;
  }

  void _applyPersonalDataMode() {
    if (demoMode) {
      savedPlaces = List.from(MockData.demoSavedPlaces);
      savedCollections = List.from(MockData.demoSavedCollections);
      savedCollectionPlaces = List.from(MockData.demoSavedCollectionPlaces);
      _resetRealSavedCollectionsState();
      _resetRealWishlistState();
      clearRealPlaceHydrationCache();
      _resetRealTripsState();
      trips = List.from(MockData.trips);
      timeline = List.from(MockData.timeline);
      expenses = List.from(MockData.expenses);
      demoBookings = List.from(MockData.demoBookings);
      travelWalletItems = List.from(MockData.travelWalletItems);
      tripDocuments = List.from(MockData.tripDocuments);
      tripCollaborators = List.from(MockData.tripCollaborators);
      sharedTrips = List.from(MockData.sharedTrips);
      tripNotes = List.from(MockData.tripNotes);
      packingItems = List.from(MockData.packingItems);
      tripReminders = List.from(MockData.tripReminders);
      reviews = List.from(MockData.reviews);
      demoPaymentAttempts = List.from(MockData.demoPaymentAttempts);
      userNotifications = List.from(MockData.demoNotifications);
      publicTripIds = Set<int>.from(MockData.publicTripIds);
      _applyRewardDataMode();
      return;
    }
    trips = [];
    savedPlaces = [];
    savedCollections = [];
    savedCollectionPlaces = [];
    _resetRealSavedCollectionsState();
    _resetRealWishlistState();
    clearRealPlaceHydrationCache();
    _resetRealTripsState();
    timeline = [];
    expenses = [];
    demoBookings = [];
    travelWalletItems = [];
    tripDocuments = [];
    tripCollaborators = [];
    sharedTrips = [];
    tripNotes = [];
    packingItems = [];
    tripReminders = [];
    reviews = [];
    demoPaymentAttempts = [];
    userNotifications = [];
    publicTripIds = {};
    _applyRewardDataMode();
  }

  void _applyRewardDataMode() {
    if (demoMode) {
      travelCreditAccount = MockData.travelCreditAccount;
      travelCreditTransactions = List.from(MockData.travelCreditTransactions);
      loyaltyAccount = MockData.loyaltyAccount;
      loyaltyTransactions = List.from(MockData.loyaltyTransactions);
      membershipAccount = MockData.membershipAccount;
      membershipProgress = MockData.membershipProgress;
      membershipBenefits = List.from(MockData.membershipBenefits);
      membershipHistory = List.from(MockData.membershipHistory);
      coupons = List.from(MockData.coupons);
      referralSummary = MockData.referralSummary;
      referralHistory = List.from(MockData.referralHistory);
      giftCards = List.from(MockData.giftCards);
      return;
    }
    travelCreditAccount = null;
    travelCreditTransactions = [];
    loyaltyAccount = null;
    loyaltyTransactions = [];
    membershipAccount = null;
    membershipProgress = null;
    membershipBenefits = [];
    membershipHistory = [];
    coupons = [];
    referralSummary = null;
    referralHistory = [];
    giftCards = [];
  }

  // ── Local preferences ────────────────────────────────────────────────────

  Future<void> setLocaleOverride(Locale? locale) async {
    localeOverride = locale;
    await preferences.saveLocale(locale);
    notifyListeners();
  }

  Future<void> setTripRemindersEnabled(bool value) async {
    tripRemindersEnabled = value;
    await preferences.saveTripReminders(value);
    notifyListeners();
  }

  Future<void> setBookingUpdatesEnabled(bool value) async {
    bookingUpdatesEnabled = value;
    await preferences.saveBookingUpdates(value);
    notifyListeners();
  }

  Future<void> setTravelTipsEnabled(bool value) async {
    travelTipsEnabled = value;
    await preferences.saveTravelTips(value);
    notifyListeners();
  }

  Future<void> setReduceMotionEnabled(bool value) async {
    reduceMotionEnabled = value;
    await preferences.saveReduceMotion(value);
    notifyListeners();
  }

  // ── Notifications ───────────────────────────────────────────────────────

  List<UserNotification> get visibleNotifications {
    if (!demoMode) return const <UserNotification>[];
    return List<UserNotification>.from(userNotifications)
      ..sort(_compareNotifications);
  }

  int get unreadNotificationCount =>
      visibleNotifications.where((item) => !item.read).length;

  UserNotification? notificationById(String id) => _firstWhereOrNull(
        userNotifications,
        (item) => item.id == id,
      );

  NotificationActionResult markNotificationRead(String id) {
    if (!demoMode) return NotificationActionResult.unavailable;
    final index = userNotifications.indexWhere((item) => item.id == id);
    if (index < 0) return NotificationActionResult.notFound;
    final notification = userNotifications[index];
    if (notification.read) return NotificationActionResult.success;
    final readAt = now().toUtc();
    userNotifications = [
      for (var i = 0; i < userNotifications.length; i++)
        i == index
            ? notification.copyWith(readAt: readAt)
            : userNotifications[i],
    ];
    notifyListeners();
    return NotificationActionResult.success;
  }

  int markAllNotificationsRead() {
    if (!demoMode) return 0;
    final unread = userNotifications.where((item) => !item.read).length;
    if (unread == 0) return 0;
    final readAt = now().toUtc();
    userNotifications = userNotifications
        .map((item) => item.read ? item : item.copyWith(readAt: readAt))
        .toList();
    notifyListeners();
    return unread;
  }

  NotificationActionResult deleteNotification(String id) {
    if (!demoMode) return NotificationActionResult.unavailable;
    if (!userNotifications.any((item) => item.id == id)) {
      return NotificationActionResult.notFound;
    }
    userNotifications =
        userNotifications.where((item) => item.id != id).toList();
    notifyListeners();
    return NotificationActionResult.success;
  }

  // ── Places ────────────────────────────────────────────────────────────────

  List<SavedPlaceRecord> get visibleSavedPlaces {
    if (!demoMode) return const <SavedPlaceRecord>[];
    final ownerId = currentDemoUser.id;
    final newestByPlace = <int, SavedPlaceRecord>{};
    for (final record
        in savedPlaces.where((item) => item.ownerUserId == ownerId)) {
      final existing = newestByPlace[record.placeId];
      if (existing == null || _compareSavedPlaces(record, existing) < 0) {
        newestByPlace[record.placeId] = record;
      }
    }
    return newestByPlace.values.toList()..sort(_compareSavedPlaces);
  }

  int get savedPlaceCount => visibleSavedPlaces.length;

  bool isPlaceSaved(int placeId) =>
      demoMode && visibleSavedPlaces.any((record) => record.placeId == placeId);

  SavedPlaceRecord? savedPlaceForPlaceId(int placeId) {
    if (!demoMode) return null;
    return _firstWhereOrNull(
      visibleSavedPlaces,
      (record) => record.placeId == placeId,
    );
  }

  SavedPlaceRecord? savedPlaceById(String id) {
    if (!demoMode) return null;
    return _firstWhereOrNull(
      visibleSavedPlaces,
      (record) => record.id == id,
    );
  }

  List<ResolvedSavedPlace> savedPlaceResults({
    String query = '',
    String? category,
    SavedPlaceSort sort = SavedPlaceSort.newest,
    bool includeMissing = true,
  }) {
    final normalizedQuery = normalizeSearchText(query);
    final normalizedCategory = category == null || category.trim().isEmpty
        ? null
        : normalizeSearchText(category);
    final results = <ResolvedSavedPlace>[];
    for (final record in visibleSavedPlaces) {
      final place = placeById(record.placeId);
      if (place == null) {
        final missingText =
            normalizeSearchText('${record.id} ${record.note ?? ''}');
        if (includeMissing &&
            normalizedCategory == null &&
            (normalizedQuery.isEmpty ||
                missingText.contains(normalizedQuery))) {
          results.add(ResolvedSavedPlace(record: record, place: null));
        }
        continue;
      }
      if (normalizedCategory != null &&
          normalizeSearchText(place.category) != normalizedCategory &&
          normalizeSearchText(place.effectiveCategorySlug) !=
              normalizedCategory) {
        continue;
      }
      if (normalizedQuery.isNotEmpty &&
          !_savedPlaceMatchesQuery(record, place, normalizedQuery)) {
        continue;
      }
      results.add(ResolvedSavedPlace(record: record, place: place));
    }
    switch (sort) {
      case SavedPlaceSort.newest:
        results.sort((a, b) => _compareSavedPlaces(a.record, b.record));
        break;
      case SavedPlaceSort.name:
        results.sort((a, b) {
          final aName = a.place?.name ?? '';
          final bName = b.place?.name ?? '';
          final name =
              normalizeSearchText(aName).compareTo(normalizeSearchText(bName));
          if (name != 0) return name;
          return _compareSavedPlaces(a.record, b.record);
        });
        break;
    }
    return results;
  }

  List<String> get savedPlaceCategories {
    final categories = <String>{};
    for (final record in visibleSavedPlaces) {
      final place = placeById(record.placeId);
      if (place != null && place.category.trim().isNotEmpty) {
        categories.add(place.category);
      }
    }
    return categories.toList()..sort();
  }

  SavedPlaceActionResult savePlace(int placeId, {String? note}) {
    if (!demoMode) return SavedPlaceActionResult.unavailable;
    final place = placeById(placeId);
    if (place == null) return SavedPlaceActionResult.notFound;
    if (isPlaceSaved(placeId)) return SavedPlaceActionResult.duplicate;
    if (_savedPlaceNoteTooLong(note)) {
      return SavedPlaceActionResult.invalidNote;
    }
    final owner = currentDemoUser;
    final savedAt = now().toUtc();
    savedPlaces = [
      ...savedPlaces,
      SavedPlaceRecord(
        id: 'wishlist-demo-$placeId',
        ownerUserId: owner.id,
        placeId: place.id,
        savedAt: savedAt,
        note: note,
      ),
    ];
    notifyListeners();
    return SavedPlaceActionResult.success;
  }

  SavedPlaceActionResult removeSavedPlace(int placeId) {
    if (!demoMode) return SavedPlaceActionResult.unavailable;
    final ownerId = currentDemoUser.id;
    final index = savedPlaces.indexWhere(
      (record) => record.ownerUserId == ownerId && record.placeId == placeId,
    );
    if (index < 0) {
      return savedPlaces.any((record) => record.placeId == placeId)
          ? SavedPlaceActionResult.forbidden
          : SavedPlaceActionResult.notFound;
    }
    savedPlaces = [
      for (var i = 0; i < savedPlaces.length; i++)
        if (i != index) savedPlaces[i],
    ];
    notifyListeners();
    return SavedPlaceActionResult.success;
  }

  SavedPlaceActionResult updateSavedPlaceNote(int placeId, String? note) {
    if (!demoMode) return SavedPlaceActionResult.unavailable;
    if (_savedPlaceNoteTooLong(note)) {
      return SavedPlaceActionResult.invalidNote;
    }
    final ownerId = currentDemoUser.id;
    final index = savedPlaces.indexWhere(
      (record) => record.ownerUserId == ownerId && record.placeId == placeId,
    );
    if (index < 0) {
      return savedPlaces.any((record) => record.placeId == placeId)
          ? SavedPlaceActionResult.forbidden
          : SavedPlaceActionResult.notFound;
    }
    final current = savedPlaces[index];
    if (current.note == note) return SavedPlaceActionResult.success;
    savedPlaces = [
      for (var i = 0; i < savedPlaces.length; i++)
        i == index ? current.copyWith(note: note) : savedPlaces[i],
    ];
    notifyListeners();
    return SavedPlaceActionResult.success;
  }

  List<SavedCollectionRecord> get visibleSavedCollections {
    if (!demoMode) return const <SavedCollectionRecord>[];
    final ownerId = currentDemoUser.id;
    return savedCollections
        .where((collection) => collection.ownerUserId == ownerId)
        .toList()
      ..sort(_compareSavedCollections);
  }

  int get savedCollectionCount => visibleSavedCollections.length;

  SavedCollectionRecord? savedCollectionById(String id) {
    if (!demoMode) return null;
    return _firstWhereOrNull(
      visibleSavedCollections,
      (collection) => collection.id == id,
    );
  }

  List<SavedCollectionPlaceRecord> savedCollectionItems(String collectionId) {
    final collection = savedCollectionById(collectionId);
    if (collection == null) return const <SavedCollectionPlaceRecord>[];
    return savedCollectionPlaces
        .where((item) => item.collectionId == collection.id)
        .toList()
      ..sort(_compareSavedCollectionPlaces);
  }

  List<ResolvedCollectionPlace> resolvedCollectionPlaces(String collectionId) {
    return savedCollectionItems(collectionId)
        .map(
          (item) => ResolvedCollectionPlace(
            record: item,
            place: placeById(item.placeId),
          ),
        )
        .toList();
  }

  int savedCollectionItemCount(String collectionId) =>
      savedCollectionItems(collectionId).length;

  bool isPlaceInCollection({
    required String collectionId,
    required int placeId,
  }) =>
      savedCollectionItems(collectionId).any((item) => item.placeId == placeId);

  SavedCollectionActionResult createSavedCollection({
    required String name,
    String? description,
    String? coverImageUrl,
    bool privateCollection = true,
    int? sortOrder,
  }) {
    if (!demoMode) return SavedCollectionActionResult.unavailable;
    final validation = _validateCollectionFields(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
    );
    if (validation != null) return validation;
    if (visibleSavedCollections.length >=
        SavedCollectionRecord.maxCollectionsPerUser) {
      return SavedCollectionActionResult.collectionLimitReached;
    }
    final timestamp = now().toUtc();
    final order = sortOrder ?? _nextCollectionSortOrder();
    savedCollections = [
      ...savedCollections,
      SavedCollectionRecord(
        id: 'collection-demo-${_collectionSlug(name)}-$order',
        ownerUserId: currentDemoUser.id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        privateCollection: privateCollection,
        sortOrder: order,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ];
    notifyListeners();
    return SavedCollectionActionResult.success;
  }

  SavedCollectionActionResult updateSavedCollection({
    required String collectionId,
    required String name,
    String? description,
    String? coverImageUrl,
    bool? privateCollection,
    int? sortOrder,
  }) {
    if (!demoMode) return SavedCollectionActionResult.unavailable;
    final index = _visibleSavedCollectionIndex(collectionId);
    if (index < 0) return SavedCollectionActionResult.collectionNotFound;
    final validation = _validateCollectionFields(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
    );
    if (validation != null) return validation;
    final current = savedCollections[index];
    final updated = current.copyWith(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      privateCollection: privateCollection ?? current.privateCollection,
      sortOrder: sortOrder ?? current.sortOrder,
      updatedAt: now().toUtc(),
    );
    savedCollections = [
      for (var i = 0; i < savedCollections.length; i++)
        i == index ? updated : savedCollections[i],
    ];
    notifyListeners();
    return SavedCollectionActionResult.success;
  }

  SavedCollectionActionResult deleteSavedCollection(String collectionId) {
    if (!demoMode) return SavedCollectionActionResult.unavailable;
    final index = _visibleSavedCollectionIndex(collectionId);
    if (index < 0) return SavedCollectionActionResult.collectionNotFound;
    savedCollections = [
      for (var i = 0; i < savedCollections.length; i++)
        if (i != index) savedCollections[i],
    ];
    savedCollectionPlaces = savedCollectionPlaces
        .where((item) => item.collectionId != collectionId)
        .toList();
    notifyListeners();
    return SavedCollectionActionResult.success;
  }

  SavedCollectionActionResult addPlaceToCollection({
    required String collectionId,
    required int placeId,
  }) {
    if (!demoMode) return SavedCollectionActionResult.unavailable;
    final collectionIndex = _visibleSavedCollectionIndex(collectionId);
    if (collectionIndex < 0) {
      return SavedCollectionActionResult.collectionNotFound;
    }
    final place = placeById(placeId);
    if (place == null) return SavedCollectionActionResult.placeNotFound;
    final existing = savedCollectionPlaces.any(
      (item) => item.collectionId == collectionId && item.placeId == placeId,
    );
    if (existing) return SavedCollectionActionResult.duplicateItem;
    final items = savedCollectionItems(collectionId);
    if (items.length >= SavedCollectionPlaceRecord.maxPlacesPerCollection) {
      return SavedCollectionActionResult.itemLimitReached;
    }
    final nextPosition = items.isEmpty
        ? 0
        : items.map((item) => item.position).reduce((a, b) => a > b ? a : b) +
            1;
    final timestamp = now().toUtc();
    savedCollectionPlaces = [
      ...savedCollectionPlaces,
      SavedCollectionPlaceRecord(
        id: '$collectionId-place-$placeId-$nextPosition',
        collectionId: collectionId,
        placeId: placeId,
        position: nextPosition,
        addedAt: timestamp,
      ),
    ];
    savedCollections = [
      for (var i = 0; i < savedCollections.length; i++)
        i == collectionIndex
            ? savedCollections[i].copyWith(updatedAt: timestamp)
            : savedCollections[i],
    ];
    notifyListeners();
    return SavedCollectionActionResult.success;
  }

  SavedCollectionActionResult removePlaceFromCollection({
    required String collectionId,
    required int placeId,
  }) {
    if (!demoMode) return SavedCollectionActionResult.unavailable;
    final collectionIndex = _visibleSavedCollectionIndex(collectionId);
    if (collectionIndex < 0) {
      return SavedCollectionActionResult.collectionNotFound;
    }
    final itemIndex = savedCollectionPlaces.indexWhere(
      (item) => item.collectionId == collectionId && item.placeId == placeId,
    );
    if (itemIndex < 0) return SavedCollectionActionResult.itemNotFound;
    final timestamp = now().toUtc();
    savedCollectionPlaces = [
      for (var i = 0; i < savedCollectionPlaces.length; i++)
        if (i != itemIndex) savedCollectionPlaces[i],
    ];
    savedCollections = [
      for (var i = 0; i < savedCollections.length; i++)
        i == collectionIndex
            ? savedCollections[i].copyWith(updatedAt: timestamp)
            : savedCollections[i],
    ];
    notifyListeners();
    return SavedCollectionActionResult.success;
  }

  // ── Real Mode Saved Collections (/api/me/collections, UI-17) ─────────────
  // Wired against ApiClient's typed collection endpoints. Every one of these
  // is gated by `demoMode` in the opposite direction of the demo methods
  // above: they are no-ops (`unavailable`) while demoMode is true, and never
  // touch `savedCollections`/`savedCollectionPlaces`. A 401 never calls
  // `logout()` or clears already-loaded state — only the caller decides to
  // show a re-auth prompt.

  SavedCollectionActionResult _mapReadError(ApiErrorKind? kind) {
    switch (kind) {
      case ApiErrorKind.unauthorized:
        return SavedCollectionActionResult.unauthenticated;
      case ApiErrorKind.notFound:
        return SavedCollectionActionResult.collectionNotFound;
      case ApiErrorKind.network:
      case ApiErrorKind.timeout:
        return SavedCollectionActionResult.network;
      case ApiErrorKind.server:
      case ApiErrorKind.malformed:
      case ApiErrorKind.validation:
      case ApiErrorKind.unprocessable:
      case ApiErrorKind.conflict:
      case ApiErrorKind.forbidden:
      case null:
        return SavedCollectionActionResult.serverError;
    }
  }

  Future<SavedCollectionActionResult> loadRealSavedCollections({
    bool refresh = false,
  }) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realSavedCollectionsLoading) return SavedCollectionActionResult.success;
    if (realSavedCollectionsLoaded && !refresh) {
      return SavedCollectionActionResult.success;
    }
    realSavedCollectionsLoading = true;
    notifyListeners();
    final result = await api.listCollections();
    realSavedCollectionsLoading = false;
    if (result.success) {
      realSavedCollections = result.data!;
      realSavedCollectionsLoaded = true;
      realSavedCollectionsError = null;
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    final outcome = _mapReadError(result.errorKind);
    realSavedCollectionsError = outcome;
    notifyListeners();
    return outcome;
  }

  Future<SavedCollectionActionResult> loadRealCollectionDetail(
    int collectionId, {
    bool refresh = false,
  }) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realCollectionDetailLoading) return SavedCollectionActionResult.success;
    if (!refresh &&
        realSelectedCollectionDetail != null &&
        realSelectedCollectionDetail!.id == collectionId) {
      return SavedCollectionActionResult.success;
    }
    realSelectedCollectionId = collectionId;
    realCollectionDetailLoading = true;
    notifyListeners();
    final result = await api.getCollectionDetail(collectionId);
    realCollectionDetailLoading = false;
    if (result.success) {
      realSelectedCollectionDetail = result.data;
      realCollectionDetailError = null;
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    final outcome = _mapReadError(result.errorKind);
    realCollectionDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  void clearRealCollectionSelection() {
    realSelectedCollectionId = null;
    realSelectedCollectionDetail = null;
    realCollectionDetailError = null;
    notifyListeners();
  }

  Future<SavedCollectionActionResult> createRealSavedCollection({
    required String name,
    String? description,
    String? coverImageUrl,
    bool privateCollection = true,
  }) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realCollectionCreateInFlight)
      return SavedCollectionActionResult.success;
    final validation = _validateCollectionFields(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
    );
    if (validation != null) return validation;
    if (realSavedCollections.length >=
        SavedCollectionRecord.maxCollectionsPerUser) {
      return SavedCollectionActionResult.collectionLimitReached;
    }
    realCollectionCreateInFlight = true;
    notifyListeners();
    final result = await api.createCollection(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      privateCollection: privateCollection,
    );
    realCollectionCreateInFlight = false;
    if (result.success) {
      final detail = result.data!;
      realSavedCollections = [
        ...realSavedCollections,
        detail.toSummary(),
      ]..sort(_compareCollectionSummaries);
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    final outcome = switch (result.errorKind) {
      ApiErrorKind.conflict =>
        SavedCollectionActionResult.collectionLimitReached,
      ApiErrorKind.unauthorized => SavedCollectionActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        SavedCollectionActionResult.network,
      ApiErrorKind.validation => SavedCollectionActionResult.invalidName,
      _ => SavedCollectionActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  Future<SavedCollectionActionResult> updateRealSavedCollection({
    required int collectionId,
    required String name,
    String? description,
    String? coverImageUrl,
    required bool privateCollection,
    required int sortOrder,
  }) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realCollectionUpdateInFlight)
      return SavedCollectionActionResult.success;
    final validation = _validateCollectionFields(
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
    );
    if (validation != null) return validation;
    realCollectionUpdateInFlight = true;
    notifyListeners();
    final result = await api.updateCollection(
      collectionId: collectionId,
      name: name,
      description: description,
      coverImageUrl: coverImageUrl,
      privateCollection: privateCollection,
      sortOrder: sortOrder,
    );
    realCollectionUpdateInFlight = false;
    if (result.success) {
      final detail = result.data!;
      _upsertRealCollectionSummary(detail.toSummary());
      if (realSelectedCollectionDetail?.id == collectionId) {
        realSelectedCollectionDetail = detail;
      }
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    final outcome = switch (result.errorKind) {
      ApiErrorKind.notFound => SavedCollectionActionResult.collectionNotFound,
      ApiErrorKind.unauthorized => SavedCollectionActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        SavedCollectionActionResult.network,
      ApiErrorKind.validation => SavedCollectionActionResult.invalidName,
      _ => SavedCollectionActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  Future<SavedCollectionActionResult> deleteRealSavedCollection(
    int collectionId,
  ) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realCollectionDeleteInFlight)
      return SavedCollectionActionResult.success;
    realCollectionDeleteInFlight = true;
    notifyListeners();
    final result = await api.deleteCollection(collectionId);
    realCollectionDeleteInFlight = false;
    if (result.success) {
      realSavedCollections =
          realSavedCollections.where((c) => c.id != collectionId).toList();
      if (realSelectedCollectionDetail?.id == collectionId) {
        realSelectedCollectionDetail = null;
        realSelectedCollectionId = null;
      }
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    final outcome = switch (result.errorKind) {
      ApiErrorKind.notFound => SavedCollectionActionResult.collectionNotFound,
      ApiErrorKind.unauthorized => SavedCollectionActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        SavedCollectionActionResult.network,
      _ => SavedCollectionActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  Future<SavedCollectionActionResult> addRealCollectionPlace({
    required int collectionId,
    required int placeId,
  }) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realCollectionPlaceActionInFlight) {
      return SavedCollectionActionResult.success;
    }
    final knownPlaceCount = realSelectedCollectionDetail?.id == collectionId
        ? realSelectedCollectionDetail!.placeCount
        : _firstWhereOrNull(
            realSavedCollections,
            (c) => c.id == collectionId,
          )?.placeCount;
    if (knownPlaceCount != null &&
        knownPlaceCount >= SavedCollectionPlaceRecord.maxPlacesPerCollection) {
      return SavedCollectionActionResult.itemLimitReached;
    }
    realCollectionPlaceActionInFlight = true;
    notifyListeners();
    final result = await api.addCollectionPlace(
      collectionId: collectionId,
      placeId: placeId,
    );
    realCollectionPlaceActionInFlight = false;
    if (result.success) {
      final place = result.data!;
      if (realSelectedCollectionDetail?.id == collectionId) {
        realSelectedCollectionDetail = realSelectedCollectionDetail!.copyWith(
          places: [...realSelectedCollectionDetail!.places, place],
          placeCount: realSelectedCollectionDetail!.placeCount + 1,
        );
      }
      _bumpRealCollectionPlaceCount(collectionId, 1);
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    // Call-site context: this always targets a collection already loaded in
    // detail view, so a 404 here means the place id itself was not found
    // (see SavedCollectionService.addPlace — the collection lookup happens
    // first and would otherwise have surfaced earlier as collectionNotFound).
    final outcome = switch (result.errorKind) {
      ApiErrorKind.notFound => SavedCollectionActionResult.placeNotFound,
      ApiErrorKind.conflict => SavedCollectionActionResult.duplicateItem,
      ApiErrorKind.unauthorized => SavedCollectionActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        SavedCollectionActionResult.network,
      _ => SavedCollectionActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  Future<SavedCollectionActionResult> removeRealCollectionPlace({
    required int collectionId,
    required int placeId,
  }) async {
    if (demoMode) return SavedCollectionActionResult.unavailable;
    if (realCollectionPlaceActionInFlight) {
      return SavedCollectionActionResult.success;
    }
    realCollectionPlaceActionInFlight = true;
    notifyListeners();
    final result = await api.removeCollectionPlace(
      collectionId: collectionId,
      placeId: placeId,
    );
    realCollectionPlaceActionInFlight = false;
    if (result.success) {
      if (realSelectedCollectionDetail?.id == collectionId) {
        realSelectedCollectionDetail = realSelectedCollectionDetail!.copyWith(
          places: realSelectedCollectionDetail!.places
              .where((p) => p.placeId != placeId)
              .toList(),
          placeCount: realSelectedCollectionDetail!.placeCount - 1,
        );
      }
      _bumpRealCollectionPlaceCount(collectionId, -1);
      notifyListeners();
      return SavedCollectionActionResult.success;
    }
    final outcome = switch (result.errorKind) {
      ApiErrorKind.notFound => SavedCollectionActionResult.itemNotFound,
      ApiErrorKind.unauthorized => SavedCollectionActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        SavedCollectionActionResult.network,
      _ => SavedCollectionActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  void _upsertRealCollectionSummary(CollectionSummaryRecord summary) {
    final index = realSavedCollections.indexWhere((c) => c.id == summary.id);
    if (index < 0) {
      realSavedCollections = [...realSavedCollections, summary]
        ..sort(_compareCollectionSummaries);
      return;
    }
    realSavedCollections = [
      for (var i = 0; i < realSavedCollections.length; i++)
        i == index ? summary : realSavedCollections[i],
    ]..sort(_compareCollectionSummaries);
  }

  void _bumpRealCollectionPlaceCount(int collectionId, int delta) {
    final index = realSavedCollections.indexWhere((c) => c.id == collectionId);
    if (index < 0) return;
    final current = realSavedCollections[index];
    _upsertRealCollectionSummary(
      CollectionSummaryRecord(
        id: current.id,
        name: current.name,
        description: current.description,
        coverImageUrl: current.coverImageUrl,
        privateCollection: current.privateCollection,
        sortOrder: current.sortOrder,
        placeCount: current.placeCount + delta,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
      ),
    );
  }

  static int _compareCollectionSummaries(
    CollectionSummaryRecord a,
    CollectionSummaryRecord b,
  ) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    return a.createdAt.compareTo(b.createdAt);
  }

  // ── Real Mode Wishlist (/api/me/wishlist, UI-18) ─────────────────────────
  //
  // Mirrors the UI-17 real-collections shape: guarded on `!demoMode`,
  // confirmed-only success (no optimistic mutation), a 401 maps to
  // `unauthenticated` and NEVER calls logout()/clears state.

  WishlistActionResult _mapWishlistReadError(ApiErrorKind? kind) {
    switch (kind) {
      case ApiErrorKind.unauthorized:
        return WishlistActionResult.unauthenticated;
      case ApiErrorKind.network:
      case ApiErrorKind.timeout:
        return WishlistActionResult.network;
      case ApiErrorKind.notFound:
      case ApiErrorKind.conflict:
      case ApiErrorKind.validation:
      case ApiErrorKind.unprocessable:
      case ApiErrorKind.server:
      case ApiErrorKind.malformed:
      case ApiErrorKind.forbidden:
      case null:
        return WishlistActionResult.serverError;
    }
  }

  bool isPlaceInRealWishlist(int placeId) =>
      !demoMode && realWishlist.any((item) => item.placeId == placeId);

  bool isWishlistActionInFlight(int placeId) =>
      realWishlistActionInFlight.contains(placeId);

  Future<WishlistActionResult> loadRealWishlist({bool refresh = false}) async {
    if (demoMode) return WishlistActionResult.unavailable;
    if (realWishlistLoading) return WishlistActionResult.success;
    if (realWishlistLoaded && !refresh) return WishlistActionResult.success;
    realWishlistLoading = true;
    notifyListeners();
    final result = await api.getWishlist();
    realWishlistLoading = false;
    if (result.success) {
      // Preserve the backend's newest-first (createdAt DESC) order.
      realWishlist = result.data!.items;
      realWishlistLoaded = true;
      realWishlistError = null;
      notifyListeners();
      return WishlistActionResult.success;
    }
    final outcome = _mapWishlistReadError(result.errorKind);
    realWishlistError = outcome;
    notifyListeners();
    return outcome;
  }

  Future<WishlistActionResult> refreshRealWishlist() =>
      loadRealWishlist(refresh: true);

  /// Loads the real wishlist once (no-op if already loaded/loading). Called by
  /// cross-screen bookmark controls so their saved-state icons are accurate.
  Future<WishlistActionResult> ensureRealWishlistLoaded() => loadRealWishlist();

  Future<WishlistActionResult> addPlaceToRealWishlist(
    int placeId, {
    String? note,
  }) async {
    if (demoMode) return WishlistActionResult.unavailable;
    if (realWishlistActionInFlight.contains(placeId)) {
      return WishlistActionResult.success;
    }
    realWishlistActionInFlight.add(placeId);
    notifyListeners();
    final result = await api.addWishlistItem(placeId: placeId, note: note);
    realWishlistActionInFlight.remove(placeId);
    if (result.success) {
      final item = result.data!;
      if (!realWishlist.any((i) => i.placeId == item.placeId)) {
        // Backend returns newest-first; a freshly added item leads the list.
        realWishlist = [item, ...realWishlist];
      }
      realWishlistError = null;
      notifyListeners();
      return WishlistActionResult.success;
    }
    final outcome = switch (result.errorKind) {
      ApiErrorKind.notFound => WishlistActionResult.placeNotFound,
      ApiErrorKind.conflict => WishlistActionResult.duplicate,
      ApiErrorKind.unprocessable => WishlistActionResult.notPublished,
      ApiErrorKind.validation => WishlistActionResult.invalid,
      ApiErrorKind.unauthorized => WishlistActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        WishlistActionResult.network,
      _ => WishlistActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  Future<WishlistActionResult> removePlaceFromRealWishlist(int placeId) async {
    if (demoMode) return WishlistActionResult.unavailable;
    if (realWishlistActionInFlight.contains(placeId)) {
      return WishlistActionResult.success;
    }
    realWishlistActionInFlight.add(placeId);
    notifyListeners();
    final result = await api.removeWishlistItem(placeId);
    realWishlistActionInFlight.remove(placeId);
    if (result.success) {
      realWishlist =
          realWishlist.where((item) => item.placeId != placeId).toList();
      realWishlistError = null;
      notifyListeners();
      return WishlistActionResult.success;
    }
    final outcome = switch (result.errorKind) {
      ApiErrorKind.notFound => WishlistActionResult.itemNotFound,
      ApiErrorKind.unauthorized => WishlistActionResult.unauthenticated,
      ApiErrorKind.network ||
      ApiErrorKind.timeout =>
        WishlistActionResult.network,
      _ => WishlistActionResult.serverError,
    };
    notifyListeners();
    return outcome;
  }

  // ── Mode-aware bookmark path (shared by BookmarkButton, UI-18) ────────────

  /// Whether [placeId] is bookmarked in the active mode (demo wishlist vs the
  /// real backend wishlist). The single query every bookmark control reads.
  bool isPlaceBookmarked(int placeId) =>
      demoMode ? isPlaceSaved(placeId) : isPlaceInRealWishlist(placeId);

  /// Toggles the bookmark for [placeId] in the active mode, returning one
  /// unified outcome. Demo Mode stays fully local/synchronous (zero HTTP);
  /// Real Mode confirms with the backend before any local state changes.
  Future<BookmarkOutcome> toggleBookmark(int placeId) async {
    if (demoMode) {
      final wasSaved = isPlaceSaved(placeId);
      final result = wasSaved ? removeSavedPlace(placeId) : savePlace(placeId);
      return _demoBookmarkOutcome(result, removing: wasSaved);
    }
    final wasSaved = isPlaceInRealWishlist(placeId);
    final result = wasSaved
        ? await removePlaceFromRealWishlist(placeId)
        : await addPlaceToRealWishlist(placeId);
    return _realBookmarkOutcome(result, removing: wasSaved);
  }

  BookmarkOutcome _demoBookmarkOutcome(
    SavedPlaceActionResult result, {
    required bool removing,
  }) {
    switch (result) {
      case SavedPlaceActionResult.success:
        return removing ? BookmarkOutcome.removed : BookmarkOutcome.added;
      case SavedPlaceActionResult.duplicate:
        return BookmarkOutcome.duplicate;
      case SavedPlaceActionResult.notFound:
        return BookmarkOutcome.notFound;
      case SavedPlaceActionResult.forbidden:
        return BookmarkOutcome.forbidden;
      case SavedPlaceActionResult.invalidNote:
        return BookmarkOutcome.invalid;
      case SavedPlaceActionResult.unavailable:
        return BookmarkOutcome.unavailable;
    }
  }

  BookmarkOutcome _realBookmarkOutcome(
    WishlistActionResult result, {
    required bool removing,
  }) {
    switch (result) {
      case WishlistActionResult.success:
        return removing ? BookmarkOutcome.removed : BookmarkOutcome.added;
      case WishlistActionResult.duplicate:
        return BookmarkOutcome.duplicate;
      case WishlistActionResult.placeNotFound:
      case WishlistActionResult.itemNotFound:
        return BookmarkOutcome.notFound;
      case WishlistActionResult.notPublished:
        return BookmarkOutcome.notPublished;
      case WishlistActionResult.network:
        return BookmarkOutcome.network;
      case WishlistActionResult.unauthenticated:
        return BookmarkOutcome.sessionExpired;
      case WishlistActionResult.invalid:
        return BookmarkOutcome.invalid;
      case WishlistActionResult.unavailable:
        return BookmarkOutcome.unavailable;
      case WishlistActionResult.serverError:
        return BookmarkOutcome.serverError;
    }
  }

  // ── Real place-detail hydration (UI19) ────────────────────────────────────

  /// The full [Place] for [placeId] if it has already been hydrated this
  /// session, else `null`. Never falls back to demo data.
  Place? getHydratedRealPlace(int placeId) => _hydratedRealPlaces[placeId];

  /// Whether a hydration request for [placeId] is currently in flight.
  bool isRealPlaceHydrationInFlight(int placeId) =>
      _hydrationInFlight.containsKey(placeId);

  /// Hydrates the full [Place] for [placeId] from the public place-detail
  /// endpoint, caching a successful result for the session. Demo Mode never
  /// hits the network. Concurrent callers for the same place share one request;
  /// a failed hydration is never cached, so a retry can succeed. On success the
  /// [Place] is available via [getHydratedRealPlace].
  Future<PlaceHydrationResult> hydrateRealPlace(int placeId) {
    if (demoMode) return Future.value(PlaceHydrationResult.unavailable);
    if (_hydratedRealPlaces.containsKey(placeId)) {
      return Future.value(PlaceHydrationResult.success);
    }
    final existing = _hydrationInFlight[placeId];
    if (existing != null) return existing;
    final future = _performHydration(placeId);
    _hydrationInFlight[placeId] = future;
    notifyListeners();
    return future;
  }

  Future<PlaceHydrationResult> _performHydration(int placeId) async {
    try {
      final result = await api.getPlaceDetail(placeId);
      if (result.success && result.data != null) {
        _hydratedRealPlaces[placeId] = result.data!.toPlace();
        return PlaceHydrationResult.success;
      }
      return switch (result.errorKind) {
        ApiErrorKind.notFound => PlaceHydrationResult.notFound,
        ApiErrorKind.unauthorized => PlaceHydrationResult.sessionExpired,
        ApiErrorKind.network ||
        ApiErrorKind.timeout =>
          PlaceHydrationResult.network,
        _ => PlaceHydrationResult.serverError,
      };
    } finally {
      // Always release the in-flight slot so failures aren't cached and a
      // retry remains possible.
      _hydrationInFlight.remove(placeId);
      notifyListeners();
    }
  }

  // ── Real Mode Trips (/api/me/trips, UI20) ─────────────────────────────────
  //
  // Parallel to the demo trip methods below — never fabricates success. A 401
  // maps to [TripActionResult.sessionExpired] (caller shows a re-auth sheet;
  // this never logs out or clears the session); a 403 stays distinct as
  // [TripActionResult.forbidden] so callers show a permission error.

  TripActionResult _mapTripError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => TripActionResult.sessionExpired,
      ApiErrorKind.forbidden => TripActionResult.forbidden,
      ApiErrorKind.notFound => TripActionResult.notFound,
      ApiErrorKind.conflict => TripActionResult.conflict,
      ApiErrorKind.unprocessable => TripActionResult.unprocessable,
      ApiErrorKind.validation => TripActionResult.validation,
      ApiErrorKind.network => TripActionResult.network,
      ApiErrorKind.timeout => TripActionResult.timeout,
      ApiErrorKind.server => TripActionResult.serverError,
      ApiErrorKind.malformed => TripActionResult.malformed,
      null => TripActionResult.serverError,
    };
  }

  /// The loaded detail if it belongs to [tripId], else `null`.
  TripDetailRecord? realTripDetailFor(int tripId) =>
      realSelectedTripId == tripId ? realSelectedTripDetail : null;

  /// Loads the authenticated user's real trip list. [refresh] forces a re-fetch
  /// (pull-to-refresh) and preserves the current list if the re-fetch fails.
  Future<TripActionResult> loadRealTrips({bool refresh = false}) async {
    if (demoMode) return TripActionResult.unavailable;
    if (realTripsLoading || realTripsRefreshing) {
      return TripActionResult.success;
    }
    if (realTripsLoaded && !refresh) return TripActionResult.success;
    if (refresh) {
      realTripsRefreshing = true;
    } else {
      realTripsLoading = true;
    }
    realTripsError = null;
    notifyListeners();
    final result = await api.getMyTrips();
    realTripsLoading = false;
    realTripsRefreshing = false;
    if (result.success && result.data != null) {
      realTrips = result.data!;
      realTripsLoaded = true;
      realTripsError = null;
      notifyListeners();
      return TripActionResult.success;
    }
    // Preserve any previously loaded list; only surface the error.
    final outcome = _mapTripError(result.errorKind);
    realTripsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Loads one real trip's full day→item detail into [realSelectedTripDetail].
  /// A newer selection supersedes an older in-flight load (last request wins).
  Future<TripActionResult> loadRealTripDetail(int tripId) async {
    if (demoMode) return TripActionResult.unavailable;
    realSelectedTripId = tripId;
    realSelectedTripDetail = null;
    realTripDetailLoading = true;
    realTripDetailError = null;
    notifyListeners();
    final result = await api.getTripDetail(tripId);
    // If a newer selection started while this was in flight, ignore this result.
    if (realSelectedTripId != tripId) return TripActionResult.success;
    realTripDetailLoading = false;
    if (result.success && result.data != null) {
      realSelectedTripDetail = result.data!;
      realTripDetailError = null;
      notifyListeners();
      return TripActionResult.success;
    }
    final outcome = _mapTripError(result.errorKind);
    realTripDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Creates a real trip. Never reports optimistic success — the new summary is
  /// only prepended after the backend confirms (201). The form should navigate
  /// away only when this returns [TripActionResult.success].
  Future<TripActionResult> createRealTrip({
    required String title,
    String? description,
    String? destination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (demoMode) return TripActionResult.unavailable;
    if (realTripCreateInFlight) return TripActionResult.success;
    realTripCreateInFlight = true;
    notifyListeners();
    final result = await api.createTrip(
      title: title,
      description: description,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
    );
    realTripCreateInFlight = false;
    if (result.success && result.data != null) {
      realTrips = [TripSummaryRecord.fromDetail(result.data!), ...realTrips];
      realTripsLoaded = true;
      notifyListeners();
      return TripActionResult.success;
    }
    final outcome = _mapTripError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Creates a day on a real trip and returns the new [TripDayRecord.id] so the
  /// Add-to-Trip flow can immediately place an item on it. Reflects the new day
  /// into the loaded detail (and bumps the summary's day count) on success.
  Future<({TripActionResult result, int? dayId})> createRealTripDay({
    required int tripId,
    required int dayNumber,
    DateTime? date,
    String? title,
  }) async {
    if (demoMode) {
      return (result: TripActionResult.unavailable, dayId: null);
    }
    if (realTripActionInFlight) {
      return (result: TripActionResult.success, dayId: null);
    }
    realTripActionInFlight = true;
    notifyListeners();
    final res = await api.createTripDay(
      tripId: tripId,
      dayNumber: dayNumber,
      date: date,
      title: title,
    );
    realTripActionInFlight = false;
    if (res.success && res.data != null) {
      final day = res.data!;
      final detail = realSelectedTripDetail;
      if (realSelectedTripId == tripId && detail != null) {
        final days = [...detail.days, day]
          ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
        realSelectedTripDetail = detail.copyWith(days: days);
      }
      _bumpRealTripDayCount(tripId);
      notifyListeners();
      return (result: TripActionResult.success, dayId: day.id);
    }
    final outcome = _mapTripError(res.errorKind);
    notifyListeners();
    return (result: outcome, dayId: null);
  }

  /// Adds a hydrated place to a real trip day. Never optimistic — the item is
  /// only reflected into the loaded detail after the backend confirms (201).
  Future<TripActionResult> addRealTripPlace({
    required int dayId,
    required int placeId,
  }) async {
    if (demoMode) return TripActionResult.unavailable;
    if (realTripActionInFlight) return TripActionResult.success;
    realTripActionInFlight = true;
    notifyListeners();
    final res = await api.addTripItem(dayId: dayId, placeId: placeId);
    realTripActionInFlight = false;
    if (res.success && res.data != null) {
      final item = res.data!;
      final detail = realSelectedTripDetail;
      if (detail != null && detail.days.any((d) => d.id == dayId)) {
        final days = detail.days.map((d) {
          if (d.id != dayId) return d;
          final items = [...d.items, item]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return d.copyWith(items: items);
        }).toList();
        realSelectedTripDetail = detail.copyWith(days: days);
      }
      notifyListeners();
      return TripActionResult.success;
    }
    final outcome = _mapTripError(res.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Increments the cached summary day count for [tripId] after a day is added,
  /// so the list stays consistent without a full refresh.
  void _bumpRealTripDayCount(int tripId) {
    final idx = realTrips.indexWhere((t) => t.id == tripId);
    if (idx < 0) return;
    final t = realTrips[idx];
    realTrips = [...realTrips]..[idx] = TripSummaryRecord(
        id: t.id,
        title: t.title,
        destination: t.destination,
        coverImage: t.coverImage,
        startDate: t.startDate,
        endDate: t.endDate,
        statusRaw: t.statusRaw,
        status: t.status,
        isPublic: t.isPublic,
        dayCount: t.dayCount + 1,
        updatedAt: t.updatedAt,
      );
  }

  List<Place> filteredPlaces(PlaceQuery q) {
    var result = places;
    if (q.category != null && q.category!.isNotEmpty) {
      result =
          result.where((p) => _placeMatchesCategory(p, q.category!)).toList();
    }
    if (q.keyword != null && q.keyword!.isNotEmpty) {
      final kw = q.keyword!.toLowerCase();
      result = result
          .where((p) =>
              p.name.toLowerCase().contains(kw) ||
              p.description.toLowerCase().contains(kw) ||
              p.city.toLowerCase().contains(kw) ||
              p.locationName.toLowerCase().contains(kw) ||
              p.tags.any((t) => t.toLowerCase().contains(kw)))
          .toList();
    }
    if (q.city != null && q.city!.isNotEmpty) {
      result = result
          .where((p) => p.city.toLowerCase().contains(q.city!.toLowerCase()))
          .toList();
    }
    if (q.minRating != null) {
      result = result.where((p) => p.rating >= q.minRating!).toList();
    }
    if (q.priceLevel != null && q.priceLevel!.isNotEmpty) {
      result = result.where((p) => p.priceLevel == q.priceLevel).toList();
    }
    if (q.tags != null && q.tags!.isNotEmpty) {
      final tags = q.tags!.map((t) => t.toLowerCase()).toSet();
      result = result
          .where((p) => p.tags.any((tag) => tags.contains(tag.toLowerCase())))
          .toList();
    }
    if (q.isFeatured == true) {
      result = result.where((p) => p.isFeatured).toList();
    }
    if (q.isNearby == true) {
      result = result.where((p) => p.isNearby).toList();
    }
    return result;
  }

  Place? placeById(int id) {
    try {
      return places.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Trips ─────────────────────────────────────────────────────────────────

  Trip? tripById(int id) {
    try {
      return trips.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  TripDocument? tripDocumentById(String id) => _firstWhereOrNull(
        tripDocuments,
        (document) => document.id == id,
      );

  TravelWalletItem? travelWalletItemById(String id) => _firstWhereOrNull(
        travelWalletItems,
        (item) => item.id == id,
      );

  void addTrip(Trip trip) {
    trips = [...trips, trip];
    notifyListeners();
  }

  void updateTrip(Trip updated) {
    trips = trips.map((t) => t.id == updated.id ? updated : t).toList();
    final changedAt = now();
    timeline = timeline
        .map((item) =>
            item.tripId == updated.id && item.dayNumber > updated.days
                ? item.copyWith(dayNumber: updated.days)
                : item)
        .toList();
    expenses = expenses
        .map((expense) => expense.tripId == updated.id &&
                expense.tripDayId != null &&
                expense.tripDayId! > updated.days
            ? expense.copyWith(tripDayId: updated.days)
            : expense)
        .toList();
    tripDocuments = tripDocuments
        .map((document) => document.tripId == updated.id &&
                document.tripDayId != null &&
                document.tripDayId! > updated.days
            ? document.copyWith(tripDayId: updated.days, updatedAt: changedAt)
            : document)
        .toList();
    tripNotes = tripNotes
        .map((note) => note.tripPlanId == updated.id &&
                note.tripDayId != null &&
                note.tripDayId! > updated.days
            ? note.copyWith(tripDayId: updated.days, updatedAt: changedAt)
            : note)
        .toList();
    tripReminders = tripReminders
        .map((reminder) => reminder.tripPlanId == updated.id &&
                reminder.tripDayId != null &&
                reminder.tripDayId! > updated.days
            ? reminder.copyWith(tripDayId: updated.days, updatedAt: changedAt)
            : reminder)
        .toList();
    notifyListeners();
  }

  void deleteTrip(int id) {
    final removedDocumentIds = tripDocuments
        .where((doc) => doc.tripId == id)
        .map((doc) => doc.id)
        .toSet();
    trips = trips.where((t) => t.id != id).toList();
    timeline = timeline.where((t) => t.tripId != id).toList();
    expenses = expenses.where((e) => e.tripId != id).toList();
    tripDocuments = tripDocuments.where((doc) => doc.tripId != id).toList();
    tripCollaborators =
        tripCollaborators.where((collab) => collab.tripPlanId != id).toList();
    sharedTrips = sharedTrips.where((trip) => trip.tripId != id).toList();
    tripNotes = tripNotes.where((note) => note.tripPlanId != id).toList();
    packingItems = packingItems.where((item) => item.tripPlanId != id).toList();
    tripReminders =
        tripReminders.where((reminder) => reminder.tripPlanId != id).toList();
    publicTripIds = {...publicTripIds}..remove(id);
    travelWalletItems = travelWalletItems
        .map((item) {
          if (item.linkedDocumentId != null &&
              removedDocumentIds.contains(item.linkedDocumentId)) {
            return null;
          }
          if (item.linkedTripId == id && item.linkedBookingId != null) {
            return item.copyWith(
              linkedTripId: null,
              linkedTripTitle: null,
              updatedAt: now(),
            );
          }
          if (item.linkedTripId == id) return null;
          return item;
        })
        .whereType<TravelWalletItem>()
        .toList();
    notifyListeners();
  }

  // ── Timeline ──────────────────────────────────────────────────────────────

  List<TimelineItem> itemsForTrip(int id, int day) =>
      timeline.where((e) => e.tripId == id && e.dayNumber == day).toList()
        ..sort(_compareTimelineItems);

  bool addTimeline(TimelineItem item) {
    if (!isValidTimeRange(item.startTime, item.endTime)) return false;
    final trip = tripById(item.tripId);
    if (trip == null || item.dayNumber < 1 || item.dayNumber > trip.days) {
      return false;
    }
    timeline = [...timeline, item];
    notifyListeners();
    return true;
  }

  bool updateTimeline(TimelineItem updated) {
    if (!isValidTimeRange(updated.startTime, updated.endTime)) return false;
    final trip = tripById(updated.tripId);
    if (trip == null ||
        updated.dayNumber < 1 ||
        updated.dayNumber > trip.days) {
      return false;
    }
    timeline = timeline.map((t) => t.id == updated.id ? updated : t).toList();
    notifyListeners();
    return true;
  }

  void deleteTimeline(int id) {
    timeline = timeline.where((e) => e.id != id).toList();
    final changedAt = now();
    tripNotes = tripNotes
        .map((note) => note.tripItemId == id
            ? note.copyWith(tripItemId: null, updatedAt: changedAt)
            : note)
        .toList();
    tripReminders = tripReminders
        .map((reminder) => reminder.tripItemId == id
            ? reminder.copyWith(tripItemId: null, updatedAt: changedAt)
            : reminder)
        .toList();
    notifyListeners();
  }

  // ── Expenses ──────────────────────────────────────────────────────────────

  List<Expense> expensesForTrip(int tripId) =>
      expenses.where((e) => e.tripId == tripId).toList()
        ..sort((a, b) {
          final date = b.date.compareTo(a.date);
          return date == 0 ? b.id.compareTo(a.id) : date;
        });

  double totalForTrip(int tripId) =>
      expensesForTrip(tripId).fold(0.0, (sum, e) => sum + e.amount);

  bool addExpense(Expense expense) {
    if (!_isValidExpense(expense)) return false;
    expenses = [...expenses, expense];
    notifyListeners();
    return true;
  }

  bool updateExpense(Expense updated) {
    if (!_isValidExpense(updated)) return false;
    expenses = expenses.map((e) => e.id == updated.id ? updated : e).toList();
    notifyListeners();
    return true;
  }

  void deleteExpense(int id) {
    expenses = expenses.where((e) => e.id != id).toList();
    notifyListeners();
  }

  // ── Demo bookings ────────────────────────────────────────────────────────

  String nextDemoBookingCode() {
    _bookingSequence += 1;
    return _bookingCodeGenerator(_bookingSequence);
  }

  bool addDemoBooking(DemoBooking booking) {
    if (!demoMode || demoBookings.any((item) => item.code == booking.code)) {
      return false;
    }
    demoBookings = [...demoBookings, booking];
    notifyListeners();
    return true;
  }

  bool updateDemoBooking(DemoBooking booking) {
    if (!demoMode || !demoBookings.any((item) => item.code == booking.code)) {
      return false;
    }
    demoBookings = demoBookings
        .map((item) => item.code == booking.code ? booking : item)
        .toList();
    notifyListeners();
    return true;
  }

  DemoBooking? demoBookingByCode(String code) =>
      _firstWhereOrNull(demoBookings, (item) => item.code == code);

  DemoPaymentAttempt? paymentAttemptById(String id) =>
      _firstWhereOrNull(demoPaymentAttempts, (item) => item.id == id);

  DemoPaymentAttempt? latestPaymentAttemptForBooking(String bookingCode) {
    final attempts = demoPaymentAttempts
        .where((item) => item.bookingCode == bookingCode)
        .toList()
      ..sort((a, b) {
        final created = b.createdAt.compareTo(a.createdAt);
        return created == 0 ? b.id.compareTo(a.id) : created;
      });
    return attempts.isEmpty ? null : attempts.first;
  }

  DemoCheckoutResult startDemoCheckout({
    required Place hotel,
    required HotelRoom room,
    required HotelRatePlan ratePlan,
    required HotelPricingQuote quote,
    required HotelStayCriteria criteria,
    required String specialRequest,
    required CheckoutPaymentProvider provider,
    required String idempotencyKey,
  }) {
    if (!demoMode) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.unavailable,
      );
    }
    final normalizedKey = idempotencyKey.trim();
    if (normalizedKey.isNotEmpty) {
      final existingAttempt = _firstWhereOrNull(
        demoPaymentAttempts,
        (item) => item.idempotencyKey == normalizedKey,
      );
      if (existingAttempt != null) {
        return DemoCheckoutResult(
          result: DemoPaymentActionResult.duplicate,
          booking: demoBookingByCode(existingAttempt.bookingCode),
          attempt: existingAttempt,
        );
      }
    }
    final amount = quote.finalQuotedPrice;
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        quote.currency.trim().isEmpty) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.quoteUnavailable,
      );
    }
    if (!provider.hasCustomerSessionGateway) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.unavailable,
      );
    }

    final timestamp = now().toUtc();
    final code = nextDemoBookingCode();
    if (demoBookings.any((item) => item.code == code)) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.duplicate,
      );
    }
    final booking = DemoBooking(
      code: code,
      ownerUserId: currentDemoUser.id,
      hotel: hotel,
      room: room,
      ratePlan: ratePlan,
      quote: quote,
      criteria: criteria,
      specialRequest: specialRequest.trim(),
      status: BookingStatus.pending,
      paymentStatus: BookingPaymentStatus.pending,
      createdAt: timestamp,
      updatedAt: timestamp,
      lastStatusChangedAt: timestamp,
    );
    final attempt = _buildPaymentAttempt(
      booking: booking,
      provider: provider,
      sequence: 1,
      timestamp: timestamp,
      idempotencyKey: normalizedKey,
    );
    demoBookings = [...demoBookings, booking];
    demoPaymentAttempts = [...demoPaymentAttempts, attempt];
    notifyListeners();
    return DemoCheckoutResult(
      result: DemoPaymentActionResult.success,
      booking: booking,
      attempt: attempt,
    );
  }

  DemoCheckoutResult startDemoPaymentForExistingBooking({
    required String bookingCode,
    required CheckoutPaymentProvider provider,
    required String idempotencyKey,
  }) {
    if (!demoMode) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.unavailable,
      );
    }
    final booking = demoBookingByCode(bookingCode);
    if (booking == null) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.bookingUnavailable,
      );
    }
    if (booking.status != BookingStatus.pending) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.invalidState,
        booking: booking,
      );
    }
    final normalizedKey = idempotencyKey.trim();
    if (normalizedKey.isNotEmpty) {
      final existingAttempt = _firstWhereOrNull(
        demoPaymentAttempts,
        (item) => item.idempotencyKey == normalizedKey,
      );
      if (existingAttempt != null) {
        return DemoCheckoutResult(
          result: DemoPaymentActionResult.duplicate,
          booking: demoBookingByCode(existingAttempt.bookingCode),
          attempt: existingAttempt,
        );
      }
    }
    final latest = latestPaymentAttemptForBooking(bookingCode);
    if (latest != null) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.invalidState,
        booking: booking,
        attempt: latest,
      );
    }
    final amount = booking.quote.finalQuotedPrice;
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        booking.quote.currency.trim().isEmpty) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.quoteUnavailable,
        booking: booking,
      );
    }
    if (!provider.hasCustomerSessionGateway) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.unavailable,
        booking: booking,
      );
    }

    final timestamp = now().toUtc();
    final attempt = _buildPaymentAttempt(
      booking: booking,
      provider: provider,
      sequence: 1,
      timestamp: timestamp,
      idempotencyKey: normalizedKey,
    );
    final updatedBooking = booking.copyWith(
      paymentStatus: BookingPaymentStatus.pending,
      updatedAt: timestamp,
    );
    _replaceDemoBooking(updatedBooking);
    demoPaymentAttempts = [...demoPaymentAttempts, attempt];
    notifyListeners();
    return DemoCheckoutResult(
      result: DemoPaymentActionResult.success,
      booking: updatedBooking,
      attempt: attempt,
    );
  }

  DemoPaymentActionResult completeDemoPayment(String attemptId) {
    if (!demoMode) return DemoPaymentActionResult.unavailable;
    final index =
        demoPaymentAttempts.indexWhere((item) => item.id == attemptId);
    if (index < 0) return DemoPaymentActionResult.notFound;
    final attempt = demoPaymentAttempts[index];
    if (attempt.isSuccessful) return DemoPaymentActionResult.success;
    if (!attempt.isPending) return DemoPaymentActionResult.invalidState;
    final booking = demoBookingByCode(attempt.bookingCode);
    if (booking == null) return DemoPaymentActionResult.bookingUnavailable;
    if (booking.status == BookingStatus.cancelled) {
      return DemoPaymentActionResult.invalidState;
    }
    final timestamp = now().toUtc();
    final updatedAttempt = attempt.copyWith(
      paymentStatus: BookingPaymentStatus.paid,
      sessionStatus: PaymentSessionStatus.captured,
      safeProviderReference: '${attempt.provider.code}-${attempt.sessionId}',
      paidAt: timestamp,
      updatedAt: timestamp,
    );
    final updatedBooking = booking.copyWith(
      status: BookingStatus.confirmed,
      paymentStatus: BookingPaymentStatus.paid,
      confirmedAt: booking.confirmedAt ?? timestamp,
      paidAt: timestamp,
      updatedAt: timestamp,
      lastStatusChangedAt: timestamp,
    );
    _replacePaymentAttempt(index, updatedAttempt);
    _replaceDemoBooking(updatedBooking);
    notifyListeners();
    return DemoPaymentActionResult.success;
  }

  DemoPaymentActionResult failDemoPayment(
    String attemptId, {
    String? reason,
  }) {
    if (!demoMode) return DemoPaymentActionResult.unavailable;
    final index =
        demoPaymentAttempts.indexWhere((item) => item.id == attemptId);
    if (index < 0) return DemoPaymentActionResult.notFound;
    final attempt = demoPaymentAttempts[index];
    if (attempt.sessionStatus == PaymentSessionStatus.failed) {
      return DemoPaymentActionResult.success;
    }
    if (!attempt.isPending) return DemoPaymentActionResult.invalidState;
    final booking = demoBookingByCode(attempt.bookingCode);
    if (booking == null) return DemoPaymentActionResult.bookingUnavailable;
    final timestamp = now().toUtc();
    final safeReason = reason?.trim();
    final updatedAttempt = attempt.copyWith(
      paymentStatus: BookingPaymentStatus.failed,
      sessionStatus: PaymentSessionStatus.failed,
      failureReason:
          safeReason == null || safeReason.isEmpty ? null : safeReason,
      failedAt: timestamp,
      updatedAt: timestamp,
    );
    final updatedBooking = booking.copyWith(
      paymentStatus: BookingPaymentStatus.failed,
      updatedAt: timestamp,
      lastStatusChangedAt: booking.lastStatusChangedAt,
    );
    _replacePaymentAttempt(index, updatedAttempt);
    _replaceDemoBooking(updatedBooking);
    notifyListeners();
    return DemoPaymentActionResult.success;
  }

  DemoPaymentActionResult cancelDemoPaymentAttempt(String attemptId) {
    if (!demoMode) return DemoPaymentActionResult.unavailable;
    final index =
        demoPaymentAttempts.indexWhere((item) => item.id == attemptId);
    if (index < 0) return DemoPaymentActionResult.notFound;
    final attempt = demoPaymentAttempts[index];
    if (attempt.sessionStatus == PaymentSessionStatus.cancelled) {
      return DemoPaymentActionResult.success;
    }
    if (!attempt.isPending) return DemoPaymentActionResult.invalidState;
    final booking = demoBookingByCode(attempt.bookingCode);
    if (booking == null) return DemoPaymentActionResult.bookingUnavailable;
    final timestamp = now().toUtc();
    final updatedAttempt = attempt.copyWith(
      paymentStatus: BookingPaymentStatus.failed,
      sessionStatus: PaymentSessionStatus.cancelled,
      cancelledAt: timestamp,
      updatedAt: timestamp,
    );
    final updatedBooking = booking.copyWith(
      paymentStatus: BookingPaymentStatus.failed,
      updatedAt: timestamp,
      lastStatusChangedAt: booking.lastStatusChangedAt,
    );
    _replacePaymentAttempt(index, updatedAttempt);
    _replaceDemoBooking(updatedBooking);
    notifyListeners();
    return DemoPaymentActionResult.success;
  }

  DemoCheckoutResult retryDemoPayment(String bookingCode) {
    if (!demoMode) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.unavailable,
      );
    }
    final booking = demoBookingByCode(bookingCode);
    if (booking == null) {
      return const DemoCheckoutResult(
        result: DemoPaymentActionResult.bookingUnavailable,
      );
    }
    if (booking.status == BookingStatus.cancelled ||
        demoPaymentAttempts.any((item) =>
            item.bookingCode == bookingCode &&
            item.paymentStatus == BookingPaymentStatus.paid)) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.invalidState,
        booking: booking,
      );
    }
    final latest = latestPaymentAttemptForBooking(bookingCode);
    if (latest != null && !latest.canRetry) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.invalidState,
        booking: booking,
        attempt: latest,
      );
    }
    final amount = booking.quote.finalQuotedPrice;
    if (amount == null || !amount.isFinite || amount <= 0) {
      return DemoCheckoutResult(
        result: DemoPaymentActionResult.quoteUnavailable,
        booking: booking,
      );
    }
    final sequence = demoPaymentAttempts
            .where((item) => item.bookingCode == bookingCode)
            .length +
        1;
    final timestamp = now().toUtc();
    final attempt = _buildPaymentAttempt(
      booking: booking,
      provider: latest?.provider ?? CheckoutPaymentProvider.mock,
      sequence: sequence,
      timestamp: timestamp,
      idempotencyKey: 'retry-$bookingCode-$sequence',
    );
    final updatedBooking = booking.copyWith(
      paymentStatus: BookingPaymentStatus.pending,
      updatedAt: timestamp,
    );
    demoPaymentAttempts = [...demoPaymentAttempts, attempt];
    _replaceDemoBooking(updatedBooking);
    notifyListeners();
    return DemoCheckoutResult(
      result: DemoPaymentActionResult.success,
      booking: updatedBooking,
      attempt: attempt,
    );
  }

  BookingModificationEligibility modificationEligibilityForBooking(
    DemoBooking booking,
  ) {
    if (!demoMode) {
      return const BookingModificationEligibility(
        result: BookingModificationResult.unavailable,
      );
    }
    final current = demoBookingByCode(booking.code);
    if (current == null) {
      return const BookingModificationEligibility(
        result: BookingModificationResult.notFound,
      );
    }
    if (current.ownerUserId != currentDemoUser.id) {
      return BookingModificationEligibility(
        result: BookingModificationResult.forbidden,
        booking: current,
      );
    }
    if (current.status != BookingStatus.pending) {
      return BookingModificationEligibility(
        result: BookingModificationResult.onlyPending,
        booking: current,
      );
    }
    if (!_bookingReferencesAvailable(current)) {
      return BookingModificationEligibility(
        result: BookingModificationResult.roomRateUnavailable,
        booking: current,
      );
    }
    final checkIn = dateOnly(current.criteria.checkIn);
    if (checkIn.isBefore(dateOnly(now()))) {
      return BookingModificationEligibility(
        result: BookingModificationResult.stayStarted,
        booking: current,
      );
    }
    if (latestPaymentAttemptForBooking(current.code) != null) {
      return BookingModificationEligibility(
        result: BookingModificationResult.activePaymentStarted,
        booking: current,
      );
    }
    return BookingModificationEligibility(
      result: BookingModificationResult.available,
      booking: current,
    );
  }

  BookingModificationResult modifyDemoBooking({
    required String bookingCode,
    required DateTime expectedVersion,
    required BookingModificationDraft draft,
    required HotelRatePlan ratePlan,
    required HotelPricingQuote proposedQuote,
  }) {
    final booking = demoBookingByCode(bookingCode);
    final eligibility = booking == null
        ? const BookingModificationEligibility(
            result: BookingModificationResult.notFound,
          )
        : modificationEligibilityForBooking(booking);
    if (!eligibility.canModify || eligibility.booking == null) {
      return eligibility.result;
    }
    final current = eligibility.booking!;
    if (!current.modificationVersion
        .toUtc()
        .isAtSameMomentAs(expectedVersion.toUtc())) {
      return BookingModificationResult.stale;
    }
    if (!draft.changes(current)) {
      return BookingModificationResult.noChanges;
    }

    final newCheckIn = dateOnly(draft.checkIn);
    final newCheckOut = dateOnly(draft.checkOut);
    if (newCheckIn.isBefore(dateOnly(now())) ||
        !newCheckOut.isAfter(newCheckIn)) {
      return BookingModificationResult.invalidDates;
    }
    if (draft.adults < 1 || draft.children < 0 || draft.extraBeds < 0) {
      return BookingModificationResult.invalidGuests;
    }
    if (draft.adults > current.room.maxAdults ||
        draft.children > current.room.maxChildren ||
        draft.adults + draft.children > current.room.maxGuests) {
      return BookingModificationResult.capacityExceeded;
    }
    final supportedRatePlan = _ratePlanForBooking(current, ratePlan.ratePlanId);
    if (supportedRatePlan == null ||
        !supportedRatePlan.eligible ||
        supportedRatePlan.ratePlanId != ratePlan.ratePlanId) {
      return BookingModificationResult.roomRateUnavailable;
    }
    final amount = proposedQuote.finalQuotedPrice;
    if (amount == null ||
        !amount.isFinite ||
        amount < 0 ||
        proposedQuote.currency.trim().isEmpty ||
        proposedQuote.currency != current.quote.currency ||
        proposedQuote.selectedRatePlanId != ratePlan.ratePlanId ||
        !proposedQuote.inventoryAvailable) {
      return BookingModificationResult.quoteUnavailable;
    }

    final timestamp = now().toUtc();
    final criteria = current.criteria.copyWith(
      checkIn: newCheckIn,
      checkOut: newCheckOut,
      adults: draft.adults,
      children: draft.children,
      extraBeds: draft.extraBeds,
    );
    final updated = current.copyWith(
      ratePlan: supportedRatePlan,
      quote: proposedQuote,
      criteria: criteria,
      modifiedAt: timestamp,
      updatedAt: timestamp,
    );
    _replaceDemoBooking(updated);
    notifyListeners();
    return BookingModificationResult.available;
  }

  BookingCancellationEligibility cancellationEligibilityForBooking(
    DemoBooking booking,
  ) {
    if (!demoMode) {
      return const BookingCancellationEligibility(
        result: BookingCancellationResult.unavailable,
      );
    }
    final current = demoBookingByCode(booking.code);
    if (current == null) {
      return const BookingCancellationEligibility(
        result: BookingCancellationResult.notFound,
      );
    }
    if (current.ownerUserId != currentDemoUser.id) {
      return BookingCancellationEligibility(
        result: BookingCancellationResult.forbidden,
        booking: current,
      );
    }
    switch (current.status) {
      case BookingStatus.pending:
      case BookingStatus.confirmed:
        return BookingCancellationEligibility(
          result: BookingCancellationResult.eligible,
          booking: current,
        );
      case BookingStatus.cancelled:
        return BookingCancellationEligibility(
          result: BookingCancellationResult.alreadyCancelled,
          booking: current,
        );
      case BookingStatus.checkInReady:
      case BookingStatus.checkedIn:
        return BookingCancellationEligibility(
          result: BookingCancellationResult.checkInStarted,
          booking: current,
        );
      case BookingStatus.checkedOut:
      case BookingStatus.completed:
      case BookingStatus.refunded:
      case BookingStatus.archived:
      case BookingStatus.noShow:
        return BookingCancellationEligibility(
          result: BookingCancellationResult.completed,
          booking: current,
        );
    }
  }

  BookingCancellationResult cancelDemoBookingWithResult(
    String code, {
    String? reason,
  }) {
    final booking = demoBookingByCode(code);
    final eligibility = booking == null
        ? const BookingCancellationEligibility(
            result: BookingCancellationResult.notFound,
          )
        : cancellationEligibilityForBooking(booking);
    if (!eligibility.canCancel || eligibility.booking == null) {
      return eligibility.result;
    }
    final current = eligibility.booking!;
    final timestamp = now().toUtc();
    final safeReason = reason?.trim();
    final updated = current.copyWith(
      status: BookingStatus.cancelled,
      cancelledAt: timestamp,
      updatedAt: timestamp,
      lastStatusChangedAt: timestamp,
      cancellationReason:
          safeReason == null || safeReason.isEmpty ? null : safeReason,
    );
    demoBookings = [
      for (final item in demoBookings)
        item.code == current.code ? updated : item,
    ];
    notifyListeners();
    return BookingCancellationResult.eligible;
  }

  bool cancelDemoBooking(String code, {String? reason}) {
    return cancelDemoBookingWithResult(code, reason: reason) ==
        BookingCancellationResult.eligible;
  }

  bool markDemoBookingItineraryAdded(String code) {
    if (!demoMode) return false;
    final index = demoBookings.indexWhere((item) => item.code == code);
    if (index < 0) return false;
    if (demoBookings[index].itineraryAdded) return true;
    final updated = demoBookings[index].copyWith(itineraryAdded: true);
    demoBookings = [
      for (var i = 0; i < demoBookings.length; i++)
        i == index ? updated : demoBookings[i],
    ];
    notifyListeners();
    return true;
  }

  DemoPaymentAttempt _buildPaymentAttempt({
    required DemoBooking booking,
    required CheckoutPaymentProvider provider,
    required int sequence,
    required DateTime timestamp,
    required String idempotencyKey,
  }) {
    final safeCode =
        booking.code.replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
    final suffix = sequence.toString().padLeft(2, '0');
    final sessionId = 'PS-$safeCode-$suffix';
    final paymentCode = 'PAY-$safeCode-$suffix';
    return DemoPaymentAttempt(
      id: paymentCode,
      sessionId: sessionId,
      bookingCode: booking.code,
      provider: provider,
      paymentMethod: provider.settlementMethod,
      amount: booking.quote.finalQuotedPrice ?? 0,
      currency: booking.quote.currency,
      paymentStatus: BookingPaymentStatus.pending,
      sessionStatus: PaymentSessionStatus.pending,
      checkoutUrl: _checkoutUrlForProvider(provider, sessionId),
      expiresAt: timestamp.add(const Duration(minutes: 30)),
      createdAt: timestamp,
      updatedAt: timestamp,
      idempotencyKey: idempotencyKey,
    );
  }

  String _checkoutUrlForProvider(
    CheckoutPaymentProvider provider,
    String sessionId,
  ) {
    if (provider == CheckoutPaymentProvider.mock) {
      return 'https://mock-gateway.planyourtrip.local/checkout/$sessionId';
    }
    return 'https://sandbox.example.test/checkout/$sessionId';
  }

  void _replacePaymentAttempt(int index, DemoPaymentAttempt attempt) {
    demoPaymentAttempts = [
      for (var i = 0; i < demoPaymentAttempts.length; i++)
        i == index ? attempt : demoPaymentAttempts[i],
    ];
  }

  void _replaceDemoBooking(DemoBooking booking) {
    demoBookings = [
      for (final item in demoBookings)
        item.code == booking.code ? booking : item,
    ];
  }

  bool _bookingReferencesAvailable(DemoBooking booking) {
    final hotel = _firstWhereOrNull(
      places,
      (place) => place.id == booking.hotel.id && place.hotelDetail != null,
    );
    if (hotel == null) return false;
    final room = _firstWhereOrNull(
      hotel.hotelDetail?.rooms ?? const <HotelRoom>[],
      (item) => item.id == booking.room.id && item.active,
    );
    if (room == null) return false;
    return _ratePlanForBooking(booking, booking.ratePlan.ratePlanId) != null;
  }

  HotelRatePlan? _ratePlanForBooking(DemoBooking booking, int ratePlanId) {
    final hotel = _firstWhereOrNull(
      places,
      (place) => place.id == booking.hotel.id && place.hotelDetail != null,
    );
    final room = _firstWhereOrNull(
      hotel?.hotelDetail?.rooms ?? const <HotelRoom>[],
      (item) => item.id == booking.room.id && item.active,
    );
    return _firstWhereOrNull(
      room?.ratePlans ?? const <HotelRatePlan>[],
      (item) => item.ratePlanId == ratePlanId,
    );
  }

  // ── Reviews and traveler trust ──────────────────────────────────────────

  TravelerReview? reviewById(int id) =>
      _firstWhereOrNull(reviews, (review) => review.id == id);

  List<TravelerReview> publicReviewsForPlace(
    int placeId, {
    ReviewSort sort = ReviewSort.newest,
    int? rating,
    bool verifiedOnly = false,
  }) {
    if (!demoMode) return <TravelerReview>[];
    final filtered = reviews.where((review) {
      if (review.placeId != placeId || !review.status.isPublic) return false;
      if (rating != null && review.ratingOverall != rating) return false;
      if (verifiedOnly && !review.hasVerifiedBooking) return false;
      return true;
    }).toList();
    filtered.sort((a, b) => _compareReviews(a, b, sort));
    return filtered;
  }

  List<TravelerReview> myReviews({ReviewStatus? status}) {
    if (!demoMode) return <TravelerReview>[];
    final user = currentDemoUser;
    final mine = reviews
        .where((review) =>
            review.authorUserId == user.id &&
            (status == null || review.status == status))
        .toList();
    mine.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return mine;
  }

  PlaceReviewSummary reviewSummaryForPlace(int placeId) {
    final public = publicReviewsForPlace(placeId);
    final distribution = {
      for (var rating = 1; rating <= 5; rating++)
        rating: public.where((review) => review.ratingOverall == rating).length,
    };
    final average = public.isEmpty
        ? null
        : public.map((review) => review.ratingOverall).reduce((a, b) => a + b) /
            public.length;
    final categoryAverages = <ReviewRatingCategory, double>{};
    for (final category in ReviewRatingCategory.values) {
      final ratings = public
          .map((review) => review.ratingFor(category))
          .whereType<int>()
          .toList();
      if (ratings.isNotEmpty) {
        categoryAverages[category] =
            ratings.reduce((a, b) => a + b) / ratings.length;
      }
    }
    return PlaceReviewSummary(
      placeId: placeId,
      total: public.length,
      average: average,
      distribution: distribution,
      categoryAverages: categoryAverages,
      verifiedCount: public.where((review) => review.hasVerifiedBooking).length,
      preview: public.take(3).toList(),
    );
  }

  ReviewEligibility reviewEligibilityForPlace(int placeId) {
    if (!demoMode) {
      return const ReviewEligibility(result: ReviewActionResult.unavailable);
    }
    final booking = _firstWhereOrNull(
      demoBookings,
      (item) =>
          item.hotel.id == placeId &&
          item.status == BookingStatus.completed &&
          !reviews.any((review) => review.bookingCode == item.code),
    );
    if (booking == null) {
      return const ReviewEligibility(result: ReviewActionResult.ineligible);
    }
    return ReviewEligibility(
        result: ReviewActionResult.success, booking: booking);
  }

  ReviewEligibility reviewEligibilityForBooking(DemoBooking booking) {
    if (!demoMode) {
      return const ReviewEligibility(result: ReviewActionResult.unavailable);
    }
    final current =
        _firstWhereOrNull(demoBookings, (item) => item.code == booking.code);
    if (current == null) {
      return const ReviewEligibility(result: ReviewActionResult.notFound);
    }
    if (current.status != BookingStatus.completed) {
      return ReviewEligibility(
        result: ReviewActionResult.ineligible,
        booking: current,
      );
    }
    if (reviews.any((review) => review.bookingCode == current.code)) {
      return ReviewEligibility(
        result: ReviewActionResult.duplicate,
        booking: current,
      );
    }
    return ReviewEligibility(
        result: ReviewActionResult.success, booking: current);
  }

  ReviewActionResult createDemoReviewForBooking({
    required String bookingCode,
    required int ratingOverall,
    int? ratingCleanliness,
    int? ratingService,
    int? ratingLocation,
    int? ratingValue,
    int? ratingFacilities,
    String title = '',
    String content = '',
  }) {
    if (!demoMode) return ReviewActionResult.unavailable;
    final booking =
        _firstWhereOrNull(demoBookings, (item) => item.code == bookingCode);
    if (booking == null) return ReviewActionResult.notFound;
    final eligibility = reviewEligibilityForBooking(booking);
    if (eligibility.result != ReviewActionResult.success) {
      return eligibility.result;
    }
    final ratings = [
      ratingOverall,
      if (ratingCleanliness != null) ratingCleanliness,
      if (ratingService != null) ratingService,
      if (ratingLocation != null) ratingLocation,
      if (ratingValue != null) ratingValue,
      if (ratingFacilities != null) ratingFacilities,
    ];
    if (!ratings.every(_validReviewRating)) {
      return ReviewActionResult.invalidRating;
    }
    final safeTitle = title.trim();
    final safeContent = content.trim();
    if (safeTitle.length > 200) return ReviewActionResult.titleTooLong;
    if (safeContent.length > 5000) return ReviewActionResult.contentTooLong;

    final user = currentDemoUser;
    final timestamp = now();
    final id = reviews.fold<int>(
          0,
          (value, review) => review.id > value ? review.id : value,
        ) +
        1;
    reviews = [
      TravelerReview(
        id: id,
        bookingId: booking.code,
        bookingCode: booking.code,
        authorUserId: user.id,
        authorName: user.fullName,
        placeId: booking.hotel.id,
        placeName: booking.hotel.name,
        ratingOverall: ratingOverall,
        ratingCleanliness: ratingCleanliness,
        ratingService: ratingService,
        ratingLocation: ratingLocation,
        ratingValue: ratingValue,
        ratingFacilities: ratingFacilities,
        title: safeTitle,
        content: safeContent,
        status: ReviewStatus.pending,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
      ...reviews,
    ];
    notifyListeners();
    return ReviewActionResult.success;
  }

  // ── Demo rewards ─────────────────────────────────────────────────────────

  RewardActionResult enrollDemoMembership() {
    if (!demoMode) return RewardActionResult.unavailable;
    final current = membershipAccount ?? const MembershipAccount();
    if (current.active && !current.expired) return RewardActionResult.success;
    final enrolled = current.copyWith(
      active: true,
      expired: false,
      qualifiedAt: now(),
      validFrom: now(),
      validUntil: current.validUntil ?? now().add(const Duration(days: 365)),
    );
    membershipAccount = enrolled;
    if (!membershipHistory.any((item) =>
        item.tier == enrolled.displayTier &&
        item.description == 'Local demo enrollment')) {
      membershipHistory = [
        ...membershipHistory,
        MembershipHistoryItem(
          tier: enrolled.displayTier,
          changedAt: now(),
          description: 'Local demo enrollment',
        ),
      ];
    }
    notifyListeners();
    return RewardActionResult.success;
  }

  RewardActionResult claimDemoCoupon(String code) {
    if (!demoMode) return RewardActionResult.unavailable;
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return RewardActionResult.blank;
    final index =
        coupons.indexWhere((coupon) => coupon.code.toUpperCase() == normalized);
    if (index < 0) return RewardActionResult.rejected;
    if (coupons[index].isClaimed) return RewardActionResult.duplicate;
    final updated = coupons[index].copyWith(
      status: 'CLAIMED',
      effectiveStatus: 'ACTIVE',
      claimedAt: now(),
      expiresAt: coupons[index].expiresAt ?? coupons[index].validUntil,
    );
    coupons = [
      for (var i = 0; i < coupons.length; i++) i == index ? updated : coupons[i]
    ];
    notifyListeners();
    return RewardActionResult.success;
  }

  RewardActionResult useDemoReferralCode(String code) {
    if (!demoMode) return RewardActionResult.unavailable;
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return RewardActionResult.blank;
    final summary = referralSummary;
    if (summary == null) return RewardActionResult.unavailable;
    if (normalized == summary.code.toUpperCase()) {
      return RewardActionResult.ownCode;
    }
    if (summary.usedCode != null ||
        referralHistory.any((item) =>
            item.role == ReferralRole.invitee &&
            item.campaignCode.toUpperCase() == normalized)) {
      return RewardActionResult.duplicate;
    }
    referralSummary = summary.copyWith(
      pendingReferrals: summary.pendingReferrals + 1,
      usedCode: normalized,
    );
    referralHistory = [
      ReferralHistoryItem(
        role: ReferralRole.invitee,
        campaignCode: normalized,
        status: ReferralStatus.used,
        usedAt: now(),
      ),
      ...referralHistory,
    ];
    notifyListeners();
    return RewardActionResult.success;
  }

  RewardActionResult claimDemoGiftCard(String code) {
    if (!demoMode) return RewardActionResult.unavailable;
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return RewardActionResult.blank;
    if (giftCards.any((card) => card.id == 'gift-claimed-local')) {
      return RewardActionResult.duplicate;
    }
    if (normalized != 'GIFTDEMO') return RewardActionResult.rejected;
    giftCards = [
      GiftCard(
        id: 'gift-claimed-local',
        maskedCode: 'PYT-****-9900',
        productName: 'Demo Claimed Gift Card',
        originalAmountMinor: 300000,
        currentBalanceMinor: 300000,
        currency: 'VND',
        status: GiftCardStatus.active,
        effectiveStatus: GiftCardStatus.active,
        issuedAt: now(),
        activatedAt: now(),
        expiresAt: now().add(const Duration(days: 365)),
        personalMessage: 'Local demo claim only.',
        purchaserSummary: 'Demo campaign',
        recipientSummary: email ?? MockData.demoEmail,
        transactions: [
          GiftCardTransaction(
            id: 'gift-claimed-local-activation',
            transactionType: GiftCardTransactionType.activation,
            amountMinor: 300000,
            balanceBeforeMinor: 0,
            balanceAfterMinor: 300000,
            description: 'Local demo gift-card claim',
            createdAt: now(),
          ),
        ],
      ),
      ...giftCards,
    ];
    notifyListeners();
    return RewardActionResult.success;
  }

  RewardActionResult activateDemoGiftCard(String id) {
    if (!demoMode) return RewardActionResult.unavailable;
    final index = giftCards.indexWhere((card) => card.id == id);
    if (index < 0) return RewardActionResult.rejected;
    final card = giftCards[index];
    if (card.effectiveStatus != GiftCardStatus.issued) {
      return RewardActionResult.duplicate;
    }
    final updated = card.copyWith(
      status: GiftCardStatus.active,
      effectiveStatus: GiftCardStatus.active,
      activatedAt: now(),
      transactions: [
        GiftCardTransaction(
          id: '${card.id}-activation',
          transactionType: GiftCardTransactionType.activation,
          amountMinor: card.currentBalanceMinor,
          balanceBeforeMinor: 0,
          balanceAfterMinor: card.currentBalanceMinor,
          description: 'Local demo activation',
          createdAt: now(),
        ),
        ...card.transactions,
      ],
    );
    giftCards = [
      for (var i = 0; i < giftCards.length; i++)
        i == index ? updated : giftCards[i],
    ];
    notifyListeners();
    return RewardActionResult.success;
  }

  // ── Travel wallet and trip documents ────────────────────────────────────

  List<TravelWalletItem> sortedWalletItems({DateTime? today}) {
    final current = today ?? now();
    return List<TravelWalletItem>.from(travelWalletItems)
      ..sort((a, b) => _compareWalletItems(a, b, current));
  }

  List<TripDocument> documentsForTrip(int tripId) =>
      tripDocuments.where((doc) => doc.tripId == tripId).toList()
        ..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          final updated = b.updatedAt.compareTo(a.updatedAt);
          return updated == 0 ? b.createdAt.compareTo(a.createdAt) : updated;
        });

  WalletActionResult addWalletItem(TravelWalletItem item) {
    if (!demoMode) return WalletActionResult.unavailable;
    if (item.title.trim().isEmpty) return WalletActionResult.blank;
    if (!_validWalletDates(item.validFrom, item.validUntil)) {
      return WalletActionResult.invalidDateRange;
    }
    if (travelWalletItems.any((existing) => existing.id == item.id)) {
      return WalletActionResult.duplicate;
    }
    travelWalletItems = [...travelWalletItems, _sanitizeWalletItem(item)];
    notifyListeners();
    return WalletActionResult.success;
  }

  WalletActionResult updateWalletItem(TravelWalletItem item) {
    if (!demoMode) return WalletActionResult.unavailable;
    final index =
        travelWalletItems.indexWhere((existing) => existing.id == item.id);
    if (index < 0) return WalletActionResult.notFound;
    if (item.title.trim().isEmpty) return WalletActionResult.blank;
    if (!_validWalletDates(item.validFrom, item.validUntil)) {
      return WalletActionResult.invalidDateRange;
    }
    final original = travelWalletItems[index];
    final safe = _sanitizeWalletItem(item.copyWith(
      linkedTripId: original.linkedTripId,
      linkedTripTitle: original.linkedTripTitle,
      linkedDocumentId: original.linkedDocumentId,
      linkedBookingId: original.linkedBookingId,
      linkedInvoiceId: original.linkedInvoiceId,
      updatedAt: now(),
    ));
    travelWalletItems = [
      for (var i = 0; i < travelWalletItems.length; i++)
        i == index ? safe : travelWalletItems[i],
    ];
    notifyListeners();
    return WalletActionResult.success;
  }

  WalletActionResult deleteWalletItem(String id) {
    if (!demoMode) return WalletActionResult.unavailable;
    if (!travelWalletItems.any((item) => item.id == id)) {
      return WalletActionResult.notFound;
    }
    travelWalletItems =
        travelWalletItems.where((item) => item.id != id).toList();
    notifyListeners();
    return WalletActionResult.success;
  }

  WalletActionResult setWalletFavorite(String id, bool favorite) =>
      _updateWalletFlag(
          id,
          (item) => item.copyWith(
                favorite: favorite,
                updatedAt: now(),
              ));

  WalletActionResult setWalletArchived(String id, bool archived) =>
      _updateWalletFlag(
          id,
          (item) => item.copyWith(
                archived: archived,
                updatedAt: now(),
              ));

  WalletActionResult setWalletExpiryReminder(String id, bool enabled) =>
      _updateWalletFlag(
          id,
          (item) => item.copyWith(
                expiryReminderEnabled: enabled,
                updatedAt: now(),
              ));

  WalletActionResult addTripDocument(TripDocument document) {
    if (!demoMode) return WalletActionResult.unavailable;
    if (tripById(document.tripId) == null) return WalletActionResult.notFound;
    if (document.title.trim().isEmpty) return WalletActionResult.blank;
    if (!_hasSafeDocumentMedia(document)) {
      return WalletActionResult.unsafeUrl;
    }
    if (document.tripDayId != null) {
      final trip = tripById(document.tripId)!;
      if (document.tripDayId! < 1 || document.tripDayId! > trip.days) {
        return WalletActionResult.rejected;
      }
    }
    if (document.tripActivityId != null &&
        !timeline.any((item) =>
            item.id == document.tripActivityId &&
            item.tripId == document.tripId)) {
      return WalletActionResult.rejected;
    }
    if (tripDocuments.any((existing) => existing.id == document.id)) {
      return WalletActionResult.duplicate;
    }
    tripDocuments = [...tripDocuments, document];
    notifyListeners();
    return WalletActionResult.success;
  }

  WalletActionResult updateTripDocument(TripDocument document) {
    if (!demoMode) return WalletActionResult.unavailable;
    final index =
        tripDocuments.indexWhere((existing) => existing.id == document.id);
    if (index < 0) return WalletActionResult.notFound;
    if (document.title.trim().isEmpty) return WalletActionResult.blank;
    if (!_hasSafeDocumentMedia(document)) {
      return WalletActionResult.unsafeUrl;
    }
    final original = tripDocuments[index];
    final safe = document.copyWith(
      tripId: original.tripId,
      mediaUrl: original.mediaUrl,
      mediaLabel: original.mediaLabel,
      updatedAt: now(),
    );
    tripDocuments = [
      for (var i = 0; i < tripDocuments.length; i++)
        i == index ? safe : tripDocuments[i],
    ];
    notifyListeners();
    return WalletActionResult.success;
  }

  WalletActionResult deleteTripDocument(String id) {
    if (!demoMode) return WalletActionResult.unavailable;
    if (!tripDocuments.any((doc) => doc.id == id)) {
      return WalletActionResult.notFound;
    }
    final changedAt = now();
    tripDocuments = tripDocuments.where((doc) => doc.id != id).toList();
    travelWalletItems =
        travelWalletItems.where((item) => item.linkedDocumentId != id).toList();
    tripReminders = tripReminders
        .map((reminder) => reminder.documentId == id
            ? reminder.copyWith(documentId: null, updatedAt: changedAt)
            : reminder)
        .toList();
    notifyListeners();
    return WalletActionResult.success;
  }

  WalletActionResult setTripDocumentPinned(String id, bool pinned) {
    if (!demoMode) return WalletActionResult.unavailable;
    final index = tripDocuments.indexWhere((doc) => doc.id == id);
    if (index < 0) return WalletActionResult.notFound;
    tripDocuments = [
      for (var i = 0; i < tripDocuments.length; i++)
        i == index
            ? tripDocuments[i].copyWith(pinned: pinned, updatedAt: now())
            : tripDocuments[i],
    ];
    notifyListeners();
    return WalletActionResult.success;
  }

  TravelWalletItem? importDemoBookingToWallet(String bookingCode) {
    if (!demoMode) return null;
    final existing = _firstWhereOrNull(
      travelWalletItems,
      (item) => item.linkedBookingId == bookingCode,
    );
    if (existing != null) return existing;
    final booking = _firstWhereOrNull(
      demoBookings,
      (item) => item.code == bookingCode,
    );
    if (booking == null) return null;
    final trip = booking.criteria.tripId == null
        ? null
        : tripById(booking.criteria.tripId!);
    final item = TravelWalletItem(
      id: 'wallet-booking-${booking.code}',
      linkedTripId: trip?.id,
      linkedTripTitle: trip?.title,
      linkedBookingId: booking.code,
      type: WalletItemType.bookingConfirmation,
      title: booking.hotel.name,
      issuer: 'Plan Your Trip local demo',
      maskedReference: maskSensitiveReference(booking.code),
      validFrom: booking.criteria.checkIn,
      validUntil: booking.criteria.checkOut,
      status: booking.status == BookingStatus.cancelled
          ? WalletItemStatus.cancelled
          : WalletItemStatus.active,
      createdAt: now(),
      updatedAt: now(),
    );
    travelWalletItems = [...travelWalletItems, item];
    notifyListeners();
    return item;
  }

  TravelWalletItem? importTripDocumentToWallet(String documentId) {
    if (!demoMode) return null;
    final existing = _firstWhereOrNull(
      travelWalletItems,
      (item) => item.linkedDocumentId == documentId,
    );
    if (existing != null) return existing;
    final document = _firstWhereOrNull(
      tripDocuments,
      (item) => item.id == documentId,
    );
    if (document == null) return null;
    final trip = tripById(document.tripId);
    final item = TravelWalletItem(
      id: 'wallet-doc-${document.id}',
      linkedTripId: trip?.id,
      linkedTripTitle: trip?.title,
      linkedDocumentId: document.id,
      type: document.type.walletItemType,
      title: document.title,
      issuer: document.uploaderName,
      maskedReference: maskSensitiveReference(document.id),
      validFrom: trip?.startDate,
      validUntil: trip?.endDate,
      createdAt: now(),
      updatedAt: now(),
    );
    travelWalletItems = [...travelWalletItems, item];
    notifyListeners();
    return item;
  }

  // ── Trip collaboration and companion tools ──────────────────────────────

  String get currentUserEmail =>
      (email?.trim().isNotEmpty ?? false) ? email!.trim() : MockData.demoEmail;

  DemoTripUser get currentDemoUser {
    final normalized = _normalizeEmail(currentUserEmail);
    return _firstWhereOrNull(
          MockData.demoTripUsers,
          (user) => _normalizeEmail(user.email) == normalized,
        ) ??
        MockData.demoTripUsers.first;
  }

  TripPermission tripAccessLevel(int tripId) {
    if (!demoMode) return TripPermission.noAccess;
    final actor = _normalizeEmail(currentUserEmail);
    final trip = tripById(tripId);
    if (trip != null && _normalizeEmail(trip.ownerEmail) == actor) {
      return TripPermission.owner;
    }
    final collaborator = _firstWhereOrNull(
      tripCollaborators,
      (item) =>
          item.tripPlanId == tripId &&
          item.active &&
          _normalizeEmail(item.userEmail) == actor,
    );
    if (collaborator == null) return TripPermission.noAccess;
    return collaborator.role == TripCollaboratorRole.editor
        ? TripPermission.editor
        : TripPermission.viewer;
  }

  bool isTripPublic(int tripId) => publicTripIds.contains(tripId);

  List<TripCollaborator> collaboratorsForTrip(int tripId) =>
      tripCollaborators.where((item) => item.tripPlanId == tripId).toList()
        ..sort((a, b) {
          if (a.active != b.active) return a.active ? -1 : 1;
          return a.userFullName.compareTo(b.userFullName);
        });

  List<TripCollaborator> activeCollaboratorsForTrip(int tripId) =>
      collaboratorsForTrip(tripId).where((item) => item.active).toList();

  List<SharedTripSummary> visibleSharedTrips() {
    if (!demoMode) return <SharedTripSummary>[];
    final actor = _normalizeEmail(currentUserEmail);
    final ownedTripIds = trips
        .where((trip) => _normalizeEmail(trip.ownerEmail) == actor)
        .map((trip) => trip.id)
        .toSet();
    final visible = <SharedTripSummary>[];
    final seen = <int>{};

    for (final collaborator in tripCollaborators) {
      if (!collaborator.active ||
          _normalizeEmail(collaborator.userEmail) != actor ||
          ownedTripIds.contains(collaborator.tripPlanId)) {
        continue;
      }
      final trip = tripById(collaborator.tripPlanId);
      if (trip == null || !seen.add(trip.id)) continue;
      visible.add(SharedTripSummary(
        tripId: trip.id,
        title: trip.title,
        destination: trip.destination,
        coverImage: trip.imageUrl,
        startDate: trip.startDate,
        endDate: trip.endDate,
        status: 'ACTIVE',
        ownerName: trip.ownerName,
        role: collaborator.role,
      ));
    }

    if (actor == _normalizeEmail(MockData.demoEmail)) {
      for (final summary in sharedTrips) {
        if (seen.add(summary.tripId)) visible.add(summary);
      }
    }

    return visible..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  TripCompanionCounts companionCountsForTrip(int tripId) => TripCompanionCounts(
        activeCollaborators: activeCollaboratorsForTrip(tripId).length,
        notes: notesForTrip(tripId).length,
        uncheckedPacking: packingProgressForTrip(tripId).unchecked,
        pendingReminders: remindersForTrip(tripId)
            .where((item) => item.status == TripReminderStatus.pending)
            .length,
        documents: documentsForTrip(tripId).length,
      );

  TripToolActionResult inviteTripCollaborator(
    int tripId,
    String email, {
    TripCollaboratorRole role = TripCollaboratorRole.viewer,
  }) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (tripAccessLevel(tripId) != TripPermission.owner) {
      return TripToolActionResult.forbidden;
    }
    final trip = tripById(tripId);
    if (trip == null) return TripToolActionResult.notFound;
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty) return TripToolActionResult.blank;
    if (!_looksLikeEmail(normalized)) return TripToolActionResult.invalidEmail;
    if (_normalizeEmail(trip.ownerEmail) == normalized) {
      return TripToolActionResult.rejected;
    }
    if (tripCollaborators.any((item) =>
        item.tripPlanId == tripId &&
        _normalizeEmail(item.userEmail) == normalized)) {
      return TripToolActionResult.duplicate;
    }
    final user = _firstWhereOrNull(
      MockData.demoTripUsers,
      (item) => _normalizeEmail(item.email) == normalized,
    );
    if (user == null) return TripToolActionResult.rejected;
    final timestamp = now();
    tripCollaborators = [
      ...tripCollaborators,
      TripCollaborator(
        id: 'collab-$tripId-${user.id}',
        tripPlanId: tripId,
        userId: user.id,
        userEmail: user.email,
        userFullName: user.fullName,
        role: role,
        invitedAt: timestamp,
        acceptedAt: timestamp,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult updateCollaboratorRole(
    int tripId,
    String collaboratorId,
    TripCollaboratorRole role,
  ) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (tripAccessLevel(tripId) != TripPermission.owner) {
      return TripToolActionResult.forbidden;
    }
    final index = tripCollaborators.indexWhere(
      (item) => item.id == collaboratorId && item.tripPlanId == tripId,
    );
    if (index < 0) return TripToolActionResult.notFound;
    tripCollaborators = [
      for (var i = 0; i < tripCollaborators.length; i++)
        i == index
            ? tripCollaborators[i].copyWith(role: role, updatedAt: now())
            : tripCollaborators[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult removeCollaborator(int tripId, String collaboratorId) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (tripAccessLevel(tripId) != TripPermission.owner) {
      return TripToolActionResult.forbidden;
    }
    final removed = _firstWhereOrNull(
      tripCollaborators,
      (item) => item.id == collaboratorId && item.tripPlanId == tripId,
    );
    if (removed == null) return TripToolActionResult.notFound;
    tripCollaborators =
        tripCollaborators.where((item) => item.id != collaboratorId).toList();
    packingItems = packingItems
        .map((item) =>
            item.tripPlanId == tripId && item.assignedToUserId == removed.userId
                ? item.copyWith(
                    assignedToUserId: null,
                    assignedToUserName: null,
                    updatedAt: now(),
                  )
                : item)
        .toList();
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult setTripPublic(int tripId, bool isPublic) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (tripAccessLevel(tripId) != TripPermission.owner) {
      return TripToolActionResult.forbidden;
    }
    if (tripById(tripId) == null) return TripToolActionResult.notFound;
    publicTripIds = {...publicTripIds};
    isPublic ? publicTripIds.add(tripId) : publicTripIds.remove(tripId);
    notifyListeners();
    return TripToolActionResult.success;
  }

  List<TripNote> notesForTrip(int tripId) =>
      tripNotes.where((note) => note.tripPlanId == tripId).toList()
        ..sort((a, b) {
          if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
          final updated = b.updatedAt.compareTo(a.updatedAt);
          return updated == 0 ? b.createdAt.compareTo(a.createdAt) : updated;
        });

  TripToolActionResult addTripNote(TripNote note) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (!tripAccessLevel(note.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    final validation = _validateTripNote(note);
    if (validation != TripToolActionResult.success) return validation;
    if (tripNotes.any((item) => item.id == note.id)) {
      return TripToolActionResult.duplicate;
    }
    final user = currentDemoUser;
    final safe = note.copyWith(
      authorUserId: user.id,
      authorUserName: user.fullName,
      title: note.title.trim(),
      content: note.content.trim(),
      photoUrl: note.photoUrl.trim(),
    );
    tripNotes = [...tripNotes, safe];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult updateTripNote(TripNote note) {
    if (!demoMode) return TripToolActionResult.unavailable;
    final index = tripNotes.indexWhere((item) => item.id == note.id);
    if (index < 0) return TripToolActionResult.notFound;
    final original = tripNotes[index];
    if (!tripAccessLevel(original.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    final validation = _validateTripNote(note.copyWith(
      tripPlanId: original.tripPlanId,
      authorUserId: original.authorUserId,
      authorUserName: original.authorUserName,
      createdAt: original.createdAt,
    ));
    if (validation != TripToolActionResult.success) return validation;
    final safe = note.copyWith(
      tripPlanId: original.tripPlanId,
      authorUserId: original.authorUserId,
      authorUserName: original.authorUserName,
      createdAt: original.createdAt,
      title: note.title.trim(),
      content: note.content.trim(),
      photoUrl: note.photoUrl.trim(),
      updatedAt: now(),
    );
    tripNotes = [
      for (var i = 0; i < tripNotes.length; i++)
        i == index ? safe : tripNotes[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult deleteTripNote(String noteId) {
    final note = _firstWhereOrNull(tripNotes, (item) => item.id == noteId);
    if (!demoMode) return TripToolActionResult.unavailable;
    if (note == null) return TripToolActionResult.notFound;
    if (!tripAccessLevel(note.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    tripNotes = tripNotes.where((item) => item.id != noteId).toList();
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult setTripNotePinned(String noteId, bool pinned) {
    final index = tripNotes.indexWhere((item) => item.id == noteId);
    if (!demoMode) return TripToolActionResult.unavailable;
    if (index < 0) return TripToolActionResult.notFound;
    final note = tripNotes[index];
    if (!tripAccessLevel(note.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    tripNotes = [
      for (var i = 0; i < tripNotes.length; i++)
        i == index
            ? note.copyWith(pinned: pinned, updatedAt: now())
            : tripNotes[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  List<PackingItem> packingForTrip(int tripId) =>
      packingItems.where((item) => item.tripPlanId == tripId).toList()
        ..sort(_comparePackingItems);

  PackingProgress packingProgressForTrip(int tripId) {
    final items = packingItems.where((item) => item.tripPlanId == tripId);
    return PackingProgress(
      total: items.length,
      checked: items.where((item) => item.checked).length,
    );
  }

  TripToolActionResult addPackingItem(PackingItem item) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (!tripAccessLevel(item.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    final validation = _validatePackingItem(item);
    if (validation != TripToolActionResult.success) return validation;
    if (packingItems.any((existing) => existing.id == item.id)) {
      return TripToolActionResult.duplicate;
    }
    packingItems = [...packingItems, _sanitizePackingItem(item)];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult updatePackingItem(PackingItem item) {
    if (!demoMode) return TripToolActionResult.unavailable;
    final index = packingItems.indexWhere((existing) => existing.id == item.id);
    if (index < 0) return TripToolActionResult.notFound;
    final original = packingItems[index];
    if (!tripAccessLevel(original.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    final validation = _validatePackingItem(item.copyWith(
      tripPlanId: original.tripPlanId,
      sortOrder: original.sortOrder,
      createdAt: original.createdAt,
    ));
    if (validation != TripToolActionResult.success) return validation;
    final safe = _sanitizePackingItem(item.copyWith(
      tripPlanId: original.tripPlanId,
      sortOrder: original.sortOrder,
      createdAt: original.createdAt,
      checked: original.checked,
      checkedAt: original.checkedAt,
      updatedAt: now(),
    ));
    packingItems = [
      for (var i = 0; i < packingItems.length; i++)
        i == index ? safe : packingItems[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult deletePackingItem(String id) {
    final item =
        _firstWhereOrNull(packingItems, (existing) => existing.id == id);
    if (!demoMode) return TripToolActionResult.unavailable;
    if (item == null) return TripToolActionResult.notFound;
    if (!tripAccessLevel(item.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    packingItems = packingItems.where((existing) => existing.id != id).toList();
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult setPackingChecked(String id, bool checked) {
    final index = packingItems.indexWhere((item) => item.id == id);
    if (!demoMode) return TripToolActionResult.unavailable;
    if (index < 0) return TripToolActionResult.notFound;
    final item = packingItems[index];
    if (!tripAccessLevel(item.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    packingItems = [
      for (var i = 0; i < packingItems.length; i++)
        i == index
            ? item.copyWith(
                checked: checked,
                checkedAt: checked ? now().toUtc() : null,
                updatedAt: now(),
              )
            : packingItems[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult reorderPackingItems(
      int tripId, List<String> orderedIds) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (!tripAccessLevel(tripId).canEdit) return TripToolActionResult.forbidden;
    final currentIds = packingItems
        .where((item) => item.tripPlanId == tripId)
        .map((item) => item.id)
        .toSet();
    final suppliedIds = orderedIds.toSet();
    if (orderedIds.length != currentIds.length ||
        suppliedIds.length != orderedIds.length ||
        suppliedIds.difference(currentIds).isNotEmpty ||
        currentIds.difference(suppliedIds).isNotEmpty) {
      return TripToolActionResult.invalidReorder;
    }
    final order = {
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };
    packingItems = packingItems
        .map((item) => item.tripPlanId == tripId
            ? item.copyWith(sortOrder: order[item.id], updatedAt: now())
            : item)
        .toList();
    notifyListeners();
    return TripToolActionResult.success;
  }

  List<TripReminder> remindersForTrip(
    int tripId, {
    bool includeCancelled = false,
  }) =>
      tripReminders
          .where((item) =>
              item.tripPlanId == tripId &&
              (includeCancelled || item.status != TripReminderStatus.cancelled))
          .toList()
        ..sort((a, b) {
          final date = a.reminderAt.compareTo(b.reminderAt);
          return date == 0 ? a.id.compareTo(b.id) : date;
        });

  TripToolActionResult addTripReminder(TripReminder reminder) {
    if (!demoMode) return TripToolActionResult.unavailable;
    if (!tripAccessLevel(reminder.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    final validation = _validateReminder(reminder);
    if (validation != TripToolActionResult.success) return validation;
    if (tripReminders.any((item) => item.id == reminder.id)) {
      return TripToolActionResult.duplicate;
    }
    final user = currentDemoUser;
    tripReminders = [
      ...tripReminders,
      reminder.copyWith(
        userId: user.id,
        userName: user.fullName,
        title: reminder.title.trim(),
        message: reminder.message.trim(),
        reminderAt: reminder.reminderAt.toUtc(),
      ),
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult updateTripReminder(TripReminder reminder) {
    if (!demoMode) return TripToolActionResult.unavailable;
    final index = tripReminders.indexWhere((item) => item.id == reminder.id);
    if (index < 0) return TripToolActionResult.notFound;
    final original = tripReminders[index];
    if (!tripAccessLevel(original.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    final validation = _validateReminder(reminder.copyWith(
      tripPlanId: original.tripPlanId,
      userId: original.userId,
      userName: original.userName,
      createdAt: original.createdAt,
      status: original.status,
      completedAt: original.completedAt,
    ));
    if (validation != TripToolActionResult.success) return validation;
    tripReminders = [
      for (var i = 0; i < tripReminders.length; i++)
        i == index
            ? reminder.copyWith(
                tripPlanId: original.tripPlanId,
                userId: original.userId,
                userName: original.userName,
                title: reminder.title.trim(),
                message: reminder.message.trim(),
                reminderAt: reminder.reminderAt.toUtc(),
                status: original.status,
                completedAt: original.completedAt,
                createdAt: original.createdAt,
                updatedAt: now(),
              )
            : tripReminders[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  TripToolActionResult completeTripReminder(String id) =>
      _setReminderStatus(id, TripReminderStatus.completed);

  TripToolActionResult cancelTripReminder(String id) =>
      _setReminderStatus(id, TripReminderStatus.cancelled);

  TripToolActionResult deleteTripReminder(String id) {
    final reminder = _firstWhereOrNull(tripReminders, (item) => item.id == id);
    if (!demoMode) return TripToolActionResult.unavailable;
    if (reminder == null) return TripToolActionResult.notFound;
    if (!tripAccessLevel(reminder.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    tripReminders = tripReminders.where((item) => item.id != id).toList();
    notifyListeners();
    return TripToolActionResult.success;
  }

  // ── Unique ID helper ──────────────────────────────────────────────────────

  int get newId => DateTime.now().millisecondsSinceEpoch;

  static bool isValidTimeRange(String start, String end) {
    final startMinutes = _minutes(start);
    final endMinutes = _minutes(end);
    return startMinutes != null &&
        endMinutes != null &&
        endMinutes > startMinutes;
  }

  static int? _minutes(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }
    return hour * 60 + minute;
  }

  static bool _placeMatchesCategory(Place place, String requested) {
    final key = requested.toLowerCase();
    final slug = place.effectiveCategorySlug.toLowerCase();
    final label = place.category.toLowerCase();
    if (slug == key || label == key) return true;

    switch (key) {
      case 'accommodation':
        return slug == 'hotel' || label == 'hotels';
      case 'food':
        return slug == 'restaurant' ||
            label == 'food' ||
            label == 'restaurants';
      case 'cafe':
        return label == 'cafe' || label == 'cafes';
      case 'attraction':
        return slug == 'photo-spot' ||
            label == 'attractions' ||
            label == 'photo spots' ||
            label == 'nature' ||
            label == 'culture';
      case 'entertainment':
        return label == 'entertainment' || label == 'nightlife';
      case 'transportation':
        return label == 'transportation' || label == 'transport';
      default:
        return false;
    }
  }

  static bool _validReviewRating(int rating) => rating >= 1 && rating <= 5;

  static int _compareReviews(
    TravelerReview a,
    TravelerReview b,
    ReviewSort sort,
  ) {
    switch (sort) {
      case ReviewSort.newest:
        final created = b.createdAt.compareTo(a.createdAt);
        return created == 0 ? b.id.compareTo(a.id) : created;
      case ReviewSort.oldest:
        final created = a.createdAt.compareTo(b.createdAt);
        return created == 0 ? a.id.compareTo(b.id) : created;
      case ReviewSort.highestRating:
        final rating = b.ratingOverall.compareTo(a.ratingOverall);
        return rating == 0 ? _compareReviews(a, b, ReviewSort.newest) : rating;
      case ReviewSort.lowestRating:
        final rating = a.ratingOverall.compareTo(b.ratingOverall);
        return rating == 0 ? _compareReviews(a, b, ReviewSort.newest) : rating;
      case ReviewSort.mostHelpful:
        final helpful = b.helpfulCount.compareTo(a.helpfulCount);
        return helpful == 0
            ? _compareReviews(a, b, ReviewSort.newest)
            : helpful;
    }
  }

  bool _isValidExpense(Expense expense) {
    final trip = tripById(expense.tripId);
    if (trip == null || !expense.amount.isFinite || expense.amount <= 0) {
      return false;
    }
    if (expense.currency.trim().isEmpty) return false;
    final day = expense.tripDayId;
    if (day != null && (day < 1 || day > trip.days)) return false;
    final itemId = expense.tripItemId;
    if (itemId != null &&
        !timeline.any((item) => item.id == itemId && item.tripId == trip.id)) {
      return false;
    }
    return true;
  }

  static int _compareTimelineItems(TimelineItem a, TimelineItem b) {
    final aStart = _minutes(a.startTime);
    final bStart = _minutes(b.startTime);
    if (aStart != null && bStart != null && aStart != bStart) {
      return aStart.compareTo(bStart);
    }
    if (aStart != null && bStart == null) return -1;
    if (aStart == null && bStart != null) return 1;
    final sortOrder = a.sortOrder.compareTo(b.sortOrder);
    if (sortOrder != 0) return sortOrder;
    return a.id.compareTo(b.id);
  }

  static int _compareNotifications(
    UserNotification a,
    UserNotification b,
  ) {
    final created = b.createdAt.compareTo(a.createdAt);
    return created == 0 ? a.id.compareTo(b.id) : created;
  }

  static int _compareSavedPlaces(SavedPlaceRecord a, SavedPlaceRecord b) {
    final saved = b.savedAt.compareTo(a.savedAt);
    return saved == 0 ? a.id.compareTo(b.id) : saved;
  }

  static int _compareSavedCollections(
    SavedCollectionRecord a,
    SavedCollectionRecord b,
  ) {
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    final created = a.createdAt.compareTo(b.createdAt);
    return created == 0 ? a.id.compareTo(b.id) : created;
  }

  static int _compareSavedCollectionPlaces(
    SavedCollectionPlaceRecord a,
    SavedCollectionPlaceRecord b,
  ) {
    final position = a.position.compareTo(b.position);
    if (position != 0) return position;
    final added = a.addedAt.compareTo(b.addedAt);
    return added == 0 ? a.id.compareTo(b.id) : added;
  }

  static bool _savedPlaceMatchesQuery(
    SavedPlaceRecord record,
    Place place,
    String normalizedQuery,
  ) {
    if (normalizedQuery.isEmpty) return true;
    final haystack = normalizeSearchText([
      place.name,
      place.category,
      place.locationName,
      place.city,
      place.province,
      place.description,
      place.tags.join(' '),
      record.note ?? '',
    ].join(' '));
    return haystack.contains(normalizedQuery);
  }

  static bool _savedPlaceNoteTooLong(String? value) =>
      value != null && value.length > SavedPlaceRecord.maxNoteLength;

  int _visibleSavedCollectionIndex(String collectionId) {
    if (!demoMode) return -1;
    final ownerId = currentDemoUser.id;
    return savedCollections.indexWhere(
      (collection) =>
          collection.id == collectionId && collection.ownerUserId == ownerId,
    );
  }

  int _nextCollectionSortOrder() {
    final collections = visibleSavedCollections;
    if (collections.isEmpty) return 0;
    return collections
            .map((collection) => collection.sortOrder)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  static SavedCollectionActionResult? _validateCollectionFields({
    required String name,
    String? description,
    String? coverImageUrl,
  }) {
    if (name.trim().isEmpty ||
        name.length > SavedCollectionRecord.maxNameLength) {
      return SavedCollectionActionResult.invalidName;
    }
    if (description != null &&
        description.length > SavedCollectionRecord.maxDescriptionLength) {
      return SavedCollectionActionResult.invalidDescription;
    }
    if (coverImageUrl != null &&
        coverImageUrl.length > SavedCollectionRecord.maxCoverImageUrlLength) {
      return SavedCollectionActionResult.invalidCover;
    }
    return null;
  }

  static String _collectionSlug(String name) {
    final normalized = normalizeSearchText(name)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return normalized.isEmpty ? 'collection' : normalized;
  }

  static String normalizeSearchText(String value) {
    var normalized = value.trim().toLowerCase();
    const replacements = {
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };
    for (final entry in replacements.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized.replaceAll(RegExp(r'\s+'), ' ');
  }

  WalletActionResult _updateWalletFlag(
    String id,
    TravelWalletItem Function(TravelWalletItem item) update,
  ) {
    if (!demoMode) return WalletActionResult.unavailable;
    final index = travelWalletItems.indexWhere((item) => item.id == id);
    if (index < 0) return WalletActionResult.notFound;
    travelWalletItems = [
      for (var i = 0; i < travelWalletItems.length; i++)
        i == index ? update(travelWalletItems[i]) : travelWalletItems[i],
    ];
    notifyListeners();
    return WalletActionResult.success;
  }

  TravelWalletItem _sanitizeWalletItem(TravelWalletItem item) {
    final masked = item.maskedReference.trim().isEmpty
        ? ''
        : maskSensitiveReference(item.maskedReference);
    final storedStatus = item.status == WalletItemStatus.expired
        ? WalletItemStatus.active
        : item.status;
    return item.copyWith(maskedReference: masked, status: storedStatus);
  }

  static bool _validWalletDates(DateTime? from, DateTime? until) {
    if (from == null || until == null) return true;
    return !dateOnly(until).isBefore(dateOnly(from));
  }

  static bool _hasSafeDocumentMedia(TripDocument document) {
    final mediaUrl = document.mediaUrl.trim();
    if (mediaUrl.isEmpty) return document.mediaLabel.trim().isNotEmpty;
    return isSafeDocumentMediaUrl(mediaUrl);
  }

  TripToolActionResult _validateTripNote(TripNote note) {
    final trip = tripById(note.tripPlanId);
    if (trip == null) return TripToolActionResult.notFound;
    if (note.content.trim().isEmpty) return TripToolActionResult.blank;
    if (!_validTripDay(trip, note.tripDayId)) {
      return TripToolActionResult.rejected;
    }
    if (!_validTripItem(note.tripPlanId, note.tripItemId)) {
      return TripToolActionResult.rejected;
    }
    if (note.photoUrl.trim().isNotEmpty &&
        !isSafeDocumentMediaUrl(note.photoUrl)) {
      return TripToolActionResult.unsafeUrl;
    }
    return TripToolActionResult.success;
  }

  TripToolActionResult _validatePackingItem(PackingItem item) {
    if (tripById(item.tripPlanId) == null) {
      return TripToolActionResult.notFound;
    }
    if (item.label.trim().isEmpty) return TripToolActionResult.blank;
    if (item.quantity < 1) return TripToolActionResult.invalidQuantity;
    if (!_validAssignee(item.tripPlanId, item.assignedToUserId)) {
      return TripToolActionResult.rejected;
    }
    return TripToolActionResult.success;
  }

  PackingItem _sanitizePackingItem(PackingItem item) {
    final assignee = item.assignedToUserId == null
        ? null
        : _assigneeFor(item.tripPlanId, item.assignedToUserId!);
    return item.copyWith(
      label: item.label.trim(),
      notes: item.notes.trim(),
      assignedToUserName: assignee?.$2,
    );
  }

  TripToolActionResult _validateReminder(TripReminder reminder) {
    final trip = tripById(reminder.tripPlanId);
    if (trip == null) return TripToolActionResult.notFound;
    if (reminder.title.trim().isEmpty) return TripToolActionResult.blank;
    if (!_validTripDay(trip, reminder.tripDayId)) {
      return TripToolActionResult.rejected;
    }
    if (!_validTripItem(reminder.tripPlanId, reminder.tripItemId)) {
      return TripToolActionResult.rejected;
    }
    if (reminder.documentId != null &&
        !tripDocuments.any((document) =>
            document.id == reminder.documentId &&
            document.tripId == reminder.tripPlanId)) {
      return TripToolActionResult.rejected;
    }
    return TripToolActionResult.success;
  }

  TripToolActionResult _setReminderStatus(
    String id,
    TripReminderStatus status,
  ) {
    final index = tripReminders.indexWhere((item) => item.id == id);
    if (!demoMode) return TripToolActionResult.unavailable;
    if (index < 0) return TripToolActionResult.notFound;
    final reminder = tripReminders[index];
    if (!tripAccessLevel(reminder.tripPlanId).canEdit) {
      return TripToolActionResult.forbidden;
    }
    if (reminder.status == status) return TripToolActionResult.success;
    if (reminder.status != TripReminderStatus.pending) {
      return TripToolActionResult.rejected;
    }
    final timestamp = now().toUtc();
    tripReminders = [
      for (var i = 0; i < tripReminders.length; i++)
        i == index
            ? reminder.copyWith(
                status: status,
                completedAt:
                    status == TripReminderStatus.completed ? timestamp : null,
                updatedAt: timestamp,
              )
            : tripReminders[i],
    ];
    notifyListeners();
    return TripToolActionResult.success;
  }

  bool _validTripDay(Trip trip, int? day) =>
      day == null || (day >= 1 && day <= trip.days);

  bool _validTripItem(int tripId, int? itemId) =>
      itemId == null ||
      timeline.any((item) => item.id == itemId && item.tripId == tripId);

  bool _validAssignee(int tripId, String? userId) {
    if (userId == null || userId.trim().isEmpty) return true;
    return _assigneeFor(tripId, userId) != null;
  }

  (String, String)? _assigneeFor(int tripId, String userId) {
    final trip = tripById(tripId);
    if (trip != null && trip.ownerUserId == userId) {
      return (trip.ownerUserId, trip.ownerName);
    }
    final collaborator = _firstWhereOrNull(
      tripCollaborators,
      (item) =>
          item.tripPlanId == tripId && item.active && item.userId == userId,
    );
    return collaborator == null
        ? null
        : (collaborator.userId, collaborator.userFullName);
  }

  static int _comparePackingItems(PackingItem a, PackingItem b) {
    if (a.checked != b.checked) return a.checked ? 1 : -1;
    final order = a.sortOrder.compareTo(b.sortOrder);
    if (order != 0) return order;
    return a.createdAt.compareTo(b.createdAt);
  }

  static String _normalizeEmail(String value) => value.trim().toLowerCase();

  static bool _looksLikeEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

  static int _compareWalletItems(
    TravelWalletItem a,
    TravelWalletItem b,
    DateTime today,
  ) {
    if (a.archived != b.archived) return a.archived ? 1 : -1;
    if (a.favorite != b.favorite) return a.favorite ? -1 : 1;
    final aStatus = a.effectiveStatus(today);
    final bStatus = b.effectiveStatus(today);
    final statusOrder = {
      WalletItemStatus.active: 0,
      WalletItemStatus.upcoming: 1,
      WalletItemStatus.expired: 2,
      WalletItemStatus.cancelled: 3,
      WalletItemStatus.archived: 4,
    };
    final status = statusOrder[aStatus]!.compareTo(statusOrder[bStatus]!);
    if (status != 0) return status;
    final aFrom = a.validFrom;
    final bFrom = b.validFrom;
    if (aFrom != null && bFrom != null) {
      final date = dateOnly(aFrom).compareTo(dateOnly(bFrom));
      if (date != 0) return date;
    } else if (aFrom != null) {
      return -1;
    } else if (bFrom != null) {
      return 1;
    }
    final created = b.createdAt.compareTo(a.createdAt);
    return created == 0 ? a.id.compareTo(b.id) : created;
  }

  static T? _firstWhereOrNull<T>(
    Iterable<T> values,
    bool Function(T value) test,
  ) {
    for (final value in values) {
      if (test(value)) return value;
    }
    return null;
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required super.child})
      : super(notifier: notifier);
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
