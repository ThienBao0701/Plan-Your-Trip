import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';
import '../../core/mock/app_models.dart';
import '../../design/app_breakpoints.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../bookings/my_bookings_screen.dart';
import '../payments/secure_checkout_screen.dart';
import '../rewards/rewards_screen.dart';
import '../reviews/reviews_screen.dart';
import '../trips/trip_companion_screen.dart';
import '../trips/trip_detail_screen.dart';
import '../trips/trip_documents_screen.dart';
import '../wallet/travel_wallet_screen.dart';
import 'real_notifications_view.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool loading;

  const NotificationsScreen({super.key, this.loading = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notifications = _filtered(app.visibleNotifications);
    final unreadCount = app.unreadNotificationCount;
    return Scaffold(
      appBar: OceanGlassAppBar(
        leading: IconButton(
          tooltip: l10n.commonBackSemantic,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(l10n.notificationsTitle),
        actions: [
          Semantics(
            button: true,
            label: l10n.notificationsSettingsSemantic,
            child: IconButton(
              tooltip: l10n.notificationsSettingsSemantic,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: const Icon(Icons.settings_rounded),
            ),
          ),
        ],
      ),
      body: BubbleBackground(
        child: SafeArea(
          top: false,
          child: !app.demoMode
              ? const RealNotificationsBody()
              : widget.loading
                  ? const Center(
                      child: SizedBox(width: 420, child: OceanLoadingState()),
                    )
                  : ListView(
                      key: const Key('notification-center-screen'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xxl,
                      ),
                      children: [
                        OceanContentConstraint(
                          maxWidth: AppBreakpoints.maxContentWidth,
                          child: !app.demoMode
                              ? _RealModeBoundary(l10n: l10n)
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _NotificationHeader(
                                      unreadCount: unreadCount,
                                      totalCount:
                                          app.visibleNotifications.length,
                                      onMarkAllRead: unreadCount == 0
                                          ? null
                                          : () => _markAllRead(app),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    _FilterRail(
                                      selected: _filter,
                                      onChanged: (filter) =>
                                          setState(() => _filter = filter),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    if (notifications.isEmpty)
                                      OceanEmptyState(
                                        title: l10n.notificationsDemoEmptyTitle,
                                        message: _filter ==
                                                _NotificationFilter.all
                                            ? l10n.notificationsDemoEmptyMessage
                                            : l10n
                                                .notificationFilterEmptyMessage,
                                      )
                                    else
                                      _NotificationGroups(
                                        notifications: notifications,
                                        today: app.now(),
                                        onOpen: (notification) =>
                                            _openNotification(notification),
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

  List<UserNotification> _filtered(List<UserNotification> notifications) {
    return notifications.where((notification) {
      switch (_filter) {
        case _NotificationFilter.all:
          return true;
        case _NotificationFilter.unread:
          return !notification.read;
        case _NotificationFilter.booking:
          return notification.type == UserNotificationType.booking ||
              notification.type == UserNotificationType.reservation;
        case _NotificationFilter.payment:
          return notification.type == UserNotificationType.payment;
        case _NotificationFilter.trip:
          return notification.type == UserNotificationType.trip;
        case _NotificationFilter.review:
          return notification.type == UserNotificationType.review;
        case _NotificationFilter.rewards:
          return notification.type == UserNotificationType.promotion;
        case _NotificationFilter.wallet:
          return notification.target.kind == NotificationTargetKind.wallet ||
              notification.target.kind == NotificationTargetKind.tripDocument;
        case _NotificationFilter.system:
          return notification.type == UserNotificationType.system;
      }
    }).toList();
  }

  void _markAllRead(AppState app) {
    final l10n = AppLocalizations.of(context)!;
    final count = app.markAllNotificationsRead();
    _showMessage(l10n.notificationMarkAllReadResult(count));
  }

  void _openNotification(UserNotification notification) {
    final app = AppScope.of(context);
    app.markNotificationRead(notification.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OceanGlassBottomSheet(
        child: _NotificationDetailSheet(
          notificationId: notification.id,
          onOpenTarget: () {
            Navigator.pop(context);
            _openTarget(notification);
          },
          onDelete: () {
            Navigator.pop(context);
            _confirmDeleteNotification(notification.id);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDeleteNotification(String notificationId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.notificationDeleteConfirmTitle),
        content: Text(l10n.notificationDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.profileCancel),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(l10n.notificationDeleteConfirmAction),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    final app = AppScope.of(context);
    final result = app.deleteNotification(notificationId);
    final currentL10n = AppLocalizations.of(context)!;
    switch (result) {
      case NotificationActionResult.success:
        _showMessage(currentL10n.notificationDeletedMessage);
      case NotificationActionResult.notFound:
        _showMessage(currentL10n.notificationMissingMessage);
      case NotificationActionResult.unavailable:
        _showMessage(currentL10n.notificationsRealEmptyMessage);
    }
  }

  void _openTarget(UserNotification notification) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final target = notification.target;
    switch (target.kind) {
      case NotificationTargetKind.none:
        _showMessage(l10n.notificationTargetUnavailable);
      case NotificationTargetKind.booking:
        final code = target.bookingCode;
        final booking = code == null ? null : app.demoBookingByCode(code);
        if (booking == null) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(
              bookingCode: booking.code,
              fallbackBooking: booking,
            ),
          ),
        );
      case NotificationTargetKind.payment:
        final code = target.bookingCode;
        final attemptId = target.paymentAttemptId;
        final booking = code == null ? null : app.demoBookingByCode(code);
        final attempt =
            attemptId == null ? null : app.paymentAttemptById(attemptId);
        if (booking == null || attempt == null) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentStatusScreen(
              bookingCode: booking.code,
              attemptId: attempt.id,
            ),
          ),
        );
      case NotificationTargetKind.trip:
        final tripId = target.tripId;
        final trip = tripId == null ? null : app.tripById(tripId);
        if (trip == null) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
        );
      case NotificationTargetKind.tripCompanion:
        final tripId = target.tripId;
        final trip = tripId == null ? null : app.tripById(tripId);
        if (trip == null) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripCompanionScreen(trip: trip)),
        );
      case NotificationTargetKind.tripDocument:
        final tripId = target.tripId;
        final documentId = target.tripDocumentId;
        final trip = tripId == null ? null : app.tripById(tripId);
        final document =
            documentId == null ? null : app.tripDocumentById(documentId);
        if (trip == null || document == null || document.tripId != trip.id) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TripDocumentsScreen(trip: trip)),
        );
      case NotificationTargetKind.review:
        final reviewId = target.reviewId;
        final review = reviewId == null ? null : app.reviewById(reviewId);
        if (review == null) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewDetailScreen(
              reviewId: review.id,
              authorView: true,
            ),
          ),
        );
      case NotificationTargetKind.rewards:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RewardsHubScreen()),
        );
      case NotificationTargetKind.wallet:
        final walletId = target.walletItemId;
        final item =
            walletId == null ? null : app.travelWalletItemById(walletId);
        if (item == null) {
          _showMessage(l10n.notificationTargetMissing);
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TravelWalletScreen()),
        );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _RealModeBoundary extends StatelessWidget {
  final AppLocalizations l10n;

  const _RealModeBoundary({required this.l10n});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OceanEmptyState(
            title: l10n.notificationsRealEmptyTitle,
            message: l10n.notificationsRealEmptyMessage,
          ),
          const SizedBox(height: AppSpacing.md),
          OceanGlassCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notifications_off_rounded,
                    color: AppColors.ocean),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.notificationRealBoundary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final int totalCount;
  final VoidCallback? onMarkAllRead;

  const _NotificationHeader({
    required this.unreadCount,
    required this.totalCount,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OceanGlassCard(
      semanticLabel: l10n.notificationCenterSemantic,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OceanStatusPill(
                label: l10n.notificationDemoModeLabel,
                icon: Icons.science_rounded,
                color: AppColors.ocean,
              ),
              OceanStatusPill(
                label: l10n.notificationUnreadCount(unreadCount),
                semanticLabel: l10n.notificationUnreadCountSemantic(
                  unreadCount,
                ),
                icon: Icons.mark_email_unread_rounded,
                color: unreadCount == 0 ? AppColors.success : AppColors.coral,
              ),
              OceanStatusPill(
                label: l10n.notificationTotalCount(totalCount),
                icon: Icons.inbox_rounded,
                color: AppColors.turquoise600,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.notificationCenterSubtitle,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          OceanSecondaryButton(
            label: l10n.notificationsMarkAllRead,
            icon: Icons.done_all_rounded,
            semanticLabel: l10n.notificationMarkAllReadSemantic,
            onPressed: onMarkAllRead,
            fullWidth: false,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.notificationPreferenceBoundary,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FilterRail extends StatelessWidget {
  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onChanged;

  const _FilterRail({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Semantics(
        label: l10n.notificationFilterSemantic,
        child: SegmentedButton<_NotificationFilter>(
          key: const Key('notification-filter-rail'),
          selected: {selected},
          onSelectionChanged: (values) => onChanged(values.first),
          segments: [
            for (final filter in _NotificationFilter.values)
              ButtonSegment(
                value: filter,
                icon: Icon(_filterIcon(filter), size: AppIconSizes.xs),
                label: Text(_notificationFilterLabel(l10n, filter)),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationGroups extends StatelessWidget {
  final List<UserNotification> notifications;
  final DateTime today;
  final ValueChanged<UserNotification> onOpen;

  const _NotificationGroups({
    required this.notifications,
    required this.today,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final todayOnly = _notificationLocalDate(today);
    final todayItems = notifications
        .where((item) => _notificationLocalDate(item.createdAt) == todayOnly)
        .toList();
    final earlierItems = notifications
        .where((item) => _notificationLocalDate(item.createdAt) != todayOnly)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NotificationSection(
          title: l10n.notificationsToday,
          items: todayItems,
          onOpen: onOpen,
        ),
        if (todayItems.isNotEmpty && earlierItems.isNotEmpty)
          const SizedBox(height: AppSpacing.lg),
        _NotificationSection(
          title: l10n.notificationsEarlier,
          items: earlierItems,
          onOpen: onOpen,
        ),
      ],
    );
  }
}

class _NotificationSection extends StatelessWidget {
  final String title;
  final List<UserNotification> items;
  final ValueChanged<UserNotification> onOpen;

  const _NotificationSection({
    required this.title,
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _NotificationCard(
              notification: item,
              onTap: () => onOpen(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final UserNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = demoNotificationTitle(l10n, notification.template);
    final message = demoNotificationMessage(l10n, notification.template);
    final typeLabel = notificationTypeLabel(l10n, notification.type);
    final readLabel = notification.read
        ? l10n.notificationReadSemantic
        : l10n.notificationUnreadSemantic;
    final time = _formatNotificationTime(context, notification.createdAt);
    final color = _notificationColor(notification);
    return OceanGlassCard(
      key: Key('notification-card-${notification.id}'),
      onTap: onTap,
      semanticLabel: l10n.notificationCardSemantic(
        readLabel,
        typeLabel,
        title,
        time,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 420;
          final icon = _notificationIcon(notification);
          final leading = Container(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: color, size: AppIconSizes.sm),
          );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OceanStatusPill(
                    label: typeLabel,
                    icon: icon,
                    color: color,
                  ),
                  OceanStatusPill(
                    label: notification.read
                        ? l10n.notificationReadLabel
                        : l10n.notificationUnreadLabel,
                    icon: notification.read
                        ? Icons.drafts_rounded
                        : Icons.mark_email_unread_rounded,
                    color: notification.read
                        ? AppColors.textSecondary
                        : AppColors.coral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(message, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                time,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          );
          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leading,
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                content,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: AppSpacing.md),
              Expanded(child: content),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  final String notificationId;
  final VoidCallback onOpenTarget;
  final VoidCallback onDelete;

  const _NotificationDetailSheet({
    required this.notificationId,
    required this.onOpenTarget,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final notification = app.notificationById(notificationId);
    if (notification == null) {
      return OceanEmptyState(
        title: l10n.notificationMissingTitle,
        message: l10n.notificationMissingMessage,
      );
    }
    final title = demoNotificationTitle(l10n, notification.template);
    final message = demoNotificationMessage(l10n, notification.template);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OceanStatusPill(
                label: notificationTypeLabel(l10n, notification.type),
                icon: _notificationIcon(notification),
                color: _notificationColor(notification),
              ),
              OceanStatusPill(
                label: notificationPriorityLabel(l10n, notification.priority),
                icon: Icons.priority_high_rounded,
                color: _priorityColor(notification.priority),
              ),
              OceanStatusPill(
                label: notification.read
                    ? l10n.notificationReadLabel
                    : l10n.notificationUnreadLabel,
                icon: notification.read
                    ? Icons.drafts_rounded
                    : Icons.mark_email_unread_rounded,
                color: notification.read
                    ? AppColors.textSecondary
                    : AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: l10n.notificationCreatedAtLabel,
            value: _formatNotificationDateTime(context, notification.createdAt),
          ),
          if (notification.readAt != null)
            _DetailRow(
              icon: Icons.done_rounded,
              label: l10n.notificationReadAtLabel,
              value: _formatNotificationDateTime(context, notification.readAt!),
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.notificationPrivacyNote,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OceanPrimaryButton(
            label: notificationTargetActionLabel(l10n, notification.target),
            icon: _targetIcon(notification.target),
            semanticLabel: l10n.notificationOpenTargetSemantic,
            onPressed: notification.target.hasAction ? onOpenTarget : null,
          ),
          const SizedBox(height: AppSpacing.sm),
          OceanSecondaryButton(
            label: l10n.notificationDeleteAction,
            icon: Icons.delete_outline_rounded,
            semanticLabel: l10n.notificationDeleteSemantic,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.ocean, size: AppIconSizes.sm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(value, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      );
}

enum _NotificationFilter {
  all,
  unread,
  booking,
  payment,
  trip,
  review,
  rewards,
  wallet,
  system,
}

String _notificationFilterLabel(
  AppLocalizations l10n,
  _NotificationFilter filter,
) {
  switch (filter) {
    case _NotificationFilter.all:
      return l10n.notificationFilterAll;
    case _NotificationFilter.unread:
      return l10n.notificationFilterUnread;
    case _NotificationFilter.booking:
      return l10n.notificationFilterBookings;
    case _NotificationFilter.payment:
      return l10n.notificationFilterPayments;
    case _NotificationFilter.trip:
      return l10n.notificationFilterTrips;
    case _NotificationFilter.review:
      return l10n.notificationFilterReviews;
    case _NotificationFilter.rewards:
      return l10n.notificationFilterRewards;
    case _NotificationFilter.wallet:
      return l10n.notificationFilterWallet;
    case _NotificationFilter.system:
      return l10n.notificationFilterSystem;
  }
}

String notificationTypeLabel(
  AppLocalizations l10n,
  UserNotificationType type,
) {
  switch (type) {
    case UserNotificationType.booking:
      return l10n.notificationTypeBooking;
    case UserNotificationType.payment:
      return l10n.notificationTypePayment;
    case UserNotificationType.reservation:
      return l10n.notificationTypeReservation;
    case UserNotificationType.system:
      return l10n.notificationTypeSystem;
    case UserNotificationType.promotion:
      return l10n.notificationTypePromotion;
    case UserNotificationType.review:
      return l10n.notificationTypeReview;
    case UserNotificationType.partner:
      return l10n.notificationTypePartner;
    case UserNotificationType.admin:
      return l10n.notificationTypeAdmin;
    case UserNotificationType.message:
      return l10n.notificationTypeMessage;
    case UserNotificationType.trip:
      return l10n.notificationTypeTrip;
  }
}

String notificationPriorityLabel(
  AppLocalizations l10n,
  UserNotificationPriority priority,
) {
  switch (priority) {
    case UserNotificationPriority.low:
      return l10n.notificationPriorityLow;
    case UserNotificationPriority.normal:
      return l10n.notificationPriorityNormal;
    case UserNotificationPriority.high:
      return l10n.notificationPriorityHigh;
    case UserNotificationPriority.urgent:
      return l10n.notificationPriorityUrgent;
  }
}

String demoNotificationTitle(
  AppLocalizations l10n,
  DemoNotificationTemplate template,
) {
  switch (template) {
    case DemoNotificationTemplate.bookingModified:
      return l10n.notificationDemoBookingModifiedTitle;
    case DemoNotificationTemplate.paymentSuccessful:
      return l10n.notificationDemoPaymentSuccessTitle;
    case DemoNotificationTemplate.paymentFailed:
      return l10n.notificationDemoPaymentFailedTitle;
    case DemoNotificationTemplate.tripCollaboration:
      return l10n.notificationDemoTripCollaborationTitle;
    case DemoNotificationTemplate.itineraryReminder:
      return l10n.notificationDemoItineraryReminderTitle;
    case DemoNotificationTemplate.reviewReply:
      return l10n.notificationDemoReviewReplyTitle;
    case DemoNotificationTemplate.rewardUnlocked:
      return l10n.notificationDemoRewardTitle;
    case DemoNotificationTemplate.walletDocument:
      return l10n.notificationDemoWalletTitle;
    case DemoNotificationTemplate.systemAccount:
      return l10n.notificationDemoSystemTitle;
  }
}

String demoNotificationMessage(
  AppLocalizations l10n,
  DemoNotificationTemplate template,
) {
  switch (template) {
    case DemoNotificationTemplate.bookingModified:
      return l10n.notificationDemoBookingModifiedMessage;
    case DemoNotificationTemplate.paymentSuccessful:
      return l10n.notificationDemoPaymentSuccessMessage;
    case DemoNotificationTemplate.paymentFailed:
      return l10n.notificationDemoPaymentFailedMessage;
    case DemoNotificationTemplate.tripCollaboration:
      return l10n.notificationDemoTripCollaborationMessage;
    case DemoNotificationTemplate.itineraryReminder:
      return l10n.notificationDemoItineraryReminderMessage;
    case DemoNotificationTemplate.reviewReply:
      return l10n.notificationDemoReviewReplyMessage;
    case DemoNotificationTemplate.rewardUnlocked:
      return l10n.notificationDemoRewardMessage;
    case DemoNotificationTemplate.walletDocument:
      return l10n.notificationDemoWalletMessage;
    case DemoNotificationTemplate.systemAccount:
      return l10n.notificationDemoSystemMessage;
  }
}

String notificationTargetActionLabel(
  AppLocalizations l10n,
  NotificationTarget target,
) {
  switch (target.kind) {
    case NotificationTargetKind.none:
      return l10n.notificationNoTargetAction;
    case NotificationTargetKind.booking:
      return l10n.notificationOpenBooking;
    case NotificationTargetKind.payment:
      return l10n.notificationOpenPayment;
    case NotificationTargetKind.trip:
      return l10n.notificationOpenTrip;
    case NotificationTargetKind.tripCompanion:
      return l10n.notificationOpenTripCompanion;
    case NotificationTargetKind.tripDocument:
      return l10n.notificationOpenTripDocuments;
    case NotificationTargetKind.review:
      return l10n.notificationOpenReview;
    case NotificationTargetKind.rewards:
      return l10n.notificationOpenRewards;
    case NotificationTargetKind.wallet:
      return l10n.notificationOpenWallet;
  }
}

IconData _notificationIcon(UserNotification notification) {
  switch (notification.type) {
    case UserNotificationType.booking:
    case UserNotificationType.reservation:
      return Icons.hotel_rounded;
    case UserNotificationType.payment:
      return Icons.account_balance_wallet_rounded;
    case UserNotificationType.trip:
      return Icons.map_rounded;
    case UserNotificationType.review:
      return Icons.rate_review_rounded;
    case UserNotificationType.promotion:
      return Icons.redeem_rounded;
    case UserNotificationType.message:
      return Icons.forum_rounded;
    case UserNotificationType.partner:
    case UserNotificationType.admin:
    case UserNotificationType.system:
      return Icons.info_rounded;
  }
}

Color _notificationColor(UserNotification notification) {
  switch (notification.type) {
    case UserNotificationType.booking:
    case UserNotificationType.reservation:
      return AppColors.ocean;
    case UserNotificationType.payment:
      return notification.priority == UserNotificationPriority.high
          ? AppColors.coral
          : AppColors.success;
    case UserNotificationType.trip:
      return AppColors.turquoise600;
    case UserNotificationType.review:
      return AppColors.violet;
    case UserNotificationType.promotion:
      return AppColors.warning;
    case UserNotificationType.message:
      return AppColors.aqua;
    case UserNotificationType.partner:
    case UserNotificationType.admin:
    case UserNotificationType.system:
      return AppColors.textSecondary;
  }
}

Color _priorityColor(UserNotificationPriority priority) {
  switch (priority) {
    case UserNotificationPriority.low:
      return AppColors.textSecondary;
    case UserNotificationPriority.normal:
      return AppColors.ocean;
    case UserNotificationPriority.high:
      return AppColors.coral;
    case UserNotificationPriority.urgent:
      return AppColors.danger;
  }
}

IconData _targetIcon(NotificationTarget target) {
  switch (target.kind) {
    case NotificationTargetKind.none:
      return Icons.block_rounded;
    case NotificationTargetKind.booking:
      return Icons.hotel_rounded;
    case NotificationTargetKind.payment:
      return Icons.payments_rounded;
    case NotificationTargetKind.trip:
      return Icons.map_rounded;
    case NotificationTargetKind.tripCompanion:
      return Icons.group_rounded;
    case NotificationTargetKind.tripDocument:
      return Icons.folder_copy_rounded;
    case NotificationTargetKind.review:
      return Icons.rate_review_rounded;
    case NotificationTargetKind.rewards:
      return Icons.redeem_rounded;
    case NotificationTargetKind.wallet:
      return Icons.wallet_rounded;
  }
}

IconData _filterIcon(_NotificationFilter filter) {
  switch (filter) {
    case _NotificationFilter.all:
      return Icons.all_inbox_rounded;
    case _NotificationFilter.unread:
      return Icons.mark_email_unread_rounded;
    case _NotificationFilter.booking:
      return Icons.hotel_rounded;
    case _NotificationFilter.payment:
      return Icons.account_balance_wallet_rounded;
    case _NotificationFilter.trip:
      return Icons.map_rounded;
    case _NotificationFilter.review:
      return Icons.rate_review_rounded;
    case _NotificationFilter.rewards:
      return Icons.redeem_rounded;
    case _NotificationFilter.wallet:
      return Icons.wallet_rounded;
    case _NotificationFilter.system:
      return Icons.info_rounded;
  }
}

String _formatNotificationTime(BuildContext context, DateTime value) {
  return DateFormat.MMMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}

String _formatNotificationDateTime(BuildContext context, DateTime value) {
  return DateFormat.yMMMd(Localizations.localeOf(context).toString())
      .add_jm()
      .format(value.toLocal());
}

DateTime _notificationLocalDate(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
