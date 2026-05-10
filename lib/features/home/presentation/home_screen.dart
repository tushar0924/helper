import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helper/app/utils/app_toast.dart';
import '../../auth/application/auth_provider.dart';
import '../application/banner_provider.dart';
import '../application/category_provider.dart';
import '../application/home_bootstrap_provider.dart';
import '../../cart/application/cart_provider.dart';
import '../../cart/application/coupon_provider.dart';
import '../modal/banner_modal.dart';
import '../modal/category_modal.dart';
import '../../../routes/app_router.dart';
import 'profile_screen.dart';
import 'widgets/category_skeleton_grid.dart';
import 'widgets/location_picker_bottom_sheet.dart';
import 'widgets/most_booked_card.dart';
import 'widgets/offer_card.dart';
import 'widgets/service_tile.dart';
import 'widgets/in_progress_bookings_widget.dart';

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

class _HelperTabViewState extends ConsumerState<HelperTabView>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isNotifySubmitting = false;
  bool _showPinnedSearch = false;
  String _categoryQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    Future.microtask(() {
      ref.invalidate(bannerProvider(null));
      ref.read(homeBootstrapProvider.notifier).loadInitialLocation();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshHomePage());
    }
  }

  String? _currentBannerCity() {
    final bootstrap = ref.read(homeBootstrapProvider);
    if (bootstrap.city?.trim().isNotEmpty == true) {
      return bootstrap.city!.trim();
    }

    final cartSummary = ref.read(cartProvider).summary;
    final selectedAddress = cartSummary?.address;
    return selectedAddress?.city.trim().isNotEmpty == true
        ? selectedAddress!.city.trim()
        : _cityFromLocationLine(bootstrap.locationLine);
  }

  void _handleScroll() {
    final shouldShow =
        _scrollController.hasClients && _scrollController.offset > 180;
    if (shouldShow == _showPinnedSearch) {
      return;
    }

    setState(() {
      _showPinnedSearch = shouldShow;
    });
  }

  Future<void> _refreshHomePage() async {
    await ref.read(homeBootstrapProvider.notifier).loadInitialLocation();
    await ref
        .read(categoryControllerProvider.notifier)
        .loadCategories(forceRefresh: true);
    await ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);

    final city = _currentBannerCity();
    try {
      final _ = await ref.refresh(bannerProvider(city).future);
    } catch (_) {
      // Banner failures are already surfaced by the UI state.
    }
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
      await ref
          .read(homeBootstrapRepositoryProvider)
          .notifyServiceability(pincode: pincode, userId: userId);
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

  Future<void> _onChangeLocationTap() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LocationPickerBottomSheet(),
    );
  }

  void _updateCategoryQuery(String value) {
    setState(() {
      _categoryQuery = value;
    });
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
      child: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              onRefresh: _refreshHomePage,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TopHeader(
                      fallbackLocationLine: homeBootstrapState.locationLine,
                      isFetchingCurrentLocation:
                          homeBootstrapState.isLoading &&
                          !homeBootstrapState.hasLoaded,
                      searchController: _searchController,
                      onSearchChanged: _updateCategoryQuery,
                    ),
                    Padding(
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
                          _CategoryGrid(
                            categoryState: categoryState,
                            searchQuery: _categoryQuery,
                          ),
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
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 10),
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
                          const InProgressBookingsWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: IgnorePointer(
              ignoring: !_showPinnedSearch,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showPinnedSearch ? 1 : 0,
                child: _PinnedSearchHeader(
                  cartCount: ref.watch(cartProvider).summary?.items.length ?? 0,
                  onCartTap: () {
                    ref
                        .read(cartProvider.notifier)
                        .loadSummary(forceRefresh: true);
                    Navigator.of(context).pushNamed(AppRouter.cart);
                  },
                  onProfileTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  searchController: _searchController,
                  onSearchChanged: _updateCategoryQuery,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedSearchHeader extends StatelessWidget {
  const _PinnedSearchHeader({
    required this.cartCount,
    required this.onCartTap,
    required this.onProfileTap,
    required this.searchController,
    required this.onSearchChanged,
  });

  final int cartCount;
  final VoidCallback onCartTap;
  final VoidCallback onProfileTap;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topInset + 8, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(Icons.mic, color: Color(0xFF0A2440), size: 16),
                  ),
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _HeaderCircleButton(
            icon: Icons.shopping_cart_outlined,
            onTap: onCartTap,
            badgeCount: cartCount,
          ),
          const SizedBox(width: 8),
          _HeaderCircleButton(icon: Icons.person, onTap: onProfileTap),
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
  const _CategoryGrid({required this.categoryState, required this.searchQuery});

  final CategoryState categoryState;
  final String searchQuery;

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

    final query = widget.searchQuery.trim().toLowerCase();
    final categories = query.isEmpty
        ? widget.categoryState.items
        : widget.categoryState.items
              .where((item) => item.name.toLowerCase().contains(query))
              .toList(growable: false);
    if (categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No matching categories found',
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

class _OfferCarousel extends ConsumerStatefulWidget {
  const _OfferCarousel();

  @override
  ConsumerState<_OfferCarousel> createState() => _OfferCarouselState();
}

class _OfferCarouselState extends ConsumerState<_OfferCarousel> {
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

    final couponAsync = ref.watch(availableCouponsProvider);

    return Column(
      children: [
        couponAsync.when(
          loading: () => SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => Container(
                width: 232,
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (data) {
            final coupons = data.coupons;
            if (coupons.isEmpty) {
              return const SizedBox.shrink();
            }

            return Column(
              children: [
                SizedBox(
                  height: 84,
                  child: ListView.separated(
                    controller: _offerController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final coupon = coupons[index];
                      final gradient = index % 2 == 0
                          ? const [Color(0xFF22BDF2), Color(0xFF0FA4DC)]
                          : const [Color(0xFF0F294A), Color(0xFF0B203D)];

                      return OfferCard(
                        title: coupon.title.isNotEmpty ? coupon.title : coupon.message,
                        code: coupon.code,
                        gradient: gradient,
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
          },
        ),
      ],
    );
  }
}

class _TopHeader extends ConsumerStatefulWidget {
  const _TopHeader({
    this.fallbackLocationLine,
    this.isFetchingCurrentLocation = false,
    required this.searchController,
    required this.onSearchChanged,
  });

  final String? fallbackLocationLine;
  final bool isFetchingCurrentLocation;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LocationPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final cartState = ref.watch(cartProvider);
    final cartSummary = cartState.summary;
    final cartCount = cartSummary?.items.length ?? 0;
    final selectedAddress = cartSummary?.address;
    final bannerCity = selectedAddress?.city.trim().isNotEmpty == true
        ? selectedAddress!.city.trim()
        : (ref.read(homeBootstrapProvider).city?.trim().isNotEmpty == true
              ? ref.read(homeBootstrapProvider).city!.trim()
              : _cityFromLocationLine(widget.fallbackLocationLine));
    final bannersAsync = ref.watch(bannerProvider(bannerCity));
    final categories = ref.watch(categoryControllerProvider).items;
    final fullNameFuture = ref.read(sessionManagerProvider).fullName;

    final locationLine = widget.isFetchingCurrentLocation
        ? 'Fetching current location...'
        : ((widget.fallbackLocationLine?.trim().isNotEmpty == true)
              ? widget.fallbackLocationLine!
              : (selectedAddress != null
                    ? '${selectedAddress.address}, ${selectedAddress.city} - ${selectedAddress.pinCode}'
                    : 'Select service address'));

    return bannersAsync.when(
      loading: () => _HomeBannerCarousel(
        banners: const <BannerModal>[],
        categories: categories,
        topInset: topInset,
        fullNameFuture: fullNameFuture,
        locationLine: locationLine,
        cartCount: cartCount,
        canChangeAddress: !cartState.isMutating,
        onChangeAddressTap: _onChangeAddressTap,
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
        onCartTap: () {
          ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
          Navigator.of(context).pushNamed(AppRouter.cart);
        },
        onProfileTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
        },
      ),
      error: (_, __) => _HomeBannerCarousel(
        banners: const <BannerModal>[],
        categories: categories,
        topInset: topInset,
        fullNameFuture: fullNameFuture,
        locationLine: locationLine,
        cartCount: cartCount,
        canChangeAddress: !cartState.isMutating,
        onChangeAddressTap: _onChangeAddressTap,
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
        onCartTap: () {
          ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
          Navigator.of(context).pushNamed(AppRouter.cart);
        },
        onProfileTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
        },
      ),
      data: (banners) => _HomeBannerCarousel(
        banners: banners,
        categories: categories,
        topInset: topInset,
        fullNameFuture: fullNameFuture,
        locationLine: locationLine,
        cartCount: cartCount,
        canChangeAddress: !cartState.isMutating,
        onChangeAddressTap: _onChangeAddressTap,
        searchController: widget.searchController,
        onSearchChanged: widget.onSearchChanged,
        onCartTap: () {
          ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
          Navigator.of(context).pushNamed(AppRouter.cart);
        },
        onProfileTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
          );
        },
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({
    required this.banners,
    required this.categories,
    required this.topInset,
    required this.fullNameFuture,
    required this.locationLine,
    required this.cartCount,
    required this.canChangeAddress,
    required this.searchController,
    required this.onSearchChanged,
    required this.onChangeAddressTap,
    required this.onCartTap,
    required this.onProfileTap,
  });

  final List<BannerModal> banners;
  final List<CategoryModal> categories;
  final double topInset;
  final Future<String?> fullNameFuture;
  final String locationLine;
  final int cartCount;
  final bool canChangeAddress;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onChangeAddressTap;
  final VoidCallback onCartTap;
  final VoidCallback onProfileTap;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant _HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _currentIndex = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBannerTap(BuildContext context, BannerModal banner) {
    if (!banner.isClickable) {
      return;
    }

    final redirect = banner.redirect;
    if (redirect.type.toUpperCase() != 'CATEGORY' || redirect.id == null) {
      return;
    }

    CategoryModal? category;
    for (final item in widget.categories) {
      if (item.id == redirect.id) {
        category = item;
        break;
      }
    }

    Navigator.of(context).pushNamed(
      AppRouter.serviceDetail,
      arguments: {
        'categoryId': redirect.id,
        'title': category?.name ?? banner.title,
        'image': category?.imageUrl ?? banner.mediaUrl,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeIndex = widget.banners.isEmpty
        ? 0
        : _currentIndex.clamp(0, widget.banners.length - 1).toInt();
    final currentBanner = widget.banners.isEmpty
        ? null
        : widget.banners[safeIndex];
    final title = currentBanner?.title.trim() ?? '';
    final subtitle = currentBanner?.subtitle.trim() ?? '';
    final showBannerContent =
        currentBanner != null &&
        (title.isNotEmpty || subtitle.isNotEmpty || currentBanner.isClickable);

    return Padding(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        child: SizedBox(
          height: widget.topInset + 286,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: widget.banners.isEmpty ? 1 : widget.banners.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final banner = widget.banners.isEmpty
                      ? null
                      : widget.banners[index];
                  return GestureDetector(
                    onTap: banner == null
                        ? null
                        : () => _onBannerTap(context, banner),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (banner == null)
                          const ColoredBox(color: Color(0xFF19B8E8))
                        else
                          Image.network(
                            banner.mediaUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const ColoredBox(color: Color(0xFF19B8E8));
                            },
                          ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xDD17B7E7),
                                Color(0x9917B7E7),
                                Color(0x3317B7E7),
                              ],
                            ),
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x22000000),
                                Color(0x00000000),
                                Color(0x44000000),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                left: 16,
                right: 16,
                top: widget.topInset + 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FutureBuilder<String?>(
                        future: widget.fullNameFuture,
                        builder: (context, snapshot) {
                          final name = snapshot.data?.trim().isNotEmpty == true
                              ? snapshot.data!.trim()
                              : 'Parul';

                          return InkWell(
                            onTap: widget.canChangeAddress
                                ? widget.onChangeAddressTap
                                : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      size: 14,
                                      color: Color(0xFF11314B),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Hello $name',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF0F172A),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 17,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.locationLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF11314B),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: Color(0xFF11314B),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    _HeaderCircleButton(
                      icon: Icons.shopping_cart_outlined,
                      onTap: widget.onCartTap,
                      badgeCount: widget.cartCount,
                    ),
                    const SizedBox(width: 8),
                    _HeaderCircleButton(
                      icon: Icons.person,
                      onTap: widget.onProfileTap,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: widget.topInset + 94,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xEAF7F9FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: widget.onSearchChanged,
                    onTapOutside: (_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search services...',
                      hintStyle: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 19,
                        color: Color(0xFF6B7280),
                      ),
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.mic,
                          color: Color(0xFF0A2440),
                          size: 15,
                        ),
                      ),
                      suffixIconConstraints: BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              if (showBannerContent)
                Positioned(
                  left: 16,
                  right: 112,
                  top: widget.topInset + 160,
                  bottom: 32,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth,
                            minWidth: constraints.maxWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title.isNotEmpty)
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 31,
                                    height: 0.96,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if (title.isNotEmpty && subtitle.isNotEmpty)
                                const SizedBox(height: 5),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF08213A),
                                    fontSize: 13,
                                    height: 1.15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              if ((title.isNotEmpty || subtitle.isNotEmpty) &&
                                  currentBanner.isClickable)
                                const SizedBox(height: 9),
                              if (currentBanner.isClickable)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A2440),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Book Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (widget.banners.length > 1)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.banners.length, (index) {
                      final selected = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: selected ? 7 : 5,
                        height: selected ? 7 : 5,
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white
                              : Colors.white.withOpacity(0.62),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF0A2440),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00D09C),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String? _cityFromLocationLine(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  final parts = text.split(',');
  if (parts.length >= 2) {
    final city = parts[parts.length - 2].replaceAll(RegExp(r'[^A-Za-z ]'), '');
    return city.trim().isEmpty ? null : city.trim();
  }

  return null;
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

class _CategorySearchSheet extends StatefulWidget {
  const _CategorySearchSheet({
    required this.categories,
    required this.onCategoryTap,
  });

  final List<CategoryModal> categories;
  final ValueChanged<CategoryModal> onCategoryTap;

  @override
  State<_CategorySearchSheet> createState() => _CategorySearchSheetState();
}

class _CategorySearchSheetState extends State<_CategorySearchSheet> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CategoryModal> get _filteredCategories {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.categories;
    }

    return widget.categories
        .where((category) {
          return category.name.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categories = _filteredCategories;

    return FractionallySizedBox(
      heightFactor: 0.9,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 10, 16, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Search categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search by category name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF0B2A4A)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${categories.length} result${categories.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: categories.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching categories found',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: categories.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.onCategoryTap(category);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      color: const Color(0xFFE5E7EB),
                                      child: category.imageUrl.isNotEmpty
                                          ? Image.network(
                                              category.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.category_outlined,
                                                    color: Color(0xFF64748B),
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.category_outlined,
                                              color: Color(0xFF64748B),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Tap to view services',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Color(0xFF94A3B8),
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
      ),
    );
  }
}
