import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/utils/app_toast.dart';
import '../data/address_models.dart';
import '../data/google_maps_service.dart';
import 'edit_address_screen.dart';

class AddressLocationPickerScreen extends ConsumerStatefulWidget {
  const AddressLocationPickerScreen({super.key});

  @override
  ConsumerState<AddressLocationPickerScreen> createState() =>
      _AddressLocationPickerScreenState();
}

class _AddressLocationPickerScreenState
    extends ConsumerState<AddressLocationPickerScreen> {
  static const LatLng _fallbackLocation = LatLng(26.9124, 75.7873);

  final GoogleMapsService _mapsService = GoogleMapsService();

  GoogleMapController? _mapController;
  AddressDraft _draft = const AddressDraft(
    formattedAddress: 'Loading location...',
    city: '',
    pinCode: '',
    latitude: 26.9124,
    longitude: 75.7873,
  );
  bool _isLoadingLocation = true;
  bool _showMyLocation = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_initializeLocation);
  }

  @override
  void dispose() {
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
    try {
      final draft = await _mapsService.reverseGeocode(position);
      if (!mounted) {
        return;
      }

      setState(() {
        _draft = draft;
      });

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
      });
      AppToast.error(error.toString());
    }
  }

  Future<void> _openSearchSheet() async {
    final selected = await showModalBottomSheet<AddressDraft>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LocationSearchSheet(service: _mapsService),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _draft = selected;
    });

    final position = LatLng(selected.latitude, selected.longitude);
    if (_mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  Future<void> _openEditAddress() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => EditAddressScreen(initialDraft: _draft),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result != null) {
      Navigator.of(context).pop(result);
    }
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
                target: LatLng(_draft.latitude, _draft.longitude),
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              myLocationEnabled: _showMyLocation,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              markers: <Marker>{
                Marker(
                  markerId: const MarkerId('selected-location'),
                  position: LatLng(_draft.latitude, _draft.longitude),
                  draggable: true,
                  onDragEnd: (position) => _setSelectedPosition(position),
                ),
              },
              onTap: (position) => _setSelectedPosition(position),
            ),
          ),
          Positioned(
            top: 16,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: GestureDetector(
                onTap: _openSearchSheet,
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
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
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Color(0xFF94A3B8)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search for new area or locality...',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                              color: Color(0xFF16A34A),
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
                                : _openEditAddress,
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

class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({required this.service});

  final GoogleMapsService service;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<PlaceSuggestion> _suggestions = const <PlaceSuggestion>[];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.length < 2) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const <PlaceSuggestion>[];
        _loading = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final suggestions = await widget.service.autocomplete(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = suggestions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _suggestions = const <PlaceSuggestion>[];
        _loading = false;
      });
      AppToast.error(error.toString());
    }
  }

  Future<void> _onChanged(String value) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _search(value);
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    try {
      final draft = await widget.service.placeDetails(suggestion.placeId);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(draft);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: TextField(
                  controller: _controller,
                  onChanged: _onChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for new area or locality...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _suggestions = const <PlaceSuggestion>[];
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              SizedBox(
                height: 360,
                child: _suggestions.isEmpty
                    ? const Center(
                        child: Text(
                          'Type to search an address in Google Maps',
                          style: TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final suggestion = _suggestions[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.place,
                              color: Color(0xFF16A34A),
                            ),
                            title: Text(
                              suggestion.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectSuggestion(suggestion),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
