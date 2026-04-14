import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_provider.dart';
import '../../../routes/app_router.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.serviceTitle,
    required this.serviceImage,
  });

  final String serviceTitle;
  final String serviceImage;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final TextEditingController _searchController = TextEditingController();

  static final List<_ServiceItem> _services = [
    _ServiceItem(
      title: 'Living Room Cleaning',
      description: 'Complete deep cleaning of all rooms including kitchen & bathroom',
      image: 'https://images.unsplash.com/photo-1527515637462-cff94eecc1ac?w=600',
      price: '₹699',
      rating: '4.8',
      duration: '3 hrs',
      popular: true,
    ),
    _ServiceItem(
      title: 'Dinning Room',
      description: 'Intensive hall cleaning with descaling',
      image: 'https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=600',
      price: '₹499',
      rating: '4.9',
      duration: '1.5 hrs',
      popular: true,
    ),
    _ServiceItem(
      title: 'Hall Cleaning',
      description: 'Complete kitchen cleaning including chimney, stove & cabinets',
      image: 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=600',
      price: '₹699',
      rating: '4.7',
      duration: '2 hrs',
      popular: false,
    ),
    _ServiceItem(
      title: 'Sofa Cleaning',
      description: 'Professional sofa & upholstery dry cleaning service',
      image: 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600',
      price: '₹599',
      rating: '4.8',
      duration: '2.5 hrs',
      popular: false,
    ),
    _ServiceItem(
      title: '18hk Cleaning',
      description: 'Steam cleaning & stain removal for carpets and rugs',
      image: 'https://images.unsplash.com/photo-1563453392212-326f5e854473?w=600',
      price: '₹449',
      rating: '4.5',
      duration: '1.5 hrs',
      popular: false,
    ),
    _ServiceItem(
      title: 'Window Cleaning',
      description: 'Streak-free windows & glass cleaning for all rooms',
      image: 'https://images.unsplash.com/photo-1527515545081-5db817172677?w=600',
      price: '₹349',
      rating: '4.7',
      duration: '1 hr',
      popular: false,
    ),
    _ServiceItem(
      title: '2Bhk Cleaning',
      description: 'Comprehensive cleaning for moving in or out of property',
      image: 'https://images.unsplash.com/photo-1581578017423-45bed7d5f58d?w=600',
      price: '₹1,299',
      rating: '4.8',
      duration: '4 hrs',
      popular: false,
    ),
    _ServiceItem(
      title: '3Bhk Cleaning',
      description: 'Deep cleaning of AC vents & tiles for better air quality',
      image: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=600',
      price: '₹399',
      rating: '4.6',
      duration: '45 mins',
      popular: false,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _services.where((item) {
      if (query.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList(growable: false);

    final popular = filtered.where((item) => item.popular).toList(growable: false);

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
                    icon: const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
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
                        '${_services.length} services available',
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
                    _HeroBanner(title: widget.serviceTitle, image: widget.serviceImage),
                    const SizedBox(height: 12),
                    _SearchRow(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  const _SearchRow({
    required this.controller,
    required this.onChanged,
  });

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
          child: const Icon(
            Icons.tune,
            size: 17,
            color: Color(0xFF385476),
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final quantity = cartQuantityForTitle(cartItems, item.title);

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
              child: Image.network(
                item.image,
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
                            item.title,
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
                            item.description,
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
                                item.rating,
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
                                item.duration,
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
                    Text(
                      item.price,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
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
                                'title': item.title,
                                'image': item.image,
                                'price': item.price,
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
                        onAdd: () {
                          final category = item.title.toLowerCase().contains('repair')
                              ? 'Repair Services'
                              : 'Home Services';
                          ref.read(cartProvider.notifier).addService(
                                title: item.title,
                                category: category,
                                priceText: item.price,
                                duration: item.duration,
                                imageUrl: item.image,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.title} added to cart'),
                              duration: const Duration(milliseconds: 900),
                            ),
                          );
                        },
                        onIncrement: () {
                          ref.read(cartProvider.notifier).increment(item.title);
                        },
                        onDecrement: () {
                          ref.read(cartProvider.notifier).decrement(item.title);
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

class _CartActionButton extends StatelessWidget {
  const _CartActionButton({
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return SizedBox(
        height: 28,
        child: ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5C6),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
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
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 30,
              child: Center(
                child: Text(
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
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(8),
            child: const SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1,
                    color: Color(0xFF0EA5C6),
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

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.description,
    required this.image,
    required this.price,
    required this.rating,
    required this.duration,
    required this.popular,
  });

  final String title;
  final String description;
  final String image;
  final String price;
  final String rating;
  final String duration;
  final bool popular;
}
