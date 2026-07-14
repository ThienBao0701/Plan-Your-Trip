import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: BubbleBackground(
            child: SafeArea(
                child: ListView(padding: const EdgeInsets.all(20), children: [
          Text('Preferences',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          GlassCard(
              child: Column(children: [
            _SettingsTile(
                icon: Icons.science_rounded,
                title: 'Demo Mode',
                subtitle: app.demoMode
                    ? 'Active — using mock data'
                    : 'Backend connected',
                trailing: Switch(
                    value: app.demoMode,
                    activeThumbColor: AppColors.ocean,
                    onChanged: null)),
            const Divider(),
            _SettingsTile(
                icon: Icons.cloud_rounded,
                title: 'Backend URL',
                subtitle:
                    app.demoMode ? 'Not connected (Demo Mode)' : 'Connected',
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.slate)),
          ])),
          const SizedBox(height: 16),
          GlassCard(
              child: Column(children: [
            _SettingsTile(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Trip reminders and updates',
                trailing: Switch(value: false, onChanged: (_) {})),
            const Divider(),
            const _SettingsTile(
                icon: Icons.dark_mode_rounded,
                title: 'Dark mode',
                subtitle: 'Coming soon',
                trailing: Switch(value: false, onChanged: null)),
          ])),
          const SizedBox(height: 16),
          const GlassCard(
              child: Column(children: [
            _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                trailing:
                    Icon(Icons.chevron_right_rounded, color: AppColors.slate)),
            Divider(),
            _SettingsTile(
                icon: Icons.attach_money_rounded,
                title: 'Currency',
                subtitle: 'Vietnamese Dong (₫)',
                trailing:
                    Icon(Icons.chevron_right_rounded, color: AppColors.slate)),
          ])),
          const SizedBox(height: 16),
          GlassCard(
              child: Column(children: [
            _SettingsTile(
                icon: Icons.restore_rounded,
                title: 'Reset demo data',
                subtitle: 'Restore original mock trips and places',
                trailing: TextButton(
                    onPressed: () => _resetDemo(context, app),
                    child: const Text('Reset'))),
          ])),
          const SizedBox(height: 20),
          Center(
              child: Column(children: [
            const Text('Plan Your Trip',
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.ocean)),
            const Text('Version 1.0.0',
                style: TextStyle(color: AppColors.slate, fontSize: 12)),
            const SizedBox(height: 4),
            Text(app.demoMode ? 'Running in Demo Mode' : 'Connected to backend',
                style: const TextStyle(color: AppColors.slate, fontSize: 11)),
          ])),
        ]))));
  }

  void _resetDemo(BuildContext ctx, AppState app) {
    showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: const Text('Reset demo data?'),
                content: const Text(
                    'This will restore all original mock trips, places, and expenses.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () async {
                        await app.logout();
                        await app.login('demo@planyourtrip.com', 'demo123456');
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                              content: Text('Demo data restored!')));
                        }
                      },
                      child: const Text('Reset')),
                ]));
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: AppColors.ocean.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.ocean, size: 20)),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.slate)),
        ])),
        trailing,
      ]));
}
