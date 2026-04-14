import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_provider.dart';
import '../../../routes/app_router.dart';
import 'widgets/most_booked_card.dart';
import 'widgets/offer_card.dart';
import 'widgets/service_tile.dart';

class HelperTabView extends ConsumerWidget {
  const HelperTabView({super.key});

  static final List<_ServiceData> _services = <_ServiceData>[
    _ServiceData(
      title: 'Home Cleaning',
      imageUrl: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300',
      background: const Color(0xFFD5E1EF),
    ),
    _ServiceData(
      title: 'Kitchen cleaning',
      imageUrl: 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=300',
      background: const Color(0xFFE3E7ED),
    ),
    _ServiceData(
      title: 'Bathroom cleaning',
      imageUrl: 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=300',
      background: const Color(0xFFE3E7ED),
    ),
    _ServiceData(
      title: 'Electrician',
      imageUrl: 'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?w=300',
      background: const Color(0xFFEEE7C3),
    ),
    _ServiceData(
      title: 'AC Repair',
      imageUrl: 'https://images.unsplash.com/photo-1631545806522-84d3a35ec6fd?w=300',
      background: const Color(0xFFDEE2F2),
    ),
    _ServiceData(
      title: 'Plumber',
      imageUrl: 'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?w=300',
      background: const Color(0xFFE9E9EA),
    ),
    _ServiceData(
      title: 'Refrigerator Repair',
      imageUrl: 'https://images.unsplash.com/photo-1584568694244-14fbdf83bd30?w=300',
      background: const Color(0xFFE3E7ED),
    ),
    _ServiceData(
      title: 'Cook',
      imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=300',
      background: const Color(0xFFF0D4B0),
    ),
    _ServiceData(
      title: 'Care',
      imageUrl: 'https://images.unsplash.com/photo-1515378791036-0648a3ef77b2?w=300',
      background: const Color(0xFFD8ECEC),
    ),
    _ServiceData(
      title: 'Women Parlour',
      imageUrl: 'https://images.unsplash.com/photo-1521590832167-7bcbfaa6381f?w=300',
      background: const Color(0xFFE8DDDB),
    ),
    _ServiceData(
      title: 'Mehndi',
      imageUrl: 'https://images.unsplash.com/photo-1607861716497-e65ab29fc7ac?w=300',
      background: const Color(0xFFF0DBA7),
    ),
    _ServiceData(
      title: 'Washing Machine Repair',
      imageUrl: 'https://images.unsplash.com/photo-1626806787461-102c1bfaaea1?w=300',
      background: const Color(0xFFD9E4F2),
    ),
  ];

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
                  GridView.builder(
                    itemCount: _services.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final item = _services[index];
                      return ServiceTile(
                        title: item.title,
                        imageUrl: item.imageUrl,
                        background: item.background,
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRouter.serviceDetail,
                            arguments: {
                              'title': item.title,
                              'image': item.imageUrl,
                            },
                          );
                        },
                      );
                    },
                  ),
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
                  return Positioned(
                    left: left,
                    child: child!,
                  );
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

class _TopHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topInset = MediaQuery.of(context).padding.top;
    final cartCount = ref.watch(cartProvider).length;

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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Helperr4U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hello',
                      style: TextStyle(
                        color: Color(0xFFB5C5D5),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(AppRouter.cart);
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 5,
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
                const Icon(
                  Icons.search,
                  size: 21,
                  color: Color(0xFF8796A5),
                ),
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
                  child: const Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceData {
  const _ServiceData({
    required this.title,
    required this.imageUrl,
    required this.background,
  });

  final String title;
  final String imageUrl;
  final Color background;
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
