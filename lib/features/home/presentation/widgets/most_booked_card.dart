import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/utils/app_toast.dart';
import '../../../cart/application/cart_provider.dart';
import 'price_stack.dart';

class MostBookedCard extends ConsumerWidget {
  const MostBookedCard({
    super.key,
    this.serviceId,
    required this.title,
    required this.price,
    required this.rating,
    required this.imageUrl,
  });

  final int? serviceId;
  final String title;
  final String price;
  final String rating;
  final String imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final quantity = serviceId == null
        ? 0
        : cartQuantityForServiceId(cartState, serviceId!);
    final disableAdd = serviceId == null
        ? true
        : ref.read(cartProvider.notifier).isAddDisabled(serviceId!);
    final isServiceMutating =
        serviceId != null && cartState.mutatingServiceId == serviceId;
    final isAddLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'add';
    final isIncrementLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'increment';
    final isDecrementLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'decrement';

    return Container(
      width: 134,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
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
          const SizedBox(height: 9),
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
              PriceStack(
                originalPrice: null,
                payablePrice: price,
                compact: true,
              ),
              const Spacer(),
              _CartActionButton(
                quantity: quantity,
                disableIncrement: disableAdd,
                isAddLoading: isAddLoading,
                isIncrementLoading: isIncrementLoading,
                isDecrementLoading: isDecrementLoading,
                onAdd: () {
                  if (serviceId == null) {
                    AppToast.error('Service id not available for this item');
                    return;
                  }

                  ref
                      .read(cartProvider.notifier)
                      .addToCart(serviceId: serviceId!, quantity: 1);
                },
                onIncrement: () {
                  if (serviceId == null) {
                    return;
                  }
                  ref
                      .read(cartProvider.notifier)
                      .incrementByServiceId(serviceId!);
                },
                onDecrement: () {
                  if (serviceId == null) {
                    return;
                  }
                  ref
                      .read(cartProvider.notifier)
                      .decrementByServiceId(serviceId!);
                },
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
      final bgColor = disableIncrement ? const Color(0xFFE5E7EB) : const Color(0xFF09A6E8);
      final textColor = disableIncrement ? const Color(0xFF9CA3AF) : Colors.white;
      return InkWell(
        onTap: disableIncrement || isAddLoading ? null : onAdd,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          height: 21,
          width: 38,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: isAddLoading
              ? SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        disableIncrement ? const Color(0xFF9CA3AF) : Colors.white),
                  ),
                )
              : Text(
                  'Add',
                  style: TextStyle(
                    color: textColor,
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
            onTap: isDecrementLoading ? null : onDecrement,
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              width: 20,
              child: Center(
                child: isDecrementLoading
                    ? const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF09A6E8),
                          ),
                        ),
                      )
                    : const Text(
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
            onTap: disableIncrement || isIncrementLoading ? null : onIncrement,
            borderRadius: BorderRadius.circular(7),
            child: SizedBox(
              width: 20,
              child: Center(
                child: isIncrementLoading
                    ? const SizedBox(
                        width: 11,
                        height: 11,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF09A6E8),
                          ),
                        ),
                      )
                      : Text(
                          '+',
                          style: TextStyle(
                            color: disableIncrement ? const Color(0xFF9CA3AF) : const Color(0xFF09A6E8),
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
