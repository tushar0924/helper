import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/services.dart';

import '../../../app/utils/app_toast.dart';
import '../application/cart_provider.dart';
import '../modal/booking_details_modal.dart';
import '../modal/cart_summary_modal.dart';
import 'booking_tracking_screen.dart';

class BookingConfirmedScreen extends ConsumerStatefulWidget {
  const BookingConfirmedScreen({
    super.key,
    required this.summary,
    required this.bookingId,
    this.bookingDetails,
    this.partnerDetails = const <String, dynamic>{},
  });

  final CartSummaryModal summary;
  final int bookingId;
  final BookingDetailsModal? bookingDetails;
  final Map<String, dynamic> partnerDetails;

  @override
  ConsumerState<BookingConfirmedScreen> createState() =>
      _BookingConfirmedScreenState();
}

class _BookingConfirmedScreenState
    extends ConsumerState<BookingConfirmedScreen> {
  static const String _razorpayFallbackKey = 'rzp_test_SL7um4c5zp7RIm';

  late final Razorpay _razorpay;
  BookingDetailsModal? _bookingDetails;
  bool _isPaying = false;
  bool _paymentCompleted = false;
  bool _isLoadingBookingDetails = false;

  @override
  void initState() {
    super.initState();

    // Log the data received on this screen
    debugPrint('[BOOKING_SCREEN] ===== BOOKING CONFIRMED SCREEN INIT =====');
    debugPrint('[BOOKING_SCREEN] Booking ID: ${widget.bookingId}');
    debugPrint('[BOOKING_SCREEN] Summary: ${widget.summary}');
    debugPrint('[BOOKING_SCREEN] Items: ${widget.summary.items}');
    debugPrint('[BOOKING_SCREEN] Address: ${widget.summary.address}');
    debugPrint('[BOOKING_SCREEN] Pricing: ${widget.summary.pricing}');
    if (widget.bookingDetails != null) {
      debugPrint(
        '[BOOKING_SCREEN] Booking status: ${widget.bookingDetails!.status}',
      );
      debugPrint(
        '[BOOKING_SCREEN] Partner: ${widget.bookingDetails!.helper?.displayName ?? 'Partner'}',
      );
    }
    debugPrint('[BOOKING_SCREEN] ===== END INIT =====');

    _bookingDetails = widget.bookingDetails;
    unawaited(_loadUserBookingDetails());

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPaying = false;
      _paymentCompleted = true;
    });

    await _loadUserBookingDetails();
    await Future<void>.delayed(const Duration(seconds: 1));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BookingTrackingScreen(
            summary: widget.summary,
            bookingId: widget.bookingId,
            bookingDetails: _bookingDetails ?? widget.bookingDetails,
            partnerDetails:
                (_bookingDetails ?? widget.bookingDetails)
                    ?.toPartnerDetailsMap() ??
                widget.partnerDetails,
          ),
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPaying = false;
    });

    final message = response.message?.trim();
    AppToast.error(
      message == null || message.isEmpty
          ? 'Payment failed. Please try again.'
          : message,
    );
  }

  Future<BookingDetailsModal?> _loadUserBookingDetails() async {
    if (_isLoadingBookingDetails || widget.bookingId <= 0) {
      return _bookingDetails;
    }

    if (mounted) {
      setState(() {
        _isLoadingBookingDetails = true;
      });
    } else {
      _isLoadingBookingDetails = true;
    }

    try {
      final repository = ref.read(cartRepositoryProvider);
      final bookingDetails = await repository.getUserBooking(
        bookingId: widget.bookingId,
      );

      if (mounted) {
        setState(() {
          _bookingDetails = bookingDetails;
        });
      } else {
        _bookingDetails = bookingDetails;
      }

      return bookingDetails;
    } catch (error) {
      debugPrint(
        '[BOOKING_SCREEN] Failed to load user booking details: $error',
      );
      return _bookingDetails;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBookingDetails = false;
        });
      } else {
        _isLoadingBookingDetails = false;
      }
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPaying = false;
    });

    final walletName = response.walletName?.trim();
    AppToast.success(
      walletName == null || walletName.isEmpty
          ? 'External wallet selected'
          : 'External wallet selected: $walletName',
    );
  }

  Future<void> _onPayNowTap() async {
    if (_isPaying) {
      return;
    }

    if (widget.bookingId <= 0) {
      AppToast.error('Invalid booking id for payment');
      return;
    }

    setState(() {
      _isPaying = true;
    });

    try {
      final repository = ref.read(cartRepositoryProvider);
      await repository.initiatePayment(bookingId: widget.bookingId);

      final order = await repository.createPaymentOrder(
        bookingId: widget.bookingId,
        amount: widget.summary.pricing.total,
      );

      final options = <String, Object>{
        'key': order.keyId.isEmpty ? _razorpayFallbackKey : order.keyId,
        'order_id': order.orderId,
        'amount': order.amount,
        'currency': order.currency,
        'name': 'Zynexx',
        'description': 'Booking #${widget.bookingId}',
        'retry': <String, Object>{'enabled': true, 'max_count': 1},
        'send_sms_hash': true,
        'prefill': <String, Object>{'contact': '', 'email': ''},
      };

      _razorpay.open(options);
    } catch (error) {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
        if (error is MissingPluginException) {
          AppToast.error('Payment SDK not available. Please reinstall app.');
        } else {
          AppToast.error(error.toString());
        }
      }
    }
  }

  void _onCancelBookingTap() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'The refund will be processed according to the cancellation policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Booking'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Cancel Booking',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        AppToast.success('Booking cancelled successfully');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final bookingDetails = _bookingDetails ?? widget.bookingDetails;
    final services = summary.items;
    final statusLabel = bookingDetails?.statusLabel ?? 'Partner Assigned';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _paymentCompleted
            ? null
            : IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.arrow_back,
                  size: 24,
                  color: Color(0xFF0F172A),
                ),
              ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _paymentCompleted ? 'Booking Scheduled' : 'Booking Confirmed',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 2),
            Text(
              _paymentCompleted
                  ? 'Your booking is confirmed'
                  : bookingDetails != null
                  ? 'Booking #${bookingDetails.id} • $statusLabel'
                  : 'A partner has been assigned to your service',
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(13, 13, 13, 15),
        child: Column(
          children: [
            if (_paymentCompleted)
              const _PaymentSuccessCard()
            else
              _AssignedInfoCard(bookingDetails: bookingDetails),
            const SizedBox(height: 10),
            _PartnerCard(
              bookingDetails: bookingDetails,
              fallbackPartnerDetails: widget.partnerDetails,
            ),
            const SizedBox(height: 10),
            _ImportantInstructionsCard(bookingDetails: bookingDetails),
            const SizedBox(height: 10),
            _BookingDetailsCard(
              summary: summary,
              bookingDetails: bookingDetails,
            ),
            const SizedBox(height: 10),
            _ServiceDetailsCard(
              summary: summary,
              services: services,
              bookingDetails: bookingDetails,
            ),
            const SizedBox(height: 10),
            _AddressCard(summary: summary, bookingDetails: bookingDetails),
            const SizedBox(height: 10),
            if (!_paymentCompleted) _ApplyCouponRow(),
            if (!_paymentCompleted) const SizedBox(height: 10),
            if (!_paymentCompleted) _BillCard(summary: summary),
            if (!_paymentCompleted) const SizedBox(height: 10),
            if (!_paymentCompleted)
              _PendingPaymentCard(
                total: summary.pricing.total,
                paymentExpiresAt: bookingDetails?.paymentExpiresAt,
              ),
            if (_paymentCompleted) _CancellationPolicyCard(),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(13, 0, 13, 13),
        child: SizedBox(
          height: 58,
          child: FilledButton.icon(
            onPressed: _isPaying
                ? null
                : (_paymentCompleted ? _onCancelBookingTap : _onPayNowTap),
            style: FilledButton.styleFrom(
              backgroundColor: _paymentCompleted
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF0B1F3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: _paymentCompleted
                ? const Icon(Icons.close, size: 19, color: Colors.white)
                : (_isPaying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.credit_card,
                          size: 19,
                          color: Colors.white,
                        )),
            label: Text(
              _paymentCompleted
                  ? 'Cancel Booking'
                  : _isPaying
                  ? 'Processing...'
                  : 'Pay Now ${formatInr(summary.pricing.total)}',
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
  const _AssignedInfoCard({required this.bookingDetails});

  final BookingDetailsModal? bookingDetails;

  @override
  Widget build(BuildContext context) {
    final status = bookingDetails?.statusLabel ?? 'Partner Assigned';
    final subtitle = bookingDetails == null
        ? 'Your partner will arrive at the scheduled time'
        : 'Booking #${bookingDetails!.id} • $status';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBFE8CC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 20, color: Color(0xFF16A34A)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
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

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.bookingDetails,
    required this.fallbackPartnerDetails,
  });

  final BookingDetailsModal? bookingDetails;
  final Map<String, dynamic> fallbackPartnerDetails;

  @override
  Widget build(BuildContext context) {
    final helper = bookingDetails?.helper;
    final helperUser = helper?.user;
    final displayName =
        helper?.displayName ??
        fallbackPartnerDetails['name']?.toString().trim() ??
        'Partner';
    final ratingValue =
        helper?.rating ??
        (fallbackPartnerDetails['rating'] is num
            ? (fallbackPartnerDetails['rating'] as num).toDouble()
            : double.tryParse(
                    fallbackPartnerDetails['rating']?.toString() ?? '',
                  ) ??
                  0);
    final phone =
        helperUser?.phone ?? fallbackPartnerDetails['phone']?.toString();
    final serviceName = bookingDetails?.serviceDisplayName ?? 'Service';
    final statusLabel = bookingDetails?.statusLabel ?? 'Assigned';

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ratingValue > 0
                      ? ratingValue.toStringAsFixed(1)
                      : 'No rating yet',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Booking #${bookingDetails?.id ?? '-'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  serviceName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF16A34A),
                  ),
                ),
                if (phone != null && phone.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone.trim(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
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
  const _ServiceDetailsCard({
    required this.summary,
    required this.services,
    required this.bookingDetails,
  });

  final CartSummaryModal summary;
  final List<CartItemModal> services;
  final BookingDetailsModal? bookingDetails;

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
                child: Text(
                  bookingDetails?.serviceDisplayName ?? 'Service',
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
            children: [
              const Text(
                'Total Service Hours',
                style: TextStyle(fontSize: 13, color: Color(0xFF111827)),
              ),
              const Spacer(),
              Text(
                _durationLabel(),
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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

  String _durationLabel() {
    final hours = bookingDetails?.totalHours ?? bookingDetails?.duration ?? 0;
    if (hours <= 0) {
      return 'Duration unavailable';
    }
    return hours == 1 ? '1 hour' : '$hours hours';
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.summary, required this.bookingDetails});

  final CartSummaryModal summary;
  final BookingDetailsModal? bookingDetails;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _addressLabel(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
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
          const SizedBox(height: 8),
          Text(
            _addressLine(),
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  String _addressLabel() {
    final customerName = bookingDetails?.customer?.fullName.trim();
    if (customerName != null && customerName.isNotEmpty) {
      return customerName;
    }

    return summary.address?.label ?? 'Service Address';
  }

  String _addressLine() {
    final bookingAddress =
        bookingDetails?.fullAddress ?? bookingDetails?.location;
    if (bookingAddress != null && bookingAddress.trim().isNotEmpty) {
      return bookingAddress.trim();
    }

    if (summary.address != null) {
      return '${summary.address!.address}, ${summary.address!.city} - ${summary.address!.pinCode}';
    }

    return 'Service address unavailable';
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
                child: const Text(
                  'Change Slot',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _MetaRow(
            icon: Icons.calendar_today_outlined,
            title: 'Date',
            value:
                bookingDetails?.displayDateLabel ??
                _formatBookingDate(summary.slot.date),
            iconColor: const Color(0xFF1F2937),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.access_time,
            title: 'Time',
            value:
                bookingDetails?.displayTimeLabel ??
                _formatBookingTime(summary.slot.time),
            iconColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 8),
          _MetaRow(
            icon: Icons.info_outline,
            title: 'Status',
            value: bookingDetails?.statusLabel ?? 'Pending Payment',
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
  const _PendingPaymentCard({
    required this.total,
    required this.paymentExpiresAt,
  });

  final int total;
  final DateTime? paymentExpiresAt;

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
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFF97316)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
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
            _expiryLabel(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  String _expiryLabel() {
    final expiry = paymentExpiresAt;
    if (expiry == null) {
      return 'Pending';
    }

    final local = expiry.toLocal();
    var hour12 = local.hour % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return 'Expires ${hour12.toString().padLeft(2, '0')}:$minute $period';
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

class _PaymentSuccessCard extends StatelessWidget {
  const _PaymentSuccessCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF16A34A),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Booking Scheduled',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your booking is confirmed and payment is done',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ImportantInstructionsCard extends StatelessWidget {
  const _ImportantInstructionsCard({required this.bookingDetails});

  final BookingDetailsModal? bookingDetails;

  @override
  Widget build(BuildContext context) {
    final partnerName = bookingDetails?.helper?.displayName ?? 'your helper';
    return _CardFrame(
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
            text: 'Verify the OTP before $partnerName starts working',
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

class _CancellationPolicyCard extends StatelessWidget {
  const _CancellationPolicyCard();

  @override
  Widget build(BuildContext context) {
    return _CardFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancellation Policy',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
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
          style: TextStyle(fontSize: 16, color: Color(0xFF111827)),
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
