import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/partner/partner_inventory_models.dart';
import '../../../core/partner/partner_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_inventory_state.dart';
import 'widgets/partner_inventory_widgets.dart';

/// The Partner Inventory module — daily availability for one room type.
///
/// ## Backend contract (verified in `backend-v1`/`develop` and live on :8081)
///
/// The namespace is **calendar**, not "inventory":
///
/// | Action | Endpoint |
/// |---|---|
/// | Read | `GET /api/partner/calendar/rooms/{roomId}?from&to` |
/// | Stop-sell | `PATCH /api/partner/calendar/rooms/{roomId}/{date}/stop-sell` |
/// | Closed to arrival | `PATCH .../{date}/closed-arrival` |
/// | Closed to departure | `PATCH .../{date}/closed-departure` |
///
/// `PUT .../{date}` and `POST .../bulk` exist but are **not** exposed here — see
/// `PartnerInventoryState.setFlag` for why. `.../price` is rate plans (a later
/// phase) and is absent entirely.
///
/// ## Date semantics
///
/// `from` and `to` are **inclusive on both ends**, and the backend only applies
/// the range when both are present. An inverted range returns an empty 200
/// rather than a 400, so the client validates it. All three are covered by
/// tests.
///
/// ## Context chain
///
/// property (`PartnerState.selectedPropertyId`) → rooms → calendar. The screen
/// reads the property from the workspace and never stores a second copy; room
/// choice is local because it is an inventory concern only.
class PartnerInventoryScreen extends StatefulWidget {
  const PartnerInventoryScreen({super.key});

  @override
  State<PartnerInventoryScreen> createState() => _PartnerInventoryScreenState();
}

class _PartnerInventoryScreenState extends State<PartnerInventoryScreen> {
  PartnerInventoryState? _inventory;
  PartnerState? _partner;
  int? _syncedPropertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _inventory?.dispose();
      _inventory = PartnerInventoryState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final inventory = _inventory!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) inventory.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _inventory?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final inventory = _inventory;
    if (partner == null || inventory == null) return;
    await inventory.load(partner, partner.selectedPropertyId);
  }

  @override
  Widget build(BuildContext context) {
    final partner = PartnerScope.of(context);
    final inventory = _inventory;

    if (!partner.isReady || inventory == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: inventory,
      builder: (context, _) => _InventoryBody(
        partner: partner,
        inventory: inventory,
        onReload: _reload,
      ),
    );
  }
}

class _InventoryBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerInventoryState inventory;
  final Future<void> Function() onReload;

  const _InventoryBody({
    required this.partner,
    required this.inventory,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (inventory.status) {
      case PartnerInventoryStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerInventoryStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: inventory.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerInventoryStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: inventory.errorMessage,
          onPrimaryAction: onReload,
        );
      default:
        break;
    }

    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= AppBreakpoints.desktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _InventoryHeader(
            partner: partner, inventory: inventory, onReload: onReload),
        const SizedBox(height: AppSpacing.md),
        if (inventory.rooms.isNotEmpty) ...[
          _InventoryScopeBar(partner: partner, inventory: inventory),
          const SizedBox(height: AppSpacing.md),
        ],
        _body(context, l10n, isWide),
      ],
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, bool isWide) {
    switch (inventory.status) {
      case PartnerInventoryStatus.noProperties:
        return OceanStateView(
          icon: Icons.apartment_outlined,
          title: l10n.partnerInventoryNoPropertiesTitle,
          message: l10n.partnerInventoryNoPropertiesMessage,
          semanticLabel: l10n.partnerInventoryNoPropertiesTitle,
        );
      case PartnerInventoryStatus.noPropertySelected:
        return OceanStateView(
          icon: Icons.touch_app_outlined,
          title: l10n.partnerInventorySelectPropertyTitle,
          message: l10n.partnerInventorySelectPropertyMessage,
          semanticLabel: l10n.partnerInventorySelectPropertyTitle,
        );
      case PartnerInventoryStatus.noRooms:
        return OceanStateView(
          icon: Icons.meeting_room_outlined,
          title: l10n.partnerInventoryNoRoomsTitle,
          message: l10n.partnerInventoryNoRoomsMessage,
          semanticLabel: l10n.partnerInventoryNoRoomsTitle,
        );
      case PartnerInventoryStatus.noRoomSelected:
        return OceanStateView(
          icon: Icons.touch_app_outlined,
          title: l10n.partnerInventorySelectRoomTitle,
          message: l10n.partnerInventorySelectRoomMessage,
          semanticLabel: l10n.partnerInventorySelectRoomTitle,
        );
      case PartnerInventoryStatus.invalidRange:
        return OceanStateView(
          icon: Icons.event_busy_outlined,
          title: l10n.partnerInventoryInvalidRangeTitle,
          message: l10n.partnerInventoryInvalidRangeMessage,
          semanticLabel: l10n.partnerInventoryInvalidRangeTitle,
        );
      case PartnerInventoryStatus.notFound:
        return OceanStateView(
          icon: Icons.error_outline_rounded,
          title: l10n.partnerInventoryUnavailableTitle,
          message: l10n.partnerInventoryUnavailableMessage,
          semanticLabel: l10n.partnerInventoryUnavailableTitle,
          actionLabel: l10n.partnerActionRetry,
          onAction: onReload,
        );
      case PartnerInventoryStatus.idle:
      case PartnerInventoryStatus.loading:
      case PartnerInventoryStatus.loadingRooms:
        return const _InventoryLoading();
      case PartnerInventoryStatus.ready:
        if (inventory.isEmpty) {
          return OceanStateView(
            icon: Icons.event_note_outlined,
            title: l10n.partnerInventoryEmptyTitle,
            message: l10n.partnerInventoryEmptyMessage,
            semanticLabel: l10n.partnerInventoryEmptyTitle,
          );
        }
        return _InventoryData(
          partner: partner,
          inventory: inventory,
          isWide: isWide,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _InventoryHeader extends StatelessWidget {
  final PartnerState partner;
  final PartnerInventoryState inventory;
  final Future<void> Function() onReload;

  const _InventoryHeader({
    required this.partner,
    required this.inventory,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMd(locale);
    final number = NumberFormat('#,##0', locale);
    final property = partner.selectedProperty;
    final window = inventory.window;
    final calendar = inventory.calendar;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.partnerNavCalendar,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property == null
                          ? l10n.partnerInventoryNoPropertyContext
                          : l10n.partnerInventoryForProperty(property.name),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: inventory.isLoading ? null : onReload,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              // The window is stated inclusively because that is what the
              // backend query does — "29 Aug – 11 Sep" really is 14 rows.
              _Fact(
                icon: Icons.date_range_rounded,
                text: l10n.partnerInventoryWindow(
                  dateFmt.format(window.from),
                  dateFmt.format(window.to),
                  inventory.range.days,
                ),
              ),
              if (calendar != null) ...[
                _Fact(
                  icon: Icons.check_circle_outline_rounded,
                  text: l10n.partnerInventoryBookableDays(
                      calendar.bookableDays, calendar.days.length),
                ),
                _Fact(
                  icon: Icons.inventory_2_outlined,
                  text: l10n.partnerInventoryTotalAvailable(
                      number.format(calendar.totalAvailable)),
                ),
                if (calendar.stopSellDays > 0)
                  _Fact(
                    icon: Icons.block_outlined,
                    text: l10n
                        .partnerInventoryStopSellDays(calendar.stopSellDays),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Fact({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
}

/// Property (workspace), room and window selectors.
class _InventoryScopeBar extends StatelessWidget {
  final PartnerState partner;
  final PartnerInventoryState inventory;

  const _InventoryScopeBar({required this.partner, required this.inventory});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String rangeLabel(PartnerInventoryRange r) => switch (r) {
          PartnerInventoryRange.week => l10n.partnerInventoryRangeWeek,
          PartnerInventoryRange.fortnight =>
            l10n.partnerInventoryRangeFortnight,
          PartnerInventoryRange.month => l10n.partnerInventoryRangeMonth,
        };

    Widget group(String title, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            child,
          ],
        );

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (partner.properties.length > 1) ...[
            group(
              l10n.partnerInventoryPropertyScope,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final property in partner.properties)
                    _Chip(
                      label: property.name,
                      selected: partner.selectedPropertyId == property.id,
                      enabled: !inventory.isLoading,
                      onTap: () => partner.selectProperty(property.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (inventory.rooms.length > 1) ...[
            group(
              l10n.partnerInventoryRoomScope,
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final room in inventory.rooms)
                    _Chip(
                      label: room.roomName,
                      selected: inventory.selectedRoomId == room.id,
                      enabled: !inventory.isLoading,
                      onTap: () => inventory.selectRoom(room.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          group(
            l10n.partnerInventoryRangeLabel,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final r in PartnerInventoryRange.values)
                  _Chip(
                    label: rangeLabel(r),
                    selected: inventory.range == r,
                    enabled: !inventory.isLoading,
                    onTap: () => inventory.selectRange(r),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: selected ? AppColors.textInverse : AppColors.textPrimary,
      ),
      selectedColor: AppColors.ocean700,
      backgroundColor: AppColors.surfaceMuted,
      showCheckmark: false,
    );
  }
}

class _InventoryLoading extends StatelessWidget {
  const _InventoryLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            for (var i = 0; i < 5; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.sm),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The calendar itself: a dense table on desktop, the same data as cards below.
class _InventoryData extends StatelessWidget {
  final PartnerState partner;
  final PartnerInventoryState inventory;
  final bool isWide;

  const _InventoryData({
    required this.partner,
    required this.inventory,
    required this.isWide,
  });

  /// `PartnerCalendarService` applies no `PartnerTeamRole` check — it resolves
  /// the caller with `partnerProfileRepo.findByUserId`, so only the profile
  /// owner reaches these endpoints. Gating on OWNER mirrors that; unknown fails
  /// closed. UX only — the backend re-checks every request.
  bool get _canEdit => partner.teamRole == PartnerTeamRole.owner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final calendar = inventory.calendar!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_canEdit) ...[
          _Notice(message: l10n.partnerInventoryEditOwnerOnly),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (calendar.inconsistentDays > 0) ...[
          _Notice(
            message: l10n
                .partnerInventoryInconsistentSummary(calendar.inconsistentDays),
            warning: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (isWide)
          _InventoryTable(
            inventory: inventory,
            canEdit: _canEdit,
            onFlagChanged: (day, flag, value) =>
                _apply(context, day, flag, value),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final day in calendar.days) ...[
                PartnerInventoryDayCard(
                  day: day,
                  pending: _isPending(day),
                  canEdit: _canEdit,
                  onFlagChanged: _canEdit
                      ? (flag, value) => _apply(context, day, flag, value)
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }

  bool _isPending(PartnerInventoryDay day) {
    final pending = inventory.pendingDate;
    return pending != null &&
        pending.year == day.date.year &&
        pending.month == day.date.month &&
        pending.day == day.date.day;
  }

  Future<void> _apply(
    BuildContext context,
    PartnerInventoryDay day,
    PartnerInventoryFlag flag,
    bool value,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await inventory.setFlag(
      date: day.date,
      flag: flag,
      value: value,
    );
    if (!context.mounted) return;

    // Never claim a change the server did not confirm.
    final message = switch (result) {
      PartnerInventoryActionResult.success => l10n.partnerInventorySaved,
      PartnerInventoryActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerInventoryActionResult.forbidden =>
        l10n.partnerDashboardErrorForbidden,
      PartnerInventoryActionResult.notFound =>
        l10n.partnerInventoryActionNotFound,
      PartnerInventoryActionResult.uncertain =>
        l10n.partnerPropertyActionUncertain,
      PartnerInventoryActionResult.failed => l10n.partnerPropertyActionFailed,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Notice extends StatelessWidget {
  final String message;
  final bool warning;

  const _Notice({required this.message, this.warning = false});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
                color: warning ? AppColors.warning : AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(
                warning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: warning ? AppColors.warning : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Desktop table. Scrolls inside its own container so the console never scrolls
/// sideways, and every column carries a backend field.
class _InventoryTable extends StatelessWidget {
  final PartnerInventoryState inventory;
  final bool canEdit;
  final void Function(
          PartnerInventoryDay day, PartnerInventoryFlag flag, bool value)?
      onFlagChanged;

  const _InventoryTable({
    required this.inventory,
    required this.canEdit,
    this.onFlagChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFmt = DateFormat.MMMEd(locale);
    final number = NumberFormat('#,##0', locale);
    final calendar = inventory.calendar!;

    Widget head(String text) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
          child: Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
            ),
          ),
        );

    Widget cell(String text, {bool emphasis = false}) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
              color: emphasis ? AppColors.ocean700 : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        );

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 940),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(150),
              1: FixedColumnWidth(132),
              2: FixedColumnWidth(80),
              3: FixedColumnWidth(80),
              4: FixedColumnWidth(80),
              5: FixedColumnWidth(90),
              6: FixedColumnWidth(96),
              7: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                children: [
                  head(l10n.partnerInventoryDate),
                  head(l10n.partnerInventoryStateColumn),
                  head(l10n.partnerInventoryTotal),
                  head(l10n.partnerInventoryAvailable),
                  head(l10n.partnerInventorySold),
                  head(l10n.partnerInventoryBlocked),
                  head(l10n.partnerInventoryMaintenance),
                  head(l10n.partnerInventoryRestrictions),
                ],
              ),
              for (final day in calendar.days)
                TableRow(
                  decoration: BoxDecoration(
                    color: day.hasRestriction
                        ? AppColors.warning.withValues(alpha: 0.06)
                        : null,
                    border: const Border(
                        bottom: BorderSide(color: AppColors.divider)),
                  ),
                  children: [
                    cell(dateFmt.format(day.date)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: PartnerInventoryStateBadge(day: day),
                      ),
                    ),
                    cell(number.format(day.totalInventory)),
                    cell(number.format(day.availableInventory), emphasis: true),
                    cell(number.format(day.soldInventory)),
                    cell(number.format(day.blockedInventory)),
                    cell(number.format(day.maintenanceInventory)),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
                      child: PartnerInventoryFlagRow(
                        day: day,
                        pending: _isPending(day),
                        canEdit: canEdit,
                        onFlagChanged: canEdit && onFlagChanged != null
                            ? (flag, value) => onFlagChanged!(day, flag, value)
                            : null,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isPending(PartnerInventoryDay day) {
    final pending = inventory.pendingDate;
    return pending != null &&
        pending.year == day.date.year &&
        pending.month == day.date.month &&
        pending.day == day.date.day;
  }
}
