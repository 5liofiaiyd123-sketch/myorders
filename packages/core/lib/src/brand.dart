import 'package:flutter/material.dart';

import 'data/models.dart';
import 'theme.dart';

/// Photos bundled with the apps, taken from the approved design.
class AppImages {
  static const _dir = 'assets/images';
  static const package = 'myorders_core';

  static const hero = '$_dir/hero.jpg';
  static const partner = '$_dir/partner.jpg';

  static String banner(Section section) => '$_dir/${section.name}.jpg';

  static const _storePhotos = {
    'blue-hole',
    'bedouin-kitchen',
    'el-primo',
    'lighthouse-burger',
    'coco-cafe',
    'ocean-juice',
    'fresh-corner',
    'dahab-mart',
    'fresh-market',
    'dahab-pharmacy',
    'al-salam-pharmacy',
  };

  /// The bundled photo for a demo store, or null.
  static String? store(String id) => _storePhotos.contains(id) ? '$_dir/store-$id.jpg' : null;
}

/// Soft, wide shadow used on cards instead of borders.
const softShadow = [
  BoxShadow(color: Color(0x140A4A55), blurRadius: 24, offset: Offset(0, 8)),
  BoxShadow(color: Color(0x0A0A4A55), blurRadius: 4, offset: Offset(0, 1)),
];

/// The MyOrders word mark: a wave over "My" + "Orders".
class BrandLogo extends StatelessWidget {
  final double size;
  final bool onDark;
  const BrandLogo({super.key, this.size = 30, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final my = onDark ? Colors.white : AppColors.tealDark;
    final orders = onDark ? const Color(0xFFBFF1F7) : AppColors.teal;
    final style = TextStyle(
      fontFamily: appFont,
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('My', style: style.copyWith(color: my)),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text('Orders', style: style.copyWith(color: orders)),
              Positioned(
                top: -size * 0.5,
                left: size * 0.05,
                child: Icon(Icons.waves_rounded, size: size * 0.62, color: orders),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A photo with a gradient on the reading side and a title over it.
class PhotoBanner extends StatelessWidget {
  final String image;
  final String title;
  final String? body;
  final double height;
  final double radius;
  final Widget? trailing;

  const PhotoBanner({
    super.key,
    required this.image,
    required this.title,
    this.body,
    this.height = 140,
    this.radius = 20,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(radius), boxShadow: softShadow),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The photos put their subject on the right, so mirror them in Arabic
          // to keep the text over the open water.
          Transform.flip(
            flipX: rtl,
            child: Image.asset(image, package: AppImages.package, fit: BoxFit.cover),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
                colors: [
                  AppColors.tealDark.withValues(alpha: 0.88),
                  AppColors.tealDark.withValues(alpha: 0.55),
                  AppColors.tealDark.withValues(alpha: 0),
                ],
                stops: const [0, 0.42, 0.7],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(color: Color(0x55000000), blurRadius: 8)],
                          ),
                        ),
                      ),
                      if (body != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          body!,
                          maxLines: trailing == null ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xF2FFFFFF),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                      if (trailing != null) ...[const SizedBox(height: 10), trailing!],
                    ],
                  ),
                ),
                const Spacer(flex: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The store's photo, or its emoji on a tinted tile when it has none.
class StorePhoto extends StatelessWidget {
  final Store store;
  final double width;
  final double height;
  final double radius;
  final Color tint;

  const StorePhoto(
    this.store, {
    super.key,
    this.width = 84,
    this.height = 76,
    this.radius = 14,
    this.tint = AppColors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final asset = AppImages.store(store.id);
    final fallback = Container(
      alignment: Alignment.center,
      color: tint.withValues(alpha: 0.12),
      child: Icon(itemIcon(store.emoji), color: tint, size: height * 0.45),
    );
    final Widget image;
    if (store.imageUrl.isNotEmpty) {
      image = Image.network(store.imageUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback);
    } else if (asset != null) {
      image = Image.asset(asset, package: AppImages.package, fit: BoxFit.cover);
    } else {
      image = fallback;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(width: width, height: height, child: image),
    );
  }
}

const _itemIcons = <String, IconData>{
  '🍕': Icons.local_pizza_rounded,
  '🍔': Icons.lunch_dining_rounded,
  '🍟': Icons.fastfood_rounded,
  '🍖': Icons.kebab_dining_rounded,
  '🫓': Icons.bakery_dining_rounded,
  '🍛': Icons.rice_bowl_rounded,
  '🍝': Icons.ramen_dining_rounded,
  '🍲': Icons.soup_kitchen_rounded,
  '🐟': Icons.set_meal_rounded,
  '🦐': Icons.set_meal_rounded,
  '🦑': Icons.set_meal_rounded,
  '☕': Icons.coffee_rounded,
  '🧋': Icons.local_cafe_rounded,
  '🍵': Icons.emoji_food_beverage_rounded,
  '🍹': Icons.local_bar_rounded,
  '🥤': Icons.local_drink_rounded,
  '🥭': Icons.local_drink_rounded,
  '🍋': Icons.local_drink_rounded,
  '🍓': Icons.local_drink_rounded,
  '🫐': Icons.blender_rounded,
  '🥛': Icons.local_drink_rounded,
  '💧': Icons.water_drop_rounded,
  '🥚': Icons.egg_rounded,
  '🥬': Icons.eco_rounded,
  '🥑': Icons.eco_rounded,
  '🍅': Icons.eco_rounded,
  '🍌': Icons.eco_rounded,
  '🌿': Icons.spa_rounded,
  '🛒': Icons.shopping_cart_rounded,
  '💊': Icons.medication_rounded,
  '🧴': Icons.sanitizer_rounded,
  '🩹': Icons.healing_rounded,
  '🏥': Icons.local_hospital_rounded,
  '👶': Icons.child_friendly_rounded,
};

/// Icon for a store or product, picked from its emoji. Emoji fonts are not
/// always available on the web, so the apps draw icons instead.
IconData itemIcon(String emoji) => _itemIcons[emoji] ?? Icons.restaurant_menu_rounded;

/// Rounded tile with the item's icon on a soft tint of [color].
class ItemIcon extends StatelessWidget {
  final String emoji;
  final Color color;
  final double size;
  const ItemIcon(this.emoji, {super.key, required this.color, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.10), color.withValues(alpha: 0.22)],
        ),
      ),
      child: Icon(itemIcon(emoji), color: color, size: size * 0.5),
    );
  }
}
