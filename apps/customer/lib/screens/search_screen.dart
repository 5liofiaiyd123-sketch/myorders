import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../widgets/common.dart';
import 'store_screen.dart';

/// Searches every store and its products at once.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  late final Future<List<(Store, List<Product>)>> _catalog = _load();

  Future<List<(Store, List<Product>)>> _load() async {
    final repo = context.read<MyOrdersRepository>();
    final stores = await repo.stores();
    return Future.wait(stores.map((s) async => (s, await repo.products(s.id))));
  }

  static bool _hit(Tr text, String q) => '${text.en} ${text.ar}'.toLowerCase().contains(q);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SearchBox(
          hint: context.t('searchProducts'),
          autofocus: true,
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
        actions: const [CartIconButton()],
      ),
      body: FutureBuilder(
        future: _catalog,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final q = _query;
          final results = [
            for (final (store, products) in snap.data!)
              if (q.isEmpty ||
                  _hit(store.name, q) ||
                  _hit(store.tags, q) ||
                  products.any((p) => _hit(p.name, q)))
                (store, q.isEmpty ? <Product>[] : products.where((p) => _hit(p.name, q)).toList()),
          ];
          if (results.isEmpty) {
            return EmptyState(icon: Icons.search_off_rounded, text: context.t('noResults'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final (store, products) in results) ...[
                StoreTile(store),
                for (final p in products.take(3))
                  ListTile(
                    dense: true,
                    leading: ItemIcon(p.emoji, color: AppColors.teal, size: 40),
                    title: Text(context.tr(p.name)),
                    trailing: Text(context.price(p.price)),
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => StoreScreen(store: store))),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
