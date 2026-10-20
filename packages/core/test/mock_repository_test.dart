import 'package:flutter_test/flutter_test.dart';
import 'package:myorders_core/myorders_core.dart';

void main() {
  test('placing an order prices items from the catalog', () async {
    final repo = MockRepository();
    await repo.verifyOtp('+201000000001', '123456', name: 'Sara');
    final order = await repo.placeOrder(
      const OrderDraft(
        kind: OrderKind.store,
        storeId: 'blue-hole',
        quantities: {'bh1': 2, 'bh3': 1},
        customerName: 'Sara',
        customerPhone: '+201000000001',
        address: 'Lighthouse',
      ),
    );
    expect(order.subtotal, 320 * 2 + 260);
    expect(order.deliveryFee, 25);
    expect(order.total, order.subtotal + 25);
    expect(order.status, OrderStatus.pending);
  });

  test('wrong OTP code is rejected', () async {
    final repo = MockRepository();
    expect(() => repo.verifyOtp('+201000000001', '000000'), throwsA(isA<AuthFailure>()));
  });

  test('closed stores do not take orders', () async {
    final repo = MockRepository();
    await repo.setStoreOpen('blue-hole', false);
    expect(
      () => repo.placeOrder(
        const OrderDraft(
          kind: OrderKind.store,
          storeId: 'blue-hole',
          quantities: {'bh1': 1},
          customerName: 'x',
          customerPhone: 'x',
          address: 'x',
        ),
      ),
      throwsA(isA<OrderFailure>()),
    );
  });

  test('a delivery can only be taken once', () async {
    final repo = MockRepository(signedIn: MockRepository.demoRider);
    final ready = (await repo.watchAvailableDeliveries().first).first;
    await repo.takeDelivery(ready.id);
    expect(() => repo.takeDelivery(ready.id), throwsA(isA<OrderFailure>()));
  });

  test('order statuses follow the store and courier flows', () {
    Order make(OrderKind kind, OrderStatus status) => Order(
      id: 'o',
      code: 1,
      kind: kind,
      customerId: 'c',
      customerName: '',
      customerPhone: '',
      address: '',
      items: const [],
      subtotal: 0,
      deliveryFee: 0,
      total: 0,
      payment: PaymentMethod.cash,
      status: status,
      createdAt: DateTime(2026),
    );
    expect(nextStatus(make(OrderKind.store, OrderStatus.pending)), OrderStatus.accepted);
    expect(nextStatus(make(OrderKind.store, OrderStatus.ready)), OrderStatus.pickedUp);
    expect(nextStatus(make(OrderKind.courier, OrderStatus.accepted)), OrderStatus.pickedUp);
    expect(nextStatus(make(OrderKind.store, OrderStatus.delivered)), isNull);
  });

  test('database rows round-trip', () {
    final row = {
      'id': 'o1',
      'code': 1001,
      'kind': 'store',
      'status': 'picked_up',
      'items': [
        {'product_id': 'p', 'name_en': 'Tea', 'name_ar': 'شاي', 'price': 35, 'quantity': 2},
      ],
      'subtotal': 70,
      'total': 90,
      'delivery_fee': 20,
      'store_name_en': 'Cafe',
      'store_name_ar': 'كافيه',
      'created_at': '2026-10-20T10:00:00Z',
    };
    final order = Order.fromRow(row);
    expect(order.status, OrderStatus.pickedUp);
    expect(statusToDb(order.status), 'picked_up');
    expect(order.items.single.total, 70);
    expect(order.storeName!.ar, 'كافيه');
  });
}
