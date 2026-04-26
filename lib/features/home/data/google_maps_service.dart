import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import 'address_models.dart';

class GoogleMapsService {
  GoogleMapsService({http.Client? client}) : _client = client ?? http.Client();

  static const String apiKey = 'AIzaSyDoZLkd9Mn8KBms9KSw9PlEwGZYNTo938U';

  final http.Client _client;

  Future<List<PlaceSuggestion>> autocomplete(String input) async {
    final query = input.trim();
    if (query.length < 2) {
      return const <PlaceSuggestion>[];
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      <String, String>{
        'input': query,
        'components': 'country:in',
        'language': 'en',
        'key': apiKey,
      },
    );

    final json = await _getJson(uri);
    final predictions = json['predictions'];
    if (predictions is! List) {
      return const <PlaceSuggestion>[];
    }

    return predictions
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => PlaceSuggestion(
            placeId: item['place_id']?.toString() ?? '',
            description: item['description']?.toString() ?? '',
          ),
        )
        .where((item) => item.placeId.isNotEmpty && item.description.isNotEmpty)
        .toList();
  }

  Future<AddressDraft> reverseGeocode(LatLng position) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/geocode/json',
      <String, String>{
        'latlng': '${position.latitude},${position.longitude}',
        'language': 'en',
        'key': apiKey,
      },
    );

    return _parseLocationResponse(await _getJson(uri), position);
  }

  Future<AddressDraft> placeDetails(String placeId) async {
    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/details/json',
      <String, String>{
        'place_id': placeId,
        'fields': 'formatted_address,geometry,address_component',
        'language': 'en',
        'key': apiKey,
      },
    );

    final json = await _getJson(uri);
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      throw StateError('Unable to resolve selected address.');
    }

    final geometry = result['geometry'];
    final location = geometry is Map<String, dynamic>
        ? geometry['location']
        : null;
    final lat = location is Map<String, dynamic>
        ? _parseDouble(location['lat'])
        : 0.0;
    final lng = location is Map<String, dynamic>
        ? _parseDouble(location['lng'])
        : 0.0;
    final components = result['address_components'];

    return AddressDraft(
      formattedAddress: result['formatted_address']?.toString() ?? '',
      city: _extractCity(components),
      pinCode: _extractPostalCode(components),
      latitude: lat,
      longitude: lng,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Request failed with status ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final status = decoded['status']?.toString();
      if (status != null && status != 'OK' && status != 'ZERO_RESULTS') {
        final message = decoded['error_message']?.toString();
        throw StateError(message ?? 'Google Maps request failed: $status');
      }
      return decoded;
    }

    throw StateError('Unexpected response from Google Maps.');
  }

  AddressDraft _parseLocationResponse(
    Map<String, dynamic> json,
    LatLng position,
  ) {
    final results = json['results'];
    if (results is! List || results.isEmpty) {
      return AddressDraft(
        formattedAddress: 'Selected location',
        city: '',
        pinCode: '',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    final result = results.first;
    if (result is! Map<String, dynamic>) {
      return AddressDraft(
        formattedAddress: 'Selected location',
        city: '',
        pinCode: '',
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    final components = result['address_components'];
    return AddressDraft(
      formattedAddress:
          result['formatted_address']?.toString() ?? 'Selected location',
      city: _extractCity(components),
      pinCode: _extractPostalCode(components),
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  String _extractCity(Object? components) {
    if (components is! List) {
      return '';
    }

    for (final item in components) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final types = item['types'];
      final typeList = types is List
          ? types.map((value) => value.toString()).toList()
          : const <String>[];
      if (typeList.contains('locality') ||
          typeList.contains('administrative_area_level_2') ||
          typeList.contains('postal_town')) {
        return item['long_name']?.toString() ?? '';
      }
    }

    return '';
  }

  String _extractPostalCode(Object? components) {
    if (components is! List) {
      return '';
    }

    for (final item in components) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final types = item['types'];
      final typeList = types is List
          ? types.map((value) => value.toString()).toList()
          : const <String>[];
      if (typeList.contains('postal_code')) {
        return item['long_name']?.toString() ?? '';
      }
    }

    return '';
  }
}

double _parseDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is int) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0.0;
}
