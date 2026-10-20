import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

/// Live orders in three columns: new, in progress, done. With [storeId] it
/// shows one store's orders (partner); without it, every order (admin).
class OrdersBoard extends StatelessWidget {
  final String? storeId;
  const OrdersBoard({super.key, this.storeId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    return Column(
      children: [
        if (storeId != null) _StoreOpenSwitch(storeId: storeId!),
        Expanded(
          child: StreamBuilder<List<Order>>(
            stream: storeId == null ? repo.watchAllOrders() : repo.watchStoreOrders(storeId!),
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final orders = snap.data!;
              final columns = [
                (context.t('newOrders'), orders.where((o) => o.status == OrderStatus.pending)),
                (
                  context.t('inProgress'),
                  orders.where((o) => o.isActive && o.status != OrderStatus.pending),
                ),
                (context.t('done'), orders.where((o) => !o.isActive).take(30)),
              ];
              final wide = MediaQuery.sizeOf(context).width >= 1100;
              final lists = [
                for (final (title, list) in columns)
                  _Column(title: title, orders: list.toList(), admin: storeId == null),
              ];
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final l in lists) Expanded(child: l)],
                );
              }
              return DefaultTabController(
                length: 3,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        for (final (title, list) in columns) Tab(text: '$title (${list.length})'),
                      ],
                    ),
                    Expanded(child: TabBarView(children: lists)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoreOpenSwitch extends StatefulWidget {
  final String storeId;
  const _StoreOpenSwitch({required this.storeId});

  @override
  State<_StoreOpenSwitch> createState() => _StoreOpenSwitchState();
}

class _StoreOpenSwitchState extends State<_StoreOpenSwitch> {
  bool? _open;

  @override
  void initState() {
    super.initState();
    context.read<MyOrdersRepository>().store(widget.storeId).then((s) {
      if (mounted) setState(() => _open = s?.isOpen ?? false);
    });
  }

  Future<void> _set(bool open) async {
    setState(() => _open = open);
    try {
      await context.read<MyOrdersRepository>().setStoreOpen(widget.storeId, open);
    } catch (e) {
      if (mounted) {
        setState(() => _open = !open);
        showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_open == null) return const SizedBox.shrink();
    return SwitchListTile(
      tileColor: _open! ? AppColors.tealLight : AppColors.delivery.withValues(alpha: 0.1),
      title: Text(
        context.t(_open! ? 'storeOpen' : 'storeClosed'),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      value: _open!,
      onChanged: _set,
    );
  }
}

class _Column extends StatelessWidget {
  final String title;
  final List<Order> orders;
  final bool admin;
  const _Column({required this.title, required this.orders, required this.admin});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (MediaQuery.sizeOf(context).width >= 1100)
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              '$title (${orders.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        for (final o in orders) OrderCard(order: o, admin: admin),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  final Order order;
  final bool admin;
  const OrderCard({super.key, required this.order, required this.admin});

  Future<void> _set(BuildContext context, OrderStatus status) async {
    try {
      await context.read<MyOrdersRepository>().updateOrderStatus(order.id, status);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = order;
    // Partners move their order until it's ready; riders take it from there.
    final partnerNext = switch (o.status) {
      OrderStatus.pending => (OrderStatus.accepted, 'accept'),
      OrderStatus.accepted => (OrderStatus.preparing, 'startPreparing'),
      OrderStatus.preparing => (OrderStatus.ready, 'markReady'),
      _ => null,
    };
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: o.status == OrderStatus.pending ? AppColors.promo : AppColors.border,
          width: o.status == OrderStatus.pending ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${o.code}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(width: 8),
                Text(
                  timeAgo(context, o.createdAt),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const Spacer(),
                StatusChip(o.status),
              ],
            ),
            if (admin)
              Text(
                o.storeName == null ? context.t('courierTitle') : context.tr(o.storeName!),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: 6),
            for (final i in o.items)
              Text('${i.quantity}× ${context.tr(i.name)}  ·  ${context.price(i.total)}'),
            if (o.kind == OrderKind.courier) Text('${o.pickupAddress} → ${o.address}'),
            if (o.notes.isNotEmpty && o.kind == OrderKind.store)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(o.notes, style: const TextStyle(color: AppColors.textMuted)),
                  ),
                ],
              ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${o.customerName} · ${o.address}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ),
                Text(
                  context.price(admin ? o.total : o.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (!admin)
              Text(
                '${context.t('commission')}: ${context.price(o.subtotal * platformCommission)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            if (o.riderName != null)
              Row(
                children: [
                  const Icon(Icons.delivery_dining_rounded, size: 18, color: AppColors.teal),
                  const SizedBox(width: 4),
                  Text('${o.riderName}', style: const TextStyle(color: AppColors.teal)),
                ],
              ),
            if (o.isActive) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (partnerNext != null)
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () => _set(context, partnerNext.$1),
                      child: Text(context.t(partnerNext.$2)),
                    ),
                  if (o.status == OrderStatus.ready && o.riderId == null)
                    Chip(label: Text(context.t('waitingRider'))),
                  if (o.status == OrderStatus.pending || admin)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.delivery,
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => _set(context, OrderStatus.cancelled),
                      child: Text(
                        context.t(o.status == OrderStatus.pending ? 'reject' : 'cancelOrder'),
                      ),
                    ),
                  if (admin && o.riderId != null)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                      onPressed: () => _set(context, OrderStatus.delivered),
                      child: Text(context.t('delivered')),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
