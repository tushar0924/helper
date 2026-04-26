import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../../auth/application/auth_provider.dart';
import '../application/category_provider.dart';
import '../../cart/application/cart_provider.dart';
import '../application/address_provider.dart';
import '../data/address_models.dart';
import '../../../routes/app_router.dart';
import 'profile_screen.dart';
import 'widgets/category_skeleton_grid.dart';
import 'widgets/most_booked_card.dart';
import 'widgets/offer_card.dart';
import 'widgets/service_tile.dart';

class HelperTabView extends ConsumerWidget {
  const HelperTabView({super.key});

  static final List<_MostBookedData> _mostBooked = <_MostBookedData>[
    _MostBookedData(
      title: 'Deep Cleaning',
      price: '₹499',
      rating: '4.8',
      imageUrl:
          'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=600',
    ),
    _MostBookedData(
      title: 'Hair Styling',
      price: '₹599',
      rating: '4.9',
      imageUrl:
          'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600',
    ),
    _MostBookedData(
      title: 'AC Service',
      price: '₹699',
      rating: '4.7',
      imageUrl:
          'https://images.unsplash.com/photo-1581093458791-9f3c3900df4b?w=600',
    ),
    _MostBookedData(
      title: 'Kitchen Deep Clean',
      price: '₹799',
      rating: '4.8',
      imageUrl:
          'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=600',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CategoryState>(categoryControllerProvider, (_, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppToast.error(next.errorMessage!);
      }
    });

    final categoryState = ref.watch(categoryControllerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0F2A47),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        children: [
          _TopHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CategoryGrid(categoryState: categoryState),
                  const SizedBox(height: 10),
                  const _OfferCarousel(),
                  const SizedBox(height: 12),
                  const Text(
                    'Most Booked',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 185,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _mostBooked.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = _mostBooked[index];
                        return MostBookedCard(
                          title: item.title,
                          price: item.price,
                          rating: item.rating,
                          imageUrl: item.imageUrl,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends ConsumerStatefulWidget {
  const _CategoryGrid({required this.categoryState});

  final CategoryState categoryState;

  @override
  ConsumerState<_CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends ConsumerState<_CategoryGrid> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryControllerProvider.notifier).loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categoryState.isLoading && widget.categoryState.items.isEmpty) {
      return const CategorySkeletonGrid(itemCount: 6);
    }

    final categories = widget.categoryState.items;
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No services available right now',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return GridView.builder(
      itemCount: categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final item = categories[index];
        return ServiceTile(
          title: item.name,
          imageUrl: item.imageUrl,
          background: _backgroundForIndex(index),
          onTap: () {
            Navigator.of(context).pushNamed(
              AppRouter.serviceDetail,
              arguments: {
                'categoryId': item.id,
                'title': item.name,
                'image': item.imageUrl,
              },
            );
          },
        );
      },
    );
  }
}

Color _backgroundForIndex(int index) {
  const palette = <Color>[
    Color(0xFFD5E1EF),
    Color(0xFFE3E7ED),
    Color(0xFFEEE7C3),
    Color(0xFFDEE2F2),
    Color(0xFFE9E9EA),
    Color(0xFFF0D4B0),
    Color(0xFFD8ECEC),
    Color(0xFFE8DDDB),
    Color(0xFFF0DBA7),
    Color(0xFFD9E4F2),
  ];

  return palette[index % palette.length];
}

class _OfferCarousel extends StatefulWidget {
  const _OfferCarousel();

  @override
  State<_OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends State<_OfferCarousel> {
  final ScrollController _offerController = ScrollController();

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  double _progress() {
    if (!_offerController.hasClients) {
      return 0;
    }

    final position = _offerController.position;
    if (!position.hasContentDimensions) {
      return 0;
    }

    final max = position.maxScrollExtent;
    if (max <= 0) {
      return 0;
    }

    return (position.pixels / max).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    const trackWidth = 58.0;
    const thumbWidth = 20.0;

    return Column(
      children: [
        SizedBox(
          height: 84,
          child: ListView.separated(
            controller: _offerController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return OfferCard(
                title: '20% off on first booking',
                code: 'FIRST20',
                gradient: index == 0
                    ? const [Color(0xFF22BDF2), Color(0xFF0FA4DC)]
                    : const [Color(0xFF0F294A), Color(0xFF0B203D)],
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: trackWidth,
          height: 4,
          child: Stack(
            children: [
              Container(
                width: trackWidth,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCFD3D8),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              AnimatedBuilder(
                animation: _offerController,
                builder: (context, child) {
                  final left = (trackWidth - thumbWidth) * _progress();
                  return Positioned(left: left, child: child!);
                },
                child: Container(
                  width: thumbWidth,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0D10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopHeader extends ConsumerStatefulWidget {
  const _TopHeader();

  @override
  ConsumerState<_TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends ConsumerState<_TopHeader> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cartProvider.notifier).loadSummary();
    });
  }

  Future<void> _onChangeAddressTap() async {
    final selectedAddress = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _HomeAddressSelectionBottomSheet(
        currentAddressId: ref.read(cartProvider).summary?.address?.id,
      ),
    );

    if (!mounted || selectedAddress == null) {
      return;
    }

    await ref
        .read(cartProvider.notifier)
        .updateAddress(addressId: selectedAddress.id);

    if (!mounted) {
      return;
    }

    final state = ref.read(cartProvider);
    if (state.errorMessage == null || state.errorMessage!.isEmpty) {
      AppToast.success('Address updated successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final cartState = ref.watch(cartProvider);
    final cartSummary = cartState.summary;
    final cartCount = cartSummary?.items.length ?? 0;
    final selectedAddress = cartSummary?.address;
    final fullNameFuture = ref.read(sessionManagerProvider).fullName;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 18),
      decoration: const BoxDecoration(
        color: Color(0xFF0F2A47),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: Color(0xFFE8EEF6), width: 1),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FutureBuilder<String?>(
                  future: fullNameFuture,
                  builder: (context, snapshot) {
                    final name = snapshot.data?.trim().isNotEmpty == true
                        ? snapshot.data!.trim()
                        : 'Parul';

                    return InkWell(
                      onTap: cartState.isMutating ? null : _onChangeAddressTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello $name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedAddress != null
                                ? '${selectedAddress.address}, ${selectedAddress.city} - ${selectedAddress.pinCode}'
                                : 'Select service address',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB5C5D5),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () {
                            ref
                                .read(cartProvider.notifier)
                                .loadSummary(forceRefresh: true);
                            Navigator.of(context).pushNamed(AppRouter.cart);
                          },
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        if (cartCount > 0)
                          Positioned(
                            right: 3,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D09C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$cartCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.person,
                        size: 22,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                const Icon(Icons.search, size: 21, color: Color(0xFF8796A5)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Search services...',
                    style: TextStyle(
                      color: Color(0xFF97A3AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  height: 28,
                  width: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11C5BB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MostBookedData {
  const _MostBookedData({
    required this.title,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  final String title;
  final String price;
  final String rating;
  final String imageUrl;
}

class _HomeAddressSelectionBottomSheet extends ConsumerStatefulWidget {
  const _HomeAddressSelectionBottomSheet({this.currentAddressId});

  final int? currentAddressId;

  @override
  ConsumerState<_HomeAddressSelectionBottomSheet> createState() =>
      _HomeAddressSelectionBottomSheetState();
}

class _HomeAddressSelectionBottomSheetState
    extends ConsumerState<_HomeAddressSelectionBottomSheet> {
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
      if (!mounted) {
        return;
      }

      final fallbackId = response.addresses.isNotEmpty
          ? response.addresses.first.id
          : null;
      final currentId = _selectedAddressId;
      final hasCurrentId =
          currentId != null &&
          response.addresses.any((item) => item.id == currentId);

      setState(() {
        _addresses = response.addresses;
        if (!hasCurrentId) {
          _selectedAddressId = fallbackId;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _saveSelection() {
    final selectedId = _selectedAddressId;
    if (selectedId == null || _isSaving || _addresses.isEmpty) {
      return;
    }

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
            const Text(
              'Select Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
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
                                if (value == null) {
                                  return;
                                }
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
