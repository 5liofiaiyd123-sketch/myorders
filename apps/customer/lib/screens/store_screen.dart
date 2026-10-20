import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../cart.dart';
import '../widgets/common.dart';

class StoreScreen extends StatelessWidget {
  final Store store;
  const StoreScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final style = SectionStyle.of[store.section]!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      bottomNavigationBar: const CartBar(),
      body: FutureView<List<Product>>(
        load: () => context.read<MyOrdersRepository>().products(store.id),
        builder: (context, products, _) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 210,
              backgroundColor: AppColors.tealDark,
              foregroundColor: Colors.white,
              title: Text(context.tr(store.name), style: const TextStyle(color: Colors.white)),
              actions: [
                FavoriteButton(store.id),
                const CartIconButton(color: Colors.white),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Transform.flip(
                      flipX: rtl,
                      child: Image.asset(
                        AppImages.banner(store.section),
                        package: AppImages.package,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerRight,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.tealDark.withValues(alpha: 0.7),
                            AppColors.tealDark.withValues(alpha: 0.1),
                            AppColors.tealDark.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: softShadow,
                ),
                child: Row(
                  children: [
                    StorePhoto(store, width: 92, height: 92, radius: 16, tint: style.color),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr(store.name),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            context.tr(store.tags),
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Rating(store),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList.list(
                children: [
                  if (!store.isOpen)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.delivery.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        context.t('closed'),
                        style: const TextStyle(
                          color: AppColors.delivery,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (store.minOrder > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${context.t('minOrder')}: ${context.price(store.minOrder)}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 10),
                    child: Text(
                      context.t('menu'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  for (final p in products) _ProductRow(store: store, product: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Store store;
  final Product product;
  const _ProductRow({required this.store, required this.product});

  Future<void> _add(BuildContext context) async {
    final cart = context.read<CartModel>();
    if (cart.conflictsWith(store)) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.t('replaceCartTitle')),
          content: Text(context.t('replaceCartBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.t('cancel')),
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.t('newCart')),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    cart.add(store, product);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    final qty = cart.store?.id == store.id ? cart.quantityOf(product) : 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow,
      ),
      child: Row(
        children: [
          ItemIcon(product.emoji, color: SectionStyle.of[store.section]!.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr(product.name),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                Text(
                  context.tr(product.description),
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  context.price(product.price),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.tealDark),
                ),
              ],
            ),
          ),
          if (!store.isOpen)
            const SizedBox.shrink()
          else if (qty == 0)
            IconButton.filled(
              tooltip: context.t('add'),
              onPressed: () => _add(context),
              icon: const Icon(Icons.add_rounded),
            )
          else
            QuantityStepper(
              quantity: qty,
              onAdd: () => _add(context),
              onRemove: () => cart.remove(product),
            ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  const QuantityStepper({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: Icon(
              quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
              color: AppColors.tealDark,
            ),
          ),
          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, color: AppColors.tealDark),
          ),
        ],
      ),
    );
  }
}
