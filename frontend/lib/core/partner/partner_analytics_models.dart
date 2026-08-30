/// Typed models for the Partner Analytics module (C11), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth:
///   * `controller/PartnerAnalyticsController` — `/api/partner/analytics/**`
///   * `service/PartnerAnalyticsService`, `dto/PartnerAnalyticsDto`
///
/// ## What C11 adds, and what it deliberately leaves alone
///
/// C1's dashboard already consumes `/analytics/overview`, `/analytics/revenue`
/// and `/analytics/occupancy` through [PartnerAnalyticsOverview],
/// [PartnerRevenueAnalytics] and [PartnerOccupancyAnalytics]. Those models and
/// their `ApiClient` methods are **reused, not redefined**, so revenue and
/// occupancy keep exactly one definition across the product.
///
/// C11 adds only the five that had no client at all: bookings, rooms,
/// promotions, reviews and messages.
///
/// ## Nullable is not zero
///
/// Two metrics are genuinely `Double`/`Long` objects in Java and arrive as
/// `null` when the backend cannot compute them:
/// `PromotionAnalyticsResponse.estimatedDiscountedBookings` (the controller says
/// "no exact discount attribution yet") and
/// `MessageAnalyticsResponse.averageResponseTimeMinutes` (no replies observed).
/// Both are modelled nullable and rendered as *not available* — never as `0`,
/// which would be a different and false claim.
library;

import 'partner_dashboard_models.dart';

/// `dto/PartnerAnalyticsDto.BookingAnalyticsResponse`.
class PartnerBookingAnalytics {
  /// One entry per `BookingStatus` present in the window. `value` and `count`
  /// are both the count here — the backend fills both from `Collectors.counting`.
  final List<PartnerMetricBreakdown> bookingsByStatus;

  final int arrivals;
  final int departures;
  final int cancellations;
  final int noShows;

  /// Server-computed mean nights. The client never averages anything.
  final double averageStayLength;

  const PartnerBookingAnalytics({
    required this.bookingsByStatus,
    required this.arrivals,
    required this.departures,
    required this.cancellations,
    required this.noShows,
    required this.averageStayLength,
  });

  int get totalBookings =>
      bookingsByStatus.fold(0, (sum, entry) => sum + entry.count);

  /// No bookings fell in the window at all — distinct from "every counter
  /// happens to be zero for a window that does contain bookings".
  bool get isEmpty => bookingsByStatus.isEmpty;

  static PartnerBookingAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerBookingAnalytics(
        bookingsByStatus:
            _list(json['bookingsByStatus'], PartnerMetricBreakdown.fromJson),
        arrivals: partnerAsInt(json['arrivals']) ?? 0,
        departures: partnerAsInt(json['departures']) ?? 0,
        cancellations: partnerAsInt(json['cancellations']) ?? 0,
        noShows: partnerAsInt(json['noShows']) ?? 0,
        averageStayLength: partnerAsDouble(json['averageStayLength']) ?? 0,
      );
}

/// `dto/PartnerAnalyticsDto.RoomAnalyticsResponse`.
///
/// The two "top rooms" lists measure different things and are kept apart:
/// `topRoomsByRevenue` carries money in `value`, `topRoomsByBookings` carries a
/// count. Merging them would invent a ranking the backend never produced.
class PartnerRoomAnalytics {
  final List<PartnerMetricBreakdown> topRoomsByRevenue;
  final List<PartnerMetricBreakdown> topRoomsByBookings;
  final List<PartnerMetricBreakdown> roomAvailabilitySummary;

  /// A percentage the server calls an *estimate*; the label says so.
  final double roomOccupancyEstimate;

  const PartnerRoomAnalytics({
    required this.topRoomsByRevenue,
    required this.topRoomsByBookings,
    required this.roomAvailabilitySummary,
    required this.roomOccupancyEstimate,
  });

  bool get isEmpty =>
      topRoomsByRevenue.isEmpty &&
      topRoomsByBookings.isEmpty &&
      roomAvailabilitySummary.isEmpty;

  static PartnerRoomAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerRoomAnalytics(
        topRoomsByRevenue:
            _list(json['topRoomsByRevenue'], PartnerMetricBreakdown.fromJson),
        topRoomsByBookings:
            _list(json['topRoomsByBookings'], PartnerMetricBreakdown.fromJson),
        roomAvailabilitySummary: _list(
            json['roomAvailabilitySummary'], PartnerMetricBreakdown.fromJson),
        roomOccupancyEstimate:
            partnerAsDouble(json['roomOccupancyEstimate']) ?? 0,
      );
}

/// `dto/PartnerAnalyticsDto.PromotionAnalyticsResponse`.
///
/// The controller names this "**structural** promotion analytics (no exact
/// discount attribution yet)". [estimatedDiscountedBookings] is therefore
/// nullable and, when null, is shown as unavailable rather than as zero.
class PartnerPromotionAnalytics {
  final int activePromotions;
  final List<PartnerMetricBreakdown> promotionsByType;

  /// Null when the backend cannot attribute discounts — not a count of zero.
  final int? estimatedDiscountedBookings;

  final List<PartnerMetricBreakdown> promotionCountByStatus;

  const PartnerPromotionAnalytics({
    required this.activePromotions,
    required this.promotionsByType,
    required this.promotionCountByStatus,
    this.estimatedDiscountedBookings,
  });

  bool get isEmpty =>
      activePromotions == 0 &&
      promotionsByType.isEmpty &&
      promotionCountByStatus.isEmpty;

  bool get hasDiscountAttribution => estimatedDiscountedBookings != null;

  static PartnerPromotionAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerPromotionAnalytics(
        activePromotions: partnerAsInt(json['activePromotions']) ?? 0,
        promotionsByType:
            _list(json['promotionsByType'], PartnerMetricBreakdown.fromJson),
        estimatedDiscountedBookings:
            partnerAsInt(json['estimatedDiscountedBookings']),
        promotionCountByStatus: _list(
            json['promotionCountByStatus'], PartnerMetricBreakdown.fromJson),
      );
}

/// `dto/PartnerAnalyticsDto.ReviewAnalyticsResponse`.
///
/// Only the **aggregates** are mapped. `latestReviews` is a list of
/// `ReviewPreview` carrying guest names and review titles — that is the Reviews
/// domain, which C12 owns, and an analytics screen is the wrong place to start
/// surfacing guest-authored content. Not parsing it means it cannot be rendered
/// here by accident.
class PartnerReviewAnalytics {
  /// Mean over **approved** reviews only, per the service's documented
  /// population. `0.0` when there are none, which is why [reviewCount] must be
  /// read alongside it.
  final double averageRating;

  final int reviewCount;
  final int pendingReviews;
  final int approvedReviews;
  final int rejectedReviews;

  const PartnerReviewAnalytics({
    required this.averageRating,
    required this.reviewCount,
    required this.pendingReviews,
    required this.approvedReviews,
    required this.rejectedReviews,
  });

  /// No reviews exist, so `averageRating == 0` means "no observations" rather
  /// than "rated zero".
  bool get hasNoObservations => reviewCount == 0;

  static PartnerReviewAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerReviewAnalytics(
        averageRating: partnerAsDouble(json['averageRating']) ?? 0,
        reviewCount: partnerAsInt(json['reviewCount']) ?? 0,
        pendingReviews: partnerAsInt(json['pendingReviews']) ?? 0,
        approvedReviews: partnerAsInt(json['approvedReviews']) ?? 0,
        rejectedReviews: partnerAsInt(json['rejectedReviews']) ?? 0,
      );
}

/// `dto/PartnerAnalyticsDto.MessageAnalyticsResponse`.
class PartnerMessageAnalytics {
  final int openConversations;
  final int closedConversations;
  final int archivedConversations;
  final int unreadPartnerMessages;

  /// Null when no response time could be observed — shown as unavailable, not
  /// as an instant reply.
  final double? averageResponseTimeMinutes;

  const PartnerMessageAnalytics({
    required this.openConversations,
    required this.closedConversations,
    required this.archivedConversations,
    required this.unreadPartnerMessages,
    this.averageResponseTimeMinutes,
  });

  int get totalConversations =>
      openConversations + closedConversations + archivedConversations;

  bool get isEmpty => totalConversations == 0;

  bool get hasResponseTime => averageResponseTimeMinutes != null;

  static PartnerMessageAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerMessageAnalytics(
        openConversations: partnerAsInt(json['openConversations']) ?? 0,
        closedConversations: partnerAsInt(json['closedConversations']) ?? 0,
        archivedConversations: partnerAsInt(json['archivedConversations']) ?? 0,
        unreadPartnerMessages: partnerAsInt(json['unreadPartnerMessages']) ?? 0,
        averageResponseTimeMinutes:
            partnerAsDouble(json['averageResponseTimeMinutes']),
      );
}

List<T> _list<T>(Object? raw, T? Function(Map<String, dynamic>) parse) {
  if (raw is! List) return const [];
  final items = <T>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;
    final item = parse(entry);
    if (item != null) items.add(item);
  }
  return List.unmodifiable(items);
}
