import 'package:flutter/widgets.dart';

import 'payment_intent.dart';

enum GatewayPaymentStatus { completed, cancelled, failed }

class GatewayPaymentResult {
  final GatewayPaymentStatus status;
  final String txRef;
  final String? transactionId;
  final NativePurchaseVerificationData? nativeVerificationData;
  final String? message;

  const GatewayPaymentResult({
    required this.status,
    required this.txRef,
    this.transactionId,
    this.nativeVerificationData,
    this.message,
  });

  bool get isCompleted => status == GatewayPaymentStatus.completed;
}

class NativePurchaseVerificationData {
  final String completionKey;
  final String productId;
  final String? purchaseId;
  final String? transactionDate;
  final String source;
  final String localVerificationData;
  final String serverVerificationData;

  const NativePurchaseVerificationData({
    required this.completionKey,
    required this.productId,
    required this.source,
    required this.localVerificationData,
    required this.serverVerificationData,
    this.purchaseId,
    this.transactionDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'completionKey': completionKey,
      'productId': productId,
      'purchaseId': purchaseId,
      'transactionDate': transactionDate,
      'source': source,
      'localVerificationData': localVerificationData,
      'serverVerificationData': serverVerificationData,
    };
  }
}

abstract class PaymentGateway {
  Future<GatewayPaymentResult> charge({
    required BuildContext context,
    required PaymentIntent intent,
  });

  Future<GatewayPaymentResult> authorizeRedirect({
    required BuildContext context,
    required String redirectUrl,
    required String fallbackTxRef,
  });
}
