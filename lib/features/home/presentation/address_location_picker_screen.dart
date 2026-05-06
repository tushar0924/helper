import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/utils/app_toast.dart';
import '../application/home_bootstrap_provider.dart';
import '../data/address_models.dart';
import '../data/google_maps_service.dart';

class AddressLocationPickerScreen extends ConsumerStatefulWidget {
  const AddressLocationPickerScreen({super.key, this.initialDraft});

  final AddressDraft? initialDraft;

  @override
  ConsumerState<AddressLocationPickerScreen> createState() =>
      _AddressLocationPickerScreenState();
}

class _AddressLocationPickerScreenState
    extends ConsumerState<AddressLocationPickerScreen> {
  static const LatLng _fallbackLocation = LatLng(26.9124, 75.7873);

  final GoogleMapsService _mapsService = GoogleMapsService();
  final TextEditingController _searchController = TextEditingController();

  GoogleMapController? _mapController;
  late AddressDraft _draft;
  late LatLng _selectedPosition;
  bool _isLoadingLocation = true;
  bool _isUpdatingLocation = false;
  bool _isCheckingServiceability = false;
  bool? _isServiceAvailable;
  String? _serviceabilityPincode;
  bool _showMyLocation = false;
  bool _isSearching = false;
  bool _searchLoading = false;
  List<PlaceSuggestion> _searchSuggestions = const <PlaceSuggestion>[];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _draft =
        widget.initialDraft ??
        const AddressDraft(
          formattedAddress: 'Loading location...',
          city: '',
          pinCode: '',
          latitude: 26.9124,
          longitude: 75.7873,
        );
    _selectedPosition = LatLng(_draft.latitude, _draft.longitude);
    if (widget.initialDraft == null) {
      Future.microtask(_initializeLocation);
    } else {
      _isLoadingLocation = false;
      Future.microtask(() => _checkServiceability(_draft));
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    await _selectCurrentLocation(showErrors: false);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoadingLocation = false;
    });
  }

  Future<void> _selectCurrentLocation({bool showErrors = true}) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw StateError('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Location permission is required to use current location.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _showMyLocation = true;
      await _setSelectedPosition(
        LatLng(position.latitude, position.longitude),
        moveCamera: true,
      );
    } catch (error) {
      _showMyLocation = false;
      await _setSelectedPosition(_fallbackLocation, moveCamera: true);
      if (showErrors && mounted) {
        AppToast.error(error.toString());
      }
    }
  }

  Future<void> _setSelectedPosition(
    LatLng position, {
    bool moveCamera = false,
  }) async {
    _selectedPosition = position;

    try {
      if (mounted) {
        setState(() {
          _isUpdatingLocation = true;
        });
      } else {
        _isUpdatingLocation = true;
      }

      final draft = await _mapsService.reverseGeocode(position);
      if (!mounted) {
        return;
      }

      setState(() {
        _draft = draft;
        _selectedPosition = position;
        _isUpdatingLocation = false;
      });
      unawaited(_checkServiceability(draft));

      if (moveCamera && _mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLng(position));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _draft = AddressDraft(
          formattedAddress: 'Selected location',
          city: '',
          pinCode: '',
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _selectedPosition = position;
        _isUpdatingLocation = false;
        _isServiceAvailable = null;
        _serviceabilityPincode = null;
      });
      AppToast.error(error.toString());
    }
  }

  Future<void> _checkServiceability(AddressDraft draft) async {
    final pincode = draft.pinCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (pincode.isEmpty || pincode == _serviceabilityPincode) {
      return;
    }

    if (mounted) {
      setState(() {
        _isCheckingServiceability = true;
        _serviceabilityPincode = pincode;
        _isServiceAvailable = null;
      });
    }

    try {
      final response = await ref
          .read(homeBootstrapRepositoryProvider)
          .getHomeByPincode(pincode);
      final isAvailable = !_extractComingSoon(response);
      if (!mounted || _serviceabilityPincode != pincode) {
        return;
      }

      setState(() {
        _isCheckingServiceability = false;
        _isServiceAvailable = isAvailable;
      });
    } catch (_) {
      if (!mounted || _serviceabilityPincode != pincode) {
        return;
      }

      setState(() {
        _isCheckingServiceability = false;
        _isServiceAvailable = false;
      });
    }
  }

  void _confirmSelection() {
    Navigator.of(context).pop(_draft);
  }

  Future<void> _searchLocations(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchSuggestions = const <PlaceSuggestion>[];
        _searchLoading = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _searchLoading = true;
    });

    try {
      final suggestions = await _mapsService.autocomplete(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _searchSuggestions = suggestions;
        _searchLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchSuggestions = const <PlaceSuggestion>[];
        _searchLoading = false;
      });
      AppToast.error(error.toString());
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _isSearching = value.trim().isNotEmpty;
    });
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _searchLocations(value);
    });
  }

  Future<void> _selectSearchSuggestion(PlaceSuggestion suggestion) async {
    try {
      final selected = await _mapsService.placeDetails(suggestion.placeId);
      if (!mounted) {
        return;
      }

      setState(() {
        _draft = selected;
        _selectedPosition = LatLng(selected.latitude, selected.longitude);
        _searchController.text = suggestion.description;
        _searchSuggestions = const <PlaceSuggestion>[];
        _isSearching = false;
      });
      unawaited(_checkServiceability(selected));

      final position = LatLng(selected.latitude, selected.longitude);
      if (_mapController != null) {
        await _mapController!.animateCamera(CameraUpdate.newLatLng(position));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(error.toString());
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchSuggestions = const <PlaceSuggestion>[];
      _isSearching = false;
      _searchLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        titleSpacing: 0,
        title: const Text(
          'Select Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: _showMyLocation,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              markers: const <Marker>{},
              onCameraMove: (position) {
                _selectedPosition = position.target;
              },
              onCameraIdle: () => _setSelectedPosition(_selectedPosition),
              onTap: (LatLng position) => _setSelectedPosition(position),
            ),
          ),
          const Center(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search for new area or locality...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _searchController.text.trim().isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: _clearSearch,
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_isSearching ||
                      _searchLoading ||
                      _searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_searchLoading)
                            const LinearProgressIndicator(minHeight: 2),
                          if (_searchSuggestions.isEmpty && !_searchLoading)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Type to search an address in Google Maps',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            )
                          else
                            Flexible(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _searchSuggestions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final suggestion = _searchSuggestions[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.place,
                                      color: Color(0xFF16A34A),
                                    ),
                                    title: Text(
                                      suggestion.description,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    onTap: () =>
                                        _selectSearchSuggestion(suggestion),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton.icon(
                      onPressed: _selectCurrentLocation,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0B2A4A),
                        side: const BorderSide(color: Color(0xFFB8C3D1)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(Icons.my_location, size: 18),
                      label: const Text(
                        'Use Current Location',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ServiceabilityBanner(
                          isChecking: _isCheckingServiceability,
                          isAvailable: _isServiceAvailable,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Order will be delivered here',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 18,
                              color: Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _draft.formattedAddress,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF111827),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_draft.city}${_draft.pinCode.isNotEmpty ? ', ${_draft.pinCode}' : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: _isLoadingLocation
                                ? null
                                : _confirmSelection,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0B2A4A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Confirm & proceed',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isUpdatingLocation) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(minHeight: 2),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoadingLocation)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x10000000),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ServiceabilityBanner extends StatelessWidget {
  const _ServiceabilityBanner({
    required this.isChecking,
    required this.isAvailable,
  });

  final bool isChecking;
  final bool? isAvailable;

  @override
  Widget build(BuildContext context) {
    final available = isAvailable == true;
    final unavailable = isAvailable == false;
    final color = available
        ? const Color(0xFF86F5B2)
        : unavailable
        ? const Color(0xFFFFCDD2)
        : const Color(0xFFE5E7EB);
    final textColor = available
        ? const Color(0xFF065F46)
        : unavailable
        ? const Color(0xFFB91C1C)
        : const Color(0xFF475569);
    final text = isChecking
        ? 'Checking service availability...'
        : available
        ? 'Service is available in this area'
        : unavailable
        ? 'Service is not available in this area'
        : 'Select a location to check service availability';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          if (isChecking)
            const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF475569)),
              ),
            )
          else
            Icon(
              available ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: textColor,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _extractComingSoon(Map<String, dynamic> response) {
  final data = response['data'];
  final source = data is Map<String, dynamic> ? data : response;

  final comingSoon =
      _asBool(source['comingSoon']) ??
      _asBool(source['isComingSoon']) ??
      _asBool(source['showComingSoon']);
  if (comingSoon != null) {
    return comingSoon;
  }

  final serviceable =
      _asBool(source['serviceable']) ??
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
