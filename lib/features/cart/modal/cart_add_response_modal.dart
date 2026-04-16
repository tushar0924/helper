import 'cart_summary_modal.dart';

class CartAddResponseModal {
  const CartAddResponseModal({required this.success, required this.data});

  final bool success;
  final CartSummaryModal data;

  factory CartAddResponseModal.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return CartAddResponseModal(
      success: json['success'] == true,
      data: dataJson is Map<String, dynamic>
          ? CartSummaryModal.fromJson(dataJson)
          : CartSummaryModal.empty(),
    );
  }
}
