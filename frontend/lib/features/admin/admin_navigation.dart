import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Sidebar grouping. The Admin CMS is information-dense, so destinations are
/// grouped rather than presented as one flat list.
enum AdminSection { overview, operations, finance, community, audit }

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

  const AdminDestination({
    required this.route,
    required this.section,
    required this.icon,
    required this.label,
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
      section: AdminSection.overview,
      icon: Icons.dashboard_outlined,
      label: _dashboard,
    ),
    AdminDestination(
      route: AdminRoutesRefs.bookings,
      section: AdminSection.operations,
      icon: Icons.event_note_outlined,
      label: _bookings,
    ),
    AdminDestination(
      route: AdminRoutesRefs.payments,
      section: AdminSection.finance,
      icon: Icons.payments_outlined,
      label: _payments,
    ),
    AdminDestination(
      route: AdminRoutesRefs.invoices,
      section: AdminSection.finance,
      icon: Icons.receipt_long_outlined,
      label: _invoices,
    ),
    AdminDestination(
      route: AdminRoutesRefs.reviews,
      section: AdminSection.community,
      icon: Icons.rate_review_outlined,
      label: _reviews,
    ),
    AdminDestination(
      route: AdminRoutesRefs.activityLog,
      section: AdminSection.audit,
      icon: Icons.history_outlined,
      label: _activityLog,
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
        AdminSection.finance => l10n.adminSectionFinance,
        AdminSection.community => l10n.adminSectionCommunity,
        AdminSection.audit => l10n.adminSectionAudit,
      };

  // Const-compatible label resolvers.
  static String _dashboard(AppLocalizations l) => l.adminNavDashboard;
  static String _bookings(AppLocalizations l) => l.adminNavBookings;
  static String _payments(AppLocalizations l) => l.adminNavPayments;
  static String _invoices(AppLocalizations l) => l.adminNavInvoices;
  static String _reviews(AppLocalizations l) => l.adminNavReviews;
  static String _activityLog(AppLocalizations l) => l.adminNavActivityLog;
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
}
