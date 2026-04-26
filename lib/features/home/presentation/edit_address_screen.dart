import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../application/address_provider.dart';
import '../data/address_models.dart';
import '../../auth/application/auth_provider.dart';

class EditAddressScreen extends ConsumerStatefulWidget {
  const EditAddressScreen({
    super.key,
    required this.initialDraft,
    this.addressId,
  });

  final AddressDraft initialDraft;
  final int? addressId;

  @override
  ConsumerState<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _pinCodeController = TextEditingController();

  String _selectedLabel = 'Home';
  bool _useAccountDetails = false;
  bool _saving = false;
  String _accountName = '';
  String _accountPhone = '';

  bool get _isEditing => widget.addressId != null;

  @override
  void initState() {
    super.initState();
    _selectedLabel = widget.initialDraft.label;
    _receiverNameController.text = widget.initialDraft.receiverName;
    _phoneController.text = widget.initialDraft.phoneNumber;
    _buildingController.text = widget.initialDraft.buildingFloor;
    _streetController.text = widget.initialDraft.streetAddress;
    _areaController.text = widget.initialDraft.areaLocality.isNotEmpty
        ? widget.initialDraft.areaLocality
        : widget.initialDraft.formattedAddress;
    _pinCodeController.text = widget.initialDraft.pinCode;
    Future.microtask(_loadAccountDetails);
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _phoneController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAccountDetails() async {
    final session = await ref.read(sessionManagerProvider).getSessionData();
    if (!mounted) {
      return;
    }

    _accountName = session['fullName']?.toString() ?? '';
    _accountPhone = session['phone']?.toString() ?? '';

    if (_useAccountDetails) {
      _receiverNameController.text = _accountName;
      _phoneController.text = _accountPhone;
    }
  }

  Future<void> _saveAddress() async {
    if (_saving) {
      return;
    }

    final draft = widget.initialDraft.copyWith(
      label: _selectedLabel,
      receiverName: _receiverNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      buildingFloor: _buildingController.text.trim(),
      streetAddress: _streetController.text.trim(),
      areaLocality: _areaController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
    );

    setState(() {
      _saving = true;
    });

    try {
      final repository = ref.read(addressRepositoryProvider);
      final response = _isEditing
          ? await repository.updateAddress(
              addressId: widget.addressId!,
              draft: draft,
            )
          : await repository.saveAddress(draft);
      if (!mounted) {
        return;
      }

      setState(() {
        _saving = false;
      });

      if (!response.success) {
        AppToast.error('Unable to save address.');
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
      });
      AppToast.error(error.toString());
    }
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _chip(String label) {
    final selected = _selectedLabel == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedLabel = label),
      selectedColor: const Color(0xFFE5F2FF),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFF0B2A4A) : const Color(0xFF4B5563),
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF0B2A4A) : const Color(0xFFD1D5DB),
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B2A4A), width: 1.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        toolbarHeight: 64,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        titleSpacing: 0,
        title: Text(
          _isEditing ? 'Edit Address' : 'Add Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Receiver Details Section
            _sectionTitle('Receiver Details'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _useAccountDetails,
                    onChanged: (value) {
                      setState(() {
                        _useAccountDetails = value ?? false;
                        if (_useAccountDetails) {
                          _receiverNameController.text = _accountName;
                          _phoneController.text = _accountPhone;
                        }
                      });
                    },
                    title: const Text(
                      'Use my account details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _receiverNameController,
                    decoration: _fieldDecoration('Receiver name'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _fieldDecoration('Phone number').copyWith(
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_copy, size: 18),
                        onPressed: () {
                          AppToast.success('Phone number copied');
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Location Details Section
            _sectionTitle('Location Details'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save address as',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip('Home'),
                      _chip('Work'),
                      _chip('Hotel'),
                      _chip('Other'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Building / Floor',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _buildingController,
                    decoration: _fieldDecoration('44'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Street Address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _streetController,
                    decoration: _fieldDecoration('Street Address'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Area / Locality',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _areaController.text.isNotEmpty
                                ? _areaController.text
                                : widget.initialDraft.formattedAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.edit_location_alt_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'PIN Code',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pinCodeController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('PIN Code'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Save address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFF8FAFC),
                    ),
                    child: Text(
                      _selectedLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _saveAddress,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B2A4A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        _isEditing ? 'Save Address' : 'Add Address',
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
    );
  }
}
