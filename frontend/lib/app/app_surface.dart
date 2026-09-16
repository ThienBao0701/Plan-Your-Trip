import '../core/app_role.dart';

/// The three independently served web applications built from this codebase.
///
/// One Flutter codebase builds three applications — the traveller app, the
/// Partner workspace and the Admin console. Each runs on its own origin (a port
/// in local development, its own domain in production) and admits exactly one
/// role family. See `docs/APP_SURFACES.md`.
///
/// A surface is **product separation, not authorization.** The backend still
/// authorizes every request against the JWT. The surface decides only which
/// shell an origin may show, and it fails closed for everything else: an
/// unknown role, an unknown `APP_SURFACE` value or a missing surface never
/// falls back to the traveller app.
enum AppSurface {
  user('user'),
  partner('partner'),
  admin('admin');

  const AppSurface(this.id);

  /// The value accepted by `--dart-define=APP_SURFACE=...`.
  final String id;

  /// The build-time define that selects a surface for `lib/main.dart`.
  static const String environmentKey = 'APP_SURFACE';

  static const bool _hasEnvironmentValue = bool.hasEnvironment(environmentKey);
  static const String _environmentValue =
      String.fromEnvironment(environmentKey);

  /// Parses an `APP_SURFACE` value. Exact and case-sensitive; anything else is
  /// null so the caller can refuse to boot rather than guess a surface.
  static AppSurface? parse(String? raw) {
    for (final surface in values) {
      if (surface.id == raw) return surface;
    }
    return null;
  }

  /// The surface named by `APP_SURFACE`, or [fallback] when the define is
  /// absent. A define that is present but not one of the three ids is null — a
  /// misconfiguration, not a reason to boot the fallback.
  static AppSurface? fromEnvironment({required AppSurface fallback}) =>
      _hasEnvironmentValue ? parse(_environmentValue) : fallback;

  /// Whether a signed-in account of [role] may use this surface.
  ///
  /// Exactly one role family per surface, and [AppRole.unknown] is admitted
  /// nowhere. This is stricter than the backend's URL rule for
  /// `/api/partner/**` (which also admits `ADMIN`): an administrator has no
  /// partner profile, so the Partner workspace is not an administrator's
  /// application. The backend still decides every individual request.
  bool admits(AppRole role) => switch (this) {
        AppSurface.user => role == AppRole.user,
        AppSurface.partner => role == AppRole.partner,
        AppSurface.admin => role == AppRole.admin,
      };

  /// Demo Mode signs in the local traveller demo account, whose role is `USER`
  /// (`ApiClient.login`). There is no partner or admin mock data, and inventing
  /// a demo partner or administrator would fabricate authorization, so only the
  /// traveller app offers it.
  bool get offersDemoMode => this == AppSurface.user;

  /// Self sign-up creates a `USER` account, which only the traveller app
  /// admits. Partner and administrator accounts are never self-created.
  bool get offersSelfRegistration => this == AppSurface.user;

  /// The public origin of this surface when one is configured — for example
  /// `--dart-define=PARTNER_APP_URL=https://partner.planyourtrip.com` — or null.
  ///
  /// Nothing in V1 links across surfaces; this is the single place a future
  /// cross-surface workflow reads an origin from, so no screen ever names a
  /// host.
  String? get publicUrl {
    final value = switch (this) {
      AppSurface.user => const String.fromEnvironment('USER_APP_URL'),
      AppSurface.partner => const String.fromEnvironment('PARTNER_APP_URL'),
      AppSurface.admin => const String.fromEnvironment('ADMIN_APP_URL'),
    };
    return value.isEmpty ? null : value;
  }
}
