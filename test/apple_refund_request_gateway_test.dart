import 'package:africanmovies/features/payment/data/apple_refund_request_gateway.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.africanmovies.mobile/storekit_refund.test',
  );

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passes the normalized transaction ID to StoreKit', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          capturedCall = call;
          return 'submitted';
        });
    final gateway = AppleRefundRequestGateway(
      channel: channel,
      isIos: () => true,
    );

    final status = await gateway.beginRefundRequest(' 2000000123456789 ');

    expect(status, AppleRefundRequestStatus.submitted);
    expect(capturedCall?.method, 'beginRefundRequest');
    expect(capturedCall?.arguments, {'transactionId': '2000000123456789'});
  });

  test('reports when the user cancels the Apple sheet', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => 'cancelled');
    final gateway = AppleRefundRequestGateway(
      channel: channel,
      isIos: () => true,
    );

    final status = await gateway.beginRefundRequest('2000000123456789');

    expect(status, AppleRefundRequestStatus.cancelled);
  });

  test('preserves native StoreKit error codes and messages', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          throw PlatformException(
            code: 'duplicate_request',
            message: 'A refund request already exists for this purchase.',
          );
        });
    final gateway = AppleRefundRequestGateway(
      channel: channel,
      isIos: () => true,
    );

    await expectLater(
      gateway.beginRefundRequest('2000000123456789'),
      throwsA(
        isA<AppleRefundRequestException>()
            .having((error) => error.code, 'code', 'duplicate_request')
            .having(
              (error) => error.message,
              'message',
              'A refund request already exists for this purchase.',
            ),
      ),
    );
  });

  test('rejects empty transactions before invoking the channel', () async {
    var invocationCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          invocationCount += 1;
          return 'submitted';
        });
    final gateway = AppleRefundRequestGateway(
      channel: channel,
      isIos: () => true,
    );

    await expectLater(
      gateway.beginRefundRequest(' '),
      throwsA(
        isA<AppleRefundRequestException>().having(
          (error) => error.code,
          'code',
          'invalid_transaction',
        ),
      ),
    );
    expect(invocationCount, 0);
  });

  test('rejects non-iOS platforms before invoking the channel', () async {
    var invocationCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
          invocationCount += 1;
          return 'submitted';
        });
    final gateway = AppleRefundRequestGateway(
      channel: channel,
      isIos: () => false,
    );

    await expectLater(
      gateway.beginRefundRequest('2000000123456789'),
      throwsA(
        isA<AppleRefundRequestException>().having(
          (error) => error.code,
          'code',
          'unsupported_platform',
        ),
      ),
    );
    expect(invocationCount, 0);
  });
}
