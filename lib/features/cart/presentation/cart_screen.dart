import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/cart_provider.dart';
import '../modal/cart_summary_modal.dart';
import 'widgets/apply_coupon_bottom_sheet.dart';
import 'widgets/select_slot_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
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
                    _ActionCard(
                      icon: Icons.discount_outlined,
                      title: 'Apply Coupon',
                      isPrimary: false,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ApplyCouponScreen(),
                          ),
                        );
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
                ? null
                : () => showSelectSlotBottomSheet(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B1F3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Select a slot',
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFF0B1F3A)
                : const Color(0xFFD1D5DB),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0EA5E9), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
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
