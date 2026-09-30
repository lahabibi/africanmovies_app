import 'package:africanmovies/core/network/api_exception.dart';
import 'package:africanmovies/features/payment/application/apple_refund_request_coordinator.dart';
import 'package:africanmovies/features/payment/data/apple_refund_request_gateway.dart';
import 'package:africanmovies/features/payment/domain/apple_refund_consent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'saves declined consent before starting the Apple refund request',
    () async {
      final events = <String>[];
      final coordinator = AppleRefundRequestCoordinator(
        loadConsent: (_) async => _consent(consented: false),
        updateConsent:
            ({required String transactionId, required bool consented}) async {
              events.add('consent:$transactionId:$consented');
              return _consent(consented: consented);
            },
        beginRefundRequest: (transactionId) async {
          events.add('refund:$transactionId');
          return AppleRefundRequestStatus.submitted;
        },
      );

      final status = await coordinator.requestRefund(
        transactionId: '2000000123456789',
        shareViewingActivity: false,
      );

      expect(status, AppleRefundRequestStatus.submitted);
      expect(events, [
        'consent:2000000123456789:false',
        'refund:2000000123456789',
      ]);
    },
  );

  test(
    'does not open StoreKit when the consent choice cannot be saved',
    () async {
      var refundStarted = false;
      final coordinator = AppleRefundRequestCoordinator(
        loadConsent: (_) async => _consent(consented: false),
        updateConsent:
            ({required String transactionId, required bool consented}) async {
              throw const ApiException('Could not save consent');
            },
        beginRefundRequest: (_) async {
          refundStarted = true;
          return AppleRefundRequestStatus.submitted;
        },
      );

      await expectLater(
        coordinator.requestRefund(
          transactionId: '2000000123456789',
          shareViewingActivity: true,
        ),
        throwsA(isA<ApiException>()),
      );
      expect(refundStarted, isFalse);
    },
  );
}

AppleRefundConsent _consent({required bool consented}) {
  return AppleRefundConsent(
    transactionId: '2000000123456789',
    consented: consented,
    consentVersion: consented ? appleRefundConsentVersion : null,
    requiredConsentVersion: appleRefundConsentVersion,
  );
}
