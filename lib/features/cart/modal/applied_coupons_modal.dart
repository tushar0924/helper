class AppliedCouponsModal {
  const AppliedCouponsModal({
    required this.success,
    required this.coupons,
  });

  final bool success;
  final List<AppliedCouponItemModal> coupons;

  factory AppliedCouponsModal.fromJson(Map<String, dynamic> json) {
    final dynamic rootList =
        json['coupons'] ?? json['appliedCoupons'] ?? json['coupon'] ?? json['data'];

    List<dynamic> rawCoupons = const <dynamic>[];
    if (rootList is List) {
      rawCoupons = rootList;
    } else if (rootList is Map<String, dynamic>) {
      final nested = rootList['coupons'] ?? rootList['appliedCoupons'];
      if (nested is List) {
        rawCoupons = nested;
      } else if (rootList.containsKey('code') || rootList.containsKey('discountType')) {
        rawCoupons = <dynamic>[rootList];
      }
    }

    return AppliedCouponsModal(
      success: json['success'] == true,
      coupons: rawCoupons
          .map(AppliedCouponItemModal.fromDynamic)
          .where((item) => item.message.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class AppliedCouponItemModal {
  const AppliedCouponItemModal({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  factory AppliedCouponItemModal.fromDynamic(dynamic raw) {
    if (raw is String) {
      return AppliedCouponItemModal(code: '', message: raw.trim());
    }

    if (raw is! Map<String, dynamic>) {
      return const AppliedCouponItemModal(code: '', message: '');
    }

    final code = raw['code']?.toString() ?? '';

    final directMessage =
        raw['message']?.toString() ??
        raw['displayText']?.toString() ??
        raw['title']?.toString() ??
        raw['description']?.toString() ??
        '';

    if (directMessage.trim().isNotEmpty) {
      return AppliedCouponItemModal(code: code, message: directMessage.trim());
    }

    final savedAmount = _asInt(raw['savedAmount']);
    final discountValue = _asInt(raw['discountValue']);
    final discountType = raw['discountType']?.toString().toUpperCase() ?? '';

    if (savedAmount > 0 && discountValue > 0 && discountType.isNotEmpty) {
      final offerText = _offerText(discountType, discountValue);
      return AppliedCouponItemModal(
        code: code,
        message: '${_formatInr(savedAmount)} saved with $offerText',
      );
    }

    if (discountValue > 0 && discountType.isNotEmpty && code.isNotEmpty) {
      return AppliedCouponItemModal(
        code: code,
        message: '$code applied with ${_offerText(discountType, discountValue)}',
      );
    }

    if (code.isNotEmpty) {
      return AppliedCouponItemModal(code: code, message: '$code applied');
    }

    return const AppliedCouponItemModal(code: '', message: '');
  }
}

String _offerText(String discountType, int discountValue) {
  if (discountType.startsWith('PERCENT')) {
    return 'flat $discountValue% off';
  }
  return 'flat ${_formatInr(discountValue)} off';
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final raw = value?.toString() ?? '';
  if (raw.isEmpty) {
    return 0;
  }
  final cleaned = raw.replaceAll(RegExp(r'[^0-9-]'), '');
  if (cleaned.isEmpty || cleaned == '-') {
    return 0;
  }
  return int.tryParse(cleaned) ?? 0;
}

String _formatInr(int value) {
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
