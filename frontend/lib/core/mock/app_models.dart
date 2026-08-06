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

enum SavedPlaceSort { newest, name }

enum SavedPlaceActionResult {
  success,
  unavailable,
  notFound,
  duplicate,
  forbidden,
  invalidNote,
}

class SavedPlaceRecord {
  static const Object _unset = Object();
  static const int maxNoteLength = 500;

  final String id;
  final int? backendId;
  final String ownerUserId;
  final int placeId;
  final DateTime savedAt;
  final String? note;
  final bool demoOnly;

  const SavedPlaceRecord({
    required this.id,
    this.backendId,
    required this.ownerUserId,
    required this.placeId,
    required this.savedAt,
    this.note,
    this.demoOnly = true,
  });

  SavedPlaceRecord copyWith({
    String? id,
    Object? backendId = _unset,
    String? ownerUserId,
    int? placeId,
    DateTime? savedAt,
    Object? note = _unset,
    bool? demoOnly,
  }) =>
      SavedPlaceRecord(
        id: id ?? this.id,
        backendId:
            identical(backendId, _unset) ? this.backendId : backendId as int?,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        placeId: placeId ?? this.placeId,
        savedAt: savedAt ?? this.savedAt,
        note: identical(note, _unset) ? this.note : note as String?,
        demoOnly: demoOnly ?? this.demoOnly,
      );
}

class ResolvedSavedPlace {
  final SavedPlaceRecord record;
  final Place? place;

  const ResolvedSavedPlace({
    required this.record,
    required this.place,
  });

  bool get available => place != null;
}

enum SavedCollectionActionResult {
  success,
  unavailable,
  invalidName,
  invalidDescription,
  invalidCover,
  collectionLimitReached,
  collectionNotFound,
  placeNotFound,
  duplicateItem,
  itemNotFound,
  itemLimitReached,
  network,
  serverError,
  unauthenticated,
}

class SavedCollectionRecord {
  static const Object _unset = Object();
  static const int maxNameLength = 120;
  static const int maxDescriptionLength = 1000;
  static const int maxCoverImageUrlLength = 2048;
  static const int maxCollectionsPerUser = 100;

  final String id;
  final int? backendId;
  final String ownerUserId;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final bool privateCollection;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool demoOnly;

  const SavedCollectionRecord({
    required this.id,
    this.backendId,
    required this.ownerUserId,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.privateCollection = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.demoOnly = true,
  });

  SavedCollectionRecord copyWith({
    String? id,
    Object? backendId = _unset,
    String? ownerUserId,
    String? name,
    Object? description = _unset,
    Object? coverImageUrl = _unset,
    bool? privateCollection,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? demoOnly,
  }) =>
      SavedCollectionRecord(
        id: id ?? this.id,
        backendId:
            identical(backendId, _unset) ? this.backendId : backendId as int?,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        name: name ?? this.name,
        description: identical(description, _unset)
            ? this.description
            : description as String?,
        coverImageUrl: identical(coverImageUrl, _unset)
            ? this.coverImageUrl
            : coverImageUrl as String?,
        privateCollection: privateCollection ?? this.privateCollection,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        demoOnly: demoOnly ?? this.demoOnly,
      );
}

class SavedCollectionPlaceRecord {
  static const int maxPlacesPerCollection = 500;

  final String id;
  final String collectionId;
  final int placeId;
  final int position;
  final DateTime addedAt;
  final bool demoOnly;

  const SavedCollectionPlaceRecord({
    required this.id,
    required this.collectionId,
    required this.placeId,
    required this.position,
    required this.addedAt,
    this.demoOnly = true,
  });
}

class ResolvedCollectionPlace {
  final SavedCollectionPlaceRecord record;
  final Place? place;

  const ResolvedCollectionPlace({
    required this.record,
    required this.place,
  });

  bool get available => place != null;
}

/// Real-backend mirror of `CollectionSummaryResponse` (`/api/me/collections`,
/// `backend-v1.0-foundation`). Kept separate from [SavedCollectionRecord],
/// which is Demo Mode's local shape.
class CollectionSummaryRecord {
  final int id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final bool privateCollection;
  final int sortOrder;
  final int placeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CollectionSummaryRecord({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.privateCollection,
    required this.sortOrder,
    required this.placeCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CollectionSummaryRecord.fromJson(Map<String, dynamic> json) =>
      CollectionSummaryRecord(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        privateCollection: json['privateCollection'] as bool,
        sortOrder: (json['sortOrder'] as num).toInt(),
        placeCount: (json['placeCount'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

/// Real-backend mirror of `CollectionPlaceResponse`. Carries only the Place
/// fields the backend actually returns for a collection item — no
/// `imageUrl`/`locationName`/`city`, unlike the Demo Mode `Place` model.
class CollectionPlaceRecord {
  final int placeId;
  final String name;
  final String slug;
  final String? categoryName;
  final String? address;
  final String? shortDescription;
  final double ratingAvg;
  final int reviewCount;
  final int position;
  final DateTime addedAt;

  const CollectionPlaceRecord({
    required this.placeId,
    required this.name,
    required this.slug,
    this.categoryName,
    this.address,
    this.shortDescription,
    required this.ratingAvg,
    required this.reviewCount,
    required this.position,
    required this.addedAt,
  });

  factory CollectionPlaceRecord.fromJson(Map<String, dynamic> json) =>
      CollectionPlaceRecord(
        placeId: (json['placeId'] as num).toInt(),
        name: json['name'] as String,
        slug: json['slug'] as String,
        categoryName: json['categoryName'] as String?,
        address: json['address'] as String?,
        shortDescription: json['shortDescription'] as String?,
        ratingAvg: (json['ratingAvg'] as num).toDouble(),
        reviewCount: (json['reviewCount'] as num).toInt(),
        position: (json['position'] as num).toInt(),
        addedAt: DateTime.parse(json['addedAt'] as String),
      );
}

/// Real-backend mirror of `CollectionDetailResponse`.
class CollectionDetailRecord {
  final int id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final bool privateCollection;
  final int sortOrder;
  final int placeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CollectionPlaceRecord> places;

  const CollectionDetailRecord({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    required this.privateCollection,
    required this.sortOrder,
    required this.placeCount,
    required this.createdAt,
    required this.updatedAt,
    required this.places,
  });

  factory CollectionDetailRecord.fromJson(Map<String, dynamic> json) =>
      CollectionDetailRecord(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        description: json['description'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        privateCollection: json['privateCollection'] as bool,
        sortOrder: (json['sortOrder'] as num).toInt(),
        placeCount: (json['placeCount'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        places: (json['places'] as List<dynamic>? ?? const [])
            .map(
              (e) => CollectionPlaceRecord.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
      );

  CollectionDetailRecord copyWith({
    List<CollectionPlaceRecord>? places,
    int? placeCount,
  }) =>
      CollectionDetailRecord(
        id: id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        privateCollection: privateCollection,
        sortOrder: sortOrder,
        placeCount: placeCount ?? this.placeCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
        places: places ?? this.places,
      );

  CollectionSummaryRecord toSummary() => CollectionSummaryRecord(
        id: id,
        name: name,
        description: description,
        coverImageUrl: coverImageUrl,
        privateCollection: privateCollection,
        sortOrder: sortOrder,
        placeCount: placeCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ── Real Mode Wishlist (/api/me/wishlist, UI-18) ─────────────────────────────
//
// Typed mirrors of the backend `WishlistDto` records. Kept entirely separate
// from the Demo Mode [SavedPlaceRecord] shape — the real wishlist is a distinct
// data source that must never be merged with the local demo list.

/// Real-mode outcome for the authenticated `/api/me/wishlist` endpoints.
/// Distinct from the Demo Mode [SavedPlaceActionResult]. Note: the backend
/// enforces NO per-wishlist item cap, so there is deliberately no
/// `itemLimitReached` member (surfacing one would be a fabricated contract).
enum WishlistActionResult {
  success,
  unavailable,
  network,
  serverError,
  unauthenticated,
  placeNotFound,
  itemNotFound,
  duplicate,
  notPublished,
  invalid,
}

/// The single unified outcome the shared `BookmarkButton` switches on, spanning
/// both Demo Mode (local, synchronous) and Real Mode (backend) bookmark toggles.
enum BookmarkOutcome {
  added,
  removed,
  duplicate,
  notFound,
  notPublished,
  network,
  serverError,
  sessionExpired,
  unavailable,
  invalid,
  forbidden,
}

DateTime? _parseNullableInstant(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Real-backend mirror of `WishlistDto.WishlistPlaceSummary`. Carries only the
/// Place fields the backend actually returns — no `imageUrl`/`locationName`/
/// `city`, unlike the Demo Mode [Place] model.
class WishlistPlaceSummaryRecord {
  final int id;
  final String name;
  final String? slug;
  final String? categoryName;
  final String? address;
  final String? shortDescription;
  final double ratingAvg;
  final int reviewCount;

  const WishlistPlaceSummaryRecord({
    required this.id,
    required this.name,
    this.slug,
    this.categoryName,
    this.address,
    this.shortDescription,
    this.ratingAvg = 0,
    this.reviewCount = 0,
  });

  factory WishlistPlaceSummaryRecord.fromJson(Map<String, dynamic> json) =>
      WishlistPlaceSummaryRecord(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        slug: json['slug'] as String?,
        categoryName: json['categoryName'] as String?,
        address: json['address'] as String?,
        shortDescription: json['shortDescription'] as String?,
        ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
        reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      );
}

/// Real-backend mirror of `WishlistDto.WishlistItemResponse`.
class WishlistItemRecord {
  final int id;
  final WishlistPlaceSummaryRecord place;
  final String? note;
  final DateTime? createdAt;

  const WishlistItemRecord({
    required this.id,
    required this.place,
    this.note,
    this.createdAt,
  });

  int get placeId => place.id;

  factory WishlistItemRecord.fromJson(Map<String, dynamic> json) =>
      WishlistItemRecord(
        id: (json['id'] as num).toInt(),
        place: WishlistPlaceSummaryRecord.fromJson(
          json['place'] as Map<String, dynamic>,
        ),
        note: json['note'] as String?,
        createdAt: _parseNullableInstant(json['createdAt']),
      );
}

/// Real-backend mirror of `WishlistDto.WishlistResponse`. The backend returns
/// items newest-first (`createdAt DESC`); that server order is preserved.
class WishlistRecord {
  final int id;
  final int? userId;
  final List<WishlistItemRecord> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WishlistRecord({
    required this.id,
    this.userId,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WishlistRecord.fromJson(Map<String, dynamic> json) => WishlistRecord(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num?)?.toInt(),
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => WishlistItemRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        createdAt: _parseNullableInstant(json['createdAt']),
        updatedAt: _parseNullableInstant(json['updatedAt']),
      );
}

/// Outcome of hydrating a partial saved place into a full [Place] via the real
/// backend. [unavailable] is the Demo Mode / no-op guard; [sessionExpired] is a
/// defensive-only branch — the place-detail endpoint is public, so a 401 is not
/// expected, but if one ever occurs it must be surfaced without logging out.
enum PlaceHydrationResult {
  success,
  notFound,
  network,
  serverError,
  sessionExpired,
  unavailable,
}

/// One consecutive-days opening-hours group from `PlaceDetailResponse`
/// (`groupedOpeningHours`). The backend pre-labels `days` (e.g. "Monday -
/// Friday") and serialises times as `"HH:mm:ss"`.
class PlaceOpeningHourGroupRecord {
  final String days;
  final String? openTime;
  final String? closeTime;
  final bool closed;

  const PlaceOpeningHourGroupRecord({
    required this.days,
    this.openTime,
    this.closeTime,
    this.closed = false,
  });

  factory PlaceOpeningHourGroupRecord.fromJson(Map<String, dynamic> json) =>
      PlaceOpeningHourGroupRecord(
        days: (json['days'] as String?) ?? '',
        openTime: json['openTime'] as String?,
        closeTime: json['closeTime'] as String?,
        closed: (json['closed'] as bool?) ?? false,
      );
}

/// One gallery image from `PlaceDetailResponse.galleryImages` (backed by the
/// MediaAsset table, pre-sorted by `sortOrder`). Real-Mode only — the Demo
/// [Place] keeps just a single `imageUrl`.
class PlaceGalleryImageRecord {
  final int id;
  final String url;
  final String? thumbnailUrl;
  final String? altText;
  final int sortOrder;
  final bool cover;

  const PlaceGalleryImageRecord({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    this.altText,
    this.sortOrder = 0,
    this.cover = false,
  });

  factory PlaceGalleryImageRecord.fromJson(Map<String, dynamic> json) =>
      PlaceGalleryImageRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        url: (json['url'] as String?) ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        altText: json['altText'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        cover: (json['cover'] as bool?) ?? false,
      );
}

/// One place-level amenity from `PlaceDetailResponse.amenities` (`AmenityRef`).
class PlaceAmenityRecord {
  final int id;
  final String name;
  final String? slug;
  final String? icon;
  final String? groupName;

  const PlaceAmenityRecord({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
    this.groupName,
  });

  factory PlaceAmenityRecord.fromJson(Map<String, dynamic> json) =>
      PlaceAmenityRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: (json['name'] as String?) ?? '',
        slug: json['slug'] as String?,
        icon: json['icon'] as String?,
        groupName: json['groupName'] as String?,
      );
}

/// Real-Mode mirror of the nullable `PlaceMetadataResponse`. Enum values are
/// kept as raw UPPER-CASE strings; the UI maps them to localized labels.
/// Nothing is fabricated — absent fields stay null/empty and the detail screen
/// hides the section when [isEmpty].
class PlaceMetadataRecord {
  final List<String> travelStyles;
  final List<String> bestVisitTimes;
  final List<String> bestSeasons;
  final List<String> weatherTypes;
  final int? estimatedVisitMinutes;
  final String? budgetLevel;
  final String? difficultyLevel;
  final String? accessibilityLevel;
  final String? crowdLevel;
  final bool romantic;
  final bool familyFriendly;
  final bool kidFriendly;
  final bool petFriendly;
  final bool wheelchairFriendly;
  final bool photographySpot;
  final bool sunsetSpot;
  final bool sunriseSpot;
  final bool indoor;
  final bool outdoor;
  final bool rainyDaySuitable;
  final String? notes;

  const PlaceMetadataRecord({
    this.travelStyles = const [],
    this.bestVisitTimes = const [],
    this.bestSeasons = const [],
    this.weatherTypes = const [],
    this.estimatedVisitMinutes,
    this.budgetLevel,
    this.difficultyLevel,
    this.accessibilityLevel,
    this.crowdLevel,
    this.romantic = false,
    this.familyFriendly = false,
    this.kidFriendly = false,
    this.petFriendly = false,
    this.wheelchairFriendly = false,
    this.photographySpot = false,
    this.sunsetSpot = false,
    this.sunriseSpot = false,
    this.indoor = false,
    this.outdoor = false,
    this.rainyDaySuitable = false,
    this.notes,
  });

  factory PlaceMetadataRecord.fromJson(Map<String, dynamic> json) {
    List<String> enumList(Object? raw) => (raw as List<dynamic>? ?? const [])
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    return PlaceMetadataRecord(
      travelStyles: enumList(json['travelStyles']),
      bestVisitTimes: enumList(json['bestVisitTimes']),
      bestSeasons: enumList(json['bestSeasons']),
      weatherTypes: enumList(json['weatherTypes']),
      estimatedVisitMinutes: (json['estimatedVisitMinutes'] as num?)?.toInt(),
      budgetLevel: json['estimatedBudgetLevel'] as String?,
      difficultyLevel: json['difficultyLevel'] as String?,
      accessibilityLevel: json['accessibilityLevel'] as String?,
      crowdLevel: json['crowdLevel'] as String?,
      romantic: (json['romantic'] as bool?) ?? false,
      familyFriendly: (json['familyFriendly'] as bool?) ?? false,
      kidFriendly: (json['kidFriendly'] as bool?) ?? false,
      petFriendly: (json['petFriendly'] as bool?) ?? false,
      wheelchairFriendly: (json['wheelchairFriendly'] as bool?) ?? false,
      photographySpot: (json['photographySpot'] as bool?) ?? false,
      sunsetSpot: (json['sunsetSpot'] as bool?) ?? false,
      sunriseSpot: (json['sunriseSpot'] as bool?) ?? false,
      indoor: (json['indoor'] as bool?) ?? false,
      outdoor: (json['outdoor'] as bool?) ?? false,
      rainyDaySuitable: (json['rainyDaySuitable'] as bool?) ?? false,
      notes: json['notes'] as String?,
    );
  }

  /// The subset of boolean characteristic flags that are `true`, as raw keys
  /// the UI maps to localized labels. Order is stable for deterministic render.
  List<String> get activeFlags {
    final flags = <String>[];
    if (romantic) flags.add('romantic');
    if (familyFriendly) flags.add('familyFriendly');
    if (kidFriendly) flags.add('kidFriendly');
    if (petFriendly) flags.add('petFriendly');
    if (wheelchairFriendly) flags.add('wheelchairFriendly');
    if (photographySpot) flags.add('photographySpot');
    if (sunsetSpot) flags.add('sunsetSpot');
    if (sunriseSpot) flags.add('sunriseSpot');
    if (indoor) flags.add('indoor');
    if (outdoor) flags.add('outdoor');
    if (rainyDaySuitable) flags.add('rainyDaySuitable');
    return flags;
  }

  bool get isEmpty =>
      travelStyles.isEmpty &&
      bestVisitTimes.isEmpty &&
      bestSeasons.isEmpty &&
      weatherTypes.isEmpty &&
      estimatedVisitMinutes == null &&
      budgetLevel == null &&
      difficultyLevel == null &&
      accessibilityLevel == null &&
      crowdLevel == null &&
      activeFlags.isEmpty &&
      (notes == null || notes!.trim().isEmpty);
}

/// One hotel facility from `hotelDetail.facilities` (`FacilityResponse`) — keeps
/// the `facilityGroup` the collapsed demo [HotelDetail] discards.
class HotelFacilityRecord {
  final int id;
  final String facilityName;
  final String? facilityGroup;
  final String? icon;
  final int sortOrder;

  const HotelFacilityRecord({
    required this.id,
    required this.facilityName,
    this.facilityGroup,
    this.icon,
    this.sortOrder = 0,
  });

  factory HotelFacilityRecord.fromJson(Map<String, dynamic> json) =>
      HotelFacilityRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        facilityName: (json['facilityName'] as String?) ?? '',
        facilityGroup: json['facilityGroup'] as String?,
        icon: json['icon'] as String?,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

/// One hotel service from `hotelDetail.services` (`ServiceResponse`) — keeps the
/// `available` flag the collapsed demo [HotelDetail] discards.
class HotelServiceRecord {
  final int id;
  final String serviceName;
  final String? icon;
  final bool available;

  const HotelServiceRecord({
    required this.id,
    required this.serviceName,
    this.icon,
    this.available = true,
  });

  factory HotelServiceRecord.fromJson(Map<String, dynamic> json) =>
      HotelServiceRecord(
        id: (json['id'] as num?)?.toInt() ?? 0,
        serviceName: (json['serviceName'] as String?) ?? '',
        icon: json['icon'] as String?,
        available: (json['available'] as bool?) ?? true,
      );
}

/// Parking info from `hotelDetail.parking` (`ParkingInfo`).
class HotelParkingRecord {
  final bool available;
  final bool free;
  final String? description;

  const HotelParkingRecord({
    this.available = false,
    this.free = false,
    this.description,
  });

  factory HotelParkingRecord.fromJson(Map<String, dynamic> json) =>
      HotelParkingRecord(
        available: (json['parkingAvailable'] as bool?) ?? false,
        free: (json['parkingFree'] as bool?) ?? false,
        description: json['parkingDescription'] as String?,
      );

  bool get hasInfo =>
      available || free || (description?.trim().isNotEmpty ?? false);
}

/// Internet info from `hotelDetail.internet` (`InternetInfo`).
class HotelInternetRecord {
  final bool wifiAvailable;
  final bool wifiFree;
  final String? description;

  const HotelInternetRecord({
    this.wifiAvailable = false,
    this.wifiFree = false,
    this.description,
  });

  factory HotelInternetRecord.fromJson(Map<String, dynamic> json) =>
      HotelInternetRecord(
        wifiAvailable: (json['wifiAvailable'] as bool?) ?? false,
        wifiFree: (json['wifiFree'] as bool?) ?? false,
        description: json['internetDescription'] as String?,
      );

  bool get hasInfo =>
      wifiAvailable || wifiFree || (description?.trim().isNotEmpty ?? false);
}

/// Rich Real-Mode mirror of `hotelDetail` — preserves facility grouping, service
/// availability, and the parking/wifi booleans that the collapsed demo
/// [HotelDetail] drops. Rooms reuse the shared [HotelRoom] model; times are
/// trimmed to `HH:mm`. Every value comes from the backend; nothing is invented.
class HotelDetailRecord {
  final int id;
  final int? starRating;
  final String? checkInTime;
  final String? checkOutTime;
  final int? distanceToBeachMeters;
  final int? distanceToCityCenterMeters;
  final int? totalRooms;
  final int? availableRooms;
  final bool freeCancellation;
  final String? cancellationPolicy;
  final bool prepaymentRequired;
  final String? paymentPolicy;
  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;
  final bool breakfastIncluded;
  final bool airportShuttle;
  final List<HotelFacilityRecord> facilities;
  final List<HotelServiceRecord> services;
  final List<String> languages;
  final List<String> paymentMethods;
  final HotelParkingRecord parking;
  final HotelInternetRecord internet;
  final List<HotelRoom> rooms;

  const HotelDetailRecord({
    required this.id,
    this.starRating,
    this.checkInTime,
    this.checkOutTime,
    this.distanceToBeachMeters,
    this.distanceToCityCenterMeters,
    this.totalRooms,
    this.availableRooms,
    this.freeCancellation = false,
    this.cancellationPolicy,
    this.prepaymentRequired = false,
    this.paymentPolicy,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
    this.breakfastIncluded = false,
    this.airportShuttle = false,
    this.facilities = const [],
    this.services = const [],
    this.languages = const [],
    this.paymentMethods = const [],
    this.parking = const HotelParkingRecord(),
    this.internet = const HotelInternetRecord(),
    this.rooms = const [],
  });

  factory HotelDetailRecord.fromJson(Map<String, dynamic> json) {
    List<String> stringList(Object? raw) => (raw as List<dynamic>? ?? const [])
        .map((e) => e?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final parking = json['parking'] as Map<String, dynamic>?;
    final internet = json['internet'] as Map<String, dynamic>?;
    return HotelDetailRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      starRating: (json['starRating'] as num?)?.toInt(),
      checkInTime: _shortTime(json['checkInTime'] as String?),
      checkOutTime: _shortTime(json['checkOutTime'] as String?),
      distanceToBeachMeters: (json['distanceToBeachMeters'] as num?)?.toInt(),
      distanceToCityCenterMeters:
          (json['distanceToCityCenterMeters'] as num?)?.toInt(),
      totalRooms: (json['totalRooms'] as num?)?.toInt(),
      availableRooms: (json['availableRooms'] as num?)?.toInt(),
      freeCancellation: (json['freeCancellation'] as bool?) ?? false,
      cancellationPolicy: json['cancellationPolicy'] as String?,
      prepaymentRequired: (json['prepaymentRequired'] as bool?) ?? false,
      paymentPolicy: json['paymentPolicy'] as String?,
      childrenPolicy: json['childrenPolicy'] as String?,
      petPolicy: json['petPolicy'] as String?,
      smokingPolicy: json['smokingPolicy'] as String?,
      breakfastIncluded: (json['breakfastIncluded'] as bool?) ?? false,
      airportShuttle: (json['airportShuttle'] as bool?) ?? false,
      facilities: (json['facilities'] as List<dynamic>? ?? const [])
          .map((e) => HotelFacilityRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      services: (json['services'] as List<dynamic>? ?? const [])
          .map((e) => HotelServiceRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      languages: stringList(json['languages']),
      paymentMethods: stringList(json['paymentMethods']),
      parking: parking == null
          ? const HotelParkingRecord()
          : HotelParkingRecord.fromJson(parking),
      internet: internet == null
          ? const HotelInternetRecord()
          : HotelInternetRecord.fromJson(internet),
      rooms: (json['rooms'] as List<dynamic>? ?? const [])
          .map((e) => _hotelRoomFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Facilities grouped by `facilityGroup` (null/blank → `GENERAL`), each list
  /// sorted by `sortOrder`, groups in first-seen order. Empty when no facilities.
  List<MapEntry<String, List<HotelFacilityRecord>>> get groupedFacilities {
    final groups = <String, List<HotelFacilityRecord>>{};
    for (final f in facilities) {
      final key = (f.facilityGroup == null || f.facilityGroup!.trim().isEmpty)
          ? 'GENERAL'
          : f.facilityGroup!.trim().toUpperCase();
      groups.putIfAbsent(key, () => <HotelFacilityRecord>[]).add(f);
    }
    for (final list in groups.values) {
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return groups.entries.toList();
  }
}

/// Trims a backend `"HH:mm:ss"` (or `"HH:mm"`) time string down to `"HH:mm"`.
String? _shortTime(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final parts = raw.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return raw;
}

/// Best-effort parent (province-level) segment of a collapsed location
/// `fullPath` hierarchy. Uses only backend-supplied text — never invents an
/// administrative division. Falls back to [fallback] when the path has no
/// distinct parent segment.
String _provinceFromFullPath(String? fullPath, String fallback) {
  if (fullPath == null || fullPath.trim().isEmpty) return fallback;
  for (final sep in const [' > ', ' / ', ' - ', ',', '/', '>']) {
    if (fullPath.contains(sep)) {
      final parts = fullPath
          .split(sep)
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.length >= 2) return parts[parts.length - 2];
    }
  }
  return fallback;
}

RoomType _roomTypeFromCode(String? code) {
  final upper = (code ?? '').toUpperCase();
  return RoomType.values.firstWhere(
    (v) => v.code == upper,
    orElse: () => RoomType.standard,
  );
}

BedType _bedTypeFromCode(String? code) {
  final upper = (code ?? '').toUpperCase();
  return BedType.values.firstWhere(
    (v) => v.code == upper,
    orElse: () => BedType.single,
  );
}

/// Maps a `PlaceDetailResponse.hotelDetail` JSON object (already decoded) into
/// the Demo-Mode-shaped domain [HotelDetail]. Every value comes from the
/// backend response; nothing is fabricated. `ratePlans` are intentionally left
/// empty — they are a local booking-preview concept computed elsewhere and are
/// out of hydration scope.
HotelDetail _hotelDetailFromJson(Map<String, dynamic> json) {
  List<String> stringList(Object? raw) => (raw as List<dynamic>? ?? const [])
      .map((e) => e?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();

  final facilities = (json['facilities'] as List<dynamic>? ?? const [])
      .map((e) => (e as Map<String, dynamic>)['facilityName']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  final services = (json['services'] as List<dynamic>? ?? const [])
      .map((e) => (e as Map<String, dynamic>)['serviceName']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  final parking = json['parking'] as Map<String, dynamic>?;
  final internet = json['internet'] as Map<String, dynamic>?;
  final rooms = (json['rooms'] as List<dynamic>? ?? const [])
      .map((e) => _hotelRoomFromJson(e as Map<String, dynamic>))
      .toList();

  return HotelDetail(
    starRating: (json['starRating'] as num?)?.toInt(),
    checkInTime: _shortTime(json['checkInTime'] as String?),
    checkOutTime: _shortTime(json['checkOutTime'] as String?),
    distanceToBeachMeters: (json['distanceToBeachMeters'] as num?)?.toInt(),
    distanceToCityCenterMeters:
        (json['distanceToCityCenterMeters'] as num?)?.toInt(),
    totalRooms: (json['totalRooms'] as num?)?.toInt(),
    availableRooms: (json['availableRooms'] as num?)?.toInt(),
    freeCancellation: json['freeCancellation'] as bool?,
    cancellationPolicy: json['cancellationPolicy'] as String?,
    prepaymentRequired: json['prepaymentRequired'] as bool?,
    paymentPolicy: json['paymentPolicy'] as String?,
    childrenPolicy: json['childrenPolicy'] as String?,
    petPolicy: json['petPolicy'] as String?,
    smokingPolicy: json['smokingPolicy'] as String?,
    breakfastIncluded: json['breakfastIncluded'] as bool?,
    airportShuttle: json['airportShuttle'] as bool?,
    facilities: facilities,
    services: services,
    languages: stringList(json['languages']),
    paymentMethods: stringList(json['paymentMethods']),
    parking: parking?['parkingDescription'] as String?,
    internet: internet?['internetDescription'] as String?,
    rooms: rooms,
  );
}

HotelRoom _hotelRoomFromJson(Map<String, dynamic> json) {
  final gallery = (json['galleryImages'] as List<dynamic>? ?? const [])
      .map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  final amenities = (json['amenities'] as List<dynamic>? ?? const [])
      .map((e) => (e as Map<String, dynamic>)['name']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  return HotelRoom(
    id: (json['id'] as num?)?.toInt() ?? 0,
    roomName: (json['roomName'] as String?) ?? '',
    roomCode: (json['roomCode'] as String?) ?? '',
    roomType: _roomTypeFromCode(json['roomType'] as String?),
    description: (json['description'] as String?) ?? '',
    bedType: _bedTypeFromCode(json['bedType'] as String?),
    bedCount: (json['bedCount'] as num?)?.toInt() ?? 1,
    maxAdults: (json['maxAdults'] as num?)?.toInt() ?? 1,
    maxChildren: (json['maxChildren'] as num?)?.toInt() ?? 0,
    maxGuests: (json['maxGuests'] as num?)?.toInt() ?? 1,
    roomSizeSqm: (json['roomSizeSqm'] as num?)?.toInt(),
    floorNumber: (json['floorNumber'] as num?)?.toInt(),
    smokingAllowed: (json['smokingAllowed'] as bool?) ?? false,
    breakfastIncluded: (json['breakfastIncluded'] as bool?) ?? false,
    freeCancellation: (json['freeCancellation'] as bool?) ?? false,
    instantConfirmation: (json['instantConfirmation'] as bool?) ?? false,
    priceFrom: (json['priceFrom'] as num?)?.toDouble(),
    originalPrice: (json['originalPrice'] as num?)?.toDouble(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
    active: (json['active'] as bool?) ?? true,
    amenities: amenities,
    coverImageUrl: json['coverImageUrl'] as String?,
    galleryImages: gallery,
    // ratePlans are a local booking-preview concept, out of hydration scope.
  );
}

/// Typed transport mirror of the backend `PlaceDetailResponse`
/// (`GET /api/places/{id}`). All `Map<String, dynamic>` decoding is confined to
/// [fromJson]; [toPlace] is a pure typed→typed mapping into the Demo-Mode-shaped
/// domain [Place]. The backend collapses the location hierarchy into
/// `location.name` (leaf) + `location.fullPath`, and has no discrete
/// city/province/country — [toPlace] reuses the authoritative location text
/// rather than inventing administrative divisions.
class PlaceDetailRecord {
  final int id;
  final String name;
  final String? slug;
  final String? shortDescription;
  final String? description;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? categoryName;
  final String? categorySlug;
  final String? subcategorySlug;
  final String locationName;
  final String? locationFullPath;
  final double ratingAvg;
  final int ratingCount;
  final int priceLevel;
  final bool featured;
  final bool verified;
  final List<String> tags;
  final String? coverImageUrl;
  final List<PlaceGalleryImageRecord> galleryImages;
  final int? estimatedVisitMinutes;
  final List<PlaceOpeningHourGroupRecord> groupedOpeningHours;
  final HotelDetail? hotelDetail;

  // ── UI23 rich Real-Mode detail fields (dropped by [toPlace]) ──────────────
  final String? googleMapUrl;
  final bool openNow;
  final List<PlaceAmenityRecord> amenities;
  final PlaceMetadataRecord? metadata;
  final HotelDetailRecord? hotelDetailRich;

  /// Convenience view of [galleryImages] as plain URLs (used by [toPlace] and
  /// any summary rendering); derived so there is a single source of truth.
  List<String> get galleryUrls =>
      galleryImages.map((g) => g.url).where((u) => u.isNotEmpty).toList();

  const PlaceDetailRecord({
    required this.id,
    required this.name,
    this.slug,
    this.shortDescription,
    this.description,
    this.address = '',
    this.latitude,
    this.longitude,
    this.categoryName,
    this.categorySlug,
    this.subcategorySlug,
    this.locationName = '',
    this.locationFullPath,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.priceLevel = 0,
    this.featured = false,
    this.verified = false,
    this.tags = const [],
    this.coverImageUrl,
    this.galleryImages = const [],
    this.estimatedVisitMinutes,
    this.groupedOpeningHours = const [],
    this.hotelDetail,
    this.googleMapUrl,
    this.openNow = false,
    this.amenities = const [],
    this.metadata,
    this.hotelDetailRich,
  });

  factory PlaceDetailRecord.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final subcategory = json['subcategory'] as Map<String, dynamic>?;
    final location = json['location'] as Map<String, dynamic>?;
    final metadata = json['metadata'] as Map<String, dynamic>?;
    final hotelDetail = json['hotelDetail'] as Map<String, dynamic>?;
    return PlaceDetailRecord(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      slug: json['slug'] as String?,
      shortDescription: json['shortDescription'] as String?,
      description: json['description'] as String?,
      address: (json['address'] as String?) ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      categoryName: category?['name'] as String?,
      categorySlug: category?['slug'] as String?,
      subcategorySlug: subcategory?['slug'] as String?,
      locationName: (location?['name'] as String?) ?? '',
      locationFullPath: location?['fullPath'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 0,
      featured: (json['featured'] as bool?) ?? false,
      verified: (json['verified'] as bool?) ?? false,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((e) => (e as Map<String, dynamic>)['tag']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList(),
      coverImageUrl: json['coverImageUrl'] as String?,
      galleryImages: (json['galleryImages'] as List<dynamic>? ?? const [])
          .map((e) =>
              PlaceGalleryImageRecord.fromJson(e as Map<String, dynamic>))
          .where((g) => g.url.isNotEmpty)
          .toList(),
      estimatedVisitMinutes:
          (metadata?['estimatedVisitMinutes'] as num?)?.toInt(),
      groupedOpeningHours:
          (json['groupedOpeningHours'] as List<dynamic>? ?? const [])
              .map((e) => PlaceOpeningHourGroupRecord.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList(),
      hotelDetail:
          hotelDetail == null ? null : _hotelDetailFromJson(hotelDetail),
      googleMapUrl: json['googleMapUrl'] as String?,
      openNow: (json['openNow'] as bool?) ?? false,
      amenities: (json['amenities'] as List<dynamic>? ?? const [])
          .map((e) => PlaceAmenityRecord.fromJson(e as Map<String, dynamic>))
          .where((a) => a.name.isNotEmpty)
          .toList(),
      metadata:
          metadata == null ? null : PlaceMetadataRecord.fromJson(metadata),
      hotelDetailRich:
          hotelDetail == null ? null : HotelDetailRecord.fromJson(hotelDetail),
    );
  }

  /// Builds a compact opening-hours summary from [groupedOpeningHours], showing
  /// only the days the place is open (the backend already labels each group's
  /// `days`). Returns `null` when no open group is available so the detail
  /// screen simply omits the row rather than showing a fabricated schedule.
  String? get _openingHoursSummary {
    final open = groupedOpeningHours
        .where((g) => !g.closed && g.openTime != null && g.closeTime != null)
        .map((g) =>
            '${g.days}: ${_shortTime(g.openTime)}–${_shortTime(g.closeTime)}')
        .toList();
    return open.isEmpty ? null : open.join('\n');
  }

  /// Maps this verified backend detail into the full domain [Place]. Required
  /// [Place] fields the backend does not model discretely reuse authoritative
  /// backend text or the model's own neutral defaults — nothing is invented.
  Place toPlace() {
    final level = priceLevel.clamp(0, 4);
    return Place(
      id: id,
      name: name,
      category: categoryName ?? '',
      categorySlug: categorySlug,
      subcategorySlug: subcategorySlug,
      locationName: locationName,
      city: locationName,
      province: _provinceFromFullPath(locationFullPath, locationName),
      address: address,
      latitude: latitude,
      longitude: longitude,
      description: description ?? shortDescription ?? '',
      imageUrl:
          coverImageUrl ?? (galleryUrls.isNotEmpty ? galleryUrls.first : ''),
      rating: ratingAvg,
      reviewCount: ratingCount,
      priceLevel: '\$' * level,
      estimatedDurationMinutes: estimatedVisitMinutes ?? 60,
      openingHours: _openingHoursSummary,
      tags: tags,
      isFeatured: featured,
      verified: verified,
      hotelDetail: hotelDetail,
    );
  }
}

// ── Real Mode Trips (UI-20, `/api/me/trips` TripPlan planner) ────────────────
//
// Typed transport mirrors of the backend TripPlan DTOs. All `Map<String,
// dynamic>` decoding is confined to the `fromJson` factories. The real trip
// list/detail UIs render these records directly — they are deliberately NOT
// mapped into the Demo-Mode `Trip`/`TimelineItem` models (whose flat shape and
// travelers/budget fields the backend does not model). Backend dates are
// `yyyy-MM-dd`, times `HH:mm:ss`, timestamps ISO `Instant`.

/// Backend `TripPlanStatus` (`PLANNING/ACTIVE/COMPLETED/CANCELLED`). [unknown]
/// keeps forward-compatibility with any future status the backend may add — the
/// raw string is preserved on the record for honest display fallback.
enum TripPlanStatusValue { planning, active, completed, cancelled, unknown }

TripPlanStatusValue _tripStatusFromString(String? raw) {
  switch ((raw ?? '').toUpperCase()) {
    case 'PLANNING':
      return TripPlanStatusValue.planning;
    case 'ACTIVE':
      return TripPlanStatusValue.active;
    case 'COMPLETED':
      return TripPlanStatusValue.completed;
    case 'CANCELLED':
      return TripPlanStatusValue.cancelled;
    default:
      return TripPlanStatusValue.unknown;
  }
}

/// Defensive ISO date/instant parse — returns `null` for missing or malformed
/// values so a nullable backend field degrades honestly instead of throwing.
DateTime? _tryParseDate(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Machine-readable outcome of a real-mode trip operation. Mirrors
/// [SavedCollectionActionResult] and adds [forbidden]/[unprocessable] for the
/// 403/422 responses the TripPlan endpoints can return. [unavailable] is the
/// Demo Mode guard; [sessionExpired] maps a 401 without ever logging out.
enum TripActionResult {
  success,
  unavailable,
  network,
  timeout,
  sessionExpired,
  forbidden,
  notFound,
  conflict,
  unprocessable,
  validation,
  serverError,
  malformed,
}

/// Real-backend mirror of `TripSummaryResponse` (`GET /api/me/trips`). Carries
/// only list-row fields — no days (fetch the detail for those).
class TripSummaryRecord {
  final int id;
  final String title;
  final String? destination;
  final String? coverImage;
  final DateTime? startDate;
  final DateTime? endDate;
  final String statusRaw;
  final TripPlanStatusValue status;
  final bool isPublic;
  final int dayCount;
  final DateTime? updatedAt;

  const TripSummaryRecord({
    required this.id,
    required this.title,
    this.destination,
    this.coverImage,
    this.startDate,
    this.endDate,
    this.statusRaw = '',
    this.status = TripPlanStatusValue.unknown,
    this.isPublic = false,
    this.dayCount = 0,
    this.updatedAt,
  });

  factory TripSummaryRecord.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String?) ?? '';
    return TripSummaryRecord(
      id: (json['id'] as num).toInt(),
      title: (json['title'] as String?) ?? '',
      destination: json['destination'] as String?,
      coverImage: json['coverImage'] as String?,
      startDate: _tryParseDate(json['startDate']),
      endDate: _tryParseDate(json['endDate']),
      statusRaw: statusRaw,
      status: _tripStatusFromString(statusRaw),
      isPublic: (json['isPublic'] as bool?) ?? false,
      dayCount: (json['dayCount'] as num?)?.toInt() ?? 0,
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  /// Derives a summary row from a full detail record — used after create, where
  /// the backend returns a `TripResponse` but the list wants a summary row.
  factory TripSummaryRecord.fromDetail(TripDetailRecord d) => TripSummaryRecord(
        id: d.id,
        title: d.title,
        destination: d.destination,
        coverImage: d.coverImage,
        startDate: d.startDate,
        endDate: d.endDate,
        statusRaw: d.statusRaw,
        status: d.status,
        isPublic: d.isPublic,
        dayCount: d.days.length,
        updatedAt: d.updatedAt,
      );
}

/// Real-backend mirror of `TripItemResponse` — the "activity" row. An item is
/// either place-linked (`placeId`/`placeName`) or a custom activity
/// (`customTitle`). Times are trimmed to `HH:mm` for display.
class TripItemRecord {
  final int id;
  final int? placeId;
  final String? placeName;
  final String? placeSlug;
  final String? customTitle;
  final String? customDescription;
  final String? startTime;
  final String? endTime;
  final int sortOrder;
  final double? estimatedCost;
  final double? latitude;
  final double? longitude;
  final String? transportationNote;

  const TripItemRecord({
    required this.id,
    this.placeId,
    this.placeName,
    this.placeSlug,
    this.customTitle,
    this.customDescription,
    this.startTime,
    this.endTime,
    this.sortOrder = 0,
    this.estimatedCost,
    this.latitude,
    this.longitude,
    this.transportationNote,
  });

  bool get hasPlace => placeId != null;

  /// The linked place name, else the custom title, else empty.
  String get displayTitle => (placeName != null && placeName!.isNotEmpty)
      ? placeName!
      : (customTitle ?? '');

  factory TripItemRecord.fromJson(Map<String, dynamic> json) => TripItemRecord(
        id: (json['id'] as num).toInt(),
        placeId: (json['placeId'] as num?)?.toInt(),
        placeName: json['placeName'] as String?,
        placeSlug: json['placeSlug'] as String?,
        customTitle: json['customTitle'] as String?,
        customDescription: json['customDescription'] as String?,
        startTime: _shortTime(json['startTime'] as String?),
        endTime: _shortTime(json['endTime'] as String?),
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        transportationNote: json['transportationNote'] as String?,
      );
}

/// Real-backend mirror of `TripDayResponse`. Items are sorted by `sortOrder`
/// defensively (the backend already orders them).
class TripDayRecord {
  final int id;
  final int dayNumber;
  final DateTime? date;
  final String? title;
  final String? notes;
  final List<TripItemRecord> items;

  const TripDayRecord({
    required this.id,
    required this.dayNumber,
    this.date,
    this.title,
    this.notes,
    this.items = const [],
  });

  factory TripDayRecord.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((e) => TripItemRecord.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return TripDayRecord(
      id: (json['id'] as num).toInt(),
      dayNumber: (json['dayNumber'] as num?)?.toInt() ?? 0,
      date: _tryParseDate(json['date']),
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      items: items,
    );
  }

  TripDayRecord copyWith({List<TripItemRecord>? items}) => TripDayRecord(
        id: id,
        dayNumber: dayNumber,
        date: date,
        title: title,
        notes: notes,
        items: items ?? this.items,
      );
}

/// Real-backend mirror of `TripResponse` (`GET /api/me/trips/{id}`), the full
/// day→item itinerary. Days are sorted by `dayNumber` defensively.
class TripDetailRecord {
  final int id;
  final int? userId;
  final String title;
  final String? description;
  final String? destination;
  final String? coverImage;
  final DateTime? startDate;
  final DateTime? endDate;
  final String statusRaw;
  final TripPlanStatusValue status;
  final bool isPublic;
  final List<TripDayRecord> days;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TripDetailRecord({
    required this.id,
    this.userId,
    required this.title,
    this.description,
    this.destination,
    this.coverImage,
    this.startDate,
    this.endDate,
    this.statusRaw = '',
    this.status = TripPlanStatusValue.unknown,
    this.isPublic = false,
    this.days = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TripDetailRecord.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String?) ?? '';
    final days = (json['days'] as List<dynamic>? ?? const [])
        .map((e) => TripDayRecord.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    return TripDetailRecord(
      id: (json['id'] as num).toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      destination: json['destination'] as String?,
      coverImage: json['coverImage'] as String?,
      startDate: _tryParseDate(json['startDate']),
      endDate: _tryParseDate(json['endDate']),
      statusRaw: statusRaw,
      status: _tripStatusFromString(statusRaw),
      isPublic: (json['isPublic'] as bool?) ?? false,
      days: days,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }

  /// Next `dayNumber` to use when appending a new day (max existing + 1, else 1).
  int get nextDayNumber => days.isEmpty
      ? 1
      : days.map((d) => d.dayNumber).reduce((a, b) => a > b ? a : b) + 1;

  TripDetailRecord copyWith({List<TripDayRecord>? days}) => TripDetailRecord(
        id: id,
        userId: userId,
        title: title,
        description: description,
        destination: destination,
        coverImage: coverImage,
        startDate: startDate,
        endDate: endDate,
        statusRaw: statusRaw,
        status: status,
        isPublic: isPublic,
        days: days ?? this.days,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ── Real Mode Place Search (UI-21, `GET /api/places/search`) ─────────────────
//
// Typed transport mirrors of the backend `PageResponse<PlaceSummaryResponse>`.
// The search list is deliberately lean — the backend summary carries no
// tags/description/openingHours/gallery/distance, so result cards render only
// these fields and a full [Place] is materialised on demand via UI-19
// hydration (never fabricated). Note the summary's `administrativeUnit`/
// `reviewCount` naming differs from the detail DTO's `location`/`ratingCount`.

/// Backend sort tokens for `GET /api/places/search` (fixed whitelist; anything
/// else falls to `newest` server-side).
enum PlaceSearchSort { newest, ratingDesc, priceAsc, priceDesc, nameAsc }

extension PlaceSearchSortToken on PlaceSearchSort {
  String get token => switch (this) {
        PlaceSearchSort.newest => 'newest',
        PlaceSearchSort.ratingDesc => 'rating_desc',
        PlaceSearchSort.priceAsc => 'price_asc',
        PlaceSearchSort.priceDesc => 'price_desc',
        PlaceSearchSort.nameAsc => 'name_asc',
      };
}

/// Machine-readable outcome of a real-mode place-search operation. Mirrors
/// [TripActionResult]; [unavailable] is the Demo Mode guard. The public search
/// endpoint never returns 401/403, but [sessionExpired]/[forbidden] are mapped
/// defensively and never trigger a logout.
enum PlaceSearchOutcome {
  success,
  unavailable,
  network,
  timeout,
  sessionExpired,
  forbidden,
  notFound,
  validation,
  serverError,
  malformed,
}

/// Real-backend mirror of `PlaceSummaryResponse` — one search result row.
class PlaceSummaryRecord {
  final int id;
  final String name;
  final String? slug;
  final String? categoryName;
  final String? categorySlug;
  final String locationName;
  final String address;
  final String? shortDescription;
  final int priceLevel;
  final double ratingAvg;
  final int reviewCount;
  final bool featured;
  final bool verified;
  final String? coverImageUrl;
  final double? latitude;
  final double? longitude;

  const PlaceSummaryRecord({
    required this.id,
    required this.name,
    this.slug,
    this.categoryName,
    this.categorySlug,
    this.locationName = '',
    this.address = '',
    this.shortDescription,
    this.priceLevel = 0,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.featured = false,
    this.verified = false,
    this.coverImageUrl,
    this.latitude,
    this.longitude,
  });

  /// A faithful `$`-scale label for the 0–4 price level (empty when 0/unknown).
  String get priceLevelLabel => '\$' * priceLevel.clamp(0, 4);

  factory PlaceSummaryRecord.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final unit = json['administrativeUnit'] as Map<String, dynamic>?;
    return PlaceSummaryRecord(
      id: (json['id'] as num).toInt(),
      name: (json['name'] as String?) ?? '',
      slug: json['slug'] as String?,
      categoryName: category?['name'] as String?,
      categorySlug: category?['slug'] as String?,
      locationName: (unit?['name'] as String?) ?? '',
      address: (json['address'] as String?) ?? '',
      shortDescription: json['shortDescription'] as String?,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 0,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      featured: (json['featured'] as bool?) ?? false,
      verified: (json['verified'] as bool?) ?? false,
      coverImageUrl: json['coverImageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Real-backend mirror of `PageResponse<PlaceSummaryResponse>` (offset paging).
class PlaceSearchPage {
  final List<PlaceSummaryRecord> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const PlaceSearchPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  bool get hasMore => page + 1 < totalPages;

  factory PlaceSearchPage.fromJson(Map<String, dynamic> json) =>
      PlaceSearchPage(
        content: (json['content'] as List<dynamic>? ?? const [])
            .map((e) => PlaceSummaryRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
        page: (json['page'] as num?)?.toInt() ?? 0,
        size: (json['size'] as num?)?.toInt() ?? 0,
        totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
        totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      );
}

/// Machine-readable outcome of a real-mode hotel availability lookup. Mirrors
/// [PlaceSearchOutcome]; [unavailable] is the Demo Mode guard and [invalidDates]
/// is a client-side guard that mirrors the backend's own 400 for a check-out
/// that is not after check-in (or a past check-in). The public availability
/// endpoint never returns 401/403, but [sessionExpired]/[forbidden] are mapped
/// defensively and never trigger a logout.
enum HotelAvailabilityOutcome {
  success,
  unavailable,
  invalidDates,
  network,
  timeout,
  sessionExpired,
  forbidden,
  notFound,
  validation,
  serverError,
  malformed,
}

/// Real-backend mirror of `RatePlanDto.AvailableRoomResult` — one bookable room
/// returned by `GET /api/places/{placeId}/availability`. Every field comes
/// straight from the backend; nothing is synthesized. Money values are decoded
/// as-is (the availability DTO carries no explicit currency code — see
/// [HotelAvailabilityResult]).
class AvailableRoomRecord {
  final int roomId;
  final String roomName;
  final String? roomCode;
  final String? roomType;
  final String? bedType;
  final int? bedCount;
  final int? maxAdults;
  final int? maxChildren;
  final int? maxGuests;
  final double? roomSizeSqm;
  final bool breakfastIncluded;
  final bool freeCancellation;
  final bool instantConfirmation;
  final double? pricePerNight;
  final double? originalPricePerNight;
  final double? totalPrice;
  final int nights;
  final String? appliedRatePlan;
  final String? coverImageUrl;
  final List<String> amenities;

  const AvailableRoomRecord({
    required this.roomId,
    required this.roomName,
    this.roomCode,
    this.roomType,
    this.bedType,
    this.bedCount,
    this.maxAdults,
    this.maxChildren,
    this.maxGuests,
    this.roomSizeSqm,
    this.breakfastIncluded = false,
    this.freeCancellation = false,
    this.instantConfirmation = false,
    this.pricePerNight,
    this.originalPricePerNight,
    this.totalPrice,
    this.nights = 0,
    this.appliedRatePlan,
    this.coverImageUrl,
    this.amenities = const [],
  });

  /// True only when the backend reports a strictly lower current price than the
  /// original — used to show a discount without ever inventing one.
  bool get hasDiscount =>
      pricePerNight != null &&
      originalPricePerNight != null &&
      originalPricePerNight! > pricePerNight!;

  factory AvailableRoomRecord.fromJson(Map<String, dynamic> json) {
    final amenities = (json['amenities'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((a) => (a['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    return AvailableRoomRecord(
      roomId: (json['roomId'] as num).toInt(),
      roomName: (json['roomName'] as String?) ?? '',
      roomCode: json['roomCode'] as String?,
      roomType: json['roomType'] as String?,
      bedType: json['bedType'] as String?,
      bedCount: (json['bedCount'] as num?)?.toInt(),
      maxAdults: (json['maxAdults'] as num?)?.toInt(),
      maxChildren: (json['maxChildren'] as num?)?.toInt(),
      maxGuests: (json['maxGuests'] as num?)?.toInt(),
      roomSizeSqm: (json['roomSizeSqm'] as num?)?.toDouble(),
      breakfastIncluded: (json['breakfastIncluded'] as bool?) ?? false,
      freeCancellation: (json['freeCancellation'] as bool?) ?? false,
      instantConfirmation: (json['instantConfirmation'] as bool?) ?? false,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      originalPricePerNight:
          (json['originalPricePerNight'] as num?)?.toDouble(),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      nights: (json['nights'] as num?)?.toInt() ?? 0,
      appliedRatePlan: json['appliedRatePlan'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      amenities: amenities,
    );
  }
}

/// Real-backend mirror of `RatePlanDto.HotelAvailabilityResponse` for a single
/// hotel place and date range. The DTO carries no currency code, so callers use
/// the app's default (VND) formatting — documented as a known limitation.
class HotelAvailabilityResult {
  final int placeId;
  final String placeName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final int adults;
  final int children;
  final List<AvailableRoomRecord> availableRooms;

  const HotelAvailabilityResult({
    required this.placeId,
    this.placeName = '',
    this.checkIn,
    this.checkOut,
    this.nights = 0,
    this.adults = 1,
    this.children = 0,
    this.availableRooms = const [],
  });

  static DateTime? _parseDate(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  factory HotelAvailabilityResult.fromJson(Map<String, dynamic> json) =>
      HotelAvailabilityResult(
        placeId: (json['placeId'] as num?)?.toInt() ?? 0,
        placeName: (json['placeName'] as String?) ?? '',
        checkIn: _parseDate(json['checkIn']),
        checkOut: _parseDate(json['checkOut']),
        nights: (json['nights'] as num?)?.toInt() ?? 0,
        adults: (json['adults'] as num?)?.toInt() ?? 1,
        children: (json['children'] as num?)?.toInt() ?? 0,
        availableRooms: (json['availableRooms'] as List<dynamic>? ?? const [])
            .map((e) => AvailableRoomRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
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
      this == BookingStatus.pending || this == BookingStatus.confirmed;
}

enum BookingPaymentStatus {
  pending,
  paid,
  failed,
  cancelled,
  refunded,
}

extension BookingPaymentStatusData on BookingPaymentStatus {
  String get code {
    switch (this) {
      case BookingPaymentStatus.pending:
        return 'PENDING';
      case BookingPaymentStatus.paid:
        return 'PAID';
      case BookingPaymentStatus.failed:
        return 'FAILED';
      case BookingPaymentStatus.cancelled:
        return 'CANCELLED';
      case BookingPaymentStatus.refunded:
        return 'REFUNDED';
    }
  }
}

BookingStatus? bookingStatusFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final status in BookingStatus.values) {
    if (status.code == normalized) return status;
  }
  return null;
}

BookingPaymentStatus? bookingPaymentStatusFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final status in BookingPaymentStatus.values) {
    if (status.code == normalized) return status;
  }
  return null;
}

enum CheckoutPaymentMethod {
  mock,
  cash,
  card,
  bankTransfer,
  vnpay,
  momo,
  stripe,
  payos,
}

extension CheckoutPaymentMethodData on CheckoutPaymentMethod {
  String get code {
    switch (this) {
      case CheckoutPaymentMethod.mock:
        return 'MOCK';
      case CheckoutPaymentMethod.cash:
        return 'CASH';
      case CheckoutPaymentMethod.card:
        return 'CARD';
      case CheckoutPaymentMethod.bankTransfer:
        return 'BANK_TRANSFER';
      case CheckoutPaymentMethod.vnpay:
        return 'VNPAY';
      case CheckoutPaymentMethod.momo:
        return 'MOMO';
      case CheckoutPaymentMethod.stripe:
        return 'STRIPE';
      case CheckoutPaymentMethod.payos:
        return 'PAYOS';
    }
  }
}

CheckoutPaymentMethod? checkoutPaymentMethodFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final method in CheckoutPaymentMethod.values) {
    if (method.code == normalized) return method;
  }
  return null;
}

enum CheckoutPaymentProvider {
  mock,
  vnpay,
  payos,
  momo,
  stripe,
  applePay,
  googlePay,
  manual,
}

extension CheckoutPaymentProviderData on CheckoutPaymentProvider {
  String get code {
    switch (this) {
      case CheckoutPaymentProvider.mock:
        return 'MOCK';
      case CheckoutPaymentProvider.vnpay:
        return 'VNPAY';
      case CheckoutPaymentProvider.payos:
        return 'PAYOS';
      case CheckoutPaymentProvider.momo:
        return 'MOMO';
      case CheckoutPaymentProvider.stripe:
        return 'STRIPE';
      case CheckoutPaymentProvider.applePay:
        return 'APPLE_PAY';
      case CheckoutPaymentProvider.googlePay:
        return 'GOOGLE_PAY';
      case CheckoutPaymentProvider.manual:
        return 'MANUAL';
    }
  }

  CheckoutPaymentMethod get settlementMethod {
    switch (this) {
      case CheckoutPaymentProvider.vnpay:
        return CheckoutPaymentMethod.vnpay;
      case CheckoutPaymentProvider.momo:
        return CheckoutPaymentMethod.momo;
      case CheckoutPaymentProvider.stripe:
        return CheckoutPaymentMethod.stripe;
      case CheckoutPaymentProvider.payos:
        return CheckoutPaymentMethod.payos;
      case CheckoutPaymentProvider.manual:
        return CheckoutPaymentMethod.bankTransfer;
      case CheckoutPaymentProvider.mock:
      case CheckoutPaymentProvider.applePay:
      case CheckoutPaymentProvider.googlePay:
        return CheckoutPaymentMethod.mock;
    }
  }

  bool get hasCustomerSessionGateway {
    switch (this) {
      case CheckoutPaymentProvider.mock:
      case CheckoutPaymentProvider.vnpay:
      case CheckoutPaymentProvider.payos:
      case CheckoutPaymentProvider.momo:
      case CheckoutPaymentProvider.stripe:
        return true;
      case CheckoutPaymentProvider.applePay:
      case CheckoutPaymentProvider.googlePay:
      case CheckoutPaymentProvider.manual:
        return false;
    }
  }
}

enum PaymentSessionStatus {
  newSession,
  pending,
  authorized,
  captured,
  failed,
  cancelled,
  expired,
}

extension PaymentSessionStatusData on PaymentSessionStatus {
  String get code {
    switch (this) {
      case PaymentSessionStatus.newSession:
        return 'NEW';
      case PaymentSessionStatus.pending:
        return 'PENDING';
      case PaymentSessionStatus.authorized:
        return 'AUTHORIZED';
      case PaymentSessionStatus.captured:
        return 'CAPTURED';
      case PaymentSessionStatus.failed:
        return 'FAILED';
      case PaymentSessionStatus.cancelled:
        return 'CANCELLED';
      case PaymentSessionStatus.expired:
        return 'EXPIRED';
    }
  }

  bool get isTerminal =>
      this == PaymentSessionStatus.captured ||
      this == PaymentSessionStatus.failed ||
      this == PaymentSessionStatus.cancelled ||
      this == PaymentSessionStatus.expired;
}

CheckoutPaymentProvider? checkoutPaymentProviderFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final provider in CheckoutPaymentProvider.values) {
    if (provider.code == normalized) return provider;
  }
  return null;
}

PaymentSessionStatus? paymentSessionStatusFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final status in PaymentSessionStatus.values) {
    if (status.code == normalized) return status;
  }
  return null;
}

enum UserNotificationType {
  booking,
  payment,
  reservation,
  system,
  promotion,
  review,
  partner,
  admin,
  message,
  trip,
}

extension UserNotificationTypeData on UserNotificationType {
  String get code {
    switch (this) {
      case UserNotificationType.booking:
        return 'BOOKING';
      case UserNotificationType.payment:
        return 'PAYMENT';
      case UserNotificationType.reservation:
        return 'RESERVATION';
      case UserNotificationType.system:
        return 'SYSTEM';
      case UserNotificationType.promotion:
        return 'PROMOTION';
      case UserNotificationType.review:
        return 'REVIEW';
      case UserNotificationType.partner:
        return 'PARTNER';
      case UserNotificationType.admin:
        return 'ADMIN';
      case UserNotificationType.message:
        return 'MESSAGE';
      case UserNotificationType.trip:
        return 'TRIP';
    }
  }
}

UserNotificationType? userNotificationTypeFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final type in UserNotificationType.values) {
    if (type.code == normalized) return type;
  }
  return null;
}

enum UserNotificationPriority { low, normal, high, urgent }

extension UserNotificationPriorityData on UserNotificationPriority {
  String get code {
    switch (this) {
      case UserNotificationPriority.low:
        return 'LOW';
      case UserNotificationPriority.normal:
        return 'NORMAL';
      case UserNotificationPriority.high:
        return 'HIGH';
      case UserNotificationPriority.urgent:
        return 'URGENT';
    }
  }
}

UserNotificationPriority? userNotificationPriorityFromWire(String? value) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final priority in UserNotificationPriority.values) {
    if (priority.code == normalized) return priority;
  }
  return null;
}

enum UserNotificationRelatedEntityType {
  booking,
  payment,
  hotel,
  room,
  promotion,
  system,
  partner,
  message,
  trip,
}

extension UserNotificationRelatedEntityTypeData
    on UserNotificationRelatedEntityType {
  String get code {
    switch (this) {
      case UserNotificationRelatedEntityType.booking:
        return 'BOOKING';
      case UserNotificationRelatedEntityType.payment:
        return 'PAYMENT';
      case UserNotificationRelatedEntityType.hotel:
        return 'HOTEL';
      case UserNotificationRelatedEntityType.room:
        return 'ROOM';
      case UserNotificationRelatedEntityType.promotion:
        return 'PROMOTION';
      case UserNotificationRelatedEntityType.system:
        return 'SYSTEM';
      case UserNotificationRelatedEntityType.partner:
        return 'PARTNER';
      case UserNotificationRelatedEntityType.message:
        return 'MESSAGE';
      case UserNotificationRelatedEntityType.trip:
        return 'TRIP';
    }
  }
}

UserNotificationRelatedEntityType? userNotificationRelatedEntityTypeFromWire(
  String? value,
) {
  final normalized = value?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return null;
  for (final type in UserNotificationRelatedEntityType.values) {
    if (type.code == normalized) return type;
  }
  return null;
}

enum NotificationTargetKind {
  none,
  booking,
  payment,
  trip,
  tripCompanion,
  tripDocument,
  review,
  rewards,
  wallet,
}

enum DemoNotificationTemplate {
  bookingModified,
  paymentSuccessful,
  paymentFailed,
  tripCollaboration,
  itineraryReminder,
  reviewReply,
  rewardUnlocked,
  walletDocument,
  systemAccount,
}

class NotificationTarget {
  final NotificationTargetKind kind;
  final String? bookingCode;
  final String? paymentAttemptId;
  final int? tripId;
  final String? tripDocumentId;
  final int? reviewId;
  final String? walletItemId;

  const NotificationTarget._({
    required this.kind,
    this.bookingCode,
    this.paymentAttemptId,
    this.tripId,
    this.tripDocumentId,
    this.reviewId,
    this.walletItemId,
  });

  const NotificationTarget.none() : this._(kind: NotificationTargetKind.none);

  const NotificationTarget.booking(String code)
      : this._(kind: NotificationTargetKind.booking, bookingCode: code);

  const NotificationTarget.payment({
    required String bookingCode,
    required String attemptId,
  }) : this._(
          kind: NotificationTargetKind.payment,
          bookingCode: bookingCode,
          paymentAttemptId: attemptId,
        );

  const NotificationTarget.trip(int id)
      : this._(kind: NotificationTargetKind.trip, tripId: id);

  const NotificationTarget.tripCompanion(int id)
      : this._(kind: NotificationTargetKind.tripCompanion, tripId: id);

  const NotificationTarget.tripDocument({
    required int tripId,
    required String documentId,
  }) : this._(
          kind: NotificationTargetKind.tripDocument,
          tripId: tripId,
          tripDocumentId: documentId,
        );

  const NotificationTarget.review(int id)
      : this._(kind: NotificationTargetKind.review, reviewId: id);

  const NotificationTarget.rewards()
      : this._(kind: NotificationTargetKind.rewards);

  const NotificationTarget.wallet(String itemId)
      : this._(kind: NotificationTargetKind.wallet, walletItemId: itemId);

  bool get hasAction => kind != NotificationTargetKind.none;
}

class UserNotification {
  static const Object _unset = Object();

  final String id;
  final int? backendId;
  final UserNotificationType type;
  final UserNotificationPriority priority;
  final UserNotificationRelatedEntityType? relatedEntityType;
  final String? relatedEntityId;
  final DemoNotificationTemplate template;
  final NotificationTarget target;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool demoOnly;

  const UserNotification({
    required this.id,
    this.backendId,
    required this.type,
    this.priority = UserNotificationPriority.normal,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.template,
    this.target = const NotificationTarget.none(),
    required this.createdAt,
    this.readAt,
    this.demoOnly = true,
  });

  bool get read => readAt != null;

  UserNotification copyWith({
    String? id,
    Object? backendId = _unset,
    UserNotificationType? type,
    UserNotificationPriority? priority,
    Object? relatedEntityType = _unset,
    Object? relatedEntityId = _unset,
    DemoNotificationTemplate? template,
    NotificationTarget? target,
    DateTime? createdAt,
    Object? readAt = _unset,
    bool? demoOnly,
  }) =>
      UserNotification(
        id: id ?? this.id,
        backendId:
            identical(backendId, _unset) ? this.backendId : backendId as int?,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        relatedEntityType: identical(relatedEntityType, _unset)
            ? this.relatedEntityType
            : relatedEntityType as UserNotificationRelatedEntityType?,
        relatedEntityId: identical(relatedEntityId, _unset)
            ? this.relatedEntityId
            : relatedEntityId as String?,
        template: template ?? this.template,
        target: target ?? this.target,
        createdAt: createdAt ?? this.createdAt,
        readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
        demoOnly: demoOnly ?? this.demoOnly,
      );
}

enum NotificationActionResult {
  success,
  unavailable,
  notFound,
}

enum DemoPaymentActionResult {
  success,
  unavailable,
  notFound,
  duplicate,
  invalidState,
  quoteUnavailable,
  bookingUnavailable,
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

  /// Real-backend mirror of `RatePlanDto.RatePlanPricingBreakdownResponse`
  /// (`GET /api/rooms/{roomId}/rate-plans`). Every value is taken straight from
  /// the response; `Map` decoding is confined here. The DTO carries no currency
  /// code, so price fields use the app's default (VND) formatting downstream.
  factory HotelRatePlan.fromJson(Map<String, dynamic> json) => HotelRatePlan(
        ratePlanId: (json['ratePlanId'] as num?)?.toInt() ?? 0,
        code: (json['code'] as String?) ?? '',
        rateName: (json['rateName'] as String?) ?? '',
        roomId: (json['roomId'] as num?)?.toInt() ?? 0,
        roomName: (json['roomName'] as String?) ?? '',
        sourceType: (json['sourceType'] as String?) ?? '',
        parentRatePlanId: (json['parentRatePlanId'] as num?)?.toInt(),
        eligible: (json['eligible'] as bool?) ?? false,
        reason: json['reason'] as String?,
        nights: (json['nights'] as num?)?.toInt() ?? 0,
        baseNightlyRate: (json['baseNightlyRate'] as num?)?.toDouble(),
        derivedAdjustment: (json['derivedAdjustment'] as num?)?.toDouble() ?? 0,
        occupancyAdjustment:
            (json['occupancyAdjustment'] as num?)?.toDouble() ?? 0,
        childSupplement: (json['childSupplement'] as num?)?.toDouble() ?? 0,
        extraBedSupplement:
            (json['extraBedSupplement'] as num?)?.toDouble() ?? 0,
        finalNightlyRate: (json['finalNightlyRate'] as num?)?.toDouble(),
        staySubtotal: (json['staySubtotal'] as num?)?.toDouble(),
        mealPlan: _mealPlanFromCode(json['mealPlan'] as String?),
        cancellationPolicyType:
            _cancellationPolicyFromCode(json['cancellationPolicy'] as String?),
        refundable: (json['refundable'] as bool?) ?? false,
        cancellationDeadline: _tryParseDate(json['cancellationDeadline']),
        policySummary: (json['policySummary'] as String?) ?? '',
      );

  bool get hasBreakdown =>
      baseNightlyRate != null ||
      finalNightlyRate != null ||
      staySubtotal != null;
}

/// Outcome of loading a room's real rate plans (`GET /rooms/{id}/rate-plans`).
/// [unavailable] is the Demo Mode guard; [invalidDates] is a client-side guard
/// mirroring the backend 400; [sessionExpired] surfaces a 401 without logging
/// out (the endpoint is public so it is not expected).
enum RatePlanOutcome {
  success,
  unavailable,
  invalidDates,
  notFound,
  network,
  timeout,
  sessionExpired,
  forbidden,
  validation,
  serverError,
  malformed,
}

MealPlanType _mealPlanFromCode(String? code) {
  switch ((code ?? '').toUpperCase()) {
    case 'BREAKFAST':
      return MealPlanType.breakfast;
    case 'HALF_BOARD':
      return MealPlanType.halfBoard;
    case 'FULL_BOARD':
      return MealPlanType.fullBoard;
    case 'ALL_INCLUSIVE':
      return MealPlanType.allInclusive;
    case 'ROOM_ONLY':
    default:
      return MealPlanType.roomOnly;
  }
}

CancellationPolicyType _cancellationPolicyFromCode(String? code) {
  switch ((code ?? '').toUpperCase()) {
    case 'FREE_CANCELLATION':
      return CancellationPolicyType.freeCancellation;
    case 'PARTIALLY_REFUNDABLE':
      return CancellationPolicyType.partiallyRefundable;
    case 'NON_REFUNDABLE':
      return CancellationPolicyType.nonRefundable;
    case 'CUSTOM':
    default:
      return CancellationPolicyType.custom;
  }
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

  /// Real-backend mirror of `RoomPricingQuoteDto.RoomPricingQuoteResponse`
  /// (`POST /api/rooms/{roomId}/pricing/quote`, public, read-only). Every value
  /// is taken straight from the response — the backend computes all prices, so
  /// nothing here is calculated client-side (CLAUDE.md §6). `Map` decoding is
  /// confined to this factory. Unlike the availability/rate-plan DTOs, the quote
  /// carries a real `currency`, so downstream formatting is no longer hardcoded.
  factory HotelPricingQuote.fromJson(Map<String, dynamic> json) {
    final generated = _tryParseDate(json['quoteGeneratedAt']) ?? DateTime.now();
    return HotelPricingQuote(
      roomId: (json['roomId'] as num?)?.toInt() ?? 0,
      roomName: (json['roomName'] as String?) ?? '',
      roomCode: (json['roomCode'] as String?) ?? '',
      placeId: (json['placeId'] as num?)?.toInt() ?? 0,
      hotelId: (json['hotelId'] as num?)?.toInt(),
      checkIn: _tryParseDate(json['checkIn']) ?? generated,
      checkOut: _tryParseDate(json['checkOut']) ??
          generated.add(const Duration(days: 1)),
      nights: (json['nights'] as num?)?.toInt() ?? 1,
      adults: (json['adults'] as num?)?.toInt() ?? 1,
      children: (json['children'] as num?)?.toInt() ?? 0,
      extraBeds: (json['extraBeds'] as num?)?.toInt() ?? 0,
      selectedRatePlanId: (json['selectedRatePlanId'] as num?)?.toInt(),
      selectedRatePlanCode: json['selectedRatePlanCode'] as String?,
      selectedRatePlanName: json['selectedRatePlanName'] as String?,
      mealPlanType: json['mealPlanType'] == null
          ? null
          : _mealPlanFromCode(json['mealPlanType'] as String?),
      cancellationPolicyType: json['cancellationPolicyType'] == null
          ? null
          : _cancellationPolicyFromCode(
              json['cancellationPolicyType'] as String?),
      refundable: (json['refundable'] as bool?) ?? false,
      cancellationDeadline: _tryParseDate(json['cancellationDeadline']),
      baseNightlyRate: (json['baseNightlyRate'] as num?)?.toDouble(),
      derivedAdjustment: (json['derivedAdjustment'] as num?)?.toDouble() ?? 0,
      occupancyAdjustment:
          (json['occupancyAdjustment'] as num?)?.toDouble() ?? 0,
      childSupplement: (json['childSupplement'] as num?)?.toDouble() ?? 0,
      extraBedSupplement: (json['extraBedSupplement'] as num?)?.toDouble() ?? 0,
      finalNightlyRate: (json['finalNightlyRate'] as num?)?.toDouble(),
      staySubtotal: (json['staySubtotal'] as num?)?.toDouble(),
      promotionDiscount: (json['promotionDiscount'] as num?)?.toDouble() ?? 0,
      totalBeforeCustomerBenefits:
          (json['totalBeforeCustomerBenefits'] as num?)?.toDouble(),
      finalQuotedPrice: (json['finalQuotedPrice'] as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'VND',
      inventoryAvailable: (json['inventoryAvailable'] as bool?) ?? true,
      availableRooms: (json['availableRooms'] as num?)?.toInt() ?? 0,
      quoteGeneratedAt: generated,
      quoteExpiresAt: _tryParseDate(json['quoteExpiresAt']) ??
          generated.add(const Duration(minutes: 15)),
      warnings: (json['warnings'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          const [],
      eligibilityReason: json['eligibilityReason'] as String?,
    );
  }
}

/// Preset special-request options offered in the booking guest form. Each maps
/// to a localized label; the free-text note is stored separately. These are
/// composed into the backend's single `specialRequest` string only when a
/// future real booking-create call is wired (deferred).
enum SpecialRequestPreset {
  lateCheckIn,
  highFloor,
  quietRoom,
  twinBed,
  largeBed,
}

/// Locally-collected guest details for a booking draft. The backend booking
/// request carries no guest/traveler/contact object (the booker is the JWT
/// user, and no phone field exists in the domain), so [fullName], [phone] and
/// [country] are foundation-only local data; [arrivalTime] folds into the
/// backend `specialRequest` when a future create is wired.
class BookingGuestInfo {
  final String fullName;
  final String email;
  final String phone;
  final String country;
  final String arrivalTime;

  const BookingGuestInfo({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.country = '',
    this.arrivalTime = '',
  });
}

/// Per-field validation of the booking guest form. Pure value type — computed
/// from the working fields with no backend call. Mirrors the backend's own
/// `@NotNull`/`@Email` constraints where they exist, plus client-side length
/// limits for the local-only fields.
class BookingValidation {
  final bool nameRequired;
  final bool emailRequired;
  final bool emailInvalid;
  final bool phoneInvalid;
  final bool nameTooLong;
  final bool phoneTooLong;
  final bool countryTooLong;
  final bool noteTooLong;

  const BookingValidation({
    this.nameRequired = false,
    this.emailRequired = false,
    this.emailInvalid = false,
    this.phoneInvalid = false,
    this.nameTooLong = false,
    this.phoneTooLong = false,
    this.countryTooLong = false,
    this.noteTooLong = false,
  });

  bool get isValid =>
      !nameRequired &&
      !emailRequired &&
      !emailInvalid &&
      !phoneInvalid &&
      !nameTooLong &&
      !phoneTooLong &&
      !countryTooLong &&
      !noteTooLong;

  static const int maxNameLength = 120;
  static const int maxPhoneLength = 32;
  static const int maxCountryLength = 60;
  static const int maxNoteLength = 500;
}

/// A prepared (not yet submitted) booking. This is the honest "Booking Ready"
/// artifact of UI25: it snapshots the selected stay, guest details, requests and
/// the backend-computed [quote], but it is **not** a reservation — no booking
/// was created, so there is no reservation id, confirmation number, payment, or
/// status. The side-effecting `POST /api/bookings` create is deferred.
class BookingDraft {
  final int placeId;
  final String hotelName;
  final int roomId;
  final String roomName;
  final String? roomCode;
  final int? ratePlanId;
  final String? ratePlanName;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final int adults;
  final int children;
  final int extraBeds;
  final BookingGuestInfo guest;
  final Set<SpecialRequestPreset> specialRequestPresets;
  final String specialRequestNote;
  final HotelPricingQuote quote;
  final int? tripId;
  final DateTime createdAt;

  const BookingDraft({
    required this.placeId,
    required this.hotelName,
    required this.roomId,
    required this.roomName,
    this.roomCode,
    this.ratePlanId,
    this.ratePlanName,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.adults,
    required this.children,
    this.extraBeds = 0,
    required this.guest,
    this.specialRequestPresets = const {},
    this.specialRequestNote = '',
    required this.quote,
    this.tripId,
    required this.createdAt,
  });
}

/// Outcome of loading a real room pricing quote
/// (`POST /api/rooms/{id}/pricing/quote`). [unavailable] is the Demo Mode guard;
/// [invalidDates] is a client-side guard mirroring the backend 400. The endpoint
/// is public, so [sessionExpired]/[forbidden] are mapped defensively but not
/// expected.
enum BookingQuoteOutcome {
  success,
  unavailable,
  invalidDates,
  notFound,
  network,
  timeout,
  sessionExpired,
  forbidden,
  validation,
  serverError,
  malformed,
}

/// Outcome of preparing a client-side [BookingDraft]. [unavailable] is the Demo
/// Mode guard; [invalid] means the guest form failed validation; [quoteMissing]
/// means no backend quote is loaded yet. No reservation is ever created here.
enum BookingDraftOutcome { ready, invalid, quoteMissing, unavailable }

String _isoDay(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Typed request body for `POST /api/bookings` (verified against
/// `BookingDto.BookingRequest`). Only backend-supported fields are sent — the
/// backend has NO guest name / email / phone / country / arrival field, so those
/// local-only draft fields are never included; the sole free text is
/// [specialRequest]. `Map` construction is confined to [toJson]. UI26 collects no
/// coupon / travel-credit / gift-card, so those optional fields are omitted.
class BookingCreatePayload {
  final int roomId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int numberOfRooms;
  final int extraBeds;
  final int? ratePlanId;
  final String? specialRequest;

  const BookingCreatePayload({
    required this.roomId,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    this.children = 0,
    this.numberOfRooms = 1,
    this.extraBeds = 0,
    this.ratePlanId,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() {
    final sr = specialRequest?.trim();
    return {
      'roomId': roomId,
      'checkIn': _isoDay(checkIn),
      'checkOut': _isoDay(checkOut),
      'adults': adults,
      'children': children,
      'numberOfRooms': numberOfRooms,
      'extraBeds': extraBeds,
      if (ratePlanId != null) 'ratePlanId': ratePlanId,
      if (sr != null && sr.isNotEmpty) 'specialRequest': sr,
    };
  }
}

/// A safe, backend-normalized view of `BookingStatus`. Unknown/future server
/// values degrade to [unknown] (the raw string is preserved separately by the
/// caller) rather than being coerced into a misleading known state.
enum BookingStatusView {
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
  unknown,
}

BookingStatusView bookingStatusViewFromCode(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'PENDING':
      return BookingStatusView.pending;
    case 'CONFIRMED':
      return BookingStatusView.confirmed;
    case 'CHECK_IN_READY':
      return BookingStatusView.checkInReady;
    case 'CHECKED_IN':
      return BookingStatusView.checkedIn;
    case 'CHECKED_OUT':
      return BookingStatusView.checkedOut;
    case 'COMPLETED':
      return BookingStatusView.completed;
    case 'CANCELLED':
      return BookingStatusView.cancelled;
    case 'REFUNDED':
      return BookingStatusView.refunded;
    case 'ARCHIVED':
      return BookingStatusView.archived;
    case 'NO_SHOW':
      return BookingStatusView.noShow;
    default:
      return BookingStatusView.unknown;
  }
}

/// Real-backend mirror of `BookingDto.BookingResponse` (`POST /api/bookings`),
/// carrying only the fields the booking-result screen renders. Every price /
/// status / code value is the server's own (CLAUDE.md §6 — nothing computed
/// client-side); [status] is kept as the RAW server string so an unknown future
/// value is never coerced. `Map` decoding is confined to [fromJson].
class BookingCreateRecord {
  final int id;
  final String bookingCode;
  final int? hotelId;
  final String hotelName;
  final int roomId;
  final String roomName;
  final String? roomCode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final int adults;
  final int children;
  final int numberOfRooms;
  final String status;
  final String currency;
  final double? basePrice;
  final double? ratePlanPrice;
  final double? discountAmount;
  final double? finalPrice;
  final String? specialRequest;
  final int? selectedRatePlanId;
  final String? selectedRatePlanName;
  final bool? refundable;
  final DateTime? createdAt;
  final DateTime? confirmedAt;

  const BookingCreateRecord({
    required this.id,
    required this.bookingCode,
    this.hotelId,
    required this.hotelName,
    required this.roomId,
    required this.roomName,
    this.roomCode,
    this.checkIn,
    this.checkOut,
    this.nights = 0,
    this.adults = 0,
    this.children = 0,
    this.numberOfRooms = 1,
    required this.status,
    this.currency = 'VND',
    this.basePrice,
    this.ratePlanPrice,
    this.discountAmount,
    this.finalPrice,
    this.specialRequest,
    this.selectedRatePlanId,
    this.selectedRatePlanName,
    this.refundable,
    this.createdAt,
    this.confirmedAt,
  });

  BookingStatusView get statusView => bookingStatusViewFromCode(status);

  factory BookingCreateRecord.fromJson(Map<String, dynamic> json) {
    return BookingCreateRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingCode: (json['bookingCode'] as String?) ?? '',
      hotelId: (json['hotelId'] as num?)?.toInt(),
      hotelName: (json['hotelName'] as String?) ?? '',
      roomId: (json['roomId'] as num?)?.toInt() ?? 0,
      roomName: (json['roomName'] as String?) ?? '',
      roomCode: json['roomCode'] as String?,
      checkIn: _tryParseDate(json['checkIn']),
      checkOut: _tryParseDate(json['checkOut']),
      nights: (json['nights'] as num?)?.toInt() ?? 0,
      adults: (json['adults'] as num?)?.toInt() ?? 0,
      children: (json['children'] as num?)?.toInt() ?? 0,
      numberOfRooms: (json['numberOfRooms'] as num?)?.toInt() ?? 1,
      status: (json['status'] as String?) ?? '',
      currency: (json['currency'] as String?) ?? 'VND',
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      ratePlanPrice: (json['ratePlanPrice'] as num?)?.toDouble(),
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      specialRequest: json['specialRequest'] as String?,
      selectedRatePlanId: (json['selectedRatePlanId'] as num?)?.toInt(),
      selectedRatePlanName: json['selectedRatePlanName'] as String?,
      refundable: json['refundable'] as bool?,
      createdAt: _tryParseDate(json['createdAt']),
      confirmedAt: _tryParseDate(json['confirmedAt']),
    );
  }
}

/// Outcome of a real `POST /api/bookings` submission. Client-side guards:
/// [demoUnavailable] (Demo Mode — zero HTTP), [busy] (a submit is already in
/// flight — single-flight guard), [invalid] (guest form), [quoteMissing] (no
/// selection/quote). Server-mapped: [validation] 400, [sessionExpired] 401,
/// [forbidden] 403, [notFound] 404, [conflict] 409, [unprocessable] 422,
/// [serverError] 5xx, [network] transport. [uncertain] is a WRITE-safety outcome
/// — a timeout or malformed success where the booking MAY have been created, so
/// no blind retry is safe.
enum BookingSubmissionOutcome {
  success,
  invalid,
  quoteMissing,
  demoUnavailable,
  busy,
  validation,
  sessionExpired,
  forbidden,
  notFound,
  conflict,
  unprocessable,
  uncertain,
  network,
  serverError,
}

/// Real-backend mirror of `BookingDto.BookingSummaryResponse`
/// (`GET /api/me/bookings`) — the row shape for the UI27 booking-history list.
/// The backend returns a bare JSON array (all of the caller's bookings sorted
/// createdAt DESC; no pagination). Every value is the server's own; [status] is
/// kept as the RAW server string so an unknown/future value is never coerced.
/// `Map` decoding is confined to [fromJson].
class BookingSummaryRecord {
  final int id;
  final String bookingCode;
  final int? hotelId;
  final String hotelName;
  final int? roomId;
  final String roomName;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int nights;
  final String status;
  final double? finalPrice;
  final String currency;
  final DateTime? createdAt;

  const BookingSummaryRecord({
    required this.id,
    required this.bookingCode,
    this.hotelId,
    required this.hotelName,
    this.roomId,
    required this.roomName,
    this.checkIn,
    this.checkOut,
    this.nights = 0,
    required this.status,
    this.finalPrice,
    this.currency = 'VND',
    this.createdAt,
  });

  BookingStatusView get statusView => bookingStatusViewFromCode(status);

  factory BookingSummaryRecord.fromJson(Map<String, dynamic> json) {
    return BookingSummaryRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingCode: (json['bookingCode'] as String?) ?? '',
      hotelId: (json['hotelId'] as num?)?.toInt(),
      hotelName: (json['hotelName'] as String?) ?? '',
      roomId: (json['roomId'] as num?)?.toInt(),
      roomName: (json['roomName'] as String?) ?? '',
      checkIn: _tryParseDate(json['checkIn']),
      checkOut: _tryParseDate(json['checkOut']),
      nights: (json['nights'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'VND',
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Outcome of a real booking-history / booking-detail READ
/// (`GET /api/me/bookings`, `GET /api/bookings/{id}`). [demoUnavailable] is the
/// Demo Mode guard (zero HTTP); [sessionExpired] (401) never triggers
/// auto-logout — the caller shows a re-auth affordance. [forbidden] (403),
/// [notFound] (404), [serverError] (5xx / unexpected) and [network] (transport /
/// timeout) map the read failures. There is no write here, so no `uncertain`.
enum BookingHistoryOutcome {
  success,
  demoUnavailable,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

/// A safe, backend-normalized view of the settlement `PaymentStatus`
/// (PENDING/PAID/FAILED/CANCELLED/REFUNDED). Unknown/future server values degrade
/// to [unknown] (the raw string is preserved by the record) rather than being
/// coerced into a misleading known state.
enum PaymentStatusView { pending, paid, failed, cancelled, refunded, unknown }

PaymentStatusView paymentStatusViewFromCode(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'PENDING':
      return PaymentStatusView.pending;
    case 'PAID':
      return PaymentStatusView.paid;
    case 'FAILED':
      return PaymentStatusView.failed;
    case 'CANCELLED':
      return PaymentStatusView.cancelled;
    case 'REFUNDED':
      return PaymentStatusView.refunded;
    default:
      return PaymentStatusView.unknown;
  }
}

/// Real-backend mirror of `PaymentDto.PaymentResponse` (`POST /api/payments`,
/// `GET /api/payments/{id}`, `GET /api/bookings/{id}/payments`,
/// `.../mock-success`, `.../mock-fail`). Every amount / status / code value is
/// the server's own (CLAUDE.md §6 — nothing computed client-side); [status] is
/// kept as the RAW server string so an unknown future value is never coerced.
/// `Map` decoding is confined to [fromJson]. NOTE: this backend has no live
/// payment gateway — [checkoutUrl] is null for the settlement flow, so there is
/// no real redirect to launch.
class RealPaymentRecord {
  final int id;
  final String paymentCode;
  final int bookingId;
  final String bookingCode;
  final double? amount;
  final String currency;
  final String paymentMethod;
  final String status;
  final String provider;
  final String? providerTransactionId;
  final String? checkoutUrl;
  final String? failureReason;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? refundedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealPaymentRecord({
    required this.id,
    required this.paymentCode,
    required this.bookingId,
    required this.bookingCode,
    this.amount,
    this.currency = 'VND',
    this.paymentMethod = '',
    required this.status,
    this.provider = '',
    this.providerTransactionId,
    this.checkoutUrl,
    this.failureReason,
    this.paidAt,
    this.failedAt,
    this.refundedAt,
    this.createdAt,
    this.updatedAt,
  });

  PaymentStatusView get statusView => paymentStatusViewFromCode(status);

  factory RealPaymentRecord.fromJson(Map<String, dynamic> json) {
    return RealPaymentRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      paymentCode: (json['paymentCode'] as String?) ?? '',
      bookingId: (json['bookingId'] as num?)?.toInt() ?? 0,
      bookingCode: (json['bookingCode'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      currency: (json['currency'] as String?) ?? 'VND',
      paymentMethod: (json['paymentMethod'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      provider: (json['provider'] as String?) ?? '',
      providerTransactionId: json['providerTransactionId'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      failureReason: json['failureReason'] as String?,
      paidAt: _tryParseDate(json['paidAt']),
      failedAt: _tryParseDate(json['failedAt']),
      refundedAt: _tryParseDate(json['refundedAt']),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Outcome of a real payment action (`POST /api/payments`, its reads, and the
/// `mock-success` / `mock-fail` sandbox settlement endpoints). [demoUnavailable]
/// is the Demo Mode guard (zero HTTP); [busy] is the single-flight guard;
/// [sessionExpired] (401) never triggers auto-logout; [validation] 400,
/// [forbidden] 403, [notFound] 404, [conflict] 409, [unprocessable] 422 (e.g.
/// booking not payable / already paid / payment not PENDING), [serverError] 5xx,
/// [network] transport/timeout. No write here is idempotency-keyed, but every
/// action here is an explicit, user-initiated single request.
enum PaymentActionOutcome {
  success,
  demoUnavailable,
  busy,
  validation,
  sessionExpired,
  forbidden,
  notFound,
  conflict,
  unprocessable,
  network,
  serverError,
}

/// A safe, backend-normalized view of `ReviewStatus`
/// (PENDING/APPROVED/REJECTED/HIDDEN/REPORTED). A freshly-created review is
/// PENDING (awaiting moderation — not publicly visible until APPROVED). Unknown
/// values degrade to [unknown] (raw kept), never coerced.
enum ReviewStatusView {
  pending,
  approved,
  rejected,
  hidden,
  reported,
  unknown,
}

ReviewStatusView reviewStatusViewFromCode(String? raw) {
  switch (raw?.trim().toUpperCase()) {
    case 'PENDING':
      return ReviewStatusView.pending;
    case 'APPROVED':
      return ReviewStatusView.approved;
    case 'REJECTED':
      return ReviewStatusView.rejected;
    case 'HIDDEN':
      return ReviewStatusView.hidden;
    case 'REPORTED':
      return ReviewStatusView.reported;
    default:
      return ReviewStatusView.unknown;
  }
}

/// Real-backend mirror of `ReviewDto.ReviewMediaItem` (safe public projection of
/// a review's attached media). `Map` decoding is confined to [fromJson].
class ReviewMediaRecord {
  final int id;
  final String? url;
  final String? thumbnailUrl;
  final String? mediaType;
  final int sortOrder;
  final bool cover;
  final String? altText;

  const ReviewMediaRecord({
    required this.id,
    this.url,
    this.thumbnailUrl,
    this.mediaType,
    this.sortOrder = 0,
    this.cover = false,
    this.altText,
  });

  factory ReviewMediaRecord.fromJson(Map<String, dynamic> json) {
    return ReviewMediaRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      mediaType: json['mediaType'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      cover: json['cover'] as bool? ?? false,
      altText: json['altText'] as String?,
    );
  }
}

/// Real-backend mirror of `ReviewDto.PartnerReplyInfo` — the hotel's public
/// reply to a review. Null when the review has no reply.
class ReviewPartnerReplyRecord {
  final String content;
  final DateTime? repliedAt;
  final DateTime? updatedAt;
  final String? partnerDisplayName;

  const ReviewPartnerReplyRecord({
    required this.content,
    this.repliedAt,
    this.updatedAt,
    this.partnerDisplayName,
  });

  static ReviewPartnerReplyRecord? fromJsonOrNull(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    return ReviewPartnerReplyRecord(
      content: (raw['content'] as String?) ?? '',
      repliedAt: _tryParseDate(raw['repliedAt']),
      updatedAt: _tryParseDate(raw['updatedAt']),
      partnerDisplayName: raw['partnerDisplayName'] as String?,
    );
  }
}

List<ReviewMediaRecord> _reviewMediaFromJson(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ReviewMediaRecord.fromJson)
      .toList();
}

/// Real-backend mirror of `ReviewDto.ReviewSummaryResponse`
/// (`GET /api/me/reviews`, `GET /api/places/{id}/reviews`). [status] is kept as
/// the RAW server string so an unknown value is never coerced. `Map` decoding is
/// confined to [fromJson].
class ReviewSummaryRecord {
  final int id;
  final int? placeId;
  final String placeName;
  final int? userId;
  final String userName;
  final int? ratingOverall;
  final String? title;
  final String status;
  final DateTime? createdAt;
  final ReviewPartnerReplyRecord? partnerReply;
  final List<ReviewMediaRecord> media;

  const ReviewSummaryRecord({
    required this.id,
    this.placeId,
    this.placeName = '',
    this.userId,
    this.userName = '',
    this.ratingOverall,
    this.title,
    required this.status,
    this.createdAt,
    this.partnerReply,
    this.media = const [],
  });

  ReviewStatusView get statusView => reviewStatusViewFromCode(status);

  factory ReviewSummaryRecord.fromJson(Map<String, dynamic> json) {
    return ReviewSummaryRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      placeId: (json['placeId'] as num?)?.toInt(),
      placeName: (json['placeName'] as String?) ?? '',
      userId: (json['userId'] as num?)?.toInt(),
      userName: (json['userName'] as String?) ?? '',
      ratingOverall: (json['ratingOverall'] as num?)?.toInt(),
      title: json['title'] as String?,
      status: (json['status'] as String?) ?? '',
      createdAt: _tryParseDate(json['createdAt']),
      partnerReply:
          ReviewPartnerReplyRecord.fromJsonOrNull(json['partnerReply']),
      media: _reviewMediaFromJson(json['media']),
    );
  }
}

/// Real-backend mirror of `ReviewDto.ReviewResponse` (`POST /api/reviews`,
/// `GET /api/reviews/{id}`). Full detail incl. every sub-rating. [status] is kept
/// raw. `Map` decoding is confined to [fromJson].
class ReviewDetailRecord {
  final int id;
  final int? bookingId;
  final String? bookingCode;
  final int? userId;
  final String userName;
  final int? placeId;
  final String placeName;
  final int? ratingOverall;
  final int? ratingCleanliness;
  final int? ratingService;
  final int? ratingLocation;
  final int? ratingValue;
  final int? ratingFacilities;
  final String? title;
  final String? content;
  final String status;
  final int helpfulCount;
  final int reportedCount;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final ReviewPartnerReplyRecord? partnerReply;
  final List<ReviewMediaRecord> media;

  const ReviewDetailRecord({
    required this.id,
    this.bookingId,
    this.bookingCode,
    this.userId,
    this.userName = '',
    this.placeId,
    this.placeName = '',
    this.ratingOverall,
    this.ratingCleanliness,
    this.ratingService,
    this.ratingLocation,
    this.ratingValue,
    this.ratingFacilities,
    this.title,
    this.content,
    required this.status,
    this.helpfulCount = 0,
    this.reportedCount = 0,
    this.approvedAt,
    this.rejectedAt,
    this.rejectReason,
    this.createdAt,
    this.updatedAt,
    this.partnerReply,
    this.media = const [],
  });

  ReviewStatusView get statusView => reviewStatusViewFromCode(status);

  factory ReviewDetailRecord.fromJson(Map<String, dynamic> json) {
    return ReviewDetailRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingId: (json['bookingId'] as num?)?.toInt(),
      bookingCode: json['bookingCode'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      userName: (json['userName'] as String?) ?? '',
      placeId: (json['placeId'] as num?)?.toInt(),
      placeName: (json['placeName'] as String?) ?? '',
      ratingOverall: (json['ratingOverall'] as num?)?.toInt(),
      ratingCleanliness: (json['ratingCleanliness'] as num?)?.toInt(),
      ratingService: (json['ratingService'] as num?)?.toInt(),
      ratingLocation: (json['ratingLocation'] as num?)?.toInt(),
      ratingValue: (json['ratingValue'] as num?)?.toInt(),
      ratingFacilities: (json['ratingFacilities'] as num?)?.toInt(),
      title: json['title'] as String?,
      content: json['content'] as String?,
      status: (json['status'] as String?) ?? '',
      helpfulCount: (json['helpfulCount'] as num?)?.toInt() ?? 0,
      reportedCount: (json['reportedCount'] as num?)?.toInt() ?? 0,
      approvedAt: _tryParseDate(json['approvedAt']),
      rejectedAt: _tryParseDate(json['rejectedAt']),
      rejectReason: json['rejectReason'] as String?,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
      partnerReply:
          ReviewPartnerReplyRecord.fromJsonOrNull(json['partnerReply']),
      media: _reviewMediaFromJson(json['media']),
    );
  }
}

/// Typed request body for `POST /api/reviews` (verified against
/// `ReviewDto.ReviewRequest`). Only backend-supported fields are sent; sub-ratings
/// and title/content are omitted when unset. `Map` construction is confined to
/// [toJson].
class ReviewCreatePayload {
  final int bookingId;
  final int ratingOverall;
  final int? ratingCleanliness;
  final int? ratingService;
  final int? ratingLocation;
  final int? ratingValue;
  final int? ratingFacilities;
  final String? title;
  final String? content;

  const ReviewCreatePayload({
    required this.bookingId,
    required this.ratingOverall,
    this.ratingCleanliness,
    this.ratingService,
    this.ratingLocation,
    this.ratingValue,
    this.ratingFacilities,
    this.title,
    this.content,
  });

  Map<String, dynamic> toJson() {
    final t = title?.trim();
    final c = content?.trim();
    return {
      'bookingId': bookingId,
      'ratingOverall': ratingOverall,
      if (ratingCleanliness != null) 'ratingCleanliness': ratingCleanliness,
      if (ratingService != null) 'ratingService': ratingService,
      if (ratingLocation != null) 'ratingLocation': ratingLocation,
      if (ratingValue != null) 'ratingValue': ratingValue,
      if (ratingFacilities != null) 'ratingFacilities': ratingFacilities,
      if (t != null && t.isNotEmpty) 'title': t,
      if (c != null && c.isNotEmpty) 'content': c,
    };
  }
}

/// Outcome of a real review action (`GET /api/places/{id}/reviews`,
/// `GET /api/me/reviews`, `GET /api/reviews/{id}`, `POST /api/reviews`).
/// [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy] is the
/// single-flight guard; [sessionExpired] (401) never triggers auto-logout;
/// [validation] 400, [forbidden] 403, [notFound] 404, [alreadyReviewed] 409 (one
/// review per booking), [notCompleted] 422 (only completed bookings are
/// reviewable), [serverError] 5xx, [network] transport/timeout.
enum ReviewActionOutcome {
  success,
  demoUnavailable,
  busy,
  validation,
  sessionExpired,
  forbidden,
  notFound,
  alreadyReviewed,
  notCompleted,
  network,
  serverError,
}

/// Real-backend mirror of `NotificationDto` (`NotificationSummaryResponse` for
/// the list, `NotificationResponse` for a single item after mark-read). [title]
/// and [message] are literal server strings (NOT derived from a demo template);
/// [notificationType]/[priority] are kept raw and mapped to the existing
/// [UserNotificationType]/[UserNotificationPriority] view enums via the shared
/// wire mappers. `Map` decoding is confined to [fromJson].
class RealNotificationRecord {
  final int id;
  final String title;
  final String message;
  final String notificationType;
  final String priority;
  final bool read;
  final DateTime? readAt;
  final DateTime? createdAt;
  final String? relatedEntityType;
  final int? relatedEntityId;

  const RealNotificationRecord({
    required this.id,
    this.title = '',
    this.message = '',
    this.notificationType = '',
    this.priority = '',
    this.read = false,
    this.readAt,
    this.createdAt,
    this.relatedEntityType,
    this.relatedEntityId,
  });

  UserNotificationType? get typeView =>
      userNotificationTypeFromWire(notificationType);
  UserNotificationPriority? get priorityView =>
      userNotificationPriorityFromWire(priority);

  factory RealNotificationRecord.fromJson(Map<String, dynamic> json) {
    return RealNotificationRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      notificationType: (json['notificationType'] as String?) ?? '',
      priority: (json['priority'] as String?) ?? '',
      read: json['read'] as bool? ?? false,
      readAt: _tryParseDate(json['readAt']),
      createdAt: _tryParseDate(json['createdAt']),
      relatedEntityType: json['relatedEntityType'] as String?,
      relatedEntityId: (json['relatedEntityId'] as num?)?.toInt(),
    );
  }
}

/// Outcome of a real notification action (`GET /api/me/notifications`, its
/// mark-read / mark-all-read / delete mutations). [demoUnavailable] is the Demo
/// Mode guard (zero HTTP); [busy] the single-flight guard; [sessionExpired] (401)
/// never triggers auto-logout; [forbidden] 403, [notFound] 404, [serverError]
/// 5xx, [network] transport/timeout.
enum RealNotificationOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

/// Real-backend mirror of `RecentlyViewedDto.RecentlyViewedItemResponse`
/// (`GET /api/me/recently-viewed`). One row per (user, place), server-sorted
/// viewedAt DESC and capped to 50. `Map` decoding is confined to [fromJson].
class RecentlyViewedRecord {
  final int placeId;
  final String name;
  final String? slug;
  final String? categoryName;
  final String? address;
  final String? shortDescription;
  final double ratingAvg;
  final int reviewCount;
  final DateTime? viewedAt;

  const RecentlyViewedRecord({
    required this.placeId,
    this.name = '',
    this.slug,
    this.categoryName,
    this.address,
    this.shortDescription,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.viewedAt,
  });

  factory RecentlyViewedRecord.fromJson(Map<String, dynamic> json) {
    return RecentlyViewedRecord(
      placeId: (json['placeId'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      slug: json['slug'] as String?,
      categoryName: json['categoryName'] as String?,
      address: json['address'] as String?,
      shortDescription: json['shortDescription'] as String?,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      viewedAt: _tryParseDate(json['viewedAt']),
    );
  }
}

/// Outcome of a real recently-viewed action (`GET /api/me/recently-viewed`, the
/// record POST, and the clear / remove DELETEs). [demoUnavailable] is the Demo
/// Mode guard (zero HTTP); [busy] the single-flight guard; [sessionExpired] (401)
/// never triggers auto-logout; [forbidden] 403, [notFound] 404, [serverError]
/// 5xx, [network] transport/timeout.
enum RecentlyViewedOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

/// Real-backend mirror of `AuthDtos.UserDto` (`GET /api/me`). Read-only signed-in
/// identity; the server derives it from the JWT subject (owner-scoped). `Map`
/// decoding is confined to [fromJson].
class AccountIdentityRecord {
  final int id;
  final String fullName;
  final String email;
  final String role;

  const AccountIdentityRecord({
    this.id = 0,
    this.fullName = '',
    this.email = '',
    this.role = '',
  });

  factory AccountIdentityRecord.fromJson(Map<String, dynamic> json) {
    return AccountIdentityRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: (json['fullName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
    );
  }
}

/// Real-backend mirror of `CustomerProfileDto.CustomerProfileResponse`
/// (`GET`/`PUT /api/me/profile`). Owner-scoped travel profile; the server lazily
/// creates a default row on first access. `passportNumberMasked` is the ONLY
/// representation of the passport that is ever read back — the raw number is
/// write-only (see [CustomerProfileUpdate]). `profileCompleted` /
/// `completionPercentage` are server-computed. `Map` decoding is confined to
/// [fromJson].
class CustomerProfileRecord {
  final int? id;
  final int? userId;
  final String? avatarUrl;
  final String? preferredLanguage;
  final String? preferredCurrency;
  final String? preferredPaymentMethod;
  final String? nationality;
  final String? passportNumberMasked;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? accessibilityNeeds;
  final String? dietaryPreference;
  final String? travelStyle;
  final bool marketingConsent;
  final bool profileCompleted;
  final int completionPercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CustomerProfileRecord({
    this.id,
    this.userId,
    this.avatarUrl,
    this.preferredLanguage,
    this.preferredCurrency,
    this.preferredPaymentMethod,
    this.nationality,
    this.passportNumberMasked,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.accessibilityNeeds,
    this.dietaryPreference,
    this.travelStyle,
    this.marketingConsent = false,
    this.profileCompleted = false,
    this.completionPercentage = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerProfileRecord.fromJson(Map<String, dynamic> json) {
    return CustomerProfileRecord(
      id: (json['id'] as num?)?.toInt(),
      userId: (json['userId'] as num?)?.toInt(),
      avatarUrl: json['avatarUrl'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      preferredCurrency: json['preferredCurrency'] as String?,
      preferredPaymentMethod: json['preferredPaymentMethod'] as String?,
      nationality: json['nationality'] as String?,
      passportNumberMasked: json['passportNumberMasked'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      accessibilityNeeds: json['accessibilityNeeds'] as String?,
      dietaryPreference: json['dietaryPreference'] as String?,
      travelStyle: json['travelStyle'] as String?,
      marketingConsent: (json['marketingConsent'] as bool?) ?? false,
      profileCompleted: (json['profileCompleted'] as bool?) ?? false,
      completionPercentage:
          (json['completionPercentage'] as num?)?.toInt() ?? 0,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Write payload for `PUT /api/me/profile`
/// (`CustomerProfileDto.CustomerProfileRequest`). The endpoint is **full-replace**
/// — a null/absent field wipes the stored value (except `preferredLanguage` /
/// `preferredCurrency`, which the server preserves when blank). [passportNumber]
/// is the raw number (write-only; echoed back only as
/// [CustomerProfileRecord.passportNumberMasked]); leaving it null removes the
/// stored passport. [toJson] therefore emits ALL 12 keys every time so callers
/// resend the full record and only the fields they changed differ.
class CustomerProfileUpdate {
  final String? avatarUrl;
  final String? preferredLanguage;
  final String? preferredCurrency;
  final String? preferredPaymentMethod;
  final String? nationality;
  final String? passportNumber;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? accessibilityNeeds;
  final String? travelStyle;
  final String? dietaryPreference;
  final bool marketingConsent;

  const CustomerProfileUpdate({
    this.avatarUrl,
    this.preferredLanguage,
    this.preferredCurrency,
    this.preferredPaymentMethod,
    this.nationality,
    this.passportNumber,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.accessibilityNeeds,
    this.travelStyle,
    this.dietaryPreference,
    this.marketingConsent = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'avatarUrl': avatarUrl,
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'preferredPaymentMethod': preferredPaymentMethod,
      'nationality': nationality,
      'passportNumber': passportNumber,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'accessibilityNeeds': accessibilityNeeds,
      'travelStyle': travelStyle,
      'dietaryPreference': dietaryPreference,
      'marketingConsent': marketingConsent,
    };
  }
}

/// Outcome of a real customer profile action (`GET /api/me`,
/// `GET`/`PUT /api/me/profile`). [demoUnavailable] is the Demo Mode guard (zero
/// HTTP); [busy] the single-flight guard; [sessionExpired] (401) never triggers
/// auto-logout; [forbidden] 403, [notFound] 404, [serverError] 5xx, [network]
/// transport/timeout.
enum CustomerProfileOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

/// View classification of a backend gift-card `status`/`effectiveStatus` string
/// (`GiftCardStatus` enum: ISSUED, ACTIVE, PARTIALLY_REDEEMED, FULLY_REDEEMED,
/// EXPIRED, CANCELLED). [unknown] preserves forward-compatibility with any code
/// this client does not recognise — the raw string is always kept alongside.
enum GiftCardStatusView {
  issued,
  active,
  partiallyRedeemed,
  fullyRedeemed,
  expired,
  cancelled,
  unknown,
}

GiftCardStatusView giftCardStatusViewFromCode(String? code) {
  switch (code) {
    case 'ISSUED':
      return GiftCardStatusView.issued;
    case 'ACTIVE':
      return GiftCardStatusView.active;
    case 'PARTIALLY_REDEEMED':
      return GiftCardStatusView.partiallyRedeemed;
    case 'FULLY_REDEEMED':
      return GiftCardStatusView.fullyRedeemed;
    case 'EXPIRED':
      return GiftCardStatusView.expired;
    case 'CANCELLED':
      return GiftCardStatusView.cancelled;
    default:
      return GiftCardStatusView.unknown;
  }
}

/// Real-backend mirror of `GiftCardDto.GiftCardSummaryResponse`
/// (`GET /api/me/gift-cards`, a `PageResponse`). Prepaid promotional value only.
/// Amounts are decimal major units (backend `BigDecimal`); [status] is kept raw
/// with a [statusView] getter. `Map` decoding is confined to [fromJson].
class RealGiftCardSummary {
  final int id;
  final String maskedCode;
  final String productName;
  final double originalAmount;
  final double currentBalance;
  final String currency;
  final String status;
  final String effectiveStatus;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  const RealGiftCardSummary({
    required this.id,
    this.maskedCode = '',
    this.productName = '',
    this.originalAmount = 0,
    this.currentBalance = 0,
    this.currency = '',
    this.status = '',
    this.effectiveStatus = '',
    this.issuedAt,
    this.expiresAt,
  });

  GiftCardStatusView get statusView =>
      giftCardStatusViewFromCode(effectiveStatus);

  factory RealGiftCardSummary.fromJson(Map<String, dynamic> json) {
    return RealGiftCardSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      maskedCode: (json['maskedCode'] as String?) ?? '',
      productName: (json['productName'] as String?) ?? '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      effectiveStatus: (json['effectiveStatus'] as String?) ?? '',
      issuedAt: _tryParseDate(json['issuedAt']),
      expiresAt: _tryParseDate(json['expiresAt']),
    );
  }
}

/// Real-backend mirror of `GiftCardDto.GiftCardResponse` (`GET /api/me/gift-cards/{id}`,
/// and the response of claim/activate). `fullCode` is intentionally NOT stored —
/// only the masked code is ever surfaced. Nested product/purchaser/recipient are
/// flattened to their display fields. `Map` decoding is confined to [fromJson].
class RealGiftCardDetail {
  final int id;
  final String maskedCode;
  final String productName;
  final double originalAmount;
  final double currentBalance;
  final String currency;
  final String status;
  final String effectiveStatus;
  final String personalMessage;
  final String purchaserName;
  final String recipientName;
  final String recipientEmail;
  final DateTime? issuedAt;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final DateTime? cancelledAt;
  final DateTime? fullyRedeemedAt;

  const RealGiftCardDetail({
    required this.id,
    this.maskedCode = '',
    this.productName = '',
    this.originalAmount = 0,
    this.currentBalance = 0,
    this.currency = '',
    this.status = '',
    this.effectiveStatus = '',
    this.personalMessage = '',
    this.purchaserName = '',
    this.recipientName = '',
    this.recipientEmail = '',
    this.issuedAt,
    this.activatedAt,
    this.expiresAt,
    this.cancelledAt,
    this.fullyRedeemedAt,
  });

  GiftCardStatusView get statusView =>
      giftCardStatusViewFromCode(effectiveStatus);

  factory RealGiftCardDetail.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    final purchaser = json['purchaser'];
    final recipient = json['recipient'];
    return RealGiftCardDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      maskedCode: (json['maskedCode'] as String?) ?? '',
      productName: product is Map<String, dynamic>
          ? (product['name'] as String?) ?? ''
          : '',
      originalAmount: (json['originalAmount'] as num?)?.toDouble() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      effectiveStatus: (json['effectiveStatus'] as String?) ?? '',
      personalMessage: (json['personalMessage'] as String?) ?? '',
      purchaserName: purchaser is Map<String, dynamic>
          ? (purchaser['fullName'] as String?) ?? ''
          : '',
      recipientName: recipient is Map<String, dynamic>
          ? (recipient['fullName'] as String?) ?? ''
          : '',
      recipientEmail: (json['recipientEmail'] as String?) ?? '',
      issuedAt: _tryParseDate(json['issuedAt']),
      activatedAt: _tryParseDate(json['activatedAt']),
      expiresAt: _tryParseDate(json['expiresAt']),
      cancelledAt: _tryParseDate(json['cancelledAt']),
      fullyRedeemedAt: _tryParseDate(json['fullyRedeemedAt']),
    );
  }
}

/// Real-backend mirror of `GiftCardDto.GiftCardTransactionResponse`
/// (`GET /api/me/gift-cards/{id}/transactions`, a `PageResponse`). Immutable
/// ledger row. `Map` decoding is confined to [fromJson].
class RealGiftCardTransaction {
  final int id;
  final String transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final DateTime? createdAt;

  const RealGiftCardTransaction({
    required this.id,
    this.transactionType = '',
    this.amount = 0,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.description = '',
    this.createdAt,
  });

  bool get increasesBalance => balanceAfter > balanceBefore;

  factory RealGiftCardTransaction.fromJson(Map<String, dynamic> json) {
    return RealGiftCardTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      transactionType: (json['transactionType'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      description: (json['description'] as String?) ?? '',
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Typed page of gift-card summaries (`PageResponse<GiftCardSummaryResponse>`).
class RealGiftCardsPage {
  final List<RealGiftCardSummary> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const RealGiftCardsPage({
    this.content = const [],
    this.page = 0,
    this.size = 0,
    this.totalElements = 0,
    this.totalPages = 0,
  });

  bool get hasMore => page + 1 < totalPages;

  factory RealGiftCardsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    return RealGiftCardsPage(
      content: raw is List
          ? raw
              .map((e) =>
                  RealGiftCardSummary.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Typed page of gift-card transactions (`PageResponse<GiftCardTransactionResponse>`).
class RealGiftCardTransactionsPage {
  final List<RealGiftCardTransaction> content;
  final int page;
  final int totalPages;

  const RealGiftCardTransactionsPage({
    this.content = const [],
    this.page = 0,
    this.totalPages = 0,
  });

  factory RealGiftCardTransactionsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    return RealGiftCardTransactionsPage(
      content: raw is List
          ? raw
              .map((e) =>
                  RealGiftCardTransaction.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Outcome of a real gift-card action (`GET /api/me/gift-cards[/{id}[/transactions]]`,
/// `POST /claim`, `POST /{id}/activate`). [demoUnavailable] is the Demo Mode guard
/// (zero HTTP); [busy] the single-flight guard; [sessionExpired] (401) never
/// triggers auto-logout; [validation] 400/422, [forbidden] 403, [notFound] 404,
/// [conflict] 409, [serverError] 5xx, [network] transport/timeout.
enum GiftCardActionOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  validation,
  forbidden,
  notFound,
  conflict,
  network,
  serverError,
}

/// Maps a backend `LoyaltyTransactionType` wire string to the existing demo
/// [LoyaltyTransactionType] view enum (reusing its label + [knownIncrease]
/// direction logic). Returns null for any unrecognised code so the caller can
/// fall back to the balance delta.
LoyaltyTransactionType? loyaltyTransactionTypeFromCode(String? code) {
  switch (code) {
    case 'EARN_BOOKING':
      return LoyaltyTransactionType.earnBooking;
    case 'EARN_REVIEW':
      return LoyaltyTransactionType.earnReview;
    case 'GRANT':
      return LoyaltyTransactionType.grant;
    case 'ADJUSTMENT':
      return LoyaltyTransactionType.adjustment;
    case 'REVERSAL':
      return LoyaltyTransactionType.reversal;
    case 'REDEMPTION_DEBIT':
      return LoyaltyTransactionType.redemptionDebit;
    case 'REDEMPTION_RELEASE':
      return LoyaltyTransactionType.redemptionRelease;
    case 'REDEMPTION_REFUND':
      return LoyaltyTransactionType.redemptionRefund;
    default:
      return null;
  }
}

/// Real-backend mirror of `LoyaltyDto.LoyaltyAccountResponse` (`GET /api/me/loyalty`,
/// created lazily on first access). Points are integer counts (`long`), never
/// money. `Map` decoding is confined to [fromJson].
class RealLoyaltyAccount {
  final int id;
  final int userId;
  final int currentBalance;
  final int lifetimePointsEarned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealLoyaltyAccount({
    this.id = 0,
    this.userId = 0,
    this.currentBalance = 0,
    this.lifetimePointsEarned = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory RealLoyaltyAccount.fromJson(Map<String, dynamic> json) {
    return RealLoyaltyAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      currentBalance: (json['currentBalance'] as num?)?.toInt() ?? 0,
      lifetimePointsEarned:
          (json['lifetimePointsEarned'] as num?)?.toInt() ?? 0,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Real-backend mirror of `LoyaltyDto.LoyaltyTransactionResponse`
/// (`GET /api/me/loyalty/transactions`, an immutable ledger row). `points` is
/// always positive; direction is derived from [transactionType] (falling back to
/// the balance delta). `Map` decoding is confined to [fromJson].
class RealLoyaltyTransaction {
  final int id;
  final int accountId;
  final String transactionType;
  final int points;
  final int balanceBefore;
  final int balanceAfter;
  final String description;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  const RealLoyaltyTransaction({
    required this.id,
    this.accountId = 0,
    this.transactionType = '',
    this.points = 0,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.description = '',
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  LoyaltyTransactionType? get typeView =>
      loyaltyTransactionTypeFromCode(transactionType);

  bool get increasesBalance =>
      typeView?.knownIncrease ?? (balanceAfter > balanceBefore);

  factory RealLoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return RealLoyaltyTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      accountId: (json['accountId'] as num?)?.toInt() ?? 0,
      transactionType: (json['transactionType'] as String?) ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      balanceBefore: (json['balanceBefore'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toInt() ?? 0,
      description: (json['description'] as String?) ?? '',
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Typed page of loyalty transactions (`PageResponse<LoyaltyTransactionResponse>`).
class RealLoyaltyTransactionsPage {
  final List<RealLoyaltyTransaction> content;
  final int page;
  final int totalPages;

  const RealLoyaltyTransactionsPage({
    this.content = const [],
    this.page = 0,
    this.totalPages = 0,
  });

  factory RealLoyaltyTransactionsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    return RealLoyaltyTransactionsPage(
      content: raw is List
          ? raw
              .map((e) =>
                  RealLoyaltyTransaction.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Outcome of a real loyalty read (`GET /api/me/loyalty[/transactions]`). The
/// customer surface is read-only. [demoUnavailable] is the Demo Mode guard (zero
/// HTTP); [sessionExpired] (401) never triggers auto-logout; [forbidden] 403,
/// [notFound] 404, [serverError] 5xx, [network] transport/timeout.
enum LoyaltyOutcome {
  success,
  demoUnavailable,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

/// Maps a backend `TravelCreditTransactionType` wire string to the existing demo
/// [TravelCreditTransactionType] view enum (reusing its label + [increasesBalance]
/// direction logic). Returns null for any unrecognised code so the caller can
/// fall back to the balance delta.
TravelCreditTransactionType? travelCreditTransactionTypeFromCode(String? code) {
  switch (code) {
    case 'GRANT':
      return TravelCreditTransactionType.grant;
    case 'PROMOTION':
      return TravelCreditTransactionType.promotion;
    case 'REFUND_CREDIT':
      return TravelCreditTransactionType.refundCredit;
    case 'ADJUSTMENT':
      return TravelCreditTransactionType.adjustment;
    case 'REDEMPTION':
      return TravelCreditTransactionType.redemption;
    case 'EXPIRATION':
      return TravelCreditTransactionType.expiration;
    case 'REVERSAL':
      return TravelCreditTransactionType.reversal;
    default:
      return null;
  }
}

/// Real-backend mirror of `TravelCreditDto.TravelCreditAccountResponse`
/// (`GET /api/me/travel-credits`, created lazily on first access). Promotional
/// platform credit only — no withdrawal/transfer/cash-out. Money is a decimal
/// (backend `BigDecimal`) with a [currency]. `Map` decoding is confined to
/// [fromJson].
class RealTravelCreditAccount {
  final int id;
  final int userId;
  final double balance;
  final String currency;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealTravelCreditAccount({
    this.id = 0,
    this.userId = 0,
    this.balance = 0,
    this.currency = '',
    this.createdAt,
    this.updatedAt,
  });

  factory RealTravelCreditAccount.fromJson(Map<String, dynamic> json) {
    return RealTravelCreditAccount(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? '',
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Real-backend mirror of `TravelCreditDto.TravelCreditTransactionResponse`
/// (`GET /api/me/travel-credits/transactions`, an immutable ledger row). `amount`
/// is always positive; direction is derived from [transactionType] (falling back
/// to the balance delta). `Map` decoding is confined to [fromJson].
class RealTravelCreditTransaction {
  final int id;
  final int accountId;
  final String transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String description;
  final String? referenceType;
  final int? referenceId;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  const RealTravelCreditTransaction({
    required this.id,
    this.accountId = 0,
    this.transactionType = '',
    this.amount = 0,
    this.balanceBefore = 0,
    this.balanceAfter = 0,
    this.description = '',
    this.referenceType,
    this.referenceId,
    this.expiresAt,
    this.createdAt,
  });

  TravelCreditTransactionType? get typeView =>
      travelCreditTransactionTypeFromCode(transactionType);

  bool get increasesBalance =>
      typeView?.increasesBalance ?? (balanceAfter > balanceBefore);

  factory RealTravelCreditTransaction.fromJson(Map<String, dynamic> json) {
    return RealTravelCreditTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      accountId: (json['accountId'] as num?)?.toInt() ?? 0,
      transactionType: (json['transactionType'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      description: (json['description'] as String?) ?? '',
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
      expiresAt: _tryParseDate(json['expiresAt']),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Typed page of travel-credit transactions
/// (`PageResponse<TravelCreditTransactionResponse>`).
class RealTravelCreditTransactionsPage {
  final List<RealTravelCreditTransaction> content;
  final int page;
  final int totalPages;

  const RealTravelCreditTransactionsPage({
    this.content = const [],
    this.page = 0,
    this.totalPages = 0,
  });

  factory RealTravelCreditTransactionsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    return RealTravelCreditTransactionsPage(
      content: raw is List
          ? raw
              .map((e) => RealTravelCreditTransaction.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Outcome of a real travel-credit read (`GET /api/me/travel-credits[/transactions]`).
/// The customer surface is read-only. [demoUnavailable] is the Demo Mode guard
/// (zero HTTP); [sessionExpired] (401) never triggers auto-logout; [forbidden]
/// 403, [notFound] 404, [serverError] 5xx, [network] transport/timeout.
enum TravelCreditOutcome {
  success,
  demoUnavailable,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

/// Maps a backend `MembershipTier` wire string to the existing demo
/// [MembershipTier] enum (reusing its label). Null for any unrecognised code.
MembershipTier? membershipTierFromCode(String? code) {
  switch (code) {
    case 'BRONZE':
      return MembershipTier.bronze;
    case 'SILVER':
      return MembershipTier.silver;
    case 'GOLD':
      return MembershipTier.gold;
    case 'PLATINUM':
      return MembershipTier.platinum;
    case 'DIAMOND':
      return MembershipTier.diamond;
    default:
      return null;
  }
}

/// Maps a backend `MembershipBenefitType` wire string to the existing demo
/// [MembershipBenefitType] enum (reusing its label). Null for any unrecognised
/// code.
MembershipBenefitType? membershipBenefitTypeFromCode(String? code) {
  switch (code) {
    case 'POINTS_MULTIPLIER':
      return MembershipBenefitType.pointsMultiplier;
    case 'MEMBER_ONLY_COUPONS':
      return MembershipBenefitType.memberOnlyCoupons;
    case 'PRIORITY_SUPPORT':
      return MembershipBenefitType.prioritySupport;
    case 'EARLY_ACCESS':
      return MembershipBenefitType.earlyAccess;
    case 'LATE_CHECKOUT':
      return MembershipBenefitType.lateCheckout;
    case 'EARLY_CHECKIN':
      return MembershipBenefitType.earlyCheckin;
    case 'ROOM_UPGRADE':
      return MembershipBenefitType.roomUpgrade;
    case 'FREE_BREAKFAST':
      return MembershipBenefitType.freeBreakfast;
    case 'AIRPORT_TRANSFER':
      return MembershipBenefitType.airportTransfer;
    case 'CUSTOM':
      return MembershipBenefitType.custom;
    default:
      return null;
  }
}

/// Real-backend mirror of `MembershipDto.CustomerMembershipResponse`
/// (`GET`/`POST /api/me/membership`). `currentTier` is stored;
/// `effectiveTier` accounts for expiry. Tiers are kept raw with view getters.
/// `Map` decoding is confined to [fromJson].
class RealMembership {
  final int id;
  final int userId;
  final String currentTier;
  final String effectiveTier;
  final DateTime? qualifiedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool manuallyAssigned;
  final bool active;
  final bool expired;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealMembership({
    this.id = 0,
    this.userId = 0,
    this.currentTier = '',
    this.effectiveTier = '',
    this.qualifiedAt,
    this.validFrom,
    this.validUntil,
    this.manuallyAssigned = false,
    this.active = false,
    this.expired = false,
    this.createdAt,
    this.updatedAt,
  });

  MembershipTier? get currentTierView => membershipTierFromCode(currentTier);
  MembershipTier? get effectiveTierView =>
      membershipTierFromCode(effectiveTier);

  factory RealMembership.fromJson(Map<String, dynamic> json) {
    return RealMembership(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      currentTier: (json['currentTier'] as String?) ?? '',
      effectiveTier: (json['effectiveTier'] as String?) ?? '',
      qualifiedAt: _tryParseDate(json['qualifiedAt']),
      validFrom: _tryParseDate(json['validFrom']),
      validUntil: _tryParseDate(json['validUntil']),
      manuallyAssigned: (json['manuallyAssigned'] as bool?) ?? false,
      active: (json['active'] as bool?) ?? false,
      expired: (json['expired'] as bool?) ?? false,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Real-backend mirror of `MembershipDto.MembershipProgressResponse`
/// (`GET /api/me/membership/progress`, a live preview that works even before
/// enrolling). `progressPercentage` is bounded [0,100] by the backend.
class RealMembershipProgress {
  final String currentTier;
  final String effectiveTier;
  final int lifetimePointsEarned;
  final int completedBookings;
  final String? nextTier;
  final int? pointsRequiredForNextTier;
  final int? bookingsRequiredForNextTier;
  final double progressPercentage;
  final DateTime? validUntil;
  final bool expired;
  final bool manuallyAssigned;

  const RealMembershipProgress({
    this.currentTier = '',
    this.effectiveTier = '',
    this.lifetimePointsEarned = 0,
    this.completedBookings = 0,
    this.nextTier,
    this.pointsRequiredForNextTier,
    this.bookingsRequiredForNextTier,
    this.progressPercentage = 0,
    this.validUntil,
    this.expired = false,
    this.manuallyAssigned = false,
  });

  MembershipTier? get effectiveTierView =>
      membershipTierFromCode(effectiveTier);
  MembershipTier? get nextTierView => membershipTierFromCode(nextTier);
  int get clampedProgress => progressPercentage.round().clamp(0, 100);
  bool get isHighestTier => nextTier == null;

  factory RealMembershipProgress.fromJson(Map<String, dynamic> json) {
    return RealMembershipProgress(
      currentTier: (json['currentTier'] as String?) ?? '',
      effectiveTier: (json['effectiveTier'] as String?) ?? '',
      lifetimePointsEarned:
          (json['lifetimePointsEarned'] as num?)?.toInt() ?? 0,
      completedBookings: (json['completedBookings'] as num?)?.toInt() ?? 0,
      nextTier: json['nextTier'] as String?,
      pointsRequiredForNextTier:
          (json['pointsRequiredForNextTier'] as num?)?.toInt(),
      bookingsRequiredForNextTier:
          (json['bookingsRequiredForNextTier'] as num?)?.toInt(),
      progressPercentage: (json['progressPercentage'] as num?)?.toDouble() ?? 0,
      validUntil: _tryParseDate(json['validUntil']),
      expired: (json['expired'] as bool?) ?? false,
      manuallyAssigned: (json['manuallyAssigned'] as bool?) ?? false,
    );
  }
}

/// Real-backend mirror of `MembershipDto.MembershipBenefitResponse`
/// (`GET /api/me/membership/benefits`, metadata for the effective tier).
class RealMembershipBenefit {
  final int id;
  final String tier;
  final String benefitType;
  final String name;
  final String description;
  final double? numericValue;
  final String? textValue;
  final bool active;
  final int sortOrder;

  const RealMembershipBenefit({
    this.id = 0,
    this.tier = '',
    this.benefitType = '',
    this.name = '',
    this.description = '',
    this.numericValue,
    this.textValue,
    this.active = false,
    this.sortOrder = 0,
  });

  MembershipTier? get tierView => membershipTierFromCode(tier);
  MembershipBenefitType? get benefitTypeView =>
      membershipBenefitTypeFromCode(benefitType);

  factory RealMembershipBenefit.fromJson(Map<String, dynamic> json) {
    return RealMembershipBenefit(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tier: (json['tier'] as String?) ?? '',
      benefitType: (json['benefitType'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      numericValue: (json['numericValue'] as num?)?.toDouble(),
      textValue: json['textValue'] as String?,
      active: (json['active'] as bool?) ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Real-backend mirror of `MembershipDto.MembershipTierHistoryResponse`
/// (`GET /api/me/membership/history`, newest first, immutable).
class RealMembershipHistoryItem {
  final int id;
  final int membershipId;
  final String? previousTier;
  final String newTier;
  final String changeType;
  final String reason;
  final DateTime? effectiveAt;
  final DateTime? expiresAt;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  const RealMembershipHistoryItem({
    required this.id,
    this.membershipId = 0,
    this.previousTier,
    this.newTier = '',
    this.changeType = '',
    this.reason = '',
    this.effectiveAt,
    this.expiresAt,
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  MembershipTier? get newTierView => membershipTierFromCode(newTier);

  factory RealMembershipHistoryItem.fromJson(Map<String, dynamic> json) {
    return RealMembershipHistoryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      membershipId: (json['membershipId'] as num?)?.toInt() ?? 0,
      previousTier: json['previousTier'] as String?,
      newTier: (json['newTier'] as String?) ?? '',
      changeType: (json['changeType'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
      effectiveAt: _tryParseDate(json['effectiveAt']),
      expiresAt: _tryParseDate(json['expiresAt']),
      referenceType: json['referenceType'] as String?,
      referenceId: (json['referenceId'] as num?)?.toInt(),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Outcome of a real membership action (`GET /api/me/membership[/progress|
/// /benefits|/history]`, `POST /enroll`). [demoUnavailable] is the Demo Mode
/// guard (zero HTTP); [busy] the single-flight guard; [sessionExpired] (401)
/// never triggers auto-logout; [validation] 400 (e.g. enroll needs an active
/// loyalty account); [forbidden] 403, [notFound] 404, [serverError] 5xx,
/// [network] transport/timeout.
enum MembershipOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  validation,
  forbidden,
  notFound,
  network,
  serverError,
}

/// Maps a backend referral `role` wire string ("INVITER"/"INVITEE") to the
/// existing demo [ReferralRole] enum (reusing its label). Null when unrecognised.
ReferralRole? referralRoleFromCode(String? code) {
  switch (code) {
    case 'INVITER':
      return ReferralRole.inviter;
    case 'INVITEE':
      return ReferralRole.invitee;
    default:
      return null;
  }
}

/// Maps a backend `ReferralRewardStatus` wire string ("USED"/"REWARDED") to the
/// existing demo [ReferralStatus] enum (reusing its label). Null when
/// unrecognised.
ReferralStatus? referralStatusFromCode(String? code) {
  switch (code) {
    case 'USED':
      return ReferralStatus.used;
    case 'REWARDED':
      return ReferralStatus.rewarded;
    default:
      return null;
  }
}

/// Real-backend mirror of `ReferralDto.MyReferralResponse`
/// (`GET /api/me/referral`, code created lazily). `Map` decoding is confined to
/// [fromJson].
class RealReferralSummary {
  final String code;
  final int successfulReferrals;
  final int pendingReferrals;
  final DateTime? createdAt;

  const RealReferralSummary({
    this.code = '',
    this.successfulReferrals = 0,
    this.pendingReferrals = 0,
    this.createdAt,
  });

  factory RealReferralSummary.fromJson(Map<String, dynamic> json) {
    return RealReferralSummary(
      code: (json['code'] as String?) ?? '',
      successfulReferrals: (json['successfulReferrals'] as num?)?.toInt() ?? 0,
      pendingReferrals: (json['pendingReferrals'] as num?)?.toInt() ?? 0,
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Real-backend mirror of `ReferralDto.ReferralRewardResponse`
/// (`GET /api/me/referral/history`, `POST /api/me/referral/use`). [role] is
/// "INVITER"/"INVITEE" relative to the requesting user; [status] is USED/REWARDED.
/// The customer DTO carries NO reward amount — only status/role/timestamps.
/// `Map` decoding is confined to [fromJson].
class RealReferralReward {
  final int id;
  final String role;
  final String campaignCode;
  final int? inviterUserId;
  final int? inviteeUserId;
  final String status;
  final DateTime? usedAt;
  final DateTime? qualifiedAt;
  final int? qualifyingBookingId;
  final DateTime? rewardedAt;
  final DateTime? createdAt;

  const RealReferralReward({
    required this.id,
    this.role = '',
    this.campaignCode = '',
    this.inviterUserId,
    this.inviteeUserId,
    this.status = '',
    this.usedAt,
    this.qualifiedAt,
    this.qualifyingBookingId,
    this.rewardedAt,
    this.createdAt,
  });

  ReferralRole? get roleView => referralRoleFromCode(role);
  ReferralStatus? get statusView => referralStatusFromCode(status);

  factory RealReferralReward.fromJson(Map<String, dynamic> json) {
    return RealReferralReward(
      id: (json['id'] as num?)?.toInt() ?? 0,
      role: (json['role'] as String?) ?? '',
      campaignCode: (json['campaignCode'] as String?) ?? '',
      inviterUserId: (json['inviterUserId'] as num?)?.toInt(),
      inviteeUserId: (json['inviteeUserId'] as num?)?.toInt(),
      status: (json['status'] as String?) ?? '',
      usedAt: _tryParseDate(json['usedAt']),
      qualifiedAt: _tryParseDate(json['qualifiedAt']),
      qualifyingBookingId: (json['qualifyingBookingId'] as num?)?.toInt(),
      rewardedAt: _tryParseDate(json['rewardedAt']),
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Outcome of a real referral action (`GET /api/me/referral[/history]`,
/// `POST /use`). [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy] the
/// single-flight guard; [sessionExpired] (401) never triggers auto-logout;
/// [validation] 400 (e.g. using your own code); [forbidden] 403, [notFound] 404
/// (code not found), [conflict] 409 (already used a code), [serverError] 5xx,
/// [network] transport/timeout.
enum ReferralOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  validation,
  forbidden,
  notFound,
  conflict,
  network,
  serverError,
}

/// Maps a backend `DiscountType` wire string to the existing demo
/// [CouponDiscountType] enum. Null when unrecognised.
CouponDiscountType? couponDiscountTypeFromCode(String? code) {
  switch (code) {
    case 'PERCENTAGE':
      return CouponDiscountType.percentage;
    case 'FIXED_AMOUNT':
      return CouponDiscountType.fixedAmount;
    default:
      return null;
  }
}

/// Maps a backend `CouponTargetType` wire string to the existing demo
/// [CouponTargetType] enum (reusing its label). Null when unrecognised.
CouponTargetType? couponTargetTypeFromCode(String? code) {
  switch (code) {
    case 'ALL':
      return CouponTargetType.all;
    case 'HOTEL':
      return CouponTargetType.hotel;
    case 'ROOM':
      return CouponTargetType.room;
    case 'PLACE_TYPE':
      return CouponTargetType.placeType;
    default:
      return null;
  }
}

/// View classification of a backend `CustomerCouponStatus` string (AVAILABLE,
/// USED, EXPIRED, REVOKED). [unknown] preserves forward-compatibility.
enum CouponStatusView { available, used, expired, revoked, unknown }

CouponStatusView couponStatusViewFromCode(String? code) {
  switch (code) {
    case 'AVAILABLE':
      return CouponStatusView.available;
    case 'USED':
      return CouponStatusView.used;
    case 'EXPIRED':
      return CouponStatusView.expired;
    case 'REVOKED':
      return CouponStatusView.revoked;
    default:
      return CouponStatusView.unknown;
  }
}

/// Real-backend mirror of `CouponDto.CouponDefinitionResponse` (the nested coupon
/// metadata inside a claimed customer coupon). The coupon definition has no
/// currency field — fixed amounts are shown as plain decimals. `Map` decoding is
/// confined to [fromJson].
class RealCouponDefinition {
  final int id;
  final String code;
  final String name;
  final String description;
  final String discountType;
  final double discountValue;
  final double? maxDiscountAmount;
  final double? minimumSpend;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final bool active;
  final int? totalUsageLimit;
  final int usageLimitPerUser;
  final int currentUsageCount;
  final String targetType;
  final int? minimumStayNights;
  final bool firstBookingOnly;
  final bool combinableWithPromotions;
  final bool combinableWithTravelCredits;
  final String? minimumTier;

  const RealCouponDefinition({
    this.id = 0,
    this.code = '',
    this.name = '',
    this.description = '',
    this.discountType = '',
    this.discountValue = 0,
    this.maxDiscountAmount,
    this.minimumSpend,
    this.validFrom,
    this.validUntil,
    this.active = false,
    this.totalUsageLimit,
    this.usageLimitPerUser = 0,
    this.currentUsageCount = 0,
    this.targetType = '',
    this.minimumStayNights,
    this.firstBookingOnly = false,
    this.combinableWithPromotions = false,
    this.combinableWithTravelCredits = false,
    this.minimumTier,
  });

  CouponDiscountType? get discountTypeView =>
      couponDiscountTypeFromCode(discountType);
  CouponTargetType? get targetTypeView => couponTargetTypeFromCode(targetType);

  factory RealCouponDefinition.fromJson(Map<String, dynamic> json) {
    return RealCouponDefinition(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      discountType: (json['discountType'] as String?) ?? '',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      minimumSpend: (json['minimumSpend'] as num?)?.toDouble(),
      validFrom: _tryParseDate(json['validFrom']),
      validUntil: _tryParseDate(json['validUntil']),
      active: (json['active'] as bool?) ?? false,
      totalUsageLimit: (json['totalUsageLimit'] as num?)?.toInt(),
      usageLimitPerUser: (json['usageLimitPerUser'] as num?)?.toInt() ?? 0,
      currentUsageCount: (json['currentUsageCount'] as num?)?.toInt() ?? 0,
      targetType: (json['targetType'] as String?) ?? '',
      minimumStayNights: (json['minimumStayNights'] as num?)?.toInt(),
      firstBookingOnly: (json['firstBookingOnly'] as bool?) ?? false,
      combinableWithPromotions:
          (json['combinableWithPromotions'] as bool?) ?? false,
      combinableWithTravelCredits:
          (json['combinableWithTravelCredits'] as bool?) ?? false,
      minimumTier: json['minimumTier'] as String?,
    );
  }
}

/// Real-backend mirror of `CouponDto.CustomerCouponResponse`
/// (`GET`/`POST /api/me/coupons`). Wraps the nested [coupon] definition with the
/// claimed instance's status/expiry. `Map` decoding is confined to [fromJson].
class RealCoupon {
  final int id;
  final int userId;
  final RealCouponDefinition coupon;
  final String status;
  final String effectiveStatus;
  final DateTime? claimedAt;
  final DateTime? usedAt;
  final DateTime? expiresAt;
  final DateTime? effectiveExpiresAt;
  final int? bookingId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealCoupon({
    required this.id,
    this.userId = 0,
    this.coupon = const RealCouponDefinition(),
    this.status = '',
    this.effectiveStatus = '',
    this.claimedAt,
    this.usedAt,
    this.expiresAt,
    this.effectiveExpiresAt,
    this.bookingId,
    this.createdAt,
    this.updatedAt,
  });

  CouponStatusView get statusView => couponStatusViewFromCode(effectiveStatus);

  factory RealCoupon.fromJson(Map<String, dynamic> json) {
    final def = json['coupon'];
    return RealCoupon(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      coupon: def is Map<String, dynamic>
          ? RealCouponDefinition.fromJson(def)
          : const RealCouponDefinition(),
      status: (json['status'] as String?) ?? '',
      effectiveStatus: (json['effectiveStatus'] as String?) ?? '',
      claimedAt: _tryParseDate(json['claimedAt']),
      usedAt: _tryParseDate(json['usedAt']),
      expiresAt: _tryParseDate(json['expiresAt']),
      effectiveExpiresAt: _tryParseDate(json['effectiveExpiresAt']),
      bookingId: (json['bookingId'] as num?)?.toInt(),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Outcome of a real coupon action (`GET /api/me/coupons[/{id}]`,
/// `POST /claim`). [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy]
/// the single-flight guard; [sessionExpired] (401) never triggers auto-logout;
/// [validation] 400 (inactive/expired/not-yet-valid code), [forbidden] 403,
/// [notFound] 404 (unknown code), [conflict] 409 (usage limit reached),
/// [serverError] 5xx, [network] transport/timeout.
enum CouponOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  validation,
  forbidden,
  notFound,
  conflict,
  network,
  serverError,
}

// ── Recommendations (/api/me/recommendations, UI-39) ─────────────────────────
// Real-backend mirror of the Phase 7.23 personalized recommendation feed
// (`CustomerRecommendationResponse` / `PageResponse`). Read + engagement only;
// the backend never claims/reserves anything. `Map` decoding is confined to
// [fromJson]. Nested targets are captured selectively (place/hotel id+name for
// navigation/label); [targetSummary] covers room/promotion/coupon labels.

/// The kind of resource a recommendation points at (`RecommendationType`). One
/// matching target is populated per type. [unknown] preserves forward-compat for
/// any code this client does not recognise.
enum RecommendationTypeView {
  place,
  hotel,
  room,
  promotion,
  coupon,
  tripIdea,
  unknown
}

/// Maps a backend `RecommendationType` wire string to [RecommendationTypeView];
/// unrecognised codes map to [RecommendationTypeView.unknown].
RecommendationTypeView recommendationTypeViewFromCode(String? code) {
  switch (code) {
    case 'PLACE':
      return RecommendationTypeView.place;
    case 'HOTEL':
      return RecommendationTypeView.hotel;
    case 'ROOM':
      return RecommendationTypeView.room;
    case 'PROMOTION':
      return RecommendationTypeView.promotion;
    case 'COUPON':
      return RecommendationTypeView.coupon;
    case 'TRIP_IDEA':
      return RecommendationTypeView.tripIdea;
    default:
      return RecommendationTypeView.unknown;
  }
}

/// Server-computed engagement state of a recommendation snapshot
/// (`engagementState`: ACTIVE / CLICKED / CONVERTED / DISMISSED / EXPIRED).
enum RecommendationEngagementView {
  active,
  clicked,
  converted,
  dismissed,
  expired,
  unknown,
}

/// Maps a backend `engagementState` wire string to [RecommendationEngagementView];
/// unrecognised codes map to [RecommendationEngagementView.unknown].
RecommendationEngagementView recommendationEngagementViewFromCode(
    String? code) {
  switch (code) {
    case 'ACTIVE':
      return RecommendationEngagementView.active;
    case 'CLICKED':
      return RecommendationEngagementView.clicked;
    case 'CONVERTED':
      return RecommendationEngagementView.converted;
    case 'DISMISSED':
      return RecommendationEngagementView.dismissed;
    case 'EXPIRED':
      return RecommendationEngagementView.expired;
    default:
      return RecommendationEngagementView.unknown;
  }
}

/// Real-backend mirror of `CustomerRecommendationResponse` (Phase 7.23). Top-level
/// snapshot fields plus a selectively-parsed target: [placeId]/[placeName]/
/// [placeSlug] and [hotelId]/[hotelName]/[hotelSlug] when present, with
/// [targetSummary] as the human label for any type (incl. room/promotion/coupon).
/// [reasonText] is backend-authored display copy (no client-side scoring).
class RealRecommendation {
  final int id;
  final String type; // raw RecommendationType wire code
  final int score; // 0–100, backend-computed
  final String? reasonCode;
  final String? reasonText;
  final DateTime? generatedAt;
  final DateTime? expiresAt;
  final String engagementState; // raw wire code
  final DateTime? dismissedAt;
  final DateTime? clickedAt;
  final DateTime? convertedAt;
  final int? sourceRuleId;
  final String? sourceRuleCode;
  final String? targetSummary;
  final int? placeId;
  final String? placeName;
  final String? placeSlug;
  final int? hotelId;
  final String? hotelName;
  final String? hotelSlug;
  final String? metadataJson;

  const RealRecommendation({
    required this.id,
    this.type = '',
    this.score = 0,
    this.reasonCode,
    this.reasonText,
    this.generatedAt,
    this.expiresAt,
    this.engagementState = '',
    this.dismissedAt,
    this.clickedAt,
    this.convertedAt,
    this.sourceRuleId,
    this.sourceRuleCode,
    this.targetSummary,
    this.placeId,
    this.placeName,
    this.placeSlug,
    this.hotelId,
    this.hotelName,
    this.hotelSlug,
    this.metadataJson,
  });

  RecommendationTypeView get typeView => recommendationTypeViewFromCode(type);

  RecommendationEngagementView get engagementView =>
      recommendationEngagementViewFromCode(engagementState);

  factory RealRecommendation.fromJson(Map<String, dynamic> json) {
    final place = json['place'];
    final hotel = json['hotel'];
    return RealRecommendation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: (json['type'] as String?) ?? '',
      score: (json['score'] as num?)?.toInt() ?? 0,
      reasonCode: json['reasonCode'] as String?,
      reasonText: json['reasonText'] as String?,
      generatedAt: _tryParseDate(json['generatedAt']),
      expiresAt: _tryParseDate(json['expiresAt']),
      engagementState: (json['engagementState'] as String?) ?? '',
      dismissedAt: _tryParseDate(json['dismissedAt']),
      clickedAt: _tryParseDate(json['clickedAt']),
      convertedAt: _tryParseDate(json['convertedAt']),
      sourceRuleId: (json['sourceRuleId'] as num?)?.toInt(),
      sourceRuleCode: json['sourceRuleCode'] as String?,
      targetSummary: json['targetSummary'] as String?,
      placeId:
          place is Map<String, dynamic> ? (place['id'] as num?)?.toInt() : null,
      placeName:
          place is Map<String, dynamic> ? place['name'] as String? : null,
      placeSlug:
          place is Map<String, dynamic> ? place['slug'] as String? : null,
      hotelId:
          hotel is Map<String, dynamic> ? (hotel['id'] as num?)?.toInt() : null,
      hotelName:
          hotel is Map<String, dynamic> ? hotel['name'] as String? : null,
      hotelSlug:
          hotel is Map<String, dynamic> ? hotel['slug'] as String? : null,
      metadataJson: json['metadataJson'] as String?,
    );
  }
}

/// Typed page of recommendations (`PageResponse<CustomerRecommendationResponse>`).
class RealRecommendationPage {
  final List<RealRecommendation> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  const RealRecommendationPage({
    this.content = const [],
    this.page = 0,
    this.size = 0,
    this.totalElements = 0,
    this.totalPages = 0,
  });

  factory RealRecommendationPage.fromJson(Map<String, dynamic> json) {
    final raw = json['content'];
    return RealRecommendationPage(
      content: raw is List
          ? raw
              .map(
                  (e) => RealRecommendation.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      page: (json['page'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 0,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Outcome of a real recommendation action (`GET /api/me/recommendations[/{id}]`,
/// the `POST /generate` regenerate, and the `PATCH /{id}/dismiss|click` engagement
/// updates). [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy] the
/// single-flight guard; [sessionExpired] (401) never triggers auto-logout;
/// [forbidden] 403, [notFound] 404, [serverError] 5xx, [network] transport/timeout.
enum RecommendationOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

// ── Trip expenses (/api/me/trips/{tripId}/expenses, UI-40) ───────────────────
// Real-backend mirror of the Phase 7 Trip Budget & Expenses surface
// (`TripBudgetController` / `TripPlanBudgetService`). Expenses hang off a real
// TripPlan (UI-20); full CRUD is owner-or-EDITOR, reads are owner-or-collaborator.
// `Map` decoding is confined to [fromJson]; request building to [toJson].

/// The expense category (`TripPlanExpenseCategory`). [unknown] preserves
/// forward-compat for any code this client does not recognise; it is never sent.
enum RealExpenseCategory {
  accommodation,
  food,
  transport,
  attraction,
  shopping,
  health,
  visa,
  insurance,
  other,
  unknown,
}

/// The wire codes the backend accepts (`TripPlanExpenseCategory`). [unknown]
/// falls back to `OTHER` so a create/edit never sends an invalid enum.
const Map<RealExpenseCategory, String> _realExpenseCategoryWire = {
  RealExpenseCategory.accommodation: 'ACCOMMODATION',
  RealExpenseCategory.food: 'FOOD',
  RealExpenseCategory.transport: 'TRANSPORT',
  RealExpenseCategory.attraction: 'ATTRACTION',
  RealExpenseCategory.shopping: 'SHOPPING',
  RealExpenseCategory.health: 'HEALTH',
  RealExpenseCategory.visa: 'VISA',
  RealExpenseCategory.insurance: 'INSURANCE',
  RealExpenseCategory.other: 'OTHER',
  RealExpenseCategory.unknown: 'OTHER',
};

/// The 9 categories a customer may pick from (excludes [RealExpenseCategory.unknown]).
const List<RealExpenseCategory> realExpenseCategoryChoices = [
  RealExpenseCategory.accommodation,
  RealExpenseCategory.food,
  RealExpenseCategory.transport,
  RealExpenseCategory.attraction,
  RealExpenseCategory.shopping,
  RealExpenseCategory.health,
  RealExpenseCategory.visa,
  RealExpenseCategory.insurance,
  RealExpenseCategory.other,
];

String realExpenseCategoryWire(RealExpenseCategory c) =>
    _realExpenseCategoryWire[c] ?? 'OTHER';

/// Maps a backend `TripPlanExpenseCategory` wire string to [RealExpenseCategory];
/// unrecognised codes map to [RealExpenseCategory.unknown].
RealExpenseCategory realExpenseCategoryFromCode(String? code) {
  switch (code) {
    case 'ACCOMMODATION':
      return RealExpenseCategory.accommodation;
    case 'FOOD':
      return RealExpenseCategory.food;
    case 'TRANSPORT':
      return RealExpenseCategory.transport;
    case 'ATTRACTION':
      return RealExpenseCategory.attraction;
    case 'SHOPPING':
      return RealExpenseCategory.shopping;
    case 'HEALTH':
      return RealExpenseCategory.health;
    case 'VISA':
      return RealExpenseCategory.visa;
    case 'INSURANCE':
      return RealExpenseCategory.insurance;
    case 'OTHER':
      return RealExpenseCategory.other;
    default:
      return RealExpenseCategory.unknown;
  }
}

/// Real-backend mirror of `TripPlanExpenseResponse`. `amount` is a JSON number
/// (BigDecimal server-side) surfaced as [double] for display only — the backend
/// owns all budget math. `tripDayId`/`tripItemId` are optional links.
class RealExpense {
  final int id;
  final int tripPlanId;
  final int? tripDayId;
  final int? tripItemId;
  final int? paidByUserId;
  final String? paidByUserName;
  final String category; // raw wire code
  final double amount;
  final String currency;
  final String title;
  final String? notes;
  final DateTime? expenseDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealExpense({
    required this.id,
    this.tripPlanId = 0,
    this.tripDayId,
    this.tripItemId,
    this.paidByUserId,
    this.paidByUserName,
    this.category = '',
    this.amount = 0,
    this.currency = 'VND',
    this.title = '',
    this.notes,
    this.expenseDate,
    this.createdAt,
    this.updatedAt,
  });

  RealExpenseCategory get categoryView => realExpenseCategoryFromCode(category);

  factory RealExpense.fromJson(Map<String, dynamic> json) {
    return RealExpense(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tripPlanId: (json['tripPlanId'] as num?)?.toInt() ?? 0,
      tripDayId: (json['tripDayId'] as num?)?.toInt(),
      tripItemId: (json['tripItemId'] as num?)?.toInt(),
      paidByUserId: (json['paidByUserId'] as num?)?.toInt(),
      paidByUserName: json['paidByUserName'] as String?,
      category: (json['category'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'VND',
      title: (json['title'] as String?) ?? '',
      notes: json['notes'] as String?,
      expenseDate: _tryParseDate(json['expenseDate']),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Real-backend mirror of `ExpenseCategoryBreakdown`.
class RealExpenseCategoryBreakdown {
  final String category; // raw wire code
  final double totalAmount;

  const RealExpenseCategoryBreakdown({
    this.category = '',
    this.totalAmount = 0,
  });

  RealExpenseCategory get categoryView => realExpenseCategoryFromCode(category);

  factory RealExpenseCategoryBreakdown.fromJson(Map<String, dynamic> json) {
    return RealExpenseCategoryBreakdown(
      category: (json['category'] as String?) ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Real-backend mirror of `TripPlanBudgetSummaryResponse` (server-computed budget
/// vs. actual). [hasBudget] distinguishes "no budget set" (totalBudget 0) from a
/// real budget, so the UI never frames a budget-less trip as "over budget".
class RealExpenseSummary {
  final int tripPlanId;
  final double totalBudget;
  final double totalSpent;
  final double remainingBudget;
  final bool overBudget;
  final List<RealExpenseCategoryBreakdown> categoryBreakdown;

  const RealExpenseSummary({
    this.tripPlanId = 0,
    this.totalBudget = 0,
    this.totalSpent = 0,
    this.remainingBudget = 0,
    this.overBudget = false,
    this.categoryBreakdown = const [],
  });

  bool get hasBudget => totalBudget > 0;

  factory RealExpenseSummary.fromJson(Map<String, dynamic> json) {
    final raw = json['categoryBreakdown'];
    return RealExpenseSummary(
      tripPlanId: (json['tripPlanId'] as num?)?.toInt() ?? 0,
      totalBudget: (json['totalBudget'] as num?)?.toDouble() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble() ?? 0,
      overBudget: (json['overBudget'] as bool?) ?? false,
      categoryBreakdown: raw is List
          ? raw
              .map((e) => RealExpenseCategoryBreakdown.fromJson(
                  e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

/// Request payload for creating/updating an expense (`TripPlanExpenseRequest`).
/// [toJson] emits every backend field each time (create and update share the
/// same shape); optional day/item links are sent as null when absent.
class RealExpensePayload {
  final RealExpenseCategory category;
  final double amount;
  final String currency;
  final String title;
  final String? notes;
  final DateTime expenseDate;
  final int? tripDayId;
  final int? tripItemId;

  const RealExpensePayload({
    required this.category,
    required this.amount,
    required this.currency,
    required this.title,
    required this.expenseDate,
    this.notes,
    this.tripDayId,
    this.tripItemId,
  });

  Map<String, dynamic> toJson() {
    final d = expenseDate;
    final iso =
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return {
      'tripDayId': tripDayId,
      'tripItemId': tripItemId,
      'category': realExpenseCategoryWire(category),
      'amount': amount,
      'currency': currency,
      'title': title,
      'notes': notes,
      'expenseDate': iso,
    };
  }
}

/// Outcome of a real expense action (list/create/update/delete + budget summary).
/// [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy] the single-flight
/// guard; [sessionExpired] (401) never triggers auto-logout; [forbidden] 403 (a
/// VIEWER collaborator can't mutate); [notFound] 404 (trip/expense gone or not
/// yours); [validation] 400 (amount/currency/title/date); [serverError] 5xx;
/// [network] transport/timeout.
enum ExpenseOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  validation,
  network,
  serverError,
}

// ── Conversations (/api/me/conversations, UI-41) ─────────────────────────────
// Real-backend mirror of the guest↔partner messaging surface
// (`UserConversationController` / `ConversationService`). Request/response only —
// there is NO websocket/realtime, typing, or attachments; the client refreshes
// on demand. `Map` decoding is confined to [fromJson].

/// Conversation lifecycle (`ConversationStatus`). Users can OPEN (implicitly, by
/// sending) and CLOSE; ARCHIVED is admin-only. [unknown] is forward-compat.
enum ConversationStatusView { open, closed, archived, unknown }

ConversationStatusView conversationStatusViewFromCode(String? code) {
  switch (code) {
    case 'OPEN':
      return ConversationStatusView.open;
    case 'CLOSED':
      return ConversationStatusView.closed;
    case 'ARCHIVED':
      return ConversationStatusView.archived;
    default:
      return ConversationStatusView.unknown;
  }
}

/// Who authored a message (`MessageSenderRole`). The signed-in guest is [user];
/// the host is [partner]; [admin]/[system] are support/automated. [unknown] is
/// forward-compat.
enum MessageSenderRoleView { user, partner, admin, system, unknown }

MessageSenderRoleView messageSenderRoleViewFromCode(String? code) {
  switch (code) {
    case 'USER':
      return MessageSenderRoleView.user;
    case 'PARTNER':
      return MessageSenderRoleView.partner;
    case 'ADMIN':
      return MessageSenderRoleView.admin;
    case 'SYSTEM':
      return MessageSenderRoleView.system;
    default:
      return MessageSenderRoleView.unknown;
  }
}

/// Real-backend mirror of `MessageResponse`. [readByPartner] on a user-authored
/// message is the honest "seen by host" receipt the backend exposes.
class RealMessage {
  final int id;
  final int conversationId;
  final int? senderUserId;
  final String? senderName;
  final String senderRole; // raw wire code
  final String body;
  final bool readByUser;
  final bool readByPartner;
  final DateTime? createdAt;

  const RealMessage({
    required this.id,
    this.conversationId = 0,
    this.senderUserId,
    this.senderName,
    this.senderRole = '',
    this.body = '',
    this.readByUser = false,
    this.readByPartner = false,
    this.createdAt,
  });

  MessageSenderRoleView get senderRoleView =>
      messageSenderRoleViewFromCode(senderRole);

  bool get isFromUser => senderRoleView == MessageSenderRoleView.user;

  factory RealMessage.fromJson(Map<String, dynamic> json) {
    return RealMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      conversationId: (json['conversationId'] as num?)?.toInt() ?? 0,
      senderUserId: (json['senderUserId'] as num?)?.toInt(),
      senderName: json['senderName'] as String?,
      senderRole: (json['senderRole'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      readByUser: (json['readByUser'] as bool?) ?? false,
      readByPartner: (json['readByPartner'] as bool?) ?? false,
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Real-backend mirror of `ConversationResponse` (a thread + its messages,
/// ordered oldest-first by the backend).
class RealConversation {
  final int id;
  final int? bookingId;
  final String? bookingCode;
  final int? userId;
  final String? userName;
  final int? partnerProfileId;
  final String? partnerBusinessName;
  final String status; // raw wire code
  final String? subject;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<RealMessage> messages;

  const RealConversation({
    required this.id,
    this.bookingId,
    this.bookingCode,
    this.userId,
    this.userName,
    this.partnerProfileId,
    this.partnerBusinessName,
    this.status = '',
    this.subject,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  ConversationStatusView get statusView =>
      conversationStatusViewFromCode(status);

  factory RealConversation.fromJson(Map<String, dynamic> json) {
    final raw = json['messages'];
    return RealConversation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingId: (json['bookingId'] as num?)?.toInt(),
      bookingCode: json['bookingCode'] as String?,
      userId: (json['userId'] as num?)?.toInt(),
      userName: json['userName'] as String?,
      partnerProfileId: (json['partnerProfileId'] as num?)?.toInt(),
      partnerBusinessName: json['partnerBusinessName'] as String?,
      status: (json['status'] as String?) ?? '',
      subject: json['subject'] as String?,
      lastMessageAt: _tryParseDate(json['lastMessageAt']),
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
      messages: raw is List
          ? raw
              .map((e) => RealMessage.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

/// Real-backend mirror of `ConversationSummaryResponse` (inbox row).
class RealConversationSummary {
  final int id;
  final int? bookingId;
  final String? bookingCode;
  final String? subject;
  final String status; // raw wire code
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final DateTime? createdAt;

  const RealConversationSummary({
    required this.id,
    this.bookingId,
    this.bookingCode,
    this.subject,
    this.status = '',
    this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.createdAt,
  });

  ConversationStatusView get statusView =>
      conversationStatusViewFromCode(status);

  factory RealConversationSummary.fromJson(Map<String, dynamic> json) {
    return RealConversationSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingId: (json['bookingId'] as num?)?.toInt(),
      bookingCode: json['bookingCode'] as String?,
      subject: json['subject'] as String?,
      status: (json['status'] as String?) ?? '',
      lastMessageAt: _tryParseDate(json['lastMessageAt']),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      createdAt: _tryParseDate(json['createdAt']),
    );
  }
}

/// Outcome of a real conversation action (list/detail/create/send/read/close).
/// [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy] the single-flight
/// guard; [sessionExpired] (401) never triggers auto-logout; [forbidden] 403 (not
/// your conversation/booking); [notFound] 404; [validation] 400 (blank body /
/// missing bookingId); [unprocessable] 422 (archived thread / hotel has no
/// partner); [serverError] 5xx; [network] transport/timeout.
enum ConversationOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  validation,
  unprocessable,
  network,
  serverError,
}

// ── AI Context (/api/me/ai/context, UI-42) ───────────────────────────────────
// Real-backend mirror of the Phase 7.50 AI Trip Context aggregate
// (`AIContextController` / `AITripContextService`). A single read-only snapshot,
// NOT persisted and NOT an AI generation — it is the data an AI capability would
// consume. The client surfaces the summary-level fields it displays (activity
// counts, current/upcoming trips, the budget summary, wishlist count, generated
// time); the large embedded profile/recommendation/booking lists are represented
// by their backend-provided counts rather than re-mapped. `Map` decoding is
// confined to [fromJson].

/// A light trip reference from the context (`TripSummaryResponse`), carrying only
/// the fields the snapshot screen displays.
class RealAiTripRef {
  final int id;
  final String title;
  final String? destination;
  final String status; // raw wire code
  final DateTime? startDate;
  final DateTime? endDate;
  final int dayCount;

  const RealAiTripRef({
    required this.id,
    this.title = '',
    this.destination,
    this.status = '',
    this.startDate,
    this.endDate,
    this.dayCount = 0,
  });

  factory RealAiTripRef.fromJson(Map<String, dynamic> json) {
    return RealAiTripRef(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] as String?) ?? '',
      destination: json['destination'] as String?,
      status: (json['status'] as String?) ?? '',
      startDate: _tryParseDate(json['startDate']),
      endDate: _tryParseDate(json['endDate']),
      dayCount: (json['dayCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Real-backend mirror of `AITripContextDto.ActivitySummary` — cross-section
/// counts the backend computes (never recomputed client-side).
class RealAiActivitySummary {
  final int totalTrips;
  final int activeTrips;
  final int upcomingTrips;
  final int completedTrips;
  final int totalPlannedDays;
  final int totalBookings;
  final int savedCollections;
  final int wishlistItems;
  final int reviews;
  final int recommendations;

  const RealAiActivitySummary({
    this.totalTrips = 0,
    this.activeTrips = 0,
    this.upcomingTrips = 0,
    this.completedTrips = 0,
    this.totalPlannedDays = 0,
    this.totalBookings = 0,
    this.savedCollections = 0,
    this.wishlistItems = 0,
    this.reviews = 0,
    this.recommendations = 0,
  });

  factory RealAiActivitySummary.fromJson(Map<String, dynamic> json) {
    return RealAiActivitySummary(
      totalTrips: (json['totalTrips'] as num?)?.toInt() ?? 0,
      activeTrips: (json['activeTrips'] as num?)?.toInt() ?? 0,
      upcomingTrips: (json['upcomingTrips'] as num?)?.toInt() ?? 0,
      completedTrips: (json['completedTrips'] as num?)?.toInt() ?? 0,
      totalPlannedDays: (json['totalPlannedDays'] as num?)?.toInt() ?? 0,
      totalBookings: (json['totalBookings'] as num?)?.toInt() ?? 0,
      savedCollections: (json['savedCollections'] as num?)?.toInt() ?? 0,
      wishlistItems: (json['wishlistItems'] as num?)?.toInt() ?? 0,
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      recommendations: (json['recommendations'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Real-backend mirror of `AITripContextResponse` (the read-only snapshot). The
/// nested `budgetSummary` reuses [RealExpenseSummary] (UI-40); `wishlistSummary`
/// is surfaced by its item count. Embedded profile/interest/recommendation/
/// booking/collection/review lists are represented by [activitySummary] counts.
class RealAiContext {
  final RealAiTripRef? currentTrip;
  final List<RealAiTripRef> upcomingTrips;
  final RealExpenseSummary? budgetSummary;
  final RealAiActivitySummary activitySummary;
  final int wishlistItemCount;
  final DateTime? contextGeneratedAt;

  const RealAiContext({
    this.currentTrip,
    this.upcomingTrips = const [],
    this.budgetSummary,
    this.activitySummary = const RealAiActivitySummary(),
    this.wishlistItemCount = 0,
    this.contextGeneratedAt,
  });

  factory RealAiContext.fromJson(Map<String, dynamic> json) {
    final current = json['currentTrip'];
    final upcoming = json['upcomingTrips'];
    final budget = json['budgetSummary'];
    final activity = json['activitySummary'];
    final wishlist = json['wishlistSummary'];
    return RealAiContext(
      currentTrip: current is Map<String, dynamic>
          ? RealAiTripRef.fromJson(current)
          : null,
      upcomingTrips: upcoming is List
          ? upcoming
              .map((e) => RealAiTripRef.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
      budgetSummary: budget is Map<String, dynamic>
          ? RealExpenseSummary.fromJson(budget)
          : null,
      activitySummary: activity is Map<String, dynamic>
          ? RealAiActivitySummary.fromJson(activity)
          : const RealAiActivitySummary(),
      wishlistItemCount: wishlist is Map<String, dynamic>
          ? (wishlist['itemCount'] as num?)?.toInt() ?? 0
          : 0,
      contextGeneratedAt: _tryParseDate(json['contextGeneratedAt']),
    );
  }
}

/// Outcome of the real AI context read (`GET /api/me/ai/context`). Read-only.
/// [demoUnavailable] is the Demo Mode guard (zero HTTP); [sessionExpired] (401)
/// never triggers auto-logout; [forbidden] 403, [notFound] 404 (the JWT user no
/// longer exists), [serverError] 5xx, [network] transport/timeout.
enum AiContextOutcome {
  success,
  demoUnavailable,
  sessionExpired,
  forbidden,
  notFound,
  network,
  serverError,
}

// ── Trip documents (/api/me/trips/.../documents, UI-43) ──────────────────────
// Real-backend mirror of the Trip Documents & Attachments surface
// (`TripDocumentController` / `TripPlanDocumentService`). Documents attach to a
// real TripPlan (UI-20); full CRUD + pin/unpin is owner-or-EDITOR, reads are
// owner-or-collaborator. The document type REUSES the demo [TripDocumentType]
// enum (identical 12 values + wire codes via its `.code` getter). `Map` decoding
// is confined to [fromJson]; request building to [toJson].

/// Maps a backend `TripPlanDocumentType` wire string to the shared
/// [TripDocumentType] view enum. Returns null for any unrecognised code so the
/// caller can fall back to the raw string.
TripDocumentType? tripDocumentTypeFromCode(String? code) {
  switch (code) {
    case 'FLIGHT_TICKET':
      return TripDocumentType.flightTicket;
    case 'HOTEL_BOOKING':
      return TripDocumentType.hotelBooking;
    case 'TRAIN_TICKET':
      return TripDocumentType.trainTicket;
    case 'BUS_TICKET':
      return TripDocumentType.busTicket;
    case 'PASSPORT':
      return TripDocumentType.passport;
    case 'VISA':
      return TripDocumentType.visa;
    case 'INSURANCE':
      return TripDocumentType.insurance;
    case 'TOUR':
      return TripDocumentType.tour;
    case 'RECEIPT':
      return TripDocumentType.receipt;
    case 'PDF':
      return TripDocumentType.pdf;
    case 'IMAGE':
      return TripDocumentType.image;
    case 'OTHER':
      return TripDocumentType.other;
    default:
      return null;
  }
}

/// Real-backend mirror of `TripPlanDocumentResponse`. The nested `mediaAsset` is
/// parsed selectively (url/thumbnail/type) — the document points at a media asset
/// registered by URL or reused by id; the client never uploads a file.
class RealTripDocument {
  final int id;
  final int tripPlanId;
  final int? tripDayId;
  final int? tripItemId;
  final int? mediaAssetId;
  final String? mediaUrl;
  final String? mediaThumbnailUrl;
  final String? mediaType; // raw MediaType code
  final int? uploadedByUserId;
  final String? uploadedByUserName;
  final String documentType; // raw wire code
  final String? title;
  final String? notes;
  final bool pinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealTripDocument({
    required this.id,
    this.tripPlanId = 0,
    this.tripDayId,
    this.tripItemId,
    this.mediaAssetId,
    this.mediaUrl,
    this.mediaThumbnailUrl,
    this.mediaType,
    this.uploadedByUserId,
    this.uploadedByUserName,
    this.documentType = '',
    this.title,
    this.notes,
    this.pinned = false,
    this.createdAt,
    this.updatedAt,
  });

  /// The mapped document type, or null if the backend sent an unrecognised code.
  TripDocumentType? get typeView => tripDocumentTypeFromCode(documentType);

  factory RealTripDocument.fromJson(Map<String, dynamic> json) {
    final media = json['mediaAsset'];
    final mediaMap = media is Map<String, dynamic> ? media : null;
    return RealTripDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tripPlanId: (json['tripPlanId'] as num?)?.toInt() ?? 0,
      tripDayId: (json['tripDayId'] as num?)?.toInt(),
      tripItemId: (json['tripItemId'] as num?)?.toInt(),
      mediaAssetId: (mediaMap?['id'] as num?)?.toInt(),
      mediaUrl: mediaMap?['url'] as String?,
      mediaThumbnailUrl: mediaMap?['thumbnailUrl'] as String?,
      mediaType: mediaMap?['mediaType'] as String?,
      uploadedByUserId: (json['uploadedByUserId'] as num?)?.toInt(),
      uploadedByUserName: json['uploadedByUserName'] as String?,
      documentType: (json['documentType'] as String?) ?? '',
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      pinned: (json['pinned'] as bool?) ?? false,
      createdAt: _tryParseDate(json['createdAt']),
      updatedAt: _tryParseDate(json['updatedAt']),
    );
  }
}

/// Request payload for creating/updating a document (`TripPlanDocumentRequest`).
/// On create, [url] registers a new media asset (the client never uploads a raw
/// file). On update the backend ignores media fields — only type/title/notes
/// change — but [toJson] emits the same shape for both.
class RealTripDocumentPayload {
  final TripDocumentType documentType;
  final String? title;
  final String? notes;
  final String? url;
  final String? thumbnailUrl;
  final String? altText;
  final int? tripDayId;
  final int? tripItemId;

  const RealTripDocumentPayload({
    required this.documentType,
    this.title,
    this.notes,
    this.url,
    this.thumbnailUrl,
    this.altText,
    this.tripDayId,
    this.tripItemId,
  });

  Map<String, dynamic> toJson() {
    return {
      'tripDayId': tripDayId,
      'tripItemId': tripItemId,
      'documentType': documentType.code,
      'title': title,
      'notes': notes,
      if (url != null && url!.isNotEmpty) 'url': url,
      if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
        'thumbnailUrl': thumbnailUrl,
      if (altText != null && altText!.isNotEmpty) 'altText': altText,
    };
  }
}

/// Outcome of a real trip-document action (list/create/update/delete/pin/unpin).
/// [demoUnavailable] is the Demo Mode guard (zero HTTP); [busy] the single-flight
/// guard; [sessionExpired] (401) never triggers auto-logout; [forbidden] 403 (a
/// VIEWER collaborator can't mutate); [notFound] 404 (trip/document gone or not
/// yours); [validation] 400 (missing url/type or a bad day/item link);
/// [serverError] 5xx; [network] transport/timeout.
enum DocumentOutcome {
  success,
  demoUnavailable,
  busy,
  sessionExpired,
  forbidden,
  notFound,
  validation,
  network,
  serverError,
}

class DemoBooking {
  final String code;
  final String ownerUserId;
  final Place hotel;
  final HotelRoom room;
  final HotelRatePlan ratePlan;
  final HotelPricingQuote quote;
  final HotelStayCriteria criteria;
  final String specialRequest;
  final BookingStatus status;
  final BookingPaymentStatus? paymentStatus;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? updatedAt;
  final DateTime? cancelledAt;
  final DateTime? actualCheckInAt;
  final DateTime? actualCheckOutAt;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final DateTime? modifiedAt;
  final DateTime? lastStatusChangedAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;
  final String? cancellationReason;
  final bool itineraryAdded;

  const DemoBooking({
    required this.code,
    this.ownerUserId = 'demo-owner',
    required this.hotel,
    required this.room,
    required this.ratePlan,
    required this.quote,
    required this.criteria,
    this.specialRequest = '',
    this.status = BookingStatus.confirmed,
    this.paymentStatus,
    required this.createdAt,
    this.confirmedAt,
    this.updatedAt,
    this.cancelledAt,
    this.actualCheckInAt,
    this.actualCheckOutAt,
    this.completedAt,
    this.archivedAt,
    this.modifiedAt,
    this.lastStatusChangedAt,
    this.paidAt,
    this.refundedAt,
    this.cancellationReason,
    this.itineraryAdded = false,
  });

  DemoBooking copyWith({
    String? code,
    String? ownerUserId,
    Place? hotel,
    HotelRoom? room,
    HotelRatePlan? ratePlan,
    HotelPricingQuote? quote,
    HotelStayCriteria? criteria,
    String? specialRequest,
    BookingStatus? status,
    Object? paymentStatus = _unset,
    DateTime? createdAt,
    Object? confirmedAt = _unset,
    Object? updatedAt = _unset,
    Object? cancelledAt = _unset,
    Object? actualCheckInAt = _unset,
    Object? actualCheckOutAt = _unset,
    Object? completedAt = _unset,
    Object? archivedAt = _unset,
    Object? modifiedAt = _unset,
    Object? lastStatusChangedAt = _unset,
    Object? paidAt = _unset,
    Object? refundedAt = _unset,
    Object? cancellationReason = _unset,
    bool? itineraryAdded,
  }) =>
      DemoBooking(
        code: code ?? this.code,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        hotel: hotel ?? this.hotel,
        room: room ?? this.room,
        ratePlan: ratePlan ?? this.ratePlan,
        quote: quote ?? this.quote,
        criteria: criteria ?? this.criteria,
        specialRequest: specialRequest ?? this.specialRequest,
        status: status ?? this.status,
        paymentStatus: identical(paymentStatus, _unset)
            ? this.paymentStatus
            : paymentStatus as BookingPaymentStatus?,
        createdAt: createdAt ?? this.createdAt,
        confirmedAt: identical(confirmedAt, _unset)
            ? this.confirmedAt
            : confirmedAt as DateTime?,
        updatedAt: identical(updatedAt, _unset)
            ? this.updatedAt
            : updatedAt as DateTime?,
        cancelledAt: identical(cancelledAt, _unset)
            ? this.cancelledAt
            : cancelledAt as DateTime?,
        actualCheckInAt: identical(actualCheckInAt, _unset)
            ? this.actualCheckInAt
            : actualCheckInAt as DateTime?,
        actualCheckOutAt: identical(actualCheckOutAt, _unset)
            ? this.actualCheckOutAt
            : actualCheckOutAt as DateTime?,
        completedAt: identical(completedAt, _unset)
            ? this.completedAt
            : completedAt as DateTime?,
        archivedAt: identical(archivedAt, _unset)
            ? this.archivedAt
            : archivedAt as DateTime?,
        modifiedAt: identical(modifiedAt, _unset)
            ? this.modifiedAt
            : modifiedAt as DateTime?,
        lastStatusChangedAt: identical(lastStatusChangedAt, _unset)
            ? this.lastStatusChangedAt
            : lastStatusChangedAt as DateTime?,
        paidAt: identical(paidAt, _unset) ? this.paidAt : paidAt as DateTime?,
        refundedAt: identical(refundedAt, _unset)
            ? this.refundedAt
            : refundedAt as DateTime?,
        cancellationReason: identical(cancellationReason, _unset)
            ? this.cancellationReason
            : cancellationReason as String?,
        itineraryAdded: itineraryAdded ?? this.itineraryAdded,
      );

  static const Object _unset = Object();

  DateTime get modificationVersion =>
      updatedAt ?? modifiedAt ?? lastStatusChangedAt ?? createdAt;
}

enum BookingCancellationResult {
  eligible,
  unavailable,
  notFound,
  forbidden,
  alreadyCancelled,
  completed,
  checkInStarted,
  unsupportedStatus,
}

class BookingCancellationEligibility {
  final BookingCancellationResult result;
  final DemoBooking? booking;

  const BookingCancellationEligibility({
    required this.result,
    this.booking,
  });

  bool get canCancel =>
      result == BookingCancellationResult.eligible && booking != null;
}

enum BookingModificationResult {
  available,
  unavailable,
  notFound,
  forbidden,
  onlyPending,
  activePaymentStarted,
  roomRateUnavailable,
  stayStarted,
  invalidDates,
  invalidGuests,
  capacityExceeded,
  quoteUnavailable,
  noChanges,
  stale,
}

class BookingModificationEligibility {
  final BookingModificationResult result;
  final DemoBooking? booking;

  const BookingModificationEligibility({
    required this.result,
    this.booking,
  });

  bool get canModify =>
      result == BookingModificationResult.available && booking != null;
}

class BookingModificationDraft {
  static const backendRequestFields = <String>[
    'checkIn',
    'checkOut',
    'adults',
    'children',
    'extraBeds',
    'ratePlanId',
  ];

  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final int extraBeds;
  final int? ratePlanId;

  const BookingModificationDraft({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    this.extraBeds = 0,
    this.ratePlanId,
  });

  bool changes(DemoBooking booking) {
    return dateOnly(checkIn) != dateOnly(booking.criteria.checkIn) ||
        dateOnly(checkOut) != dateOnly(booking.criteria.checkOut) ||
        adults != booking.criteria.adults ||
        children != booking.criteria.children ||
        extraBeds != booking.criteria.extraBeds ||
        ratePlanId != booking.ratePlan.ratePlanId;
  }
}

class BookingTimelineEvent {
  final String code;
  final DateTime occurredAt;

  const BookingTimelineEvent({
    required this.code,
    required this.occurredAt,
  });
}

class DemoPaymentAttempt {
  static const Object _unset = Object();

  final String id;
  final String sessionId;
  final String bookingCode;
  final CheckoutPaymentProvider provider;
  final CheckoutPaymentMethod paymentMethod;
  final double amount;
  final String currency;
  final BookingPaymentStatus? paymentStatus;
  final PaymentSessionStatus sessionStatus;
  final String checkoutUrl;
  final String? safeProviderReference;
  final String? failureReason;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;
  final DateTime? failedAt;
  final DateTime? cancelledAt;
  final DateTime? refundedAt;
  final String idempotencyKey;
  final bool demoOnly;

  const DemoPaymentAttempt({
    required this.id,
    required this.sessionId,
    required this.bookingCode,
    required this.provider,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    this.paymentStatus,
    this.sessionStatus = PaymentSessionStatus.pending,
    this.checkoutUrl = '',
    this.safeProviderReference,
    this.failureReason,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
    this.failedAt,
    this.cancelledAt,
    this.refundedAt,
    this.idempotencyKey = '',
    this.demoOnly = true,
  });

  bool get amountIsSafe =>
      amount.isFinite && amount >= 0 && currency.isNotEmpty;

  bool get isSuccessful =>
      paymentStatus == BookingPaymentStatus.paid ||
      sessionStatus == PaymentSessionStatus.captured;

  bool get isPending =>
      sessionStatus == PaymentSessionStatus.newSession ||
      sessionStatus == PaymentSessionStatus.pending ||
      sessionStatus == PaymentSessionStatus.authorized;

  bool get canRetry =>
      sessionStatus == PaymentSessionStatus.failed ||
      sessionStatus == PaymentSessionStatus.cancelled ||
      sessionStatus == PaymentSessionStatus.expired ||
      paymentStatus == BookingPaymentStatus.failed ||
      paymentStatus == BookingPaymentStatus.cancelled;

  DemoPaymentAttempt copyWith({
    String? id,
    String? sessionId,
    String? bookingCode,
    CheckoutPaymentProvider? provider,
    CheckoutPaymentMethod? paymentMethod,
    double? amount,
    String? currency,
    Object? paymentStatus = _unset,
    PaymentSessionStatus? sessionStatus,
    String? checkoutUrl,
    Object? safeProviderReference = _unset,
    Object? failureReason = _unset,
    Object? expiresAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? paidAt = _unset,
    Object? failedAt = _unset,
    Object? cancelledAt = _unset,
    Object? refundedAt = _unset,
    String? idempotencyKey,
    bool? demoOnly,
  }) =>
      DemoPaymentAttempt(
        id: id ?? this.id,
        sessionId: sessionId ?? this.sessionId,
        bookingCode: bookingCode ?? this.bookingCode,
        provider: provider ?? this.provider,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        amount: amount ?? this.amount,
        currency: currency ?? this.currency,
        paymentStatus: identical(paymentStatus, _unset)
            ? this.paymentStatus
            : paymentStatus as BookingPaymentStatus?,
        sessionStatus: sessionStatus ?? this.sessionStatus,
        checkoutUrl: checkoutUrl ?? this.checkoutUrl,
        safeProviderReference: identical(safeProviderReference, _unset)
            ? this.safeProviderReference
            : safeProviderReference as String?,
        failureReason: identical(failureReason, _unset)
            ? this.failureReason
            : failureReason as String?,
        expiresAt: identical(expiresAt, _unset)
            ? this.expiresAt
            : expiresAt as DateTime?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        paidAt: identical(paidAt, _unset) ? this.paidAt : paidAt as DateTime?,
        failedAt:
            identical(failedAt, _unset) ? this.failedAt : failedAt as DateTime?,
        cancelledAt: identical(cancelledAt, _unset)
            ? this.cancelledAt
            : cancelledAt as DateTime?,
        refundedAt: identical(refundedAt, _unset)
            ? this.refundedAt
            : refundedAt as DateTime?,
        idempotencyKey: idempotencyKey ?? this.idempotencyKey,
        demoOnly: demoOnly ?? this.demoOnly,
      );
}

class DemoCheckoutResult {
  final DemoPaymentActionResult result;
  final DemoBooking? booking;
  final DemoPaymentAttempt? attempt;

  const DemoCheckoutResult({
    required this.result,
    this.booking,
    this.attempt,
  });

  bool get created =>
      result == DemoPaymentActionResult.success &&
      booking != null &&
      attempt != null;
}

enum ReviewStatus {
  pending,
  approved,
  rejected,
  hidden,
  reported,
}

extension ReviewStatusData on ReviewStatus {
  String get code {
    switch (this) {
      case ReviewStatus.pending:
        return 'PENDING';
      case ReviewStatus.approved:
        return 'APPROVED';
      case ReviewStatus.rejected:
        return 'REJECTED';
      case ReviewStatus.hidden:
        return 'HIDDEN';
      case ReviewStatus.reported:
        return 'REPORTED';
    }
  }

  bool get isPublic => this == ReviewStatus.approved;
}

enum ReviewRatingCategory {
  cleanliness,
  service,
  location,
  value,
  facilities,
}

extension ReviewRatingCategoryData on ReviewRatingCategory {
  String get code {
    switch (this) {
      case ReviewRatingCategory.cleanliness:
        return 'ratingCleanliness';
      case ReviewRatingCategory.service:
        return 'ratingService';
      case ReviewRatingCategory.location:
        return 'ratingLocation';
      case ReviewRatingCategory.value:
        return 'ratingValue';
      case ReviewRatingCategory.facilities:
        return 'ratingFacilities';
    }
  }
}

enum ReviewSort {
  newest,
  oldest,
  highestRating,
  lowestRating,
  mostHelpful,
}

enum ReviewMediaType {
  image,
  video,
  document,
}

extension ReviewMediaTypeData on ReviewMediaType {
  String get code {
    switch (this) {
      case ReviewMediaType.image:
        return 'IMAGE';
      case ReviewMediaType.video:
        return 'VIDEO';
      case ReviewMediaType.document:
        return 'DOCUMENT';
    }
  }
}

enum ReviewActionResult {
  success,
  unavailable,
  notFound,
  ineligible,
  duplicate,
  invalidRating,
  titleTooLong,
  contentTooLong,
  unsupported,
}

class ReviewEligibility {
  final ReviewActionResult result;
  final DemoBooking? booking;

  const ReviewEligibility({
    required this.result,
    this.booking,
  });

  bool get canReview => result == ReviewActionResult.success && booking != null;
}

class ReviewMediaItem {
  final String id;
  final String url;
  final String thumbnailUrl;
  final ReviewMediaType mediaType;
  final int sortOrder;
  final bool cover;
  final bool active;
  final String altText;

  const ReviewMediaItem({
    required this.id,
    required this.url,
    this.thumbnailUrl = '',
    required this.mediaType,
    this.sortOrder = 0,
    this.cover = false,
    this.active = true,
    this.altText = '',
  });

  bool get hasSafeUrl => isSafeReviewMediaUrl(url);
  bool get hasSafeThumbnailUrl => isSafeReviewMediaUrl(thumbnailUrl);
  bool get isVisible => active && hasSafeUrl;

  String get presentationUrl {
    if (!hasSafeUrl) return '';
    if (mediaType == ReviewMediaType.image && hasSafeThumbnailUrl) {
      return thumbnailUrl.trim();
    }
    return url.trim();
  }

  ReviewMediaItem copyWith({
    String? id,
    String? url,
    String? thumbnailUrl,
    ReviewMediaType? mediaType,
    int? sortOrder,
    bool? cover,
    bool? active,
    String? altText,
  }) =>
      ReviewMediaItem(
        id: id ?? this.id,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
        mediaType: mediaType ?? this.mediaType,
        sortOrder: sortOrder ?? this.sortOrder,
        cover: cover ?? this.cover,
        active: active ?? this.active,
        altText: altText ?? this.altText,
      );
}

class PartnerReviewReply {
  static const Object _unset = Object();

  final String content;
  final DateTime? repliedAt;
  final DateTime? updatedAt;
  final String partnerDisplayName;

  const PartnerReviewReply({
    required this.content,
    this.repliedAt,
    this.updatedAt,
    this.partnerDisplayName = '',
  });

  bool get isVisible => content.trim().isNotEmpty;

  PartnerReviewReply copyWith({
    String? content,
    Object? repliedAt = _unset,
    Object? updatedAt = _unset,
    String? partnerDisplayName,
  }) =>
      PartnerReviewReply(
        content: content ?? this.content,
        repliedAt: identical(repliedAt, _unset)
            ? this.repliedAt
            : repliedAt as DateTime?,
        updatedAt: identical(updatedAt, _unset)
            ? this.updatedAt
            : updatedAt as DateTime?,
        partnerDisplayName: partnerDisplayName ?? this.partnerDisplayName,
      );
}

class TravelerReview {
  static const Object _unset = Object();

  final int id;
  final String? bookingId;
  final String bookingCode;
  final String authorUserId;
  final String authorName;
  final int placeId;
  final String placeName;
  final int ratingOverall;
  final int? ratingCleanliness;
  final int? ratingService;
  final int? ratingLocation;
  final int? ratingValue;
  final int? ratingFacilities;
  final String title;
  final String content;
  final ReviewStatus status;
  final int helpfulCount;
  final int reportedCount;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String rejectReason;
  final List<ReviewMediaItem> _media;
  final PartnerReviewReply? partnerReply;
  final DateTime createdAt;
  final DateTime updatedAt;

  TravelerReview({
    required this.id,
    this.bookingId,
    this.bookingCode = '',
    required this.authorUserId,
    required this.authorName,
    required this.placeId,
    required this.placeName,
    required this.ratingOverall,
    this.ratingCleanliness,
    this.ratingService,
    this.ratingLocation,
    this.ratingValue,
    this.ratingFacilities,
    this.title = '',
    this.content = '',
    this.status = ReviewStatus.pending,
    this.helpfulCount = 0,
    this.reportedCount = 0,
    this.approvedAt,
    this.rejectedAt,
    this.rejectReason = '',
    List<ReviewMediaItem> media = const <ReviewMediaItem>[],
    this.partnerReply,
    required this.createdAt,
    required this.updatedAt,
  }) : _media = List.unmodifiable(media);

  bool get isPublic => status.isPublic;
  bool get hasVerifiedBooking => bookingCode.trim().isNotEmpty;
  bool get hasPartnerReply => partnerReply?.isVisible == true;
  List<ReviewMediaItem> get media => List.unmodifiable(_media);

  List<ReviewMediaItem> get visibleMedia {
    final items = _media.where((item) => item.isVisible).toList();
    items.sort((a, b) {
      final order = a.sortOrder.compareTo(b.sortOrder);
      return order == 0 ? a.id.compareTo(b.id) : order;
    });
    return items;
  }

  int? ratingFor(ReviewRatingCategory category) {
    switch (category) {
      case ReviewRatingCategory.cleanliness:
        return ratingCleanliness;
      case ReviewRatingCategory.service:
        return ratingService;
      case ReviewRatingCategory.location:
        return ratingLocation;
      case ReviewRatingCategory.value:
        return ratingValue;
      case ReviewRatingCategory.facilities:
        return ratingFacilities;
    }
  }

  TravelerReview copyWith({
    int? id,
    Object? bookingId = _unset,
    String? bookingCode,
    String? authorUserId,
    String? authorName,
    int? placeId,
    String? placeName,
    int? ratingOverall,
    Object? ratingCleanliness = _unset,
    Object? ratingService = _unset,
    Object? ratingLocation = _unset,
    Object? ratingValue = _unset,
    Object? ratingFacilities = _unset,
    String? title,
    String? content,
    ReviewStatus? status,
    int? helpfulCount,
    int? reportedCount,
    Object? approvedAt = _unset,
    Object? rejectedAt = _unset,
    String? rejectReason,
    List<ReviewMediaItem>? media,
    Object? partnerReply = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TravelerReview(
        id: id ?? this.id,
        bookingId: identical(bookingId, _unset)
            ? this.bookingId
            : bookingId as String?,
        bookingCode: bookingCode ?? this.bookingCode,
        authorUserId: authorUserId ?? this.authorUserId,
        authorName: authorName ?? this.authorName,
        placeId: placeId ?? this.placeId,
        placeName: placeName ?? this.placeName,
        ratingOverall: ratingOverall ?? this.ratingOverall,
        ratingCleanliness: identical(ratingCleanliness, _unset)
            ? this.ratingCleanliness
            : ratingCleanliness as int?,
        ratingService: identical(ratingService, _unset)
            ? this.ratingService
            : ratingService as int?,
        ratingLocation: identical(ratingLocation, _unset)
            ? this.ratingLocation
            : ratingLocation as int?,
        ratingValue: identical(ratingValue, _unset)
            ? this.ratingValue
            : ratingValue as int?,
        ratingFacilities: identical(ratingFacilities, _unset)
            ? this.ratingFacilities
            : ratingFacilities as int?,
        title: title ?? this.title,
        content: content ?? this.content,
        status: status ?? this.status,
        helpfulCount: helpfulCount ?? this.helpfulCount,
        reportedCount: reportedCount ?? this.reportedCount,
        approvedAt: identical(approvedAt, _unset)
            ? this.approvedAt
            : approvedAt as DateTime?,
        rejectedAt: identical(rejectedAt, _unset)
            ? this.rejectedAt
            : rejectedAt as DateTime?,
        rejectReason: rejectReason ?? this.rejectReason,
        media: media ?? this.media,
        partnerReply: identical(partnerReply, _unset)
            ? this.partnerReply
            : partnerReply as PartnerReviewReply?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class PlaceReviewSummary {
  final int placeId;
  final int total;
  final double? average;
  final Map<int, int> distribution;
  final Map<ReviewRatingCategory, double> categoryAverages;
  final int verifiedCount;
  final List<TravelerReview> preview;

  const PlaceReviewSummary({
    required this.placeId,
    required this.total,
    required this.average,
    required this.distribution,
    required this.categoryAverages,
    required this.verifiedCount,
    required this.preview,
  });
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

enum TripPermission { owner, editor, viewer, noAccess }

extension TripPermissionData on TripPermission {
  bool get canRead => this != TripPermission.noAccess;
  bool get canEdit =>
      this == TripPermission.owner || this == TripPermission.editor;
  bool get canManage => this == TripPermission.owner;
}

enum TripCollaboratorRole { viewer, editor }

extension TripCollaboratorRoleData on TripCollaboratorRole {
  String get code {
    switch (this) {
      case TripCollaboratorRole.viewer:
        return 'VIEWER';
      case TripCollaboratorRole.editor:
        return 'EDITOR';
    }
  }
}

class DemoTripUser {
  final String id;
  final String email;
  final String fullName;

  const DemoTripUser({
    required this.id,
    required this.email,
    required this.fullName,
  });
}

class TripCollaborator {
  final String id;
  final int tripPlanId;
  final String userId;
  final String userEmail;
  final String userFullName;
  final TripCollaboratorRole role;
  final bool active;
  final DateTime invitedAt;
  final DateTime? acceptedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripCollaborator({
    required this.id,
    required this.tripPlanId,
    required this.userId,
    required this.userEmail,
    required this.userFullName,
    required this.role,
    this.active = true,
    required this.invitedAt,
    this.acceptedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  TripCollaborator copyWith({
    String? id,
    int? tripPlanId,
    String? userId,
    String? userEmail,
    String? userFullName,
    TripCollaboratorRole? role,
    bool? active,
    DateTime? invitedAt,
    Object? acceptedAt = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TripCollaborator(
        id: id ?? this.id,
        tripPlanId: tripPlanId ?? this.tripPlanId,
        userId: userId ?? this.userId,
        userEmail: userEmail ?? this.userEmail,
        userFullName: userFullName ?? this.userFullName,
        role: role ?? this.role,
        active: active ?? this.active,
        invitedAt: invitedAt ?? this.invitedAt,
        acceptedAt: identical(acceptedAt, _unset)
            ? this.acceptedAt
            : acceptedAt as DateTime?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static const Object _unset = Object();
}

class SharedTripSummary {
  final int tripId;
  final String title;
  final String destination;
  final String coverImage;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final String ownerName;
  final TripCollaboratorRole role;

  const SharedTripSummary({
    required this.tripId,
    required this.title,
    required this.destination,
    required this.coverImage,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.ownerName,
    required this.role,
  });
}

enum TripNoteType { note, journal, reminder, idea, memory }

extension TripNoteTypeData on TripNoteType {
  String get code {
    switch (this) {
      case TripNoteType.note:
        return 'NOTE';
      case TripNoteType.journal:
        return 'JOURNAL';
      case TripNoteType.reminder:
        return 'REMINDER';
      case TripNoteType.idea:
        return 'IDEA';
      case TripNoteType.memory:
        return 'MEMORY';
    }
  }
}

enum TripMood { happy, excited, calm, tired, stressed, neutral }

extension TripMoodData on TripMood {
  String get code {
    switch (this) {
      case TripMood.happy:
        return 'HAPPY';
      case TripMood.excited:
        return 'EXCITED';
      case TripMood.calm:
        return 'CALM';
      case TripMood.tired:
        return 'TIRED';
      case TripMood.stressed:
        return 'STRESSED';
      case TripMood.neutral:
        return 'NEUTRAL';
    }
  }
}

class TripNote {
  static const Object _unset = Object();

  final String id;
  final int tripPlanId;
  final int? tripDayId;
  final int? tripItemId;
  final String authorUserId;
  final String authorUserName;
  final TripNoteType noteType;
  final String title;
  final String content;
  final TripMood? mood;
  final String photoUrl;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TripNote({
    required this.id,
    required this.tripPlanId,
    this.tripDayId,
    this.tripItemId,
    required this.authorUserId,
    required this.authorUserName,
    this.noteType = TripNoteType.note,
    this.title = '',
    required this.content,
    this.mood,
    this.photoUrl = '',
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  TripNote copyWith({
    String? id,
    int? tripPlanId,
    Object? tripDayId = _unset,
    Object? tripItemId = _unset,
    String? authorUserId,
    String? authorUserName,
    TripNoteType? noteType,
    String? title,
    String? content,
    Object? mood = _unset,
    String? photoUrl,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TripNote(
        id: id ?? this.id,
        tripPlanId: tripPlanId ?? this.tripPlanId,
        tripDayId:
            identical(tripDayId, _unset) ? this.tripDayId : tripDayId as int?,
        tripItemId: identical(tripItemId, _unset)
            ? this.tripItemId
            : tripItemId as int?,
        authorUserId: authorUserId ?? this.authorUserId,
        authorUserName: authorUserName ?? this.authorUserName,
        noteType: noteType ?? this.noteType,
        title: title ?? this.title,
        content: content ?? this.content,
        mood: identical(mood, _unset) ? this.mood : mood as TripMood?,
        photoUrl: photoUrl ?? this.photoUrl,
        pinned: pinned ?? this.pinned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

enum PackingCategory {
  documents,
  clothes,
  toiletries,
  electronics,
  medicine,
  money,
  food,
  baby,
  pet,
  other,
}

extension PackingCategoryData on PackingCategory {
  String get code {
    switch (this) {
      case PackingCategory.documents:
        return 'DOCUMENTS';
      case PackingCategory.clothes:
        return 'CLOTHES';
      case PackingCategory.toiletries:
        return 'TOILETRIES';
      case PackingCategory.electronics:
        return 'ELECTRONICS';
      case PackingCategory.medicine:
        return 'MEDICINE';
      case PackingCategory.money:
        return 'MONEY';
      case PackingCategory.food:
        return 'FOOD';
      case PackingCategory.baby:
        return 'BABY';
      case PackingCategory.pet:
        return 'PET';
      case PackingCategory.other:
        return 'OTHER';
    }
  }
}

class PackingItem {
  static const Object _unset = Object();

  final String id;
  final int tripPlanId;
  final String label;
  final PackingCategory category;
  final int quantity;
  final bool checked;
  final String? assignedToUserId;
  final String? assignedToUserName;
  final String notes;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? checkedAt;

  const PackingItem({
    required this.id,
    required this.tripPlanId,
    required this.label,
    required this.category,
    this.quantity = 1,
    this.checked = false,
    this.assignedToUserId,
    this.assignedToUserName,
    this.notes = '',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.checkedAt,
  });

  PackingItem copyWith({
    String? id,
    int? tripPlanId,
    String? label,
    PackingCategory? category,
    int? quantity,
    bool? checked,
    Object? assignedToUserId = _unset,
    Object? assignedToUserName = _unset,
    String? notes,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? checkedAt = _unset,
  }) =>
      PackingItem(
        id: id ?? this.id,
        tripPlanId: tripPlanId ?? this.tripPlanId,
        label: label ?? this.label,
        category: category ?? this.category,
        quantity: quantity ?? this.quantity,
        checked: checked ?? this.checked,
        assignedToUserId: identical(assignedToUserId, _unset)
            ? this.assignedToUserId
            : assignedToUserId as String?,
        assignedToUserName: identical(assignedToUserName, _unset)
            ? this.assignedToUserName
            : assignedToUserName as String?,
        notes: notes ?? this.notes,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        checkedAt: identical(checkedAt, _unset)
            ? this.checkedAt
            : checkedAt as DateTime?,
      );
}

class PackingProgress {
  final int total;
  final int checked;

  const PackingProgress({required this.total, required this.checked});

  int get unchecked => total - checked;
  double get ratio => total == 0 ? 0 : (checked / total).clamp(0.0, 1.0);
  int get percent => (ratio * 100).round();
}

enum TripReminderType {
  custom,
  document,
  checkIn,
  flight,
  activity,
  payment,
  packing,
  other,
}

extension TripReminderTypeData on TripReminderType {
  String get code {
    switch (this) {
      case TripReminderType.custom:
        return 'CUSTOM';
      case TripReminderType.document:
        return 'DOCUMENT';
      case TripReminderType.checkIn:
        return 'CHECK_IN';
      case TripReminderType.flight:
        return 'FLIGHT';
      case TripReminderType.activity:
        return 'ACTIVITY';
      case TripReminderType.payment:
        return 'PAYMENT';
      case TripReminderType.packing:
        return 'PACKING';
      case TripReminderType.other:
        return 'OTHER';
    }
  }
}

enum TripReminderStatus { pending, completed, cancelled }

extension TripReminderStatusData on TripReminderStatus {
  String get code {
    switch (this) {
      case TripReminderStatus.pending:
        return 'PENDING';
      case TripReminderStatus.completed:
        return 'COMPLETED';
      case TripReminderStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class TripReminder {
  static const Object _unset = Object();

  final String id;
  final int tripPlanId;
  final int? tripDayId;
  final int? tripItemId;
  final String? documentId;
  final String userId;
  final String userName;
  final TripReminderType reminderType;
  final String title;
  final String message;
  final DateTime reminderAt;
  final TripReminderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const TripReminder({
    required this.id,
    required this.tripPlanId,
    this.tripDayId,
    this.tripItemId,
    this.documentId,
    required this.userId,
    required this.userName,
    this.reminderType = TripReminderType.custom,
    required this.title,
    this.message = '',
    required this.reminderAt,
    this.status = TripReminderStatus.pending,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  bool isOverdue(DateTime current) =>
      status == TripReminderStatus.pending &&
      reminderAt.isBefore(current.toUtc());

  TripReminder copyWith({
    String? id,
    int? tripPlanId,
    Object? tripDayId = _unset,
    Object? tripItemId = _unset,
    Object? documentId = _unset,
    String? userId,
    String? userName,
    TripReminderType? reminderType,
    String? title,
    String? message,
    DateTime? reminderAt,
    TripReminderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? completedAt = _unset,
  }) =>
      TripReminder(
        id: id ?? this.id,
        tripPlanId: tripPlanId ?? this.tripPlanId,
        tripDayId:
            identical(tripDayId, _unset) ? this.tripDayId : tripDayId as int?,
        tripItemId: identical(tripItemId, _unset)
            ? this.tripItemId
            : tripItemId as int?,
        documentId: identical(documentId, _unset)
            ? this.documentId
            : documentId as String?,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        reminderType: reminderType ?? this.reminderType,
        title: title ?? this.title,
        message: message ?? this.message,
        reminderAt: reminderAt ?? this.reminderAt,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        completedAt: identical(completedAt, _unset)
            ? this.completedAt
            : completedAt as DateTime?,
      );
}

enum TripToolActionResult {
  success,
  unavailable,
  forbidden,
  blank,
  invalidEmail,
  duplicate,
  rejected,
  unsafeUrl,
  notFound,
  invalidQuantity,
  invalidReorder,
  invalidDate,
}

class TripCompanionCounts {
  final int activeCollaborators;
  final int notes;
  final int uncheckedPacking;
  final int pendingReminders;
  final int documents;

  const TripCompanionCounts({
    required this.activeCollaborators,
    required this.notes,
    required this.uncheckedPacking,
    required this.pendingReminders,
    required this.documents,
  });
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
  final scheme = uri?.scheme.toLowerCase();
  return uri != null &&
      (scheme == 'http' || scheme == 'https') &&
      uri.hasAuthority &&
      uri.host.trim().isNotEmpty &&
      uri.userInfo.isEmpty;
}

bool isSafeReviewMediaUrl(String value) => isSafeDocumentMediaUrl(value);

class Trip {
  final int id;
  final String ownerUserId;
  final String ownerEmail;
  final String ownerName;
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
    this.ownerUserId = 'demo-owner',
    this.ownerEmail = 'demo@planyourtrip.com',
    this.ownerName = 'Demo Traveler',
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
    String? ownerUserId,
    String? ownerEmail,
    String? ownerName,
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
        ownerUserId: ownerUserId ?? this.ownerUserId,
        ownerEmail: ownerEmail ?? this.ownerEmail,
        ownerName: ownerName ?? this.ownerName,
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
