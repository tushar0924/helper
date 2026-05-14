import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/utils/app_toast.dart';
import '../../../app/widgets/skeleton_shimmer.dart';
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
      if (!mounted) return;

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
    final isTerminal = status.contains('COMPLETE') ||
        status.contains('CANCELLED') ||
        status.contains('CANCELED');
    final isTrackingStage = status.contains('ARRIVE') ||
        status.contains('START') ||
        status.contains('ONGOING') ||
        status.contains('ON THE WAY') ||
        status.contains('INPROGRESS') ||
        status.contains('IN_PROGRESS');

    return hasOtp && !isTerminal && isTrackingStage;
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
        address: booking.fullAddress ?? booking.address ?? booking.location ?? '',
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
        backgroundColor: const Color(0xFF0B2132), // Darker shade as per image
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Booking Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white),
          )
        ],
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      body: FutureBuilder<BookingDetailsModal>(
        future: _bookingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildDetailsSkeleton();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading details'));
          }

          final booking = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildServiceDetailsCard(booking),
                const SizedBox(height: 20),
                _buildBookingDetailCard(booking),
                const SizedBox(height: 20),
                _buildHelperCard(booking),
                const SizedBox(height: 20),
                _buildBillDetailsCard(booking),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailsSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          _buildServiceDetailsCardSkeleton(),
          const SizedBox(height: 20),
          _buildBookingDetailCardSkeleton(),
          const SizedBox(height: 20),
          _buildHelperCardSkeleton(),
          const SizedBox(height: 20),
          _buildBillDetailsCardSkeleton(),
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCardSkeleton() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7EAF0), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SkeletonShimmerBox(
                    height: 24,
                    width: 100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonShimmerBox(
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
              const SizedBox(height: 8),
              SkeletonShimmerBox(
                height: 24,
                width: 80,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              SkeletonShimmerBox(
                height: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetailCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SkeletonShimmerBox(
            height: 12,
            width: 150,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShimmerBox(
                  height: 12,
                  width: 80,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                SkeletonShimmerBox(
                  height: 14,
                  width: 200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHelperCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Helper Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonShimmerBox(
                height: 48,
                width: 48,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonShimmerBox(
                      height: 15,
                      width: 150,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    SkeletonShimmerBox(
                      height: 12,
                      width: 200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBillDetailsCardSkeleton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...List.generate(3, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonShimmerBox(
                  height: 12,
                  width: 80,
                  borderRadius: BorderRadius.circular(4),
                ),
                SkeletonShimmerBox(
                  height: 12,
                  width: 80,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonShimmerBox(
                height: 14,
                width: 100,
                borderRadius: BorderRadius.circular(4),
              ),
              SkeletonShimmerBox(
                height: 16,
                width: 100,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildServiceDetailsCard(BookingDetailsModal booking) {
    final status = booking.status.toUpperCase();
    final isCompleted = status.contains('COMPLETE');
    final isConfirmed = status.contains('CONFIRM');
    final isCancelled = status.contains('CANCEL');
    final showStatusBadge = isCompleted || isConfirmed || isCancelled;
    
    late Color borderColor;
    late Color badgeColor;
    late String badgeLabel;
    
    if (isCancelled) {
      borderColor = const Color(0xFFEF4444);
      badgeColor = const Color(0xFFEF4444);
      badgeLabel = 'Cancelled';
    } else if (isCompleted) {
      borderColor = const Color(0xFF22C55E);
      badgeColor = const Color(0xFF00C853);
      badgeLabel = 'Completed';
    } else if (isConfirmed) {
      borderColor = const Color(0xFF22C55E);
      badgeColor = const Color(0xFF00C853);
      badgeLabel = 'Confirmed';
    } else {
      borderColor = const Color(0xFFE7EAF0);
      badgeColor = const Color(0xFF00C853);
      badgeLabel = booking.statusDisplayLabel;
    }
    
    final serviceRows = booking.items.isNotEmpty
        ? booking.items
        : <BookingItemModal>[];

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Service Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      booking.serviceLabel,
                      style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (serviceRows.isNotEmpty)
                ...serviceRows.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: Color(0xFF0F172A)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.serviceName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                              decorationStyle: TextDecorationStyle.dashed,
                            ),
                          ),
                        ),
                        Text(
                          _formatDurationLabel(item.duration),
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Color(0xFF0F172A)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Service details unavailable',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      Text(
                        booking.totalServiceHoursLabel,
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Less', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Service Hours', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    booking.totalServiceHoursLabel,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              )
            ],
          ),
        ),
        if (showStatusBadge)
          Positioned(
            top: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badgeLabel,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBookingDetailCard(BookingDetailsModal booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Booking ID: ${booking.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          _detailItem(Icons.calendar_today_outlined, 'Date', booking.displayDateLabel),
          const SizedBox(height: 16),
          _detailItem(Icons.access_time, 'Time & Duration', booking.bookingTimeAndDurationLabel),
          const SizedBox(height: 16),
          _detailItem(Icons.location_on_outlined, 'Service Location', 'Your Location', subValue: booking.locationLabel),
        ],
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value, {String? subValue}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.lightBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              if (subValue != null) Text(subValue, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildHelperCard(BookingDetailsModal booking) {
    final helper = booking.helper;
    final helperName = helper?.displayName.trim().isNotEmpty == true
        ? helper!.displayName
        : (booking.customer?.fullName.trim().isNotEmpty == true
            ? booking.customer!.fullName
            : 'Helper Assigned Soon');
    final helperRating = helper?.rating ?? 4.8;
    final helperReviews = helper?.totalRatings ?? 250;
    final imageUrl = helper?.user?.profileImage?.trim().isNotEmpty == true
        ? helper!.user!.profileImage
        : helper?.profileImage?.trim().isNotEmpty == true
            ? helper!.profileImage
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Helper Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF0B2132),
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(helperName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        const SizedBox(width: 4),
                        Text('$helperRating ($helperReviews+ reviews)', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBillDetailsCard(BookingDetailsModal booking) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _billRow('Item Total', '₹${booking.totalAmount}'),
          _billRow('Tax & fare', '₹${booking.tax}', isDashed: true),
          _billRow('Discount', '-₹${(booking.totalAmount + booking.tax) - booking.finalAmount}', color: Colors.green),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₹${booking.finalAmount}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? color, bool isDashed = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.black54,
              decoration: isDashed ? TextDecoration.underline : null,
              decorationStyle: isDashed ? TextDecorationStyle.dashed : null,
            ),
          ),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Widget _contactActionButton({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }

  String _formatDurationLabel(int duration) {
    if (duration <= 0) {
      return '1 hour';
    }

    return duration == 1 ? '1 hour' : '$duration hours';
  }

  String _formatTotalHoursLabel(int totalHours) {
    if (totalHours <= 0) {
      return 'Duration unavailable';
    }

    return totalHours == 1 ? '1 hour 30 minutes' : '$totalHours hours 30 minutes';
  }
}