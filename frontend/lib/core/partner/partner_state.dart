import 'package:flutter/widgets.dart';

import '../app_role.dart';
import '../app_state.dart';
import '../network/api_client.dart';
import 'partner_access_models.dart';
import 'partner_models.dart';
import 'partner_team_models.dart';

/// Where the partner workspace stands right now. Exactly one of these is true
/// at any moment, and the UI renders one view per value — no screen has to
/// re-derive "am I allowed here" from a pile of nullable fields.
///
/// The non-`ready` values are not all errors. [onboardingRequired],
/// [awaitingApproval], [rejected] and [suspended] are legitimate points in the
/// backend's `PartnerVerificationStatus` lifecycle
/// (`DRAFT -> SUBMITTED -> APPROVED | REJECTED`, plus admin `SUSPENDED`), and
/// the client must show them as such rather than as failures.
enum PartnerWorkspaceStatus {
  /// Nothing has been requested yet.
  idle,

  /// A load is in flight.
  loading,

  /// Loaded; [PartnerState.overview] is populated.
  ready,

  /// Demo Mode. The Partner Extranet has no mock dataset and never will —
  /// fabricating partner metrics would be exactly the "fake real-mode success"
  /// the project forbids.
  demoUnavailable,

  /// The signed-in account's system role is not admitted by the backend's
  /// `/api/partner/**` rule. Fail-closed default for unknown roles.
  notPartner,

  /// Authenticated, role-admitted, but no partner profile exists yet
  /// (`GET /api/partner/profile` returned 404). The account can apply.
  onboardingRequired,

  /// A profile exists in `DRAFT` or `SUBMITTED`; an admin has not approved it.
  awaitingApproval,

  /// The profile was rejected. `PartnerProfile.rejectReason` carries why.
  rejected,

  /// An admin suspended the profile.
  suspended,

  /// RBAC R5 — the caller is a team member whose membership is suspended: the
  /// access document lists no permissions until an owner or manager reactivates
  /// it. (Since R3b the backend serves team members, so the former
  /// "team access not supported" state is retired, RBAC V1.1 §23 F10.)
  membershipSuspended,

  /// The session is not (or no longer) authenticated — HTTP 401.
  unauthorized,

  /// The backend refused the request — HTTP 403 for a reason not covered by the
  /// lifecycle states above.
  forbidden,

  /// Network failure, timeout, malformed payload, or 5xx. Retryable.
  error,
}

/// Partner-side application state.
///
/// Deliberately a **separate** `ChangeNotifier` from [AppState] rather than more
/// fields on it: `AppState` is already ~8.7k lines of traveller domains, and the
/// partner surface is a different bounded context with its own session
/// lifecycle. It is exposed through the same `InheritedNotifier` paradigm the
/// app already uses ([PartnerScope] mirrors `AppScope`), so this adds no second
/// state-management system.
///
/// It stays deliberately small: workspace identity, property scope, team role,
/// and load status. Feature modules (bookings, calendar, finance, ...) get their
/// own state as they are built — this must not grow into a second monolith.
class PartnerState extends ChangeNotifier {
  final ApiClient api;

  PartnerState({required this.api});

  PartnerWorkspaceStatus _status = PartnerWorkspaceStatus.idle;
  PartnerProfile? _profile;
  PartnerWorkspaceOverview? _overview;
  List<PartnerProperty> _properties = const [];
  int? _selectedPropertyId;
  PartnerTeamRole _teamRole = PartnerTeamRole.unknown;
  PartnerAccess? _access;
  String? _errorMessage;
  bool _propertiesUnavailable = false;

  AppState? _boundApp;
  ({String? email, bool demoMode, AppRole role})? _boundSession;

  PartnerWorkspaceStatus get status => _status;

  /// The caller's own partner profile, when they own one. Null for every status
  /// except [PartnerWorkspaceStatus.ready] and the lifecycle states.
  PartnerProfile? get profile => _profile;

  /// Dashboard counts from `GET /api/partner/extranet/home`. Non-null only when
  /// [status] is [PartnerWorkspaceStatus.ready].
  PartnerWorkspaceOverview? get overview => _overview;

  /// Properties the backend says this partner may operate. Never widened
  /// client-side.
  List<PartnerProperty> get properties => List.unmodifiable(_properties);

  /// True when the workspace loaded but the property list could not be fetched.
  /// The dashboard still renders; the property switcher shows as unavailable
  /// rather than pretending the partner owns nothing.
  bool get propertiesUnavailable => _propertiesUnavailable;

  int? get selectedPropertyId => _selectedPropertyId;

  PartnerProperty? get selectedProperty {
    final id = _selectedPropertyId;
    if (id == null) return null;
    for (final property in _properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  /// The caller's `PartnerTeamRole` within this organization. Defaults to
  /// [PartnerTeamRole.unknown], which every permission helper treats as the
  /// least-privileged case.
  PartnerTeamRole get teamRole => _teamRole;

  /// RBAC R5 — the caller's effective access (`GET /api/partner/me/access`),
  /// in memory only (§23 F2). Null when it could not be loaded, in which case
  /// every capability derived from it is absent — fail closed, never "owner"
  /// (F7).
  PartnerAccess? get access => _access;

  /// Whether the caller holds [permissionKey] at any scope (§23 F4/F5). UX
  /// shaping only — the backend decides every request.
  bool holdsAnywhere(String permissionKey) =>
      _access?.holdsAnywhere(permissionKey) ?? false;

  /// Reloads the access document — after a team change, a 403
  /// `PERMISSION_DENIED`, or an explicit refresh (§23 F8). A failure keeps the
  /// previous document rather than inventing access.
  Future<void> refreshAccess() async {
    final result = await api.getPartnerAccess();
    if (!result.success) return;
    _access = result.data;
    if (_access != null && !_access!.primaryOwner) {
      _teamRole = _access!.highestRole;
    }
    notifyListeners();
  }

  /// Server-supplied message for the current failure, when one was safe to
  /// surface. Null otherwise.
  String? get errorMessage => _errorMessage;

  /// True when [status] is a retryable failure rather than a lifecycle state.
  bool get isRetryable =>
      _status == PartnerWorkspaceStatus.error ||
      _status == PartnerWorkspaceStatus.forbidden;

  bool get isReady => _status == PartnerWorkspaceStatus.ready;

  /// Mirrors this session's identity so partner data can never outlive the
  /// account that loaded it. `AppState` clears every `real*` field on
  /// logout/mode/user change for exactly this reason; partner state follows the
  /// same rule from the outside, without editing `AppState`.
  void bindSession(AppState app) {
    if (identical(_boundApp, app)) return;
    _boundApp?.removeListener(_onSessionChanged);
    _boundApp = app;
    _boundSession = _sessionOf(app);
    app.addListener(_onSessionChanged);
  }

  ({String? email, bool demoMode, AppRole role}) _sessionOf(AppState app) =>
      (email: app.email, demoMode: app.demoMode, role: app.role);

  void _onSessionChanged() {
    final app = _boundApp;
    if (app == null) return;
    final current = _sessionOf(app);
    if (current == _boundSession) return;
    _boundSession = current;
    reset();
  }

  /// Loads the partner workspace for [app]'s session.
  ///
  /// Resolution order, and why:
  ///   1. Demo Mode short-circuits — there is no partner mock data.
  ///   2. Role gate mirrors `SecurityConfig` (`PARTNER` or `ADMIN`). Unknown
  ///      roles fail closed.
  ///   3. `GET /api/partner/profile` decides the lifecycle branch. A 404 means
  ///      "no owned profile", which is either onboarding or a team membership —
  ///      step 4 disambiguates.
  ///   4. On 404, `GET /api/partner/team` distinguishes a genuine newcomer from
  ///      a team member whose org the extranet endpoints cannot serve.
  ///   5. Approved owners load the overview (required) plus properties and team
  ///      role (both best-effort — neither is worth failing the workspace for).
  Future<void> loadWorkspace(AppState app) async {
    if (_status == PartnerWorkspaceStatus.loading) return;

    if (app.demoMode) {
      _finish(PartnerWorkspaceStatus.demoUnavailable);
      return;
    }
    if (!app.role.canEnterPartnerExtranet) {
      _finish(PartnerWorkspaceStatus.notPartner);
      return;
    }

    _status = PartnerWorkspaceStatus.loading;
    _errorMessage = null;
    notifyListeners();

    final profileResult = await api.getPartnerProfile();
    if (!profileResult.success) {
      if (profileResult.errorKind == ApiErrorKind.notFound) {
        await _resolveWithoutOwnedProfile();
        return;
      }
      _finishFailure(profileResult.errorKind, profileResult.message);
      return;
    }

    final profile = profileResult.data!;
    _profile = profile;

    switch (profile.verificationStatus) {
      case PartnerVerificationStatus.draft:
      case PartnerVerificationStatus.submitted:
        _finish(PartnerWorkspaceStatus.awaitingApproval);
        return;
      case PartnerVerificationStatus.rejected:
        _finish(PartnerWorkspaceStatus.rejected);
        return;
      case PartnerVerificationStatus.suspended:
        _finish(PartnerWorkspaceStatus.suspended);
        return;
      case PartnerVerificationStatus.unknown:
        // An unrecognised lifecycle value must not be optimistically treated as
        // approved.
        _finish(PartnerWorkspaceStatus.forbidden);
        return;
      case PartnerVerificationStatus.approved:
        break;
    }

    // The profile owner is always OWNER as far as the backend is concerned
    // (`PartnerSettingsService.resolveAccess` returns OWNER unconditionally for
    // the profile's own user), so this needs no extra request.
    _teamRole = PartnerTeamRole.owner;

    // RBAC R5 — the access document shapes team affordances. Best-effort for
    // the registrant, who holds every permission server-side anyway: if it
    // cannot be read, those affordances stay hidden (fail closed, §23 F7).
    final accessResult = await api.getPartnerAccess();
    _access = accessResult.success ? accessResult.data : null;

    await _loadOperationalData();
  }

  /// The overview (required) and the property list (best-effort), shared by the
  /// registrant and by an active team member.
  Future<void> _loadOperationalData() async {
    final overviewResult = await api.getPartnerWorkspaceOverview();
    if (!overviewResult.success) {
      _finishFailure(overviewResult.errorKind, overviewResult.message);
      return;
    }
    _overview = overviewResult.data;

    final propertiesResult = await api.getPartnerProperties();
    if (propertiesResult.success) {
      _properties = propertiesResult.data ?? const [];
      _propertiesUnavailable = false;
      _selectedPropertyId = _properties.isEmpty ? null : _properties.first.id;
    } else {
      _properties = const [];
      _selectedPropertyId = null;
      _propertiesUnavailable = true;
    }

    _finish(PartnerWorkspaceStatus.ready);
  }

  /// A 404 from `GET /api/partner/profile` means the caller registered no
  /// company. RBAC R5: the access document (§25.2) says whether they are a team
  /// member, of which workspace, in which state, and with which permissions —
  /// a 404 there is a genuine newcomer.
  Future<void> _resolveWithoutOwnedProfile() async {
    final accessResult = await api.getPartnerAccess();
    if (!accessResult.success) {
      if (accessResult.errorKind == ApiErrorKind.notFound) {
        _finish(PartnerWorkspaceStatus.onboardingRequired);
        return;
      }
      _finishFailure(accessResult.errorKind, accessResult.message);
      return;
    }
    final access = accessResult.data!;
    _access = access;
    _teamRole = access.highestRole;

    switch (access.verificationStatus) {
      case PartnerVerificationStatus.approved:
        break;
      case PartnerVerificationStatus.suspended:
        _finish(PartnerWorkspaceStatus.suspended);
        return;
      default:
        // Not a company this member can work in yet; never treated as approved.
        _finish(PartnerWorkspaceStatus.forbidden);
        return;
    }
    if (access.membershipStatus == PartnerMembershipStatus.suspended) {
      _finish(PartnerWorkspaceStatus.membershipSuspended);
      return;
    }
    if (access.membershipStatus != PartnerMembershipStatus.active) {
      _finish(PartnerWorkspaceStatus.forbidden);
      return;
    }
    await _loadOperationalData();
  }

  /// Selects the property whose data later modules will operate on. Ignores ids
  /// the backend did not authorize — the client never invents scope.
  void selectProperty(int propertyId) {
    if (_selectedPropertyId == propertyId) return;
    final authorized = _properties.any((p) => p.id == propertyId);
    if (!authorized) return;
    _selectedPropertyId = propertyId;
    notifyListeners();
  }

  /// Republishes the authorized property list from a fresh
  /// `GET /api/partner/hotels` (C2's Properties module reloads it whenever that
  /// screen is opened or refreshed).
  ///
  /// This is the single, controlled way the list is replaced after the initial
  /// workspace load, so property scope keeps exactly one owner. Two invariants
  /// are enforced here rather than at each call site:
  ///
  ///  * a selection that is no longer in the authorized list is **dropped**, so
  ///    a property removed or unassigned server-side cannot linger as stale
  ///    scope for a later module;
  ///  * when nothing is selected and exactly one property exists, it becomes
  ///    the selection — a single-property partner should never have to pick.
  void replaceProperties(List<PartnerProperty> properties) {
    _properties = List.unmodifiable(properties);
    _propertiesUnavailable = false;

    final selected = _selectedPropertyId;
    if (selected != null && !properties.any((p) => p.id == selected)) {
      _selectedPropertyId = null;
    }
    if (_selectedPropertyId == null && properties.length == 1) {
      _selectedPropertyId = properties.first.id;
    }
    notifyListeners();
  }

  /// Clears the property selection without touching the authorized list — used
  /// when the workspace widens back to "all properties".
  void clearSelectedProperty() {
    if (_selectedPropertyId == null) return;
    _selectedPropertyId = null;
    notifyListeners();
  }

  /// Drops every partner value. Called on any session identity change and
  /// whenever the workspace is left.
  void reset() {
    _status = PartnerWorkspaceStatus.idle;
    _profile = null;
    _overview = null;
    _properties = const [];
    _selectedPropertyId = null;
    _teamRole = PartnerTeamRole.unknown;
    _access = null;
    _errorMessage = null;
    _propertiesUnavailable = false;
    notifyListeners();
  }

  void _finish(PartnerWorkspaceStatus status) {
    _status = status;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishFailure(ApiErrorKind? kind, String? message) {
    _status = switch (kind) {
      ApiErrorKind.unauthorized => PartnerWorkspaceStatus.unauthorized,
      ApiErrorKind.forbidden => PartnerWorkspaceStatus.forbidden,
      _ => PartnerWorkspaceStatus.error,
    };
    _errorMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _boundApp?.removeListener(_onSessionChanged);
    _boundApp = null;
    super.dispose();
  }
}

/// Partner counterpart to `AppScope`. Same `InheritedNotifier` mechanism, a
/// separate notifier — so a partner screen rebuilding on partner data does not
/// rebuild on unrelated traveller-app changes, and vice versa.
class PartnerScope extends InheritedNotifier<PartnerState> {
  const PartnerScope({
    super.key,
    required PartnerState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static PartnerState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PartnerScope>();
    assert(scope != null, 'PartnerScope not found');
    return scope!.notifier!;
  }

  /// Non-asserting lookup, for widgets that may render outside a partner
  /// subtree.
  static PartnerState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PartnerScope>()?.notifier;
}
