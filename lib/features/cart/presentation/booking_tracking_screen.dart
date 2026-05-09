import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../app/utils/app_toast.dart';
import '../../auth/application/auth_provider.dart';
import '../application/cart_provider.dart';
import '../../../network/api_endpoint.dart';
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
  static const LatLng _fallbackLocation = LatLng(26.9124, 75.7873);

  BookingDetailsModal? _bookingDetails;
  BookingArrivalModal? _arrival;
  io.Socket? _trackingSocket;
  Timer? _pollingTimer;
  bool _isLoadingBooking = false;
  bool _socketListenersAttached = false;
  bool _isJoiningRoom = false;
  bool _trackingStopped = false;

  @override
  void initState() {
    super.initState();
    _bookingDetails = widget.bookingDetails;
    _arrival = widget.bookingDetails?.arrival;

    unawaited(_bootstrapTracking());
  }

  @override
  void dispose() {
    _trackingStopped = true;
    _pollingTimer?.cancel();
    _trackingSocket?.dispose();
    super.dispose();
  }

  Future<void> _bootstrapTracking() async {
    await _refreshBookingDetails();
    await _ensureTrackingSocketConnected();

    if (_trackingSocket?.connected != true) {
      _startPollingFallback();
    }
  }

  Widget build(BuildContext context) {
    final summary = widget.summary;
    final bookingDetails = _bookingDetails ?? widget.bookingDetails;
    final arrival = _arrival ?? bookingDetails?.arrival;
    final partnerName =
        bookingDetails?.helper?.displayName ??
        widget.partnerDetails['name'] ??
        'Partner';
    final partnerPhone =
        bookingDetails?.helper?.user?.phone ??
        widget.partnerDetails['phone'] ??
        '';
    final bookingOtp = bookingDetails?.otpLabel ?? '----';
      final bookingLocation = _bookingLocation(bookingDetails);
      final helperLocation = _helperLocation(arrival);
      final showMap = _shouldShowMap(arrival, helperLocation);
      final statusTitle = _trackingTitle(arrival, bookingDetails);
      final statusMessage = _trackingMessage(arrival, bookingDetails);
      final etaLabel = _etaLabel(arrival);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F2741),
        elevation: 0,
        toolbarHeight: 70,
        leadingWidth: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8),
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              size: 24,
              color: Colors.white,
            ),
          ),
        ),
        titleSpacing: 12,
        title: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Booking Scheduled',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Your booking is confirmed',
                style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 8),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'help') {
                  AppToast.success('Help & Support - Coming Soon');
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, size: 18, color: Color(0xFF111827)),
                      SizedBox(width: 12),
                      Text(
                        'Help & Support',
                        style: TextStyle(fontSize: 14, color: Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ],
              child: const Icon(
                Icons.more_vert,
                size: 24,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                    if (etaLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        etaLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B6DD4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            if (showMap && bookingLocation != null && helperLocation != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MapSection(
                  userLocation: bookingLocation,
                  partnerLocation: helperLocation,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    _mapHint(arrival),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
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

            // Service Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ServiceDetailsCard(summary: summary),
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

  Future<void> _refreshBookingDetails() async {
    if (_isLoadingBooking || widget.bookingId <= 0) {
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingBooking = true;
      });
    } else {
      _isLoadingBooking = true;
    }

    try {
      final repository = ref.read(cartRepositoryProvider);
      final bookingDetails = await repository.getUserBooking(
        bookingId: widget.bookingId,
      );

      if (mounted) {
        setState(() {
          _bookingDetails = bookingDetails;
          _arrival = bookingDetails.arrival;
        });
      } else {
        _bookingDetails = bookingDetails;
        _arrival = bookingDetails.arrival;
      }

      _syncTrackingState(bookingDetails);
    } catch (error) {
      debugPrint('[TRACKING] Failed to load booking details: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBooking = false;
        });
      } else {
        _isLoadingBooking = false;
      }
    }
  }

  Future<void> _ensureTrackingSocketConnected() async {
    if (_trackingSocket != null) {
      if (!(_trackingSocket!.connected)) {
        _trackingSocket!.connect();
      }
      return;
    }

    final token = await ref.read(sessionManagerProvider).accessToken;
    if (token == null || token.trim().isEmpty) {
      debugPrint('[TRACKING][SOCKET] No auth token available');
      return;
    }

    _trackingSocket = io.io(
      ApiEndpoint.socketUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket', 'polling'])
          .setPath('/socket.io')
          .enableForceNew()
          .disableReconnection()
          .setAuth(<String, dynamic>{'token': token})
          .setExtraHeaders(<String, dynamic>{'Authorization': 'Bearer $token'})
          .build(),
    );

    if (!_socketListenersAttached) {
      _registerTrackingSocketListeners();
      _socketListenersAttached = true;
    }

    _trackingSocket!.connect();
    debugPrint('[TRACKING][SOCKET] Socket connected for booking ${widget.bookingId}');
  }

  void _registerTrackingSocketListeners() {
    final socket = _trackingSocket;
    if (socket == null) {
      return;
    }

    socket.onConnect((_) {
      debugPrint('[TRACKING][SOCKET] Connected');
      _isJoiningRoom = false;
      _pollingTimer?.cancel();
      _joinBookingRoom();
    });

    socket.onConnectError((error) {
      debugPrint('[TRACKING][SOCKET] Connect error: $error');
      _startPollingFallback();
    });

    socket.onError((error) {
      debugPrint('[TRACKING][SOCKET] Socket error: $error');
      _startPollingFallback();
    });

    socket.onDisconnect((reason) {
      debugPrint('[TRACKING][SOCKET] Disconnected: $reason');
      if (!_trackingStopped) {
        _startPollingFallback();
      }
    });

    const trackingEvents = <String>[
      'booking:location_update',
      'booking:arriving',
      'booking:delayed',
      'booking:arrived',
    ];

    for (final eventName in trackingEvents) {
      socket.on(eventName, _onTrackingEvent);
    }

    debugPrint('[TRACKING][SOCKET] Socket listeners registered');
  }

  void _joinBookingRoom() {
    final socket = _trackingSocket;
    if (_trackingStopped ||
        socket == null ||
        socket.connected != true ||
        _isJoiningRoom) {
      return;
    }

    _isJoiningRoom = true;
    final room = 'booking:${widget.bookingId}';
    final payload = <String, dynamic>{
      'bookingId': widget.bookingId,
      'room': room,
    };

    socket.emit('booking:join', payload);
    socket.emit('booking_join', payload);
    socket.emit('join_room', payload);

    debugPrint('[TRACKING][SOCKET] Joined room: $room');
  }

  Future<void> _onTrackingEvent(dynamic payload) async {
    final map = _normalizeMap(payload);
    if (map == null) {
      return;
    }

    debugPrint('[TRACKING][SOCKET] Event payload: $map');

    final bookingId = _toInt(
      map['bookingId'] ??
          map['id'] ??
          (map['booking'] is Map<String, dynamic>
              ? (map['booking'] as Map<String, dynamic>)['id']
              : null),
    );

    if (bookingId != null && bookingId != widget.bookingId) {
      return;
    }

    final bookingMap = _extractBookingMap(map);
    if (bookingMap != null) {
      final bookingDetails = BookingDetailsModal.fromJson(bookingMap);
      if (mounted) {
        setState(() {
          _bookingDetails = bookingDetails;
          _arrival = bookingDetails.arrival;
        });
      } else {
        _bookingDetails = bookingDetails;
        _arrival = bookingDetails.arrival;
      }
      _syncTrackingState(bookingDetails);
      return;
    }

    final arrivalMap = _extractArrivalMap(map);
    if (arrivalMap != null) {
      final currentArrival = _arrival;
      final arrival = BookingArrivalModal.fromJson(<String, dynamic>{
        'trackingEnabled': arrivalMap['trackingEnabled'] ?? currentArrival?.trackingEnabled,
        'arrivalState': arrivalMap['arrivalState'] ?? currentArrival?.arrivalState,
        'etaSeconds': arrivalMap['etaSeconds'] ?? currentArrival?.etaSeconds,
        'helperLocation': arrivalMap['helperLocation'] ?? currentArrival?.helperLocation,
        'isLocationStale': arrivalMap['isLocationStale'] ?? currentArrival?.isLocationStale,
      });

      if (mounted) {
        setState(() {
          _arrival = arrival;
        });
      } else {
        _arrival = arrival;
      }
    }
  }

  void _syncTrackingState(BookingDetailsModal bookingDetails) {
    if (_isTerminalStatus(bookingDetails.status)) {
      _trackingStopped = true;
      _pollingTimer?.cancel();
      _trackingSocket?.disconnect();
    }
  }

  void _startPollingFallback() {
    if (_trackingStopped || _pollingTimer != null) {
      return;
    }

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted || widget.bookingId <= 0) {
        _pollingTimer?.cancel();
        _pollingTimer = null;
        return;
      }

      if (_trackingSocket?.connected == true) {
        return;
      }

      await _refreshBookingDetails();
    });
  }

  Map<String, dynamic>? _extractBookingMap(Map<String, dynamic> map) {
    final candidates = <Object?>[
      map['booking'],
      map['data'],
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeMap(candidate);
      if (normalized != null && normalized.containsKey('arrival')) {
        return normalized;
      }
    }

    if (map.containsKey('status') || map.containsKey('arrival')) {
      return map;
    }

    return null;
  }

  Map<String, dynamic>? _extractArrivalMap(Map<String, dynamic> map) {
    final candidates = <Object?>[
      map['arrival'],
      map['data'] is Map ? (map['data'] as Map)['arrival'] : null,
    ];

    for (final candidate in candidates) {
      final normalized = _normalizeMap(candidate);
      if (normalized != null) {
        return normalized;
      }
    }

    if (map.containsKey('trackingEnabled') ||
        map.containsKey('arrivalState') ||
        map.containsKey('etaSeconds') ||
        map.containsKey('helperLocation')) {
      return map;
    }

    return null;
  }

  Map<String, dynamic>? _normalizeMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) {
      return value.toInt();
    }
    return null;
  }

  bool _shouldShowMap(BookingArrivalModal? arrival, LatLng? helperLocation) {
    if (arrival == null || !arrival.trackingEnabled || helperLocation == null) {
      return false;
    }

    if (arrival.arrivalState == 'ARRIVED') {
      return true;
    }

    final etaSeconds = arrival.etaSeconds;
    if (etaSeconds == null) {
      return false;
    }

    return etaSeconds <= 1800;
  }

  LatLng? _bookingLocation(BookingDetailsModal? bookingDetails) {
    if (bookingDetails == null) {
      return null;
    }

    final lat = bookingDetails.latitude;
    final lng = bookingDetails.longitude;
    if (lat == 0 || lng == 0) {
      return _fallbackLocation;
    }

    return LatLng(lat, lng);
  }

  LatLng? _helperLocation(BookingArrivalModal? arrival) {
    final helperLocation = arrival?.helperLocation;
    if (helperLocation == null || !helperLocation.isValid) {
      return null;
    }

    return LatLng(helperLocation.lat, helperLocation.lng);
  }

  String _trackingTitle(BookingArrivalModal? arrival, BookingDetailsModal? details) {
    if (details == null) {
      return 'Tracking unavailable';
    }

    if (arrival == null) {
      return 'Tracking OFF';
    }

    if (!arrival.trackingEnabled) {
      return 'Tracking OFF';
    }

    switch (arrival.arrivalState) {
      case 'ARRIVING':
        return 'Helper is on the way';
      case 'DELAYED':
        return 'Running late';
      case 'ARRIVED':
        return 'Partner arrived';
      default:
        return 'Live tracking';
    }
  }

  String _trackingMessage(BookingArrivalModal? arrival, BookingDetailsModal? details) {
    if (details == null) {
      return 'Loading booking details...';
    }

    if (arrival == null) {
      return 'Live tracking will appear only when the booking becomes trackable.';
    }

    if (!arrival.trackingEnabled) {
      return 'The backend has disabled tracking for this booking.';
    }

    switch (arrival.arrivalState) {
      case 'ARRIVING':
        return 'Helper is approaching. Live map will appear once they are within 30 minutes.';
      case 'DELAYED':
        return 'Helper is delayed. Keep an eye on the live map and ETA updates.';
      case 'ARRIVED':
        return 'Partner has arrived at the location.';
      default:
        return 'Tracking is enabled. Live updates will appear from the backend.';
    }
  }

  String _etaLabel(BookingArrivalModal? arrival) {
    final etaSeconds = arrival?.etaSeconds;
    if (etaSeconds == null) {
      return '';
    }

    final minutes = (etaSeconds / 60).ceil();
    if (minutes <= 1) {
      return 'ETA: less than 1 minute';
    }

    if (minutes < 60) {
      return 'ETA: $minutes minutes';
    }

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return 'ETA: $hours hour${hours == 1 ? '' : 's'}';
    }

    return 'ETA: $hours hour${hours == 1 ? '' : 's'} $remainingMinutes min';
  }

  String _mapHint(BookingArrivalModal? arrival) {
    if (arrival == null) {
      return 'Map will appear once tracking data is available.';
    }

    if (!arrival.trackingEnabled) {
      return 'Tracking is disabled for this booking.';
    }

    if (arrival.arrivalState == 'ARRIVED') {
      return 'Helper has arrived. The live map is still available for reference.';
    }

    final etaSeconds = arrival.etaSeconds;
    if (etaSeconds != null && etaSeconds > 1800) {
      return 'Live map will show when the helper is within 30 minutes of arrival.';
    }

    return 'Waiting for live location updates from the backend.';
  }

  bool _isTerminalStatus(String status) {
    final normalized = status.toUpperCase();
    return normalized.contains('COMPLETE') ||
        normalized.contains('CANCELLED') ||
        normalized.contains('CANCELED');
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
  });

  final LatLng userLocation;
  final LatLng partnerLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Live status
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Live map active',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0369A1),
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
              markers: <Marker>{
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
              polylines: <Polyline>{
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE5E7EB),
            child: const Icon(Icons.person, size: 26, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  experience,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.verified,
                      size: 12,
                      color: Color(0xFF10B981),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Police Verified & Trained',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PartnerActionButton(
                    icon: Icons.call,
                    backgroundColor: const Color(0xFF111827),
                    iconColor: Colors.white,
                    onTap: () => AppToast.success('Call feature coming soon'),
                  ),
                  const SizedBox(width: 8),
                  _PartnerActionButton(
                    icon: Icons.message,
                    backgroundColor: const Color(0xFFFB923C),
                    iconColor: Colors.white,
                    onTap: () => AppToast.success('Chat feature coming soon'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PartnerActionButton extends StatelessWidget {
  const _PartnerActionButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: iconColor),
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
          const _InstructionRow(
            text: 'Verify the OTP before the helper starts working',
          ),
          const SizedBox(height: 8),
          const _InstructionRow(
            text: 'Enjoy 10 min extra service free',
          ),
        ],
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '•',
          style: TextStyle(fontSize: 16, color: Color(0xFFEA580C)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
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
            width: double.infinity,
            height: 36,
            child: OutlinedButton(
              onPressed: onCancelPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Cancel Booking',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
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
