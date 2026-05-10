import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'address_provider.dart';
import '../data/address_repository.dart';
import '../modal/in_progress_booking_modal.dart';

final inProgressBookingsProvider =
    FutureProvider.autoDispose<InProgressBookingsModal>((ref) async {
  return ref.read(addressRepositoryProvider).getInProgressBookings();
});
