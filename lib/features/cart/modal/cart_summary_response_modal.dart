import 'cart_summary_modal.dart';

class CartSummaryResponseModal {
  const CartSummaryResponseModal({required this.success, required this.data});

  final bool success;
  final CartSummaryModal data;

  factory CartSummaryResponseModal.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return CartSummaryResponseModal(
      success: json['success'] == true,
      data: dataJson is Map<String, dynamic>
          ? CartSummaryModal.fromJson(dataJson)
          : CartSummaryModal.empty(),
    );
  }
}
