/// The three system roles modelled by the backend (`User.role`, a single
/// free-text column defaulting to `"USER"`). `security/JwtAuthenticationFilter`
/// grants exactly one authority per user — `"ROLE_" + user.getRole()` — so
/// there is no role hierarchy and no multi-role assignment.
///
/// `SUPER_ADMIN` and `SUPER_PARTNER` are deliberately **not** modelled here.
/// They have no source truth in the backend (see
/// `Plan-Your-Trip-backend-v1/ROLE_UI_PERMISSION_FREEZE.md` §A) and must not be
/// invented on the client. Any value the client does not recognise — including
/// those two names, a lower-cased variant, or a null — parses to
/// [AppRole.unknown], which is treated as *no* elevated access anywhere in the
/// app (fail closed).
///
/// **This enum is UX routing only.** The backend remains the sole authority for
/// authorization: `/api/admin/**` requires `ROLE_ADMIN`, `/api/partner/**`
/// requires `ROLE_PARTNER` or `ROLE_ADMIN`, and every partner controller
/// additionally self-scopes by identity. Hiding a control on the client is not
/// authorization.
enum AppRole {
  user,
  partner,
  admin,
  unknown;

  /// Parses the backend's `UserDto.role` string. Matching is exact and
  /// case-sensitive because the backend writes these literals verbatim
  /// (`"USER"`, `"PARTNER"`, `"ADMIN"` — see `DataInitializer` and
  /// `PartnerProfileService.adminApprove`). Anything else fails closed.
  static AppRole parse(Object? raw) {
    if (raw is! String) return AppRole.unknown;
    switch (raw) {
      case 'USER':
        return AppRole.user;
      case 'PARTNER':
        return AppRole.partner;
      case 'ADMIN':
        return AppRole.admin;
      default:
        return AppRole.unknown;
    }
  }

  /// The wire value, for persistence. [AppRole.unknown] persists as `null` so a
  /// restored session never re-materialises an unrecognised role as if it were
  /// meaningful.
  String? get wireValue => switch (this) {
        AppRole.user => 'USER',
        AppRole.partner => 'PARTNER',
        AppRole.admin => 'ADMIN',
        AppRole.unknown => null,
      };

  /// Whether the backend's URL rule for `/api/partner/**`
  /// (`hasAnyRole("PARTNER", "ADMIN")`) would admit this role. Mirrors
  /// `SecurityConfig` exactly rather than inventing a stricter or looser client
  /// rule; the server still decides every individual request.
  bool get canEnterPartnerExtranet =>
      this == AppRole.partner || this == AppRole.admin;

  /// Whether the Partner Extranet is this role's *default* landing surface.
  /// Only `PARTNER`. An `ADMIN` may reach partner routes (above), but partner
  /// controllers resolve `partnerProfileRepo.findByUserId(uid)`, so an admin
  /// normally has no partner profile and would land on an empty workspace —
  /// admins keep the traveller app as their default surface.
  bool get landsOnPartnerExtranet => this == AppRole.partner;
}
