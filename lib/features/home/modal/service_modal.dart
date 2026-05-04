class ServiceModal {
  const ServiceModal({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.duration,
    required this.rating,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String description;
  final int originalPrice;
  final int price;
  final int duration;
  final double rating;
  final String imageUrl;

  factory ServiceModal.fromJson(Map<String, dynamic> json) {
    return ServiceModal(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
        originalPrice: _asInt(json['originalPrice']),
      price: _asInt(json['price']),
      duration: _asInt(json['duration']),
      rating: _asDouble(json['rating']),
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

      int get payablePrice => price > 0 ? price : originalPrice;

      int get displayOriginalPrice =>
        originalPrice > 0 ? originalPrice : (price > 0 ? price : 0);

      bool get hasDiscount =>
        originalPrice > 0 && price > 0 && originalPrice != price;

      String get formattedOriginalPrice => '₹$displayOriginalPrice';

      String get formattedPayablePrice => '₹$payablePrice';

      String get formattedPrice => formattedPayablePrice;

  String get formattedDuration {
    if (duration <= 0) {
      return 'N/A';
    }
    return duration == 1 ? '1 hr' : '$duration hrs';
  }

  String get safeDescription {
    if (description.trim().isEmpty) {
      return 'Professional service by trained experts';
    }
    return description;
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
