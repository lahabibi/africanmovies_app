import 'dart:async';

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
import '../domain/payment_gateway.dart';
import '../domain/payment_history.dart';
import '../domain/payment_confirmation.dart';
import '../domain/payment_intent.dart';
import '../domain/pending_native_purchase.dart';
import '../domain/purchase_result.dart';

const bool _paymentDiagnosticsEnabled = bool.fromEnvironment(
  'AM_PAYMENT_DIAGNOSTICS',
  defaultValue: false,
);

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(apiClient: ref.watch(apiClientProvider));
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

final paymentHistoryProvider = FutureProvider<PaymentHistoryResponse>((ref) {
  return ref.watch(paymentRepositoryProvider).fetchPaymentHistory();
});

class PurchaseController extends AsyncNotifier<PurchaseResult?> {
  static const _nativeVerificationTimeout = Duration(seconds: 25);

  bool _isPurchaseInProgress = false;
  final Set<String> _completedNativePurchaseKeys = {};
  PurchaseResult? _lastCompletedNativePurchase;

  bool get isPurchaseInProgress => _isPurchaseInProgress;

  @override
  Future<PurchaseResult?> build() async {
    return null;
  }

  Future<PurchaseResult> purchaseMovie({
    required BuildContext context,
    required Movie movie,
  }) async {
    _paymentLog(
      'purchaseMovie started movieId=${_tail(movie.id)} '
      'price=${movie.price}',
    );
    if (_isPurchaseInProgress) {
      _paymentLog('purchaseMovie rejected: another purchase is in progress');
      return PurchaseResult.failed('Payment is already in progress.');
    }

    _isPurchaseInProgress = true;
    state = const AsyncLoading();
    PaymentIntent? activeIntent;

    try {
      if (movie.price <= 0) {
        _paymentLog('purchaseMovie rejected: movie is free');
        final result = PurchaseResult.failed(
          'This movie is free. Playback will open from Watch Now.',
        );
        state = AsyncData(result);
        return result;
      }

      final intent = await ref
          .read(paymentRepositoryProvider)
          .initializeMoviePurchase(movie.id);
      activeIntent = intent;
      _paymentLog(
        'initialize result method=${intent.method.name} '
        'status=${intent.status.name} productId=${intent.storeProductId} '
        'txRef=${_tail(intent.txRef)} reused=${intent.reused} '
        'awaiting=${intent.awaitingStoreConfirmation}',
      );

      if (intent.isAlreadyPurchased) {
        _paymentLog('purchaseMovie already purchased');
        final result = PurchaseResult.alreadyPurchased();
        await _refreshHomeData();
        state = AsyncData(result);
        return result;
      }

      if (!_isNativePaymentMethod(intent.method)) {
        _paymentLog(
          'purchaseMovie rejected: non-native method ${intent.method.name}',
        );
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
      _paymentLog(
        'pending native attempt saved=${pendingAttempt != null} '
        'txRef=${_tail(pendingAttempt?.txRef)}',
      );

      if (intent.awaitingStoreConfirmation && pendingAttempt != null) {
        _paymentLog('recovering existing native attempt');
        return _recoverExistingNativeAttempt(
          movie: movie,
          attempt: pendingAttempt,
        );
      }

      if (!context.mounted) {
        _paymentLog('purchaseMovie cancelled: context unmounted');
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
      _paymentLog(
        'gateway result status=${gatewayResult.status.name} '
        'txRef=${_tail(gatewayResult.txRef)} '
        'transactionId=${_tail(gatewayResult.transactionId)} '
        'message=${gatewayResult.message}',
      );
      final recoveredResult = _completedNativePurchaseResultFor(
        txRef: intent.txRef,
        transactionId: gatewayResult.transactionId,
        verificationData: gatewayResult.nativeVerificationData,
      );
      if (recoveredResult != null) {
        _paymentLog(
          'gateway result ignored; native purchase already recovered',
        );
        state = AsyncData(recoveredResult);
        return recoveredResult;
      }

      if (gatewayResult.status == GatewayPaymentStatus.cancelled) {
        _paymentLog('gateway cancelled by user/store');
        await _closeNativePurchaseAttempt(
          intent: intent,
          providerStatus: 'cancelled',
        );
        final result = PurchaseResult.cancelled();
        state = AsyncData(result);
        return result;
      }

      if (gatewayResult.isPending) {
        _paymentLog('gateway returned pending');
        return _handlePendingNativePurchase(
          intent: intent,
          attempt: pendingAttempt,
          verificationData: gatewayResult.nativeVerificationData,
        );
      }

      if (!gatewayResult.isCompleted) {
        _paymentLog('gateway failed; closing native attempt');
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
        _paymentLog('gateway completed without transaction id');
        final result = PurchaseResult.failed(
          'Payment verification details were missing. Please try again.',
        );
        state = AsyncData(result);
        return result;
      }

      return _confirmNativePurchase(
        movie: movie,
        intent: intent,
        attempt: pendingAttempt,
        gatewayResult: gatewayResult,
      );
    } catch (error) {
      _paymentLog('purchaseMovie error ${error.runtimeType}: $error');
      final recoveredResult = _completedNativePurchaseResultFor(
        txRef: activeIntent?.txRef,
      );
      if (recoveredResult != null) {
        _paymentLog(
          'purchase error ignored; native purchase already recovered',
        );
        state = AsyncData(recoveredResult);
        return recoveredResult;
      }
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

  void completeRecoveredNativePurchase({
    String? txRef,
    String? transactionId,
    String? paymentType,
  }) {
    final result = _nativeRecoverySuccessResult(
      txRef: txRef,
      transactionId: transactionId,
      paymentType: paymentType,
    );
    _rememberCompletedNativePurchase(
      txRef: result.txRef,
      transactionId: result.transactionId,
      paymentType: result.paymentType,
    );
    _isPurchaseInProgress = false;
    state = AsyncData(result);
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
    final verificationData = attempt.verificationData;
    if (attempt.platform == 'ios' && verificationData == null) {
      final result = PurchaseResult.pending(txRef: attempt.txRef);
      state = AsyncData(result);
      return result;
    }

    late final PaymentConfirmation confirmation;
    try {
      confirmation = await ref
          .read(paymentRepositoryProvider)
          .recoverNativePurchase(
            attempt: attempt,
            verificationData: verificationData,
          );
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
    final recoveredResult = _completedNativePurchaseResultFor(
      txRef: intent.txRef,
      transactionId: verificationData?.purchaseId,
      verificationData: verificationData,
    );
    if (recoveredResult != null) {
      state = AsyncData(recoveredResult);
      return recoveredResult;
    }

    if (attempt != null &&
        verificationData != null &&
        verificationData.serverVerificationData.isNotEmpty) {
      await _persistPendingNativeVerificationData(
        attempt: attempt,
        verificationData: verificationData,
      );

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
      _paymentLog(
        'closing native attempt txRef=${_tail(intent.txRef)} '
        'status=$providerStatus',
      );
      await ref
          .read(paymentRepositoryProvider)
          .closeNativePurchaseAttempt(
            txRef: intent.txRef,
            providerStatus: providerStatus,
          );
    } catch (_) {
      _paymentLog('close native attempt failed');
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
    required PendingNativePurchase? attempt,
    required GatewayPaymentResult gatewayResult,
  }) async {
    final verificationData = gatewayResult.nativeVerificationData;
    if (verificationData == null) {
      _paymentLog('confirmNativePurchase failed: missing verification data');
      final result = PurchaseResult.failed(
        'Store verification details were missing. Please try again.',
      );
      state = AsyncData(result);
      return result;
    }

    final recoveredBeforeVerification = _completedNativePurchaseResultFor(
      txRef: intent.txRef,
      transactionId: gatewayResult.transactionId,
      verificationData: verificationData,
    );
    if (recoveredBeforeVerification != null) {
      state = AsyncData(recoveredBeforeVerification);
      return recoveredBeforeVerification;
    }

    _paymentLog(
      'verifying native purchase productId=${verificationData.productId} '
      'purchaseId=${_tail(verificationData.purchaseId)} '
      'completionKey=${_tail(verificationData.completionKey)} '
      'source=${verificationData.source} '
      'serverDataLength=${verificationData.serverVerificationData.length}',
    );
    final PaymentConfirmation confirmation;
    try {
      confirmation = await ref
          .read(paymentRepositoryProvider)
          .verifyNativePurchase(
            movieId: movie.id,
            intent: intent,
            verificationData: verificationData,
          )
          .timeout(_nativeVerificationTimeout);
    } on TimeoutException {
      _paymentLog(
        'verifyNativePurchase timed out after '
        '${_nativeVerificationTimeout.inSeconds}s',
      );
      await _persistPendingNativeVerificationData(
        attempt: attempt,
        verificationData: verificationData,
      );
      final recoveredResult = _completedNativePurchaseResultFor(
        txRef: intent.txRef,
        transactionId: gatewayResult.transactionId,
        verificationData: verificationData,
      );
      if (recoveredResult != null) {
        state = AsyncData(recoveredResult);
        return recoveredResult;
      }
      final result = PurchaseResult.pending(txRef: intent.txRef);
      state = AsyncData(result);
      return result;
    } on ApiException catch (error) {
      _paymentLog(
        'verifyNativePurchase api error status=${error.statusCode} '
        'message=${error.message}',
      );
      if (_isTemporaryNativeVerificationFailure(error)) {
        await _persistPendingNativeVerificationData(
          attempt: attempt,
          verificationData: verificationData,
        );
        final recoveredResult = _completedNativePurchaseResultFor(
          txRef: intent.txRef,
          transactionId: gatewayResult.transactionId,
          verificationData: verificationData,
        );
        if (recoveredResult != null) {
          state = AsyncData(recoveredResult);
          return recoveredResult;
        }
        final result = PurchaseResult.pending(txRef: intent.txRef);
        state = AsyncData(result);
        return result;
      }

      rethrow;
    }
    _paymentLog(
      'verifyNativePurchase result success=${confirmation.isSuccessful} '
      'pending=${confirmation.isPending} '
      'transactionId=${_tail(confirmation.transactionId)}',
    );

    if (confirmation.isPending) {
      await _persistPendingNativeVerificationData(
        attempt: attempt,
        verificationData: verificationData,
      );
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
      _paymentLog('completePurchase failed after backend success');
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
    _rememberCompletedNativePurchase(
      txRef: result.txRef,
      transactionId: result.transactionId,
      completionKey: verificationData.completionKey,
      purchaseId: verificationData.purchaseId,
      paymentType: result.paymentType,
    );
    state = AsyncData(result);
    return result;
  }

  Future<void> _refreshHomeData() async {
    ref.invalidate(homeDataProvider);
    await ref.read(homeDataProvider.future);
  }

  Future<void> _persistPendingNativeVerificationData({
    required PendingNativePurchase? attempt,
    required NativePurchaseVerificationData verificationData,
  }) async {
    if (attempt == null || verificationData.serverVerificationData.isEmpty) {
      return;
    }

    _paymentLog(
      'persisting native verification data txRef=${_tail(attempt.txRef)} '
      'purchaseId=${_tail(verificationData.purchaseId)}',
    );
    await ref
        .read(pendingNativePurchaseStoreProvider)
        .upsert(attempt.copyWith(verificationData: verificationData));
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;

    return error.toString();
  }

  bool _isTemporaryNativeVerificationFailure(ApiException error) {
    final message = error.message.toLowerCase();
    return error.statusCode == null ||
        (error.statusCode != null && error.statusCode! >= 500) ||
        message.contains('timed out') ||
        message.contains('timeout') ||
        message.contains('temporarily') ||
        message.contains('connection');
  }

  void _rememberCompletedNativePurchase({
    String? txRef,
    String? transactionId,
    String? completionKey,
    String? purchaseId,
    String? paymentType,
  }) {
    for (final key in [txRef, transactionId, completionKey, purchaseId]) {
      final normalized = key?.trim();
      if (normalized != null && normalized.isNotEmpty) {
        _completedNativePurchaseKeys.add(normalized);
      }
    }

    _lastCompletedNativePurchase = _nativeRecoverySuccessResult(
      txRef: txRef,
      transactionId: transactionId ?? purchaseId ?? completionKey,
      paymentType: paymentType,
    );
  }

  PurchaseResult? _completedNativePurchaseResultFor({
    String? txRef,
    String? transactionId,
    NativePurchaseVerificationData? verificationData,
  }) {
    for (final key in [
      txRef,
      transactionId,
      verificationData?.completionKey,
      verificationData?.purchaseId,
    ]) {
      final normalized = key?.trim();
      if (normalized != null &&
          normalized.isNotEmpty &&
          _completedNativePurchaseKeys.contains(normalized)) {
        return _lastCompletedNativePurchase ??
            _nativeRecoverySuccessResult(
              txRef: txRef,
              transactionId: transactionId,
            );
      }
    }

    return null;
  }

  PurchaseResult _nativeRecoverySuccessResult({
    String? txRef,
    String? transactionId,
    String? paymentType,
  }) {
    final resolvedTxRef =
        _firstNonEmpty([txRef, transactionId]) ??
        'native-${DateTime.now().microsecondsSinceEpoch}';
    final resolvedTransactionId =
        _firstNonEmpty([transactionId, txRef]) ?? resolvedTxRef;

    return PurchaseResult.success(
      txRef: resolvedTxRef,
      transactionId: resolvedTransactionId,
      paymentType: paymentType,
    );
  }
}

void _paymentLog(String message) {
  if (!_paymentDiagnosticsEnabled) return;
  debugPrint('[PaymentFlow] $message');
}

String _tail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'empty';
  if (text.length <= 8) return text;
  return '...${text.substring(text.length - 8)}';
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) return text;
  }

  return null;
}
