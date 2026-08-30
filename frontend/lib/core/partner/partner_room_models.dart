/// Typed models for the Partner Rooms module (C3), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree:
///   * `controller/PartnerRoomController` — `/api/partner/rooms`
///   * `dto/HotelRoomDto.HotelRoomResponse` (list **and** detail — the same
///     record is returned by both, so there is no separate summary shape)
///   * `dto/PlaceDto.AmenityRef`, `dto/HotelRoomDto.RoomImageRef`
///   * `model/RoomType`, `model/BedType`
///   * `service/PartnerRoomService` — ownership rules
///
/// ## Two things this module must not get wrong
///
/// 1. **A room has no status enum.** Unlike `Place`, `HotelRoom` carries only a
///    boolean `active`. `PlaceStatus` (DRAFT/PENDING_REVIEW/…) does **not**
///    apply here and is deliberately not reused — a room is either listed or
///    not.
/// 2. **`active` and inventory are different concepts.** `quantity` /
///    `availableQuantity` describe how many physical rooms exist and how many
///    are sellable; `active` describes whether the room type is listed at all.
///    They are never collapsed into one "Active" badge.
library;

/// `model/RoomType.java` — nine values.
enum PartnerRoomType {
  standard,
  superior,
  deluxe,
  premier,
  executive,
  suite,
  family,
  villa,
  bungalow,
  unknown;

  static PartnerRoomType parse(Object? raw) {
    if (raw is! String) return PartnerRoomType.unknown;
    switch (raw) {
      case 'STANDARD':
        return PartnerRoomType.standard;
      case 'SUPERIOR':
        return PartnerRoomType.superior;
      case 'DELUXE':
        return PartnerRoomType.deluxe;
      case 'PREMIER':
        return PartnerRoomType.premier;
      case 'EXECUTIVE':
        return PartnerRoomType.executive;
      case 'SUITE':
        return PartnerRoomType.suite;
      case 'FAMILY':
        return PartnerRoomType.family;
      case 'VILLA':
        return PartnerRoomType.villa;
      case 'BUNGALOW':
        return PartnerRoomType.bungalow;
      default:
        return PartnerRoomType.unknown;
    }
  }
}

/// `model/BedType.java` — seven values. Nullable on the response record, so
/// [unknown] covers "the backend sent something new" and null is kept as null
/// by [PartnerRoom.bedType] being nullable.
enum PartnerBedType {
  single,
  double_,
  twin,
  queen,
  king,
  sofaBed,
  bunk,
  unknown;

  static PartnerBedType? parse(Object? raw) {
    if (raw == null) return null;
    if (raw is! String) return PartnerBedType.unknown;
    switch (raw) {
      case 'SINGLE':
        return PartnerBedType.single;
      case 'DOUBLE':
        return PartnerBedType.double_;
      case 'TWIN':
        return PartnerBedType.twin;
      case 'QUEEN':
        return PartnerBedType.queen;
      case 'KING':
        return PartnerBedType.king;
      case 'SOFA_BED':
        return PartnerBedType.sofaBed;
      case 'BUNK':
        return PartnerBedType.bunk;
      default:
        return PartnerBedType.unknown;
    }
  }
}

/// `dto/PlaceDto.AmenityRef` — `(id, name, slug, icon, groupName)`.
class PartnerRoomAmenity {
  final int id;
  final String name;
  final String? slug;
  final String? groupName;

  const PartnerRoomAmenity({
    required this.id,
    required this.name,
    this.slug,
    this.groupName,
  });

  static PartnerRoomAmenity? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    final name = _asString(json['name']);
    if (id == null || name == null) return null;
    return PartnerRoomAmenity(
      id: id,
      name: name,
      slug: _asString(json['slug']),
      groupName: _asString(json['groupName']),
    );
  }
}

/// `dto/HotelRoomDto.RoomImageRef`.
class PartnerRoomImage {
  final int id;
  final String? url;
  final String? thumbnailUrl;
  final String? altText;
  final int sortOrder;
  final bool cover;

  const PartnerRoomImage({
    required this.id,
    required this.sortOrder,
    required this.cover,
    this.url,
    this.thumbnailUrl,
    this.altText,
  });

  static PartnerRoomImage? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerRoomImage(
      id: id,
      url: _asString(json['url']),
      thumbnailUrl: _asString(json['thumbnailUrl']),
      altText: _asString(json['altText']),
      sortOrder: _asInt(json['sortOrder']) ?? 0,
      cover: json['cover'] == true,
    );
  }
}

/// `dto/HotelRoomDto.HotelRoomResponse`.
///
/// Almost every numeric field is a **boxed** type in the record (`Integer`,
/// `Double`, `BigDecimal`) and is genuinely nullable — verified live, where
/// `description`, `floorNumber` and `originalPrice` all come back null for the
/// seeded rooms. They stay null here rather than defaulting to 0, which would
/// read as "this room costs nothing" or "ground floor".
///
/// Note the record carries **no property reference**: a room does not tell you
/// which hotel it belongs to. The owning property is therefore only known from
/// the `hotelId` the list was requested with — see `PartnerRoomsState`.
class PartnerRoom {
  final int id;
  final String roomName;
  final String? roomCode;
  final PartnerRoomType roomType;
  final String? description;

  final PartnerBedType? bedType;
  final int? bedCount;
  final int? maxAdults;
  final int? maxChildren;
  final int? maxGuests;
  final double? roomSizeSqm;
  final int? floorNumber;

  final bool smokingAllowed;
  final bool breakfastIncluded;
  final bool freeCancellation;
  final bool instantConfirmation;

  final double? priceFrom;
  final double? originalPrice;

  /// Total physical rooms of this type.
  final int? quantity;

  /// How many of [quantity] are currently sellable. The backend rejects
  /// `availableQuantity > quantity` with a 400.
  final int? availableQuantity;

  /// Whether this room type is listed at all. Not a lifecycle status.
  final bool active;

  final List<PartnerRoomAmenity> amenities;
  final String? coverImageUrl;
  final List<PartnerRoomImage> galleryImages;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerRoom({
    required this.id,
    required this.roomName,
    required this.roomType,
    required this.active,
    required this.smokingAllowed,
    required this.breakfastIncluded,
    required this.freeCancellation,
    required this.instantConfirmation,
    this.roomCode,
    this.description,
    this.bedType,
    this.bedCount,
    this.maxAdults,
    this.maxChildren,
    this.maxGuests,
    this.roomSizeSqm,
    this.floorNumber,
    this.priceFrom,
    this.originalPrice,
    this.quantity,
    this.availableQuantity,
    this.amenities = const [],
    this.coverImageUrl,
    this.galleryImages = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// True when the backend supplied both inventory numbers, so a
  /// "sellable of total" reading is meaningful.
  bool get hasInventory => quantity != null && availableQuantity != null;

  /// True when every physical room of this type is currently unsellable —
  /// operationally distinct from the room type being switched off.
  bool get isSoldOut => hasInventory && quantity! > 0 && availableQuantity == 0;

  /// A copy with [active] replaced, used to fold a toggle response back into
  /// the list without refetching it.
  PartnerRoom copyWithActive(bool value) => PartnerRoom(
        id: id,
        roomName: roomName,
        roomCode: roomCode,
        roomType: roomType,
        description: description,
        bedType: bedType,
        bedCount: bedCount,
        maxAdults: maxAdults,
        maxChildren: maxChildren,
        maxGuests: maxGuests,
        roomSizeSqm: roomSizeSqm,
        floorNumber: floorNumber,
        smokingAllowed: smokingAllowed,
        breakfastIncluded: breakfastIncluded,
        freeCancellation: freeCancellation,
        instantConfirmation: instantConfirmation,
        priceFrom: priceFrom,
        originalPrice: originalPrice,
        quantity: quantity,
        availableQuantity: availableQuantity,
        active: value,
        amenities: amenities,
        coverImageUrl: coverImageUrl,
        galleryImages: galleryImages,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static PartnerRoom? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;

    final rawAmenities = json['amenities'];
    final amenities = <PartnerRoomAmenity>[];
    if (rawAmenities is List) {
      for (final entry in rawAmenities) {
        if (entry is! Map<String, dynamic>) continue;
        final amenity = PartnerRoomAmenity.fromJson(entry);
        if (amenity != null) amenities.add(amenity);
      }
    }

    final rawImages = json['galleryImages'];
    final images = <PartnerRoomImage>[];
    if (rawImages is List) {
      for (final entry in rawImages) {
        if (entry is! Map<String, dynamic>) continue;
        final image = PartnerRoomImage.fromJson(entry);
        if (image != null) images.add(image);
      }
    }

    return PartnerRoom(
      id: id,
      roomName: _asString(json['roomName']) ?? '',
      roomCode: _asString(json['roomCode']),
      roomType: PartnerRoomType.parse(json['roomType']),
      description: _asString(json['description']),
      bedType: PartnerBedType.parse(json['bedType']),
      bedCount: _asInt(json['bedCount']),
      maxAdults: _asInt(json['maxAdults']),
      maxChildren: _asInt(json['maxChildren']),
      maxGuests: _asInt(json['maxGuests']),
      roomSizeSqm: _asDouble(json['roomSizeSqm']),
      floorNumber: _asInt(json['floorNumber']),
      smokingAllowed: json['smokingAllowed'] == true,
      breakfastIncluded: json['breakfastIncluded'] == true,
      freeCancellation: json['freeCancellation'] == true,
      instantConfirmation: json['instantConfirmation'] == true,
      priceFrom: _asDouble(json['priceFrom']),
      originalPrice: _asDouble(json['originalPrice']),
      quantity: _asInt(json['quantity']),
      availableQuantity: _asInt(json['availableQuantity']),
      active: json['active'] == true,
      amenities: List.unmodifiable(amenities),
      coverImageUrl: _asString(json['coverImageUrl']),
      galleryImages: List.unmodifiable(images),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
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

DateTime? _asDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
