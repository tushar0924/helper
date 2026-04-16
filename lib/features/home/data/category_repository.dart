import '../../../network/api_client.dart';
import '../../../network/api_endpoint.dart';
import '../modal/category_modal.dart';

class CategoryRepository {
  CategoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<CategoryModal>> getCategories() async {
    final response = await _apiClient.getJson(HomeApiEndpoint.categories);

    if (response['success'] == false) {
      throw ApiException(
        message: response['message']?.toString() ?? 'Unable to load categories',
      );
    }

    final data = response['data'];
    if (data is! List) {
      return const <CategoryModal>[];
    }

    final categories = data
        .whereType<Map<String, dynamic>>()
        .map(CategoryModal.fromJson)
        .toList();

    categories.sort((a, b) {
      final orderCompare = a.displayOrder.compareTo(b.displayOrder);
      if (orderCompare != 0) {
        return orderCompare;
      }
      return a.id.compareTo(b.id);
    });

    return categories;
  }
}
