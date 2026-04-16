import 'cart_summary_modal.dart';

class CartUpdateResponseModal {
  const CartUpdateResponseModal({required this.success, required this.data});

  final bool success;
  final CartSummaryModal data;

  factory CartUpdateResponseModal.fromJson(Map<String, dynamic> json) {
    final dataJson = json['data'];
    return CartUpdateResponseModal(
      success: json['success'] == true,
      data: dataJson is Map<String, dynamic>
          ? CartSummaryModal.fromJson(dataJson)
          : CartSummaryModal.empty(),
    );
  }
}
