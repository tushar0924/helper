import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../../auth/application/auth_provider.dart';
import '../application/category_provider.dart';
import '../application/home_bootstrap_provider.dart';
import '../../cart/application/cart_provider.dart';
import '../data/address_models.dart';
import '../../../routes/app_router.dart';
import 'profile_screen.dart';
import 'widgets/category_skeleton_grid.dart';
import 'saved_addresses_screen.dart';
import '../../shared/widgets/address_selection_bottom_sheet.dart';
import 'widgets/most_booked_card.dart';
import 'widgets/offer_card.dart';
import 'widgets/service_tile.dart';

class HelperTabView extends ConsumerStatefulWidget {
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
  ConsumerState<HelperTabView> createState() => _HelperTabViewState();
}

class _HelperTabViewState extends ConsumerState<HelperTabView> {
  bool _isNotifySubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(homeBootstrapProvider.notifier).loadForCurrentLocation();
    });
  }

  Future<void> _onChangeLocationTap() async {
    final selectedAddress = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddressSelectionBottomSheet(
        currentAddressId: ref.read(cartProvider).summary?.address?.id,
        onAddNewAddress: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SavedAddressesScreen(),
            ),
          );
        },
      ),
    );

    if (!mounted || selectedAddress == null) {
      return;
    }

    await ref
        .read(cartProvider.notifier)
        .updateAddress(addressId: selectedAddress.id);

    final pincode = selectedAddress.pinCode.replaceAll(RegExp(r'[^0-9]'), '');
    await ref.read(homeBootstrapProvider.notifier).loadForPincode(
      pincode: pincode,
      locationLine:
          '${selectedAddress.address}, ${selectedAddress.city} - ${selectedAddress.pinCode}',
    );
  }

  Future<void> _onNotifyMeTap() async {
    if (_isNotifySubmitting) {
      return;
    }

    final pincode = ref.read(homeBootstrapProvider).pincode?.trim() ?? '';
    if (pincode.isEmpty) {
      AppToast.error('Pincode unavailable. Please change location.');
      return;
    }

    final sessionData = await ref.read(sessionManagerProvider).getSessionData();
    final rawUserId = sessionData['userId'];
    final userId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');

    setState(() {
      _isNotifySubmitting = true;
    });

    try {
      await ref.read(homeBootstrapRepositoryProvider).notifyServiceability(
        pincode: pincode,
        userId: userId,
      );
    } catch (_) {
      // ApiClient already shows toast for failures.
    } finally {
      if (mounted) {
        setState(() {
          _isNotifySubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CategoryState>(categoryControllerProvider, (_, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppToast.error(next.errorMessage!);
      }
    });

    ref.listen<HomeBootstrapState>(homeBootstrapProvider, (_, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppToast.error(next.errorMessage!);
      }
    });

    final categoryState = ref.watch(categoryControllerProvider);
    final homeBootstrapState = ref.watch(homeBootstrapProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF0F2A47),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Column(
        children: [
          _TopHeader(
            fallbackLocationLine: homeBootstrapState.locationLine,
            isFetchingCurrentLocation:
                homeBootstrapState.isLoading && !homeBootstrapState.hasLoaded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (homeBootstrapState.showComingSoon) ...[
                    _ServiceabilityCard(
                      isNotifyLoading: _isNotifySubmitting,
                      onNotifyTap: _onNotifyMeTap,
                      onChangeLocationTap: _onChangeLocationTap,
                    ),
                    const SizedBox(height: 14),
                  ],
                  const Text(
                    'Explore all Categories',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _CategoryGrid(categoryState: categoryState),
                  const SizedBox(height: 12),
                  const _OfferCarousel(),
                  const SizedBox(height: 10),
                  const Text(
                    'Most Booked',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 178,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: HelperTabView._mostBooked.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final item = HelperTabView._mostBooked[index];
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

class _ServiceabilityCard extends StatelessWidget {
  const _ServiceabilityCard({
    required this.isNotifyLoading,
    required this.onNotifyTap,
    required this.onChangeLocationTap,
  });

  final bool isNotifyLoading;
  final Future<void> Function() onNotifyTap;
  final Future<void> Function() onChangeLocationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Text(
            'We Are\nComing Soon',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'We are currently living in select area and expanding quickly. Get notified when we are near you !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF4B5563),
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 150,
            child: FilledButton(
              onPressed: isNotifyLoading
                  ? null
                  : () {
                      onNotifyTap();
                    },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B1F3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isNotifyLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Notify me'),
            ),
          ),
          TextButton(
            onPressed: () {
              onChangeLocationTap();
            },
            child: const Text(
              'Change location',
              style: TextStyle(
                color: Color(0xFF111827),
                fontSize: 13,
                decoration: TextDecoration.underline,
                decorationColor: Color(0xFF111827),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.86,
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
  const _TopHeader({
    this.fallbackLocationLine,
    this.isFetchingCurrentLocation = false,
  });

  final String? fallbackLocationLine;
  final bool isFetchingCurrentLocation;

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
      builder: (_) => AddressSelectionBottomSheet(
        currentAddressId: ref.read(cartProvider).summary?.address?.id,
        onAddNewAddress: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SavedAddressesScreen(),
            ),
          );
        },
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

    final pincode = selectedAddress.pinCode.replaceAll(RegExp(r'[^0-9]'), '');
    await ref.read(homeBootstrapProvider.notifier).loadForPincode(
      pincode: pincode,
      locationLine:
          '${selectedAddress.address}, ${selectedAddress.city} - ${selectedAddress.pinCode}',
    );
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
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.isFetchingCurrentLocation
                              ? 'Fetching current location...'
                              : ((widget.fallbackLocationLine
                                      ?.trim()
                                      .isNotEmpty ==
                                    true)
                                  ? widget.fallbackLocationLine!
                                  : (selectedAddress != null
                                    ? '${selectedAddress.address}, ${selectedAddress.city} - ${selectedAddress.pinCode}'
                                    : 'Select service address')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB5C5D5),
                              fontSize: 12.5,
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
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, size: 19, color: Color(0xFF8796A5)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Search services...',
                    style: TextStyle(
                      color: Color(0xFF97A3AF),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 24,
                  width: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF11C5BB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 14),
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


