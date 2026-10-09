import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_access_models.dart';
import '../../../core/partner/partner_booking_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../properties/widgets/partner_property_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_bookings_state.dart';
import 'partner_front_desk_state.dart';
import 'widgets/partner_booking_widgets.dart';

/// The Partner Bookings module — the operational reservation workspace.
///
/// ## Backend contract (verified in `backend-v1`/`develop` and live on :8081)
///
/// | Action | Endpoint | C8 |
/// |---|---|---|
/// | List / search / filter | `GET /api/partner/bookings` (server-paginated) | ✅ |
/// | Booking detail | `GET /api/partner/bookings/{id}` | ✅ |
/// | Guest stay projection | `GET /api/partner/stays/{bookingId}` | ✅ |
/// | Check-in / check-out / no-show / complete | `PATCH /api/partner/bookings/{id}/…` | ✅ |
/// | Front-desk check-in / check-out | `POST /api/partner/bookings/check-{in,out}` | ✅ |
/// | Cancel | — | ⛔ no partner endpoint |
/// | Modify / preview | — | ⛔ no partner endpoint |
/// | Payment actions | — | ⛔ no partner endpoint |
///
/// **Cancellation and modification are the customer's, not the partner's.**
/// `BookingService.cancel` and `BookingService.modify` both compare
/// `booking.getUser().getId()` against the caller and answer **403** to anyone
/// else — the property's own owner included. The modification *history* is
/// readable through the stay projection, and this screen renders it as history
/// with no control to create one.
///
/// **No payment control exists either.** There is no partner payment endpoint at
/// all, and `providerTransactionId` / `checkoutUrl` are not even parsed by
/// [PartnerBookingPayment], so a gateway id or a live payment link cannot be
/// rendered by accident.
///
/// ## Two tabs, because they address bookings differently
///
/// *Reservations* works from the list, by booking id, through the `PATCH`
/// endpoints. *Front desk* works by scanned voucher payload or typed booking
/// code through the `POST` endpoints — the idempotent pair that writes the
/// immutable check-in / check-out audit rows. Both reach the same
/// `BookingStatusEngineService`; neither invents a second state machine.
class PartnerBookingsScreen extends StatefulWidget {
  const PartnerBookingsScreen({super.key});

  @override
  State<PartnerBookingsScreen> createState() => _PartnerBookingsScreenState();
}

class _PartnerBookingsScreenState extends State<PartnerBookingsScreen>
    with SingleTickerProviderStateMixin {
  PartnerBookingsState? _bookings;
  PartnerFrontDeskState? _frontDesk;
  PartnerState? _partner;
  int? _syncedPropertyId;

  // Built eagerly: on a gated workspace `build` returns before the controller is
  // ever read, and a lazy `late final` would then be constructed for the first
  // time inside `dispose()`, against an already-deactivated element.
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
      _bookings?.dispose();
      _frontDesk?.dispose();
      _bookings = PartnerBookingsState(api: partner.api);
      _frontDesk = PartnerFrontDeskState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final bookings = _bookings!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) bookings.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _bookings?.dispose();
    _frontDesk?.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final partner = _partner;
    final bookings = _bookings;
    if (partner == null || bookings == null) return;
    await bookings.load(partner, partner.selectedPropertyId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final bookings = _bookings;
    final frontDesk = _frontDesk;

    if (!partner.isReady || bookings == null || frontDesk == null) {
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
                l10n.partnerBookingsTitle,
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
                  Tab(text: l10n.partnerBookingsTabReservations),
                  Tab(text: l10n.partnerBookingsTabFrontDesk),
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
                  animation: bookings,
                  builder: (context, _) => _ReservationsTab(
                    partner: partner,
                    bookings: bookings,
                    onReload: _reload,
                  ),
                )
              : AnimatedBuilder(
                  animation: frontDesk,
                  builder: (context, _) =>
                      _FrontDeskTab(frontDesk: frontDesk, onReload: _reload),
                ),
        ),
      ],
    );
  }
}

class _ReservationsTab extends StatelessWidget {
  final PartnerState partner;
  final PartnerBookingsState bookings;
  final Future<void> Function() onReload;

  const _ReservationsTab({
    required this.partner,
    required this.bookings,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    switch (bookings.status) {
      case PartnerBookingsStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerBookingsStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: bookings.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerBookingsStatus.notFound:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired,
          onPrimaryAction: onReload,
        );
      case PartnerBookingsStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: bookings.errorMessage,
          onPrimaryAction: onReload,
        );
      case PartnerBookingsStatus.idle:
      case PartnerBookingsStatus.loading:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BookingFilters(partner: partner, bookings: bookings),
            const SizedBox(height: AppSpacing.md),
            const _BookingsLoading(),
          ],
        );
      case PartnerBookingsStatus.ready:
        break;
    }

    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= AppBreakpoints.desktop;
    final open = bookings.openBookingId;

    final Widget list;
    if (bookings.isEmpty) {
      list = OceanStateView(
        icon: Icons.event_busy_outlined,
        title: bookings.isUnfilteredEmpty
            ? l10n.partnerBookingsEmptyTitle
            : l10n.partnerBookingsNoMatchTitle,
        message: bookings.isUnfilteredEmpty
            ? l10n.partnerBookingsEmptyMessage
            : l10n.partnerBookingsNoMatchMessage,
        semanticLabel: bookings.isUnfilteredEmpty
            ? l10n.partnerBookingsEmptyTitle
            : l10n.partnerBookingsNoMatchTitle,
        actionLabel:
            bookings.isUnfilteredEmpty ? null : l10n.partnerBookingFilterClear,
        onAction: bookings.isUnfilteredEmpty
            ? null
            : () => bookings.clearFilters(partner),
      );
    } else if (isDesktop && open == null) {
      list = PartnerBookingTable(
        bookings: bookings.bookings,
        openBookingId: open,
        onOpen: bookings.openBooking,
      );
    } else {
      // With a detail panel open the table would be squeezed below its
      // 1020px minimum and scroll horizontally inside a narrow column, so the
      // list falls back to cards.
      list = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final booking in bookings.bookings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: PartnerBookingCard(
                booking: booking,
                open: open == booking.id,
                onOpen: () => bookings.openBooking(booking.id),
              ),
            ),
        ],
      );
    }

    final detail = open == null
        ? null
        : _BookingDetailPanel(partner: partner, bookings: bookings);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookingFilters(partner: partner, bookings: bookings),
        const SizedBox(height: AppSpacing.md),
        if (isDesktop && detail != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: AppSpacing.md),
              Expanded(flex: 3, child: detail),
            ],
          )
        else ...[
          list,
          if (detail != null) ...[
            const SizedBox(height: AppSpacing.md),
            detail,
          ],
        ],
        if (!bookings.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Pagination(partner: partner, bookings: bookings),
        ],
      ],
    );
  }
}

/// Filters. Every control here maps to a real `@RequestParam`; nothing is
/// filtered client-side.
class _BookingFilters extends StatefulWidget {
  final PartnerState partner;
  final PartnerBookingsState bookings;

  const _BookingFilters({required this.partner, required this.bookings});

  @override
  State<_BookingFilters> createState() => _BookingFiltersState();
}

class _BookingFiltersState extends State<_BookingFilters> {
  late final TextEditingController _guest =
      TextEditingController(text: widget.bookings.query.guest ?? '');
  late final TextEditingController _code =
      TextEditingController(text: widget.bookings.query.bookingCode ?? '');

  @override
  void dispose() {
    _guest.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchesNames = widget.partner
        .holdsAnywhere(PartnerPermissionKeys.bookingGuestIdentityView);
    final searchesEmails = widget.partner
        .holdsAnywhere(PartnerPermissionKeys.bookingGuestContactView);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bookings = widget.bookings;
    final query = bookings.query;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  // Said plainly: the endpoint takes no hotelId, so this list
                  // spans every owned property.
                  l10n.partnerBookingsScopeNote,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              IconButton(
                onPressed: bookings.isLoading
                    ? null
                    : () => bookings.load(
                        widget.partner, widget.partner.selectedPropertyId),
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final filter in PartnerBookingQuickFilter.values)
                ChoiceChip(
                  label: Text(partnerBookingQuickFilterLabel(l10n, filter)),
                  selected: query.quickFilter == filter,
                  onSelected: bookings.isLoading
                      ? null
                      : (selected) => bookings.applyQuery(
                            widget.partner,
                            selected
                                ? query.copyWith(quickFilter: filter)
                                : query.copyWith(clearQuickFilter: true),
                          ),
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: query.quickFilter == filter
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.ocean700,
                  backgroundColor: AppColors.surfaceMuted,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (searchesNames || searchesEmails)
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _guest,
                    onSubmitted: (value) => bookings.applyQuery(
                      widget.partner,
                      value.trim().isEmpty
                          ? query.copyWith(clearGuest: true)
                          : query.copyWith(guest: value.trim()),
                    ),
                    decoration: InputDecoration(
                      // The server matches only what the caller may see:
                      // names with P54, emails with P35.
                      labelText: searchesNames && searchesEmails
                          ? l10n.partnerBookingFilterGuest
                          : searchesNames
                              ? l10n.partnerBookingFilterGuestName
                              : l10n.partnerBookingFilterGuestEmail,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _code,
                  onSubmitted: (value) => bookings.applyQuery(
                    widget.partner,
                    value.trim().isEmpty
                        ? query.copyWith(clearBookingCode: true)
                        : query.copyWith(bookingCode: value.trim()),
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.partnerBookingFilterCode,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 200,
                // Only real enum values are offered. An unrecognised status is
                // *silently ignored* by the backend specification, so free text
                // would quietly return an unfiltered list.
                child: DropdownButtonFormField<PartnerBookingStatus?>(
                  initialValue: query.status,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.partnerBookingFilterStatus,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.partnerBookingFilterAnyStatus),
                    ),
                    for (final status in PartnerBookingStatus.filterable)
                      DropdownMenuItem(
                        value: status,
                        child: Text(partnerBookingStatusLabel(l10n, status)),
                      ),
                  ],
                  onChanged: bookings.isLoading
                      ? null
                      : (value) => bookings.applyQuery(
                            widget.partner,
                            value == null
                                ? query.copyWith(clearStatus: true)
                                : query.copyWith(status: value),
                          ),
                ),
              ),
              if (bookings.rooms.isNotEmpty)
                SizedBox(
                  width: 220,
                  // `roomId` is the only property narrowing the backend
                  // supports; rooms belong to exactly one property.
                  child: DropdownButtonFormField<int?>(
                    initialValue: query.roomId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.partnerBookingFilterRoom,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(l10n.partnerBookingFilterAnyRoom),
                      ),
                      for (final room in bookings.rooms)
                        DropdownMenuItem(
                          value: room.id,
                          child: Text(room.roomName,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: bookings.isLoading
                        ? null
                        : (value) => bookings.applyQuery(
                              widget.partner,
                              value == null
                                  ? query.copyWith(clearRoom: true)
                                  : query.copyWith(roomId: value),
                            ),
                  ),
                ),
              OceanSecondaryButton(
                label: l10n.partnerBookingFilterDates,
                icon: Icons.date_range_rounded,
                fullWidth: false,
                onPressed:
                    bookings.isLoading ? null : () => _pickDateRange(context),
              ),
              if (query.hasActiveFilters)
                OceanSecondaryButton(
                  label: l10n.partnerBookingFilterClear,
                  icon: Icons.filter_alt_off_outlined,
                  fullWidth: false,
                  onPressed: bookings.isLoading
                      ? null
                      : () {
                          _guest.clear();
                          _code.clear();
                          bookings.clearFilters(widget.partner);
                        },
                ),
            ],
          ),
          if (query.checkInFrom != null || query.checkInTo != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              _dateRangeLabel(context, query),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  String _dateRangeLabel(BuildContext context, PartnerBookingQuery query) {
    final l10n = AppLocalizations.of(context)!;
    final f = PartnerBookingFormats.of(context);
    final from = query.checkInFrom;
    final to = query.checkInTo;
    // A partial range is a real request the backend honours, so each half is
    // described on its own rather than being forced into a pair.
    if (from != null && to != null) {
      return l10n.partnerBookingFilterRangeBoth(
          f.date.format(from), f.date.format(to));
    }
    if (from != null) {
      return l10n.partnerBookingFilterRangeFrom(f.date.format(from));
    }
    return l10n.partnerBookingFilterRangeTo(f.date.format(to!));
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final query = widget.bookings.query;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      initialDateRange: query.checkInFrom != null && query.checkInTo != null
          ? DateTimeRange(start: query.checkInFrom!, end: query.checkInTo!)
          : null,
    );
    if (picked == null || !context.mounted) return;
    await widget.bookings.applyQuery(
      widget.partner,
      query.copyWith(checkInFrom: picked.start, checkInTo: picked.end),
    );
  }
}

class _BookingsLoading extends StatelessWidget {
  const _BookingsLoading();

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
                  height: 56,
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

/// Real server-side pagination — `PageResponse` supplies every number here.
class _Pagination extends StatelessWidget {
  final PartnerState partner;
  final PartnerBookingsState bookings;

  const _Pagination({required this.partner, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);
    final page = bookings.page;

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          Text(
            l10n.partnerBookingPageRange(
              f.integer.format(page.firstIndex),
              f.integer.format(page.lastIndex),
              f.integer.format(page.totalElements),
            ),
            style: theme.textTheme.labelMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: page.hasPrevious && !bookings.isLoading
                    ? () => bookings.previousPage(partner)
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
                tooltip: l10n.partnerBookingPagePrevious,
              ),
              Text(
                l10n.partnerBookingPagePosition(
                  f.integer.format(page.page + 1),
                  f.integer.format(page.totalPages),
                ),
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: page.hasNext && !bookings.isLoading
                    ? () => bookings.nextPage(partner)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                tooltip: l10n.partnerBookingPageNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingDetailPanel extends StatelessWidget {
  final PartnerState partner;
  final PartnerBookingsState bookings;

  const _BookingDetailPanel({required this.partner, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.partnerBookingDetailHeading,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: bookings.closeDetail,
                icon: const Icon(Icons.close_rounded),
                tooltip: l10n.partnerBookingCloseDetail,
              ),
            ],
          ),
          if (bookings.isDetailLoading)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (bookings.detailErrorKind != null)
            PartnerBookingNotice(
              warning: true,
              message: _detailError(l10n, bookings.detailErrorKind),
            )
          else if (bookings.detail != null)
            _BookingDetailBody(partner: partner, bookings: bookings),
        ],
      ),
    );
  }

  String _detailError(AppLocalizations l10n, ApiErrorKind? kind) =>
      switch (kind) {
        ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
        ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
        ApiErrorKind.notFound => l10n.partnerBookingNotFound,
        ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
        ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
        _ => l10n.partnerDashboardErrorGeneric,
      };
}

class _BookingDetailBody extends StatelessWidget {
  final PartnerState partner;
  final PartnerBookingsState bookings;

  const _BookingDetailBody({required this.partner, required this.bookings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);
    final detail = bookings.detail!;
    final booking = detail.booking;
    final stay = bookings.stay;
    final absent = l10n.partnerPropertyNotSet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          booking.bookingCode,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xxs,
          children: [
            PartnerBookingStatusPill(status: booking.status),
            if (stay != null)
              OceanStatusPill(
                // The derived stay state is a *response-level* classification,
                // separate from the persisted booking status. Both are shown
                // because the backend keeps them separate.
                label: partnerStayStateLabel(l10n, stay.schedule.state),
                color: AppColors.ocean600,
                icon: Icons.hotel_outlined,
              ),
          ],
        ),

        if (stay != null && stay.warnings.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (final warning in stay.warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
              child: PartnerBookingNotice(
                message: partnerStayWarningLabel(l10n, warning),
                warning: warning.isActionable,
              ),
            ),
        ],

        const SizedBox(height: AppSpacing.md),
        _Actions(partner: partner, bookings: bookings, booking: booking),

        PartnerPropertySection(
          title: l10n.partnerBookingSectionGuest,
          children: [
            PartnerPropertyField(
                label: l10n.partnerBookingFieldGuestName,
                value: booking.guestName),
            // Shown here and nowhere else: a front desk legitimately needs to
            // reach the guest, but a dense list is the wrong place for it.
            PartnerPropertyField(
                label: l10n.partnerBookingFieldGuestEmail,
                value: booking.guestEmail),
            PartnerPropertyField(
              label: l10n.partnerBookingFieldOccupancy,
              value: l10n.partnerBookingOccupancyValue(
                f.integer.format(booking.adults),
                f.integer.format(booking.children),
              ),
            ),
            PartnerPropertyField(
                label: l10n.partnerBookingFieldSpecialRequest,
                value: booking.specialRequest),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerBookingSectionStay,
          children: [
            PartnerPropertyField(
              label: l10n.partnerBookingFieldCheckIn,
              value: booking.checkIn == null
                  ? null
                  : f.date.format(booking.checkIn!),
            ),
            PartnerPropertyField(
              label: l10n.partnerBookingFieldCheckOut,
              value: booking.checkOut == null
                  ? null
                  : f.date.format(booking.checkOut!),
            ),
            // Server-computed and half-open (checkIn <= night < checkOut),
            // deliberately unlike the inclusive C4/C5 windows. Never recomputed.
            PartnerPropertyField(
              label: l10n.partnerBookingFieldNights,
              value: f.integer.format(booking.nights),
            ),
            if (stay != null && stay.schedule.state == PartnerStayState.inHouse)
              PartnerPropertyField(
                label: l10n.partnerBookingFieldNightProgress,
                value: l10n.partnerBookingNightProgressValue(
                  f.integer.format(stay.schedule.currentNightNumber),
                  f.integer.format(stay.schedule.totalNights),
                ),
              ),
            PartnerPropertyField(
              label: l10n.partnerBookingFieldActualCheckIn,
              value: booking.actualCheckInAt == null
                  ? null
                  : f.dateTime.format(booking.actualCheckInAt!),
            ),
            PartnerPropertyField(
              label: l10n.partnerBookingFieldActualCheckOut,
              value: booking.actualCheckOutAt == null
                  ? null
                  : f.dateTime.format(booking.actualCheckOutAt!),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerBookingSectionRoom,
          children: [
            PartnerPropertyField(
                label: l10n.partnerBookingFieldProperty,
                value: booking.hotelName),
            PartnerPropertyField(
                label: l10n.partnerBookingFieldRoom, value: booking.roomName),
            PartnerPropertyField(
                label: l10n.partnerBookingFieldRoomCode,
                value: booking.roomCode),
            PartnerPropertyField(
              label: l10n.partnerBookingFieldRoomCount,
              value: f.integer.format(booking.numberOfRooms),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerBookingSectionPrice,
          children: [
            PartnerBookingAmountRow(
              label: l10n.partnerBookingFieldBasePrice,
              value: f.money(booking.basePrice, booking.currency, absent),
            ),
            if (booking.ratePlanPrice != null)
              PartnerBookingAmountRow(
                label: l10n.partnerBookingFieldRatePlanPrice,
                value: f.money(booking.ratePlanPrice, booking.currency, absent),
              ),
            if (booking.hasDiscount)
              PartnerBookingAmountRow(
                label: l10n.partnerBookingFieldDiscount,
                value:
                    f.money(booking.discountAmount, booking.currency, absent),
              ),
            PartnerBookingAmountRow(
              label: l10n.partnerBookingFieldTotal,
              value: f.money(booking.finalPrice, booking.currency, absent),
              emphasis: true,
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                // Says once that nothing here was calculated locally.
                l10n.partnerBookingPriceNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),

        // Rendered only when the booking actually captured a rate plan.
        // Historical values are never re-derived from today's rate plan.
        if (booking.hasRatePlanSnapshot)
          PartnerPropertySection(
            title: l10n.partnerBookingSectionRatePlan,
            children: [
              PartnerPropertyField(
                  label: l10n.partnerBookingFieldRatePlanName,
                  value: booking.selectedRatePlanName),
              PartnerPropertyField(
                  label: l10n.partnerBookingFieldRatePlanCode,
                  value: booking.selectedRatePlanCode),
              PartnerPropertyField(
                  label: l10n.partnerBookingFieldMealPlan,
                  value: booking.mealPlanType),
              PartnerPropertyField(
                  label: l10n.partnerBookingFieldCancellationPolicy,
                  value: booking.cancellationPolicyType),
              PartnerPropertyField(
                label: l10n.partnerBookingFieldCancellationDeadline,
                value: booking.cancellationDeadlineAt == null
                    ? null
                    : f.dateTime.format(booking.cancellationDeadlineAt!),
              ),
              PartnerPropertyField(
                label: l10n.partnerBookingFieldRefundable,
                value: booking.refundable == null
                    ? null
                    : (booking.refundable!
                        ? l10n.partnerRoomYes
                        : l10n.partnerRoomNo),
              ),
              PartnerPropertyField(
                label: l10n.partnerBookingFieldNightlySnapshot,
                value: booking.nightlyRateSnapshot == null
                    ? null
                    : f.money(
                        booking.nightlyRateSnapshot, booking.currency, absent),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  l10n.partnerBookingSnapshotNote,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ),
            ],
          ),

        PartnerPropertySection(
          title: l10n.partnerBookingSectionPayment,
          children: [
            if (!detail.hasPayments)
              Text(
                l10n.partnerBookingNoPayments,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              )
            else
              for (final payment in detail.payments)
                PartnerBookingPaymentRow(payment: payment),
            if (detail.invoice != null) ...[
              const SizedBox(height: AppSpacing.xs),
              PartnerPropertyField(
                label: l10n.partnerBookingFieldInvoice,
                value: detail.invoice!.invoiceNumber,
              ),
              PartnerPropertyField(
                label: l10n.partnerBookingFieldInvoiceStatus,
                value: detail.invoice!.status,
              ),
              PartnerBookingAmountRow(
                label: l10n.partnerBookingFieldInvoiceTotal,
                value: f.money(detail.invoice!.totalAmount,
                    detail.invoice!.currency, absent),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxs),
              child: Text(
                // States the limitation rather than leaving a dead control.
                l10n.partnerBookingPaymentReadOnlyNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ),
          ],
        ),

        PartnerPropertySection(
          title: l10n.partnerBookingSectionTimeline,
          children: [
            PartnerBookingTimelineView(events: detail.timeline),
          ],
        ),

        if (stay != null && stay.hasModifications)
          PartnerPropertySection(
            title: l10n.partnerBookingSectionModifications,
            children: [
              PartnerBookingNotice(
                  message: l10n.partnerBookingModificationNote),
              const SizedBox(height: AppSpacing.xs),
              for (final modification in stay.modifications)
                PartnerStayModificationRow(modification: modification),
            ],
          ),

        if (stay != null)
          PartnerPropertySection(
            title: l10n.partnerBookingSectionAudit,
            children: [
              if (!stay.hasAudit)
                Text(
                  l10n.partnerBookingNoAudit,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              if (stay.checkInAudit != null)
                PartnerStayAuditRow(
                  audit: stay.checkInAudit!,
                  label: l10n.partnerBookingAuditCheckIn,
                ),
              if (stay.checkOutAudit != null)
                PartnerStayAuditRow(
                  audit: stay.checkOutAudit!,
                  label: l10n.partnerBookingAuditCheckOut,
                ),
            ],
          ),
      ],
    );
  }
}

/// The lifecycle actions available for this booking's current status.
///
/// The set comes from `BookingStatusEngineService.ALLOWED`; an action the engine
/// would refuse is never offered, and the backend re-checks anyway. Every one is
/// irreversible, so each goes through an explicit confirmation step.
class _Actions extends StatelessWidget {
  final PartnerState partner;
  final PartnerBookingsState bookings;
  final PartnerBooking booking;

  const _Actions({
    required this.partner,
    required this.bookings,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actions = bookings.availableActionsFor(booking.status);
    final pending = bookings.pendingActionBookingId == booking.id;

    if (actions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: PartnerBookingNotice(
          message: booking.status.isClosed
              ? l10n.partnerBookingNoActionsClosed
              : l10n.partnerBookingNoActionsAvailable,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pending)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xs),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final action in actions)
                  OceanSecondaryButton(
                    label: partnerBookingActionLabel(l10n, action),
                    icon: _icon(action),
                    fullWidth: false,
                    onPressed: () => _confirmAndRun(context, action),
                  ),
              ],
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.partnerBookingActionsIrreversibleNote,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  IconData _icon(PartnerBookingAction action) => switch (action) {
        PartnerBookingAction.checkIn => Icons.login_rounded,
        PartnerBookingAction.checkOut => Icons.logout_rounded,
        PartnerBookingAction.noShow => Icons.person_off_outlined,
        PartnerBookingAction.complete => Icons.task_alt_rounded,
      };

  Future<void> _confirmAndRun(
    BuildContext context,
    PartnerBookingAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);

    // Every transition is one-way, so it needs a real confirmation step, not
    // just a button press.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(partnerBookingActionLabel(l10n, action)),
        content: Text(
          l10n.partnerBookingActionConfirm(
            partnerBookingActionLabel(l10n, action),
            booking.bookingCode,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.partnerBookingActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerBookingActionConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await bookings.runAction(
      partner: partner,
      bookingId: booking.id,
      action: action,
    );
    if (!context.mounted) return;

    final message = switch (result) {
      PartnerBookingActionResult.success => l10n.partnerBookingActionSucceeded(
          partnerBookingActionLabel(l10n, action), booking.bookingCode),
      PartnerBookingActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerBookingActionResult.forbidden =>
        l10n.partnerDashboardErrorForbidden,
      PartnerBookingActionResult.notFound => l10n.partnerBookingNotFound,
      PartnerBookingActionResult.rejected => l10n.partnerBookingActionRejected,
      PartnerBookingActionResult.validation =>
        l10n.partnerBookingActionValidation,
      PartnerBookingActionResult.uncertain =>
        l10n.partnerBookingActionUncertain,
      PartnerBookingActionResult.failed => l10n.partnerPropertyActionFailed,
    };
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The front-desk console: check a guest in or out by scanned voucher payload or
/// typed booking code.
class _FrontDeskTab extends StatefulWidget {
  final PartnerFrontDeskState frontDesk;
  final Future<void> Function() onReload;

  const _FrontDeskTab({required this.frontDesk, required this.onReload});

  @override
  State<_FrontDeskTab> createState() => _FrontDeskTabState();
}

class _FrontDeskTabState extends State<_FrontDeskTab> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.frontDesk.input);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final frontDesk = widget.frontDesk;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OceanGlassCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.partnerFrontDeskHeading,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.partnerFrontDeskNote,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.partnerBookingActionCheckIn),
                    icon: const Icon(Icons.login_rounded),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.partnerBookingActionCheckOut),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
                selected: {frontDesk.isCheckIn},
                onSelectionChanged: frontDesk.isWorking
                    ? null
                    : (values) => frontDesk.setCheckIn(values.first),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                onChanged: frontDesk.setInput,
                minLines: 1,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.partnerFrontDeskField,
                  hintText: 'PYT-V1.<bookingCode>.<signature>',
                  helperText: l10n.partnerFrontDeskFieldHelp,
                  helperMaxLines: 2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OceanPrimaryButton(
                    label: frontDesk.isCheckIn
                        ? l10n.partnerFrontDeskCheckInAction
                        : l10n.partnerFrontDeskCheckOutAction,
                    fullWidth: false,
                    onPressed: frontDesk.canSubmit
                        ? () => _confirmAndRun(context)
                        : null,
                  ),
                  OceanSecondaryButton(
                    label: l10n.partnerFrontDeskClear,
                    fullWidth: false,
                    onPressed: frontDesk.isWorking
                        ? null
                        : () {
                            _controller.clear();
                            frontDesk.clear();
                          },
                  ),
                ],
              ),
              if (frontDesk.isWorking) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
        if (!frontDesk.isWorking &&
            frontDesk.status != PartnerFrontDeskStatus.idle) ...[
          const SizedBox(height: AppSpacing.md),
          _FrontDeskResultCard(frontDesk: frontDesk),
        ],
      ],
    );
  }

  Future<void> _confirmAndRun(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final frontDesk = widget.frontDesk;

    // This mutates the booking and notifies the guest, so it is confirmed
    // explicitly rather than performed on a single tap.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(frontDesk.isCheckIn
            ? l10n.partnerFrontDeskCheckInAction
            : l10n.partnerFrontDeskCheckOutAction),
        content: Text(l10n.partnerFrontDeskConfirm(frontDesk.input.trim())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.partnerBookingActionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerBookingActionConfirmCta),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await frontDesk.submit();
    // The reservations list now shows a stale status for this booking.
    if (frontDesk.status == PartnerFrontDeskStatus.done) {
      await widget.onReload();
    }
  }
}

class _FrontDeskResultCard extends StatelessWidget {
  final PartnerFrontDeskState frontDesk;

  const _FrontDeskResultCard({required this.frontDesk});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerBookingFormats.of(context);
    final result = frontDesk.result;

    if (frontDesk.status != PartnerFrontDeskStatus.done || result == null) {
      final (icon, color, title, message) = switch (frontDesk.status) {
        PartnerFrontDeskStatus.notRecognised => (
            Icons.help_outline_rounded,
            AppColors.warning,
            l10n.partnerFrontDeskNotRecognisedTitle,
            l10n.partnerFrontDeskNotRecognisedMessage,
          ),
        PartnerFrontDeskStatus.rejected => (
            Icons.block_rounded,
            AppColors.warning,
            l10n.partnerFrontDeskRejectedTitle,
            // The server's own explanation — the status or the window rule.
            frontDesk.errorMessage ?? l10n.partnerFrontDeskRejectedMessage,
          ),
        PartnerFrontDeskStatus.invalidInput => (
            Icons.edit_outlined,
            AppColors.textTertiary,
            l10n.partnerFrontDeskInvalidTitle,
            l10n.partnerFrontDeskInvalidMessage,
          ),
        PartnerFrontDeskStatus.unauthorized => (
            Icons.lock_outline_rounded,
            AppColors.danger,
            l10n.partnerFrontDeskFailedTitle,
            l10n.partnerDashboardErrorUnauthorized,
          ),
        PartnerFrontDeskStatus.forbidden => (
            Icons.block_rounded,
            AppColors.danger,
            l10n.partnerFrontDeskFailedTitle,
            l10n.partnerDashboardErrorForbidden,
          ),
        PartnerFrontDeskStatus.uncertain => (
            Icons.sync_problem_rounded,
            AppColors.warning,
            l10n.partnerFrontDeskUncertainTitle,
            l10n.partnerFrontDeskUncertainMessage,
          ),
        _ => (
            Icons.cloud_off_rounded,
            AppColors.danger,
            l10n.partnerFrontDeskFailedTitle,
            frontDesk.errorMessage ?? l10n.partnerDashboardErrorGeneric,
          ),
      };
      return OceanGlassCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child:
            _Verdict(icon: icon, color: color, title: title, message: message),
      );
    }

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Verdict(
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
            title: frontDesk.isCheckIn
                ? l10n.partnerFrontDeskCheckedInTitle
                : l10n.partnerFrontDeskCheckedOutTitle,
            // The server's own message, verbatim: it is what distinguishes a
            // fresh transition from an idempotent repeat.
            message: result.message ?? '',
          ),
          const SizedBox(height: AppSpacing.md),
          PartnerPropertyField(
              label: l10n.partnerBookingColumnCode, value: result.bookingCode),
          PartnerPropertyField(
            label: l10n.partnerBookingColumnStatus,
            value: partnerBookingStatusLabel(l10n, result.status),
          ),
          PartnerPropertyField(
              label: l10n.partnerBookingFieldGuestName,
              value: result.guestName),
          PartnerPropertyField(
              label: l10n.partnerBookingFieldProperty, value: result.hotelName),
          PartnerPropertyField(
              label: l10n.partnerBookingFieldRoom, value: result.roomName),
          PartnerPropertyField(
            label: frontDesk.isCheckIn
                ? l10n.partnerBookingFieldActualCheckIn
                : l10n.partnerBookingFieldActualCheckOut,
            value: result.occurredAt == null
                ? null
                : f.dateTime.format(result.occurredAt!),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.partnerFrontDeskIdempotentNote,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _Verdict({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      label: '$title. $message',
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
