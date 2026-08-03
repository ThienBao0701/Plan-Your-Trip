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
import '../hotels/booking_widgets.dart';

/// UI27 — Real Mode booking detail. Fetches `GET /api/bookings/{id}` and renders
/// ONLY the server's own `BookingResponse` (reused as [BookingCreateRecord]).
/// Nothing is fabricated: status, code, dates, price, currency and rate plan all
/// come from the backend, unknown statuses degrade honestly, and fields the DTO
/// does not carry (trip linkage, payment status, voucher) are simply absent.
/// Separate from the demo [BookingDetailScreen] so the demo flow is untouched.
class RealBookingDetailScreen extends StatefulWidget {
  final int bookingId;

  const RealBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<RealBookingDetailScreen> createState() =>
      _RealBookingDetailScreenState();
}

class _RealBookingDetailScreenState extends State<RealBookingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadBookingDetail(widget.bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.bookingDetailsTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: _body(context, app, l10n),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    final record = app.bookingDetailCache[widget.bookingId];
    // A cached record always wins — even if a later refresh failed, show the
    // known-good detail rather than an error.
    if (record != null) {
      return _content(context, app, l10n, record);
    }
    final loading = app.bookingDetailLoadingId == widget.bookingId;
    if (loading) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.bookingDetailLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.bookingDetailLoadingMessage),
            ],
          ),
        ),
      );
    }
    final error = app.bookingDetailError;
    if (error == BookingHistoryOutcome.sessionExpired) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('booking-detail-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (error == BookingHistoryOutcome.notFound) {
      return _centered(
        OceanEmptyState(
          key: const Key('booking-detail-missing'),
          title: l10n.bookingDetailMissingTitle,
          message: l10n.bookingDetailMissingMessage,
        ),
      );
    }
    if (error != null) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('booking-detail-error'),
          message: l10n.bookingDetailErrorMessage,
          onReload: () =>
              app.loadBookingDetail(widget.bookingId, refresh: true),
        ),
      );
    }
    // Initial frame before the post-frame load has started.
    return _centered(const CircularProgressIndicator());
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

  Widget _content(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    BookingCreateRecord record,
  ) {
    final view = record.statusView;
    final createdAt = record.createdAt;
    final specialRequest = (record.specialRequest ?? '').trim();
    return ListView(
      key: const Key('booking-detail-content'),
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
              OceanGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: BookingStatusChip(
                          view: view,
                          label: bookingStatusChipLabel(
                            l10n,
                            view,
                            record.status,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      l10n.bookingResultCodeLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Semantics(
                      label: _spelledCode(record.bookingCode),
                      child: ExcludeSemantics(
                        child: SelectableText(
                          record.bookingCode,
                          key: const Key('booking-detail-code'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              BookingResultSummaryCard(record: record),
              const SizedBox(height: AppSpacing.md),
              BookingResultPriceCard(record: record),
              if (specialRequest.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                OceanGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.bookingDetailSpecialRequestLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        specialRequest,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              if (createdAt != null) ...[
                const SizedBox(height: AppSpacing.md),
                OceanGlassSurface(
                  blur: 0,
                  color: AppColors.paleCyan,
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: AppColors.ocean),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          '${l10n.bookingCreatedLabel}: '
                          '${_formatDateTime(context, createdAt)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              OceanGlassSurface(
                blur: 0,
                color: AppColors.paleCyan,
                child: Text(
                  l10n.bookingResultPaymentNextNote,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              OceanPrimaryButton(
                key: const Key('booking-detail-done'),
                label: l10n.bookingResultDoneAction,
                icon: Icons.check_rounded,
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // A character-spelled semantic label so a screen reader reads the booking code
  // one glyph at a time ("P Y T ...") instead of mangling it as a word.
  String _spelledCode(String code) => code.split('').join(' ');

  String _formatDateTime(BuildContext context, DateTime value) {
    final formatter =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm();
    return formatter.format(value.toLocal());
  }
}
