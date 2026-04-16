import 'cart_summary_modal.dart';

class CartClearResponseModal {
  const CartClearResponseModal({required this.success, required this.data});

  final bool success;
  final CartSummaryModal data;

  factory CartClearResponseModal.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return CartClearResponseModal(
      success: json['success'] == true,
      data: dataJson is Map<String, dynamic>
          ? CartSummaryModal.fromJson(dataJson)
          : CartSummaryModal.empty(),
    );
  }
}
