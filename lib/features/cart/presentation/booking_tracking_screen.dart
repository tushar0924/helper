import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/utils/app_toast.dart';
import '../application/cart_provider.dart';
import '../modal/booking_details_modal.dart';
import '../modal/cart_summary_modal.dart';

class BookingTrackingScreen extends ConsumerStatefulWidget {
  const BookingTrackingScreen({
    super.key,
    required this.summary,
    required this.bookingId,
    this.bookingDetails,
    required this.partnerDetails,
  });

  final CartSummaryModal summary;
  final int bookingId;
  final BookingDetailsModal? bookingDetails;
  final Map<String, dynamic> partnerDetails;

  @override
  ConsumerState<BookingTrackingScreen> createState() =>
      _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends ConsumerState<BookingTrackingScreen> {
  late GoogleMapController _mapController;

  // User location (you can get this from geolocator)
  final LatLng _userLocation = const LatLng(26.9124, 75.7873);
  // Partner location (this would come from real-time tracking)
  final LatLng _partnerLocation = const LatLng(26.9150, 75.7890);

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final bookingDetails = widget.bookingDetails;
    final partnerName =
        bookingDetails?.helper?.displayName ??
        widget.partnerDetails['name'] ??
        'Partner';
    final partnerPhone =
        bookingDetails?.helper?.user?.phone ??
        widget.partnerDetails['phone'] ??
        '';
    final bookingOtp = bookingDetails?.otpLabel ?? '----';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            size: 24,
            color: Color(0xFF0F172A),
          ),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Scheduled',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Your booking is confirmed',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.lock_outline,
              size: 24,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Section
            _MapSection(
              userLocation: _userLocation,
              partnerLocation: _partnerLocation,
              onMapCreated: (controller) => _mapController = controller,
            ),
            const SizedBox(height: 14),

            // Contact Buttons Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ContactButtonsSection(partnerPhone: partnerPhone),
            ),
            const SizedBox(height: 14),

            // Partner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PartnerInfoCard(partnerDetails: widget.partnerDetails),
            ),
            const SizedBox(height: 14),

            // OTP Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _OtpCard(otp: bookingOtp),
            ),
            const SizedBox(height: 14),

            // Important Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ImportantInstructionsCard(),
            ),
            const SizedBox(height: 14),

            // Booking Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BookingDetailsCard(
                summary: summary,
                bookingDetails: bookingDetails,
              ),
            ),
            const SizedBox(height: 14),

            // Service Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ServiceDetailsCard(summary: summary),
            ),
            const SizedBox(height: 14),

            // Cancellation Policy
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CancellationPolicyCard(onCancelPressed: _onCancelBookingTap),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _onCancelBookingTap() {
    // First dialog: Confirmation
    showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Are you sure you want to cancel the booking?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0B1F3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Yes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        _showCancellationReasonDialog();
      }
    });
  }

  void _showCancellationReasonDialog() {
    String? selectedReason;
    bool isLoading = false;
    const reasons = [
      'Change of plans',
      'Booked by mistake',
      'Found an alternative',
      'Not available at the scheduled time',
      'Service pricing concern',
      'Issue with service / professional',
      'Other',
    ];

    const reasonCodes = [
      'CHANGE_OF_PLANS',
      'BOOKED_BY_MISTAKE',
      'FOUND_ALTERNATIVE',
      'NOT_AVAILABLE',
      'PRICING_CONCERN',
      'ISSUE_WITH_SERVICE',
      'OTHER',
    ];

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Cancellation reason?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    if (!isLoading)
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 24),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        reasons.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      selectedReason = reasonCodes[index];
                                    });
                                  },
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedReason == reasonCodes[index]
                                          ? const Color(0xFF0B1F3A)
                                          : const Color(0xFFD1D5DB),
                                      width: 2,
                                    ),
                                  ),
                                  child: selectedReason == reasonCodes[index]
                                      ? Center(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Color(0xFF0B1F3A),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    reasons[index],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: (selectedReason != null && !isLoading)
                        ? () async {
                            setState(() {
                              isLoading = true;
                            });
                            await _cancelBookingWithReason(selectedReason!);
                            if (mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: selectedReason != null
                          ? const Color(0xFF0B1F3A)
                          : const Color(0xFFD1D5DB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: const Color(0xFFD1D5DB),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Cancel Booking',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _cancelBookingWithReason(String reason) async {
    try {
      final repository = ref.read(cartRepositoryProvider);
      await repository.cancelBooking(
        bookingId: widget.bookingId,
        reason: reason,
      );

      if (!mounted) return;

      AppToast.success('Booking cancelled successfully');
      await Future<void>.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (!mounted) return;
      AppToast.error(error.toString());
    }
  }
}

class _MapSection extends StatelessWidget {
  const _MapSection({
    required this.userLocation,
    required this.partnerLocation,
    required this.onMapCreated,
  });

  final LatLng userLocation;
  final LatLng partnerLocation;
  final ValueChanged<GoogleMapController> onMapCreated;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Arrive in timing
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Arrive in 15 mins',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF92400E),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Map
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 250,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: userLocation,
                zoom: 15,
              ),
              onMapCreated: onMapCreated,
              markers: {
                Marker(
                  markerId: const MarkerId('user'),
                  position: userLocation,
                  infoWindow: const InfoWindow(title: 'Your Location'),
                ),
                Marker(
                  markerId: const MarkerId('partner'),
                  position: partnerLocation,
                  infoWindow: const InfoWindow(title: 'Partner Location'),
                ),
              },
              polylines: {
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: [userLocation, partnerLocation],
                  color: const Color(0xFF3B82F6),
                  width: 3,
                ),
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Your Location label
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 16, color: Color(0xFF6B7280)),
            SizedBox(width: 6),
            Text(
              'Your Location',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContactButtonsSection extends StatelessWidget {
  const _ContactButtonsSection({required this.partnerPhone});

  final String partnerPhone;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Call button
        GestureDetector(
          onTap: () => AppToast.success('Call feature coming soon'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF3F4F6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(Icons.call, size: 22, color: Color(0xFF111827)),
          ),
        ),
        const SizedBox(width: 20),

        // Chat button
        GestureDetector(
          onTap: () => AppToast.success('Chat feature coming soon'),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFB923C),
            ),
            child: const Icon(Icons.message, size: 22, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _PartnerInfoCard extends StatelessWidget {
  const _PartnerInfoCard({required this.partnerDetails});

  final Map<String, dynamic> partnerDetails;

  @override
  Widget build(BuildContext context) {
    final name = partnerDetails['name'] ?? 'Partner';
    final rating = partnerDetails['rating'] ?? '5.0';
    final experience = partnerDetails['experience'] ?? '5+ years experience';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE5E7EB),
            child: const Icon(Icons.person, size: 32, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$rating • $experience',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 14,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Police Verified & Trained',
                      style: TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  const _OtpCard({required this.otp});

  final String otp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFAED7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Verification OTP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  otp,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.copy_outlined,
                  size: 20,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Share this OTP with your helper when they arrive',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportantInstructionsCard extends StatelessWidget {
  const _ImportantInstructionsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Important Instructions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _InstructionRow(
            icon: Icons.check_circle,
            text: 'Verify the OTP before the helper starts working',
          ),
          const SizedBox(height: 10),
          _InstructionRow(
            icon: Icons.check_circle,
            text: 'Enjoy 15 min extra service time free',
          ),
        ],
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF16A34A)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}

class _BookingDetailsCard extends StatelessWidget {
  const _BookingDetailsCard({
    required this.summary,
    required this.bookingDetails,
  });

  final CartSummaryModal summary;
  final BookingDetailsModal? bookingDetails;

  @override
  Widget build(BuildContext context) {
    final date = summary.slot.date ?? 'Thu, Nov 6 2025';
    final time = summary.slot.time ?? '06:00 AM';
    final displayDate = bookingDetails?.displayDateLabel ?? date;
    final displayTime = bookingDetails?.displayTimeLabel ?? time;
    final displayEndTime = bookingDetails?.endTimeLabel ?? '06:30 AM';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: displayDate,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Start Time',
            value: displayTime,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.schedule,
            label: 'Expected End',
            value: bookingDetails?.endTimeLabel ?? displayEndTime,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD97706)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ServiceDetailsCard extends StatelessWidget {
  const _ServiceDetailsCard({required this.summary});

  final CartSummaryModal summary;

  @override
  Widget build(BuildContext context) {
    final services = summary.items;
    final totalHours = services.fold<int>(
      0,
      (sum, item) => sum + (item.duration * item.quantity),
    );
    final totalMinutes = (totalHours % 60).toStringAsFixed(0);
    final displayHours = (totalHours ~/ 60);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                ),
                child: const Text(
                  'Cleaning Service',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF0B6DD4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text(
                    '•',
                    style: TextStyle(fontSize: 16, color: Color(0xFF111827)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Text(
                    '${service.duration}hr',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Total Service Hours',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              Text(
                '$displayHours hours 30 minutes',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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

class _CancellationPolicyCard extends StatelessWidget {
  const _CancellationPolicyCard({required this.onCancelPressed});

  final VoidCallback onCancelPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancellation Policy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _PolicyItem(text: '100% refund if cancelled before the service'),
          const SizedBox(height: 8),
          _PolicyItem(text: 'Refund within 12 hours of the service: 50%'),
          const SizedBox(height: 8),
          _PolicyItem(text: 'Cancel within 3 hours of the service: No refund'),
          const SizedBox(height: 8),
          _PolicyItem(text: '(100% applicable)'),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            height: 36,
            child: OutlinedButton(
              onPressed: onCancelPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel Booking',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(fontSize: 16, color: Color(0xFFEF4444)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
      ],
    );
  }
}
