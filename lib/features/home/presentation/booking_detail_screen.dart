import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_provider.dart';
import '../../cart/modal/booking_details_modal.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({
    super.key,
    required this.bookingId,
  });

  final int bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late Future<BookingDetailsModal> _bookingFuture;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _loadBookingDetails();
  }

  Future<BookingDetailsModal> _loadBookingDetails() async {
    final cartRepo = ref.read(cartRepositoryProvider);
    return cartRepo.getUserBooking(bookingId: widget.bookingId);
  }

  void _refresh() {
    setState(() {
      _bookingFuture = _loadBookingDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        title: const Text(
          'Booking Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: FutureBuilder<BookingDetailsModal>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load booking details'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final booking = snapshot.data;
          if (booking == null) {
            return const Center(child: Text('Booking not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusBadge(booking),
              const SizedBox(height: 16),
              _buildServiceDetailsCard(booking),
              const SizedBox(height: 16),
              _buildBookingDetailsCard(booking),
              const SizedBox(height: 16),
              _buildHelperInfoCard(booking),
              const SizedBox(height: 16),
              _buildBillDetailsCard(booking),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(BookingDetailsModal booking) {
    Color backgroundColor = const Color(0xFFBBF7D0);
    Color textColor = const Color(0xFF064E3B);
    String statusLabel = 'Completed';

    if (booking.status.toLowerCase().contains('cancel')) {
      backgroundColor = const Color(0xFFFCA5A5);
      textColor = Colors.white;
      statusLabel = 'Canceled';
    } else if (booking.status.toLowerCase().contains('pending')) {
      backgroundColor = const Color(0xFFFFEDD5);
      textColor = const Color(0xFF7C2D12);
      statusLabel = 'Pending';
    } else if (booking.status.toLowerCase().contains('progress')) {
      backgroundColor = const Color(0xFFE0E7FF);
      textColor = const Color(0xFF3730A3);
      statusLabel = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildServiceDetailsCard(BookingDetailsModal booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.serviceDisplayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B6DD4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildServiceItem('Safe Cleaning', 250),
          const SizedBox(height: 8),
          _buildServiceItem('Deep Cleaning', 300),
          const SizedBox(height: 8),
          _buildServiceItem('Deep Cleaning', 340),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Less',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String name, int price) {
    return Row(
      children: [
        const SizedBox(width: 6),
        const Text(
          '•',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
        ),
        Text(
          '₹$price',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard(BookingDetailsModal booking) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking detail',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Booking ID: ${booking.id}',
            icon: Icons.info_outline,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            booking.displayDateLabel,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            '${booking.displayTimeLabel} • 2 hours 30 minutes',
            icon: Icons.access_time_outlined,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            booking.fullAddress ?? booking.address ?? 'Your Location',
            icon: Icons.location_on_outlined,
            subtitle: 'Malad, India',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String value, {
    IconData? icon,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: const Color(0xFF0B6DD4)),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelperInfoCard(BookingDetailsModal booking) {
    final helper = booking.helper;
    final user = helper?.user;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Helper Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: user?.profileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Image.network(
                          user!.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Helper',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFCD34D)),
                        const SizedBox(width: 4),
                        Text(
                          '${helper?.rating.toStringAsFixed(1) ?? '0.0'} (250+ reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetailsCard(BookingDetailsModal booking) {
    final amountToShow = booking.finalAmount;
    final taxToShow = booking.tax;
    final discountAmount = 150;
    final itemTotal = amountToShow + (discountAmount - taxToShow);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Item Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '₹${itemTotal.abs()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tax & Fare',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                '₹${taxToShow.abs()}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Discount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF10B981),
                ),
              ),
              Text(
                '-₹$discountAmount',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '₹${amountToShow.abs()}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
