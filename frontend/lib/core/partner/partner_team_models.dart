/// RBAC R5 — the partner team and invitation contract of the R4 backend,
/// mapped from `dto/PartnerSettingsDto` (members, grants) and
/// `dto/PartnerInvitationDto` (invitations).
///
/// Nothing here decides what a caller may do. The role/scope table below is the
/// backend's own grant vocabulary (RBAC V1.1 §11.3, enforced by
/// `PartnerRoleScopes` and the `ck_partner_member_grants_role_scope` CHECK), used
/// only so a form never offers a combination the server always refuses. Every
/// request is still validated server-side.
///
/// No model in this file carries an invitation token: the backend never returns
/// one, and the management screens never handle one.
library;

import 'partner_account_models.dart';
import 'partner_models.dart';

/// `security/rbac/ScopeType` — where a grant applies.
enum PartnerScopeType {
  company,
  property,
  unit,
  unknown;

  static PartnerScopeType parse(Object? raw) => switch (raw) {
        'COMPANY' => PartnerScopeType.company,
        'PROPERTY' => PartnerScopeType.property,
        'UNIT' => PartnerScopeType.unit,
        _ => PartnerScopeType.unknown,
      };

  String? get wire => switch (this) {
        PartnerScopeType.company => 'COMPANY',
        PartnerScopeType.property => 'PROPERTY',
        PartnerScopeType.unit => 'UNIT',
        PartnerScopeType.unknown => null,
      };
}

/// A scope written `TYPE:id` (`ScopeRef`), e.g. `COMPANY:7`, `PROPERTY:12`,
/// `UNIT:31`. Parsing is as strict as the server's: anything else is no scope.
class PartnerScopeRef {
  final PartnerScopeType type;
  final int id;

  const PartnerScopeRef(this.type, this.id);

  static final RegExp _format =
      RegExp(r'^(COMPANY|PROPERTY|UNIT):([1-9][0-9]{0,18})$');

  static PartnerScopeRef? parse(Object? raw) {
    if (raw is! String) return null;
    final match = _format.firstMatch(raw);
    if (match == null) return null;
    final id = int.tryParse(match.group(2)!);
    if (id == null) return null;
    return PartnerScopeRef(PartnerScopeType.parse(match.group(1)), id);
  }

  String get wire => '${type.wire}:$id';

  @override
  bool operator ==(Object other) =>
      other is PartnerScopeRef && other.type == type && other.id == id;

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => wire;
}

/// One grant: a role at a scope (`PartnerTeamGrantView` / `PartnerTeamGrantItem`).
class PartnerTeamGrant {
  final PartnerTeamRole role;
  final PartnerScopeRef scope;

  const PartnerTeamGrant({required this.role, required this.scope});

  static PartnerTeamGrant? fromJson(Map<String, dynamic> json) {
    final scope = PartnerScopeRef.parse(json['scope']);
    if (scope == null) return null;
    return PartnerTeamGrant(
        role: PartnerTeamRole.parse(json['role']), scope: scope);
  }

  /// The request item, or null when the role is unknown — which can never be
  /// sent.
  Map<String, dynamic>? toJson() {
    final role = partnerTeamRoleWire(this.role);
    if (role == null) return null;
    return {'role': role, 'scope': scope.wire};
  }

  @override
  bool operator ==(Object other) =>
      other is PartnerTeamGrant && other.role == role && other.scope == scope;

  @override
  int get hashCode => Object.hash(role, scope);
}

/// `model/PartnerMembershipStatus`.
enum PartnerMembershipStatus {
  active,
  suspended,
  revoked,
  unknown;

  static PartnerMembershipStatus parse(Object? raw) => switch (raw) {
        'ACTIVE' => PartnerMembershipStatus.active,
        'SUSPENDED' => PartnerMembershipStatus.suspended,
        'REVOKED' => PartnerMembershipStatus.revoked,
        _ => PartnerMembershipStatus.unknown,
      };
}

/// The grant vocabulary of RBAC V1.1 — no authority is derived from it.
class PartnerTeamRoles {
  const PartnerTeamRoles._();

  /// Every role a grant can carry, in the backend's declaration order.
  static const List<PartnerTeamRole> all = [
    PartnerTeamRole.owner,
    PartnerTeamRole.manager,
    PartnerTeamRole.revenue,
    PartnerTeamRole.reservations,
    PartnerTeamRole.frontDesk,
    PartnerTeamRole.finance,
    PartnerTeamRole.content,
    PartnerTeamRole.housekeeping,
    PartnerTeamRole.viewer,
  ];

  /// The roles only an owner may grant or manage (§10.3 columns OWNER, MANAGER,
  /// FINANCE). A manager is offered the rest; the server enforces both.
  static const Set<PartnerTeamRole> ownerManaged = {
    PartnerTeamRole.owner,
    PartnerTeamRole.manager,
    PartnerTeamRole.finance,
  };

  /// §11.3 — the scope types a role may sit at.
  static Set<PartnerScopeType> scopesFor(PartnerTeamRole role) =>
      switch (role) {
        PartnerTeamRole.owner || PartnerTeamRole.finance => const {
            PartnerScopeType.company
          },
        PartnerTeamRole.housekeeping => const {
            PartnerScopeType.property,
            PartnerScopeType.unit
          },
        PartnerTeamRole.unknown => const {},
        _ => const {PartnerScopeType.company, PartnerScopeType.property},
      };

  /// Highest authority first (§10.3): a membership is held at its highest role.
  static PartnerTeamRole highest(Iterable<PartnerTeamRole> roles) {
    PartnerTeamRole? best;
    for (final role in roles) {
      final index = all.indexOf(role);
      if (index < 0) continue;
      if (best == null || index < all.indexOf(best)) best = role;
    }
    return best ?? PartnerTeamRole.unknown;
  }
}

/// `model/PartnerInvitationStatus`, with the list's computed `EXPIRED` for a
/// pending invitation past its expiry.
enum PartnerInvitationStatus {
  pending,
  accepted,
  declined,
  revoked,
  expired,
  unknown;

  static PartnerInvitationStatus parse(Object? raw) => switch (raw) {
        'PENDING' => PartnerInvitationStatus.pending,
        'ACCEPTED' => PartnerInvitationStatus.accepted,
        'DECLINED' => PartnerInvitationStatus.declined,
        'REVOKED' => PartnerInvitationStatus.revoked,
        'EXPIRED' => PartnerInvitationStatus.expired,
        _ => PartnerInvitationStatus.unknown,
      };
}

/// `model/PartnerInvitationDeliveryStatus` — the outcome of the latest send.
/// `QUEUED` is "not confirmed yet": the email goes out after the invitation
/// commits, so a 202 never means it was delivered.
enum PartnerInvitationDelivery {
  queued,
  sent,
  failed,
  unknown;

  static PartnerInvitationDelivery parse(Object? raw) => switch (raw) {
        'QUEUED' => PartnerInvitationDelivery.queued,
        'SENT' => PartnerInvitationDelivery.sent,
        'FAILED' => PartnerInvitationDelivery.failed,
        _ => PartnerInvitationDelivery.unknown,
      };
}

/// `PartnerInvitationDto.InvitationView` — one invitation as the team sees it.
class PartnerTeamInvitation {
  /// Backend limits (RBAC V1.1 §31 Q16), shown to the operator; the server
  /// enforces them and answers 429 `INVITATION_RATE_LIMITED`.
  static const int maxResends = 5;
  static const Duration resendCooldown = Duration(seconds: 60);
  static const int maxPendingPerCompany = 20;
  static const Duration lifetime = Duration(days: 7);

  final int id;
  final String email;
  final List<PartnerTeamGrant> grants;
  final PartnerInvitationStatus status;
  final String? statusReason;
  final PartnerInvitationDelivery delivery;
  final DateTime? expiresAt;
  final int resendCount;
  final DateTime? lastSentAt;
  final int? invitedByUserId;
  final String? invitedByName;
  final DateTime? createdAt;

  const PartnerTeamInvitation({
    required this.id,
    required this.email,
    required this.grants,
    required this.status,
    this.statusReason,
    required this.delivery,
    this.expiresAt,
    this.resendCount = 0,
    this.lastSentAt,
    this.invitedByUserId,
    this.invitedByName,
    this.createdAt,
  });

  static PartnerTeamInvitation? fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    final email = _string(json['email']);
    if (id == null || email == null) return null;
    return PartnerTeamInvitation(
      id: id,
      email: email,
      grants: _grants(json['grants']),
      status: PartnerInvitationStatus.parse(json['status']),
      statusReason: _string(json['statusReason']),
      delivery: PartnerInvitationDelivery.parse(json['deliveryStatus']),
      expiresAt: _date(json['expiresAt']),
      resendCount: _int(json['resendCount']) ?? 0,
      lastSentAt: _date(json['lastSentAt']),
      invitedByUserId: _int(json['invitedByUserId']),
      invitedByName: _string(json['invitedByName']),
      createdAt: _date(json['createdAt']),
    );
  }

  bool get isPending => status == PartnerInvitationStatus.pending;

  bool get resendLimitReached => resendCount >= maxResends;

  /// When the 60 s cooldown since the last send ends — a hint for the button;
  /// the server's clock decides.
  DateTime? get resendAvailableAt => lastSentAt?.add(resendCooldown);
}

/// One grant of an invitation addressed to the caller
/// (`PartnerInvitationDto.MyInvitationGrant`).
class PartnerMyInvitationGrant {
  final PartnerTeamRole role;
  final PartnerScopeType scopeType;
  final String? scopeName;

  const PartnerMyInvitationGrant(
      {required this.role, required this.scopeType, this.scopeName});
}

/// `PartnerInvitationDto.MyInvitationView` — `GET /api/me/partner-invitations`.
/// It names the company and the grants, never the token: accepting needs the
/// emailed link.
class PartnerMyInvitation {
  final int id;
  final int? companyId;
  final String companyName;
  final List<PartnerMyInvitationGrant> grants;
  final DateTime? expiresAt;

  const PartnerMyInvitation({
    required this.id,
    this.companyId,
    required this.companyName,
    required this.grants,
    this.expiresAt,
  });

  static PartnerMyInvitation? fromJson(Map<String, dynamic> json) {
    final id = _int(json['id']);
    if (id == null) return null;
    final grants = <PartnerMyInvitationGrant>[];
    final raw = json['grants'];
    if (raw is List) {
      for (final entry in raw) {
        if (entry is! Map<String, dynamic>) continue;
        grants.add(PartnerMyInvitationGrant(
          role: PartnerTeamRole.parse(entry['role']),
          scopeType: PartnerScopeType.parse(entry['scopeType']),
          scopeName: _string(entry['scopeName']),
        ));
      }
    }
    return PartnerMyInvitation(
      id: id,
      companyId: _int(json['companyId']),
      companyName: _string(json['companyName']) ?? '',
      grants: grants,
      expiresAt: _date(json['expiresAt']),
    );
  }
}

List<PartnerTeamGrant> parsePartnerTeamGrants(Object? raw) => _grants(raw);

List<PartnerTeamGrant> _grants(Object? raw) {
  if (raw is! List) return const [];
  final grants = <PartnerTeamGrant>[];
  for (final entry in raw) {
    if (entry is! Map<String, dynamic>) continue;
    final grant = PartnerTeamGrant.fromJson(entry);
    if (grant != null) grants.add(grant);
  }
  return List.unmodifiable(grants);
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

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
