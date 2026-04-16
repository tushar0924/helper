import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/cart_repository.dart';
import '../modal/cart_summary_modal.dart';

class CartState {
  const CartState({
    this.isLoading = false,
    this.isMutating = false,
    this.summary,
    this.errorMessage,
  });

  final bool isLoading;
  final bool isMutating;
  final CartSummaryModal? summary;
  final String? errorMessage;

  CartState copyWith({
    bool? isLoading,
    bool? isMutating,
    CartSummaryModal? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CartState(
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return CartRepository(ref.read(apiClientProvider));
});

class CartController extends StateNotifier<CartState> {
  CartController(this._repository) : super(const CartState());

  static const int maxQuantity = 5;

  final CartRepository _repository;

  Future<void> loadSummary({bool forceRefresh = false}) async {
    if (state.isLoading) {
      return;
    }

    if (!forceRefresh && state.summary != null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.getSummary();
      state = state.copyWith(isLoading: false, summary: response.data);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> addToCart({required int serviceId, int quantity = 1}) async {
    if (state.isMutating) {
      return;
    }

    if (quantity > maxQuantity) {
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await _repository.addToCart(
        serviceId: serviceId,
        quantity: quantity,
      );
      state = state.copyWith(isMutating: false, summary: response.data);
    } catch (error) {
      state = state.copyWith(isMutating: false, errorMessage: error.toString());
    }
  }

  Future<void> updateItem({
    required int serviceId,
    required int quantity,
  }) async {
    if (state.isMutating) {
      return;
    }

    if (quantity < 1 || quantity > maxQuantity) {
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await _repository.updateItem(
        serviceId: serviceId,
        quantity: quantity,
      );
      state = state.copyWith(isMutating: false, summary: response.data);
    } catch (error) {
      state = state.copyWith(isMutating: false, errorMessage: error.toString());
    }
  }

  Future<void> incrementByServiceId(int serviceId) async {
    final current = quantityForServiceId(serviceId);
    if (current >= maxQuantity) {
      return;
    }
    if (current <= 0) {
      await addToCart(serviceId: serviceId, quantity: 1);
      return;
    }
    await updateItem(serviceId: serviceId, quantity: current + 1);
  }

  Future<void> decrementByServiceId(int serviceId) async {
    final current = quantityForServiceId(serviceId);
    if (current <= 1) {
      await updateItem(serviceId: serviceId, quantity: 1);
      return;
    }
    await updateItem(serviceId: serviceId, quantity: current - 1);
  }

  Future<void> clearCart() async {
    if (state.isMutating) {
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final response = await _repository.clearCart();
      state = state.copyWith(isMutating: false, summary: response.data);
    } catch (error) {
      state = state.copyWith(isMutating: false, errorMessage: error.toString());
    }
  }

  int quantityForServiceId(int serviceId) {
    final items = state.summary?.items ?? const <CartItemModal>[];
    for (final item in items) {
      if (item.serviceId == serviceId) {
        return item.quantity;
      }
    }
    return 0;
  }

  bool isAddDisabled(int serviceId) {
    return quantityForServiceId(serviceId) >= maxQuantity || state.isMutating;
  }
}

final cartProvider = StateNotifierProvider<CartController, CartState>((ref) {
  return CartController(ref.read(cartRepositoryProvider));
});

int cartQuantityForServiceId(CartState state, int serviceId) {
  final items = state.summary?.items ?? const <CartItemModal>[];
  for (final item in items) {
    if (item.serviceId == serviceId) {
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
