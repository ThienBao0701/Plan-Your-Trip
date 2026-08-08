import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'real_travel_wallet_screen.dart';

class TravelWalletScreen extends StatefulWidget {
  final DateTime? today;

  const TravelWalletScreen({super.key, this.today});

  @override
  State<TravelWalletScreen> createState() => _TravelWalletScreenState();
}

class _TravelWalletScreenState extends State<TravelWalletScreen> {
  final _search = TextEditingController();
  OrganizerCategory? _category;
  WalletItemType? _type;
  WalletItemStatus? _status;
  int? _linkedTripId;
  bool _favoritesOnly = false;
  bool _archivedOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Real Mode is fetch-backed and has its own loading/empty/error/refresh
    // lifecycle; Demo Mode keeps the exact local behaviour below.
    if (!app.demoMode) return const RealTravelWalletScreen();
    final l10n = AppLocalizations.of(context)!;
    final today = dateOnly(widget.today ?? app.now());
    final allItems = app.sortedWalletItems(today: today);
    final filtered = _filteredItems(allItems, today);
    final summary = WalletSummary.fromItems(allItems, today);

    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.travelWalletTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: ListView(
            key: const Key('travel-wallet-screen'),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            children: [
              OceanContentConstraint(
                maxWidth: AppBreakpoints.maxContentWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _WalletHeader(),
                    const SizedBox(height: AppSpacing.md),
                    _SummaryWrap(summary: summary),
                    const SizedBox(height: AppSpacing.lg),
                    _WalletFilters(
                      search: _search,
                      category: _category,
                      type: _type,
                      status: _status,
                      linkedTripId: _linkedTripId,
                      favoritesOnly: _favoritesOnly,
                      archivedOnly: _archivedOnly,
                      trips: app.trips,
                      onSearchChanged: (_) => setState(() {}),
                      onClearSearch: () => setState(() => _search.clear()),
                      onCategoryChanged: (value) =>
                          setState(() => _category = value),
                      onTypeChanged: (value) => setState(() => _type = value),
                      onStatusChanged: (value) =>
                          setState(() => _status = value),
                      onLinkedTripChanged: (value) =>
                          setState(() => _linkedTripId = value),
                      onFavoritesChanged: (value) =>
                          setState(() => _favoritesOnly = value),
                      onArchivedChanged: (value) =>
                          setState(() => _archivedOnly = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        OceanPrimaryButton(
                          key: const Key('wallet-create-item'),
                          label: l10n.walletCreateItemAction,
                          icon: Icons.add_card_rounded,
                          semanticLabel: l10n.walletCreateItemAction,
                          fullWidth: false,
                          onPressed: () => _showItemEditor(),
                        ),
                        OceanSecondaryButton(
                          key: const Key('wallet-import-booking'),
                          label: l10n.walletImportBookingAction,
                          icon: Icons.hotel_rounded,
                          semanticLabel: l10n.walletImportBookingAction,
                          fullWidth: false,
                          onPressed: _showBookingImport,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (filtered.isEmpty)
                      OceanEmptyState(
                        title: l10n.walletEmptyTitle,
                        message: l10n.walletEmptyMessage,
                      )
                    else
                      _WalletSections(
                        items: filtered,
                        today: today,
                        onTap: _showItemDetail,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TravelWalletItem> _filteredItems(
    List<TravelWalletItem> items,
    DateTime today,
  ) {
    final query = _search.text.trim().toLowerCase();
    return items.where((item) {
      final effective = item.effectiveStatus(today);
      if (_category != null && item.organizerCategory != _category) {
        return false;
      }
      if (_type != null && item.type != _type) return false;
      if (_status != null && effective != _status) return false;
      if (_linkedTripId != null && item.linkedTripId != _linkedTripId) {
        return false;
      }
      if (_favoritesOnly && !item.favorite) return false;
      if (_archivedOnly && !item.archived) return false;
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.issuer.toLowerCase().contains(query) ||
          item.maskedReference.toLowerCase().contains(query) ||
          (item.linkedTripTitle ?? '').toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _showItemEditor([TravelWalletItem? item]) async {
    final result = await showModalBottomSheet<WalletActionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletItemEditor(item: item),
    );
    if (!mounted || result == null) return;
    if (result == WalletActionResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.walletSavedMessage)),
      );
      return;
    }
    _showResultMessage(result);
  }

  Future<void> _showBookingImport() async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (!app.demoMode) {
      _showResultMessage(WalletActionResult.unavailable);
      return;
    }
    if (app.demoBookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletNoBookingsToImport)),
      );
      return;
    }
    final booking = await showModalBottomSheet<DemoBooking>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingImportSheet(bookings: app.demoBookings),
    );
    if (!mounted || booking == null) return;
    final existed = app.travelWalletItems
        .any((item) => item.linkedBookingId == booking.code);
    final imported = app.importDemoBookingToWallet(booking.code);
    if (!mounted || imported == null) {
      _showResultMessage(WalletActionResult.unavailable);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          existed
              ? l10n.walletBookingAlreadyImportedMessage
              : l10n.walletBookingImportedMessage,
        ),
      ),
    );
  }

  Future<void> _showItemDetail(TravelWalletItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletItemDetailSheet(
        item: item,
        today: dateOnly(widget.today ?? AppScope.of(context).now()),
        onEdit: () {
          Navigator.pop(context);
          _showItemEditor(item);
        },
        onFavorite: () {
          final app = AppScope.of(context);
          final result = app.setWalletFavorite(item.id, !item.favorite);
          Navigator.pop(context);
          _showResultMessage(result);
        },
        onArchive: () {
          final app = AppScope.of(context);
          final result = app.setWalletArchived(item.id, !item.archived);
          Navigator.pop(context);
          _showResultMessage(result);
        },
        onReminder: () {
          final app = AppScope.of(context);
          final result =
              app.setWalletExpiryReminder(item.id, !item.expiryReminderEnabled);
          Navigator.pop(context);
          _showResultMessage(result);
        },
        onDelete: () {
          Navigator.pop(context);
          _confirmDelete(item);
        },
      ),
    );
  }

  Future<void> _confirmDelete(TravelWalletItem item) async {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.walletDeleteConfirmTitle),
        content: Text(l10n.walletDeleteConfirmMessage(item.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.walletDeleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = app.deleteWalletItem(item.id);
    if (!mounted) return;
    if (result == WalletActionResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.walletDeletedMessage)),
      );
    } else {
      _showResultMessage(result);
    }
  }

  void _showResultMessage(WalletActionResult result) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (result) {
      WalletActionResult.success => l10n.walletSavedMessage,
      WalletActionResult.unavailable => l10n.walletActionUnavailable,
      WalletActionResult.blank => l10n.walletTitleRequiredMessage,
      WalletActionResult.duplicate => l10n.walletDuplicateMessage,
      WalletActionResult.rejected => l10n.walletActionRejectedMessage,
      WalletActionResult.invalidDateRange => l10n.walletInvalidDateMessage,
      WalletActionResult.unsafeUrl => l10n.tripDocumentUnsafeUrlMessage,
      WalletActionResult.notFound => l10n.walletNotFoundMessage,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _WalletHeader extends StatelessWidget {
  const _WalletHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.wallet_rounded,
                  color: AppColors.ocean, size: 36),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.travelWalletTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      l10n.walletDemoSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              OceanStatusPill(
                label: l10n.demoModeLabel,
                icon: Icons.science_rounded,
                color: AppColors.ocean,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          OceanGlassSurface(
            blur: 0,
            radius: AppRadii.lg,
            color: AppColors.paleCyan,
            child: Text(
              l10n.walletPrivacyNotice,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryWrap extends StatelessWidget {
  final WalletSummary summary;

  const _SummaryWrap({required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      (l10n.walletSummaryTotal, summary.total, Icons.inventory_2_rounded),
      (l10n.walletSummaryActive, summary.active, Icons.verified_rounded),
      (l10n.walletSummaryUpcoming, summary.upcoming, Icons.event_rounded),
      (
        l10n.walletSummaryExpiringSoon,
        summary.expiringSoon,
        Icons.timer_rounded
      ),
      (l10n.walletSummaryExpired, summary.expired, Icons.event_busy_rounded),
      (l10n.walletSummaryFavorites, summary.favorites, Icons.star_rounded),
      (l10n.walletSummaryArchived, summary.archived, Icons.archive_rounded),
      (l10n.walletSummaryUnlinked, summary.unlinked, Icons.link_off_rounded),
    ];
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final card in cards)
          SizedBox(
            width: 168,
            child: OceanGlassCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              semanticLabel: l10n.walletSummarySemantic(card.$1, card.$2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(card.$3, color: AppColors.ocean),
                  const SizedBox(height: AppSpacing.xs),
                  Text(card.$1, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${card.$2}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _WalletFilters extends StatelessWidget {
  final TextEditingController search;
  final OrganizerCategory? category;
  final WalletItemType? type;
  final WalletItemStatus? status;
  final int? linkedTripId;
  final bool favoritesOnly;
  final bool archivedOnly;
  final List<Trip> trips;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<OrganizerCategory?> onCategoryChanged;
  final ValueChanged<WalletItemType?> onTypeChanged;
  final ValueChanged<WalletItemStatus?> onStatusChanged;
  final ValueChanged<int?> onLinkedTripChanged;
  final ValueChanged<bool> onFavoritesChanged;
  final ValueChanged<bool> onArchivedChanged;

  const _WalletFilters({
    required this.search,
    required this.category,
    required this.type,
    required this.status,
    required this.linkedTripId,
    required this.favoritesOnly,
    required this.archivedOnly,
    required this.trips,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onCategoryChanged,
    required this.onTypeChanged,
    required this.onStatusChanged,
    required this.onLinkedTripChanged,
    required this.onFavoritesChanged,
    required this.onArchivedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanSearchField(
            key: const Key('wallet-search-field'),
            controller: search,
            hintText: l10n.walletSearchHint,
            semanticLabel: l10n.walletSearchHint,
            onChanged: onSearchChanged,
            onClear: onClearSearch,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SizedBox(
                width: 220,
                child: _Dropdown<OrganizerCategory>(
                  key: const Key('wallet-category-filter'),
                  label: l10n.walletFilterCategory,
                  value: category,
                  values: OrganizerCategory.values,
                  labelFor: (value) => walletCategoryLabel(l10n, value),
                  onChanged: onCategoryChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: _Dropdown<WalletItemType>(
                  key: const Key('wallet-type-filter'),
                  label: l10n.walletFilterType,
                  value: type,
                  values: WalletItemType.values,
                  labelFor: (value) => walletItemTypeLabel(l10n, value),
                  onChanged: onTypeChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: _Dropdown<WalletItemStatus>(
                  key: const Key('wallet-status-filter'),
                  label: l10n.walletFilterStatus,
                  value: status,
                  values: WalletItemStatus.values,
                  labelFor: (value) => walletStatusLabel(l10n, value),
                  onChanged: onStatusChanged,
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<int?>(
                  key: const Key('wallet-trip-filter'),
                  initialValue: linkedTripId,
                  isExpanded: true,
                  decoration:
                      InputDecoration(labelText: l10n.walletFilterLinkedTrip),
                  items: [
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.walletFilterAll),
                    ),
                    for (final trip in trips)
                      DropdownMenuItem<int?>(
                        value: trip.id,
                        child: Text(
                          trip.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onLinkedTripChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              FilterChip(
                key: const Key('wallet-favorites-filter'),
                selected: favoritesOnly,
                label: Text(l10n.walletFavoritesOnly),
                avatar: const Icon(Icons.star_rounded),
                onSelected: onFavoritesChanged,
              ),
              FilterChip(
                key: const Key('wallet-archived-filter'),
                selected: archivedOnly,
                label: Text(l10n.walletArchivedOnly),
                avatar: const Icon(Icons.archive_rounded),
                onSelected: onArchivedChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    super.key,
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(labelText: label),
        items: [
          DropdownMenuItem<T?>(
            value: null,
            child: Text(AppLocalizations.of(context)!.walletFilterAll),
          ),
          for (final item in values)
            DropdownMenuItem<T?>(
              value: item,
              child: Text(labelFor(item), overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      );
}

class _WalletSections extends StatelessWidget {
  final List<TravelWalletItem> items;
  final DateTime today;
  final ValueChanged<TravelWalletItem> onTap;

  const _WalletSections({
    required this.items,
    required this.today,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sections = [
      (
        key: 'favorites',
        title: l10n.walletSectionFavorites,
        items: items.where((item) => item.favorite && !item.archived).toList(),
      ),
      (
        key: 'expiring',
        title: l10n.walletSectionExpiringSoon,
        items:
            items.where((item) => walletItemExpiringSoon(item, today)).toList(),
      ),
      (
        key: 'upcoming',
        title: l10n.walletSectionUpcoming,
        items: items
            .where((item) =>
                item.effectiveStatus(today) == WalletItemStatus.upcoming)
            .toList(),
      ),
      (
        key: 'active',
        title: l10n.walletSectionActive,
        items: items
            .where((item) =>
                item.effectiveStatus(today) == WalletItemStatus.active)
            .toList(),
      ),
      (
        key: 'expired',
        title: l10n.walletSectionExpired,
        items: items
            .where((item) =>
                item.effectiveStatus(today) == WalletItemStatus.expired)
            .toList(),
      ),
      (
        key: 'archived',
        title: l10n.walletSectionArchived,
        items: items.where((item) => item.archived).toList(),
      ),
    ];
    final byCategory = <OrganizerCategory, int>{};
    final byTrip = <String, int>{};
    for (final item in items) {
      byCategory[item.organizerCategory] =
          (byCategory[item.organizerCategory] ?? 0) + 1;
      final trip = item.linkedTripTitle;
      if (trip != null && trip.isNotEmpty) {
        byTrip[trip] = (byTrip[trip] ?? 0) + 1;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections)
          if (section.items.isNotEmpty) ...[
            _SectionTitle(section.title),
            const SizedBox(height: AppSpacing.sm),
            for (final item in section.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _WalletItemCard(
                  item: item,
                  today: today,
                  sectionKey: section.key,
                  onTap: () => onTap(item),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        _SectionTitle(l10n.walletSectionByCategory),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final entry in byCategory.entries)
              OceanStatusPill(
                label:
                    '${walletCategoryLabel(l10n, entry.key)} (${entry.value})',
                icon: Icons.folder_rounded,
              ),
          ],
        ),
        if (byTrip.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionTitle(l10n.walletSectionByTrip),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final entry in byTrip.entries)
                OceanStatusPill(
                  label: '${entry.key} (${entry.value})',
                  icon: Icons.work_rounded,
                  color: AppColors.turquoise600,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) =>
      Text(title, style: Theme.of(context).textTheme.titleLarge);
}

class _WalletItemCard extends StatelessWidget {
  final TravelWalletItem item;
  final DateTime today;
  final String sectionKey;
  final VoidCallback onTap;

  const _WalletItemCard({
    required this.item,
    required this.today,
    required this.sectionKey,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = item.effectiveStatus(today);
    return OceanGlassCard(
      key: Key('wallet-item-${item.id}-$sectionKey'),
      onTap: onTap,
      semanticLabel: l10n.walletItemSemantic(item.title),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: _statusColor(status).withValues(alpha: .12),
            child: Icon(_typeIcon(item.type), color: _statusColor(status)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  walletItemTypeLabel(l10n, item.type),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (item.issuer.isNotEmpty)
                  Text(
                    item.issuer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    OceanStatusPill(
                      label: walletStatusLabel(l10n, status),
                      icon: Icons.verified_rounded,
                      color: _statusColor(status),
                    ),
                    if (item.maskedReference.isNotEmpty)
                      OceanStatusPill(
                        label: item.maskedReference,
                        icon: Icons.shield_rounded,
                        semanticLabel:
                            l10n.walletMaskedReference(item.maskedReference),
                      ),
                    if (item.linkedTripTitle != null)
                      OceanStatusPill(
                        label: item.linkedTripTitle!,
                        icon: Icons.work_rounded,
                        color: AppColors.turquoise600,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (item.favorite)
            const Icon(Icons.star_rounded, color: AppColors.warning),
        ],
      ),
    );
  }
}

class _WalletItemDetailSheet extends StatelessWidget {
  final TravelWalletItem item;
  final DateTime today;
  final VoidCallback onEdit;
  final VoidCallback onFavorite;
  final VoidCallback onArchive;
  final VoidCallback onReminder;
  final VoidCallback onDelete;

  const _WalletItemDetailSheet({
    required this.item,
    required this.today,
    required this.onEdit,
    required this.onFavorite,
    required this.onArchive,
    required this.onReminder,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status = item.effectiveStatus(today);
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(item.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                OceanStatusPill(
                  label: walletItemTypeLabel(l10n, item.type),
                  icon: _typeIcon(item.type),
                ),
                OceanStatusPill(
                  label: walletStatusLabel(l10n, status),
                  icon: Icons.verified_rounded,
                  color: _statusColor(status),
                ),
                OceanStatusPill(
                  label: walletSourceLabel(l10n, item.sourceType),
                  icon: Icons.source_rounded,
                  color: AppColors.turquoise600,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DetailRow(
              icon: Icons.account_balance_rounded,
              label: l10n.walletIssuerLabel,
              value: item.issuer.isEmpty ? l10n.walletNoValue : item.issuer,
            ),
            if (item.maskedReference.isNotEmpty)
              _DetailRow(
                icon: Icons.shield_rounded,
                label: l10n.walletReferenceLabel,
                value: item.maskedReference,
                semanticValue: l10n.walletMaskedReference(item.maskedReference),
              ),
            _DetailRow(
              icon: Icons.date_range_rounded,
              label: l10n.walletValidityLabel,
              value: walletValidityLabel(context, item),
            ),
            if (item.linkedTripTitle != null)
              _DetailRow(
                icon: Icons.work_rounded,
                label: l10n.walletLinkedTripLabel,
                value: item.linkedTripTitle!,
              ),
            _DetailRow(
              icon: Icons.notifications_active_rounded,
              label: l10n.walletReminderLabel,
              value: item.expiryReminderEnabled
                  ? l10n.walletReminderEnabled
                  : l10n.walletReminderDisabled,
            ),
            const SizedBox(height: AppSpacing.md),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Text(
                l10n.walletPrivacyNotice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OceanSecondaryButton(
                  key: const Key('wallet-detail-edit'),
                  label: l10n.walletEditAction,
                  icon: Icons.edit_rounded,
                  fullWidth: false,
                  onPressed: onEdit,
                ),
                OceanSecondaryButton(
                  key: const Key('wallet-detail-favorite'),
                  label: item.favorite
                      ? l10n.walletUnfavoriteAction
                      : l10n.walletFavoriteAction,
                  icon: item.favorite
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                  fullWidth: false,
                  onPressed: onFavorite,
                ),
                OceanSecondaryButton(
                  key: const Key('wallet-detail-archive'),
                  label: item.archived
                      ? l10n.walletRestoreAction
                      : l10n.walletArchiveAction,
                  icon: item.archived
                      ? Icons.unarchive_rounded
                      : Icons.archive_rounded,
                  fullWidth: false,
                  onPressed: onArchive,
                ),
                OceanSecondaryButton(
                  key: const Key('wallet-detail-reminder'),
                  label: item.expiryReminderEnabled
                      ? l10n.walletReminderDisableAction
                      : l10n.walletReminderEnableAction,
                  icon: Icons.notifications_active_rounded,
                  fullWidth: false,
                  onPressed: onReminder,
                ),
                OceanSecondaryButton(
                  key: const Key('wallet-detail-delete'),
                  label: l10n.walletDeleteAction,
                  icon: Icons.delete_rounded,
                  fullWidth: false,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletItemEditor extends StatefulWidget {
  final TravelWalletItem? item;

  const _WalletItemEditor({this.item});

  @override
  State<_WalletItemEditor> createState() => _WalletItemEditorState();
}

class _WalletItemEditorState extends State<_WalletItemEditor> {
  late final TextEditingController _title;
  late final TextEditingController _issuer;
  late final TextEditingController _reference;
  late WalletItemType _type;
  late WalletItemStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _issuer = TextEditingController(text: item?.issuer ?? '');
    _reference = TextEditingController();
    _type = item?.type ?? WalletItemType.passport;
    _status = item?.status ?? WalletItemStatus.active;
  }

  @override
  void dispose() {
    _title.dispose();
    _issuer.dispose();
    _reference.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              item == null ? l10n.walletCreateTitle : l10n.walletEditTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('wallet-title-field'),
              controller: _title,
              decoration: InputDecoration(labelText: l10n.walletTitleLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _issuer,
              decoration: InputDecoration(labelText: l10n.walletIssuerLabel),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              key: const Key('wallet-reference-field'),
              controller: _reference,
              decoration: InputDecoration(
                labelText: l10n.walletReferenceInputLabel,
                helperText: l10n.walletReferencePrivacyHelper,
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppSpacing.sm),
            _Dropdown<WalletItemType>(
              label: l10n.walletTypeLabel,
              value: _type,
              values: WalletItemType.values,
              labelFor: (value) => walletItemTypeLabel(l10n, value),
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _Dropdown<WalletItemStatus>(
              label: l10n.walletStatusLabel,
              value: _status,
              values: WalletItemStatus.values
                  .where((status) => status != WalletItemStatus.expired)
                  .toList(),
              labelFor: (value) => walletStatusLabel(l10n, value),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            OceanGlassSurface(
              blur: 0,
              color: AppColors.paleCyan,
              child: Text(
                l10n.walletReferencePrivacyHelper,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            OceanPrimaryButton(
              key: const Key('wallet-save-item'),
              label: l10n.walletSaveAction,
              icon: Icons.save_rounded,
              onPressed: _saving
                  ? null
                  : () {
                      setState(() => _saving = true);
                      final now = app.now();
                      final rawRef = _reference.text.trim();
                      final draft = TravelWalletItem(
                        id: item?.id ??
                            'wallet-local-${now.microsecondsSinceEpoch}-${app.travelWalletItems.length}',
                        linkedTripId: item?.linkedTripId,
                        linkedTripTitle: item?.linkedTripTitle,
                        linkedDocumentId: item?.linkedDocumentId,
                        linkedBookingId: item?.linkedBookingId,
                        linkedInvoiceId: item?.linkedInvoiceId,
                        type: _type,
                        title: _title.text.trim(),
                        issuer: _issuer.text.trim(),
                        maskedReference: rawRef.isEmpty
                            ? item?.maskedReference ?? ''
                            : maskSensitiveReference(rawRef),
                        validFrom: item?.validFrom,
                        validUntil: item?.validUntil,
                        status: _status,
                        favorite: item?.favorite ?? false,
                        archived: item?.archived ?? false,
                        expiryReminderEnabled:
                            item?.expiryReminderEnabled ?? false,
                        createdAt: item?.createdAt ?? now,
                        updatedAt: now,
                      );
                      final result = item == null
                          ? app.addWalletItem(draft)
                          : app.updateWalletItem(draft);
                      Navigator.pop(context, result);
                    },
            ),
            const SizedBox(height: AppSpacing.sm),
            OceanSecondaryButton(
              label: l10n.profileCancel,
              icon: Icons.close_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingImportSheet extends StatelessWidget {
  final List<DemoBooking> bookings;

  const _BookingImportSheet({required this.bookings});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassBottomSheet(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.walletImportBookingAction,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            for (final booking in bookings)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: OceanGlassCard(
                  key: Key('wallet-import-booking-${booking.code}'),
                  onTap: () => Navigator.pop(context, booking),
                  child: Row(
                    children: [
                      const Icon(Icons.hotel_rounded, color: AppColors.ocean),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.hotel.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              l10n.bookingLocalCode(
                                maskSensitiveReference(booking.code),
                              ),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? semanticValue;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.semanticValue,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$label ${semanticValue ?? value}',
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.ocean),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.labelLarge),
                    Text(value, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class WalletSummary {
  final int total;
  final int active;
  final int upcoming;
  final int expiringSoon;
  final int expired;
  final int favorites;
  final int archived;
  final int unlinked;

  const WalletSummary({
    required this.total,
    required this.active,
    required this.upcoming,
    required this.expiringSoon,
    required this.expired,
    required this.favorites,
    required this.archived,
    required this.unlinked,
  });

  factory WalletSummary.fromItems(
    List<TravelWalletItem> items,
    DateTime today,
  ) {
    int countStatus(WalletItemStatus status) =>
        items.where((item) => item.effectiveStatus(today) == status).length;
    return WalletSummary(
      total: items.length,
      active: countStatus(WalletItemStatus.active),
      upcoming: countStatus(WalletItemStatus.upcoming),
      expiringSoon:
          items.where((item) => walletItemExpiringSoon(item, today)).length,
      expired: countStatus(WalletItemStatus.expired),
      favorites: items.where((item) => item.favorite).length,
      archived: countStatus(WalletItemStatus.archived),
      unlinked: items
          .where((item) =>
              item.linkedTripId == null &&
              item.linkedDocumentId == null &&
              item.linkedBookingId == null &&
              item.linkedInvoiceId == null)
          .length,
    );
  }
}

bool walletItemExpiringSoon(TravelWalletItem item, DateTime today) {
  final validUntil = item.validUntil;
  if (validUntil == null) return false;
  if (item.effectiveStatus(today) != WalletItemStatus.active) return false;
  final days = dateOnly(validUntil).difference(dateOnly(today)).inDays;
  return days >= 0 && days <= 30;
}

String walletValidityLabel(BuildContext context, TravelWalletItem item) {
  final l10n = AppLocalizations.of(context)!;
  final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
  final from = item.validFrom;
  final until = item.validUntil;
  if (from == null && until == null) return l10n.walletNoValidity;
  if (from == null) return l10n.walletValidUntil(date.format(until!));
  if (until == null) return l10n.walletValidFrom(date.format(from));
  return l10n.walletValidPeriod(date.format(from), date.format(until));
}

String walletItemTypeLabel(AppLocalizations l10n, WalletItemType type) {
  switch (type) {
    case WalletItemType.passport:
      return l10n.walletTypePassport;
    case WalletItemType.visa:
      return l10n.walletTypeVisa;
    case WalletItemType.boardingPass:
      return l10n.walletTypeBoardingPass;
    case WalletItemType.flightTicket:
      return l10n.walletTypeFlightTicket;
    case WalletItemType.trainTicket:
      return l10n.walletTypeTrainTicket;
    case WalletItemType.busTicket:
      return l10n.walletTypeBusTicket;
    case WalletItemType.hotelVoucher:
      return l10n.walletTypeHotelVoucher;
    case WalletItemType.tourVoucher:
      return l10n.walletTypeTourVoucher;
    case WalletItemType.insurance:
      return l10n.walletTypeInsurance;
    case WalletItemType.bookingConfirmation:
      return l10n.walletTypeBookingConfirmation;
    case WalletItemType.invoice:
      return l10n.walletTypeInvoice;
    case WalletItemType.receipt:
      return l10n.walletTypeReceipt;
    case WalletItemType.itinerary:
      return l10n.walletTypeItinerary;
    case WalletItemType.other:
      return l10n.walletTypeOther;
  }
}

String walletStatusLabel(AppLocalizations l10n, WalletItemStatus status) {
  switch (status) {
    case WalletItemStatus.active:
      return l10n.walletStatusActive;
    case WalletItemStatus.upcoming:
      return l10n.walletStatusUpcoming;
    case WalletItemStatus.expired:
      return l10n.walletStatusExpired;
    case WalletItemStatus.cancelled:
      return l10n.walletStatusCancelled;
    case WalletItemStatus.archived:
      return l10n.walletStatusArchived;
  }
}

String walletCategoryLabel(AppLocalizations l10n, OrganizerCategory category) {
  switch (category) {
    case OrganizerCategory.identity:
      return l10n.walletCategoryIdentity;
    case OrganizerCategory.transport:
      return l10n.walletCategoryTransport;
    case OrganizerCategory.accommodation:
      return l10n.walletCategoryAccommodation;
    case OrganizerCategory.activity:
      return l10n.walletCategoryActivity;
    case OrganizerCategory.insurance:
      return l10n.walletCategoryInsurance;
    case OrganizerCategory.financial:
      return l10n.walletCategoryFinancial;
    case OrganizerCategory.other:
      return l10n.walletCategoryOther;
  }
}

String walletSourceLabel(AppLocalizations l10n, WalletSourceType source) {
  switch (source) {
    case WalletSourceType.metadata:
      return l10n.walletSourceMetadata;
    case WalletSourceType.tripDocument:
      return l10n.walletSourceTripDocument;
    case WalletSourceType.booking:
      return l10n.walletSourceBooking;
    case WalletSourceType.invoice:
      return l10n.walletSourceInvoice;
  }
}

IconData _typeIcon(WalletItemType type) {
  switch (type) {
    case WalletItemType.passport:
    case WalletItemType.visa:
      return Icons.badge_rounded;
    case WalletItemType.boardingPass:
    case WalletItemType.flightTicket:
      return Icons.flight_rounded;
    case WalletItemType.trainTicket:
      return Icons.train_rounded;
    case WalletItemType.busTicket:
      return Icons.directions_bus_rounded;
    case WalletItemType.hotelVoucher:
    case WalletItemType.bookingConfirmation:
      return Icons.hotel_rounded;
    case WalletItemType.tourVoucher:
    case WalletItemType.itinerary:
      return Icons.explore_rounded;
    case WalletItemType.insurance:
      return Icons.health_and_safety_rounded;
    case WalletItemType.invoice:
    case WalletItemType.receipt:
      return Icons.receipt_long_rounded;
    case WalletItemType.other:
      return Icons.description_rounded;
  }
}

Color _statusColor(WalletItemStatus status) {
  switch (status) {
    case WalletItemStatus.active:
      return AppColors.success;
    case WalletItemStatus.upcoming:
      return AppColors.ocean;
    case WalletItemStatus.expired:
      return AppColors.warning;
    case WalletItemStatus.cancelled:
      return AppColors.danger;
    case WalletItemStatus.archived:
      return AppColors.textTertiary;
  }
}
