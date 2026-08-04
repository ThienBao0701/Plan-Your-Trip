import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'place_detail_screen.dart';

/// UI31 — Real Mode recently-viewed places (`GET /api/me/recently-viewed`).
/// Lists the customer's real recently-viewed places, opens a place via the
/// existing UI19 hydration (no duplicated place-detail logic), and supports
/// remove-one and clear-all. Read-only + two backend-supported deletes; nothing
/// is fabricated.
class RealRecentlyViewedScreen extends StatefulWidget {
  const RealRecentlyViewedScreen({super.key});

  @override
  State<RealRecentlyViewedScreen> createState() =>
      _RealRecentlyViewedScreenState();
}

class _RealRecentlyViewedScreenState extends State<RealRecentlyViewedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadRealRecentlyViewed();
    });
  }

  void _reauth() {
    showOceanSessionExpiredSheet(
      context,
      onLogin: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      },
      onReturnHome: () => Navigator.of(context).pop(),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _messageForOutcome(AppLocalizations l10n, RecentlyViewedOutcome o) {
    return switch (o) {
      RecentlyViewedOutcome.forbidden => l10n.recentlyViewedForbiddenMessage,
      RecentlyViewedOutcome.notFound => l10n.recentlyViewedGoneMessage,
      RecentlyViewedOutcome.network => l10n.recentlyViewedNetworkMessage,
      _ => l10n.recentlyViewedActionErrorMessage,
    };
  }

  Future<void> _open(AppState app, RecentlyViewedRecord r) async {
    final l10n = AppLocalizations.of(context)!;
    final outcome = await app.hydrateRealPlace(r.placeId);
    if (!mounted) return;
    switch (outcome) {
      case PlaceHydrationResult.success:
        final place = app.getHydratedRealPlace(r.placeId);
        if (place == null) {
          _snack(l10n.recentlyViewedOpenErrorMessage);
          return;
        }
        // Best-effort: opening bumps this place to the top of the list.
        unawaited(app.recordRealRecentlyView(r.placeId));
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
        );
      case PlaceHydrationResult.sessionExpired:
        _reauth();
      case PlaceHydrationResult.notFound:
        _snack(l10n.recentlyViewedGoneMessage);
      case PlaceHydrationResult.unavailable:
        _snack(l10n.recentlyViewedActionErrorMessage);
      case PlaceHydrationResult.network:
        _snack(l10n.recentlyViewedNetworkMessage);
      case PlaceHydrationResult.serverError:
        _snack(l10n.recentlyViewedOpenErrorMessage);
    }
  }

  Future<void> _remove(AppState app, RecentlyViewedRecord r) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recentlyViewedRemoveConfirmTitle),
        content: Text(l10n.recentlyViewedRemoveConfirmMessage(r.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('recently-viewed-remove-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.recentlyViewedRemoveConfirmAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.removeRealRecentlyViewed(r.placeId);
    if (!mounted) return;
    if (outcome == RecentlyViewedOutcome.success) {
      _snack(l10n.recentlyViewedRemovedMessage);
    } else if (outcome == RecentlyViewedOutcome.sessionExpired) {
      _reauth();
    } else if (outcome != RecentlyViewedOutcome.busy) {
      _snack(_messageForOutcome(l10n, outcome));
    }
  }

  Future<void> _clearAll(AppState app) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recentlyViewedClearConfirmTitle),
        content: Text(l10n.recentlyViewedClearConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            key: const Key('recently-viewed-clear-confirm'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_sweep_rounded),
            label: Text(l10n.recentlyViewedClearConfirmAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final outcome = await app.clearRealRecentlyViewed();
    if (!mounted) return;
    if (outcome == RecentlyViewedOutcome.success) {
      _snack(l10n.recentlyViewedClearedMessage);
    } else if (outcome == RecentlyViewedOutcome.sessionExpired) {
      _reauth();
    } else if (outcome != RecentlyViewedOutcome.busy) {
      _snack(_messageForOutcome(l10n, outcome));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final canClear = app.realRecentlyViewed.isNotEmpty &&
        !app.recentlyViewedActionInFlight.contains(-1);
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.recentlyViewedTitle),
        actions: [
          if (app.realRecentlyViewedLoaded)
            IconButton(
              key: const Key('recently-viewed-clear'),
              tooltip: l10n.recentlyViewedClearSemantic,
              onPressed: canClear ? () => _clearAll(app) : null,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    if (app.realRecentlyViewedError == RecentlyViewedOutcome.sessionExpired &&
        !app.realRecentlyViewedLoaded) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('recently-viewed-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (app.realRecentlyViewedLoading && !app.realRecentlyViewedLoaded) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.recentlyViewedLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.recentlyViewedLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (app.realRecentlyViewedError != null && !app.realRecentlyViewedLoaded) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('recently-viewed-error'),
          message: l10n.recentlyViewedErrorMessage,
          onReload: () => app.loadRealRecentlyViewed(refresh: true),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => app.loadRealRecentlyViewed(refresh: true),
      child: ListView(
        key: const Key('recently-viewed-content'),
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
                if (app.realRecentlyViewed.isEmpty)
                  OceanEmptyState(
                    key: const Key('recently-viewed-empty'),
                    title: l10n.recentlyViewedEmptyTitle,
                    message: l10n.recentlyViewedEmptyMessage,
                  )
                else
                  for (final r in app.realRecentlyViewed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RecentlyViewedCard(
                        record: r,
                        onTap: () => _open(app, r),
                        onRemove: () => _remove(app, r),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _centered(Widget child) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: [
          OceanContentConstraint(
            maxWidth: AppBreakpoints.maxContentWidth,
            child: Center(child: child),
          ),
        ],
      );
}

class _RecentlyViewedCard extends StatelessWidget {
  final RecentlyViewedRecord record;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentlyViewedCard({
    required this.record,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final subtitleParts = <String>[
      if ((record.categoryName ?? '').trim().isNotEmpty)
        record.categoryName!.trim(),
      if ((record.address ?? '').trim().isNotEmpty) record.address!.trim(),
    ];
    return OceanGlassCard(
      key: Key('recently-viewed-card-${record.placeId}'),
      onTap: onTap,
      semanticLabel: l10n.recentlyViewedCardSemantic(record.name),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.name.trim().isEmpty
                      ? l10n.recentlyViewedUnknownPlace
                      : record.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (subtitleParts.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitleParts.join(' · '),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (record.ratingAvg > 0)
                      OceanStatusPill(
                        label: record.ratingAvg.toStringAsFixed(1),
                        semanticLabel: l10n.recentlyViewedRatingSemantic(
                          record.ratingAvg.toStringAsFixed(1),
                          record.reviewCount,
                        ),
                        icon: Icons.star_rounded,
                        color: AppColors.warning,
                      ),
                    if (record.viewedAt != null)
                      OceanStatusPill(
                        label: date.format(record.viewedAt!.toLocal()),
                        icon: Icons.history_rounded,
                        color: AppColors.turquoise600,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('recently-viewed-remove-${record.placeId}'),
            tooltip: l10n.recentlyViewedRemoveSemantic(record.name),
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}
