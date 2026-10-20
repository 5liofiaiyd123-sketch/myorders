import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/models.dart';
import 'data/repository.dart';
import 'l10n.dart';
import 'state.dart';
import 'theme.dart';

class StatusChip extends StatelessWidget {
  final OrderStatus status;
  const StatusChip(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        context.status(status),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.tealLight,
              child: Icon(icon, size: 40, color: AppColors.teal),
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class LanguageButton extends StatelessWidget {
  final Color? color;
  const LanguageButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(foregroundColor: color),
      onPressed: () => context.read<LocaleModel>().toggle(),
      icon: const Icon(Icons.translate_rounded, size: 18),
      label: Text(context.t('switchLanguage')),
    );
  }
}

/// Small banner shown while the app runs on demo data.
class DemoBanner extends StatelessWidget {
  final String hintKey;
  const DemoBanner({super.key, this.hintKey = 'demoMode'});

  @override
  Widget build(BuildContext context) {
    if (!context.read<MyOrdersRepository>().isDemo) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: AppColors.promo.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        context.t(hintKey),
        style: const TextStyle(fontSize: 12, color: AppColors.text),
        textAlign: TextAlign.center,
      ),
    );
  }
}

void showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(error.toString()), backgroundColor: AppColors.delivery));
}

void showDone(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

String timeAgo(BuildContext context, DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return context.t('justNow');
  if (d.inMinutes < 60) return '${d.inMinutes} ${context.t('min')}';
  if (d.inHours < 24) return '${d.inHours} ${context.t('hours')}';
  return '${at.day}/${at.month}';
}

/// One line per item, e.g. "2× Grilled Fish Plate".
String itemsSummary(BuildContext context, Order order) => order.kind == OrderKind.courier
    ? order.notes
    : order.items.map((i) => '${i.quantity}× ${context.tr(i.name)}').join(context.listSeparator);
