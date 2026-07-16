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
  List<DemoBooking> demoBookings = [];
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
    demoBookings = [];
    _applyRewardDataMode();
    notifyListeners();
  }

  void _applyPersonalDataMode() {
    if (demoMode) {
      trips = List.from(MockData.trips);
      timeline = List.from(MockData.timeline);
      expenses = List.from(MockData.expenses);
      demoBookings = [];
      _applyRewardDataMode();
      return;
    }
    trips = [];
    timeline = [];
    expenses = [];
    demoBookings = [];
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

  void addTrip(Trip trip) {
    trips = [...trips, trip];
    notifyListeners();
  }

  void updateTrip(Trip updated) {
    trips = trips.map((t) => t.id == updated.id ? updated : t).toList();
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
    notifyListeners();
  }

  void deleteTrip(int id) {
    trips = trips.where((t) => t.id != id).toList();
    timeline = timeline.where((t) => t.tripId != id).toList();
    expenses = expenses.where((e) => e.tripId != id).toList();
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

  bool cancelDemoBooking(String code, {String? reason}) {
    if (!demoMode) return false;
    final index = demoBookings.indexWhere((item) => item.code == code);
    if (index < 0 || !demoBookings[index].status.canCancel) return false;
    final updated = demoBookings[index].copyWith(
      status: BookingStatus.cancelled,
      cancellationReason: reason?.trim().isEmpty == true ? null : reason,
    );
    demoBookings = [
      for (var i = 0; i < demoBookings.length; i++)
        i == index ? updated : demoBookings[i],
    ];
    notifyListeners();
    return true;
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
