import 'models.dart';

/// Platform share of each store order's subtotal. The rest goes to the store.
/// The delivery fee goes to the delivery operation (riders).
const platformCommission = 0.15;

/// Base fee for "send anything" courier orders inside Dahab.
const courierFee = 40.0;

/// Everything the apps need from the backend. [MockRepository] keeps data in
/// memory for demos; [SupabaseRepository] talks to the real backend.
abstract class MyOrdersRepository {
  bool get isDemo;

  // Auth
  AppUser? get currentUser;
  Stream<AppUser?> get userChanges;
  Future<void> sendOtp(String phone);
  Future<AppUser> verifyOtp(String phone, String code, {String? name});
  Future<AppUser> signInWithEmail(String email, String password);
  Future<void> updateName(String name);
  Future<void> signOut();

  // Catalog
  Future<List<Store>> stores({Section? section, bool includeInactive = false});
  Future<Store?> store(String id);
  Future<List<Product>> products(String storeId, {bool includeUnavailable = false});

  // Customer
  Future<Order> placeOrder(OrderDraft draft);
  Stream<List<Order>> watchMyOrders();
  Stream<Order?> watchOrder(String id);
  Future<void> cancelOrder(String id);
  Future<List<Address>> addresses();
  Future<Address> saveAddress(Address address);
  Future<void> deleteAddress(String id);
  Future<Set<String>> favoriteStoreIds();
  Future<void> setFavorite(String storeId, bool favorite);
  Future<void> submitPartnerApplication({
    required String businessName,
    required String contactName,
    required String phone,
    required Section section,
    String notes = '',
  });

  // Partner (store owner)
  Stream<List<Order>> watchStoreOrders(String storeId);
  Future<void> updateOrderStatus(String orderId, OrderStatus status);
  Future<Product> saveProduct(Product product);
  Future<void> deleteProduct(String productId);
  Future<void> setStoreOpen(String storeId, bool open);

  // Rider
  Stream<List<Order>> watchAvailableDeliveries();
  Stream<List<Order>> watchMyDeliveries();
  Future<void> takeDelivery(String orderId);
  Future<void> updateRiderLocation(String orderId, double lat, double lng);
  Future<void> setRiderOnline(bool online);

  // Admin
  Stream<List<Order>> watchAllOrders();
  Future<DashboardStats> stats();
  Future<Store> saveStore(Store store);
  Future<List<Rider>> riders();
  Future<List<PartnerApplication>> partnerApplications();
}

/// Which status a partner or rider can move an order to next.
OrderStatus? nextStatus(Order order) {
  if (order.kind == OrderKind.courier) {
    return switch (order.status) {
      OrderStatus.pending || OrderStatus.accepted || OrderStatus.ready => OrderStatus.pickedUp,
      OrderStatus.pickedUp => OrderStatus.delivered,
      _ => null,
    };
  }
  return switch (order.status) {
    OrderStatus.pending => OrderStatus.accepted,
    OrderStatus.accepted => OrderStatus.preparing,
    OrderStatus.preparing => OrderStatus.ready,
    OrderStatus.ready => OrderStatus.pickedUp,
    OrderStatus.pickedUp => OrderStatus.delivered,
    _ => null,
  };
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}

class OrderFailure implements Exception {
  final String message;
  const OrderFailure(this.message);
  @override
  String toString() => message;
}
