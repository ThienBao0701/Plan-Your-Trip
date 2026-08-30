/// Typed models for the Partner Dashboard (C1), mapped one-to-one from the
/// backend records in `backend-v1` (branch `develop`).
///
/// Source DTOs, verified against the backend worktree rather than any copy
/// inside this repository:
///   * `dto/PartnerBookingDto.PartnerDashboardResponse`
///   * `dto/PartnerAnalyticsDto.PartnerAnalyticsOverviewResponse`
///   * `dto/PartnerAnalyticsDto.OccupancyAnalyticsResponse`
///   * `dto/PartnerAnalyticsDto.RevenueAnalyticsResponse`
///   * `dto/PartnerFinanceDto.PartnerFinanceOverviewResponse`
///   * `dto/PartnerExtranetDto.PartnerActivityLogResponse`
///   * `dto/PartnerExtranetDto.PartnerMenuResponse` / `MenuItem` / `QuickAction`
///
/// Field names are the backend's. Nothing here is renamed, derived, or
/// invented: every value a widget shows is a value the server computed. The
/// only client-side arithmetic in the dashboard is chart axis scaling, which is
/// presentation, not business logic.
///
/// `Map<String, dynamic>` stops at these `fromJson` constructors.
library;

/// `dto/PartnerAnalyticsDto.TimeSeriesPoint` — `(LocalDate date, BigDecimal value)`.
class PartnerTimeSeriesPoint {
  final DateTime date;
  final double value;

  const PartnerTimeSeriesPoint({required this.date, required this.value});

  static PartnerTimeSeriesPoint? fromJson(Map<String, dynamic> json) {
    final date = partnerAsDate(json['date']);
    if (date == null) return null;
    return PartnerTimeSeriesPoint(
      date: date,
      value: partnerAsDouble(json['value']) ?? 0,
    );
  }
}

/// `dto/PartnerAnalyticsDto.MetricBreakdown` — `(String label, BigDecimal value, long count)`.
class PartnerMetricBreakdown {
  final String label;
  final double value;
  final int count;

  const PartnerMetricBreakdown({
    required this.label,
    required this.value,
    required this.count,
  });

  static PartnerMetricBreakdown fromJson(Map<String, dynamic> json) =>
      PartnerMetricBreakdown(
        label: partnerAsString(json['label']) ?? '',
        value: partnerAsDouble(json['value']) ?? 0,
        count: partnerAsInt(json['count']) ?? 0,
      );
}

/// `GET /api/partner/dashboard` → `PartnerDashboardResponse`.
///
/// Scope note: this endpoint takes **no** parameters. `PartnerBookingService`
/// computes it across every hotel the caller owns, anchored on `LocalDate.now()`
/// — so it is "today, all properties" and does not follow the dashboard's
/// property/date filter. The UI labels it accordingly instead of implying the
/// filter applies.
class PartnerBookingDashboard {
  final int todaysArrivals;
  final int todaysDepartures;
  final int currentGuests;
  final int upcoming;
  final int cancelled;
  final int completed;

  /// Percentage as the backend supplies it (`double occupancyRate`).
  final double occupancyRate;
  final double revenueToday;
  final double revenueMonth;
  final double averageStayNights;

  const PartnerBookingDashboard({
    required this.todaysArrivals,
    required this.todaysDepartures,
    required this.currentGuests,
    required this.upcoming,
    required this.cancelled,
    required this.completed,
    required this.occupancyRate,
    required this.revenueToday,
    required this.revenueMonth,
    required this.averageStayNights,
  });

  static PartnerBookingDashboard fromJson(Map<String, dynamic> json) =>
      PartnerBookingDashboard(
        todaysArrivals: partnerAsInt(json['todaysArrivals']) ?? 0,
        todaysDepartures: partnerAsInt(json['todaysDepartures']) ?? 0,
        currentGuests: partnerAsInt(json['currentGuests']) ?? 0,
        upcoming: partnerAsInt(json['upcoming']) ?? 0,
        cancelled: partnerAsInt(json['cancelled']) ?? 0,
        completed: partnerAsInt(json['completed']) ?? 0,
        occupancyRate: partnerAsDouble(json['occupancyRate']) ?? 0,
        revenueToday: partnerAsDouble(json['revenueToday']) ?? 0,
        revenueMonth: partnerAsDouble(json['revenueMonth']) ?? 0,
        averageStayNights: partnerAsDouble(json['averageStayNights']) ?? 0,
      );
}

/// `GET /api/partner/analytics/overview` → `PartnerAnalyticsOverviewResponse`.
///
/// Honours `hotelId` / `from` / `to`. `responseRate` is a boxed `Double` in the
/// record and is genuinely nullable — it stays null here rather than becoming a
/// misleading zero.
class PartnerAnalyticsOverview {
  final double totalRevenue;
  final int totalBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int completedBookings;
  final double occupancyRate;
  final double averageDailyRate;
  final double averageStayNights;
  final double reviewAverage;
  final int reviewCount;
  final int unreadMessages;

  /// Nullable in the DTO (`Double responseRate`).
  final double? responseRate;

  const PartnerAnalyticsOverview({
    required this.totalRevenue,
    required this.totalBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.completedBookings,
    required this.occupancyRate,
    required this.averageDailyRate,
    required this.averageStayNights,
    required this.reviewAverage,
    required this.reviewCount,
    required this.unreadMessages,
    this.responseRate,
  });

  /// True when the selected period produced no bookings at all — the dashboard
  /// shows an empty state rather than a wall of zeros pretending to be data.
  bool get hasNoBookings => totalBookings == 0;

  static PartnerAnalyticsOverview fromJson(Map<String, dynamic> json) =>
      PartnerAnalyticsOverview(
        totalRevenue: partnerAsDouble(json['totalRevenue']) ?? 0,
        totalBookings: partnerAsInt(json['totalBookings']) ?? 0,
        confirmedBookings: partnerAsInt(json['confirmedBookings']) ?? 0,
        cancelledBookings: partnerAsInt(json['cancelledBookings']) ?? 0,
        completedBookings: partnerAsInt(json['completedBookings']) ?? 0,
        occupancyRate: partnerAsDouble(json['occupancyRate']) ?? 0,
        averageDailyRate: partnerAsDouble(json['averageDailyRate']) ?? 0,
        averageStayNights: partnerAsDouble(json['averageStayNights']) ?? 0,
        reviewAverage: partnerAsDouble(json['reviewAverage']) ?? 0,
        reviewCount: partnerAsInt(json['reviewCount']) ?? 0,
        unreadMessages: partnerAsInt(json['unreadMessages']) ?? 0,
        responseRate: partnerAsDouble(json['responseRate']),
      );
}

/// `GET /api/partner/analytics/occupancy` → `OccupancyAnalyticsResponse`.
class PartnerOccupancyAnalytics {
  final List<PartnerTimeSeriesPoint> occupancyByDay;
  final int totalRoomInventory;
  final int soldRooms;
  final int availableRooms;
  final int stopSellDaysCount;

  const PartnerOccupancyAnalytics({
    required this.occupancyByDay,
    required this.totalRoomInventory,
    required this.soldRooms,
    required this.availableRooms,
    required this.stopSellDaysCount,
  });

  /// No inventory configured at all — a different situation from "inventory
  /// exists but nothing sold", and the UI says so.
  bool get hasNoInventory => totalRoomInventory == 0;

  static PartnerOccupancyAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerOccupancyAnalytics(
        occupancyByDay: partnerAsSeries(json['occupancyByDay']),
        totalRoomInventory: partnerAsInt(json['totalRoomInventory']) ?? 0,
        soldRooms: partnerAsInt(json['soldRooms']) ?? 0,
        availableRooms: partnerAsInt(json['availableRooms']) ?? 0,
        stopSellDaysCount: partnerAsInt(json['stopSellDaysCount']) ?? 0,
      );
}

/// `GET /api/partner/analytics/revenue` → `RevenueAnalyticsResponse`.
class PartnerRevenueAnalytics {
  final List<PartnerTimeSeriesPoint> revenueByDay;
  final List<PartnerMetricBreakdown> revenueByRoom;
  final List<PartnerMetricBreakdown> revenueByHotel;
  final double revenueMonthToDate;
  final double revenueLast30Days;

  const PartnerRevenueAnalytics({
    required this.revenueByDay,
    required this.revenueByRoom,
    required this.revenueByHotel,
    required this.revenueMonthToDate,
    required this.revenueLast30Days,
  });

  static PartnerRevenueAnalytics fromJson(Map<String, dynamic> json) =>
      PartnerRevenueAnalytics(
        revenueByDay: partnerAsSeries(json['revenueByDay']),
        revenueByRoom: partnerAsBreakdowns(json['revenueByRoom']),
        revenueByHotel: partnerAsBreakdowns(json['revenueByHotel']),
        revenueMonthToDate: partnerAsDouble(json['revenueMonthToDate']) ?? 0,
        revenueLast30Days: partnerAsDouble(json['revenueLast30Days']) ?? 0,
      );
}

/// `PartnerFinanceDto.PartnerFinanceOverviewResponse`.
///
/// Reached two ways, both authoritative and both the same record:
///   * embedded as `financeSummary` in `GET /api/partner/extranet/home`,
///     computed at the default scope (all hotels, last 30 days);
///   * `GET /api/partner/finance/overview`, which honours `hotelId`/`from`/`to`.
///
/// The dashboard seeds from the embedded copy and only calls the standalone
/// endpoint when the scope actually differs — see `PartnerDashboardState`.
class PartnerFinanceOverview {
  final double grossRevenue;
  final double netRevenue;
  final double commissionAmount;
  final double estimatedTax;
  final int completedBookings;
  final int paidBookings;
  final double refundedAmount;
  final double pendingSettlement;

  /// Nullable in the DTO (`LocalDate nextEstimatedPayoutDate`).
  final DateTime? nextEstimatedPayoutDate;

  const PartnerFinanceOverview({
    required this.grossRevenue,
    required this.netRevenue,
    required this.commissionAmount,
    required this.estimatedTax,
    required this.completedBookings,
    required this.paidBookings,
    required this.refundedAmount,
    required this.pendingSettlement,
    this.nextEstimatedPayoutDate,
  });

  static PartnerFinanceOverview fromJson(Map<String, dynamic> json) =>
      PartnerFinanceOverview(
        grossRevenue: partnerAsDouble(json['grossRevenue']) ?? 0,
        netRevenue: partnerAsDouble(json['netRevenue']) ?? 0,
        commissionAmount: partnerAsDouble(json['commissionAmount']) ?? 0,
        estimatedTax: partnerAsDouble(json['estimatedTax']) ?? 0,
        completedBookings: partnerAsInt(json['completedBookings']) ?? 0,
        paidBookings: partnerAsInt(json['paidBookings']) ?? 0,
        refundedAmount: partnerAsDouble(json['refundedAmount']) ?? 0,
        pendingSettlement: partnerAsDouble(json['pendingSettlement']) ?? 0,
        nextEstimatedPayoutDate: partnerAsDate(json['nextEstimatedPayoutDate']),
      );
}

/// `dto/PartnerExtranetDto.PartnerActivityLogResponse`.
///
/// `action` is a backend vocabulary string (e.g. `SETTINGS_UPDATED`). It is
/// shown verbatim when the client has no translation for it rather than being
/// reworded into something the audit trail does not actually say.
class PartnerActivityLogEntry {
  final int id;
  final String action;
  final String? actorName;
  final String? entityType;
  final int? entityId;
  final String? description;
  final DateTime? createdAt;

  const PartnerActivityLogEntry({
    required this.id,
    required this.action,
    this.actorName,
    this.entityType,
    this.entityId,
    this.description,
    this.createdAt,
  });

  static PartnerActivityLogEntry? fromJson(Map<String, dynamic> json) {
    final id = partnerAsInt(json['id']);
    if (id == null) return null;
    return PartnerActivityLogEntry(
      id: id,
      action: partnerAsString(json['action']) ?? '',
      actorName: partnerAsString(json['actorName']),
      entityType: partnerAsString(json['entityType']),
      entityId: partnerAsInt(json['entityId']),
      description: partnerAsString(json['description']),
      createdAt: partnerAsDate(json['createdAt']),
    );
  }
}

/// `dto/PartnerExtranetDto.MenuItem` — `(key, label, route, enabled, badgeCount)`.
///
/// `label` arrives from the backend in English. The client localises by [key]
/// where it has a translation and otherwise falls back to the server label, so
/// a menu entry added server-side still renders instead of disappearing.
/// `badgeCount` is nullable and a null badge is **not** rendered as zero.
class PartnerMenuItem {
  final String key;
  final String label;
  final String route;
  final bool enabled;
  final int? badgeCount;

  const PartnerMenuItem({
    required this.key,
    required this.label,
    required this.route,
    required this.enabled,
    this.badgeCount,
  });

  /// Only a positive badge means "this needs attention".
  bool get needsAttention => (badgeCount ?? 0) > 0;

  static PartnerMenuItem? fromJson(Map<String, dynamic> json) {
    final key = partnerAsString(json['key']);
    final route = partnerAsString(json['route']);
    if (key == null || route == null) return null;
    return PartnerMenuItem(
      key: key,
      label: partnerAsString(json['label']) ?? key,
      route: route,
      enabled: json['enabled'] != false,
      badgeCount: partnerAsInt(json['badgeCount']),
    );
  }
}

/// `dto/PartnerExtranetDto.QuickAction` — `(String label, String route)`.
///
/// The backend decides which actions are relevant (`buildQuickActions` only
/// offers "review today's arrivals" when there actually are arrivals), so the
/// client renders what it is given and never composes its own workflow.
class PartnerQuickAction {
  final String label;
  final String route;

  const PartnerQuickAction({required this.label, required this.route});

  static PartnerQuickAction? fromJson(Map<String, dynamic> json) {
    final label = partnerAsString(json['label']);
    final route = partnerAsString(json['route']);
    if (label == null || route == null) return null;
    return PartnerQuickAction(label: label, route: route);
  }
}

// ── Shared parsing helpers ─────────────────────────────────────────────────
//
// Public (not `_`-prefixed) so `partner_models.dart` can reuse them for the
// `financeSummary` / `quickActions` branches of the extranet home payload
// without a second copy of the same coercions.

List<PartnerTimeSeriesPoint> partnerAsSeries(Object? raw) {
  if (raw is! List) return const [];
  final points = <PartnerTimeSeriesPoint>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;
    final point = PartnerTimeSeriesPoint.fromJson(entry);
    if (point != null) points.add(point);
  }
  return points;
}

List<PartnerMetricBreakdown> partnerAsBreakdowns(Object? raw) {
  if (raw is! List) return const [];
  final items = <PartnerMetricBreakdown>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;
    items.add(PartnerMetricBreakdown.fromJson(entry));
  }
  return items;
}

int? partnerAsInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? partnerAsDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? partnerAsString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? partnerAsDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
