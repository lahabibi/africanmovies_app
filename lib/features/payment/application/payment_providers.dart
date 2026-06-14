import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../movies/application/movie_providers.dart';
import '../../movies/domain/movie.dart';
import '../../notifications/application/notification_providers.dart';
import '../data/flutterwave_payment_gateway.dart';
import '../data/native_store_payment_gateway.dart';
import '../data/payment_repository.dart';
import '../data/payment_preferences_store.dart';
import '../domain/payment_gateway.dart';
import '../domain/payment_history.dart';
import '../domain/payment_intent.dart';
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

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return FlutterwavePaymentGateway();
});

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
  @override
  Future<PurchaseResult?> build() async {
    return null;
  }

  Future<PurchaseResult> purchaseMovie({
    required BuildContext context,
    required Movie movie,
  }) async {
    if (state.isLoading) {
      return PurchaseResult.failed('Payment is already in progress.');
    }

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

      if (!context.mounted) {
        final result = PurchaseResult.cancelled();
        state = AsyncData(result);
        return result;
      }

      final gatewayResult = await _chargeGateway(
        context: context,
        intent: intent,
      );

      if (gatewayResult.status == GatewayPaymentStatus.cancelled) {
        final result = PurchaseResult.cancelled();
        state = AsyncData(result);
        return result;
      }

      if (!gatewayResult.isCompleted) {
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

      if (_isNativePaymentMethod(intent.method)) {
        return _confirmNativePurchase(
          movie: movie,
          intent: intent,
          gatewayResult: gatewayResult,
        );
      }

      final confirmation = await ref
          .read(paymentRepositoryProvider)
          .confirmFlutterwavePayment(
            txRef: gatewayResult.txRef,
            transactionId: transactionId,
          );

      if (!confirmation.isSuccessful) {
        final result = PurchaseResult.failed(
          'Payment could not be verified. Please try again.',
        );
        state = AsyncData(result);
        return result;
      }

      await _refreshAfterPurchase(movie);

      final result = PurchaseResult.success(
        txRef: gatewayResult.txRef,
        transactionId: transactionId,
        paymentType: confirmation.paymentType,
      );
      state = AsyncData(result);
      return result;
    } catch (error) {
      final result = PurchaseResult.failed(_messageFor(error));
      state = AsyncData(result);
      return result;
    }
  }

  Future<PurchaseResult> purchaseMovieWithSavedCard({
    required BuildContext context,
    required Movie movie,
  }) async {
    if (state.isLoading) {
      return PurchaseResult.failed('Payment is already in progress.');
    }

    state = const AsyncLoading();

    try {
      if (movie.price <= 0) {
        final result = PurchaseResult.failed(
          'This movie is free. Playback will open from Watch Now.',
        );
        state = AsyncData(result);
        return result;
      }

      final savedPaymentMethod = await ref.read(
        savedPaymentMethodControllerProvider.future,
      );

      if (savedPaymentMethod == null || savedPaymentMethod.isEmpty) {
        final result = PurchaseResult.failed(
          'No saved payment method found. Please use another card.',
        );
        state = AsyncData(result);
        return result;
      }

      if (savedPaymentMethod.needsRefresh) {
        final result = PurchaseResult.failed(
          'Your saved card needs to be refreshed. Please use another card.',
        );
        state = AsyncData(result);
        return result;
      }

      final chargeResult = await ref
          .read(paymentRepositoryProvider)
          .chargeSavedCard(movie.id);

      if (chargeResult.isAlreadyPurchased) {
        final result = PurchaseResult.alreadyPurchased();
        await _refreshHomeData();
        state = AsyncData(result);
        return result;
      }

      if (chargeResult.isSuccessful) {
        return _confirmSavedCardCharge(
          movie: movie,
          txRef: chargeResult.txRef,
          transactionId: chargeResult.transactionId,
        );
      }

      if (chargeResult.requiresAuthorization) {
        if (!context.mounted) {
          final result = PurchaseResult.cancelled();
          state = AsyncData(result);
          return result;
        }

        final gatewayResult = await ref
            .read(paymentGatewayProvider)
            .authorizeRedirect(
              context: context,
              redirectUrl: chargeResult.redirectUrl!,
              fallbackTxRef: chargeResult.txRef,
            );

        if (gatewayResult.status == GatewayPaymentStatus.cancelled) {
          final result = PurchaseResult.cancelled();
          state = AsyncData(result);
          return result;
        }

        if (!gatewayResult.isCompleted) {
          final result = PurchaseResult.failed(
            gatewayResult.message ?? 'Payment authorization was not completed.',
          );
          state = AsyncData(result);
          return result;
        }

        final transactionId =
            gatewayResult.transactionId?.trim().isNotEmpty == true
            ? gatewayResult.transactionId
            : chargeResult.transactionId;

        return _confirmSavedCardCharge(
          movie: movie,
          txRef: gatewayResult.txRef,
          transactionId: transactionId,
        );
      }

      final result = PurchaseResult.failed(
        chargeResult.message.isNotEmpty
            ? chargeResult.message
            : 'Saved card payment failed. Please use another card.',
      );
      state = AsyncData(result);
      return result;
    } catch (error) {
      final result = PurchaseResult.failed(_messageFor(error));
      state = AsyncData(result);
      return result;
    }
  }

  Future<GatewayPaymentResult> _chargeGateway({
    required BuildContext context,
    required PaymentIntent intent,
  }) {
    return switch (intent.method) {
      PaymentMethod.flutterwave =>
        ref
            .read(paymentGatewayProvider)
            .charge(context: context, intent: intent),
      PaymentMethod.storeKit =>
        ref
            .read(nativeStorePaymentGatewayProvider)
            .charge(context: context, intent: intent),
      PaymentMethod.googlePlay => Future.value(
        GatewayPaymentResult(
          status: GatewayPaymentStatus.failed,
          txRef: intent.txRef,
          message: 'Google Play Billing verification is not enabled yet.',
        ),
      ),
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

  Future<void> _refreshAfterPurchase(Movie movie) async {
    await ref
        .read(notificationsControllerProvider.notifier)
        .addPurchaseSuccess(movie);
    await _refreshHomeData();
  }

  Future<PurchaseResult> _confirmSavedCardCharge({
    required Movie movie,
    required String txRef,
    required String? transactionId,
  }) async {
    final normalizedTxRef = txRef.trim();
    final normalizedTransactionId = transactionId?.trim() ?? '';

    if (normalizedTxRef.isEmpty || normalizedTransactionId.isEmpty) {
      final result = PurchaseResult.failed(
        'Payment verification details were missing. Please use another card.',
      );
      state = AsyncData(result);
      return result;
    }

    final confirmation = await ref
        .read(paymentRepositoryProvider)
        .confirmFlutterwavePayment(
          txRef: normalizedTxRef,
          transactionId: normalizedTransactionId,
        );

    if (!confirmation.isSuccessful) {
      final result = PurchaseResult.failed(
        'Payment could not be verified. Please use another card.',
      );
      state = AsyncData(result);
      return result;
    }

    await _refreshAfterPurchase(movie);

    final result = PurchaseResult.success(
      txRef: normalizedTxRef,
      transactionId: normalizedTransactionId,
      paymentType: 'saved_card',
    );
    state = AsyncData(result);
    return result;
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
