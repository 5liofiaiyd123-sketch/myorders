import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';
import 'repository.dart';

/// Backend on Supabase. Tables, policies and RPCs are in
/// supabase/migrations at the repository root.
class SupabaseRepository implements MyOrdersRepository {
  final SupabaseClient _db;
  AppUser? _user;
  final _userController = StreamController<AppUser?>.broadcast();

  SupabaseRepository(this._db) {
    _db.auth.onAuthStateChange.listen((state) async {
      _user = state.session == null ? null : await _loadProfile();
      _userController.add(_user);
    });
  }

  /// Loads the signed-in user's profile once at startup.
  Future<void> init() async {
    if (_db.auth.currentSession != null) _user = await _loadProfile();
  }

  Future<AppUser?> _loadProfile() async {
    final id = _db.auth.currentUser?.id;
    if (id == null) return null;
    final row = await _db.from('profiles').select().eq('id', id).maybeSingle();
    return row == null ? null : AppUser.fromRow(row);
  }

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) throw const AuthFailure('Please sign in first.');
    return id;
  }

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      throw OrderFailure(e.message);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Stream<List<Order>> _orders(
    Stream<List<Map<String, dynamic>>> rows, [
    bool Function(Order)? where,
  ]) => rows.map((list) {
    final orders = list.map(Order.fromRow).where(where ?? (_) => true).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  });

  @override
  bool get isDemo => false;

  // ---------------------------------------------------------------- Auth

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges async* {
    yield _user;
    yield* _userController.stream;
  }

  @override
  Future<void> sendOtp(String phone) => _guard(() => _db.auth.signInWithOtp(phone: phone));

  @override
  Future<AppUser> verifyOtp(String phone, String code, {String? name}) => _guard(() async {
    await _db.auth.verifyOTP(phone: phone, token: code, type: OtpType.sms);
    if (name != null && name.trim().isNotEmpty) {
      await _db.from('profiles').update({'full_name': name.trim()}).eq('id', _uid);
    }
    _user = await _loadProfile();
    _userController.add(_user);
    return _user!;
  });

  @override
  Future<AppUser> signInWithEmail(String email, String password) => _guard(() async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
    _user = await _loadProfile();
    _userController.add(_user);
    if (_user == null) throw const AuthFailure('No profile for this account.');
    return _user!;
  });

  @override
  Future<void> updateName(String name) => _guard(() async {
    await _db.from('profiles').update({'full_name': name}).eq('id', _uid);
    _user = _user?.copyWith(name: name);
    _userController.add(_user);
  });

  @override
  Future<void> signOut() => _db.auth.signOut();

  // ------------------------------------------------------------- Catalog

  @override
  Future<List<Store>> stores({Section? section, bool includeInactive = false}) => _guard(() async {
    var query = _db.from('stores').select();
    if (section != null) query = query.eq('section', section.name);
    if (!includeInactive) query = query.eq('is_active', true);
    final rows = await query.order('rating', ascending: false);
    return rows.map(Store.fromRow).toList();
  });

  @override
  Future<Store?> store(String id) => _guard(() async {
    final row = await _db.from('stores').select().eq('id', id).maybeSingle();
    return row == null ? null : Store.fromRow(row);
  });

  @override
  Future<List<Product>> products(String storeId, {bool includeUnavailable = false}) =>
      _guard(() async {
        var query = _db.from('products').select().eq('store_id', storeId);
        if (!includeUnavailable) query = query.eq('available', true);
        final rows = await query.order('created_at');
        return rows.map(Product.fromRow).toList();
      });

  // ------------------------------------------------------------ Customer

  @override
  Future<Order> placeOrder(OrderDraft draft) => _guard(() async {
    final row = await _db.rpc('place_order', params: {'draft': draft.toJson()});
    return Order.fromRow(Map<String, dynamic>.from(row as Map));
  });

  @override
  Stream<List<Order>> watchMyOrders() =>
      _orders(_db.from('orders').stream(primaryKey: ['id']).eq('customer_id', _uid));

  @override
  Stream<Order?> watchOrder(String id) => _db
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', id)
      .map((rows) => rows.isEmpty ? null : Order.fromRow(rows.first));

  @override
  Future<void> cancelOrder(String id) => updateOrderStatus(id, OrderStatus.cancelled);

  @override
  Future<List<Address>> addresses() => _guard(() async {
    final rows = await _db.from('addresses').select().order('created_at');
    return rows.map(Address.fromRow).toList();
  });

  @override
  Future<Address> saveAddress(Address address) => _guard(() async {
    final row = await _db.from('addresses').upsert(address.toRow()).select().single();
    return Address.fromRow(row);
  });

  @override
  Future<void> deleteAddress(String id) =>
      _guard(() => _db.from('addresses').delete().eq('id', id));

  @override
  Future<Set<String>> favoriteStoreIds() => _guard(() async {
    if (_db.auth.currentUser == null) return <String>{};
    final rows = await _db.from('favorites').select('store_id');
    return rows.map((r) => r['store_id'] as String).toSet();
  });

  @override
  Future<void> setFavorite(String storeId, bool favorite) => _guard(() async {
    if (favorite) {
      await _db.from('favorites').upsert({'user_id': _uid, 'store_id': storeId});
    } else {
      await _db.from('favorites').delete().eq('store_id', storeId).eq('user_id', _uid);
    }
  });

  @override
  Future<void> submitPartnerApplication({
    required String businessName,
    required String contactName,
    required String phone,
    required Section section,
    String notes = '',
  }) => _guard(
    () => _db.from('partner_applications').insert({
      'business_name': businessName,
      'contact_name': contactName,
      'phone': phone,
      'section': section.name,
      'notes': notes,
    }),
  );

  // ------------------------------------------------------------- Partner

  @override
  Stream<List<Order>> watchStoreOrders(String storeId) =>
      _orders(_db.from('orders').stream(primaryKey: ['id']).eq('store_id', storeId));

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) => _guard(
    () => _db.rpc(
      'update_order_status',
      params: {'order_id': orderId, 'new_status': statusToDb(status)},
    ),
  );

  @override
  Future<Product> saveProduct(Product product) => _guard(() async {
    final row = await _db.from('products').upsert(product.toRow()).select().single();
    return Product.fromRow(row);
  });

  @override
  Future<void> deleteProduct(String productId) =>
      _guard(() => _db.from('products').delete().eq('id', productId));

  @override
  Future<void> setStoreOpen(String storeId, bool open) =>
      _guard(() => _db.rpc('set_store_open', params: {'target_store': storeId, 'open': open}));

  // --------------------------------------------------------------- Rider

  @override
  Stream<List<Order>> watchAvailableDeliveries() =>
      // Row level security already limits riders to orders they may see.
      _orders(
        _db.from('orders').stream(primaryKey: ['id']),
        (o) => o.riderId == null && o.isActive,
      );

  @override
  Stream<List<Order>> watchMyDeliveries() =>
      _orders(_db.from('orders').stream(primaryKey: ['id']).eq('rider_id', _uid));

  @override
  Future<void> takeDelivery(String orderId) =>
      _guard(() => _db.rpc('take_delivery', params: {'order_id': orderId}));

  @override
  Future<void> updateRiderLocation(String orderId, double lat, double lng) => _guard(
    () => _db.rpc('update_rider_location', params: {'order_id': orderId, 'p_lat': lat, 'p_lng': lng}),
  );

  @override
  Future<void> setRiderOnline(bool online) =>
      _guard(() => _db.rpc('set_rider_online', params: {'online': online}));

  // --------------------------------------------------------------- Admin

  @override
  Stream<List<Order>> watchAllOrders() =>
      _orders(_db.from('orders').stream(primaryKey: ['id']).order('created_at').limit(500));

  @override
  Future<DashboardStats> stats() => _guard(() async {
    final j = Map<String, dynamic>.from(await _db.rpc('admin_stats') as Map);
    double n(String k) => (j[k] as num? ?? 0).toDouble();
    return DashboardStats(
      totalOrders: n('total_orders').toInt(),
      ordersToday: n('orders_today').toInt(),
      activeStores: n('active_stores').toInt(),
      partners: n('partners').toInt(),
      onlineRiders: n('online_riders').toInt(),
      revenueToday: n('revenue_today'),
      commissionToday: n('commission_today'),
      revenueLast7Days: [for (final v in (j['revenue_last_7_days'] as List)) (v as num).toDouble()],
    );
  });

  @override
  Future<Store> saveStore(Store store) => _guard(() async {
    final row = await _db.from('stores').upsert(store.toRow()).select().single();
    return Store.fromRow(row);
  });

  @override
  Future<List<Rider>> riders() => _guard(() async {
    final rows = await _db.rpc('list_riders') as List;
    return [
      for (final r in rows.cast<Map>())
        Rider(
          id: r['id'] as String,
          name: r['full_name'] as String,
          phone: r['phone'] as String,
          isOnline: r['is_online'] as bool,
          activeDeliveries: (r['active_deliveries'] as num).toInt(),
        ),
    ];
  });

  @override
  Future<List<PartnerApplication>> partnerApplications() => _guard(() async {
    final rows = await _db
        .from('partner_applications')
        .select()
        .order('created_at', ascending: false);
    return rows.map(PartnerApplication.fromRow).toList();
  });
}
