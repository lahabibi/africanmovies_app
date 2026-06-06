import 'package:flutter/widgets.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import 'flutterwave_checkout_screen.dart';
import '../domain/payment_gateway.dart';
import '../domain/payment_intent.dart';

class FlutterwavePaymentGateway implements PaymentGateway {
  static const _logoUrl =
      'https://rabiu-app-files.s3.us-east-1.amazonaws.com/06-+AFRICAN+MOVIES+LOGO+-+BS+copy.png';
  static const _testCheckoutUrl =
      'https://ravesandboxapi.flutterwave.com/v3/sdkcheckout/payments';
  static const _liveCheckoutUrl =
      'https://api.ravepay.co/v3/sdkcheckout/payments';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: AppConfig.requestTimeout,
      receiveTimeout: AppConfig.requestTimeout,
      sendTimeout: AppConfig.requestTimeout,
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  @override
  Future<GatewayPaymentResult> charge({
    required BuildContext context,
    required PaymentIntent intent,
  }) async {
    final checkoutUrl = await _createCheckoutUrl(intent);
    if (!context.mounted) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.cancelled,
        txRef: intent.txRef,
      );
    }

    final result = await Navigator.push<GatewayPaymentResult>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => FlutterwaveCheckoutScreen(
          checkoutUrl: checkoutUrl,
          fallbackTxRef: intent.txRef,
        ),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    return result ??
        GatewayPaymentResult(
          status: GatewayPaymentStatus.cancelled,
          txRef: intent.txRef,
        );
  }

  @override
  Future<GatewayPaymentResult> authorizeRedirect({
    required BuildContext context,
    required String redirectUrl,
    required String fallbackTxRef,
  }) async {
    final normalizedRedirectUrl = redirectUrl.trim();
    final normalizedTxRef = fallbackTxRef.trim();

    if (normalizedRedirectUrl.isEmpty || normalizedTxRef.isEmpty) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.failed,
        txRef: normalizedTxRef,
        message: 'Payment authorization details were missing.',
      );
    }

    if (!context.mounted) {
      return GatewayPaymentResult(
        status: GatewayPaymentStatus.cancelled,
        txRef: normalizedTxRef,
      );
    }

    final result = await Navigator.push<GatewayPaymentResult>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => FlutterwaveCheckoutScreen(
          checkoutUrl: normalizedRedirectUrl,
          fallbackTxRef: normalizedTxRef,
        ),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    return result ??
        GatewayPaymentResult(
          status: GatewayPaymentStatus.cancelled,
          txRef: normalizedTxRef,
        );
  }

  Future<String> _createCheckoutUrl(PaymentIntent intent) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        intent.isTestMode ? _testCheckoutUrl : _liveCheckoutUrl,
        data: _checkoutPayload(intent),
        options: Options(headers: {'Authorization': intent.publicKey}),
      );

      final data = response.data;
      final checkoutUrl = _readCheckoutUrl(data);
      if (checkoutUrl.isEmpty) {
        throw const ApiException('Unable to open secure checkout');
      }

      return checkoutUrl;
    } on DioException catch (error) {
      final message = error.response?.data is Map
          ? (error.response?.data as Map)['message']?.toString()
          : null;
      throw ApiException(message ?? 'Unable to open secure checkout');
    }
  }

  Map<String, dynamic> _checkoutPayload(PaymentIntent intent) {
    return _removeEmptyValues({
      'tx_ref': intent.txRef,
      'publicKey': intent.publicKey,
      'amount': intent.amount.toStringAsFixed(2),
      'currency': intent.currency,
      'payment_options': intent.paymentOptions,
      'redirect_url': intent.redirectUrl,
      'customer': _removeEmptyValues({
        'email': intent.customer.email,
        'phonenumber': intent.customer.phoneNumber,
        'name': intent.customer.name,
      }),
      'customizations': _removeEmptyValues({
        'title': 'African Movies',
        'description': 'Movie purchase',
        'logo': _logoUrl,
      }),
    });
  }

  String _readCheckoutUrl(Map<String, dynamic>? json) {
    final data = json?['data'];
    if (data is! Map) return '';

    return data['link']?.toString() ?? '';
  }

  Map<String, dynamic> _removeEmptyValues(Map<String, dynamic> data) {
    return Map.fromEntries(
      data.entries.where((entry) {
        final value = entry.value;
        if (value == null) return false;
        if (value is String && value.isEmpty) return false;

        return true;
      }),
    );
  }
}
