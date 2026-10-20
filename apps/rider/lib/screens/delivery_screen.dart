import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

/// One delivery: route on the map, customer contact, and the next action.
/// While open it shares the rider's location with the customer.
class DeliveryScreen extends StatefulWidget {
  final String orderId;
  const DeliveryScreen({super.key, required this.orderId});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _shareLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 20), (_) => _shareLocation());
  }

  Future<void> _shareLocation() async {
    final repo = context.read<MyOrdersRepository>();
    final here = await currentLocation();
    if (here != null) {
      await repo
          .updateRiderLocation(widget.orderId, here.latitude, here.longitude)
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _advance(Order order, OrderStatus next) async {
    try {
      await context.read<MyOrdersRepository>().updateOrderStatus(order.id, next);
      if (next == OrderStatus.delivered && mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order?>(
      stream: context.read<MyOrdersRepository>().watchOrder(widget.orderId),
      builder: (context, snap) {
        final order = snap.data;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final customer = order.lat == null ? null : LatLng(order.lat!, order.lng!);
        final rider = order.riderLat == null ? null : LatLng(order.riderLat!, order.riderLng!);
        final next = nextStatus(order);
        final canAct = next == OrderStatus.pickedUp
            ? (order.kind == OrderKind.courier
                  ? order.status == OrderStatus.accepted
                  : order.status == OrderStatus.ready)
            : next == OrderStatus.delivered;
        return Scaffold(
          appBar: AppBar(title: Text('${context.t('order')} #${order.code}')),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: !order.isActive
                ? Center(child: StatusChip(order.status))
                : FilledButton(
                    onPressed: canAct ? () => _advance(order, next!) : null,
                    child: Text(
                      next == OrderStatus.delivered
                          ? '${context.t('delivered')} · ${context.t('collect')} ${context.price(order.total)}'
                          : canAct
                          ? context.t('pickedUp')
                          : context.status(order.status),
                    ),
                  ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 240,
                child: DahabMap(
                  center: rider ?? customer,
                  pins: [
                    if (customer != null) MapPin(customer, Icons.home_rounded, customerPinColor),
                    if (rider != null) MapPin(rider, Icons.two_wheeler_rounded, riderPinColor),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  StatusChip(order.status),
                  const Spacer(),
                  if (customer != null)
                    TextButton.icon(
                      onPressed: () => openDirections(customer.latitude, customer.longitude),
                      icon: const Icon(Icons.directions_rounded),
                      label: Text(context.t('navigate')),
                    ),
                ],
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: storePinColor,
                  child: Icon(Icons.storefront_rounded, color: Colors.white),
                ),
                title: Text(
                  order.storeName == null
                      ? (order.pickupAddress ?? '')
                      : context.tr(order.storeName!),
                ),
                subtitle: Text(context.t(order.kind == OrderKind.courier ? 'pickupFrom' : 'store')),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: customerPinColor,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                title: Text(order.customerName),
                subtitle: Text(order.address),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: context.t('call'),
                      onPressed: () => callPhone(order.customerPhone),
                      icon: const Icon(Icons.call_rounded, color: AppColors.teal),
                    ),
                    IconButton(
                      tooltip: context.t('whatsapp'),
                      onPressed: () => openWhatsApp(order.customerPhone),
                      icon: const Icon(Icons.chat_rounded, color: AppColors.supermarket),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Text(context.t('items'), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(itemsSummary(context, order)),
              if (order.notes.isNotEmpty && order.kind == OrderKind.store) ...[
                const SizedBox(height: 8),
                Text('📝 ${order.notes}'),
              ],
              const Divider(height: 24),
              Row(
                children: [
                  Text(context.t('collect'), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text(
                    '${context.price(order.total)} · ${context.t(order.payment.name)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
