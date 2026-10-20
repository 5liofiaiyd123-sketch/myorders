import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../cart.dart';
import 'addresses_screen.dart';
import 'partner_screen.dart';
import 'sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, AppUser user) async {
    final controller = TextEditingController(text: user.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('yourName')),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.t('save')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    try {
      await context.read<MyOrdersRepository>().updateName(name);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser?>();
    final locale = context.watch<LocaleModel>();
    void push(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

    return Scaffold(
      appBar: AppBar(title: Text(context.t('profile'))),
      body: ListView(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.tealLight,
              child: Icon(Icons.person_rounded, color: AppColors.teal, size: 32),
            ),
            title: Text(
              user?.name ?? context.t('guest'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(user?.phone ?? context.t('signInToOrder')),
            trailing: user == null
                ? FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => push(const SignInScreen()),
                    child: Text(context.t('signIn')),
                  )
                : IconButton(
                    onPressed: () => _editName(context, user),
                    icon: const Icon(Icons.edit_outlined),
                  ),
          ),
          const Divider(),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: Text(context.t('savedAddresses')),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => push(const AddressesScreen()),
            ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: Text(context.t('language')),
            trailing: Text(
              locale.isArabic ? 'العربية' : 'English',
              style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
            ),
            onTap: locale.toggle,
          ),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded),
            title: Text(context.t('support')),
            subtitle: Text(context.t('whatsapp')),
            onTap: () => openWhatsApp(AppConfig.supportWhatsApp),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_rounded),
            title: Text(context.t('becomePartner')),
            subtitle: Text(context.t('partnerPitchBody')),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => push(const PartnerScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: Text(context.t('about')),
            subtitle: Text(context.t('aboutBody')),
          ),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: AppColors.delivery),
              title: Text(context.t('signOut'), style: const TextStyle(color: AppColors.delivery)),
              onTap: () async {
                final favorites = context.read<FavoritesModel>();
                await context.read<MyOrdersRepository>().signOut();
                await favorites.reload();
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
