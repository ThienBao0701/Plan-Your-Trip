import 'package:flutter/material.dart';

import '../../core/admin/admin_models.dart';
import '../../core/admin/admin_state.dart';
import '../../core/app_state.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'admin_feature_states.dart';
import 'admin_partner_states.dart';
import 'widgets/admin_widgets.dart';
import 'admin_navigation.dart';
import 'admin_routes.dart';
import 'screens/admin_activity_log_screen.dart';
import 'screens/admin_bookings_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_invoices_screen.dart';
import 'screens/admin_partner_detail_screen.dart';
import 'screens/admin_partners_screen.dart';
import 'screens/admin_payments_screen.dart';
import 'screens/admin_reviews_screen.dart';

/// The Admin CMS shell.
///
/// Layout follows the console convention rather than the traveller app's:
/// a persistent sidebar on desktop, a collapsible drawer below it. There is
/// deliberately **no bottom navigation** — the admin surfaces are dense tables
/// consumed primarily on wide viewports, and a bottom bar would both fight the
/// traveller app's own identity and waste vertical space the grids need.
///
/// Feature notifiers are created once here and kept alive for the shell's
/// lifetime, so switching sections does not re-fetch or lose paging position.
/// They are disposed with the shell.
class AdminAppShell extends StatefulWidget {
  final String initialRoute;

  const AdminAppShell({super.key, this.initialRoute = AdminRoutes.dashboard});

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  late String _route;

  // Created once, in didChangeDependencies rather than initState, because the
  // ApiClient comes from an inherited widget and inherited lookups are not
  // valid during initState. Never created in build (that would re-fetch on
  // every rebuild) and never in dispose — the latter was a real defect found
  // in C7, so the ordering here is deliberate.
  AdminDashboardState? _dashboard;
  AdminBookingsState? _bookings;
  AdminPaymentsState? _payments;
  AdminReviewsState? _reviews;
  AdminInvoicesState? _invoices;
  AdminActivityLogState? _activity;
  AdminPartnersState? _partners;

  /// The partner currently open, or null when the Partners destination is
  /// showing its list. Detail state is created per partner and disposed when
  /// another is opened, so two partners can never share a notifier.
  AdminPartnerDetailState? _partnerDetail;

  bool _created = false;

  @override
  void initState() {
    super.initState();
    _route = widget.initialRoute;
  }

  @override
  void didUpdateWidget(AdminAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the shell is rebuilt pointing at a different entry route (a deep link
    // resolved after mount, or a re-push onto the same State), follow it rather
    // than silently staying on the route captured at initState.
    if (widget.initialRoute != oldWidget.initialRoute &&
        widget.initialRoute != _route) {
      setState(() => _route = widget.initialRoute);
      _loadFor(_route);
    }
  }

  @override
  void dispose() {
    _dashboard?.dispose();
    _bookings?.dispose();
    _payments?.dispose();
    _reviews?.dispose();
    _invoices?.dispose();
    _activity?.dispose();
    _partners?.dispose();
    _partnerDetail?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;

    final api = AppScope.of(context).api;
    _dashboard = AdminDashboardState(api: api);
    _bookings = AdminBookingsState(api: api);
    _payments = AdminPaymentsState(api: api);
    _reviews = AdminReviewsState(api: api);
    _invoices = AdminInvoicesState(api: api);
    _activity = AdminActivityLogState(api: api);
    _partners = AdminPartnersState(api: api);

    // One load for the landing section. Other sections load lazily when first
    // selected, so opening the console does not fan out six requests at once.
    //
    // Deferred to after the frame: both `load()` and `setActiveRoute` call
    // notifyListeners, and doing that synchronously inside
    // didChangeDependencies would notify while the tree is still building.
    final admin = AdminScope.maybeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadFor(_route);
      admin?.setActiveRoute(_route);
    });
  }

  /// Loads a section the first time it is shown. Idle-guarded so re-selecting a
  /// section keeps its rows and paging position instead of refetching.
  void _loadFor(String route) {
    switch (route) {
      case AdminRoutes.bookings:
        if (_bookings?.status == AdminLoadStatus.idle) _bookings!.load();
      case AdminRoutes.payments:
        if (_payments?.status == AdminLoadStatus.idle) _payments!.load();
      case AdminRoutes.reviews:
        if (_reviews?.status == AdminLoadStatus.idle) _reviews!.load();
      case AdminRoutes.invoices:
        if (_invoices?.status == AdminLoadStatus.idle) _invoices!.load();
      case AdminRoutes.activityLog:
        if (_activity?.status == AdminLoadStatus.idle) _activity!.load();
      case AdminRoutes.partners:
        if (_partners?.status == AdminLoadStatus.idle) _partners!.load();
      default:
        if (_dashboard?.status == AdminLoadStatus.idle) _dashboard!.load();
    }
  }

  /// Opens one partner's detail inside the Partners destination.
  ///
  /// A fresh [AdminPartnerDetailState] per partner, and the previous one is
  /// disposed: reusing a notifier across partners would let a slow response for
  /// the old id land on the new screen.
  void _openPartner(AdminPartnerRow row) {
    final api = AppScope.of(context).api;
    final previous = _partnerDetail;
    final next = AdminPartnerDetailState(api: api, partnerId: row.id);
    setState(() => _partnerDetail = next);
    previous?.dispose();
    next.load();
  }

  void _closePartner() {
    final previous = _partnerDetail;
    setState(() => _partnerDetail = null);
    previous?.dispose();
    // The lifecycle actions can change a partner's status, so the list is
    // re-read rather than showing what it held before the detail was opened.
    _partners?.refresh();
  }

  void _select(String route, {bool closeDrawer = false}) {
    if (closeDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // Leaving Partners drops any open detail, so returning to the
    // destination starts at the list rather than a stale partner.
    if (_route != route && _partnerDetail != null) {
      final previous = _partnerDetail;
      _partnerDetail = null;
      previous?.dispose();
    }
    if (_route != route) setState(() => _route = route);
    _loadFor(route);
    AdminScope.maybeOf(context)?.setActiveRoute(route);
  }

  Widget _bodyFor(String route) {
    if (!_created) return const SizedBox.shrink();
    return switch (route) {
      AdminRoutes.bookings => AdminBookingsScreen(state: _bookings!),
      AdminRoutes.payments => AdminPaymentsScreen(state: _payments!),
      AdminRoutes.reviews => AdminReviewsScreen(state: _reviews!),
      AdminRoutes.invoices => AdminInvoicesScreen(state: _invoices!),
      AdminRoutes.activityLog => AdminActivityLogScreen(state: _activity!),
      AdminRoutes.partners => _partnerDetail == null
          ? AdminPartnersScreen(
              state: _partners!,
              onOpenPartner: _openPartner,
            )
          : AdminPartnerDetailScreen(
              state: _partnerDetail!,
              onBack: _closePartner,
            ),
      _ => AdminDashboardScreen(state: _dashboard!),
    };
  }

  String _titleFor(String route, AppLocalizations l10n) =>
      AdminNavigation.byRoute(route)?.label(l10n) ?? l10n.adminConsoleTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final showSidebar = width >= AppBreakpoints.desktop;

    final content = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_titleFor(_route, l10n)),
        // Only the narrow layout gets a drawer button; the sidebar is always
        // visible on desktop, so a hamburger there would be dead weight.
        leading: showSidebar
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: l10n.adminMenu,
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
      ),
      drawer: showSidebar
          ? null
          : Drawer(
              child: SafeArea(
                child: _AdminMenu(
                  activeRoute: _route,
                  onSelect: (r) => _select(r, closeDrawer: true),
                ),
              ),
            ),
      body: SafeArea(
        child: showSidebar
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 248,
                    child: _AdminMenu(
                      activeRoute: _route,
                      onSelect: _select,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: _bodyFor(_route)),
                ],
              )
            : _bodyFor(_route),
      ),
    );

    return BubbleBackground(child: content);
  }
}

/// Sidebar / drawer contents. Grouped by [AdminSection] so a dense console
/// stays scannable; only sections that actually contain a destination render.
class _AdminMenu extends StatelessWidget {
  final String activeRoute;
  final ValueChanged<String> onSelect;

  const _AdminMenu({required this.activeRoute, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final admin = AdminScope.maybeOf(context);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adminConsoleTitle, style: theme.textTheme.titleMedium),
              if (admin?.adminEmail != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.adminSignedInAs(admin!.adminEmail!),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        for (final section in AdminNavigation.populatedSections) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xxs),
            child: Text(
              AdminNavigation.sectionLabel(section, l10n).toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.8,
              ),
            ),
          ),
          for (final d in AdminNavigation.inSection(section))
            ListTile(
              leading: Icon(d.icon),
              title: Text(d.label(l10n)),
              selected: d.route == activeRoute,
              // 48dp minimum touch target (frontend guidance §10).
              minVerticalPadding: 12,
              onTap: () => onSelect(d.route),
            ),
        ],
      ],
    );
  }
}
