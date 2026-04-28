import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../application/address_provider.dart';
import '../data/address_models.dart';
import '../../auth/application/auth_provider.dart';
import 'address_location_picker_screen.dart';

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
  final TextEditingController _fullAddressController = TextEditingController();
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
    _fullAddressController.text = widget.initialDraft.formattedAddress;
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
    _fullAddressController.dispose();
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
      formattedAddress: _fullAddressController.text.trim().isEmpty
          ? widget.initialDraft.formattedAddress
          : _fullAddressController.text.trim(),
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

  AddressDraft _buildCurrentDraft() {
    return widget.initialDraft.copyWith(
      label: _selectedLabel,
      receiverName: _receiverNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      buildingFloor: _buildingController.text.trim(),
      streetAddress: _streetController.text.trim(),
      areaLocality: _areaController.text.trim(),
      formattedAddress: _fullAddressController.text.trim().isEmpty
          ? widget.initialDraft.formattedAddress
          : _fullAddressController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
    );
  }

  void _applyDraft(AddressDraft draft) {
    setState(() {
      if (draft.label.isNotEmpty) {
        _selectedLabel = draft.label;
      }
      if (draft.receiverName.isNotEmpty) {
        _receiverNameController.text = draft.receiverName;
      }
      if (draft.phoneNumber.isNotEmpty) {
        _phoneController.text = draft.phoneNumber;
      }
      _buildingController.text = draft.buildingFloor;
      _streetController.text = draft.streetAddress;
      _areaController.text = draft.areaLocality.isNotEmpty
          ? draft.areaLocality
          : draft.formattedAddress;
      _fullAddressController.text = draft.addressForApi.isNotEmpty
          ? draft.addressForApi
          : draft.formattedAddress;
      _pinCodeController.text = draft.pinCode;
    });
  }

  Future<void> _openLocationPicker() async {
    final draft = await Navigator.of(context).push<AddressDraft>(
      MaterialPageRoute<AddressDraft>(
        builder: (_) =>
            AddressLocationPickerScreen(initialDraft: _buildCurrentDraft()),
      ),
    );

    if (!mounted || draft == null) {
      return;
    }

    _applyDraft(draft);
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
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
      selectedColor: const Color(0xFFDFF1FF),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: selected ? const Color(0xFF0B2A4A) : const Color(0xFF4B5563),
      ),
      side: BorderSide(
        color: selected ? const Color(0xFF0B2A4A) : const Color(0xFFD1D5DB),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
    );
  }

  InputDecoration _fieldDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildReceiverDetailsCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
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
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                activeColor: const Color(0xFF0B2A4A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 2),
              const Text(
                'Use my account details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _receiverNameController,
            decoration: _fieldDecoration('Receiver Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration("Receiver's number").copyWith(
              suffixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.contact_page_outlined,
                  size: 19,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetailsCard() {
    final previewText = _areaController.text.isNotEmpty
        ? _areaController.text
        : widget.initialDraft.formattedAddress;

    return _buildCard(
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
            decoration: _fieldDecoration('Enter Building / Floor address'),
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
            decoration: _fieldDecoration('Street (Recommended)'),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    previewText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 62,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _openLocationPicker,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Change',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Full Address',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _fullAddressController,
            decoration: _fieldDecoration('Enter Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _saving ? null : _saveAddress,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0B2A4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Add Address',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECECEC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2440),
        elevation: 0,
        toolbarHeight: 62,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
        ),
        titleSpacing: 0,
        title: const Text(
          'Add New Address',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Receiver Details'),
              _buildReceiverDetailsCard(),
              const SizedBox(height: 18),
              _sectionTitle('Location Details'),
              _buildLocationDetailsCard(),
              const SizedBox(height: 18),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }
}
