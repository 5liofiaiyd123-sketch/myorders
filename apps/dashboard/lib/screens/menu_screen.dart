import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

/// A store's products: add, edit, hide or delete.
class MenuScreen extends StatefulWidget {
  final String storeId;
  const MenuScreen({super.key, required this.storeId});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late Future<List<Product>> _products = _load();

  Future<List<Product>> _load() =>
      context.read<MyOrdersRepository>().products(widget.storeId, includeUnavailable: true);

  void _reload() => setState(() {
    _products = _load();
  });

  Future<void> _edit([Product? product]) async {
    final saved = await showDialog<Product>(
      context: context,
      builder: (_) => ProductDialog(
        product:
            product ??
            Product(
              id: '',
              storeId: widget.storeId,
              name: const Tr('', ''),
              description: const Tr('', ''),
              price: 0,
              emoji: '🍽️',
            ),
      ),
    );
    if (saved == null || !mounted) return;
    await _run(() => context.read<MyOrdersRepository>().saveProduct(saved));
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('addProduct')),
      ),
      body: FutureBuilder<List<Product>>(
        future: _products,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final products = snap.data!;
          if (products.isEmpty) {
            return EmptyState(icon: Icons.restaurant_menu_rounded, text: context.t('addProduct'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              for (final p in products)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: Text(p.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      context.tr(p.name),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.available ? AppColors.text : AppColors.textMuted,
                      ),
                    ),
                    subtitle: Text(
                      '${context.price(p.price)} · ${context.tr(p.description)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _edit(p),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: context.t('inStock'),
                          child: Switch(
                            value: p.available,
                            onChanged: (v) =>
                                _run(() => repo.saveProduct(p.copyWith(available: v))),
                          ),
                        ),
                        IconButton(
                          tooltip: context.t('delete'),
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _run(() => repo.deleteProduct(p.id)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class ProductDialog extends StatefulWidget {
  final Product product;
  const ProductDialog({super.key, required this.product});

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _form = GlobalKey<FormState>();
  late final _nameEn = TextEditingController(text: widget.product.name.en);
  late final _nameAr = TextEditingController(text: widget.product.name.ar);
  late final _descEn = TextEditingController(text: widget.product.description.en);
  late final _descAr = TextEditingController(text: widget.product.description.ar);
  late final _price = TextEditingController(
    text: widget.product.price == 0 ? '' : widget.product.price.toStringAsFixed(0),
  );
  late final _emoji = TextEditingController(text: widget.product.emoji);

  @override
  void dispose() {
    for (final c in [_nameEn, _nameAr, _descEn, _descAr, _price, _emoji]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.product.copyWith(
        name: Tr(_nameEn.text.trim(), _nameAr.text.trim()),
        description: Tr(_descEn.text.trim(), _descAr.text.trim()),
        price: double.parse(_price.text.trim()),
        emoji: _emoji.text.trim().isEmpty ? '🍽️' : _emoji.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String? required(String? v) => (v ?? '').trim().isEmpty ? context.t('required') : null;
    Widget field(
      TextEditingController c,
      String label, {
      String? Function(String?)? validator,
      TextInputType? keyboard,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        validator: validator,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: context.t(label),
          border: const OutlineInputBorder(),
        ),
      ),
    );
    return AlertDialog(
      title: Text(context.t(widget.product.id.isEmpty ? 'addProduct' : 'edit')),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(_nameEn, 'nameEn', validator: required),
                field(_nameAr, 'nameAr', validator: required),
                field(_descEn, 'descEn'),
                field(_descAr, 'descAr'),
                field(
                  _price,
                  'price',
                  keyboard: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) =>
                      double.tryParse((v ?? '').trim()) == null ? context.t('required') : null,
                ),
                field(_emoji, 'icon'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.t('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
          onPressed: _save,
          child: Text(context.t('save')),
        ),
      ],
    );
  }
}
