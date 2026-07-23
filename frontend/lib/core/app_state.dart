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

  void _applyPersonalDataMode() {
    if (demoMode) {
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
