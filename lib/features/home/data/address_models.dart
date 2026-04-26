class PlaceSuggestion {
  const PlaceSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

class AddressDraft {
  const AddressDraft({
    required this.formattedAddress,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    this.label = 'Home',
    this.receiverName = '',
    this.phoneNumber = '',
    this.buildingFloor = '',
    this.streetAddress = '',
    this.areaLocality = '',
  });

  factory AddressDraft.fromSavedAddress({
    required String label,
    required String address,
    required String city,
    required String pinCode,
    required double latitude,
    required double longitude,
    String receiverName = '',
    String phoneNumber = '',
  }) {
    final parsed = _parseStoredAddress(address);
    final fallbackAddress = address.trim().isNotEmpty
        ? address.trim()
        : <String>[
            if (city.trim().isNotEmpty) city.trim(),
            if (pinCode.trim().isNotEmpty) pinCode.trim(),
          ].join(', ');

    return AddressDraft(
      formattedAddress: fallbackAddress,
      city: city,
      pinCode: pinCode,
      latitude: latitude,
      longitude: longitude,
      label: label.isEmpty ? 'Home' : label,
      receiverName: receiverName,
      phoneNumber: phoneNumber,
      buildingFloor: parsed.buildingFloor,
      streetAddress: parsed.streetAddress,
      areaLocality: parsed.areaLocality,
    );
  }

  final String formattedAddress;
  final String city;
  final String pinCode;
  final double latitude;
  final double longitude;
  final String label;
  final String receiverName;
  final String phoneNumber;
  final String buildingFloor;
  final String streetAddress;
  final String areaLocality;

  String get addressForApi {
    final parts = <String>[
      buildingFloor,
      streetAddress,
      areaLocality.isNotEmpty ? areaLocality : formattedAddress,
    ];

    return parts.where((part) => part.trim().isNotEmpty).join(', ');
  }

  AddressDraft copyWith({
    String? formattedAddress,
    String? city,
    String? pinCode,
    double? latitude,
    double? longitude,
    String? label,
    String? receiverName,
    String? phoneNumber,
    String? buildingFloor,
    String? streetAddress,
    String? areaLocality,
  }) {
    return AddressDraft(
      formattedAddress: formattedAddress ?? this.formattedAddress,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      label: label ?? this.label,
      receiverName: receiverName ?? this.receiverName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      buildingFloor: buildingFloor ?? this.buildingFloor,
      streetAddress: streetAddress ?? this.streetAddress,
      areaLocality: areaLocality ?? this.areaLocality,
    );
  }

  Map<String, dynamic> toApiBody() {
    return <String, dynamic>{
      'address': addressForApi,
      'city': city,
      'pinCode': pinCode,
      'latitude': latitude,
      'longitude': longitude,
      'label': label,
    };
  }
}

class SavedAddressResponse {
  const SavedAddressResponse({required this.success, this.data});

  final bool success;
  final SavedAddressData? data;

  factory SavedAddressResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return SavedAddressResponse(
      success: json['success'] == true,
      data: dataJson is Map<String, dynamic>
          ? SavedAddressData.fromJson(dataJson)
          : null,
    );
  }
}

class SavedAddressData {
  const SavedAddressData({
    required this.id,
    required this.userId,
    required this.label,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String label;
  final String address;
  final String city;
  final String pinCode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime? createdAt;

  factory SavedAddressData.fromJson(Map<String, dynamic> json) {
    return SavedAddressData(
      id: _parseInt(json['id']),
      userId: _parseInt(json['userId']),
      label: json['label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pinCode: json['pinCode']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isDefault: json['isDefault'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  AddressDraft toDraft() {
    return AddressDraft.fromSavedAddress(
      label: label,
      address: address,
      city: city,
      pinCode: pinCode,
      latitude: latitude,
      longitude: longitude,
    );
  }

  SavedAddress toSavedAddress() {
    return SavedAddress(
      id: id,
      label: label,
      address: address,
      city: city,
      pinCode: pinCode,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      createdAt: createdAt,
    );
  }
}

int _parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _parseDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.city,
    required this.pinCode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  final int id;
  final String label;
  final String address;
  final String city;
  final String pinCode;
  final double latitude;
  final double longitude;
  final bool isDefault;
  final DateTime? createdAt;

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      id: _parseInt(json['id']),
      label: json['label']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      pinCode: json['pinCode']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      isDefault: json['isDefault'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }

  AddressDraft toDraft() {
    return AddressDraft.fromSavedAddress(
      label: label,
      address: address,
      city: city,
      pinCode: pinCode,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class GetAddressesResponse {
  const GetAddressesResponse({
    required this.success,
    required this.addresses,
    this.defaultAddress,
  });

  final bool success;
  final List<SavedAddress> addresses;
  final SavedAddress? defaultAddress;

  factory GetAddressesResponse.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    if (dataJson is! Map<String, dynamic>) {
      return const GetAddressesResponse(success: false, addresses: []);
    }

    final addressesJson = dataJson['addresses'];
    final addresses = <SavedAddress>[];
    if (addressesJson is List) {
      for (final item in addressesJson) {
        if (item is Map<String, dynamic>) {
          addresses.add(SavedAddress.fromJson(item));
        }
      }
    }

    final defaultAddressJson = dataJson['defaultAddress'];
    SavedAddress? defaultAddress;
    if (defaultAddressJson is Map<String, dynamic>) {
      defaultAddress = SavedAddress.fromJson(defaultAddressJson);
    }

    return GetAddressesResponse(
      success: json['success'] == true,
      addresses: addresses,
      defaultAddress: defaultAddress,
    );
  }
}

class _ParsedStoredAddress {
  const _ParsedStoredAddress({
    required this.buildingFloor,
    required this.streetAddress,
    required this.areaLocality,
  });

  final String buildingFloor;
  final String streetAddress;
  final String areaLocality;
}

_ParsedStoredAddress _parseStoredAddress(String address) {
  final parts = address
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return const _ParsedStoredAddress(
      buildingFloor: '',
      streetAddress: '',
      areaLocality: '',
    );
  }

  if (parts.length == 1) {
    return _ParsedStoredAddress(
      buildingFloor: '',
      streetAddress: '',
      areaLocality: parts.first,
    );
  }

  if (parts.length == 2) {
    return _ParsedStoredAddress(
      buildingFloor: parts.first,
      streetAddress: '',
      areaLocality: parts.last,
    );
  }

  return _ParsedStoredAddress(
    buildingFloor: parts.first,
    streetAddress: parts[1],
    areaLocality: parts.sublist(2).join(', '),
  );
}
