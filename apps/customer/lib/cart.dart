import 'package:flutter/foundation.dart';
import 'package:myorders_core/myorders_core.dart';

class CartLine {
  final Product product;
  int quantity;
  CartLine(this.product, this.quantity);

  double get total => product.price * quantity;
}

/// A cart holds items from one store at a time, like most delivery apps.
class CartModel extends ChangeNotifier {
  Store? _store;
  final Map<String, CartLine> _lines = {};

  Store? get store => _store;
  List<CartLine> get lines => _lines.values.toList();
  bool get isEmpty => _lines.isEmpty;
  int get count => _lines.values.fold(0, (sum, l) => sum + l.quantity);
  double get subtotal => _lines.values.fold(0, (sum, l) => sum + l.total);
  double get deliveryFee => _store?.deliveryFee ?? 0;
  double get total => subtotal + deliveryFee;

  int quantityOf(Product p) => _lines[p.id]?.quantity ?? 0;

  /// True when adding from [store] would replace items from another store.
  bool conflictsWith(Store store) => _store != null && _store!.id != store.id;

  void add(Store store, Product product) {
    if (conflictsWith(store)) _lines.clear();
    _store = store;
    _lines.putIfAbsent(product.id, () => CartLine(product, 0)).quantity++;
    notifyListeners();
  }

  void remove(Product product) {
    final line = _lines[product.id];
    if (line == null) return;
    line.quantity--;
    if (line.quantity <= 0) _lines.remove(product.id);
    if (_lines.isEmpty) _store = null;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _store = null;
    notifyListeners();
  }
}

/// Favorite store ids, loaded once and kept in sync with the backend.
class FavoritesModel extends ChangeNotifier {
  final MyOrdersRepository _repo;
  Set<String> _ids = {};

  FavoritesModel(this._repo) {
    reload();
  }

  bool contains(String storeId) => _ids.contains(storeId);
  Set<String> get ids => _ids;

  Future<void> reload() async {
    try {
      _ids = await _repo.favoriteStoreIds();
      notifyListeners();
    } catch (_) {
      // Not signed in yet; favorites stay empty.
    }
  }

  Future<void> toggle(String storeId) async {
    final favorite = !_ids.contains(storeId);
    favorite ? _ids.add(storeId) : _ids.remove(storeId);
    notifyListeners();
    try {
      await _repo.setFavorite(storeId, favorite);
    } catch (_) {
      favorite ? _ids.remove(storeId) : _ids.add(storeId);
      notifyListeners();
      rethrow;
    }
  }
}
