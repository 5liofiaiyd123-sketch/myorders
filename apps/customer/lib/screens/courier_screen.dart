import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../widgets/address_picker.dart';
import 'sign_in_screen.dart';
import 'tracking_screen.dart';

/// "Send anything": a rider picks something up and drops it off.
class CourierScreen extends StatefulWidget {
  const CourierScreen({super.key});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final _pickup = TextEditingController();
  final _what = TextEditingController();
  final _dropOff = AddressSelection();
  bool _sending = false;

  Future<void> _request() async {
    final repo = context.read<MyOrdersRepository>();
    if (_pickup.text.trim().isEmpty ||
        _what.text.trim().isEmpty ||
        _dropOff.details.trim().isEmpty) {
      return showError(context, context.t('required'));
    }
    var user = repo.currentUser;
    if (user == null) {
      user = await Navigator.of(context)
          .push<AppUser>(MaterialPageRoute(builder: (_) => const SignInScreen()));
      if (user == null || !mounted) return;
    }
    setState(() => _sending = true);
    try {
      final order = await repo.placeOrder(
        OrderDraft(
          kind: OrderKind.courier,
          customerName: user.name,
          customerPhone: user.phone ?? '',
          pickupAddress: _pickup.text.trim(),
          address: _dropOff.details.trim(),
          lat: _dropOff.point?.latitude,
          lng: _dropOff.point?.longitude,
          notes: _what.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order.id)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _pickup.dispose();
    _what.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('delivery'))),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _sending ? null : _request,
          child: Text('${context.t('requestRider')} · ${context.price(courierFee)}'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.t('courierTitle'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(context.t('courierBody'), style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _what,
            decoration: InputDecoration(
              labelText: context.t('whatToSend'),
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pickup,
            decoration: InputDecoration(
              labelText: context.t('pickupFrom'),
              hintText: context.t('addressHint'),
              prefixIcon: const Icon(Icons.storefront_outlined),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          AddressPicker(selection: _dropOff, label: context.t('dropOffAt')),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(context.t('courierFee')),
              const Spacer(),
              Text(context.price(courierFee), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          Text(context.t('cash'), style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
