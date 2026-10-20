import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

class RidersScreen extends StatelessWidget {
  const RidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Rider>>(
      future: context.read<MyOrdersRepository>().riders(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(snap.error.toString()));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final r in snap.data!)
              Card(
                elevation: 3,
                shadowColor: const Color(0x260A4A55),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.isOnline ? AppColors.supermarket : AppColors.more,
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white),
                  ),
                  title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${context.t(r.isOnline ? 'online' : 'offline')} · ${context.t('myDeliveries')}: ${r.activeDeliveries}',
                  ),
                  trailing: IconButton(
                    tooltip: context.t('call'),
                    onPressed: () => callPhone(r.phone),
                    icon: const Icon(Icons.call_rounded, color: AppColors.teal),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
