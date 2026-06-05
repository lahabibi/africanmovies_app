enum PurchaseResultStatus { success, alreadyPurchased, cancelled, failed }

class PurchaseResult {
  final PurchaseResultStatus status;
  final String message;
  final String? txRef;
  final String? transactionId;
  final String? paymentType;

  const PurchaseResult({
    required this.status,
    required this.message,
    this.txRef,
    this.transactionId,
    this.paymentType,
  });

  bool get grantsAccess {
    return status == PurchaseResultStatus.success ||
        status == PurchaseResultStatus.alreadyPurchased;
  }

  bool get canSavePaymentMethod {
    final normalizedPaymentType = paymentType?.trim().toLowerCase();

    return status == PurchaseResultStatus.success &&
        transactionId?.trim().isNotEmpty == true &&
        normalizedPaymentType == 'card';
  }

  factory PurchaseResult.success({
    required String txRef,
    required String transactionId,
    String? paymentType,
  }) {
    return PurchaseResult(
      status: PurchaseResultStatus.success,
      message: 'Purchase successful. Added to your library.',
      txRef: txRef,
      transactionId: transactionId,
      paymentType: paymentType,
    );
  }

  factory PurchaseResult.alreadyPurchased() {
    return const PurchaseResult(
      status: PurchaseResultStatus.alreadyPurchased,
      message: 'You already have access to this movie.',
    );
  }

  factory PurchaseResult.cancelled() {
    return const PurchaseResult(
      status: PurchaseResultStatus.cancelled,
      message: 'Payment cancelled.',
    );
  }

  factory PurchaseResult.failed(String message) {
    return PurchaseResult(
      status: PurchaseResultStatus.failed,
      message: message,
    );
  }
}
