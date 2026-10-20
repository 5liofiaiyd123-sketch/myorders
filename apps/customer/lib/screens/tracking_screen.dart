import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

/// Live status of one order, with the rider on a map once picked up.
class TrackingScreen extends StatelessWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    return StreamBuilder<Order?>(
      stream: repo.watchOrder(orderId),
      builder: (context, snap) {
        final order = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              order == null ? context.t('trackOrder') : '${context.t('order')} #${order.code}',
            ),
          ),
          body: order == null
              ? const Center(child: CircularProgressIndicator())
              : _TrackingBody(order: order),
        );
      },
    );
  }
}

class _TrackingBody extends StatelessWidget {
  final Order order;
  const _TrackingBody({required this.order});

  Future<void> _cancel(BuildContext context) async {
    try {
      await context.read<MyOrdersRepository>().cancelOrder(order.id);
      if (context.mounted) showDone(context, context.t('orderCancelled'));
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = LatLng(order.lat ?? dahabCenter.latitude, order.lng ?? dahabCenter.longitude);
    final rider = order.riderLat == null ? null : LatLng(order.riderLat!, order.riderLng!);
    final steps = order.kind == OrderKind.courier
        ? const [
            OrderStatus.pending,
            OrderStatus.accepted,
            OrderStatus.pickedUp,
            OrderStatus.delivered,
          ]
        : const [
            OrderStatus.pending,
            OrderStatus.accepted,
            OrderStatus.preparing,
            OrderStatus.pickedUp,
            OrderStatus.delivered,
          ];
    final reached = order.status == OrderStatus.ready
        ? steps.indexOf(OrderStatus.preparing)
        : steps.indexOf(order.status);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 220,
          child: DahabMap(
            key: ValueKey(rider),
            center: rider ?? customer,
            zoom: 14.5,
            pins: [
              MapPin(customer, Icons.home_rounded, customerPinColor),
              if (rider != null) MapPin(rider, Icons.two_wheeler_rounded, riderPinColor),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (order.status == OrderStatus.cancelled)
          Center(child: StatusChip(order.status))
        else
          for (var i = 0; i < steps.length; i++)
            _Step(
              label: context.t(i == 0 ? 'step.placed' : 'step.${steps[i].name}'),
              done: i <= reached,
              current: i == reached && order.isActive,
              last: i == steps.length - 1,
            ),
        if (order.riderName != null) ...[
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: AppColors.tealLight,
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.teal,
                child: Icon(Icons.two_wheeler_rounded, color: Colors.white),
              ),
              title: Text(order.riderName!),
              subtitle: Text(context.t('yourRider')),
              trailing: order.riderPhone == null
                  ? null
                  : IconButton(
                      onPressed: () => callPhone(order.riderPhone!),
                      icon: const Icon(Icons.call_rounded, color: AppColors.teal),
                    ),
            ),
          ),
        ],
        const Divider(height: 32),
        if (order.storeName != null)
          Text(
            context.tr(order.storeName!),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        if (order.kind == OrderKind.courier) ...[
          Text(
            context.t('courierTitle'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          Text('${context.t('pickupFrom')}: ${order.pickupAddress ?? ''}'),
        ],
        const SizedBox(height: 4),
        Text(itemsSummary(context, order), style: const TextStyle(color: AppColors.textMuted)),
        Text(
          '${context.t('deliverTo')}: ${order.address}',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(context.t('total'), style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              '${context.price(order.total)} · ${context.t(order.payment.name)}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (order.status == OrderStatus.pending)
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.delivery),
            onPressed: () => _cancel(context),
            child: Text(context.t('cancelOrder')),
          ),
        TextButton.icon(
          onPressed: () => openWhatsApp(AppConfig.supportWhatsApp, 'MyOrders #${order.code}'),
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(context.t('support')),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final bool done;
  final bool current;
  final bool last;
  const _Step({required this.label, required this.done, required this.current, required this.last});

  @override
  Widget build(BuildContext context) {
    final color = done ? AppColors.teal : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
              if (!last) Expanded(child: Container(width: 3, color: color)),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: current ? FontWeight.w800 : FontWeight.w500,
                color: done ? AppColors.text : AppColors.textMuted,
              ),
            ),
          ),
          if (current)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 8, top: 4),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
