class ServiceModal {
  const ServiceModal({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.duration,
    required this.rating,
    required this.imageUrl,
  });

  final int id;
  final String name;
  final String description;
  final int price;
  final int duration;
  final double rating;
  final String imageUrl;

  factory ServiceModal.fromJson(Map<String, dynamic> json) {
    return ServiceModal(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _asInt(json['price']),
      duration: _asInt(json['duration']),
      rating: _asDouble(json['rating']),
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }

  String get formattedPrice => '₹$price';

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
