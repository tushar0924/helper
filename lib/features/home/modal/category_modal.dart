class CategoryModal {
  const CategoryModal({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.displayOrder,
  });

  final int id;
  final String name;
  final String imageUrl;
  final int displayOrder;

  factory CategoryModal.fromJson(Map<String, dynamic> json) {
    return CategoryModal(
      id: _asInt(json['id']),
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      displayOrder: _asInt(json['displayOrder']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}
