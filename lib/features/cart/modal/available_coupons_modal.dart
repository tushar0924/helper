class AvailableCouponsModal {
  const AvailableCouponsModal({
    required this.success,
    required this.message,
    required this.coupons,
    required this.cartTotal,
  });

  final bool success;
  final String message;
  final List<CouponModal> coupons;
  final int cartTotal;

  factory AvailableCouponsModal.fromJson(Map<String, dynamic> json) {
    final couponsJson = json['coupons'];

    return AvailableCouponsModal(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      coupons: couponsJson is List
          ? couponsJson
                .whereType<Map<String, dynamic>>()
                .map(CouponModal.fromJson)
                .toList(growable: false)
          : const <CouponModal>[],
      cartTotal: _asInt(json['cartTotal']),
    );
  }
}

class CouponModal {
  const CouponModal({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.minOrderAmount,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.isApplicable,
    required this.message,
  });

  final int id;
  final String code;
  final String title;
  final String description;
  final int minOrderAmount;
  final String discountType;
  final int discountValue;
  final int maxDiscount;
  final bool isApplicable;
  final String message;

  factory CouponModal.fromJson(Map<String, dynamic> json) {
    return CouponModal(
      id: _asInt(json['id']),
      code: json['code']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      minOrderAmount: _asInt(json['minOrderAmount']),
      discountType: json['discountType']?.toString() ?? '',
      discountValue: _asInt(json['discountValue']),
      maxDiscount: _asInt(json['maxDiscount']),
      isApplicable: json['isApplicable'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
