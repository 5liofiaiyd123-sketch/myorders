import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../cart.dart';
import '../screens/cart_screen.dart';
import '../screens/store_screen.dart';

class SectionStyle {
  final IconData icon;
  final Color color;
  final Tr bannerTitle;
  final Tr bannerBody;
  final String bannerEmoji;

  const SectionStyle(this.icon, this.color, this.bannerTitle, this.bannerBody, this.bannerEmoji);

  static const of = <Section, SectionStyle>{
    Section.food: SectionStyle(
      Icons.restaurant_rounded,
      AppColors.food,
      Tr('Good Food\nGood Mood', 'أكل حلو\nمزاج حلو'),
      Tr('Fresh meals from the best restaurants in Dahab', 'أحسن مطاعم دهب لحد عندك'),
      '🍽️',
    ),
    Section.drinks: SectionStyle(
      Icons.local_cafe_rounded,
      AppColors.drinks,
      Tr('Cool Drinks\nHot Days', 'مشروبات ساقعة\nلأيام حر'),
      Tr('Fresh juices, coffee and more', 'عصاير فريش وقهوة وأكتر'),
      '🍹',
    ),
    Section.supermarket: SectionStyle(
      Icons.shopping_cart_rounded,
      AppColors.supermarket,
      Tr('Fresh Products\nEveryday', 'منتجات فريش\nكل يوم'),
      Tr('Groceries, essentials and more', 'بقالة وطلبات البيت'),
      '🧺',
    ),
    Section.pharmacy: SectionStyle(
      Icons.medical_services_rounded,
      AppColors.pharmacy,
      Tr('Health First', 'صحتك أولاً'),
      Tr('Your pharmacy in Dahab', 'صيدليتك في دهب'),
      '💊',
    ),
  };
}

/// Sea-colored gradient used where the design has a beach photo.
const seaGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0A6C7C), Color(0xFF14A3B8), Color(0xFF7FD3DE)],
);

class Rating extends StatelessWidget {
  final Store store;
  const Rating(this.store, {super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, color: AppColors.textMuted);
    final reviews = store.reviews >= 1000
        ? '${(store.reviews / 1000).toStringAsFixed(1)}k'
        : '${store.reviews}';
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 18, color: AppColors.star),
            const SizedBox(width: 2),
            Text('${store.rating} ($reviews)', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text('${store.etaMin}-${store.etaMax} ${context.t('min')}', style: style),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(context.price(store.deliveryFee), style: style),
          ],
        ),
      ],
    );
  }
}

class EmojiTile extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  const EmojiTile(this.emoji, {super.key, required this.color, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final String storeId;
  const FavoriteButton(this.storeId, {super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesModel>();
    final on = favorites.contains(storeId);
    return IconButton(
      tooltip: context.t('favorites'),
      onPressed: () => favorites.toggle(storeId).catchError((Object e) {
        if (context.mounted) showError(context, e);
      }),
      icon: Icon(
        on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: on ? AppColors.delivery : AppColors.textMuted,
      ),
    );
  }
}

class StoreTile extends StatelessWidget {
  final Store store;
  const StoreTile(this.store, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = SectionStyle.of[store.section]!;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => StoreScreen(store: store))),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 4, 12),
          child: Row(
            children: [
              Opacity(
                opacity: store.isOpen ? 1 : 0.5,
                child: EmojiTile(store.emoji, color: style.color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(store.name),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      store.isOpen ? context.tr(store.tags) : context.t('closed'),
                      style: TextStyle(
                        fontSize: 13,
                        color: store.isOpen ? AppColors.textMuted : AppColors.delivery,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Rating(store),
                  ],
                ),
              ),
              FavoriteButton(store.id),
            ],
          ),
        ),
      ),
    );
  }
}

class CartIconButton extends StatelessWidget {
  final Color? color;
  const CartIconButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartModel>().count;
    return IconButton(
      tooltip: context.t('cart'),
      onPressed: () =>
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: Icon(Icons.shopping_cart_outlined, color: color),
      ),
    );
  }
}

/// Bottom bar shown while the cart has items.
class CartBar extends StatelessWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    if (cart.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: FilledButton(
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CartScreen())),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${cart.count}'),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(context.t('viewCart'))),
            Text(context.price(cart.subtotal)),
          ],
        ),
      ),
    );
  }
}

class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool autofocus;

  const SearchBox({
    super.key,
    required this.hint,
    this.onChanged,
    this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      autofocus: autofocus,
      readOnly: onTap != null,
      onTap: onTap,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.zero,
        border: border,
        enabledBorder: border,
      ),
    );
  }
}

/// Loads a future once and shows a spinner, an error with retry, or the data.
class FutureView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, VoidCallback reload) builder;
  const FutureView({super.key, required this.load, required this.builder});

  @override
  State<FutureView<T>> createState() => _FutureViewState<T>();
}

class _FutureViewState<T> extends State<FutureView<T>> {
  late Future<T> _future = widget.load();

  void _reload() => setState(() {
    _future = widget.load();
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.wifi_off_rounded,
            text: snap.error.toString(),
            action: OutlinedButton(onPressed: _reload, child: Text(context.t('retry'))),
          );
        }
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return widget.builder(context, snap.data as T, _reload);
      },
    );
  }
}
