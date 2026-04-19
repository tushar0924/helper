import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modal/available_coupons_modal.dart';
import 'cart_provider.dart';

final availableCouponsProvider =
    FutureProvider.autoDispose<AvailableCouponsModal>((ref) {
      return ref.read(cartRepositoryProvider).getAvailableCoupons();
    });
