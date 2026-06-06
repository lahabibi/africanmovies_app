import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_providers.dart';
import '../../movies/application/movie_providers.dart';
import '../../movies/domain/movie.dart';
import '../../notifications/application/notification_providers.dart';
import '../data/flutterwave_payment_gateway.dart';
import '../data/payment_repository.dart';
import '../domain/payment_gateway.dart';
import '../domain/payment_intent.dart';
import '../domain/purchase_result.dart';
import '../domain/saved_payment_method.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(apiClient: ref.watch(apiClientProvider));
});

final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return FlutterwavePaymentGateway();
});

final purchaseControllerProvider =
    AsyncNotifierProvider<PurchaseController, PurchaseResult?>(
      PurchaseController.new,
    );

final savedPaymentMethodControllerProvider =
    AsyncNotifierProvider<SavedPaymentMethodController, SavedPaymentMethod?>(
      SavedPaymentMethodController.new,
    );

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
      if (movie.isFree || movie.price <= 0) {
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

  Future<GatewayPaymentResult> _chargeGateway({
    required BuildContext context,
    required PaymentIntent intent,
  }) {
    return switch (intent.method) {
      PaymentMethod.flutterwave =>
        ref
            .read(paymentGatewayProvider)
            .charge(context: context, intent: intent),
      PaymentMethod.storeKit => Future.value(
        GatewayPaymentResult(
          status: GatewayPaymentStatus.failed,
          txRef: intent.txRef,
          message: 'Apple in-app purchase is not enabled yet.',
        ),
      ),
      PaymentMethod.googlePlay => Future.value(
        GatewayPaymentResult(
          status: GatewayPaymentStatus.failed,
          txRef: intent.txRef,
          message: 'Google Play Billing is not enabled yet.',
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

  Future<void> _refreshAfterPurchase(Movie movie) async {
    await ref
        .read(notificationsControllerProvider.notifier)
        .addPurchaseSuccess(movie);
    await _refreshHomeData();
  }

  Future<void> _refreshHomeData() async {
    await ref.read(movieRepositoryProvider).fetchHomeData(forceRefresh: true);
    ref.invalidate(homeDataProvider);
    await ref.read(homeDataProvider.future);
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }
}
