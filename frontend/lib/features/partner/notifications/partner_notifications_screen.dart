import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/mock/app_models.dart';
import '../../../core/partner/partner_state.dart';
import '../../../design/app_colors.dart';
import '../../../design/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/glass_widgets.dart';
import '../widgets/partner_metric_widgets.dart';
import '../widgets/partner_state_views.dart';
import 'partner_notifications_state.dart';

/// The Partner Notification Centre (D6) — the `notifications` destination.
///
/// ## Why this module exists
///
/// `PartnerExtranetService` publishes `MenuItem("notifications", …, enabled: true,
/// unreadNotifications)` and the shell renders that count live, while the
/// destination fell through to the "planned" placeholder. The backend already
/// delivers ten kinds of partner-directed notification to this account; they
/// simply had nowhere to be read.
///
/// ## This is the account's whole inbox, not a partner-only feed
///
/// `Notification.recipientUser` is the only ownership axis — nothing on the row
/// says "you got this as a partner". D6 shows everything the server returns and
/// says so on screen, rather than filtering by `notificationType` and passing
/// that off as an audience field.
///
/// ## Nothing here navigates
///
/// The list endpoint omits `relatedEntityType`/`relatedEntityId` entirely; only
/// `PATCH /{id}/read` returns them. Even then, every partner destination is a
/// zero-argument screen dispatched by menu key, so no `(type, id)` pair can
/// address one. The resolved target is shown as information; guessing a route
/// from it is exactly the invention this project forbids.
class PartnerNotificationsScreen extends StatefulWidget {
  const PartnerNotificationsScreen({super.key});

  @override
  State<PartnerNotificationsScreen> createState() =>
      _PartnerNotificationsScreenState();
}

class _PartnerNotificationsScreenState
    extends State<PartnerNotificationsScreen> {
  PartnerNotificationsState? _notifications;
  PartnerState? _partner;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final partner = PartnerScope.of(context);
    if (identical(partner, _partner)) return;

    _partner = partner;
    _notifications?.dispose();
    _notifications = PartnerNotificationsState(api: partner.api);

    if (partner.isReady) {
      final notifications = _notifications!;
      // Refresh on screen entry. No polling, no timers.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) notifications.load();
      });
    }
  }

  @override
  void dispose() {
    _notifications?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final partner = PartnerScope.of(context);
    final notifications = _notifications;

    // The workspace gate stays authoritative, including `teamMemberUnsupported`.
    if (!partner.isReady || notifications == null) {
      return PartnerWorkspaceStatusView(
        status: partner.status,
        detail: partner.errorMessage,
      );
    }

    return AnimatedBuilder(
      animation: notifications,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanGlassCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.partnerNotificationsTitle,
                  key: const Key('partner-notifications-title'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.partnerNotificationsSubtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _Body(notifications: notifications),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final PartnerNotificationsState notifications;

  const _Body({required this.notifications});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (notifications.status) {
      case PartnerNotificationsStatus.unauthorized:
        return const PartnerWorkspaceStatusView(
          key: Key('partner-notifications-unauthorized'),
          status: PartnerWorkspaceStatus.unauthorized,
        );
      case PartnerNotificationsStatus.forbidden:
        return PartnerWorkspaceStatusView(
          key: const Key('partner-notifications-forbidden'),
          status: PartnerWorkspaceStatus.forbidden,
          detail: notifications.errorMessage,
          onPrimaryAction: notifications.refresh,
        );
      case PartnerNotificationsStatus.notFound:
        return PartnerWorkspaceStatusView(
          key: const Key('partner-notifications-notfound'),
          status: PartnerWorkspaceStatus.teamMemberUnsupported,
          detail: notifications.errorMessage,
        );
      case PartnerNotificationsStatus.error:
        return PartnerWorkspaceStatusView(
          key: const Key('partner-notifications-error'),
          status: PartnerWorkspaceStatus.error,
          detail: notifications.errorMessage,
          onPrimaryAction: notifications.refresh,
        );
      case PartnerNotificationsStatus.idle:
      case PartnerNotificationsStatus.loading:
        return OceanStateView(
          key: const Key('partner-notifications-loading'),
          icon: Icons.notifications_outlined,
          title: l10n.partnerNotificationsTitle,
          message: l10n.partnerNotificationsLoading,
          semanticLabel: l10n.partnerNotificationsLoading,
          showProgress: true,
        );
      case PartnerNotificationsStatus.ready:
        break;
    }

    if (notifications.isEmpty) {
      return OceanStateView(
        key: const Key('partner-notifications-empty'),
        icon: Icons.notifications_outlined,
        title: l10n.partnerNotificationsEmptyTitle,
        message: l10n.partnerNotificationsEmptyMessage,
        semanticLabel: l10n.partnerNotificationsEmptyTitle,
      );
    }

    final unread = notifications.serverUnread;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(notifications: notifications, serverUnread: unread),
        const SizedBox(height: AppSpacing.md),
        // Said plainly rather than filtered away: this is the account inbox.
        PartnerMetricNotice(
          key: const Key('partner-notifications-inbox-notice'),
          message: l10n.partnerNotificationsInboxNotice,
        ),
        const SizedBox(height: AppSpacing.sm),
        PartnerMetricNotice(
          message: l10n.partnerNotificationsUnpaginatedNotice,
        ),
        const SizedBox(height: AppSpacing.md),
        // Rendered exactly as served — the backend orders newest first.
        for (final notification in notifications.notifications)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _NotificationCard(
              notification: notification,
              notifications: notifications,
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final PartnerNotificationsState notifications;
  final int? serverUnread;

  const _Header({required this.notifications, required this.serverUnread});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return OceanGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              // The server's own count, never derived locally.
              serverUnread == null
                  ? l10n.partnerNotificationsTitle
                  : l10n.notificationUnreadCount(serverUnread!),
              key: const Key('partner-notifications-unread-count'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (notifications.isMarkingAll)
            const SizedBox(
              key: Key('partner-notifications-marking-all'),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (notifications.hasUnread)
            TextButton.icon(
              key: const Key('partner-notifications-mark-all'),
              onPressed: () => _markAll(context),
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(l10n.partnerNotificationsMarkAllRead),
            ),
        ],
      ),
    );
  }

  Future<void> _markAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await notifications.markAllRead();
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(
          content: Text(_resultMessage(l10n, result,
              success: l10n.partnerNotificationsMarkedAllRead))),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final RealNotificationRecord notification;
  final PartnerNotificationsState notifications;

  const _NotificationCard({
    required this.notification,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateTime = DateFormat.yMMMd(locale).add_Hm();
    final pending = notifications.isPending(notification.id);
    final target = notifications.targetFor(notification.id);

    return OceanGlassCard(
      key: Key('partner-notifications-row-${notification.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight:
                        notification.read ? FontWeight.w600 : FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!notification.read)
                OceanStatusPill(
                  key: Key('partner-notifications-unread-${notification.id}'),
                  label: l10n.partnerNotificationsUnreadLabel,
                  color: AppColors.ocean600,
                  icon: Icons.circle,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            children: [
              Text(
                _typeLabel(l10n, notification.typeView),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              if (notification.createdAt != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  dateTime.format(notification.createdAt!),
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            notification.message,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          // Once a row has been read the server tells us what it refers to. It
          // is shown, not followed: no partner screen accepts an entity id.
          if (target != null && target.isResolvable) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.partnerNotificationsNoDestination,
              key: Key('partner-notifications-target-${notification.id}'),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (pending)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                if (!notification.read)
                  TextButton(
                    key: Key('partner-notifications-read-${notification.id}'),
                    onPressed: () => _markRead(context),
                    child: Text(l10n.partnerNotificationsMarkRead),
                  ),
                const Spacer(),
                TextButton(
                  key: Key('partner-notifications-delete-${notification.id}'),
                  onPressed: () => _confirmDelete(context),
                  style:
                      TextButton.styleFrom(foregroundColor: AppColors.danger),
                  child: Text(l10n.partnerNotificationsDelete),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _markRead(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final result = await notifications.markRead(notification.id);
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(
          content: Text(_resultMessage(l10n, result,
              success: l10n.partnerNotificationsMarkedRead))),
    );
  }

  /// Deleting is permanent and there is no archive, so it is confirmed
  /// explicitly and never optimistically applied.
  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const Key('partner-notifications-delete-dialog'),
        title: Text(l10n.partnerNotificationsDeleteTitle),
        content: Text(l10n.partnerNotificationsDeleteMessage),
        actions: [
          TextButton(
            key: const Key('partner-notifications-delete-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.partnerBookingActionCancel),
          ),
          FilledButton(
            key: const Key('partner-notifications-delete-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.partnerNotificationsDeleteCta),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await notifications.delete(notification.id);
    if (!context.mounted) return;
    messenger?.showSnackBar(
      SnackBar(
          content: Text(_resultMessage(l10n, result,
              success: l10n.partnerNotificationsDeleted))),
    );
  }
}

String _resultMessage(
  AppLocalizations l10n,
  PartnerNotificationActionResult result, {
  required String success,
}) =>
    switch (result) {
      PartnerNotificationActionResult.success => success,
      PartnerNotificationActionResult.unauthorized =>
        l10n.partnerDashboardErrorUnauthorized,
      PartnerNotificationActionResult.forbidden =>
        l10n.partnerDashboardErrorForbidden,
      PartnerNotificationActionResult.notFound =>
        l10n.partnerNotificationsActionNotFound,
      PartnerNotificationActionResult.busy =>
        l10n.partnerNotificationsActionBusy,
      PartnerNotificationActionResult.failed =>
        l10n.partnerNotificationsActionFailed,
    };

/// Reuses the localized type labels the customer notification centre already
/// ships — these are domain-neutral wire-code labels, not customer copy.
String _typeLabel(AppLocalizations l10n, UserNotificationType? type) =>
    switch (type) {
      UserNotificationType.booking => l10n.notificationTypeBooking,
      UserNotificationType.payment => l10n.notificationTypePayment,
      UserNotificationType.reservation => l10n.notificationTypeReservation,
      UserNotificationType.system => l10n.notificationTypeSystem,
      UserNotificationType.promotion => l10n.notificationTypePromotion,
      UserNotificationType.review => l10n.notificationTypeReview,
      UserNotificationType.partner => l10n.notificationTypePartner,
      UserNotificationType.admin => l10n.notificationTypeAdmin,
      UserNotificationType.message => l10n.notificationTypeMessage,
      UserNotificationType.trip => l10n.notificationTypeTrip,
      null => l10n.partnerNotificationsTypeUnknown,
    };
