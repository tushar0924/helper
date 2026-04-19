import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../app/widgets/skeleton_shimmer.dart';
import '../../application/coupon_provider.dart';
import '../../modal/available_coupons_modal.dart';

class ApplyCouponScreen extends ConsumerWidget {
  const ApplyCouponScreen({super.key});

  static const Color _pageBg = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponAsync = ref.watch(availableCouponsProvider);

    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _pageBg,
        surfaceTintColor: _pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: _pageBg,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF0F172A),
            size: 18,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'APPLY COUPON',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.25,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: Column(
        children: [
          couponAsync.when(
            loading: () => const _CartTotalHeader(cartTotal: 0),
            error: (_, __) => const _CartTotalHeader(cartTotal: 0),
            data: (data) => _CartTotalHeader(cartTotal: data.cartTotal),
          ),
          const _CouponCodeInputRow(),
          const SizedBox(height: 10),
          Expanded(
            child: couponAsync.when(
              loading: () => const _CouponListSkeleton(),
              error: (error, stackTrace) => _CouponLoadError(
                message: error.toString(),
                onRetry: () => ref.invalidate(availableCouponsProvider),
              ),
              data: (data) => _CouponList(couponData: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartTotalHeader extends StatelessWidget {
  const _CartTotalHeader({required this.cartTotal});

  final int cartTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        'Your cart: ${_formatInr(cartTotal)}',
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CouponCodeInputRow extends StatelessWidget {
  const _CouponCodeInputRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Enter Coupon Code',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Manual coupon apply flow is not wired yet.'),
                ),
              );
            },
            child: const Text(
              'APPLY',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponList extends StatelessWidget {
  const _CouponList({required this.couponData});

  final AvailableCouponsModal couponData;

  @override
  Widget build(BuildContext context) {
    final coupons = couponData.coupons;

    if (coupons.isEmpty) {
      return const Center(
        child: Text(
          'No coupons available',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: coupons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(2, 8, 2, 10),
            child: Text(
              'More offers',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          );
        }

        final coupon = coupons[index - 1];
        return _CouponCard(coupon: coupon, isHighlighted: index == 1);
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.isHighlighted});

  final CouponModal coupon;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAEE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 56,
            decoration: BoxDecoration(
              color: isHighlighted
                  ? const Color(0xFFFF8500)
                  : const Color(0xFF4A5568),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _discountLabel(coupon),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          coupon.code,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: coupon.isApplicable
                            ? () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Selected ${coupon.code}. Apply API is pending.',
                                    ),
                                  ),
                                );
                              }
                            : null,
                        child: Text(
                          'APPLY',
                          style: TextStyle(
                            fontSize: 12,
                            color: coupon.isApplicable
                                ? const Color(0xFFFF6B00)
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _benefitTitle(coupon),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFFF6B00),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _benefitLine(coupon),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    coupon.description,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF475569),
                      height: 1.22,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '+ MORE',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w700,
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

class _CouponListSkeleton extends StatelessWidget {
  const _CouponListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(2, 8, 2, 10),
            child: SkeletonShimmerBox(
              height: 14,
              width: 92,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE8EAEE)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonShimmerBox(
                width: 56,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(10, 9, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonShimmerBox(
                        height: 12,
                        width: 110,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      SizedBox(height: 8),
                      SkeletonShimmerBox(
                        height: 10,
                        width: 92,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      SizedBox(height: 6),
                      SkeletonShimmerBox(
                        height: 10,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                      SizedBox(height: 7),
                      SkeletonShimmerBox(
                        height: 10,
                        width: 54,
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CouponLoadError extends StatelessWidget {
  const _CouponLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 34, color: Color(0xFFDC2626)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

String _discountLabel(CouponModal coupon) {
  if (coupon.discountType.toUpperCase() == 'PERCENTAGE') {
    return '${coupon.discountValue}% OFF';
  }
  return '${_formatInr(coupon.discountValue)} OFF';
}

String _benefitTitle(CouponModal coupon) {
  if (coupon.discountType.toUpperCase() == 'PERCENTAGE') {
    return 'Get ${coupon.discountValue}% Off';
  }
  return 'Get Flat ${_formatInr(coupon.discountValue)} Off';
}

String _benefitLine(CouponModal coupon) {
  if (coupon.message.trim().isNotEmpty) {
    return coupon.message;
  }
  return 'Min order ${_formatInr(coupon.minOrderAmount)}';
}

String _formatInr(int value) {
  final text = value.toString();
  if (text.length <= 3) {
    return '\u20b9$text';
  }

  final lastThree = text.substring(text.length - 3);
  var remaining = text.substring(0, text.length - 3);
  final parts = <String>[];

  while (remaining.length > 2) {
    parts.insert(0, remaining.substring(remaining.length - 2));
    remaining = remaining.substring(0, remaining.length - 2);
  }

  if (remaining.isNotEmpty) {
    parts.insert(0, remaining);
  }

  return '\u20b9${parts.join(',')},$lastThree';
}
