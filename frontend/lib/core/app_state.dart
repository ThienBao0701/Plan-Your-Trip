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
  // The full typed detail record behind each hydrated place (UI23). The [Place]
  // above is a lossy projection (single image, flattened hours); the rich
  // detail screen renders gallery / grouped hours / metadata / rich hotelDetail
  // from this record. Populated by the same single hydration call — no extra
  // HTTP — and cleared together with [_hydratedRealPlaces].
  final Map<int, PlaceDetailRecord> _hydratedRealPlaceDetails =
      <int, PlaceDetailRecord>{};
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

  // ── Real Mode Place Search (/api/places/search, UI-21) ────────────────────
  // Parallel to the demo-only [places]/[filteredPlaces] path — never merged.
  // The public search endpoint needs no auth, so a 401/403 is not expected but
  // is mapped defensively without logging out.
  List<PlaceSummaryRecord> realSearchResults = [];
  bool realSearchLoading = false; // initial / new-query load
  bool realSearchLoadingMore = false; // pagination
  bool realSearchRefreshing = false; // pull-to-refresh
  bool realSearchLoaded = false;
  PlaceSearchOutcome? realSearchError;
  String realSearchQuery = '';
  double? realSearchMinRating;
  int? realSearchMaxPriceLevel;
  PlaceSearchSort realSearchSort = PlaceSearchSort.newest;
  int realSearchPage = 0;
  int realSearchTotalPages = 0;
  int realSearchTotalElements = 0;
  // Monotonic id so a newer search always wins — a slower older response is
  // discarded instead of overwriting fresher results.
  int _realSearchRequestId = 0;
  static const int _realSearchPageSize = 20;
  // Sentinel distinguishing "argument omitted" from "explicitly set to null"
  // for the nullable filter parameters of [runRealSearch].
  static const Object _unset = Object();

  bool get realSearchHasMore => realSearchPage + 1 < realSearchTotalPages;

  // ── Real Mode Hotel Availability (/api/places/{id}/availability, UI-22) ────
  // Per-hotel real room availability + prices. Not paginated (the backend
  // returns the full room list), so there is no load-more here. A newer lookup
  // supersedes an older in-flight one (last wins). Zero HTTP in Demo Mode.
  HotelAvailabilityResult? realAvailability;
  bool realAvailabilityLoading = false;
  bool realAvailabilityRefreshing = false;
  HotelAvailabilityOutcome? realAvailabilityError;
  int? realAvailabilityPlaceId;
  int _realAvailabilityRequestId = 0;

  // UI24 — Real room selection over the UI22 availability result plus the
  // public per-room rate plans (`GET /rooms/{id}/rate-plans`). Selection is
  // client-side (the backend checkout is offline/mocked). Exactly one room may
  // be selected at a time; a date/guest change re-runs availability and
  // invalidates the selection if the room is no longer offered. Reset on
  // logout / mode change with the availability state.
  int? selectedRoomId;
  int? selectedRatePlanId;
  List<HotelRatePlan> roomRatePlans = const [];
  bool roomRatePlansLoading = false;
  RatePlanOutcome? roomRatePlansError;
  int? roomRatePlansRoomId;
  int _roomRatePlanRequestId = 0;

  // UI25 — Real booking flow foundation. A client-side booking DRAFT built on
  // top of the UI24 selection, priced by the real read-only quote endpoint
  // (`POST /api/rooms/{id}/pricing/quote`). No reservation is created — the
  // side-effecting `POST /api/bookings` create + payment are deferred. The guest
  // form is autosaved in-session (survives navigation) and reset only on logout
  // / mode change via [_resetBookingFlowState]. Zero HTTP in Demo Mode.
  String bookingGuestName = '';
  String bookingContactEmail = '';
  String bookingContactPhone = '';
  String bookingGuestCountry = '';
  String bookingArrivalTime = '';
  Set<SpecialRequestPreset> bookingSpecialRequestPresets =
      <SpecialRequestPreset>{};
  String bookingSpecialRequestNote = '';
  bool bookingTermsAccepted = false;
  HotelPricingQuote? bookingQuote;
  bool bookingQuoteLoading = false;
  BookingQuoteOutcome? bookingQuoteError;
  int? bookingQuoteRoomId;
  int _bookingQuoteRequestId = 0;
  BookingDraft? bookingDraft;

  // UI26 — Real booking submission. `submitRealBooking` performs the real
  // `POST /api/bookings` create (Real Mode only) and stores the server's own
  // booking record. Single-flight (only one submit at a time); no optimistic
  // insert; state advances only on a real backend response; the draft/guest form
  // are preserved on any failure. Cleared on logout / mode-or-user change via
  // [_resetBookingFlowState]. Zero HTTP in Demo Mode.
  bool realBookingSubmitting = false;
  BookingCreateRecord? lastCreatedBooking;
  BookingSubmissionOutcome? realBookingSubmissionError;

  /// True when the last submission could not be confirmed (timeout / malformed
  /// success). The booking MAY have been created — no blind resubmit is safe.
  bool get realBookingSubmissionUncertain =>
      realBookingSubmissionError == BookingSubmissionOutcome.uncertain;

  // ── Real Mode Booking History (/api/me/bookings + /api/bookings/{id}, UI-27) ─
  // Parallel to the demo-only [demoBookings] list — never merged. Read-only:
  // the full history list (bare array, no paging) + a per-id detail cache. A 401
  // here never calls logout(); the caller shows a re-auth affordance. Cleared on
  // logout / mode / user change via [_resetRealBookingHistoryState]. Zero HTTP in
  // Demo Mode.
  List<BookingSummaryRecord> realBookings = [];
  bool realBookingsLoading = false;
  bool realBookingsLoaded = false;
  bool realBookingsRefreshing = false;
  BookingHistoryOutcome? realBookingsError;
  final Map<int, BookingCreateRecord> bookingDetailCache = {};
  int? bookingDetailLoadingId;
  BookingHistoryOutcome? bookingDetailError;

  // ── Real Mode Payment (/api/payments, UI-28) ──────────────────────────────
  // The currently-open payment context for one booking. Read-only settlement:
  // create a PENDING payment, read/refresh its status, and settle it offline via
  // the backend's own sandbox endpoints (no live gateway → no redirect). A 401
  // here never calls logout(). Cleared on logout / mode / user change via
  // [_resetRealPaymentState]. Zero HTTP in Demo Mode.
  int? realPaymentBookingId;
  RealPaymentRecord? realPayment;
  bool realPaymentLoading = false;
  bool realPaymentSubmitting = false;
  PaymentActionOutcome? realPaymentError;

  // ── Real Mode Reviews (/api/reviews, /api/me/reviews, UI-29) ──────────────
  // Read a place's public (approved) reviews, the user's own reviews, and submit
  // a review for a COMPLETED booking (created PENDING → awaits moderation). A 401
  // never calls logout(). Cleared on logout / mode / user change via
  // [_resetRealReviewsState]. Zero HTTP in Demo Mode.
  int? reviewsPlaceId;
  List<ReviewSummaryRecord> placeReviews = [];
  bool placeReviewsLoading = false;
  bool placeReviewsLoaded = false;
  ReviewActionOutcome? placeReviewsError;
  List<ReviewSummaryRecord> realMyReviews = [];
  bool myReviewsLoading = false;
  bool myReviewsLoaded = false;
  bool myReviewsRefreshing = false;
  ReviewActionOutcome? myReviewsError;
  bool reviewSubmitting = false;
  ReviewActionOutcome? reviewSubmitError;
  ReviewDetailRecord? lastSubmittedReview;

  // ── Real Mode Notifications (/api/me/notifications, UI-30) ─────────────────
  // Parallel to the demo-only [userNotifications] — never merged. Read the real
  // notification list, mark one/all read, delete. A 401 never calls logout().
  // Cleared on logout / mode / user change via [_resetRealNotificationsState].
  // Zero HTTP in Demo Mode. Unread count is derived from the loaded list plus an
  // authoritative server count (unread-count endpoint) shown in the header.
  List<RealNotificationRecord> realNotifications = [];
  bool realNotificationsLoading = false;
  bool realNotificationsLoaded = false;
  bool realNotificationsRefreshing = false;
  RealNotificationOutcome? realNotificationsError;
  int? realNotificationsServerUnread;
  final Set<int> notificationActionInFlight = {};

  int get realNotificationsUnreadCount =>
      realNotifications.where((n) => !n.read).length;

  // ── Real Mode Recently Viewed (/api/me/recently-viewed, UI-31) ────────────
  // The customer's real recently-viewed places (server-sorted viewedAt DESC,
  // capped 50). A 401 never calls logout(). Cleared on logout / mode / user
  // change via [_resetRealRecentlyViewedState]. Zero HTTP in Demo Mode.
  List<RecentlyViewedRecord> realRecentlyViewed = [];
  bool realRecentlyViewedLoading = false;
  bool realRecentlyViewedLoaded = false;
  bool realRecentlyViewedRefreshing = false;
  RecentlyViewedOutcome? realRecentlyViewedError;
  final Set<int> recentlyViewedActionInFlight = {};

  // ── Real Mode Customer Profile (/api/me, /api/me/profile, UI-32) ──────────
  // Read-only signed-in identity plus the editable travel profile. A 401 never
  // calls logout(). Both are cleared on logout / mode / user change via
  // [_resetRealProfileState]. Zero HTTP in Demo Mode.
  AccountIdentityRecord? realIdentity;
  bool realIdentityLoading = false;
  bool realIdentityLoaded = false;
  CustomerProfileOutcome? realIdentityError;
  CustomerProfileRecord? realProfile;
  bool realProfileLoading = false;
  bool realProfileLoaded = false;
  bool realProfileRefreshing = false;
  bool realProfileSaving = false;
  CustomerProfileOutcome? realProfileError;

  // ── Real Mode Gift Cards (/api/me/gift-cards, UI-33) ──────────────────────
  // The customer's prepaid promotional gift cards (paged list), per-card detail
  // + ledger, plus claim/activate actions. A 401 never calls logout(). Cleared on
  // logout / mode / user change via [_resetRealGiftCardsState]. Zero HTTP in Demo
  // Mode.
  List<RealGiftCardSummary> realGiftCards = [];
  bool realGiftCardsLoading = false;
  bool realGiftCardsLoaded = false;
  bool realGiftCardsRefreshing = false;
  bool realGiftCardsLoadingMore = false;
  int realGiftCardsPage = 0;
  int realGiftCardsTotalPages = 0;
  GiftCardActionOutcome? realGiftCardsError;
  final Map<int, RealGiftCardDetail> giftCardDetailCache = {};
  int? giftCardDetailLoadingId;
  GiftCardActionOutcome? giftCardDetailError;
  final Map<int, List<RealGiftCardTransaction>> giftCardTransactionsCache = {};
  int? giftCardTransactionsLoadingId;
  final Set<int> giftCardActionInFlight = {};

  bool get realGiftCardsHasMore =>
      realGiftCardsPage + 1 < realGiftCardsTotalPages;

  // ── Real Mode Loyalty (/api/me/loyalty, UI-34) ────────────────────────────
  // Read-only: the customer's loyalty account (balance + lifetime earned) and an
  // immutable transaction ledger (paged). A 401 never calls logout(). Cleared on
  // logout / mode / user change via [_resetRealLoyaltyState]. Zero HTTP in Demo
  // Mode.
  RealLoyaltyAccount? realLoyaltyAccount;
  bool realLoyaltyLoading = false;
  bool realLoyaltyLoaded = false;
  bool realLoyaltyRefreshing = false;
  LoyaltyOutcome? realLoyaltyError;
  List<RealLoyaltyTransaction> realLoyaltyTransactions = [];
  int realLoyaltyTxPage = 0;
  int realLoyaltyTxTotalPages = 0;
  bool realLoyaltyTxLoadingMore = false;

  bool get realLoyaltyTxHasMore =>
      realLoyaltyTxPage + 1 < realLoyaltyTxTotalPages;

  // ── Real Mode Travel Credit (/api/me/travel-credits, UI-35) ───────────────
  // Read-only: the customer's promotional credit account (balance + currency) and
  // an immutable transaction ledger (paged). A 401 never calls logout(). Cleared
  // on logout / mode / user change via [_resetRealTravelCreditState]. Zero HTTP in
  // Demo Mode.
  RealTravelCreditAccount? realTravelCreditAccount;
  bool realTravelCreditLoading = false;
  bool realTravelCreditLoaded = false;
  bool realTravelCreditRefreshing = false;
  TravelCreditOutcome? realTravelCreditError;
  List<RealTravelCreditTransaction> realTravelCreditTransactions = [];
  int realTravelCreditTxPage = 0;
  int realTravelCreditTxTotalPages = 0;
  bool realTravelCreditTxLoadingMore = false;

  bool get realTravelCreditTxHasMore =>
      realTravelCreditTxPage + 1 < realTravelCreditTxTotalPages;

  // ── Real Mode Membership (/api/me/membership, UI-36) ──────────────────────
  // The customer's membership: live progress (works pre-enrollment), the
  // membership row (null = never enrolled, a valid state), benefit metadata, tier
  // history, plus an idempotent enroll action. A 401 never calls logout(). Cleared
  // on logout / mode / user change via [_resetRealMembershipState]. Zero HTTP in
  // Demo Mode.
  RealMembership? realMembership;
  bool realMembershipEnrolled = false;
  RealMembershipProgress? realMembershipProgress;
  List<RealMembershipBenefit> realMembershipBenefits = [];
  List<RealMembershipHistoryItem> realMembershipHistory = [];
  bool realMembershipLoading = false;
  bool realMembershipLoaded = false;
  bool realMembershipRefreshing = false;
  bool realMembershipEnrolling = false;
  MembershipOutcome? realMembershipError;

  // ── Real Mode Referral (/api/me/referral, UI-37) ──────────────────────────
  // The customer's referral code + stats, activity history (as inviter and/or
  // invitee), plus a use-a-code action. A 401 never calls logout(). Cleared on
  // logout / mode / user change via [_resetRealReferralState]. Zero HTTP in Demo
  // Mode.
  RealReferralSummary? realReferralSummary;
  List<RealReferralReward> realReferralHistory = [];
  bool realReferralLoading = false;
  bool realReferralLoaded = false;
  bool realReferralRefreshing = false;
  bool realReferralUsing = false;
  ReferralOutcome? realReferralError;

  // ── Real Mode Coupons (/api/me/coupons, UI-38) ────────────────────────────
  // The customer's claimed coupons (list + per-id detail) plus a claim-by-code
  // action. No checkout/apply integration (preview/eligibility deferred). A 401
  // never calls logout(). Cleared on logout / mode / user change via
  // [_resetRealCouponsState]. Zero HTTP in Demo Mode.
  List<RealCoupon> realCoupons = [];
  bool realCouponsLoading = false;
  bool realCouponsLoaded = false;
  bool realCouponsRefreshing = false;
  bool realCouponsClaiming = false;
  CouponOutcome? realCouponsError;
  final Map<int, RealCoupon> couponDetailCache = {};
  int? couponDetailLoadingId;
  CouponOutcome? couponDetailError;

  // ── Real Mode Recommendations (/api/me/recommendations, UI-39) ────────────
  // The customer's personalized recommendation feed (Phase 7.23): a paginated
  // list, a regenerate action, and per-item dismiss/click engagement. The
  // backend never claims/reserves anything. A 401 never calls logout(). Cleared
  // on logout / mode / user change via [_resetRealRecommendationsState]. Zero
  // HTTP in Demo Mode.
  List<RealRecommendation> realRecommendations = [];
  bool realRecommendationsLoading = false;
  bool realRecommendationsLoaded = false;
  bool realRecommendationsRefreshing = false;
  bool realRecommendationsLoadingMore = false;
  bool realRecommendationsGenerating = false;
  int realRecommendationsPage = 0;
  int realRecommendationsTotalPages = 0;
  RecommendationOutcome? realRecommendationsError;
  final Map<int, RealRecommendation> recommendationDetailCache = {};
  int? recommendationDetailLoadingId;
  RecommendationOutcome? recommendationDetailError;
  final Set<int> recommendationActionInFlight = {};

  bool get realRecommendationsHasMore =>
      realRecommendationsPage + 1 < realRecommendationsTotalPages;

  // ── Real Mode Trip Expenses (/api/me/trips/.../expenses, UI-40) ───────────
  // Expenses for a real TripPlan (UI-20). One trip's expenses are loaded at a
  // time ([realExpensesTripId]); switching trips reloads. Full CRUD is
  // owner-or-EDITOR; a 401 never calls logout(). Cleared on logout / mode / user
  // change via [_resetRealExpensesState]. Zero HTTP in Demo Mode.
  int? realExpensesTripId;
  List<RealExpense> realExpenses = [];
  RealExpenseSummary? realExpenseSummary;
  bool realExpensesLoading = false;
  bool realExpensesLoaded = false;
  bool realExpensesRefreshing = false;
  bool realExpenseMutationInFlight = false;
  ExpenseOutcome? realExpensesError;

  /// The loaded expenses for [tripId], or an empty list if a different trip
  /// (or none) is currently loaded.
  List<RealExpense> realExpensesFor(int tripId) =>
      realExpensesTripId == tripId ? realExpenses : const [];

  /// The loaded budget summary for [tripId], or null if a different trip (or
  /// none) is currently loaded.
  RealExpenseSummary? realExpenseSummaryFor(int tripId) =>
      realExpensesTripId == tripId ? realExpenseSummary : null;

  // ── Real Mode Conversations (/api/me/conversations, UI-41) ────────────────
  // Guest↔partner messaging about a booking. The inbox ([realConversations]) and
  // one active thread ([realConversationDetail]) are loaded independently. No
  // websocket/realtime — the client refreshes on demand. A 401 never calls
  // logout(). Cleared on logout / mode / user change via
  // [_resetRealConversationsState]. Zero HTTP in Demo Mode.
  List<RealConversationSummary> realConversations = [];
  bool realConversationsLoading = false;
  bool realConversationsLoaded = false;
  bool realConversationsRefreshing = false;
  ConversationOutcome? realConversationsError;
  int? realConversationDetailId;
  RealConversation? realConversationDetail;
  bool realConversationDetailLoading = false;
  ConversationOutcome? realConversationDetailError;
  bool realConversationSending = false;
  bool realConversationMutating = false;

  /// The loaded thread for [conversationId], or null if a different thread (or
  /// none) is currently loaded.
  RealConversation? realConversationDetailFor(int conversationId) =>
      realConversationDetailId == conversationId
          ? realConversationDetail
          : null;

  /// Total unread across the loaded inbox (sums the backend-provided per-thread
  /// counts; display only).
  int get realConversationsUnreadTotal =>
      realConversations.fold(0, (sum, c) => sum + c.unreadCount);

  // ── Real Mode AI Context (/api/me/ai/context, UI-42) ──────────────────────
  // A single read-only aggregate snapshot (no persistence, no AI generation).
  // A 401 never calls logout(). Cleared on logout / mode / user change via
  // [_resetRealAiContextState]. Zero HTTP in Demo Mode.
  RealAiContext? realAiContext;
  bool realAiContextLoading = false;
  bool realAiContextLoaded = false;
  bool realAiContextRefreshing = false;
  AiContextOutcome? realAiContextError;

  // ── Real Mode Trip Documents (/api/me/trips/.../documents, UI-43) ─────────
  // Travel documents for a real TripPlan (UI-20). One trip's documents are
  // loaded at a time ([realDocumentsTripId]); switching trips reloads. Full CRUD
  // + pin/unpin is owner-or-EDITOR; a 401 never calls logout(). Cleared on logout
  // / mode / user change via [_resetRealDocumentsState]. Zero HTTP in Demo Mode.
  int? realDocumentsTripId;
  List<RealTripDocument> realDocuments = [];
  bool realDocumentsLoading = false;
  bool realDocumentsLoaded = false;
  bool realDocumentsRefreshing = false;
  bool realDocumentMutationInFlight = false;
  DocumentOutcome? realDocumentsError;

  /// The loaded documents for [tripId], or an empty list if a different trip (or
  /// none) is currently loaded.
  List<RealTripDocument> realDocumentsFor(int tripId) =>
      realDocumentsTripId == tripId ? realDocuments : const [];

  // ── Real Mode Trip Notes (/api/me/trips/.../notes, UI-44) ─────────────────
  // Freeform notes & journal entries for a real TripPlan (UI-20). One trip's
  // notes are loaded at a time ([realNotesTripId]); switching trips reloads. Full
  // CRUD + pin/unpin is owner-or-EDITOR; a 401 never calls logout(). Cleared on
  // logout / mode / user change via [_resetRealNotesState]. Zero HTTP in Demo
  // Mode.
  int? realNotesTripId;
  List<RealTripNote> realNotes = [];
  bool realNotesLoading = false;
  bool realNotesLoaded = false;
  bool realNotesRefreshing = false;
  bool realNoteMutationInFlight = false;
  NoteOutcome? realNotesError;

  /// The loaded notes for [tripId], or an empty list if a different trip (or
  /// none) is currently loaded.
  List<RealTripNote> realNotesFor(int tripId) =>
      realNotesTripId == tripId ? realNotes : const [];

  // ── Real Mode Trip Packing (/api/me/trips/.../packing, UI-45) ─────────────
  // Per-trip packing checklist for a real TripPlan (UI-20). One trip's items are
  // loaded at a time ([realPackingTripId]); switching trips reloads. Full CRUD +
  // check/uncheck is owner-or-EDITOR; a 401 never calls logout(). Cleared on
  // logout / mode / user change via [_resetRealPackingState]. Zero HTTP in Demo
  // Mode.
  int? realPackingTripId;
  List<RealPackingItem> realPackingItems = [];
  bool realPackingLoading = false;
  bool realPackingLoaded = false;
  bool realPackingRefreshing = false;
  bool realPackingMutationInFlight = false;
  PackingOutcome? realPackingError;

  /// The loaded packing items for [tripId], or an empty list if a different trip
  /// (or none) is currently loaded.
  List<RealPackingItem> realPackingItemsFor(int tripId) =>
      realPackingTripId == tripId ? realPackingItems : const [];

  // ── Real Mode Trip Reminders (/api/me/trips/.../reminders, UI-46) ─────────
  // Per-trip in-app reminder records for a real TripPlan (UI-20). One trip's
  // reminders are loaded at a time ([realRemindersTripId]); switching trips (or
  // toggling [realRemindersIncludeCancelled]) reloads. Create/update/complete/
  // cancel/delete is owner-or-EDITOR; a 401 never calls logout(). There is no
  // delivery/scheduler — storage + CRUD only. Cleared on logout / mode / user
  // change via [_resetRealReminderState]. Zero HTTP in Demo Mode.
  int? realRemindersTripId;
  List<RealReminder> realReminders = [];
  bool realRemindersIncludeCancelled = false;
  bool realRemindersLoading = false;
  bool realRemindersLoaded = false;
  bool realRemindersRefreshing = false;
  bool realRemindersMutationInFlight = false;
  ReminderOutcome? realRemindersError;

  /// The loaded reminders for [tripId], or an empty list if a different trip
  /// (or none) is currently loaded.
  List<RealReminder> realRemindersFor(int tripId) =>
      realRemindersTripId == tripId ? realReminders : const [];

  // ── Real Mode Trip Budget (/api/me/trips/.../budget, UI-47) ───────────────
  // The single per-trip budget entity for a real TripPlan (UI-20). One trip is
  // loaded at a time ([realBudgetTripId]); switching trips reloads. Setting the
  // budget (PUT) and deleting it is owner-only (403 for a collaborator); a 401
  // never calls logout(). [realBudget] is null when the trip has no budget yet
  // (backend 404). Spent/remaining/over-budget come from [realBudgetSummary]
  // ([RealExpenseSummary], reused from UI-40's budget-summary — nothing is
  // computed client-side). Cleared on logout / mode / user change via
  // [_resetRealBudgetState]. Zero HTTP in Demo Mode.
  int? realBudgetTripId;
  RealBudget? realBudget;
  RealExpenseSummary? realBudgetSummary;
  bool realBudgetLoading = false;
  bool realBudgetLoaded = false;
  bool realBudgetRefreshing = false;
  bool realBudgetMutationInFlight = false;
  BudgetOutcome? realBudgetError;

  /// The loaded budget for [tripId], or null if a different trip (or none) is
  /// loaded, or the trip has no budget set.
  RealBudget? realBudgetFor(int tripId) =>
      realBudgetTripId == tripId ? realBudget : null;

  /// The loaded budget summary for [tripId] (spent/remaining/over-budget), or
  /// null if a different trip (or none) is loaded.
  RealExpenseSummary? realBudgetSummaryFor(int tripId) =>
      realBudgetTripId == tripId ? realBudgetSummary : null;

  // ── Real Mode Trip Collaboration (/api/me/trips/.../collaborators, UI-48) ──
  // Owner-only collaborator management + public/private toggle for a real
  // TripPlan (UI-20). One trip is loaded at a time ([realCollabTripId]);
  // switching trips reloads. Invite / role change / remove / publish is
  // owner-only — a collaborator gets 403 and a stranger 404; a 401 never calls
  // logout(). [realCollabIsPublic] is seeded from the trip detail and updated
  // from the publish toggle's response. Cleared on logout / mode / user change
  // via [_resetRealCollaborationState]. Zero HTTP in Demo Mode.
  int? realCollabTripId;
  List<RealCollaborator> realCollaborators = [];
  bool? realCollabIsPublic;
  bool realCollabLoading = false;
  bool realCollabLoaded = false;
  bool realCollabRefreshing = false;
  bool realCollabMutationInFlight = false;
  CollaborationOutcome? realCollabError;

  /// The loaded collaborators for [tripId], or an empty list if a different
  /// trip (or none) is currently loaded.
  List<RealCollaborator> realCollaboratorsFor(int tripId) =>
      realCollabTripId == tripId ? realCollaborators : const [];

  /// The known public/private state for [tripId], or null if unknown.
  bool? realCollabIsPublicFor(int tripId) =>
      realCollabTripId == tripId ? realCollabIsPublic : null;

  // ── Real Mode Shared Trips (/api/me/trips/shared, UI-49) ──────────────────
  // The invitee-side "shared with me" list — trips the authenticated user
  // collaborates on (active only, createdAt DESC). Global (not trip-scoped),
  // read-only; tapping a row opens the existing RealTripDetailScreen (getById is
  // collaborator-viewable). A 401 never calls logout(). Cleared on logout /
  // mode / user change via [_resetRealSharedTripsState]. Zero HTTP in Demo Mode.
  List<RealSharedTrip> realSharedTrips = [];
  bool realSharedTripsLoading = false;
  bool realSharedTripsLoaded = false;
  bool realSharedTripsRefreshing = false;
  SharedTripsOutcome? realSharedTripsError;

  // ── Real Mode Travel Wallet (/api/me/travel-wallet, UI-50) ────────────────
  // The customer's per-user organizer of documents/vouchers/tickets. Global
  // (not trip-scoped); owner-only CRUD + favorite/archive toggles. A 401 never
  // calls logout(). Cleared on logout / mode / user change via
  // [_resetRealWalletState]. Zero HTTP in Demo Mode.
  List<RealWalletItem> realWalletItems = [];
  bool realWalletLoading = false;
  bool realWalletLoaded = false;
  bool realWalletRefreshing = false;
  bool realWalletMutationInFlight = false;
  WalletOutcome? realWalletError;

  // ── Real Mode Interest Profile (/api/me/interests, UI-52) ─────────────────
  // The customer's derived, read-only travel-interest profile. Global (not
  // trip-scoped); a single [recalculateRealInterestProfile] safely re-derives it
  // from the user's own activity. A 401 never calls logout(). Cleared on logout /
  // mode / user change via [_resetRealInterestState]. Zero HTTP in Demo Mode.
  RealInterestProfile? realInterestProfile;
  bool realInterestLoading = false;
  bool realInterestLoaded = false;
  bool realInterestRefreshing = false;
  bool realInterestRecalculating = false;
  InterestProfileOutcome? realInterestError;

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
    _resetRealSearchState();
    _resetRealAvailabilityState();
    _resetRealBookingHistoryState();
    _resetRealPaymentState();
    _resetRealReviewsState();
    _resetRealNotificationsState();
    _resetRealRecentlyViewedState();
    _resetRealProfileState();
    _resetRealGiftCardsState();
    _resetRealLoyaltyState();
    _resetRealTravelCreditState();
    _resetRealMembershipState();
    _resetRealReferralState();
    _resetRealCouponsState();
    _resetRealRecommendationsState();
    _resetRealExpensesState();
    _resetRealConversationsState();
    _resetRealAiContextState();
    _resetRealDocumentsState();
    _resetRealNotesState();
    _resetRealPackingState();
    _resetRealReminderState();
    _resetRealBudgetState();
    _resetRealCollaborationState();
    _resetRealSharedTripsState();
    _resetRealWalletState();
    _resetRealInterestState();
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
    _hydratedRealPlaceDetails.clear();
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

  void _resetRealBookingHistoryState() {
    realBookings = [];
    realBookingsLoading = false;
    realBookingsLoaded = false;
    realBookingsRefreshing = false;
    realBookingsError = null;
    bookingDetailCache.clear();
    bookingDetailLoadingId = null;
    bookingDetailError = null;
  }

  void _resetRealPaymentState() {
    realPaymentBookingId = null;
    realPayment = null;
    realPaymentLoading = false;
    realPaymentSubmitting = false;
    realPaymentError = null;
  }

  void _resetRealRecentlyViewedState() {
    realRecentlyViewed = [];
    realRecentlyViewedLoading = false;
    realRecentlyViewedLoaded = false;
    realRecentlyViewedRefreshing = false;
    realRecentlyViewedError = null;
    recentlyViewedActionInFlight.clear();
  }

  void _resetRealProfileState() {
    realIdentity = null;
    realIdentityLoading = false;
    realIdentityLoaded = false;
    realIdentityError = null;
    realProfile = null;
    realProfileLoading = false;
    realProfileLoaded = false;
    realProfileRefreshing = false;
    realProfileSaving = false;
    realProfileError = null;
  }

  void _resetRealGiftCardsState() {
    realGiftCards = [];
    realGiftCardsLoading = false;
    realGiftCardsLoaded = false;
    realGiftCardsRefreshing = false;
    realGiftCardsLoadingMore = false;
    realGiftCardsPage = 0;
    realGiftCardsTotalPages = 0;
    realGiftCardsError = null;
    giftCardDetailCache.clear();
    giftCardDetailLoadingId = null;
    giftCardDetailError = null;
    giftCardTransactionsCache.clear();
    giftCardTransactionsLoadingId = null;
    giftCardActionInFlight.clear();
  }

  void _resetRealLoyaltyState() {
    realLoyaltyAccount = null;
    realLoyaltyLoading = false;
    realLoyaltyLoaded = false;
    realLoyaltyRefreshing = false;
    realLoyaltyError = null;
    realLoyaltyTransactions = [];
    realLoyaltyTxPage = 0;
    realLoyaltyTxTotalPages = 0;
    realLoyaltyTxLoadingMore = false;
  }

  void _resetRealTravelCreditState() {
    realTravelCreditAccount = null;
    realTravelCreditLoading = false;
    realTravelCreditLoaded = false;
    realTravelCreditRefreshing = false;
    realTravelCreditError = null;
    realTravelCreditTransactions = [];
    realTravelCreditTxPage = 0;
    realTravelCreditTxTotalPages = 0;
    realTravelCreditTxLoadingMore = false;
  }

  void _resetRealMembershipState() {
    realMembership = null;
    realMembershipEnrolled = false;
    realMembershipProgress = null;
    realMembershipBenefits = [];
    realMembershipHistory = [];
    realMembershipLoading = false;
    realMembershipLoaded = false;
    realMembershipRefreshing = false;
    realMembershipEnrolling = false;
    realMembershipError = null;
  }

  void _resetRealReferralState() {
    realReferralSummary = null;
    realReferralHistory = [];
    realReferralLoading = false;
    realReferralLoaded = false;
    realReferralRefreshing = false;
    realReferralUsing = false;
    realReferralError = null;
  }

  void _resetRealCouponsState() {
    realCoupons = [];
    realCouponsLoading = false;
    realCouponsLoaded = false;
    realCouponsRefreshing = false;
    realCouponsClaiming = false;
    realCouponsError = null;
    couponDetailCache.clear();
    couponDetailLoadingId = null;
    couponDetailError = null;
  }

  void _resetRealRecommendationsState() {
    realRecommendations = [];
    realRecommendationsLoading = false;
    realRecommendationsLoaded = false;
    realRecommendationsRefreshing = false;
    realRecommendationsLoadingMore = false;
    realRecommendationsGenerating = false;
    realRecommendationsPage = 0;
    realRecommendationsTotalPages = 0;
    realRecommendationsError = null;
    recommendationDetailCache.clear();
    recommendationDetailLoadingId = null;
    recommendationDetailError = null;
    recommendationActionInFlight.clear();
  }

  void _resetRealExpensesState() {
    realExpensesTripId = null;
    realExpenses = [];
    realExpenseSummary = null;
    realExpensesLoading = false;
    realExpensesLoaded = false;
    realExpensesRefreshing = false;
    realExpenseMutationInFlight = false;
    realExpensesError = null;
  }

  void _resetRealConversationsState() {
    realConversations = [];
    realConversationsLoading = false;
    realConversationsLoaded = false;
    realConversationsRefreshing = false;
    realConversationsError = null;
    realConversationDetailId = null;
    realConversationDetail = null;
    realConversationDetailLoading = false;
    realConversationDetailError = null;
    realConversationSending = false;
    realConversationMutating = false;
  }

  void _resetRealAiContextState() {
    realAiContext = null;
    realAiContextLoading = false;
    realAiContextLoaded = false;
    realAiContextRefreshing = false;
    realAiContextError = null;
  }

  void _resetRealDocumentsState() {
    realDocumentsTripId = null;
    realDocuments = [];
    realDocumentsLoading = false;
    realDocumentsLoaded = false;
    realDocumentsRefreshing = false;
    realDocumentMutationInFlight = false;
    realDocumentsError = null;
  }

  void _resetRealNotesState() {
    realNotesTripId = null;
    realNotes = [];
    realNotesLoading = false;
    realNotesLoaded = false;
    realNotesRefreshing = false;
    realNoteMutationInFlight = false;
    realNotesError = null;
  }

  void _resetRealPackingState() {
    realPackingTripId = null;
    realPackingItems = [];
    realPackingLoading = false;
    realPackingLoaded = false;
    realPackingRefreshing = false;
    realPackingMutationInFlight = false;
    realPackingError = null;
  }

  void _resetRealReminderState() {
    realRemindersTripId = null;
    realReminders = [];
    realRemindersIncludeCancelled = false;
    realRemindersLoading = false;
    realRemindersLoaded = false;
    realRemindersRefreshing = false;
    realRemindersMutationInFlight = false;
    realRemindersError = null;
  }

  void _resetRealBudgetState() {
    realBudgetTripId = null;
    realBudget = null;
    realBudgetSummary = null;
    realBudgetLoading = false;
    realBudgetLoaded = false;
    realBudgetRefreshing = false;
    realBudgetMutationInFlight = false;
    realBudgetError = null;
  }

  void _resetRealCollaborationState() {
    realCollabTripId = null;
    realCollaborators = [];
    realCollabIsPublic = null;
    realCollabLoading = false;
    realCollabLoaded = false;
    realCollabRefreshing = false;
    realCollabMutationInFlight = false;
    realCollabError = null;
  }

  void _resetRealSharedTripsState() {
    realSharedTrips = [];
    realSharedTripsLoading = false;
    realSharedTripsLoaded = false;
    realSharedTripsRefreshing = false;
    realSharedTripsError = null;
  }

  void _resetRealWalletState() {
    realWalletItems = [];
    realWalletLoading = false;
    realWalletLoaded = false;
    realWalletRefreshing = false;
    realWalletMutationInFlight = false;
    realWalletError = null;
  }

  void _resetRealInterestState() {
    realInterestProfile = null;
    realInterestLoading = false;
    realInterestLoaded = false;
    realInterestRefreshing = false;
    realInterestRecalculating = false;
    realInterestError = null;
  }

  void _resetRealNotificationsState() {
    realNotifications = [];
    realNotificationsLoading = false;
    realNotificationsLoaded = false;
    realNotificationsRefreshing = false;
    realNotificationsError = null;
    realNotificationsServerUnread = null;
    notificationActionInFlight.clear();
  }

  void _resetRealReviewsState() {
    reviewsPlaceId = null;
    placeReviews = [];
    placeReviewsLoading = false;
    placeReviewsLoaded = false;
    placeReviewsError = null;
    realMyReviews = [];
    myReviewsLoading = false;
    myReviewsLoaded = false;
    myReviewsRefreshing = false;
    myReviewsError = null;
    reviewSubmitting = false;
    reviewSubmitError = null;
    lastSubmittedReview = null;
  }

  void _resetRealSearchState() {
    realSearchResults = [];
    realSearchLoading = false;
    realSearchLoadingMore = false;
    realSearchRefreshing = false;
    realSearchLoaded = false;
    realSearchError = null;
    realSearchQuery = '';
    realSearchMinRating = null;
    realSearchMaxPriceLevel = null;
    realSearchSort = PlaceSearchSort.newest;
    realSearchPage = 0;
    realSearchTotalPages = 0;
    realSearchTotalElements = 0;
    // Bump the request id so any in-flight response is discarded on reset.
    _realSearchRequestId++;
  }

  void _resetRealAvailabilityState() {
    realAvailability = null;
    realAvailabilityLoading = false;
    realAvailabilityRefreshing = false;
    realAvailabilityError = null;
    realAvailabilityPlaceId = null;
    // Bump the request id so any in-flight response is discarded on reset.
    _realAvailabilityRequestId++;
    _resetRoomSelectionState();
  }

  void _resetRoomSelectionState() {
    selectedRoomId = null;
    selectedRatePlanId = null;
    roomRatePlans = const [];
    roomRatePlansLoading = false;
    roomRatePlansError = null;
    roomRatePlansRoomId = null;
    _roomRatePlanRequestId++;
    // The booking-flow draft is downstream of room selection, so it resets on
    // the same logout / mode-change boundaries (never on an in-session
    // criteria change, which only revalidates the selection).
    _resetBookingFlowState();
  }

  void _resetBookingFlowState() {
    bookingGuestName = '';
    bookingContactEmail = '';
    bookingContactPhone = '';
    bookingGuestCountry = '';
    bookingArrivalTime = '';
    bookingSpecialRequestPresets = <SpecialRequestPreset>{};
    bookingSpecialRequestNote = '';
    bookingTermsAccepted = false;
    bookingQuote = null;
    bookingQuoteLoading = false;
    bookingQuoteError = null;
    bookingQuoteRoomId = null;
    bookingDraft = null;
    // UI26 — clear real submission state so a created booking never leaks across
    // logout / mode / user change (session isolation).
    realBookingSubmitting = false;
    lastCreatedBooking = null;
    realBookingSubmissionError = null;
    // Bump the request id so any in-flight quote response is discarded.
    _bookingQuoteRequestId++;
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
      _resetRealSearchState();
      _resetRealAvailabilityState();
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
    _resetRealSearchState();
    _resetRealAvailabilityState();
    _resetRealBookingHistoryState();
    _resetRealPaymentState();
    _resetRealReviewsState();
    _resetRealNotificationsState();
    _resetRealRecentlyViewedState();
    _resetRealProfileState();
    _resetRealGiftCardsState();
    _resetRealLoyaltyState();
    _resetRealTravelCreditState();
    _resetRealMembershipState();
    _resetRealReferralState();
    _resetRealCouponsState();
    _resetRealRecommendationsState();
    _resetRealExpensesState();
    _resetRealConversationsState();
    _resetRealAiContextState();
    _resetRealDocumentsState();
    _resetRealNotesState();
    _resetRealPackingState();
    _resetRealReminderState();
    _resetRealBudgetState();
    _resetRealCollaborationState();
    _resetRealSharedTripsState();
    _resetRealWalletState();
    _resetRealInterestState();
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
      case ApiErrorKind.uncertain:
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
      case ApiErrorKind.uncertain:
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

  /// The full typed [PlaceDetailRecord] for [placeId] if it has been hydrated
  /// this session, else `null` (UI23). Carries the gallery, grouped opening
  /// hours, metadata, and rich hotelDetail the lossy [Place] projection drops.
  PlaceDetailRecord? getHydratedRealPlaceDetail(int placeId) =>
      _hydratedRealPlaceDetails[placeId];

  /// Whether a hydration request for [placeId] is currently in flight.
  bool isRealPlaceHydrationInFlight(int placeId) =>
      _hydrationInFlight.containsKey(placeId);

  /// Hydrates the full [Place] for [placeId] from the public place-detail
  /// endpoint, caching a successful result for the session. Demo Mode never
  /// hits the network. Concurrent callers for the same place share one request;
  /// a failed hydration is never cached, so a retry can succeed. On success the
  /// [Place] is available via [getHydratedRealPlace] and the full typed record
  /// via [getHydratedRealPlaceDetail]. Pass [refresh] `true` (pull-to-refresh)
  /// to bypass the cache and re-fetch; a failed refresh keeps the prior cached
  /// record rather than clearing it to a fake-empty state.
  Future<PlaceHydrationResult> hydrateRealPlace(
    int placeId, {
    bool refresh = false,
  }) {
    if (demoMode) return Future.value(PlaceHydrationResult.unavailable);
    if (!refresh && _hydratedRealPlaces.containsKey(placeId)) {
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
        _hydratedRealPlaceDetails[placeId] = result.data!;
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
      ApiErrorKind.uncertain => TripActionResult.serverError,
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

  // ── Real Mode Place Search (UI-21) ────────────────────────────────────────
  //
  // Parallel to the demo [filteredPlaces] path — never fabricates results. A
  // monotonic request id guarantees last-request-wins: a slower older response
  // is discarded rather than overwriting fresher results. 401/403 map without
  // logging out (the search endpoint is public, so they should never occur).

  PlaceSearchOutcome _mapSearchError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => PlaceSearchOutcome.sessionExpired,
      ApiErrorKind.forbidden => PlaceSearchOutcome.forbidden,
      ApiErrorKind.notFound => PlaceSearchOutcome.notFound,
      ApiErrorKind.validation => PlaceSearchOutcome.validation,
      ApiErrorKind.network => PlaceSearchOutcome.network,
      ApiErrorKind.timeout => PlaceSearchOutcome.timeout,
      ApiErrorKind.server => PlaceSearchOutcome.serverError,
      ApiErrorKind.malformed => PlaceSearchOutcome.malformed,
      _ => PlaceSearchOutcome.serverError,
    };
  }

  /// Runs a fresh real-mode search (page 0). Passing a filter argument updates
  /// that criterion; omitted arguments keep the current value. A newer call
  /// supersedes an older in-flight one (last wins); on failure the previous
  /// results are preserved so the UI can show an error without losing content.
  Future<PlaceSearchOutcome> runRealSearch({
    String? query,
    Object? minRating = _unset,
    Object? maxPriceLevel = _unset,
    PlaceSearchSort? sort,
    bool refresh = false,
  }) async {
    if (demoMode) return PlaceSearchOutcome.unavailable;
    if (query != null) realSearchQuery = query;
    if (!identical(minRating, _unset)) {
      realSearchMinRating = minRating as double?;
    }
    if (!identical(maxPriceLevel, _unset)) {
      realSearchMaxPriceLevel = maxPriceLevel as int?;
    }
    if (sort != null) realSearchSort = sort;

    final reqId = ++_realSearchRequestId;
    realSearchPage = 0;
    if (refresh) {
      realSearchRefreshing = true;
    } else {
      realSearchLoading = true;
    }
    realSearchError = null;
    notifyListeners();

    final result = await api.searchPlaces(
      q: realSearchQuery,
      minRating: realSearchMinRating,
      maxPriceLevel: realSearchMaxPriceLevel,
      sort: realSearchSort.token,
      page: 0,
      size: _realSearchPageSize,
    );

    // A newer search started while this was in flight — discard this response.
    if (reqId != _realSearchRequestId) return PlaceSearchOutcome.success;
    realSearchLoading = false;
    realSearchRefreshing = false;
    if (result.success && result.data != null) {
      final page = result.data!;
      realSearchResults = page.content;
      realSearchPage = page.page;
      realSearchTotalPages = page.totalPages;
      realSearchTotalElements = page.totalElements;
      realSearchLoaded = true;
      realSearchError = null;
      notifyListeners();
      return PlaceSearchOutcome.success;
    }
    final outcome = _mapSearchError(result.errorKind);
    realSearchError = outcome; // prior results preserved
    notifyListeners();
    return outcome;
  }

  /// Loads and appends the next page of the current real-mode search. Guarded
  /// against demo mode, concurrent loads, and end-of-results; a filter/query
  /// change mid-flight (new request id) discards the stale page.
  Future<PlaceSearchOutcome> loadMoreRealSearch() async {
    if (demoMode) return PlaceSearchOutcome.unavailable;
    if (realSearchLoading || realSearchLoadingMore || realSearchRefreshing) {
      return PlaceSearchOutcome.success;
    }
    if (!realSearchHasMore) return PlaceSearchOutcome.success;
    final reqId = _realSearchRequestId;
    final nextPage = realSearchPage + 1;
    realSearchLoadingMore = true;
    notifyListeners();

    final result = await api.searchPlaces(
      q: realSearchQuery,
      minRating: realSearchMinRating,
      maxPriceLevel: realSearchMaxPriceLevel,
      sort: realSearchSort.token,
      page: nextPage,
      size: _realSearchPageSize,
    );

    // The query/filters changed while paging — drop this stale page.
    if (reqId != _realSearchRequestId) {
      realSearchLoadingMore = false;
      return PlaceSearchOutcome.success;
    }
    realSearchLoadingMore = false;
    if (result.success && result.data != null) {
      final page = result.data!;
      realSearchResults = [...realSearchResults, ...page.content];
      realSearchPage = page.page;
      realSearchTotalPages = page.totalPages;
      realSearchTotalElements = page.totalElements;
      notifyListeners();
      return PlaceSearchOutcome.success;
    }
    final outcome = _mapSearchError(result.errorKind);
    realSearchError = outcome;
    notifyListeners();
    return outcome;
  }

  HotelAvailabilityOutcome _mapAvailabilityError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => HotelAvailabilityOutcome.sessionExpired,
      ApiErrorKind.forbidden => HotelAvailabilityOutcome.forbidden,
      ApiErrorKind.notFound => HotelAvailabilityOutcome.notFound,
      ApiErrorKind.validation => HotelAvailabilityOutcome.validation,
      ApiErrorKind.network => HotelAvailabilityOutcome.network,
      ApiErrorKind.timeout => HotelAvailabilityOutcome.timeout,
      ApiErrorKind.server => HotelAvailabilityOutcome.serverError,
      ApiErrorKind.malformed => HotelAvailabilityOutcome.malformed,
      _ => HotelAvailabilityOutcome.serverError,
    };
  }

  /// Loads real bookable rooms for a hotel [placeId] over a date range in Real
  /// Mode only. Guards invalid dates client-side (mirroring the backend 400),
  /// never fabricates rooms/prices, and lets a newer lookup supersede an older
  /// in-flight one (last wins). On failure the previous result is cleared only
  /// when it belonged to a different hotel, so a transient error on the same
  /// hotel keeps the last-known rooms visible behind the error banner.
  Future<HotelAvailabilityOutcome> loadRealAvailability({
    required int placeId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 1,
    int children = 0,
    bool refresh = false,
  }) async {
    if (demoMode) return HotelAvailabilityOutcome.unavailable;
    final inDay = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final outDay = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (!outDay.isAfter(inDay)) {
      realAvailabilityError = HotelAvailabilityOutcome.invalidDates;
      realAvailabilityLoading = false;
      realAvailabilityRefreshing = false;
      notifyListeners();
      return HotelAvailabilityOutcome.invalidDates;
    }

    final reqId = ++_realAvailabilityRequestId;
    if (realAvailabilityPlaceId != placeId) {
      // Switching hotels — don't show a stale hotel's rooms while loading.
      realAvailability = null;
    }
    realAvailabilityPlaceId = placeId;
    if (refresh) {
      realAvailabilityRefreshing = true;
    } else {
      realAvailabilityLoading = true;
    }
    realAvailabilityError = null;
    notifyListeners();

    final result = await api.getHotelAvailability(
      placeId: placeId,
      checkIn: inDay,
      checkOut: outDay,
      adults: adults,
      children: children,
    );

    // A newer lookup started while this was in flight — discard this response.
    if (reqId != _realAvailabilityRequestId) {
      return HotelAvailabilityOutcome.success;
    }
    realAvailabilityLoading = false;
    realAvailabilityRefreshing = false;
    if (result.success && result.data != null) {
      realAvailability = result.data!;
      realAvailabilityError = null;
      // A date/guest change re-runs availability; drop a selection whose room is
      // no longer offered so the UI never shows a stale/invalid selection.
      _revalidateRoomSelection();
      notifyListeners();
      return HotelAvailabilityOutcome.success;
    }
    final outcome = _mapAvailabilityError(result.errorKind);
    realAvailabilityError = outcome;
    notifyListeners();
    return outcome;
  }

  // ── UI24 Real room selection ──────────────────────────────────────────────

  /// The currently selected room within the loaded availability, or `null` if
  /// no room is selected or it is no longer in the result.
  AvailableRoomRecord? get selectedRoom {
    final id = selectedRoomId;
    final rooms = realAvailability?.availableRooms;
    if (id == null || rooms == null) return null;
    for (final room in rooms) {
      if (room.roomId == id) return room;
    }
    return null;
  }

  /// The currently selected rate plan within the loaded rate plans, or `null`.
  HotelRatePlan? get selectedRatePlan {
    final id = selectedRatePlanId;
    if (id == null) return null;
    for (final plan in roomRatePlans) {
      if (plan.ratePlanId == id) return plan;
    }
    return null;
  }

  /// Guests / nights for the current stay, taken from the availability result
  /// (never recomputed client-side).
  int get selectedGuestCount =>
      (realAvailability?.adults ?? 0) + (realAvailability?.children ?? 0);
  int get selectedNightCount => realAvailability?.nights ?? 0;

  /// Selects exactly one [roomId] (and optionally a [ratePlanId]) from the
  /// loaded availability. Ignored in Demo Mode or when the room is not offered.
  void selectRoom(int roomId, {int? ratePlanId}) {
    if (demoMode) return;
    final rooms = realAvailability?.availableRooms;
    if (rooms == null || !rooms.any((r) => r.roomId == roomId)) return;
    selectedRoomId = roomId;
    if (ratePlanId != null &&
        roomRatePlansRoomId == roomId &&
        roomRatePlans.any((p) => p.ratePlanId == ratePlanId)) {
      selectedRatePlanId = ratePlanId;
    } else if (ratePlanId == null) {
      // Keep an existing plan only if it still belongs to this room.
      if (roomRatePlansRoomId != roomId) selectedRatePlanId = null;
    } else {
      selectedRatePlanId = null;
    }
    notifyListeners();
  }

  /// Clears any current room + rate-plan selection.
  void clearRoomSelection() {
    if (selectedRoomId == null && selectedRatePlanId == null) return;
    selectedRoomId = null;
    selectedRatePlanId = null;
    notifyListeners();
  }

  /// Drops the selection when the selected room is no longer in the loaded
  /// availability (e.g. after a date/guest change). Also drops rate plans that
  /// no longer apply to the selected room.
  void _revalidateRoomSelection() {
    final id = selectedRoomId;
    if (id == null) return;
    final rooms =
        realAvailability?.availableRooms ?? const <AvailableRoomRecord>[];
    if (!rooms.any((r) => r.roomId == id)) {
      selectedRoomId = null;
      selectedRatePlanId = null;
      if (roomRatePlansRoomId == id) {
        roomRatePlans = const [];
        roomRatePlansRoomId = null;
        roomRatePlansError = null;
      }
    }
  }

  RatePlanOutcome _mapRatePlanError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => RatePlanOutcome.sessionExpired,
      ApiErrorKind.forbidden => RatePlanOutcome.forbidden,
      ApiErrorKind.notFound => RatePlanOutcome.notFound,
      ApiErrorKind.validation => RatePlanOutcome.validation,
      ApiErrorKind.network => RatePlanOutcome.network,
      ApiErrorKind.timeout => RatePlanOutcome.timeout,
      ApiErrorKind.server => RatePlanOutcome.serverError,
      ApiErrorKind.malformed => RatePlanOutcome.malformed,
      _ => RatePlanOutcome.serverError,
    };
  }

  /// Loads the real rate plans for [roomId] over the stay in Real Mode only.
  /// Guards invalid dates client-side (mirroring the backend 400). Reuses the
  /// cached plans for the same room unless [refresh] is set — this never
  /// re-issues the UI22 availability request. A newer load supersedes an older
  /// in-flight one (last wins).
  Future<RatePlanOutcome> loadRoomRatePlans({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int extraBeds = 0,
    bool refresh = false,
  }) async {
    if (demoMode) return RatePlanOutcome.unavailable;
    final inDay = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final outDay = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (!outDay.isAfter(inDay)) {
      roomRatePlansRoomId = roomId;
      roomRatePlansError = RatePlanOutcome.invalidDates;
      roomRatePlansLoading = false;
      notifyListeners();
      return RatePlanOutcome.invalidDates;
    }
    if (!refresh &&
        roomRatePlansRoomId == roomId &&
        roomRatePlansError == null &&
        roomRatePlans.isNotEmpty) {
      return RatePlanOutcome.success; // cached — no HTTP
    }

    final reqId = ++_roomRatePlanRequestId;
    if (roomRatePlansRoomId != roomId) {
      roomRatePlans = const [];
    }
    roomRatePlansRoomId = roomId;
    roomRatePlansLoading = true;
    roomRatePlansError = null;
    notifyListeners();

    final result = await api.getRoomRatePlans(
      roomId: roomId,
      checkIn: inDay,
      checkOut: outDay,
      adults: adults,
      children: children,
      extraBeds: extraBeds,
    );

    if (reqId != _roomRatePlanRequestId) {
      return RatePlanOutcome.success; // superseded — discard
    }
    roomRatePlansLoading = false;
    if (result.success && result.data != null) {
      roomRatePlans = result.data!;
      roomRatePlansError = null;
      notifyListeners();
      return RatePlanOutcome.success;
    }
    final outcome = _mapRatePlanError(result.errorKind);
    roomRatePlansError = outcome;
    notifyListeners();
    return outcome;
  }

  // ── UI25 Real booking flow foundation ─────────────────────────────────────

  /// Guests / nights for the booking, taken from the availability result — never
  /// recomputed client-side (aliases the UI24 selection getters for booking use).
  int get bookingGuestCount => selectedGuestCount;
  int get bookingNightCount => selectedNightCount;

  /// Autosaves a single guest-form field in-session. Whitespace is trimmed on
  /// finalization, not here, so the field editing experience is unaffected.
  void updateBookingGuestField({
    String? name,
    String? email,
    String? phone,
    String? country,
    String? arrivalTime,
  }) {
    if (name != null) bookingGuestName = name;
    if (email != null) bookingContactEmail = email;
    if (phone != null) bookingContactPhone = phone;
    if (country != null) bookingGuestCountry = country;
    if (arrivalTime != null) bookingArrivalTime = arrivalTime;
    notifyListeners();
  }

  /// Prefills the contact email from the signed-in account when the guest form
  /// is first opened and the field is still blank. Never overwrites user input.
  void prefillBookingContactEmail() {
    final current = bookingContactEmail.trim();
    if (current.isEmpty && (email?.trim().isNotEmpty ?? false)) {
      bookingContactEmail = email!.trim();
      notifyListeners();
    }
  }

  void toggleBookingSpecialRequest(SpecialRequestPreset preset) {
    final next = Set<SpecialRequestPreset>.from(bookingSpecialRequestPresets);
    if (!next.remove(preset)) next.add(preset);
    bookingSpecialRequestPresets = next;
    notifyListeners();
  }

  void setBookingSpecialRequestNote(String note) {
    bookingSpecialRequestNote = note;
    notifyListeners();
  }

  void setBookingTermsAccepted(bool accepted) {
    if (bookingTermsAccepted == accepted) return;
    bookingTermsAccepted = accepted;
    notifyListeners();
  }

  /// Clears any prepared draft (leaves the guest form intact for editing).
  void clearBookingDraft() {
    if (bookingDraft == null) return;
    bookingDraft = null;
    notifyListeners();
  }

  BookingQuoteOutcome _mapBookingQuoteError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => BookingQuoteOutcome.sessionExpired,
      ApiErrorKind.forbidden => BookingQuoteOutcome.forbidden,
      ApiErrorKind.notFound => BookingQuoteOutcome.notFound,
      ApiErrorKind.validation => BookingQuoteOutcome.validation,
      ApiErrorKind.network => BookingQuoteOutcome.network,
      ApiErrorKind.timeout => BookingQuoteOutcome.timeout,
      ApiErrorKind.server => BookingQuoteOutcome.serverError,
      ApiErrorKind.malformed => BookingQuoteOutcome.malformed,
      _ => BookingQuoteOutcome.serverError,
    };
  }

  /// Loads the real, backend-computed pricing quote for [roomId] over the stay
  /// in Real Mode only. Guards invalid dates client-side (mirroring the backend
  /// 400). Reuses the cached quote for the same room unless [refresh] is set. A
  /// newer load supersedes an older in-flight one (last wins).
  Future<BookingQuoteOutcome> loadBookingQuote({
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    int adults = 2,
    int children = 0,
    int extraBeds = 0,
    int? ratePlanId,
    bool refresh = false,
  }) async {
    if (demoMode) return BookingQuoteOutcome.unavailable;
    final inDay = DateTime(checkIn.year, checkIn.month, checkIn.day);
    final outDay = DateTime(checkOut.year, checkOut.month, checkOut.day);
    if (!outDay.isAfter(inDay)) {
      bookingQuoteRoomId = roomId;
      bookingQuoteError = BookingQuoteOutcome.invalidDates;
      bookingQuoteLoading = false;
      notifyListeners();
      return BookingQuoteOutcome.invalidDates;
    }
    if (!refresh &&
        bookingQuoteRoomId == roomId &&
        bookingQuoteError == null &&
        bookingQuote != null) {
      return BookingQuoteOutcome.success; // cached — no HTTP
    }

    final reqId = ++_bookingQuoteRequestId;
    if (bookingQuoteRoomId != roomId) {
      bookingQuote = null;
    }
    bookingQuoteRoomId = roomId;
    bookingQuoteLoading = true;
    bookingQuoteError = null;
    notifyListeners();

    final result = await api.getRoomPricingQuote(
      roomId: roomId,
      checkIn: inDay,
      checkOut: outDay,
      adults: adults,
      children: children,
      extraBeds: extraBeds,
      ratePlanId: ratePlanId,
    );

    if (reqId != _bookingQuoteRequestId) {
      return BookingQuoteOutcome.success; // superseded — discard
    }
    bookingQuoteLoading = false;
    if (result.success && result.data != null) {
      bookingQuote = result.data!;
      bookingQuoteError = null;
      notifyListeners();
      return BookingQuoteOutcome.success;
    }
    final outcome = _mapBookingQuoteError(result.errorKind);
    bookingQuoteError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Validates the current guest form. Pure — no backend call, no mutation.
  /// Required name + email and email format mirror what a future create needs;
  /// phone format and length caps guard the local-only fields.
  BookingValidation validateBookingDraft() {
    final name = bookingGuestName.trim();
    final mail = bookingContactEmail.trim();
    final phone = bookingContactPhone.trim();
    final country = bookingGuestCountry.trim();
    final note = bookingSpecialRequestNote.trim();
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final phoneRe = RegExp(r'^[+0-9][0-9 ()\-]{5,}$');
    return BookingValidation(
      nameRequired: name.isEmpty,
      emailRequired: mail.isEmpty,
      emailInvalid: mail.isNotEmpty && !emailRe.hasMatch(mail),
      phoneInvalid: phone.isNotEmpty && !phoneRe.hasMatch(phone),
      nameTooLong: name.length > BookingValidation.maxNameLength,
      phoneTooLong: phone.length > BookingValidation.maxPhoneLength,
      countryTooLong: country.length > BookingValidation.maxCountryLength,
      noteTooLong: note.length > BookingValidation.maxNoteLength,
    );
  }

  /// Prepares (but never submits) a client-side [BookingDraft] from the current
  /// selection, guest form and loaded quote. Real Mode only. No reservation is
  /// created — the side-effecting `POST /api/bookings` is deferred, so this can
  /// never produce a fake confirmation.
  BookingDraftOutcome finalizeBookingDraft({int? tripId}) {
    if (demoMode) return BookingDraftOutcome.unavailable;
    if (!validateBookingDraft().isValid) return BookingDraftOutcome.invalid;
    final room = selectedRoom;
    final quote = bookingQuote;
    final availability = realAvailability;
    if (room == null || quote == null || availability == null) {
      return BookingDraftOutcome.quoteMissing;
    }
    final plan = selectedRatePlan;
    final checkIn = availability.checkIn ?? quote.checkIn;
    final checkOut = availability.checkOut ?? quote.checkOut;
    bookingDraft = BookingDraft(
      placeId: availability.placeId,
      hotelName: availability.placeName,
      roomId: room.roomId,
      roomName: room.roomName,
      roomCode: room.roomCode,
      ratePlanId: plan?.ratePlanId ?? quote.selectedRatePlanId,
      ratePlanName: plan?.rateName ?? quote.selectedRatePlanName,
      checkIn: checkIn,
      checkOut: checkOut,
      nights: availability.nights,
      adults: availability.adults,
      children: availability.children,
      extraBeds: quote.extraBeds,
      guest: BookingGuestInfo(
        fullName: bookingGuestName.trim(),
        email: bookingContactEmail.trim(),
        phone: bookingContactPhone.trim(),
        country: bookingGuestCountry.trim(),
        arrivalTime: bookingArrivalTime.trim(),
      ),
      specialRequestPresets:
          Set<SpecialRequestPreset>.from(bookingSpecialRequestPresets),
      specialRequestNote: bookingSpecialRequestNote.trim(),
      quote: quote,
      tripId: tripId,
      createdAt: now(),
    );
    notifyListeners();
    return BookingDraftOutcome.ready;
  }

  BookingSubmissionOutcome _mapBookingSubmissionError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => BookingSubmissionOutcome.sessionExpired,
      ApiErrorKind.forbidden => BookingSubmissionOutcome.forbidden,
      ApiErrorKind.notFound => BookingSubmissionOutcome.notFound,
      ApiErrorKind.validation => BookingSubmissionOutcome.validation,
      ApiErrorKind.conflict => BookingSubmissionOutcome.conflict,
      ApiErrorKind.unprocessable => BookingSubmissionOutcome.unprocessable,
      ApiErrorKind.uncertain => BookingSubmissionOutcome.uncertain,
      ApiErrorKind.network => BookingSubmissionOutcome.network,
      ApiErrorKind.server => BookingSubmissionOutcome.serverError,
      _ => BookingSubmissionOutcome.serverError,
    };
  }

  /// Submits a REAL booking (`POST /api/bookings`) in Real Mode only. Returns
  /// the server's own booking code / status / pricing — nothing is fabricated,
  /// no payment state is implied, and [PENDING] stays pending. Single-flight:
  /// while one submit is in flight a second call returns [busy] with no HTTP. On
  /// any failure or an [uncertain] (timeout / malformed success) outcome the
  /// draft and guest form are preserved and no automatic retry is attempted.
  ///
  /// [specialRequest] is the composed, backend-supported free text (guest
  /// name/phone/country/email have no backend field and are never submitted).
  Future<BookingSubmissionOutcome> submitRealBooking({
    String? specialRequest,
    int? tripId,
  }) async {
    // Demo Mode: zero HTTP. Single-flight guard: no second concurrent submit.
    if (demoMode) return BookingSubmissionOutcome.demoUnavailable;
    if (realBookingSubmitting) return BookingSubmissionOutcome.busy;
    if (!validateBookingDraft().isValid) {
      return BookingSubmissionOutcome.invalid;
    }
    final room = selectedRoom;
    final quote = bookingQuote;
    final availability = realAvailability;
    if (room == null || quote == null || availability == null) {
      return BookingSubmissionOutcome.quoteMissing;
    }

    final sr = specialRequest?.trim();
    final payload = BookingCreatePayload(
      roomId: room.roomId,
      checkIn: availability.checkIn ?? quote.checkIn,
      checkOut: availability.checkOut ?? quote.checkOut,
      adults: availability.adults,
      children: availability.children,
      numberOfRooms: 1,
      extraBeds: quote.extraBeds,
      ratePlanId: selectedRatePlan?.ratePlanId ?? quote.selectedRatePlanId,
      specialRequest: (sr != null && sr.isNotEmpty) ? sr : null,
    );

    realBookingSubmitting = true;
    realBookingSubmissionError = null;
    notifyListeners();

    final result = await api.createBooking(payload);

    realBookingSubmitting = false;
    if (result.success && result.data != null) {
      // Store the server's real record. Deliberately NOT clearing the draft or
      // implying any payment success — payment is a separate future phase.
      lastCreatedBooking = result.data!;
      realBookingSubmissionError = null;
      notifyListeners();
      return BookingSubmissionOutcome.success;
    }
    // Failure / uncertain: preserve the draft + guest form so the user can
    // review or recover; never fabricate a success.
    final outcome = _mapBookingSubmissionError(result.errorKind);
    realBookingSubmissionError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Clears a prior submission error so the user can explicitly recover (e.g.
  /// dismiss an uncertain-submission warning). Does not touch [lastCreatedBooking].
  void clearBookingSubmissionError() {
    if (realBookingSubmissionError == null) return;
    realBookingSubmissionError = null;
    notifyListeners();
  }

  BookingHistoryOutcome _mapBookingHistoryError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => BookingHistoryOutcome.sessionExpired,
      ApiErrorKind.forbidden => BookingHistoryOutcome.forbidden,
      ApiErrorKind.notFound => BookingHistoryOutcome.notFound,
      ApiErrorKind.network => BookingHistoryOutcome.network,
      ApiErrorKind.timeout => BookingHistoryOutcome.network,
      ApiErrorKind.server => BookingHistoryOutcome.serverError,
      _ => BookingHistoryOutcome.serverError,
    };
  }

  /// Loads the authenticated user's real booking history (`GET /api/me/bookings`,
  /// UI-27). [refresh] forces a re-fetch (pull-to-refresh) and preserves the
  /// current list if the re-fetch fails. Zero HTTP in Demo Mode. A 401 maps to
  /// [BookingHistoryOutcome.sessionExpired] and never calls [logout].
  Future<BookingHistoryOutcome> loadMyBookings({bool refresh = false}) async {
    if (demoMode) return BookingHistoryOutcome.demoUnavailable;
    if (realBookingsLoading || realBookingsRefreshing) {
      return BookingHistoryOutcome.success;
    }
    if (realBookingsLoaded && !refresh) return BookingHistoryOutcome.success;
    if (refresh) {
      realBookingsRefreshing = true;
    } else {
      realBookingsLoading = true;
    }
    realBookingsError = null;
    notifyListeners();
    final result = await api.getMyBookings();
    realBookingsLoading = false;
    realBookingsRefreshing = false;
    if (result.success && result.data != null) {
      realBookings = result.data!;
      realBookingsLoaded = true;
      realBookingsError = null;
      notifyListeners();
      return BookingHistoryOutcome.success;
    }
    // Preserve any previously loaded list; only surface the error.
    final outcome = _mapBookingHistoryError(result.errorKind);
    realBookingsError = outcome;
    notifyListeners();
    return outcome;
  }

  BookingCreateRecord? bookingDetailFor(int id) => bookingDetailCache[id];

  /// Loads one real booking's full detail (`GET /api/bookings/{id}`, UI-27) into
  /// [bookingDetailCache]. A cached record short-circuits unless [refresh]. Zero
  /// HTTP in Demo Mode; a 401 maps to [sessionExpired] and never calls [logout].
  Future<BookingHistoryOutcome> loadBookingDetail(
    int id, {
    bool refresh = false,
  }) async {
    if (demoMode) return BookingHistoryOutcome.demoUnavailable;
    if (bookingDetailCache.containsKey(id) && !refresh) {
      return BookingHistoryOutcome.success;
    }
    if (bookingDetailLoadingId == id) return BookingHistoryOutcome.success;
    bookingDetailLoadingId = id;
    bookingDetailError = null;
    notifyListeners();
    final result = await api.getBookingDetail(id);
    bookingDetailLoadingId = null;
    if (result.success && result.data != null) {
      bookingDetailCache[id] = result.data!;
      bookingDetailError = null;
      notifyListeners();
      return BookingHistoryOutcome.success;
    }
    final outcome = _mapBookingHistoryError(result.errorKind);
    bookingDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  PaymentActionOutcome _mapPaymentError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => PaymentActionOutcome.sessionExpired,
      ApiErrorKind.forbidden => PaymentActionOutcome.forbidden,
      ApiErrorKind.notFound => PaymentActionOutcome.notFound,
      ApiErrorKind.validation => PaymentActionOutcome.validation,
      ApiErrorKind.conflict => PaymentActionOutcome.conflict,
      ApiErrorKind.unprocessable => PaymentActionOutcome.unprocessable,
      ApiErrorKind.network => PaymentActionOutcome.network,
      ApiErrorKind.timeout => PaymentActionOutcome.network,
      ApiErrorKind.server => PaymentActionOutcome.serverError,
      _ => PaymentActionOutcome.serverError,
    };
  }

  /// Opens the payment context for [bookingId] and loads any EXISTING payment
  /// (`GET /api/bookings/{id}/payments`, latest first — the backend sorts
  /// createdAt DESC). Leaves [realPayment] null when the booking has none yet.
  /// Zero HTTP in Demo Mode; a 401 maps to sessionExpired, never [logout].
  Future<PaymentActionOutcome> loadPaymentForBooking(int bookingId) async {
    if (demoMode) return PaymentActionOutcome.demoUnavailable;
    realPaymentBookingId = bookingId;
    realPayment = null;
    realPaymentLoading = true;
    realPaymentError = null;
    notifyListeners();
    final result = await api.getBookingPayments(bookingId);
    // Ignore a stale response if the user opened a different booking meanwhile.
    if (realPaymentBookingId != bookingId) return PaymentActionOutcome.success;
    realPaymentLoading = false;
    if (result.success && result.data != null) {
      realPayment = result.data!.isEmpty ? null : result.data!.first;
      realPaymentError = null;
      notifyListeners();
      return PaymentActionOutcome.success;
    }
    final outcome = _mapPaymentError(result.errorKind);
    realPaymentError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Creates a real PENDING payment for [bookingId] (`POST /api/payments`).
  /// Single-flight. On success stores [realPayment]; on failure preserves any
  /// existing payment and surfaces the mapped outcome.
  Future<PaymentActionOutcome> createRealPayment(int bookingId) async {
    if (demoMode) return PaymentActionOutcome.demoUnavailable;
    if (realPaymentSubmitting) return PaymentActionOutcome.busy;
    realPaymentBookingId = bookingId;
    realPaymentSubmitting = true;
    realPaymentError = null;
    notifyListeners();
    final result = await api.createPayment(bookingId);
    realPaymentSubmitting = false;
    if (result.success && result.data != null) {
      realPayment = result.data!;
      realPaymentError = null;
      notifyListeners();
      return PaymentActionOutcome.success;
    }
    final outcome = _mapPaymentError(result.errorKind);
    realPaymentError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Re-fetches the current payment's status (`GET /api/payments/{id}`).
  Future<PaymentActionOutcome> refreshRealPayment() async {
    if (demoMode) return PaymentActionOutcome.demoUnavailable;
    final payment = realPayment;
    if (payment == null) return PaymentActionOutcome.notFound;
    if (realPaymentLoading) return PaymentActionOutcome.busy;
    realPaymentLoading = true;
    realPaymentError = null;
    notifyListeners();
    final result = await api.getPayment(payment.id);
    realPaymentLoading = false;
    if (result.success && result.data != null) {
      realPayment = result.data!;
      realPaymentError = null;
      notifyListeners();
      return PaymentActionOutcome.success;
    }
    final outcome = _mapPaymentError(result.errorKind);
    realPaymentError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Settles the current PENDING payment via the backend's sandbox endpoints
  /// ([success]=true → `mock-success` → PAID + booking CONFIRMED; false →
  /// `mock-fail` → FAILED). These are REAL backend endpoints (the only offline
  /// completion path). On a successful capture the real booking history/detail
  /// caches are invalidated so the now-CONFIRMED booking is re-fetched.
  Future<PaymentActionOutcome> settleRealPaymentSandbox({
    required bool success,
  }) async {
    if (demoMode) return PaymentActionOutcome.demoUnavailable;
    if (realPaymentSubmitting) return PaymentActionOutcome.busy;
    final payment = realPayment;
    if (payment == null) return PaymentActionOutcome.notFound;
    realPaymentSubmitting = true;
    realPaymentError = null;
    notifyListeners();
    final result = await api.settlePaymentSandbox(payment.id, success: success);
    realPaymentSubmitting = false;
    if (result.success && result.data != null) {
      realPayment = result.data!;
      realPaymentError = null;
      if (result.data!.statusView == PaymentStatusView.paid) {
        _invalidateRealBookingsAfterPayment(result.data!.bookingId);
      }
      notifyListeners();
      return PaymentActionOutcome.success;
    }
    final outcome = _mapPaymentError(result.errorKind);
    realPaymentError = outcome;
    notifyListeners();
    return outcome;
  }

  /// A PAID payment CONFIRMS the booking server-side, so the cached history list
  /// and this booking's detail are now stale — drop them so the next open
  /// re-fetches the real, updated status. No fabricated local status flip.
  void _invalidateRealBookingsAfterPayment(int bookingId) {
    realBookingsLoaded = false;
    bookingDetailCache.remove(bookingId);
  }

  void clearRealPaymentError() {
    if (realPaymentError == null) return;
    realPaymentError = null;
    notifyListeners();
  }

  ReviewActionOutcome _mapReviewError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => ReviewActionOutcome.sessionExpired,
      ApiErrorKind.forbidden => ReviewActionOutcome.forbidden,
      ApiErrorKind.notFound => ReviewActionOutcome.notFound,
      ApiErrorKind.validation => ReviewActionOutcome.validation,
      ApiErrorKind.conflict => ReviewActionOutcome.alreadyReviewed,
      ApiErrorKind.unprocessable => ReviewActionOutcome.notCompleted,
      ApiErrorKind.network => ReviewActionOutcome.network,
      ApiErrorKind.timeout => ReviewActionOutcome.network,
      ApiErrorKind.server => ReviewActionOutcome.serverError,
      _ => ReviewActionOutcome.serverError,
    };
  }

  /// Loads a place's PUBLIC (approved) reviews (`GET /api/places/{id}/reviews`).
  /// A different place supersedes an older in-flight load (last request wins).
  Future<ReviewActionOutcome> loadPlaceReviews(
    int placeId, {
    bool refresh = false,
  }) async {
    if (demoMode) return ReviewActionOutcome.demoUnavailable;
    if (reviewsPlaceId == placeId &&
        placeReviewsLoaded &&
        !refresh &&
        !placeReviewsLoading) {
      return ReviewActionOutcome.success;
    }
    reviewsPlaceId = placeId;
    placeReviewsLoading = true;
    placeReviewsError = null;
    notifyListeners();
    final result = await api.getPlaceReviews(placeId);
    if (reviewsPlaceId != placeId) return ReviewActionOutcome.success;
    placeReviewsLoading = false;
    if (result.success && result.data != null) {
      placeReviews = result.data!;
      placeReviewsLoaded = true;
      placeReviewsError = null;
      notifyListeners();
      return ReviewActionOutcome.success;
    }
    final outcome = _mapReviewError(result.errorKind);
    placeReviewsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Loads the authenticated user's own reviews (`GET /api/me/reviews`).
  /// [refresh] forces a re-fetch and preserves the current list on failure.
  Future<ReviewActionOutcome> loadMyReviews({bool refresh = false}) async {
    if (demoMode) return ReviewActionOutcome.demoUnavailable;
    if (myReviewsLoading || myReviewsRefreshing) {
      return ReviewActionOutcome.success;
    }
    if (myReviewsLoaded && !refresh) return ReviewActionOutcome.success;
    if (refresh) {
      myReviewsRefreshing = true;
    } else {
      myReviewsLoading = true;
    }
    myReviewsError = null;
    notifyListeners();
    final result = await api.getMyReviews();
    myReviewsLoading = false;
    myReviewsRefreshing = false;
    if (result.success && result.data != null) {
      realMyReviews = result.data!;
      myReviewsLoaded = true;
      myReviewsError = null;
      notifyListeners();
      return ReviewActionOutcome.success;
    }
    final outcome = _mapReviewError(result.errorKind);
    myReviewsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Submits a review for a COMPLETED booking (`POST /api/reviews`). Single-flight.
  /// The created review is PENDING (awaits moderation) — no fabricated approval.
  /// On success invalidates the my-reviews cache so it re-fetches on next open.
  Future<ReviewActionOutcome> submitReview(ReviewCreatePayload payload) async {
    if (demoMode) return ReviewActionOutcome.demoUnavailable;
    if (reviewSubmitting) return ReviewActionOutcome.busy;
    reviewSubmitting = true;
    reviewSubmitError = null;
    notifyListeners();
    final result = await api.createReview(payload);
    reviewSubmitting = false;
    if (result.success && result.data != null) {
      lastSubmittedReview = result.data!;
      reviewSubmitError = null;
      // The new review belongs in the user's list — invalidate it for a re-fetch.
      myReviewsLoaded = false;
      notifyListeners();
      return ReviewActionOutcome.success;
    }
    final outcome = _mapReviewError(result.errorKind);
    reviewSubmitError = outcome;
    notifyListeners();
    return outcome;
  }

  void clearReviewSubmitError() {
    if (reviewSubmitError == null) return;
    reviewSubmitError = null;
    notifyListeners();
  }

  RealNotificationOutcome _mapNotificationError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => RealNotificationOutcome.sessionExpired,
      ApiErrorKind.forbidden => RealNotificationOutcome.forbidden,
      ApiErrorKind.notFound => RealNotificationOutcome.notFound,
      ApiErrorKind.network => RealNotificationOutcome.network,
      ApiErrorKind.timeout => RealNotificationOutcome.network,
      ApiErrorKind.server => RealNotificationOutcome.serverError,
      _ => RealNotificationOutcome.serverError,
    };
  }

  Future<void> _refreshServerUnread() async {
    final result = await api.getUnreadNotificationCount();
    if (result.success && result.data != null) {
      realNotificationsServerUnread = result.data;
      notifyListeners();
    }
  }

  /// Loads the authenticated user's real notifications (`GET /api/me/notifications`).
  /// [refresh] forces a re-fetch and preserves the current list on failure.
  Future<RealNotificationOutcome> loadRealNotifications({
    bool refresh = false,
  }) async {
    if (demoMode) return RealNotificationOutcome.demoUnavailable;
    if (realNotificationsLoading || realNotificationsRefreshing) {
      return RealNotificationOutcome.success;
    }
    if (realNotificationsLoaded && !refresh) {
      return RealNotificationOutcome.success;
    }
    if (refresh) {
      realNotificationsRefreshing = true;
    } else {
      realNotificationsLoading = true;
    }
    realNotificationsError = null;
    notifyListeners();
    final result = await api.getNotifications();
    realNotificationsLoading = false;
    realNotificationsRefreshing = false;
    if (result.success && result.data != null) {
      realNotifications = result.data!;
      realNotificationsLoaded = true;
      realNotificationsError = null;
      notifyListeners();
      // Best-effort authoritative unread count for the header badge.
      await _refreshServerUnread();
      return RealNotificationOutcome.success;
    }
    final outcome = _mapNotificationError(result.errorKind);
    realNotificationsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Marks one notification read (`PATCH /api/me/notifications/{id}/read`). The
  /// list item is replaced with the server's updated record — no optimistic flip.
  Future<RealNotificationOutcome> markRealNotificationRead(int id) async {
    if (demoMode) return RealNotificationOutcome.demoUnavailable;
    if (notificationActionInFlight.contains(id)) {
      return RealNotificationOutcome.busy;
    }
    notificationActionInFlight.add(id);
    notifyListeners();
    final result = await api.markNotificationRead(id);
    notificationActionInFlight.remove(id);
    if (result.success && result.data != null) {
      final updated = result.data!;
      realNotifications = [
        for (final n in realNotifications)
          if (n.id == id) updated else n,
      ];
      notifyListeners();
      await _refreshServerUnread();
      return RealNotificationOutcome.success;
    }
    final outcome = _mapNotificationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Marks every notification read (`PATCH /api/me/notifications/read-all`), then
  /// re-fetches the list so the read state reflects the server (no local guess).
  Future<RealNotificationOutcome> markAllRealNotificationsRead() async {
    if (demoMode) return RealNotificationOutcome.demoUnavailable;
    if (notificationActionInFlight.isNotEmpty) {
      return RealNotificationOutcome.busy;
    }
    // Reserve a sentinel so no concurrent action runs during the batch update.
    notificationActionInFlight.add(-1);
    notifyListeners();
    final result = await api.markAllNotificationsRead();
    notificationActionInFlight.remove(-1);
    if (result.success) {
      notifyListeners();
      await loadRealNotifications(refresh: true);
      return RealNotificationOutcome.success;
    }
    final outcome = _mapNotificationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes one notification (`DELETE /api/me/notifications/{id}`) and removes it
  /// from the list only after the server confirms.
  Future<RealNotificationOutcome> deleteRealNotification(int id) async {
    if (demoMode) return RealNotificationOutcome.demoUnavailable;
    if (notificationActionInFlight.contains(id)) {
      return RealNotificationOutcome.busy;
    }
    notificationActionInFlight.add(id);
    notifyListeners();
    final result = await api.deleteNotification(id);
    notificationActionInFlight.remove(id);
    if (result.success) {
      realNotifications = realNotifications.where((n) => n.id != id).toList();
      notifyListeners();
      await _refreshServerUnread();
      return RealNotificationOutcome.success;
    }
    final outcome = _mapNotificationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  RecentlyViewedOutcome _mapRecentlyViewedError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => RecentlyViewedOutcome.sessionExpired,
      ApiErrorKind.forbidden => RecentlyViewedOutcome.forbidden,
      ApiErrorKind.notFound => RecentlyViewedOutcome.notFound,
      ApiErrorKind.network => RecentlyViewedOutcome.network,
      ApiErrorKind.timeout => RecentlyViewedOutcome.network,
      ApiErrorKind.server => RecentlyViewedOutcome.serverError,
      _ => RecentlyViewedOutcome.serverError,
    };
  }

  /// Loads the user's real recently-viewed places (`GET /api/me/recently-viewed`).
  /// [refresh] forces a re-fetch and preserves the current list on failure.
  Future<RecentlyViewedOutcome> loadRealRecentlyViewed({
    bool refresh = false,
  }) async {
    if (demoMode) return RecentlyViewedOutcome.demoUnavailable;
    if (realRecentlyViewedLoading || realRecentlyViewedRefreshing) {
      return RecentlyViewedOutcome.success;
    }
    if (realRecentlyViewedLoaded && !refresh) {
      return RecentlyViewedOutcome.success;
    }
    if (refresh) {
      realRecentlyViewedRefreshing = true;
    } else {
      realRecentlyViewedLoading = true;
    }
    realRecentlyViewedError = null;
    notifyListeners();
    final result = await api.getRecentlyViewed();
    realRecentlyViewedLoading = false;
    realRecentlyViewedRefreshing = false;
    if (result.success && result.data != null) {
      realRecentlyViewed = result.data!;
      realRecentlyViewedLoaded = true;
      realRecentlyViewedError = null;
      notifyListeners();
      return RecentlyViewedOutcome.success;
    }
    final outcome = _mapRecentlyViewedError(result.errorKind);
    realRecentlyViewedError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Records (or refreshes) a view of a published place
  /// (`POST /api/me/recently-viewed/{placeId}`). Best-effort — the list is
  /// invalidated so it re-fetches, but a failure is returned, not surfaced as an
  /// error state. Zero HTTP in Demo Mode.
  Future<RecentlyViewedOutcome> recordRealRecentlyView(int placeId) async {
    if (demoMode) return RecentlyViewedOutcome.demoUnavailable;
    final result = await api.recordRecentlyView(placeId);
    if (result.success) {
      // The list order changed server-side; invalidate for a fresh re-fetch.
      realRecentlyViewedLoaded = false;
      return RecentlyViewedOutcome.success;
    }
    return _mapRecentlyViewedError(result.errorKind);
  }

  /// Clears the entire recently-viewed list (`DELETE /api/me/recently-viewed`).
  Future<RecentlyViewedOutcome> clearRealRecentlyViewed() async {
    if (demoMode) return RecentlyViewedOutcome.demoUnavailable;
    if (recentlyViewedActionInFlight.contains(-1)) {
      return RecentlyViewedOutcome.busy;
    }
    recentlyViewedActionInFlight.add(-1);
    notifyListeners();
    final result = await api.clearRecentlyViewed();
    recentlyViewedActionInFlight.remove(-1);
    if (result.success) {
      realRecentlyViewed = [];
      notifyListeners();
      return RecentlyViewedOutcome.success;
    }
    final outcome = _mapRecentlyViewedError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Removes one place from the list (`DELETE /api/me/recently-viewed/{placeId}`)
  /// and drops it locally only after the server confirms.
  Future<RecentlyViewedOutcome> removeRealRecentlyViewed(int placeId) async {
    if (demoMode) return RecentlyViewedOutcome.demoUnavailable;
    if (recentlyViewedActionInFlight.contains(placeId)) {
      return RecentlyViewedOutcome.busy;
    }
    recentlyViewedActionInFlight.add(placeId);
    notifyListeners();
    final result = await api.removeRecentlyViewed(placeId);
    recentlyViewedActionInFlight.remove(placeId);
    if (result.success) {
      realRecentlyViewed =
          realRecentlyViewed.where((r) => r.placeId != placeId).toList();
      notifyListeners();
      return RecentlyViewedOutcome.success;
    }
    final outcome = _mapRecentlyViewedError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Customer Profile (UI-32) ───────────────────────────────────

  CustomerProfileOutcome _mapProfileError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => CustomerProfileOutcome.sessionExpired,
      ApiErrorKind.forbidden => CustomerProfileOutcome.forbidden,
      ApiErrorKind.notFound => CustomerProfileOutcome.notFound,
      ApiErrorKind.network => CustomerProfileOutcome.network,
      ApiErrorKind.timeout => CustomerProfileOutcome.network,
      ApiErrorKind.server => CustomerProfileOutcome.serverError,
      _ => CustomerProfileOutcome.serverError,
    };
  }

  /// Loads the signed-in user's identity (`GET /api/me`). Read-only; preserves
  /// the current value on failure. Zero HTTP in Demo Mode.
  Future<CustomerProfileOutcome> loadRealAccountIdentity({
    bool refresh = false,
  }) async {
    if (demoMode) return CustomerProfileOutcome.demoUnavailable;
    if (realIdentityLoading) return CustomerProfileOutcome.success;
    if (realIdentityLoaded && !refresh) return CustomerProfileOutcome.success;
    realIdentityLoading = true;
    realIdentityError = null;
    notifyListeners();
    final result = await api.getAccountIdentity();
    realIdentityLoading = false;
    if (result.success && result.data != null) {
      realIdentity = result.data!;
      realIdentityLoaded = true;
      realIdentityError = null;
      notifyListeners();
      return CustomerProfileOutcome.success;
    }
    final outcome = _mapProfileError(result.errorKind);
    realIdentityError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Loads the signed-in user's travel profile (`GET /api/me/profile`).
  /// [refresh] forces a re-fetch and preserves the current profile on failure.
  Future<CustomerProfileOutcome> loadRealCustomerProfile({
    bool refresh = false,
  }) async {
    if (demoMode) return CustomerProfileOutcome.demoUnavailable;
    if (realProfileLoading || realProfileRefreshing) {
      return CustomerProfileOutcome.success;
    }
    if (realProfileLoaded && !refresh) return CustomerProfileOutcome.success;
    if (refresh) {
      realProfileRefreshing = true;
    } else {
      realProfileLoading = true;
    }
    realProfileError = null;
    notifyListeners();
    final result = await api.getCustomerProfile();
    realProfileLoading = false;
    realProfileRefreshing = false;
    if (result.success && result.data != null) {
      realProfile = result.data!;
      realProfileLoaded = true;
      realProfileError = null;
      notifyListeners();
      return CustomerProfileOutcome.success;
    }
    final outcome = _mapProfileError(result.errorKind);
    realProfileError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Full-replace update of the travel profile (`PUT /api/me/profile`). Stores
  /// only the server's returned (masked) record — never optimistic. Single-flight
  /// via [realProfileSaving]. Zero HTTP in Demo Mode.
  Future<CustomerProfileOutcome> updateRealCustomerProfile(
    CustomerProfileUpdate update,
  ) async {
    if (demoMode) return CustomerProfileOutcome.demoUnavailable;
    if (realProfileSaving) return CustomerProfileOutcome.busy;
    realProfileSaving = true;
    realProfileError = null;
    notifyListeners();
    final result = await api.updateCustomerProfile(update);
    realProfileSaving = false;
    if (result.success && result.data != null) {
      realProfile = result.data!;
      realProfileLoaded = true;
      realProfileError = null;
      notifyListeners();
      return CustomerProfileOutcome.success;
    }
    final outcome = _mapProfileError(result.errorKind);
    realProfileError = outcome;
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Gift Cards (UI-33) ─────────────────────────────────────────

  static const int _giftCardsPageSize = 20;

  GiftCardActionOutcome _mapGiftCardError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => GiftCardActionOutcome.sessionExpired,
      ApiErrorKind.forbidden => GiftCardActionOutcome.forbidden,
      ApiErrorKind.notFound => GiftCardActionOutcome.notFound,
      ApiErrorKind.conflict => GiftCardActionOutcome.conflict,
      ApiErrorKind.validation => GiftCardActionOutcome.validation,
      ApiErrorKind.unprocessable => GiftCardActionOutcome.validation,
      ApiErrorKind.network => GiftCardActionOutcome.network,
      ApiErrorKind.timeout => GiftCardActionOutcome.network,
      ApiErrorKind.server => GiftCardActionOutcome.serverError,
      _ => GiftCardActionOutcome.serverError,
    };
  }

  /// Loads the first page of the user's gift cards (`GET /api/me/gift-cards`).
  /// [refresh] forces a re-fetch and preserves the current list on failure.
  Future<GiftCardActionOutcome> loadRealGiftCards(
      {bool refresh = false}) async {
    if (demoMode) return GiftCardActionOutcome.demoUnavailable;
    if (realGiftCardsLoading || realGiftCardsRefreshing) {
      return GiftCardActionOutcome.success;
    }
    if (realGiftCardsLoaded && !refresh) return GiftCardActionOutcome.success;
    if (refresh) {
      realGiftCardsRefreshing = true;
    } else {
      realGiftCardsLoading = true;
    }
    realGiftCardsError = null;
    notifyListeners();
    final result = await api.getMyGiftCards(page: 0, size: _giftCardsPageSize);
    realGiftCardsLoading = false;
    realGiftCardsRefreshing = false;
    if (result.success && result.data != null) {
      final data = result.data!;
      realGiftCards = data.content;
      realGiftCardsPage = data.page;
      realGiftCardsTotalPages = data.totalPages;
      realGiftCardsLoaded = true;
      realGiftCardsError = null;
      notifyListeners();
      return GiftCardActionOutcome.success;
    }
    final outcome = _mapGiftCardError(result.errorKind);
    realGiftCardsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Appends the next page of gift cards (real backend pagination — never faked).
  Future<GiftCardActionOutcome> loadMoreRealGiftCards() async {
    if (demoMode) return GiftCardActionOutcome.demoUnavailable;
    if (!realGiftCardsLoaded || realGiftCardsLoadingMore) {
      return GiftCardActionOutcome.success;
    }
    if (!realGiftCardsHasMore) return GiftCardActionOutcome.success;
    realGiftCardsLoadingMore = true;
    notifyListeners();
    final next = realGiftCardsPage + 1;
    final result =
        await api.getMyGiftCards(page: next, size: _giftCardsPageSize);
    realGiftCardsLoadingMore = false;
    if (result.success && result.data != null) {
      final data = result.data!;
      realGiftCards = [...realGiftCards, ...data.content];
      realGiftCardsPage = data.page;
      realGiftCardsTotalPages = data.totalPages;
      notifyListeners();
      return GiftCardActionOutcome.success;
    }
    final outcome = _mapGiftCardError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Loads one gift card's full detail (`GET /api/me/gift-cards/{id}`), cached.
  Future<GiftCardActionOutcome> loadRealGiftCardDetail(
    int id, {
    bool refresh = false,
  }) async {
    if (demoMode) return GiftCardActionOutcome.demoUnavailable;
    if (giftCardDetailLoadingId == id) return GiftCardActionOutcome.success;
    if (giftCardDetailCache.containsKey(id) && !refresh) {
      return GiftCardActionOutcome.success;
    }
    giftCardDetailLoadingId = id;
    giftCardDetailError = null;
    notifyListeners();
    final result = await api.getGiftCard(id);
    giftCardDetailLoadingId = null;
    if (result.success && result.data != null) {
      giftCardDetailCache[id] = result.data!;
      giftCardDetailError = null;
      notifyListeners();
      return GiftCardActionOutcome.success;
    }
    final outcome = _mapGiftCardError(result.errorKind);
    giftCardDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Loads the first page of one gift card's ledger
  /// (`GET /api/me/gift-cards/{id}/transactions`), cached.
  Future<GiftCardActionOutcome> loadRealGiftCardTransactions(
    int id, {
    bool refresh = false,
  }) async {
    if (demoMode) return GiftCardActionOutcome.demoUnavailable;
    if (giftCardTransactionsLoadingId == id) {
      return GiftCardActionOutcome.success;
    }
    if (giftCardTransactionsCache.containsKey(id) && !refresh) {
      return GiftCardActionOutcome.success;
    }
    giftCardTransactionsLoadingId = id;
    notifyListeners();
    final result = await api.getGiftCardTransactions(id,
        page: 0, size: _giftCardsPageSize);
    giftCardTransactionsLoadingId = null;
    if (result.success && result.data != null) {
      giftCardTransactionsCache[id] = result.data!.content;
      notifyListeners();
      return GiftCardActionOutcome.success;
    }
    final outcome = _mapGiftCardError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Claims a gift card by code (`POST /api/me/gift-cards/claim`) and, on success,
  /// refreshes the list so the claimed card appears. Single-flight via a sentinel.
  Future<GiftCardActionOutcome> claimRealGiftCard(String code) async {
    if (demoMode) return GiftCardActionOutcome.demoUnavailable;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return GiftCardActionOutcome.validation;
    if (giftCardActionInFlight.contains(-1)) return GiftCardActionOutcome.busy;
    giftCardActionInFlight.add(-1);
    notifyListeners();
    final result = await api.claimGiftCard(trimmed);
    giftCardActionInFlight.remove(-1);
    if (result.success && result.data != null) {
      giftCardDetailCache[result.data!.id] = result.data!;
      notifyListeners();
      await loadRealGiftCards(refresh: true);
      return GiftCardActionOutcome.success;
    }
    final outcome = _mapGiftCardError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Activates an ISSUED gift card (`POST /api/me/gift-cards/{id}/activate`) and,
  /// on success, updates the cached detail and refreshes the list row.
  Future<GiftCardActionOutcome> activateRealGiftCard(int id) async {
    if (demoMode) return GiftCardActionOutcome.demoUnavailable;
    if (giftCardActionInFlight.contains(id)) return GiftCardActionOutcome.busy;
    giftCardActionInFlight.add(id);
    notifyListeners();
    final result = await api.activateGiftCard(id);
    giftCardActionInFlight.remove(id);
    if (result.success && result.data != null) {
      giftCardDetailCache[id] = result.data!;
      notifyListeners();
      await loadRealGiftCards(refresh: true);
      return GiftCardActionOutcome.success;
    }
    final outcome = _mapGiftCardError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Loyalty (UI-34) ────────────────────────────────────────────

  static const int _loyaltyPageSize = 20;

  LoyaltyOutcome _mapLoyaltyError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => LoyaltyOutcome.sessionExpired,
      ApiErrorKind.forbidden => LoyaltyOutcome.forbidden,
      ApiErrorKind.notFound => LoyaltyOutcome.notFound,
      ApiErrorKind.network => LoyaltyOutcome.network,
      ApiErrorKind.timeout => LoyaltyOutcome.network,
      ApiErrorKind.server => LoyaltyOutcome.serverError,
      _ => LoyaltyOutcome.serverError,
    };
  }

  /// Loads the loyalty account (`GET /api/me/loyalty`) plus the first page of the
  /// transaction ledger (`GET /api/me/loyalty/transactions`). Both must succeed
  /// to commit; on failure the prior state is preserved. [refresh] forces a
  /// re-fetch. Zero HTTP in Demo Mode.
  Future<LoyaltyOutcome> loadRealLoyalty({bool refresh = false}) async {
    if (demoMode) return LoyaltyOutcome.demoUnavailable;
    if (realLoyaltyLoading || realLoyaltyRefreshing) {
      return LoyaltyOutcome.success;
    }
    if (realLoyaltyLoaded && !refresh) return LoyaltyOutcome.success;
    if (refresh) {
      realLoyaltyRefreshing = true;
    } else {
      realLoyaltyLoading = true;
    }
    realLoyaltyError = null;
    notifyListeners();
    final accountResult = await api.getLoyaltyAccount();
    if (!accountResult.success || accountResult.data == null) {
      realLoyaltyLoading = false;
      realLoyaltyRefreshing = false;
      final outcome = _mapLoyaltyError(accountResult.errorKind);
      realLoyaltyError = outcome;
      notifyListeners();
      return outcome;
    }
    final txResult =
        await api.getLoyaltyTransactions(page: 0, size: _loyaltyPageSize);
    realLoyaltyLoading = false;
    realLoyaltyRefreshing = false;
    if (!txResult.success || txResult.data == null) {
      final outcome = _mapLoyaltyError(txResult.errorKind);
      realLoyaltyError = outcome;
      notifyListeners();
      return outcome;
    }
    realLoyaltyAccount = accountResult.data!;
    realLoyaltyTransactions = txResult.data!.content;
    realLoyaltyTxPage = txResult.data!.page;
    realLoyaltyTxTotalPages = txResult.data!.totalPages;
    realLoyaltyLoaded = true;
    realLoyaltyError = null;
    notifyListeners();
    return LoyaltyOutcome.success;
  }

  /// Appends the next page of loyalty transactions (real backend pagination).
  Future<LoyaltyOutcome> loadMoreRealLoyaltyTransactions() async {
    if (demoMode) return LoyaltyOutcome.demoUnavailable;
    if (!realLoyaltyLoaded || realLoyaltyTxLoadingMore) {
      return LoyaltyOutcome.success;
    }
    if (!realLoyaltyTxHasMore) return LoyaltyOutcome.success;
    realLoyaltyTxLoadingMore = true;
    notifyListeners();
    final next = realLoyaltyTxPage + 1;
    final result =
        await api.getLoyaltyTransactions(page: next, size: _loyaltyPageSize);
    realLoyaltyTxLoadingMore = false;
    if (result.success && result.data != null) {
      realLoyaltyTransactions = [
        ...realLoyaltyTransactions,
        ...result.data!.content,
      ];
      realLoyaltyTxPage = result.data!.page;
      realLoyaltyTxTotalPages = result.data!.totalPages;
      notifyListeners();
      return LoyaltyOutcome.success;
    }
    final outcome = _mapLoyaltyError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Travel Credit (UI-35) ──────────────────────────────────────

  static const int _travelCreditPageSize = 20;

  TravelCreditOutcome _mapTravelCreditError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => TravelCreditOutcome.sessionExpired,
      ApiErrorKind.forbidden => TravelCreditOutcome.forbidden,
      ApiErrorKind.notFound => TravelCreditOutcome.notFound,
      ApiErrorKind.network => TravelCreditOutcome.network,
      ApiErrorKind.timeout => TravelCreditOutcome.network,
      ApiErrorKind.server => TravelCreditOutcome.serverError,
      _ => TravelCreditOutcome.serverError,
    };
  }

  /// Loads the travel-credit account (`GET /api/me/travel-credits`) plus the first
  /// page of the transaction ledger (`GET /api/me/travel-credits/transactions`).
  /// Both must succeed to commit; on failure the prior state is preserved.
  /// [refresh] forces a re-fetch. Zero HTTP in Demo Mode.
  Future<TravelCreditOutcome> loadRealTravelCredit(
      {bool refresh = false}) async {
    if (demoMode) return TravelCreditOutcome.demoUnavailable;
    if (realTravelCreditLoading || realTravelCreditRefreshing) {
      return TravelCreditOutcome.success;
    }
    if (realTravelCreditLoaded && !refresh) return TravelCreditOutcome.success;
    if (refresh) {
      realTravelCreditRefreshing = true;
    } else {
      realTravelCreditLoading = true;
    }
    realTravelCreditError = null;
    notifyListeners();
    final accountResult = await api.getTravelCreditAccount();
    if (!accountResult.success || accountResult.data == null) {
      realTravelCreditLoading = false;
      realTravelCreditRefreshing = false;
      final outcome = _mapTravelCreditError(accountResult.errorKind);
      realTravelCreditError = outcome;
      notifyListeners();
      return outcome;
    }
    final txResult = await api.getTravelCreditTransactions(
        page: 0, size: _travelCreditPageSize);
    realTravelCreditLoading = false;
    realTravelCreditRefreshing = false;
    if (!txResult.success || txResult.data == null) {
      final outcome = _mapTravelCreditError(txResult.errorKind);
      realTravelCreditError = outcome;
      notifyListeners();
      return outcome;
    }
    realTravelCreditAccount = accountResult.data!;
    realTravelCreditTransactions = txResult.data!.content;
    realTravelCreditTxPage = txResult.data!.page;
    realTravelCreditTxTotalPages = txResult.data!.totalPages;
    realTravelCreditLoaded = true;
    realTravelCreditError = null;
    notifyListeners();
    return TravelCreditOutcome.success;
  }

  /// Appends the next page of travel-credit transactions (real backend paging).
  Future<TravelCreditOutcome> loadMoreRealTravelCreditTransactions() async {
    if (demoMode) return TravelCreditOutcome.demoUnavailable;
    if (!realTravelCreditLoaded || realTravelCreditTxLoadingMore) {
      return TravelCreditOutcome.success;
    }
    if (!realTravelCreditTxHasMore) return TravelCreditOutcome.success;
    realTravelCreditTxLoadingMore = true;
    notifyListeners();
    final next = realTravelCreditTxPage + 1;
    final result = await api.getTravelCreditTransactions(
        page: next, size: _travelCreditPageSize);
    realTravelCreditTxLoadingMore = false;
    if (result.success && result.data != null) {
      realTravelCreditTransactions = [
        ...realTravelCreditTransactions,
        ...result.data!.content,
      ];
      realTravelCreditTxPage = result.data!.page;
      realTravelCreditTxTotalPages = result.data!.totalPages;
      notifyListeners();
      return TravelCreditOutcome.success;
    }
    final outcome = _mapTravelCreditError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Membership (UI-36) ─────────────────────────────────────────

  MembershipOutcome _mapMembershipError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => MembershipOutcome.sessionExpired,
      ApiErrorKind.forbidden => MembershipOutcome.forbidden,
      ApiErrorKind.notFound => MembershipOutcome.notFound,
      ApiErrorKind.validation => MembershipOutcome.validation,
      ApiErrorKind.unprocessable => MembershipOutcome.validation,
      ApiErrorKind.network => MembershipOutcome.network,
      ApiErrorKind.timeout => MembershipOutcome.network,
      ApiErrorKind.server => MembershipOutcome.serverError,
      _ => MembershipOutcome.serverError,
    };
  }

  /// Loads the customer's membership surface: live progress + benefits + history
  /// (all always available), plus the membership row (a 404 is tolerated as the
  /// "never enrolled" state, not an error). Commits atomically; on failure the
  /// prior state is preserved. [refresh] forces a re-fetch. Zero HTTP in Demo Mode.
  Future<MembershipOutcome> loadRealMembership({bool refresh = false}) async {
    if (demoMode) return MembershipOutcome.demoUnavailable;
    if (realMembershipLoading || realMembershipRefreshing) {
      return MembershipOutcome.success;
    }
    if (realMembershipLoaded && !refresh) return MembershipOutcome.success;
    if (refresh) {
      realMembershipRefreshing = true;
    } else {
      realMembershipLoading = true;
    }
    realMembershipError = null;
    notifyListeners();

    MembershipOutcome fail(ApiErrorKind? kind) {
      realMembershipLoading = false;
      realMembershipRefreshing = false;
      final outcome = _mapMembershipError(kind);
      realMembershipError = outcome;
      notifyListeners();
      return outcome;
    }

    final progressResult = await api.getMembershipProgress();
    if (!progressResult.success || progressResult.data == null) {
      return fail(progressResult.errorKind);
    }
    // Membership row: 404 = never enrolled (a valid state), any other error fails.
    final membershipResult = await api.getMembership();
    RealMembership? membership;
    var enrolled = false;
    if (membershipResult.success && membershipResult.data != null) {
      membership = membershipResult.data!;
      enrolled = true;
    } else if (membershipResult.errorKind != ApiErrorKind.notFound) {
      return fail(membershipResult.errorKind);
    }
    final benefitsResult = await api.getMembershipBenefits();
    if (!benefitsResult.success || benefitsResult.data == null) {
      return fail(benefitsResult.errorKind);
    }
    final historyResult = await api.getMembershipHistory();
    if (!historyResult.success || historyResult.data == null) {
      return fail(historyResult.errorKind);
    }

    realMembershipLoading = false;
    realMembershipRefreshing = false;
    realMembershipProgress = progressResult.data!;
    realMembership = membership;
    realMembershipEnrolled = enrolled;
    realMembershipBenefits = benefitsResult.data!;
    realMembershipHistory = historyResult.data!;
    realMembershipLoaded = true;
    realMembershipError = null;
    notifyListeners();
    return MembershipOutcome.success;
  }

  /// Enrolls the customer in membership (`POST /api/me/membership/enroll`,
  /// idempotent). On success reloads the membership surface. A 400 (no active
  /// loyalty account) surfaces as [MembershipOutcome.validation].
  Future<MembershipOutcome> enrollRealMembership() async {
    if (demoMode) return MembershipOutcome.demoUnavailable;
    if (realMembershipEnrolling) return MembershipOutcome.busy;
    realMembershipEnrolling = true;
    notifyListeners();
    final result = await api.enrollMembership();
    realMembershipEnrolling = false;
    if (result.success && result.data != null) {
      realMembership = result.data!;
      realMembershipEnrolled = true;
      notifyListeners();
      await loadRealMembership(refresh: true);
      return MembershipOutcome.success;
    }
    final outcome = _mapMembershipError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Referral (UI-37) ───────────────────────────────────────────

  ReferralOutcome _mapReferralError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => ReferralOutcome.sessionExpired,
      ApiErrorKind.forbidden => ReferralOutcome.forbidden,
      ApiErrorKind.notFound => ReferralOutcome.notFound,
      ApiErrorKind.conflict => ReferralOutcome.conflict,
      ApiErrorKind.validation => ReferralOutcome.validation,
      ApiErrorKind.unprocessable => ReferralOutcome.validation,
      ApiErrorKind.network => ReferralOutcome.network,
      ApiErrorKind.timeout => ReferralOutcome.network,
      ApiErrorKind.server => ReferralOutcome.serverError,
      _ => ReferralOutcome.serverError,
    };
  }

  /// Loads the referral code + stats (`GET /api/me/referral`) plus the activity
  /// history (`GET /api/me/referral/history`). Both must succeed to commit; on
  /// failure the prior state is preserved. [refresh] forces a re-fetch. Zero HTTP
  /// in Demo Mode.
  Future<ReferralOutcome> loadRealReferral({bool refresh = false}) async {
    if (demoMode) return ReferralOutcome.demoUnavailable;
    if (realReferralLoading || realReferralRefreshing) {
      return ReferralOutcome.success;
    }
    if (realReferralLoaded && !refresh) return ReferralOutcome.success;
    if (refresh) {
      realReferralRefreshing = true;
    } else {
      realReferralLoading = true;
    }
    realReferralError = null;
    notifyListeners();
    final summaryResult = await api.getReferral();
    if (!summaryResult.success || summaryResult.data == null) {
      realReferralLoading = false;
      realReferralRefreshing = false;
      final outcome = _mapReferralError(summaryResult.errorKind);
      realReferralError = outcome;
      notifyListeners();
      return outcome;
    }
    final historyResult = await api.getReferralHistory();
    realReferralLoading = false;
    realReferralRefreshing = false;
    if (!historyResult.success || historyResult.data == null) {
      final outcome = _mapReferralError(historyResult.errorKind);
      realReferralError = outcome;
      notifyListeners();
      return outcome;
    }
    realReferralSummary = summaryResult.data!;
    realReferralHistory = historyResult.data!;
    realReferralLoaded = true;
    realReferralError = null;
    notifyListeners();
    return ReferralOutcome.success;
  }

  /// Uses another user's referral code (`POST /api/me/referral/use`). On success
  /// reloads the surface (stats + history change). A 400 (own code) maps to
  /// [ReferralOutcome.validation], 404 to [ReferralOutcome.notFound], 409 (already
  /// used) to [ReferralOutcome.conflict]. Single-flight via [realReferralUsing].
  Future<ReferralOutcome> useRealReferralCode(String code) async {
    if (demoMode) return ReferralOutcome.demoUnavailable;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return ReferralOutcome.validation;
    if (realReferralUsing) return ReferralOutcome.busy;
    realReferralUsing = true;
    notifyListeners();
    final result = await api.useReferralCode(trimmed);
    realReferralUsing = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealReferral(refresh: true);
      return ReferralOutcome.success;
    }
    final outcome = _mapReferralError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Coupons (UI-38) ────────────────────────────────────────────

  CouponOutcome _mapCouponError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => CouponOutcome.sessionExpired,
      ApiErrorKind.forbidden => CouponOutcome.forbidden,
      ApiErrorKind.notFound => CouponOutcome.notFound,
      ApiErrorKind.conflict => CouponOutcome.conflict,
      ApiErrorKind.validation => CouponOutcome.validation,
      ApiErrorKind.unprocessable => CouponOutcome.validation,
      ApiErrorKind.network => CouponOutcome.network,
      ApiErrorKind.timeout => CouponOutcome.network,
      ApiErrorKind.server => CouponOutcome.serverError,
      _ => CouponOutcome.serverError,
    };
  }

  /// Loads the customer's claimed coupons (`GET /api/me/coupons`). [refresh]
  /// forces a re-fetch and preserves the current list on failure. Zero HTTP in
  /// Demo Mode.
  Future<CouponOutcome> loadRealCoupons({bool refresh = false}) async {
    if (demoMode) return CouponOutcome.demoUnavailable;
    if (realCouponsLoading || realCouponsRefreshing) {
      return CouponOutcome.success;
    }
    if (realCouponsLoaded && !refresh) return CouponOutcome.success;
    if (refresh) {
      realCouponsRefreshing = true;
    } else {
      realCouponsLoading = true;
    }
    realCouponsError = null;
    notifyListeners();
    final result = await api.getCoupons();
    realCouponsLoading = false;
    realCouponsRefreshing = false;
    if (result.success && result.data != null) {
      realCoupons = result.data!;
      realCouponsLoaded = true;
      realCouponsError = null;
      notifyListeners();
      return CouponOutcome.success;
    }
    final outcome = _mapCouponError(result.errorKind);
    realCouponsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Loads one coupon's detail (`GET /api/me/coupons/{id}`), cached.
  Future<CouponOutcome> loadRealCouponDetail(int id,
      {bool refresh = false}) async {
    if (demoMode) return CouponOutcome.demoUnavailable;
    if (couponDetailLoadingId == id) return CouponOutcome.success;
    if (couponDetailCache.containsKey(id) && !refresh) {
      return CouponOutcome.success;
    }
    couponDetailLoadingId = id;
    couponDetailError = null;
    notifyListeners();
    final result = await api.getCoupon(id);
    couponDetailLoadingId = null;
    if (result.success && result.data != null) {
      couponDetailCache[id] = result.data!;
      couponDetailError = null;
      notifyListeners();
      return CouponOutcome.success;
    }
    final outcome = _mapCouponError(result.errorKind);
    couponDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Claims a coupon by code (`POST /api/me/coupons/claim`). On success refreshes
  /// the list so the claimed coupon appears. Maps 400→validation (inactive/
  /// expired/not-yet-valid), 404→notFound (unknown code), 409→conflict (usage
  /// limit reached). Single-flight via [realCouponsClaiming].
  Future<CouponOutcome> claimRealCoupon(String code) async {
    if (demoMode) return CouponOutcome.demoUnavailable;
    final trimmed = code.trim();
    if (trimmed.isEmpty) return CouponOutcome.validation;
    if (realCouponsClaiming) return CouponOutcome.busy;
    realCouponsClaiming = true;
    notifyListeners();
    final result = await api.claimCoupon(trimmed);
    realCouponsClaiming = false;
    if (result.success && result.data != null) {
      couponDetailCache[result.data!.id] = result.data!;
      notifyListeners();
      await loadRealCoupons(refresh: true);
      return CouponOutcome.success;
    }
    final outcome = _mapCouponError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Recommendations (UI-39) ────────────────────────────────────

  static const int _recommendationsPageSize = 20;

  RecommendationOutcome _mapRecommendationError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => RecommendationOutcome.sessionExpired,
      ApiErrorKind.forbidden => RecommendationOutcome.forbidden,
      ApiErrorKind.notFound => RecommendationOutcome.notFound,
      ApiErrorKind.network => RecommendationOutcome.network,
      ApiErrorKind.timeout => RecommendationOutcome.network,
      ApiErrorKind.server => RecommendationOutcome.serverError,
      _ => RecommendationOutcome.serverError,
    };
  }

  /// Loads the customer's active recommendation feed
  /// (`GET /api/me/recommendations`, page 0). [refresh] forces a re-fetch and
  /// preserves the current list on failure. Zero HTTP in Demo Mode.
  Future<RecommendationOutcome> loadRealRecommendations({
    bool refresh = false,
  }) async {
    if (demoMode) return RecommendationOutcome.demoUnavailable;
    if (realRecommendationsLoading || realRecommendationsRefreshing) {
      return RecommendationOutcome.success;
    }
    if (realRecommendationsLoaded && !refresh) {
      return RecommendationOutcome.success;
    }
    if (refresh) {
      realRecommendationsRefreshing = true;
    } else {
      realRecommendationsLoading = true;
    }
    realRecommendationsError = null;
    notifyListeners();
    final result = await api.getRecommendations(
      page: 0,
      size: _recommendationsPageSize,
    );
    realRecommendationsLoading = false;
    realRecommendationsRefreshing = false;
    if (result.success && result.data != null) {
      realRecommendations = result.data!.content;
      realRecommendationsPage = result.data!.page;
      realRecommendationsTotalPages = result.data!.totalPages;
      realRecommendationsLoaded = true;
      realRecommendationsError = null;
      notifyListeners();
      return RecommendationOutcome.success;
    }
    final outcome = _mapRecommendationError(result.errorKind);
    realRecommendationsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Appends the next page of recommendations (`GET ...?page=n+1`).
  Future<RecommendationOutcome> loadMoreRealRecommendations() async {
    if (demoMode) return RecommendationOutcome.demoUnavailable;
    if (!realRecommendationsLoaded || realRecommendationsLoadingMore) {
      return RecommendationOutcome.success;
    }
    if (!realRecommendationsHasMore) return RecommendationOutcome.success;
    realRecommendationsLoadingMore = true;
    notifyListeners();
    final next = realRecommendationsPage + 1;
    final result = await api.getRecommendations(
      page: next,
      size: _recommendationsPageSize,
    );
    realRecommendationsLoadingMore = false;
    if (result.success && result.data != null) {
      realRecommendations = [
        ...realRecommendations,
        ...result.data!.content,
      ];
      realRecommendationsPage = result.data!.page;
      realRecommendationsTotalPages = result.data!.totalPages;
      notifyListeners();
      return RecommendationOutcome.success;
    }
    final outcome = _mapRecommendationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Loads one recommendation's detail (`GET /api/me/recommendations/{id}`),
  /// cached. Zero HTTP in Demo Mode.
  Future<RecommendationOutcome> loadRealRecommendationDetail(
    int id, {
    bool refresh = false,
  }) async {
    if (demoMode) return RecommendationOutcome.demoUnavailable;
    if (recommendationDetailLoadingId == id) {
      return RecommendationOutcome.success;
    }
    if (recommendationDetailCache.containsKey(id) && !refresh) {
      return RecommendationOutcome.success;
    }
    recommendationDetailLoadingId = id;
    recommendationDetailError = null;
    notifyListeners();
    final result = await api.getRecommendation(id);
    recommendationDetailLoadingId = null;
    if (result.success && result.data != null) {
      recommendationDetailCache[id] = result.data!;
      recommendationDetailError = null;
      notifyListeners();
      return RecommendationOutcome.success;
    }
    final outcome = _mapRecommendationError(result.errorKind);
    recommendationDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Regenerates the active recommendation set
  /// (`POST /api/me/recommendations/generate`) and reloads the feed. Read-only
  /// snapshots — nothing is claimed or reserved. Single-flight via
  /// [realRecommendationsGenerating]. Zero HTTP in Demo Mode.
  Future<RecommendationOutcome> generateRealRecommendations() async {
    if (demoMode) return RecommendationOutcome.demoUnavailable;
    if (realRecommendationsGenerating) return RecommendationOutcome.busy;
    realRecommendationsGenerating = true;
    notifyListeners();
    final result = await api.generateRecommendations();
    realRecommendationsGenerating = false;
    if (result.success) {
      notifyListeners();
      await loadRealRecommendations(refresh: true);
      return RecommendationOutcome.success;
    }
    final outcome = _mapRecommendationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Dismisses a recommendation (`PATCH /api/me/recommendations/{id}/dismiss`)
  /// and removes it from the local feed only after the server confirms. Per-id
  /// single-flight via [recommendationActionInFlight]. Zero HTTP in Demo Mode.
  Future<RecommendationOutcome> dismissRealRecommendation(int id) async {
    if (demoMode) return RecommendationOutcome.demoUnavailable;
    if (recommendationActionInFlight.contains(id)) {
      return RecommendationOutcome.busy;
    }
    recommendationActionInFlight.add(id);
    notifyListeners();
    final result = await api.dismissRecommendation(id);
    recommendationActionInFlight.remove(id);
    if (result.success && result.data != null) {
      realRecommendations =
          realRecommendations.where((r) => r.id != id).toList();
      recommendationDetailCache[id] = result.data!;
      notifyListeners();
      return RecommendationOutcome.success;
    }
    final outcome = _mapRecommendationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Tracks a click on a recommendation
  /// (`PATCH /api/me/recommendations/{id}/click`, idempotent). Best-effort — the
  /// updated snapshot is merged into the local feed/cache, but a failure is
  /// returned, not surfaced as an error state. Zero HTTP in Demo Mode.
  Future<RecommendationOutcome> trackRealRecommendationClick(int id) async {
    if (demoMode) return RecommendationOutcome.demoUnavailable;
    if (recommendationActionInFlight.contains(id)) {
      return RecommendationOutcome.busy;
    }
    recommendationActionInFlight.add(id);
    final result = await api.clickRecommendation(id);
    recommendationActionInFlight.remove(id);
    if (result.success && result.data != null) {
      final updated = result.data!;
      recommendationDetailCache[id] = updated;
      realRecommendations = [
        for (final r in realRecommendations) r.id == id ? updated : r,
      ];
      notifyListeners();
      return RecommendationOutcome.success;
    }
    return _mapRecommendationError(result.errorKind);
  }

  // ── Real Mode Trip Expenses (UI-40) ──────────────────────────────────────

  ExpenseOutcome _mapExpenseError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => ExpenseOutcome.sessionExpired,
      ApiErrorKind.forbidden => ExpenseOutcome.forbidden,
      ApiErrorKind.notFound => ExpenseOutcome.notFound,
      ApiErrorKind.validation => ExpenseOutcome.validation,
      ApiErrorKind.unprocessable => ExpenseOutcome.validation,
      ApiErrorKind.network => ExpenseOutcome.network,
      ApiErrorKind.timeout => ExpenseOutcome.network,
      ApiErrorKind.server => ExpenseOutcome.serverError,
      _ => ExpenseOutcome.serverError,
    };
  }

  /// Loads a trip's expenses (`GET .../expenses`) plus the server-computed budget
  /// summary (best-effort). Switching [tripId] reloads. [refresh] forces a
  /// re-fetch and preserves the current list on failure. Zero HTTP in Demo Mode.
  Future<ExpenseOutcome> loadRealExpenses(int tripId,
      {bool refresh = false}) async {
    if (demoMode) return ExpenseOutcome.demoUnavailable;
    if (realExpensesLoading || realExpensesRefreshing) {
      return ExpenseOutcome.success;
    }
    final sameTrip = realExpensesTripId == tripId;
    if (sameTrip && realExpensesLoaded && !refresh) {
      return ExpenseOutcome.success;
    }
    if (sameTrip && refresh) {
      realExpensesRefreshing = true;
    } else {
      realExpensesLoading = true;
      if (!sameTrip) {
        // Switching trips: drop the previous trip's data immediately.
        realExpenses = [];
        realExpenseSummary = null;
        realExpensesLoaded = false;
        realExpensesTripId = tripId;
      }
    }
    realExpensesError = null;
    notifyListeners();

    final listResult = await api.getTripExpenses(tripId);
    if (!(listResult.success && listResult.data != null)) {
      realExpensesLoading = false;
      realExpensesRefreshing = false;
      final outcome = _mapExpenseError(listResult.errorKind);
      realExpensesError = outcome;
      notifyListeners();
      return outcome;
    }
    // Summary is secondary context — a failure leaves it null, not an error.
    final summaryResult = await api.getTripBudgetSummary(tripId);
    realExpensesLoading = false;
    realExpensesRefreshing = false;
    realExpensesTripId = tripId;
    realExpenses = listResult.data!;
    realExpenseSummary = (summaryResult.success && summaryResult.data != null)
        ? summaryResult.data
        : null;
    realExpensesLoaded = true;
    realExpensesError = null;
    notifyListeners();
    return ExpenseOutcome.success;
  }

  /// Adds an expense to [tripId] (`POST .../expenses`) and reloads the trip's
  /// expenses + summary from the backend (no optimistic insert). Single-flight
  /// via [realExpenseMutationInFlight]. Zero HTTP in Demo Mode.
  Future<ExpenseOutcome> createRealExpense(
      int tripId, RealExpensePayload payload) async {
    if (demoMode) return ExpenseOutcome.demoUnavailable;
    if (realExpenseMutationInFlight) return ExpenseOutcome.busy;
    realExpenseMutationInFlight = true;
    notifyListeners();
    final result = await api.createTripExpense(tripId, payload);
    realExpenseMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealExpenses(tripId, refresh: true);
      return ExpenseOutcome.success;
    }
    final outcome = _mapExpenseError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates an expense (`PUT .../expenses/{expenseId}`) and reloads [tripId]'s
  /// expenses + summary. No optimistic mutation. Zero HTTP in Demo Mode.
  Future<ExpenseOutcome> updateRealExpense(
      int tripId, int expenseId, RealExpensePayload payload) async {
    if (demoMode) return ExpenseOutcome.demoUnavailable;
    if (realExpenseMutationInFlight) return ExpenseOutcome.busy;
    realExpenseMutationInFlight = true;
    notifyListeners();
    final result = await api.updateTripExpense(expenseId, payload);
    realExpenseMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealExpenses(tripId, refresh: true);
      return ExpenseOutcome.success;
    }
    final outcome = _mapExpenseError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes an expense (`DELETE .../expenses/{expenseId}`) and reloads [tripId]'s
  /// expenses + summary only after the server confirms. Zero HTTP in Demo Mode.
  Future<ExpenseOutcome> deleteRealExpense(int tripId, int expenseId) async {
    if (demoMode) return ExpenseOutcome.demoUnavailable;
    if (realExpenseMutationInFlight) return ExpenseOutcome.busy;
    realExpenseMutationInFlight = true;
    notifyListeners();
    final result = await api.deleteTripExpense(expenseId);
    realExpenseMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealExpenses(tripId, refresh: true);
      return ExpenseOutcome.success;
    }
    final outcome = _mapExpenseError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Conversations (UI-41) ──────────────────────────────────────

  ConversationOutcome _mapConversationError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => ConversationOutcome.sessionExpired,
      ApiErrorKind.forbidden => ConversationOutcome.forbidden,
      ApiErrorKind.notFound => ConversationOutcome.notFound,
      ApiErrorKind.validation => ConversationOutcome.validation,
      ApiErrorKind.unprocessable => ConversationOutcome.unprocessable,
      ApiErrorKind.network => ConversationOutcome.network,
      ApiErrorKind.timeout => ConversationOutcome.network,
      ApiErrorKind.server => ConversationOutcome.serverError,
      _ => ConversationOutcome.serverError,
    };
  }

  /// Loads the user's conversation inbox (`GET /api/me/conversations`). [refresh]
  /// forces a re-fetch and preserves the current list on failure. Zero HTTP in
  /// Demo Mode.
  Future<ConversationOutcome> loadRealConversations({
    bool refresh = false,
  }) async {
    if (demoMode) return ConversationOutcome.demoUnavailable;
    if (realConversationsLoading || realConversationsRefreshing) {
      return ConversationOutcome.success;
    }
    if (realConversationsLoaded && !refresh) {
      return ConversationOutcome.success;
    }
    if (refresh) {
      realConversationsRefreshing = true;
    } else {
      realConversationsLoading = true;
    }
    realConversationsError = null;
    notifyListeners();
    final result = await api.getConversations();
    realConversationsLoading = false;
    realConversationsRefreshing = false;
    if (result.success && result.data != null) {
      realConversations = result.data!;
      realConversationsLoaded = true;
      realConversationsError = null;
      notifyListeners();
      return ConversationOutcome.success;
    }
    final outcome = _mapConversationError(result.errorKind);
    realConversationsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Loads one conversation thread (`GET /api/me/conversations/{id}`). Switching
  /// [conversationId] reloads. Zero HTTP in Demo Mode.
  Future<ConversationOutcome> loadRealConversationDetail(
    int conversationId, {
    bool refresh = false,
  }) async {
    if (demoMode) return ConversationOutcome.demoUnavailable;
    if (realConversationDetailLoading) return ConversationOutcome.success;
    final same = realConversationDetailId == conversationId;
    if (same && realConversationDetail != null && !refresh) {
      return ConversationOutcome.success;
    }
    realConversationDetailLoading = true;
    if (!same) {
      realConversationDetail = null;
      realConversationDetailId = conversationId;
    }
    realConversationDetailError = null;
    notifyListeners();
    final result = await api.getConversation(conversationId);
    realConversationDetailLoading = false;
    if (result.success && result.data != null) {
      realConversationDetailId = conversationId;
      realConversationDetail = result.data;
      realConversationDetailError = null;
      notifyListeners();
      return ConversationOutcome.success;
    }
    final outcome = _mapConversationError(result.errorKind);
    realConversationDetailError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Marks a thread's incoming messages read (`PATCH .../read`) and refreshes the
  /// inbox so unread counts update. Best-effort — a failure is returned, not
  /// surfaced as an error state. Zero HTTP in Demo Mode.
  Future<ConversationOutcome> markRealConversationRead(
    int conversationId,
  ) async {
    if (demoMode) return ConversationOutcome.demoUnavailable;
    final result = await api.markConversationRead(conversationId);
    if (result.success && result.data != null) {
      if (realConversationDetailId == conversationId) {
        realConversationDetail = result.data;
      }
      notifyListeners();
      if (realConversationsLoaded) {
        await loadRealConversations(refresh: true);
      }
      return ConversationOutcome.success;
    }
    return _mapConversationError(result.errorKind);
  }

  /// Sends a guest message (`POST .../messages`) and reloads the thread + inbox
  /// from the backend (no optimistic insert). Single-flight via
  /// [realConversationSending]. Zero HTTP in Demo Mode.
  Future<ConversationOutcome> sendRealMessage(
    int conversationId,
    String body,
  ) async {
    if (demoMode) return ConversationOutcome.demoUnavailable;
    final trimmed = body.trim();
    if (trimmed.isEmpty) return ConversationOutcome.validation;
    if (realConversationSending) return ConversationOutcome.busy;
    realConversationSending = true;
    notifyListeners();
    final result = await api.sendConversationMessage(conversationId, trimmed);
    realConversationSending = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealConversationDetail(conversationId, refresh: true);
      if (realConversationsLoaded) {
        await loadRealConversations(refresh: true);
      }
      return ConversationOutcome.success;
    }
    final outcome = _mapConversationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Closes a conversation (`PATCH .../close`) and updates the thread + inbox.
  /// Single-flight via [realConversationMutating]. Zero HTTP in Demo Mode.
  Future<ConversationOutcome> closeRealConversation(int conversationId) async {
    if (demoMode) return ConversationOutcome.demoUnavailable;
    if (realConversationMutating) return ConversationOutcome.busy;
    realConversationMutating = true;
    notifyListeners();
    final result = await api.closeConversation(conversationId);
    realConversationMutating = false;
    if (result.success && result.data != null) {
      if (realConversationDetailId == conversationId) {
        realConversationDetail = result.data;
      }
      notifyListeners();
      if (realConversationsLoaded) {
        await loadRealConversations(refresh: true);
      }
      return ConversationOutcome.success;
    }
    final outcome = _mapConversationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Starts (or reuses) a conversation for a booking (`POST /api/me/conversations`).
  /// On success stores it as the active thread ([realConversationDetailId] carries
  /// the new/reused id for navigation) and refreshes the inbox. Single-flight via
  /// [realConversationMutating]. Zero HTTP in Demo Mode.
  Future<ConversationOutcome> createRealConversation(
    int bookingId, {
    String? subject,
  }) async {
    if (demoMode) return ConversationOutcome.demoUnavailable;
    if (realConversationMutating) return ConversationOutcome.busy;
    realConversationMutating = true;
    notifyListeners();
    final result = await api.createConversation(bookingId, subject: subject);
    realConversationMutating = false;
    if (result.success && result.data != null) {
      realConversationDetail = result.data;
      realConversationDetailId = result.data!.id;
      realConversationDetailError = null;
      notifyListeners();
      if (realConversationsLoaded) {
        await loadRealConversations(refresh: true);
      }
      return ConversationOutcome.success;
    }
    final outcome = _mapConversationError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode AI Context (UI-42) ─────────────────────────────────────────

  AiContextOutcome _mapAiContextError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => AiContextOutcome.sessionExpired,
      ApiErrorKind.forbidden => AiContextOutcome.forbidden,
      ApiErrorKind.notFound => AiContextOutcome.notFound,
      ApiErrorKind.network => AiContextOutcome.network,
      ApiErrorKind.timeout => AiContextOutcome.network,
      ApiErrorKind.server => AiContextOutcome.serverError,
      _ => AiContextOutcome.serverError,
    };
  }

  /// Loads the user's aggregated AI trip context (`GET /api/me/ai/context`).
  /// [refresh] forces a re-fetch and preserves the current snapshot on failure.
  /// Zero HTTP in Demo Mode.
  Future<AiContextOutcome> loadRealAiContext({bool refresh = false}) async {
    if (demoMode) return AiContextOutcome.demoUnavailable;
    if (realAiContextLoading || realAiContextRefreshing) {
      return AiContextOutcome.success;
    }
    if (realAiContextLoaded && !refresh) return AiContextOutcome.success;
    if (refresh) {
      realAiContextRefreshing = true;
    } else {
      realAiContextLoading = true;
    }
    realAiContextError = null;
    notifyListeners();
    final result = await api.getAiContext();
    realAiContextLoading = false;
    realAiContextRefreshing = false;
    if (result.success && result.data != null) {
      realAiContext = result.data;
      realAiContextLoaded = true;
      realAiContextError = null;
      notifyListeners();
      return AiContextOutcome.success;
    }
    final outcome = _mapAiContextError(result.errorKind);
    realAiContextError = outcome;
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Trip Documents (UI-43) ─────────────────────────────────────

  DocumentOutcome _mapDocumentError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => DocumentOutcome.sessionExpired,
      ApiErrorKind.forbidden => DocumentOutcome.forbidden,
      ApiErrorKind.notFound => DocumentOutcome.notFound,
      ApiErrorKind.validation => DocumentOutcome.validation,
      ApiErrorKind.unprocessable => DocumentOutcome.validation,
      ApiErrorKind.network => DocumentOutcome.network,
      ApiErrorKind.timeout => DocumentOutcome.network,
      ApiErrorKind.server => DocumentOutcome.serverError,
      _ => DocumentOutcome.serverError,
    };
  }

  /// Loads a trip's documents (`GET .../documents`, pinned first then newest).
  /// Switching [tripId] reloads. [refresh] forces a re-fetch and preserves the
  /// current list on failure. Zero HTTP in Demo Mode.
  Future<DocumentOutcome> loadRealDocuments(int tripId,
      {bool refresh = false}) async {
    if (demoMode) return DocumentOutcome.demoUnavailable;
    if (realDocumentsLoading || realDocumentsRefreshing) {
      return DocumentOutcome.success;
    }
    final sameTrip = realDocumentsTripId == tripId;
    if (sameTrip && realDocumentsLoaded && !refresh) {
      return DocumentOutcome.success;
    }
    if (sameTrip && refresh) {
      realDocumentsRefreshing = true;
    } else {
      realDocumentsLoading = true;
      if (!sameTrip) {
        realDocuments = [];
        realDocumentsLoaded = false;
        realDocumentsTripId = tripId;
      }
    }
    realDocumentsError = null;
    notifyListeners();
    final result = await api.getTripDocuments(tripId);
    realDocumentsLoading = false;
    realDocumentsRefreshing = false;
    if (result.success && result.data != null) {
      realDocumentsTripId = tripId;
      realDocuments = result.data!;
      realDocumentsLoaded = true;
      realDocumentsError = null;
      notifyListeners();
      return DocumentOutcome.success;
    }
    final outcome = _mapDocumentError(result.errorKind);
    realDocumentsError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Attaches a document to [tripId] (`POST .../documents`) and reloads the trip's
  /// documents from the backend (no optimistic insert). Single-flight via
  /// [realDocumentMutationInFlight]. Zero HTTP in Demo Mode.
  Future<DocumentOutcome> createRealDocument(
      int tripId, RealTripDocumentPayload payload) async {
    if (demoMode) return DocumentOutcome.demoUnavailable;
    if (realDocumentMutationInFlight) return DocumentOutcome.busy;
    realDocumentMutationInFlight = true;
    notifyListeners();
    final result = await api.createTripDocument(tripId, payload);
    realDocumentMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealDocuments(tripId, refresh: true);
      return DocumentOutcome.success;
    }
    final outcome = _mapDocumentError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates a document's metadata (`PUT .../documents/{id}`) and reloads
  /// [tripId]'s documents. No optimistic mutation. Zero HTTP in Demo Mode.
  Future<DocumentOutcome> updateRealDocument(
      int tripId, int documentId, RealTripDocumentPayload payload) async {
    if (demoMode) return DocumentOutcome.demoUnavailable;
    if (realDocumentMutationInFlight) return DocumentOutcome.busy;
    realDocumentMutationInFlight = true;
    notifyListeners();
    final result = await api.updateTripDocument(documentId, payload);
    realDocumentMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealDocuments(tripId, refresh: true);
      return DocumentOutcome.success;
    }
    final outcome = _mapDocumentError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes a document (`DELETE .../documents/{id}`) and reloads [tripId]'s
  /// documents only after the server confirms. Zero HTTP in Demo Mode.
  Future<DocumentOutcome> deleteRealDocument(int tripId, int documentId) async {
    if (demoMode) return DocumentOutcome.demoUnavailable;
    if (realDocumentMutationInFlight) return DocumentOutcome.busy;
    realDocumentMutationInFlight = true;
    notifyListeners();
    final result = await api.deleteTripDocument(documentId);
    realDocumentMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealDocuments(tripId, refresh: true);
      return DocumentOutcome.success;
    }
    final outcome = _mapDocumentError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Pins or unpins a document (`PATCH .../documents/{id}/pin|unpin`) and reloads
  /// [tripId]'s documents so ordering updates. No optimistic mutation. Zero HTTP
  /// in Demo Mode.
  Future<DocumentOutcome> setRealDocumentPinned(
      int tripId, int documentId, bool pinned) async {
    if (demoMode) return DocumentOutcome.demoUnavailable;
    if (realDocumentMutationInFlight) return DocumentOutcome.busy;
    realDocumentMutationInFlight = true;
    notifyListeners();
    final result = pinned
        ? await api.pinTripDocument(documentId)
        : await api.unpinTripDocument(documentId);
    realDocumentMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealDocuments(tripId, refresh: true);
      return DocumentOutcome.success;
    }
    final outcome = _mapDocumentError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Trip Notes (UI-44) ─────────────────────────────────────────

  NoteOutcome _mapNoteError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => NoteOutcome.sessionExpired,
      ApiErrorKind.forbidden => NoteOutcome.forbidden,
      ApiErrorKind.notFound => NoteOutcome.notFound,
      ApiErrorKind.validation => NoteOutcome.validation,
      ApiErrorKind.unprocessable => NoteOutcome.validation,
      ApiErrorKind.network => NoteOutcome.network,
      ApiErrorKind.timeout => NoteOutcome.network,
      ApiErrorKind.server => NoteOutcome.serverError,
      _ => NoteOutcome.serverError,
    };
  }

  /// Loads a trip's notes (`GET .../notes`, pinned first then newest updated).
  /// Switching [tripId] reloads. [refresh] forces a re-fetch and preserves the
  /// current list on failure. Zero HTTP in Demo Mode.
  Future<NoteOutcome> loadRealNotes(int tripId, {bool refresh = false}) async {
    if (demoMode) return NoteOutcome.demoUnavailable;
    if (realNotesLoading || realNotesRefreshing) return NoteOutcome.success;
    final sameTrip = realNotesTripId == tripId;
    if (sameTrip && realNotesLoaded && !refresh) return NoteOutcome.success;
    if (sameTrip && refresh) {
      realNotesRefreshing = true;
    } else {
      realNotesLoading = true;
      if (!sameTrip) {
        realNotes = [];
        realNotesLoaded = false;
        realNotesTripId = tripId;
      }
    }
    realNotesError = null;
    notifyListeners();
    final result = await api.getTripNotes(tripId);
    realNotesLoading = false;
    realNotesRefreshing = false;
    if (result.success && result.data != null) {
      realNotesTripId = tripId;
      realNotes = result.data!;
      realNotesLoaded = true;
      realNotesError = null;
      notifyListeners();
      return NoteOutcome.success;
    }
    final outcome = _mapNoteError(result.errorKind);
    realNotesError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Adds a note to [tripId] (`POST .../notes`) and reloads the trip's notes from
  /// the backend (no optimistic insert). Blank content is rejected client-side
  /// (the backend requires it). Single-flight via [realNoteMutationInFlight].
  /// Zero HTTP in Demo Mode.
  Future<NoteOutcome> createRealNote(
      int tripId, RealTripNotePayload payload) async {
    if (demoMode) return NoteOutcome.demoUnavailable;
    if (payload.content.trim().isEmpty) return NoteOutcome.validation;
    if (realNoteMutationInFlight) return NoteOutcome.busy;
    realNoteMutationInFlight = true;
    notifyListeners();
    final result = await api.createTripNote(tripId, payload);
    realNoteMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealNotes(tripId, refresh: true);
      return NoteOutcome.success;
    }
    final outcome = _mapNoteError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates a note (`PUT .../notes/{id}`) and reloads [tripId]'s notes. Blank
  /// content is rejected client-side. No optimistic mutation. Zero HTTP in Demo
  /// Mode.
  Future<NoteOutcome> updateRealNote(
      int tripId, int noteId, RealTripNotePayload payload) async {
    if (demoMode) return NoteOutcome.demoUnavailable;
    if (payload.content.trim().isEmpty) return NoteOutcome.validation;
    if (realNoteMutationInFlight) return NoteOutcome.busy;
    realNoteMutationInFlight = true;
    notifyListeners();
    final result = await api.updateTripNote(noteId, payload);
    realNoteMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealNotes(tripId, refresh: true);
      return NoteOutcome.success;
    }
    final outcome = _mapNoteError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes a note (`DELETE .../notes/{id}`) and reloads [tripId]'s notes only
  /// after the server confirms. Zero HTTP in Demo Mode.
  Future<NoteOutcome> deleteRealNote(int tripId, int noteId) async {
    if (demoMode) return NoteOutcome.demoUnavailable;
    if (realNoteMutationInFlight) return NoteOutcome.busy;
    realNoteMutationInFlight = true;
    notifyListeners();
    final result = await api.deleteTripNote(noteId);
    realNoteMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealNotes(tripId, refresh: true);
      return NoteOutcome.success;
    }
    final outcome = _mapNoteError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Pins or unpins a note (`PATCH .../notes/{id}/pin|unpin`) and reloads
  /// [tripId]'s notes so ordering updates. No optimistic mutation. Zero HTTP in
  /// Demo Mode.
  Future<NoteOutcome> setRealNotePinned(
      int tripId, int noteId, bool pinned) async {
    if (demoMode) return NoteOutcome.demoUnavailable;
    if (realNoteMutationInFlight) return NoteOutcome.busy;
    realNoteMutationInFlight = true;
    notifyListeners();
    final result = pinned
        ? await api.pinTripNote(noteId)
        : await api.unpinTripNote(noteId);
    realNoteMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealNotes(tripId, refresh: true);
      return NoteOutcome.success;
    }
    final outcome = _mapNoteError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Trip Packing (UI-45) ───────────────────────────────────────

  PackingOutcome _mapPackingError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => PackingOutcome.sessionExpired,
      ApiErrorKind.forbidden => PackingOutcome.forbidden,
      ApiErrorKind.notFound => PackingOutcome.notFound,
      ApiErrorKind.validation => PackingOutcome.validation,
      ApiErrorKind.unprocessable => PackingOutcome.validation,
      ApiErrorKind.network => PackingOutcome.network,
      ApiErrorKind.timeout => PackingOutcome.network,
      ApiErrorKind.server => PackingOutcome.serverError,
      _ => PackingOutcome.serverError,
    };
  }

  /// Loads a trip's packing checklist (`GET .../packing`, unchecked first then by
  /// order). Switching [tripId] reloads. [refresh] forces a re-fetch and
  /// preserves the current list on failure. Zero HTTP in Demo Mode.
  Future<PackingOutcome> loadRealPacking(int tripId,
      {bool refresh = false}) async {
    if (demoMode) return PackingOutcome.demoUnavailable;
    if (realPackingLoading || realPackingRefreshing) {
      return PackingOutcome.success;
    }
    final sameTrip = realPackingTripId == tripId;
    if (sameTrip && realPackingLoaded && !refresh) {
      return PackingOutcome.success;
    }
    if (sameTrip && refresh) {
      realPackingRefreshing = true;
    } else {
      realPackingLoading = true;
      if (!sameTrip) {
        realPackingItems = [];
        realPackingLoaded = false;
        realPackingTripId = tripId;
      }
    }
    realPackingError = null;
    notifyListeners();
    final result = await api.getPackingItems(tripId);
    realPackingLoading = false;
    realPackingRefreshing = false;
    if (result.success && result.data != null) {
      realPackingTripId = tripId;
      realPackingItems = result.data!;
      realPackingLoaded = true;
      realPackingError = null;
      notifyListeners();
      return PackingOutcome.success;
    }
    final outcome = _mapPackingError(result.errorKind);
    realPackingError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Adds a packing item to [tripId] (`POST .../packing`) and reloads the trip's
  /// checklist from the backend (no optimistic insert). Blank label / quantity
  /// < 1 are rejected client-side (the backend requires them). Single-flight via
  /// [realPackingMutationInFlight]. Zero HTTP in Demo Mode.
  Future<PackingOutcome> createRealPackingItem(
      int tripId, RealPackingItemPayload payload) async {
    if (demoMode) return PackingOutcome.demoUnavailable;
    if (payload.label.trim().isEmpty || payload.quantity < 1) {
      return PackingOutcome.validation;
    }
    if (realPackingMutationInFlight) return PackingOutcome.busy;
    realPackingMutationInFlight = true;
    notifyListeners();
    final result = await api.createPackingItem(tripId, payload);
    realPackingMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealPacking(tripId, refresh: true);
      return PackingOutcome.success;
    }
    final outcome = _mapPackingError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates a packing item (`PUT .../packing/{id}`) and reloads [tripId]'s
  /// checklist. Blank label / quantity < 1 are rejected client-side. No
  /// optimistic mutation. Zero HTTP in Demo Mode.
  Future<PackingOutcome> updateRealPackingItem(
      int tripId, int itemId, RealPackingItemPayload payload) async {
    if (demoMode) return PackingOutcome.demoUnavailable;
    if (payload.label.trim().isEmpty || payload.quantity < 1) {
      return PackingOutcome.validation;
    }
    if (realPackingMutationInFlight) return PackingOutcome.busy;
    realPackingMutationInFlight = true;
    notifyListeners();
    final result = await api.updatePackingItem(itemId, payload);
    realPackingMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealPacking(tripId, refresh: true);
      return PackingOutcome.success;
    }
    final outcome = _mapPackingError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes a packing item (`DELETE .../packing/{id}`) and reloads [tripId]'s
  /// checklist only after the server confirms. Zero HTTP in Demo Mode.
  Future<PackingOutcome> deleteRealPackingItem(int tripId, int itemId) async {
    if (demoMode) return PackingOutcome.demoUnavailable;
    if (realPackingMutationInFlight) return PackingOutcome.busy;
    realPackingMutationInFlight = true;
    notifyListeners();
    final result = await api.deletePackingItem(itemId);
    realPackingMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealPacking(tripId, refresh: true);
      return PackingOutcome.success;
    }
    final outcome = _mapPackingError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Checks or unchecks a packing item
  /// (`PATCH .../packing/{id}/check|uncheck`) and reloads [tripId]'s checklist so
  /// ordering updates (checked items sink). No optimistic mutation. Zero HTTP in
  /// Demo Mode.
  Future<PackingOutcome> setRealPackingItemChecked(
      int tripId, int itemId, bool checked) async {
    if (demoMode) return PackingOutcome.demoUnavailable;
    if (realPackingMutationInFlight) return PackingOutcome.busy;
    realPackingMutationInFlight = true;
    notifyListeners();
    final result = checked
        ? await api.checkPackingItem(itemId)
        : await api.uncheckPackingItem(itemId);
    realPackingMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealPacking(tripId, refresh: true);
      return PackingOutcome.success;
    }
    final outcome = _mapPackingError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Trip Reminders (UI-46) ─────────────────────────────────────

  ReminderOutcome _mapReminderError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => ReminderOutcome.sessionExpired,
      ApiErrorKind.forbidden => ReminderOutcome.forbidden,
      ApiErrorKind.notFound => ReminderOutcome.notFound,
      ApiErrorKind.validation => ReminderOutcome.validation,
      ApiErrorKind.unprocessable => ReminderOutcome.validation,
      ApiErrorKind.network => ReminderOutcome.network,
      ApiErrorKind.timeout => ReminderOutcome.network,
      ApiErrorKind.server => ReminderOutcome.serverError,
      _ => ReminderOutcome.serverError,
    };
  }

  /// Loads a trip's reminders (`GET .../reminders`, soonest first). Switching
  /// [tripId] — or changing [includeCancelled] — reloads. [refresh] forces a
  /// re-fetch and preserves the current list on failure. Zero HTTP in Demo Mode.
  Future<ReminderOutcome> loadRealReminders(int tripId,
      {bool refresh = false, bool? includeCancelled}) async {
    if (demoMode) return ReminderOutcome.demoUnavailable;
    if (realRemindersLoading || realRemindersRefreshing) {
      return ReminderOutcome.success;
    }
    final wantCancelled = includeCancelled ?? realRemindersIncludeCancelled;
    final sameTrip = realRemindersTripId == tripId;
    final sameFilter = realRemindersIncludeCancelled == wantCancelled;
    if (sameTrip && sameFilter && realRemindersLoaded && !refresh) {
      return ReminderOutcome.success;
    }
    if (sameTrip && sameFilter && refresh) {
      realRemindersRefreshing = true;
    } else {
      realRemindersLoading = true;
      if (!sameTrip || !sameFilter) {
        realReminders = [];
        realRemindersLoaded = false;
        realRemindersTripId = tripId;
        realRemindersIncludeCancelled = wantCancelled;
      }
    }
    realRemindersError = null;
    notifyListeners();
    final result =
        await api.getReminders(tripId, includeCancelled: wantCancelled);
    realRemindersLoading = false;
    realRemindersRefreshing = false;
    if (result.success && result.data != null) {
      realRemindersTripId = tripId;
      realRemindersIncludeCancelled = wantCancelled;
      realReminders = result.data!;
      realRemindersLoaded = true;
      realRemindersError = null;
      notifyListeners();
      return ReminderOutcome.success;
    }
    final outcome = _mapReminderError(result.errorKind);
    realRemindersError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Adds a reminder to [tripId] (`POST .../reminders`) and reloads the trip's
  /// list from the backend (no optimistic insert). A blank title is rejected
  /// client-side (the backend requires it). Single-flight via
  /// [realRemindersMutationInFlight]. Zero HTTP in Demo Mode.
  Future<ReminderOutcome> createRealReminder(
      int tripId, RealReminderPayload payload) async {
    if (demoMode) return ReminderOutcome.demoUnavailable;
    if (payload.title.trim().isEmpty) return ReminderOutcome.validation;
    if (realRemindersMutationInFlight) return ReminderOutcome.busy;
    realRemindersMutationInFlight = true;
    notifyListeners();
    final result = await api.createReminder(tripId, payload);
    realRemindersMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealReminders(tripId, refresh: true);
      return ReminderOutcome.success;
    }
    final outcome = _mapReminderError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates a reminder (`PUT .../reminders/{id}`) and reloads [tripId]'s list.
  /// A blank title is rejected client-side. No optimistic mutation. Zero HTTP in
  /// Demo Mode.
  Future<ReminderOutcome> updateRealReminder(
      int tripId, int reminderId, RealReminderPayload payload) async {
    if (demoMode) return ReminderOutcome.demoUnavailable;
    if (payload.title.trim().isEmpty) return ReminderOutcome.validation;
    if (realRemindersMutationInFlight) return ReminderOutcome.busy;
    realRemindersMutationInFlight = true;
    notifyListeners();
    final result = await api.updateReminder(reminderId, payload);
    realRemindersMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealReminders(tripId, refresh: true);
      return ReminderOutcome.success;
    }
    final outcome = _mapReminderError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Marks a reminder completed (`PATCH .../reminders/{id}/complete`) and reloads
  /// [tripId]'s list. No optimistic mutation. Zero HTTP in Demo Mode.
  Future<ReminderOutcome> completeRealReminder(int tripId, int reminderId) =>
      _patchRealReminder(tripId, reminderId, complete: true);

  /// Cancels a reminder (`PATCH .../reminders/{id}/cancel`) and reloads
  /// [tripId]'s list (a cancelled reminder disappears unless the include-cancelled
  /// filter is on). No optimistic mutation. Zero HTTP in Demo Mode.
  Future<ReminderOutcome> cancelRealReminder(int tripId, int reminderId) =>
      _patchRealReminder(tripId, reminderId, complete: false);

  Future<ReminderOutcome> _patchRealReminder(int tripId, int reminderId,
      {required bool complete}) async {
    if (demoMode) return ReminderOutcome.demoUnavailable;
    if (realRemindersMutationInFlight) return ReminderOutcome.busy;
    realRemindersMutationInFlight = true;
    notifyListeners();
    final result = complete
        ? await api.completeReminder(reminderId)
        : await api.cancelReminder(reminderId);
    realRemindersMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealReminders(tripId, refresh: true);
      return ReminderOutcome.success;
    }
    final outcome = _mapReminderError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes a reminder (`DELETE .../reminders/{id}`) and reloads [tripId]'s list
  /// only after the server confirms. Zero HTTP in Demo Mode.
  Future<ReminderOutcome> deleteRealReminder(int tripId, int reminderId) async {
    if (demoMode) return ReminderOutcome.demoUnavailable;
    if (realRemindersMutationInFlight) return ReminderOutcome.busy;
    realRemindersMutationInFlight = true;
    notifyListeners();
    final result = await api.deleteReminder(reminderId);
    realRemindersMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealReminders(tripId, refresh: true);
      return ReminderOutcome.success;
    }
    final outcome = _mapReminderError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Trip Budget (UI-47) ────────────────────────────────────────

  BudgetOutcome _mapBudgetError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => BudgetOutcome.sessionExpired,
      ApiErrorKind.forbidden => BudgetOutcome.forbidden,
      ApiErrorKind.notFound => BudgetOutcome.notFound,
      ApiErrorKind.validation => BudgetOutcome.validation,
      ApiErrorKind.unprocessable => BudgetOutcome.validation,
      ApiErrorKind.network => BudgetOutcome.network,
      ApiErrorKind.timeout => BudgetOutcome.network,
      ApiErrorKind.server => BudgetOutcome.serverError,
      _ => BudgetOutcome.serverError,
    };
  }

  /// Loads a trip's budget + spend summary. The summary
  /// (`GET .../budget-summary`) is the primary trip-accessibility signal; the
  /// budget entity (`GET .../budget`) is secondary — a 404 there means "no
  /// budget set yet" (a normal empty state, [realBudget] stays null), not an
  /// error. Switching [tripId] reloads. [refresh] forces a re-fetch and
  /// preserves prior state on failure. Zero HTTP in Demo Mode.
  Future<BudgetOutcome> loadRealBudget(int tripId,
      {bool refresh = false}) async {
    if (demoMode) return BudgetOutcome.demoUnavailable;
    if (realBudgetLoading || realBudgetRefreshing) return BudgetOutcome.success;
    final sameTrip = realBudgetTripId == tripId;
    if (sameTrip && realBudgetLoaded && !refresh) return BudgetOutcome.success;
    if (sameTrip && refresh) {
      realBudgetRefreshing = true;
    } else {
      realBudgetLoading = true;
      if (!sameTrip) {
        realBudget = null;
        realBudgetSummary = null;
        realBudgetLoaded = false;
        realBudgetTripId = tripId;
      }
    }
    realBudgetError = null;
    notifyListeners();

    final summaryResult = await api.getTripBudgetSummary(tripId);
    if (!(summaryResult.success && summaryResult.data != null)) {
      realBudgetLoading = false;
      realBudgetRefreshing = false;
      final outcome = _mapBudgetError(summaryResult.errorKind);
      realBudgetError = outcome;
      notifyListeners();
      return outcome;
    }
    final budgetResult = await api.getBudget(tripId);
    realBudgetLoading = false;
    realBudgetRefreshing = false;
    realBudgetTripId = tripId;
    realBudgetSummary = summaryResult.data;
    if (budgetResult.success && budgetResult.data != null) {
      realBudget = budgetResult.data;
    } else {
      // 404 = budget not set (normal); any other error here is non-fatal since
      // the summary already loaded — surface an empty budget rather than block.
      realBudget = null;
    }
    realBudgetLoaded = true;
    realBudgetError = null;
    notifyListeners();
    return BudgetOutcome.success;
  }

  /// Creates or updates a trip's budget (`PUT .../budget`, owner-only) and
  /// reloads from the backend (no optimistic mutation). A negative amount or a
  /// blank currency is rejected client-side. Single-flight via
  /// [realBudgetMutationInFlight]. Zero HTTP in Demo Mode.
  Future<BudgetOutcome> saveRealBudget(
      int tripId, RealBudgetPayload payload) async {
    if (demoMode) return BudgetOutcome.demoUnavailable;
    if (payload.totalBudget < 0 || payload.currency.trim().isEmpty) {
      return BudgetOutcome.validation;
    }
    if (realBudgetMutationInFlight) return BudgetOutcome.busy;
    realBudgetMutationInFlight = true;
    notifyListeners();
    final result = await api.upsertBudget(tripId, payload);
    realBudgetMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealBudget(tripId, refresh: true);
      return BudgetOutcome.success;
    }
    final outcome = _mapBudgetError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes a trip's budget (`DELETE .../budget`, owner-only) and reloads only
  /// after the server confirms. Zero HTTP in Demo Mode.
  Future<BudgetOutcome> deleteRealBudget(int tripId) async {
    if (demoMode) return BudgetOutcome.demoUnavailable;
    if (realBudgetMutationInFlight) return BudgetOutcome.busy;
    realBudgetMutationInFlight = true;
    notifyListeners();
    final result = await api.deleteBudget(tripId);
    realBudgetMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealBudget(tripId, refresh: true);
      return BudgetOutcome.success;
    }
    final outcome = _mapBudgetError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Trip Collaboration (UI-48) ─────────────────────────────────

  CollaborationOutcome _mapCollabError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => CollaborationOutcome.sessionExpired,
      ApiErrorKind.forbidden => CollaborationOutcome.forbidden,
      ApiErrorKind.notFound => CollaborationOutcome.notFound,
      ApiErrorKind.conflict => CollaborationOutcome.conflict,
      ApiErrorKind.validation => CollaborationOutcome.validation,
      ApiErrorKind.unprocessable => CollaborationOutcome.validation,
      ApiErrorKind.network => CollaborationOutcome.network,
      ApiErrorKind.timeout => CollaborationOutcome.network,
      ApiErrorKind.server => CollaborationOutcome.serverError,
      _ => CollaborationOutcome.serverError,
    };
  }

  /// Loads a trip's collaborators (`GET .../collaborators`, owner-only, createdAt
  /// ASC). Switching [tripId] reloads. [seedIsPublic] seeds the public/private
  /// toggle from the trip detail on first load (the collaborators endpoint does
  /// not carry it). [refresh] forces a re-fetch and preserves the current list
  /// on failure. Zero HTTP in Demo Mode.
  Future<CollaborationOutcome> loadRealCollaborators(int tripId,
      {bool refresh = false, bool? seedIsPublic}) async {
    if (demoMode) return CollaborationOutcome.demoUnavailable;
    if (realCollabLoading || realCollabRefreshing) {
      return CollaborationOutcome.success;
    }
    final sameTrip = realCollabTripId == tripId;
    if (sameTrip && realCollabLoaded && !refresh) {
      return CollaborationOutcome.success;
    }
    if (sameTrip && refresh) {
      realCollabRefreshing = true;
    } else {
      realCollabLoading = true;
      if (!sameTrip) {
        realCollaborators = [];
        realCollabIsPublic = null;
        realCollabLoaded = false;
        realCollabTripId = tripId;
      }
    }
    if (seedIsPublic != null && realCollabIsPublic == null) {
      realCollabIsPublic = seedIsPublic;
    }
    realCollabError = null;
    notifyListeners();
    final result = await api.getCollaborators(tripId);
    realCollabLoading = false;
    realCollabRefreshing = false;
    if (result.success && result.data != null) {
      realCollabTripId = tripId;
      realCollaborators = result.data!;
      realCollabLoaded = true;
      realCollabError = null;
      notifyListeners();
      return CollaborationOutcome.success;
    }
    final outcome = _mapCollabError(result.errorKind);
    realCollabError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Invites a collaborator by email (`POST .../collaborators`, owner-only) and
  /// reloads the list from the backend (no optimistic insert). A blank email is
  /// rejected client-side. Single-flight via [realCollabMutationInFlight]. Zero
  /// HTTP in Demo Mode.
  Future<CollaborationOutcome> inviteRealCollaborator(
      int tripId, RealCollaboratorPayload payload) async {
    if (demoMode) return CollaborationOutcome.demoUnavailable;
    if (payload.email.trim().isEmpty) return CollaborationOutcome.validation;
    if (realCollabMutationInFlight) return CollaborationOutcome.busy;
    realCollabMutationInFlight = true;
    notifyListeners();
    final result = await api.inviteCollaborator(tripId, payload);
    realCollabMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealCollaborators(tripId, refresh: true);
      return CollaborationOutcome.success;
    }
    final outcome = _mapCollabError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates a collaborator's role (`PATCH .../collaborators/{id}`, owner-only)
  /// and reloads the list. No optimistic mutation. Zero HTTP in Demo Mode.
  Future<CollaborationOutcome> updateRealCollaboratorRole(
      int tripId, int collaboratorId, RealCollaboratorPayload payload) async {
    if (demoMode) return CollaborationOutcome.demoUnavailable;
    if (payload.email.trim().isEmpty) return CollaborationOutcome.validation;
    if (realCollabMutationInFlight) return CollaborationOutcome.busy;
    realCollabMutationInFlight = true;
    notifyListeners();
    final result =
        await api.updateCollaboratorRole(tripId, collaboratorId, payload);
    realCollabMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealCollaborators(tripId, refresh: true);
      return CollaborationOutcome.success;
    }
    final outcome = _mapCollabError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Removes a collaborator (`DELETE .../collaborators/{id}`, owner-only) and
  /// reloads only after the server confirms. Zero HTTP in Demo Mode.
  Future<CollaborationOutcome> removeRealCollaborator(
      int tripId, int collaboratorId) async {
    if (demoMode) return CollaborationOutcome.demoUnavailable;
    if (realCollabMutationInFlight) return CollaborationOutcome.busy;
    realCollabMutationInFlight = true;
    notifyListeners();
    final result = await api.removeCollaborator(tripId, collaboratorId);
    realCollabMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealCollaborators(tripId, refresh: true);
      return CollaborationOutcome.success;
    }
    final outcome = _mapCollabError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Toggles a trip's public visibility (`PATCH .../public|private`, owner-only).
  /// The new state comes from the server response (not an optimistic guess); the
  /// collaborator list is reloaded afterwards. Zero HTTP in Demo Mode.
  Future<CollaborationOutcome> setRealTripPublic(
      int tripId, bool makePublic) async {
    if (demoMode) return CollaborationOutcome.demoUnavailable;
    if (realCollabMutationInFlight) return CollaborationOutcome.busy;
    realCollabMutationInFlight = true;
    notifyListeners();
    final result = await api.setTripPublic(tripId, makePublic);
    realCollabMutationInFlight = false;
    if (result.success && result.data != null) {
      realCollabTripId = tripId;
      realCollabIsPublic = result.data!.isPublic;
      notifyListeners();
      await loadRealCollaborators(tripId, refresh: true);
      return CollaborationOutcome.success;
    }
    final outcome = _mapCollabError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Shared Trips (UI-49) ───────────────────────────────────────

  SharedTripsOutcome _mapSharedTripsError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => SharedTripsOutcome.sessionExpired,
      ApiErrorKind.forbidden => SharedTripsOutcome.forbidden,
      ApiErrorKind.notFound => SharedTripsOutcome.notFound,
      ApiErrorKind.network => SharedTripsOutcome.network,
      ApiErrorKind.timeout => SharedTripsOutcome.network,
      ApiErrorKind.server => SharedTripsOutcome.serverError,
      _ => SharedTripsOutcome.serverError,
    };
  }

  /// Loads the "shared with me" list (`GET .../trips/shared`, createdAt DESC).
  /// [refresh] forces a re-fetch and preserves the current list on failure.
  /// Single-flight; cached after first success. Zero HTTP in Demo Mode.
  Future<SharedTripsOutcome> loadRealSharedTrips({bool refresh = false}) async {
    if (demoMode) return SharedTripsOutcome.demoUnavailable;
    if (realSharedTripsLoading || realSharedTripsRefreshing) {
      return SharedTripsOutcome.success;
    }
    if (realSharedTripsLoaded && !refresh) return SharedTripsOutcome.success;
    if (realSharedTripsLoaded && refresh) {
      realSharedTripsRefreshing = true;
    } else {
      realSharedTripsLoading = true;
    }
    realSharedTripsError = null;
    notifyListeners();
    final result = await api.getSharedTrips();
    realSharedTripsLoading = false;
    realSharedTripsRefreshing = false;
    if (result.success && result.data != null) {
      realSharedTrips = result.data!;
      realSharedTripsLoaded = true;
      realSharedTripsError = null;
      notifyListeners();
      return SharedTripsOutcome.success;
    }
    final outcome = _mapSharedTripsError(result.errorKind);
    realSharedTripsError = outcome;
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Interest Profile (UI-52) ───────────────────────────────────

  InterestProfileOutcome _mapInterestError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => InterestProfileOutcome.sessionExpired,
      ApiErrorKind.forbidden => InterestProfileOutcome.forbidden,
      ApiErrorKind.notFound => InterestProfileOutcome.notFound,
      ApiErrorKind.network => InterestProfileOutcome.network,
      ApiErrorKind.timeout => InterestProfileOutcome.network,
      ApiErrorKind.server => InterestProfileOutcome.serverError,
      _ => InterestProfileOutcome.serverError,
    };
  }

  /// Loads the derived interest profile (`GET /api/me/interests`). [refresh]
  /// forces a re-fetch and preserves the current profile on failure.
  /// Single-flight; cached after first success. Zero HTTP in Demo Mode.
  Future<InterestProfileOutcome> loadRealInterestProfile(
      {bool refresh = false}) async {
    if (demoMode) return InterestProfileOutcome.demoUnavailable;
    if (realInterestLoading ||
        realInterestRefreshing ||
        realInterestRecalculating) {
      return InterestProfileOutcome.busy;
    }
    if (realInterestLoaded && !refresh) return InterestProfileOutcome.success;
    if (realInterestLoaded && refresh) {
      realInterestRefreshing = true;
    } else {
      realInterestLoading = true;
    }
    realInterestError = null;
    notifyListeners();
    final result = await api.getInterestProfile();
    realInterestLoading = false;
    realInterestRefreshing = false;
    if (result.success && result.data != null) {
      realInterestProfile = result.data;
      realInterestLoaded = true;
      realInterestError = null;
      notifyListeners();
      return InterestProfileOutcome.success;
    }
    final outcome = _mapInterestError(result.errorKind);
    realInterestError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Re-derives the interest profile (`POST /api/me/interests/recalculate`).
  /// Single-flight via [realInterestRecalculating]; on success replaces the
  /// stored profile with the returned one (no optimistic update). Preserves the
  /// current profile on failure. Zero HTTP in Demo Mode.
  Future<InterestProfileOutcome> recalculateRealInterestProfile() async {
    if (demoMode) return InterestProfileOutcome.demoUnavailable;
    if (realInterestLoading ||
        realInterestRefreshing ||
        realInterestRecalculating) {
      return InterestProfileOutcome.busy;
    }
    realInterestRecalculating = true;
    realInterestError = null;
    notifyListeners();
    final result = await api.recalculateInterestProfile();
    realInterestRecalculating = false;
    if (result.success && result.data != null) {
      realInterestProfile = result.data;
      realInterestLoaded = true;
      realInterestError = null;
      notifyListeners();
      return InterestProfileOutcome.success;
    }
    final outcome = _mapInterestError(result.errorKind);
    realInterestError = outcome;
    notifyListeners();
    return outcome;
  }

  // ── Real Mode Travel Wallet (UI-50) ──────────────────────────────────────

  WalletOutcome _mapWalletError(ApiErrorKind? kind) {
    return switch (kind) {
      ApiErrorKind.unauthorized => WalletOutcome.sessionExpired,
      ApiErrorKind.forbidden => WalletOutcome.forbidden,
      ApiErrorKind.notFound => WalletOutcome.notFound,
      ApiErrorKind.validation => WalletOutcome.validation,
      ApiErrorKind.unprocessable => WalletOutcome.validation,
      ApiErrorKind.network => WalletOutcome.network,
      ApiErrorKind.timeout => WalletOutcome.network,
      ApiErrorKind.server => WalletOutcome.serverError,
      _ => WalletOutcome.serverError,
    };
  }

  /// Loads my travel wallet (`GET .../travel-wallet`, default sort). [refresh]
  /// forces a re-fetch and preserves the current list on failure. Single-flight;
  /// cached after first success. Zero HTTP in Demo Mode.
  Future<WalletOutcome> loadRealWallet({bool refresh = false}) async {
    if (demoMode) return WalletOutcome.demoUnavailable;
    if (realWalletLoading || realWalletRefreshing) return WalletOutcome.success;
    if (realWalletLoaded && !refresh) return WalletOutcome.success;
    if (realWalletLoaded && refresh) {
      realWalletRefreshing = true;
    } else {
      realWalletLoading = true;
    }
    realWalletError = null;
    notifyListeners();
    final result = await api.getWalletItems();
    realWalletLoading = false;
    realWalletRefreshing = false;
    if (result.success && result.data != null) {
      realWalletItems = result.data!;
      realWalletLoaded = true;
      realWalletError = null;
      notifyListeners();
      return WalletOutcome.success;
    }
    final outcome = _mapWalletError(result.errorKind);
    realWalletError = outcome;
    notifyListeners();
    return outcome;
  }

  /// Adds a wallet item (`POST .../travel-wallet`) and reloads the list from the
  /// backend (no optimistic insert). A blank display title is rejected
  /// client-side (required for a standalone item). Single-flight via
  /// [realWalletMutationInFlight]. Zero HTTP in Demo Mode.
  Future<WalletOutcome> createRealWalletItem(
      RealWalletItemPayload payload) async {
    if (demoMode) return WalletOutcome.demoUnavailable;
    if (payload.displayTitle.trim().isEmpty) return WalletOutcome.validation;
    if (realWalletMutationInFlight) return WalletOutcome.busy;
    realWalletMutationInFlight = true;
    notifyListeners();
    final result = await api.createWalletItem(payload);
    realWalletMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealWallet(refresh: true);
      return WalletOutcome.success;
    }
    final outcome = _mapWalletError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Updates a wallet item (`PUT .../travel-wallet/{id}`) and reloads the list.
  /// A blank display title is rejected client-side. No optimistic mutation.
  /// Zero HTTP in Demo Mode.
  Future<WalletOutcome> updateRealWalletItem(
      int id, RealWalletItemPayload payload) async {
    if (demoMode) return WalletOutcome.demoUnavailable;
    if (payload.displayTitle.trim().isEmpty) return WalletOutcome.validation;
    if (realWalletMutationInFlight) return WalletOutcome.busy;
    realWalletMutationInFlight = true;
    notifyListeners();
    final result = await api.updateWalletItem(id, payload);
    realWalletMutationInFlight = false;
    if (result.success && result.data != null) {
      notifyListeners();
      await loadRealWallet(refresh: true);
      return WalletOutcome.success;
    }
    final outcome = _mapWalletError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Deletes a wallet item (`DELETE .../travel-wallet/{id}`) and reloads only
  /// after the server confirms. Zero HTTP in Demo Mode.
  Future<WalletOutcome> deleteRealWalletItem(int id) async {
    if (demoMode) return WalletOutcome.demoUnavailable;
    if (realWalletMutationInFlight) return WalletOutcome.busy;
    realWalletMutationInFlight = true;
    notifyListeners();
    final result = await api.deleteWalletItem(id);
    realWalletMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealWallet(refresh: true);
      return WalletOutcome.success;
    }
    final outcome = _mapWalletError(result.errorKind);
    notifyListeners();
    return outcome;
  }

  /// Favorites or unfavorites a wallet item (`PATCH .../favorite|unfavorite`)
  /// and reloads the list so ordering updates. No optimistic mutation. Zero HTTP
  /// in Demo Mode.
  Future<WalletOutcome> setRealWalletItemFavorite(int id, bool favorite) =>
      _mutateRealWalletItem(favorite
          ? () => api.favoriteWalletItem(id)
          : () => api.unfavoriteWalletItem(id));

  /// Archives or restores a wallet item (`PATCH .../archive|restore`) and
  /// reloads the list. No optimistic mutation. Zero HTTP in Demo Mode.
  Future<WalletOutcome> setRealWalletItemArchived(int id, bool archived) =>
      _mutateRealWalletItem(archived
          ? () => api.archiveWalletItem(id)
          : () => api.restoreWalletItem(id));

  Future<WalletOutcome> _mutateRealWalletItem(
      Future<CollectionApiVoidResult> Function() action) async {
    if (demoMode) return WalletOutcome.demoUnavailable;
    if (realWalletMutationInFlight) return WalletOutcome.busy;
    realWalletMutationInFlight = true;
    notifyListeners();
    final result = await action();
    realWalletMutationInFlight = false;
    if (result.success) {
      notifyListeners();
      await loadRealWallet(refresh: true);
      return WalletOutcome.success;
    }
    final outcome = _mapWalletError(result.errorKind);
    notifyListeners();
    return outcome;
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
