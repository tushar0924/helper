import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/cart_provider.dart';
import '../application/coupon_provider.dart';
import '../modal/applied_coupons_modal.dart';
import '../modal/cart_summary_modal.dart';
import 'booking_confirmed_screen.dart';
import 'widgets/apply_coupon_bottom_sheet.dart';
import 'widgets/search_partner_dialog.dart';
import 'widgets/select_slot_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isSearchingPartner = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CartState>(cartProvider, (_, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final state = ref.watch(cartProvider);
    final summary = state.summary ?? CartSummaryModal.empty();
    final items = summary.items;
    final appliedCouponsAsync = ref.watch(appliedCouponsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: state.isMutating
                  ? null
                  : () {
                      ref.read(cartProvider.notifier).clearCart();
                    },
              child: const Text('Clear Cart'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${items.length} services added',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () {
                ref.invalidate(appliedCouponsProvider);
                return ref
                    .read(cartProvider.notifier)
                    .loadSummary(forceRefresh: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: [
                    if (items.isEmpty)
                      _SimpleTile(
                        child: Column(
                          children: [
                            const Text(
                              'No services added yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Continue browsing'),
                            ),
                          ],
                        ),
                      ),
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _CartServiceTile(item: item),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ActionCard(
                      icon: Icons.add_box_outlined,
                      title: 'Add more services',
                      isPrimary: false,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(height: 10),
                    _SimpleTile(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Color(0xFF0EA5E9),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Service Address',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => _showComingSoonSheet(
                                  context,
                                  title: 'Change address',
                                  message:
                                      'Address selection is not connected yet.',
                                ),
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            summary.address?.label ?? 'Not selected',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            summary.address != null
                                ? '${summary.address!.address}, ${summary.address!.city} - ${summary.address!.pinCode}'
                                : 'Select an address for delivery and service execution',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SimpleTile(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Booking Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: items.isEmpty
                                    ? null
                                    : () => showSelectSlotBottomSheet(
                                        context,
                                        summary,
                                      ),
                                child: const Text('Change Slot'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _slotInfoRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date',
                            value: _formatBookingDate(summary.slot.date),
                          ),
                          const SizedBox(height: 8),
                          _slotInfoRow(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: _formatBookingTime(summary.slot.time),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _AppliedCouponsCard(
                      appliedCouponsAsync: appliedCouponsAsync,
                      summary: summary,
                      onTapApplyCoupon: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ApplyCouponScreen(),
                          ),
                        );
                        if (!mounted) {
                          return;
                        }

                        ref.invalidate(appliedCouponsProvider);
                        await ref
                            .read(cartProvider.notifier)
                            .loadSummary(forceRefresh: true);
                      },
                    ),
                    const SizedBox(height: 10),
                    _SimpleTile(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Details',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _billRow(
                            'Item Total',
                            formatInr(summary.pricing.itemTotal),
                          ),
                          _billRow(
                            'Add-ons',
                            formatInr(summary.pricing.addonTotal),
                          ),
                          _billRow(
                            'Discount',
                            '-${formatInr(summary.pricing.discount.abs())}',
                            valueColor: const Color(0xFF16A34A),
                          ),
                          _billRow(
                            'Tax & fee',
                            formatInr(summary.pricing.taxAndFee),
                          ),
                          const Divider(height: 24, color: Color(0xFFE5E7EB)),
                          _billRow(
                            'Total Amount',
                            formatInr(summary.pricing.total),
                            isTotal: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: items.isEmpty
                || _isSearchingPartner
                ? null
                : () => _onSearchPartnerTap(summary),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B1F3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSearchingPartner
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Search Partner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSearchPartnerTap(CartSummaryModal summary) async {
    if (_isSearchingPartner) {
      return;
    }

    setState(() {
      _isSearchingPartner = true;
    });

    final partnerFound = await showSearchPartnerDialog(context);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchingPartner = false;
    });

    if (!partnerFound) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmedScreen(summary: summary),
      ),
    );
  }

  Widget _billRow(
    String label,
    String value, {
    Color? valueColor,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 22 : 15,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 30 : 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _formatBookingDate(String? rawDate) {
  final date = DateTime.tryParse(rawDate ?? '');
  if (date == null) {
    return 'Not selected';
  }

  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final weekday = weekdays[date.weekday - 1];
  final month = months[date.month - 1];
  return '$weekday, $month ${date.day}, ${date.year}';
}

String _formatBookingTime(String? rawTime) {
  if (rawTime == null || rawTime.trim().isEmpty) {
    return 'Not selected';
  }

  final parts = rawTime.split(':');
  if (parts.length < 2) {
    return rawTime;
  }

  final hour24 = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour24 == null || minute == null) {
    return rawTime;
  }

  var hour12 = hour24 % 12;
  if (hour12 == 0) {
    hour12 = 12;
  }
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
}

class _AppliedCouponsCard extends StatelessWidget {
  const _AppliedCouponsCard({
    required this.appliedCouponsAsync,
    required this.summary,
    required this.onTapApplyCoupon,
  });

  final AsyncValue<AppliedCouponsModal> appliedCouponsAsync;
  final CartSummaryModal summary;
  final VoidCallback onTapApplyCoupon;

  @override
  Widget build(BuildContext context) {
    final fallbackRows = _fallbackAppliedCouponRows(summary);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTapApplyCoupon,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: const [
                  Icon(Icons.discount_outlined, color: Color(0xFF0EA5E9), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Apply Coupon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          appliedCouponsAsync.when(
            loading: () {
              if (fallbackRows.isEmpty) {
                return const SizedBox.shrink();
              }
              return _AppliedCouponRows(messages: fallbackRows);
            },
            error: (_, __) {
              if (fallbackRows.isEmpty) {
                return const SizedBox.shrink();
              }
              return _AppliedCouponRows(messages: fallbackRows);
            },
            data: (appliedData) {
              final rows = appliedData.coupons
                  .map((coupon) => coupon.message)
                  .where((message) => message.trim().isNotEmpty)
                  .toList(growable: false);

              if (rows.isEmpty && fallbackRows.isEmpty) {
                return const SizedBox.shrink();
              }

              return _AppliedCouponRows(messages: rows.isEmpty ? fallbackRows : rows);
            },
          ),
        ],
      ),
    );
  }
}

class _AppliedCouponRows extends StatelessWidget {
  const _AppliedCouponRows({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          ...messages.map(
            (message) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(
                    Icons.discount_outlined,
                    size: 16,
                    color: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check,
                    size: 14,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    'Applied',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
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

List<String> _fallbackAppliedCouponRows(CartSummaryModal summary) {
  final discountAmount = summary.pricing.discount.abs();
  final coupon = summary.coupon;
  if (discountAmount <= 0 && coupon is! Map<String, dynamic>) {
    return const <String>[];
  }

  var offerText = 'applied coupon';
  if (coupon is Map<String, dynamic>) {
    final discountType = coupon['discountType']?.toString().toUpperCase() ?? '';
    final discountValue = _parseInt(coupon['discountValue']);
    if (discountType.startsWith('PERCENT') && discountValue > 0) {
      offerText = 'flat $discountValue% off';
    } else if (discountValue > 0) {
      offerText = 'flat ${formatInr(discountValue)} off';
    }
  }

  if (discountAmount <= 0 && coupon is Map<String, dynamic>) {
    final code = coupon['code']?.toString() ?? '';
    if (code.isNotEmpty) {
      return <String>['$code applied with $offerText'];
    }
    return <String>['Coupon applied with $offerText'];
  }

  return <String>['${formatInr(discountAmount)} saved with $offerText'];
}

int _parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final cleaned = (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9-]'), '');
  if (cleaned.isEmpty || cleaned == '-') {
    return 0;
  }
  return int.tryParse(cleaned) ?? 0;
}

void _showComingSoonSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: const _DashedRoundedRectPainter(
          color: Color(0xFF000000),
          strokeWidth: 1.2,
          gap: 3.2,
          dash: 1,
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF0097D5), size: 14),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0097D5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance =
            (distance + dash).clamp(0.0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _CartServiceTile extends ConsumerWidget {
  const _CartServiceTile({required this.item});

  final CartItemModal item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disableIncrement =
        item.quantity >= CartController.maxQuantity ||
        ref.watch(cartProvider).isMutating;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 66,
              height: 66,
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.cleaning_services_outlined),
                    )
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFFE5E7EB));
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatInr(item.priceAtAdded),
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: item.quantity <= 1
                                ? null
                                : () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .decrementByServiceId(item.serviceId);
                                  },
                            child: const Icon(
                              Icons.remove,
                              size: 20,
                              color: Color(0xFF0097D5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: disableIncrement
                                ? null
                                : () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .incrementByServiceId(item.serviceId);
                                  },
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: disableIncrement
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF00B6B5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.duration == 1 ? '1 hr' : '${item.duration} hrs',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
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
