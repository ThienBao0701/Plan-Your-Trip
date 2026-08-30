/// Typed models for the Partner Rates module (C5), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree and verified
/// against the running backend:
///   * `controller/PartnerPricingController` — `/api/partner/rooms/{roomId}/rate-plans`
///     and `/api/partner/rate-plans/**`
///   * `dto/RatePlanDto.*`
///   * `service/RatePlanService` — validation and conflict rules
///   * `service/RatePlanEligibilityService` — how the validity window is applied
///   * `model/RatePlanType`, `MealPlanType`, `CancellationPolicyType`,
///     `RateSourceType`, `RateAdjustmentType`
///
/// ## Currency — a deliberate absence
///
/// **`RatePlan` carries no currency.** Not on the DTO, not on the entity, not in
/// the `rate_plans` table. `Booking`, `Invoice`, `Payment` and `GiftCard` all do
/// (seeded `"VND"`), so the platform has a currency concept — it simply is not
/// part of the rate contract. Every money field here is therefore an unqualified
/// `BigDecimal`, rendered as a grouped number with no symbol. Printing `₫`
/// because the app has a Vietnamese locale would be inventing a fact the API
/// never stated.
///
/// ## Validity window — NOT the same as C4's calendar
///
/// `startDate`/`endDate` are `LocalDate` and **both inclusive**, but measured
/// against *nights*: `RatePlanEligibilityService` rejects a stay when
/// `startDate > checkIn || endDate < lastNight` (where `lastNight = checkOut-1`).
/// Creation additionally requires `endDate` **strictly after** `startDate`
/// (`validateDates`), so a zero-length plan is impossible — unlike the C4
/// inventory calendar, where `from == to` is a legitimate single day.
library;

/// `model/RatePlanType` — five values.
enum PartnerRatePlanType {
  standard,
  promotional,
  member,
  earlyBird,
  lastMinute,
  unknown;

  static PartnerRatePlanType parse(Object? raw) {
    if (raw is! String) return PartnerRatePlanType.unknown;
    switch (raw) {
      case 'STANDARD':
        return PartnerRatePlanType.standard;
      case 'PROMOTIONAL':
        return PartnerRatePlanType.promotional;
      case 'MEMBER':
        return PartnerRatePlanType.member;
      case 'EARLY_BIRD':
        return PartnerRatePlanType.earlyBird;
      case 'LAST_MINUTE':
        return PartnerRatePlanType.lastMinute;
      default:
        return PartnerRatePlanType.unknown;
    }
  }
}

/// `model/MealPlanType` — five values. Nullable on the response.
enum PartnerMealPlanType {
  roomOnly,
  breakfast,
  halfBoard,
  fullBoard,
  allInclusive,
  unknown;

  static PartnerMealPlanType? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) return PartnerMealPlanType.unknown;
    switch (raw) {
      case 'ROOM_ONLY':
        return PartnerMealPlanType.roomOnly;
      case 'BREAKFAST':
        return PartnerMealPlanType.breakfast;
      case 'HALF_BOARD':
        return PartnerMealPlanType.halfBoard;
      case 'FULL_BOARD':
        return PartnerMealPlanType.fullBoard;
      case 'ALL_INCLUSIVE':
        return PartnerMealPlanType.allInclusive;
      default:
        return PartnerMealPlanType.unknown;
    }
  }
}

/// `model/CancellationPolicyType` — four values. Nullable on the response.
enum PartnerCancellationPolicyType {
  freeCancellation,
  partiallyRefundable,
  nonRefundable,
  custom,
  unknown;

  static PartnerCancellationPolicyType? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) return PartnerCancellationPolicyType.unknown;
    switch (raw) {
      case 'FREE_CANCELLATION':
        return PartnerCancellationPolicyType.freeCancellation;
      case 'PARTIALLY_REFUNDABLE':
        return PartnerCancellationPolicyType.partiallyRefundable;
      case 'NON_REFUNDABLE':
        return PartnerCancellationPolicyType.nonRefundable;
      case 'CUSTOM':
        return PartnerCancellationPolicyType.custom;
      default:
        return PartnerCancellationPolicyType.unknown;
    }
  }
}

/// `model/RateSourceType` — whether a plan prices itself (`BASE`) or is derived
/// from a parent by an adjustment (`DERIVED`).
enum PartnerRateSourceType {
  base,
  derived,
  unknown;

  static PartnerRateSourceType parse(Object? raw) {
    if (raw is! String) return PartnerRateSourceType.unknown;
    switch (raw) {
      case 'BASE':
        return PartnerRateSourceType.base;
      case 'DERIVED':
        return PartnerRateSourceType.derived;
      default:
        return PartnerRateSourceType.unknown;
    }
  }
}

/// `model/RateAdjustmentType`. Nullable — only DERIVED plans carry one.
enum PartnerRateAdjustmentType {
  fixedAmount,
  percentage,
  unknown;

  static PartnerRateAdjustmentType? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) return PartnerRateAdjustmentType.unknown;
    switch (raw) {
      case 'FIXED_AMOUNT':
        return PartnerRateAdjustmentType.fixedAmount;
      case 'PERCENTAGE':
        return PartnerRateAdjustmentType.percentage;
      default:
        return PartnerRateAdjustmentType.unknown;
    }
  }
}

/// `dto/RatePlanDto.RatePlanResponse` — 31 fields, verified against the wire.
///
/// The boxed types in the record (`Integer`, `BigDecimal`) are genuinely
/// nullable and stay null here; the primitives (`boolean`, `int priority`) are
/// never null. Live seed data returns null for `code`, `description`,
/// `cancellationDeadlineHours`, `cancellationPenaltyPercent`, `minStayNights`,
/// `maxStayNights`, advance-booking days and `extraBedPrice`.
class PartnerRatePlan {
  final int id;
  final int? roomId;
  final String rateName;
  final PartnerRatePlanType rateType;

  /// Nightly price. **No currency accompanies this value** — see the library doc.
  final double? pricePerNight;

  /// Inclusive validity window. `endDate` is strictly after `startDate`.
  final DateTime? startDate;
  final DateTime? endDate;

  final bool active;

  final String? code;
  final String? description;
  final PartnerMealPlanType? mealPlanType;
  final PartnerCancellationPolicyType? cancellationPolicyType;
  final int? cancellationDeadlineHours;
  final double? cancellationPenaltyPercent;
  final bool refundable;

  final PartnerRateSourceType sourceType;

  /// Set only when [sourceType] is DERIVED.
  final int? parentRatePlanId;
  final PartnerRateAdjustmentType? adjustmentType;
  final double? adjustmentValue;

  /// Resolution order between overlapping plans. The backend permits
  /// overlapping validity windows on one room; priority is how it picks.
  final int priority;

  final int? minStayNights;
  final int? maxStayNights;
  final int? minAdvanceBookingDays;
  final int? maxAdvanceBookingDays;

  /// Rate-plan level CTA/CTD. Distinct from the C4 per-day inventory flags of
  /// the same name — these are terms of the plan, not of a date.
  final bool closedToArrival;
  final bool closedToDeparture;

  final bool occupancyPricingEnabled;
  final bool childPricingEnabled;
  final double? extraBedPrice;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerRatePlan({
    required this.id,
    required this.rateName,
    required this.rateType,
    required this.active,
    required this.refundable,
    required this.sourceType,
    required this.priority,
    required this.closedToArrival,
    required this.closedToDeparture,
    required this.occupancyPricingEnabled,
    required this.childPricingEnabled,
    this.roomId,
    this.pricePerNight,
    this.startDate,
    this.endDate,
    this.code,
    this.description,
    this.mealPlanType,
    this.cancellationPolicyType,
    this.cancellationDeadlineHours,
    this.cancellationPenaltyPercent,
    this.parentRatePlanId,
    this.adjustmentType,
    this.adjustmentValue,
    this.minStayNights,
    this.maxStayNights,
    this.minAdvanceBookingDays,
    this.maxAdvanceBookingDays,
    this.extraBedPrice,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDerived => sourceType == PartnerRateSourceType.derived;

  /// True when the plan's inclusive window covers [day].
  bool coversDate(DateTime day) {
    final start = startDate;
    final end = endDate;
    if (start == null || end == null) return false;
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  /// Whether the window has already elapsed relative to [now]. Presented as a
  /// fact about the dates, never as a substitute for [active].
  bool isExpired([DateTime? now]) {
    final end = endDate;
    if (end == null) return false;
    final today = now ?? DateTime.now();
    return end.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Any stay restriction is configured.
  bool get hasRestrictions =>
      minStayNights != null ||
      maxStayNights != null ||
      minAdvanceBookingDays != null ||
      maxAdvanceBookingDays != null ||
      closedToArrival ||
      closedToDeparture;

  PartnerRatePlan copyWithActive(bool value) => PartnerRatePlan(
        id: id,
        roomId: roomId,
        rateName: rateName,
        rateType: rateType,
        pricePerNight: pricePerNight,
        startDate: startDate,
        endDate: endDate,
        active: value,
        code: code,
        description: description,
        mealPlanType: mealPlanType,
        cancellationPolicyType: cancellationPolicyType,
        cancellationDeadlineHours: cancellationDeadlineHours,
        cancellationPenaltyPercent: cancellationPenaltyPercent,
        refundable: refundable,
        sourceType: sourceType,
        parentRatePlanId: parentRatePlanId,
        adjustmentType: adjustmentType,
        adjustmentValue: adjustmentValue,
        priority: priority,
        minStayNights: minStayNights,
        maxStayNights: maxStayNights,
        minAdvanceBookingDays: minAdvanceBookingDays,
        maxAdvanceBookingDays: maxAdvanceBookingDays,
        closedToArrival: closedToArrival,
        closedToDeparture: closedToDeparture,
        occupancyPricingEnabled: occupancyPricingEnabled,
        childPricingEnabled: childPricingEnabled,
        extraBedPrice: extraBedPrice,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static PartnerRatePlan? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerRatePlan(
      id: id,
      roomId: _asInt(json['roomId']),
      rateName: _asString(json['rateName']) ?? '',
      rateType: PartnerRatePlanType.parse(json['rateType']),
      pricePerNight: _asDouble(json['pricePerNight']),
      startDate: _asDate(json['startDate']),
      endDate: _asDate(json['endDate']),
      active: json['active'] == true,
      code: _asString(json['code']),
      description: _asString(json['description']),
      mealPlanType: PartnerMealPlanType.parse(json['mealPlanType']),
      cancellationPolicyType:
          PartnerCancellationPolicyType.parse(json['cancellationPolicyType']),
      cancellationDeadlineHours: _asInt(json['cancellationDeadlineHours']),
      cancellationPenaltyPercent: _asDouble(json['cancellationPenaltyPercent']),
      refundable: json['refundable'] == true,
      sourceType: PartnerRateSourceType.parse(json['sourceType']),
      parentRatePlanId: _asInt(json['parentRatePlanId']),
      adjustmentType: PartnerRateAdjustmentType.parse(json['adjustmentType']),
      adjustmentValue: _asDouble(json['adjustmentValue']),
      priority: _asInt(json['priority']) ?? 0,
      minStayNights: _asInt(json['minStayNights']),
      maxStayNights: _asInt(json['maxStayNights']),
      minAdvanceBookingDays: _asInt(json['minAdvanceBookingDays']),
      maxAdvanceBookingDays: _asInt(json['maxAdvanceBookingDays']),
      closedToArrival: json['closedToArrival'] == true,
      closedToDeparture: json['closedToDeparture'] == true,
      occupancyPricingEnabled: json['occupancyPricingEnabled'] == true,
      childPricingEnabled: json['childPricingEnabled'] == true,
      extraBedPrice: _asDouble(json['extraBedPrice']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// `dto/RatePlanDto.RatePlanOccupancyPriceResponse`.
class PartnerOccupancyPrice {
  final int id;
  final int? ratePlanId;
  final int adults;
  final int children;
  final double? pricePerNight;
  final double? childSupplement;
  final double? extraBedSupplement;

  const PartnerOccupancyPrice({
    required this.id,
    required this.adults,
    required this.children,
    this.ratePlanId,
    this.pricePerNight,
    this.childSupplement,
    this.extraBedSupplement,
  });

  static PartnerOccupancyPrice? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerOccupancyPrice(
      id: id,
      ratePlanId: _asInt(json['ratePlanId']),
      adults: _asInt(json['adults']) ?? 0,
      children: _asInt(json['children']) ?? 0,
      pricePerNight: _asDouble(json['pricePerNight']),
      childSupplement: _asDouble(json['childSupplement']),
      extraBedSupplement: _asDouble(json['extraBedSupplement']),
    );
  }
}

/// `dto/RatePlanDto.RatePlanPricingBreakdownResponse` — the computed preview of
/// one plan against one stay.
///
/// Every amount is backend-computed. The client performs **no** pricing
/// arithmetic; `PricingEngineService` owns that, and a plausible client-side
/// total would be a financial claim the API never made.
class PartnerRatePreview {
  final int? ratePlanId;
  final String? code;
  final String? rateName;
  final int? roomId;
  final String? roomName;
  final PartnerRateSourceType sourceType;
  final int? parentRatePlanId;
  final bool eligible;

  /// The backend's own explanation, e.g. "Stay is outside the rate plan's date
  /// range". Shown verbatim — it is the authoritative reason.
  final String? reason;

  final int nights;
  final double? baseNightlyRate;
  final double? derivedAdjustment;
  final double? occupancyAdjustment;
  final double? childSupplement;
  final double? extraBedSupplement;
  final double? finalNightlyRate;
  final double? staySubtotal;

  final PartnerMealPlanType? mealPlan;
  final PartnerCancellationPolicyType? cancellationPolicy;
  final bool refundable;
  final DateTime? cancellationDeadline;
  final String? policySummary;

  const PartnerRatePreview({
    required this.eligible,
    required this.nights,
    required this.refundable,
    required this.sourceType,
    this.ratePlanId,
    this.code,
    this.rateName,
    this.roomId,
    this.roomName,
    this.parentRatePlanId,
    this.reason,
    this.baseNightlyRate,
    this.derivedAdjustment,
    this.occupancyAdjustment,
    this.childSupplement,
    this.extraBedSupplement,
    this.finalNightlyRate,
    this.staySubtotal,
    this.mealPlan,
    this.cancellationPolicy,
    this.cancellationDeadline,
    this.policySummary,
  });

  static PartnerRatePreview? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('eligible')) return null;
    return PartnerRatePreview(
      ratePlanId: _asInt(json['ratePlanId']),
      code: _asString(json['code']),
      rateName: _asString(json['rateName']),
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      sourceType: PartnerRateSourceType.parse(json['sourceType']),
      parentRatePlanId: _asInt(json['parentRatePlanId']),
      eligible: json['eligible'] == true,
      reason: _asString(json['reason']),
      nights: _asInt(json['nights']) ?? 0,
      baseNightlyRate: _asDouble(json['baseNightlyRate']),
      derivedAdjustment: _asDouble(json['derivedAdjustment']),
      occupancyAdjustment: _asDouble(json['occupancyAdjustment']),
      childSupplement: _asDouble(json['childSupplement']),
      extraBedSupplement: _asDouble(json['extraBedSupplement']),
      finalNightlyRate: _asDouble(json['finalNightlyRate']),
      staySubtotal: _asDouble(json['staySubtotal']),
      mealPlan: PartnerMealPlanType.parse(json['mealPlan']),
      cancellationPolicy:
          PartnerCancellationPolicyType.parse(json['cancellationPolicy']),
      refundable: json['refundable'] == true,
      cancellationDeadline: _asInstant(json['cancellationDeadline']),
      policySummary: _asString(json['policySummary']),
    );
  }
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// `startDate`/`endDate` are `LocalDate` — a calendar day with no zone, parsed
/// as a plain local date so it cannot shift across a timezone boundary.
DateTime? _asDate(Object? value) {
  if (value is! String) return null;
  final parts = value.split('-');
  if (parts.length < 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2].substring(0, 2));
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

/// `createdAt` / `cancellationDeadline` are true `Instant`s.
DateTime? _asInstant(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
