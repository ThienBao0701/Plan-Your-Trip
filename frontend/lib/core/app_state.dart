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
  List<TravelWalletItem> travelWalletItems =
      List.from(MockData.travelWalletItems);
  List<TripDocument> tripDocuments = List.from(MockData.tripDocuments);
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
    travelWalletItems = List.from(MockData.travelWalletItems);
    tripDocuments = List.from(MockData.tripDocuments);
    _applyRewardDataMode();
    notifyListeners();
  }

  void _applyPersonalDataMode() {
    if (demoMode) {
      trips = List.from(MockData.trips);
      timeline = List.from(MockData.timeline);
      expenses = List.from(MockData.expenses);
      demoBookings = [];
      travelWalletItems = List.from(MockData.travelWalletItems);
      tripDocuments = List.from(MockData.tripDocuments);
      _applyRewardDataMode();
      return;
    }
    trips = [];
    timeline = [];
    expenses = [];
    demoBookings = [];
    travelWalletItems = [];
    tripDocuments = [];
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
    final removedDocumentIds = tripDocuments
        .where((doc) => doc.tripId == id)
        .map((doc) => doc.id)
        .toSet();
    trips = trips.where((t) => t.id != id).toList();
    timeline = timeline.where((t) => t.tripId != id).toList();
    expenses = expenses.where((e) => e.tripId != id).toList();
    tripDocuments = tripDocuments.where((doc) => doc.tripId != id).toList();
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
    tripDocuments = tripDocuments.where((doc) => doc.id != id).toList();
    travelWalletItems =
        travelWalletItems.where((item) => item.linkedDocumentId != id).toList();
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
