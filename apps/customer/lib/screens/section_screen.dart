import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../widgets/common.dart';

class SectionScreen extends StatefulWidget {
  final Section section;
  const SectionScreen({super.key, required this.section});

  @override
  State<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends State<SectionScreen> {
  String _filter = 'all';
  String _query = '';

  bool _matches(BuildContext context, Store s) {
    if (_filter != 'all' && s.category != _filter) return false;
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return '${s.name.en} ${s.name.ar} ${s.tags.en} ${s.tags.ar}'.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final style = SectionStyle.of[widget.section]!;
    final filters = sectionFilters[widget.section]!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.section(widget.section)),
            Row(
              children: [
                const Icon(Icons.location_on_rounded, size: 14, color: AppColors.promo),
                const SizedBox(width: 2),
                Text(
                  context.t('dahab'),
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: const [CartIconButton()],
      ),
      bottomNavigationBar: const CartBar(),
      body: FutureView<List<Store>>(
        load: () => context.read<MyOrdersRepository>().stores(section: widget.section),
        builder: (context, stores, reload) {
          final shown = stores.where((s) => _matches(context, s)).toList();
          return RefreshIndicator(
            onRefresh: () async => reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SearchBox(
                  hint: context.t('search'),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
                const SizedBox(height: 16),
                _Banner(style: style),
                const SizedBox(height: 16),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) => _FilterChip(
                      filter: filters[i],
                      selected: filters[i].id == _filter,
                      onTap: () => setState(() => _filter = filters[i].id),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (shown.isEmpty)
                  EmptyState(icon: Icons.storefront_rounded, text: context.t('noResults'))
                else
                  for (final s in shown) StoreTile(s),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final SectionStyle style;
  const _Banner({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(gradient: seaGradient, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr(style.bannerTitle),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr(style.bannerBody),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(style.bannerEmoji, style: const TextStyle(fontSize: 64)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final SectionFilter filter;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.filter, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? AppColors.teal : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? AppColors.teal : AppColors.border),
              ),
              child: Icon(filter.icon, color: selected ? Colors.white : AppColors.teal),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr(filter.label),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.teal : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
