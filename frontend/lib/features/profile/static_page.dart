import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';

class StaticPage extends StatelessWidget {
  final String title;
  const StaticPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title)),
      body: BubbleBackground(
          child: SafeArea(
              child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        ..._sections(title).map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: GlassCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  if (s.heading.isNotEmpty)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(s.heading,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.ocean))),
                  Text(s.body, style: Theme.of(context).textTheme.bodyLarge),
                ])))),
      ]))));

  List<_Section> _sections(String t) {
    switch (t) {
      case 'Privacy Policy':
        return [
          const _Section('Data We Collect',
              'Plan Your Trip collects only the minimum information required to operate: your email address for authentication, trip and timeline data you create, expense records, and app preferences such as Demo Mode status.\n\nIn Demo Mode, no personal data is transmitted to any server. All data is stored locally as mock data.'),
          const _Section('How We Use Your Data',
              'Your data is used exclusively to power your travel planning experience. We do not sell, share, or monetize your personal information with third parties.\n\nTrip data, timeline items, and expenses are stored only for the purpose of providing the trip planning features.'),
          const _Section('Data Storage',
              'Authentication tokens and session preferences are stored locally using SharedPreferences in this demo implementation. It is not secure credential storage. In Demo Mode, mock data remains local and resets on logout.'),
          const _Section('Your Rights',
              'You may request deletion of all account data at any time by logging out and using the Reset Demo Data option in Settings. For backend accounts, contact support for full data deletion.'),
          const _Section('Contact',
              'For privacy inquiries, contact: privacy@planyourtrip.com'),
        ];
      case 'Terms of Service':
        return [
          const _Section('Acceptance of Terms',
              'By using Plan Your Trip, you agree to these Terms of Service. If you do not agree, please do not use the application.'),
          const _Section('Permitted Use',
              'Plan Your Trip is designed for personal travel planning. You may use it to:\n• Create and manage personal trip itineraries\n• Record travel expenses\n• Discover and save places of interest\n• Plan daily travel schedules'),
          const _Section('Prohibited Use',
              'You may not use this application to:\n• Upload illegal, harmful, or offensive content\n• Impersonate other users\n• Attempt to reverse-engineer or exploit the application\n• Use the app for commercial resale without authorization'),
          const _Section('Demo Mode',
              'Demo Mode provides simulated data for testing and demonstration purposes. Data in Demo Mode is not persisted to any backend server and is reset on logout.'),
          const _Section('Limitation of Liability',
              'Plan Your Trip is provided "as is" without warranties of any kind. We are not liable for any travel decisions made based on information within the app.'),
          const _Section('Changes to Terms',
              'We may update these terms from time to time. Continued use of the app after changes constitutes acceptance of the new terms.'),
        ];
      case 'About App':
        return [
          const _Section('Plan Your Trip',
              'Plan Your Trip is a premium travel planning application designed to help you create beautiful daily itineraries, discover curated places, and manage travel budgets — all in one elegant interface.\n\nBuilt with Flutter, powered by glassmorphism design and a local Demo Mode.'),
          const _Section('Key Features',
              '• Trip Planner Timeline — daily schedule for every trip\n• Place Discovery — curated hotels, cafes, restaurants, attractions, and photo spots\n• Expense Tracker — budget and spending management\n• Demo Mode — full experience without a backend connection\n• Add to Trip — add any place directly to your trip timeline'),
          const _Section('Design',
              'Inspired by premium travel apps and iOS Liquid Glass aesthetic. Features smooth glassmorphism cards, bubble gradient backgrounds, and a clean travel discovery layout.'),
          const _Section('Version',
              'Version: 1.0.0\nBuild: 1\nPlatform: Flutter 3.x\nDemo Mode: Active'),
          const _Section('Contact & Support',
              'For support and feedback:\nsupport@planyourtrip.com\n\nFollow us for travel inspiration and app updates.'),
        ];
      default:
        return [
          _Section(
              t, 'Content for "$t" is coming soon. Check back for updates.'),
        ];
    }
  }
}

class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}
