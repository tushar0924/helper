import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../app/utils/app_toast.dart';
import '../../auth/application/auth_provider.dart';
import '../application/cart_provider.dart';
import '../application/coupon_provider.dart';
import '../data/cart_repository.dart';
import '../../home/application/address_provider.dart';
import '../../home/data/address_models.dart';
import '../modal/booking_details_modal.dart';
import '../modal/applied_coupons_modal.dart';
import '../modal/cart_summary_modal.dart';
import '../../home/presentation/saved_addresses_screen.dart';
import '../../shared/widgets/address_selection_bottom_sheet.dart';
import '../../../network/api_endpoint.dart';
import 'booking_confirmed_screen.dart';
import 'widgets/search_partner_dialog.dart';
import 'widgets/apply_coupon_bottom_sheet.dart';
import 'widgets/select_slot_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isSearchingPartner = false;
  io.Socket? _bookingSocket;
  Completer<int?>? _pendingAcceptCompleter;
  Timer? _pendingAcceptTimeout;
  int? _pendingBookingRequestId;
  int? _pendingUserId;
  bool _socketListenersAttached = false;
  Map<String, dynamic> _partnerDetails = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
      unawaited(_ensureBookingSocketConnected());
    });
  }

  @override
  void dispose() {
    _pendingAcceptTimeout?.cancel();
    _bookingSocket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CartState>(cartProvider, (_, next) {
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        AppToast.error(next.errorMessage!);
      }
    });

    final state = ref.watch(cartProvider);
    final summary = state.summary ?? CartSummaryModal.empty();
    final items = summary.items;
    final hasSelectedSlot = _hasSelectedSlot(summary);
    final appliedCouponsAsync = ref.watch(appliedCouponsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            size: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        title: const Text(
          'Your Cart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: state.isMutating
                  ? null
                  : () {
                      ref.read(cartProvider.notifier).clearCart();
                    },
              child: const Text('Clear Cart'),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(left: 56, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${items.length} services added',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () {
                ref.invalidate(appliedCouponsProvider);
                return ref
                    .read(cartProvider.notifier)
                    .loadSummary(forceRefresh: true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  children: [
                    if (items.isEmpty)
                      const _EmptyCartState()
                    else ...[
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CartServiceTile(item: item),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _ActionCard(
                        icon: Icons.add,
                        title: 'Add more services',
                        isPrimary: false,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(height: 10),
                      _SimpleTile(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF0EA5E9),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Service Address',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: _onChangeAddressTap,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0EA5E9),
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.only(left: 26),
                              child: _addressSummary(summary),
                            ),
                          ],
                        ),
                      ),
                      if (hasSelectedSlot) ...[
                        const SizedBox(height: 10),
                        _SimpleTile(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule,
                                    color: Color(0xFFF59E0B),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Selected slot',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _onSelectSlotTap(summary),
                                    child: const Text('Change Slot'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _slotInfoRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Date',
                                value: _formatBookingDate(summary.slot.date),
                              ),
                              const SizedBox(height: 8),
                              _slotInfoRow(
                                icon: Icons.access_time,
                                label: 'Time',
                                value: _formatBookingTime(summary.slot.time),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      _AppliedCouponsCard(
                        appliedCouponsAsync: appliedCouponsAsync,
                        summary: summary,
                        onTapApplyCoupon: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ApplyCouponScreen(),
                            ),
                          );
                          if (!mounted) {
                            return;
                          }

                          ref.invalidate(appliedCouponsProvider);
                          await ref
                              .read(cartProvider.notifier)
                              .loadSummary(forceRefresh: true);
                        },
                      ),
                      const SizedBox(height: 10),
                      _SimpleTile(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bill Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _billRow(
                              'Item Total',
                              formatInr(summary.pricing.itemTotal),
                            ),
                            _billRow(
                              'Tax & fare',
                              formatInr(summary.pricing.taxAndFee),
                              isLabelUnderlined: true,
                              onLabelTap: _showTaxFeeInfoSheet,
                            ),
                            if (summary.pricing.addonTotal > 0)
                              _billRow(
                                'Add-ons',
                                formatInr(summary.pricing.addonTotal),
                              ),
                            _billRow(
                              'Discount',
                              '-${formatInr(summary.pricing.discount.abs())}',
                              labelColor: const Color(0xFF22C55E),
                              valueColor: const Color(0xFF22C55E),
                            ),
                            const Divider(height: 24, color: Color(0xFFE5E7EB)),
                            _billRow(
                              'Total Amount',
                              formatInr(summary.pricing.total),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: items.isEmpty || _isSearchingPartner
                ? null
                : hasSelectedSlot
                ? () => _onSearchPartnerTap(summary)
                : () => _onSelectSlotTap(summary),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B1F3A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSearchingPartner
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    hasSelectedSlot ? 'Search Partner' : 'Select a Slot',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSearchPartnerTap(CartSummaryModal summary) async {
    if (_isSearchingPartner) {
      return;
    }

    if (!_hasSelectedSlot(summary)) {
      await _onSelectSlotTap(summary);
      return;
    }

    setState(() {
      _isSearchingPartner = true;
    });

    await _ensureBookingSocketConnected();

    final idempotencyKey = _generateIdempotencyKey();
    var searchDialogDismissed = false;
    final dialogFuture = showSearchPartnerDialog(context).whenComplete(() {
      searchDialogDismissed = true;
      if (mounted && _isSearchingPartner) {
        setState(() {
          _isSearchingPartner = false;
        });
      }
    });

    CreateFromCartResult? result;
    try {
      result = await ref
          .read(cartRepositoryProvider)
          .createFromCart(idempotencyKey: idempotencyKey);
      if (searchDialogDismissed) {
        return;
      }
    } catch (error) {
      if (mounted && !searchDialogDismissed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      await dialogFuture;

      if (mounted) {
        AppToast.error(error.toString());
      }
      if (mounted) {
        setState(() {
          _isSearchingPartner = false;
        });
      }
      return;
    }

    if (result!.message.trim().isNotEmpty) {
      AppToast.success(result.message);
    }

    int? bookingId = result.bookingId;
    final bookingRequestId = result.bookingRequestId;
    if ((bookingId == null || bookingId <= 0) &&
        bookingRequestId != null &&
        bookingRequestId > 0) {
      bookingId = await _waitForBookingAcceptanceViaSocket(
        bookingRequestId: bookingRequestId,
        timeout: Duration(seconds: (result.acceptanceWindowSeconds ?? 30) + 5),
      );
      if (searchDialogDismissed) {
        return;
      }
    }

    if (!searchDialogDismissed) {
      await _closeSearchDialog(dialogFuture);
    }

    if (!mounted) {
      return;
    }

    if (_isSearchingPartner) {
      setState(() {
        _isSearchingPartner = false;
      });
    }

    if (bookingId == null || bookingId <= 0) {
      final shouldRetry = await showNoPartnerAcceptedDialog(context);
      if (shouldRetry && mounted) {
        await Future<void>.delayed(Duration.zero);
        await _onSearchPartnerTap(summary);
      }
      return;
    }

    BookingDetailsModal? bookingDetails;
    try {
      bookingDetails = await ref
          .read(cartRepositoryProvider)
          .getPartnerBooking(bookingId: bookingId);
      _partnerDetails = bookingDetails.toPartnerDetailsMap();
      
      if (mounted) {
        AppToast.success('Partner request accepted');
      }
    } catch (error) {
      debugPrint('[BOOKING] Failed to load booking details: $error');
      if (mounted) {
        AppToast.error('Failed to load booking details');
      }
    }

    debugPrint('[BOOKING] ===== REDIRECTING TO BOOKING CONFIRMED SCREEN =====');
    debugPrint('[BOOKING] BookingId: $bookingId');
    debugPrint('[BOOKING] Summary Data:');
    debugPrint('  - Items Count: ${summary.items.length}');
    debugPrint('  - Items: ${summary.items}');
    debugPrint('  - Address: ${summary.address}');
    debugPrint('  - Pricing Total: ${summary.pricing.total}');
    if (bookingDetails != null) {
      debugPrint('  - Booking Status: ${bookingDetails.status}');
      debugPrint(
        '  - Partner Name: ${bookingDetails.helper?.displayName ?? 'Partner'}',
      );
    }
    debugPrint('[BOOKING] ===== NAVIGATING NOW =====');

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingConfirmedScreen(
          summary: summary,
          bookingId: bookingId!,
          bookingDetails: bookingDetails,
          partnerDetails: _partnerDetails,
        ),
      ),
    );
  }

  Future<int?> _waitForBookingAcceptanceViaSocket({
    required int bookingRequestId,
    required Duration timeout,
  }) async {
    await _ensureBookingSocketConnected();
    if (_bookingSocket == null) {
      return null;
    }

    _pendingBookingRequestId = bookingRequestId;
    _pendingAcceptCompleter = Completer<int?>();
    _pendingAcceptTimeout?.cancel();
    _pendingAcceptTimeout = Timer(timeout, () {
      debugPrint(
        '[SOCKET][BOOKING] Timeout waiting for accept '
        '(bookingRequestId=$bookingRequestId, timeout=${timeout.inSeconds}s)',
      );
      if (!(_pendingAcceptCompleter?.isCompleted ?? true)) {
        _pendingAcceptCompleter?.complete(null);
      }
    });

    _bookingSocket?.emit('booking_request_subscribe', <String, dynamic>{
      'bookingRequestId': bookingRequestId,
      if (_pendingUserId != null) 'userId': _pendingUserId,
    });
    _bookingSocket?.emit('booking-request-subscribe', <String, dynamic>{
      'bookingRequestId': bookingRequestId,
      if (_pendingUserId != null) 'userId': _pendingUserId,
    });
    _bookingSocket?.emit('bookingRequestSubscribe', <String, dynamic>{
      'bookingRequestId': bookingRequestId,
      if (_pendingUserId != null) 'userId': _pendingUserId,
    });
    debugPrint(
      '[SOCKET][BOOKING] Subscribe emitted for bookingRequestId=$bookingRequestId'
      '${_pendingUserId != null ? ', userId=$_pendingUserId' : ''}',
    );

    final result = await _pendingAcceptCompleter!.future;
    debugPrint(
      '[SOCKET][BOOKING] waitForBookingAcceptance completed with bookingId=$result',
    );

    _pendingAcceptTimeout?.cancel();
    _pendingAcceptTimeout = null;
    _pendingAcceptCompleter = null;
    _pendingBookingRequestId = null;

    return result;
  }

  Future<void> _ensureBookingSocketConnected() async {
    if (_bookingSocket != null) {
      if (!(_bookingSocket!.connected)) {
        _bookingSocket!.connect();
      }
      return;
    }

    final token = await ref.read(sessionManagerProvider).accessToken;
    if (token == null || token.trim().isEmpty) {
      return;
    }

    final sessionData = await ref.read(sessionManagerProvider).getSessionData();
    _pendingUserId = _toInt(sessionData['userId']);

    _bookingSocket = io.io(
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
      _registerBookingSocketListeners();
      _socketListenersAttached = true;
    }

    _bookingSocket!.connect();
  }

  void _registerBookingSocketListeners() {
    final socket = _bookingSocket;
    if (socket == null) {
      return;
    }

    socket.onConnect((_) {
      debugPrint('[SOCKET][BOOKING] Connected');
    });

    socket.onAny((event, payload) {
      debugPrint('[SOCKET][BOOKING] onAny event=$event payload=$payload');
    });

    socket.onConnectError((error) {
      debugPrint('[SOCKET][BOOKING] Connect error: $error');
    });

    socket.onError((error) {
      debugPrint('[SOCKET][BOOKING] Socket error: $error');
    });

    socket.onDisconnect((reason) {
      debugPrint('[SOCKET][BOOKING] Disconnected: $reason');
    });

    const bookingAcceptEvents = <String>[
      'booking:accepted',
      'booking_request_accepted',
      'booking-request-accepted',
      'bookingRequestAccepted',
      'booking_request_updated',
      'booking-request-updated',
      'bookingRequestUpdated',
      'booking_request_status_updated',
      'booking-request-status-updated',
      'bookingRequestStatusUpdated',
      'booking_request_accept',
      'booking-request-accept',
      'bookingRequestAccept',
      'booking_accepted',
      'booking-accepted',
      'bookingAccepted',
      'booking_assigned',
      'booking-assigned',
      'bookingAssigned',
    ];

    for (final eventName in bookingAcceptEvents) {
      socket.on(eventName, _onBookingAcceptedEvent);
    }
  }

  void _onBookingAcceptedEvent(dynamic payload) {
    final map = _normalizeEventPayload(payload);
    if (map == null) {
      return;
    }

    debugPrint('[SOCKET][BOOKING] ===== WEBHOOK DATA =====');
    debugPrint('[SOCKET][BOOKING] Full payload: $map');

    // Extract partner information if available
    if (map['partner'] is Map<String, dynamic>) {
      final partner = map['partner'] as Map<String, dynamic>;
      _partnerDetails = partner;
      debugPrint('[SOCKET][BOOKING] Partner Details:');
      debugPrint('  - ID: ${partner['id']}');
      debugPrint('  - Name: ${partner['name']}');
      debugPrint('  - Email: ${partner['email']}');
      debugPrint('  - Phone: ${partner['phone']}');
      debugPrint('  - Rating: ${partner['rating']}');
      debugPrint('  - Experience: ${partner['experience']}');
      debugPrint('  - ProfileImage: ${partner['profileImage']}');
      debugPrint('  - Full Partner Data: $partner');
    }

    // Extract user information if available
    if (map['user'] is Map<String, dynamic>) {
      final user = map['user'] as Map<String, dynamic>;
      debugPrint('[SOCKET][BOOKING] User Details: $user');
    }

    // Extract booking information
    if (map['booking'] is Map<String, dynamic>) {
      final booking = map['booking'] as Map<String, dynamic>;
      debugPrint('[SOCKET][BOOKING] Booking Details: $booking');
    }

    final payloadRequestId = _toInt(
      map['bookingRequestId'] ??
          map['requestId'] ??
          (map['bookingRequest'] is Map<String, dynamic>
              ? (map['bookingRequest'] as Map<String, dynamic>)['id']
              : null),
    );

    if (_pendingBookingRequestId != null &&
        payloadRequestId != null &&
        payloadRequestId != _pendingBookingRequestId) {
      debugPrint(
        '[SOCKET][BOOKING] Ignored event: request id mismatch '
        '(expected=$_pendingBookingRequestId, got=$payloadRequestId)',
      );
      return;
    }

    final bookingId = _toInt(
      map['bookingId'] ??
          map['acceptedBookingId'] ??
          map['id'] ??
          (map['booking'] is Map<String, dynamic>
              ? (map['booking'] as Map<String, dynamic>)['id']
              : null),
    );

    if (bookingId == null || bookingId <= 0) {
      debugPrint('[SOCKET][BOOKING] Event received but booking id not found');
      return;
    }

    debugPrint('[SOCKET][BOOKING] Accepted booking id received: $bookingId');
    debugPrint('[SOCKET][BOOKING] ===== END WEBHOOK DATA =====');
    if (!(_pendingAcceptCompleter?.isCompleted ?? true)) {
      _pendingAcceptCompleter?.complete(bookingId);
    }
  }

  Map<String, dynamic>? _normalizeEventPayload(dynamic payload) {
    final root = _toMap(payload);
    if (root == null) {
      return null;
    }

    final nestedData = root['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }
    if (nestedData is Map) {
      return nestedData.map((key, value) => MapEntry(key.toString(), value));
    }

    return root;
  }

  Future<void> _closeSearchDialog(Future<void> dialogFuture) async {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
    await dialogFuture;
  }

  Map<String, dynamic>? _toMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }
    if (payload is String) {
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return decoded.map((key, value) => MapEntry(key.toString(), value));
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> _onSelectSlotTap(CartSummaryModal summary) async {
    await showSelectSlotBottomSheet(context, summary);

    if (!mounted) {
      return;
    }

    await ref.read(cartProvider.notifier).loadSummary(forceRefresh: true);
  }

  bool _hasSelectedSlot(CartSummaryModal summary) {
    final hasDate = (summary.slot.date ?? '').trim().isNotEmpty;
    final hasTime = (summary.slot.time ?? '').trim().isNotEmpty;
    return hasDate && hasTime;
  }

  Future<void> _onChangeAddressTap() async {
    final selectedAddress = await showModalBottomSheet<SavedAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddressSelectionBottomSheet(
        currentAddressId: ref.read(cartProvider).summary?.address?.id,
        onAddNewAddress: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SavedAddressesScreen(),
            ),
          );
        },
      ),
    );

    if (!mounted || selectedAddress == null) {
      return;
    }

    await ref
        .read(cartProvider.notifier)
        .updateAddress(addressId: selectedAddress.id);

    if (!mounted) {
      return;
    }

    final latestState = ref.read(cartProvider);
    if (latestState.errorMessage == null || latestState.errorMessage!.isEmpty) {
      AppToast.success('Service address updated');
    }
  }

  String _generateIdempotencyKey() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');

    return '${bytes.take(4).map(hex).join()}-'
        '${bytes.skip(4).take(2).map(hex).join()}-'
        '${bytes.skip(6).take(2).map(hex).join()}-'
        '${bytes.skip(8).take(2).map(hex).join()}-'
        '${bytes.skip(10).take(6).map(hex).join()}';
  }

  Widget _billRow(
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
    bool isTotal = false,
    bool isLabelUnderlined = false,
    VoidCallback? onLabelTap,
  }) {
    final labelStyle = TextStyle(
      fontSize: isTotal ? 22 : 15,
      fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
      color: labelColor ?? const Color(0xFF1F2937),
    );

    final textPainter = TextPainter(
      text: TextSpan(text: label, style: labelStyle),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();

    final labelWidget = isLabelUnderlined
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: 4),
              CustomPaint(
                size: Size(textPainter.width, 2),
                painter: const _DottedLinePainter(
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          )
        : Text(label, style: labelStyle);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          InkWell(
            onTap: onLabelTap,
            borderRadius: BorderRadius.circular(4),
            child: labelWidget,
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 30 : 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTaxFeeInfoSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 26,
                  color: Color(0xFF374151),
                ),
                const SizedBox(height: 10),
                const Text(
                  'What is Tax & Fare ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Taxes levied as per govt. regulations subject to change basis final service value. The fee goes towards training of partners and providing support & assistance during the service.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0B1F3A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Okay, got it'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _slotInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _addressSummary(CartSummaryModal summary) {
    final address = summary.address;
    if (address == null) {
      return const Text(
        'Service address not selected',
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          height: 1.35,
        ),
      );
    }

    final addressLabel = address.label.trim().isEmpty ? 'Home' : address.label;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          addressLabel,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${address.address}, ${address.city} - ${address.pinCode}',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  const _DottedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const dotSpacing = 4.0;
    const dotRadius = 0.9;
    final y = size.height / 2;

    for (double x = 0; x <= size.width; x += dotSpacing) {
      canvas.drawCircle(Offset(x, y), dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

String _formatBookingDate(String? rawDate) {
  final date = DateTime.tryParse(rawDate ?? '');
  if (date == null) {
    return 'Not selected';
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
    return 'Not selected';
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

class _AppliedCouponsCard extends StatelessWidget {
  const _AppliedCouponsCard({
    required this.appliedCouponsAsync,
    required this.summary,
    required this.onTapApplyCoupon,
  });

  final AsyncValue<AppliedCouponsModal> appliedCouponsAsync;
  final CartSummaryModal summary;
  final VoidCallback onTapApplyCoupon;

  @override
  Widget build(BuildContext context) {
    final fallbackRows = _fallbackAppliedCouponRows(summary);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTapApplyCoupon,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: const [
                  Icon(
                    Icons.discount_outlined,
                    color: Color(0xFF0EA5E9),
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Apply Coupon',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
          appliedCouponsAsync.when(
            loading: () {
              if (fallbackRows.isEmpty) {
                return const SizedBox.shrink();
              }
              return _AppliedCouponRows(messages: fallbackRows);
            },
            error: (_, __) {
              if (fallbackRows.isEmpty) {
                return const SizedBox.shrink();
              }
              return _AppliedCouponRows(messages: fallbackRows);
            },
            data: (appliedData) {
              final rows = appliedData.coupons
                  .map((coupon) => coupon.message)
                  .where((message) => message.trim().isNotEmpty)
                  .toList(growable: false);

              if (rows.isEmpty && fallbackRows.isEmpty) {
                return const SizedBox.shrink();
              }

              return _AppliedCouponRows(
                messages: rows.isEmpty ? fallbackRows : rows,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AppliedCouponRows extends StatelessWidget {
  const _AppliedCouponRows({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 8),
          ...messages.map(
            (message) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  const Icon(
                    Icons.discount_outlined,
                    size: 16,
                    color: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 2),
                  const Text(
                    'Applied',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _fallbackAppliedCouponRows(CartSummaryModal summary) {
  final discountAmount = summary.pricing.discount.abs();
  final coupon = summary.coupon;
  if (discountAmount <= 0 && coupon is! Map<String, dynamic>) {
    return const <String>[];
  }

  var offerText = 'applied coupon';
  if (coupon is Map<String, dynamic>) {
    final discountType = coupon['discountType']?.toString().toUpperCase() ?? '';
    final discountValue = _parseInt(coupon['discountValue']);
    if (discountType.startsWith('PERCENT') && discountValue > 0) {
      offerText = 'flat $discountValue% off';
    } else if (discountValue > 0) {
      offerText = 'flat ${formatInr(discountValue)} off';
    }
  }

  if (discountAmount <= 0 && coupon is Map<String, dynamic>) {
    final code = coupon['code']?.toString() ?? '';
    if (code.isNotEmpty) {
      return <String>['$code applied with $offerText'];
    }
    return <String>['Coupon applied with $offerText'];
  }

  return <String>['${formatInr(discountAmount)} saved with $offerText'];
}

int _parseInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final cleaned = (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9-]'), '');
  if (cleaned.isEmpty || cleaned == '-') {
    return 0;
  }
  return int.tryParse(cleaned) ?? 0;
}



class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.isPrimary,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: CustomPaint(
        painter: const _DashedRoundedRectPainter(
          color: Color(0xFF000000),
          strokeWidth: 1.2,
          gap: 3.2,
          dash: 1,
          radius: 14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF0097D5), size: 14),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0097D5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRoundedRectPainter extends CustomPainter {
  const _DashedRoundedRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.dash,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = (distance + dash)
            .clamp(0.0, metric.length)
            .toDouble();
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.72,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 112,
              color: Color(0xFF1F2937),
            ),
            const SizedBox(height: 18),
            const Text(
              'Your Cart Is Currently Empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Look like you haven’t added anything to your cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 145,
              height: 38,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B1F3A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Add Now',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  const _SimpleTile({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _CartServiceTile extends ConsumerWidget {
  const _CartServiceTile({required this.item});

  final CartItemModal item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final isServiceMutating = cartState.mutatingServiceId == item.serviceId;
    final isIncrementLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'increment';
    final isDecrementLoading =
        isServiceMutating && cartState.mutatingServiceAction == 'decrement';
    final disableIncrement =
        item.quantity >= CartController.maxQuantity ||
        cartState.isMutating ||
        cartState.mutatingServiceId != null;
    final disableDecrement =
      cartState.isMutating || cartState.mutatingServiceId != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 66,
              height: 66,
              child: item.imageUrl == null || item.imageUrl!.isEmpty
                  ? Container(
                      color: const Color(0xFFE5E7EB),
                      child: const Icon(Icons.cleaning_services_outlined),
                    )
                  : Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: const Color(0xFFE5E7EB));
                      },
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      formatInr(item.priceAtAdded),
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: disableDecrement
                                ? null
                                : () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .decrementByServiceId(item.serviceId);
                                  },
                            child: isDecrementLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF0097D5),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.remove,
                                    size: 20,
                                    color: disableDecrement
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF0097D5),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${item.quantity}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: disableIncrement
                                ? null
                                : () {
                                    ref
                                        .read(cartProvider.notifier)
                                        .incrementByServiceId(item.serviceId);
                                  },
                            child: isIncrementLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF00B6B5),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.add,
                                    size: 20,
                                    color: disableIncrement
                                        ? const Color(0xFF9CA3AF)
                                        : const Color(0xFF00B6B5),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.duration == 1 ? '1 hr' : '${item.duration} hrs',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
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
