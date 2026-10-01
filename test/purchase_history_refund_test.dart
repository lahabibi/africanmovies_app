import 'package:africanmovies/core/theme/app_theme.dart';
import 'package:africanmovies/features/payment/application/apple_refund_request_coordinator.dart';
import 'package:africanmovies/features/payment/application/payment_providers.dart';
import 'package:africanmovies/features/payment/data/apple_refund_request_gateway.dart';
import 'package:africanmovies/features/payment/domain/apple_refund_consent.dart';
import 'package:africanmovies/features/payment/domain/payment_history.dart';
import 'package:africanmovies/features/profile/purchase_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('allows an Apple refund request without sharing viewing data', (
    tester,
  ) async {
    final choices = <bool>[];
    final startedTransactions = <String>[];
    final coordinator = AppleRefundRequestCoordinator(
      loadConsent: (_) async => const AppleRefundConsent(
        transactionId: '2000000123456789',
        consented: false,
        requiredConsentVersion: appleRefundConsentVersion,
      ),
      updateConsent:
          ({required String transactionId, required bool consented}) async {
            choices.add(consented);
            return AppleRefundConsent(
              transactionId: transactionId,
              consented: consented,
              consentVersion: consented ? appleRefundConsentVersion : null,
              requiredConsentVersion: appleRefundConsentVersion,
            );
          },
      beginRefundRequest: (transactionId) async {
        startedTransactions.add(transactionId);
        return AppleRefundRequestStatus.submitted;
      },
    );

    await _pumpHistory(
      tester,
      history: _history(provider: 'apple', platform: 'ios'),
      coordinator: coordinator,
    );

    await tester.tap(find.text('Apple Movie').first);
    await tester.pumpAndSettle();
    expect(find.text('Request Refund'), findsOneWidget);

    await tester.tap(find.text('Request Refund'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Request a refund'), findsOneWidget);

    await tester.tap(find.text('Continue to Apple'));
    await tester.pumpAndSettle();

    expect(choices, [false]);
    expect(startedTransactions, ['2000000123456789']);
    expect(find.text('Request Submitted'), findsOneWidget);
    expect(
      find.text(
        'Refund request sent to Apple. Apple will notify you of its decision.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('apple-refund-status-message')),
      findsOneWidget,
    );
  });

  testWidgets('keeps an Apple refund error visible in the details sheet', (
    tester,
  ) async {
    const errorMessage = 'A refund request already exists for this purchase.';
    final coordinator = AppleRefundRequestCoordinator(
      loadConsent: (_) async => const AppleRefundConsent(
        transactionId: '2000000123456789',
        consented: true,
        consentVersion: appleRefundConsentVersion,
        requiredConsentVersion: appleRefundConsentVersion,
      ),
      updateConsent:
          ({required String transactionId, required bool consented}) async {
            return AppleRefundConsent(
              transactionId: transactionId,
              consented: consented,
              consentVersion: appleRefundConsentVersion,
              requiredConsentVersion: appleRefundConsentVersion,
            );
          },
      beginRefundRequest: (_) async => throw const AppleRefundRequestException(
        code: 'duplicate_request',
        message: errorMessage,
      ),
    );

    await _pumpHistory(
      tester,
      history: _history(provider: 'apple', platform: 'ios'),
      coordinator: coordinator,
    );

    await tester.tap(find.text('Apple Movie').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Refund'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Continue to Apple'));
    await tester.pumpAndSettle();

    expect(find.text(errorMessage), findsOneWidget);
    expect(
      find.byKey(const Key('apple-refund-status-message')),
      findsOneWidget,
    );
    expect(find.text('Request Refund'), findsOneWidget);
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('request-apple-refund-button')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('shows when the Apple refund sheet is cancelled', (tester) async {
    final coordinator = AppleRefundRequestCoordinator(
      loadConsent: (_) async => const AppleRefundConsent(
        transactionId: '2000000123456789',
        consented: false,
        requiredConsentVersion: appleRefundConsentVersion,
      ),
      updateConsent:
          ({required String transactionId, required bool consented}) async {
            return AppleRefundConsent(
              transactionId: transactionId,
              consented: consented,
              consentVersion: consented ? appleRefundConsentVersion : null,
              requiredConsentVersion: appleRefundConsentVersion,
            );
          },
      beginRefundRequest: (_) async => AppleRefundRequestStatus.cancelled,
    );

    await _pumpHistory(
      tester,
      history: _history(provider: 'apple', platform: 'ios'),
      coordinator: coordinator,
    );

    await tester.tap(find.text('Apple Movie').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Request Refund'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Continue to Apple'));
    await tester.pumpAndSettle();

    expect(
      find.text('Refund request cancelled. No request was sent to Apple.'),
      findsOneWidget,
    );
    expect(find.text('Request Refund'), findsOneWidget);
  });

  testWidgets('does not show the Apple action for a Google Play purchase', (
    tester,
  ) async {
    final coordinator = AppleRefundRequestCoordinator(
      loadConsent: (_) async => throw StateError('should not load consent'),
      updateConsent:
          ({required String transactionId, required bool consented}) async {
            throw StateError('should not save consent');
          },
      beginRefundRequest: (_) async {
        throw StateError('should not open StoreKit');
      },
    );

    await _pumpHistory(
      tester,
      history: _history(
        provider: 'google',
        platform: 'android',
        transactionId: 'GPA.1234-5678',
      ),
      coordinator: coordinator,
    );

    await tester.tap(find.text('Apple Movie').first);
    await tester.pumpAndSettle();

    expect(find.text('Request Refund'), findsNothing);
  });
}

Future<void> _pumpHistory(
  WidgetTester tester, {
  required PaymentHistoryResponse history,
  required AppleRefundRequestCoordinator coordinator,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentHistoryProvider.overrideWith((ref) async => history),
        appleRefundRequestCoordinatorProvider.overrideWith(
          (ref) => coordinator,
        ),
        appleRefundRequestSupportedProvider.overrideWith((ref) => true),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const PurchaseHistoryScreen(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

PaymentHistoryResponse _history({
  required String provider,
  required String platform,
  String transactionId = '2000000123456789',
}) {
  return PaymentHistoryResponse.fromJson({
    'items': [
      {
        'id': 'payment-1',
        'type': 'payment',
        'txRef': 'tx-1',
        'accessStatus': 'active',
        'createdAt': '2026-09-30T10:00:00.000Z',
        'movie': {'id': 'movie-1', 'title': 'Apple Movie', 'price': 0.99},
        'order': {
          'id': 'order-1',
          'txRef': 'tx-1',
          'movieId': 'movie-1',
          'paid': true,
          'active': true,
          'expired': false,
          'revoked': false,
          'currentTime': 0,
          'startWatch': false,
        },
        'payment': {
          'id': 'payment-1',
          'txRef': 'tx-1',
          'amount': 0.99,
          'currency': 'USD',
          'status': 'Completed',
          'financialStatus': 'completed',
          'provider': provider,
          'platform': platform,
          'productId': 'com.africanmovies.movie.apple_movie.rental',
          'entitlementStatus': 'active',
          'transactionId': transactionId,
          'createdAt': '2026-09-30T10:00:00.000Z',
        },
      },
    ],
    'summary': {
      'total': 1,
      'completed': 1,
      'pending': 0,
      'failed': 0,
      'refunded': 0,
      'active': 1,
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
}
