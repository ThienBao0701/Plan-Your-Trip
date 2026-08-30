import 'package:flutter/material.dart';

import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../inventory/partner_inventory_screen.dart';
import '../widgets/partner_state_views.dart';
import 'partner_calendar_state.dart';
import 'widgets/partner_calendar_widgets.dart';

/// The `calendar` destination — the backend's own menu key, which C4 already
/// owned. C9 adds a second view to the *same* module rather than inventing a
/// fourteenth destination the backend menu does not have.
///
/// ## The C4 / C9 boundary
///
/// | | C4 — Inventory | C9 — Property calendar |
/// |---|---|---|
/// | Shape | one room, a date list | **every room × every day**, a grid |
/// | Owns | quantities, stop-sell, CTA, CTD **edits** | read-only overview |
/// | Endpoints | `GET /calendar/rooms/{id}`, the three flag `PATCH`es | the **same** `GET`, once per room |
/// | Models | `PartnerInventoryDay` / `PartnerInventoryCalendar` | reuses both, adds no DTO |
///
/// C9 adds **no endpoint and no parsing**: `ApiClient.getPartnerInventory` and
/// `ApiClient.getPartnerRooms` are C4's and C3's, used unchanged. It also
/// performs **no mutation** — the three restriction toggles already exist one
/// tab away, and two code paths writing the same rows would be worse than one.
///
/// ## Endpoints deliberately not consumed
///
/// `PartnerCalendarController` also exposes `PUT /rooms/{roomId}/{date}` and
/// `POST /rooms/{roomId}/bulk` (numeric inventory writes) and
/// `GET|PUT /rooms/{roomId}/price` (rate plans, which are C5's). The numeric
/// writes are withheld on purpose: `RoomInventory` has no `@Version`, so two
/// partners editing the same row overwrite one another silently. A calendar that
/// offered inline quantity editing would imply a safety the backend does not
/// provide.
class PartnerCalendarScreen extends StatefulWidget {
  const PartnerCalendarScreen({super.key});

  @override
  State<PartnerCalendarScreen> createState() => _PartnerCalendarScreenState();
}

class _PartnerCalendarScreenState extends State<PartnerCalendarScreen>
    with SingleTickerProviderStateMixin {
  PartnerCalendarState? _calendar;
  PartnerState? _partner;
  int? _syncedPropertyId;

  // Built eagerly: on a gated workspace `build` returns before the controller is
  // read, and a lazy `late final` would then be constructed for the first time
  // inside `dispose()`, against an already-deactivated element.
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _calendar?.dispose();
      _calendar = PartnerCalendarState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final calendar = _calendar!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) calendar.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _calendar?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final calendar = _calendar;

    if (!partner.isReady || calendar == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.partnerCalendarTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.ocean700,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.ocean700,
                tabs: [
                  Tab(text: l10n.partnerCalendarTabOverview),
                  Tab(text: l10n.partnerCalendarTabInventory),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AnimatedBuilder(
          animation: _tabs,
          builder: (context, _) => _tabs.index == 0
              ? AnimatedBuilder(
                  animation: calendar,
                  builder: (context, _) => _OverviewTab(
                    partner: partner,
                    calendar: calendar,
                    onManageRestrictions: () => _tabs.animateTo(1),
                  ),
                )
              // C4, embedded verbatim. It keeps its own state and its own
              // mutation controls; C9 neither wraps nor re-implements them.
              : const PartnerInventoryScreen(),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerCalendarState calendar;
  final VoidCallback onManageRestrictions;

  const _OverviewTab({
    required this.partner,
    required this.calendar,
    required this.onManageRestrictions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (calendar.status) {
      case PartnerCalendarStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerCalendarStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: calendar.errorMessage,
          onPrimaryAction: () => calendar.refresh(partner),
        );
      case PartnerCalendarStatus.notFound:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired,
          onPrimaryAction: () => calendar.refresh(partner),
        );
      case PartnerCalendarStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: calendar.errorMessage,
          onPrimaryAction: () => calendar.refresh(partner),
        );
      case PartnerCalendarStatus.idle:
      case PartnerCalendarStatus.loading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CalendarHeader(partner: partner, calendar: calendar),
            const SizedBox(height: AppSpacing.md),
            const _CalendarLoading(),
          ],
        );
      case PartnerCalendarStatus.ready:
        break;
    }

    if (calendar.hasNoRooms) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CalendarHeader(partner: partner, calendar: calendar),
          const SizedBox(height: AppSpacing.md),
          OceanStateView(
            icon: Icons.meeting_room_outlined,
            title: l10n.partnerCalendarNoRoomsTitle,
            message: l10n.partnerCalendarNoRoomsMessage,
            semanticLabel: l10n.partnerCalendarNoRoomsTitle,
          ),
        ],
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < AppBreakpoints.tablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CalendarHeader(partner: partner, calendar: calendar),
        const SizedBox(height: AppSpacing.md),
        if (calendar.failedRooms > 0) ...[
          PartnerCalendarNotice(
            warning: true,
            message: l10n.partnerCalendarRoomsFailed(
                '${calendar.failedRooms}', '${calendar.rows.length}'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (calendar.isWindowEmpty) ...[
          PartnerCalendarNotice(
            message: l10n.partnerCalendarWindowEmptyMessage,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // A fourteen-column grid is unusable on a phone, so mobile gets a
        // focused single-day view of every room instead.
        if (isCompact)
          _MobileDayView(calendar: calendar)
        else
          _CalendarGrid(calendar: calendar),
        const SizedBox(height: AppSpacing.md),
        const OceanGlassCard(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: PartnerCalendarLegend(),
        ),
        if (calendar.selectedCell != null) ...[
          const SizedBox(height: AppSpacing.md),
          _NightPanel(
            calendar: calendar,
            onManageRestrictions: onManageRestrictions,
          ),
        ],
      ],
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  final PartnerState partner;
  final PartnerCalendarState calendar;

  const _CalendarHeader({required this.partner, required this.calendar});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerCalendarFormats.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.partnerCalendarScopeNote,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              IconButton(
                onPressed: calendar.isLoading
                    ? null
                    : () => calendar.shiftWeeks(partner, -1),
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: l10n.partnerCalendarPreviousWeek,
              ),
              Text(
                l10n.partnerCalendarWindowRange(
                  f.monthDay.format(calendar.windowStart),
                  f.full.format(calendar.windowEnd),
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: calendar.isLoading
                    ? null
                    : () => calendar.shiftWeeks(partner, 1),
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: l10n.partnerCalendarNextWeek,
              ),
              OceanSecondaryButton(
                label: l10n.partnerCalendarToday,
                icon: Icons.today_rounded,
                fullWidth: false,
                onPressed: calendar.isLoading || calendar.showsToday
                    ? null
                    : () => calendar.goToToday(partner),
              ),
              IconButton(
                onPressed:
                    calendar.isLoading ? null : () => calendar.refresh(partner),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          if (calendar.isReady && calendar.rows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xxs,
              children: [
                PartnerCalendarMetric(
                  icon: Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  value: f.integer.format(calendar.totalSellableNights),
                  label: l10n.partnerCalendarMetricSellable,
                ),
                PartnerCalendarMetric(
                  icon: Icons.person_rounded,
                  color: AppColors.violet,
                  value: f.integer.format(calendar.totalOccupiedNights),
                  label: l10n.partnerCalendarMetricOccupied,
                ),
                PartnerCalendarMetric(
                  icon: Icons.rule_rounded,
                  color: AppColors.warning,
                  value: f.integer.format(calendar.totalRestrictedNights),
                  label: l10n.partnerCalendarMetricRestricted,
                ),
                if (calendar.totalMissingNights > 0)
                  PartnerCalendarMetric(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.textTertiary,
                    value: f.integer.format(calendar.totalMissingNights),
                    label: l10n.partnerCalendarMetricMissing,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CalendarLoading extends StatelessWidget {
  const _CalendarLoading();

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
            for (var i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  height: 54,
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

/// The desktop and tablet grid: rooms down, days across.
///
/// Horizontal scrolling is deliberate for this data shape — a fortnight of
/// room-nights cannot be reflowed without hiding something — and the room column
/// stays inside the scroll area so a row's label always travels with its cells.
class _CalendarGrid extends StatelessWidget {
  final PartnerCalendarState calendar;

  const _CalendarGrid({required this.calendar});

  @override
  Widget build(BuildContext context) {
    const roomColumn = 168.0;
    const dayColumn = 58.0;
    final days = calendar.days;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: roomColumn + dayColumn * days.length,
          ),
          child: Table(
            columnWidths: {
              0: const FixedColumnWidth(roomColumn),
              for (var i = 0; i < days.length; i++)
                i + 1: const FixedColumnWidth(dayColumn),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                children: [
                  const SizedBox.shrink(),
                  for (final date in days)
                    PartnerCalendarDayHeader(
                      date: date,
                      isToday: calendar.isToday(date),
                    ),
                ],
              ),
              for (final row in calendar.rows)
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.divider, width: .5),
                    ),
                  ),
                  children: [
                    PartnerCalendarRoomHeader(
                      roomName: row.room.roomName,
                      roomCode: row.room.roomCode,
                      hasError: row.hasError,
                    ),
                    if (row.hasError)
                      for (var i = 0; i < days.length; i++)
                        const SizedBox(height: 54)
                    else
                      for (final cell in row.cells)
                        PartnerCalendarCellTile(
                          cell: cell,
                          selected: _isSelected(cell),
                          isToday: calendar.isToday(cell.date),
                          onTap: () =>
                              calendar.selectCell(cell.roomId, cell.date),
                        ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isSelected(PartnerCalendarCell cell) {
    final selected = calendar.selectedCell;
    return selected != null &&
        selected.roomId == cell.roomId &&
        selected.date == cell.date;
  }
}

/// Mobile: one chosen day, every room.
class _MobileDayView extends StatefulWidget {
  final PartnerCalendarState calendar;

  const _MobileDayView({required this.calendar});

  @override
  State<_MobileDayView> createState() => _MobileDayViewState();
}

class _MobileDayViewState extends State<_MobileDayView> {
  int _dayIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerCalendarFormats.of(context);
    final calendar = widget.calendar;
    final days = calendar.days;
    final index = _dayIndex.clamp(0, days.length - 1);
    final date = days[index];

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The day picker scrolls; the room list below does not, so no
          // essential data is hidden behind a horizontal gesture.
          SizedBox(
            height: 62,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, i) {
                final day = days[i];
                final selected = i == index;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xxs),
                  child: ChoiceChip(
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(f.weekday.format(day),
                            style: const TextStyle(fontSize: 10)),
                        Text(f.dayOfMonth.format(day),
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _dayIndex = i),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.textInverse
                          : AppColors.textPrimary,
                    ),
                    selectedColor: AppColors.ocean700,
                    backgroundColor: AppColors.surfaceMuted,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            f.full.format(date),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final row in calendar.rows)
            if (row.hasError)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: PartnerCalendarNotice(
                  warning: true,
                  message: l10n.partnerCalendarRoomFailed(row.room.roomName),
                ),
              )
            else if (index < row.cells.length)
              PartnerCalendarDayRoomCard(
                roomName: row.room.roomName,
                roomCode: row.room.roomCode,
                cell: row.cells[index],
                selected: _isSelected(row.cells[index]),
                onTap: () => calendar.selectCell(
                    row.cells[index].roomId, row.cells[index].date),
              ),
        ],
      ),
    );
  }

  bool _isSelected(PartnerCalendarCell cell) {
    final selected = widget.calendar.selectedCell;
    return selected != null &&
        selected.roomId == cell.roomId &&
        selected.date == cell.date;
  }
}

/// The selected room-night, answering each availability question separately.
class _NightPanel extends StatelessWidget {
  final PartnerCalendarState calendar;
  final VoidCallback onManageRestrictions;

  const _NightPanel({
    required this.calendar,
    required this.onManageRestrictions,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerCalendarFormats.of(context);
    final cell = calendar.selectedCell!;
    final room = calendar.roomFor(cell.roomId);
    final day = cell.day;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerCalendarNightHeading(
                    room?.roomName ?? '',
                    f.full.format(cell.date),
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: calendar.clearSelection,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerCalendarCloseNight,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            children: [
              PartnerCalendarWindowPill(
                label: partnerNightStateLabel(l10n, cell.state),
                icon: partnerNightStateVisual(cell.state).icon,
                color: partnerNightStateVisual(cell.state).color,
              ),
              if (cell.isOccupied)
                PartnerCalendarWindowPill(
                  label: l10n
                      .partnerCalendarSoldValue(f.integer.format(cell.sold)),
                  icon: Icons.person_rounded,
                  color: AppColors.violet,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (day == null)
            PartnerCalendarNotice(
              warning: true,
              // The single most consequential thing to say correctly.
              message: l10n.partnerCalendarNoRecordExplanation,
            )
          else ...[
            // Straight from `RoomInventoryResponse`. Read-only here — C4 owns
            // every edit.
            PartnerCalendarFact(
              label: l10n.partnerCalendarFieldAvailable,
              value: f.integer.format(day.availableInventory),
            ),
            PartnerCalendarFact(
              label: l10n.partnerCalendarFieldSold,
              value: f.integer.format(day.soldInventory),
            ),
            PartnerCalendarFact(
              label: l10n.partnerCalendarFieldBlocked,
              value: f.integer.format(day.blockedInventory),
            ),
            PartnerCalendarFact(
              label: l10n.partnerCalendarFieldMaintenance,
              value: f.integer.format(day.maintenanceInventory),
            ),
            PartnerCalendarFact(
              label: l10n.partnerCalendarFieldTotal,
              value: f.integer.format(day.totalInventory),
            ),
            if (day.isInconsistent) ...[
              const SizedBox(height: AppSpacing.xs),
              PartnerCalendarNotice(
                warning: true,
                message: l10n.partnerCalendarInconsistentMessage,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.partnerCalendarQuestionsHeading,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            // Four separate questions, because the backend answers them with
            // four separate conditions.
            PartnerCalendarAnswer(
              question: l10n.partnerCalendarQuestionStock,
              answer: day.availableInventory > 0,
              reason: l10n.partnerCalendarReasonNoStock,
            ),
            PartnerCalendarAnswer(
              question: l10n.partnerCalendarQuestionSellable,
              answer: cell.state.isSellable,
              reason: day.stopSell
                  ? l10n.partnerCalendarReasonStopSell
                  : l10n.partnerCalendarReasonNoStock,
            ),
            PartnerCalendarAnswer(
              question: l10n.partnerCalendarQuestionArrival,
              answer: cell.canStartStay,
              reason: day.closedArrival
                  ? l10n.partnerCalendarReasonClosedArrival
                  : l10n.partnerCalendarReasonNotSellable,
            ),
            PartnerCalendarAnswer(
              question: l10n.partnerCalendarQuestionDeparture,
              answer: cell.canEndStay,
              reason: day.closedDeparture
                  ? l10n.partnerCalendarReasonClosedDeparture
                  : l10n.partnerCalendarReasonNotSellable,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.partnerCalendarQuestionsNote,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          PartnerCalendarNotice(
            message: l10n.partnerCalendarReadOnlyNote,
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OceanSecondaryButton(
              label: l10n.partnerCalendarManageRestrictions,
              icon: Icons.tune_rounded,
              fullWidth: false,
              // Hands over to C4 rather than duplicating its controls.
              onPressed: onManageRestrictions,
            ),
          ),
        ],
      ),
    );
  }
}
