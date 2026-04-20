import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../app/widgets/skeleton_shimmer.dart';
import '../../application/cart_provider.dart';
import '../../application/coupon_provider.dart';
import '../../modal/available_coupons_modal.dart';

class ApplyCouponScreen extends ConsumerStatefulWidget {
  const ApplyCouponScreen({super.key});

  static const Color _pageBg = Color(0xFFF3F4F6);

  @override
  ConsumerState<ApplyCouponScreen> createState() => _ApplyCouponScreenState();
}

class _ApplyCouponScreenState extends ConsumerState<ApplyCouponScreen> {
  String? _appliedCouponCode;
  String? _applyingCouponCode;
  String? _removingCouponCode;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(appliedCouponsProvider);
    });
  }

  Future<void> _onApplyCoupon(CouponModal coupon) async {
    if (
        !coupon.isApplicable ||
        _applyingCouponCode != null ||
        _removingCouponCode != null) {
      return;
    }

    setState(() {
      _applyingCouponCode = coupon.code;
    });

    try {
      final response = await ref
          .read(cartRepositoryProvider)
          .applyCoupon(couponCode: coupon.code);

      if (!mounted) {
        return;
      }

      setState(() {
        _appliedCouponCode = coupon.code;
      });

      ref.invalidate(appliedCouponsProvider);
      await ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _applyingCouponCode = null;
      });
    }
  }

  Future<void> _onRemoveCoupon(CouponModal coupon) async {
    if (_applyingCouponCode != null || _removingCouponCode != null) {
      return;
    }

    setState(() {
      _removingCouponCode = coupon.code;
    });

    try {
      final response = await ref
          .read(cartRepositoryProvider)
          .removeCoupon(couponCode: coupon.code);

      if (!mounted) {
        return;
      }

      setState(() {
        if (_appliedCouponCode == coupon.code) {
          _appliedCouponCode = null;
        }
      });

      ref.invalidate(appliedCouponsProvider);
      ref.invalidate(availableCouponsProvider);
      await ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        _removingCouponCode = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final couponAsync = ref.watch(availableCouponsProvider);
    final appliedCouponsAsync = ref.watch(appliedCouponsProvider);
    final cartCoupon = ref.watch(cartProvider).summary?.coupon;

    final appliedCouponCodes = <String>{if (_appliedCouponCode != null) _appliedCouponCode!};

    final summaryCouponCode = cartCoupon is Map<String, dynamic>
        ? cartCoupon['code']?.toString()
        : null;
    if (summaryCouponCode != null && summaryCouponCode.isNotEmpty) {
      appliedCouponCodes.add(summaryCouponCode);
    }

    appliedCouponsAsync.whenData((data) {
      for (final coupon in data.coupons) {
        if (coupon.code.isNotEmpty) {
          appliedCouponCodes.add(coupon.code);
        }
      }
    });

    return Scaffold(
      backgroundColor: ApplyCouponScreen._pageBg,
      appBar: AppBar(
        backgroundColor: ApplyCouponScreen._pageBg,
        surfaceTintColor: ApplyCouponScreen._pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: ApplyCouponScreen._pageBg,
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
          const SizedBox(height: 12),
          Expanded(
            child: couponAsync.when(
              loading: () => const _CouponListSkeleton(),
              error: (error, stackTrace) => _CouponLoadError(
                message: error.toString(),
                onRetry: () => ref.invalidate(availableCouponsProvider),
              ),
              data: (data) => _CouponList(
                couponData: data,
                appliedCouponCodes: appliedCouponCodes,
                applyingCouponCode: _applyingCouponCode,
                removingCouponCode: _removingCouponCode,
                onApplyCoupon: _onApplyCoupon,
                onRemoveCoupon: _onRemoveCoupon,
              ),
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
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Text(
        'Your cart: ${_formatInr(cartTotal)}',
        style: const TextStyle(
          fontSize: 12,
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
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
                fontSize: 13,
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
                fontSize: 12,
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
  const _CouponList({
    required this.couponData,
    required this.appliedCouponCodes,
    required this.applyingCouponCode,
    required this.removingCouponCode,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  final AvailableCouponsModal couponData;
  final Set<String> appliedCouponCodes;
  final String? applyingCouponCode;
  final String? removingCouponCode;
  final ValueChanged<CouponModal> onApplyCoupon;
  final ValueChanged<CouponModal> onRemoveCoupon;

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
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      itemCount: coupons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(2, 12, 2, 14),
            child: Text(
              'More offers',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          );
        }

        final coupon = coupons[index - 1];
        final isApplied = appliedCouponCodes.contains(coupon.code);
        final isApplying = applyingCouponCode == coupon.code;
        final isRemoving = removingCouponCode == coupon.code;

        return _CouponCard(
          coupon: coupon,
          isApplied: isApplied,
          isApplying: isApplying,
          isRemoving: isRemoving,
          onApplyTap: () => onApplyCoupon(coupon),
          onRemoveTap: () => onRemoveCoupon(coupon),
        );
      },
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.isApplied,
    required this.isApplying,
    required this.isRemoving,
    required this.onApplyTap,
    required this.onRemoveTap,
  });

  final CouponModal coupon;
  final bool isApplied;
  final bool isApplying;
    final bool isRemoving;
  final VoidCallback onApplyTap;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final isBusy = isApplying || isRemoving;
    final canApply = coupon.isApplicable && !isApplied && !isBusy;
    final stripColor = coupon.isApplicable
        ? const Color(0xFFFF8500)
        : const Color(0xFF4B5563);
    final actionLabel = isRemoving
      ? 'REMOVING...'
      : isApplying
      ? 'APPLYING...'
      : (isApplied ? 'Remove' : 'APPLY');
    final actionColor = isApplied
      ? const Color(0xFFDC2626)
        : canApply
        ? const Color(0xFFFF6B00)
        : const Color(0xFF9CA3AF);
    final onActionTap = isBusy
      ? null
      : (isApplied ? onRemoveTap : (canApply ? onApplyTap : null));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      constraints: const BoxConstraints(minHeight: 168),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8EAEE)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 82,
              decoration: BoxDecoration(
                color: stripColor,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    _discountLabel(coupon),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            coupon.code,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: onActionTap,
                          child: Text(
                            actionLabel,
                            style: TextStyle(
                              fontSize: 15,
                              color: actionColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _benefitTitle(coupon),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFF6B00),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _benefitLine(coupon),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      coupon.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                        height: 1.32,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      '+ MORE',
                      style: TextStyle(
                        fontSize: 13,
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
      ),
    );
  }
}

class _CouponListSkeleton extends StatelessWidget {
  const _CouponListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
      itemCount: 5,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(2, 12, 2, 14),
            child: SkeletonShimmerBox(
              height: 20,
              width: 128,
              borderRadius: BorderRadius.all(Radius.circular(6)),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          constraints: const BoxConstraints(minHeight: 168),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE8EAEE)),
          ),
          child: const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonShimmerBox(
                  width: 82,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonShimmerBox(
                          height: 16,
                          width: 142,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        SizedBox(height: 10),
                        SkeletonShimmerBox(
                          height: 13,
                          width: 118,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        SizedBox(height: 9),
                        SkeletonShimmerBox(
                          height: 13,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        SizedBox(height: 10),
                        SkeletonShimmerBox(
                          height: 13,
                          width: 66,
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
