import 'package:flutter/widgets.dart';

import 'payment_intent.dart';

enum GatewayPaymentStatus { completed, cancelled, failed }

class GatewayPaymentResult {
  final GatewayPaymentStatus status;
  final String txRef;
  final String? transactionId;
  final String? message;

  const GatewayPaymentResult({
    required this.status,
    required this.txRef,
    this.transactionId,
    this.message,
  });

  bool get isCompleted => status == GatewayPaymentStatus.completed;
}

abstract class PaymentGateway {
  Future<GatewayPaymentResult> charge({
    required BuildContext context,
    required PaymentIntent intent,
  });
}
