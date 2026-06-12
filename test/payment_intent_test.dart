import 'package:africanmovies/features/payment/domain/payment_intent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses native store product id from payment intent', () {
    final intent = PaymentIntent.fromJson({
      'method': 'storeKit',
      'status': 'pending',
      'txRef': 'native-tx-1',
      'orderId': 'order-1',
      'amount': 0.99,
      'currency': 'USD',
      'storeProductId': 'com.africanmovies.movie.tima_bata_2026.rental',
    });

    expect(intent.method, PaymentMethod.storeKit);
    expect(
      intent.storeProductId,
      'com.africanmovies.movie.tima_bata_2026.rental',
    );
  });

  test('falls back to productId alias for native payment intent', () {
    final intent = PaymentIntent.fromJson({
      'method': 'googlePlay',
      'txRef': 'native-tx-2',
      'productId': 'am_tima_bata_2026_rental',
    });

    expect(intent.method, PaymentMethod.googlePlay);
    expect(intent.storeProductId, 'am_tima_bata_2026_rental');
  });
}
