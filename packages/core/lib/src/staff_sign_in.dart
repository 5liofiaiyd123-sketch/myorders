import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'brand.dart';
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred so the photo reads as a backdrop at any screen size.
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Image.asset(AppImages.hero, package: AppImages.package, fit: BoxFit.cover),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.tealDark.withValues(alpha: 0.25),
                  AppColors.tealDark.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 12,
                  shadowColor: const Color(0x55062128),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 14),
                                    child: BrandLogo(size: 28),
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
        ],
      ),
    );
  }
}
