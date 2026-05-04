class ServiceDetailModal {
  const ServiceDetailModal({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.duration,
    required this.rating,
    required this.imageUrl,
    required this.included,
    required this.notIncluded,
    required this.requirements,
    required this.faqs,
  });

  final int id;
  final String name;
  final String? description;
  final int originalPrice;
  final int price;
  final int duration;
  final double rating;
  final String imageUrl;
  final List<String> included;
  final List<String> notIncluded;
  final List<String> requirements;
  final List<ServiceDetailFaqModal> faqs;

  factory ServiceDetailModal.fromJson(Map<String, dynamic> json) {
    return ServiceDetailModal(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      originalPrice: _asInt(json['originalPrice']),
      price: _asInt(json['price']),
      duration: _asInt(json['duration']),
      rating: _asDouble(json['rating']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      included: _asStringList(json['included']),
      notIncluded: _asStringList(json['notIncluded']),
      requirements: _asStringList(json['requirements']),
      faqs: _asFaqList(json['faqs']),
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
    final value = description?.trim() ?? '';
    if (value.isEmpty) {
      return 'Professional service by trained experts';
    }
    return value;
  }
}

class ServiceDetailFaqModal {
  const ServiceDetailFaqModal({required this.question, required this.answer});

  final String question;
  final String answer;

  factory ServiceDetailFaqModal.fromJson(Map<String, dynamic> json) {
    return ServiceDetailFaqModal(
      question: json['q']?.toString() ?? json['question']?.toString() ?? '',
      answer: json['a']?.toString() ?? json['answer']?.toString() ?? '',
    );
  }
}

List<String> _asStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .where((item) => item != null)
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

List<ServiceDetailFaqModal> _asFaqList(Object? value) {
  if (value is! List) {
    return const <ServiceDetailFaqModal>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) =>
            ServiceDetailFaqModal.fromJson(Map<String, dynamic>.from(item)),
      )
      .where((item) => item.question.trim().isNotEmpty)
      .toList(growable: false);
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
