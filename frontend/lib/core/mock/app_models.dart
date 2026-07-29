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
  final List<String> galleryUrls;
  final int? estimatedVisitMinutes;
  final List<PlaceOpeningHourGroupRecord> groupedOpeningHours;
  final HotelDetail? hotelDetail;

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
    this.galleryUrls = const [],
    this.estimatedVisitMinutes,
    this.groupedOpeningHours = const [],
    this.hotelDetail,
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
      galleryUrls: (json['galleryImages'] as List<dynamic>? ?? const [])
          .map((e) => (e as Map<String, dynamic>)['url']?.toString() ?? '')
          .where((e) => e.isNotEmpty)
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
