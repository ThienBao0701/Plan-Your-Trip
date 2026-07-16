import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../design/app_colors.dart';
import '../../design/app_icon_sizes.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final bool loading;

  const NotificationsScreen({super.key, this.loading = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final readIds = <String>{'tips', 'budget'};

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final l10n = AppLocalizations.of(context)!;
    final items = app.demoMode ? _demoItems(context) : <_NotificationItem>[];
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
          child: widget.loading
              ? const Center(
                  child: SizedBox(width: 420, child: OceanLoadingState()),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.xxl,
                  ),
                  children: [
                    OceanContentConstraint(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (items.any((item) => !readIds.contains(item.id)))
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => setState(
                                  () => readIds.addAll(
                                    items.map((item) => item.id),
                                  ),
                                ),
                                child: Text(l10n.notificationsMarkAllRead),
                              ),
                            ),
                          if (!app.demoMode)
                            OceanEmptyState(
                              title: l10n.notificationsRealEmptyTitle,
                              message: l10n.notificationsRealEmptyMessage,
                            )
                          else if (items.isEmpty)
                            OceanEmptyState(
                              title: l10n.notificationsDemoEmptyTitle,
                              message: l10n.notificationsDemoEmptyMessage,
                            )
                          else ...[
                            _section(
                              context,
                              title: l10n.notificationsToday,
                              items: items
                                  .where(
                                      (item) => item.section == _Section.today)
                                  .toList(),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _section(
                              context,
                              title: l10n.notificationsEarlier,
                              items: items
                                  .where((item) =>
                                      item.section == _Section.earlier)
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required List<_NotificationItem> items,
  }) {
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
              item: item,
              read: readIds.contains(item.id),
              onTap: () => setState(() => readIds.add(item.id)),
            ),
          ),
        ),
      ],
    );
  }

  List<_NotificationItem> _demoItems(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _NotificationItem(
        id: 'schedule',
        title: l10n.notificationScheduleTitle,
        message: l10n.notificationScheduleMessage,
        time: '09:30',
        icon: Icons.calendar_month_rounded,
        color: AppColors.ocean,
        section: _Section.today,
      ),
      _NotificationItem(
        id: 'booking',
        title: l10n.notificationBookingTitle,
        message: l10n.notificationBookingMessage,
        time: '08:15',
        icon: Icons.notifications_rounded,
        color: AppColors.turquoise600,
        section: _Section.today,
      ),
      _NotificationItem(
        id: 'tips',
        title: l10n.notificationTipsTitle,
        message: l10n.notificationTipsMessage,
        time: l10n.notificationYesterday,
        icon: Icons.tips_and_updates_rounded,
        color: AppColors.ocean400,
        section: _Section.earlier,
      ),
      _NotificationItem(
        id: 'budget',
        title: l10n.notificationBudgetTitle,
        message: l10n.notificationBudgetMessage,
        time: l10n.notificationBudgetDate,
        icon: Icons.pie_chart_rounded,
        color: AppColors.turquoise600,
        section: _Section.earlier,
      ),
    ];
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  final bool read;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.read,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: read
          ? l10n.notificationReadSemantic
          : l10n.notificationUnreadSemantic,
      child: OceanGlassCard(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(AppRadii.xl),
              ),
              child: Icon(item.icon, color: item.color, size: AppIconSizes.md),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(item.message,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(item.time, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                if (!read)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.turquoise600,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color color;
  final _Section section;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.color,
    required this.section,
  });
}

enum _Section { today, earlier }
