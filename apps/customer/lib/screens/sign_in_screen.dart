import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../cart.dart';

/// Phone number + SMS code sign-in. Pops with the signed-in [AppUser].
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;

  /// Egyptian numbers typed as 010... become +2010...
  String get _e164 {
    final digits = _phone.text.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) return digits;
    if (digits.startsWith('0')) return '+2$digits';
    return '+$digits';
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _send() {
    if (_phone.text.trim().length < 8) return showError(context, context.t('phone'));
    _run(() async {
      await context.read<MyOrdersRepository>().sendOtp(_e164);
      setState(() => _codeSent = true);
    });
  }

  void _verify() => _run(() async {
    final repo = context.read<MyOrdersRepository>();
    final favorites = context.read<FavoritesModel>();
    final user = await repo.verifyOtp(_e164, _code.text.trim(), name: _name.text);
    await favorites.reload();
    if (mounted) Navigator.of(context).pop(user);
  });

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('signIn'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: BrandLogo(size: 36)),
          const SizedBox(height: 8),
          Text(
            context.t('signInToOrder'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            enabled: !_codeSent,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: context.t('yourName')),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            enabled: !_codeSent,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: context.t('phone'),
              hintText: '010 1234 5678',
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            Text(context.t('enterCode')),
            const SizedBox(height: 8),
            TextField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : (_codeSent ? _verify : _send),
            child: Text(context.t(_codeSent ? 'verify' : 'sendCode')),
          ),
          if (context.read<MyOrdersRepository>().isDemo)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                context.t('demoOtp'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}
