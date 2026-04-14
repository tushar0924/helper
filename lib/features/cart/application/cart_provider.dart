import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  const CartItem({
    required this.title,
    required this.category,
    required this.price,
    required this.duration,
    required this.imageUrl,
    required this.quantity,
  });

  final String title;
  final String category;
  final int price;
  final String duration;
  final String imageUrl;
  final int quantity;

  CartItem copyWith({
    String? title,
    String? category,
    int? price,
    String? duration,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItem(
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartController extends StateNotifier<List<CartItem>> {
  CartController() : super(const <CartItem>[]);

  void addService({
    required String title,
    required String category,
    required String priceText,
    required String duration,
    required String imageUrl,
  }) {
    final price = _parsePrice(priceText);
    final index = state.indexWhere((item) => item.title == title);
    if (index >= 0) {
      final updated = [...state];
      final current = updated[index];
      updated[index] = current.copyWith(quantity: current.quantity + 1);
      state = updated;
      return;
    }

    state = [
      ...state,
      CartItem(
        title: title,
        category: category,
        price: price,
        duration: duration,
        imageUrl: imageUrl,
        quantity: 1,
      ),
    ];
  }

  void increment(String title) {
    final index = state.indexWhere((item) => item.title == title);
    if (index < 0) {
      return;
    }

    final updated = [...state];
    final item = updated[index];
    updated[index] = item.copyWith(quantity: item.quantity + 1);
    state = updated;
  }

  void decrement(String title) {
    final index = state.indexWhere((item) => item.title == title);
    if (index < 0) {
      return;
    }

    final updated = [...state];
    final item = updated[index];
    if (item.quantity <= 1) {
      updated.removeAt(index);
      state = updated;
      return;
    }

    updated[index] = item.copyWith(quantity: item.quantity - 1);
    state = updated;
  }

  static int _parsePrice(String priceText) {
    final onlyDigits = priceText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(onlyDigits) ?? 0;
  }
}

final cartProvider = StateNotifierProvider<CartController, List<CartItem>>(
  (ref) => CartController(),
);

int cartQuantityForTitle(List<CartItem> items, String title) {
  for (final item in items) {
    if (item.title == title) {
      return item.quantity;
    }
  }
  return 0;
}

String formatInr(int value) {
  final text = value.toString();
  if (text.length <= 3) {
    return '\u20b9$text';
  }

  final lastThree = text.substring(text.length - 3);
  var remaining = text.substring(0, text.length - 3);
  final parts = <String>[];

  while (remaining.length > 2) {
    parts.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }

  if (remaining.isNotEmpty) {
    parts.insert(0, remaining);
  }

  return '\u20b9${parts.join(',')},$lastThree';
}
