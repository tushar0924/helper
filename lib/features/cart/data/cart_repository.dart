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
    );

    return AvailableCouponsModal.fromJson(response);
  }

  Future<ApplyCouponResponseModal> applyCoupon({
    required String couponCode,
  }) async {
    final response = await _apiClient.postJson(
      CartApiEndpoint.applyCoupon,
      requiresAuth: true,
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
      body: <String, dynamic>{'couponCode': couponCode},
    );

    return ApplyCouponResponseModal.fromJson(response);
  }

  Future<AppliedCouponsModal> getAppliedCoupons() async {
    final response = await _apiClient.getJson(
      CartApiEndpoint.appliedCoupons,
      requiresAuth: true,
    );

    return AppliedCouponsModal.fromJson(response);
  }
}
