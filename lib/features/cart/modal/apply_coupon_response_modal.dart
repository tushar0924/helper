class ApplyCouponResponseModal {
  const ApplyCouponResponseModal({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;

  factory ApplyCouponResponseModal.fromJson(Map<String, dynamic> json) {
    return ApplyCouponResponseModal(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Coupon applied successfully',
    );
  }
}
