import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/partner/partner_models.dart';
import '../../core/partner/partner_state.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'partner_dashboard_screen.dart';
import 'messages/partner_messages_screen.dart';
import 'partner_module_screen.dart';
import 'partner_navigation.dart';
import 'properties/partner_properties_screen.dart';
import 'analytics/partner_analytics_screen.dart';
import 'bookings/partner_bookings_screen.dart';
import 'finance/partner_finance_screen.dart';
import 'calendar/partner_calendar_screen.dart';
import 'reviews/partner_reviews_screen.dart';
import 'settings/partner_settings_screen.dart';
import 'promotions/partner_promotions_screen.dart';
import 'rates/partner_rates_screen.dart';
import 'rooms/partner_rooms_screen.dart';
import 'widgets/partner_state_views.dart';

/// The Partner Extranet shell: an operations workspace, not the traveller app.
///
/// Layout differs by width on purpose. Desktop web is the primary target, so at
/// >= [AppBreakpoints.desktop] the shell is a permanent two-pane console —
/// grouped sidebar plus a working area with a page header. Below that the
/// sidebar becomes a drawer and the header collapses into an app bar.
///
/// There is **no bottom navigation bar** at any width. The traveller app's
/// four-tab bar is a consumer pattern; thirteen operational destinations in six
/// groups do not belong in one.
class PartnerAppShell extends StatefulWidget {
  final String initialRoute;

  const PartnerAppShell({super.key, required this.initialRoute});

  @override
  State<PartnerAppShell> createState() => _PartnerAppShellState();
}

class _PartnerAppShellState extends State<PartnerAppShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _route = widget.initialRoute;
  bool _requestedLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedLoad) return;
    _requestedLoad = true;
    // The workspace is loaded once when the shell mounts. Every later refresh
    // is an explicit user action, so a transient backend failure never turns
    // into a retry loop.
    final app = AppScope.of(context);
    final partner = PartnerScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) partner.loadWorkspace(app);
    });
  }

  Future<void> _reload() async {
    final app = AppScope.of(context);
    final partner = PartnerScope.of(context);
    partner.reset();
    await partner.loadWorkspace(app);
  }

  void _select(String route) {
    if (_route == route) return;
    setState(() => _route = route);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppBreakpoints.desktop;
    final destination = PartnerNavigation.byRoute(_route) ??
        PartnerNavigation.destinations.first;

    final sidebar = _PartnerSidebar(
      selectedRoute: _route,
      overview: partner.overview,
      teamRole: partner.teamRole,
      onSelect: (route) {
        if (!isDesktop) Navigator.of(context).maybePop();
        _select(route);
      },
      onExit: () => Navigator.of(context).maybePop(),
    );

    final body = _PartnerWorkArea(
      destination: destination,
      isDesktop: isDesktop,
      onReload: _reload,
      onOpenMenu:
          isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.surfaceMuted,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: AppColors.white,
              child: SafeArea(child: sidebar),
            ),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                destination.label(l10n),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              actions: [
                IconButton(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: l10n.partnerActionRefresh,
                ),
              ],
            ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 272, child: sidebar),
                  const VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: AppColors.divider,
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
    );
  }
}

/// Grouped destination list plus the workspace identity header. Used as both
/// the desktop rail and the mobile drawer so the two never drift apart.
class _PartnerSidebar extends StatelessWidget {
  final String selectedRoute;
  final PartnerWorkspaceOverview? overview;
  final PartnerTeamRole teamRole;
  final ValueChanged<String> onSelect;
  final VoidCallback onExit;

  const _PartnerSidebar({
    required this.selectedRoute,
    required this.overview,
    required this.teamRole,
    required this.onSelect,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.ocean700,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.partnerExtranetTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  overview?.businessName ?? l10n.partnerWorkspaceUnnamed,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.partnerTeamRoleLabel(_teamRoleLabel(l10n, teamRole)),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              children: [
                for (final group in PartnerNavigation.groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxs,
                    ),
                    child: Text(
                      PartnerNavigation.groupLabel(l10n, group).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                      ),
                    ),
                  ),
                  for (final destination in PartnerNavigation.ofGroup(group))
                    _PartnerNavTile(
                      destination: destination,
                      selected: destination.route == selectedRoute,
                      badgeCount: _badgeFor(destination),
                      onTap: () => onSelect(destination.route),
                    ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: OceanSecondaryButton(
              label: l10n.partnerActionExitToTravellerApp,
              icon: Icons.logout_rounded,
              onPressed: onExit,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge counts come from `GET /api/partner/extranet/home`; nothing is
  /// computed client-side. A null overview means "not loaded yet", which shows
  /// no badge rather than a zero.
  int? _badgeFor(PartnerDestination destination) {
    final data = overview;
    if (data == null) return null;
    final count = switch (destination.badge) {
      PartnerNavBadge.none => null,
      PartnerNavBadge.unreadMessages => data.unreadMessages,
      PartnerNavBadge.pendingReviews => data.pendingReviews,
      PartnerNavBadge.activePromotions => data.activePromotions,
      PartnerNavBadge.unreadNotifications => data.unreadNotifications,
    };
    if (count == null || count <= 0) return null;
    return count;
  }
}

class _PartnerNavTile extends StatelessWidget {
  final PartnerDestination destination;
  final bool selected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _PartnerNavTile({
    required this.destination,
    required this.selected,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = destination.label(l10n);
    final count = badgeCount;

    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? label : l10n.partnerNavBadgeSemantic(label, count),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 1,
        ),
        child: Material(
          color: selected ? AppColors.mist : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    selected ? destination.selectedIcon : destination.icon,
                    size: 20,
                    color:
                        selected ? AppColors.ocean700 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                        color: selected
                            ? AppColors.ocean700
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (count != null)
                    Container(
                      margin: const EdgeInsets.only(left: AppSpacing.xxs),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ocean700,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The right-hand pane: a page header (breadcrumb + title + actions) above the
/// selected destination's content, or the shared status view when the workspace
/// is not [PartnerWorkspaceStatus.ready].
class _PartnerWorkArea extends StatelessWidget {
  final PartnerDestination destination;
  final bool isDesktop;
  final Future<void> Function() onReload;
  final VoidCallback? onOpenMenu;

  const _PartnerWorkArea({
    required this.destination,
    required this.isDesktop,
    required this.onReload,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isDesktop)
          _PartnerPageHeader(
            destination: destination,
            onReload: onReload,
            onOpenMenu: onOpenMenu,
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onReload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (!partner.isReady)
                  PartnerWorkspaceStatusView(
                    status: partner.status,
                    detail: partner.errorMessage,
                    onPrimaryAction: partner.isRetryable ? onReload : null,
                  )
                else
                  // Dispatch by the backend's own menu key. Anything not yet
                  // built falls through to the honest "planned" view rather
                  // than a fabricated screen.
                  switch (destination.key) {
                    'dashboard' => const PartnerDashboardScreen(),
                    'hotels' => const PartnerPropertiesScreen(),
                    'rooms' => const PartnerRoomsScreen(),
                    'calendar' => const PartnerCalendarScreen(),
                    'pricing' => const PartnerRatesScreen(),
                    'promotions' => const PartnerPromotionsScreen(),
                    'bookings' => const PartnerBookingsScreen(),
                    'messages' => const PartnerMessagesScreen(),
                    'finance' => const PartnerFinanceScreen(),
                    'analytics' => const PartnerAnalyticsScreen(),
                    'reviews' => const PartnerReviewsScreen(),
                    'settings' => const PartnerSettingsScreen(),
                    _ => PartnerModuleScreen(destination: destination),
                  },
                if (!isDesktop) ...[
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      l10n.partnerShellMobileHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PartnerPageHeader extends StatelessWidget {
  final PartnerDestination destination;
  final Future<void> Function() onReload;
  final VoidCallback? onOpenMenu;

  const _PartnerPageHeader({
    required this.destination,
    required this.onReload,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final partner = PartnerScope.of(context);
    final crumb = PartnerNavigation.groupLabel(l10n, destination.group);

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          if (onOpenMenu != null)
            IconButton(
              onPressed: onOpenMenu,
              icon: const Icon(Icons.menu_rounded),
              tooltip: l10n.partnerNavMenuTooltip,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${l10n.partnerExtranetTitle} / $crumb',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  destination.label(l10n),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (partner.profile != null) ...[
            PartnerVerificationPill(
              status: partner.profile!.verificationStatus,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          IconButton(
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.partnerActionRefresh,
          ),
        ],
      ),
    );
  }
}

String _teamRoleLabel(AppLocalizations l10n, PartnerTeamRole role) =>
    switch (role) {
      PartnerTeamRole.owner => l10n.partnerTeamRoleOwner,
      PartnerTeamRole.manager => l10n.partnerTeamRoleManager,
      PartnerTeamRole.frontDesk => l10n.partnerTeamRoleFrontDesk,
      PartnerTeamRole.finance => l10n.partnerTeamRoleFinance,
      PartnerTeamRole.viewer => l10n.partnerTeamRoleViewer,
      PartnerTeamRole.unknown => l10n.partnerTeamRoleUnknown,
    };
