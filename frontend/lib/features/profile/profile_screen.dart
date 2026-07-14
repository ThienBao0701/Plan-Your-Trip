import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../auth/login_screen.dart';
import 'settings_screen.dart';
import 'static_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final tripCount = app.trips.length;
    final expenseCount = app.expenses.length;

    return ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          // User card
          GlassCard(
              child: Row(children: [
            CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.ocean.withValues(alpha: .15),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.ocean, size: 32)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(app.email ?? 'Traveler',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Row(children: [
                    if (app.demoMode)
                      Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.ocean,
                              borderRadius: BorderRadius.circular(999)),
                          child: const Text('Demo Mode',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800))),
                    Text(app.demoMode ? 'Mock data active' : 'Backend account',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12)),
                  ]),
                ]))
          ])),
          const SizedBox(height: 12),
          // Stats card
          GlassCard(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                _stat(context, '$tripCount', 'Trips'),
                Container(
                    width: 1,
                    height: 40,
                    color: AppColors.slate.withValues(alpha: .3)),
                _stat(context, '$expenseCount', 'Expenses'),
                Container(
                    width: 1,
                    height: 40,
                    color: AppColors.slate.withValues(alpha: .3)),
                _stat(context, '${app.timeline.length}', 'Activities'),
              ])),
          const SizedBox(height: 16),
          const _SectionHeader('Account'),
          _navCard(context, Icons.settings_rounded, 'Settings', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()));
          }),
          const SizedBox(height: 6),
          const _SectionHeader('Legal'),
          _navCard(context, Icons.privacy_tip_rounded, 'Privacy Policy', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StaticPage(title: 'Privacy Policy')));
          }),
          _navCard(context, Icons.gavel_rounded, 'Terms of Service', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const StaticPage(title: 'Terms of Service')));
          }),
          _navCard(context, Icons.info_outline_rounded, 'About App', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const StaticPage(title: 'About App')));
          }),
          const SizedBox(height: 16),
          GlassButton(
              text: 'Logout',
              icon: Icons.logout_rounded,
              onPressed: () async {
                await app.logout();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false);
                }
              }),
          const SizedBox(height: 8),
          Center(
              child: Text('Plan Your Trip v1.0.0',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate.withValues(alpha: .7)))),
        ]);
  }

  Widget _stat(BuildContext context, String value, String label) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ocean)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.slate)),
      ]);

  Widget _navCard(BuildContext context, IconData icon, String title,
          VoidCallback onTap) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GlassCard(
              onTap: onTap,
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: AppColors.ocean.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: AppColors.ocean, size: 20)),
                const SizedBox(width: 14),
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleMedium)),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
              ])));
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.slate,
              letterSpacing: 0.8)));
}
