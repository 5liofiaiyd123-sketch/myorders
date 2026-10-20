import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import 'delivery_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  bool _online = true;

  Future<void> _setOnline(bool value) async {
    setState(() => _online = value);
    try {
      await context.read<MyOrdersRepository>().setRiderOnline(value);
    } catch (e) {
      if (mounted) {
        setState(() => _online = !value);
        showError(context, e);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<MyOrdersRepository>().setRiderOnline(true).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    final user = context.watch<AppUser?>()!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(user.name),
          actions: [
            Text(
              context.t(_online ? 'online' : 'offline'),
              style: TextStyle(
                color: _online ? AppColors.supermarket : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            Switch(value: _online, onChanged: _setOnline),
            PopupMenuButton<String>(
              onSelected: (v) =>
                  v == 'lang' ? context.read<LocaleModel>().toggle() : repo.signOut(),
              itemBuilder: (context) => [
                PopupMenuItem(value: 'lang', child: Text(context.t('switchLanguage'))),
                PopupMenuItem(value: 'out', child: Text(context.t('signOut'))),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.t('available')),
              Tab(text: context.t('myDeliveries')),
            ],
          ),
        ),
        body: Column(
          children: [
            const DemoBanner(),
            Expanded(
              child: TabBarView(
                children: [
                  _online
                      ? _OrderList(
                          stream: repo.watchAvailableDeliveries(),
                          emptyText: context.t('noAvailable'),
                          available: true,
                        )
                      : EmptyState(
                          icon: Icons.power_settings_new_rounded,
                          text: context.t('goOnline'),
                        ),
                  StreamBuilder<List<Order>>(
                    stream: repo.watchMyDeliveries(),
                    builder: (context, snap) {
                      final all = snap.data ?? const <Order>[];
                      return Column(
                        children: [
                          _EarningsCard(orders: all),
                          Expanded(
                            child: _OrderListView(
                              orders: all.where((o) => o.isActive).toList(),
                              emptyText: context.t('noDeliveries'),
                              available: false,
                              loading: !snap.hasData,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final List<Order> orders;
  const _EarningsCard({required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = orders.where(
      (o) =>
          o.status == OrderStatus.delivered &&
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day,
    );
    final fees = today.fold<double>(0, (sum, o) => sum + o.deliveryFee);
    Widget stat(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          Text(label, style: const TextStyle(color: Color(0xDDFFFFFF))),
        ],
      ),
    );
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: const AssetImage(AppImages.hero, package: AppImages.package),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.tealDark.withValues(alpha: 0.72),
            BlendMode.srcOver,
          ),
        ),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          Text(
            context.t('earningsToday'),
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              stat(context.t('trips'), '${today.length}'),
              stat(context.t('fees'), context.price(fees)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final Stream<List<Order>> stream;
  final String emptyText;
  final bool available;
  const _OrderList({required this.stream, required this.emptyText, required this.available});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: stream,
      builder: (context, snap) => _OrderListView(
        orders: snap.data ?? const [],
        emptyText: emptyText,
        available: available,
        loading: !snap.hasData,
      ),
    );
  }
}

class _OrderListView extends StatelessWidget {
  final List<Order> orders;
  final String emptyText;
  final bool available;
  final bool loading;
  const _OrderListView({
    required this.orders,
    required this.emptyText,
    required this.available,
    required this.loading,
  });

  Future<void> _take(BuildContext context, Order order) async {
    try {
      await context.read<MyOrdersRepository>().takeDelivery(order.id);
      if (context.mounted) {
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: order.id)));
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (orders.isEmpty) return EmptyState(icon: Icons.two_wheeler_rounded, text: emptyText);
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, i) {
        final o = orders[i];
        final from = o.storeName == null ? (o.pickupAddress ?? '') : context.tr(o.storeName!);
        return Card(
          elevation: 3,
          shadowColor: const Color(0x260A4A55),
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: available
                ? null
                : () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => DeliveryScreen(orderId: o.id))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#${o.code}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      StatusChip(o.status),
                      const Spacer(),
                      Text(
                        context.price(o.deliveryFee),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.supermarket,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _Leg(icon: Icons.storefront_rounded, color: storePinColor, text: from),
                  _Leg(icon: Icons.home_rounded, color: customerPinColor, text: o.address),
                  const SizedBox(height: 4),
                  Text(
                    '${context.t('collect')}: ${context.price(o.total)}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  if (available) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => _take(context, o),
                      child: Text(context.t('take')),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Leg extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Leg({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
