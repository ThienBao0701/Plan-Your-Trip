import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../shared/widgets/glass_widgets.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
      body: BubbleBackground(
          child: SafeArea(
              child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Spacer(),
                        GlassCard(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.network(
                                    'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=1000&q=80',
                                    height: 330,
                                    width: double.infinity,
                                    fit: BoxFit.cover))),
                        const SizedBox(height: 28),
                        Text('Plan days, places, budgets — beautifully.',
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 14),
                        Text(
                            'Create daily travel schedules with premium glass cards, curated places, and a reliable Demo Mode when your backend is offline.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: AppColors.slate)),
                        const Spacer(),
                        GlassButton(
                            text: 'Start planning',
                            icon: Icons.flight_takeoff_rounded,
                            onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()))),
                      ])))));
}
