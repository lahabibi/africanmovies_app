import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../auth/application/auth_controller.dart';
import '../../movies/application/movie_providers.dart';
import '../domain/payment_confirmation.dart';
import '../domain/payment_gateway.dart';
import '../domain/pending_native_purchase.dart';
import 'payment_providers.dart';

final nativePurchaseRecoveryControllerProvider =
    AsyncNotifierProvider<
      NativePurchaseRecoveryController,
      NativePurchaseRecoveryNotice?
    >(NativePurchaseRecoveryController.new);

class NativePurchaseRecoveryNotice {
  final String message;
  final String transactionKey;

  const NativePurchaseRecoveryNotice({
    required this.message,
    required this.transactionKey,
  });
}

class NativePurchaseRecoveryController
    extends AsyncNotifier<NativePurchaseRecoveryNotice?> {
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  String? _userId;
  final Set<String> _processingTokens = {};
  final Set<String> _notifiedTransactions = {};

  @override
  Future<NativePurchaseRecoveryNotice?> build() async {
    await _subscription?.cancel();
    _subscription = null;

    final session = await ref.watch(authControllerProvider.future);
    _userId = session?.user.id;
    if (_userId == null || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(purchases)),
      onError: (Object error) {
        debugPrint('[NativeRecovery] purchase stream error=$error');
      },
    );
    ref.onDispose(() => unawaited(_subscription?.cancel()));

    unawaited(Future<void>.delayed(Duration.zero, recoverOutstandingPurchases));
    return null;
  }

  Future<void> recoverOutstandingPurchases() async {
    final userId = _userId;
    if (userId == null || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final store = ref.read(pendingNativePurchaseStoreProvider);
    final attempts = await store.readAll(userId);
    for (final attempt in attempts) {
      try {
        final result = await ref
            .read(paymentRepositoryProvider)
            .recoverNativePurchase(attempt: attempt);
        await _handleRecoveryResult(
          result: result,
          attempt: attempt,
          purchase: null,
        );
      } catch (error) {
        debugPrint(
          '[NativeRecovery] txRef=${attempt.txRef} awaiting store data: $error',
        );
      }
    }

    try {
      await InAppPurchase.instance.restorePurchases(
        applicationUserName: userId,
      );
    } catch (error) {
      debugPrint('[NativeRecovery] restorePurchases failed: $error');
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    final userId = _userId;
    if (userId == null) return;

    for (final purchase in purchases) {
      final token = purchase.verificationData.serverVerificationData.trim();
      if (purchase.productID.isEmpty || token.isEmpty) continue;
      if (!_processingTokens.add(token)) continue;

      try {
        final attempts = await ref
            .read(pendingNativePurchaseStoreProvider)
            .readAll(userId);
        final attempt = attempts
            .where((item) => item.productId == purchase.productID)
            .firstOrNull;
        final result = await ref
            .read(paymentRepositoryProvider)
            .recoverNativePurchase(
              attempt: attempt,
              verificationData: _verificationDataFor(purchase),
            );
        await _handleRecoveryResult(
          result: result,
          attempt: attempt,
          purchase: purchase,
        );
      } catch (error) {
        debugPrint(
          '[NativeRecovery] productId=${purchase.productID} recovery failed: $error',
        );
      } finally {
        _processingTokens.remove(token);
      }
    }
  }

  Future<void> _handleRecoveryResult({
    required PaymentConfirmation result,
    required PendingNativePurchase? attempt,
    required PurchaseDetails? purchase,
  }) async {
    final userId = _userId;
    if (userId == null) return;

    final store = ref.read(pendingNativePurchaseStoreProvider);

    if (result.isPending) {
      if (attempt == null &&
          result.txRef?.isNotEmpty == true &&
          result.movieId?.isNotEmpty == true &&
          purchase != null) {
        await store.upsert(
          PendingNativePurchase(
            userId: userId,
            txRef: result.txRef!,
            movieId: result.movieId!,
            productId: purchase.productID,
            platform: 'android',
            createdAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    final txRef = result.txRef ?? attempt?.txRef;
    if (txRef != null && txRef.isNotEmpty) {
      await store.remove(userId: userId, txRef: txRef);
    }

    if (!result.isSuccessful) {
      final transactionKey = txRef ?? purchase?.purchaseID ?? '';
      final checkoutIsActive = ref
          .read(purchaseControllerProvider.notifier)
          .isPurchaseInProgress;
      if (transactionKey.isNotEmpty &&
          !checkoutIsActive &&
          _notifiedTransactions.add(transactionKey)) {
        state = AsyncData(
          NativePurchaseRecoveryNotice(
            message:
                'Your pending payment was not completed. You have not been charged.',
            transactionKey: transactionKey,
          ),
        );
      }
      return;
    }

    if (purchase?.pendingCompletePurchase == true) {
      try {
        await InAppPurchase.instance.completePurchase(purchase!);
      } catch (error) {
        debugPrint('[NativeRecovery] completePurchase failed: $error');
      }
    }

    ref.invalidate(homeDataProvider);
    try {
      await ref.read(homeDataProvider.future);
    } catch (error) {
      debugPrint('[NativeRecovery] home refresh failed: $error');
    }

    final transactionKey =
        result.transactionId ?? txRef ?? purchase?.purchaseID ?? '';
    final checkoutIsActive = ref
        .read(purchaseControllerProvider.notifier)
        .isPurchaseInProgress;
    if (transactionKey.isNotEmpty &&
        !checkoutIsActive &&
        _notifiedTransactions.add(transactionKey)) {
      state = AsyncData(
        NativePurchaseRecoveryNotice(
          message: 'Purchase confirmed. The movie is now in your library.',
          transactionKey: transactionKey,
        ),
      );
    }
  }

  NativePurchaseVerificationData _verificationDataFor(
    PurchaseDetails purchase,
  ) {
    final completionKey = purchase.purchaseID?.trim().isNotEmpty == true
        ? purchase.purchaseID!
        : [
            purchase.productID,
            purchase.transactionDate,
            purchase.verificationData.source,
            purchase.verificationData.serverVerificationData.hashCode,
          ].join(':');

    return NativePurchaseVerificationData(
      completionKey: completionKey,
      productId: purchase.productID,
      purchaseId: purchase.purchaseID,
      transactionDate: purchase.transactionDate,
      source: purchase.verificationData.source,
      localVerificationData: purchase.verificationData.localVerificationData,
      serverVerificationData: purchase.verificationData.serverVerificationData,
    );
  }

  void clearNotice() {
    state = const AsyncData(null);
  }
}
