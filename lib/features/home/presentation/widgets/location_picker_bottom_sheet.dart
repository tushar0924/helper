import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import '../../../../app/utils/app_toast.dart';
import '../../../home/application/address_provider.dart';
import '../../../home/application/home_bootstrap_provider.dart';
import '../../../home/data/address_models.dart';
import '../../../home/presentation/address_location_picker_screen.dart';
import '../../../home/presentation/saved_addresses_screen.dart';

class LocationPickerBottomSheet extends ConsumerStatefulWidget {
  const LocationPickerBottomSheet({super.key});

  @override
  ConsumerState<LocationPickerBottomSheet> createState() =>
      _LocationPickerBottomSheetState();
}

class _LocationPickerBottomSheetState
    extends ConsumerState<LocationPickerBottomSheet> {
  static const int _inlineSavedAddressLimit = 2;

  bool _loadingAddresses = true;
  bool _savingSelection = false;
  bool _isSavingCurrentLocation = false;
  int? _savingAddressId;
  String? _errorMessage;
  List<SavedAddress> _addresses = const <SavedAddress>[];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAddresses);
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
      _errorMessage = null;
    });

    try {
      final response = await ref.read(addressRepositoryProvider).getAddresses();
      if (!mounted) {
        return;
      }

      setState(() {
        _addresses = response.addresses;
        _loadingAddresses = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _loadingAddresses = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_savingSelection) {
      return;
    }

    setState(() {
      _savingSelection = true;
      _isSavingCurrentLocation = true;
      _savingAddressId = null;
    });

    try {
      await ref.read(homeBootstrapProvider.notifier).applyCurrentLocation();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _savingSelection = false;
          _isSavingCurrentLocation = false;
        });
      }
    }
  }

  Future<void> _useSavedAddress(SavedAddress address) async {
    if (_savingSelection) {
      return;
    }

    setState(() {
      _savingSelection = true;
      _savingAddressId = address.id;
      _isSavingCurrentLocation = false;
    });

    try {
      await ref.read(homeBootstrapProvider.notifier).applySavedAddress(address);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(address);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _savingSelection = false;
          _savingAddressId = null;
        });
      }
    }
  }

  Future<void> _searchManualLocation() async {
    if (_savingSelection) {
      return;
    }

    final draft = await Navigator.of(context).push<AddressDraft>(
      MaterialPageRoute<AddressDraft>(
        builder: (_) => const AddressLocationPickerScreen(),
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    setState(() {
      _savingSelection = true;
      _isSavingCurrentLocation = false;
      _savingAddressId = null;
    });

    try {
      await ref.read(homeBootstrapProvider.notifier).applyManualDraft(draft);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppToast.error(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _savingSelection = false;
          _savingAddressId = null;
        });
      }
    }
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();

    if (!mounted) {
      return;
    }

    for (var attempt = 0; attempt < 3; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) {
        return;
      }

      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) {
        return;
      }

      if (enabled) {
        await ref.read(homeBootstrapProvider.notifier).loadInitialLocation();
        return;
      }
    }

    await ref.read(homeBootstrapProvider.notifier).loadInitialLocation();
  }

  Future<void> _openSavedAddresses() async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SavedAddressesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeBootstrapProvider);
    final locationIssueMessage = homeState.locationIssueMessage;
    final currentLocationText =
      locationIssueMessage ??
      (homeState.locationLine?.trim().isNotEmpty == true
        ? homeState.locationLine!.trim()
        : 'Use your current GPS location');
    final currentLabel =
      locationIssueMessage != null
      ? 'Location is off'
      : (homeState.selectedLocationSource ==
            SelectedLocationSource.currentLocation
          ? 'Current location selected'
          : 'Use current location');
    final inlineAddresses = _addresses.take(_inlineSavedAddressLimit).toList();
    final hasMoreSavedAddresses = _addresses.length > inlineAddresses.length;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Select delivery location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose your current location or one of your saved addresses.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (locationIssueMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6EA6FF), Color(0xFF5A8DED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Location Permission is Off',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            locationIssueMessage,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF8FAFC),
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: _openLocationSettings,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4F7DDA),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'GRANT',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (locationIssueMessage != null) const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.my_location,
              iconBackground: const Color(0xFFE8F2FF),
              title: currentLabel,
              subtitle: currentLocationText,
              trailing:
                  _savingSelection && _isSavingCurrentLocation
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: locationIssueMessage != null
                  ? _openLocationSettings
                  : _useCurrentLocation,
            ),
            const SizedBox(height: 12),
            _ActionCard(
              icon: Icons.map_outlined,
              iconBackground: const Color(0xFFF2E8FF),
              title: 'Search on map',
              subtitle: 'Search any area or address manually',
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: _searchManualLocation,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Saved addresses',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openSavedAddresses,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF97316),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    hasMoreSavedAddresses ? 'View all' : 'Manage',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loadingAddresses)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Failed to load saved addresses.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _loadAddresses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_addresses.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: const Text(
                  'No saved addresses found. Add one from your profile or choose map search.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: inlineAddresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final address = inlineAddresses[index];
                    final isSavingThisAddress = _savingAddressId == address.id;
                    return InkWell(
                      onTap: _savingSelection
                          ? null
                          : () => _useSavedAddress(address),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                address.label.toLowerCase() == 'home'
                                    ? Icons.home_outlined
                                    : Icons.location_on_outlined,
                                color: const Color(0xFF0B1F3A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          address.label,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      if (isSavingThisAddress)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${address.address}, ${address.city} - ${address.pinCode}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
