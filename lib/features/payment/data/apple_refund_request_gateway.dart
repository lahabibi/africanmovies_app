import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum AppleRefundRequestStatus { submitted, cancelled }

class AppleRefundRequestException implements Exception {
  final String code;
  final String message;

  const AppleRefundRequestException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => message;
}

class AppleRefundRequestGateway {
  AppleRefundRequestGateway({MethodChannel? channel, bool Function()? isIos})
    : _channel = channel ?? const MethodChannel(_channelName),
      _isIos = isIos ?? _isCurrentPlatformIos;

  static const _channelName = 'com.africanmovies.mobile/storekit_refund';

  final MethodChannel _channel;
  final bool Function() _isIos;

  Future<AppleRefundRequestStatus> beginRefundRequest(
    String transactionId,
  ) async {
    final normalizedTransactionId = transactionId.trim();
    if (normalizedTransactionId.isEmpty) {
      throw const AppleRefundRequestException(
        code: 'invalid_transaction',
        message: 'Missing Apple transaction ID.',
      );
    }
    if (!_isIos()) {
      throw const AppleRefundRequestException(
        code: 'unsupported_platform',
        message: 'Apple refund requests are only available on iOS.',
      );
    }

    try {
      final result = await _channel.invokeMethod<String>('beginRefundRequest', {
        'transactionId': normalizedTransactionId,
      });

      return switch (result) {
        'submitted' => AppleRefundRequestStatus.submitted,
        'cancelled' => AppleRefundRequestStatus.cancelled,
        _ => throw const AppleRefundRequestException(
          code: 'invalid_response',
          message: 'The App Store returned an unexpected refund status.',
        ),
      };
    } on MissingPluginException {
      throw const AppleRefundRequestException(
        code: 'storekit_unavailable',
        message: 'App Store refund requests are temporarily unavailable.',
      );
    } on PlatformException catch (error) {
      final message = error.message?.trim();
      throw AppleRefundRequestException(
        code: error.code,
        message: message == null || message.isEmpty
            ? 'The App Store could not start the refund request.'
            : message,
      );
    }
  }

  static bool _isCurrentPlatformIos() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }
}
