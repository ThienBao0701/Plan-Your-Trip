import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/partner/partner_dashboard_models.dart';
import '../../../../design/app_colors.dart';
import '../../../../design/app_radii.dart';
import '../../../../design/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/glass_widgets.dart';
import '../partner_dashboard_state.dart';

/// Formats the numbers the dashboard shows, in the viewer's locale.
///
/// Presentation only — no figure is computed here. Currency is rendered as a
/// plain grouped number rather than with a symbol, because the backend's
/// finance DTOs carry `BigDecimal` amounts with no currency code attached and
/// inventing one (₫? $?) would be a business claim the API never made.
class PartnerNumberFormats {
  final NumberFormat integer;
  final NumberFormat decimal;
  final NumberFormat money;
  final DateFormat shortDate;
  final DateFormat dateTime;

  PartnerNumberFormats(String locale)
      : integer = NumberFormat('#,##0', locale),
        decimal = NumberFormat('#,##0.0', locale),
        money = NumberFormat('#,##0.##', locale),
        shortDate = DateFormat.MMMd(locale),
        dateTime = DateFormat.yMMMd(locale).add_Hm();

  static PartnerNumberFormats of(BuildContext context) =>
      PartnerNumberFormats(Localizations.localeOf(context).toString());

  /// A percentage the backend already expressed as 0–100.
  String percent(double value) => '${decimal.format(value)}%';
}

/// A dashboard panel: heading, optional scope caption, and a body that renders
/// exactly one of loading / failed / empty / content.
///
/// Every panel owns its own outcome. One failing endpoint greys out one card
/// and leaves the rest of the console usable, which is what an operations tool
/// has to do — a partner checking today's arrivals should not lose them because
/// the revenue query timed out.
class PartnerDashboardSection extends StatelessWidget {
  final String title;

  /// What scope this panel's numbers describe. Shown because the panels do
  /// **not** all share one scope: `/partner/dashboard` is always "today, all
  /// properties" while the analytics panels follow the selected filter, and
  /// silently mixing the two would make the same metric look contradictory.
  final String? scopeCaption;

  final Widget? trailing;
  final Widget child;

  const PartnerDashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.scopeCaption,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (scopeCaption != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        scopeCaption!,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.textTertiary),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Inline body for a panel whose request failed.
///
/// Distinguishes the outcomes the backend actually produces rather than
/// collapsing them into "Something went wrong". The server's own message is
/// shown only when `ApiClient._safeServerMessage` already judged it safe
/// (short, tag-stripped) — this adds no new leak path.
class PartnerSectionFailure extends StatelessWidget {
  final ApiErrorKind? kind;
  final String? message;
  final VoidCallback? onRetry;

  const PartnerSectionFailure({
    super.key,
    required this.kind,
    this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final text = switch (kind) {
      ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
      ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
      ApiErrorKind.notFound => l10n.partnerDashboardErrorNotFound,
      ApiErrorKind.validation => l10n.partnerDashboardErrorValidation,
      ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
      ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
      ApiErrorKind.server => l10n.partnerDashboardErrorServer,
      _ => l10n.partnerDashboardErrorGeneric,
    };

    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    text,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                message!,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textTertiary),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(l10n.partnerActionRetry),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Body for a panel that loaded successfully but has nothing to show. A real
/// answer, visually distinct from a failure.
class PartnerSectionEmpty extends StatelessWidget {
  final String message;

  const PartnerSectionEmpty({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              const Icon(Icons.inbox_outlined,
                  size: 18, color: AppColors.textTertiary),
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

/// Skeleton body while a panel's request is in flight.
class PartnerSectionLoading extends StatelessWidget {
  final int lines;

  const PartnerSectionLoading({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < lines; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single KPI: a large backend-supplied value with a label and optional
/// caption.
///
/// The value is always rendered as text — the requirement that a chart never be
/// the only way to read the data is met by these tiles, which repeat every
/// figure the charts plot.
class PartnerKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final IconData icon;
  final Color accent;

  const PartnerKpiTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.caption,
    this.accent = AppColors.ocean600,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: caption == null ? '$label: $value' : '$label: $value. $caption',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: accent),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays KPI tiles out on a column count that suits the width. Wrap rather than
/// a fixed grid so large text scales push tiles onto new rows instead of
/// clipping, and so the console never scrolls sideways.
class PartnerKpiGrid extends StatelessWidget {
  final List<Widget> tiles;
  final double minTileWidth;

  const PartnerKpiGrid({
    super.key,
    required this.tiles,
    this.minTileWidth = 168,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = AppSpacing.sm;
          final maxColumns =
              (constraints.maxWidth / minTileWidth).floor().clamp(1, 4);
          final columns = tiles.length < maxColumns ? tiles.length : maxColumns;
          final safeColumns = columns < 1 ? 1 : columns;
          final width = (constraints.maxWidth - spacing * (safeColumns - 1)) /
              safeColumns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final tile in tiles) SizedBox(width: width, child: tile),
            ],
          );
        },
      );
}

/// The "needs attention" rail, built from `GET /api/partner/extranet/menu`.
///
/// Only entries the backend gave a positive `badgeCount` appear. A null badge
/// means "this destination has no counter", which is not the same as zero and
/// is never rendered as one.
class PartnerAttentionRail extends StatelessWidget {
  final List<PartnerMenuItem> items;
  final void Function(PartnerMenuItem item)? onOpen;

  const PartnerAttentionRail({super.key, required this.items, this.onOpen});

  /// Localised label for a backend menu key.
  ///
  /// `PartnerExtranetService.getMenu` hard-codes English labels
  /// (`"Dashboard"`, `"Hotels"`, ...), so they cannot be shown verbatim in a
  /// Vietnamese session. The `key` is the stable part of that contract, and it
  /// matches the navigation vocabulary C0 already localised — so these reuse
  /// the existing `partnerNav*` strings rather than adding a parallel set.
  /// An unrecognised key falls back to the server's own label, so a menu entry
  /// added server-side still renders instead of disappearing.
  static String labelFor(AppLocalizations l10n, PartnerMenuItem item) =>
      switch (item.key) {
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
        _ => item.label,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formats = PartnerNumberFormats.of(context);
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in items)
          _AttentionChip(
            label: labelFor(l10n, item),
            count: formats.integer.format(item.badgeCount ?? 0),
            semanticLabel: l10n.partnerDashboardAttentionSemantic(
              labelFor(l10n, item),
              item.badgeCount ?? 0,
            ),
            enabled: item.enabled,
            onTap: onOpen == null ? null : () => onOpen!(item),
          ),
      ],
    );
  }
}

class _AttentionChip extends StatelessWidget {
  final String label;
  final String count;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback? onTap;

  const _AttentionChip({
    required this.label,
    required this.count,
    required this.semanticLabel,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      enabled: enabled && onTap != null,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Material(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: Container(
              constraints:
                  const BoxConstraints(minHeight: AppSpacing.minTouchTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.warning,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      count,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
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

/// Quick actions, exactly as `PartnerExtranetService.buildQuickActions` supplied
/// them. The backend decides which are relevant; the client neither adds nor
/// reorders, and each one carries the backend's own `/partner/...` route.
class PartnerQuickActionsRow extends StatelessWidget {
  final List<PartnerQuickAction> actions;
  final void Function(PartnerQuickAction action)? onOpen;

  const PartnerQuickActionsRow({
    super.key,
    required this.actions,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final action in actions)
            OceanSecondaryButton(
              label: action.label,
              fullWidth: false,
              onPressed: onOpen == null ? null : () => onOpen!(action),
            ),
        ],
      );
}

/// The partner's own audit trail from `GET /api/partner/extranet/activity-logs`,
/// newest first as the repository returns it.
///
/// `action` is backend vocabulary (`SETTINGS_UPDATED`, ...). It is shown as-is
/// when there is no translation, because an audit line must say what the audit
/// record says.
class PartnerActivityList extends StatelessWidget {
  final List<PartnerActivityLogEntry> entries;
  final int maxEntries;

  const PartnerActivityList({
    super.key,
    required this.entries,
    this.maxEntries = 8,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formats = PartnerNumberFormats.of(context);
    final shown = entries.take(maxEntries).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0) const Divider(height: AppSpacing.md),
          _ActivityRow(entry: shown[i], formats: formats),
        ],
        if (entries.length > shown.length) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.partnerDashboardActivityMore(entries.length - shown.length),
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final PartnerActivityLogEntry entry;
  final PartnerNumberFormats formats;

  const _ActivityRow({required this.entry, required this.formats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final actor = entry.actorName ?? l10n.partnerDashboardActivityUnknownActor;
    final when = entry.createdAt == null
        ? null
        : formats.dateTime.format(entry.createdAt!);

    return Semantics(
      container: true,
      label: [
        entry.action,
        if (entry.description != null) entry.description!,
        actor,
        if (when != null) when,
      ].join('. '),
      child: ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.ocean500,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.description ?? entry.action,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      entry.action,
                      l10n.partnerDashboardActivityBy(actor),
                      if (when != null) when,
                    ].join(' · '),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled row of a monetary or counted finance figure.
class PartnerFinanceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasised;

  const PartnerFinanceRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: emphasised
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: emphasised ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: emphasised ? FontWeight.w800 : FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scope controls: the analytics window and the property filter.
///
/// The property list comes from `PartnerState.properties`, i.e. from
/// `GET /api/partner/hotels`. Nothing else can be selected, so the client can
/// never ask for a `hotelId` the backend did not already authorise.
class PartnerScopeBar extends StatelessWidget {
  final PartnerDashboardRange range;
  final int? selectedPropertyId;
  final List<({int id, String name})> properties;
  final bool enabled;
  final ValueChanged<PartnerDashboardRange> onRangeChanged;
  final ValueChanged<int?> onPropertyChanged;

  const PartnerScopeBar({
    super.key,
    required this.range,
    required this.selectedPropertyId,
    required this.properties,
    required this.onRangeChanged,
    required this.onPropertyChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    String rangeLabel(PartnerDashboardRange value) => switch (value) {
          PartnerDashboardRange.last7 => l10n.partnerDashboardRangeLast7,
          PartnerDashboardRange.last30 => l10n.partnerDashboardRangeLast30,
          PartnerDashboardRange.last90 => l10n.partnerDashboardRangeLast90,
        };

    // Chips in a Wrap rather than a SegmentedButton: a segmented control has an
    // intrinsic minimum width and overflows a phone-width card by a few pixels,
    // whereas chips reflow onto a second line at any width. The console must
    // never scroll sideways.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: l10n.partnerDashboardRangeLabel,
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final value in PartnerDashboardRange.values)
                ChoiceChip(
                  label: Text(rangeLabel(value)),
                  selected: value == range,
                  onSelected: enabled ? (_) => onRangeChanged(value) : null,
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: value == range
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.ocean700,
                  backgroundColor: AppColors.surfaceMuted,
                  showCheckmark: false,
                ),
            ],
          ),
        ),
        // Property scope as visible chips rather than a dropdown: on an
        // operations console the scope a number was computed in must be
        // readable at a glance, not one click away. "All properties" is a real
        // option because the backend's own default is every owned hotel
        // (`resolveHotelScope` with a null hotelId).
        if (properties.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Semantics(
            label: l10n.partnerDashboardPropertyLabel,
            child: Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text(l10n.partnerDashboardPropertyAll),
                  selected: selectedPropertyId == null,
                  onSelected: enabled ? (_) => onPropertyChanged(null) : null,
                  labelStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selectedPropertyId == null
                        ? AppColors.textInverse
                        : AppColors.textPrimary,
                  ),
                  selectedColor: AppColors.ocean700,
                  backgroundColor: AppColors.surfaceMuted,
                  showCheckmark: false,
                ),
                for (final property in properties)
                  ChoiceChip(
                    label: Text(
                      property.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: selectedPropertyId == property.id,
                    onSelected:
                        enabled ? (_) => onPropertyChanged(property.id) : null,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: selectedPropertyId == property.id
                          ? AppColors.textInverse
                          : AppColors.textPrimary,
                    ),
                    selectedColor: AppColors.ocean700,
                    backgroundColor: AppColors.surfaceMuted,
                    showCheckmark: false,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
