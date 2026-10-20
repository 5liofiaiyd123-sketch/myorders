import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../cart.dart';
import '../widgets/common.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ids = context.watch<FavoritesModel>().ids;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('favorites'))),
      body: FutureView<List<Store>>(
        key: ValueKey(ids.length),
        load: () => context.read<MyOrdersRepository>().stores(),
        builder: (context, stores, _) {
          final favorites = stores.where((s) => ids.contains(s.id)).toList();
          if (favorites.isEmpty) {
            return EmptyState(icon: Icons.favorite_border_rounded, text: context.t('noFavorites'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [for (final s in favorites) StoreTile(s)],
          );
        },
      ),
    );
  }
}
