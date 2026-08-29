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

/// `dto/PartnerProfileDto.PartnerProfileResponse`. Only the fields C0 needs are
/// mapped; the write-side fields (address, tax code, ...) belong to the partner
/// onboarding phase, not to the shell foundation.
class PartnerProfile {
  final int id;
  final int userId;
  final String businessName;
  final String? businessType;
  final String representativeName;
  final String? email;
  final String? phone;
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
    this.rejectReason,
    this.submittedAt,
    this.approvedAt,
  });

  bool get isApproved =>
      verificationStatus == PartnerVerificationStatus.approved;

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
      verificationStatus:
          PartnerVerificationStatus.parse(json['verificationStatus']),
      rejectReason: _asString(json['rejectReason']),
      submittedAt: _asDate(json['submittedAt']),
      approvedAt: _asDate(json['approvedAt']),
    );
  }
}

/// `dto/PartnerExtranetDto.PartnerExtranetHomeResponse`, minus the nested
/// finance overview: C0 shows operational counts only, and finance is its own
/// later module with its own DTO surface.
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
  });

  static PartnerWorkspaceOverview fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final profileMap =
        profile is Map<String, dynamic> ? profile : const <String, dynamic>{};
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
    );
  }
}

/// `dto/PartnerHotelDto.PartnerHotelSummaryResponse` — one authorized property
/// in the partner's workspace scope.
class PartnerProperty {
  final int id;
  final String name;
  final String? address;
  final bool active;
  final String? status;
  final double ratingAvg;
  final int reviewCount;

  const PartnerProperty({
    required this.id,
    required this.name,
    required this.active,
    this.address,
    this.status,
    this.ratingAvg = 0,
    this.reviewCount = 0,
  });

  static PartnerProperty? fromJson(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    return PartnerProperty(
      id: id,
      name: _asString(json['name']) ?? '',
      address: _asString(json['address']),
      active: json['active'] == true,
      status: _asString(json['status']),
      ratingAvg: _asDouble(json['ratingAvg']) ?? 0,
      reviewCount: _asInt(json['reviewCount']) ?? 0,
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
