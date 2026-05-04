import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/banner_repository.dart';
import '../modal/banner_modal.dart';

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.read(apiClientProvider));
});

final bannerProvider =
    FutureProvider.autoDispose.family<List<BannerModal>, String?>((ref, city) {
  return ref.read(bannerRepositoryProvider).getBanners(city: city);
});
