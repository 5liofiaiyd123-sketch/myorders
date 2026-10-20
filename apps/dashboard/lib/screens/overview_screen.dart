import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late Future<DashboardStats> _stats = context.read<MyOrdersRepository>().stats();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _stats = repo.stats();
        });
        await _stats;
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          FutureBuilder<DashboardStats>(
            future: _stats,
            builder: (context, snap) {
              if (snap.hasError) return Text(snap.error.toString());
              if (!snap.hasData) return const LinearProgressIndicator();
              final s = snap.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(
                        context.t('ordersToday'),
                        '${s.ordersToday}',
                        Icons.receipt_rounded,
                      ),
                      _StatCard(
                        context.t('revenueToday'),
                        context.price(s.revenueToday),
                        Icons.payments_rounded,
                      ),
                      _StatCard(
                        context.t('commissionToday'),
                        context.price(s.commissionToday),
                        Icons.savings_rounded,
                      ),
                      _StatCard(
                        context.t('totalOrders'),
                        '${s.totalOrders}',
                        Icons.all_inbox_rounded,
                      ),
                      _StatCard(
                        context.t('activeStores'),
                        '${s.activeStores} / ${s.partners}',
                        Icons.storefront_rounded,
                      ),
                      _StatCard(
                        context.t('onlineRiders'),
                        '${s.onlineRiders}',
                        Icons.two_wheeler_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RevenueChart(values: s.revenueLast7Days),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            context.t('recentOrders'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Order>>(
            stream: repo.watchAllOrders(),
            builder: (context, snap) {
              final orders = (snap.data ?? const <Order>[]).take(8).toList();
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    for (final o in orders)
                      ListTile(
                        title: Text(
                          '#${o.code} · ${o.storeName == null ? context.t('delivery') : context.tr(o.storeName!)}',
                        ),
                        subtitle: Text('${o.customerName} · ${timeAgo(context, o.createdAt)}'),
                        trailing: Wrap(
                          spacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [Text(context.price(o.total)), StatusChip(o.status)],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatCard(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.tealLight,
            child: Icon(icon, color: AppColors.teal),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple bar chart of daily sales, oldest day first.
class _RevenueChart extends StatelessWidget {
  final List<double> values;
  const _RevenueChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(1, (m, v) => v > m ? v : m);
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t('revenue7d'), style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            values[i].toStringAsFixed(0),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 130 * values[i] / maxValue,
                            decoration: BoxDecoration(
                              color: i == values.length - 1 ? AppColors.teal : AppColors.tealLight,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(() {
                            final d = today.subtract(Duration(days: values.length - 1 - i));
                            return '${d.day}/${d.month}';
                          }(), style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
