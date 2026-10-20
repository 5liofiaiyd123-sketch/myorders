import 'package:flutter/material.dart';
import 'package:myorders_core/myorders_core.dart';
import 'package:provider/provider.dart';

import '../cart.dart';
import '../widgets/address_picker.dart';
import 'sign_in_screen.dart';
import 'store_screen.dart';
import 'tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _notes = TextEditingController();
  final _address = AddressSelection();
  bool _placing = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final repo = context.read<MyOrdersRepository>();
    final cart = context.read<CartModel>();
    var user = repo.currentUser;
    if (user == null) {
      user = await Navigator.of(context)
          .push<AppUser>(MaterialPageRoute(builder: (_) => const SignInScreen()));
      if (user == null || !mounted) return;
    }
    if (_address.details.trim().isEmpty) {
      showError(context, context.t('addressHint'));
      return;
    }
    setState(() => _placing = true);
    try {
      final order = await repo.placeOrder(
        OrderDraft(
          kind: OrderKind.store,
          storeId: cart.store!.id,
          quantities: {for (final l in cart.lines) l.product.id: l.quantity},
          customerName: user.name,
          customerPhone: user.phone ?? '',
          address: _address.details.trim(),
          lat: _address.point?.latitude,
          lng: _address.point?.longitude,
          notes: _notes.text.trim(),
        ),
      );
      cart.clear();
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order.id)));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartModel>();
    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(context.t('cart'))),
        body: EmptyState(
          icon: Icons.shopping_cart_outlined,
          text: context.t('emptyCart'),
          action: FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: Text(context.t('browse')),
          ),
        ),
      );
    }
    final store = cart.store!;
    final belowMin = cart.subtotal < store.minOrder;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('cart'))),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: FilledButton(
          onPressed: _placing || belowMin ? null : _placeOrder,
          child: _placing
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Text(
                  belowMin
                      ? '${context.t('minOrder')}: ${context.price(store.minOrder)}'
                      : '${context.t('placeOrder')} · ${context.price(cart.total)}',
                ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.tr(store.name),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final line in cart.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  ItemIcon(line.product.emoji, color: AppColors.teal, size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(line.product.name),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          context.price(line.total),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  QuantityStepper(
                    quantity: line.quantity,
                    onAdd: () => cart.add(store, line.product),
                    onRemove: () => cart.remove(line.product),
                  ),
                ],
              ),
            ),
          const Divider(height: 32),
          _SectionTitle(context.t('deliverTo')),
          AddressPicker(selection: _address),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(labelText: context.t('notes')),
          ),
          const Divider(height: 32),
          _SectionTitle(context.t('payment')),
          RadioGroup<PaymentMethod>(
            groupValue: PaymentMethod.cash,
            onChanged: (_) {},
            child: Column(
              children: [
                RadioListTile(
                  value: PaymentMethod.cash,
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.t('cash')),
                  secondary: const Icon(Icons.payments_outlined),
                ),
                RadioListTile(
                  value: PaymentMethod.card,
                  enabled: false,
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.t('card')),
                  subtitle: Text(context.t('cardSoon')),
                  secondary: const Icon(Icons.credit_card_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          _SummaryRow(context.t('subtotal'), context.price(cart.subtotal)),
          _SummaryRow(context.t('deliveryFee'), context.price(cart.deliveryFee)),
          _SummaryRow(context.t('total'), context.price(cart.total), bold: true),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
