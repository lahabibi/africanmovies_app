import 'package:africanmovies/features/payment/domain/payment_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'parses a refunded purchase without losing completed payment status',
    () {
      final response = PaymentHistoryResponse.fromJson({
        'items': [
          {
            'id': 'order-1',
            'type': 'payment',
            'txRef': 'tx-1',
            'accessStatus': 'refunded',
            'createdAt': '2026-07-08T23:53:45.967Z',
            'order': {
              'id': 'order-1',
              'txRef': 'tx-1',
              'movieId': 'movie-1',
              'paid': true,
              'active': false,
              'expired': true,
              'revoked': true,
              'currentTime': 0,
              'startWatch': false,
              'expiryDate': '2026-07-09T11:22:49.137Z',
              'revokedAt': '2026-07-09T11:22:49.137Z',
            },
            'payment': {
              'id': 'payment-1',
              'txRef': 'tx-1',
              'amount': 0.99,
              'currency': 'USD',
              'status': 'Completed',
              'financialStatus': 'refunded',
              'entitlementStatus': 'revoked',
              'transactionId': 'GPA.1',
              'createdAt': '2026-07-08T23:53:45.967Z',
              'refundedAt': '2026-07-09T11:22:49.137Z',
              'refundReason': 'GOOGLE_PLAY_REMORSE_DEVELOPER',
              'refundSource': 'google_play_reconciliation',
            },
          },
        ],
        'summary': {
          'total': 1,
          'completed': 0,
          'refunded': 1,
          'pending': 0,
          'failed': 0,
          'active': 0,
          'expired': 0,
          'orderOnly': 0,
        },
        'pagination': {
          'page': 1,
          'limit': 25,
          'total': 1,
          'totalPages': 1,
          'hasNextPage': false,
          'hasPreviousPage': false,
        },
      });

      final item = response.items.single;

      expect(item.payment?.status, 'Completed');
      expect(item.paymentStatusLabel, 'Refunded');
      expect(item.accessStatusLabel, 'Refunded');
      expect(item.payment?.isRefunded, isTrue);
      expect(item.payment?.refundReasonLabel, 'Refund requested');
      expect(item.order?.revoked, isTrue);
      expect(response.summary.refunded, 1);
      expect(response.summary.completed, 0);
    },
  );

  test('identifies only completed paid Apple transactions as refundable', () {
    PaymentHistoryPayment payment({
      String provider = 'apple',
      String platform = 'ios',
      String status = 'Completed',
      String financialStatus = 'completed',
      String entitlementStatus = 'active',
      Object amount = 0.99,
      String transactionId = '2000000123456789',
    }) {
      return PaymentHistoryPayment.fromJson({
        'id': 'payment-1',
        'txRef': 'tx-1',
        'amount': amount,
        'currency': 'USD',
        'status': status,
        'financialStatus': financialStatus,
        'provider': provider,
        'platform': platform,
        'productId': 'com.africanmovies.movie.test.rental',
        'entitlementStatus': entitlementStatus,
        'transactionId': transactionId,
      });
    }

    final eligible = payment();

    expect(eligible.provider, 'apple');
    expect(eligible.platform, 'ios');
    expect(eligible.productId, 'com.africanmovies.movie.test.rental');
    expect(eligible.canRequestAppleRefund, isTrue);
    expect(payment(provider: 'google').canRequestAppleRefund, isFalse);
    expect(payment(platform: 'android').canRequestAppleRefund, isFalse);
    expect(payment(status: 'Pending').canRequestAppleRefund, isFalse);
    expect(payment(financialStatus: 'refunded').canRequestAppleRefund, isFalse);
    expect(
      payment(entitlementStatus: 'revoked').canRequestAppleRefund,
      isFalse,
    );
    expect(payment(amount: 0).canRequestAppleRefund, isFalse);
    expect(payment(transactionId: 'GPA.123').canRequestAppleRefund, isFalse);
  });
}
