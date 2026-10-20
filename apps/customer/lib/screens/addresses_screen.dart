import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../widgets/address_picker.dart';
import '../widgets/common.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  int _version = 0;

  Future<void> _add() async {
    final saved = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const _NewAddressScreen()));
    if (saved == true) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<MyOrdersRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(context.t('savedAddresses'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(context.t('addAddress')),
      ),
      body: FutureView<List<Address>>(
        key: ValueKey(_version),
        load: repo.addresses,
        builder: (context, addresses, reload) => addresses.isEmpty
            ? EmptyState(icon: Icons.location_off_rounded, text: context.t('noAddresses'))
            : ListView(
                children: [
                  for (final a in addresses)
                    ListTile(
                      leading: const Icon(Icons.location_on_rounded, color: AppColors.teal),
                      title: Text(a.label.isEmpty ? a.details : a.label),
                      subtitle: Text(a.details),
                      trailing: IconButton(
                        tooltip: context.t('delete'),
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          await repo.deleteAddress(a.id);
                          reload();
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _NewAddressScreen extends StatefulWidget {
  const _NewAddressScreen();

  @override
  State<_NewAddressScreen> createState() => _NewAddressScreenState();
}

class _NewAddressScreenState extends State<_NewAddressScreen> {
  final _label = TextEditingController();
  final _selection = AddressSelection();

  Future<void> _save() async {
    if (_selection.details.trim().isEmpty) return showError(context, context.t('addressHint'));
    try {
      await context.read<MyOrdersRepository>().saveAddress(
        Address(
          id: '',
          label: _label.text.trim(),
          details: _selection.details.trim(),
          lat: _selection.point?.latitude,
          lng: _selection.point?.longitude,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('addAddress'))),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(onPressed: _save, child: Text(context.t('save'))),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: context.t('addressLabel')),
          ),
          const SizedBox(height: 12),
          AddressPicker(selection: _selection, showSaved: false),
        ],
      ),
    );
  }
}
