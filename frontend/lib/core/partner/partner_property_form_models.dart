/// What the Partner property editor sends, and the catalogue it chooses from.
///
/// Phase C, mapped one-to-one from `backend-v1`:
///   * `dto/PartnerHotelDto.PartnerHotelCreateRequest` — `POST /api/partner/hotels`
///   * `PartnerHotelUpdateRequest` / `PartnerContactRequest` /
///     `PartnerLocationRequest` / `PartnerPolicyRequest` / `PartnerAmenitiesRequest`
///   * `dto/CategoryDto.CategoryResponse`, `LocationDto.LocationResponse`,
///     `AmenityDto.AmenityResponse` — the admin-managed reference data, read from
///     the public `GET /api/categories`, `/api/locations/...`, `/api/amenities`
///
/// Nothing here invents an option: a category, location or amenity exists only
/// because the backend returned it, and the backend validates every id again on
/// write. The client sends ids, never names.
library;

/// Field names exactly as the backend's `fieldErrors` spell them, so a refusal
/// can be attached to the control that caused it.
class PropertyFields {
  const PropertyFields._();

  static const String name = 'name';
  static const String shortDescription = 'shortDescription';
  static const String description = 'description';
  static const String categoryId = 'categoryId';
  static const String subcategoryId = 'subcategoryId';
  static const String administrativeUnitId = 'administrativeUnitId';
  static const String address = 'address';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String phone = 'phone';
  static const String email = 'email';
  static const String website = 'website';
  static const String starRating = 'starRating';
  static const String checkIn = 'checkIn';
  static const String checkOut = 'checkOut';
  static const String slug = 'slug';
  static const String amenityIds = 'amenityIds';
}

/// `CategoryResponse` — one row of the admin-managed category tree.
///
/// A property may only be classified under `type == "ACCOMMODATION"`; the
/// backend enforces it and [isAccommodation] is how the editor offers only
/// those, rather than hard-coding the eight names.
class PropertyCategoryOption {
  final int id;
  final int? parentId;
  final String name;
  final String? slug;
  final String? type;
  final bool active;

  const PropertyCategoryOption({
    required this.id,
    required this.name,
    this.parentId,
    this.slug,
    this.type,
    this.active = true,
  });

  bool get isAccommodation => type == 'ACCOMMODATION';
  bool get isRoot => parentId == null;

  static PropertyCategoryOption? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PropertyCategoryOption(
      id: id,
      parentId: _asInt(json['parentId']),
      name: _asString(json['name']) ?? '',
      slug: _asString(json['slug']),
      type: _asString(json['type']),
      active: json['active'] != false,
    );
  }
}

/// `LocationResponse` — one administrative unit of the D13 hierarchy
/// (COUNTRY → PROVINCE/CITY → AREA).
///
/// [canHoldProperty] mirrors the backend's rule exactly: a property sits in a
/// province, a city or an area, never in a country.
class PropertyLocationOption {
  final int id;
  final int? parentId;
  final String name;
  final String? slug;

  /// The raw `UnitType` name. Kept as the backend's own string: an unknown one
  /// must not become a guess.
  final String? type;
  final String? fullPath;
  final bool active;

  const PropertyLocationOption({
    required this.id,
    required this.name,
    this.parentId,
    this.slug,
    this.type,
    this.fullPath,
    this.active = true,
  });

  static const Set<String> propertyTypes = {'PROVINCE', 'CITY', 'AREA'};

  bool get canHoldProperty => active && propertyTypes.contains(type);

  /// Whether units can hang below this one — a country or a province/city.
  bool get hasChildren =>
      type == 'COUNTRY' || type == 'PROVINCE' || type == 'CITY';

  String get label => fullPath ?? name;

  static PropertyLocationOption? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PropertyLocationOption(
      id: id,
      parentId: _asInt(json['parentId']),
      name: _asString(json['name']) ?? '',
      slug: _asString(json['slug']),
      type: _asString(json['type']),
      fullPath: _asString(json['fullPath']),
      active: json['active'] != false,
    );
  }
}

/// `AmenityResponse` — one amenity of the admin-managed catalogue.
///
/// Only the groups that describe a property are offered; `ROOM` belongs to a
/// room and the rest to other kinds of place. The backend refuses the others,
/// so this is the same rule, not a client-side opinion.
class PropertyAmenityOption {
  final int id;
  final String name;
  final String? slug;
  final String? icon;
  final String? groupName;
  final bool active;

  const PropertyAmenityOption({
    required this.id,
    required this.name,
    this.slug,
    this.icon,
    this.groupName,
    this.active = true,
  });

  static const Set<String> propertyGroups = {'GENERAL', 'HOTEL'};

  bool get describesProperty => active && propertyGroups.contains(groupName);

  static PropertyAmenityOption? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PropertyAmenityOption(
      id: id,
      name: _asString(json['name']) ?? '',
      slug: _asString(json['slug']),
      icon: _asString(json['icon']),
      groupName: _asString(json['groupName']),
      active: json['active'] != false,
    );
  }
}

/// `PartnerHotelCreateRequest` — everything a new draft property needs.
///
/// There is no status, slug, owner or moderation flag: the backend assigns the
/// first three and owns the last, and sending them would change nothing.
class PartnerPropertyDraft {
  final String name;
  final String? shortDescription;
  final String? description;
  final int categoryId;
  final int? subcategoryId;
  final int administrativeUnitId;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final String? website;

  /// 1–5, required: `hotel_details.star_rating` is NOT NULL with a 1..5 check,
  /// so there is no value meaning "not classified". It is the partner's own
  /// declaration.
  final int starRating;

  /// `"HH:mm"` — sent as `"HH:mm:00"`, which is what `LocalTime` reads.
  final String checkIn;
  final String checkOut;

  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;
  final String? cancellationPolicy;
  final bool freeCancellation;
  final bool parkingAvailable;
  final bool parkingFree;
  final String? parkingDescription;
  final bool wifiAvailable;
  final bool wifiFree;
  final String? internetDescription;
  final List<String> languages;
  final List<String> paymentMethods;
  final List<int> amenityIds;

  const PartnerPropertyDraft({
    required this.name,
    required this.categoryId,
    required this.administrativeUnitId,
    required this.address,
    required this.starRating,
    required this.checkIn,
    required this.checkOut,
    this.shortDescription,
    this.description,
    this.subcategoryId,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
    this.cancellationPolicy,
    this.freeCancellation = false,
    this.parkingAvailable = false,
    this.parkingFree = false,
    this.parkingDescription,
    this.wifiAvailable = false,
    this.wifiFree = false,
    this.internetDescription,
    this.languages = const [],
    this.paymentMethods = const [],
    this.amenityIds = const [],
  });

  Map<String, dynamic> toRequestJson() => {
        'name': name,
        'shortDescription': shortDescription,
        'description': description,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
        'administrativeUnitId': administrativeUnitId,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'phone': phone,
        'email': email,
        'website': website,
        'starRating': starRating,
        'checkIn': _time(checkIn),
        'checkOut': _time(checkOut),
        'childrenPolicy': childrenPolicy,
        'petPolicy': petPolicy,
        'smokingPolicy': smokingPolicy,
        'cancellationPolicy': cancellationPolicy,
        'freeCancellation': freeCancellation,
        'parkingAvailable': parkingAvailable,
        'parkingFree': parkingFree,
        'parkingDescription': parkingDescription,
        'wifiAvailable': wifiAvailable,
        'wifiFree': wifiFree,
        'internetDescription': internetDescription,
        'languages': languages,
        'paymentMethods': paymentMethods,
        'amenityIds': amenityIds,
      };
}

/// `PartnerHotelUpdateRequest` — the basics section of an existing property.
///
/// The slug is sent back exactly as it was read. It is the property's public
/// identifier and the editor does not offer to change it, so an edit of the
/// name can never silently move it.
class PartnerPropertyBasics {
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final int categoryId;
  final int? subcategoryId;

  const PartnerPropertyBasics({
    required this.name,
    required this.slug,
    required this.categoryId,
    this.shortDescription,
    this.description,
    this.subcategoryId,
  });

  Map<String, dynamic> toRequestJson() => {
        'name': name,
        'slug': slug,
        'shortDescription': shortDescription,
        'description': description,
        'categoryId': categoryId,
        'subcategoryId': subcategoryId,
      };
}

/// `PartnerContactRequest`. Every field is sent, so clearing one really clears
/// it; the two social fields the editor does not show are carried through
/// unchanged rather than erased.
class PartnerPropertyContact {
  final String? phone;
  final String? email;
  final String? website;
  final String? facebook;
  final String? instagram;

  const PartnerPropertyContact({
    this.phone,
    this.email,
    this.website,
    this.facebook,
    this.instagram,
  });

  Map<String, dynamic> toRequestJson() => {
        'phone': phone,
        'email': email,
        'website': website,
        'facebook': facebook,
        'instagram': instagram,
      };
}

/// `PartnerLocationRequest` — address, coordinates and administrative unit.
class PartnerPropertyPlacement {
  final String address;
  final double? latitude;
  final double? longitude;
  final int administrativeUnitId;

  const PartnerPropertyPlacement({
    required this.address,
    required this.administrativeUnitId,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toRequestJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'administrativeUnitId': administrativeUnitId,
      };
}

/// `PartnerPolicyRequest` — the Phase C editor's "details and policies"
/// section.
///
/// The C6 Policies module sends the same record's five original fields
/// (`PartnerPropertyPolicies`); this sends those plus the Phase C ones. Both are
/// complete for what they declare: the backend leaves a Phase C field it was not
/// sent exactly as it was, so neither model can erase the other's work.
class PartnerPropertyDetails {
  final String checkIn;
  final String checkOut;
  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;
  final int starRating;
  final String? cancellationPolicy;
  final bool freeCancellation;
  final bool parkingAvailable;
  final bool parkingFree;
  final String? parkingDescription;
  final bool wifiAvailable;
  final bool wifiFree;
  final String? internetDescription;
  final List<String> languages;
  final List<String> paymentMethods;

  const PartnerPropertyDetails({
    required this.checkIn,
    required this.checkOut,
    required this.starRating,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
    this.cancellationPolicy,
    this.freeCancellation = false,
    this.parkingAvailable = false,
    this.parkingFree = false,
    this.parkingDescription,
    this.wifiAvailable = false,
    this.wifiFree = false,
    this.internetDescription,
    this.languages = const [],
    this.paymentMethods = const [],
  });

  Map<String, dynamic> toRequestJson() => {
        'checkIn': _time(checkIn),
        'checkOut': _time(checkOut),
        'childrenPolicy': childrenPolicy,
        'petPolicy': petPolicy,
        'smokingPolicy': smokingPolicy,
        'starRating': starRating,
        'cancellationPolicy': cancellationPolicy,
        'freeCancellation': freeCancellation,
        'parkingAvailable': parkingAvailable,
        'parkingFree': parkingFree,
        'parkingDescription': parkingDescription,
        'wifiAvailable': wifiAvailable,
        'wifiFree': wifiFree,
        'internetDescription': internetDescription,
        'languages': languages,
        'paymentMethods': paymentMethods,
      };
}

/// `"Vietnamese, English"` → `["Vietnamese", "English"]`; blanks dropped.
///
/// The one reading of a comma-separated field, shared by the Phase C editor and
/// the Phase D wizard so both send the backend the same list.
List<String> splitPropertyList(String? raw) {
  if (raw == null) return const [];
  return raw
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

/// `"HH:mm"` → `"HH:mm:00"`; anything already carrying seconds is left alone.
String _time(String value) {
  final parts = value.split(':');
  return parts.length == 2 ? '$value:00' : value;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
