import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_client.dart';
import '../../../core/partner/partner_dashboard_models.dart';
import '../../../core/partner/partner_finance_models.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_radii.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../finance/partner_finance_state.dart' show PartnerFinanceSection;

/// Formats for the finance and analytics modules.
///
/// **No currency symbol is ever applied.** Not one of the seven finance DTOs
/// carries a currency field, so amounts are grouped numbers and each screen says
/// so once. This is read from `PartnerFinanceDto` directly, and it is not the
/// same question as the `Booking`/`Payment` currency, which C8 does show.
class PartnerMetricFormats {
  final NumberFormat amount;
  final NumberFormat integer;
  final NumberFormat decimal;
  final DateFormat date;
  final DateFormat monthDay;

  PartnerMetricFormats(String locale)
      : amount = NumberFormat('#,##0.##', locale),
        integer = NumberFormat('#,##0', locale),
        decimal = NumberFormat('#,##0.0#', locale),
        date = DateFormat.yMMMd(locale),
        monthDay = DateFormat.MMMd(locale);

  static PartnerMetricFormats of(BuildContext context) =>
      PartnerMetricFormats(Localizations.localeOf(context).toString());

  /// Renders a server amount. Formatting only — never arithmetic.
  String money(PartnerMoney? value, String absent) =>
      value == null ? absent : amount.format(value.value);

  /// A server-supplied percentage, shown with its unit.
  String percent(double? value, String absent) =>
      value == null ? absent : '${decimal.format(value)}%';

  /// A fraction the server expresses as `0.15`, shown as `15%`.
  ///
  /// This multiplies a *rate*, not a money amount, purely to label it — no
  /// monetary figure is derived from it anywhere.
  String rate(double fraction) => '${amount.format(fraction * 100)}%';
}

/// Wraps one independently-loaded section so loading, failure, emptiness and
/// data are always told apart.
///
/// A failed section renders as failed — never as an empty one, which for
/// finance would read as "you earned nothing".
class PartnerSectionCard<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final PartnerFinanceSection<T> section;

  /// True when the loaded data genuinely contains no observations.
  final bool Function(T data) isEmpty;

  final String emptyMessage;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  const PartnerSectionCard({
    super.key,
    required this.title,
    required this.section,
    required this.isEmpty,
    required this.emptyMessage,
    required this.builder,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          if (section.loading)
            const _SectionSkeleton()
          else if (section.hasError)
            PartnerMetricNotice(
              warning: true,
              message: _errorText(l10n, section.errorKind),
              onRetry: onRetry,
            )
          else if (!section.hasData)
            PartnerMetricNotice(message: l10n.partnerMetricNotLoaded)
          else if (isEmpty(section.data as T))
            Text(
              emptyMessage,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            )
          else
            builder(section.data as T),
        ],
      ),
    );
  }

  String _errorText(AppLocalizations l10n, ApiErrorKind? kind) =>
      switch (kind) {
        ApiErrorKind.unauthorized => l10n.partnerDashboardErrorUnauthorized,
        ApiErrorKind.forbidden => l10n.partnerDashboardErrorForbidden,
        ApiErrorKind.notFound => l10n.partnerMetricScopeNotFound,
        ApiErrorKind.validation => l10n.partnerMetricInvalidRange,
        ApiErrorKind.timeout => l10n.partnerDashboardErrorTimeout,
        ApiErrorKind.network => l10n.partnerDashboardErrorNetwork,
        _ => l10n.partnerDashboardErrorGeneric,
      };
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.partnerStatusLoadingTitle,
      liveRegion: true,
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Container(
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppSpacing.xs),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A headline money figure.
///
/// Deliberately shows no currency symbol and no approximation: the exact server
/// value, grouped for readability.
class PartnerAmountTile extends StatelessWidget {
  final String label;
  final PartnerMoney? amount;
  final String? caption;
  final bool emphasis;

  const PartnerAmountTile({
    super.key,
    required this.label,
    required this.amount,
    this.caption,
    this.emphasis = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerMetricFormats.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasis
            ? AppColors.ocean700.withValues(alpha: .08)
            : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            f.money(amount, l10n.partnerPropertyNotSet),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasis ? AppColors.ocean700 : AppColors.textPrimary,
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
    );
  }
}

/// A non-monetary figure: a count, a rate, or an explicit "not available".
class PartnerStatTile extends StatelessWidget {
  final String label;

  /// Null renders as unavailable rather than as zero — the two mean different
  /// things and the backend distinguishes them.
  final String? value;

  final IconData icon;
  final Color color;
  final String? caption;

  const PartnerStatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.ocean600,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final unavailable = value == null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value ?? l10n.partnerMetricUnavailable,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: unavailable ? FontWeight.w500 : FontWeight.w800,
              color:
                  unavailable ? AppColors.textTertiary : AppColors.textPrimary,
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
    );
  }
}

/// A ranked breakdown with proportional bars.
///
/// The bar width is a display proportion computed from the largest value in the
/// list; it is geometry, never a figure shown as money. Every number printed is
/// the server's own.
class PartnerBreakdownList extends StatelessWidget {
  final List<PartnerMetricBreakdown> entries;

  /// True when `value` is money, false when it is a count.
  final bool valueIsMoney;

  final Color color;
  final int maxEntries;

  const PartnerBreakdownList({
    super.key,
    required this.entries,
    required this.valueIsMoney,
    this.color = AppColors.ocean600,
    this.maxEntries = 8,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = PartnerMetricFormats.of(context);
    final shown = entries.take(maxEntries).toList(growable: false);
    final largest = shown.fold<double>(
        0, (max, e) => e.value.abs() > max ? e.value.abs() : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      valueIsMoney
                          ? f.amount.format(entry.value)
                          : f.integer.format(entry.value),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fraction =
                        largest == 0 ? 0.0 : entry.value.abs() / largest;
                    return Stack(
                      children: [
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        Container(
                          height: 6,
                          width: (constraints.maxWidth * fraction)
                              .clamp(0.0, constraints.maxWidth),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A compact daily bar chart over a server time series.
///
/// Bar heights are display geometry derived from the largest point; no value is
/// smoothed, interpolated or recomputed, and days the server sent as zero stay
/// visible as zero.
class PartnerDailyBars extends StatelessWidget {
  final List<PartnerTimeSeriesPoint> points;
  final Color color;

  const PartnerDailyBars({
    super.key,
    required this.points,
    this.color = AppColors.ocean600,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerMetricFormats.of(context);
    if (points.isEmpty) return const SizedBox.shrink();

    final largest =
        points.fold<double>(0, (max, p) => p.value > max ? p.value : max);
    final peak = points.reduce((a, b) => b.value > a.value ? b : a);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.partnerMetricPeakDay(
            f.date.format(peak.date),
            f.amount.format(peak.value),
          ),
          child: ExcludeSemantics(
            child: SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final point in points)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: largest == 0
                                  ? 2
                                  : (2 + 78 * (point.value / largest))
                                      .clamp(2.0, 80.0),
                              decoration: BoxDecoration(
                                color: point.value == 0
                                    ? AppColors.divider
                                    : color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              f.monthDay.format(points.first.date),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
            Text(
              f.monthDay.format(points.last.date),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}

/// A short inline statement — a limitation, a warning, or an explanation.
class PartnerMetricNotice extends StatelessWidget {
  final String message;
  final bool warning;
  final VoidCallback? onRetry;

  const PartnerMetricNotice({
    super.key,
    required this.message,
    this.warning = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = warning ? AppColors.warning : AppColors.ocean600;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  OceanSecondaryButton(
                    label: l10n.partnerActionRefresh,
                    icon: Icons.refresh_rounded,
                    fullWidth: false,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared scope and date-window bar.
///
/// Both modules send the same `hotelId`/`from`/`to` triple, so they share one
/// control rather than growing two that could drift apart.
class PartnerRangeBar extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final bool isPartnerWide;
  final bool busy;
  final String scopeNote;
  final Future<void> Function(DateTime from, DateTime to) onRangeChanged;
  final VoidCallback onReset;
  final VoidCallback onRefresh;

  const PartnerRangeBar({
    super.key,
    required this.from,
    required this.to,
    required this.isPartnerWide,
    required this.busy,
    required this.scopeNote,
    required this.onRangeChanged,
    required this.onReset,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final f = PartnerMetricFormats.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scopeNote,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OceanStatusPill(
                label: l10n.partnerMetricWindow(
                    f.date.format(from), f.date.format(to)),
                color: AppColors.ocean700,
                icon: Icons.date_range_rounded,
              ),
              if (isPartnerWide)
                OceanStatusPill(
                  label: l10n.partnerMetricAllProperties,
                  color: AppColors.violet,
                  icon: Icons.apartment_rounded,
                ),
              OceanSecondaryButton(
                label: l10n.partnerMetricChangeRange,
                icon: Icons.edit_calendar_outlined,
                fullWidth: false,
                onPressed: busy ? null : () => _pick(context),
              ),
              OceanSecondaryButton(
                label: l10n.partnerMetricDefaultRange,
                icon: Icons.restart_alt_rounded,
                fullWidth: false,
                onPressed: busy ? null : onReset,
              ),
              IconButton(
                onPressed: busy ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.partnerActionRefresh,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(start: from, end: to),
    );
    if (picked == null || !context.mounted) return;
    await onRangeChanged(picked.start, picked.end);
  }
}
