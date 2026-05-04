import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../auth/application/auth_provider.dart';
import '../../../session/session_manager.dart';
import '../data/home_bootstrap_repository.dart';
import '../data/google_maps_service.dart';

class HomeBootstrapState {
  const HomeBootstrapState({
    this.isLoading = false,
    this.hasLoaded = false,
    this.showComingSoon = false,
    this.locationLine,
    this.city,
    this.pincode,
    this.errorMessage,
  });

  final bool isLoading;
  final bool hasLoaded;
  final bool showComingSoon;
  final String? locationLine;
  final String? city;
  final String? pincode;
  final String? errorMessage;

  HomeBootstrapState copyWith({
    bool? isLoading,
    bool? hasLoaded,
    bool? showComingSoon,
    String? locationLine,
    String? city,
    String? pincode,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeBootstrapState(
      isLoading: isLoading ?? this.isLoading,
      hasLoaded: hasLoaded ?? this.hasLoaded,
      showComingSoon: showComingSoon ?? this.showComingSoon,
      locationLine: locationLine ?? this.locationLine,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final homeBootstrapRepositoryProvider = Provider<HomeBootstrapRepository>((ref) {
  return HomeBootstrapRepository(ref.read(apiClientProvider));
});

final homeBootstrapProvider =
    StateNotifierProvider<HomeBootstrapController, HomeBootstrapState>((ref) {
      return HomeBootstrapController(
        ref.read(homeBootstrapRepositoryProvider),
        ref.read(sessionManagerProvider),
      );
    });

class HomeBootstrapController extends StateNotifier<HomeBootstrapState> {
  HomeBootstrapController(this._repository, this._sessionManager)
      : super(const HomeBootstrapState());

  final HomeBootstrapRepository _repository;
  final SessionManager _sessionManager;
  final GoogleMapsService _mapsService = GoogleMapsService();

  static const LatLng _fallbackLocation = LatLng(26.9124, 75.7873);

  Future<void> loadForCurrentLocation() async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final position = await _fetchCurrentLatLng();
      final draft = await _mapsService.reverseGeocode(position);
      final pincode = draft.pinCode.trim();
      final city = draft.city.trim();
      final locationLine = _buildLocationLine(
        formattedAddress: draft.formattedAddress,
        city: draft.city,
        pincode: pincode,
      );

      if (pincode.isEmpty) {
        await _sessionManager.setLocationComingSoon(false);
        state = state.copyWith(
          isLoading: false,
          hasLoaded: true,
          locationLine: locationLine,
          city: city,
          pincode: pincode,
          showComingSoon: false,
        );
        return;
      }

      final response = await _repository.getHomeByPincode(pincode);
      final showComingSoon = _extractComingSoon(response);
      await _sessionManager.setLocationComingSoon(showComingSoon);
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        locationLine: locationLine,
        city: city,
        pincode: pincode,
        showComingSoon: showComingSoon,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> loadForPincode({
    required String pincode,
    required String city,
    required String locationLine,
  }) async {
    final normalized = pincode.trim();
    if (normalized.isEmpty || state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      locationLine: locationLine,
      city: city.trim(),
      pincode: normalized,
      clearError: true,
    );

    try {
      final response = await _repository.getHomeByPincode(normalized);
      final showComingSoon = _extractComingSoon(response);
      await _sessionManager.setLocationComingSoon(showComingSoon);
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        showComingSoon: showComingSoon,
        city: city.trim(),
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        hasLoaded: true,
        errorMessage: error.toString(),
      );
    }
  }

  Future<LatLng> _fetchCurrentLatLng() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      return _fallbackLocation;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return _fallbackLocation;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  String _buildLocationLine({
    required String formattedAddress,
    required String city,
    required String pincode,
  }) {
    final formatted = formattedAddress.trim();
    if (formatted.isNotEmpty) {
      return formatted;
    }

    final cityText = city.trim();
    if (cityText.isNotEmpty && pincode.isNotEmpty) {
      return '$cityText - $pincode';
    }
    if (cityText.isNotEmpty) {
      return cityText;
    }
    return pincode;
  }

  bool _extractComingSoon(Map<String, dynamic> response) {
    final data = response['data'];
    final source = data is Map<String, dynamic> ? data : response;

    final comingSoon = _asBool(source['comingSoon']) ??
        _asBool(source['isComingSoon']) ??
        _asBool(source['showComingSoon']);
    if (comingSoon != null) {
      return comingSoon;
    }

    final serviceable = _asBool(source['serviceable']) ??
        _asBool(source['isServiceable']) ??
        _asBool(source['isAvailable']);
    if (serviceable != null) {
      return !serviceable;
    }

    final message =
        (source['message']?.toString() ?? response['message']?.toString() ?? '')
            .toLowerCase();
    return message.contains('coming soon') ||
        message.contains('not serviceable') ||
        message.contains('not available');
  }

  bool? _asBool(Object? value) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }

    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') {
      return true;
    }
    if (text == 'false' || text == '0' || text == 'no') {
      return false;
    }

    return null;
  }
}
