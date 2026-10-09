/// RBAC R5 — the caller's effective partner access, `GET /api/partner/me/access`
/// (`dto/PartnerAccessDto.AccessDocument`, RBAC V1.1 §25.2).
///
/// It is the client's single source of truth for what to *show* (§23 F2): the
/// workspace, the caller's membership and grants, the effective permission keys
/// by scope (after the server applied scope floors), and the parent context of
/// properties and room types the caller works in. Kept in memory only — never
/// persisted (F2).
///
/// Checks go by permission key at a scope, never by role name (F3). Unknown keys
/// are carried and ignored (F9). None of this authorizes anything: the backend
/// re-checks every request.
library;

import 'partner_models.dart';
import 'partner_team_models.dart';

/// Permission keys the client reads (`security/rbac/PartnerPermission`).
class PartnerPermissionKeys {
  const PartnerPermissionKeys._();

  static const String teamView = 'partner.team.view';
  static const String teamInvite = 'partner.team.invite';
  static const String teamRoleAssign = 'partner.team.role.assign';
  static const String teamSuspend = 'partner.team.suspend';
  static const String teamRemove = 'partner.team.remove';
  static const String teamOwnerManage = 'partner.team.owner.manage';

  /// P54 / P35 — the guest's name / contact. The booking list's guest search
  /// matches only what these let the caller see; without either the server
  /// refuses it, so the field is not offered.
  static const String bookingGuestIdentityView =
      'partner.booking.guest_identity.view';
  static const String bookingGuestContactView =
      'partner.booking.guest_contact.view';
}

/// A grant as the access document lists it (`Grant(role, scopeType, scopeId)`).
class PartnerAccessGrant {
  final PartnerTeamRole role;
  final PartnerScopeType scopeType;
  final int? scopeId;

  const PartnerAccessGrant(
      {required this.role, required this.scopeType, this.scopeId});
}

/// §11.7 parent context: a property the caller works in.
class PartnerAccessProperty {
  final int id;
  final String name;
  final String? locationLabel;
  final bool active;

  const PartnerAccessProperty(
      {required this.id,
      required this.name,
      this.locationLabel,
      this.active = true});
}

/// §11.7 parent context: a room type the caller holds a unit grant on.
class PartnerAccessUnit {
  final int id;
  final String roomName;
  final String? roomCode;
  final int? propertyId;

  const PartnerAccessUnit(
      {required this.id,
      required this.roomName,
      this.roomCode,
      this.propertyId});
}

class PartnerAccess {
  final int? companyId;
  final String? businessName;
  final PartnerVerificationStatus verificationStatus;

  /// The caller's membership row (for the registrant, their own OWNER row).
  final int? membershipId;
  final PartnerMembershipStatus membershipStatus;
  final bool primaryOwner;
  final bool pendingOwnerConfirmation;

  final List<PartnerAccessGrant> grants;
  final Set<String> companyPermissions;
  final Map<int, Set<String>> propertyPermissions;
  final Map<int, Set<String>> unitPermissions;
  final List<PartnerAccessProperty> properties;
  final List<PartnerAccessUnit> units;

  /// Until when the session counts as fresh for owner-level actions (step-up).
  final DateTime? stepUpFreshUntil;

  const PartnerAccess({
    this.companyId,
    this.businessName,
    this.verificationStatus = PartnerVerificationStatus.unknown,
    this.membershipId,
    this.membershipStatus = PartnerMembershipStatus.unknown,
    this.primaryOwner = false,
    this.pendingOwnerConfirmation = false,
    this.grants = const [],
    this.companyPermissions = const {},
    this.propertyPermissions = const {},
    this.unitPermissions = const {},
    this.properties = const [],
    this.units = const [],
    this.stepUpFreshUntil,
  });

  static PartnerAccess? fromJson(Map<String, dynamic> json) {
    final workspace = json['workspace'];
    if (workspace is! Map<String, dynamic>) return null;
    final membership = json['membership'] is Map<String, dynamic>
        ? json['membership'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final permissions = json['permissions'] is Map<String, dynamic>
        ? json['permissions'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final context = json['context'] is Map<String, dynamic>
        ? json['context'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final stepUp = json['stepUp'];

    final grants = <PartnerAccessGrant>[];
    final rawGrants = json['grants'];
    if (rawGrants is List) {
      for (final entry in rawGrants) {
        if (entry is! Map<String, dynamic>) continue;
        grants.add(PartnerAccessGrant(
          role: PartnerTeamRole.parse(entry['role']),
          scopeType: PartnerScopeType.parse(entry['scopeType']),
          scopeId: _int(entry['scopeId']),
        ));
      }
    }

    final properties = <PartnerAccessProperty>[];
    final rawProperties = context['properties'];
    if (rawProperties is List) {
      for (final entry in rawProperties) {
        if (entry is! Map<String, dynamic>) continue;
        final id = _int(entry['id']);
        if (id == null) continue;
        properties.add(PartnerAccessProperty(
          id: id,
          name: _string(entry['name']) ?? '#$id',
          locationLabel: _string(entry['locationLabel']),
          active: entry['active'] != false,
        ));
      }
    }
    final units = <PartnerAccessUnit>[];
    final rawUnits = context['units'];
    if (rawUnits is List) {
      for (final entry in rawUnits) {
        if (entry is! Map<String, dynamic>) continue;
        final id = _int(entry['id']);
        if (id == null) continue;
        units.add(PartnerAccessUnit(
          id: id,
          roomName: _string(entry['roomName']) ?? '#$id',
          roomCode: _string(entry['roomCode']),
          propertyId: _int(entry['propertyId']),
        ));
      }
    }

    return PartnerAccess(
      companyId: _int(workspace['companyId']),
      businessName: _string(workspace['businessName']),
      verificationStatus:
          PartnerVerificationStatus.parse(workspace['verificationStatus']),
      membershipId: _int(membership['id']),
      membershipStatus: PartnerMembershipStatus.parse(membership['status']),
      primaryOwner: membership['primaryOwner'] == true,
      pendingOwnerConfirmation: membership['pendingOwnerConfirmation'] == true,
      grants: List.unmodifiable(grants),
      companyPermissions: _keys(permissions['company']),
      propertyPermissions: _byId(permissions['properties']),
      unitPermissions: _byId(permissions['units']),
      properties: List.unmodifiable(properties),
      units: List.unmodifiable(units),
      stepUpFreshUntil:
          stepUp is Map<String, dynamic> && stepUp['freshUntil'] is String
              ? DateTime.tryParse(stepUp['freshUntil'] as String)
              : null,
    );
  }

  /// Whether [key] is held at company scope.
  bool holdsAtCompany(String key) => companyPermissions.contains(key);

  /// Whether [key] is held at any scope at all (§23 F4/F5: show the control).
  bool holdsAnywhere(String key) =>
      holdsAtCompany(key) ||
      propertyPermissions.values.any((keys) => keys.contains(key)) ||
      unitPermissions.values.any((keys) => keys.contains(key));

  /// Whether [key] covers [propertyId]: held at company scope or at that property.
  bool holdsForProperty(String key, int propertyId) =>
      holdsAtCompany(key) ||
      (propertyPermissions[propertyId]?.contains(key) ?? false);

  /// Whether [key] covers the room type [unitId] of [propertyId].
  bool holdsForUnit(String key, int unitId, int? propertyId) =>
      holdsAtCompany(key) ||
      (propertyId != null &&
          (propertyPermissions[propertyId]?.contains(key) ?? false)) ||
      (unitPermissions[unitId]?.contains(key) ?? false);

  /// The properties [key] covers, from the parent context (§11.7) — never a
  /// property the document does not name.
  List<PartnerAccessProperty> propertiesCovering(String key) => properties
      .where((p) => holdsForProperty(key, p.id))
      .toList(growable: false);

  /// The caller's highest role, for labels only (§23 F3).
  PartnerTeamRole get highestRole =>
      PartnerTeamRoles.highest(grants.map((g) => g.role));

  /// True when the membership may act at all: active (or the registrant) in an
  /// approved company. Otherwise the document lists no permissions.
  bool get isActiveMembership =>
      primaryOwner || membershipStatus == PartnerMembershipStatus.active;

  /// A confirmed owner: the registrant, or a member holding owner management
  /// (P12, company-only and owner-only) without a pending confirmation.
  bool get isOwnerActor =>
      primaryOwner ||
      (!pendingOwnerConfirmation &&
          holdsAtCompany(PartnerPermissionKeys.teamOwnerManage));

  /// The property's name in the parent context, when the caller may see it.
  String? propertyName(int propertyId) {
    for (final property in properties) {
      if (property.id == propertyId) return property.name;
    }
    return null;
  }

  /// The room type's name in the parent context, when listed.
  String? unitName(int unitId) {
    for (final unit in units) {
      if (unit.id == unitId) return unit.roomName;
    }
    return null;
  }
}

Set<String> _keys(Object? raw) {
  if (raw is! List) return const {};
  return Set.unmodifiable(raw.whereType<String>());
}

Map<int, Set<String>> _byId(Object? raw) {
  if (raw is! Map) return const {};
  final out = <int, Set<String>>{};
  raw.forEach((key, value) {
    final id = int.tryParse('$key');
    if (id != null) out[id] = _keys(value);
  });
  return Map.unmodifiable(out);
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
