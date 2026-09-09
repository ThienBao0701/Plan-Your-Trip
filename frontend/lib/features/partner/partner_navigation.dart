import 'package:flutter/material.dart';

import '../../core/partner/partner_models.dart';
import '../../l10n/app_localizations.dart';

/// The Partner Extranet navigation model.
///
/// **Keys and routes come from the backend, not from us.**
/// `PartnerExtranetService.getMenu` returns exactly thirteen `MenuItem`s with
/// the keys and route strings reproduced below, so the client uses those
/// verbatim. Where the C0 brief named a concept the backend calls something
/// else, the backend wins:
///
/// | Brief concept              | Backend surface                                |
/// |----------------------------|------------------------------------------------|
/// | Properties                 | `hotels` — `/api/partner/hotels`                |
/// | Inventory                  | `calendar` — `/api/partner/calendar/rooms/...`  |
/// | Rates                      | `pricing` — `/api/partner/rooms/*/rate-plans`   |
/// | Policies                   | part of `hotels` (`PUT /hotels/{id}/policies`)  |
/// | Check-in / Check-out       | part of `bookings` (`PATCH .../check-in`)       |
/// | Facilities, Assets         | no partner endpoint exists — **not modelled**   |
///
/// Facilities and Assets are deliberately absent: inventing destinations with
/// no backend behind them would be a fake surface.
///
/// The backend's menu is a flat list. The grouping below is a client-side
/// presentation concern only — it changes no key, route, or permission.
enum PartnerNavGroup {
  overview,
  property,
  operations,
  growth,
  business,
  account
}

/// Which count from `GET /api/partner/extranet/home` decorates a destination.
enum PartnerNavBadge {
  none,
  unreadMessages,
  pendingReviews,
  activePromotions,
  unreadNotifications
}

@immutable
class PartnerDestination {
  /// The backend `MenuItem.key`.
  final String key;

  /// The backend `MenuItem.route` — also this client's route path.
  final String route;

  final IconData icon;
  final IconData selectedIcon;
  final PartnerNavGroup group;
  final PartnerNavBadge badge;

  /// False for every destination whose module has not been built yet. C0 ships
  /// the shell and the dashboard; the rest render an honest "planned" view
  /// rather than a fabricated screen.
  final bool implemented;

  const PartnerDestination({
    required this.key,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.group,
    this.badge = PartnerNavBadge.none,
    this.implemented = false,
  });

  String label(AppLocalizations l10n) => switch (key) {
        'dashboard' => l10n.partnerNavDashboard,
        'hotels' => l10n.partnerNavHotels,
        'rooms' => l10n.partnerNavRooms,
        'calendar' => l10n.partnerNavCalendar,
        'pricing' => l10n.partnerNavPricing,
        'promotions' => l10n.partnerNavPromotions,
        'bookings' => l10n.partnerNavBookings,
        'messages' => l10n.partnerNavMessages,
        'analytics' => l10n.partnerNavAnalytics,
        'finance' => l10n.partnerNavFinance,
        'reviews' => l10n.partnerNavReviews,
        'notifications' => l10n.partnerNavNotifications,
        'settings' => l10n.partnerNavSettings,
        _ => key,
      };

  /// Whether this destination's module is one the caller's [PartnerTeamRole]
  /// can act in. **UX shaping only** — the backend re-checks every request, so a
  /// destination being visible is never authorization.
  ///
  /// Only the rules the backend actually enforces today are mirrored:
  /// `PartnerSettingsService` gates settings writes on OWNER/MANAGER, payout on
  /// OWNER/FINANCE and team management on OWNER. Every other partner service is
  /// owner-scoped rather than role-gated, so nothing else is filtered here.
  bool isWritableBy(PartnerTeamRole role) =>
      key == 'settings' ? role.canEditSettings : true;
}

/// The thirteen destinations, in the backend's own order, grouped for display.
class PartnerNavigation {
  const PartnerNavigation._();

  static const List<PartnerDestination> destinations = [
    PartnerDestination(
      key: 'dashboard',
      route: '/partner/dashboard',
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard_rounded,
      group: PartnerNavGroup.overview,
      implemented: true,
    ),
    PartnerDestination(
      key: 'hotels',
      route: '/partner/hotels',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment_rounded,
      group: PartnerNavGroup.property,
      implemented: true,
    ),
    PartnerDestination(
      key: 'rooms',
      route: '/partner/rooms',
      icon: Icons.meeting_room_outlined,
      selectedIcon: Icons.meeting_room_rounded,
      group: PartnerNavGroup.property,
      implemented: true,
    ),
    PartnerDestination(
      key: 'calendar',
      route: '/partner/calendar',
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month_rounded,
      group: PartnerNavGroup.property,
      implemented: true,
    ),
    PartnerDestination(
      key: 'pricing',
      route: '/partner/pricing',
      icon: Icons.sell_outlined,
      selectedIcon: Icons.sell_rounded,
      group: PartnerNavGroup.property,
      implemented: true,
    ),
    PartnerDestination(
      key: 'bookings',
      route: '/partner/bookings',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      group: PartnerNavGroup.operations,
      implemented: true,
    ),
    PartnerDestination(
      key: 'messages',
      route: '/partner/messages',
      icon: Icons.forum_outlined,
      selectedIcon: Icons.forum_rounded,
      group: PartnerNavGroup.operations,
      badge: PartnerNavBadge.unreadMessages,
      implemented: true,
    ),
    PartnerDestination(
      key: 'promotions',
      route: '/partner/promotions',
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer_rounded,
      group: PartnerNavGroup.growth,
      badge: PartnerNavBadge.activePromotions,
      implemented: true,
    ),
    PartnerDestination(
      key: 'reviews',
      route: '/partner/reviews',
      icon: Icons.star_outline_rounded,
      selectedIcon: Icons.star_rounded,
      group: PartnerNavGroup.growth,
      badge: PartnerNavBadge.pendingReviews,
      implemented: true,
    ),
    PartnerDestination(
      key: 'finance',
      route: '/partner/finance',
      icon: Icons.account_balance_outlined,
      selectedIcon: Icons.account_balance_rounded,
      group: PartnerNavGroup.business,
      implemented: true,
    ),
    PartnerDestination(
      key: 'analytics',
      route: '/partner/analytics',
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights_rounded,
      group: PartnerNavGroup.business,
      implemented: true,
    ),
    PartnerDestination(
      key: 'notifications',
      route: '/partner/notifications',
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      group: PartnerNavGroup.account,
      badge: PartnerNavBadge.unreadNotifications,
    ),
    PartnerDestination(
      key: 'settings',
      route: '/partner/settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      group: PartnerNavGroup.account,
      implemented: true,
    ),
  ];

  static const List<PartnerNavGroup> groups = PartnerNavGroup.values;

  static List<PartnerDestination> ofGroup(PartnerNavGroup group) =>
      destinations.where((d) => d.group == group).toList(growable: false);

  static PartnerDestination? byRoute(String route) {
    for (final destination in destinations) {
      if (destination.route == route) return destination;
    }
    return null;
  }

  static int indexOfRoute(String route) {
    for (var i = 0; i < destinations.length; i++) {
      if (destinations[i].route == route) return i;
    }
    return -1;
  }

  static String groupLabel(AppLocalizations l10n, PartnerNavGroup group) =>
      switch (group) {
        PartnerNavGroup.overview => l10n.partnerNavGroupOverview,
        PartnerNavGroup.property => l10n.partnerNavGroupProperty,
        PartnerNavGroup.operations => l10n.partnerNavGroupOperations,
        PartnerNavGroup.growth => l10n.partnerNavGroupGrowth,
        PartnerNavGroup.business => l10n.partnerNavGroupBusiness,
        PartnerNavGroup.account => l10n.partnerNavGroupAccount,
      };
}
