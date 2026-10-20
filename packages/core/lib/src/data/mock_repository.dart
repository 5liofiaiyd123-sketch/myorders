import 'dart:async';
import 'dart:math';

import 'mock_data.dart';
import 'models.dart';
import 'repository.dart';

/// Center of Dahab, used for demo locations.
const dahabLat = 28.4936;
const dahabLng = 34.5136;

/// In-memory backend used until Supabase keys are configured.
///
/// Demo sign-ins: customers use any phone with code 123456. Staff use
/// admin@myorders.app, partner@myorders.app (Blue Hole Restaurant) or
/// rider@myorders.app with any password.
class MockRepository implements MyOrdersRepository {
  /// When true, new orders move through their statuses by themselves so the
  /// customer app can show live tracking without a partner or rider.
  final bool simulateProgress;

  MockRepository({this.simulateProgress = false, AppUser? signedIn}) : _user = signedIn {
    _seedOrders();
  }

  static const demoCustomer = AppUser(id: 'u-customer', name: 'Guest', phone: '+201000000000');
  static const demoAdmin = AppUser(
    id: 'u-admin',
    name: 'Admin',
    email: 'admin@myorders.app',
    role: UserRole.admin,
  );
  static const demoPartner = AppUser(
    id: 'u-partner',
    name: 'Blue Hole Restaurant',
    email: 'partner@myorders.app',
    role: UserRole.partner,
    storeId: 'blue-hole',
  );
  static const demoRider = AppUser(
    id: 'u-rider',
    name: 'Ahmed Salem',
    phone: '+201011112222',
    email: 'rider@myorders.app',
    role: UserRole.rider,
  );

  AppUser? _user;
  final _userController = StreamController<AppUser?>.broadcast();
  final _changes = StreamController<void>.broadcast();

  final List<Store> _stores = [...seedStores];
  final List<Product> _products = [...seedProducts];
  final List<Order> _orders = [];
  final List<Address> _addresses = [
    const Address(
      id: 'a1',
      label: 'Home',
      details: 'Lighthouse, Dahab',
      lat: 28.5005,
      lng: 34.5190,
    ),
  ];
  final Set<String> _favorites = {'blue-hole'};
  final List<PartnerApplication> _applications = [];
  final Map<String, bool> _ridersOnline = {
    demoRider.id: true,
    'u-rider-2': true,
    'u-rider-3': false,
  };
  int _nextCode = 1001;
  int _nextId = 1;

  String _id(String prefix) => '$prefix-${_nextId++}';
  void _notify() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  @override
  bool get isDemo => true;

  // ---------------------------------------------------------------- Auth

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _watchUser();

  Stream<AppUser?> _watchUser() async* {
    yield _user;
    yield* _userController.stream;
  }

  void _setUser(AppUser? user) {
    _user = user;
    _userController.add(user);
  }

  @override
  Future<void> sendOtp(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<AppUser> verifyOtp(String phone, String code, {String? name}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (code != '123456') throw const AuthFailure('Wrong code. In demo mode use 123456.');
    final user = AppUser(
      id: demoCustomer.id,
      name: (name ?? '').trim().isEmpty ? 'Guest' : name!.trim(),
      phone: phone,
    );
    _setUser(user);
    return user;
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final user = switch (email.trim().toLowerCase()) {
      'admin@myorders.app' => demoAdmin,
      'partner@myorders.app' => demoPartner,
      'rider@myorders.app' => demoRider,
      _ => throw const AuthFailure(
        'Unknown demo account. Use admin@, partner@ or rider@myorders.app.',
      ),
    };
    _setUser(user);
    return user;
  }

  @override
  Future<void> updateName(String name) async {
    if (_user != null) _setUser(_user!.copyWith(name: name));
  }

  @override
  Future<void> signOut() async => _setUser(null);

  // ------------------------------------------------------------- Catalog

  @override
  Future<List<Store>> stores({Section? section, bool includeInactive = false}) async => _stores
      .where((s) => (section == null || s.section == section) && (includeInactive || s.isActive))
      .toList();

  @override
  Future<Store?> store(String id) async => _stores.where((s) => s.id == id).firstOrNull;

  @override
  Future<List<Product>> products(String storeId, {bool includeUnavailable = false}) async =>
      _products.where((p) => p.storeId == storeId && (includeUnavailable || p.available)).toList();

  // ------------------------------------------------------------ Customer

  @override
  Future<Order> placeOrder(OrderDraft draft) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = _user ?? demoCustomer;
    Store? store;
    final items = <OrderItem>[];
    if (draft.kind == OrderKind.store) {
      store = _stores.firstWhere((s) => s.id == draft.storeId);
      if (!store.isOpen) throw const OrderFailure('This store is closed right now.');
      for (final e in draft.quantities.entries) {
        final p = _products.firstWhere((p) => p.id == e.key);
        items.add(OrderItem(productId: p.id, name: p.name, price: p.price, quantity: e.value));
      }
    }
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
    if (store != null && subtotal < store.minOrder) {
      throw OrderFailure('Minimum order is ${store.minOrder.toStringAsFixed(0)} EGP.');
    }
    final fee = store?.deliveryFee ?? courierFee;
    final order = Order(
      id: _id('o'),
      code: _nextCode++,
      kind: draft.kind,
      customerId: user.id,
      customerName: draft.customerName,
      customerPhone: draft.customerPhone,
      address: draft.address,
      lat: draft.lat ?? dahabLat,
      lng: draft.lng ?? dahabLng,
      pickupAddress: draft.pickupAddress,
      storeId: store?.id,
      storeName: store?.name,
      items: items,
      subtotal: subtotal,
      deliveryFee: fee,
      total: subtotal + fee,
      payment: draft.payment,
      status: OrderStatus.pending,
      notes: draft.notes,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    _notify();
    if (simulateProgress) _simulate(order.id);
    return order;
  }

  void _simulate(String orderId) {
    var step = 0;
    Timer.periodic(const Duration(seconds: 5), (timer) {
      final i = _orders.indexWhere((o) => o.id == orderId);
      if (i < 0 || !_orders[i].isActive) return timer.cancel();
      final o = _orders[i];
      step++;
      final next = nextStatus(o);
      if (o.status == OrderStatus.pickedUp && step < 9) {
        // Move the rider a bit closer to the customer.
        final t = (step - 4) / 5;
        _orders[i] = o.copyWith(
          riderLat: (o.riderLat ?? 28.5) + ((o.lat ?? dahabLat) - (o.riderLat ?? 28.5)) * t,
          riderLng: (o.riderLng ?? 34.52) + ((o.lng ?? dahabLng) - (o.riderLng ?? 34.52)) * t,
        );
      } else if (next == OrderStatus.pickedUp) {
        _orders[i] = o.copyWith(
          status: next,
          riderId: demoRider.id,
          riderName: demoRider.name,
          riderPhone: demoRider.phone,
          riderLat: 28.5005,
          riderLng: 34.5200,
        );
      } else if (next != null) {
        _orders[i] = o.copyWith(status: next);
      }
      _notify();
    });
  }

  @override
  Stream<List<Order>> watchMyOrders() =>
      _watch(() => _orders.where((o) => o.customerId == (_user ?? demoCustomer).id).toList());

  @override
  Stream<Order?> watchOrder(String id) =>
      _watch(() => _orders.where((o) => o.id == id).firstOrNull);

  @override
  Future<void> cancelOrder(String id) async {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) return;
    if (_orders[i].status != OrderStatus.pending) {
      throw const OrderFailure('The store already accepted this order.');
    }
    _orders[i] = _orders[i].copyWith(status: OrderStatus.cancelled);
    _notify();
  }

  @override
  Future<List<Address>> addresses() async => [..._addresses];

  @override
  Future<Address> saveAddress(Address address) async {
    final saved = address.id.isEmpty
        ? Address(
            id: _id('a'),
            label: address.label,
            details: address.details,
            lat: address.lat,
            lng: address.lng,
          )
        : address;
    _addresses.removeWhere((a) => a.id == saved.id);
    _addresses.add(saved);
    return saved;
  }

  @override
  Future<void> deleteAddress(String id) async => _addresses.removeWhere((a) => a.id == id);

  @override
  Future<Set<String>> favoriteStoreIds() async => {..._favorites};

  @override
  Future<void> setFavorite(String storeId, bool favorite) async =>
      favorite ? _favorites.add(storeId) : _favorites.remove(storeId);

  @override
  Future<void> submitPartnerApplication({
    required String businessName,
    required String contactName,
    required String phone,
    required Section section,
    String notes = '',
  }) async {
    _applications.insert(
      0,
      PartnerApplication(
        id: _id('pa'),
        businessName: businessName,
        contactName: contactName,
        phone: phone,
        section: section,
        notes: notes,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  // ------------------------------------------------------------- Partner

  @override
  Stream<List<Order>> watchStoreOrders(String storeId) =>
      _watch(() => _orders.where((o) => o.storeId == storeId).toList());

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    _orders[i] = _orders[i].copyWith(status: status);
    _notify();
  }

  @override
  Future<Product> saveProduct(Product product) async {
    final saved = product.id.isEmpty
        ? Product(
            id: _id('p'),
            storeId: product.storeId,
            name: product.name,
            description: product.description,
            price: product.price,
            emoji: product.emoji,
            available: product.available,
          )
        : product;
    final i = _products.indexWhere((p) => p.id == saved.id);
    i < 0 ? _products.add(saved) : _products[i] = saved;
    _notify();
    return saved;
  }

  @override
  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    _notify();
  }

  @override
  Future<void> setStoreOpen(String storeId, bool open) async {
    final i = _stores.indexWhere((s) => s.id == storeId);
    if (i >= 0) _stores[i] = _stores[i].copyWith(isOpen: open);
    _notify();
  }

  // --------------------------------------------------------------- Rider

  bool _waitingForRider(Order o) =>
      o.riderId == null &&
      (o.kind == OrderKind.courier
          ? o.status == OrderStatus.pending
          : o.status == OrderStatus.preparing || o.status == OrderStatus.ready);

  @override
  Stream<List<Order>> watchAvailableDeliveries() =>
      _watch(() => _orders.where(_waitingForRider).toList());

  @override
  Stream<List<Order>> watchMyDeliveries() =>
      _watch(() => _orders.where((o) => o.riderId != null && o.riderId == _user?.id).toList());

  @override
  Future<void> takeDelivery(String orderId) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    if (_orders[i].riderId != null) throw const OrderFailure('Another rider took this order.');
    final rider = _user ?? demoRider;
    _orders[i] = _orders[i].copyWith(
      riderId: rider.id,
      riderName: rider.name,
      riderPhone: rider.phone,
      status: _orders[i].kind == OrderKind.courier ? OrderStatus.accepted : null,
    );
    _notify();
  }

  @override
  Future<void> updateRiderLocation(String orderId, double lat, double lng) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i < 0) return;
    _orders[i] = _orders[i].copyWith(riderLat: lat, riderLng: lng);
    _notify();
  }

  @override
  Future<void> setRiderOnline(bool online) async {
    _ridersOnline[_user?.id ?? demoRider.id] = online;
    _notify();
  }

  // --------------------------------------------------------------- Admin

  @override
  Stream<List<Order>> watchAllOrders() => _watch(() => [..._orders]);

  @override
  Future<DashboardStats> stats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    bool counts(Order o) => o.status != OrderStatus.cancelled;
    double revenueOn(DateTime day) => _orders
        .where(
          (o) =>
              counts(o) &&
              !o.createdAt.isBefore(day) &&
              o.createdAt.isBefore(day.add(const Duration(days: 1))),
        )
        .fold(0.0, (sum, o) => sum + o.total);
    final todays = _orders.where((o) => counts(o) && !o.createdAt.isBefore(today));
    return DashboardStats(
      totalOrders: _orders.where(counts).length,
      ordersToday: todays.length,
      activeStores: _stores.where((s) => s.isActive).length,
      partners: _stores.length,
      onlineRiders: _ridersOnline.values.where((v) => v).length,
      revenueToday: todays.fold(0.0, (sum, o) => sum + o.total),
      commissionToday: todays.fold(0.0, (sum, o) => sum + o.subtotal * platformCommission),
      revenueLast7Days: [for (var d = 6; d >= 0; d--) revenueOn(today.subtract(Duration(days: d)))],
    );
  }

  @override
  Future<Store> saveStore(Store store) async {
    final saved = store.id.isEmpty
        ? Store(
            id: _id('s'),
            name: store.name,
            section: store.section,
            tags: store.tags,
            category: store.category,
            etaMin: store.etaMin,
            etaMax: store.etaMax,
            deliveryFee: store.deliveryFee,
            minOrder: store.minOrder,
            emoji: store.emoji,
            phone: store.phone,
            isOpen: store.isOpen,
            isActive: store.isActive,
          )
        : store;
    final i = _stores.indexWhere((s) => s.id == saved.id);
    i < 0 ? _stores.add(saved) : _stores[i] = saved;
    _notify();
    return saved;
  }

  @override
  Future<List<Rider>> riders() async => [
    Rider(
      id: demoRider.id,
      name: demoRider.name,
      phone: demoRider.phone!,
      isOnline: _ridersOnline[demoRider.id]!,
      activeDeliveries: _orders.where((o) => o.riderId == demoRider.id && o.isActive).length,
    ),
    Rider(
      id: 'u-rider-2',
      name: 'Mostafa Eid',
      phone: '+201033334444',
      isOnline: _ridersOnline['u-rider-2']!,
    ),
    Rider(
      id: 'u-rider-3',
      name: 'Sameh Farag',
      phone: '+201055556666',
      isOnline: _ridersOnline['u-rider-3']!,
    ),
  ];

  @override
  Future<List<PartnerApplication>> partnerApplications() async => [..._applications];

  // ---------------------------------------------------------------- Seed

  /// A week of history plus a few live orders so every app has something
  /// to show in demo mode.
  void _seedOrders() {
    final rnd = Random(7);
    final now = DateTime.now();
    const names = ['Sara', 'Omar', 'Lena', 'Karim', 'Mona', 'Tom', 'Youssef', 'Nour'];
    Order make(Store store, DateTime at, OrderStatus status, {bool withRider = false}) {
      final menu = _products.where((p) => p.storeId == store.id).toList();
      final items = [
        for (final p in (menu..shuffle(rnd)).take(1 + rnd.nextInt(min(3, menu.length))))
          OrderItem(productId: p.id, name: p.name, price: p.price, quantity: 1 + rnd.nextInt(2)),
      ];
      final subtotal = items.fold<double>(0, (sum, i) => sum + i.total);
      return Order(
        id: _id('o'),
        code: _nextCode++,
        kind: OrderKind.store,
        customerId: 'u-seed',
        customerName: names[rnd.nextInt(names.length)],
        customerPhone: '+2010${10000000 + rnd.nextInt(89999999)}',
        address: ['Mashraba', 'Lighthouse', 'Masbat', 'Assalah', 'Laguna'][rnd.nextInt(5)],
        lat: 28.48 + rnd.nextDouble() * 0.04,
        lng: 34.50 + rnd.nextDouble() * 0.02,
        storeId: store.id,
        storeName: store.name,
        items: items,
        subtotal: subtotal,
        deliveryFee: store.deliveryFee,
        total: subtotal + store.deliveryFee,
        payment: rnd.nextInt(4) == 0 ? PaymentMethod.card : PaymentMethod.cash,
        status: status,
        riderId: withRider ? demoRider.id : null,
        riderName: withRider ? demoRider.name : null,
        riderPhone: withRider ? demoRider.phone : null,
        riderLat: withRider ? 28.4990 : null,
        riderLng: withRider ? 34.5170 : null,
        createdAt: at,
      );
    }

    for (var d = 6; d >= 0; d--) {
      final count = 5 + rnd.nextInt(6);
      for (var k = 0; k < count; k++) {
        final at = now.subtract(Duration(days: d, minutes: 60 + rnd.nextInt(600)));
        final status = rnd.nextInt(12) == 0 ? OrderStatus.cancelled : OrderStatus.delivered;
        _orders.add(make(_stores[rnd.nextInt(_stores.length)], at, status));
      }
    }
    final blueHole = _stores.first;
    _orders.addAll([
      make(blueHole, now.subtract(const Duration(minutes: 2)), OrderStatus.pending),
      make(blueHole, now.subtract(const Duration(minutes: 9)), OrderStatus.preparing),
      make(_stores[4], now.subtract(const Duration(minutes: 14)), OrderStatus.ready),
      make(
        _stores[1],
        now.subtract(const Duration(minutes: 20)),
        OrderStatus.pickedUp,
        withRider: true,
      ),
    ]);
    _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
