import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../cart/modal/booking_details_modal.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _loadBookings();
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          Icon(Icons.search, color: Color(0xFF9CA3AF)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Search for help or stores nearby...',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedIndex == 0
                    ? const Color(0xFF0B2A4A)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person,
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _selectedIndex == 1
                    ? const Color(0xFF0B2A4A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store,
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
          return const Center(child: CircularProgressIndicator());
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

        final bookings = snapshot.data ?? <BookingDetailsModal>[];
        if (bookings.isEmpty) {
          return Center(
            child: Text(
              'No bookings found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        return ListView.separated(
          itemCount: bookings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final b = bookings[index];
            return _buildBookingCard(b);
          },
        );
      },
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
    Color statusColor = const Color(0xFFDCFCE7);
    Color statusTextColor = const Color(0xFF059669);
    String statusLabel = 'In Progress';
    bool isInProgress = true;

    if (b.status.toLowerCase().contains('cancel')) {
      statusColor = const Color(0xFFFFEBEE);
      statusTextColor = const Color(0xFFDC2626);
      statusLabel = 'Cancelled';
      isInProgress = false;
    } else if (b.status.toLowerCase().contains('complete')) {
      statusColor = const Color(0xFFF3F4F6);
      statusTextColor = const Color(0xFF059669);
      statusLabel = 'Completed';
      isInProgress = false;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  b.serviceDisplayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Text(
                b.displayDateLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Text(
                b.displayTimeLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.currency_rupee,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 10),
              Text(
                '₹${b.finalAmount}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isInProgress)
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => BookingDetailScreen(bookingId: b.id),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'View Detail',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B2A4A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'View Progress',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.chevron_right, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(bookingId: b.id),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right, size: 18, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
