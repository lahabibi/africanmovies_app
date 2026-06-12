enum PaymentMethod { none, flutterwave, storeKit, googlePlay }

enum PaymentIntentStatus { pending, alreadyPurchased }

class PaymentIntent {
  final PaymentMethod method;
  final PaymentIntentStatus status;
  final String txRef;
  final String orderId;
  final double amount;
  final String currency;
  final String paymentOptions;
  final String? storeProductId;
  final String redirectUrl;
  final String publicKey;
  final bool isTestMode;
  final PaymentCustomer customer;

  const PaymentIntent({
    required this.method,
    required this.status,
    required this.txRef,
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.paymentOptions,
    this.storeProductId,
    required this.redirectUrl,
    required this.publicKey,
    required this.isTestMode,
    required this.customer,
  });

  bool get isAlreadyPurchased {
    return status == PaymentIntentStatus.alreadyPurchased;
  }

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      method: _readMethod(json['method']),
      status: _readStatus(json['status']),
      txRef: json['txRef']?.toString() ?? json['tx_ref']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: _readDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'USD',
      paymentOptions: json['paymentOptions']?.toString() ?? 'card',
      storeProductId:
          _readOptionalCleanString(json['storeProductId']) ??
          _readOptionalCleanString(json['productId']),
      redirectUrl: json['redirectUrl']?.toString() ?? '',
      publicKey: json['publicKey']?.toString() ?? '',
      isTestMode: json['isTestMode'] == true,
      customer: PaymentCustomer.fromJson(
        json['customer'] is Map
            ? Map<String, dynamic>.from(json['customer'] as Map)
            : const {},
      ),
    );
  }

  static PaymentMethod _readMethod(Object? value) {
    return switch (value?.toString()) {
      'flutterwave' => PaymentMethod.flutterwave,
      'storeKit' => PaymentMethod.storeKit,
      'googlePlay' => PaymentMethod.googlePlay,
      _ => PaymentMethod.none,
    };
  }

  static PaymentIntentStatus _readStatus(Object? value) {
    return switch (value?.toString()) {
      'alreadyPurchased' => PaymentIntentStatus.alreadyPurchased,
      _ => PaymentIntentStatus.pending,
    };
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _readOptionalCleanString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }
}

class PaymentCustomer {
  final String email;
  final String name;
  final String phoneNumber;

  const PaymentCustomer({
    required this.email,
    required this.name,
    required this.phoneNumber,
  });

  factory PaymentCustomer.fromJson(Map<String, dynamic> json) {
    return PaymentCustomer(
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }
}
