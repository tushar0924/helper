import 'package:flutter/material.dart';

class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});

  static const List<_QuickCardData> _quickCards = <_QuickCardData>[
    _QuickCardData(
      title: 'Helperr4u',
      subtitle: 'Maids, cooks, drivers\n& more',
      bg: Color(0xFFF2D46E),
      icon: Icons.engineering_outlined,
    ),
    _QuickCardData(
      title: 'Kirana4u',
      subtitle: 'Order Groceries from\nNearby Stores',
      bg: Color(0xFFA0EB7A),
      icon: Icons.local_grocery_store_outlined,
    ),
  ];

  static const List<_ServingCardData> _servingCards = <_ServingCardData>[
    _ServingCardData(
      title: 'Maid Serving',
      imageUrl:
          'https://images.unsplash.com/photo-1522163182402-834f871fd851?w=700',
    ),
    _ServingCardData(
      title: 'Grocery Serving',
      imageUrl:
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=700',
    ),
    _ServingCardData(
      title: 'Room Cleaning',
      imageUrl:
          'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=700',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TopRow(),
            const SizedBox(height: 14),
            const _SearchBar(),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Zynexx',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F93A8),
                  fontFamily: 'serif',
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: _quickCards
                  .map(
                    (card) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: card == _quickCards.first ? 8 : 0,
                          left: card == _quickCards.last ? 8 : 0,
                        ),
                        child: _QuickActionCard(data: card),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 14),
            const _PromoCard(),
            const SizedBox(height: 8),
            const _PageDots(),
            const SizedBox(height: 18),
            const Text(
              'See us serving',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _servingCards.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  return _ServingCard(data: _servingCards[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 20, color: Color(0xFFF97316)),
        const SizedBox(width: 6),
        const Text(
          'Jaipur, India',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF6B7280)),
        const Spacer(),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFF082042),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDFE3E8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 20, color: Color(0xFF7C8796)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search for help or stores nearby...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF8A94A6),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Icon(Icons.mic_none_rounded, size: 20, color: Color(0xFF7C8796)),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.data});

  final _QuickCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 116,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF111827),
              height: 1.15,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 12, color: Color(0xFF111827)),
                  ],
                ),
              ),
              const Spacer(),
              Icon(data.icon, size: 28, color: const Color(0xFF111827)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 136,
      decoration: BoxDecoration(
        color: const Color(0xFF158F32),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Groceries At Your\nDoorstep',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Skip the store, we'll bring\nit from nearby stores.",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8FFD2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF176D1E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Image.network(
              'https://images.unsplash.com/photo-1515543904379-3d757abe8d76?w=700',
              width: 126,
              height: 136,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 126,
                  height: 136,
                  color: const Color(0xFF2A6B39),
                  child: const Icon(
                    Icons.local_grocery_store,
                    color: Colors.white,
                    size: 38,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(const Color(0xFF00A8D6), 18),
        const SizedBox(width: 4),
        _dot(const Color(0xFFD0D5DD), 8),
        const SizedBox(width: 4),
        _dot(const Color(0xFFD0D5DD), 8),
        const SizedBox(width: 4),
        _dot(const Color(0xFFD0D5DD), 8),
      ],
    );
  }

  Widget _dot(Color color, double width) {
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ServingCard extends StatelessWidget {
  const _ServingCard({required this.data});

  final _ServingCardData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 128,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                data.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFD1D5DB));
                },
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.02),
                      Colors.black.withOpacity(0.52),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCardData {
  const _QuickCardData({
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color bg;
  final IconData icon;
}

class _ServingCardData {
  const _ServingCardData({required this.title, required this.imageUrl});

  final String title;
  final String imageUrl;
}
