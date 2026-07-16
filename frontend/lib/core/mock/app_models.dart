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
