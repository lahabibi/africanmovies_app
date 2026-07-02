class PaymentConfirmation {
  final String status;
  final String? paymentType;
  final bool alreadyProcessed;
  final String? transactionId;
  final String? txRef;
  final String? movieId;

  const PaymentConfirmation({
    required this.status,
    this.paymentType,
    required this.alreadyProcessed,
    this.transactionId,
    this.txRef,
    this.movieId,
  });

  bool get isSuccessful => status == 'successful';
  bool get isPending => status == 'pending';

  factory PaymentConfirmation.fromJson(Map<String, dynamic> json) {
    return PaymentConfirmation(
      status: json['status']?.toString() ?? '',
      paymentType: json['payment_type']?.toString(),
      alreadyProcessed: json['alreadyProcessed'] == true,
      transactionId: json['transactionId']?.toString(),
      txRef: json['txRef']?.toString(),
      movieId: json['movieId']?.toString(),
    );
  }
}
