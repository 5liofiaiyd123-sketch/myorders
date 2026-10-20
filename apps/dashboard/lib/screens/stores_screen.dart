import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import 'menu_screen.dart';

class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  late Future<List<Store>> _stores = _load();

  Future<List<Store>> _load() => context.read<MyOrdersRepository>().stores(includeInactive: true);

  Future<void> _save(Store store) async {
    try {
      await context.read<MyOrdersRepository>().saveStore(store);
      setState(() {
        _stores = _load();
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _edit([Store? store]) async {
    final saved = await showDialog<Store>(
      context: context,
      builder: (_) => _StoreDialog(
        store:
            store ??
            const Store(
              id: '',
              name: Tr('', ''),
              section: Section.food,
              tags: Tr('', ''),
              category: 'all',
            ),
      ),
    );
    if (saved != null) await _save(saved);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(context.t('addStore')),
      ),
      body: FutureBuilder<List<Store>>(
        future: _stores,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(snap.error.toString()));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              for (final s in snap.data!)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    leading: Text(s.emoji, style: const TextStyle(fontSize: 28)),
                    title: Text(
                      context.tr(s.name),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${context.section(s.section)} · ⭐ ${s.rating} · ${context.price(s.deliveryFee)} · '
                      '${context.t(s.isOpen ? 'storeOpen' : 'storeClosed')}',
                    ),
                    onTap: () => _edit(s),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: Text(context.tr(s.name))),
                                body: MenuScreen(storeId: s.id),
                              ),
                            ),
                          ),
                          child: Text(context.t('menu')),
                        ),
                        Tooltip(
                          message: context.t(s.isActive ? 'active' : 'hidden'),
                          child: Switch(
                            value: s.isActive,
                            onChanged: (v) => _save(s.copyWith(isActive: v)),
                          ),
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

class _StoreDialog extends StatefulWidget {
  final Store store;
  const _StoreDialog({required this.store});

  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  final _form = GlobalKey<FormState>();
  late final _nameEn = TextEditingController(text: widget.store.name.en);
  late final _nameAr = TextEditingController(text: widget.store.name.ar);
  late final _tagsEn = TextEditingController(text: widget.store.tags.en);
  late final _tagsAr = TextEditingController(text: widget.store.tags.ar);
  late final _emoji = TextEditingController(text: widget.store.emoji);
  late final _phone = TextEditingController(text: widget.store.phone);
  late final _fee = TextEditingController(text: widget.store.deliveryFee.toStringAsFixed(0));
  late final _minOrder = TextEditingController(text: widget.store.minOrder.toStringAsFixed(0));
  late final _etaMin = TextEditingController(text: '${widget.store.etaMin}');
  late final _etaMax = TextEditingController(text: '${widget.store.etaMax}');
  late Section _section = widget.store.section;
  late String _category = widget.store.category;

  @override
  void dispose() {
    for (final c in [
      _nameEn,
      _nameAr,
      _tagsEn,
      _tagsAr,
      _emoji,
      _phone,
      _fee,
      _minOrder,
      _etaMin,
      _etaMax,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.store.copyWith(
        name: Tr(_nameEn.text.trim(), _nameAr.text.trim()),
        tags: Tr(_tagsEn.text.trim(), _tagsAr.text.trim()),
        section: _section,
        category: _category,
        emoji: _emoji.text.trim().isEmpty ? '🏪' : _emoji.text.trim(),
        phone: _phone.text.trim(),
        deliveryFee: double.tryParse(_fee.text) ?? 20,
        minOrder: double.tryParse(_minOrder.text) ?? 0,
        etaMin: int.tryParse(_etaMin.text) ?? 20,
        etaMax: int.tryParse(_etaMax.text) ?? 40,
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
      bool number = false,
    }) => TextFormField(
      controller: c,
      validator: validator,
      keyboardType: number ? TextInputType.number : null,
      decoration: InputDecoration(labelText: context.t(label), border: const OutlineInputBorder()),
    );
    Widget pair(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      ),
    );
    final categories = sectionFilters[_section]!;
    if (!categories.any((c) => c.id == _category)) _category = 'all';
    return AlertDialog(
      title: Text(context.t(widget.store.id.isEmpty ? 'addStore' : 'edit')),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _form,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                pair(
                  field(_nameEn, 'nameEn', validator: required),
                  field(_nameAr, 'nameAr', validator: required),
                ),
                pair(field(_tagsEn, 'tagsEn'), field(_tagsAr, 'tagsAr')),
                pair(
                  DropdownButtonFormField<Section>(
                    initialValue: _section,
                    decoration: InputDecoration(
                      labelText: context.t('section'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final s in Section.values)
                        DropdownMenuItem(value: s, child: Text(context.section(s))),
                    ],
                    onChanged: (v) => setState(() => _section = v!),
                  ),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_section),
                    initialValue: _category,
                    decoration: InputDecoration(
                      labelText: context.t('category'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in categories)
                        DropdownMenuItem(value: c.id, child: Text(context.tr(c.label))),
                    ],
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ),
                pair(field(_emoji, 'icon'), field(_phone, 'phone')),
                pair(
                  field(_fee, 'deliveryFee', number: true),
                  field(_minOrder, 'minOrder', number: true),
                ),
                pair(field(_etaMin, 'eta', number: true), field(_etaMax, 'eta', number: true)),
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
