import 'package:flutter/material.dart';

import '../../../core/partner/partner_state.dart';
import '../../../design/app_breakpoints.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_metric_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_analytics_state.dart';

/// The Partner Analytics module (C11) — the `analytics` destination.
///
/// ## Deliberately narrower than the endpoint list
///
/// `/analytics/overview`, `/analytics/revenue` and `/analytics/occupancy` are
/// already consumed and rendered by C1's dashboard. Repeating them here would
/// give the product two screens computing the same KPI names from two states,
/// and the first time they disagreed a partner would be right to distrust both.
/// So this module shows only the five that had no client: bookings, rooms,
/// promotions, reviews and messages — and points at the dashboard for the rest.
///
/// ## Nothing here is computed
///
/// Every count, mean and percentage is server-supplied. Where the backend cannot
/// compute a value it sends `null`, and the UI renders *not available* rather
/// than `0` — `estimatedDiscountedBookings` and `averageResponseTimeMinutes` are
/// both genuinely nullable, and conflating them with zero would be a false
/// claim.
///
/// Review **aggregates** appear here; the review list does not. The response
/// carries `latestReviews` previews with guest names, which is the Reviews
/// domain — C12's, not an analytics screen's.
class PartnerAnalyticsScreen extends StatefulWidget {
  const PartnerAnalyticsScreen({super.key});

  @override
  State<PartnerAnalyticsScreen> createState() => _PartnerAnalyticsScreenState();
}

class _PartnerAnalyticsScreenState extends State<PartnerAnalyticsScreen> {
  PartnerAnalyticsState? _analytics;
  PartnerState? _partner;
  int? _syncedPropertyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    final rebind = !identical(partner, _partner);
    if (rebind) {
      _partner = partner;
      _analytics?.dispose();
      _analytics = PartnerAnalyticsState(api: partner.api);
      _syncedPropertyId = null;
    }

    final selected = partner.selectedPropertyId;
    if (partner.isReady && (rebind || selected != _syncedPropertyId)) {
      _syncedPropertyId = selected;
      final analytics = _analytics!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) analytics.load(partner, selected);
      });
    }
  }

  @override
  void dispose() {
    _analytics?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final analytics = _analytics;

    if (!partner.isReady || analytics == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: analytics,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerAnalyticsTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Says where revenue and occupancy live, so the split is
                  // explicit rather than looking like an omission.
                  l10n.partnerAnalyticsDashboardPointer,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Body(partner: partner, analytics: analytics),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PartnerState partner;
  final PartnerAnalyticsState analytics;

  const _Body({required this.partner, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (analytics.status) {
      case PartnerAnalyticsStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
            status: PartnerWorkspaceStatus.unauthorized);
      case PartnerAnalyticsStatus.forbidden:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.forbidden,
          detail: analytics.errorMessage,
          onPrimaryAction: () => analytics.refresh(partner),
        );
      case PartnerAnalyticsStatus.notFound:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.onboardingRequired,
          onPrimaryAction: () => analytics.refresh(partner),
        );
      case PartnerAnalyticsStatus.invalidRange:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _rangeBar(context),
            const SizedBox(height: AppSpacing.md),
            PartnerMetricNotice(
              warning: true,
              message: l10n.partnerMetricInvalidRange,
              onRetry: () => analytics.resetRange(partner),
            ),
          ],
        );
      case PartnerAnalyticsStatus.error:
        return PartnerWorkspaceStatusView(
          status: PartnerWorkspaceStatus.error,
          detail: analytics.errorMessage,
          onPrimaryAction: () => analytics.refresh(partner),
        );
      case PartnerAnalyticsStatus.idle:
      case PartnerAnalyticsStatus.loading:
      case PartnerAnalyticsStatus.ready:
        break;
    }

    final f = PartnerMetricFormats.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _rangeBar(context),
        const SizedBox(height: AppSpacing.md),
        if (analytics.failedSections > 0) ...[
          PartnerMetricNotice(
            warning: true,
            message:
                l10n.partnerMetricSectionsFailed('${analytics.failedSections}'),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        PartnerSectionCard(
          title: l10n.partnerAnalyticsBookingsHeading,
          section: analytics.bookings,
          onRetry: () => analytics.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerAnalyticsBookingsEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grid(children: [
                PartnerStatTile(
                    label: l10n.partnerAnalyticsArrivals,
                    value: f.integer.format(data.arrivals),
                    icon: Icons.login_rounded),
                PartnerStatTile(
                    label: l10n.partnerAnalyticsDepartures,
                    value: f.integer.format(data.departures),
                    icon: Icons.logout_rounded),
                PartnerStatTile(
                    label: l10n.partnerAnalyticsCancellations,
                    value: f.integer.format(data.cancellations),
                    icon: Icons.cancel_outlined,
                    color: AppColors.danger),
                PartnerStatTile(
                    label: l10n.partnerAnalyticsNoShows,
                    value: f.integer.format(data.noShows),
                    icon: Icons.person_off_outlined,
                    color: AppColors.danger),
                PartnerStatTile(
                    label: l10n.partnerAnalyticsAverageStay,
                    value: f.decimal.format(data.averageStayLength),
                    icon: Icons.nights_stay_outlined,
                    caption: l10n.partnerAnalyticsAverageStayCaption),
              ]),
              const SizedBox(height: AppSpacing.md),
              _SubHeading(l10n.partnerAnalyticsByStatus),
              PartnerBreakdownList(
                  entries: data.bookingsByStatus, valueIsMoney: false),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerAnalyticsRoomsHeading,
          section: analytics.rooms,
          onRetry: () => analytics.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerAnalyticsRoomsEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PartnerStatTile(
                label: l10n.partnerAnalyticsOccupancyEstimate,
                value: f.percent(data.roomOccupancyEstimate, ''),
                icon: Icons.donut_small_rounded,
                caption: l10n.partnerAnalyticsOccupancyCaption,
              ),
              if (data.topRoomsByRevenue.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerAnalyticsTopRoomsRevenue),
                // Money in `value` here — a different measure from the list
                // below, so the two are never merged into one ranking.
                PartnerBreakdownList(
                    entries: data.topRoomsByRevenue, valueIsMoney: true),
              ],
              if (data.topRoomsByBookings.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerAnalyticsTopRoomsBookings),
                PartnerBreakdownList(
                    entries: data.topRoomsByBookings, valueIsMoney: false),
              ],
              if (data.roomAvailabilitySummary.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerAnalyticsAvailability),
                PartnerBreakdownList(
                    entries: data.roomAvailabilitySummary, valueIsMoney: false),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerAnalyticsPromotionsHeading,
          subtitle: l10n.partnerAnalyticsPromotionsSubtitle,
          section: analytics.promotions,
          onRetry: () => analytics.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerAnalyticsPromotionsEmpty,
          builder: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grid(children: [
                PartnerStatTile(
                    label: l10n.partnerAnalyticsActivePromotions,
                    value: f.integer.format(data.activePromotions),
                    icon: Icons.local_offer_outlined),
                PartnerStatTile(
                  label: l10n.partnerAnalyticsDiscountedBookings,
                  // Null means the backend cannot attribute discounts — shown
                  // as unavailable, never as zero.
                  value: data.estimatedDiscountedBookings == null
                      ? null
                      : f.integer.format(data.estimatedDiscountedBookings),
                  icon: Icons.percent_rounded,
                  caption: data.hasDiscountAttribution
                      ? null
                      : l10n.partnerAnalyticsNoAttribution,
                ),
              ]),
              if (data.promotionsByType.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerAnalyticsPromotionsByType),
                PartnerBreakdownList(
                    entries: data.promotionsByType, valueIsMoney: false),
              ],
              if (data.promotionCountByStatus.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _SubHeading(l10n.partnerAnalyticsPromotionsByStatus),
                PartnerBreakdownList(
                    entries: data.promotionCountByStatus, valueIsMoney: false),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerAnalyticsReviewsHeading,
          subtitle: l10n.partnerAnalyticsReviewsSubtitle,
          section: analytics.reviews,
          onRetry: () => analytics.refresh(partner),
          isEmpty: (data) => false,
          emptyMessage: l10n.partnerAnalyticsReviewsEmpty,
          builder: (data) => _Grid(children: [
            PartnerStatTile(
              label: l10n.partnerAnalyticsAverageRating,
              // A mean of zero over zero reviews is not a rating of zero.
              value: data.hasNoObservations
                  ? null
                  : f.decimal.format(data.averageRating),
              icon: Icons.star_outline_rounded,
              color: AppColors.warning,
              caption: data.hasNoObservations
                  ? l10n.partnerAnalyticsNoReviews
                  : l10n.partnerAnalyticsApprovedOnly,
            ),
            PartnerStatTile(
                label: l10n.partnerAnalyticsReviewCount,
                value: f.integer.format(data.reviewCount),
                icon: Icons.rate_review_outlined),
            PartnerStatTile(
                label: l10n.partnerAnalyticsReviewsApproved,
                value: f.integer.format(data.approvedReviews),
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.success),
            PartnerStatTile(
                label: l10n.partnerAnalyticsReviewsPending,
                value: f.integer.format(data.pendingReviews),
                icon: Icons.schedule_rounded,
                color: AppColors.warning),
            PartnerStatTile(
                label: l10n.partnerAnalyticsReviewsRejected,
                value: f.integer.format(data.rejectedReviews),
                icon: Icons.block_rounded,
                color: AppColors.danger),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        PartnerSectionCard(
          title: l10n.partnerAnalyticsMessagesHeading,
          section: analytics.messages,
          onRetry: () => analytics.refresh(partner),
          isEmpty: (data) => data.isEmpty,
          emptyMessage: l10n.partnerAnalyticsMessagesEmpty,
          builder: (data) => _Grid(children: [
            PartnerStatTile(
                label: l10n.partnerAnalyticsOpenConversations,
                value: f.integer.format(data.openConversations),
                icon: Icons.forum_outlined),
            PartnerStatTile(
                label: l10n.partnerAnalyticsClosedConversations,
                value: f.integer.format(data.closedConversations),
                icon: Icons.mark_chat_read_outlined),
            PartnerStatTile(
                label: l10n.partnerAnalyticsArchivedConversations,
                value: f.integer.format(data.archivedConversations),
                icon: Icons.archive_outlined),
            PartnerStatTile(
                label: l10n.partnerAnalyticsUnreadMessages,
                value: f.integer.format(data.unreadPartnerMessages),
                icon: Icons.mark_email_unread_outlined,
                color: AppColors.warning),
            PartnerStatTile(
              label: l10n.partnerAnalyticsResponseTime,
              // Null when nothing could be observed — not an instant reply.
              value: data.hasResponseTime
                  ? l10n.partnerAnalyticsMinutesValue(
                      f.decimal.format(data.averageResponseTimeMinutes))
                  : null,
              icon: Icons.timer_outlined,
              caption: data.hasResponseTime
                  ? null
                  : l10n.partnerAnalyticsNoResponses,
            ),
          ]),
        ),
      ],
    );
  }

  Widget _rangeBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PartnerRangeBar(
      from: analytics.from,
      to: analytics.to,
      isPartnerWide: analytics.isPartnerWide,
      busy: analytics.isLoading,
      scopeNote: analytics.isPartnerWide
          ? l10n.partnerAnalyticsScopeAll
          : l10n.partnerAnalyticsScopeProperty,
      onRangeChanged: (from, to) => analytics.setRange(partner, from, to),
      onReset: () => analytics.resetRange(partner),
      onRefresh: () => analytics.refresh(partner),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<Widget> children;

  const _Grid({required this.children});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          const spacing = AppSpacing.sm;
          final columns = constraints.maxWidth >= AppBreakpoints.desktop
              ? 3
              : constraints.maxWidth >= AppBreakpoints.tablet
                  ? 2
                  : 1;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (final child in children)
                SizedBox(width: width, child: child),
            ],
          );
        },
      );
}

class _SubHeading extends StatelessWidget {
  final String text;

  const _SubHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
        ),
      );
}
