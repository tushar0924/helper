import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/application/cart_provider.dart';
import '../../cart/modal/booking_details_modal.dart';
import '../../cart/modal/cart_summary_modal.dart';
import '../../cart/presentation/booking_tracking_screen.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  late Future<BookingDetailsModal> _bookingFuture;
  bool _navigatedToOtpScreen = false;

  @override
  void initState() {
    super.initState();
    _bookingFuture = _loadBookingDetails();
  }

  Future<BookingDetailsModal> _loadBookingDetails() async {
    final cartRepo = ref.read(cartRepositoryProvider);
    final booking = await cartRepo.getUserBooking(bookingId: widget.bookingId);
    _maybeNavigateToOtpScreen(booking);
    return booking;
  }

  void _maybeNavigateToOtpScreen(BookingDetailsModal booking) {
    if (_navigatedToOtpScreen || !_shouldOpenOtpScreen(booking)) {
      return;
    }

    _navigatedToOtpScreen = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookingTrackingScreen(
            summary: _buildSummaryFromBooking(booking),
            bookingId: booking.id,
            bookingDetails: booking,
            partnerDetails: booking.toPartnerDetailsMap(),
          ),
        ),
      );
    });
  }

  bool _shouldOpenOtpScreen(BookingDetailsModal booking) {
    final status = booking.status.toUpperCase();
    final hasOtp = booking.otpLabel != '----';
    final isTerminal =
        status.contains('COMPLETE') ||
        status.contains('CANCELLED') ||
        status.contains('CANCELED');

    return hasOtp && !isTerminal;
  }

  CartSummaryModal _buildSummaryFromBooking(BookingDetailsModal booking) {
    final items = booking.items
        .map(
          (item) => CartItemModal(
            serviceId: item.serviceId,
            name: item.serviceName,
            imageUrl: item.imageUrl,
            priceAtAdded: item.price,
            originalPrice: item.price,
            totalPrice: item.price * (item.quantity <= 0 ? 1 : item.quantity),
            duration: item.duration,
            quantity: item.quantity <= 0 ? 1 : item.quantity,
            addons: const <Object?>[],
          ),
        )
        .toList(growable: false);

    return CartSummaryModal(
      cartId: booking.id,
      items: items,
      slot: CartSlotModal(
        date: booking.bookingDate?.toIso8601String(),
        time: booking.startTimeLabel,
      ),
      address: CartAddressModal(
        id: 0,
        label: booking.customer?.fullName.isNotEmpty == true
            ? booking.customer!.fullName
            : 'Service Location',
        address:
            booking.fullAddress ?? booking.address ?? booking.location ?? '',
        city: booking.city ?? '',
        pinCode: booking.pinCode ?? '',
        latitude: booking.latitude,
        longitude: booking.longitude,
      ),
      coupon: null,
      pricing: CartPricingModal(
        itemTotal: booking.totalAmount,
        addonTotal: 0,
        discount: 0,
        taxAndFee: booking.tax,
        total: booking.finalAmount,
      ),
      lastUpdatedAt: booking.updatedAt,
    );
  }

  void _refresh() {
    setState(() {
      _bookingFuture = _loadBookingDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B2A4A),
        elevation: 0,
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
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

          if (_shouldOpenOtpScreen(booking)) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatusBadge(booking),
                ),
                const SizedBox(height: 16),
                _buildServiceDetailsCard(booking),
                const SizedBox(height: 14),
                _buildBookingDetailsCard(booking),
                const SizedBox(height: 14),
                _buildHelperInfoCard(booking),
                const SizedBox(height: 14),
                _buildBillDetailsCard(booking),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(BookingDetailsModal booking) {
    Color backgroundColor = const Color(0xFFE7F8EC);
    Color textColor = const Color(0xFF16A34A);
    String statusLabel = 'Completed';

    final normalized = booking.status.toUpperCase();

    if (normalized.contains('CANCEL')) {
      backgroundColor = const Color(0xFFFFE4E6);
      textColor = const Color(0xFFEF4444);
      statusLabel = 'Canceled';
    } else if (normalized.contains('COMPLETE')) {
      backgroundColor = const Color(0xFFE7F8EC);
      textColor = const Color(0xFF16A34A);
      statusLabel = 'Completed';
    } else if (normalized.contains('CONFIRMED') ||
        normalized.contains('PENDING') ||
        normalized.contains('ACCEPTED')) {
      backgroundColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFF97316);
      statusLabel = 'Scheduled';
    } else if (normalized.contains('PROGRESS') ||
        normalized.contains('STARTED')) {
      backgroundColor = const Color(0xFFEFF6FF);
      textColor = const Color(0xFF2563EB);
      statusLabel = 'In Progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        statusLabel,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildServiceDetailsCard(BookingDetailsModal booking) {
    final serviceItems = booking.items;
    final fallbackHours = booking.totalHours > 0
        ? booking.totalHours
        : booking.duration;
    final totalHours = fallbackHours > 0
        ? fallbackHours
        : serviceItems.fold<int>(
            0,
            (sum, item) =>
                sum +
                ((item.quantity <= 0 ? 1 : item.quantity) * item.duration),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.serviceDisplayName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0B6DD4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (serviceItems.isNotEmpty)
            ...serviceItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildServiceItem(
                  item.serviceName,
                  item.duration <= 1 ? '1 hour' : '${item.duration} hours',
                ),
              ),
            )
          else
            _buildServiceItem(
              booking.serviceDisplayName,
              totalHours <= 1 ? '1 hour' : '$totalHours hours',
            ),
          const SizedBox(height: 10),
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
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Divider(height: 20, thickness: 1, color: Color(0xFFEAECEF)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Service Hours',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151),
                ),
              ),
              Text(
                '${totalHours == 1 ? '1 hour' : '$totalHours hours'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String name, String duration) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Icon(Icons.circle, size: 5, color: Color(0xFF111827)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Text(
          duration,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailsCard(BookingDetailsModal booking) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking detail',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Booking ID: ${booking.id}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          _buildDetailRow(
            'Date',
            value: booking.displayDateLabel,
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Time & Duration',
            value:
                '${booking.displayTimeLabel} • ${(booking.totalHours > 0 ? booking.totalHours : booking.duration)} hours',
            icon: Icons.access_time_outlined,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Service Location',
            value: booking.fullAddress ?? booking.address ?? 'Your Location',
            icon: Icons.location_on_outlined,
            subtitle: [
              booking.city,
              booking.pinCode,
            ].whereType<String>().where((e) => e.trim().isNotEmpty).join(', '),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String title, {
    required String value,
    IconData? icon,
    String? subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 17, color: const Color(0xFF1E88E5)),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Helper Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
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
                      helper?.displayName ?? 'Helper',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${helper?.rating.toStringAsFixed(1) ?? '0.0'} (${helper?.totalRatings ?? 0}+ reviews)',
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
    final taxToShow = booking.tax < 0 ? booking.tax.abs() : booking.tax;
    final itemTotal = booking.totalAmount <= 0
        ? amountToShow
        : booking.totalAmount;
    final discountAmount = (itemTotal + taxToShow) - amountToShow;
    final normalizedDiscount = discountAmount > 0 ? discountAmount : 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bill Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
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
                '-₹$normalizedDiscount',
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
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                '₹${amountToShow.abs()}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
