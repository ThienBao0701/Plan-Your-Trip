/// RBAC R6 — the admin access document and access management
/// (`GET /api/admin/me/access`, `GET /api/admin/access/admins`,
/// `PUT /api/admin/access/admins/{userId}/profiles`; RBAC V1.1 §7, §25.4).
///
/// The console renders from these; it never decides access. Every
/// `/api/admin/**` request is still authorized by the server, so hiding a
/// destination here is a convenience, not a control.
library;

/// The admin permission keys the console reads (RBAC V1.1 §9.2). Only keys
/// that gate a destination or a control are named here.
class AdminPermissionKeys {
  const AdminPermissionKeys._();

  static const consoleAccess = 'admin.console.access';
  static const accessManage = 'admin.access.manage';
  static const auditLogView = 'admin.audit_log.view';
  static const analyticsView = 'admin.analytics.view';
  static const customerView = 'admin.customer.view';
  static const partnerView = 'admin.partner.view';
  static const placeView = 'admin.place.view';
  static const mediaManage = 'admin.media.manage';
  static const bookingView = 'admin.booking.view';
  static const paymentView = 'admin.payment.view';
  static const invoiceView = 'admin.invoice.view';
  static const reviewView = 'admin.review.view';
}

/// The 11 admin profiles of RBAC V1.1 §7, in the matrix's column order.
/// [unknown] stands for any value this build does not know: it is shown as
/// such and never sent back.
enum AdminProfile {
  platformOwner('PLATFORM_OWNER'),
  partnerOperations('PARTNER_OPERATIONS'),
  contentCatalogue('CONTENT_CATALOGUE'),
  bookingSupport('BOOKING_SUPPORT'),
  financeOperations('FINANCE_OPERATIONS'),
  growthMarketing('GROWTH_MARKETING'),
  trustSafety('TRUST_SAFETY'),
  reviewModeration('REVIEW_MODERATION'),
  analytics('ANALYTICS'),
  locationCatalogue('LOCATION_CATALOGUE'),
  techSupport('TECH_SUPPORT'),
  unknown('');

  final String wire;
  const AdminProfile(this.wire);

  /// Every profile an administrator can be given, in display order.
  static const List<AdminProfile> assignable = [
    platformOwner,
    partnerOperations,
    contentCatalogue,
    bookingSupport,
    financeOperations,
    growthMarketing,
    trustSafety,
    reviewModeration,
    analytics,
    locationCatalogue,
    techSupport,
  ];

  static AdminProfile parse(Object? value) {
    if (value is! String) return unknown;
    for (final p in assignable) {
      if (p.wire == value) return p;
    }
    return unknown;
  }
}

List<AdminProfile> _profiles(Object? raw) {
  if (raw is! List) return const [];
  return [for (final v in raw) AdminProfile.parse(v)];
}

/// `GET /api/admin/me/access` — the caller's profiles and active admin
/// permission keys. Held in memory only, like the partner access document.
class AdminAccess {
  final int userId;
  final String? email;
  final List<AdminProfile> profiles;
  final Set<String> permissions;

  /// Until when the current session counts as fresh for step-up actions.
  final DateTime? freshUntil;

  const AdminAccess({
    required this.userId,
    this.email,
    required this.profiles,
    required this.permissions,
    this.freshUntil,
  });

  bool holds(String permissionKey) => permissions.contains(permissionKey);

  bool get isPlatformOwner => profiles.contains(AdminProfile.platformOwner);

  /// Null when the document has no user id (malformed).
  static AdminAccess? fromJson(Map<String, dynamic> json) {
    final id = json['userId'];
    if (id is! num) return null;
    final rawPermissions = json['permissions'];
    final stepUp = json['stepUp'];
    final fresh = stepUp is Map ? stepUp['freshUntil'] : null;
    return AdminAccess(
      userId: id.toInt(),
      email: json['email'] is String ? json['email'] as String : null,
      profiles: _profiles(json['profiles']),
      permissions: {
        if (rawPermissions is List)
          for (final p in rawPermissions)
            if (p is String) p,
      },
      freshUntil: fresh is String ? DateTime.tryParse(fresh)?.toLocal() : null,
    );
  }
}

/// One administrator in `GET /api/admin/access/admins`, and the result of a
/// profile change.
class AdminAccount {
  final int userId;
  final String fullName;
  final String email;
  final bool enabled;

  /// The signed-in administrator — whose own profiles cannot be changed (AP-1).
  final bool self;
  final List<AdminProfile> profiles;

  const AdminAccount({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.enabled,
    required this.self,
    required this.profiles,
  });

  static AdminAccount? fromJson(Map<String, dynamic> json) {
    final id = json['userId'];
    if (id is! num) return null;
    return AdminAccount(
      userId: id.toInt(),
      fullName: json['fullName'] is String ? json['fullName'] as String : '',
      email: json['email'] is String ? json['email'] as String : '',
      enabled: json['enabled'] != false,
      self: json['self'] == true,
      profiles: _profiles(json['profiles']),
    );
  }
}
