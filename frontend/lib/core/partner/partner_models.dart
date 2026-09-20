/// Typed Partner Extranet models, mapped one-to-one from the backend's
/// `dto/Partner*Dto.java` records.
///
/// These deliberately live here rather than in `lib/core/mock/app_models.dart`:
/// that file is already ~10k lines of *traveller* domain models and its `mock/`
/// path is misleading for a real backend contract. Partner is a new bounded
/// context, so it gets its own file — same plain-Dart `fromJson` convention as
/// every other model in the app, no new pattern.
///
/// `Map<String, dynamic>` stops at these `fromJson` constructors: nothing above
/// this layer sees raw JSON.
library;

import 'partner_dashboard_models.dart';
import 'partner_property_models.dart';

/// `model/PartnerVerificationStatus.java`. The moderation lifecycle of a
/// partner profile. Only `APPROVED` unlocks `/api/partner/extranet/**`.
enum PartnerVerificationStatus {
  draft,
  submitted,
  approved,
  rejected,
  suspended,
  unknown;

  static PartnerVerificationStatus parse(Object? raw) {
    if (raw is! String) return PartnerVerificationStatus.unknown;
    switch (raw) {
      case 'DRAFT':
        return PartnerVerificationStatus.draft;
      case 'SUBMITTED':
        return PartnerVerificationStatus.submitted;
      case 'APPROVED':
        return PartnerVerificationStatus.approved;
      case 'REJECTED':
        return PartnerVerificationStatus.rejected;
      case 'SUSPENDED':
        return PartnerVerificationStatus.suspended;
      default:
        return PartnerVerificationStatus.unknown;
    }
  }
}

/// `model/PartnerTeamRole.java` — an **intra-organization** scope, not a Spring
/// Security system role. It never crosses partner boundaries and must not be
/// promoted into a system role. Enforced server-side in the service layer
/// (`PartnerSettingsService.requireRole` / `requireOwner`); the client only uses
/// it to shape affordances.
///
/// [unknown] means "the client could not determine this team role" and must be
/// treated as the least-privileged case (fail closed).
enum PartnerTeamRole {
  owner,
  manager,
  frontDesk,
  finance,
  viewer,
  unknown;

  static PartnerTeamRole parse(Object? raw) {
    if (raw is! String) return PartnerTeamRole.unknown;
    switch (raw) {
      case 'OWNER':
        return PartnerTeamRole.owner;
      case 'MANAGER':
        return PartnerTeamRole.manager;
      case 'FRONT_DESK':
        return PartnerTeamRole.frontDesk;
      case 'FINANCE':
        return PartnerTeamRole.finance;
      case 'VIEWER':
        return PartnerTeamRole.viewer;
      default:
        return PartnerTeamRole.unknown;
    }
  }

  /// Mirrors `PartnerSettingsService.SETTINGS_WRITE_ROLES`.
  bool get canEditSettings =>
      this == PartnerTeamRole.owner || this == PartnerTeamRole.manager;

  /// Mirrors `PartnerSettingsService.PAYOUT_WRITE_ROLES`.
  bool get canEditPayout =>
      this == PartnerTeamRole.owner || this == PartnerTeamRole.finance;

  /// Mirrors `PartnerSettingsService.requireOwner`.
  bool get canManageTeam => this == PartnerTeamRole.owner;
}

/// `dto/PartnerProfileDto.PartnerProfileResponse`.
///
/// Phase B adds the write-side fields the response already carried — address,
/// tax code and website — because the Partner now edits this profile through
/// [PartnerProfileDraft] rather than only reading it.
class PartnerProfile {
  final int id;
  final int userId;
  final String businessName;
  final String? businessType;
  final String representativeName;
  final String? email;
  final String? phone;
  final String? address;
  final String? taxCode;
  final String? website;
  final PartnerVerificationStatus verificationStatus;
  final String? rejectReason;
  final DateTime? submittedAt;
  final DateTime? approvedAt;

  const PartnerProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.representativeName,
    required this.verificationStatus,
    this.businessType,
    this.email,
    this.phone,
    this.address,
    this.taxCode,
    this.website,
    this.rejectReason,
    this.submittedAt,
    this.approvedAt,
  });

  bool get isApproved =>
      verificationStatus == PartnerVerificationStatus.approved;

  /// The typed business kind; [PartnerBusinessType.unknown] when the server sent
  /// a value this build does not know.
  PartnerBusinessType get businessTypeValue =>
      PartnerBusinessType.parse(businessType);

  /// Whether the profile is in a state the backend allows editing and
  /// submitting: `createOrUpdateMyProfile` and `submitMyProfile` both accept
  /// only DRAFT or REJECTED.
  bool get isEditable =>
      verificationStatus == PartnerVerificationStatus.draft ||
      verificationStatus == PartnerVerificationStatus.rejected;

  static PartnerProfile? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerProfile(
      id: id,
      userId: _asInt(json['userId']) ?? 0,
      businessName: _asString(json['businessName']) ?? '',
      businessType: _asString(json['businessType']),
      representativeName: _asString(json['representativeName']) ?? '',
      email: _asString(json['email']),
      phone: _asString(json['phone']),
      address: _asString(json['address']),
      taxCode: _asString(json['taxCode']),
      website: _asString(json['website']),
      verificationStatus:
          PartnerVerificationStatus.parse(json['verificationStatus']),
      rejectReason: _asString(json['rejectReason']),
      submittedAt: _asDate(json['submittedAt']),
      approvedAt: _asDate(json['approvedAt']),
    );
  }
}

/// `model/BusinessType.java` — the business kinds the profile API accepts.
///
/// The wire value is what the backend stores; anything unrecognised parses to
/// [unknown] rather than being coerced into a real type.
enum PartnerBusinessType {
  hotel('HOTEL'),
  restaurant('RESTAURANT'),
  cafe('CAFE'),
  tourOperator('TOUR_OPERATOR'),
  transport('TRANSPORT'),
  other('OTHER'),
  unknown(null);

  const PartnerBusinessType(this.wireValue);

  final String? wireValue;

  /// The types a Partner may choose — [unknown] is a read-side fallback only.
  static List<PartnerBusinessType> get selectable =>
      values.where((t) => t.wireValue != null).toList();

  static PartnerBusinessType parse(Object? raw) {
    if (raw is! String) return PartnerBusinessType.unknown;
    for (final type in values) {
      if (type.wireValue == raw) return type;
    }
    return PartnerBusinessType.unknown;
  }
}

/// `dto/PartnerProfileDto.PartnerProfileRequest` — the write side of the
/// business profile, exactly the fields the backend accepts. `businessType` is
/// sent as its wire value; `taxCode` and `website` are the only optional ones.
class PartnerProfileDraft {
  final String businessName;
  final PartnerBusinessType businessType;
  final String representativeName;
  final String phone;
  final String email;
  final String address;
  final String? taxCode;
  final String? website;

  const PartnerProfileDraft({
    required this.businessName,
    required this.businessType,
    required this.representativeName,
    required this.phone,
    required this.email,
    required this.address,
    this.taxCode,
    this.website,
  });

  /// Builds the editable draft of an existing profile, so an edit starts from
  /// what the server holds rather than from an empty form.
  static PartnerProfileDraft fromProfile(PartnerProfile profile) =>
      PartnerProfileDraft(
        businessName: profile.businessName,
        businessType: profile.businessTypeValue,
        representativeName: profile.representativeName,
        phone: profile.phone ?? '',
        email: profile.email ?? '',
        address: profile.address ?? '',
        taxCode: profile.taxCode,
        website: profile.website,
      );

  Map<String, dynamic> toJson() => {
        'businessName': businessName.trim(),
        'businessType': businessType.wireValue,
        'representativeName': representativeName.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'address': address.trim(),
        if (taxCode != null && taxCode!.trim().isNotEmpty)
          'taxCode': taxCode!.trim(),
        if (website != null && website!.trim().isNotEmpty)
          'website': website!.trim(),
      };
}

/// `dto/PartnerProfileDto.PartnerSubmitResponse` — the acknowledgement of a
/// submission for Admin review.
class PartnerProfileSubmission {
  final int id;
  final PartnerVerificationStatus verificationStatus;
  final DateTime? submittedAt;
  final String? message;

  const PartnerProfileSubmission({
    required this.id,
    required this.verificationStatus,
    this.submittedAt,
    this.message,
  });

  static PartnerProfileSubmission? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerProfileSubmission(
      id: id,
      verificationStatus:
          PartnerVerificationStatus.parse(json['verificationStatus']),
      submittedAt: _asDate(json['submittedAt']),
      message: _asString(json['message']),
    );
  }
}

/// `dto/PartnerExtranetDto.PartnerExtranetHomeResponse`.
///
/// C1 additionally maps the two members C0 discarded — `financeSummary` and
/// `quickActions` — because they are already on the wire in this same response.
/// Fetching either again over HTTP would be a duplicate request for data the
/// client already holds.
///
/// Scope caveat that the dashboard must respect: `PartnerExtranetService.getHome`
/// computes [financeSummary] as `financeService.getOverview(userId, null, null,
/// null)` — i.e. **all hotels, default 30-day window**. It is therefore only
/// valid while the dashboard is at its default scope; a narrowed property or
/// date range requires `GET /api/partner/finance/overview` with those params.
class PartnerWorkspaceOverview {
  final String businessName;
  final String representativeName;
  final PartnerVerificationStatus verificationStatus;
  final int ownedHotelCount;
  final int activeRoomCount;
  final int todaysArrivals;
  final int todaysDepartures;
  final int unreadMessages;
  final int unreadNotifications;
  final int pendingReviews;
  final int activePromotions;

  /// Default-scope finance overview embedded in this response. Null only when
  /// the server omitted it.
  final PartnerFinanceOverview? financeSummary;

  /// Server-chosen quick actions, each with a `/partner/...` route.
  final List<PartnerQuickAction> quickActions;

  const PartnerWorkspaceOverview({
    required this.businessName,
    required this.representativeName,
    required this.verificationStatus,
    required this.ownedHotelCount,
    required this.activeRoomCount,
    required this.todaysArrivals,
    required this.todaysDepartures,
    required this.unreadMessages,
    required this.unreadNotifications,
    required this.pendingReviews,
    required this.activePromotions,
    this.financeSummary,
    this.quickActions = const [],
  });

  static PartnerWorkspaceOverview fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap =
        profile is Map<String, dynamic> ? profile : const <String, dynamic>{};
    final finance = json['financeSummary'];
    final rawActions = json['quickActions'];
    final actions = <PartnerQuickAction>[];
    if (rawActions is List) {
      for (final entry in rawActions) {
        if (entry is! Map<String, dynamic>) continue;
        final action = PartnerQuickAction.fromJson(entry);
        if (action != null) actions.add(action);
      }
    }
    return PartnerWorkspaceOverview(
      businessName: _asString(profileMap['businessName']) ?? '',
      representativeName: _asString(profileMap['representativeName']) ?? '',
      verificationStatus:
          PartnerVerificationStatus.parse(json['verificationStatus']),
      ownedHotelCount: _asInt(json['ownedHotelCount']) ?? 0,
      activeRoomCount: _asInt(json['activeRoomCount']) ?? 0,
      todaysArrivals: _asInt(json['todaysArrivals']) ?? 0,
      todaysDepartures: _asInt(json['todaysDepartures']) ?? 0,
      unreadMessages: _asInt(json['unreadMessages']) ?? 0,
      unreadNotifications: _asInt(json['unreadNotifications']) ?? 0,
      pendingReviews: _asInt(json['pendingReviews']) ?? 0,
      activePromotions: _asInt(json['activePromotions']) ?? 0,
      financeSummary: finance is Map<String, dynamic>
          ? PartnerFinanceOverview.fromJson(finance)
          : null,
      quickActions: List.unmodifiable(actions),
    );
  }
}

/// `dto/PartnerHotelDto.PartnerHotelSummaryResponse` — one authorized property
/// in the partner's workspace scope, as returned by `GET /api/partner/hotels`.
///
/// C0 mapped only the fields the shell needed. C2 maps the whole record, since
/// the Properties list renders it: `slug`, `shortDescription`, `featured`,
/// `verified`, `createdAt` and `updatedAt` were already on the wire and simply
/// discarded. [status] keeps its raw backend string for backward compatibility
/// and gains [placeStatus] as the typed reading.
class PartnerProperty {
  final int id;
  final String name;
  final String? slug;
  final String? shortDescription;
  final String? address;
  final bool active;
  final bool featured;
  final bool verified;

  /// Raw `PlaceStatus` name as the backend sent it.
  final String? status;
  final double ratingAvg;
  final int reviewCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PartnerProperty({
    required this.id,
    required this.name,
    required this.active,
    this.slug,
    this.shortDescription,
    this.address,
    this.featured = false,
    this.verified = false,
    this.status,
    this.ratingAvg = 0,
    this.reviewCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Typed reading of [status]; [PartnerPlaceStatus.unknown] for anything the
  /// client does not recognise, which is never treated as publishable.
  PartnerPlaceStatus get placeStatus => PartnerPlaceStatus.parse(status);

  /// A copy with [active] replaced — used to fold an activate/deactivate
  /// response back into the list without refetching it.
  PartnerProperty copyWithActive(bool value) => PartnerProperty(
        id: id,
        name: name,
        slug: slug,
        shortDescription: shortDescription,
        address: address,
        active: value,
        featured: featured,
        verified: verified,
        status: status,
        ratingAvg: ratingAvg,
        reviewCount: reviewCount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static PartnerProperty? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerProperty(
      id: id,
      name: _asString(json['name']) ?? '',
      slug: _asString(json['slug']),
      shortDescription: _asString(json['shortDescription']),
      address: _asString(json['address']),
      active: json['active'] == true,
      featured: json['featured'] == true,
      verified: json['verified'] == true,
      status: _asString(json['status']),
      ratingAvg: _asDouble(json['ratingAvg']) ?? 0,
      reviewCount: _asInt(json['reviewCount']) ?? 0,
      createdAt: _asDate(json['createdAt']),
      updatedAt: _asDate(json['updatedAt']),
    );
  }
}

/// `dto/PartnerSettingsDto.PartnerTeamMemberResponse`.
class PartnerTeamMember {
  final int id;
  final int partnerProfileId;
  final int userId;
  final String userName;
  final String userEmail;
  final PartnerTeamRole role;
  final bool active;

  const PartnerTeamMember({
    required this.id,
    required this.partnerProfileId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.active,
  });

  static PartnerTeamMember? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerTeamMember(
      id: id,
      partnerProfileId: _asInt(json['partnerProfileId']) ?? 0,
      userId: _asInt(json['userId']) ?? 0,
      userName: _asString(json['userName']) ?? '',
      userEmail: _asString(json['userEmail']) ?? '',
      role: PartnerTeamRole.parse(json['role']),
      active: json['active'] == true,
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
