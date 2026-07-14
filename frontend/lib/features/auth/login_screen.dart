import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../core/mock/mock_data.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../home/app_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: MockData.demoEmail);
  final pass = TextEditingController(text: MockData.demoPassword);
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
        body: BubbleBackground(
            child: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: ListView(
                            padding: const EdgeInsets.all(24),
                            shrinkWrap: true,
                            children: [
                              Text('Welcome back',
                                  style:
                                      Theme.of(context).textTheme.displaySmall),
                              const SizedBox(height: 8),
                              Text(
                                  'Demo account: ${MockData.demoEmail} / ${MockData.demoPassword}',
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(height: 26),
                              GlassCard(
                                  child: Column(children: [
                                GlassTextField(
                                    controller: email,
                                    hint: 'Email',
                                    icon: Icons.mail_rounded,
                                    keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 14),
                                GlassTextField(
                                    controller: pass,
                                    hint: 'Password',
                                    icon: Icons.lock_rounded,
                                    obscure: true),
                                const SizedBox(height: 18),
                                loading
                                    ? const PremiumLoading()
                                    : GlassButton(
                                        text: 'Login',
                                        icon: Icons.login_rounded,
                                        onPressed: () async {
                                          if (loading) return;
                                          setState(() => loading = true);
                                          final nav = Navigator.of(context);
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final res = await app.login(
                                              email.text, pass.text);
                                          if (!mounted) return;
                                          setState(() => loading = false);
                                          if (res['success'] == true) {
                                            nav.pushReplacement(
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        const AppShell()));
                                          } else {
                                            messenger.showSnackBar(SnackBar(
                                                content: Text(
                                                    res['message'] as String? ??
                                                        'Login failed')));
                                          }
                                        }),
                                TextButton(
                                    onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const RegisterScreen())),
                                    child: const Text('Create new account'))
                              ])),
                            ]))))));
  }
}
