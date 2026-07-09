import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../movies/application/movie_providers.dart';
import '../../movies/domain/movie.dart';
import '../../notifications/application/notification_providers.dart';
import '../data/native_store_payment_gateway.dart';
import '../data/pending_native_purchase_store.dart';
import '../data/payment_repository.dart';
import '../data/payment_preferences_store.dart';
import '../domain/payment_gateway.dart';
import '../domain/payment_history.dart';
import '../domain/payment_confirmation.dart';
import '../domain/payment_intent.dart';
import '../domain/pending_native_purchase.dart';
import '../domain/purchase_result.dart';
import '../domain/saved_payment_method.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(apiClient: ref.watch(apiClientProvider));
});

final paymentPreferencesStoreProvider = Provider<PaymentPreferencesStore>((
  ref,
) {
  return PaymentPreferencesStore();
});

final pendingNativePurchaseStoreProvider = Provider<PendingNativePurchaseStore>(
  (ref) {
    return PendingNativePurchaseStore(
      cacheStore: ref.watch(jsonCacheStoreProvider),
    );
  },
);

final nativeStorePaymentGatewayProvider = Provider<NativeStorePaymentGateway>((
  ref,
) {
  return NativeStorePaymentGateway();
});

final purchaseControllerProvider =
    AsyncNotifierProvider<PurchaseController, PurchaseResult?>(
      PurchaseController.new,
    );

final savedPaymentMethodControllerProvider =
    AsyncNotifierProvider<SavedPaymentMethodController, SavedPaymentMethod?>(
      SavedPaymentMethodController.new,
    );

final saveCardPromptPreferenceControllerProvider =
    AsyncNotifierProvider<SaveCardPromptPreferenceController, bool>(
      SaveCardPromptPreferenceController.new,
    );

final paymentHistoryProvider = FutureProvider<PaymentHistoryResponse>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchPaymentHistory();
});

class SaveCardPromptPreferenceController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final isHidden = await ref
        .watch(paymentPreferencesStoreProvider)
        .isSaveCardPromptHidden();

    return !isHidden;
  }

  Future<void> setShouldAskAfterCheckout(bool shouldAsk) async {
    final previousValue = state.asData?.value ?? true;
    state = AsyncData(shouldAsk);

    try {
      final store = ref.read(paymentPreferencesStoreProvider);
      if (shouldAsk) {
        await store.showSaveCardPrompt();
      } else {
        await store.hideSaveCardPrompt();
      }
    } catch (error, stackTrace) {
      state = AsyncData(previousValue);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class SavedPaymentMethodController extends AsyncNotifier<SavedPaymentMethod?> {
  @override
  Future<SavedPaymentMethod?> build() {
    return ref.watch(paymentRepositoryProvider).fetchSavedPaymentMethod();
  }

  Future<SavedPaymentMethod> saveFromTransaction(String transactionId) async {
    final previousPaymentMethod = state.asData?.value;
    state = const AsyncLoading();

    try {
      final paymentMethod = await ref
          .read(paymentRepositoryProvider)
          .savePaymentMethod(transactionId: transactionId, isNewCard: true);
      state = AsyncData(paymentMethod);

      return paymentMethod;
    } catch (error, stackTrace) {
      state = AsyncData(previousPaymentMethod);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> removeSavedPaymentMethod() async {
    final previousPaymentMethod = state.asData?.value;
    state = const AsyncLoading();

    try {
      await ref.read(paymentRepositoryProvider).removeSavedPaymentMethod();
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncData(previousPaymentMethod);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class PurchaseController extends AsyncNotifier<PurchaseResult?> {
  bool _isPurchaseInProgress = false;

  bool get isPurchaseInProgress => _isPurchaseInProgress;

  @override
  Future<PurchaseResult?> build() async {
    return null;
  }

  Future<PurchaseResult> purchaseMovie({
    required BuildContext context,
    required Movie movie,
  }) async {
    if (_isPurchaseInProgress) {
      return PurchaseResult.failed('Payment is already in progress.');
    }

    _isPurchaseInProgress = true;
    state = const AsyncLoading();

    try {
      if (movie.price <= 0) {
        final result = PurchaseResult.failed(
          'This movie is free. Playback will open from Watch Now.',
        );
        state = AsyncData(result);
        return result;
      }

      final intent = await ref
          .read(paymentRepositoryProvider)
          .initializeMoviePurchase(movie.id);

      if (intent.isAlreadyPurchased) {
        final result = PurchaseResult.alreadyPurchased();
        await _refreshHomeData();
        state = AsyncData(result);
        return result;
      }

      if (!_isNativePaymentMethod(intent.method)) {
        final result = PurchaseResult.failed(
          'Mobile purchases must use Apple or Google Play billing.',
        );
        state = AsyncData(result);
        return result;
      }

      final pendingAttempt = await _savePendingNativeAttempt(
        movie: movie,
        intent: intent,
      );

      if (intent.awaitingStoreConfirmation && pendingAttempt != null) {
        return _recoverExistingNativeAttempt(
          movie: movie,
          attempt: pendingAttempt,
        );
      }

      if (!context.mounted) {
        await _closeNativePurchaseAttempt(
          intent: intent,
          providerStatus: 'cancelled',
        );
        final result = PurchaseResult.cancelled();
        state = AsyncData(result);
        return result;
      }

      final gatewayResult = await _chargeGateway(
        context: context,
        intent: intent,
      );

      if (gatewayResult.status == GatewayPaymentStatus.cancelled) {
        await _closeNativePurchaseAttempt(
          intent: intent,
          providerStatus: 'cancelled',
        );
        final result = PurchaseResult.cancelled();
        state = AsyncData(result);
        return result;
      }

      if (gatewayResult.isPending) {
        return _handlePendingNativePurchase(
          intent: intent,
          attempt: pendingAttempt,
          verificationData: gatewayResult.nativeVerificationData,
        );
      }

      if (!gatewayResult.isCompleted) {
        await _closeNativePurchaseAttempt(
          intent: intent,
          providerStatus: 'failed',
        );
        final result = PurchaseResult.failed(
          gatewayResult.message ?? 'Payment could not be completed.',
        );
        state = AsyncData(result);
        return result;
      }

      final transactionId = gatewayResult.transactionId;
      if (transactionId == null || transactionId.isEmpty) {
        final result = PurchaseResult.failed(
          'Payment verification details were missing. Please try again.',
        );
        state = AsyncData(result);
        return result;
      }

      return _confirmNativePurchase(
        movie: movie,
        intent: intent,
        gatewayResult: gatewayResult,
      );
    } catch (error) {
      final result = PurchaseResult.failed(_messageFor(error));
      state = AsyncData(result);
      return result;
    } finally {
      _isPurchaseInProgress = false;
    }
  }

  Future<GatewayPaymentResult> _chargeGateway({
    required BuildContext context,
    required PaymentIntent intent,
  }) {
    return switch (intent.method) {
      PaymentMethod.flutterwave => Future.value(
        GatewayPaymentResult(
          status: GatewayPaymentStatus.failed,
          txRef: intent.txRef,
          message: 'Mobile purchases require native store billing.',
        ),
      ),
      PaymentMethod.storeKit =>
        ref
            .read(nativeStorePaymentGatewayProvider)
            .charge(context: context, intent: intent),
      PaymentMethod.googlePlay =>
        ref
            .read(nativeStorePaymentGatewayProvider)
            .charge(context: context, intent: intent),
      PaymentMethod.none => Future.value(
        GatewayPaymentResult(
          status: GatewayPaymentStatus.failed,
          txRef: intent.txRef,
          message: 'Payment method unavailable.',
        ),
      ),
    };
  }

  bool _isNativePaymentMethod(PaymentMethod method) {
    return method == PaymentMethod.storeKit ||
        method == PaymentMethod.googlePlay;
  }

  Future<PendingNativePurchase?> _savePendingNativeAttempt({
    required Movie movie,
    required PaymentIntent intent,
  }) async {
    if (!_isNativePaymentMethod(intent.method)) return null;

    final productId = intent.storeProductId?.trim() ?? '';
    final session = await ref.read(authControllerProvider.future);
    if (session == null || productId.isEmpty || intent.txRef.isEmpty) {
      return null;
    }

    final attempt = PendingNativePurchase(
      userId: session.user.id,
      txRef: intent.txRef,
      movieId: movie.id,
      productId: productId,
      platform: intent.method == PaymentMethod.googlePlay ? 'android' : 'ios',
      createdAt: DateTime.now(),
    );
    await ref.read(pendingNativePurchaseStoreProvider).upsert(attempt);
    return attempt;
  }

  Future<PurchaseResult> _recoverExistingNativeAttempt({
    required Movie movie,
    required PendingNativePurchase attempt,
  }) async {
    late final PaymentConfirmation confirmation;
    try {
      confirmation = await ref
          .read(paymentRepositoryProvider)
          .recoverNativePurchase(attempt: attempt);
    } catch (_) {
      final result = PurchaseResult.pending(txRef: attempt.txRef);
      state = AsyncData(result);
      return result;
    }

    if (confirmation.isSuccessful) {
      await _removePendingNativeAttempt(attempt);
      await _refreshAfterPurchase(movie);
      final result = PurchaseResult.success(
        txRef: confirmation.txRef ?? attempt.txRef,
        transactionId: confirmation.transactionId ?? attempt.txRef,
        paymentType: confirmation.paymentType,
      );
      state = AsyncData(result);
      return result;
    }

    if (confirmation.isPending) {
      final result = PurchaseResult.pending(txRef: attempt.txRef);
      state = AsyncData(result);
      return result;
    }

    await _removePendingNativeAttempt(attempt);
    final result = PurchaseResult.failed(
      'The pending payment was not completed. Please try again.',
    );
    state = AsyncData(result);
    return result;
  }

  Future<PurchaseResult> _handlePendingNativePurchase({
    required PaymentIntent intent,
    required PendingNativePurchase? attempt,
    required NativePurchaseVerificationData? verificationData,
  }) async {
    if (attempt != null &&
        verificationData != null &&
        verificationData.serverVerificationData.isNotEmpty) {
      PaymentConfirmation? confirmation;
      try {
        confirmation = await ref
            .read(paymentRepositoryProvider)
            .recoverNativePurchase(
              attempt: attempt,
              verificationData: verificationData,
            );
      } catch (_) {}

      if (confirmation?.isSuccessful == true) {
        try {
          await ref
              .read(nativeStorePaymentGatewayProvider)
              .completePurchase(verificationData.completionKey);
        } catch (_) {
          // The backend has already consumed or acknowledged the purchase.
        }
        await _removePendingNativeAttempt(attempt);
        await _refreshHomeData();
        final result = PurchaseResult.success(
          txRef: confirmation!.txRef ?? intent.txRef,
          transactionId:
              confirmation.transactionId ?? verificationData.completionKey,
          paymentType: confirmation.paymentType,
        );
        state = AsyncData(result);
        return result;
      }

      if (confirmation != null && !confirmation.isPending) {
        await _removePendingNativeAttempt(attempt);
        final result = PurchaseResult.failed(
          'Payment was not completed. Please try again.',
        );
        state = AsyncData(result);
        return result;
      }
    }

    final result = PurchaseResult.pending(txRef: intent.txRef);
    state = AsyncData(result);
    return result;
  }

  Future<void> _removePendingNativeAttempt(PendingNativePurchase attempt) {
    return ref
        .read(pendingNativePurchaseStoreProvider)
        .remove(userId: attempt.userId, txRef: attempt.txRef);
  }

  Future<void> _removePendingNativeAttemptForIntent(
    PaymentIntent intent,
  ) async {
    if (!_isNativePaymentMethod(intent.method)) return;

    final userId = intent.storeAccountId?.trim();
    if (userId == null || userId.isEmpty) return;

    await ref
        .read(pendingNativePurchaseStoreProvider)
        .remove(userId: userId, txRef: intent.txRef);
  }

  Future<void> _closeNativePurchaseAttempt({
    required PaymentIntent intent,
    required String providerStatus,
  }) async {
    if (!_isNativePaymentMethod(intent.method)) return;

    try {
      await ref
          .read(paymentRepositoryProvider)
          .closeNativePurchaseAttempt(
            txRef: intent.txRef,
            providerStatus: providerStatus,
          );
    } catch (_) {
      // Cleanup is best-effort and must not replace the store result shown.
    } finally {
      await _removePendingNativeAttemptForIntent(intent);
    }
  }

  Future<void> _refreshAfterPurchase(Movie movie) async {
    await ref
        .read(notificationsControllerProvider.notifier)
        .addPurchaseSuccess(movie);
    await _refreshHomeData();
  }

  Future<PurchaseResult> _confirmNativePurchase({
    required Movie movie,
    required PaymentIntent intent,
    required GatewayPaymentResult gatewayResult,
  }) async {
    final verificationData = gatewayResult.nativeVerificationData;
    if (verificationData == null) {
      final result = PurchaseResult.failed(
        'Store verification details were missing. Please try again.',
      );
      state = AsyncData(result);
      return result;
    }

    final confirmation = await ref
        .read(paymentRepositoryProvider)
        .verifyNativePurchase(
          movieId: movie.id,
          intent: intent,
          verificationData: verificationData,
        );

    if (confirmation.isPending) {
      final result = PurchaseResult.pending(txRef: intent.txRef);
      state = AsyncData(result);
      return result;
    }

    if (!confirmation.isSuccessful) {
      final result = PurchaseResult.failed(
        'Payment could not be verified. Please try again.',
      );
      state = AsyncData(result);
      return result;
    }

    try {
      await ref
          .read(nativeStorePaymentGatewayProvider)
          .completePurchase(verificationData.completionKey);
    } catch (_) {
      // Access is already granted by the backend. StoreKit will redeliver the
      // transaction later if completion fails, so do not show a false failure.
    }

    await _removePendingNativeAttemptForIntent(intent);
    await _refreshAfterPurchase(movie);

    final result = PurchaseResult.success(
      txRef: gatewayResult.txRef,
      transactionId:
          gatewayResult.transactionId ?? verificationData.completionKey,
      paymentType: confirmation.paymentType,
    );
    state = AsyncData(result);
    return result;
  }

  Future<void> _refreshHomeData() async {
    ref.invalidate(homeDataProvider);
    await ref.read(homeDataProvider.future);
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }
}
