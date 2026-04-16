class CartSummaryModal {
  const CartSummaryModal({
    required this.cartId,
    required this.items,
    required this.slot,
    required this.address,
    required this.coupon,
    required this.pricing,
    required this.lastUpdatedAt,
  });

  final int cartId;
  final List<CartItemModal> items;
  final CartSlotModal slot;
  final CartAddressModal? address;
  final Object? coupon;
  final CartPricingModal pricing;
  final DateTime? lastUpdatedAt;

  factory CartSummaryModal.empty() {
    return CartSummaryModal(
      cartId: 0,
      items: const <CartItemModal>[],
      slot: const CartSlotModal(date: null, time: null),
      address: null,
      coupon: null,
      pricing: const CartPricingModal(
        itemTotal: 0,
        addonTotal: 0,
        discount: 0,
        platformFee: 0,
        gst: 0,
        total: 0,
      ),
      lastUpdatedAt: null,
    );
  }

  factory CartSummaryModal.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final slotJson = json['slot'];
    final addressJson = json['address'];
    final pricingJson = json['pricing'];

    return CartSummaryModal(
      cartId: _asInt(json['cartId']),
      items: itemsJson is List
          ? itemsJson
                .whereType<Map<String, dynamic>>()
                .map(CartItemModal.fromJson)
                .toList(growable: false)
          : const <CartItemModal>[],
      slot: slotJson is Map<String, dynamic>
          ? CartSlotModal.fromJson(slotJson)
          : const CartSlotModal(date: null, time: null),
      address: addressJson is Map<String, dynamic>
          ? CartAddressModal.fromJson(addressJson)
          : null,
      coupon: json['coupon'],
      pricing: pricingJson is Map<String, dynamic>
          ? CartPricingModal.fromJson(pricingJson)
          : const CartPricingModal(
              itemTotal: 0,
              addonTotal: 0,
              discount: 0,
              platformFee: 0,
              gst: 0,
              total: 0,
            ),
      lastUpdatedAt: DateTime.tryParse(json['lastUpdatedAt']?.toString() ?? ''),
    );
  }
}

class CartItemModal {
  const CartItemModal({
    required this.serviceId,
    required this.name,
    required this.imageUrl,
    required this.priceAtAdded,
    required this.duration,
    required this.quantity,
    required this.addons,
  });

  final int serviceId;
  final String name;
  final String? imageUrl;
  final int priceAtAdded;
  final int duration;
  final int quantity;
  final List<Object?> addons;

  factory CartItemModal.fromJson(Map<String, dynamic> json) {
    final addonsJson = json['addons'];

    return CartItemModal(
      serviceId: _asInt(json['serviceId']),
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      priceAtAdded: _asInt(json['priceAtAdded']),
      duration: _asInt(json['duration']),
      quantity: _asInt(json['quantity']),
      addons: addonsJson is List ? addonsJson : const <Object?>[],
    );
  }
}

class CartSlotModal {
  const CartSlotModal({required this.date, required this.time});

  final String? date;
  final String? time;

  factory CartSlotModal.fromJson(Map<String, dynamic> json) {
    return CartSlotModal(
      date: json['date']?.toString(),
      time: json['time']?.toString(),
    );
  }
}

class CartAddressModal {
  const CartAddressModal({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String label;
  final String address;
  final String city;
  final String pinCode;
  final double latitude;
  final double longitude;

  factory CartAddressModal.fromJson(Map<String, dynamic> json) {
    return CartAddressModal(
      id: _asInt(json['id']),
      label: json['label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pinCode: json['pinCode']?.toString() ?? '',
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
    );
  }
}

class CartPricingModal {
  const CartPricingModal({
    required this.itemTotal,
    required this.addonTotal,
    required this.discount,
    required this.platformFee,
    required this.gst,
    required this.total,
  });

  final int itemTotal;
  final int addonTotal;
  final int discount;
  final int platformFee;
  final int gst;
  final int total;

  factory CartPricingModal.fromJson(Map<String, dynamic> json) {
    return CartPricingModal(
      itemTotal: _asInt(json['itemTotal']),
      addonTotal: _asInt(json['addonTotal']),
      discount: _asInt(json['discount']),
      platformFee: _asInt(json['platformFee']),
      gst: _asInt(json['gst']),
      total: _asInt(json['total']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
