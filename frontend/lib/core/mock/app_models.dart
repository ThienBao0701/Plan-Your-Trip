import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final int sortOrder;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.sortOrder,
  });
}

class Place {
  final int id;
  final String name;
  final String category;
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

  const Place({
    required this.id,
    required this.name,
    required this.category,
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
  });

  // Backward-compat accessors used by existing widgets
  String get location => locationName;
  String get priceRange => priceLevel;
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
    this.notes = '',
  });

  int get days => endDate.difference(startDate).inDays + 1;

  Trip copyWith({
    int? id,
    String? title,
    String? destination,
    String? imageUrl,
    DateTime? startDate,
    DateTime? endDate,
    int? travelers,
    double? budget,
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
  final int id;
  final int tripId;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final String notes;

  const Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  Expense copyWith({
    int? id,
    int? tripId,
    String? title,
    String? category,
    double? amount,
    DateTime? date,
    String? notes,
  }) =>
      Expense(
        id: id ?? this.id,
        tripId: tripId ?? this.tripId,
        title: title ?? this.title,
        category: category ?? this.category,
        amount: amount ?? this.amount,
        date: date ?? this.date,
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
