import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modal/service_detail_modal.dart';
import 'service_provider.dart';

final serviceDetailProvider = FutureProvider.autoDispose
    .family<ServiceDetailModal, int>((ref, serviceId) {
      return ref.read(serviceRepositoryProvider).getServiceDetails(serviceId);
    });
