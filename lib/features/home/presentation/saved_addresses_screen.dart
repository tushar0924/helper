import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../application/address_provider.dart';
import '../data/address_models.dart';
import 'address_location_picker_screen.dart';
import 'edit_address_screen.dart';
import 'widgets/delete_address_modal.dart';

class SavedAddressesScreen extends ConsumerStatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  ConsumerState<SavedAddressesScreen> createState() =>
      _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends ConsumerState<SavedAddressesScreen> {
  bool _isLoading = true;
  int? _editingAddressId;

  GetAddressesResponse? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadAddresses);
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ref.read(addressRepositoryProvider).getAddresses();
      if (!mounted) {
        return;
      }

      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddAddressFlow() async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (_) => const AddressLocationPickerScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result is AddressDraft) {
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => EditAddressScreen(initialDraft: result),
        ),
      );

      if (saved == true) {
        AppToast.success('Address saved successfully');
        await _loadAddresses();
      }
    }
  }

  Future<void> _openEditAddressFlow(SavedAddress address) async {
    try {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => EditAddressScreen(
            initialDraft: address.toDraft(),
            addressId: address.id,
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        await _loadAddresses();
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.error(error.toString());
    }
  }

  Future<void> _deleteAddress(SavedAddress address) async {
    final confirmed = await showDeleteAddressModal(
      context,
      onDelete: () async {
        await ref.read(addressRepositoryProvider).deleteAddress(address.id);
      },
    );

    if (!mounted) return;

    if (confirmed == true) {
      try {
        await _loadAddresses();
      } catch (error) {
        if (mounted) {
          AppToast.error(error.toString());
        }
      }
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
          'Saved Addresses',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error loading addresses',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadAddresses,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _openAddAddressFlow,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B2A4A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 22),
                      label: const Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_response?.addresses.isEmpty ?? true)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 48,
                            color: const Color(0xFFD1D5DB),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No addresses yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Add your first address to get started',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _response?.addresses.length ?? 0,
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final address = _response!.addresses[index];
                        final isDefault =
                            address.id == _response?.defaultAddress?.id;

                        return _AddressCard(
                          address: address,
                          isDefault: isDefault,
                          isEditLoading: _editingAddressId == address.id,
                          onEdit: () => _openEditAddressFlow(address),
                          onDelete: () => _deleteAddress(address),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.isEditLoading,
    this.isDeleteLoading = false,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedAddress address;
  final bool isDefault;
  final bool isEditLoading;
  final bool isDeleteLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getColorForLabel(
                    address.label,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIconForLabel(address.label),
                  size: 16,
                  color: _getColorForLabel(address.label),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (isDefault)
                      const Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address.address,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${address.city}, ${address.pinCode}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isEditLoading || isDeleteLoading ? null : onEdit,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0B2A4A),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: isEditLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined, size: 16),
                  label: Text(
                    isEditLoading ? 'Loading...' : 'Edit',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isEditLoading || isDeleteLoading ? null : onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: isDeleteLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outlined, size: 16),
                  label: Text(
                    isDeleteLoading ? 'Deleting...' : 'Delete',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home_outlined;
      case 'work':
        return Icons.business_outlined;
      case 'hotel':
        return Icons.hotel_outlined;
      default:
        return Icons.location_on_outlined;
    }
  }

  Color _getColorForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return const Color(0xFFFB923C);
      case 'work':
        return const Color(0xFF3B82F6);
      case 'hotel':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
