import 'package:flutter/material.dart';

import '../application/cart_provider.dart';
import '../modal/cart_summary_modal.dart';

class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key, required this.summary});

  final CartSummaryModal summary;

  @override
  Widget build(BuildContext context) {
    final services = summary.items;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, size: 24, color: Color(0xFF0F172A)),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Confirmed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'A partner has been assigned to your service',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
        child: Column(
          children: [
            _AssignedInfoCard(),
            const SizedBox(height: 10),
            const _PartnerCard(),
            const SizedBox(height: 10),
            _ServiceDetailsCard(summary: summary, services: services),
            const SizedBox(height: 10),
            _AddressCard(summary: summary),
            const SizedBox(height: 10),
            _BookingDetailsCard(summary: summary),
            const SizedBox(height: 10),
            _ApplyCouponRow(),
            const SizedBox(height: 10),
            _BillCard(summary: summary),
            const SizedBox(height: 10),
            _PendingPaymentCard(total: summary.pricing.total),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(13, 0, 13, 13),
        child: SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B1F3A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.credit_card, size: 19, color: Colors.white),
            label: Text(
              'Pay Now ${formatInr(summary.pricing.total)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AssignedInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFE8CC)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: Color(0xFF16A34A)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partner Assigned',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your partner will arrive at the scheduled time',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFE5E7EB),
            child: Icon(Icons.person, size: 28, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priya Sharma',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '4.8',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '5+ years experience',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                SizedBox(height: 2),
                Text(
                  'Police Verification',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                SizedBox(height: 2),
                Text(
                  'HelperJay Trusted & Trained',
                  style: TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
          _ActionIcon(
            icon: Icons.call,
            color: const Color(0xFF0B1F3A),
            iconColor: Colors.white,
          ),
          const SizedBox(width: 8),
          _ActionIcon(
            icon: Icons.chat,
            color: const Color(0xFFF97316),
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 17, color: iconColor),
    );
  }
}

class _ServiceDetailsCard extends StatelessWidget {
  const _ServiceDetailsCard({required this.summary, required this.services});

  final CartSummaryModal summary;
  final List<CartItemModal> services;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Cleaning Service',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B6DD4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...services.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Text(
                    '•',
                    style: TextStyle(fontSize: 15, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Text(
                    formatInr(_lineAmount(item)),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Text(
            'Less',
            style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
          ),
          const Divider(height: 18, color: Color(0xFFE5E7EB)),
          Row(
            children: const [
              Text(
                'Total Service Hours',
                style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
              ),
              Spacer(),
              Text(
                '2 hours 30 minutes',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _lineAmount(CartItemModal item) {
    if (item.totalPrice > 0) {
      return item.totalPrice;
    }
    return item.priceAtAdded * item.quantity;
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.summary});

  final CartSummaryModal summary;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF0EA5E9)),
              const SizedBox(width: 10),
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
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Change', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Text(
            summary.address?.label ?? 'Home',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            summary.address != null
                ? '${summary.address!.address}, ${summary.address!.city} - ${summary.address!.pinCode}'
                : '123 Park Avenue, Sector 21, New Metro Station, Mumbai - 400001',
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({required this.summary});

  final CartSummaryModal summary;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
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
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                child: const Text('Change Slot', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            title: 'Date',
            value: _formatBookingDate(summary.slot.date),
            iconColor: const Color(0xFF1F2937),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.access_time,
            title: 'Time',
            value: '${_formatBookingTime(summary.slot.time)} to 08:30 AM',
            iconColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApplyCouponRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Row(
        children: const [
          Icon(Icons.discount_outlined, size: 20, color: Color(0xFF0EA5E9)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Apply Coupon',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.summary});

  final CartSummaryModal summary;

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _billRow('Item Total', formatInr(summary.pricing.itemTotal)),
          _billRow('Tax & fare', formatInr(summary.pricing.taxAndFee)),
          _billRow(
            'Discount',
            '-${formatInr(summary.pricing.discount.abs())}',
            valueColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 8),
          _billRow(
            'Total Amount',
            formatInr(summary.pricing.total),
            isTotal: true,
          ),
        ],
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 28 : 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingPaymentCard extends StatelessWidget {
  const _PendingPaymentCard({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.error_outline, size: 20, color: Color(0xFFF97316)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Payment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9A3412),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Complete payment within 10 minutes to confirm\nyour booking',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Color(0xFF9A3412),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '10:00',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}

String _formatBookingDate(String? rawDate) {
  final date = DateTime.tryParse(rawDate ?? '');
  if (date == null) {
    return 'Thursday, November 6, 2025';
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
    return '06:00 AM';
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
