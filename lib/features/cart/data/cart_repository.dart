import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../modal/apply_coupon_response_modal.dart';
import '../modal/applied_coupons_modal.dart';
import '../modal/available_coupons_modal.dart';
import '../modal/cart_add_response_modal.dart';
import '../modal/cart_clear_response_modal.dart';
import '../modal/cart_summary_response_modal.dart';
import '../modal/cart_update_response_modal.dart';

class CartRepository {
  CartRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<CartAddResponseModal> addToCart({
    required int serviceId,
    required int quantity,
  }) async {
    final response = await _apiClient.postJson(
      CartApiEndpoint.add,
      requiresAuth: true,
      body: <String, dynamic>{'serviceId': serviceId, 'quantity': quantity},
    );

    return CartAddResponseModal.fromJson(response);
  }

  Future<CartUpdateResponseModal> updateItem({
    required int serviceId,
    required int quantity,
  }) async {
    final response = await _apiClient.postJson(
      CartApiEndpoint.updateItem,
      requiresAuth: true,
      body: <String, dynamic>{'serviceId': serviceId, 'quantity': quantity},
    );

    return CartUpdateResponseModal.fromJson(response);
  }

  Future<CartUpdateResponseModal> updateSlot({
    required String date,
    required String time,
  }) async {
    final response = await _apiClient.postJson(
      CartApiEndpoint.updateSlot,
      requiresAuth: true,
      body: <String, dynamic>{'date': date, 'time': time},
    );

    return CartUpdateResponseModal.fromJson(response);
  }

  Future<CartUpdateResponseModal> updateAddress({
    required int addressId,
  }) async {
    final response = await _apiClient.postJson(
      CartApiEndpoint.updateAddress,
      requiresAuth: true,
      body: <String, dynamic>{'addressId': addressId},
    );

    return CartUpdateResponseModal.fromJson(response);
  }

  Future<CartSummaryResponseModal> getSummary() async {
    final response = await _apiClient.getJson(
      CartApiEndpoint.summary,
      requiresAuth: true,
    );

    return CartSummaryResponseModal.fromJson(response);
  }

  Future<CartClearResponseModal> clearCart() async {
    final response = await _apiClient.deleteJson(
      CartApiEndpoint.clear,
      requiresAuth: true,
    );

    return CartClearResponseModal.fromJson(response);
  }

  Future<AvailableCouponsModal> getAvailableCoupons() async {
    final response = await _apiClient.getJson(
      CartApiEndpoint.availableCoupons,
      requiresAuth: true,
      showSuccessToast: false,
    );

    return AvailableCouponsModal.fromJson(response);
  }

  Future<ApplyCouponResponseModal> applyCoupon({
    required String couponCode,
  }) async {
    final response = await _apiClient.postJson(
      CartApiEndpoint.applyCoupon,
      requiresAuth: true,
      showSuccessToast: false,
      body: <String, dynamic>{'couponCode': couponCode},
    );

    return ApplyCouponResponseModal.fromJson(response);
  }

  Future<ApplyCouponResponseModal> removeCoupon({
    required String couponCode,
  }) async {
    final response = await _apiClient.deleteJson(
      CartApiEndpoint.removeCoupon,
      requiresAuth: true,
      showSuccessToast: false,
      body: <String, dynamic>{'couponCode': couponCode},
    );

    return ApplyCouponResponseModal.fromJson(response);
  }

  Future<AppliedCouponsModal> getAppliedCoupons() async {
    final response = await _apiClient.getJson(
      CartApiEndpoint.appliedCoupons,
      requiresAuth: true,
      showSuccessToast: false,
    );

    return AppliedCouponsModal.fromJson(response);
  }

  Future<void> createFromCart({required String idempotencyKey}) async {
    await _apiClient.postJson(
      BookingRequestApiEndpoint.createFromCart,
      requiresAuth: true,
      body: <String, dynamic>{'idempotencyKey': idempotencyKey},
    );
  }
}
