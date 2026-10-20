import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models.dart';
import 'data/repository.dart';
import 'l10n.dart';
import 'theme.dart';
import 'widgets.dart';

/// Email + password sign-in for riders, partners and admins.
class StaffSignInScreen extends StatefulWidget {
  final String title;
  final Set<UserRole> allowedRoles;
  const StaffSignInScreen({super.key, required this.title, required this.allowedRoles});

  @override
  State<StaffSignInScreen> createState() => _StaffSignInScreenState();
}

class _StaffSignInScreenState extends State<StaffSignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  Future<void> _signIn() async {
    final repo = context.read<MyOrdersRepository>();
    setState(() => _busy = true);
    try {
      final user = await repo.signInWithEmail(_email.text, _password.text);
      if (!widget.allowedRoles.contains(user.role)) {
        await repo.signOut();
        if (mounted) showError(context, context.t('notAllowed'));
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A6C7C), Color(0xFF14A3B8), Color(0xFF7FD3DE)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'MyOrders',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.teal,
                                ),
                              ),
                            ),
                            const LanguageButton(),
                          ],
                        ),
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: context.t('email'),
                            prefixIcon: const Icon(Icons.alternate_email_rounded),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _signIn(),
                          decoration: InputDecoration(
                            labelText: context.t('password'),
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _signIn,
                          child: Text(context.t('signIn')),
                        ),
                        if (context.read<MyOrdersRepository>().isDemo)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              context.t('demoStaff'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
