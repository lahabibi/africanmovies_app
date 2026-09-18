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

const bool _nativeRecoveryDiagnosticsEnabled = bool.fromEnvironment(
  'AM_NATIVE_RECOVERY_DIAGNOSTICS',
  defaultValue: false,
);

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
  static const _freshCheckoutNoticeGracePeriod = Duration(minutes: 2);

  static const _recoveryRetryDelays = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
    Duration(seconds: 30),
    Duration(minutes: 1),
  ];

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _recoveryRetryTimer;
  String? _userId;
  int _recoveryRetryAttempt = 0;
  bool _isRecoveryRunning = false;
  final Set<String> _processingTokens = {};
  final Set<String> _notifiedTransactions = {};
  final Set<String> _handledTransactionKeys = {};

  @override
  Future<NativePurchaseRecoveryNotice?> build() async {
    await _subscription?.cancel();
    _subscription = null;
    _cancelRecoveryRetry();

    final session = await ref.watch(authControllerProvider.future);
    _userId = session?.user.id;
    if (_userId == null || !_supportsNativeRecovery) {
      _log('build skipped user=${_tail(_userId)} platform=$_nativePlatform');
      return null;
    }

    _log('build active user=${_tail(_userId)} platform=$_nativePlatform');
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) => unawaited(_handlePurchases(purchases)),
      onError: (Object error, StackTrace stackTrace) {
        _log('purchaseStream error ${error.runtimeType}: $error');
      },
    );
    ref.onDispose(() {
      _recoveryRetryTimer?.cancel();
      unawaited(_subscription?.cancel());
    });

    unawaited(Future<void>.delayed(Duration.zero, recoverOutstandingPurchases));
    return null;
  }

  Future<void> recoverOutstandingPurchases() async {
    final userId = _userId;
    if (userId == null || !_supportsNativeRecovery || _isRecoveryRunning) {
      return;
    }

    _isRecoveryRunning = true;
    var shouldRetry = false;

    try {
      final store = ref.read(pendingNativePurchaseStoreProvider);
      final attempts = await store.readAll(userId);
      _log('recoverOutstandingPurchases attempts=${attempts.length}');
      for (final attempt in attempts) {
        if (attempt.platform == 'ios') {
          final verificationData = attempt.verificationData;
          if (verificationData == null ||
              verificationData.serverVerificationData.isEmpty) {
            shouldRetry = true;
            _log(
              'ios attempt has no saved verification data '
              'txRef=${_tail(attempt.txRef)}',
            );
            _showAwaitingConfirmationNotice(attempt);
            continue;
          }

          try {
            _log(
              'recovering ios attempt with saved verification data '
              'txRef=${_tail(attempt.txRef)} '
              'purchaseId=${_tail(verificationData.purchaseId)}',
            );
            final result = await ref
                .read(paymentRepositoryProvider)
                .recoverNativePurchase(
                  attempt: attempt,
                  verificationData: verificationData,
                );
            shouldRetry = shouldRetry || result.isPending;
            await _handleRecoveryResult(
              result: result,
              attempt: attempt,
              purchase: null,
            );
          } catch (error) {
            shouldRetry = true;
            _log(
              'ios saved verification recovery failed '
              '${error.runtimeType}: $error',
            );
            _showAwaitingConfirmationNotice(attempt);
          }
          continue;
        }

        try {
          _log('recovering android attempt txRef=${_tail(attempt.txRef)}');
          final result = await ref
              .read(paymentRepositoryProvider)
              .recoverNativePurchase(attempt: attempt);
          shouldRetry = shouldRetry || result.isPending;
          await _handleRecoveryResult(
            result: result,
            attempt: attempt,
            purchase: null,
          );
        } catch (error) {
          _log('android recovery failed ${error.runtimeType}: $error');
          shouldRetry = true;
          _showAwaitingConfirmationNotice(attempt);
        }
      }

      if (attempts.isNotEmpty &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          _log('requesting store restore/redelivery');
          await InAppPurchase.instance.restorePurchases(
            applicationUserName: userId,
          );
        } catch (error) {
          _log('store restore/redelivery failed ${error.runtimeType}: $error');
          shouldRetry = shouldRetry || attempts.isNotEmpty;
        }
      }
    } finally {
      _isRecoveryRunning = false;
      if (shouldRetry) {
        _scheduleRecoveryRetry();
      } else {
        _cancelRecoveryRetry();
      }
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    final userId = _userId;
    if (userId == null) return;

    _log('purchaseStream update count=${purchases.length}');
    for (final purchase in purchases) {
      _log('purchase update ${_purchaseSummary(purchase)}');
      final token = purchase.verificationData.serverVerificationData.trim();
      if (purchase.productID.isEmpty || token.isEmpty) continue;
      if (!_processingTokens.add(token)) continue;

      PendingNativePurchase? attempt;
      try {
        final attempts = await ref
            .read(pendingNativePurchaseStoreProvider)
            .readAll(userId);
        attempt = attempts
            .where((item) => item.productId == purchase.productID)
            .firstOrNull;

        if (purchase.status == PurchaseStatus.pending) {
          if (attempt != null) _showAwaitingConfirmationNotice(attempt);
          _scheduleRecoveryRetry();
          continue;
        }

        if (purchase.status == PurchaseStatus.canceled ||
            purchase.status == PurchaseStatus.error) {
          final failedResult = PaymentConfirmation(
            status: 'failed',
            alreadyProcessed: false,
            txRef: attempt?.txRef,
            transactionId: purchase.purchaseID,
          );
          await _handleRecoveryResult(
            result: failedResult,
            attempt: attempt,
            purchase: purchase,
          );
          continue;
        }

        final verificationData = _verificationDataFor(purchase);
        if (attempt != null) {
          await ref
              .read(pendingNativePurchaseStoreProvider)
              .upsert(attempt.copyWith(verificationData: verificationData));
        }
        final result = await ref
            .read(paymentRepositoryProvider)
            .recoverNativePurchase(
              attempt: attempt,
              verificationData: verificationData,
            );
        await _handleRecoveryResult(
          result: result,
          attempt: attempt,
          purchase: purchase,
        );
        if (result.isPending) _scheduleRecoveryRetry();
      } catch (error) {
        _log('purchase recovery failed ${error.runtimeType}: $error');
        if (attempt != null) _showAwaitingConfirmationNotice(attempt);
        _scheduleRecoveryRetry();
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

    if (_isHandledTransaction(
      txRef: result.txRef ?? attempt?.txRef,
      transactionId: result.transactionId ?? purchase?.purchaseID,
    )) {
      final txRef = result.txRef ?? attempt?.txRef;
      if (txRef != null && txRef.isNotEmpty) {
        await store.remove(userId: userId, txRef: txRef);
      }
      return;
    }

    if (result.isPending) {
      if (attempt != null && purchase != null) {
        await store.upsert(
          attempt.copyWith(verificationData: _verificationDataFor(purchase)),
        );
      } else if (attempt == null &&
          result.txRef?.isNotEmpty == true &&
          result.movieId?.isNotEmpty == true &&
          purchase != null) {
        await store.upsert(
          PendingNativePurchase(
            userId: userId,
            txRef: result.txRef!,
            movieId: result.movieId!,
            productId: purchase.productID,
            platform: _nativePlatform ?? 'android',
            createdAt: DateTime.now(),
          ),
        );
      }
      return;
    }

    final txRef = result.txRef ?? attempt?.txRef;
    if (txRef != null && txRef.isNotEmpty) {
      await store.remove(userId: userId, txRef: txRef);
      final remainingAttempts = await store.readAll(userId);
      if (remainingAttempts.isEmpty) _cancelRecoveryRetry();
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
      } catch (_) {}
    }

    ref.invalidate(homeDataProvider);
    try {
      await ref.read(homeDataProvider.future);
    } catch (_) {}

    final transactionKey =
        result.transactionId ?? txRef ?? purchase?.purchaseID ?? '';
    final purchaseController = ref.read(purchaseControllerProvider.notifier);
    final checkoutIsActive = purchaseController.isPurchaseInProgress;
    if (checkoutIsActive) {
      purchaseController.completeRecoveredNativePurchase(
        txRef: txRef,
        transactionId: result.transactionId ?? purchase?.purchaseID,
        paymentType: result.paymentType,
      );
    }
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

  void _showAwaitingConfirmationNotice(PendingNativePurchase attempt) {
    if (_isHandledTransaction(txRef: attempt.txRef)) return;
    if (_isFreshCheckoutAttempt(attempt)) return;

    final checkoutIsActive = ref
        .read(purchaseControllerProvider.notifier)
        .isPurchaseInProgress;
    final noticeKey = 'waiting:${attempt.txRef}';
    if (checkoutIsActive || !_notifiedTransactions.add(noticeKey)) return;

    state = AsyncData(
      NativePurchaseRecoveryNotice(
        message:
            "Your purchase is awaiting confirmation. We'll complete it automatically when the connection is restored.",
        transactionKey: noticeKey,
      ),
    );
  }

  void _scheduleRecoveryRetry() {
    if (_recoveryRetryTimer?.isActive == true) return;

    final delayIndex = _recoveryRetryAttempt < _recoveryRetryDelays.length
        ? _recoveryRetryAttempt
        : _recoveryRetryDelays.length - 1;
    final delay = _recoveryRetryDelays[delayIndex];
    _log('scheduling recovery retry in ${delay.inSeconds}s');
    _recoveryRetryAttempt++;
    _recoveryRetryTimer = Timer(delay, () {
      _recoveryRetryTimer = null;
      unawaited(recoverOutstandingPurchases());
    });
  }

  void _cancelRecoveryRetry() {
    _recoveryRetryTimer?.cancel();
    _recoveryRetryTimer = null;
    _recoveryRetryAttempt = 0;
  }

  void clearNotice() {
    state = const AsyncData(null);
  }

  void markPurchaseHandled({String? txRef, String? transactionId}) {
    final keys = [txRef, transactionId]
        .whereType<String>()
        .map((key) => key.trim())
        .where((key) => key.isNotEmpty);

    var handledAny = false;
    for (final key in keys) {
      handledAny = true;
      _handledTransactionKeys.add(key);
      _notifiedTransactions.add(key);
      _notifiedTransactions.add('waiting:$key');
    }

    if (!handledAny) return;

    _cancelRecoveryRetry();
    state = const AsyncData(null);
  }

  bool _isHandledTransaction({String? txRef, String? transactionId}) {
    final normalizedTxRef = txRef?.trim();
    if (normalizedTxRef != null &&
        normalizedTxRef.isNotEmpty &&
        _handledTransactionKeys.contains(normalizedTxRef)) {
      return true;
    }

    final normalizedTransactionId = transactionId?.trim();
    return normalizedTransactionId != null &&
        normalizedTransactionId.isNotEmpty &&
        _handledTransactionKeys.contains(normalizedTransactionId);
  }

  bool _isFreshCheckoutAttempt(PendingNativePurchase attempt) {
    final age = DateTime.now().difference(attempt.createdAt);

    return age >= Duration.zero && age < _freshCheckoutNoticeGracePeriod;
  }

  bool get _supportsNativeRecovery {
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String? get _nativePlatform {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  void _log(String message) {
    if (!_nativeRecoveryDiagnosticsEnabled) return;
    debugPrint('[NativeRecovery] $message');
  }

  String _purchaseSummary(PurchaseDetails purchase) {
    final verificationData = purchase.verificationData;
    return 'product=${purchase.productID} status=${purchase.status.name} '
        'pendingComplete=${purchase.pendingCompletePurchase} '
        'purchaseId=${_tail(purchase.purchaseID)} '
        'source=${verificationData.source} '
        'serverDataLength=${verificationData.serverVerificationData.length} '
        'error=${purchase.error?.code}:${purchase.error?.message}';
  }

  String _tail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'empty';
    if (text.length <= 8) return text;
    return '...${text.substring(text.length - 8)}';
  }
}
