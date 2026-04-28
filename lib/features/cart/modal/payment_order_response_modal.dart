class PaymentOrderResponseModal {
  const PaymentOrderResponseModal({
    required this.paymentId,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  final int paymentId;
  final String orderId;
  final int amount;
  final String currency;
  final String keyId;

  factory PaymentOrderResponseModal.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final payload = data is Map<String, dynamic>
        ? data
        : const <String, dynamic>{};

    return PaymentOrderResponseModal(
      paymentId: _asInt(payload['paymentId']),
      orderId: payload['orderId']?.toString() ?? '',
      amount: _asInt(payload['amount']),
      currency: payload['currency']?.toString() ?? 'INR',
      keyId: payload['keyId']?.toString() ?? '',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
