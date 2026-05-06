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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by category...',
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

        var bookings = snapshot.data ?? <BookingDetailsModal>[];
        
        // Filter by search query
        if (_searchQuery.isNotEmpty) {
          bookings = bookings.where((b) {
            final categoryName = b.categoryName?.toLowerCase() ?? '';
            final serviceName = b.serviceDisplayName.toLowerCase();
            return categoryName.contains(_searchQuery) || serviceName.contains(_searchQuery);
          }).toList();
        }

        if (bookings.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty ? 'No bookings found for "$_searchQuery"' : 'No bookings found',
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
    final status = _bookingStatusFor(b.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(bookingId: b.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6EAF0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
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
                          fontSize: 14.5,
                          height: 1.1,
                          fontWeight: FontWeight.w700,
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookingMetaRow(
                      icon: Icons.calendar_today_outlined,
                      text: b.displayDateLabel,
                    ),
                    const SizedBox(height: 8),
                    _BookingMetaRow(
                      icon: Icons.access_time_outlined,
                      text: b.displayTimeLabel,
                    ),
                    const SizedBox(height: 8),
                    _BookingMetaRow(
                      icon: Icons.currency_rupee,
                      text: '₹${b.finalAmount}',
                    ),
                    if (status.showRatings) ...[
                      const SizedBox(height: 14),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
                      const SizedBox(height: 10),
                      const Row(
                        children: [
                          Expanded(
                            child: _BookingRatingBlock(title: 'Service Rating'),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _BookingRatingBlock(title: 'Partner Rating'),
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

  _BookingStatusData _bookingStatusFor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('cancel')) {
      return const _BookingStatusData(
        label: 'Canceled',
        backgroundColor: Color(0xFFFFF1F2),
        foregroundColor: Color(0xFFEF4444),
        icon: Icons.cancel_rounded,
        showRatings: false,
      );
    }
    if (lower.contains('complete')) {
      return const _BookingStatusData(
        label: 'Completed',
        backgroundColor: Color(0xFFEFFAF3),
        foregroundColor: Color(0xFF16A34A),
        icon: Icons.check_circle_rounded,
        showRatings: true,
      );
    }
    return const _BookingStatusData(
      label: 'Scheduled',
      backgroundColor: Color(0xFFFFF7ED),
      foregroundColor: Color(0xFFF97316),
      icon: Icons.event_available_rounded,
      showRatings: false,
    );
  }

  Widget _buildBookingThumbnail(BookingDetailsModal b) {
    final img = b.categoryImageUrl;
    if (img != null && img.isNotEmpty) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFF3F4F6),
          image: DecorationImage(
            image: NetworkImage(img),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFE8D6B8),
      ),
      child: const Center(
        child: Icon(
          Icons.cleaning_services_outlined,
          size: 16,
          color: Color(0xFF6B4F3B),
        ),
      ),
    );
  }
}

class _BookingStatusData {
  const _BookingStatusData({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.showRatings,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final bool showRatings;
}

class _BookingStatusPill extends StatelessWidget {
  const _BookingStatusPill({required this.status});

  final _BookingStatusData status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.foregroundColor),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: status.foregroundColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingMetaRow extends StatelessWidget {
  const _BookingMetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.18,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingRatingBlock extends StatelessWidget {
  const _BookingRatingBlock({required this.title});

  final String title;

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
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: List.generate(5, (index) {
            final filled = index == 0;
            return Padding(
              padding: EdgeInsets.only(right: index == 4 ? 0 : 3),
              child: Icon(
                Icons.star,
                size: 14,
                color: filled ? const Color(0xFFFACC15) : const Color(0xFFD1D5DB),
              ),
            );
          }),
        ),
      ],
    );
  }
}
