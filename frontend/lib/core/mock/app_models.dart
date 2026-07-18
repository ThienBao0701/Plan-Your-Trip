import 'package:flutter/material.dart';

class Category {
  final String id;
  final String slug;
  final String type;
  final String? parentSlug;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final int sortOrder;

  const Category({
    required this.id,
    String? slug,
    String? type,
    this.parentSlug,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.sortOrder,
  })  : slug = slug ?? id,
        type = type ?? id;
}

class Place {
  final int id;
  final String name;
  final String category;
  final String? categorySlug;
  final String? subcategorySlug;
  final String locationName;
  final String city;
  final String province;
  final String country;
  final String address;
  final double? latitude;
  final double? longitude;
  final String description;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final String priceLevel;
  final int estimatedDurationMinutes;
  final String? openingHours;
  final List<String> tags;
  final bool isFeatured;
  final bool isNearby;
  final bool verified;
  final HotelDetail? hotelDetail;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    this.categorySlug,
    this.subcategorySlug,
    required this.locationName,
    required this.city,
    required this.province,
    this.country = 'Vietnam',
    this.address = '',
    this.latitude,
    this.longitude,
    required this.description,
    required this.imageUrl,
    required this.rating,
    this.reviewCount = 0,
    this.priceLevel = '\$\$',
    this.estimatedDurationMinutes = 60,
    this.openingHours,
    this.tags = const [],
    this.isFeatured = false,
    this.isNearby = false,
    this.verified = false,
    this.hotelDetail,
  });

  // Backward-compat accessors used by existing widgets
  String get location => locationName;
  String get priceRange => priceLevel;
  String get effectiveCategorySlug =>
      categorySlug ?? category.toLowerCase().replaceAll(' ', '-');
}

enum RoomType {
  standard,
  superior,
  deluxe,
  premier,
  executive,
  suite,
  family,
  villa,
  bungalow,
}

extension RoomTypeData on RoomType {
  String get code {
    switch (this) {
      case RoomType.standard:
        return 'STANDARD';
      case RoomType.superior:
        return 'SUPERIOR';
      case RoomType.deluxe:
        return 'DELUXE';
      case RoomType.premier:
        return 'PREMIER';
      case RoomType.executive:
        return 'EXECUTIVE';
      case RoomType.suite:
        return 'SUITE';
      case RoomType.family:
        return 'FAMILY';
      case RoomType.villa:
        return 'VILLA';
      case RoomType.bungalow:
        return 'BUNGALOW';
    }
  }
}

enum BedType {
  single,
  double,
  twin,
  queen,
  king,
  sofaBed,
  bunk,
}

extension BedTypeData on BedType {
  String get code {
    switch (this) {
      case BedType.single:
        return 'SINGLE';
      case BedType.double:
        return 'DOUBLE';
      case BedType.twin:
        return 'TWIN';
      case BedType.queen:
        return 'QUEEN';
      case BedType.king:
        return 'KING';
      case BedType.sofaBed:
        return 'SOFA_BED';
      case BedType.bunk:
        return 'BUNK';
    }
  }
}

enum MealPlanType {
  roomOnly,
  breakfast,
  halfBoard,
  fullBoard,
  allInclusive,
}

extension MealPlanTypeData on MealPlanType {
  String get code {
    switch (this) {
      case MealPlanType.roomOnly:
        return 'ROOM_ONLY';
      case MealPlanType.breakfast:
        return 'BREAKFAST';
      case MealPlanType.halfBoard:
        return 'HALF_BOARD';
      case MealPlanType.fullBoard:
        return 'FULL_BOARD';
      case MealPlanType.allInclusive:
        return 'ALL_INCLUSIVE';
    }
  }
}

enum CancellationPolicyType {
  freeCancellation,
  partiallyRefundable,
  nonRefundable,
  custom,
}

extension CancellationPolicyTypeData on CancellationPolicyType {
  String get code {
    switch (this) {
      case CancellationPolicyType.freeCancellation:
        return 'FREE_CANCELLATION';
      case CancellationPolicyType.partiallyRefundable:
        return 'PARTIALLY_REFUNDABLE';
      case CancellationPolicyType.nonRefundable:
        return 'NON_REFUNDABLE';
      case CancellationPolicyType.custom:
        return 'CUSTOM';
    }
  }
}

enum BookingStatus {
  pending,
  confirmed,
  checkInReady,
  checkedIn,
  checkedOut,
  completed,
  cancelled,
  refunded,
  archived,
  noShow,
}

extension BookingStatusData on BookingStatus {
  String get code {
    switch (this) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.checkInReady:
        return 'CHECK_IN_READY';
      case BookingStatus.checkedIn:
        return 'CHECKED_IN';
      case BookingStatus.checkedOut:
        return 'CHECKED_OUT';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
      case BookingStatus.refunded:
        return 'REFUNDED';
      case BookingStatus.archived:
        return 'ARCHIVED';
      case BookingStatus.noShow:
        return 'NO_SHOW';
    }
  }

  bool get canCancel =>
      this == BookingStatus.pending ||
      this == BookingStatus.confirmed ||
      this == BookingStatus.checkInReady;
}

class HotelDetail {
  final int? starRating;
  final String? checkInTime;
  final String? checkOutTime;
  final int? distanceToBeachMeters;
  final int? distanceToCityCenterMeters;
  final int? totalRooms;
  final int? availableRooms;
  final bool? freeCancellation;
  final String? cancellationPolicy;
  final bool? prepaymentRequired;
  final String? paymentPolicy;
  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;
  final bool? breakfastIncluded;
  final bool? airportShuttle;
  final List<String> facilities;
  final List<String> services;
  final List<String> languages;
  final List<String> paymentMethods;
  final String? parking;
  final String? internet;
  final List<HotelRoom> rooms;

  const HotelDetail({
    this.starRating,
    this.checkInTime,
    this.checkOutTime,
    this.distanceToBeachMeters,
    this.distanceToCityCenterMeters,
    this.totalRooms,
    this.availableRooms,
    this.freeCancellation,
    this.cancellationPolicy,
    this.prepaymentRequired,
    this.paymentPolicy,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
    this.breakfastIncluded,
    this.airportShuttle,
    this.facilities = const [],
    this.services = const [],
    this.languages = const [],
    this.paymentMethods = const [],
    this.parking,
    this.internet,
    this.rooms = const [],
  });
}

class HotelRoom {
  final int id;
  final String roomName;
  final String roomCode;
  final RoomType roomType;
  final String description;
  final BedType bedType;
  final int bedCount;
  final int maxAdults;
  final int maxChildren;
  final int maxGuests;
  final int? roomSizeSqm;
  final int? floorNumber;
  final bool smokingAllowed;
  final bool breakfastIncluded;
  final bool freeCancellation;
  final bool instantConfirmation;
  final double? priceFrom;
  final double? originalPrice;
  final int quantity;
  final int availableQuantity;
  final bool active;
  final List<String> amenities;
  final String? coverImageUrl;
  final List<String> galleryImages;
  final List<HotelRatePlan> ratePlans;

  const HotelRoom({
    required this.id,
    required this.roomName,
    required this.roomCode,
    required this.roomType,
    required this.description,
    required this.bedType,
    this.bedCount = 1,
    this.maxAdults = 1,
    this.maxChildren = 0,
    this.maxGuests = 1,
    this.roomSizeSqm,
    this.floorNumber,
    this.smokingAllowed = false,
    this.breakfastIncluded = false,
    this.freeCancellation = false,
    this.instantConfirmation = false,
    this.priceFrom,
    this.originalPrice,
    this.quantity = 0,
    this.availableQuantity = 0,
    this.active = true,
    this.amenities = const [],
    this.coverImageUrl,
    this.galleryImages = const [],
    this.ratePlans = const [],
  });

  bool get sellable => active && availableQuantity > 0;
}

class HotelRatePlan {
  final int ratePlanId;
  final String code;
  final String rateName;
  final int roomId;
  final String roomName;
  final String sourceType;
  final int? parentRatePlanId;
  final bool eligible;
  final String? reason;
  final int nights;
  final double? baseNightlyRate;
  final double derivedAdjustment;
  final double occupancyAdjustment;
  final double childSupplement;
  final double extraBedSupplement;
  final double? finalNightlyRate;
  final double? staySubtotal;
  final MealPlanType mealPlan;
  final CancellationPolicyType cancellationPolicyType;
  final bool refundable;
  final DateTime? cancellationDeadline;
  final String policySummary;

  const HotelRatePlan({
    required this.ratePlanId,
    required this.code,
    required this.rateName,
    required this.roomId,
    required this.roomName,
    this.sourceType = 'LOCAL_PREVIEW',
    this.parentRatePlanId,
    this.eligible = true,
    this.reason,
    this.nights = 1,
    this.baseNightlyRate,
    this.derivedAdjustment = 0,
    this.occupancyAdjustment = 0,
    this.childSupplement = 0,
    this.extraBedSupplement = 0,
    this.finalNightlyRate,
    this.staySubtotal,
    this.mealPlan = MealPlanType.roomOnly,
    this.cancellationPolicyType = CancellationPolicyType.custom,
    this.refundable = false,
    this.cancellationDeadline,
    this.policySummary = '',
  });
}

class HotelStayCriteria {
  final String destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int extraBeds;
  final int? tripId;

  const HotelStayCriteria({
    this.destination = '',
    required this.checkIn,
    required this.checkOut,
    this.adults = 1,
    this.children = 0,
    this.extraBeds = 0,
    this.tripId,
  });

  int get nights => _dateOnly(checkOut).difference(_dateOnly(checkIn)).inDays;
  int get guests => adults + children;

  HotelStayCriteria copyWith({
    String? destination,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? extraBeds,
    Object? tripId = _unset,
  }) =>
      HotelStayCriteria(
        destination: destination ?? this.destination,
        checkIn: checkIn ?? this.checkIn,
        checkOut: checkOut ?? this.checkOut,
        adults: adults ?? this.adults,
        children: children ?? this.children,
        extraBeds: extraBeds ?? this.extraBeds,
        tripId: identical(tripId, _unset) ? this.tripId : tripId as int?,
      );

  static const Object _unset = Object();

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class HotelPricingQuote {
  final int roomId;
  final String roomName;
  final String roomCode;
  final int placeId;
  final int? hotelId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final int extraBeds;
  final int? selectedRatePlanId;
  final String? selectedRatePlanCode;
  final String? selectedRatePlanName;
  final MealPlanType? mealPlanType;
  final CancellationPolicyType? cancellationPolicyType;
  final bool refundable;
  final DateTime? cancellationDeadline;
  final double? baseNightlyRate;
  final double derivedAdjustment;
  final double occupancyAdjustment;
  final double childSupplement;
  final double extraBedSupplement;
  final double? finalNightlyRate;
  final double? staySubtotal;
  final double promotionDiscount;
  final double? totalBeforeCustomerBenefits;
  final double? finalQuotedPrice;
  final String currency;
  final bool inventoryAvailable;
  final int availableRooms;
  final DateTime quoteGeneratedAt;
  final DateTime quoteExpiresAt;
  final List<String> warnings;
  final String? eligibilityReason;

  const HotelPricingQuote({
    required this.roomId,
    required this.roomName,
    required this.roomCode,
    required this.placeId,
    this.hotelId,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    this.extraBeds = 0,
    this.selectedRatePlanId,
    this.selectedRatePlanCode,
    this.selectedRatePlanName,
    this.mealPlanType,
    this.cancellationPolicyType,
    this.refundable = false,
    this.cancellationDeadline,
    this.baseNightlyRate,
    this.derivedAdjustment = 0,
    this.occupancyAdjustment = 0,
    this.childSupplement = 0,
    this.extraBedSupplement = 0,
    this.finalNightlyRate,
    this.staySubtotal,
    this.promotionDiscount = 0,
    this.totalBeforeCustomerBenefits,
    this.finalQuotedPrice,
    this.currency = 'VND',
    this.inventoryAvailable = true,
    this.availableRooms = 0,
    required this.quoteGeneratedAt,
    required this.quoteExpiresAt,
    this.warnings = const [],
    this.eligibilityReason,
  });
}

class DemoBooking {
  final String code;
  final Place hotel;
  final HotelRoom room;
  final HotelRatePlan ratePlan;
  final HotelPricingQuote quote;
  final HotelStayCriteria criteria;
  final String specialRequest;
  final BookingStatus status;
  final DateTime createdAt;
  final String? cancellationReason;
  final bool itineraryAdded;

  const DemoBooking({
    required this.code,
    required this.hotel,
    required this.room,
    required this.ratePlan,
    required this.quote,
    required this.criteria,
    this.specialRequest = '',
    this.status = BookingStatus.confirmed,
    required this.createdAt,
    this.cancellationReason,
    this.itineraryAdded = false,
  });

  DemoBooking copyWith({
    String? code,
    Place? hotel,
    HotelRoom? room,
    HotelRatePlan? ratePlan,
    HotelPricingQuote? quote,
    HotelStayCriteria? criteria,
    String? specialRequest,
    BookingStatus? status,
    DateTime? createdAt,
    Object? cancellationReason = _unset,
    bool? itineraryAdded,
  }) =>
      DemoBooking(
        code: code ?? this.code,
        hotel: hotel ?? this.hotel,
        room: room ?? this.room,
        ratePlan: ratePlan ?? this.ratePlan,
        quote: quote ?? this.quote,
        criteria: criteria ?? this.criteria,
        specialRequest: specialRequest ?? this.specialRequest,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        cancellationReason: identical(cancellationReason, _unset)
            ? this.cancellationReason
            : cancellationReason as String?,
        itineraryAdded: itineraryAdded ?? this.itineraryAdded,
      );

  static const Object _unset = Object();
}

enum RewardActionResult {
  success,
  unavailable,
  blank,
  duplicate,
  rejected,
  ownCode,
}

enum TravelCreditTransactionType {
  grant,
  promotion,
  refundCredit,
  adjustment,
  redemption,
  expiration,
  reversal,
}

extension TravelCreditTransactionTypeData on TravelCreditTransactionType {
  String get code {
    switch (this) {
      case TravelCreditTransactionType.grant:
        return 'GRANT';
      case TravelCreditTransactionType.promotion:
        return 'PROMOTION';
      case TravelCreditTransactionType.refundCredit:
        return 'REFUND_CREDIT';
      case TravelCreditTransactionType.adjustment:
        return 'ADJUSTMENT';
      case TravelCreditTransactionType.redemption:
        return 'REDEMPTION';
      case TravelCreditTransactionType.expiration:
        return 'EXPIRATION';
      case TravelCreditTransactionType.reversal:
        return 'REVERSAL';
    }
  }

  bool get increasesBalance =>
      this == TravelCreditTransactionType.grant ||
      this == TravelCreditTransactionType.promotion ||
      this == TravelCreditTransactionType.refundCredit ||
      this == TravelCreditTransactionType.reversal;
}

class TravelCreditAccount {
  final String id;
  final String userId;
  final int balanceMinor;
  final String currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TravelCreditAccount({
    required this.id,
    required this.userId,
    required this.balanceMinor,
    required this.currency,
    required this.createdAt,
    required this.updatedAt,
  });
}

class TravelCreditTransaction {
  final String id;
  final String accountId;
  final TravelCreditTransactionType transactionType;
  final int amountMinor;
  final int balanceBeforeMinor;
  final int balanceAfterMinor;
  final String description;
  final String? referenceType;
  final String? referenceId;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const TravelCreditTransaction({
    required this.id,
    required this.accountId,
    required this.transactionType,
    required this.amountMinor,
    required this.balanceBeforeMinor,
    required this.balanceAfterMinor,
    required this.description,
    this.referenceType,
    this.referenceId,
    this.expiresAt,
    required this.createdAt,
  });
}

enum LoyaltyTransactionType {
  earnBooking,
  earnReview,
  grant,
  adjustment,
  reversal,
  redemptionDebit,
  redemptionRelease,
  redemptionRefund,
}

extension LoyaltyTransactionTypeData on LoyaltyTransactionType {
  String get code {
    switch (this) {
      case LoyaltyTransactionType.earnBooking:
        return 'EARN_BOOKING';
      case LoyaltyTransactionType.earnReview:
        return 'EARN_REVIEW';
      case LoyaltyTransactionType.grant:
        return 'GRANT';
      case LoyaltyTransactionType.adjustment:
        return 'ADJUSTMENT';
      case LoyaltyTransactionType.reversal:
        return 'REVERSAL';
      case LoyaltyTransactionType.redemptionDebit:
        return 'REDEMPTION_DEBIT';
      case LoyaltyTransactionType.redemptionRelease:
        return 'REDEMPTION_RELEASE';
      case LoyaltyTransactionType.redemptionRefund:
        return 'REDEMPTION_REFUND';
    }
  }

  bool? get knownIncrease {
    switch (this) {
      case LoyaltyTransactionType.earnBooking:
      case LoyaltyTransactionType.earnReview:
      case LoyaltyTransactionType.grant:
      case LoyaltyTransactionType.redemptionRelease:
      case LoyaltyTransactionType.redemptionRefund:
        return true;
      case LoyaltyTransactionType.redemptionDebit:
        return false;
      case LoyaltyTransactionType.adjustment:
      case LoyaltyTransactionType.reversal:
        return null;
    }
  }
}

class LoyaltyAccount {
  final String id;
  final String userId;
  final int currentBalance;
  final int lifetimePointsEarned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoyaltyAccount({
    required this.id,
    required this.userId,
    required this.currentBalance,
    required this.lifetimePointsEarned,
    required this.createdAt,
    required this.updatedAt,
  });
}

class LoyaltyTransaction {
  final LoyaltyTransactionType transactionType;
  final int points;
  final int balanceBefore;
  final int balanceAfter;
  final String description;
  final String? referenceType;
  final String? referenceId;
  final DateTime createdAt;

  const LoyaltyTransaction({
    required this.transactionType,
    required this.points,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    this.referenceType,
    this.referenceId,
    required this.createdAt,
  });

  bool get increasesBalance =>
      transactionType.knownIncrease ?? balanceAfter > balanceBefore;
}

enum MembershipTier { bronze, silver, gold, platinum, diamond }

extension MembershipTierData on MembershipTier {
  String get code {
    switch (this) {
      case MembershipTier.bronze:
        return 'BRONZE';
      case MembershipTier.silver:
        return 'SILVER';
      case MembershipTier.gold:
        return 'GOLD';
      case MembershipTier.platinum:
        return 'PLATINUM';
      case MembershipTier.diamond:
        return 'DIAMOND';
    }
  }
}

enum MembershipBenefitType {
  pointsMultiplier,
  memberOnlyCoupons,
  prioritySupport,
  earlyAccess,
  lateCheckout,
  earlyCheckin,
  roomUpgrade,
  freeBreakfast,
  airportTransfer,
  custom,
}

extension MembershipBenefitTypeData on MembershipBenefitType {
  String get code {
    switch (this) {
      case MembershipBenefitType.pointsMultiplier:
        return 'POINTS_MULTIPLIER';
      case MembershipBenefitType.memberOnlyCoupons:
        return 'MEMBER_ONLY_COUPONS';
      case MembershipBenefitType.prioritySupport:
        return 'PRIORITY_SUPPORT';
      case MembershipBenefitType.earlyAccess:
        return 'EARLY_ACCESS';
      case MembershipBenefitType.lateCheckout:
        return 'LATE_CHECKOUT';
      case MembershipBenefitType.earlyCheckin:
        return 'EARLY_CHECKIN';
      case MembershipBenefitType.roomUpgrade:
        return 'ROOM_UPGRADE';
      case MembershipBenefitType.freeBreakfast:
        return 'FREE_BREAKFAST';
      case MembershipBenefitType.airportTransfer:
        return 'AIRPORT_TRANSFER';
      case MembershipBenefitType.custom:
        return 'CUSTOM';
    }
  }
}

class MembershipAccount {
  final MembershipTier currentTier;
  final MembershipTier? effectiveTier;
  final DateTime? qualifiedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool manuallyAssigned;
  final bool active;
  final bool expired;

  const MembershipAccount({
    this.currentTier = MembershipTier.bronze,
    this.effectiveTier,
    this.qualifiedAt,
    this.validFrom,
    this.validUntil,
    this.manuallyAssigned = false,
    this.active = false,
    this.expired = false,
  });

  MembershipTier get displayTier =>
      active && !expired ? effectiveTier ?? currentTier : MembershipTier.bronze;

  MembershipAccount copyWith({
    MembershipTier? currentTier,
    Object? effectiveTier = _unset,
    Object? qualifiedAt = _unset,
    Object? validFrom = _unset,
    Object? validUntil = _unset,
    bool? manuallyAssigned,
    bool? active,
    bool? expired,
  }) =>
      MembershipAccount(
        currentTier: currentTier ?? this.currentTier,
        effectiveTier: identical(effectiveTier, _unset)
            ? this.effectiveTier
            : effectiveTier as MembershipTier?,
        qualifiedAt: identical(qualifiedAt, _unset)
            ? this.qualifiedAt
            : qualifiedAt as DateTime?,
        validFrom: identical(validFrom, _unset)
            ? this.validFrom
            : validFrom as DateTime?,
        validUntil: identical(validUntil, _unset)
            ? this.validUntil
            : validUntil as DateTime?,
        manuallyAssigned: manuallyAssigned ?? this.manuallyAssigned,
        active: active ?? this.active,
        expired: expired ?? this.expired,
      );

  static const Object _unset = Object();
}

class MembershipProgress {
  final MembershipTier currentTier;
  final MembershipTier effectiveTier;
  final int lifetimePointsEarned;
  final int completedBookings;
  final MembershipTier? nextTier;
  final int? pointsRequiredForNextTier;
  final int? bookingsRequiredForNextTier;
  final int progressPercentage;
  final DateTime? validUntil;
  final bool expired;
  final bool manuallyAssigned;

  const MembershipProgress({
    required this.currentTier,
    required this.effectiveTier,
    required this.lifetimePointsEarned,
    required this.completedBookings,
    this.nextTier,
    this.pointsRequiredForNextTier,
    this.bookingsRequiredForNextTier,
    required this.progressPercentage,
    this.validUntil,
    this.expired = false,
    this.manuallyAssigned = false,
  });

  int get clampedProgress => progressPercentage.clamp(0, 100);
  bool get isHighestTier => nextTier == null;
}

class MembershipBenefit {
  final String id;
  final MembershipTier tier;
  final MembershipBenefitType type;
  final String title;
  final String description;
  final String conditions;

  const MembershipBenefit({
    required this.id,
    required this.tier,
    required this.type,
    required this.title,
    required this.description,
    this.conditions = '',
  });
}

class MembershipHistoryItem {
  final MembershipTier tier;
  final DateTime changedAt;
  final String description;

  const MembershipHistoryItem({
    required this.tier,
    required this.changedAt,
    required this.description,
  });
}

enum CouponDiscountType { percentage, fixedAmount }

extension CouponDiscountTypeData on CouponDiscountType {
  String get code =>
      this == CouponDiscountType.percentage ? 'PERCENTAGE' : 'FIXED_AMOUNT';
}

enum CouponTargetType { all, hotel, room, placeType }

extension CouponTargetTypeData on CouponTargetType {
  String get code {
    switch (this) {
      case CouponTargetType.all:
        return 'ALL';
      case CouponTargetType.hotel:
        return 'HOTEL';
      case CouponTargetType.room:
        return 'ROOM';
      case CouponTargetType.placeType:
        return 'PLACE_TYPE';
    }
  }
}

class CustomerCoupon {
  final String id;
  final String code;
  final String name;
  final String description;
  final CouponDiscountType discountType;
  final int discountValue;
  final int? maximumDiscountMinor;
  final int? minimumSpendMinor;
  final String? currency;
  final DateTime validFrom;
  final DateTime validUntil;
  final CouponTargetType targetType;
  final int? minimumStay;
  final String status;
  final String effectiveStatus;
  final DateTime? claimedAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;
  final String? associatedBookingId;
  final MembershipTier? minimumMembershipTier;
  final bool stackableWithPromotion;
  final bool stackableWithCredit;
  final String eligibilityReason;

  const CustomerCoupon({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.maximumDiscountMinor,
    this.minimumSpendMinor,
    this.currency,
    required this.validFrom,
    required this.validUntil,
    this.targetType = CouponTargetType.all,
    this.minimumStay,
    this.status = 'AVAILABLE',
    this.effectiveStatus = 'AVAILABLE',
    this.claimedAt,
    this.usedAt,
    this.expiresAt,
    this.associatedBookingId,
    this.minimumMembershipTier,
    this.stackableWithPromotion = false,
    this.stackableWithCredit = false,
    this.eligibilityReason = '',
  });

  bool get isClaimed => claimedAt != null;
  bool get isUsable => effectiveStatus == 'ACTIVE';

  CustomerCoupon copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    CouponDiscountType? discountType,
    int? discountValue,
    Object? maximumDiscountMinor = _unset,
    Object? minimumSpendMinor = _unset,
    Object? currency = _unset,
    DateTime? validFrom,
    DateTime? validUntil,
    CouponTargetType? targetType,
    Object? minimumStay = _unset,
    String? status,
    String? effectiveStatus,
    Object? claimedAt = _unset,
    Object? usedAt = _unset,
    Object? expiresAt = _unset,
    Object? associatedBookingId = _unset,
    Object? minimumMembershipTier = _unset,
    bool? stackableWithPromotion,
    bool? stackableWithCredit,
    String? eligibilityReason,
  }) =>
      CustomerCoupon(
        id: id ?? this.id,
        code: code ?? this.code,
        name: name ?? this.name,
        description: description ?? this.description,
        discountType: discountType ?? this.discountType,
        discountValue: discountValue ?? this.discountValue,
        maximumDiscountMinor: identical(maximumDiscountMinor, _unset)
            ? this.maximumDiscountMinor
            : maximumDiscountMinor as int?,
        minimumSpendMinor: identical(minimumSpendMinor, _unset)
            ? this.minimumSpendMinor
            : minimumSpendMinor as int?,
        currency:
            identical(currency, _unset) ? this.currency : currency as String?,
        validFrom: validFrom ?? this.validFrom,
        validUntil: validUntil ?? this.validUntil,
        targetType: targetType ?? this.targetType,
        minimumStay: identical(minimumStay, _unset)
            ? this.minimumStay
            : minimumStay as int?,
        status: status ?? this.status,
        effectiveStatus: effectiveStatus ?? this.effectiveStatus,
        claimedAt: identical(claimedAt, _unset)
            ? this.claimedAt
            : claimedAt as DateTime?,
        usedAt: identical(usedAt, _unset) ? this.usedAt : usedAt as DateTime?,
        expiresAt: identical(expiresAt, _unset)
            ? this.expiresAt
            : expiresAt as DateTime?,
        associatedBookingId: identical(associatedBookingId, _unset)
            ? this.associatedBookingId
            : associatedBookingId as String?,
        minimumMembershipTier: identical(minimumMembershipTier, _unset)
            ? this.minimumMembershipTier
            : minimumMembershipTier as MembershipTier?,
        stackableWithPromotion:
            stackableWithPromotion ?? this.stackableWithPromotion,
        stackableWithCredit: stackableWithCredit ?? this.stackableWithCredit,
        eligibilityReason: eligibilityReason ?? this.eligibilityReason,
      );

  static const Object _unset = Object();
}

enum ReferralRole { inviter, invitee }

extension ReferralRoleData on ReferralRole {
  String get code => this == ReferralRole.inviter ? 'INVITER' : 'INVITEE';
}

enum ReferralStatus { used, rewarded }

extension ReferralStatusData on ReferralStatus {
  String get code => this == ReferralStatus.used ? 'USED' : 'REWARDED';
}

class ReferralSummary {
  final String code;
  final int successfulReferrals;
  final int pendingReferrals;
  final DateTime createdAt;
  final String? usedCode;

  const ReferralSummary({
    required this.code,
    required this.successfulReferrals,
    required this.pendingReferrals,
    required this.createdAt,
    this.usedCode,
  });

  ReferralSummary copyWith({
    String? code,
    int? successfulReferrals,
    int? pendingReferrals,
    DateTime? createdAt,
    Object? usedCode = _unset,
  }) =>
      ReferralSummary(
        code: code ?? this.code,
        successfulReferrals: successfulReferrals ?? this.successfulReferrals,
        pendingReferrals: pendingReferrals ?? this.pendingReferrals,
        createdAt: createdAt ?? this.createdAt,
        usedCode:
            identical(usedCode, _unset) ? this.usedCode : usedCode as String?,
      );

  static const Object _unset = Object();
}

class ReferralHistoryItem {
  final ReferralRole role;
  final String campaignCode;
  final ReferralStatus status;
  final DateTime usedAt;
  final DateTime? qualifiedAt;
  final String? qualifyingBookingId;
  final DateTime? rewardedAt;

  const ReferralHistoryItem({
    required this.role,
    required this.campaignCode,
    required this.status,
    required this.usedAt,
    this.qualifiedAt,
    this.qualifyingBookingId,
    this.rewardedAt,
  });
}

enum GiftCardStatus {
  issued,
  active,
  partiallyRedeemed,
  fullyRedeemed,
  expired,
  cancelled,
}

extension GiftCardStatusData on GiftCardStatus {
  String get code {
    switch (this) {
      case GiftCardStatus.issued:
        return 'ISSUED';
      case GiftCardStatus.active:
        return 'ACTIVE';
      case GiftCardStatus.partiallyRedeemed:
        return 'PARTIALLY_REDEEMED';
      case GiftCardStatus.fullyRedeemed:
        return 'FULLY_REDEEMED';
      case GiftCardStatus.expired:
        return 'EXPIRED';
      case GiftCardStatus.cancelled:
        return 'CANCELLED';
    }
  }

  bool get canRedeem =>
      this == GiftCardStatus.active || this == GiftCardStatus.partiallyRedeemed;
}

enum GiftCardTransactionType { issue, activation, redemption, refund, expiry }

extension GiftCardTransactionTypeData on GiftCardTransactionType {
  String get code {
    switch (this) {
      case GiftCardTransactionType.issue:
        return 'ISSUE';
      case GiftCardTransactionType.activation:
        return 'ACTIVATION';
      case GiftCardTransactionType.redemption:
        return 'REDEMPTION';
      case GiftCardTransactionType.refund:
        return 'REFUND';
      case GiftCardTransactionType.expiry:
        return 'EXPIRY';
    }
  }
}

class GiftCardTransaction {
  final String id;
  final GiftCardTransactionType transactionType;
  final int amountMinor;
  final int balanceBeforeMinor;
  final int balanceAfterMinor;
  final String description;
  final DateTime createdAt;

  const GiftCardTransaction({
    required this.id,
    required this.transactionType,
    required this.amountMinor,
    required this.balanceBeforeMinor,
    required this.balanceAfterMinor,
    required this.description,
    required this.createdAt,
  });

  bool get increasesBalance => balanceAfterMinor > balanceBeforeMinor;
}

class GiftCard {
  final String id;
  final String maskedCode;
  final String productName;
  final int originalAmountMinor;
  final int currentBalanceMinor;
  final String currency;
  final GiftCardStatus status;
  final GiftCardStatus effectiveStatus;
  final DateTime issuedAt;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final String personalMessage;
  final String purchaserSummary;
  final String recipientSummary;
  final List<GiftCardTransaction> transactions;

  const GiftCard({
    required this.id,
    required this.maskedCode,
    required this.productName,
    required this.originalAmountMinor,
    required this.currentBalanceMinor,
    required this.currency,
    required this.status,
    required this.effectiveStatus,
    required this.issuedAt,
    this.activatedAt,
    this.expiresAt,
    this.personalMessage = '',
    this.purchaserSummary = '',
    this.recipientSummary = '',
    this.transactions = const [],
  });

  GiftCard copyWith({
    String? id,
    String? maskedCode,
    String? productName,
    int? originalAmountMinor,
    int? currentBalanceMinor,
    String? currency,
    GiftCardStatus? status,
    GiftCardStatus? effectiveStatus,
    DateTime? issuedAt,
    Object? activatedAt = _unset,
    Object? expiresAt = _unset,
    String? personalMessage,
    String? purchaserSummary,
    String? recipientSummary,
    List<GiftCardTransaction>? transactions,
  }) =>
      GiftCard(
        id: id ?? this.id,
        maskedCode: maskedCode ?? this.maskedCode,
        productName: productName ?? this.productName,
        originalAmountMinor: originalAmountMinor ?? this.originalAmountMinor,
        currentBalanceMinor: currentBalanceMinor ?? this.currentBalanceMinor,
        currency: currency ?? this.currency,
        status: status ?? this.status,
        effectiveStatus: effectiveStatus ?? this.effectiveStatus,
        issuedAt: issuedAt ?? this.issuedAt,
        activatedAt: identical(activatedAt, _unset)
            ? this.activatedAt
            : activatedAt as DateTime?,
        expiresAt: identical(expiresAt, _unset)
            ? this.expiresAt
            : expiresAt as DateTime?,
        personalMessage: personalMessage ?? this.personalMessage,
        purchaserSummary: purchaserSummary ?? this.purchaserSummary,
        recipientSummary: recipientSummary ?? this.recipientSummary,
        transactions: transactions ?? this.transactions,
      );

  static const Object _unset = Object();
}

enum WalletItemType {
  passport,
  visa,
  boardingPass,
  flightTicket,
  trainTicket,
  busTicket,
  hotelVoucher,
  tourVoucher,
  insurance,
  bookingConfirmation,
  invoice,
  receipt,
  itinerary,
  other,
}

extension WalletItemTypeData on WalletItemType {
  String get code {
    switch (this) {
      case WalletItemType.passport:
        return 'PASSPORT';
      case WalletItemType.visa:
        return 'VISA';
      case WalletItemType.boardingPass:
        return 'BOARDING_PASS';
      case WalletItemType.flightTicket:
        return 'FLIGHT_TICKET';
      case WalletItemType.trainTicket:
        return 'TRAIN_TICKET';
      case WalletItemType.busTicket:
        return 'BUS_TICKET';
      case WalletItemType.hotelVoucher:
        return 'HOTEL_VOUCHER';
      case WalletItemType.tourVoucher:
        return 'TOUR_VOUCHER';
      case WalletItemType.insurance:
        return 'INSURANCE';
      case WalletItemType.bookingConfirmation:
        return 'BOOKING_CONFIRMATION';
      case WalletItemType.invoice:
        return 'INVOICE';
      case WalletItemType.receipt:
        return 'RECEIPT';
      case WalletItemType.itinerary:
        return 'ITINERARY';
      case WalletItemType.other:
        return 'OTHER';
    }
  }

  OrganizerCategory get organizerCategory {
    switch (this) {
      case WalletItemType.passport:
      case WalletItemType.visa:
        return OrganizerCategory.identity;
      case WalletItemType.boardingPass:
      case WalletItemType.flightTicket:
      case WalletItemType.trainTicket:
      case WalletItemType.busTicket:
        return OrganizerCategory.transport;
      case WalletItemType.hotelVoucher:
        return OrganizerCategory.accommodation;
      case WalletItemType.tourVoucher:
      case WalletItemType.itinerary:
        return OrganizerCategory.activity;
      case WalletItemType.insurance:
        return OrganizerCategory.insurance;
      case WalletItemType.bookingConfirmation:
      case WalletItemType.invoice:
      case WalletItemType.receipt:
        return OrganizerCategory.financial;
      case WalletItemType.other:
        return OrganizerCategory.other;
    }
  }
}

enum WalletItemStatus { active, upcoming, expired, cancelled, archived }

extension WalletItemStatusData on WalletItemStatus {
  String get code {
    switch (this) {
      case WalletItemStatus.active:
        return 'ACTIVE';
      case WalletItemStatus.upcoming:
        return 'UPCOMING';
      case WalletItemStatus.expired:
        return 'EXPIRED';
      case WalletItemStatus.cancelled:
        return 'CANCELLED';
      case WalletItemStatus.archived:
        return 'ARCHIVED';
    }
  }
}

enum OrganizerCategory {
  identity,
  transport,
  accommodation,
  activity,
  insurance,
  financial,
  other,
}

extension OrganizerCategoryData on OrganizerCategory {
  String get code {
    switch (this) {
      case OrganizerCategory.identity:
        return 'IDENTITY';
      case OrganizerCategory.transport:
        return 'TRANSPORT';
      case OrganizerCategory.accommodation:
        return 'ACCOMMODATION';
      case OrganizerCategory.activity:
        return 'ACTIVITY';
      case OrganizerCategory.insurance:
        return 'INSURANCE';
      case OrganizerCategory.financial:
        return 'FINANCIAL';
      case OrganizerCategory.other:
        return 'OTHER';
    }
  }
}

enum WalletSourceType { metadata, tripDocument, booking, invoice }

extension WalletSourceTypeData on WalletSourceType {
  String get code {
    switch (this) {
      case WalletSourceType.metadata:
        return 'METADATA';
      case WalletSourceType.tripDocument:
        return 'TRIP_DOCUMENT';
      case WalletSourceType.booking:
        return 'BOOKING';
      case WalletSourceType.invoice:
        return 'INVOICE';
    }
  }
}

enum TripDocumentType {
  flightTicket,
  hotelBooking,
  trainTicket,
  busTicket,
  passport,
  visa,
  insurance,
  tour,
  receipt,
  pdf,
  image,
  other,
}

extension TripDocumentTypeData on TripDocumentType {
  String get code {
    switch (this) {
      case TripDocumentType.flightTicket:
        return 'FLIGHT_TICKET';
      case TripDocumentType.hotelBooking:
        return 'HOTEL_BOOKING';
      case TripDocumentType.trainTicket:
        return 'TRAIN_TICKET';
      case TripDocumentType.busTicket:
        return 'BUS_TICKET';
      case TripDocumentType.passport:
        return 'PASSPORT';
      case TripDocumentType.visa:
        return 'VISA';
      case TripDocumentType.insurance:
        return 'INSURANCE';
      case TripDocumentType.tour:
        return 'TOUR';
      case TripDocumentType.receipt:
        return 'RECEIPT';
      case TripDocumentType.pdf:
        return 'PDF';
      case TripDocumentType.image:
        return 'IMAGE';
      case TripDocumentType.other:
        return 'OTHER';
    }
  }

  WalletItemType get walletItemType {
    switch (this) {
      case TripDocumentType.flightTicket:
        return WalletItemType.flightTicket;
      case TripDocumentType.hotelBooking:
        return WalletItemType.hotelVoucher;
      case TripDocumentType.trainTicket:
        return WalletItemType.trainTicket;
      case TripDocumentType.busTicket:
        return WalletItemType.busTicket;
      case TripDocumentType.passport:
        return WalletItemType.passport;
      case TripDocumentType.visa:
        return WalletItemType.visa;
      case TripDocumentType.insurance:
        return WalletItemType.insurance;
      case TripDocumentType.tour:
        return WalletItemType.tourVoucher;
      case TripDocumentType.receipt:
        return WalletItemType.receipt;
      case TripDocumentType.pdf:
      case TripDocumentType.image:
      case TripDocumentType.other:
        return WalletItemType.other;
    }
  }
}

enum WalletActionResult {
  success,
  unavailable,
  blank,
  duplicate,
  rejected,
  invalidDateRange,
  unsafeUrl,
  notFound,
}

class TravelWalletItem {
  static const Object _unset = Object();

  final String id;
  final int? linkedTripId;
  final String? linkedTripTitle;
  final String? linkedDocumentId;
  final String? linkedBookingId;
  final String? linkedInvoiceId;
  final WalletItemType type;
  final String title;
  final String issuer;
  final String maskedReference;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final WalletItemStatus status;
  final bool favorite;
  final bool archived;
  final bool expiryReminderEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TravelWalletItem({
    required this.id,
    this.linkedTripId,
    this.linkedTripTitle,
    this.linkedDocumentId,
    this.linkedBookingId,
    this.linkedInvoiceId,
    required this.type,
    required this.title,
    this.issuer = '',
    this.maskedReference = '',
    this.validFrom,
    this.validUntil,
    this.status = WalletItemStatus.active,
    this.favorite = false,
    this.archived = false,
    this.expiryReminderEnabled = false,
    required this.createdAt,
    required this.updatedAt,
  });

  OrganizerCategory get organizerCategory => type.organizerCategory;

  WalletSourceType get sourceType {
    if (linkedDocumentId != null) return WalletSourceType.tripDocument;
    if (linkedBookingId != null) return WalletSourceType.booking;
    if (linkedInvoiceId != null) return WalletSourceType.invoice;
    return WalletSourceType.metadata;
  }

  WalletItemStatus effectiveStatus(DateTime today) =>
      computeWalletEffectiveStatus(
        archived: archived,
        storedStatus: status,
        validFrom: validFrom,
        validUntil: validUntil,
        today: today,
      );

  TravelWalletItem copyWith({
    String? id,
    Object? linkedTripId = _unset,
    Object? linkedTripTitle = _unset,
    Object? linkedDocumentId = _unset,
    Object? linkedBookingId = _unset,
    Object? linkedInvoiceId = _unset,
    WalletItemType? type,
    String? title,
    String? issuer,
    String? maskedReference,
    Object? validFrom = _unset,
    Object? validUntil = _unset,
    WalletItemStatus? status,
    bool? favorite,
    bool? archived,
    bool? expiryReminderEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TravelWalletItem(
        id: id ?? this.id,
        linkedTripId: identical(linkedTripId, _unset)
            ? this.linkedTripId
            : linkedTripId as int?,
        linkedTripTitle: identical(linkedTripTitle, _unset)
            ? this.linkedTripTitle
            : linkedTripTitle as String?,
        linkedDocumentId: identical(linkedDocumentId, _unset)
            ? this.linkedDocumentId
            : linkedDocumentId as String?,
        linkedBookingId: identical(linkedBookingId, _unset)
            ? this.linkedBookingId
            : linkedBookingId as String?,
        linkedInvoiceId: identical(linkedInvoiceId, _unset)
            ? this.linkedInvoiceId
            : linkedInvoiceId as String?,
        type: type ?? this.type,
        title: title ?? this.title,
        issuer: issuer ?? this.issuer,
        maskedReference: maskedReference ?? this.maskedReference,
        validFrom: identical(validFrom, _unset)
            ? this.validFrom
            : validFrom as DateTime?,
        validUntil: identical(validUntil, _unset)
            ? this.validUntil
            : validUntil as DateTime?,
        status: status ?? this.status,
        favorite: favorite ?? this.favorite,
        archived: archived ?? this.archived,
        expiryReminderEnabled:
            expiryReminderEnabled ?? this.expiryReminderEnabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class TripDocument {
  static const Object _unset = Object();

  final String id;
  final int tripId;
  final int? tripDayId;
  final int? tripActivityId;
  final TripDocumentType type;
  final String title;
  final String notes;
  final String mediaLabel;
  final String mediaUrl;
  final String uploaderName;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripDocument({
    required this.id,
    required this.tripId,
    this.tripDayId,
    this.tripActivityId,
    required this.type,
    required this.title,
    this.notes = '',
    this.mediaLabel = '',
    this.mediaUrl = '',
    this.uploaderName = '',
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasSafeMedia =>
      mediaLabel.isNotEmpty || isSafeDocumentMediaUrl(mediaUrl);

  TripDocument copyWith({
    String? id,
    int? tripId,
    Object? tripDayId = _unset,
    Object? tripActivityId = _unset,
    TripDocumentType? type,
    String? title,
    String? notes,
    String? mediaLabel,
    String? mediaUrl,
    String? uploaderName,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TripDocument(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        tripDayId:
            identical(tripDayId, _unset) ? this.tripDayId : tripDayId as int?,
        tripActivityId: identical(tripActivityId, _unset)
            ? this.tripActivityId
            : tripActivityId as int?,
        type: type ?? this.type,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        mediaLabel: mediaLabel ?? this.mediaLabel,
        mediaUrl: mediaUrl ?? this.mediaUrl,
        uploaderName: uploaderName ?? this.uploaderName,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

WalletItemStatus computeWalletEffectiveStatus({
  required bool archived,
  required WalletItemStatus storedStatus,
  DateTime? validFrom,
  DateTime? validUntil,
  required DateTime today,
}) {
  if (archived) return WalletItemStatus.archived;
  if (storedStatus == WalletItemStatus.cancelled) {
    return WalletItemStatus.cancelled;
  }
  final current = dateOnly(today);
  if (validUntil != null && dateOnly(validUntil).isBefore(current)) {
    return WalletItemStatus.expired;
  }
  if (validFrom != null && dateOnly(validFrom).isAfter(current)) {
    return WalletItemStatus.upcoming;
  }
  return storedStatus;
}

DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String maskSensitiveReference(String raw) {
  final safe = raw.trim().replaceAll(RegExp('[^A-Za-z0-9]'), '').toUpperCase();
  if (safe.isEmpty) return '';
  final tail = safe.length <= 4 ? safe : safe.substring(safe.length - 4);
  return '****-$tail';
}

bool isSafeDocumentMediaUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.hasAuthority &&
      uri.host.trim().isNotEmpty &&
      uri.userInfo.isEmpty;
}

class Trip {
  final int id;
  final String title;
  final String destination;
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int travelers;
  final double budget;
  final String budgetCurrency;
  final String budgetNotes;
  final String notes;

  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.budget,
    this.budgetCurrency = 'VND',
    this.budgetNotes = '',
    this.notes = '',
  });

  int get days {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  Trip copyWith({
    int? id,
    String? title,
    String? destination,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    int? travelers,
    double? budget,
    String? budgetCurrency,
    String? budgetNotes,
    String? notes,
  }) =>
      Trip(
        id: id ?? this.id,
        title: title ?? this.title,
        destination: destination ?? this.destination,
        imageUrl: imageUrl ?? this.imageUrl,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        travelers: travelers ?? this.travelers,
        budget: budget ?? this.budget,
        budgetCurrency: budgetCurrency ?? this.budgetCurrency,
        budgetNotes: budgetNotes ?? this.budgetNotes,
        notes: notes ?? this.notes,
      );
}

class TimelineItem {
  final int id;
  final int tripId;
  final int dayNumber;
  final String startTime;
  final String endTime;
  final String title;
  final String notes;
  final Place? place;
  final int? placeId;
  final String? customActivity;
  final double estimatedCost;
  final String category;
  final int sortOrder;

  const TimelineItem({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.notes = '',
    this.place,
    this.placeId,
    this.customActivity,
    this.estimatedCost = 0,
    this.category = 'Activity',
    this.sortOrder = 0,
  });

  TimelineItem copyWith({
    int? id,
    int? tripId,
    int? dayNumber,
    String? startTime,
    String? endTime,
    String? title,
    String? notes,
    Place? place,
    int? placeId,
    String? customActivity,
    double? estimatedCost,
    String? category,
    int? sortOrder,
  }) =>
      TimelineItem(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        dayNumber: dayNumber ?? this.dayNumber,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        place: place ?? this.place,
        placeId: placeId ?? this.placeId,
        customActivity: customActivity ?? this.customActivity,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        category: category ?? this.category,
        sortOrder: sortOrder ?? this.sortOrder,
      );
}

class Expense {
  static const Object _unset = Object();

  final int id;
  final int tripId;
  final String title;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final int? tripDayId;
  final int? tripItemId;
  final String notes;

  const Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    required this.amount,
    this.currency = 'VND',
    required this.date,
    this.tripDayId,
    this.tripItemId,
    this.notes = '',
  });

  Expense copyWith({
    int? id,
    int? tripId,
    String? title,
    String? category,
    double? amount,
    String? currency,
    DateTime? date,
    Object? tripDayId = _unset,
    Object? tripItemId = _unset,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        title: title ?? this.title,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        date: date ?? this.date,
        tripDayId:
            identical(tripDayId, _unset) ? this.tripDayId : tripDayId as int?,
        tripItemId: identical(tripItemId, _unset)
            ? this.tripItemId
            : tripItemId as int?,
        notes: notes ?? this.notes,
      );
}

class PlaceQuery {
  final String? keyword;
  final String? category;
  final String? city;
  final double? minRating;
  final String? priceLevel;
  final List<String>? tags;
  final bool? isFeatured;
  final bool? isNearby;

  const PlaceQuery({
    this.keyword,
    this.category,
    this.city,
    this.minRating,
    this.priceLevel,
    this.tags,
    this.isFeatured,
    this.isNearby,
  });

  bool get isEmpty =>
      keyword == null &&
      category == null &&
      city == null &&
      minRating == null &&
      priceLevel == null &&
      (tags == null || tags!.isEmpty) &&
      isFeatured == null &&
      isNearby == null;
}
