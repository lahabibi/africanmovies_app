enum SavedCardChargeStatus { successful, pending, alreadyPurchased, failed }

class SavedCardChargeResult {
  final SavedCardChargeStatus status;
  final String code;
  final String message;
  final String txRef;
  final String? transactionId;
  final String? redirectUrl;
  final String? paymentType;

  const SavedCardChargeResult({
    required this.status,
    required this.code,
    required this.message,
    required this.txRef,
    this.transactionId,
    this.redirectUrl,
    this.paymentType,
  });

  bool get isSuccessful => status == SavedCardChargeStatus.successful;

  bool get requiresAuthorization =>
      status == SavedCardChargeStatus.pending &&
      redirectUrl?.trim().isNotEmpty == true;

  bool get isAlreadyPurchased =>
      status == SavedCardChargeStatus.alreadyPurchased;

  factory SavedCardChargeResult.fromJson(Map<String, dynamic> json) {
    return SavedCardChargeResult(
      status: _readStatus(json['status']),
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      txRef: json['txRef']?.toString() ?? json['tx_ref']?.toString() ?? '',
      transactionId: json['transactionId']?.toString(),
      redirectUrl: json['redirectUrl']?.toString() ?? json['url']?.toString(),
      paymentType:
          json['paymentType']?.toString() ?? json['payment_type']?.toString(),
    );
  }

  static SavedCardChargeStatus _readStatus(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'successful' || 'success' => SavedCardChargeStatus.successful,
      'pending' => SavedCardChargeStatus.pending,
      'alreadypurchased' ||
      'already_purchased' => SavedCardChargeStatus.alreadyPurchased,
      _ => SavedCardChargeStatus.failed,
    };
  }
}
