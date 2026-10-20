import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

/// Stores that asked to join from the customer app.
class ApplicationsScreen extends StatelessWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PartnerApplication>>(
      future: context.read<MyOrdersRepository>().partnerApplications(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(snap.error.toString()));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final apps = snap.data!;
        if (apps.isEmpty) {
          return EmptyState(icon: Icons.how_to_reg_rounded, text: context.t('noApplications'));
        }
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final a in apps)
              Card(
                elevation: 3,
                shadowColor: const Color(0x260A4A55),
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  title: Text(a.businessName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${context.section(a.section)} · ${a.contactName} · ${timeAgo(context, a.createdAt)}'
                    '${a.notes.isEmpty ? '' : '\n${a.notes}'}',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: context.t('call'),
                        onPressed: () => callPhone(a.phone),
                        icon: const Icon(Icons.call_rounded, color: AppColors.teal),
                      ),
                      IconButton(
                        tooltip: context.t('whatsapp'),
                        onPressed: () => openWhatsApp(a.phone),
                        icon: const Icon(Icons.chat_rounded, color: AppColors.supermarket),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
