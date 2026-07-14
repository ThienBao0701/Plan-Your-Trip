import 'package:flutter/material.dart';
import '../../core/app_state.dart';
import '../../shared/widgets/glass_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  String? _validationMessage() {
    final fullName = name.text.trim();
    final address = email.text.trim();
    if (fullName.length < 2) return 'Enter your full name.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(address)) {
      return 'Enter a valid email address.';
    }
    if (pass.text.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: BubbleBackground(
            child: SafeArea(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              Text('Create account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium),
                              const SizedBox(height: 18),
                              GlassCard(
                                  child: Column(children: [
                                GlassTextField(
                                    controller: name,
                                    hint: 'Full name',
                                    icon: Icons.person_rounded),
                                const SizedBox(height: 12),
                                GlassTextField(
                                    controller: email,
                                    hint: 'Email',
                                    icon: Icons.mail_rounded),
                                const SizedBox(height: 12),
                                GlassTextField(
                                    controller: pass,
                                    hint: 'Password at least 8 characters',
                                    icon: Icons.lock_rounded,
                                    obscure: true),
                                const SizedBox(height: 18),
                                loading
                                    ? const PremiumLoading()
                                    : GlassButton(
                                        text: 'Register',
                                        onPressed: () async {
                                          if (loading) return;
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final nav = Navigator.of(context);
                                          final validation =
                                              _validationMessage();
                                          if (validation != null) {
                                            messenger.showSnackBar(SnackBar(
                                                content: Text(validation)));
                                            return;
                                          }
                                          setState(() => loading = true);
                                          final res = await app.register(
                                              name.text.trim(),
                                              email.text.trim(),
                                              pass.text);
                                          if (!mounted) return;
                                          setState(() => loading = false);
                                          if (res['success'] == true) {
                                            messenger.showSnackBar(const SnackBar(
                                                content: Text(
                                                    'Registration complete. Please log in.')));
                                            nav.pop();
                                          } else {
                                            messenger.showSnackBar(SnackBar(
                                                content: Text(res['message']
                                                        as String? ??
                                                    'Registration failed.')));
                                          }
                                        })
                              ]))
                            ]))))));
  }
}
