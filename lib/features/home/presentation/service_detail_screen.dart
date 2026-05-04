import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../../../app/widgets/skeleton_shimmer.dart';
import '../../../routes/app_router.dart';
import '../../auth/application/auth_provider.dart';
import '../../auth/application/auth_provider.dart' as auth_provider;
import '../../cart/application/cart_provider.dart';
import '../../cart/presentation/widgets/clear_cart_dialog.dart';
import '../../cart/presentation/widgets/replace_cart_item_dialog.dart';
import '../application/home_bootstrap_provider.dart';
import '../application/service_provider.dart';
import '../modal/service_modal.dart';
import '../presentation/widgets/coming_soon_modal.dart';
import 'widgets/price_stack.dart';

class ServiceDetailScreen extends ConsumerStatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.categoryId,
    required this.serviceTitle,
    required this.serviceImage,
  });

  final int categoryId;
  final String serviceTitle;
  final String serviceImage;

  @override
  ConsumerState<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends ConsumerState<ServiceDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCartBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(serviceControllerProvider.notifier)
          .loadServicesForCategory(widget.categoryId, forceRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ServiceState>(serviceControllerProvider, (_, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppToast.error(next.errorMessage!);
      }
    });

    final state = ref.watch(serviceControllerProvider);
    final cartState = ref.watch(cartProvider);
    final homeBootstrapState = ref.watch(homeBootstrapProvider);
    final cartSummary = cartState.summary;
    final cartItemCount = cartSummary?.items.length ?? 0;
    final services = state.categoryId == widget.categoryId
        ? state.items
        : const <ServiceModal>[];

    final query = _searchController.text.trim().toLowerCase();
    final filtered = services
        .where((item) {
          if (query.isEmpty) {
            return true;
          }
          return item.name.toLowerCase().contains(query) ||
              item.safeDescription.toLowerCase().contains(query);
        })
        .toList(growable: false);

    final sortedByRating = [...filtered]
      ..sort((a, b) => b.rating.compareTo(a.rating));
    final popular = sortedByRating.take(3).toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F4),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      const Text(
                        'Cleaning Services',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${services.length} services available',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF858E9B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroBanner(
                      title: widget.serviceTitle,
                      image: widget.serviceImage,
                    ),
                    const SizedBox(height: 12),
                    _SearchRow(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    if (homeBootstrapState.showComingSoon)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              RichText(
                                textAlign: TextAlign.center,
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'We Are\n',
                                      style: TextStyle(
                                        color: Color(0xFF374151),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Coming Soon',
                                      style: TextStyle(
                                        color: Color(0xFF111827),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'We are currently living in select area and expanding quickly. Get notified when we are near you !',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Expanded(
                      child: _ServiceListingContent(
                        categoryId: widget.categoryId,
                        isLoading: state.isLoading,
                        hasData: services.isNotEmpty,
                        popular: popular,
                        filtered: filtered,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: cartItemCount <= 0
              || _isCartBannerDismissed
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xD9FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x66D8DDE5), width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A0F172A),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$cartItemCount ${cartItemCount == 1 ? 'item' : 'items'} added',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formatInr(cartSummary?.pricing.total ?? 0),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        height: 33,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRouter.cart);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0B1F3A),
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'View Cart',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () async {
                          final shouldClear = await showClearCartDialog(
                            context,
                            onConfirm: () {
                              return ref
                                  .read(cartProvider.notifier)
                                  .clearCart();
                            },
                          );
                          if (!mounted || !shouldClear) {
                            return;
                          }
                          setState(() {
                            _isCartBannerDismissed = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.cancel,
                            size: 18,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ServiceListingContent extends ConsumerWidget {
  const _ServiceListingContent({
    required this.categoryId,
    required this.isLoading,
    required this.hasData,
    required this.popular,
    required this.filtered,
  });

  final int categoryId;
  final bool isLoading;
  final bool hasData;
  final List<ServiceModal> popular;
  final List<ServiceModal> filtered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading && !hasData) {
      return const _ServiceListSkeleton();
    }

    if (!isLoading && filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_repair_service_outlined,
              size: 36,
              color: Color(0xFF9AA4B2),
            ),
            const SizedBox(height: 10),
            const Text(
              'Currently no services available for this category',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref
                    .read(serviceControllerProvider.notifier)
                    .loadServicesForCategory(categoryId, forceRefresh: true);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (popular.isNotEmpty) ...[
            const Text(
              'Most Popular',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 146,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: popular.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 318,
                    child: _ServiceCard(item: popular[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'All Services',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _ServiceCard(item: filtered[index]);
            },
          ),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.title, required this.image});

  final String title;
  final String image;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 132,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              image,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFFD9DEE6));
              },
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x15000000), Color(0xA0000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 29,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Professional home cleaning services',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFE8ECF3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: Color(0xFF8D96A2)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Search within category...',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E99A6),
                        fontSize: 11,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.tune, size: 17, color: Color(0xFF385476)),
        ),
      ],
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.item});

  final ServiceModal item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final quantity = cartQuantityForServiceId(cartState, item.id);
    final disableAdd = ref.read(cartProvider.notifier).isAddDisabled(item.id);
    final isServiceMutating = cartState.mutatingServiceId == item.id;
    final isAddLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'add';
    final isIncrementLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'increment';
    final isDecrementLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'decrement';
    
    // Check if location is coming soon
    final homeBootstrapState = ref.watch(homeBootstrapProvider);
    final isComingSoon = homeBootstrapState.showComingSoon;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E7EF)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 78,
              height: 78,
              color: const Color(0xFFE3E7ED),
              child: item.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.cleaning_services_outlined,
                        color: Color(0xFF8FA1B5),
                      ),
                    )
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.safeDescription,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF7E8793),
                              fontWeight: FontWeight.w400,
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 14,
                                color: Color(0xFFFFC107),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.rating == 0
                                    ? 'New'
                                    : item.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 7),
                              const Text(
                                '●',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Color(0xFF9AA3AF),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Text(
                                item.formattedDuration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF606B78),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PriceStack(
                      originalPrice: item.hasDiscount
                          ? item.formattedOriginalPrice
                          : null,
                      payablePrice: item.formattedPayablePrice,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 28,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(
                              AppRouter.serviceViewDetail,
                              arguments: {
                                'serviceId': item.id,
                                'title': item.name,
                                'image': item.imageUrl,
                                'price': item.formattedPrice,
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E294A),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View Detail',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CartActionButton(
                        quantity: quantity,
                        disableIncrement: disableAdd || isComingSoon,
                        isAddLoading: isAddLoading,
                        isIncrementLoading: isIncrementLoading,
                        isDecrementLoading: isDecrementLoading,
                        onAdd: isComingSoon
                            ? () async {
                                await showComingSoonModal(
                                  context,
                                  onChangeLocation: () {
                                    Navigator.of(context).pop();
                                  },
                                );
                              }
                            : () async {
                                final result = await ref
                                    .read(cartProvider.notifier)
                                    .addToCart(serviceId: item.id, quantity: 1);
                                if (!context.mounted) {
                                  return;
                                }
                                if (result == CartAddResult.added) {
                                  AppToast.success('${item.name} added to cart');
                                  return;
                                }
                                if (result == CartAddResult.failed) {
                                  final message =
                                      ref.read(cartProvider).errorMessage;
                                  if (message != null && message.isNotEmpty) {
                                    AppToast.error(message);
                                  }
                                  return;
                                }
                                if (result != CartAddResult.categoryConflict) {
                                  return;
                                }

                                final shouldReplace =
                                    await showReplaceCartItemDialog(context);
                                if (!context.mounted || !shouldReplace) {
                                  return;
                                }

                                final replaced = await ref
                                    .read(cartProvider.notifier)
                                    .replaceCartItem(
                                      serviceId: item.id,
                                      quantity: 1,
                                    );
                                if (context.mounted && replaced) {
                                  AppToast.success('${item.name} added to cart');
                                } else if (context.mounted) {
                                  final message =
                                      ref.read(cartProvider).errorMessage;
                                  if (message != null && message.isNotEmpty) {
                                    AppToast.error(message);
                                  }
                                }
                              },
                        onIncrement: isComingSoon
                            ? () {}
                            : () {
                                ref
                                    .read(cartProvider.notifier)
                                    .incrementByServiceId(item.id);
                              },
                        onDecrement: isComingSoon
                            ? () {}
                            : () {
                                ref
                                    .read(cartProvider.notifier)
                                    .decrementByServiceId(item.id);
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceListSkeleton extends StatelessWidget {
  const _ServiceListSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Most Popular',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return Container(
                  width: 318,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E7EF)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SkeletonShimmerBox(
                        width: 78,
                        height: 78,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonShimmerBox(
                              height: 12,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                            SizedBox(height: 8),
                            SkeletonShimmerBox(
                              height: 10,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                            SizedBox(height: 6),
                            SkeletonShimmerBox(
                              height: 10,
                              width: 120,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'All Services',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          ListView.separated(
            itemCount: 4,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return Container(
                height: 110,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE2E7EF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SkeletonShimmerBox(
                      width: 78,
                      height: 78,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonShimmerBox(
                            height: 12,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          SizedBox(height: 8),
                          SkeletonShimmerBox(
                            height: 10,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                          SizedBox(height: 6),
                          SkeletonShimmerBox(
                            height: 10,
                            width: 130,
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CartActionButton extends StatelessWidget {
  const _CartActionButton({
    required this.quantity,
    required this.disableIncrement,
    required this.isAddLoading,
    required this.isIncrementLoading,
    required this.isDecrementLoading,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool disableIncrement;
  final bool isAddLoading;
  final bool isIncrementLoading;
  final bool isDecrementLoading;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: disableIncrement || isAddLoading ? null : onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5C6),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: isAddLoading
              ? const SizedBox(
                  height: 14,
                  width: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  'Add',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    }

    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: isDecrementLoading ? null : onDecrement,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 30,
              child: Center(
                child: isDecrementLoading
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0EA5C6),
                          ),
                        ),
                      )
                    : const Text(
                        '−',
                        style: TextStyle(
                          fontSize: 20,
                          height: 1,
                          color: Color(0xFF0EA5C6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          InkWell(
            onTap: disableIncrement || isIncrementLoading ? null : onIncrement,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 30,
              child: Center(
                child: isIncrementLoading
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF0EA5C6),
                          ),
                        ),
                      )
                    : Text(
                        '+',
                        style: TextStyle(
                          fontSize: 18,
                          height: 1,
                          color: disableIncrement
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF0EA5C6),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
