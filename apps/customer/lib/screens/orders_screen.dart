import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import 'sign_in_screen.dart';
import 'store_screen.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppUser?>();
    final repo = context.read<MyOrdersRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('orders'))),
      body: user == null
          ? EmptyState(
              icon: Icons.receipt_long_rounded,
              text: context.t('signInToOrder'),
              action: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
                onPressed: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const SignInScreen())),
                child: Text(context.t('signIn')),
              ),
            )
          : StreamBuilder<List<Order>>(
              key: ValueKey(user.id),
              stream: repo.watchMyOrders(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final orders = snap.data!;
                if (orders.isEmpty) {
                  return EmptyState(icon: Icons.receipt_long_rounded, text: context.t('noOrders'));
                }
                final active = orders.where((o) => o.isActive).toList();
                final past = orders.where((o) => !o.isActive).toList();
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (active.isNotEmpty) _Heading(context.t('activeOrders')),
                    for (final o in active) _OrderCard(o),
                    if (past.isNotEmpty) _Heading(context.t('pastOrders')),
                    for (final o in past) _OrderCard(o),
                  ],
                );
              },
            ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
  );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard(this.order);

  Future<void> _reorder(BuildContext context) async {
    final store = await context.read<MyOrdersRepository>().store(order.storeId!);
    if (store != null && context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => StoreScreen(store: store)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = order.storeName == null
        ? context.t('courierTitle')
        : context.tr(order.storeName!);
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  StatusChip(order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                itemsSummary(context, order),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    '#${order.code} · ${timeAgo(context, order.createdAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    context.price(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              if (!order.isActive && order.storeId != null)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    onPressed: () => _reorder(context),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: Text(context.t('reorder')),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
