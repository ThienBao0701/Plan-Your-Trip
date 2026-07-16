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
  });

  // Backward-compat accessors used by existing widgets
  String get location => locationName;
  String get priceRange => priceLevel;
  String get effectiveCategorySlug =>
      categorySlug ?? category.toLowerCase().replaceAll(' ', '-');
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
