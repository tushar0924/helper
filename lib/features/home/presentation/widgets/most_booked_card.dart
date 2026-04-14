import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/application/cart_provider.dart';

class MostBookedCard extends ConsumerWidget {
  const MostBookedCard({
    super.key,
    required this.title,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  final String title;
  final String price;
  final String rating;
  final String imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quantity = cartQuantityForTitle(ref.watch(cartProvider), title);

    return Container(
      width: 134,
      padding: const EdgeInsets.fromLTRB(7, 7, 7, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E8ED), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: const Color(0xFFE6E8EC));
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              height: 1.15,
              color: Color(0xFF151B26),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              const Icon(Icons.star, size: 11, color: Color(0xFFFFC107)),
              const SizedBox(width: 3),
              Text(
                rating,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF2A313C),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E2632),
                ),
              ),
              const Spacer(),
              _CartActionButton(
                quantity: quantity,
                onAdd: () {
                  ref.read(cartProvider.notifier).addService(
                        title: title,
                        category: 'Home Services',
                        priceText: price,
                        duration: '1 hr',
                        imageUrl: imageUrl,
                      );
                },
                onIncrement: () => ref.read(cartProvider.notifier).increment(title),
                onDecrement: () => ref.read(cartProvider.notifier).decrement(title),
              ),
            ],
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
      return InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 21,
          width: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF09A6E8),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Add',
            style: TextStyle(
              color: Colors.white,
              fontSize: 8.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 21,
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: onDecrement,
            borderRadius: BorderRadius.circular(7),
            child: const SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  '−',
                  style: TextStyle(
                    color: Color(0xFF09A6E8),
                    fontSize: 16,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          InkWell(
            onTap: onIncrement,
            borderRadius: BorderRadius.circular(7),
            child: const SizedBox(
              width: 20,
              child: Center(
                child: Text(
                  '+',
                  style: TextStyle(
                    color: Color(0xFF09A6E8),
                    fontSize: 14,
                    height: 1,
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
