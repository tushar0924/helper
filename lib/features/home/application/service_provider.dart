import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/service_repository.dart';
import '../modal/service_modal.dart';

class ServiceState {
  const ServiceState({
    this.isLoading = false,
    this.categoryId,
    this.items = const <ServiceModal>[],
    this.errorMessage,
  });

  final bool isLoading;
  final int? categoryId;
  final List<ServiceModal> items;
  final String? errorMessage;

  ServiceState copyWith({
    bool? isLoading,
    int? categoryId,
    List<ServiceModal>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ServiceState(
      isLoading: isLoading ?? this.isLoading,
      categoryId: categoryId ?? this.categoryId,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final serviceRepositoryProvider = Provider<ServiceRepository>((ref) {
  return ServiceRepository(ref.read(apiClientProvider));
});

class ServiceController extends StateNotifier<ServiceState> {
  ServiceController(this._repository) : super(const ServiceState());

  final ServiceRepository _repository;

  Future<void> loadServicesForCategory(
    int categoryId, {
    bool forceRefresh = false,
  }) async {
    if (state.isLoading && state.categoryId == categoryId) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      categoryId: categoryId,
      items: const <ServiceModal>[],
      clearError: true,
    );

    try {
      final services = await _repository.getServicesByCategory(categoryId);
      state = state.copyWith(
        isLoading: false,
        categoryId: categoryId,
        items: services,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        categoryId: categoryId,
        errorMessage: error.toString(),
      );
    }
  }
}

final serviceControllerProvider =
    StateNotifierProvider<ServiceController, ServiceState>((ref) {
      return ServiceController(ref.read(serviceRepositoryProvider));
    });
