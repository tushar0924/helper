import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/application/address_provider.dart';
import '../../home/data/address_models.dart';

class AddressSelectionBottomSheet extends ConsumerStatefulWidget {
  const AddressSelectionBottomSheet({
    this.currentAddressId,
    this.onAddNewAddress,
    this.title = 'Select Service Address',
    this.showAddNew = true,
  });

  final int? currentAddressId;
  final Future<void> Function()? onAddNewAddress;
  final String title;
  final bool showAddNew;

  @override
  ConsumerState<AddressSelectionBottomSheet> createState() =>
      _AddressSelectionBottomSheetState();
}

class _AddressSelectionBottomSheetState
    extends ConsumerState<AddressSelectionBottomSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<SavedAddress> _addresses = const <SavedAddress>[];
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _selectedAddressId = widget.currentAddressId;
    Future.microtask(_loadAddresses);
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ref.read(addressRepositoryProvider).getAddresses();
      if (!mounted) return;

      final fallbackId = response.addresses.isNotEmpty
          ? response.addresses.first.id
          : null;
      final currentId = _selectedAddressId;
      final hasCurrentId =
          currentId != null && response.addresses.any((item) => item.id == currentId);

      setState(() {
        _addresses = response.addresses;
        if (!hasCurrentId) {
          _selectedAddressId = fallbackId;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _saveSelection() {
    final selectedId = _selectedAddressId;
    if (selectedId == null || _isSaving || _addresses.isEmpty) return;

    final selectedAddress = _addresses.firstWhere(
      (address) => address.id == selectedId,
      orElse: () => _addresses.first,
    );

    setState(() {
      _isSaving = true;
    });
    Navigator.of(context).pop(selectedAddress);
  }

  @override
  Widget build(BuildContext context) {
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
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.showAddNew && widget.onAddNewAddress != null)
              InkWell(
                onTap: () async {
                  Navigator.of(context).pop();
                  await widget.onAddNewAddress!.call();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(Icons.add, size: 20, color: Color(0xFF0B1F3A)),
                      SizedBox(width: 8),
                      Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0B1F3A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Failed to load addresses.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No saved addresses found. Please add an address from Profile > Addresses.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _addresses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    final isSelected = address.id == _selectedAddressId;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAddressId = address.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0B1F3A)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Radio<int>(
                              value: address.id,
                              groupValue: _selectedAddressId,
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  _selectedAddressId = value;
                                });
                              },
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    address.label,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
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
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _addresses.isEmpty || _selectedAddressId == null
                    ? null
                    : _saveSelection,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Save Address'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
