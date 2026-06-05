class PaymentConfirmation {
  final String status;
  final String? paymentType;
  final bool alreadyProcessed;

  const PaymentConfirmation({
    required this.status,
    this.paymentType,
    required this.alreadyProcessed,
  });

  bool get isSuccessful => status == 'successful';

  factory PaymentConfirmation.fromJson(Map<String, dynamic> json) {
    return PaymentConfirmation(
      status: json['status']?.toString() ?? '',
      paymentType: json['payment_type']?.toString(),
      alreadyProcessed: json['alreadyProcessed'] == true,
    );
  }
}
