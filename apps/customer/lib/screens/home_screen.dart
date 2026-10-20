import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../widgets/common.dart';
import 'courier_screen.dart';
import 'search_screen.dart';
import 'section_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: _Hero()),
          const SliverToBoxAdapter(
            child: Padding(padding: EdgeInsets.only(top: 12), child: DemoBanner()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverGrid.count(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1,
              children: [
                for (final section in Section.values)
                  _SectionTile(
                    label: context.section(section),
                    icon: SectionStyle.of[section]!.icon,
                    color: SectionStyle.of[section]!.color,
                    onTap: () => open(SectionScreen(section: section)),
                  ),
                _SectionTile(
                  label: context.t('delivery'),
                  icon: Icons.two_wheeler_rounded,
                  color: AppColors.delivery,
                  onTap: () => open(const CourierScreen()),
                ),
                _SectionTile(
                  label: context.t('more'),
                  icon: Icons.grid_view_rounded,
                  color: AppColors.more,
                  onTap: () => open(const SearchScreen()),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: _Heading(context.t('explore'))),
          const SliverToBoxAdapter(child: _Highlights()),
          const SliverToBoxAdapter(child: _PromoCard()),
          SliverToBoxAdapter(child: _Heading(context.t('popular'))),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: FutureView<List<Store>>(
                load: () => repo.stores(),
                builder: (context, stores, _) {
                  final top = [...stores]..sort((a, b) => b.rating.compareTo(a.rating));
                  return Column(children: [for (final s in top.take(6)) StoreTile(s)]);
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    );
  }
}

/// Full-bleed photo of Dahab's bay with the logo, tagline and search.
class _Hero extends StatelessWidget {
  const _Hero();

  static const _searchHeight = 54.0;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + 320 + _searchHeight / 2,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: _searchHeight / 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.flip(
                    flipX: rtl,
                    child: Image.asset(
                      AppImages.hero,
                      package: AppImages.package,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.6),
                          Colors.white.withValues(alpha: 0),
                          AppColors.tealDark.withValues(alpha: 0.05),
                          AppColors.tealDark.withValues(alpha: 0.75),
                        ],
                        stops: const [0, 0.4, 0.55, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(padding: EdgeInsets.only(top: 16), child: BrandLogo(size: 32)),
                    ),
                  ),
                  _GlassButton(child: const LanguageButton(color: AppColors.tealDark)),
                  const SizedBox(width: 8),
                  const _GlassButton(child: CartIconButton(color: AppColors.tealDark)),
                ],
              ),
            ),
          ),
          Positioned(
            top: top + 72,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.tealDark, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    context.t('location'),
                    style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w700),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: AppColors.tealDark,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: _searchHeight / 2 + 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('appTagline'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Color(0x66000000), blurRadius: 12)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('appSubtitle'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            height: _searchHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: softShadow,
              ),
              child: SearchBox(
                hint: context.t('search'),
                onTap: () =>
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const SearchScreen())),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted white pill so icons stay readable over the sky.
class _GlassButton extends StatelessWidget {
  final Widget child;
  const _GlassButton({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _SectionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SectionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final light = Color.lerp(color, Colors.white, 0.25)!;
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: softShadow),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [light, color],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Swipeable photo cards, one per section.
class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) {
    final sections = Section.values;
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final section = sections[i];
          final style = SectionStyle.of[section]!;
          return SizedBox(
            width: 300,
            child: GestureDetector(
              onTap: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => SectionScreen(section: section))),
              child: PhotoBanner(
                image: AppImages.banner(section),
                title: context.tr(style.bannerTitle),
                body: context.tr(style.bannerBody),
                height: 164,
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.promo,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.t('orderNow'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFD45C), AppColors.promo]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.promo.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.delivery_dining_rounded, color: AppColors.delivery, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('promoTitle'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                Text(context.t('promoBody'), style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
