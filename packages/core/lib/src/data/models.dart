import 'package:flutter/widgets.dart';

/// A piece of text in both app languages.
class Tr {
  final String en;
  final String ar;
  const Tr(this.en, this.ar);

  String of(Locale locale) => locale.languageCode == 'ar' ? ar : en;

  /// Reads `<field>_en` and `<field>_ar` columns from a database row.
  factory Tr.fromRow(Map<String, dynamic> row, String field) =>
      Tr(row['${field}_en'] as String? ?? '', row['${field}_ar'] as String? ?? '');

  Map<String, dynamic> toRow(String field) => {'${field}_en': en, '${field}_ar': ar};
}

enum Section { food, drinks, supermarket, pharmacy }

enum UserRole { customer, partner, rider, admin }

enum PaymentMethod { cash, card }

enum OrderKind { store, courier }

/// Lifecycle of an order. Courier orders skip accepted/preparing/ready.
enum OrderStatus { pending, accepted, preparing, ready, pickedUp, delivered, cancelled }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

double _num(Object? v) => v == null ? 0 : (v as num).toDouble();

class AppUser {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final UserRole role;
  final String? storeId; // set for partners

  const AppUser({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.role = UserRole.customer,
    this.storeId,
  });

  factory AppUser.fromRow(Map<String, dynamic> row) => AppUser(
    id: row['id'] as String,
    name: row['full_name'] as String? ?? '',
    phone: row['phone'] as String?,
    email: row['email'] as String?,
    role: _enumByName(UserRole.values, row['role'], UserRole.customer),
    storeId: row['store_id'] as String?,
  );

  AppUser copyWith({String? name}) => AppUser(
    id: id,
    name: name ?? this.name,
    phone: phone,
    email: email,
    role: role,
    storeId: storeId,
  );
}

class Store {
  final String id;
  final Tr name;
  final Section section;
  final Tr tags;
  final String category; // matches a SectionFilter.id
  final double rating;
  final int reviews;
  final int etaMin;
  final int etaMax;
  final double deliveryFee;
  final double minOrder;
  final String emoji;
  final String phone;
  final bool isOpen;
  final bool isActive;

  const Store({
    required this.id,
    required this.name,
    required this.section,
    required this.tags,
    required this.category,
    this.rating = 0,
    this.reviews = 0,
    this.etaMin = 20,
    this.etaMax = 40,
    this.deliveryFee = 20,
    this.minOrder = 0,
    this.emoji = '🏪',
    this.phone = '',
    this.isOpen = true,
    this.isActive = true,
  });

  factory Store.fromRow(Map<String, dynamic> row) => Store(
    id: row['id'] as String,
    name: Tr.fromRow(row, 'name'),
    section: _enumByName(Section.values, row['section'], Section.food),
    tags: Tr.fromRow(row, 'tags'),
    category: row['category'] as String? ?? 'all',
    rating: _num(row['rating']),
    reviews: row['reviews'] as int? ?? 0,
    etaMin: row['eta_min'] as int? ?? 20,
    etaMax: row['eta_max'] as int? ?? 40,
    deliveryFee: _num(row['delivery_fee']),
    minOrder: _num(row['min_order']),
    emoji: row['emoji'] as String? ?? '🏪',
    phone: row['phone'] as String? ?? '',
    isOpen: row['is_open'] as bool? ?? true,
    isActive: row['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toRow() => {
    if (id.isNotEmpty) 'id': id,
    ...name.toRow('name'),
    ...tags.toRow('tags'),
    'section': section.name,
    'category': category,
    'eta_min': etaMin,
    'eta_max': etaMax,
    'delivery_fee': deliveryFee,
    'min_order': minOrder,
    'emoji': emoji,
    'phone': phone,
    'is_open': isOpen,
    'is_active': isActive,
  };

  Store copyWith({
    Tr? name,
    Section? section,
    Tr? tags,
    String? category,
    int? etaMin,
    int? etaMax,
    double? deliveryFee,
    double? minOrder,
    String? emoji,
    String? phone,
    bool? isOpen,
    bool? isActive,
  }) => Store(
    id: id,
    name: name ?? this.name,
    section: section ?? this.section,
    tags: tags ?? this.tags,
    category: category ?? this.category,
    rating: rating,
    reviews: reviews,
    etaMin: etaMin ?? this.etaMin,
    etaMax: etaMax ?? this.etaMax,
    deliveryFee: deliveryFee ?? this.deliveryFee,
    minOrder: minOrder ?? this.minOrder,
    emoji: emoji ?? this.emoji,
    phone: phone ?? this.phone,
    isOpen: isOpen ?? this.isOpen,
    isActive: isActive ?? this.isActive,
  );
}

class Product {
  final String id;
  final String storeId;
  final Tr name;
  final Tr description;
  final double price; // EGP
  final String emoji;
  final bool available;

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    required this.description,
    required this.price,
    required this.emoji,
    this.available = true,
  });

  factory Product.fromRow(Map<String, dynamic> row) => Product(
    id: row['id'] as String,
    storeId: row['store_id'] as String,
    name: Tr.fromRow(row, 'name'),
    description: Tr.fromRow(row, 'description'),
    price: _num(row['price']),
    emoji: row['emoji'] as String? ?? '🍽️',
    available: row['available'] as bool? ?? true,
  );

  Map<String, dynamic> toRow() => {
    if (id.isNotEmpty) 'id': id,
    'store_id': storeId,
    ...name.toRow('name'),
    ...description.toRow('description'),
    'price': price,
    'emoji': emoji,
    'available': available,
  };

  Product copyWith({Tr? name, Tr? description, double? price, String? emoji, bool? available}) =>
      Product(
        id: id,
        storeId: storeId,
        name: name ?? this.name,
        description: description ?? this.description,
        price: price ?? this.price,
        emoji: emoji ?? this.emoji,
        available: available ?? this.available,
      );
}

class OrderItem {
  final String productId;
  final Tr name;
  final double price;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    productId: j['product_id'] as String,
    name: Tr(j['name_en'] as String? ?? '', j['name_ar'] as String? ?? ''),
    price: _num(j['price']),
    quantity: j['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'name_en': name.en,
    'name_ar': name.ar,
    'price': price,
    'quantity': quantity,
  };
}

class Address {
  final String id;
  final String label;
  final String details;
  final double? lat;
  final double? lng;

  const Address({required this.id, required this.label, required this.details, this.lat, this.lng});

  factory Address.fromRow(Map<String, dynamic> row) => Address(
    id: row['id'] as String,
    label: row['label'] as String? ?? '',
    details: row['details'] as String? ?? '',
    lat: (row['lat'] as num?)?.toDouble(),
    lng: (row['lng'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toRow() => {
    if (id.isNotEmpty) 'id': id,
    'label': label,
    'details': details,
    'lat': lat,
    'lng': lng,
  };
}

/// What the customer app sends when placing an order. Prices are
/// recalculated on the server, so only ids and quantities matter.
class OrderDraft {
  final OrderKind kind;
  final String? storeId;
  final Map<String, int> quantities; // productId -> qty
  final String customerName;
  final String customerPhone;
  final String address;
  final double? lat;
  final double? lng;
  final String? pickupAddress; // courier orders
  final String notes;
  final PaymentMethod payment;

  const OrderDraft({
    required this.kind,
    this.storeId,
    this.quantities = const {},
    required this.customerName,
    required this.customerPhone,
    required this.address,
    this.lat,
    this.lng,
    this.pickupAddress,
    this.notes = '',
    this.payment = PaymentMethod.cash,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'store_id': storeId,
    'items': [
      for (final e in quantities.entries) {'product_id': e.key, 'quantity': e.value},
    ],
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'address': address,
    'lat': lat,
    'lng': lng,
    'pickup_address': pickupAddress,
    'notes': notes,
    'payment': payment.name,
  };
}

class Order {
  final String id;
  final int code;
  final OrderKind kind;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String address;
  final double? lat;
  final double? lng;
  final String? pickupAddress;
  final String? storeId;
  final Tr? storeName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final PaymentMethod payment;
  final OrderStatus status;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final double? riderLat;
  final double? riderLng;
  final String notes;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.code,
    required this.kind,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    this.lat,
    this.lng,
    this.pickupAddress,
    this.storeId,
    this.storeName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.payment,
    required this.status,
    this.riderId,
    this.riderName,
    this.riderPhone,
    this.riderLat,
    this.riderLng,
    this.notes = '',
    required this.createdAt,
  });

  bool get isActive => status != OrderStatus.delivered && status != OrderStatus.cancelled;

  factory Order.fromRow(Map<String, dynamic> row) => Order(
    id: row['id'] as String,
    code: row['code'] as int? ?? 0,
    kind: _enumByName(OrderKind.values, row['kind'], OrderKind.store),
    customerId: row['customer_id'] as String? ?? '',
    customerName: row['customer_name'] as String? ?? '',
    customerPhone: row['customer_phone'] as String? ?? '',
    address: row['address'] as String? ?? '',
    lat: (row['lat'] as num?)?.toDouble(),
    lng: (row['lng'] as num?)?.toDouble(),
    pickupAddress: row['pickup_address'] as String?,
    storeId: row['store_id'] as String?,
    storeName: row['store_name_en'] == null ? null : Tr.fromRow(row, 'store_name'),
    items: [
      for (final i in (row['items'] as List? ?? const []))
        OrderItem.fromJson(Map<String, dynamic>.from(i as Map)),
    ],
    subtotal: _num(row['subtotal']),
    deliveryFee: _num(row['delivery_fee']),
    total: _num(row['total']),
    payment: _enumByName(PaymentMethod.values, row['payment'], PaymentMethod.cash),
    status: _statusFromDb(row['status']),
    riderId: row['rider_id'] as String?,
    riderName: row['rider_name'] as String?,
    riderPhone: row['rider_phone'] as String?,
    riderLat: (row['rider_lat'] as num?)?.toDouble(),
    riderLng: (row['rider_lng'] as num?)?.toDouble(),
    notes: row['notes'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );

  Order copyWith({
    OrderStatus? status,
    String? riderId,
    String? riderName,
    String? riderPhone,
    double? riderLat,
    double? riderLng,
  }) => Order(
    id: id,
    code: code,
    kind: kind,
    customerId: customerId,
    customerName: customerName,
    customerPhone: customerPhone,
    address: address,
    lat: lat,
    lng: lng,
    pickupAddress: pickupAddress,
    storeId: storeId,
    storeName: storeName,
    items: items,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    total: total,
    payment: payment,
    status: status ?? this.status,
    riderId: riderId ?? this.riderId,
    riderName: riderName ?? this.riderName,
    riderPhone: riderPhone ?? this.riderPhone,
    riderLat: riderLat ?? this.riderLat,
    riderLng: riderLng ?? this.riderLng,
    notes: notes,
    createdAt: createdAt,
  );
}

/// The database stores statuses in snake_case (picked_up).
OrderStatus _statusFromDb(Object? s) =>
    _enumByName(OrderStatus.values, s == 'picked_up' ? 'pickedUp' : s, OrderStatus.pending);

String statusToDb(OrderStatus s) => s == OrderStatus.pickedUp ? 'picked_up' : s.name;

class Rider {
  final String id;
  final String name;
  final String phone;
  final bool isOnline;
  final int activeDeliveries;

  const Rider({
    required this.id,
    required this.name,
    required this.phone,
    this.isOnline = false,
    this.activeDeliveries = 0,
  });
}

class PartnerApplication {
  final String id;
  final String businessName;
  final String contactName;
  final String phone;
  final Section section;
  final String notes;
  final DateTime createdAt;

  const PartnerApplication({
    required this.id,
    required this.businessName,
    required this.contactName,
    required this.phone,
    required this.section,
    this.notes = '',
    required this.createdAt,
  });

  factory PartnerApplication.fromRow(Map<String, dynamic> row) => PartnerApplication(
    id: row['id'] as String,
    businessName: row['business_name'] as String? ?? '',
    contactName: row['contact_name'] as String? ?? '',
    phone: row['phone'] as String? ?? '',
    section: _enumByName(Section.values, row['section'], Section.food),
    notes: row['notes'] as String? ?? '',
    createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
  );
}

class DashboardStats {
  final int totalOrders;
  final int ordersToday;
  final int activeStores;
  final int partners;
  final int onlineRiders;
  final double revenueToday; // order totals
  final double commissionToday; // platform share
  final List<double> revenueLast7Days; // oldest first

  const DashboardStats({
    required this.totalOrders,
    required this.ordersToday,
    required this.activeStores,
    required this.partners,
    required this.onlineRiders,
    required this.revenueToday,
    required this.commissionToday,
    required this.revenueLast7Days,
  });
}

/// A chip under a section's banner, e.g. "Seafood" in Food.
class SectionFilter {
  final String id;
  final Tr label;
  final IconData icon;
  const SectionFilter(this.id, this.label, this.icon);
}
