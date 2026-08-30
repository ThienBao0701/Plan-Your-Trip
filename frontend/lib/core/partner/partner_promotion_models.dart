/// Typed models for the Partner Promotions & Vouchers module (C7), mapped
/// one-to-one from `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree and verified
/// against the running backend:
///   * `controller/PartnerPromotionController` — `/api/partner/promotions`
///   * `dto/PromotionDto.PromotionRequest` / `PromotionResponse` /
///     `PromotionSummaryResponse` / `PricingBreakdownResponse`
///   * `service/PartnerPromotionService`, `service/PromotionService`,
///     `service/PricingEngineService`
///   * `dto/PartnerVoucherDto` — `POST /api/partner/bookings/voucher/verify`
///   * `model/PromotionType`, `DiscountType`, `PromotionTargetType`
///
/// ## "Promotion" and "voucher" are two unrelated things here
///
/// They are deliberately **not** modelled as one concept:
///
///  * A **promotion** is an automatic, rule-based discount the pricing engine
///    applies to a stay. It has a target, a validity window, a discount, a
///    priority and a stackable flag. Partners create and own these.
///  * A **voucher** in the partner API is an HMAC-signed **booking** QR payload
///    (`PYT-V1.<bookingCode>.<sig>`) that a front-desk clerk verifies to admit a
///    guest. It carries no discount at all.
///
/// The discount-code concept the word "voucher" usually implies is a **coupon**
/// or **gift card**, and both are admin/customer-only — there is no partner
/// coupon or gift-card API. See the C7 report.
///
/// ## Currency — split by endpoint
///
/// `PromotionResponse` carries **no currency**, exactly like `RatePlan` (C5), so
/// `discountValue`, `maxDiscountAmount` and `minimumSpend` are unqualified
/// numbers. `PricingBreakdownResponse` **does** carry `String currency`
/// (live: `"VND"`), so the pricing preview — and only the preview — may show it.
library;

/// `model/PromotionType` — eight values.
enum PartnerPromotionType {
  general,
  room,
  hotel,
  member,
  earlyBird,
  lastMinute,
  weekend,
  holiday,
  unknown;

  static PartnerPromotionType parse(Object? raw) {
    if (raw is! String) return PartnerPromotionType.unknown;
    switch (raw) {
      case 'GENERAL':
        return PartnerPromotionType.general;
      case 'ROOM':
        return PartnerPromotionType.room;
      case 'HOTEL':
        return PartnerPromotionType.hotel;
      case 'MEMBER':
        return PartnerPromotionType.member;
      case 'EARLY_BIRD':
        return PartnerPromotionType.earlyBird;
      case 'LAST_MINUTE':
        return PartnerPromotionType.lastMinute;
      case 'WEEKEND':
        return PartnerPromotionType.weekend;
      case 'HOLIDAY':
        return PartnerPromotionType.holiday;
      default:
        return PartnerPromotionType.unknown;
    }
  }

  /// The wire literal, for a lossless read-modify-write.
  String? get wireValue => switch (this) {
        PartnerPromotionType.general => 'GENERAL',
        PartnerPromotionType.room => 'ROOM',
        PartnerPromotionType.hotel => 'HOTEL',
        PartnerPromotionType.member => 'MEMBER',
        PartnerPromotionType.earlyBird => 'EARLY_BIRD',
        PartnerPromotionType.lastMinute => 'LAST_MINUTE',
        PartnerPromotionType.weekend => 'WEEKEND',
        PartnerPromotionType.holiday => 'HOLIDAY',
        PartnerPromotionType.unknown => null,
      };
}

/// `model/DiscountType` — how [PartnerPromotion.discountValue] is read.
enum PartnerDiscountType {
  percentage,
  fixedAmount,
  unknown;

  static PartnerDiscountType parse(Object? raw) {
    if (raw is! String) return PartnerDiscountType.unknown;
    switch (raw) {
      case 'PERCENTAGE':
        return PartnerDiscountType.percentage;
      case 'FIXED_AMOUNT':
        return PartnerDiscountType.fixedAmount;
      default:
        return PartnerDiscountType.unknown;
    }
  }

  String? get wireValue => switch (this) {
        PartnerDiscountType.percentage => 'PERCENTAGE',
        PartnerDiscountType.fixedAmount => 'FIXED_AMOUNT',
        PartnerDiscountType.unknown => null,
      };
}

/// `model/PromotionTargetType`.
///
/// A partner may only own `HOTEL` or `ROOM` targets — `PartnerPromotionService`
/// answers a create with `targetType = ALL` with **403** ("Partners cannot
/// create global ALL promotions"), and an `ALL`-targeted promotion never appears
/// in a partner's list because `isOwnedTarget` returns false for it.
///
/// `targetId` means different things per type, which is easy to get wrong:
///   * `HOTEL` → a **`HotelDetail` id**, *not* a `Place` id.
///   * `ROOM`  → a `HotelRoom` id.
enum PartnerPromotionTargetType {
  all,
  hotel,
  room,
  unknown;

  static PartnerPromotionTargetType parse(Object? raw) {
    if (raw is! String) return PartnerPromotionTargetType.unknown;
    switch (raw) {
      case 'ALL':
        return PartnerPromotionTargetType.all;
      case 'HOTEL':
        return PartnerPromotionTargetType.hotel;
      case 'ROOM':
        return PartnerPromotionTargetType.room;
      default:
        return PartnerPromotionTargetType.unknown;
    }
  }

  String? get wireValue => switch (this) {
        PartnerPromotionTargetType.all => 'ALL',
        PartnerPromotionTargetType.hotel => 'HOTEL',
        PartnerPromotionTargetType.room => 'ROOM',
        PartnerPromotionTargetType.unknown => null,
      };

  /// Whether a partner can own a promotion with this target.
  bool get isPartnerOwnable =>
      this == PartnerPromotionTargetType.hotel ||
      this == PartnerPromotionTargetType.room;
}

/// `dto/PromotionDto.PromotionResponse` — 19 fields.
///
/// Every field of `PromotionRequest` (16) also appears here, which is what makes
/// a lossless read-modify-write `PUT` possible: the client can echo the whole
/// record back and change exactly one field. `PromotionService.fill` is a full
/// replace, so anything omitted would be nulled — echoing everything is the only
/// safe way to write.
class PartnerPromotion {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final bool active;

  /// Inclusive validity window; `endDate` must be strictly after `startDate`
  /// (`PromotionService.validateDates`).
  final DateTime? startDate;
  final DateTime? endDate;

  final PartnerPromotionType promotionType;
  final PartnerDiscountType discountType;

  /// A percentage (0–100) or a bare amount, depending on [discountType].
  /// **No currency accompanies it** — see the library doc.
  final double? discountValue;

  /// Cap on a percentage discount. Nullable.
  final double? maxDiscountAmount;

  final int? minimumStay;
  final double? minimumSpend;

  /// When false, `PricingEngineService` stops applying further promotions
  /// **after** this one — it still applies itself first.
  final bool stackable;

  /// Higher runs first (`Comparator.comparingInt(getPriority).reversed()`).
  final int priority;

  final PartnerPromotionTargetType targetType;
  final int? targetId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerPromotion({
    required this.id,
    required this.name,
    required this.active,
    required this.promotionType,
    required this.discountType,
    required this.stackable,
    required this.priority,
    required this.targetType,
    this.code,
    this.description,
    this.startDate,
    this.endDate,
    this.discountValue,
    this.maxDiscountAmount,
    this.minimumStay,
    this.minimumSpend,
    this.targetId,
    this.createdAt,
    this.updatedAt,
  });

  bool get isPercentage => discountType == PartnerDiscountType.percentage;

  /// Whether the window has elapsed. A fact about the dates, reported
  /// separately from [active] — a promotion can be both active and expired.
  bool isExpired([DateTime? now]) {
    final end = endDate;
    if (end == null) return false;
    final today = now ?? DateTime.now();
    return end.isBefore(DateTime(today.year, today.month, today.day));
  }

  /// Whether the window has not started yet.
  bool isScheduled([DateTime? now]) {
    final start = startDate;
    if (start == null) return false;
    final today = now ?? DateTime.now();
    return start.isAfter(DateTime(today.year, today.month, today.day));
  }

  bool get hasConditions => minimumStay != null || minimumSpend != null;

  /// The complete `PromotionRequest` body, echoing every stored field and
  /// overriding only what is passed.
  ///
  /// This is the **only** safe way to write: `PromotionService.fill` replaces
  /// all sixteen fields, so a partial body would silently null `code`,
  /// `description`, `maxDiscountAmount`, `minimumStay` and `minimumSpend`.
  Map<String, dynamic> toRequestJson({bool? activeOverride}) => {
        'name': name,
        'code': code,
        'description': description,
        'promotionType': promotionType.wireValue,
        'discountType': discountType.wireValue,
        'discountValue': discountValue,
        'maxDiscountAmount': maxDiscountAmount,
        'minimumStay': minimumStay,
        'minimumSpend': minimumSpend,
        'stackable': stackable,
        'priority': priority,
        'startDate': startDate == null ? null : _isoDate(startDate!),
        'endDate': endDate == null ? null : _isoDate(endDate!),
        'active': activeOverride ?? active,
        'targetType': targetType.wireValue,
        'targetId': targetId,
      };

  /// True when every field the request needs is present, so a lossless
  /// read-modify-write can be attempted. Guards against writing a record the
  /// client only partially understood.
  bool get canRoundTrip =>
      name.isNotEmpty &&
      promotionType.wireValue != null &&
      discountType.wireValue != null &&
      discountValue != null &&
      startDate != null &&
      endDate != null &&
      targetType.wireValue != null;

  PartnerPromotion copyWithActive(bool value) => PartnerPromotion(
        id: id,
        name: name,
        code: code,
        description: description,
        active: value,
        startDate: startDate,
        endDate: endDate,
        promotionType: promotionType,
        discountType: discountType,
        discountValue: discountValue,
        maxDiscountAmount: maxDiscountAmount,
        minimumStay: minimumStay,
        minimumSpend: minimumSpend,
        stackable: stackable,
        priority: priority,
        targetType: targetType,
        targetId: targetId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static PartnerPromotion? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerPromotion(
      id: id,
      name: _asString(json['name']) ?? '',
      code: _asString(json['code']),
      description: _asString(json['description']),
      active: json['active'] == true,
      startDate: _asDate(json['startDate']),
      endDate: _asDate(json['endDate']),
      promotionType: PartnerPromotionType.parse(json['promotionType']),
      discountType: PartnerDiscountType.parse(json['discountType']),
      discountValue: _asDouble(json['discountValue']),
      maxDiscountAmount: _asDouble(json['maxDiscountAmount']),
      minimumStay: _asInt(json['minimumStay']),
      minimumSpend: _asDouble(json['minimumSpend']),
      stackable: json['stackable'] == true,
      priority: _asInt(json['priority']) ?? 0,
      targetType: PartnerPromotionTargetType.parse(json['targetType']),
      targetId: _asInt(json['targetId']),
      createdAt: _asInstant(json['createdAt']),
      updatedAt: _asInstant(json['updatedAt']),
    );
  }
}

/// `dto/PromotionDto.PromotionSummaryResponse` — one promotion as the pricing
/// engine actually applied it, including the resulting amount.
class PartnerAppliedPromotion {
  final int? promotionId;
  final String? name;
  final String? code;
  final PartnerDiscountType discountType;
  final double? discountValue;

  /// The amount this promotion actually removed. **Backend-computed** — the
  /// client performs no pricing arithmetic.
  final double? discountApplied;

  const PartnerAppliedPromotion({
    required this.discountType,
    this.promotionId,
    this.name,
    this.code,
    this.discountValue,
    this.discountApplied,
  });

  static PartnerAppliedPromotion fromJson(Map<String, dynamic> json) =>
      PartnerAppliedPromotion(
        promotionId: _asInt(json['promotionId']),
        name: _asString(json['name']),
        code: _asString(json['code']),
        discountType: PartnerDiscountType.parse(json['discountType']),
        discountValue: _asDouble(json['discountValue']),
        discountApplied: _asDouble(json['discountApplied']),
      );
}

/// `dto/PromotionDto.PricingBreakdownResponse` from
/// `GET /api/partner/rooms/{roomId}/pricing-preview`.
///
/// The one partner-facing payload that **does** carry a currency (live:
/// `"VND"`), so amounts here may be qualified where promotion amounts may not.
class PartnerPricingPreview {
  final int? roomId;
  final String? roomName;
  final String? roomCode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final double? basePrice;
  final double? ratePlanPrice;
  final String? ratePlanName;
  final double? promotionDiscount;
  final double? finalPrice;

  /// Backend-supplied currency code. Null is possible in principle and is
  /// rendered as an unqualified number rather than a guessed symbol.
  final String? currency;

  final List<PartnerAppliedPromotion> appliedPromotions;

  const PartnerPricingPreview({
    required this.nights,
    required this.appliedPromotions,
    this.roomId,
    this.roomName,
    this.roomCode,
    this.checkIn,
    this.checkOut,
    this.basePrice,
    this.ratePlanPrice,
    this.ratePlanName,
    this.promotionDiscount,
    this.finalPrice,
    this.currency,
  });

  bool get hasPromotions => appliedPromotions.isNotEmpty;

  static PartnerPricingPreview? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('nights')) return null;
    final raw = json['appliedPromotions'];
    final applied = <PartnerAppliedPromotion>[];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        applied.add(PartnerAppliedPromotion.fromJson(entry));
      }
    }
    return PartnerPricingPreview(
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      roomCode: _asString(json['roomCode']),
      checkIn: _asDate(json['checkIn']),
      checkOut: _asDate(json['checkOut']),
      nights: _asInt(json['nights']) ?? 0,
      basePrice: _asDouble(json['basePrice']),
      ratePlanPrice: _asDouble(json['ratePlanPrice']),
      ratePlanName: _asString(json['ratePlanName']),
      promotionDiscount: _asDouble(json['promotionDiscount']),
      finalPrice: _asDouble(json['finalPrice']),
      currency: _asString(json['currency']),
      appliedPromotions: List.unmodifiable(applied),
    );
  }
}

/// `dto/PartnerVoucherDto.VoucherVerificationResponse`.
///
/// A **booking** voucher, not a discount. The endpoint is
/// `@Transactional(readOnly = true)` and mutates nothing: it verifies the HMAC
/// signature, resolves the booking, confirms partner ownership and reports
/// check-in eligibility. Actual check-in is a separate booking operation.
///
/// The projection is deliberately minimal and staff-facing — it carries no
/// payment, coupon, loyalty or contact data.
class PartnerVoucherVerification {
  final bool verified;
  final bool eligible;

  /// The backend's own explanation, shown verbatim.
  final String? reason;

  final String? bookingCode;
  final String? bookingStatus;
  final int? hotelId;
  final String? hotelName;
  final int? roomId;
  final String? roomName;
  final String? guestName;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int? adults;
  final int? children;
  final int nights;

  const PartnerVoucherVerification({
    required this.verified,
    required this.eligible,
    required this.nights,
    this.reason,
    this.bookingCode,
    this.bookingStatus,
    this.hotelId,
    this.hotelName,
    this.roomId,
    this.roomName,
    this.guestName,
    this.checkInDate,
    this.checkOutDate,
    this.adults,
    this.children,
  });

  static PartnerVoucherVerification? fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('verified')) return null;
    final occ = json['occupancy'];
    final occupancy =
        occ is Map<String, dynamic> ? occ : const <String, dynamic>{};
    return PartnerVoucherVerification(
      verified: json['verified'] == true,
      eligible: json['eligible'] == true,
      reason: _asString(json['reason']),
      bookingCode: _asString(json['bookingCode']),
      bookingStatus: _asString(json['bookingStatus']),
      hotelId: _asInt(json['hotelId']),
      hotelName: _asString(json['hotelName']),
      roomId: _asInt(json['roomId']),
      roomName: _asString(json['roomName']),
      guestName: _asString(json['guestName']),
      checkInDate: _asDate(json['checkInDate']),
      checkOutDate: _asDate(json['checkOutDate']),
      adults: _asInt(occupancy['adults']),
      children: _asInt(occupancy['children']),
      nights: _asInt(json['nights']) ?? 0,
    );
  }
}

String _isoDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

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

/// `LocalDate` — a calendar day with no zone, parsed as a plain local date so it
/// cannot shift across a timezone boundary.
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

DateTime? _asInstant(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
