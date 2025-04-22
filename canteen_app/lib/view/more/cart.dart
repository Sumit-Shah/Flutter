class Cart {
  static final List<Map<String, dynamic>> _items = [];

  static List<Map<String, dynamic>> get items => _items;

  static void addItem(String name, double price, {int qty = 1, String? image}) {
    final existingItem = _items.firstWhere(
      (item) => item['name'] == name,
      orElse: () => {},
    );

    if (existingItem.isNotEmpty) {
      existingItem['qty'] += qty;
    } else {
      _items.add({
        'name': name,
        'price': price,
        'qty': qty,
        'image': image,
      });
    }
  }

  static void updateQuantity(String name, int newQty) {
    final item = _items.firstWhere((item) => item['name'] == name);
    if (newQty <= 0) {
      _items.remove(item);
    } else {
      item['qty'] = newQty;
    }
  }

  static double getTotal() {
    return _items.fold(0.0, (sum, item) => sum + (item['price'] * item['qty']));
  }

  static void clear() {
    _items.clear();
  }
}
