import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_failure.dart';
import '../../../core/partner/partner_access_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_team_models.dart';

/// Where the team screen's data stands.
enum PartnerTeamStatus { idle, loading, ready, unauthorized, forbidden, error }

/// The outcome of one team or invitation action.
///
/// [ignored] means the same action was already in flight, so nothing was sent
/// (no double submission). [reloaded] means the list was re-read from the server
/// because the failure showed the view was stale — a concurrent change, or an
/// item that was accepted, revoked, expired or removed elsewhere. The caller
/// decides what to tell the operator; the state never retries a write.
class PartnerTeamActionResult {
  final bool success;
  final bool ignored;
  final bool reloaded;
  final ApiFailure? failure;

  const PartnerTeamActionResult._({
    required this.success,
    this.ignored = false,
    this.reloaded = false,
    this.failure,
  });

  const PartnerTeamActionResult.succeeded() : this._(success: true);

  const PartnerTeamActionResult.ignored()
      : this._(success: false, ignored: true);

  const PartnerTeamActionResult.failed(ApiFailure failure,
      {bool reloaded = false})
      : this._(success: false, failure: failure, reloaded: reloaded);

  String? get code => failure?.code;

  /// 403 `STEP_UP_REQUIRED`: an owner-level action on a session older than 15
  /// minutes. The screen confirms the password and retries once (§23 F13).
  bool get stepUpRequired => code == PartnerTeamCodes.stepUpRequired;
}

/// The backend's stable codes this module branches on (RBAC V1.1 §26).
class PartnerTeamCodes {
  const PartnerTeamCodes._();

  static const String stepUpRequired = 'STEP_UP_REQUIRED';
  static const String concurrentModification = 'CONCURRENT_MODIFICATION';
  static const String invitationNotPending = 'INVITATION_NOT_PENDING';
}

/// RBAC R5 — UX shaping for team actions, from the access document only.
///
/// What may be *shown*: a permission held at some scope (§23 F4/F5) plus the
/// §10.3 authority table, which is not expressible as a permission (only an
/// owner manages OWNER, MANAGER and FINANCE; nobody modifies themselves; the
/// primary owner is immutable). This never authorizes anything — the backend
/// re-checks every request, and may still refuse a control shown here.
class PartnerTeamCapabilities {
  final PartnerAccess? access;

  const PartnerTeamCapabilities(this.access);

  bool _holds(String key) => access?.holdsAnywhere(key) ?? false;

  bool get canView => _holds(PartnerPermissionKeys.teamView);
  bool get canInvite => _holds(PartnerPermissionKeys.teamInvite);
  bool get canAssign => _holds(PartnerPermissionKeys.teamRoleAssign);
  bool get canSuspend => _holds(PartnerPermissionKeys.teamSuspend);
  bool get canRemove => _holds(PartnerPermissionKeys.teamRemove);

  /// A confirmed owner (the registrant, or an owner holding P12).
  bool get isOwnerActor => access?.isOwnerActor ?? false;

  /// The registrant cannot leave (O-1); anyone else with a membership may try —
  /// the server refuses the last owner.
  bool get canLeave {
    final doc = access;
    return doc != null && !doc.primaryOwner && doc.membershipId != null;
  }

  /// Roles this actor may hand out: everything for an owner, the six
  /// below-manager roles for anyone else (§10.3).
  List<PartnerTeamRole> get grantableRoles => isOwnerActor
      ? PartnerTeamRoles.all
      : PartnerTeamRoles.all
          .where((r) => !PartnerTeamRoles.ownerManaged.contains(r))
          .toList(growable: false);

  /// Whether a COMPANY grant can be offered for [permissionKey] — only to a
  /// holder at company scope: a property scope never becomes company scope.
  bool offersCompanyScope(String permissionKey) =>
      access?.holdsAtCompany(permissionKey) ?? false;

  /// The properties a grant may target for [permissionKey].
  List<PartnerAccessProperty> propertiesFor(String permissionKey) =>
      access?.propertiesCovering(permissionKey) ?? const [];

  /// Whether this actor may act on [member] with [permissionKey]. The list only
  /// holds members the caller's team view covers; the rest is §10.3.
  bool canManage(PartnerTeamMember member, String permissionKey) {
    if (!_holds(permissionKey)) return false;
    if (member.isSelf || member.primaryOwner) return false;
    if (member.status == PartnerMembershipStatus.revoked) return false;
    if (isOwnerActor) return true;
    if (member.involvesOwner) return false;
    return member.roles
        .every((role) => !PartnerTeamRoles.ownerManaged.contains(role));
  }

  /// Whether a change to [member] or to [grants] involves an owner, so the
  /// server will ask for a fresh session (O-7).
  static bool involvesOwner(
          {PartnerTeamMember? member,
          Iterable<PartnerTeamGrant> grants = const []}) =>
      (member?.involvesOwner ?? false) ||
      grants.any((g) => g.role == PartnerTeamRole.owner);
}

/// The team module's server-owned state: members (`GET /api/partner/team`) and
/// invitations (`GET /api/partner/team/invitations`).
///
/// Nothing is ever invented locally: after every successful change both lists
/// are re-read, and a failure keeps the lists exactly as they were (unless the
/// failure proves them stale, which re-reads them too). No invitation token is
/// ever held here — the backend never returns one to the team.
class PartnerTeamState extends ChangeNotifier {
  final ApiClient api;

  PartnerTeamState({required this.api});

  PartnerTeamStatus _status = PartnerTeamStatus.idle;
  List<PartnerTeamMember> _members = const [];
  List<PartnerTeamInvitation> _invitations = const [];
  bool _invitationsUnavailable = false;
  final Set<String> _busy = {};

  PartnerTeamStatus get status => _status;
  List<PartnerTeamMember> get members => _members;
  List<PartnerTeamInvitation> get invitations => _invitations;

  /// True when the member list loaded but the invitation list could not.
  bool get invitationsUnavailable => _invitationsUnavailable;

  List<PartnerTeamMember> get activeMembers => _members
      .where((m) => m.status == PartnerMembershipStatus.active)
      .toList(growable: false);

  List<PartnerTeamMember> get suspendedMembers => _members
      .where((m) => m.status == PartnerMembershipStatus.suspended)
      .toList(growable: false);

  List<PartnerTeamInvitation> get pendingInvitations =>
      _invitations.where((i) => i.isPending).toList(growable: false);

  /// Whether the action keyed [key] (e.g. `member:5`, `invitation:3`, `invite`)
  /// is in flight — its control stays disabled until it settles.
  bool isBusy(String key) => _busy.contains(key);

  static String memberKey(int id) => 'member:$id';
  static String invitationKey(int id) => 'invitation:$id';
  static const String inviteKey = 'invite';
  static const String leaveKey = 'leave';

  /// Loads both lists. A refresh keeps showing the previous data until the new
  /// answer arrives; only the first load shows the loading state.
  Future<void> load() async {
    if (_status != PartnerTeamStatus.ready) {
      _status = PartnerTeamStatus.loading;
      notifyListeners();
    }
    final results = await Future.wait([
      api.getPartnerTeamMembers(),
      api.getPartnerTeamInvitations(),
    ]);
    final membersResult =
        results[0] as CollectionApiResult<List<PartnerTeamMember>>;
    final invitationsResult =
        results[1] as CollectionApiResult<List<PartnerTeamInvitation>>;
    if (!membersResult.success) {
      _status = switch (membersResult.errorKind) {
        ApiErrorKind.unauthorized => PartnerTeamStatus.unauthorized,
        ApiErrorKind.forbidden ||
        ApiErrorKind.notFound =>
          PartnerTeamStatus.forbidden,
        _ => PartnerTeamStatus.error,
      };
      notifyListeners();
      return;
    }
    _members = List.unmodifiable(membersResult.data ?? const []);
    _invitationsUnavailable = !invitationsResult.success;
    _invitations = List.unmodifiable(invitationsResult.data ?? const []);
    _status = PartnerTeamStatus.ready;
    notifyListeners();
  }

  Future<PartnerTeamActionResult> invite(
          {required String email, required List<PartnerTeamGrant> grants}) =>
      _run(inviteKey,
          () => api.createPartnerTeamInvitation(email: email, grants: grants));

  Future<PartnerTeamActionResult> resend(PartnerTeamInvitation invitation) =>
      _run(invitationKey(invitation.id),
          () => api.resendPartnerTeamInvitation(invitation.id));

  Future<PartnerTeamActionResult> revoke(PartnerTeamInvitation invitation,
          {String? reason}) =>
      _run(invitationKey(invitation.id),
          () => api.revokePartnerTeamInvitation(invitation.id, reason: reason));

  /// Replaces [member]'s grants with the version the list showed. A stale
  /// version is refused by the server (409) and the list is re-read — the change
  /// is never resubmitted on its own.
  Future<PartnerTeamActionResult> replaceGrants(
    PartnerTeamMember member,
    List<PartnerTeamGrant> grants, {
    String? reason,
  }) {
    final version = member.version;
    if (version == null) {
      return Future.value(const PartnerTeamActionResult.failed(
          ApiFailure.of(ApiErrorKind.malformed)));
    }
    return _run(
      memberKey(member.id),
      () => api.replacePartnerTeamGrants(
          memberId: member.id,
          grants: grants,
          version: version,
          reason: reason),
    );
  }

  Future<PartnerTeamActionResult> suspend(PartnerTeamMember member,
          {String? reason}) =>
      _run(memberKey(member.id),
          () => api.suspendPartnerTeamMember(member.id, reason: reason));

  Future<PartnerTeamActionResult> reactivate(PartnerTeamMember member) => _run(
      memberKey(member.id), () => api.reactivatePartnerTeamMember(member.id));

  Future<PartnerTeamActionResult> remove(PartnerTeamMember member,
          {String? reason}) =>
      _run(memberKey(member.id),
          () => api.removePartnerTeamMember(member.id, reason: reason));

  /// Leaves the workspace. On success the caller's own access is gone, so the
  /// list is not re-read here; the shell reloads the workspace.
  Future<PartnerTeamActionResult> leave() =>
      _run(leaveKey, api.leavePartnerTeam, reload: false);

  Future<PartnerTeamActionResult> _run(
    String key,
    Future<ApiWriteResult<Object?>> Function() call, {
    bool reload = true,
  }) async {
    if (_busy.contains(key)) return const PartnerTeamActionResult.ignored();
    _busy.add(key);
    notifyListeners();
    try {
      final result = await call();
      if (result.success) {
        if (reload) await load();
        return const PartnerTeamActionResult.succeeded();
      }
      final failure = result.failure!;
      final stale = failure.code == PartnerTeamCodes.concurrentModification ||
          failure.code == PartnerTeamCodes.invitationNotPending ||
          failure.kind == ApiErrorKind.notFound ||
          failure.kind == ApiErrorKind.uncertain;
      if (stale && reload) await load();
      return PartnerTeamActionResult.failed(failure, reloaded: stale && reload);
    } finally {
      _busy.remove(key);
      notifyListeners();
    }
  }

  /// Drops every team value — on sign-out, or when the workspace is left.
  void reset() {
    _status = PartnerTeamStatus.idle;
    _members = const [];
    _invitations = const [];
    _invitationsUnavailable = false;
    _busy.clear();
    notifyListeners();
  }
}
