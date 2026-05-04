class BannerModal {
  const BannerModal({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    required this.title,
    required this.subtitle,
    required this.isClickable,
    required this.redirect,
  });

  final int id;
  final String mediaUrl;
  final String mediaType;
  final String title;
  final String subtitle;
  final bool isClickable;
  final BannerRedirectModal redirect;

  factory BannerModal.fromJson(Map<String, dynamic> json) {
    final redirectJson = json['redirect'];
    return BannerModal(
      id: _asInt(json['id']),
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      isClickable: json['isClickable'] == true,
      redirect: redirectJson is Map<String, dynamic>
          ? BannerRedirectModal.fromJson(redirectJson)
          : const BannerRedirectModal(type: 'NONE', id: null, slug: ''),
    );
  }
}

class BannerRedirectModal {
  const BannerRedirectModal({
    required this.type,
    required this.id,
    required this.slug,
  });

  final String type;
  final int? id;
  final String slug;

  factory BannerRedirectModal.fromJson(Map<String, dynamic> json) {
    final id = _nullableInt(json['id']);
    return BannerRedirectModal(
      type: json['type']?.toString() ?? 'NONE',
      id: id,
      slug: json['slug']?.toString() ?? '',
    );
  }
}

int _asInt(Object? value) {
  return _nullableInt(value) ?? 0;
}

int? _nullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}
