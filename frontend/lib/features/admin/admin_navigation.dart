import 'package:flutter/material.dart';

import '../../core/admin/admin_access_models.dart';
import '../../l10n/app_localizations.dart';

/// Sidebar grouping. The Admin CMS is information-dense, so destinations are
/// grouped rather than presented as one flat list.
enum AdminSection {
  overview,
  operations,
  catalog,
  finance,
  community,
  audit,
  access
}

/// One destination in the Admin CMS shell.
///
/// Every entry here corresponds to a backend surface that exists **and** is
/// paginated as of `develop@92a009a`. Nothing speculative is listed: D0 found
/// 16 admin collections still returning unbounded lists, and putting a
/// destination in this menu before its endpoint is ready would mean building a
/// grid against a contract that is about to change.
class AdminDestination {
  final String route;
  final AdminSection section;
  final IconData icon;

  /// Resolves the localized label. Held as a function rather than a string so
  /// the menu is built once and still follows a locale change.
  final String Function(AppLocalizations) label;

  /// RBAC R6 — the admin permission key the destination's own read needs
  /// (§9.2). The shell lists a destination only when the access document
  /// grants it; the server still authorizes every request.
  final String requiresPermission;

  const AdminDestination({
    required this.route,
    required this.section,
    required this.icon,
    required this.label,
    required this.requiresPermission,
  });
}

/// The Admin CMS menu.
///
/// Deliberately six entries. The D0 information-architecture hypothesis listed
/// Catalog, Commercial, Partners, Customers and System as well; those are
/// excluded because their endpoints are either unpaginated, absent (there is no
/// admin user list or role-change API at all), or out of D1b's stated scope.
class AdminNavigation {
  const AdminNavigation._();

  static const List<AdminDestination> destinations = [
    AdminDestination(
      route: AdminRoutesRefs.dashboard,
      requiresPermission: AdminPermissionKeys.analyticsView,
      section: AdminSection.overview,
      icon: Icons.dashboard_outlined,
      label: _dashboard,
    ),
    AdminDestination(
      route: AdminRoutesRefs.bookings,
      requiresPermission: AdminPermissionKeys.bookingView,
      section: AdminSection.operations,
      icon: Icons.event_note_outlined,
      label: _bookings,
    ),
    AdminDestination(
      route: AdminRoutesRefs.partners,
      requiresPermission: AdminPermissionKeys.partnerView,
      section: AdminSection.operations,
      icon: Icons.storefront_outlined,
      label: _partners,
    ),
    AdminDestination(
      route: AdminRoutesRefs.catalog,
      requiresPermission: AdminPermissionKeys.placeView,
      section: AdminSection.catalog,
      icon: Icons.place_outlined,
      label: _catalog,
    ),
    AdminDestination(
      route: AdminRoutesRefs.media,
      requiresPermission: AdminPermissionKeys.mediaManage,
      section: AdminSection.catalog,
      icon: Icons.photo_library_outlined,
      label: _media,
    ),
    AdminDestination(
      route: AdminRoutesRefs.referenceData,
      requiresPermission: AdminPermissionKeys.consoleAccess,
      section: AdminSection.catalog,
      icon: Icons.category_outlined,
      label: _referenceData,
    ),
    AdminDestination(
      route: AdminRoutesRefs.payments,
      requiresPermission: AdminPermissionKeys.paymentView,
      section: AdminSection.finance,
      icon: Icons.payments_outlined,
      label: _payments,
    ),
    AdminDestination(
      route: AdminRoutesRefs.invoices,
      requiresPermission: AdminPermissionKeys.invoiceView,
      section: AdminSection.finance,
      icon: Icons.receipt_long_outlined,
      label: _invoices,
    ),
    AdminDestination(
      route: AdminRoutesRefs.reviews,
      requiresPermission: AdminPermissionKeys.reviewView,
      section: AdminSection.community,
      icon: Icons.rate_review_outlined,
      label: _reviews,
    ),
    AdminDestination(
      route: AdminRoutesRefs.activityLog,
      requiresPermission: AdminPermissionKeys.auditLogView,
      section: AdminSection.audit,
      icon: Icons.history_outlined,
      label: _activityLog,
    ),
    // RBAC R6 — administrators and their profiles (PLATFORM_OWNER only).
    AdminDestination(
      route: AdminRoutesRefs.access,
      requiresPermission: AdminPermissionKeys.accessManage,
      section: AdminSection.access,
      icon: Icons.admin_panel_settings_outlined,
      label: _access,
    ),
  ];

  static AdminDestination? byRoute(String route) {
    for (final d in destinations) {
      if (d.route == route) return d;
    }
    return null;
  }

  static List<AdminDestination> inSection(AdminSection section) =>
      destinations.where((d) => d.section == section).toList(growable: false);

  /// Sections that actually contain at least one destination, in menu order.
  static List<AdminSection> get populatedSections {
    final seen = <AdminSection>[];
    for (final d in destinations) {
      if (!seen.contains(d.section)) seen.add(d.section);
    }
    return seen;
  }

  static String sectionLabel(AdminSection section, AppLocalizations l10n) =>
      switch (section) {
        AdminSection.overview => l10n.adminSectionOverview,
        AdminSection.operations => l10n.adminSectionOperations,
        AdminSection.catalog => l10n.adminSectionCatalog,
        AdminSection.finance => l10n.adminSectionFinance,
        AdminSection.community => l10n.adminSectionCommunity,
        AdminSection.audit => l10n.adminSectionAudit,
        AdminSection.access => l10n.adminSectionAccess,
      };

  // Const-compatible label resolvers.
  static String _dashboard(AppLocalizations l) => l.adminNavDashboard;
  static String _bookings(AppLocalizations l) => l.adminNavBookings;
  static String _payments(AppLocalizations l) => l.adminNavPayments;
  static String _invoices(AppLocalizations l) => l.adminNavInvoices;
  static String _reviews(AppLocalizations l) => l.adminNavReviews;
  static String _activityLog(AppLocalizations l) => l.adminNavActivityLog;
  static String _partners(AppLocalizations l) => l.adminNavPartners;
  static String _catalog(AppLocalizations l) => l.adminNavCatalog;
  static String _media(AppLocalizations l) => l.adminNavMedia;
  static String _referenceData(AppLocalizations l) => l.adminNavReferenceData;
  static String _access(AppLocalizations l) => l.adminNavAccess;
}

/// Route strings, kept separate from `AdminRoutes` so `AdminNavigation` can be
/// `const` without a circular import between navigation and routing.
class AdminRoutesRefs {
  const AdminRoutesRefs._();

  static const String namespace = '/admin';
  static const String dashboard = '/admin/dashboard';
  static const String bookings = '/admin/bookings';
  static const String payments = '/admin/payments';
  static const String reviews = '/admin/reviews';
  static const String invoices = '/admin/invoices';
  static const String activityLog = '/admin/activity-log';

  /// D2C. Partner detail is reached from this destination rather than
  /// being its own menu entry: an operator opens a partner from the list,
  /// never by typing an id.
  static const String partners = '/admin/partners';

  /// D3C-A. Place detail is reached from this destination, same convention.
  static const String catalog = '/admin/catalog';

  /// D3C-B. One place's media gallery. The admin media API has no "list all
  /// media" read, so this destination opens on a place picker rather than on a
  /// grid of every asset.
  static const String media = '/admin/media';

  /// D10. Amenities and categories, as two tabs of one destination rather than
  /// two menu entries: they are the same four-operation contract over two
  /// small vocabularies, and an operator curating one is usually curating the
  /// other. Locations are deliberately absent — that contract is heavier and
  /// is its own phase.
  static const String referenceData = '/admin/reference-data';

  /// RBAC R6. Administrators and their admin profiles (A02).
  static const String access = '/admin/access';
}
