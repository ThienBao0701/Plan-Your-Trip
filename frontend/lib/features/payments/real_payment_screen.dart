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
import '../expenses/expenses_screen.dart' show formatMoney;

/// UI28 — Real Mode payment. Creates a GENUINE backend payment
/// (`POST /api/payments`) for a PENDING booking and shows its real status
/// (`GET /api/payments/{id}`, `.../bookings/{id}/payments`). This backend has NO
/// live payment gateway — the settlement `checkoutUrl` is null, so nothing is
/// redirected or launched. A payment is completed offline via the backend's own
/// `mock-success` / `mock-fail` endpoints, surfaced here as explicitly-labelled
/// SANDBOX actions (real endpoints, not fabricated results) behind an explicit
/// confirmation (CLAUDE.md §11). A PAID payment confirms the booking server-side.
class RealPaymentScreen extends StatefulWidget {
  final int bookingId;
  final String bookingCode;
  final double? amount;
  final String currency;

  const RealPaymentScreen({
    super.key,
    required this.bookingId,
    required this.bookingCode,
    this.amount,
    this.currency = 'VND',
  });

  @override
  State<RealPaymentScreen> createState() => _RealPaymentScreenState();
}

class _RealPaymentScreenState extends State<RealPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) AppScope.of(context).loadPaymentForBooking(widget.bookingId);
    });
  }

  Future<void> _create(AppState app) async {
    final outcome = await app.createRealPayment(widget.bookingId);
    _afterAction(app, outcome);
  }

  Future<void> _refresh(AppState app) async {
    final outcome = await app.refreshRealPayment();
    _afterAction(app, outcome);
  }

  Future<void> _settle(AppState app, {required bool success}) async {
    if (success) {
      final confirmed = await _confirmComplete();
      if (confirmed != true) return;
    }
    final outcome = await app.settleRealPaymentSandbox(success: success);
    _afterAction(app, outcome);
  }

  void _afterAction(AppState app, PaymentActionOutcome outcome) {
    if (!mounted) return;
    if (outcome == PaymentActionOutcome.success ||
        outcome == PaymentActionOutcome.busy) {
      return;
    }
    if (outcome == PaymentActionOutcome.sessionExpired) {
      _reauth();
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(_messageForOutcome(l10n, outcome))));
  }

  Future<bool?> _confirmComplete() {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.paymentConfirmTitle),
        content: Text(l10n.paymentConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.icon(
            key: const Key('payment-confirm-complete'),
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded),
            label: Text(l10n.paymentConfirmAction),
          ),
        ],
      ),
    );
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

  String _messageForOutcome(AppLocalizations l10n, PaymentActionOutcome o) {
    return switch (o) {
      PaymentActionOutcome.validation => l10n.paymentActionValidationMessage,
      PaymentActionOutcome.forbidden => l10n.paymentActionForbiddenMessage,
      PaymentActionOutcome.notFound => l10n.paymentActionNotPayableMessage,
      PaymentActionOutcome.unprocessable => l10n.paymentActionNotPayableMessage,
      PaymentActionOutcome.conflict => l10n.paymentActionConflictMessage,
      PaymentActionOutcome.network => l10n.paymentActionNetworkMessage,
      _ => l10n.paymentActionServerErrorMessage,
    };
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
        title: Text(l10n.paymentTitle),
      ),
      body: BubbleBackground(
        child: SafeArea(top: false, child: _body(context, app, l10n)),
      ),
    );
  }

  Widget _body(BuildContext context, AppState app, AppLocalizations l10n) {
    final payment = app.realPayment;
    final loading = app.realPaymentLoading;
    final error = app.realPaymentError;

    if (payment == null &&
        error == PaymentActionOutcome.sessionExpired &&
        !loading) {
      return _centered(
        OceanSessionExpiredState(
          key: const Key('payment-session-expired'),
          onLogin: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ),
          onReturnHome: () => Navigator.maybePop(context),
        ),
      );
    }
    if (payment == null && loading) {
      return _centered(
        Semantics(
          liveRegion: true,
          label: l10n.paymentLoadingMessage,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(l10n.paymentLoadingMessage),
            ],
          ),
        ),
      );
    }
    if (payment == null &&
        error != null &&
        error != PaymentActionOutcome.sessionExpired) {
      return _centered(
        OceanRecoverableErrorState(
          key: const Key('payment-error'),
          message: l10n.paymentErrorMessage,
          onReload: () => app.loadPaymentForBooking(widget.bookingId),
        ),
      );
    }

    return ListView(
      key: const Key('payment-content'),
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
              _sandboxNotice(context, l10n),
              const SizedBox(height: AppSpacing.md),
              _amountCard(context, l10n),
              const SizedBox(height: AppSpacing.md),
              if (payment == null)
                ..._noPaymentSection(context, app, l10n)
              else
                ..._paymentSection(context, app, l10n, payment),
            ],
          ),
        ),
      ],
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

  Widget _sandboxNotice(BuildContext context, AppLocalizations l10n) =>
      OceanGlassSurface(
        key: const Key('payment-sandbox-notice'),
        blur: 0,
        color: AppColors.paleCyan,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.ocean),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.paymentSandboxNotice,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );

  Widget _amountCard(BuildContext context, AppLocalizations l10n) {
    final amount = widget.amount;
    return OceanGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paymentAmountToPayLabel,
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            amount == null
                ? l10n.bookingQuoteUnavailable
                : formatMoney(context, amount, widget.currency),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }

  List<Widget> _noPaymentSection(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
  ) {
    final submitting = app.realPaymentSubmitting;
    return [
      OceanGlassCard(
        key: const Key('payment-none'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.paymentNoneTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.paymentNoneMessage,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (submitting) _processing(context, l10n),
      OceanPrimaryButton(
        key: const Key('payment-create'),
        label:
            submitting ? l10n.paymentCreatingLabel : l10n.paymentCreateAction,
        icon: Icons.add_card_rounded,
        onPressed: submitting ? null : () => _create(app),
      ),
    ];
  }

  List<Widget> _paymentSection(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    RealPaymentRecord payment,
  ) {
    final view = payment.statusView;
    final submitting = app.realPaymentSubmitting || app.realPaymentLoading;
    final (String headline, String body) = _statusCopy(l10n, view);
    return [
      OceanGlassCard(
        key: const Key('payment-status-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              liveRegion: true,
              label: '$headline. $body',
              child: Row(
                children: [
                  Icon(_statusIcon(view), color: _statusColor(view)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(headline,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            _row(context, l10n.paymentCodeLabel, payment.paymentCode,
                key: const Key('payment-code'), spelled: true),
            _statusRow(context, l10n, view, payment.status),
            _row(context, l10n.paymentMethodLabel, payment.paymentMethod),
            _row(context, l10n.paymentProviderLabel, payment.provider),
            if (payment.amount != null)
              _row(context, l10n.paymentAmountLabel,
                  formatMoney(context, payment.amount!, payment.currency)),
            if (payment.paidAt != null)
              _row(context, l10n.paymentPaidAtLabel,
                  _dateTime(context, payment.paidAt!)),
            if (payment.failedAt != null)
              _row(context, l10n.paymentFailedAtLabel,
                  _dateTime(context, payment.failedAt!)),
            if ((payment.failureReason ?? '').trim().isNotEmpty)
              _row(context, l10n.paymentFailureReasonLabel,
                  payment.failureReason!.trim()),
            if (payment.createdAt != null)
              _row(context, l10n.paymentCreatedLabel,
                  _dateTime(context, payment.createdAt!)),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      if (submitting) _processing(context, l10n),
      ..._actionsForStatus(context, app, l10n, view, submitting),
    ];
  }

  List<Widget> _actionsForStatus(
    BuildContext context,
    AppState app,
    AppLocalizations l10n,
    PaymentStatusView view,
    bool submitting,
  ) {
    switch (view) {
      case PaymentStatusView.pending:
        return [
          OceanPrimaryButton(
            key: const Key('payment-complete'),
            label: l10n.paymentCompleteSandboxAction,
            icon: Icons.verified_rounded,
            onPressed: submitting ? null : () => _settle(app, success: true),
          ),
          const SizedBox(height: AppSpacing.sm),
          OceanSecondaryButton(
            key: const Key('payment-fail'),
            label: l10n.paymentFailSandboxAction,
            icon: Icons.cancel_schedule_send_rounded,
            onPressed: submitting ? null : () => _settle(app, success: false),
          ),
          const SizedBox(height: AppSpacing.sm),
          OceanSecondaryButton(
            key: const Key('payment-refresh'),
            label: l10n.paymentRefreshAction,
            icon: Icons.refresh_rounded,
            onPressed: submitting ? null : () => _refresh(app),
          ),
        ];
      case PaymentStatusView.paid:
        return [
          OceanPrimaryButton(
            key: const Key('payment-done'),
            label: l10n.bookingResultDoneAction,
            icon: Icons.check_rounded,
            onPressed: () => Navigator.maybePop(context),
          ),
        ];
      default:
        // FAILED / CANCELLED / REFUNDED / unknown — a new attempt needs a new
        // payment (the backend only settles a PENDING one).
        return [
          OceanPrimaryButton(
            key: const Key('payment-new'),
            label: l10n.paymentRetryNewAction,
            icon: Icons.add_card_rounded,
            onPressed: submitting ? null : () => _create(app),
          ),
          const SizedBox(height: AppSpacing.sm),
          OceanSecondaryButton(
            key: const Key('payment-refresh'),
            label: l10n.paymentRefreshAction,
            icon: Icons.refresh_rounded,
            onPressed: submitting ? null : () => _refresh(app),
          ),
        ];
    }
  }

  Widget _processing(BuildContext context, AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          liveRegion: true,
          label: l10n.paymentProcessingLabel,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.paymentProcessingLabel),
            ],
          ),
        ),
      );

  (String, String) _statusCopy(AppLocalizations l10n, PaymentStatusView view) {
    switch (view) {
      case PaymentStatusView.paid:
        return (l10n.paymentSuccessHeadline, l10n.paymentSuccessBody);
      case PaymentStatusView.pending:
        return (l10n.paymentPendingHeadline, l10n.paymentPendingBody);
      case PaymentStatusView.failed:
        return (l10n.paymentFailedHeadline, l10n.paymentFailedBody);
      default:
        return (l10n.paymentPendingHeadline, l10n.paymentPendingBody);
    }
  }

  Widget _statusRow(
    BuildContext context,
    AppLocalizations l10n,
    PaymentStatusView view,
    String raw,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Text('${l10n.bookingPaymentStatusLabel}: ',
              style: Theme.of(context).textTheme.bodyMedium),
          OceanStatusPill(
            label: _statusLabel(l10n, view, raw),
            icon: _statusIcon(view),
            color: _statusColor(view),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    Key? key,
    bool spelled = false,
  }) {
    final display = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: '$label: ${spelled ? display.split('').join(' ') : display}',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(label, style: Theme.of(context).textTheme.labelLarge),
            ),
            Expanded(
              flex: 3,
              child: key != null
                  ? SelectableText(display,
                      key: key, style: Theme.of(context).textTheme.bodyMedium)
                  : Text(display,
                      style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(
      AppLocalizations l10n, PaymentStatusView view, String raw) {
    switch (view) {
      case PaymentStatusView.pending:
        return l10n.bookingPaymentStatusPending;
      case PaymentStatusView.paid:
        return l10n.bookingPaymentStatusPaid;
      case PaymentStatusView.failed:
        return l10n.bookingPaymentStatusFailed;
      case PaymentStatusView.cancelled:
        return l10n.bookingPaymentStatusCancelled;
      case PaymentStatusView.refunded:
        return l10n.bookingPaymentStatusRefunded;
      case PaymentStatusView.unknown:
        return raw.trim().isEmpty ? l10n.paymentStatusUnknownLabel : raw.trim();
    }
  }

  IconData _statusIcon(PaymentStatusView view) {
    switch (view) {
      case PaymentStatusView.paid:
        return Icons.verified_rounded;
      case PaymentStatusView.pending:
        return Icons.hourglass_top_rounded;
      case PaymentStatusView.failed:
      case PaymentStatusView.cancelled:
        return Icons.cancel_rounded;
      case PaymentStatusView.refunded:
        return Icons.replay_rounded;
      case PaymentStatusView.unknown:
        return Icons.help_outline_rounded;
    }
  }

  Color _statusColor(PaymentStatusView view) {
    switch (view) {
      case PaymentStatusView.paid:
      case PaymentStatusView.refunded:
        return AppColors.success;
      case PaymentStatusView.failed:
      case PaymentStatusView.cancelled:
        return AppColors.coral;
      case PaymentStatusView.pending:
      case PaymentStatusView.unknown:
        return AppColors.ocean;
    }
  }

  String _dateTime(BuildContext context, DateTime value) {
    final formatter =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm();
    return formatter.format(value.toLocal());
  }
}
