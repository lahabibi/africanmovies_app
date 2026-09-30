import 'package:africanmovies/core/network/api_client.dart';
import 'package:africanmovies/core/network/api_exception.dart';
import 'package:africanmovies/core/storage/device_identity_store.dart';
import 'package:africanmovies/core/storage/secure_token_store.dart';
import 'package:africanmovies/features/payment/data/payment_repository.dart';
import 'package:africanmovies/features/payment/domain/apple_refund_consent.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses current, versioned Apple refund consent', () {
    final consent = AppleRefundConsent.fromJson({
      'transactionId': '2000000123456789',
      'consented': true,
      'consentedAt': '2026-09-30T10:00:00.000Z',
      'withdrawnAt': null,
      'updatedAt': '2026-09-30T10:00:00.000Z',
      'consentVersion': 'v1',
      'requiredConsentVersion': 'v1',
    });

    expect(consent.transactionId, '2000000123456789');
    expect(consent.consented, isTrue);
    expect(consent.consentedAt, DateTime.utc(2026, 9, 30, 10));
    expect(consent.withdrawnAt, isNull);
    expect(consent.hasCurrentConsent, isTrue);
  });

  test('does not treat stale or missing versions as current consent', () {
    final stale = AppleRefundConsent.fromJson({
      'transactionId': '2000000123456789',
      'consented': true,
      'consentVersion': 'v0',
      'requiredConsentVersion': 'v1',
    });
    final missing = AppleRefundConsent.fromJson({
      'transactionId': '2000000123456789',
      'consented': true,
    });

    expect(stale.hasCurrentConsent, isFalse);
    expect(missing.hasCurrentConsent, isFalse);
  });

  test('fetches consent for the normalized Apple transaction ID', () async {
    final requests = <RequestOptions>[];
    final repository = _createRepository((options, handler) {
      requests.add(options);
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'transactionId': 'apple/transaction 1',
            'consented': false,
            'requiredConsentVersion': appleRefundConsentVersion,
          },
        ),
      );
    });

    final consent = await repository.fetchAppleRefundConsent(
      ' apple/transaction 1 ',
    );

    expect(requests.single.method, 'GET');
    expect(
      requests.single.path,
      '/payment/app-store/refund-consent/apple%2Ftransaction%201',
    );
    expect(consent.transactionId, 'apple/transaction 1');
    expect(consent.consented, isFalse);
  });

  test('grants current-version consent through the backend', () async {
    final requests = <RequestOptions>[];
    final repository = _createRepository((options, handler) {
      requests.add(options);
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'transactionId': '2000000123456789',
            'consented': true,
            'consentVersion': appleRefundConsentVersion,
            'requiredConsentVersion': appleRefundConsentVersion,
          },
        ),
      );
    });

    final consent = await repository.updateAppleRefundConsent(
      transactionId: '2000000123456789',
      consented: true,
    );

    expect(requests.single.method, 'PUT');
    expect(
      requests.single.path,
      '/payment/app-store/refund-consent/2000000123456789',
    );
    expect(requests.single.data, {
      'consented': true,
      'consentVersion': appleRefundConsentVersion,
    });
    expect(consent.hasCurrentConsent, isTrue);
  });

  test('withdraws consent without claiming a new consent version', () async {
    final requests = <RequestOptions>[];
    final repository = _createRepository((options, handler) {
      requests.add(options);
      handler.resolve(
        Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: 200,
          data: {
            'transactionId': '2000000123456789',
            'consented': false,
            'consentVersion': appleRefundConsentVersion,
            'requiredConsentVersion': appleRefundConsentVersion,
          },
        ),
      );
    });

    final consent = await repository.updateAppleRefundConsent(
      transactionId: '2000000123456789',
      consented: false,
    );

    expect(requests.single.data, {'consented': false});
    expect(consent.hasCurrentConsent, isFalse);
  });

  test('rejects an empty transaction before making an API request', () async {
    var requestCount = 0;
    final repository = _createRepository((options, handler) {
      requestCount += 1;
      handler.next(options);
    });

    await expectLater(
      repository.fetchAppleRefundConsent('  '),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      repository.updateAppleRefundConsent(transactionId: '', consented: true),
      throwsA(isA<ApiException>()),
    );

    expect(requestCount, 0);
  });
}

PaymentRepository _createRepository(
  void Function(RequestOptions, RequestInterceptorHandler) onRequest,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  final apiClient = ApiClient(
    tokenStore: _FakeSecureTokenStore(),
    deviceIdentityStore: DeviceIdentityStore(),
    dio: dio,
  );
  dio.interceptors.add(InterceptorsWrapper(onRequest: onRequest));

  return PaymentRepository(apiClient: apiClient);
}

class _FakeSecureTokenStore extends SecureTokenStore {
  @override
  Future<String?> readAccessToken() async => null;
}
