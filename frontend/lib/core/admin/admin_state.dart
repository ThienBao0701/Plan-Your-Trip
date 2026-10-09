import 'package:flutter/widgets.dart';

import '../app_role.dart';
import '../app_state.dart';
import '../network/api_client.dart';
import 'admin_access_models.dart';

/// Global context for the Admin CMS workspace.
///
/// A sibling of `AppState` and `PartnerState` under the same `InheritedNotifier`
/// paradigm — deliberately **not** a third state-management system, and
/// deliberately not an extension of `AppState`, which is already a large single
/// store and must not grow an admin wing.
///
/// ## What lives here, and what does not
///
/// This holds only workspace-level context: who the administrator is, which
/// shell section is active, and the session binding that clears everything on
/// logout. Row data — bookings, payments, reviews, invoices, audit entries —
/// belongs to the per-feature notifiers, exactly as the partner modules do. If
/// a list ever appears in this class, the split has been lost.
///
/// ## Session coupling
///
/// [bindSession] mirrors the partner approach: the notifier listens to
/// `AppState` and resets whenever the identity, role or demo flag changes, so
/// admin context can never outlive the account that established it. That is
/// done from the outside, without editing `AppState`.
/// RBAC R6 — where the caller's admin access document stands.
enum AdminAccessStatus {
  idle,
  loading,
  ready,

  /// `GET /api/admin/me/access` answered 403: the account holds no admin
  /// profile, so it may not use any part of the console.
  noAccess,
  error,
}

class AdminState extends ChangeNotifier {
  final ApiClient api;

  AdminState({required this.api});

  AdminAccess? _access;
  AdminAccessStatus _accessStatus = AdminAccessStatus.idle;

  /// RBAC R6 — the caller's admin profiles and permission keys, in memory
  /// only. Null until loaded.
  AdminAccess? get access => _access;

  AdminAccessStatus get accessStatus => _accessStatus;

  /// Whether the access document grants [permissionKey]. Fails closed: false
  /// while the document is missing, loading or failed. UX only — the server
  /// authorizes every request.
  bool holds(String permissionKey) => _access?.holds(permissionKey) ?? false;

  /// Loads the access document; a no-op while a load is in flight.
  Future<void> loadAccess() async {
    if (_accessStatus == AdminAccessStatus.loading) return;
    _accessStatus = AdminAccessStatus.loading;
    notifyListeners();
    final result = await api.getAdminAccess();
    if (result.success && result.data != null) {
      _access = result.data;
      _accessStatus = AdminAccessStatus.ready;
    } else {
      _access = null;
      _accessStatus = result.errorKind == ApiErrorKind.forbidden
          ? AdminAccessStatus.noAccess
          : AdminAccessStatus.error;
    }
    notifyListeners();
  }

  String? _activeRoute;
  AppState? _boundApp;
  ({String? email, bool demoMode, AppRole role})? _boundSession;

  /// Email of the signed-in administrator, mirrored from the session. Displayed
  /// in the shell so it is always obvious *which* privileged account is acting.
  String? _adminEmail;

  AppRole _role = AppRole.unknown;

  String? get adminEmail => _adminEmail;

  AppRole get role => _role;

  /// The shell's current destination route, or null before the shell mounts.
  String? get activeRoute => _activeRoute;

  /// Whether the current session may use the Admin CMS at all. UX only — the
  /// backend authorizes every `/api/admin/**` request independently.
  bool get isAdmin => _role.canEnterAdminConsole;

  void setActiveRoute(String route) {
    if (_activeRoute == route) return;
    _activeRoute = route;
    notifyListeners();
  }

  /// Mirrors this session's identity so admin context can never outlive the
  /// account that loaded it. Same contract as `PartnerState.bindSession`.
  void bindSession(AppState app) {
    if (identical(_boundApp, app)) return;
    _boundApp?.removeListener(_onSessionChanged);
    _boundApp = app;
    _boundSession = _sessionOf(app);
    _adminEmail = app.email;
    _role = app.role;
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
    _adminEmail = app.email;
    _role = app.role;
    reset();
  }

  /// Drops all workspace context. Called on any session change, and safe to
  /// call repeatedly.
  void reset() {
    _activeRoute = null;
    _access = null;
    _accessStatus = AdminAccessStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _boundApp?.removeListener(_onSessionChanged);
    _boundApp = null;
    super.dispose();
  }
}

/// Admin counterpart to `AppScope` and `PartnerScope`. Same `InheritedNotifier`
/// mechanism, a separate notifier — so an admin screen rebuilding on admin
/// context does not rebuild on unrelated traveller-app or partner changes.
class AdminScope extends InheritedNotifier<AdminState> {
  const AdminScope({
    super.key,
    required AdminState notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AdminState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminScope>();
    assert(scope != null, 'AdminScope not found');
    return scope!.notifier!;
  }

  /// Non-asserting lookup, for widgets that may render outside an admin subtree.
  static AdminState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminScope>()?.notifier;
}
