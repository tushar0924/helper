import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../modal/booking_details_modal.dart';
import '../modal/apply_coupon_response_modal.dart';
import '../modal/applied_coupons_modal.dart';
import '../modal/available_coupons_modal.dart';
import '../modal/cart_add_response_modal.dart';
import '../modal/cart_clear_response_modal.dart';
import '../modal/cart_summary_response_modal.dart';
import '../modal/cart_update_response_modal.dart';
import '../modal/payment_order_response_modal.dart';

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
      showSuccessToast: false,
      showErrorToast: false,
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

  Future<CreateFromCartResult> createFromCart({
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.postJson(
      BookingRequestApiEndpoint.createFromCart,
      requiresAuth: true,
      showSuccessToast: false,
      body: <String, dynamic>{'idempotencyKey': idempotencyKey},
    );

    return CreateFromCartResult(
      message: response['message']?.toString() ?? '',
      status: _extractStatus(response),
      bookingId: _extractFinalBookingId(response),
      bookingRequestId: _extractBookingRequestId(response),
      acceptanceWindowSeconds: _extractAcceptanceWindowSeconds(response),
    );
  }

  Future<BookingDetailsModal> getPartnerBooking({
    required int bookingId,
  }) async {
    final response = await _apiClient.getJson(
      PartnerApiEndpoint.bookingById(bookingId),
      requiresAuth: true,
      showSuccessToast: false,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return BookingDetailsModal.fromJson(data);
    }

    throw StateError('Booking details response is invalid');
  }

  Future<BookingDetailsModal> getUserBooking({required int bookingId}) async {
    final response = await _apiClient.getJson(
      UserApiEndpoint.bookingById(bookingId),
      requiresAuth: true,
      showSuccessToast: false,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return BookingDetailsModal.fromJson(data);
    }

    throw StateError('User booking details response is invalid');
  }

  Future<void> initiatePayment({required int bookingId}) async {
    await _apiClient.postJson(
      PaymentApiEndpoint.initiate,
      requiresAuth: true,
      showSuccessToast: false,
      body: <String, dynamic>{'bookingId': bookingId},
    );
  }

  Future<PaymentOrderResponseModal> createPaymentOrder({
    required int bookingId,
    required int amount,
  }) async {
    final response = await _apiClient.postJson(
      PaymentApiEndpoint.createOrder,
      requiresAuth: true,
      showSuccessToast: false,
      body: <String, dynamic>{'bookingId': bookingId, 'amount': amount},
    );

    return PaymentOrderResponseModal.fromJson(response);
  }

  int? _extractBookingRequestId(Map<String, dynamic> response) {
    final data = response['data'];
    final candidates = <Object?>[
      response['id'],
      if (data is Map<String, dynamic>) data['id'],
    ];

    for (final candidate in candidates) {
      final parsed = _toInt(candidate);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  int? _extractFinalBookingId(Map<String, dynamic> response) {
    final data = response['data'];
    final candidates = <Object?>[
      response['bookingId'],
      if (data is Map<String, dynamic>) data['bookingId'],
      if (data is Map<String, dynamic>)
        data['booking'] is Map<String, dynamic>
            ? (data['booking'] as Map<String, dynamic>)['id']
            : null,
    ];

    for (final candidate in candidates) {
      final parsed = _toInt(candidate);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }

    return null;
  }

  String _extractStatus(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data['status']?.toString().toUpperCase() ?? '';
    }
    return '';
  }

  int? _extractAcceptanceWindowSeconds(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    return _toInt(data['acceptanceWindowSeconds']);
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Future<Map<String, dynamic>> cancelBooking({
    required int bookingId,
    required String reason,
    String? note,
  }) async {
    final response = await _apiClient.deleteJson(
      'user/bookings/$bookingId/cancel',
      requiresAuth: true,
      body: <String, dynamic>{
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return response;
  }
}

class CreateFromCartResult {
  const CreateFromCartResult({
    required this.message,
    required this.status,
    required this.bookingId,
    required this.bookingRequestId,
    required this.acceptanceWindowSeconds,
  });

  final String message;
  final String status;
  final int? bookingId;
  final int? bookingRequestId;
  final int? acceptanceWindowSeconds;
}
