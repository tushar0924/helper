import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_provider.dart';
import '../data/category_repository.dart';
import '../modal/category_modal.dart';

class CategoryState {
  const CategoryState({
    this.isLoading = false,
    this.items = const <CategoryModal>[],
    this.errorMessage,
  });

  final bool isLoading;
  final List<CategoryModal> items;
  final String? errorMessage;

  CategoryState copyWith({
    bool? isLoading,
    List<CategoryModal>? items,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CategoryState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.read(apiClientProvider));
});

class CategoryController extends StateNotifier<CategoryState> {
  CategoryController(this._repository) : super(const CategoryState());

  final CategoryRepository _repository;

  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (state.isLoading) {
      return;
    }

    if (!forceRefresh && state.items.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.getCategories();
      state = state.copyWith(isLoading: false, items: categories);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }
}

final categoryControllerProvider =
    StateNotifierProvider<CategoryController, CategoryState>((ref) {
      return CategoryController(ref.read(categoryRepositoryProvider));
    });
