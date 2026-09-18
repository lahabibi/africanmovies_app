import 'package:flutter/widgets.dart';

import 'payment_intent.dart';

enum GatewayPaymentStatus { completed, pending, cancelled, failed }

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
  bool get isPending => status == GatewayPaymentStatus.pending;
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

  factory NativePurchaseVerificationData.fromJson(Map<String, dynamic> json) {
    return NativePurchaseVerificationData(
      completionKey: json['completionKey']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      purchaseId: json['purchaseId']?.toString(),
      transactionDate: json['transactionDate']?.toString(),
      source: json['source']?.toString() ?? '',
      localVerificationData: json['localVerificationData']?.toString() ?? '',
      serverVerificationData: json['serverVerificationData']?.toString() ?? '',
    );
  }

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
