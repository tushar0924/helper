import 'package:flutter/material.dart';

import 'widgets/kirana_category_tile.dart';
import 'widgets/kirana_product_card.dart';

class KiranaScreen extends StatelessWidget {
  const KiranaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const headerColor = Color(0xFF0B2341);
    const pageBg = Colors.white;

    final deliveryOptions = <_DeliveryOption>[
      const _DeliveryOption(
        title: 'Instant',
        subtitle: '(10-15 mins)',
        selected: true,
      ),
      const _DeliveryOption(
        title: 'Express',
        subtitle: '(4 hrs)',
      ),
      const _DeliveryOption(
        title: 'Standard',
        subtitle: '(1 day)',
      ),
    ];

    final suggestedItems = <_ProductItem>[
      const _ProductItem(
        name: 'Chakki Fresh Atta',
        subtitle: 'Pure, whole, fine',
        price: '₹50/kg',
        imageUrl: 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=600&q=80',
      ),
      const _ProductItem(
        name: 'Aashirvaad Atta',
        subtitle: 'Soft, wholesome',
        price: '₹50/kg',
        imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=600&q=80',
      ),
      const _ProductItem(
        name: 'Fortune Oil',
        subtitle: 'Refined, healthy',
        price: '₹110/ltr',
        imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=600&q=80',
      ),
    ];

    final groceries = <_CategoryItem>[
      const _CategoryItem(title: 'Atta, rice &\ndaal', imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Oil & Ghee', imageUrl: 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Masala', imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Dry Fruits', imageUrl: 'https://images.unsplash.com/photo-1505253716362-afaea1d3d1af?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Oil & Ghee', imageUrl: 'https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Masala', imageUrl: 'https://images.unsplash.com/photo-1514986888952-8cd320577b68?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Dry Fruits', imageUrl: 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Atta, rice &\ndaal', imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?auto=format&fit=crop&w=600&q=80'),
    ];

    final personalCare = <_CategoryItem>[
      const _CategoryItem(title: 'Tooth Paste', imageUrl: 'https://images.unsplash.com/photo-1585247226801-bc613c441316?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Hair Oil', imageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Tooth Brush', imageUrl: 'https://images.unsplash.com/photo-1580894732444-8ecded7900cd?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Face Wash', imageUrl: 'https://images.unsplash.com/photo-1556228578-8e1f3f6a5d12?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Soap', imageUrl: 'https://images.unsplash.com/photo-1601042636094-7b7cb47b0f93?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Shampoo', imageUrl: 'https://images.unsplash.com/photo-1526947425960-945c6e728a2f?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Body Lotion', imageUrl: 'https://images.unsplash.com/photo-1596755389378-c31d21fd1273?auto=format&fit=crop&w=600&q=80'),
      const _CategoryItem(title: 'Moisturizer', imageUrl: 'https://images.unsplash.com/photo-1571781926291-c477ebfd024b?auto=format&fit=crop&w=600&q=80'),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: headerColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kirana4u',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Choose delivery option',
                                style: TextStyle(
                                  color: Color(0xFFC7D2E3),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 32,
                            width: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                            child: const Icon(
                              Icons.shopping_basket_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search for chini, sugar, rice...',
                            hintStyle: TextStyle(
                              color: Color(0xFF8D98AA),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFF8D98AA),
                            ),
                            suffixIcon: Icon(
                              Icons.mic_none,
                              color: Color(0xFF8D98AA),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7FB),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD0EDF5)),
                  ),
                  child: Row(
                    children: deliveryOptions
                        .map(
                          (option) => Expanded(
                            child: _DeliveryOptionChip(option: option),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _FreshSpicesBanner(),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Suggested Items'),
              const SizedBox(height: 10),
              SizedBox(
                height: 195,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestedItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = suggestedItems[index];
                    return KiranaProductCard(item: item);
                  },
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Groceries'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  itemCount: groceries.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final item = groceries[index];
                    return KiranaCategoryTile(item: item);
                  },
                ),
              ),
              const SizedBox(height: 18),
              _SectionTitle(title: 'Personal Care'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  itemCount: personalCare.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.82,
                  ),
                  itemBuilder: (context, index) {
                    final item = personalCare[index];
                    return KiranaCategoryTile(item: item);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreshSpicesBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: const Color(0xFFF5D96D),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            flex: 11,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 8, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Fresh Spices ',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E1A2B),
                          ),
                        ),
                        TextSpan(
                          text: 'For\nEvery Kitchen',
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0E1A2B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rich flavours crafted from\nthe freshest spices',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE77A2D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Shop Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  'https://images.unsplash.com/photo-1608025798349-4c0de0d0a5d1?auto=format&fit=crop&w=900&q=80',
                  fit: BoxFit.cover,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFF5D96D).withOpacity(0.0),
                        const Color(0xFF4B2D13).withOpacity(0.15),
                      ],
                    ),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _DeliveryOption {
  const _DeliveryOption({
    required this.title,
    required this.subtitle,
    this.selected = false,
  });

  final String title;
  final String subtitle;
  final bool selected;
}

class _DeliveryOptionChip extends StatelessWidget {
  const _DeliveryOptionChip({required this.option});

  final _DeliveryOption option;

  @override
  Widget build(BuildContext context) {
    final bgColor = option.selected ? Colors.white : const Color(0xFFEAF7FB);
    final titleColor = option.selected ? const Color(0xFF0EA5E9) : const Color(0xFF334155);
    final subtitleColor = option.selected ? const Color(0xFF0EA5E9) : const Color(0xFF16A34A);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: option.selected
            ? const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            option.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            option.subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductItem {
  const _ProductItem({
    required this.name,
    required this.subtitle,
    required this.price,
    required this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String price;
  final String imageUrl;
}

class _CategoryItem {
  const _CategoryItem({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;
}
