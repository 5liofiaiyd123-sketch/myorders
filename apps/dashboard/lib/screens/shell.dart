import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import 'applications_screen.dart';
import 'menu_screen.dart';
import 'orders_board.dart';
import 'overview_screen.dart';
import 'riders_screen.dart';
import 'stores_screen.dart';

class _Page {
  final String labelKey;
  final IconData icon;
  final Widget Function() build;
  const _Page(this.labelKey, this.icon, this.build);
}

/// Side navigation on wide screens, a drawer on phones. Partners see their
/// own store; admins see everything.
class DashboardShell extends StatefulWidget {
  final AppUser user;
  const DashboardShell({super.key, required this.user});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _index = 0;

  List<_Page> get _pages {
    final user = widget.user;
    if (user.role == UserRole.partner) {
      final storeId = user.storeId!;
      return [
        _Page('orders', Icons.receipt_long_rounded, () => OrdersBoard(storeId: storeId)),
        _Page('menu', Icons.restaurant_menu_rounded, () => MenuScreen(storeId: storeId)),
      ];
    }
    return [
      _Page('overview', Icons.dashboard_rounded, () => const OverviewScreen()),
      _Page('allOrders', Icons.receipt_long_rounded, () => const OrdersBoard()),
      _Page('stores', Icons.storefront_rounded, () => const StoresScreen()),
      _Page('riders', Icons.two_wheeler_rounded, () => const RidersScreen()),
      _Page('applications', Icons.how_to_reg_rounded, () => const ApplicationsScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final repo = context.read<MyOrdersRepository>();
    final subtitle = context.t(widget.user.role == UserRole.admin ? 'adminPanel' : 'partnerPortal');

    Widget navList({required bool closeDrawer}) => ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 12), child: BrandLogo(size: 26)),
              Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
        for (var i = 0; i < pages.length; i++)
          ListTile(
            leading: Icon(pages[i].icon),
            title: Text(context.t(pages[i].labelKey)),
            selected: i == _index,
            selectedColor: AppColors.teal,
            selectedTileColor: AppColors.tealLight,
            onTap: () {
              setState(() => _index = i);
              if (closeDrawer) Navigator.of(context).pop();
            },
          ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.translate_rounded),
          title: Text(context.t('switchLanguage')),
          onTap: context.read<LocaleModel>().toggle,
        ),
        ListTile(
          leading: const Icon(Icons.logout_rounded),
          title: Text(context.t('signOut')),
          onTap: repo.signOut,
        ),
      ],
    );

    final page = pages[_index];
    final body = Column(
      children: [
        const DemoBanner(),
        Expanded(
          child: KeyedSubtree(key: ValueKey(_index), child: page.build()),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(page.labelKey)),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 16),
            child: Center(
              child: Text(widget.user.name, style: const TextStyle(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: navList(closeDrawer: true)),
      body: wide
          ? Row(
              children: [
                SizedBox(
                  width: 250,
                  child: Material(color: Colors.white, child: navList(closeDrawer: false)),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            )
          : body,
    );
  }
}
