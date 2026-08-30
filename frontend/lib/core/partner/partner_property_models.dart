/// Typed models for the Partner Properties module (C2), mapped one-to-one from
/// `backend-v1` (branch `develop`).
///
/// Source of truth, read from the authoritative backend worktree rather than the
/// stale `src/` copy on this frontend branch:
///   * `controller/PartnerHotelController` — `/api/partner/hotels`
///   * `dto/PartnerHotelDto.PartnerHotelSummaryResponse` (list)
///   * `dto/PartnerHotelDto.PartnerHotelResponse` (detail)
///   * `service/PartnerPropertyService` — ownership and status rules
///   * `model/PlaceStatus` — the moderation lifecycle
///
/// The backend calls this concept a **hotel** (`Place` owned by a
/// `PartnerProfile`); the product calls it a **property**. The route and DTO
/// names stay the backend's; only the user-facing wording is localised.
library;

/// `model/PlaceStatus.java` — the moderation lifecycle of a listing.
///
/// These are the seven values the enum actually declares. Note the real name is
/// `PENDING_REVIEW`, not `PENDING`, and that `DRAFT` and `HIDDEN` exist — a
/// lifecycle guessed from convention would have got all three wrong.
///
/// The partner cannot move a listing through this lifecycle: `PartnerHotel
/// Controller` exposes no status transition, and `PartnerPropertyTest`
/// (`partner_cannotModifyFeatured` / `partner_cannotModifyVerified`) confirms
/// the moderation flags are admin-owned. It is therefore displayed, never
/// edited.
enum PartnerPlaceStatus {
  draft,
  pendingReview,
  approved,
  published,
  hidden,
  archived,
  rejected,
  unknown;

  static PartnerPlaceStatus parse(Object? raw) {
    if (raw is! String) return PartnerPlaceStatus.unknown;
    switch (raw) {
      case 'DRAFT':
        return PartnerPlaceStatus.draft;
      case 'PENDING_REVIEW':
        return PartnerPlaceStatus.pendingReview;
      case 'APPROVED':
        return PartnerPlaceStatus.approved;
      case 'PUBLISHED':
        return PartnerPlaceStatus.published;
      case 'HIDDEN':
        return PartnerPlaceStatus.hidden;
      case 'ARCHIVED':
        return PartnerPlaceStatus.archived;
      case 'REJECTED':
        return PartnerPlaceStatus.rejected;
      default:
        return PartnerPlaceStatus.unknown;
    }
  }

  /// Whether guests can currently reach this listing. Only `PUBLISHED` is
  /// public; everything else is pre-publication, withdrawn or refused.
  ///
  /// This is a *description* of the backend's own state, not a client-side
  /// permission — nothing is unlocked by it.
  bool get isPubliclyVisible => this == PartnerPlaceStatus.published;

  /// Whether the listing is still moving through moderation.
  bool get isAwaitingModeration =>
      this == PartnerPlaceStatus.draft ||
      this == PartnerPlaceStatus.pendingReview;
}

/// `dto/PartnerHotelDto.PartnerHotelResponse` — the full detail record returned
/// by `GET /api/partner/hotels/{id}` and by every mutation endpoint.
///
/// Every nullable field below is genuinely nullable on the wire: verified
/// against the running backend, where `phone`, `email`, `website`, `facebook`,
/// `instagram`, `childrenPolicy`, `petPolicy` and `smokingPolicy` all come back
/// null for the seeded property. They render as "not set", never as an empty
/// row pretending to hold a value.
class PartnerPropertyDetail {
  final int id;
  final String name;
  final String? slug;
  final String? shortDescription;
  final String? description;
  final String? address;
  final double? latitude;
  final double? longitude;

  // Contact — all nullable.
  final String? phone;
  final String? email;
  final String? website;
  final String? facebook;
  final String? instagram;

  // Policies — `LocalTime` serialises as "HH:mm:ss"; kept as the raw backend
  // string plus a parsed pair, because a policy time has no date and coercing
  // it into a DateTime would invent one.
  final String? checkIn;
  final String? checkOut;
  final String? childrenPolicy;
  final String? petPolicy;
  final String? smokingPolicy;

  /// Partner-controlled: `PATCH /activate` / `PATCH /deactivate`.
  final bool active;

  /// Admin-controlled. Read-only for the partner — the backend rejects any
  /// attempt to change these.
  final bool featured;
  final bool verified;

  final double ratingAvg;
  final int reviewCount;
  final PartnerPlaceStatus status;

  final int? ownerProfileId;
  final String? ownerBusinessName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerPropertyDetail({
    required this.id,
    required this.name,
    required this.active,
    required this.featured,
    required this.verified,
    required this.ratingAvg,
    required this.reviewCount,
    required this.status,
    this.slug,
    this.shortDescription,
    this.description,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    this.website,
    this.facebook,
    this.instagram,
    this.checkIn,
    this.checkOut,
    this.childrenPolicy,
    this.petPolicy,
    this.smokingPolicy,
    this.ownerProfileId,
    this.ownerBusinessName,
    this.createdAt,
    this.updatedAt,
  });

  /// True when the backend supplied coordinates for both axes. A single axis is
  /// not a location, so it is treated as absent rather than plotted at zero.
  bool get hasCoordinates => latitude != null && longitude != null;

  bool get hasAnyContact =>
      phone != null ||
      email != null ||
      website != null ||
      facebook != null ||
      instagram != null;

  bool get hasAnyPolicy =>
      checkIn != null ||
      checkOut != null ||
      childrenPolicy != null ||
      petPolicy != null ||
      smokingPolicy != null;

  static PartnerPropertyDetail? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerPropertyDetail(
      id: id,
      name: _asString(json['name']) ?? '',
      slug: _asString(json['slug']),
      shortDescription: _asString(json['shortDescription']),
      description: _asString(json['description']),
      address: _asString(json['address']),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      phone: _asString(json['phone']),
      email: _asString(json['email']),
      website: _asString(json['website']),
      facebook: _asString(json['facebook']),
      instagram: _asString(json['instagram']),
      checkIn: _asTime(json['checkIn']),
      checkOut: _asTime(json['checkOut']),
      childrenPolicy: _asString(json['childrenPolicy']),
      petPolicy: _asString(json['petPolicy']),
      smokingPolicy: _asString(json['smokingPolicy']),
      active: json['active'] == true,
      featured: json['featured'] == true,
      verified: json['verified'] == true,
      ratingAvg: _asDouble(json['ratingAvg']) ?? 0,
      reviewCount: _asInt(json['reviewCount']) ?? 0,
      status: PartnerPlaceStatus.parse(json['status']),
      ownerProfileId: _asInt(json['ownerProfileId']),
      ownerBusinessName: _asString(json['ownerBusinessName']),
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }
}

/// `LocalTime` arrives as `"HH:mm:ss"` (or `"HH:mm"`). Trim the seconds for
/// display but keep it a string — a check-in time has no date, and manufacturing
/// one to get a `DateTime` would be inventing data.
String? _asTime(Object? value) {
  final raw = _asString(value);
  if (raw == null) return null;
  final parts = raw.split(':');
  if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
  return raw;
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
