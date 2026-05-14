import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/widgets/skeleton_shimmer.dart';
import '../../cart/modal/booking_details_modal.dart';
import '../../cart/modal/cart_summary_modal.dart';
import '../../cart/presentation/booking_tracking_screen.dart';
import '../../../network/api_client.dart';
import '../../auth/application/auth_provider.dart';
import 'booking_detail_screen.dart';

class BookingsOrdersScreen extends ConsumerStatefulWidget {
  const BookingsOrdersScreen({super.key});

  @override
  ConsumerState<BookingsOrdersScreen> createState() =>
      _BookingsOrdersScreenState();
}

class _BookingsOrdersScreenState extends ConsumerState<BookingsOrdersScreen> {
  late Future<List<BookingDetailsModal>> _future;
  int _selectedIndex = 0; // 0 = Helper4u, 1 = Kirana4u
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _future = _loadBookings();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  Future<List<BookingDetailsModal>> _loadBookings() async {
    final api = ref.read(apiClientProvider);
    final json = await api.getJson('user/bookings', requiresAuth: true);
    final data = json['data'];
    if (data is List) {
      return data
          .map((e) => BookingDetailsModal.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return <BookingDetailsModal>[];
  }

  void _refresh() {
    setState(() {
      _future = _loadBookings();
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
          'Booking & Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.more_vert, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildSearchBox(),
            const SizedBox(height: 12),
            _buildTabs(),
            const SizedBox(height: 12),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search for help or stores nearby...',
                hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(color: Color(0xFF111827)),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _onSearchChanged();
              },
              child: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedIndex == 0
                    ? const Color(0xFF0B2A4A)
                    : const Color(0xFFE8EEF6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 18,
                    color: _selectedIndex == 0
                        ? Colors.white
                        : const Color(0xFF0B2A4A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Helper4u',
                    style: TextStyle(
                      color: _selectedIndex == 0
                          ? Colors.white
                          : const Color(0xFF0B2A4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedIndex = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedIndex == 1
                    ? const Color(0xFF0B2A4A)
                    : const Color(0xFFE8EEF6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_outlined,
                    size: 17,
                    color: _selectedIndex == 1
                        ? Colors.white
                        : const Color(0xFF0B2A4A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Kirana4u',
                    style: TextStyle(
                      color: _selectedIndex == 1
                          ? Colors.white
                          : const Color(0xFF0B2A4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) {
      return _buildKiranaEmpty();
    }

    return FutureBuilder<List<BookingDetailsModal>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoading();
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Failed to load bookings'),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          );
        }

        var bookings = snapshot.data ?? <BookingDetailsModal>[];

        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          bookings = bookings.where((b) {
            final categoryName = b.categoryName?.toLowerCase() ?? '';
            final serviceName = b.serviceDisplayName.toLowerCase();
            return categoryName.contains(_searchQuery) ||
                serviceName.contains(_searchQuery);
          }).toList();
        }

        if (bookings.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'No bookings found for "$_searchQuery"'
                  : 'No bookings found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            final b = bookings[index];
            return _buildBookingCard(b);
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.separated(
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _buildBookingCardSkeleton(),
    );
  }

  Widget _buildBookingCardSkeleton() {
    return Container(
      constraints: const BoxConstraints(minHeight: 162),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SkeletonShimmerBox(
                  height: 34,
                  width: 34,
                  borderRadius: BorderRadius.circular(7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SkeletonShimmerBox(
                    height: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                SkeletonShimmerBox(
                  height: 18,
                  width: 60,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShimmerBox(
                  height: 14,
                  width: double.infinity,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                SkeletonShimmerBox(
                  height: 14,
                  width: 200,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 10),
                SkeletonShimmerBox(
                  height: 14,
                  width: 150,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKiranaEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'You have no orders in Kirana4u',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BookingDetailsModal b) {
    final status = _bookingStatusFor(b.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onBookingTap(b),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 162),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE3EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildBookingThumbnail(b),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b.serviceDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.1,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _BookingStatusPill(status: status),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookingMetaRow(
                      icon: Icons.calendar_today_outlined,
                      text: b.displayDateLabel,
                    ),
                    const SizedBox(height: 10),
                    _BookingMetaRow(
                      icon: Icons.access_time_outlined,
                      text: b.displayTimeLabel,
                    ),
                    const SizedBox(height: 10),
                    _BookingMetaRow(
                      svgAssetPath: 'assets/images/ruppee.svg',
                      text: '₹${b.finalAmount.abs()}',
                    ),
                    if (status.showRatings) ...[
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F2F5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BookingRatingBlock(
                              title: 'Service Rating',
                              isRated: b.isServiceRated,
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _BookingRatingBlock(
                              title: 'Partner Rating',
                              isRated: b.isPartnerRated,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onBookingTap(BookingDetailsModal booking) {
    if (_shouldOpenOtpScreen(booking)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingTrackingScreen(
            summary: _buildSummaryFromBooking(booking),
            bookingId: booking.id,
            bookingDetails: booking,
            partnerDetails: booking.toPartnerDetailsMap(),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailScreen(bookingId: booking.id),
      ),
    );
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

  _BookingStatusData _bookingStatusFor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('cancel')) {
      return const _BookingStatusData(
        label: 'Canceled',
        foregroundColor: Color(0xFFEF4444),
        icon: Icons.cancel,
        showRatings: false,
      );
    }
    if (lower.contains('complete')) {
      return const _BookingStatusData(
        label: 'Completed',
        foregroundColor: Color(0xFF16A34A),
        icon: Icons.check_circle,
        showRatings: true,
      );
    }
    return const _BookingStatusData(
      label: 'Scheduled',
      foregroundColor: Color(0xFFF97316),
      icon: Icons.schedule,
      showRatings: false,
    );
  }

  Widget _buildBookingThumbnail(BookingDetailsModal b) {
    final img = b.primaryServiceImageUrl;
    if (img != null && img.isNotEmpty) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: const Color(0xFFF3F4F6),
          image: DecorationImage(image: NetworkImage(img), fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: const Color(0xFFE5E7EB),
      ),
      child: const Center(
        child: Icon(
          Icons.cleaning_services_outlined,
          size: 17,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

class _BookingStatusData {
  const _BookingStatusData({
    required this.label,
    required this.foregroundColor,
    required this.icon,
    required this.showRatings,
  });

  final String label;
  final Color foregroundColor;
  final IconData icon;
  final bool showRatings;
}

class _BookingStatusPill extends StatelessWidget {
  const _BookingStatusPill({required this.status});

  final _BookingStatusData status;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          status.label,
          style: TextStyle(
            color: status.foregroundColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 4),
        Icon(status.icon, size: 14, color: status.foregroundColor),
      ],
    );
  }
}

class _BookingMetaRow extends StatelessWidget {
  const _BookingMetaRow({
    required this.text,
    this.icon,
    this.svgAssetPath,
  });

  final IconData? icon;
  final String? svgAssetPath;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (svgAssetPath != null)
          SvgPicture.asset(
            svgAssetPath!,
            width: 16,
            height: 16,
            colorFilter: const ColorFilter.mode(
              Color(0xFF9CA3AF),
              BlendMode.srcIn,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 16, color: const Color(0xFF9CA3AF))
        else
          const SizedBox(width: 16),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.15,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingRatingBlock extends StatelessWidget {
  const _BookingRatingBlock({required this.title, required this.isRated});

  final String title;
  final bool isRated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final filled = isRated && index == 0;
            return Padding(
              padding: EdgeInsets.only(right: index == 4 ? 0 : 4),
              child: Icon(
                Icons.star,
                size: 14,
                color: filled
                    ? const Color(0xFFFACC15)
                    : const Color(0xFFD1D5DB),
              ),
            );
          }),
        ),
      ],
    );
  }
}
